title: Java 8： 事实上的多继承语言
date: 2018-12-26 20:38:57
tags: [Java, OO, Programming Language]
---

**Java 在多重继承上的设计甚至不如 C++**。这个论点让人很难接受，毕竟我们在第一堂 Java 课上学到了：“Java 的优越性之一是摒除了 C++ 中易出错的多重继承”。然而，Java 的类单继承、接口多继承的设计，最终使 Java 走上了多重继承的老路，这最后一根稻草就是 Java 8 的 `default` 关键字。

## Java 为什么设计成单继承

Java 语言在设计之初显然受到了 C++ 的很大影响。然而，Java 最终却没有采用 C++ 的多重继承方案。这是 Java 与 C++ 区分开的一个特点。在 Java 中，不允许“实现多继承”，即一个类不允许继承多个父类。但是 Java 允许“声明多继承”，即一个类可以实现多个接口，一个接口也可以继承多个父接口。由于接口只允许有方法声明而不允许有方法实现，这就避免了 C++ 中多继承的决议问题。

James Gosling 在设计 Java 的继承方案时，借鉴了 Objective-C 中的“纯接口”概念。他发现，没有实现体的纯接口避免了 C++ 中的很多歧义和坑。因此 Java 引入了 interface。

## Java 8：default 关键字的引入

Java 8 这一版本可以说是 Java 5 之后一次最大的改动了。在全面引入了 lambda 和函数式编程之后，JDK 中的很多接口也需要升级，例如 `Iterable.forEach`:

```diff
 public interface Iterable<T> {
     Iterator<T> iterator();
+    void forEach(Consumer<? super T> action);
 }
```

然而，如果直接在 `Iterable` 接口中添加 `forEach` 方法。在 Java 7 及以前的所有实现 `Iterable` 的类都无法通过编译。为了向后兼容已有的代码，Java 8 引入了 `default` 关键字以及 default method，用来在接口中定义一个有方法体的方法。通过定义一个 default 的 `forEach`。所有实现了 `Iterable` 的类无需修改代码，便可在对象上调用 `forEach`。

```Java
public interface Iterable<T> {
    Iterator<T> iterator();

    default void forEach(Consumer<? super T> action) {
        Objects.requireNonNull(action);
        for (T t : this) {
            action.accept(t);
        }
    }
}
```

## default 与多重继承

<!-- more -->

Java 在设计之初，将 interface 设计成“没有任何实现”的纯接口，以此来避免接口多继承可能导致的问题。如果继承的多个接口中定义了相同的方法，只需要检查方法的返回值是否一致即可，例如：

```Java
public class Test {

    public interface Base {
        int doSomething();
    }

    public interface Foo extends Base {
    }

    public interface Bar extends Base {
    }

    public abstract class FooBar implements Foo, Bar {
        // 编译器检查 Foo 和 Bar 中的 doSomething() 返回类型是否相同
    }
}
```

然而，在引入了 default method 之后，情况变得不太一样了。子接口可以 override 父接口定义的方法。我们可以轻易地构造出 C++ 的多重继承常出现的“[菱形问题](https://en.wikipedia.org/wiki/Multiple_inheritance#The_diamond_problem)”：

```Java
public class Test {

    public interface Base {
        int doSomething();
    }

    public interface Foo extends Base {
        @Override
        default int doSomething() {
            System.out.println("Foo::doSomething");
            return 1;
        }
    }

    public interface Bar extends Base {
        @Override
        default int doSomething() {
            System.out.println("Bar::doSomething");
            return 2;
        }
    }

    public abstract class FooBar implements Foo, Bar {
        // Error: inherit unrelated default from super-interfaces
    }
}
```

在上面的例子中，`Foo` 和 `Bar` 都重写了 `doSomething`，使得 `FooBar` 中的 `doSomething` 的含义出现了歧义，编译器会在此处报错。

## Interface 还是 interface 吗

Java 8 引入的 default method 当然是一次对 interface 的极大增强（同时引入的还有 static method）。但是我们不禁思考，现在的 interface 是否还是 Java 设计之初的那个“纯接口”。上面的菱形问题的例子，我们发现，带有 default method 的接口表现得和抽象类越来越相似了。当然，interface 无法拥有和抽象类一样的能力，例如没有 private 的 method 和 field。但是以 interface 目前的能力，已经足够导致菱形问题这样的多继承问题。

在 Java 9 中，为了解决 default method 中重复代码的例子，又为 interface 引入了 private method （以及 private static method），interface 的能力进一步得到增强。可以预料，未来 Java 中接口的能力将无限接近于抽象类。从这个层面上来讲，Java 虽然当年努力与 C++ 区分开，可还是和 C++ 越来越像。

多继承当然是一种有力的语言机制，库和框架的开发者应该可以使用多继承实现一些酷炫的功能。但对于普通的 Java 程序员来说，interface 的语义变化会带来额外的心智负担。所以最好的办法是，忘记 default method 这件事情，让 interface 继续做最纯粹的接口。多继承这件事情，还是交给 Scala 这样更现代的语言来写吧。
