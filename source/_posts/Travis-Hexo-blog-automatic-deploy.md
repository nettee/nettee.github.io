title: 使用 Travis CI 实现 Github Pages + Hexo 博客的自动部署
date: 2018-05-31 09:59:24
tags: [Hexo, GitHub, CI]
---

在使用 Hexo 写博客的时候，每次总是要使用 `hexo deploy` 将博客部署到 GitHub Pages，然后在把博客的源文件 push 到自己的 GitHub repo 里。我之前使用了 Git 分支的方法将博客源文件和博客部署文件放在一个 repo 里（[这里](/posts/2016/Two-Branch-Managing-Blog/)）。但是有没有一种方法能让我每次只需要 push 一次呢？答案是有的，那就是使用 Travis CI 持续集成工具。

Travis CI 最普通的用法是用来做自动测试。每次你 push 到 GitHub repo 的时候，Travis 会自动执行单元测试，这样你就可以知道自己的每个 commit 是否可以通过 build。在发起 pull request 的时候，Travis 也会自动执行待合并分支的单元测试。不过 Travis 能做的事情不止这些，它同样可以实现自动部署，就比如我想要的 GitHub Pages 自动部署。

Travis CI 会执行用户定义的 `.travis.yml` 脚本。我想在这个脚本中实现：使用 Hexo 生成博客内容，再将博客内容部署到 [nettee.github.io 项目的 master 分支](https://github.com/nettee/nettee.github.io/tree/master) 上。

### 生成博客内容

```yaml
language: node_js

node_js: stable

install:
  - npm install

before_script:
  - git clone https://github.com/nettee/hexo-theme-next themes/next

script:
  - hexo clean
  - hexo generate
```

<!-- more -->

`.travis.yml` 脚本中首先定义了项目语言 (Node.js)，并指定了 Node.js 的版本。`install` 和 `before_script` 进行一些 build 前的准备工作。`npm install` 安装 `package.json` 文件中定义的项目依赖（Hexo 一系列的依赖）。由于我使用 NexT 主题，并且将 themes/next 作为嵌套 Git 项目，这里还需要将这个项目 clone 下来。

`script` 定义了真正的 build 过程。由于前面安装好了 Hexo 相关依赖，这里直接调用平时使用的 Hexo 脚本即可。

### 部署博客内容

在日常的使用中，我们使用 `hexo deploy` 命令来将项目部署到 GitHub Pages 上。但是，由于 `.travis.yml` 脚本执行在 Travis 的虚拟机中，我们还需要为其配置 SSH。更方便的做法是直接将 public 目录下的内容 push 到 [nettee.github.io 项目的 master 分支](https://github.com/nettee/nettee.github.io/tree/master) 上。这一过程可以使用 GitHub personal token 进行认证。

```yaml
language: node_js

node_js: stable

install:
  - npm install

before_script:
  - git clone https://github.com/nettee/hexo-theme-next themes/next

script:
  - hexo clean
  - hexo generate

after_script:
  - cd ./public
  - git init
  - git config user.name "nettee"
  - git config user.email "nettee.liu@gmail.com"
  - git add .
  - git commit -m "Deploy blog pages"
  - git push --force --quiet "https://${GH_TOKEN}@github.com/nettee/nettee.github.io" master:master

branches:
  only:
    - blog
```

脚本中的 `GH_TOKEN` 是你在 GitHub 上获取的 personal access token。这个 token 需要配置在 Travis 的环境变量中，而不是直接写在 `.travis.yml` 脚本里。

### 参考资料

+ [使用 Travis CI 自动部署 Hexo](https://www.jianshu.com/p/5e74046e7a0f)
