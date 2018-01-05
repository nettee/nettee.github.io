title: 分布式系统复习
date: 2017-12-25 14:41:50
tags:
---

# 分布式系统模型

## 什么是分布式系统 [01-8]

A distributed system is a collection of **autonomous(自治的) computing elements** that appears to its users as a **single coherent(一致的) system**.

+ 每个计算单元(机器/进程)可以独立地工作（但他们通过通信相互协作）
+ 用户(人或应用)认为他面对的是一个单一系统（分布式透明性）

## 为什么要分布式? [01-11]

+ Economic: 微处理器比大型机性价比高
+ Speed: 分布式系统整个计算能力比单个大型主机要强
+ Inherent(固有的) distribution: 有些应用涉及到空间上分散的机器
+ Reliability: 如果其中一台机器崩溃,整体系统仍然能够运转 ==> Availability
+ Incremental growth: 计算能力可以逐渐有所增加 ==> Scalability

## 分布式系统的目标 [01-12]

（构建分布式系统的时候应该努力达成的重要目标）

"ATOS"

+ Making resources **available** 可用性
  + 用户易于访问, 易于共享
+ **Transparency** 透明性: Hide the fact that resources are distributed
+ **Openness** 开放性
+ **Scalability** 可扩展性
  + **size scalability**: 可以容易地添加用户/资源，而没有显著的性能损失
  + **geographical scalability**: 用户/资源可能距离很远，但没有显著的通信延迟
  + **administrative scalability**: An administratively scalable system is one that can still be easily managed even if it spans many independent administrative organizations. 即使跨越许多独立的行政组织，仍然可以轻松管理
  + 大部分系统可以做到第一点，但后两点很难做到

<!-- more -->

## 分布式系统透明性和开放性的含义

### 透明性 [01-13] [P8]

+ Access
  + Hide differences in data representation and how a resource is accessed: 数据在不同的机器上如何表示
+ Location
  + Hide where a resource is located: 机器/资源的物理位置
+ Relocation
  + Hide that a resource may be moved to another location while in use (被动移动): 云计算中很重要
+ Migration
  + Hide that a resource may move to another location (主动移动): 如移动通信
+ Replication
  + Hide that a resource may be shared by several competitive users
+ Concurrency
  + Hide that a resource may be shared by several competitive users: 并发访问时需要保持资源的一致性状态
+ Failure
  + Hide the failure and recovery of a resource: 用户察觉不到故障以及后续的修复过程

### 开放性 [01-15] [P12]

+ (Textbook p.12) An **open** distributed system is essentially a system that offers components that can easily be used by, or integrated into other systems.
 提供的组件可以很容易地被其他系统使用或集成
+ 灵活性 flexibility
+ 可以更换一个组件而不影响整个系统
+ 策略(policy)与机制(mechanism)分离：策略具体，机制抽象

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

经典的三层架构：

+ user interface layer
+ processing layer
+ data layer

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
  + BitTorrent

## 将分布式系统组织为中间件 [02-28] [P71]

+ 上面讨论的都是高层的架构, 而中间件是一个具体的组织形式
+ 中间件的目标: 实现开放性
+ 中间件常用的两个设计模式: wrappers 和 interceptors
  + wrapper/adapter: 为某个组件提供接口, 解决了接口不兼容的问题
    + broker 模式用来将 adapter 的数量由 m*n 减少为 m+n
  + interceptor: 在正常的控制流(通常是RPC请求过程)中插入一段代码
  + 通常用于改造中间件, 以满足应用的实际需求

# 进程与线程

## 进程和线程

什么是进程：

+ Program: Static code and static data
+ Process: Dynamic instance of code and data

线程是轻量级的进程：

+ 一个线程只能属于一个进程，而一个进程可以有多个线程
+ 进程是系统进行资源分配和调度的一个独立单位，线程是CPU调度和分派的基本单位
+ 线程不拥有存储资源，同一进程的所有线程共享该进程的所有资源

## 代码迁移 [03-31]

+ 迁移代码通常是为了性能考虑
+ 迁移虚拟机比迁移代码要容易很多
+ 同构系统中, 假设迁移后的代码可以直接运行

### 强迁移 vs. 弱迁移 [03-32]

+ **weak mobility**: 只迁移 code segment，一定重启
+ **strong mobility**: 迁移 code segment & execution segment

+ 强迁移
  + Move only code and data segment (and reboot execution):
  + Relatively simple, especially if code is portable
  + Distinguish code shipping (push) from code fetching (pull)
+ 弱迁移
  + Move component, including execution state
  + Migration: move entire object from one machine to the other
  + Cloning: start a clone, and set it in the same execution state

