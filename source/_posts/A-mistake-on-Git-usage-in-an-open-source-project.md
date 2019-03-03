title: 记一次开源项目中使用 Git 犯错的经历
date: 2019-03-03 15:07:27
tags: [Git]
---

最近在[掘金翻译计划](https://github.com/xitu/gold-miner)上参与翻译，这也是我第一次参与正式的开源项目。虽然这不是一个编程的项目，但也会使用 GitHub 的 issue / branch / pull request 这些工具来进行协作。我在一次更新分支的时候，push 了一些不必要的 commits。好在我仔细分析，然后在十分钟之内解决了问题。这是我第一次在正式的开源项目中遇到 Git 相关的挑战，想想也挺有趣的。在这里写篇文章记录一下。

首先介绍一下这个翻译项目的工作流程。项目的主分支是 master，当认领一篇文章进行翻译的时候，需要创建一个新分支 `translate/file-name.md`，翻译完成后需要创建一个 pull request 以供 review（也就是校对）。校对的主要过程是对 pull request 中内容进行评论。而校对之后，译者根据校对意见进行修改的时候，只需要直接提交到原分支，GitHub 就会自动将修改的内容同步到 pull request 中，非常方便。可以看到，整个项目其实和编程项目的工作方式类似，只不过你提交的不是源代码，而是翻译过的 markdown 文章。

## 漫不经心的错误

言归正传。我一共翻译了两篇文章，不妨称为 A 和 B。这样我就需要从 `master` 分支分出两个新分支：`translate/A.md` 和 `translate/B.md`。由于我两次翻译的间隔时间较短，**在我创建分支 B 的时候，分支 A 还没有被 merge 到 master**（这是重点）。也就是说，B 分支中的文件是没有我已翻译好的 A 文章的。

终于我的 B 文章也翻译完了，而且两位认真的校对者也在 pull request 中提出了自己的校对意见。我翻译文章 B 本来一直是在我的笔记本电脑上进行的。当我想要根据校对意见进行最后一次修改的时候，我突然决定直接在手边的台式机上干这些活！这当然是完全可以的，只是有点麻烦。我的台式机上有 `translate/A.md` 分支的所有内容，但很明显没有 `translate/B.md` 分支。于是我很自然地从 GitHub 上同步新的 B 分支：

```bash
git checkout -b translation/B.md
git pull origin translation/B.md
```

然而我犯了一个致命的错误，我本该从 master 分支上分出 B 分支的，但是我没有注意到当前分支是 A 分支。于是，**我从 A 分支上分出了 B 分支**！

<!-- more -->

这样，我的 B 分支中有了我翻译 A 文章时的几条 commit。Git 很贴心地为我 merge 了本地的 A 分支和 GitHub 上的 B 分支，然后跳出 vim 让我填写 `Merge ...` 开头的 commit 信息。我稀里糊涂地确认了。这样，我错过了一次意识到错误的机会。

很快我根据校对意见修改了几行内容。`git diff` 看一下，嗯没问题，于是直接 `git push origin translate/B.md` 完事。Git 开始上传，显示有 N 个 object 需要上传，以及跳动着上传进度……等等！我不是只修改了几行内容吗，怎么上传这么慢？好像有哪里不太对。

再打开 GitHub 上看一眼我的 pull request。天呐！`Commits` 飙升到了 12 个，`Files changed` 也变成了 2。仔细看看，我翻译 A 文章的 commit 全部都过来了！前面提到了，我创建 B 分支的时候，A 分支还没有被 merge 到 master。所以这里很不幸地，我的 B 分支被 A 分支里的 commit 给污染了。而且我 push 到了远程的分支上。

我以前也干过 Git 提交出错的问题。不过因为都是我的个人项目，我经常会干一些“直接删除 GitHub 仓库，再创建一个新的”这样粗暴的事情。不过现在这是一个公共的项目，而且分支对应的 pull request 里已经写满了两个人的校对意见！看来我必须要思考一些巧妙的解决方案了。

## 解决方案

解决方案想出来之后，竟然意外地简单：我先用我的笔记本电脑（上面保存了原先正确的 B 分支）把 B 分支 force push 到 GitHub 上，再想办法补上我的最后一次修改。

第一步是 force push。这个操作我好像经常用。在 GitHub 上创建一个新的仓库的时候，有时候我会顺手创建一个 README。这样新的仓库就有一个 commit 了。我在本地已有的代码想 push 上去的时候，就会提示错误。于是我可以使用 force push 来覆盖掉 GitHub 上那个实际上没有内容的 README：

```bash
git push -f origin master
```

放到这个情况下，就是我回到笔记本电脑上，强制覆盖掉远程（GitHub 上）的 `translate/B.md` 分支：

```bash
git push -f origin tranlsate/B.md
```

第二步，补上最后一次修改。本来我一开始想到的是用 cherry pick，但稳妥起见还是用了 diff 文件的方法，毕竟这个方法我比较熟悉。回到台式机上那个错误的 B 分支。首先把我最后一次 commit 的内容记录在 diff 文件里：

```bash
git diff HEAD~1 HEAD > a.diff
```

然后删除当前分支：

```bash
git checkout master
git branch -D translate/B.md
```

再重新同步新的分支（此时 GitHub 上已经是 force push 后的正确分支），把修改的内容加上去：

```bash
git checkout -b translate/B.md
git pull origin translate/B.md
git apply a.diff
```

Good job! 终于化险为夷。我不禁感慨 Git 的强大。一方面，Git 的分布式特性，让你即使把服务器上的分支搞坏了，也能用本地的分支恢复。另一方面，Git 有强大的功能来让你修复自己的错误。这次我利用的是 git diff / git apply 功能。不过我对另外的高级功能如 git revert 和 git cherry-pick 还不是很熟。看来我还要再多学学 Git 的高级功能，以后如果捅出更大的篓子，也能有办法修补 XD
