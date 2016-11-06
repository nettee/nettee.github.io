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

## 生成Maven webapp项目骨架

```Shell
mvn archetype:generate
```

## 更改目录结构

+ [更新之前的目录结构](https://github.com/nettee/IFTTT-Web/tree/629f50ed92b755294b29ab90f79604700d4739e8)
+ [更新之后的目录结构](https://github.com/nettee/IFTTT-Web/tree/b4af1ab6926b20cf8d6a557d47216513260c4356)

## 添加依赖

pom.xml文件：

```XML
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
