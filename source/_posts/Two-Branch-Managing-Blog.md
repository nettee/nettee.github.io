title: Hexo博客的多分支管理方法
date: 2016-07-27 15:54:23
tags: [Hexo, Git]
---

我的博客自开博以来一直使用Hexo框架，部署到GitHub Pages上。由Hexo生成的静态页面放置在GitHub仓库[nettee.github.io](https://github.com/nettee/nettee.github.io/tree/master)里，这样你们就可以访问我的博客了。

但是，我有可能会在多个机器上写文章，Hexo项目里的Markdown文件和图片一样需要管理。一开始我是新开了一个GitHub仓库[Hexo.y](https://github.com/nettee/Hexo.y)（如果这个链接打不开，说明这个过时的仓库已经被我删掉了），设置好gitignore之后，把Markdown文件和图片托管到上面。但是本来博客就有一个仓库了，这样又建了一个仓库，总觉得怪怪的。于是我灵机一动，使用Git的多分支策略管理博客内容。

nettee.github.io仓库中，博客的静态页面放在master分支上，而Markdown文件放在blog分支上，两个分支互相之间不会进行合并。本机写博客的时候，就在blog分支下写Markdown文件，使用Hexo生成静态页面后，部署到远程（GitHub上）的master分支。而博客源文件在blog分支管理后，和远程的blog分支进行同步。本地从来不处理master分支。这样两个分支就可以相安无事地共同呆在一个仓库里了。

最后碎碎念一点。我将博客文件用Git进行管理的初衷是要同时在我电脑上的Windows系统和Ubuntu系统上写博客。原本在Windows系统上写博客的时候，因为Windows的cmd字体非常难看，又和Linux命令不兼容，我一直是在Git Bash里输入各种Hexo命令，不管是`hexo new`，还是`hexo s`，都要等待非常长的时间。这让我一度以为Hexo的效率有问题。今天第一次在Ubuntu系统里写博客，`hexo new`在1秒的时间就响应了，而不是在Windows系统上的几十秒。我不禁感慨，使用Linux真的能把工作效率提高很多。