### 虚拟机迁移 [P158]

将计算环境与底层系统解耦

# 通信

## 通信的类型 [P172]

见“基于消息的通信”

## 远程过程调用(RPC) 

### RPC的工作过程 [04-1-16]

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

### 故障处理 [P464] [04-1-20]

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

### 动态绑定 [04-1-35]

一种让 client 找到 server 的方法

静态绑定：将server地址硬编码到client代码中 (ip, port)

???

## 基于消息的通信 [04-2]

### 持久性/非持久性 [P172] [04-2-4]

Persistent/transient (reliable/unreliable)

+ **persistent communication**: a message that has been submitted for transmission is stored by the communication middleware as long as it takes to deliver it to the receiver
+ **transient communication**: a message is stored by the communication system only as long as the sending and receiving application are executing

Asynchronous/synchronous (unblocking/blocking) [04-2-3]

+ **asynchronous communication**: a sender continues immediately after it has submitted its
message for transmission
+ **synchronous communication**: the sender is blocked until its request is known to be accepted
  + synchronize at request submission
  + synchronize at request delivery
  + synchronize after processing by server (at response)

[04-2-7] Persistent Messaging Alternatives 这页啥意思？？？

### 流数据 [04-2-16]

？？？

### Multicast communication [04-2-26]
 
不在范围内

# 同步与资源管理

## 同步问题 [06-4]

为什么要进行同步？

+ 保证多个进程不会同时访问gs共享资源 (mutual exclusion)
+ 保证多个进程可以相互达成一致 (consensus)

分布式系统的同步与集中式系统有何区别？

分布式系统中的同步更困难：
+ ？？？
+ ？？？

## 时钟同步机制 [06-5]

时间不能回退，可以逐渐放快或放慢

+ Cristian's algorithm [06-12] [P304]
  + 假设 time server 提供精确时间
  + 所有机器和 time server 同步
  + 考虑通信延迟
+ Berkeley algorithm [06-13] [P306]
  + 适用于没有精确时钟的情况
  + time daemon 主动询问其他所有机器的时间
  + 计算平均时间作为标准
+ Network Time Protocol [06-15] [P304]
  + 类似 Cristian's algorithm 的计算方法
  + Stratum-0/1/2/3 server，数字越小越精确

## Logical clocks 逻辑时钟 [06-16]

很多时候不需要知道精确的时间，只需要知道事件发生的先后关系就可以，这就叫做逻辑时钟

### Lamport's logical clocks [06-18] [P310]

+ 定义 Happens-before 关系
+ Assigning time C(e) to events，使满足 HB 关系
  + 每个进程维护一个 C (分布式)
  + 调整方法：When a message arrives and the receiver’s clock shows a value prior to the time the message was sent, the receiver fast forwards its clock to be one more than the sending time. C_j = max{ts(m), C_j}
  + 为 timestamp 添加进程ID(e.g. <40,i>, <40,j>)，防止出现相等的 timestamp
+ 缺点
  + 通过 C(a) 和 C(b) 不能确定 a 和 b 的 HB 关系 
  + 根本原因: Lamport's logical clocks 不包含因果关系(causality)

### Vector clock 向量时戳 [06-23] [P316]

+ 原理：记录所有进程的历史信息(causal histories)
+ Assign time VC，VC[i] 表示 P_i 发生过的时间数量
  + 每个进程维护一个 VC (分布式)
  + 调整方法同Lamport's logical clocks
+ 比较方法
  + VC(a) < VC(b) iff. VC(a)[k] <= VC(b)[k] for all k
+ 若 VC(a) < VC(b)，则可以认为 a, b 之间有 causal relationship

## Mutual exclusion 互斥访问 [06-27]

### A centralized algorithm [P322] [06-28]

+ 方法
  + 使用单个决策进程，称为 coordinator
  + 请求资源的进程向 coordinator 请求 permission
  + 若资源被占用，可能 block，也可能返回错误消息
+ 缺点
  +	单点失效
    + 进程无法区分到底是 coordinator 失效了还是被 block 了
  + 性能瓶颈

### A distributed algorithm [P323] [06-29]

+ 方法
  + 基于 timestamp
  + 请求资源的进程向所有进程请求 permission
  + 若两个进程都感兴趣，timestamp 更早的胜出
  + 获得所有进程的 permission 才可以使用资源、
+ 缺点
  + 单点失效（任何一个进程 fail 都会导致单点失效）
  + 如果环境不支持广播，会很麻烦
  + 相比集中式算法更慢、更复杂，还更易失效

### A token-ring algorithm [P325] [06-32]

+ 方法
  + 在环上传递 token
  + 拥有 token 的才能使用资源
