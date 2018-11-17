title: C++ 函数返回一个对象，究竟有多大影响？
date: 2018-11-16 19:16:21
tags: [C++]
---

稍微了解一点 C++ 的人都会知道，C++ 的内存和资源管理是相当复杂的。不像 Java 一股脑地把所有对象都放在堆上，C++ 既可以默认地把对象放在栈上，也可以用 `new` 把对象放在堆上。当我们把一个大对象放在栈上的时候，就必须要考虑对象拷贝的开销了。C++ 由于和 C 兼容，默认情况下参数是按值传递 (call by value) 的，在传递参数的时候就会拷贝一遍对象。对于这种情况，我们可以将参数声明为引用类型 `T&` 来避免对象拷贝。然而，函数返回时的对象拷贝开销，往往无法用引用类型来解决。我们必须正视这一问题。

# 何时必须返回一个对象

假设我们想写一个 `range` 函数：

```C++
vector<int> range(int begin, int end, int step=1) {
    vector<int> res;
    for (int i = begin; i < end; i += step) {
        res.push_back(i);
    }
    return res;
}
```

这段代码会返回一个 `vector<int>` 对象，也就是我们不希望看到的：放在栈上的大对象。调用这个函数会产生返回值的临时对象，从而产生对象拷贝。很显然，你不能直接把返回值类型改成 `vector<int>&` 来避免对象拷贝——编译器会产生一个警告：`warning: reference to local variable ‘res’ returned`，你返回了一个临时变量的引用，这个引用指向了一个栈上的地址，而这个地址随时可能被回收。所以，正确的做法就是返回一个对象。

那么，这时候对象拷贝会有怎样的开销呢？

# 临时对象与返回值优化

根据 《深度探索 C++ 对象模型》第 2.3 节 “程序转化语意学” (Program Transformation Semantics) 所述，函数的返回值会做如下转化：

1. 添加一个临时变量 `__result`
1. 当函数返回时，调用 `__result` 的 copy constructor，使用返回值 `x` 作为参数
1. （如果有的话）对 `__result` 进行后续操作

注意，后续操作中还能包括更多的 constructor，例如我们调用 `range` 函数以初始化变量 `r1`：

```C++
vector<int> r1;
r1 = range(1, 10); // 调用 r1 的 copy assignment operator (即 operator=)
```

可以看到，虽然只是简单的一次函数调用，临时对象就进行了两次拷贝。而 `range` 产生的数越多，需要拷贝的内容就越多，对性能的影响就越大。

为了解决这个问题，很多 C++ 编译器都实现了 [返回值优化][RVO] (Return Value Optimization)，来消除返回值临时对象的多次拷贝。

# 一个例子

为了验证编译器进行返回值优化前后的不同，我们运行一个完整的例子。我们定义 `Blob` 类用于保存原始的二进制数据块。`Blob` 需要自己分配空间以存储数据，因此它需要实现 destructor, copy constructor 和 copy assignment operator。所有的 constructor 和 destructor 都会调用 logging 函数，让我们能看出它们的调用顺序。

```C++
class Blob {
public:
    Blob()
    : data_(nullptr), size_(0) {
        log("Blob's default constructor");
    }

    explicit Blob(size_t size)
    : data_(new char[size]), size_(size) {
        log("Blob's parameter constructor");
    }

    ~Blob() {
        log("Blob's destructor");
        delete[] data_;
    }

    Blob(const Blob& other) {
        log("Blob's copy constructor");
        data_ = new char[other.size_];
        memcpy(data_, other.data_, other.size_);
        size_ = other.size_;
    }

    Blob& operator=(const Blob& other) {
        log("Blob's copy assignment operator");
        if (this == &other) {
            return *this;
        }
        delete[] data_;
        data_ = new char[other.size_];
        memcpy(data_, other.data_, other.size_);
        size_ = other.size_;
        return *this;
    }

    void set(size_t offset, size_t len, const void* src) {
        len = min(len, size_ - offset);
        memcpy(data_ + offset, src, len);
    }

private:
    char* data_;
    size_t size_;

    void log(const char* msg) {
        cout << "[" << this << "] " << msg << endl;
    }
};
```

