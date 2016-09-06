title: Go语言对面向对象的支持
date: 2016-04-15 20:54:48
tags: [Object-oriented, Go, Programming Language]
---
Go语言的风格比较独特，相比于C++、Java等语言中传统的面向对象机制，Go的机制非常不同。Go支持类，但不支持继承，也不支持虚函数（抽象方法）。同时，Go语言抛弃了构造函数。

### 继承

Go语言虽然反对继承，但可以通过其他的方式实现继承的功能。Go语言的继承可以通过组合来模拟实现，称为匿名组合。下面的例子里，类`Foo`继承了类`Base`：

```Go
type Base struct {
	Name string
}

type Foo struct {
	Base
	Desc string
}
```

在`Foo`类定义了`Base`类型的匿名成员，`Foo`就获得了`Base`的全部成员，即`Name`成为`Foo`的成员。

<!-- more -->

这样的继承风格的好处是，不需要显示给出继承关键字（如Java中的`extends`），而且不需要设计继承体系（这一般挺难的）。坏处是，`Foo`类需要知道`Base`类的所有成员，因为在创建一个`Foo`对象时，需要对继承来的成员进行初始化：

```Go
foo := Foo{Name:"Jack", Desc:"Foo"}
```

### 接口

Go语言中的接口是一种“非侵入式”接口。实现一个类的时候，无需从接口派生，只要一个类实现了这个接口中的所有方法，就认为这个类实现了这个接口，可以将该类实例赋值到一个类型为该接口的变量。

这种接口机制的好处时，无需建立继承体系，一个类只要实现自己需要的方法即可，接口可以在使用时按需定义，而无需事前规划。

### 多态

在传统的面向对象语言中，多态的实现依赖于继承。那么在没有继承机制的Go语言中如何实现多态呢？实际上，Go语言的多态主要表现在实现了相同接口的类上。比如下面的例子：

```Go
type I interface {
	sayHello()
}

type Foo struct {
	name string
}

type Bar struct {
	name string
}

func (foo *Foo) sayHello() {
	fmt.Println("hello", foo.name)
}

func (bar *Bar) sayHello() {
	fmt.Println("hello", bar.name)
}

func main() {
	var o1 I = Foo{"foo"}
	var o2 I = Bar{"Bar"}
	o1.sayHello()
	o2.sayHello()
}
```

仔细观察可以发现，上面例子中所谓的“多态”其实多此一举，因为Go的接口的性质，调用的实际上就是`Foo`实例和`Bar`实例的成员方法。本来就只有子类的方法，不可能不是多态的。

在面向对象语言中，更关键的是类继承的多态。我没有找到关于Go的类继承中多态的资料，但我的看法是：多态是为了让同一个父类方法对不同的子类有不同的行为，但Go中既然有这种非侵入式接口的机制，就没必要实现类继承中的多态。各个子类不需要拥有共同的父类，而只需要各自拥有一个名字相同的方法，再利用接口规定这个方法，直接对每个类中的这个方法进行调用即可。也就是说，Java等语言由于没有Go语言中接口的功能，就无法实现这样的多态性，必须构建一个继承体系来实现。Go语言的风格决定了在使用中多用组合，少用或不用继承，这可以算是语言影响编程风格的一个例子。

### Go语言和Java语言的区别

从面向对象的角度来理解，Java是一个比较彻底的面向对象语言（主要表现在所有的变量和方法都放在类中），而Go语言骨子里不是一种面向对象的语言，或者说与传统的面向对象方法背道而驰。Go语言不支持继承，实际上是崇尚组合，倡导用清晰明了的方式解决问题，而不是用庞杂的继承体系。因为Go虽然可以模拟继承机制，但如果这样去写代码，一定会导致代码非常臃肿（和Java相比）。总体来说，Go和Java在面向对象方面的思想可以说是大相径庭，这也导致了语法上很大的差异。


### 参考资料

+ 许世伟等，Go语言编程，人民邮电出版社
+ Go语言（二） 继承和重载，http://www.cnblogs.com/xuxu8511/p/3296546.html
+ go语言如何实现类似c++中的多态功能，http://www.2cto.com/kf/201502/374968.html