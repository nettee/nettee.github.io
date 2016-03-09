title: Python Argparse Tutorial 翻译
date: 2015-12-09 12:49:58
tags: [Python, 翻译]
---

本文翻译自Python官方documentation, Python 版本 3.3

原文：[Argparse Tutorial](http://docs.python.org/3/howto/argparse.html#id1)

翻译：[nettee](http://nettee.github.io)

---

这份教程是对 `argparse` 的简要介绍, `argparse` 是 Python 标准库中推荐使用的命令行解析模块.

注意: 与 `argparse` 完成相同任务的模块还有 `getopt` (与C语言中的 `getopt()` 函数用法相同)和已经被废弃的 `optparse`. 另外 `argparse` 是以 `optparse` 为基础的,因此二者在用法方面很相似.

## 一些概念

让我们通过使用 **ls** 命令来展示在入门指引中我们将要探讨的命令行解析功能:

<!--more-->

	$ ls
	cpython  devguide  prog.py  pypy  rm-unused-function.patch
	$ ls pypy
	ctypes_configure  demo  dotviewer  include  lib_pypy  lib-python ...
	$ ls -l
	total 20
	drwxr-xr-x 19 wena wena 4096 Feb 18 18:51 cpython
	drwxr-xr-x  4 wena wena 4096 Feb  8 12:04 devguide
	-rwxr-xr-x  1 wena wena  535 Feb 19 00:05 prog.py
	drwxr-xr-x 14 wena wena 4096 Feb  7 00:59 pypy
	-rw-r--r--  1 wena wena  741 Feb 18 01:01 rm-unused-function.patch
	$ ls --help
	Usage: ls [OPTION]... [FILE]...
	List information about the FILEs (the current directory by default).
	Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.
	...
	 

我们从这四条命令中可以看出几点概念:

+ **ls** 命令在不加选项时可以直接运行,它默认打印出当前目录下的内容.

+ 如果想实现默认以外的功能,就要多给 ls 一个参数.在第二条命令中,我们想让它打印出 `pypy` 目录下的内容,这时就要指明"位置参数".程序对命令行参数的处理取决于参数在命令行上出现的位置.这个概念在 **cp** 命令的使用中体现得更明显, 它的基本用法是 `cp SRC DEST`. 第一个参数是你要复制的东西,第二个参数是要复制到的目标位置.

+ 在第三条命令中,我们想要改变程序的行为,于是我们让 **ls** 打印出每个文件的详细信息,而不仅是文件名.这时的 `-l` 就是可选参数.

+ 第四条命令是让显示一段帮助信息.在你从来没有用过一个命令的时候,这是非常有用的,我们简单地通过查看帮助文字就可以明白一个命令是怎样工作的.

## 基础知识

让我们从一个非常简单的例子开始,下面这段代码几乎什么都不做:

	import argparse
	parser = argparse.ArgumentParser()
	parser.parse_args()
 

程序的运行结果如下:

	$ python3 prog.py
	$ python3 prog.py --help
	usage: prog.py [-h]
	
	optional arguments:
	  -h, --help  show this help message and exit
	$ python3 prog.py --verbose
	usage: prog.py [-h]
	prog.py: error: unrecognized arguments: --verbose
	$ python3 prog.py foo
	usage: prog.py [-h]
	prog.py: error: unrecognized arguments: foo
 

解释一下每次程序都做了什么:

+ 不加任何选项就运行,结果什么都没有打印到标准输出.这没啥意思.

+ 第二条命令已经开始体现出 argparse 模块的优势了:即使我们什么都没做,也能自动显示出漂亮的帮助信息.

+ `--help` 选项(或缩写 `-h`),是唯一被自动添加的选项.在命令中给出任何其他的选项都会导致错误.

## 必选参数

一个例子:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("echo")
	args = parser.parse_args()
	print(args.echo)
 

运行结果:

	$ python3 prog.py
	usage: prog.py [-h] echo
	prog.py: error: the following arguments are required: echo
	$ python3 prog.py --help
	usage: prog.py [-h] echo
	
	positional arguments:
	  echo
	
	optional arguments:
	  -h, --help  show this help message and exit
	$ python3 prog.py foo
	foo
	 

解释一下程序做了什么:

+ `add_argument()` 方法用来添加我们想要的选项.在例子中,我们添加了一个叫 `echo` 的选项.

+ 现在运行程序必须指定一个参数

+ `parse_args()` 方法返回一些参数中指明的数据，比如例子中的 `echo`.

+ `args.echo` 是一个"有魔力"的变量,即我们不需要指定在 `echo` 参数位置上的值用什么变量来存储，argparse 自动创建一个和参数名相同名字的变量，作为 `parse_args()` 返回值的方法.

注意到,虽然帮助信息看起来漂亮齐全,但其实它并不够有用.我们通过帮助可以知道有一个叫 `echo` 的位置参数，但不能从帮助信息中得知它的作用.下面做一点小的改动:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("echo", help="echo the string you use here")
	args = parser.parse_args()
	print(args.echo)
 
然后结果变成这样：

	$ python3 prog.py -h
	usage: prog.py [-h] echo
	
	positional arguments:
	  echo        echo the string you use here
	
	optional arguments:
	  -h, --help  show this help message and exit
 
让我们做些更有用的东西:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("square", help="display a square of a given number")
	args = parser.parse_args()
	print(args.square**2)

运行结果如下:

	$ python3 prog.py 4
	Traceback (most recent call last):
	  File "prog.py", line 5, in <module>
	    print(args.square**2)
	TypeError: unsupported operand type(s) for ** or pow(): 'str' and 'int'
 
出了点问题.这是因为,除非另外说明, argparse 把我们传给它的参数当成字符串类型.那么,我们可以告诉 argparse 把输入作为整数类型对待:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("square", help="display a square of a given number",
	                    type=int)
	args = parser.parse_args()
	print(args.square**2)

下面是运行结果:

	$ python3 prog.py 4
	16
	$ python3 prog.py four
	usage: prog.py [-h] square
	prog.py: error: argument square: invalid int value: 'four'

这样就对了. 现在程序不仅能对正确的输入给出正确的结果,还能对错误的输入及时给出有用的提示并退出. 

## 可选参数

现在我们已经可以添加必选参数了.下面我们来看一下可选参数是怎么添加的:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("--verbosity", help="increase output verbosity")
	args = parser.parse_args()
	if args.verbosity:
	    print("verbosity turned on")

结果是:

	$ python3 prog.py --verbosity 1
	verbosity turned on
	$ python3 prog.py
	$ python3 prog.py --help
	usage: prog.py [-h] [--verbosity VERBOSITY]
	
	optional arguments:
	  -h, --help            show this help message and exit
	  --verbosity VERBOSITY
	                        increase output verbosity
	$ python3 prog.py --verbosity
	usage: prog.py [-h] [--verbosity VERBOSITY]
	prog.py: error: argument --verbosity: expected one argument


解释一下发生了什么:

+ 这个程序在有 `--verbosity` 选项的时候输出一段话,在没有选项的时候就什么都不输出

+ 不加这个选项,程序也可以正常运行,证明了这个选项确实是可选的.注意到,在默认情况下,可选参数是不被使用的,这种情况下,选项对应的变量(本例中是 `args.verbosity`)被赋值为 `None`,这时它作为 `if` 语句中的条件表达式就会被认为是假.

+ 帮助信息和之前有一些不同.

+ 当使用 `--verbosity` 选项的时候,必须给定一个值,这个值可以是任意的.

上面的例子中,任意的整数值都可以被 `--verbosity` 接受,但是对于简单的程序来说,其实只要两个值就够了,那就是 `True` 和 `False`. 让我们修改代码来做到这一点:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("--verbose", help="increase output verbosity",
	                    action="store_true")
	args = parser.parse_args()
	if args.verbose:
	    print("verbosity turned on")

然后结果变成:

	$ python3 prog.py --verbose
	verbosity turned on
	$ python3 prog.py --verbose 1
	usage: prog.py [-h] [--verbose]
	prog.py: error: unrecognized arguments: 1
	$ python3 prog.py --help
	usage: prog.py [-h] [--verbose]
	
	optional arguments:
	  -h, --help  show this help message and exit
	  --verbose   increase output verbosity

这时候的情况是:

+ 现在这个选项不再需要一个值,而是变成了一个标志. 为了体现这一点,我们甚至把选项的名字改了. 现在我们指定了一个新关键字 `action`, 它的值是 `store_true`. 这意味着,如果用户给出了这个参数,就为 `args.verbose` 赋值 `True`, 否则赋值 `False`.

+ 这个选项确实是作为一个标志,如果你给它指定一个值,将会出错.

+ 帮助信息又有一些不同.

### 短选项

如果你对命令行的使用比较熟悉的话,你会发现有一个方面我们还没有涉及,那就是短选项.它实现起来很简单:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("-v", "--verbose", help="increase output verbosity",
	                    action="store_true")
	args = parser.parse_args()
	if args.verbose:
	    print("verbosity turned on")

运行结果:

	$ python3 prog.py -v
	verbosity turned on
	$ python3 prog.py --help
	usage: prog.py [-h] [-v]
	
	optional arguments:
	  -h, --help     show this help message and exit
	  -v, --verbose  increase output verbosity

注意到这个新功能在帮助文本里也反映了出来.

## 必选参数和可选参数的结合

我们继续让程序变得更复杂:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("square", type=int,
	                    help="display a square of a given number")
	parser.add_argument("-v", "--verbose", action="store_true",
	                    help="increase output verbosity")
	args = parser.parse_args()
	answer = args.square**2
	if args.verbose:
	    print("the square of {} equals {}".format(args.square, answer))
	else:
	    print(answer)

然后结果是:

	$ python3 prog.py
	usage: prog.py [-h] [-v] square
	prog.py: error: the following arguments are required: square
	$ python3 prog.py 4
	16
	$ python3 prog.py 4 --verbose
	the square of 4 equals 16
	$ python3 prog.py --verbose 4
	the square of 4 equals 16

+ 我们加回了一个必选参数,因此运行时什么参数都不给会出错

+ 注意必选参数和可选参数的顺序是无所谓的.

如果我们让程序可以处理多个 verbosity 级别,我们可以让 verbosity 选项拥有值,并且使用该值:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("square", type=int,
	                    help="display a square of a given number")
	parser.add_argument("-v", "--verbosity", type=int,
	                    help="increase output verbosity")
	args = parser.parse_args()
	answer = args.square**2
	if args.verbosity == 2:
	    print("the square of {} equals {}".format(args.square, answer))
	elif args.verbosity == 1:
	    print("{}^2 == {}".format(args.square, answer))
	else:
	    print(answer)

结果是:

	$ python3 prog.py 4
	16
	$ python3 prog.py 4 -v
	usage: prog.py [-h] [-v VERBOSITY] square
	prog.py: error: argument -v/--verbosity: expected one argument
	$ python3 prog.py 4 -v 1
	4^2 == 16
	$ python3 prog.py 4 -v 2
	the square of 4 equals 16
	$ python3 prog.py 4 -v 3
	16

除了最后一次运行之外都一切正常,这暴露出了我们程序中的一个 bug. 我们可以通过限制 `--verbosity` 选项可以接受的值来修正这个 bug:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("square", type=int,
	                    help="display a square of a given number")
	parser.add_argument("-v", "--verbosity", type=int, choices=[0, 1, 2],
	                    help="increase output verbosity")
	args = parser.parse_args()
	answer = args.square**2
	if args.verbosity == 2:
	    print("the square of {} equals {}".format(args.square, answer))
	elif args.verbosity == 1:
	    print("{}^2 == {}".format(args.square, answer))
	else:
	    print(answer)

运行结果是:

	$ python3 prog.py 4 -v 3
	usage: prog.py [-h] [-v {0,1,2}] square
	prog.py: error: argument -v/--verbosity: invalid choice: 3 (choose from 0, 1, 2)
	$ python3 prog.py 4 -h
	usage: prog.py [-h] [-v {0,1,2}] square
	
	positional arguments:
	  square                display a square of a given number
	
	optional arguments:
	  -h, --help            show this help message and exit
	  -v {0,1,2}, --verbosity {0,1,2}
	                        increase output verbosity

注意到这个限制在出错信息和帮助文本里也同样体现了出来.

然后我们可以用另一种常见的方法来使用 verbosity:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("square", type=int,
	                    help="display the square of a given number")
	parser.add_argument("-v", "--verbosity", action="count",
	                    help="increase output verbosity")
	args = parser.parse_args()
	answer = args.square**2
	if args.verbosity == 2:
	    print("the square of {} equals {}".format(args.square, answer))
	elif args.verbosity == 1:
	    print("{}^2 == {}".format(args.square, answer))
	else:
	    print(answer)

我们引入了另一个 action, "count", 来为某个可选参数出现的次数计数:

	$ python3 prog.py 4
	16
	$ python3 prog.py 4 -v
	4^2 == 16
	$ python3 prog.py 4 -vv
	the square of 4 equals 16
	$ python3 prog.py 4 --verbosity --verbosity
	the square of 4 equals 16
	$ python3 prog.py 4 -v 1
	usage: prog.py [-h] [-v] square
	prog.py: error: unrecognized arguments: 1
	$ python3 prog.py 4 -h
	usage: prog.py [-h] [-v] square

	positional arguments:
	  square           display a square of a given number

	optional arguments:
	  -h, --help       show this help message and exit
	  -v, --verbosity  increase output verbosity
	$ python3 prog.py 4 -vvv
	16

+ 现在这个参数更像是一个标志(和 `action="store_true")类似, 这解释了为什么给它一个值会出错.

+ 参数的行为也和 "store_true" 的行为类似

+ 例子中示范出了 "count" 行为是如何工作的. 你可能之前看到过类似的用法.

+ 和 "store_true" 行为一样,如果你没有指定 `-v` 标志, 这个标志对应的变量的值应该是 `None`.

+ 和预计的一样,长选项和短选项具有相同的效果.

+ 遗憾的是,对于我们要求的新的功能 (verbosity 级别只能是 0,1,2), 我们的帮助信息中并没有说明. 不过我们可以通过修改在 `help` 关键字中给出的信息来解决这个问题.

+ 最后一个运行暴露了我们程序中的一个 bug.

让我们修正这个 bug:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("square", type=int,
	                    help="display a square of a given number")
	parser.add_argument("-v", "--verbosity", action="count",
	                    help="increase output verbosity")
	args = parser.parse_args()
	answer = args.square**2
	
	# bugfix: replace == with >=
	if args.verbosity >= 2:
	    print("the square of {} equals {}".format(args.square, answer))
	elif args.verbosity >= 1:
	    print("{}^2 == {}".format(args.square, answer))
	else:
	    print(answer)

现在程序运行结果变成了:

	$ python3 prog.py 4 -vvv
	the square of 4 equals 16
	$ python3 prog.py 4 -vvvv
	the square of 4 equals 16
	$ python3 prog.py 4
	Traceback (most recent call last):
	  File "prog.py", line 11, in <module>
	    if args.verbosity >= 2:
	TypeError: unorderable types: NoneType() >= int()

+ 第一次运行结果是正确的,修正了之前程序中的 bug. 我们让所有 >= 2 的值都认为是最高级别的 verbosity.

+ 第三次运行结果有问题.

继续修正 bug:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("square", type=int,
	                    help="display a square of a given number")
	parser.add_argument("-v", "--verbosity", action="count", default=0,
	                    help="increase output verbosity")
	args = parser.parse_args()
	answer = args.square**2
	if args.verbosity >= 2:
	    print("the square of {} equals {}".format(args.square, answer))
	elif args.verbosity >= 1:
	    print("{}^2 == {}".format(args.square, answer))
	else:
	    print(answer)

我们又引入了一个新的关键字, `default`. 将默认值设置成0, 使得它总是能够和整数值想比较. 如果不这么设置, 如果可选参数没有给定, 变量的值会是 `None`, 和整数值无法比较, 会引发 `TypeError` 异常.

看到这里相信你已经学会了不少东西了, 但是 argparse 模块太强大了, 我们在最后还要再介绍一些内容.

## 一点高级用法

如果我们想让程序不再只是计算平方值, 而是拥有高级一点的功能:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("x", type=int, help="the base")
	parser.add_argument("y", type=int, help="the exponent")
	parser.add_argument("-v", "--verbosity", action="count", default=0)
	args = parser.parse_args()
	answer = args.x**args.y
	if args.verbosity >= 2:
	    print("{} to the power {} equals {}".format(args.x, args.y, answer))
	elif args.verbosity >= 1:
	    print("{}^{} == {}".format(args.x, args.y, answer))
	else:
	    print(answer)

结果是:

	$ python3 prog.py
	usage: prog.py [-h] [-v] x y
	prog.py: error: the following arguments are required: x, y
	$ python3 prog.py -h
	usage: prog.py [-h] [-v] x y
	
	positional arguments:
	  x                the base
	  y                the exponent
	
	optional arguments:
	  -h, --help       show this help message and exit
	  -v, --verbosity
	$ python3 prog.py 4 2 -v
	4^2 == 16

刚才我们通过 verbosity 级别来改变结果输出的格式, 下面一个例子改成用 verbosity 级别来输出更多的信息:

	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument("x", type=int, help="the base")
	parser.add_argument("y", type=int, help="the exponent")
	parser.add_argument("-v", "--verbosity", action="count", default=0)
	args = parser.parse_args()
	answer = args.x**args.y
	if args.verbosity >= 2:
	    print("Running '{}'".format(__file__))
	if args.verbosity >= 1:
	    print("{}^{} == ".format(args.x, args.y), end="")
	print(answer)

运行结果:

	$ python3 prog.py 4 2
	16
	$ python3 prog.py 4 2 -v
	4^2 == 16
	$ python3 prog.py 4 2 -vv
	Running 'prog.py'
	4^2 == 16

### 有冲突的选项

到目前为止我们都是在使用 `argparse.ArgumentParser` 实例的两个方法. 下面介绍第三个方法, `add_mutually_exclusive_group()`. 这个方法让我们可以制定互相冲突的选项. 我们对程序进行一些更改,使得新功能有意义: 我们引入 `--quiet` 选项, 和 `--verboes` 选项是对立的.

	import argparse
	
	parser = argparse.ArgumentParser()
	group = parser.add_mutually_exclusive_group()
	group.add_argument("-v", "--verbose", action="store_true")
	group.add_argument("-q", "--quiet", action="store_true")
	parser.add_argument("x", type=int, help="the base")
	parser.add_argument("y", type=int, help="the exponent")
	args = parser.parse_args()
	answer = args.x**args.y
	
	if args.quiet:
	    print(answer)
	elif args.verbose:
	    print("{} to the power {} equals {}".format(args.x, args.y, answer))
	else:
	    print("{}^{} == {}".format(args.x, args.y, answer))

现在程序变得简单了一些,为了便于展示,我们牺牲了一些程序功能. 下面是运行结果:

	$ python3 prog.py 4 2
	4^2 == 16
	$ python3 prog.py 4 2 -q
	16
	$ python3 prog.py 4 2 -v
	4 to the power 2 equals 16
	$ python3 prog.py 4 2 -vq
	usage: prog.py [-h] [-v | -q] x y
	prog.py: error: argument -q/--quiet: not allowed with argument -v/--verbose
	$ python3 prog.py 4 2 -v --quiet
	usage: prog.py [-h] [-v | -q] x y
	prog.py: error: argument -q/--quiet: not allowed with argument -v/--verbose

应该容易看得懂. 最后一个例子是为了说明参数的一些灵活性,长选项和短选项是可以混合的.

最后一个内容,你可能想要告诉用户你的程序的主要功能,以防他们不知道:

	import argparse
	
	parser = argparse.ArgumentParser(description="calculate X to the power of Y")
	group = parser.add_mutually_exclusive_group()
	group.add_argument("-v", "--verbose", action="store_true")
	group.add_argument("-q", "--quiet", action="store_true")
	parser.add_argument("x", type=int, help="the base")
	parser.add_argument("y", type=int, help="the exponent")
	args = parser.parse_args()
	answer = args.x**args.y
	
	if args.quiet:
	    print(answer)
	elif args.verbose:
	    print("{} to the power {} equals {}".format(args.x, args.y, answer))
	else:
	    print("{}^{} == {}".format(args.x, args.y, answer))


	$ python3 prog.py --help
	usage: prog.py [-h] [-v | -q] x y
	
	calculate X to the power of Y
	
	positional arguments:
	  x              the base
	  y              the exponent
	
	optional arguments:
	  -h, --help     show this help message and exit
	  -v, --verbose
	  -q, --quiet

## 总结

`argparse` 模块提供的功能远比我们介绍到的要多. 它的文档相当全面细致,而且有很多的例子. 在看过这个 tutorial 之后, 你应该可以仔细研究那份文档而不会晕头转向了.
