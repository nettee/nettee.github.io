title: 如何手写一个简单的 parser
date: 2019-08-04 09:32:24
tags: [Compiler, Java]
---

前一阵子，收到烨兄的私聊，他突然要解决这样一个任务：

> 做如下格式的表达式转换：
>
> + `Multi(a, Multi(b, c))  -->  a * (b * c)`
> + `Divide(a, Sub(b, c))  --> a / (b - c)`
> 
> 支持的运算符有：
> 
> + `Add`: +
> + `Sub`: -
> + `Multi`: *
> + `Divide`: /

而且好死不死的需要用他没怎么用过的 C++ 来写。我发现这是一个 parser 的问题，第一反应是推荐他用 flex/bison，但想到为了这么大点任务大费周章不太合适，又开始想手写这样一个表达式的 parser 难不难。最后得出的结论是，不难。

了解编译原理的人都知道什么是 parser。Parser 中文名（语法）分析器，是每个编译器的前端都会有的一个东西。不过，从编译原理的视角来看，“语言”的范畴要比我们理解的编程语言要广义得多，任何有一定规则的字符串构成方式，都可以看成是语言，例如上面的那个任务里用 `Add`、`Sub` 这样的函数描述的表达式。

那么，要解决上面这个任务，只需要对表达式的字符串进行语法分析，得到一个中间表示（一般是分析树或抽象语法树），再将中间表示输出为所需的格式即可。也就是说我们需要为表达式提供一个 parser，这个任务的任何解决方式，本质上都可以看成是写了一个 parser。

<!-- more -->

在平时，我们完全没有任何必要去手写一个 parser，因为这东西已经有工具可以为我们生成。感谢几十年前伟大的程序员就已经发明了这样的工具。我用过的有 C/C++ 的 flex/bison，以及 Java 的 ANTLR。你只需要提供一个文法描述，这些工具就可以为你自动生成对应的语法分析器。如果要手写分析器，会很复杂，也很容易出错，不是一个明智的选择。

不过，面对上面举例的这种小任务，使用自动生成 parser 的工具有时候显得太重了，这时候也许手写一个 parser 是更好的选择。而且在这样的任务场景下，我们的 parser 有两个地方起码是可以得到大大简化的：

第一，我们要处理的语言应该不会像通用编程语言那样，有很复杂的状态转移。通常情况下，应该能看到当前的字符串就知道下面要分析什么类型的内容。一般标记语言都会是这种风格的，比如：

+ XML/HTML：看到 `<tag>` 就知道是一个标签的开始，直到 `</tag>` 为止
+ CSS：选择器后的声明，总是用花括号括起来，每一条声明以 `;` 分隔
+ Markdown：一行以 `#` 开头就是标题，以 `1.` 开头就是有序列表项

第二，我们不需要进行复杂的语法错误处理，只需要报“语法错误”就好了，而不需要费力说明到底发生了什么错误。

有了这两个前提，我们开始思考如何手写一个语法分析器。当然，我已经思考好了，下面是我给出的一个简单的分析器的实现。我是用 Java 实现的，用到了一点 lambda 表达式的语法，不过不难理解。因为 parser 的主要工作是做字符串比较，所以用任何语言都差不多。后面我会考虑再用其他语言实现。

在实现上我们再做一点简化：我们把要分析的字符串作为字符数组保存下来，而不是从所谓“字符流”中读入。这样我们不必考虑读 (get) 了字符却不用掉 (consume) 的情况下，这些是输入模块要考虑的部分，我们专注于 parser 本身。

首先，我们的 `SimpleParser` 是这样定义的：

```Java
public class SimpleParser {

    private char[] input;
    private int pos;

    public SimpleParser(String source) {
        this.input = source.toCharArray();
        this.pos = 0;
    }
}
```

我们将输入保存为字符数组，`pos` 是一个指向待读取的下一个字符的指针。将 `pos` 加一，就相当于从读入了一个字符。

下面，我们添加一些脚手架函数：

```Java
private void consumeWhitespace() {
    consumeWhile(Character::isWhitespace);
}

private String consumeWhile(Predicate<Character> test) {
    StringBuilder sb = new StringBuilder();
    while (!eof() && test.test(nextChar())) {
        sb.append(consumeChar());
    }
    return sb.toString();
}

private char consumeChar() {
    return input[pos++];
}

private boolean startsWith(String s) {
    return new String(input, pos, input.length - pos).startsWith(s);
}

private char nextChar() {
    return input[pos];
}

private boolean eof() {
    return pos >= input.length;
}
```

这些函数的来源于我之前看过的一个系列文章：[Let's build a browser engine!](https://limpet.net/mbrubeck/2014/08/08/toy-layout-engine-1.html)（原文是用 Rust 语言的）。我们来看一下这几个函数：

其中，`nextChar`, `startsWith` 这两个函数是用来“向后看”，判断后面输入的状态。这实际上已经和编译原理中说的语法分析不太一样了（回忆一下，编译原理中说的语法分析方法只会向后看一个字符），但是因为我们只是判断是不是等于一个固定的字符串，所以也不是太大的问题。

以 `consume...` 开头的几个函数就是真正的读取输入的函数了。其中，`consumeWhile` 是一个通用的函数，`consumeWhitespace` 也是基于其实现的。类似地，我们还可以基于其实现解析变量名的函数：

```Java
private String parseVariableName() {
    return consumeWhile(Character::isAlphabetic);
}
```

注意到这实际上就是在解析我们任务中的变量名了，以此为思路，后面的实现其实很简单。我们一上来会觉得手写 parser 会很复杂，实际上是因为没找到入手点。所以这几个脚手架函数特别重要，先有了他们，后面就可以一步一步写出整个 parser 的功能了。

那么我们接下来可以这么写：

```Java
// 解析由单个变量组成的表达式
private VariableExpression parseVariableExpression() {
    String name = parseVariableName();
    // VariableExpression 的定义略
    return new VariableExpression(name);
}
```

```Java
// 解析加减乘除表达式
private CompoundExpression parseCompoundExpression(String name) {
    for (char c : name.toCharArray()) {
        checkState(c == consumeChar());
    }
    checkState('(' == consumeChar());
    // 递归解析
    Expression left = parseExpression();
    checkState(',' == consumeChar());
    consumeWhitespace();
    Expression right = parseExpression();
    checkState(')' == consumeChar());
    // CompoundExpression 的定义略
    return new CompoundExpression(name, left, right);
}

// VariableExpression 和 CompoundExpression 都是 Expression
private Expression parseExpression() {
    if (startsWith("Add")) {
        return parseCompoundExpression("Add");
    } else if (startsWith("Sub")) {
        return parseCompoundExpression("Sub");
    } else if (startsWith("Multi")) {
        return parseCompoundExpression("Multi");
    } else if (startsWith("Divide")) {
        return parseCompoundExpression("Divide");
    } else {
        return parseVariableExpression();
    }
}
```

写到这里，我们 parser 的主要工作已经做完了，接下来的任务就非常简单了。似乎我们的任务有点太简单了？在这种场景下，手写 parser 确实不难，接下来可以手写一个 Markdown 的 parser 练习一下了😜。

P.S. 烨兄后来并没有做这个任务，我也是到现在才想起来把这个 parser 实现出来，只是我自己觉得好玩想了这件事。

文章中的 parser 的完整代码，可以到我的 GitHub 上查看：[simpleparser](https://github.com/nettee/simpleparser)。
