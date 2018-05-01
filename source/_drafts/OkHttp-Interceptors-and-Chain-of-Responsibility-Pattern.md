title: OkHttp 的 Interceptors 与责任链模式
tags: [Android, Java, 设计模式]
---

[OkHttp](http://square.github.io/okhttp/)是目前Android最流行的HTTP网络库。从Android 4.4开始，标准库`HttpURLConnection`的底层实现开始使用OkHttp。OkHttp + Retrofit目前是Android网络请求的主流选择。

OkHttp的源码有很多可以学习的地方，[这篇文章](https://publicobject.com/2016/07/03/the-last-httpurlconnection/)中介绍了OkHttp代码架构的进化过程。OkHttp当前的代码架构已经相当清晰。其中作为发送网络请求的核心的interceptors，是设计模式中[责任链模式(Chain-of-responsibility pattern)](https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern)的一个典型的应用。

## OkHttp 的基本用法

OkHttp使用`Request`和`Response`类对网络请求的输入输出进行建模，使用`Call`对网络请求的行为进行建模。

```Java
OkHttpClient client = new OkHttpClient();

Request request = new Request.Builder()  
    .url(url)
    .header("Accept", "text/html")
    .build();

Call call = client.newCall(request);

Response response = call.execute();  
int responseCode = response.code();  
```

### Interceptors

[Interceptor](https://github.com/square/okhttp/wiki/Interceptors)是OkHttp提供的一个强大的机制。用户使用Interceptor可以对网络请求(call)进行监控、重写或重试。用户通过实现`Interceptor`接口来创建一个interceptor。例如，下面是一个对request/response记录log的interceptor：

```Java
class LoggingInterceptor implements Interceptor {
  @Override public Response intercept(Interceptor.Chain chain) throws IOException {
    Request request = chain.request();

    long t1 = System.nanoTime();
    logger.info(String.format("Sending request %s on %s%n%s",
        request.url(), chain.connection(), request.headers()));

    Response response = chain.proceed(request);

    long t2 = System.nanoTime();
    logger.info(String.format("Received response for %s in %.1fms%n%s",
        response.request().url(), (t2 - t1) / 1e6d, response.headers()));

    return response;
  }
}
```

在创建OkHttp client的时候可以指定使用自定义的interceptors：

```Java
OkHttpClient client = new OkHttpClient.Builder()
    .addInterceptor(new LoggingInterceptor())
    .build();
```

正如interceptor的名字（拦截器）所表达的含义。它可以在网络请求的过程中“拦截”request或response，进行用户自定义的操作。

## Interceptors chain

然而，在OkHttp的内部实现中，interceptors并不仅仅是拦截器这么简单。实际上，OkHttp发送网络请求的一切核心功能，包括建立连接、发送请求、读取缓存等，都是通过interceptors来实现的。这些interceptors在运行的时候彼此协作，构成了一个interceptor chain。

下面我们结合OkHttp的源码理解interceptor chain的工作方式。无论是同步请求还是异步请求，OkHttp都会进入`getResponseWithInterceptorChain()`中：

```Java
Response getResponseWithInterceptorChain() throws IOException {
    // Build a full stack of interceptors.
    List<Interceptor> interceptors = new ArrayList<>();
    interceptors.addAll(client.interceptors());
    interceptors.add(retryAndFollowUpInterceptor);
    interceptors.add(new BridgeInterceptor(client.cookieJar()));
    interceptors.add(new CacheInterceptor(client.internalCache()));
    interceptors.add(new ConnectInterceptor(client));
    if (!forWebSocket) {
        interceptors.addAll(client.networkInterceptors());
    }
    interceptors.add(new CallServerInterceptor(forWebSocket));

    Interceptor.Chain chain = new RealInterceptorChain(interceptors, null, null, null, 0,
            originalRequest, this, eventListener, client.connectTimeoutMillis(),
            client.readTimeoutMillis(), client.writeTimeoutMillis());

    return chain.proceed(originalRequest);
}
```

通过传入`List<Interceptor>`，以及其他信息，得到了`chain`对象。调用`chain.proceed(Request)`得到`Response`。`chain.proceed()`所做的事情是这样的：

```Java
// Call the next interceptor in the chain.
RealInterceptorChain next = new RealInterceptorChain(interceptors, streamAllocation, httpCodec,
    connection, index + 1, request, call, eventListener, connectTimeout, readTimeout,
    writeTimeout);
Interceptor interceptor = interceptors.get(index);
Response response = interceptor.intercept(next);
```

得到当前的interceptor，并生成下一个`chain`对象。调用`interceptor.intercept(chain)`。而interceptor，正如上面`LoggingInterceptor`的例子所示，会反过来调用`chain.proceed()`。

实际上，`Chain`可以理解为interceptors的执行环境，其中`index`表示了从第i个interceptor开始是有效的。`Chain`类保证`Chain.proceed(Request)`一定能返回一个response对象。

## 参考文档

+ [The Last HttpURLConnection](https://publicobject.com/2016/07/03/the-last-httpurlconnection/)
+ [拆轮子系列：拆 OkHttp](https://blog.piasy.com/2016/07/11/Understand-OkHttp/)