我们定义 `createBlob` 函数，由字符串创建 blob，并调用这个函数：

```C++
Blob createBlob(const char* str) {
    size_t len = strlen(str);
    Blob blob(len);
    blob.set(0, len, str);
    return blob;
}

int main() {

    Blob blob;

    cout << "Start assigning value..." << endl;
    blob = createBlob("A very very very long string representing serialized data");
    cout << "End assigning value" << endl;

    return 0;
}
```

`createBlob` 函数返回了一个 `Blob` 对象，产生一个临时对象，这个临时对象会赋值给 `blob` 变量。那么我们应该能观察到很多的 constructor 和 destructor 调用。不过，现在编译器一般会默认进行返回值优化，消除掉很多不必要的 constructor 调用。为了观察最坏情况下的 constructor 调用情况，我们使用 `-fno-elide-constructors` 编译选项让编译器不进行返回值优化。

不进行返回值优化的结果：

```
[0x7ffd220ada20] Blob's default constructor
Start assigning value...
[0x7ffd220ad9e0] Blob's parameter constructor
[0x7ffd220ada30] Blob's copy constructor
[0x7ffd220ad9e0] Blob's destructor
[0x7ffd220ada20] Blob's copy assignment operator
[0x7ffd220ada30] Blob's destructor
End assigning value
[0x7ffd220ada20] Blob's destructor
```

可以看到，编译器生成了一个地址为 0x7ffd220ada30 的临时对象，临时对象需要调用一次 copy constructor 和 destructor。其中，copy constructor 需要复制 blob 中的数据，开销巨大。

进行返回值优化的结果：

```
[0x7ffdd52c7d50] Blob's default constructor
Start assigning value...
[0x7ffdd52c7d60] Blob's parameter constructor
[0x7ffdd52c7d50] Blob's copy assignment operator
[0x7ffdd52c7d60] Blob's destructor
End assigning value
[0x7ffdd52c7d50] Blob's destructor
```

编译器帮助我们优化掉了这个不需要的临时对象。然而，在实际的比较复杂的情况下（例如函数里 `if` 语句的两个分支分别返回不同的对象），编译器可能无法进行返回值优化。那么，我们需要更好的方法来消除临时对象的不利影响。C++11 中引入的 _移动语义_ (move semantics) 可以很好地解决这个问题。

# 移动语义与 move constructor

```C++
Blob(Blob&& other) {
    log("Blob's move constructor");
    swap(data_, other.data_);
    swap(size_, other.size_);
}

Blob& operator=(Blob&& other) {
    log("Blob's move assignment operator");
    if (this == &other) {
        return *this;
    }
    swap(data_, other.data_);
    swap(size_, other.size_);
}
```

不进行返回值优化的结果：

```
[0x7ffef7172f70] Blob's default constructor
Start assigning value...
[0x7ffef7172f30] Blob's parameter constructor
[0x7ffef7172f80] Blob's move constructor
[0x7ffef7172f30] Blob's destructor
[0x7ffef7172f70] Blob's move assignment operator
[0x7ffef7172f80] Blob's destructor
End assigning value
[0x7ffef7172f70] Blob's destructor
```

进行返回值优化的结果：

```
[0x7ffc18a6e2a0] Blob's default constructor
Start assigning value...
[0x7ffc18a6e2b0] Blob's parameter constructor
[0x7ffc18a6e2a0] Blob's move assignment operator
[0x7ffc18a6e2b0] Blob's destructor
End assigning value
[0x7ffc18a6e2a0] Blob's destructor
```

[RVO]: https://en.wikipedia.org/wiki/Copy_elision#Return_value_optimization
