# The Architecture of SQLAlchemy 翻译

本文是对The Architecture of Open Source Applications, Volumn II中SQLAlchemy一章的翻译。

原文：[The Architecture of Open Source Applications - SQLAlchemy](http://www.aosabook.org/en/sqlalchemy.html)

翻译：[nettee](https://nettee.github.io)

图灵社区已有这本书的[翻译计划][1]，其中SQLAlchemy一章的翻译[在此][2]。不过被下面的评论吐槽说近似于机翻。我不参考此翻译重新进行翻译，希望不要成为另一个机翻：）

[1]:http://www.ituring.com.cn/minibook/19
[2]:http://www.ituring.com.cn/article/13444

---

SQLAlchemy诞生于2005年，是一个Python语言的数据库工具集和对象关系映射(ORM)系统。在一开始，SQLAlchemy提供了使用Python数据库API（DBAPI）处理关系数据库的端到端系统。它的核心特性包括顺畅地处理复杂的SQL查询和对象映射和"unit of work"模式的实现。这些特性使得SQLAlchemy能够提供高度自动化的数据库系统，因此SQLAlchemy在很早期的几个版本里就受到了大量的关注。


写作本文时，SQLAlchemy已经在多个领域中被大量组织所采用。在很多人眼中，它已经成为Python关系数据库处理事实上的标准。

## 数据库抽象面临的挑战

术语“数据库抽象”通常用来表示



