title: Java 的虚拟线程为什么设计成这样？
tags: [Java]
---

Java 的主要思路还是尽量保持兼容性。

Java 8 中要想实现高并发的话：

1. 多路复用 IO，Java NIO
2. 异步，

简单的，就是 CompletableFuture（相当于 Promise，在 Java 的实现中叫做 CompletableFuture）

复杂的，就是 RxJava



于是继续发展，出现了 netty 框架（对 Java NIO 的封装，使用事件驱动的方式），

出现了 Spring WebFlux（将 Rx 引入 Spring Web 框架，底层使用的 netty 或者 servlet 3.1+ 来实现 IO 多路复用）。



这种实现高并发的方式，没有传统的同步方式编程容易理解，而且引入了之后，跟已有的代码和库不能很好地融合（比如 webflux 就不能跟 JDBC 一起使用）。



很多语言选择了 async/await 方式（Kotlin，JavaScript，C++），在异步语法的基础上增加语法糖。

最终 Java 选择了类似 Go 语言的实现方法：用户级线程


如何迁移？也不是完全的平滑迁移，代码还是需要做一些改造的。

1. 改造创建线程的方式
2. synchorized 改造
3. thread local 改造


