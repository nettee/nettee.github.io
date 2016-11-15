title: SQLAlchemy架构笔记
date: 2016-07-12 14:30:11
tags: [Architecture, Python]
---

这篇笔记主要是为了帮助读者更好地理解SQLAlchemy的架构。虽然原文中已经将SQLAlchemy架构的大部分讲得很全面了，但原文主要是介绍SQLAlchemy的架构，很多部分并没有详细解释。这篇笔记到了补充说明的作用。本笔记共10个小节，和原文的10个小节是完全对应的，读者可以在阅读本笔记的过程中随时参照原文。

SQLAlchemy的代码比较难以阅读，这是由它自身的特点决定的。首先，SQLAlchemy不是一个应用软件，而是一个Python Library。由于SQLAlchemy是一个数据库工具，它必须要适配各种主流的数据库，因此含有大量处理环境上下文的代码。其次，SQLAlchemy用Python书写，Python是动态类型的语言，变量不需要声明，而且可以在对象上添加任意的属性，这给阅读代码带来了很大的难度。总体来说，SQLAlchemy的源代码读起来非常困难。因此，这篇笔记中没有太多对源代码的分析，重点在于分析SQLAlchemy的架构层次，理解设计的思路、动机，并阐释其中使用的模式。

-----

## 1. 数据库抽象面临的挑战

原文中给出了一个概念，叫做“对象-关系阻抗失配”(object-relational impedance mismatch)问题。这个概念的含义是这样的：

“对象-关系阻抗失配”(object-relational impedance mismatch)，有时候叫做“范式不匹配”(paradigm mismatch)，指的是对象模型和关系模型不能很好地共同工作。关系数据库系统用表格的形式表示数据，然而面向对象的语言，如Java，是用相联系的对象来表示的。用表格状的关系数据库加载和存储对象，暴露了下面五个不匹配的问题。

<!-- more -->

+ **粒度**：有时候你的对象模型中的类比对应的数据库中的表的数量要多（我们把这个叫做对象模型比关系模型粒度更细）。想想一个地址的例子就知道了
+ **继承**：继承是面向对象编程语言中一个自然的范式，然而，关系数据库系统基本上无法定义类似的东西（确实有些数据库支持子类，但那完全不是规范化的东西）
+ **相等关系**：关系数据库系统只定义了一种“相等”的概念：主键相等则元组相等。面向对象语言中则常常有两种相等关系。例如，Python中的`a is b`（全等）和`a == b`（相等）。
+ **关联性**：在面向对象语言中，关联表示为单向引用，而在关系数据库系统中，关联表示为外键。如果你在Python中需要定义双向关联，你必须定义两次关联。
+ **获取数据的方式**：你在Python中访问数据的方式和在关系数据库中访问数据的方式有本质的不同。在Python中，你在一个对象中通过引用访问到另一个对象。但这在关系数据库中不是一个获取数据的高效方法，你可能想要让SQL查询与的数量最小。

如果你开发的系统使用的是面向对象语言和关系型数据库，当系统规模大到一定程度的时候，就一定会出现对象-关系阻抗失配的问题。SQLAlchemy这类的ORM工具就是用来解决这类问题的。

## 2. SQLAlchemy的两层结构

原文中已经给出了SQLAlchemy的两个层次的关系图：

![Figure 20.1][fig1]

SQLAlchemy的两个最主要的功能点就是**对象-关系映射（ORM）**和**SQL表达式语言**。SQL表达式语言可以独立于ORM使用。而当用户使用ORM时，SQL表达式语言在背后工作，但用户也可以通过开放的API操纵SQL表达式语言的行为。

下面的3到9节都是围绕上图所展示的SQLAlchemy架构层次进行阐述的。其中，3-5节讲述的是核心层，而6-9节讲述的是ORM层。

我们知道，SQL语言一共分为四大类：

+ DDL(Data Definition Language) - 主要包括CREATE TABLE，DROP，ALTER，用来定义数据库模式
+ DML(Data Manipulation Language) - 主要包括SELECT，用来查询数据 
+ DQL(Data Query Language) - 主要包括INSERT，UPDATE，DELETE，用来插入、更新、删除数据
+ DCL(Data Control Language) - 主要包括GRANT等

