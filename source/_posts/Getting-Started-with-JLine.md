title: Java 命令行交互输入库 JLine 入门
date: 2018-09-03 15:04:00
tags: [Java]
---

我们都知道，软件的用户界面无非分为 GUI （图形用户界面）和 CLI （命令行用户界面）。对于我们经常使用 Linux 的人来说，命令行界面一定非常熟悉。无论是 Shell 里输入命令的界面，还是如 GDB 等软件的内部交互界面，都是命令行界面。而当我们开发自己的软件，要写认真写一个 CLI 的时候，却发现要手写做出一个好用的命令行界面其实非常困难。因为一个好的命令行界面，在输入/输出之外，还要支持一些常见的命令行功能。

对我而言，一个合格的命令行软件界面应该支持这三个功能：

+ 自动补全：当按下 TAB 键时，在当前光标处进行内容补全。根据上下文信息，补全可能是对命令的补全，也可能是对文件路径的补全。
+ 命令历史：当按上/下方向键时，可以显示上一条/下一条命令。
+ 行编辑 (line editing)：可以使用 Emacs 快捷键进行行内的编辑功能，例如 Ctrl+A 移动光标至行首，Ctrl+E 移动光标至行尾。

熟悉 Linux 的人会发现，上面这三个功能都是 [GNU Readline][GNU readline] 的功能。我们不需要在软件中手写这几个功能，只要用这样一个库就可以了。实际上，GNU/Linux 中使用 GNU Readline 库的软件非常多，这使得 GNU Readline 同时也成为了一个事实上的命令行交互标准。GNU Readline 是 C 语言的库。我们用其他语言的时候，就要找对应功能的库（这往往是封装了底层的 GNU Readline 的库）。对 Java 语言来说，[JLine][jline3] 就是这样一个帮助你搭建一个命令行交互界面的库。

本文是想通过一个例子介绍 JLine3 的基本用法。JLine3 并没有一个 "Hello, world!" 的例子，它的 [wiki][wiki] 也写得非常简略。虽然有一个示例的程序 [Example.java][jline example]，但这个示例比较复杂，难以理解。希望本文的内容能对你理解 JLine3 的用法有所帮助。

## 基本框架

我们尝试为软件 Fog 设计一个命令行用户界面。用户可以输入四种命令：

```
CREATE [FILE_NAME]
OPEN [FILE_NAME] AS [FILE_VAR]
WRITE TIME|DATE|LOCATION TO [FILE_VAR]
CLOSE [FILE_VAR]
```

<!-- more -->

下面我们将一步步地写出 Fog 软件的命令行界面。首先，用 JLine3 搭建一个最基础的 REPL (Read-Eval-Print Loop) 框架：

```Java
Terminal terminal = TerminalBuilder.builder()
        .system(true)
        .build();

LineReader lineReader = LineReaderBuilder.builder()
        .terminal(terminal)
        .build();

String prompt = "fog> ";
while (true) {
    String line;
    try {
        line = lineReader.readLine(prompt);
        System.out.println(line);
    } catch (UserInterruptException e) {
        // Do nothing
    } catch (EndOfFileException e) {
        System.out.println("\nBye.");
        return;
    }
}
```

这里除了设置命令提示符 (prompt)，没有进行任何特殊的设置。命令行会将用户输入的一行原样打印出来。当用户输入 Ctrl+D (End of line) 时，程序会退出。

即使我们只写了一个框架，但此时程序已经拥有了 JLine3 默认提供的命令历史和行编辑功能。此时按上/下方向键时，会显示上一条/下一条命令，也可以使用 Ctrl+A、Ctrl+E 等 Emacs 快捷键进行行内编辑。

## 命令补全

### 简单补全与复合补全

由于命令补全和程序的命令格式密切相关，所以我们必须自己定义补全的方式。根据 [wiki][wiki] 中所写，JLine3 中定义命令补全的方式是：创建一个 `Completer` 类的实例，将其传入 `LineReader`。JLine3 内置了多个 completer，其中最常见的是 `FileNameCompleter` （补全文件名）和 `StringsCompleter` （根据预定义的几个字符串进行补全，用于命令名或参数名）。例如，Fog 程序的四个命令分别以 CREATE, OPEN, WRITE, CLOSE 开头，那么我们可以使用一个 `StringsCompleter` 来对命令的第一个单词进行补全：

