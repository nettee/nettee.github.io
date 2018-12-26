# Java 8：事实上的多继承语言

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

然而，如果直接在 `Iterable` 接口中添加 `forEach` 方法。在 Java 7 及以前的所有实现 `Iterable` 的类都无法使用 JDK 8 编译。为了向后兼容已有的代码，Java 8 引入了 `default` 关键字以及 default method，用来在接口中定义一个有方法体的方法。通过定义一个 default 的 `forEach`。所有实现了 `Iterable` 的类无需修改代码，便可在对象上调用 `forEach`。

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

Java 在设计之初，将 interface 设计成“没有任何实现”的纯接口，以此来避免接口多继承可能导致的问题。例如，

## 参考资料

+ [James Gosling on Java, May 1999](https://www.artima.com/intv/gosling13.html)