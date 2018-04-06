# 说明

这里是blog分支，使用Markdown写博客在这个分支下，写好博客后，再使用`hexo deploy`将生成好的静态网页推送到GitHub上的master分支。

## 安装

### 安装Hexo

```Shell
npm install
npm install -g hexo
```

## 写作

### 创建草稿

```Shell
hexo new draft "My article"
```

## 本地预览

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