```Java
Completer commandCompleter = new StringsCompleter("CREATE", "OPEN", "WRITE", "CLOSE");

LineReader lineReader = LineReaderBuilder.builder()
        .terminal(terminal)
        .completer(commandCompleter)
        .build();
```

然而，这种补全方式只能支持每个命令的第一个单词，我们想要在命令的各种可能的地方都进行补全该怎么办呢？这时候就需要将 completer 进行组合，形成 **复合 completer** 。一般情况下，`StringsCompleter` 这样的 **简单 completer** 只能负责一个单词的补全，而要想实现整条命令的补全，就需要将几个不同的 completer 组合起来使用。`ArgumentCompleter` 就是用来补全整条命令的复合 completer。它可以将若干个 completer 组合在一起，每个 completer 负责补全命令中的第 i 个单词。以 CREATE 命令为例，这条命令共有两个单词，第一个单词需要字符串补全，第二个单词需要文件名补全。于是我们使用 `ArgumentCompleter` 将 `StringsCompleter` 和 `FileNameCompleter` 组合起来：

```Java
Completer createCompleter = new ArgumentCompleter(
        new StringsCompleter("CREATE"),
        new Completers.FileNameCompleter()
);

LineReader lineReader = LineReaderBuilder.builder()
        .terminal(terminal)
        .completer(createCompleter)
        .build();
```

根据 `ArgumentCompleter` 的两个参数，在输入第一个单词的时候会补全 CREATE，输入第二个单词的时候会补全文件名。但实测时会发现一个问题：当你已经输入了 CREATE 和文件名后，再试图进行补全，在第三个单词处试图补全，还是会出现文件名的补全。这是因为，`ArgumentCompleter` 在你已经“用完了”所有的 completers 之后（即第三个单词开始），会默认使用最后一个 completer。这并不是我们想要的效果。为了解决这个问题，我们可以在最后添加一个 `NullCompleter`：

```Java
Completer createCompleter = new ArgumentCompleter(
        new StringsCompleter("CREATE"),
        new Completers.FileNameCompleter(),
        NullCompleter.INSTANCE
);

LineReader lineReader = LineReaderBuilder.builder()
        .terminal(terminal)
        .completer(createCompleter)
        .build();
```

`NullCompleter` 即不进行任何补全。这样，从第三个单词开始，都不会进行任何多余的补全。

类似地，我们再加入 OPEN 命令补全的定义：

```Java
Completer createCompleter = new ArgumentCompleter(
        new StringsCompleter("CREATE"),
        new Completers.FileNameCompleter(),
        NullCompleter.INSTANCE
);

Completer openCompleter = new ArgumentCompleter(
        new StringsCompleter("OPEN"),
        new Completers.FileNameCompleter(),
        new StringsCompleter("AS"),
        NullCompleter.INSTANCE
);

Completer fogCompleter = new AggregateCompleter(
        createCompleter,
        openCompleter
);

LineReader lineReader = LineReaderBuilder.builder()
        .terminal(terminal)
        .completer(fogCompleter)
        .build();
```

这里有两点需要注意的地方：

1. CREATE 命令和 OPEN 命令分别定义了 completer，再用 `AggregateCompleter` 组合起来。`AggregateCompleter` 是另一种复合 completer，将多种可能的补全方式组合到了一起。打比方来说，`ArgumentCompleter` 相当于串联电路，而 `AggregateCompleter` 相当于并联电路。
2. OPEN 命令的 `ArgumentCompleter` 中只定义了前三个单词的补全方式。这是因为第四个单词是用户定义了文件变量，用户可能输入任何的名字，因此无法进行补全。

### 动态补全

WRITE 命令的补全与前两个稍有不同。根据程序语义，只有用户在 OPEN 命令中定义了的文件变量才能在 WRITE 命令中使用。那么，在补全的时候也应该考虑这一点。我们需要在运行时动态地调整补全候选词：每当用户使用 OPEN 命令打开一个文件后，都调整 completer，将新的文件变量纳入补全候选词。我们需要知道如何动态地修改 completer。虽然 completer 的创建和传递给 `LineReader` 的过程是静态的，但在程序运行时，是通过调用 `Completer.complete()` 来获取补全的候选词的。那么，我们可以继承 `Completer` 并重写 `complete()` 方法来实现动态的候选词调整。

