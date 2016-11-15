title: 将Java Web项目从Myeclipse迁移到Maven
date: 2016-11-06 13:34:56
tags: [Java, JSP, Maven]
---

一年前和[checky](https://github.com/checkyh)同学合作写了一个Java Web项目[IFTTT-Web](https://github.com/nettee/IFTTT-Web)。当时这个项目是作为课程的编程作业，为了尽快完成项目，我们选择在MyEclipse中进行开发。课程结束之后代码就一直搁置，有一天我想在Eclipse中重新配置项目（MyEclipse是收费软件，我的电脑里已经不再安装），但没有成功。Java Web项目比较复杂，除了Java代码之外，还包括JSP页面、JavaScript脚本、CSS文件等各种webapp需要的文件，想把一个已有的项目重新在Eclipse里运行起来，确实比较困难。

我当时尝试了一种更为“原始”的做法：在命令行下手工编译Java源文件，将编译后的字节码和webapp文件拷贝到Tomcat的目录下。这种方法当然成功了，但部署需要的手工操作太多，显然不是长久之计。直到不久之前，我才了解到Maven这个工具在Java世界里的重要地位，并开始在我的项目里使用Maven。这次我尝试用Maven重新构建一年前的项目，终于成功，在这里记录一下全部的过程。

## 主要步骤

1. 生成Maven webapp项目骨架
1. 更改目录结构
1. 添加依赖
1. 使用jetty

<!-- more -->

## 生成Maven webapp项目骨架

为了清晰直观，这里我先生成Maven webapp的目录骨架，再把已有的文件搬到对应的目录里。运行`mvn archetype:generate`，注意artifactId选择org.apache.maven.archetypes:maven-archetype-webapp。

## 更改目录结构

首先让我们看一下[更新之前的目录结构](https://github.com/nettee/IFTTT-Web/tree/629f50ed92b755294b29ab90f79604700d4739e8)：

```
.
├── src
│   ├── log4j.properties
│   ├── database
│   ├── model
│   │   ├── data
│   │   └── task
│   ├── servlet
│   └── task
│       ├── action
│       ├── mail
│       ├── run
│       ├── trigger
│       └── weibo
│── weibo
│   ├── config.properties
│   ├── log4j.properties
│   └── weibo4j
│       └── ...
├── lib
│   └── ...
└── WebRoot
    ├── assets
    ├── component
    ├── css
    ├── dashboard.jsp
    ├── favicon.ico
    ├── font
    ├── index.jsp
    ├── js
    ├── login.jsp
    ├── META-INF
    │   └── MANIFEST.MF
    ├── register.jsp
    └── WEB-INF
        └── web.xml

```

这是一个典型的MyEclipse生成的Java Web项目的目录结构，WebRoot目录下放着webapp需要的各种文件。需要注意的是，src和weibo都是source folder。

而上一步生成的Maven项目骨架是这个样子的：

```
.
├── pom.xml
└── src
    └── main
        ├── java
        ├── resources
        └── webapp
            ├── index.jsp
            └── WEB-INF
                └── web.xml
```

按照Maven对webapp项目的约定，src/main/java放置Java源代码，src/main/resources放置资源文件，src/main/webapp放置JSP、JavaScript、CSS等文件，其中web.xml放置在src/main/webapp/WEB-INF目录下。

那么，原来的文件这样进行移动：

1. src、weibo目录下所有包含Java源代码的子目录移动到src/main/java目录中
2. 配置文件config.properties，log4j.properties移动到src/main/resources目录中
3. WebRoot目录下所有的文件原样移动到src/main/webapp中

感觉移动起来还是挺简单的:) 原来的lib目录就不需要了，我们马上会使用Maven依赖来完成这个任务。文件移动之后的目录结构可以参看[这里](https://github.com/nettee/IFTTT-Web/tree/b4af1ab6926b20cf8d6a557d47216513260c4356)。

```
.
├── pom.xml
└── src
    ├── main
    │   ├── java
    │   │   ├── database
    │   │   ├── model
    │   │   │   ├── data
    │   │   │   └── task
    │   │   ├── servlet
    │   │   ├── task
    │   │   │   ├── action
    │   │   │   ├── mail
    │   │   │   ├── run
    │   │   │   ├── trigger
    │   │   │   └── weibo
    │   │   └── weibo4j
    │   ├── resources
    │   │   ├── config.properties
    │   │   ├── log4j.properties
    │   │   └── schema.sql
    │   └── webapp
    │       ├── assets
    │       ├── component
    │       ├── css
    │       ├── dashboard.jsp
    │       ├── favicon.ico
    │       ├── font
    │       ├── index.jsp
    │       ├── js
    │       ├── login.jsp
    │       ├── META-INF
    │       │   └── MANIFEST.MF
    │       ├── register.jsp
    │       └── WEB-INF
    │           └── web.xml
    └── test
        └── java
```

## 添加依赖

pom.xml文件：

```POM
<dependencies>
	<dependency>
		<groupId>junit</groupId>
		<artifactId>junit</artifactId>
		<version>4.11</version>
		<scope>compile</scope>
	</dependency>
	<dependency>
		<groupId>log4j</groupId>
		<artifactId>log4j</artifactId>
		<version>1.2.17</version>
	</dependency>
	<dependency>
		<groupId>javax.servlet</groupId>
		<artifactId>servlet-api</artifactId>
		<version>2.5</version>
	</dependency>
	<dependency>
		<groupId>javax.mail</groupId>
		<artifactId>mail</artifactId>
		<version>1.4</version>
	</dependency>
	<dependency>
		<groupId>commons-httpclient</groupId>
		<artifactId>commons-httpclient</artifactId>
		<version>3.1</version>
</dependency>
```

## 使用jetty

```XML
<plugin>
	<groupId>org.eclipse.jetty</groupId>
	<artifactId>jetty-maven-plugin</artifactId>
	<version>9.2.11.v20150529</version>
	<configuration>
		<scanIntervalSeconds>10</scanIntervalSeconds>
		<webApp>
			<contextPath>/</contextPath>
		</webApp>
	</configuration>
</plugin>
```

```Shell
mvn jetty:run
```
