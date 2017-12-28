title: 分布式系统复习
date: 2017-12-25 14:41:50
tags:
---

# 分布式系统模型

## 什么是分布式系统 [01-8]

A distributed system is a collection of **autonomous(自治的) computing elements** that appears to its users as a **single coherent(一致的) system**.

+ 定义包含了硬件和软件两个方面的内容。硬件指的是机器本身是独立的;软件是说对于用户来讲就像在和单个系统打交道。
+ 分布式系统的目标是单一性(single),但是区别于网络系统的单一性,从功能上来说,网络系统都可以完成,但是二者之间的差别在于透明性。而构造分布式系统也不仅仅是用网线连接若干台独立的计算机。

## 为什么要分布式? [01-11]

+ Economic: 微处理器比大型机性价比高
+ Speed: 分布式系统整个计算能力比单个大型主机要强
+ Inherent(固有的) distribution: 有些应用涉及到空间上分散的机器
+ Reliability: 如果其中一台机器崩溃,整体系统仍然能够运转
+ Incremental growth: 计算能力可以逐渐有所增加

## 分布式系统的目标 [01-12]

+ Making resources available: 可用性
+ Distribution transparency: 透明性
+ Openness: 开放性
+ Scalability: (用户和 cpu)

<!-- more -->

## 分布式系统透明性和开放性的含义

### 透明性 [01-13]

### 开放性 [01-15]

## 分布式系统构成方法：分布式操作系统、网络操作系统和基于中间件的系统

## 分布式系统的类型 [01-18]

+ Distributed computing systems : Cluster Computing
+ Distributed information systems : Transaction processing systems
+ Distributed pervasive systems : Mobile computing systems , Mobile computing systems

# 分布式系统架构

## 分布式系统架构风格 [02-3~4]

Organize into logically different components, and distribute those components over the various machines.
Decoupling processes in space (“anonymous”) and also time (“asynchronous”) has led to alternative styles.

## 分布式系统组织形式

+ Centralized :Basic Client–Server Model
+ Decentralized :
  + Structured P2P: nodes are organized following a specific distributed data structure
  + Unstructured P2P: nodes have randomly selected neighbors
  + Hybrid P2P: some nodes are appointed special functions in a well-organized fashion
+ Hybrid : Client-server combined with P2P

## 客户-服务器模式和对等模式

## 将分布式系统组织为中间件

# 进程与线程
## 进程和线程
## 代码迁移
### 什么是代码迁移
#### Approaches to code migration
#### Migration and local resources
#### Migration in heterogeneous systems
### 强迁移 vs. 弱迁移
#### 强迁移
#### 弱迁移

# 通信
## 通信的类型
## 远程过程调用RPC
### RPC的工作过程
### 故障处理
### 动态绑定
## 基于消息的通信
### 持久性/非持久性
### 同步/异步
### 流数据

# 同步与资源管理
## 同步问题
## 时钟同步机制
## 逻辑时钟
### Lamport算法
### 向量时戳
## 分布式系统中的互斥访问
## 分布式系统中的选举机制

# 复制与一致性
## 复制的优势与不足
## 数据一致性模型
## 数据一致性协议实例
### 基于法定数量的协议

# 容错
## 可信系统(Dependable System)特征
## 提高系统可信性的途径
## K容错系统
## 拜占庭问题( Byzantine Problem)
## 系统恢复
### 回退恢复
### 前向恢复
## 检查点(Check point)
