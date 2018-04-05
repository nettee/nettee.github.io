title: Hexo之坑：如何让Hexo不渲染某些文件
date: 2018-04-05 15:57:16
tags: [Hexo]
---

最近在复习和整理一些计算机学科的知识，知识的提纲整理在了[iknowledge](https://github.com/nettee/iknowledge)项目中。我使用的是gitbook工具，可以生成静态网页的书籍格式，于是我就想把这个也放在我的博客上。

Hexo博客的基本内容是一些Markdown文件，放在`source/_post`文件夹下，每个文件对应一篇文章。除此之外，放在`source`文件夹下的所有开头不是下划线的文件，在`hexo generate`的时候，都会被拷贝到`public`文件夹下。但是，Hexo默认会渲染所有的HTML和Markdown文件，导致gitbook的相关网页显示出错。

怎么样避开这个坑呢？如果只有一个HTML文件的话，可以简单地在文件开头加上`layout: false`一行即可：

```html
layout: false
---

<html>
...
```

然而gitbook生成的静态网页有十几个HTML文件，显然是不可能使用这种方法的。这时候需要使用`skip_render`配置。根据[Hexo文档](https://hexo.io/zh-cn/docs/configuration.html)中的说明，通过在`_config.yml`配置文件中使用`skip_render`参数，可以跳过指定文件的渲染。使用方式如下：

```yml
skip_render: [games/**, depview/**, knowledge/**]
```

这里的路径匹配可以使用[glob 表达式](https://github.com/isaacs/node-glob)。

在设置了跳过渲染之后，最好使用`hexo clean`清除以前的编译结果，保证配置生效。

可以在[这里](/knowledge/)看到我的gitbook书籍的效果。
