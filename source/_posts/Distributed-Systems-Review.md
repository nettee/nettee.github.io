title: 分布式系统复习
date: 2017-12-25 14:41:50
tags:
---

# 分布式系统模型

## 什么是分布式系统

**定义:独立的计算机的集合,对这个系统的用户来说,系统就像一台计算机一样**

+ 定义包含了硬件和软件两个方面的内容。硬件指的是机器本身是独立的;软件是说对于用户来讲就像在和单个系统打交道。
+ 分布式系统的目标是单一性(single),但是区别于网络系统的单一性,从功能上来说,网络系统都可以完成,但是二者之间的差别在于透明性。而构造分布式系统也不仅仅是用网线连接若干台独立的计算机。

## 分布式系统的目标 [01-12]

+ Making resources available: 连接用户和资源
+ Distribution transparency: 透明性
+ Openness: (通过服务的语法和语义定义标准规则来提供服务)
+ Scalability: (用户和 cpu)

## 为什么要分布式? [01-11]

+ Economic: 微处理机比大型机性价比高
+ Speed: 分布式系统整个计算能力比单个大型主机要强
+ Inherent(固有的) distribution: 有些应用涉及到空间上分散的机器
+ Reliability: 如果其中一台机器崩溃,整体系统仍然能够运转
+ Incremental growth: 计算能力可以逐渐有所增加

## 分布式系统透明性和开放性的含义

### 透明性 [01-13]

### 开放性 [01-15]



## 分布式系统构成方法：分布式操作系统、网络操作系统和基于中间件的系统

## 分布式系统的类型 [01-18]

+ Distributed computing systems : Cluster Computing
+ Distributed information systems : Transaction processing systems
+ Distributed pervasive systems : Mobile computing systems , Mobile computing systems
