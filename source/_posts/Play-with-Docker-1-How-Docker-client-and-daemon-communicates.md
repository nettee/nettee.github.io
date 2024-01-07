title: 玩转 Docker（一）：“劫持” Docker server
date: 2021-01-23 20:01:36
tags: [docker]
---

本文是玩转 Docker 系列第一篇。本系列文章将通过一些好玩的方式探索 Docker 的内部原理。

## 小小的 docker.sock 文件，大大的学问

你在第一次装 Docker 的时候很可能会遇到下面的这个错误：

```text
docker: Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
```

这个问题解决的方法是把当前用户加入 docker 用户组：

```shell
sudo usermod -a -G docker $USER
```

你可能会觉得 `unix:///var/run/docker.sock` 这个文件名有点奇怪，但是并没有去深究它。实际上这个小小的文件，是 Docker 的 client 与 server 通信的必经之路。今天我们的玩转 Docker，就要从这个文件来入手。

### Docker client 与 Docker server

Docker 是一个 client-server 模式的架构。其中的 client，就是我们敲命令的 `docker` 命令；而 server，则是一个叫 `dockerd` 的守护进程。守护进程在后台一直运行，并开放 REST API。你在命令行敲 `docker` 命令的时候，它会调用守护进程开放的接口，其他的工作就交给守护进程来做。

我们可以用 `docker context ls`，查看当前 `docker` 是调用哪里的 REST API：

```shell
$ docker context ls
NAME                TYPE                DESCRIPTION                               DOCKER ENDPOINT               KUBERNETES ENDPOINT   ORCHESTRATOR
default             moby                Current DOCKER_HOST based configuration   unix:///var/run/docker.sock                         swarm
```

可以看到，当前的 default context，它的 DOCKER ENDPOINT 是 `unix:///var/run/docker.sock`，这就是 docker server 开放的接口的地址。

但是，这个地址是什么意思呢？为什么不是我们熟悉的 _ip:port_ 格式呢？实际上，这是 TCP 之外的另外一种协议，叫做 Unix socket。

### Unix socket

提到 REST API，我们知道它一定是 HTTP 协议。一般我们接触到的 HTTP 协议，都是 "HTTP over TCP"，也就是 HTTP 的底层协议是 TCP。TCP 的 socket 的格式，就是我们熟悉的 _ip:port_，例如 `127.0.0.1:8080`。

不过一般情况下，我们的 docker server 都是运行在本机，socket 的 IP 是 localhost。这时候，还用 TCP 协议来通信的话，感觉是“大炮打蚊子”了。因为本机通信一般比较稳定，不会有丢包等各种情况，TCP 的大部分特性是没有太多用处的。

这个时候，我们就可以搬出另一个 socket 出来了，那就是 **Unix socket**。

Unix socket 实际上是一个进程间通信（IPC）的协议，只不过它用起来特别像 TCP，我们可以用 TCP 网络编程类似的方法来用 Unix socket。相比于 TCP socket 用 IP 加上端口来标识，Unix socket 就是用一个普通文件来标识，比如这里的 `unix:///var/run/docker.sock`。

HTTP 其实并不要求底层的协议是 TCP，它只需要底层的协议是一个全双工的、流式的、可靠的协议就可以。Unix socket 也满足这些特性，那么如果 Docker server 放在本机，我们也可以用 HTTP + Unix socket 来进行通信。

## 自己写一个 HTTP + Unix socket 的 server

既然 Unix socket 可以作为 HTTP 的底层协议，我们就尝试用网络编程写一写 Unix socket，看看怎么把它用在 HTTP 上。

<!-- more -->

### 一个最简单的 server

我们可以用 Go 语言写一个非常简单的底层使用 Unix socket 的 HTTP server。这里选用 Go 语言，是因为 Go 语言写 HTTP server 特别简单，而且 Docker 也是用 Go 语言写的。

