title: GDB 自动化调试
date: 2018-06-05 17:15:35
tags:
---

我们通常都是在交互模式下使用 GDB 的，即手动输入各种 GDB 命令。其实 GDB 也支持执行预先写好的调试脚本，进行自动化的调试。调试脚本由一系列的 GDB 命令组成，GDB 会顺序执行调试脚本中的命令。

编写调试脚本时必须要处理好断点的问题。在交互模式下，程序执行至脚本时，GDB 会等待用户输入下一步的命令。如何在脚本中定义断点触发时进行的操作？这需要一种类似回调函数的机制。

GDB 中使用 **Breakpoint Command Lists** 的机制来实现这一点。用户可以定义，当程序停在某个 breakpoint (或 watchpoint, catchpoint) 时，执行由 `command-list` 定义的一系列命令。其语法为：

```gdb
commands [list…]
… command-list …
end
```

例如，我想在每次进入 `foo` 函数且其参数 `x` > 0 时打印 `x` 的值：

```gdb
break foo if x>0
commands
silent
printf "x is %d\n",x
continue
end
```

这里有几点要注意的：

+ Breakpoint command list 中的第一个命令通常是 `silent`。这会让断点触发是打印的消息尽量精简。如果 `command … end` 中没有 `printf` 之类的打印语句，断点触发时甚至不会产生任何输出。
+ Breakpoint command list 中的最后一个命令通常是 `continue`。这样程序不会在断点处停下，自动化调试脚本可以继续执行。

GDB 运行自动化调试脚本的方式为：

```Shell
gdb [program] -batch -x [commands_file] > log
```

其中 `-batch` 参数将 GDB 运行为脚本模式（不进入交互环境），`-x` 参数 (也可以写为 `-command`) 指定调试脚本文件。

## 参考资料

+ [GDB User Manual](https://sourceware.org/gdb/current/onlinedocs/gdb/)
+ [GDB 自动化操作的技术](https://segmentfault.com/a/1190000005367875)
