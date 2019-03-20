title: 使用 Monkey 向 Android 设备精确发送事件
date: 2019-03-20 16:35:01
tags: [Android]
---

[Monkey](https://developer.android.com/studio/test/monkey) 是一个 Android 设备（模拟器或真实设备）上的一个程序，可以产生大量随机的用户输入事件，如点击、触摸、手势等。因此 Monkey 可用于 UI 上的压力测试。例如，下面的命令会启动一个特定的 app 并发送 500 个随机的事件：

```Shell
adb shell monkey -p your.package.name -v 500
```

然而，Monkey 程序还有一个特殊的 `--port` 选项。当这个选项开启后，Monkey 会运行在 _Automated Network Control_ 模式下，可以精确地向 app 发送一些 [KeyEvent](https://developer.android.com/reference/android/view/KeyEvent.html) 和 [MotionEvent](https://developer.android.com/reference/android/view/MotionEvent)。这也提供了一种在 `adb shell input` 命令之外，程序性地发送用户事件的方法。经测试，Monkey 支持的用户事件比 `input` 命令的用户事件更细致一些。

如果你有 AOSP 源代码，可以在 `development/cmds/monkey/` 目录下找到 README.NETWORK.txt 文件，其中有说明 _Automated Network Control_ 协议的简单文档。或者你可以访问[这里](https://android.googlesource.com/platform/development/+/master/cmds/monkey/README.NETWORK.txt)。

下面简单概括一下文档内容：

## 建立连接

`monkey --port` 命令会让 monkey server 运行起来，并监听特定的端口：

```Shell
adb shell monkey --port 1080
```

那么我在 host 机器上就可以通过 TCP 连接来向 monkey server 发送命令。注意 monkey server 只会绑定 localhost。TCP 协议是 ADB 支持的，因此需要设置端口转发：

```Shell
adb forward tcp:1080 tcp:1080
```

这样就可以向 monkey server 发送命令了。

## 协议格式

不同的命令之间通过换行来分隔。对于正常完成的命令，monkey 会回复 OK；否则会回复 ERROR。如果命令有返回值，返回值会放在与 OK 或 ERROR 的同一行，以冒号分隔。ERROR 回复的返回值一般是错误消息。下面是一个请求-响应序列的例子：

```plain
key down menu
OK
touch monkey
ERROR: monkey not a number
getvar sdk
OK: donut
getvar foo
ERROR: no such var
```

<!-- more -->

## 命令列表

### wake

唤醒设备，以接收用户输入

### touch [down|up|move] x y

发送一个 [MotionEvent](https://developer.android.com/reference/android/view/MotionEvent)，模拟用户点击屏幕。x 和 y 是相对于左上角的坐标。如果要模拟滑动事件的话，可以先 touch down，然后 touch move，最后 touch up。

### tap x y

是 touch 命令的简化版，相当于一次 touch down 和一次 touch up。

### key [down|up] keycode

发送一个 [KeyEvent](http://developer.android.com/reference/android/view/KeyEvent.html)。keycode 既可以是文本也可以是整数值，例如 `KeyEvent.KEYCODE_MENU = 82`，那么发送 82 或者 "KEYCODE_MENU" 都可以。

### press keycode

是 key 命令的简化版，相当于一次 key down 和一次 key up。

### type string

模拟用户的键盘输入，通过生成 KeyEvent 来实现。

### flip [open|close]

模拟键盘的打开/关闭。