我们暂时不关注DCL。在DDL/DML/DQL中，DDL负责对数据库的模式进行定义，而DML和DQL负责数据的存取。虽然同属SQL语言，但它们关注的东西完全不同。SQLAlchemy中使用不同的模块对这两部分进行抽象。在核心层，SQLAlchemy使用`Metadata`对DDL进行抽象，使用SQL表达式语言对DML和DQL进行抽象。在ORM层，SQLAlchemy使用`mapper`对DDL进行抽象，使用`Query`对象对DML和DQL进行抽象。下面的4/5/6/7节分别对应这四块：

+ (4)模式定义 - 核心层的模式定义(DDL)
+ (5)SQL表达式语言 - 核心层的数据存取(DML/DQL)
+ (6)对象-关系映射 - ORM层的模式定义(DDL)
+ (7)查询和加载 - ORM层的数据存取(DML/DQL)

读者不妨在阅读时对比第4节和第6节、第5节和第7节的内容，会发现很多联系和相似之处。

## 3. 改良DBAPI

首先，我们要理解什么是DBAPI，以下内容引用自SQLAlchemy文档的术语表：

> DBAPI是“Python数据库API规范”（Python Database API Specification）的简称。这是在Python中广泛使用的规范，定义了数据库连接的第三方库的使用模式。DBAPI是一个低层的API，在一个Python应用中基本上位于最底层，和数据库直接进行交互。SQLAlchemy的方言系统按照DBAPI的操作来构建。基本上，一个方言就是DBAPI加上一个特定的数据库引擎。通过在`create_engine()`函数中提供不同的数据库URL可以将方言绑定到不同的数据库引擎上。 
>
> 参见： [PEP 249 - Python Database API Specification v2.0](http://www.python.org/dev/peps/pep-0249/)

—— [SQLAlchemy文档 - 术语表 - DBAPI](http://docs.sqlalchemy.org/en/rel_1_0/glossary.html#term-dbapi)


PEP的文档介绍比较枯燥，我们可以通过这个示例代码直观地理解DBAPI的使用模式：

```Python
connection = dbapi.connect(user="root", pw="123456", host="localhost:8000")
cursor = connection.cursor()
cursor.execute("select * from user_table where name=?", ("jack",))
print "Columns in result:", [desc[0] for desc in cursor.description]
for row in cursor.fetchall():
    print "Row:", row
cursor.close()
connection.close()
```

作为对比，SQLAlchemy的使用模式是这样的：

```Python
engine = create_engine("postgresql://user:pw@host/dbname")
connection = engine.connect()
result = connection.execute("select * from user_table where name=?", "jack")
print result.fetchall()
connection.close()
```

可以看到，二者的使用模式非常相似，都是直接通过SQL语句进行查询。SQLAlchemy只进行了封装，但没有进行高层次的抽象。不过，这只是SQLAlchemy最简单的使用方式，后面会看到，使用SQL表达式语言可以进行抽象性很高的描述，不需要手写SQL语句。

原文中给出了SQLAlchemy方言系统核心类的关系图：

![Figure20.2][fig2]

对照原文中的描述，阅读源代码：

> `Engine`、`Connection`两个类的`execute`方法返回的结果是一个`ResultProxy`，它提供了一个与DBAPI的游标类似但功能更丰富的接口。`Engine`，`Connection`和`ResultProxy`分别对应于DBAPI模块、一个具体的DBAPI连接对象，和一个具体的DBAPI游标对象。
>
> 在底层，`Engine`引用了一个叫`Dialect`的对象。`Dialect`是一个有众多实现的抽象类，它的每一个实现都对应于一个具体的DBAPI和数据库。一个为`Engine`而创建的`Connection`会咨询`Dialect`作出选择，对于不同的目标DBAPI和数据库，`Connection`的行为都不一样。
>
> `Connection`创建时会从一个连接池获取并维护一个DBAPI的连接，这个连接池叫`Pool`，也和`Engine`相关联。`Pool`负责创建新的DBAPI连接，通常在内存中维护DBAPI连接池，供频繁的重复使用。
>
> 在一个语句执行的过程中，`Connection`会创建一个额外的`ExecutionContext`对象。这个对象从开始执行的时刻，一直存在到`ResultProxy`消亡为止。

#### Engine和Connection

全局函数`create_engine`用来创建`Engine`对象，这个函数的第一个参数是一个数据库URL，还有一些关键字参数，用来控制`Engine`，`Pool`和`Dialect`对象的特性。其中关键字参数strategy用于指定创建`Engine`时的策略。函数会从全局的`strategies`字典中查找对应的策略（`EngineStrategy`的一个子类），将自己的参数传入策略类的`create`方法。如果strategy参数没有提供，则使用默认策略`DefaultEngineStrategy`。观察每个`EngineStrategy`子类的`create`方法，发现它们都会在创建`Engine`对象之前先创建`Dialect`对象和`Pool`对象，并将这两个对象的引用保存在`Engine`对象中，保证了`Engine`对象可以通过`Dialect`和`Pool`处理DBAPI。

`Connection`类看起来比`Engine`类更加强大。`Engine.connect()`方法用于创建`Connection`：

```Python
_connection_cls = Connection

def connect(self, **kwargs):
    return self._connection_cls(self, **kwargs)
```

调用`Engine.connect()`实际上是将`Engine`对象自己作为第一个参数传入了`Connection`的构造函数，但`Connection`的构造函数还要调用`Engine.raw_connection()`方法获得数据库连接。这样做主要是为了方便`Engine`的隐式执行接口。在`Connection`没有创建的时候，`Engine`也可以自己调用`raw_connection()`获得数据库连接。

不论怎样，`Connection`拥有`Engine`的引用，并可以通过`Engine`的访问`Pool`和`Dialect`对象。对数据库的操作通常是使用`Connection.execute()`方法进行的。

#### Pool

`Pool`负责管理DBAPI连接。`Connection`对象创建时，会从连接池中取出一个DBAPI连接，而在`close`方法调用时，会将连接归还。

`Pool`的代码定义在`pool.py`中，包括抽象父类`Pool`，和几个有具体功能的子类：

+ `QueuePool` 限制连接个数（默认使用）
+ `SingletonThreadPool` 为每个线程维护一个连接
+ `AssertionPool` 任何时候都只允许一个连接，否则抛出异常
+ `NullPool` 不进行任何池操作，直接打开/关闭DBAPI连接
+ `StaticPool` 有且仅有一个连接

#### 执行SQL语句

`Connection`的`execute`方法执行一个SQL语句，并返回一个`ResultProxy`对象。`execute`方法接受多种类型的参数，参数类型可以是一个字符串，也可以是`ClauseElement`和`Executable`的共同子类。关于`execute`方法的参数在下文中详细讨论，这里主要分析`execute`方法执行时背后的过程。

```Python
def execute(self, object, *multiparams, **params):
    if isinstance(object, util.string_types[0]):
        return self._execute_text(object, multiparams, params)
    try:
        meth = object._execute_on_connection
    except AttributeError:
        raise exc.InvalidRequestError(
        "Unexecutable object type: %s" %
        type(object))
    else:
        return meth(self, multiparams, params)
```

可以看到，`execute`方法对SQL语句对象的类型进行判断，如果是一个字符串，则调用`_execute_text`方法执行，否则调用对象的`_execute_on_connection`方法，而不同对象的`_execute_on_connection`方法会调用`Connection._execute_*()`方法，具体为：

+ `sql.FunctionElement`对象，调用`Connection._execute_function()`
+ `schema.ColumnDefault`对象，调用`Connection._execute_default()`
+ `schema.DDL`对象，调用`Connection._execute_ddl()`
+ `sql.ClauseElement`对象，调用`Connection._execute_clauseelement()`
+ `sql.Compiled`对象，调用`Connection._execute_compiled()`

以上的`Connection._execute_*()`方法都调用了`Connection._execute_context()`方法。这个方法的第一个参数是`Dialect`对象，第二个参数是`ExecutionContext`对象的构造器（构造器从`Dialect`对象获取）。在方法中调用构造器构造了一个`ExecutionContext`对象，并根据context对象的状态调用dialect对象的相关方法产生结果。对不同的状态，调用的dialect对象的方法不同，总的来说，调用的是`Dialect.do_execute*()`方法。

从上述方法调用的过程可以看出，`Connection`的`execute`方法最终将生成结果的任务转交给了`Dialect`的`do_execute`方法。SQLAlchemy正是用这种方法应对多变的DBAPI实现的：`Connection`在执行SQL语句的时候，会咨询`Dialect`作出选择。因此对于不同的目标DBAPI和数据库，`Connection`的行为都不一样。

#### Dialect

`Dialect`定义在engine/interfaces.py文件中，是一个抽象的接口，其中定义了三个`do_execute*()`方法，分别是`do_execute()`，`do_executemany()`和`do_execute_no_params()`。`Dialect`的子类通过实现这些接口来定义自己执行时的行为。SQLAlchemy中默认的dialect子类是`DefaultDialect`。在默认实现中，`do_execute`方法调用`Cursor.execute`，而`Cursor`是来自DBAPI的类。在这里，SQLAlchemy核心层和DBAPI层连接了起来。

`sqlalchemy.dialects`包中包含有来自firebird，mssql，mysql，oracle，postgresql，sqlite，sybase等数据库的dialect。以SQLite数据库为例，`SQLiteDialect`继承自`DefaultDialect`，而`SQLiteDialect_pysqlite`和`SQLiteDialect_pysqlcipher`。SQLite的dialect没有重写`do_execute*()`，而是重写了一些其他的方法，来定义一些和`DefaultDialect`不同的行为。例如，SQLite没有内置的DATE，TIME，DATETIME类型，`SQLiteDialect`处理了这些问题。

#### ResultProxy

`ResultProxy`包装了一个DBAPI游标(cursor)对象，使一行结果中的各个字段更容易访问。在数据库术语中，结果通常称为一个行(row)。

一个字段可以通过三种方式访问：

```Python
row = fetchone()
col1 = row[0] # 通过位置下标访问
col2 = row['col2'] # 通过名字访问
col3 = row[mytable.c.mycol] # 通过Column对象访问
```

ResultProxy定义了`__iter__`方法，可以在ResultProxy对象上使用for循环，效果和不断调用fetchone方法一样：

```Python
def __iter__(self):
    while True:
        row = self.fetchone()
        if row is None:
            return
        else:
            yield row
```

## 4. 模式定义

> 数据库模式是用形式化的语言描述的数据库系统的结构。在关系数据库中，模式定义了表、表中字段，以及表和字段间的关系

—— [Webopedia](http://www.webopedia.com/TERM/S/schema.html)

直观来说，下面的SQL语句就描述了一个数据库的模式：

```SQL
CREATE TABLE users (
    id INTEGER NOT NULL,
    name VARCHAR,
    fullname VARCHAR,
    PRIMARY KEY (id)
);

CREATE TABLE addresses (
    id INTEGER NOT NULL,
    user_id INTEGER,
    email_address VARCHAR NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(user_id) REFERENCES users (id)
);
```

SQLAlchemy的模式定义功能就是用一种抽象的方式表达上面SQL语句的内容。下面的代码定义了和上面SQL语句相同的模式：

```Python
metadata = MetaData()

users = Table('users', metadata,
        Column('id', Integer, primary_key=True),
        Column('name', String),
        Column('fullname', String),
)
addresses = Table('addresses', metadata,
        Column('id', Integer, primary_key=True),
        Column('user_id', None, ForeignKey('users.id')),
        Column('email_address', String, nullable=False),
)

metadata.create_all(engine)
```

`MetaData`的名字来自元数据映射模式，但真正实现了这个模式的实际上是`Table`和`mapper()`函数，下面关于ORM的章节将会详细讲述。

`MetaData`对象保存了所有的schema相关的所有结构，特别是`Table`对象。`sorted_tables`方法返回`Table`对象经过拓扑排序的列表。关于表的拓扑排序，参见第九节“工作单元”。

阅读源代码，`Table`的构造函数`__new__`的前两个参数分别是表名和`MetaData`对象。构造函数会创建一个名字唯一的`Table`对象，用同样的表名和`MetaData`对象再次调用构造函数，会返回相同的对象。因此`Table`的构造函数充当了“注册”的角色。

## 5. SQL表达式语言

`Query`对象实现了Martin Fowler定义的*查询对象*(Query Object)模式。Martin Fowler在书中是这么描述这个模式的：

> SQL是一个演化中的语言，很多开发人员对它不是非常熟悉。而且，你在写查询语句的时候需要知道数据库schema是什么样的。查询对象模式可以解决这些问题。
>
> 查询对象是一个解释器模式(Interpreter Pattern)，也就是一个对象可以把自己变成一个SQL查询。你可以通过使用类和属性，而不是表和字段来创建一条查询。用这种方法，你在写查询语句时可以不依赖数据库schema，对schema的改变也不会造成全局的影响。

—— Martin Fowler: [*Patterns of Enterprise Application Architecture*, Query Object](http://martinfowler.com/eaaCatalog/queryObject.html)


Mike Bayer指出，SQL表达式的创建主要使用了**Python表达式**和**重载的操作符**。

#### 源代码分析

`sqlalchemy.sql.dml.Insert`是`UpdateBase`的子类，而`UpdateBase`同时是`ClauseElement`和`Executable`的子类，所以可以将`Insert`的实例传给`Connection.execute()`

`select`是一个全局的函数，而不是类。在sql/expression.py中，调用`public_factory`，将`selectable.Select`类变为函数`select`，也就是将
`Select.__init__()`赋值给`select`。

## 6. 对象-关系映射（ORM）

什么是ORM呢？让我们先看看Martin Fowler在书中所描述的**数据映射器**(Data Mapper)模式。原文中提到，SQLAlchemy的ORM系统正是借鉴了这种模式。

> ![Figure: DatabaseMapperSketch](http://martinfowler.com/eaaCatalog/databaseMapperSketch.gif)
>
> 对象和关系数据库组织数据的方式是不同的。对象中的很多部分，如继承，在关系数据库中是没有的。当你建立了一个有大量业务逻辑的对象模型，对象的schema和关系数据库的schema就可能不匹配。
>
> 但你仍需要在两种schema之间进行转换，这种转换本身就成为一个复杂的东西。如果内存中的对象知道关系数据库的结构，两者之间一者的改变就会影响到另一者。
>
> 数据映射器(Data Mapper)是将内存中的对象和数据库分离的一层系统。它的责任是分隔对象和关系数据库，并在两者之间转换数据。有了数据映射器，内存中的对象既不需要的SQL接口代码，也不需要知道数据库schema，甚至都不需要知道数据库是否存在。

—— Martin Fowler: [*Patterns of Enterprise Application Architecture*, Data Mapper](http://martinfowler.com/eaaCatalog/dataMapper.html)

为了理解上面这段话的含义，我们看下面的示例代码：

```Python
from sqlalchemy import Table, MetaData, Column, Integer, String, ForeignKey
from sqlalchemy.orm import mapper

metadata = MetaData()

users = Table('users', metadata,
        Column('id', Integer, primary_key=True),
        Column('name', String),
        Column('fullname', String),
)

class User(object):
    def __init__(self, name, fullname, password):
        self.name = name
        self.fullname = fullname
        self.password = password

mapper(User, users)
```

在上面的代码中，`User`类是用户自己定义的类，它是业务逻辑中的一个实体对象。而`users`是数据库的schema（在第四节“模式定义”中已经详细分析过）。使用`mapper`函数将`User`类映射到schema上。注意到，`User`类和数据库的schema完全无关，在不知道数据存储方式的情况下就可以写出这个类。这样就实现了对象和数据库的分离。

#### 两类映射

所谓“传统的”和“声明式的”，不过是SQLAlchemy中用户定义ORM的新旧两种风格。SQLAlchemy一开始只支持传统映射，后来出现了声明式映射，它在传统映射的基础上建立，功能更丰富，表达更简洁。两个映射方式可以互相交换使用，结果是一模一样的。而且声明式映射最终也会被转换为传统映射——用`mapper()`函数映射一个用户定义的类，因此两种映射方式在本质上是没有区别的。

按我的理解，传统映射思路更加明确，更能体现对象和数据库分离的思想，而声明式映射功能更强大。

## 7. 查询和加载

#### 查询对象

前面已经提到过，SQLAlchemy的ORM层建立在核心层之上，因此用户使用ORM层时，不会使用核心层中`connection.execute()`之类的接口。`Session`（会话）成为用户使用数据库的唯一入口。而用户通过`Session`进行查询时，需要使用`Query`对象进行查询。示例代码如下：

```Python
session = Session(engine)
result = session.query(User).filter(User.name == 'ed').all()
```

`Query`对象实现了Martin Fowler定义的*查询对象*(Query Object)模式。在第五节中已经提到，`select()`也实现了这个模式。实际上`Query`和`select()`的功能很相似，都是进行数据库查询，只不过一个工作在核心层，一个工作在ORM层。比较`select()`的代码：

```Python
connection = engine.connect()
result = connection.execute(select([users])).where(users.c.name == 'ed')
```

所谓QUERY TIME和LOAD TIME两个部分，是因为ORM层工作在核心层（SQL表达式语言）之上，要调用SQL表达式语言的基础设施进行工作。

## 8. 会话

原文中的图20.13非常清晰地展示了会话的组成部分：

![Figure 20.13][fig13]

前一节已经分析了`Query`对象，它主要负责进行查询和对象加载。而`Session`负责的是更多细致和琐碎的工作。从图中可以看出，`Session`对象包含了三个重要的部分

+ 标识映射
+ 对象的状态
+ 事务

标识映射和状态跟踪之间的配合，是我认为SQLAlchemy设计最为精妙的两个部分之一。下面会详细介绍这两部分内容。

#### 标识映射

标识映射(Identity Map)是一个由Martin Fowler定义的模式，下面是Martin Fowler在书中对这个模式的介绍：

> ![Figure: Identity Mapper Sketch](http://www.martinfowler.com/eaaCatalog/idMapperSketch.gif)
>
> 一个古老的谚语说，一个有两块手表的人永远不知道时间是多少。在从数据库加载对象时，如果两块表（两个对象）不一致，你会有更大的麻烦。你一不小心就可能从同一个数据库中加载数据并存到两个不同的对象中。当你同时更新了两个对象，你在把改变写到数据库时，就会出现一些奇怪的结果。
> 
> 这还和一个明显的性能问题有关。如果你不止一次加载同一份数据，会导致远程调用的昂贵开销。那么，避免加载同一份数据两次，不仅能保证正确性，还能提升应用的性能。
> 
> 标识映射保存了在一个事务中从数据库中读取出的所有数据。当你需要一份（加载到对象中的）数据时，首先检查标识映射，看看是不是已经有了。

—— Martin Fowler, [*Patterns of Enterprise Application Architecture*, Identity Map](http://www.martinfowler.com/eaaCatalog/identityMap.html)

简单的说，标识映射是一个Python字典，是从一个Python对象到这个对象的数据库ID的映射。当应用程序试图获取一个对象时，如果对象还没有被加载，标识映射会加载这个对象，并保存在字典里；而如果对象已经加载过，标识映射会从字典里取出原先的对象。标识映射有两个显著的好处：

1. 已加载的对象被“缓存”下来，不需要加载多次，造成额外开销。这实际上是一种懒惰加载(lazy loading)
2. 保证应用程序获取对象时，得到的是唯一的对象，避免数据不一致的问题

在SQLAlchemy的实际实现中，`IdentityMap`的key是数据库ID，但value不是一个对象，而是保存了对象状态的`InstanceState`。下面“状态跟踪”解释了`IdentityMap`为什么要这样设计。

#### 状态跟踪

在`Session`中，一个对象有四种状态，用一个`InstanceState`来记录：

+ **Transient** - 这个对象不在会话中，而且没有保存到数据库。也就是说，它没有一个数据库ID。这个对象和ORM的唯一关系是，它的类关联到了一个`mapper()`
+ **Pending** - 当你调用`add()`并传入了一个transient对象，它就成了pending状态。这时候它还没有刷新到数据库中，但下一次刷新后就会保存到数据库
+ **Persistent** - 在会话当中，并且在数据库里有一条记录的对象。得到persistent对象有两种方法，一种是通过刷新将pending对象变成persistent对象，另一种是从数据库中查询得到对象
+ **Detached** - 对象和数据库里的一条记录对应（或曾经对应），但它不在任何会话中了。在会话中的事务提交后，所有的对象都变为detached状态

一个对象从进入`Session`到离开`Session`，就是将这四个状态依次走一遍的过程（对新创建的对象，需要走完四个状态；其他对象则没有transient状态）。先是进入`Session`，内存的数据发生了改变，进入pending状态；接着经过刷新操作，将内存的改变保存到数据库，进入persistent状态；最后离开`Session`，进入detached状态。

理解了这四种状态的区别后，我们就可以发现：`Session`要重点跟踪的对象是pending状态的对象，因为这些对象的内存数据和数据库不一致；而一旦对象到达persistent状态，实际上对象已经不需要跟踪，因为内存数据已经和数据库一致，`Session`可以在此后的任意时间点将这些对象丢弃。

那么，何时将这个对象丢弃掉呢？首先，不能丢弃得太早。因为当对象在persistent状态时，用户可能进行一次查询操作，通过标识映射找到了这个内存中的对象。如果太早丢弃，这时候就要从数据库中重新加载对象，造成不必要的开销。其次，也不能丢弃得太晚，因为这样会话中会保留大量的对象，内存得不到及时的回收。那么最好的方法，就是交给垃圾回收器来做决定，垃圾回收器在内存不够的时候会释放对象，回收内存，同时有让对象在内存中保持一段时间，在需要的时候可以拿来使用。

`Session`使用*弱引用*(weak reference)机制来实现这一点，所谓弱引用，就是说，在保存了对象的引用的情况下，对象仍然可能被垃圾回收器回收。在某一时刻通过引用访问对象时，对象可能存在也可能不存在，如果对象不存在，就重新从数据库中加载对象。而如果不希望对象被回收，只需要另外保存一个对象的强引用即可。`Session`中的`IdentityMap`，实际上是一个“弱引用字典”(weak value dictionary)，也就是说，映射中的值(value)是弱引用的，当字典中的值没有强引用指向它时，字典中的这个键值对就会被清除。关于弱引用字典的详细资料可以查看[Python官方文档-WeakValueDictionary](https://docs.python.org/3/library/weakref.html#weakref.WeakValueDictionary)。

图中显示，`Session`对象包含了一个`new`属性和一个`deleted`属性。阅读源代码发现，`Session`还包含一个`dirty`属性。这三个属性都是对象的集合。顾名思义，`new`表示刚刚被加入会话的对象，`dirty`属性表示刚刚被修改的对象，而`deleted`属性表示在会话中被删除的对象。这三个对象都有一个共同的特点：它们都是内存中经过改变而和数据库不一致的数据，正是上面“对象的四个状态”中的pending状态。也就是说，`Session`保存了所有处于pending状态的对象的强引用，这保证了这些对象不会被垃圾回收器回收。对于其他的对象，`Session`只保留了弱引用。


## 9. 工作单元

工作单元也是Martin Fowler在书中定义的模式，SQLAlchemy的`unitofwork`模块实现了这个模式。SQLAlchemy文档中说，工作单元模式“自动地跟踪对象上发生的改变，周期性地将pending的改变刷新到数据库中”（[SQLAlchemy文档 - 术语表 - unit of work](http://docs.sqlalchemy.org/en/rel_1_0/glossary.html#term-unit-of-work)）。工作单元和会话之间的关系是：会话定义了对象的四个状态，而工作单元负责将会话中的pending状态对象转移到persistent状态，在这个过程中完成数据库持久化的工作。用户调用`Session`的`commit`方法，讲对数据的查询、更新等操作保存到数据库中。原文中提到，`commit`方法调用了`flush`方法进行“刷新”操作，而`flush`的所有实际工作都由工作单元模块完成。

工作单元是我认为SQLAlchemy设计最精妙的两个部分之二。要理解工作单元的精妙之处，首先要知道数据库持久化工作的主要难点在哪里。内存的速度很快，在一段时间内可能有很多对象的状态发生了改变。要将这些改变进行持久化，最简单的做法是，对每一个发生变化的对象，生成一条SQL语句（可能是INSERT语句、UPDATE语句或DELETE语句），进行一次数据库调用。但是数据库的写入速度要比内存慢很多，太多的数据库操作会极大地降低性能。要想实现高效，需要一次将一批数据送入数据库。

然而，这些对象并不能按照任意的顺序进行持久化。例如，当两个表之间存在外键关系，如果想要持久化一个存在外键的对象，就要先对外键引用的对象进行持久化。这意味着，虽然可以一次将一批对象持久化，但遇到有外键的对象，就必须停下来，先持久化那个外键引用的对象。于是实际上还是进行了很多次的数据库调用。

工作单元则使用了一种非常优越的模式，在进行持久化操作之前，先安排好对象进行持久化的顺序。持久化的时候只需要将一批批的对象送到数据库，而不需要在处理每个对象之前先考虑一下是不是还有别的依赖。工作单元将对象之间的依赖关系用有向图进行建模，根据图论中有向无环图的拓扑排序，就可以安排出所有对象刷新的顺序。关于具体的步骤，原文中已经讲得很清楚了，在此不再赘述。

## 10. 结语

在调研SQLAlchemy之前，我从未听说过ORM这个概念，也不知道Hibernate等著名的ORM工具。去年在使用JSP进行Web开发时，就遇到了关系数据库和对象之间的转换问题，也意识到这是一个必要但又很复杂的工作。如果在开发中使用ORM工具，必然会很大程度上提升程序的健壮性。 关系数据库是再重要不过的技术，而面向对象语言一直是主流的语言。ORM则将这两者结合了起来。SQLAlchemy是Python中最流行的ORM工具，也是事实上的标准。实际上，Python著名的Web框架Django因为自带了一套ORM系统而不支持SQLAlchemy一直遭人诟病。如果你还从来没有听说ORM这个概念，建议你能了解一下SQLAlchemy，并在开发中尝试使用这个库。

--- 

## 参考资料

+ [SQLAlchemy 1.0 官方文档](http://docs.sqlalchemy.org/en/rel_1_0/index.html)
+ Martin Fowler: Patterns of Enterprise Application Architecture 
+ [Mike Bayer: SQLAlchemy所实现的模式](http://techspot.zzzeek.org/2012/02/07/patterns-implemented-by-sqlalchemy/)
+ [Mike Bayer: SQLAlchemy架构回顾](http://techspot.zzzeek.org/files/2011/sqla_arch_retro.key.pdf)
+ [Catalog of Patterns of Enterprise Application Architecture](http://martinfowler.com/eaaCatalog/)
+ [Hibernate文档 - 什么是ORM](http://hibernate.org/orm/what-is-an-orm/)

[fig1]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/layers.png
[fig2]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/engine.png
[fig3]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/dialect-simple.png
[fig4]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/common-dbapi.png
[fig5]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/basic-schema.png
[fig6]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/table-column-crossover.png
[fig7]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/expression-hierarchy.png
[fig8]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/example-expression.png
[fig9]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/compiler-hierarchy.png
[fig10]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/statement-compilation.png
[fig11]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/mapper-components.png
[fig12]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/query-loading.png
[fig13]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/session-overview.png
[fig14]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/topological-sort.png
[fig15]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/uow-mapper-buckets.png
[fig16]: https://raw.githubusercontent.com/nettee/SQLAlchemy-survey/master/picture/uow-element-buckets.png
