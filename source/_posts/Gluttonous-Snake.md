title: 用HTML5 Canvas实现一个贪吃蛇小游戏
date: 2016-03-08 20:00:51
tags: [HTML5, JavaScript, 游戏]
---

事情的缘由是这样的，上上学期我在课程作业中实现了一个Windows控制台下的“飞机大战”小游戏，做完之后感觉这样一个小游戏实在是过于简陋。在上个学期学习了Java Swing图形界面编程之后，我计划着使用Swing重写一个飞机大战小游戏，但一拖再拖，一直没有动手。

今年年初决定开始之后，我查阅了Swing和JavaFX（一个更年轻的Java图形界面框架）的资料，感觉到JavaFX似乎一直是不温不火，再加上GUI编程代码的极其繁琐，我心中产生了动摇。忽然意识到现在用户界面已经是移动端和Web的天下了，我应该在Web端开发游戏才是。很快我找到了HTML Canvas，在没有写过JavaScript代码的情况下，我边摸索边开工，居然在一天的时间里就写出了一个基本成型的贪吃蛇游戏。

<!-- more -->

## Canvas画面绘制

Canvas（画布）是HTML5新增的一个标签，它是一个图形容器，可以用JavaScript脚本在上面绘制图形。在HTML5中，SVG也可以用来绘制图形。二者相比，SVG是基于矢量的图像，可以自动更新，Canvas是基于像素的绘图，逐像素进行渲染。因此，Canvas更适合具有实时动画的游戏开发。

Canvas元素的宽度和高度可以在一开始指定，也可以由JavaScript代码动态设置。为了开发方便，我固定了游戏画布的宽度为720像素，高度为360像素。画布中每个小方格的边长规定为24像素，也就是说，整个画面实际上是一个30x15的格子阵。蛇在画面中移动的时候，一次移动一个小方格。

Canvas内容的更新需要程序员手动控制刷新。我写了一个`repaintAll`函数，在每次蛇的位置移动之后调用它，重新绘制Canvas画面。函数代码如下所示，不熟悉Canvas用法的读者可以跳过。关于Canvas的使用方法，可以参考W3School的[Canvas教程][2]和[Canvas参考手册][3]。

[2]: http://w3school.com.cn/html5/html_5_canvas.asp
[3]: http://w3school.com.cn/tags/html_ref_canvas.asp

```JavaScript
function repaintAll() {
    
    // clear all contents
    context.clearRect(0, 0, canvas.width, canvas.height);

    // draw background color
    context.fillStyle = color.background;
    context.fillRect(0, 0, canvas.width, canvas.height)

    // draw snake
    for (var i = 0; i < snake.body.length; i++) {
        paintPoint(snake.body[i], color.snakeBody);
    }

    paintPoint(snake.head, color.snakeHead);
    
    // draw apple
    context.fillStyle = color.apple;
    context.beginPath();
    context.arc(apple.x * squareSize + squareSize / 2, apple.y * squareSize + squareSize / 2, 
            squareSize / 2, 0, Math.PI * 2);
    context.closePath();
    context.fill();
}

function paintPoint(p, color) {
    context.fillStyle = color;
    context.fillRect(p.x * squareSize, p.y * squareSize, squareSize - 1, squareSize - 1);
}
```

## 游戏逻辑设计

蛇在JavaScript代码中表示为snake对象。snake对象有四个属性，分别是head, body, dir, dead。head属性记录蛇头的坐标，body属性是坐标的数组，记录蛇身各个点的坐标，dir属性记录蛇当前的行走方向，dead属性记录蛇死亡与否。

在蛇前进时，先使蛇身一次前进一格，再将蛇头先移动到新的点。要使蛇身前进，只要将body的各个元素依次向后复制，再将head复制到body[0]即可，代码如下所示：

```JavaScript
// move snake body forward
for (var i = snake.body.length - 1; i > 0; i--) {
    snake.body[i] = snake.body[i-1];
}
snake.body[0] = snake.head;

snake.head = newPoint; // move snake head forward
```

这样蛇就可以正常前进，蛇身长度不会变化，如果蛇吃到了食物，要使蛇身长度增加一格，只需在蛇前进的代码前在body的尾部增加一个空对象即可。


```JavaScript
snake.body.push({}); // add a square to body

// move snake body forward
for (var i = snake.body.length - 1; i > 0; i--) {
    snake.body[i] = snake.body[i-1];
}
snake.body[0] = snake.head;

snake.head = newPoint; // move snake head forward
```

上面的代码都在一个叫做`moveToNewPoint`的函数中，这个函数统一实现了蛇向前移动的所有逻辑：

```JavaScript
function moveToNewPoint(newPoint) {

    if (isOnSnake(newPoint)) {
        // snake bites itself
        gameOver();
        return;
    }
    
    if (newPoint.x == apple.x && newPoint.y == apple.y) {
        // reaches apple
        addScore();
        apple = generateApple();
    
        snake.body.push({}); // add a square to body
    }

    // move snake body forward
    for (var i = snake.body.length - 1; i > 0; i--) {
        snake.body[i] = snake.body[i-1];
    }
    snake.body[0] = snake.head;
    
    snake.head = newPoint; // move snake head forward
}
```

如果要移动到的点在蛇身上，则表明蛇撞倒了自己，蛇即死亡。接下来判断要移动的点是否和食物重合，如果吃到食物，则给蛇身增加一格。最后是蛇的前进。对于蛇的上、下、左、右四个方向的移动，只要给`moveToNewPoint`函数传入适当的参数即可。

## 实现难点

蛇在前进过程中，方向的改变是有限制的。例如，如果蛇向右前进，那么按下左方向键和右方向键都无法对蛇的方向产生影响。但如果游戏实现的方式有问题，可能会出现蛇突然“掉头”的错误。

在游戏的第一个版本中，我采用的方法是固定时间间隔使蛇前进，而每次玩家按下方向键时，立即改变蛇的方向（即`snake.dir`的值）。这样会产生潜在的问题，假设蛇正在向右移动，玩家在蛇两次前进的时间间隔内依次按下了上方向键和左方向键，这两次的方向改变都是合法的，蛇的方向（`snake.dir`）会变为向左。那么下一次蛇会向左前进，即方向由向右突然变为向左。根据游戏逻辑，蛇向左是走到了身体上，导致蛇意外死亡。

事实上，如果玩家想刚才说的那样操作，蛇本应该向上走一格之后立即向左走才是。但由于蛇方向的改变直接通过修改`snake.dir`控制，会使得玩家手速过快时，进行的两次方向改变无法同时被记录。解决这一问题的方法是，使用一个FIFO的“指令队列”instrQueue。每次玩家按下一个键之后，将按键的方向加入指令队列中；每次蛇欲前进一格的时候，从指令队列中取出一条指令判断是否改变方向。如此可圆满解决问题。

## 总结

我的贪吃蛇实现仍然存在多个缺陷。已知的两个缺陷是：

1. 有极小的概率出现蛇吃到食物，但食物仍留在原地的“未消化”视觉效果
2. 在游戏暂停的时候按方向键，会对继续游戏之后蛇的方向产生影响

由于我是JavaScript初学者，在写这个游戏的时候是一边翻阅参考手册一遍写下代码的。一开始写的代码有种种的问题，后来我重构过一遍，在这个过程中对JavaScript语言有了一些理解，不过我决定在对这个语言有更深入的理解之后再把它们写出来。

整个小游戏的JavaScript行数约300行，可以说这个小游戏非常适合上手练习JavaScript。项目已经放到我的Github上（[这里][4]），欢迎访问。

[4]: https://github.com/nettee/Gluttonous-Snake