+ 缺点
  + token 丢失后很难判断

### 算法比较

见 [06-33]

## Election 选举机制 [06-34]

+ ID 大的胜出
+ 考虑进程 fail 的情况

### The bully algorithm [P330] [06-35]

+ 一个进程开始选举，发送 ELECTION 消息给 ID 更大的进程
+ 进程收到 ELECTION 消息后，返回 OK 消息，并向更 ID 更大的进程发送 ELECTION 消息
+ 收到 OK 消息的进程出局
+ 如果发送 ELECTION 消息之后没有回应，当前进程成为 Leader

### A ring algorithm [P332] [06-38]

+ 一个进程开始选举，在环上发送 ELECTION 消息，跳过 fail 的进程
+ 每个进程在环上添加自己的 ID，并继续传递
+ 当 ELECTION 消息传了一圈后，选出 ID 最大的进程
+ 发送 COORDINATOR 消息通知所有人谁是 Leader
+ 如果两个进程同时开始选举，不影响时间复杂度，只是占用带宽增加

# 复制与一致性

## 复制的优势与不足 [07-2]

+ 优势
  + Reliability
    + Avoid single points of failure
  + Performance
    + Scalability in numbers and geographic area
+ 劣势
  + Replication transparency
  + Consistency issues
    + Updates are costly
    + Availability may suffer if not careful

## 数据一致性模型

+ Data-centric consistency [07-9]
  + 未使用同步操作的模型
    + Strict [07-10]
    + Linearizability [07-12]
    + Sequential [07-11] [P364]
	  + 所有的进程看到相同的操作序列
    + Causal [07-14] [P368]
	  + 比 Sequential consistency 要弱
    + FIFO [07-17]
	  + Writes that are potentially casually related must be seen by all processes in the same order. Concurrent writes may be seen in a different order on different machines.
  + 使用同步操作的模型
    + Weak [07-21]
    + Release [07-24]
    + Entry [07-26] [P372]
+ Client-centric consistency [07-29]
  + Eventual [07-30] [P373]
  + Monotonic reads [07-32] [P377]
  + Monotonic writes [07-33] [P379]
  + Read your writes [07-34] [P380]
  + Writes follow reads [07-35] [P382]

## 数据一致性协议实例

### Quorum-based protocols 基于法定数量的协议 [P402] [07-45]

TODO

# 容错

## 可信系统(dependable systems)特征 [08-3]

+ Availability 可用性
  + 系统可以立即被使用
  + 在给定时间点可以最大可能地正常工作
+ Reliability 可靠性
  + (在一段时间内)持续运行，而没有 failure
+ Safety 安全性
  + 当系统暂时无法正常运行时，不会造成灾难性后果（例：核电站）
+ Maintainability 可维护性
  + 系统 fail 后是否容易修复
  
一些概念（不在考点内）	：

fault --> error --> failure

+ **failure**: 没有满足承诺，无法提供服务
+ **error**: 系统的错误状态，可能导致 failure
+ **fault**: 造成 error 的原因

Failure 的分类
+ Crash failure
+ Omission failure
+ Timing failure
+ Response failure
+ Byzantine failure

## 提高系统可信性(Dependability)的途径 [08-9]

使用冗余来掩盖故障 (Mask failures by redundancy)

+ Information redundancy
  + 在数据传输中添加纠错码
+ Time redundancy
  + 事务处理终止，则重新执行
+ Physical redundancy
  + 添加额外的机器或进程

## k-容错系统

k-容错定义 [P435]
+ A system is said to be k-fault tolerant if it can survive faults in k components and still meet its specifications

## 拜占庭问题 (Byzantine agreement problem)

TODO

## Distributed commit (不在考点中)

+ Two-phase commit
+ Three-phase commit

## 系统恢复 [08-54]

真正发生故障以后，使崩溃的进程恢复到正确的状态。

### 两种形式的错误恢复 [08-55]

+ 回退恢复 (backward recovery)
  + 从当前的错误状态回退到先前的正确状态
  + 定时记录系统的状态，称为**检查点**
+ 前向恢复 (forward recovery)
  + 尝试从某点继续执行，把系统带入一个正确的新状态
  + 关键在于必须预先知道会发生什么错误

### 检查点(Checkpointing) [08-56]

+ 独立检查点(Independent checkpointing) [08-58]
  + 每个进程独立地设置本地检查点
  + 每个进程回退到的状态可能不一致，需要继续回退，可能造成多米诺效应
+ 协调检查点(Coordinated checkpointing) [08-59]
  + 所保存的状态自动保持全局一致
  + 两个算法：
    + Distributed snapshot algorithm
    + Two-phase blocking protocol
