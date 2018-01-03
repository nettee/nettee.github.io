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
+ Reliability: 如果其中一台机器崩溃,整体系统仍然能够运转 ==> Availability
+ Incremental growth: 计算能力可以逐渐有所增加 ==> Scalability

## 分布式系统的目标 [01-12]

（构建分布式系统的时候应该努力达成的重要目标）

"ATOS"

+ Making resources **available**: 可用性
+ Distribution **transparency** (hide the fact that resources are distributed): 透明性
+ **Openness**: 开放性
+ **Scalability**: 可扩展性
  + **size scalability**: 可以容易地添加用户/资源，而没有显著的性能损失
  + **geographical scalability**: 用户/资源可能距离很远，但没有显著的通信延迟
  + **administrative scalability**: An administratively scalable system is one that can still be easily managed even if it spans many independent administrative organizations. 即使跨越许多独立的行政组织，仍然可以轻松管理
  + 大部分系统可以做到第一点，但后两点很难做到

<!-- more -->

## 分布式系统透明性和开放性的含义

### 透明性 [01-13] [P8]

+ Access
+ Location
+ Migration
+ Relocation
+ Replication
+ Concurrency
+ Failure

### 开放性 [01-15] [P12]

(Textbook p.12) An **open** distributed system is essentially a system that offers components that can easily be used by, or integrated into other systems. 可以提供可以被其他系统使用或集成的组件。

策略(policy)与机制(mechanism)分离：策略具体，机制抽象

## 分布式系统构成方法

分为：分布式操作系统(DOS)、网络操作系统(NOS)和基于中间件的系统(Middleware)

（课件没有，参见急救包）

## 分布式系统的类型 [01-19]

+ Distributed computing systems
  + Cluster Computing
  + Grid Computing
  + Cloud Computing
+ Distributed information systems
  + Transaction processing systems
+ Distributed pervasive systems (next-generation)
  + Mobile computing systems
  + Sensor networks

# 分布式系统架构

## 分布式系统架构风格 [02-3~4]

+ Organize into logically different components, and distribute those components over the various machines.
+ Decoupling processes in space (“anonymous”) and also time (“asynchronous”) has led to alternative styles.

(Textbook p.56) 使用**component**和**connector**定义，有四种典型类型：

+ Layered architectures
+ Object-based architectures
+ Resource-centered architectures
+ Event-based architectures

经典的三层架构：

+ user interface layer
+ processing layer
+ data layer

## 分布式系统组织形式 [02-5]

+ **Centralized**: 基本的 Client/Server 模型
+ **Decentralized**: Peer-to-peer (P2P)
+ **Hybrid**: Client/Server combined with P2P

## 客户-服务器模式和对等模式

+ Client-Server 模式是 **vertical distribution**，将不同逻辑功能的 component 划分到不同的机器上
+ P2P 模式是 **horizontal distribution**，每个机器的功能都是等价的

### Client-Server 模式 [02-6]

Request/Response 模型

+ Multiple client / Single server
+ Multiple client / Multiple server

多层架构（对于机器而言）

+ (Physically) two-tiered architecture: client machine & server machine
  + 一般将 user interface layer 放在 client machine 上，将 processing layer 和 data layer放在 server machine 上
+ (Physically) three-tiered architecture: client machine, application server & database server.

### 对等 (P2P) 模式 [02-21]

+ Structured P2P: 有特定的拓扑结构，如环、二叉树、网格
  + 找一个数据只要找特定ID的结点即可
+ Unstructured P2P: nodes have randomly selected neighbors
  + search 方法：
    + Flooding
    + Random walk
  + Super peers: weak peer 通过 super peers 来通信
+ Hybrid P2P: some nodes are appointed special functions in a well-organized fashion
  + **Edge-server systems**

## 将分布式系统组织为中间件 [02-28]

???

# 进程与线程

## 进程和线程

什么是进程：

+ Program: Static code and static data
+ Process: Dynamic instance of code and data

线程是轻量级的进程：

+ 一个线程只能属于一个进程，而一个进程可以有多个线程
+ 进程是系统进行资源分配和调度的一个独立单位，线程是CPU调度和分派的基本单位
+ 线程不拥有存储资源，同一进程的所有线程共享该进程的所有资源

## 代码迁移

### 什么是代码迁移

+ **weak mobility**: 只迁移 code segment，一定重启
+ **strong mobility**: 迁移 code segment & execution segment

### 强迁移 vs. 弱迁移

+ 强迁移
  + Move only code and data segment (and reboot execution):
  + Relatively simple, especially if code is portable
  + Distinguish code shipping (push) from code fetching (pull)
+ 弱迁移
  + Move component, including execution state
  + Migration: move entire object from one machine to the other
  + Cloning: start a clone, and set it in the same execution state

# 通信

## 通信的类型 [P172]

Persistent/transient
+ **persistent communication**: a message that has been submitted for transmission is stored by the communication middleware as long as it takes to deliver it to the receiver
+ **transient communication**: a message is stored by the communication system only as long as the sending and receiving application are executing

Asynchronous/synchronous

+ **asynchronous communication**: a sender continues immediately after it has submitted its
message for transmission
+ **synchronous communication**: the sender is blocked until its request is known to be accepted

## 远程过程调用RPC

### RPC的工作过程

1. The client procedure calls the client stub in the normal way.
2. The client stub builds a message and calls the local operating system.
3. The client’s OS sends the message to the remote OS.
4. The remote OS gives the message to the server stub.
5. The server stub unpacks the parameter(s) and calls the server.
6. The server does the work and returns the result to the stub.
7. The server stub packs the result in a message and calls its local OS.
8. The server’s OS sends the message to the client’s OS.
9. The client’s OS gives the message to the client stub.
10. The stub unpacks the result and returns it to the client.

Client --(1)-> Client stub -(2)-> Client OS -(3)-> Server OS -(4)-> Server stub (5)-> Server
Client <-(10)- Client stub <-(9)- Client OS <-(8)- Server OS <-(7)- Server stub <-(6)- Server

### 故障处理 [P464]

五种 failure:

1. Client cannot locate the server
    + Reason: 服务器宕机，服务器接口更新
    + Solution: Throw an exception，或使用特殊的返回值
2. Lost request messages
    + 超时则重新request
    + 对于不幂等的请求，编上序号让server能识别重复请求
3. Server crashes
    + 两种情况: Execute之前Crash，Execute之后Crash
    + 难以解决
      + 重启server并重新进行处理：保证至少执行一次(at-least-once)
      + 立即放弃并报告错误：保证至多执行一次(at-most-once)
      + 什么都不保证
4. Lost reply messages
    + 超时则重新request
    + 对于不幂等的请求，编上序号让server能识别重复请求
5. Client crashes (orphan 问题)
    + **orphan extermination**: 为request记录log，client重启时检查log
    + **reincarnation**: client重启时广播，停止orphan computations
    + **gentle reincarnation**: server收到广播时寻找本地computations的owner，找不到则停止computations
    + **expiration**: 除非另外要求，RPC都要在规定时间内完成

### 动态绑定

一种让 client 找到 server 的方法

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
