title: Java 泛型技巧：获取真实的泛型类型
tags: [Java]
---

## 不合常理的泛型类

使用 netty 的人肯定都接触过 `SimpleChannelInboundHandler`，它是一个开箱即用的处理请求数据的类。在 `SimpleChannelInboundHandler` 中，我们只需要重写 `channelRead0(ChannelHandlerContext, T)` 方法，就可以直接处理 `T` 类型的数据对象，无需强制转换了：

```java
public class CreateUserHandler extends SimpleChannelInboundHandler<CreateUserRequest> {
  
  	@Override
  	protected void channelRead0(ChannelHandlerContext ctx, CreateUserRequest request) throws Exception {
      	// handles request
    }
}
```

用起来真的很方便……等等！Java 的泛型不是会在编译时抹除吗，为什么 `SimpleChannelInboundHandler` 能知道我们数据对象的真实类型？

我们知道，Java 使用类型擦除的方式来实现泛型。因此一个 `SimpleChannelInboundHandler<CreateUserRequest>` 的对象，在编译之后 CreateUserRequest 会被擦除成 Object。因此，要想知道具体的泛型类型，一般有两种方式：

```java
// 1. 方法参数中有泛型对象，通过 getClass() 获得泛型对象的实际类型
void handle(T data) {
  Class<T> clazz = data.getClass();
  // ...
}

// 2. 方法参数中无泛型对象，直接增加一个参数传入泛型类型
void handle(String message, Class<T> clazz) {
  // ...
}
```

但是 `SimpleChannelInboundHandler` 显然不属于以上任何一种方式。这是什么情况呢？

## 神奇的代码

为了一探究竟，我打开 netty 的源码，获取泛型类型的关键就在于这一行代码：

```Java
matcher = TypeParameterMatcher.find(this, SimpleChannelInboundHandler.class, "I");
```

这里 `I` 是 `SimpleChannelInboundHandler` 的泛型参数声明：

```java
public abstract class SimpleChannelInboundHandler<I> extends ChannelInboundHandlerAdapter { 
}
```

正是这一行代码实现了我认为不可能的功能。究竟是为什么，继续往里看：

```java
public static TypeParameterMatcher find(
        final Object object, final Class<?> parameterizedSuperclass, final String typeParamName) {

    final Map<Class<?>, Map<String, TypeParameterMatcher>> findCache =
            InternalThreadLocalMap.get().typeParameterMatcherFindCache();
    final Class<?> thisClass = object.getClass();

    Map<String, TypeParameterMatcher> map = findCache.get(thisClass);
    if (map == null) {
        map = new HashMap<String, TypeParameterMatcher>();
        findCache.put(thisClass, map);
    }

    TypeParameterMatcher matcher = map.get(typeParamName);
    if (matcher == null) {
        matcher = get(find0(object, parameterizedSuperclass, typeParamName));
        map.put(typeParamName, matcher);
    }

    return matcher;
}

private static Class<?> find0(
        final Object object, Class<?> parameterizedSuperclass, String typeParamName) {

    final Class<?> thisClass = object.getClass();
    Class<?> currentClass = thisClass;
    for (;;) {
        if (currentClass.getSuperclass() == parameterizedSuperclass) {
            int typeParamIndex = -1;
            TypeVariable<?>[] typeParams = currentClass.getSuperclass().getTypeParameters();
            for (int i = 0; i < typeParams.length; i ++) {
                if (typeParamName.equals(typeParams[i].getName())) {
                    typeParamIndex = i;
                    break;
                }
            }

            if (typeParamIndex < 0) {
                throw new IllegalStateException(
                        "unknown type parameter '" + typeParamName + "': " + parameterizedSuperclass);
            }

            Type genericSuperType = currentClass.getGenericSuperclass();
            if (!(genericSuperType instanceof ParameterizedType)) {
                return Object.class;
            }

            Type[] actualTypeParams = ((ParameterizedType) genericSuperType).getActualTypeArguments();

            Type actualTypeParam = actualTypeParams[typeParamIndex];
            if (actualTypeParam instanceof ParameterizedType) {
                actualTypeParam = ((ParameterizedType) actualTypeParam).getRawType();
            }
            if (actualTypeParam instanceof Class) {
                return (Class<?>) actualTypeParam;
            }
            if (actualTypeParam instanceof GenericArrayType) {
                Type componentType = ((GenericArrayType) actualTypeParam).getGenericComponentType();
                if (componentType instanceof ParameterizedType) {
                    componentType = ((ParameterizedType) componentType).getRawType();
                }
                if (componentType instanceof Class) {
                    return Array.newInstance((Class<?>) componentType, 0).getClass();
                }
            }
            if (actualTypeParam instanceof TypeVariable) {
                // Resolved type parameter points to another type parameter.
                TypeVariable<?> v = (TypeVariable<?>) actualTypeParam;
                currentClass = thisClass;
                if (!(v.getGenericDeclaration() instanceof Class)) {
                    return Object.class;
                }

                parameterizedSuperclass = (Class<?>) v.getGenericDeclaration();
                typeParamName = v.getName();
                if (parameterizedSuperclass.isAssignableFrom(thisClass)) {
                    continue;
                } else {
                    return Object.class;
                }
            }

            return fail(thisClass, typeParamName);
        }
        currentClass = currentClass.getSuperclass();
        if (currentClass == null) {
            return fail(thisClass, typeParamName);
        }
    }
}

private static Class<?> fail(Class<?> type, String typeParamName) {
    throw new IllegalStateException(
            "cannot determine the type of the type parameter '" + typeParamName + "': " + type);
}
```

我把这段神奇的代码复制到了本地，自己写了一个例子试一下：

```java
public class ExceptionHandler<E extends RuntimeException> {

    public ExceptionHandler() {
        Class<?> c = find(this, ExceptionHandler.class, "E");
        System.out.println(c);
    }
}
```

```java
public class IllegalArgumentExceptionHandler extends ExceptionHandler<IllegalArgumentException> {
}
```

```java
public class ExceptionHandlerTest {

    public static void main(String[] args) {
        ExceptionHandler<IllegalArgumentException> handler = new IllegalArgumentExceptionHandler();
    }
}
```

配合 debugger 单步执行，我发现这段代码最关键的地方在于 `currentClass.getGenericSuperclass()` 这一句。原来从子类中可以获取父类的泛型类型。那么这意味着，在继承的场景可以实现获取真实泛型类型。而我刚才举的例子是方法泛型，这种场景下是拿不到的。

## 泛型信息的来源

那么，为什么只有在继承的场景可以获取真实泛型类型呢？

查阅资料，原来是父类的泛型签名保存在了字节码中。

用 javap 解码 `IllegalArgumentExceptionHandler.class` 文件，可以看到有一行：

```text
Signature: #12                          // Lcom/oceanbase/ocp/obsdk/exception/ExceptionHandler<Ljava/lang/IllegalArgumentException;>;
```

这里记录了这个类的泛型类型签名，包括真实的泛型类型 `java.lang.IllegalArgumentException`。`getGenericSuperclass()` 正是拿的这里的信息。

看来，在有继承的情况下，可以用这种方法来简化代码。

## 参考资料

+ https://stackoverflow.com/questions/42874197/getgenericsuperclass-in-java-how-does-it-work
