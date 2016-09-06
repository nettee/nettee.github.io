title: Android Activity回调方法的特殊调用顺序：onStart -> onStop
tags: [Android]
---

Android developer网站上给出了Android Activity生命周期的状态图：

![activity-state-path](http://android.xsoftlab.net/images/activity_lifecycle.png)

<!-- more -->

图中的矩形表示回调方法，箭头表示回调方法调用的顺序。但是在文档中，图片下方的表格中关于`onStart()`方法是这样描述的：

> Called when the activity is becoming visible to the user. 

> Followed by `onResume()` if the activity comes to the foreground, or `onStop()` if it becomes hidden.

也就是说，`onStart()`调用之后，如果Activity来到前台，就接着调用`onResume()`；而如果Activity变得不可见，就接着调用`onStop()`。但图片中不存在从`onStart()`到`onStop()`的边。是否存在一种特殊的情况使得调用`onStart()`之后接着调用`onStop()`呢？

在StackOverflow上的[一个问题](http://stackoverflow.com/questions/3865347/android-activity-lifecycle-onstart-onstop-possible)中，回答者给出了一个方案：

1. 你当前的Activity（叫做A1）启动了另一个非全屏的的Activity，例如对话框（叫做A2）。这时候A1的`onPause()`被调用
2. 按下Home键。这时候A1的`onStop()`被调用
3. 重新启动应用。这时候A1的`onStart()`被调用，但因为前台还有一个对话框，A1的`onResume()`不会被调用
4. 再次按下Home键。这时候A1的`onStop()`被调用

写一个应用进行验证，发现确实可行，以下是日志信息：

```
09-06 14:04:18.110 me.nettee.geoquiz D/QuizActivity: onCreate() called
09-06 14:04:18.190 me.nettee.geoquiz D/QuizActivity: onStart() called
09-06 14:04:18.190 me.nettee.geoquiz D/QuizActivity: onResume() called
09-06 14:04:20.410 me.nettee.geoquiz D/QuizActivity: onPause() called
09-06 14:04:20.805 me.nettee.geoquiz I/QuizActivity: onSaveInstanceState
09-06 14:04:21.730 me.nettee.geoquiz D/QuizActivity: onStop() called
09-06 14:04:22.530 me.nettee.geoquiz D/QuizActivity: onStart() called
09-06 14:04:23.385 me.nettee.geoquiz D/QuizActivity: onStop() called
```

从这个例子可以总结出两点结论：

+ 在某些情况下，`onStop()`的调用可以紧跟在`onStart()`调用之后

+ 虽然Android文档上说，Activity在调用`onStart()`之后的**Started**状态是不稳定的，会很快调用`onResume()`，但在某些情况下，Activity可以在Started状态停留。调用`onStarted()`之后不一定会调用`onResume()`