```go
package main

import (
    "fmt"
    "net"
    "net/http"
    "os"
)

type HttpHandler struct {
}

func (handler HttpHandler) ServeHTTP(response http.ResponseWriter, request *http.Request) {
    fmt.Fprintf(response, "hello, world")
}

func serve(sockFile string) {
    // 在创建 Unix socket 之前，需要保证 demo.sock 文件不存在
    _ = os.Remove(sockFile)

    listener, _ := net.Listen("unix", sockFile)
    http.Handle("/", HttpHandler{})
    _ = http.Serve(listener, nil)
}

func main() {
    sockFile := "/tmp/demo.sock"
    serve(sockFile)
}
```

这个简单的 server 只是监听了 /tmp/demo.sock 文件，然后对所有的请求返回 "hello, world"。

用 `go run` 运行代码以后，我们可以用 `curl` 命令来测试 server 的行为：

```shell
$ curl --unix-socket /tmp/demo.sock http://localhost
hello, world
```

### 在 Unix socket 和 TCP socket 之间切换

在上面的代码中，创建 Unix socket 的一行语句是：

```go
listener, _ := net.Listen("unix", sockFile)
```

这里的字符串 "unix" 指定了 socket 的类型是 Unix socket。实际上，我们可以把它换成 "tcp"，这样就变成了创建常见的 TCP socket：

```go
listener, _ := net.Listen("tcp", "127.0.0.1:9000")
```

我们同样可以用 `curl` 命令来测试这时候的 server 的行为：

```shell
$ curl http://localhost:9000
hello, world
```

## 劫持 Docker server

既然我们是可以写出一个 HTTP + Unix socket 的 server，那 Docker client 和 server 的通信方式就不是什么秘密了。我们可以自己写一个 Docker server，然后劫持 Docker client 的请求，看看是什么效果。

首先我们要创建一个新的 docker context，让 `docker` 命令的请求发到另一个地址，而不是默认的 `unix:///var/run/docker.sock`：

```shell
$ docker context create dogger --docker host=unix:///tmp/dogger.sock
$ docker context use dogger
$ docker context ls
NAME                TYPE                DESCRIPTION                               DOCKER ENDPOINT               KUBERNETES ENDPOINT   ORCHESTRATOR
default             moby                Current DOCKER_HOST based configuration   unix:///var/run/docker.sock                         swarm
dogger *            moby                                                          unix:///tmp/dogger.sock
```

可以看到，我们创建了一个叫 dogger 的 docker context，然后让 docker 默认使用这个 context。这样，docker client 的命令就会发往 `/tmp/dogger.sock` 了。接下来我们运行一个 server，监听 `/tmp/dogger.sock`：

```go
package main

import (
    "fmt"
    "net"
    "net/http"
    "os"
)

type HttpHandler struct {
}

func (handler HttpHandler) ServeHTTP(response http.ResponseWriter, request *http.Request) {
    fmt.Printf("> %v %v\n", request.Method, request.URL)
    fmt.Printf("%v\n", request.Body)
    _, _ = fmt.Fprintf(response, "hello, docker\n")
}

func serve(sockFile string) {
    fmt.Printf("listen to %v...\n", sockFile)

    _ = os.Remove(sockFile)
    listener, _ := net.Listen("unix", sockFile)
    http.Handle("/", HttpHandler{})
    _ = http.Serve(listener, nil)
}

func main() {
    sockFile := "/tmp/dogger.sock"
    serve(sockFile)
}
```

我们创建了一个 server 监听 `/tmp/dogger.sock`，并打印所有请求的 method、url 和 body，然后返回 "hello, docker"。运行 `go run` 启动 server。

接下来，我们执行一个简单的 docker 命令，比如 `docker ps`：

```shell
$ docker ps
invalid character 'h' looking for beginning of value
```

可以看到，docker ps 返回的结果变化了。这里报错是因为 docker client 试图把我们返回的 "hello, docker" 解析成 JSON 而报错。

再看 server 下面的输出：

```text
listen to /tmp/dogger.sock...
> HEAD /_ping
{}
> GET /v1.24/containers/json
{}
```

可以看到，docker client 发来了请求，URL 是 `/v1.24/containers/json`。Cool！这样，我们就做到了“劫持” Docker server。Docker client 的返回内容，我们可以自己控制了。