```Java
public class FileVarsCompleter implements Completer {

    Completer completer;

    public FileVarsCompleter() {
        this.completer = new StringsCompleter();
    }

    @Override
    public void complete(LineReader reader, ParsedLine line, List<Candidate> candidates) {
        completer.complete(reader, line, candidates);
    }

    public void setFileVars(List<String> fileVars) {
        this.completer = new StringsCompleter(fileVars);
    }
}
```

当调用 `setFileVars()` 时，会重新创建一个新的 `StringsCompleter`，从而扩充候选词。而在 REPL 中，只需要在用户输入 OPEN 命令后，调用 `setFileVars()` 即可。

```Java
public class Fog {

    private static List<String> fileVars = new ArrayList<>();
    private static FileVarsCompleter fileVarsCompleter = new FileVarsCompleter();

    public static void main(String[] args) throws IOException {

        // ...

        Completer writeCompleter = new ArgumentCompleter(
                new StringsCompleter("WRITE"),
                new StringsCompleter("TIME", "DATE", "LOCATION"),
                new StringsCompleter("TO"),
                fileVarsCompleter,
                NullCompleter.INSTANCE
        );

        Completer fogCompleter = new AggregateCompleter(
                createCompleter,
                openCompleter,
                writeCompleter
        );

        // ...

        String prompt = "fog> ";
        while (true) {
            String line;
            try {
                line = lineReader.readLine(prompt);
                System.out.println(line);
                if (line.startsWith("OPEN")) {
                    fileVars.add(line.split(" ")[3]);
                    fileVarsCompleter.setFileVars(fileVars);
                }
            } catch (UserInterruptException e) {
                // Do nothing
            } catch (EndOfFileException e) {
                System.out.println("\nBye.");
                return;
            }
        }
    }
}
```

## 命令历史

前面已经过说，在默认情况下，JLine3 已经支持命令历史查找。不过我们想加上一个特殊的功能：用户输入的注释（以 # 开头）不会进入命令历史，从而在命令历史查找时不受注释内容的干扰。

JLine3 中，`History` 负责控制历史记录的行为，其默认实现为 `DefaultHistory`。查看源代码，我们发现 `add()` 方法是其核心行为。用户输入的一行命令，会通过 `add()` 方法加入命令历史中。

```Java
@Override
public void add(Instant time, String line) {
    Objects.requireNonNull(time);
    Objects.requireNonNull(line);

    if (getBoolean(reader, LineReader.DISABLE_HISTORY, false)) {
        return;
    }

    // ...

    internalAdd(time, line);

    // ...
}
```

同样地，我们可以通过继承并重写 `add()` 方法，将注释内容过滤掉，不加入命令历史：

```Java
public final class FogHistory extends DefaultHistory {

    private static boolean isComment(String line) {
        return line.startsWith("#");
    }

    @Override
    public void add(Instant time, String line) {
        if (isComment(line)) {
            return;
        }
        super.add(time, line);
    }
}
```

然后我们这样设置 `LineReader`：

```Java
LineReader lineReader = LineReaderBuilder.builder()
        .terminal(terminal)
        .completer(fogCompleter)
        .history(new FogHistory())
        .build();
```

## 总结

我们发现，JLine3 的各个功能设计得比较清晰，有其对应的接口和默认实现。如果我们想自定义一些特性，一般通过继承并重写的方式可以做到。JLine3 的源代码也比较容易理解，遇到困难时，可以自己阅读源代码来寻找线索。

本文中示例程序的完整代码参见 [jline3-demo](https://github.com/nettee/jline3-demo)。

[jline3]: https://github.com/jline/jline3
[jline example]: https://github.com/jline/jline3/blob/master/builtins/src/test/java/org/jline/example/Example.java
[wiki]: https://github.com/jline/jline3/wiki
[GNU readline]: https://en.wikipedia.org/wiki/GNU_Readline
