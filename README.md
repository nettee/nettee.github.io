# nettee.github.io ([My blog](http://nettee.github.io/))

[![Build Status](https://api.travis-ci.org/nettee/nettee.github.io.svg?branch=blog)](https://travis-ci.org/nettee/nettee.github.io)

我的博客，使用 Hexo 框架 + NexT 主题，部署在 GitHub Pages 上。使用[双分支管理方法](http://nettee.github.io/posts/2016/Two-Branch-Managing-Blog/)，将博客源文件放在 blog 分支上，博客部署文件放在 master 分支上，两个分支互不干扰。使用 Travis CI [自动部署](http://nettee.github.io/posts/2018/Travis-Hexo-blog-automatic-deploy/) blog 分支上的博客内容。

## 克隆项目

注意克隆 `themes/next` 子项目。

## 安装 Hexo

```Shell
npm install -g hexo-cli
npm install
```

## 写作

### 创建草稿

```Shell
hexo new draft "My article"
```

### 本地预览

```Shell
hexo generate # 或简写 hexo g
hexo server --draft # 或简写 hexo s --draft
```

打开`http://localhost:4000`预览博客效果。可实时刷新。

## 发布

### 发布为正式稿

将`source/_draft`中的文件移动到`source/_post`中。

### 部署

```Shell
hexo deploy # 或简写 hexo d
```
