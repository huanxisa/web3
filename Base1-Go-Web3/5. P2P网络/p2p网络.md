# 区块链技术原理 （四）以太坊 P2P 网络

由于区块链分布式的特性，一般区块链都会建立 P2P 网络来实现节点之间的发现与数据传输。

以太坊利用 P2P 网络来同步区块链、传播交易和维护网络的一致性。下面详细介绍以太坊如何使用 P2P 网络。

## **节点发现**

以太坊网络由多个节点组成，这些节点有多种类型可以是全节点、轻节点或其他类型的节点。节点需要能够发现和连接到其他节点才能形成一个网络。

以太坊使用基于 Kademlia 的 DHT（分布式哈希表）协议来实现节点发现。每个节点都有一个唯一的节点 ID，节点会通过彼此交换节点 ID 和网络地址来发现和连接到其他节点。

### **节点 ID 和网络地址**

每个以太坊节点都有一个唯一的节点 ID，是一个 256 位的随机数，用于标识节点。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/enode/node.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/enode/node.go) 第 37 行。

```go
// ID is a unique identifier for each node.
type ID [32]byte // 32 * 8bit = 256

type Node struct {
    r  enr.Record
    id ID
    ip  netip.Addr
    udp uint16
    tcp uint16
}
```

### **引导节点（Bootstrap Nodes）**

一个新的节点加入以太坊网络时，它需要先找到一些现有的节点来开始与它们通信。这些现有的节点称为引导节点（Bootstrap Nodes）。

引导节点的地址通常是硬编码在以太坊客户端中的硬编码的引导节点地址保存在 [https://github.com/ethereum/go-ethereum/blob/master/params/bootnodes.go](https://github.com/ethereum/go-ethereum/blob/master/params/bootnodes.go)

也可以通过--bootnodes 命令行参数指定。

### **Kademlia DHT 协议**

Kademlia 是一种基于 DHT 的分布式存储和查找协议，它通过节点 ID 的距离（XOR 距离度量）来组织和查找节点。

在 Kademlia DHT 中，每个节点维护一个路由表，记录了网络中其他节点的信息。路由表分为多个桶，每个桶包含距离当前节点在某个范围内的节点。

源码: [https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go)

## 节点发现的步骤

以太坊中，默认情况下 discV4 和 discV5 是都会开启。

两者同时开启并不会端口冲突，因为他们是建立在同一个服务器连接上的，只需要占用一个端口号。

当有新消息时，会先由 discV5 处理，discV5 处理不了，才会交给 discV4 处理。

目前以太坊执行层的 P2P 网络只用到了节点发现的功能。

以太坊的共识层则既使用了 P2P 网络的服务发现，也使用 P2P 网络的传输协议 gossip 协议传播数据。

### **引导阶段**

新节点首先会连接到一个或多个引导节点。引导节点的列表可以从客户端的默认配置中获取，也可以通过手动配置。

新节点向引导节点发送 `FIND_NODE` 请求，请求引导节点提供距离目标节点 ID（通常是新节点 ID 的随机前缀）最近的节点列表。

### **节点查询**

引导节点收到 `FIND_NODE` 请求后，会从其路由表中查找并返回一组距离目标节点 ID 最近的节点。

新节点会依次向这些返回的节点发送 `FIND_NODE` 请求，逐步扩展其视野，获取更多节点的信息。

这种递归查询过程持续进行，直到新节点的路由表填充足够多的节点。

### **定期刷新**

为了保持路由表的最新和准确性，每个节点会定期刷新其路由表。这包括重新查询已知节点，发现新节点，以及删除不响应的节点。

节点会定期发送 `PING` 消息以检测其他节点是否在线，并根据响应情况更新路由表。

### **广播节点信息**

节点也会定期向其邻居广播自己的存在。这通常通过发送包含自己节点 ID 和网络地址的 `PING` 或 `PONG` 消息来实现。

这种广播机制有助于保持网络的连通性，确保新节点能够被快速发现并加入网络。

### 路由表的维护

**K 桶（K-Buckets）**：路由表由一系列 K 桶组成，每个桶存储距离节点 ID 在某个范围内的其他节点信息。K 桶的大小通常是一个固定值（例如 16），以限制每个桶中存储的节点数量。

**节点替换**：当 K 桶满时，如果有新节点要加入，会根据 LIFO（后进先出）的原则进行节点替换，优先替换掉较老且不响应的节点。

**距离度量**

节点 ID 之间的距离通过 XOR 操作计算，例如，距离 d(A, B) = A XOR B。距离越小，两个节点在网络拓扑上越接近。

他不是代表地理上的两个节点距离，而是 id 上的距离大小，只是一种分组方式。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/enode/node.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/enode/node.go) 第 338 行。

```go
// LogDist returns the logarithmic distance between a and b, log2(a ^ b).
func LogDist(a, b ID) int {
    lz := 0
    for i := range a {
       x := a[i] ^ b[i]
       if x == 0 {
          lz += 8
       } else {
          lz += bits.LeadingZeros8(x)
          break
       }
    }
    return len(a)*8 - lz
}
```

### 代码展示

在初始化 discv4 和 discV5 时，都会使用 newTable 方法创建一个 table，该方法的第一个参数接受 transport 类型的参数，UDPv4 和 UDPv5 都可以转为此类型，这个 table 就是 K-Buckets 的实现。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/v4_udp.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/v4_udp.go) 第 130 行。

```go
func ListenV4(c UDPConn, ln *enode.LocalNode, cfg Config) (*UDPv4, error) {
    cfg = cfg.withDefaults()
    closeCtx, cancel := context.WithCancel(context.Background())
    t := &UDPv4{
       // 省略一些不重要的代码...
    }

    tab, err := newTable(t, ln.Database(), cfg)
    if err != nil {
       return nil, err
    }
    t.tab = tab
    // 省略一些不重要代码
    return t, nil
}
```

[https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/v5_udp.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/v5_udp.go) 第 148 行。

```go
// newUDPv5 creates a UDPv5 transport, but doesn't start any goroutines.
func newUDPv5(conn UDPConn, ln *enode.LocalNode, cfg Config) (*UDPv5, error) {
    closeCtx, cancelCloseCtx := context.WithCancel(context.Background())
    cfg = cfg.withDefaults()
    t := &UDPv5{
       // 省略一些不重要的代码...
    }
    t.talk = newTalkSystem(t)
    // 创建新的table
    tab, err := newTable(t, t.db, cfg)
    if err != nil {
       return nil, err
    }
    t.tab = tab
    return t, nil
}
```

初始化引导是在 newTable 方法中完成的。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go) 第 121 行。

```go
func newTable(t transport, db *enode.DB, cfg Config) (*Table, error) {
    // 省略一些不重要代码...
    tab.rand.seed()
    tab.revalidation.init(&cfg)

    // initial table content
    if err := tab.setFallbackNodes(cfg.Bootnodes); err != nil {
       return nil, err
    }
    tab.loadSeedNodes()

    return tab, nil
}
```

这个方法中会通过 setFallbackNodes 方法将引导节点添加到数组中，并在 loadSeedNodes 方法中将这些节点正式添加到专门维护节点信息的 bucket 中。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go) 第 506 行。

```go
func (tab *Table) handleAddNode(req addNodeOp) bool {
    // 省略一些不重要代码...

    b := tab.bucket(req.node.ID())
    n, _ := tab.bumpInBucket(b, req.node, req.isInbound)
    if n != nil {
       // Already in bucket.
       return false
    }
    // 限制bucket中entries数量
    if len(b.entries) >= _bucketSize _{
       // Bucket full, maybe add as replacement.
       tab.addReplacement(b, req.node)
       return false
    }
    // 限制子网IP数量
    if !tab.addIP(b, req.node.IPAddr()) {
       // Can't add: IP limit reached.
       return false
    }

    // Add to bucket.
    wn := &tableNode{Node: req.node}
    if req.forceSetLive {
       wn.livenessChecks = 1
       wn.isValidatedLive = true
    }
    b.entries = append(b.entries, wn)
    b.replacements = deleteNode(b.replacements, wn.ID())
    tab.nodeAdded(b, wn)
    return true
}
```

而 bucket 会把节点分成两类，一类是生效的节点，存放在 entries 中，一类是替补节点，存放在 replacements 中。

当 entries 长度达到限制时，添加进来的节点会被放入 replacements 中。

新节点添加到 entries 前，还会检查当前属于同一个子网的 IP 数量是否过多，如果超过数量限制，会被直接丢弃。

最后会在 nodeAdded 方法中，会把新添加到 entries 中的节点添加到 tab.revalidation 维护其状态。

UDPv4 和 UDPv5 初始化好了之后，会直接启动一些 goroutine 来执行一些 loop 任务，table 中的 loop 会执行前文提到的几个步骤，节点查询、广播节点信息以及维护路由表。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go) 第 349 行。

```go
func (tab *Table) loop() {
    var (
       refresh         = time.NewTimer(tab.nextRefreshTime())
       refreshDone     = make(chan struct{})           // where doRefresh reports completion
       waiting         = []chan struct{}{tab.initDone} // holds waiting callers while doRefresh runs
       revalTimer      = mclock.NewAlarm(tab.cfg.Clock)
       reseedRandTimer = time.NewTicker(10 * time._Minute_)
    )
    defer refresh.Stop()
    defer revalTimer.Stop()
    defer reseedRandTimer.Stop()

    // Start initial refresh.
    go tab.doRefresh(refreshDone)

loop:
    for {
       nextTime := tab.revalidation.run(tab, tab.cfg.Clock.Now())
       revalTimer.Schedule(nextTime)

       select {
       // 省略一些不重要代码...
       case r := <-tab.revalResponseCh:
          tab.revalidation.handleResponse(tab, r)

       case op := <-tab.addNodeCh:
          tab.mutex.Lock()
          ok := tab.handleAddNode(op)
          tab.mutex.Unlock()
          tab.addNodeHandled <- ok

       case op := <-tab.trackRequestCh:
           tab.handleTrackRequest(op)

       case <-refresh.C:
          if refreshDone == nil {
             refreshDone = make(chan struct{})
             go tab.doRefresh(refreshDone)
          }

       case req := <-tab.refreshReq:
          waiting = append(waiting, req)
          if refreshDone == nil {
             refreshDone = make(chan struct{})
             go tab.doRefresh(refreshDone)
          }

       // 省略一些不重要代码...
       }
    }

    // 省略一些不重要代码...
}
```

这个方法中，只需要关注 doRefresh 方法、addNodeCh 中消息的消费、以及 revalidation.run 方法的执行。

addNodeCh 中消息的来源主要是 discV4 或者 discV5 收到的来自别的节点主动发送过来的数据包时添加的。

另一个比较重要的 channel 是 trackRequestCh，这个 channel 中的消息则来自所有 lookup 任务返回的 `FIND_NODE` 结果。

doRefresh 方法中，会做三件事，处理新增的节点到 bucket，主动广播，在不断地通过 doRefresh 方法，获取寻找新的 peer 并且广播自己。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table.go) 第 423 行。

```go
func (tab *Table) doRefresh(done chan struct{}) {
    defer close(done)
    // 处理新增的节点到bucket
    tab.loadSeedNodes()
    // 从本地挑选指定距离内的节点广播findnode消息
    tab.net.lookupSelf()
    
    // 随机挑选三个节点广播findnode消息
    for i := 0; i < 3; i++ {
       tab.net.lookupRandom()
    }
}
```

tab.revalidation 中有两个 revalidationList，分别命名为 fast 和 slow。

fast 列表中，存放状态会在短时间内发生变化的节点信息。

slow 列表中，则与 fast 对应，存放着状态发生变化的频率非常低，这类节点通常检查其状态的频率很低，间隔时间是 fast 列表中的 3 倍。

每次 table 的 loop 方法执行，都会执行一次 tab.revalidation 的 run 方法。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table_reval.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table_reval.go) 第 79 行。

```go
func (tr *tableRevalidation) run(tab *Table, now mclock.AbsTime) (nextTime mclock.AbsTime) {
    if n := tr.fast.get(now, &tab.rand, tr.activeReq); n != nil {
       tr.startRequest(tab, n)
       tr.fast.schedule(now, &tab.rand)
    }
    if n := tr.slow.get(now, &tab.rand, tr.activeReq); n != nil {
       tr.startRequest(tab, n)
       tr.slow.schedule(now, &tab.rand)
    }

    return min(tr.fast.nextTime, tr.slow.nextTime)
}
```

此方法中，分别从 fast 和 slow 列表中取出节点，执行 startRequest 方法，在 startRequest 方法中，又使用 goroutine 去执行 doRevalidate 方法，会在这里向该节点发送 PING 消息，检查节点的存货状态。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table_reval.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/discover/table_reval.go) 第 108 行。

```go
func (tab *Table) doRevalidate(resp revalidationResponse, node *enode.Node) {
    // Ping the selected node and wait for a pong response.
    remoteSeq, err := tab.net.ping(node)
    resp.didRespond = err == nil
    // 省略一些不重要代码...
}
```

## **消息传递**

当节点发现之后，会创建一个稳定的连接，这个连接默认情况下是 tcp 协议的。

在以太坊中，有一个专门的结构体负责这个工作，叫做 DialScheduler。

在 DialScheduler 的 loop 方法中，会不停地读取 nodesCh 中的消息，一旦有新的存活节点被发现，那么就会创建一个 DialTask。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/dial.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/dial.go) 第 222 行。

```go
func (d *dialScheduler) loop(it enode.Iterator) {
    var (
       nodesCh chan *enode.Node
    )

loop:
    for {
       // Launch new dials if slots are available.
       slots := d.freeDialSlots()
       slots -= d.startStaticDials(slots)
       if slots > 0 {
          nodesCh = d.nodesIn
       } else {
          nodesCh = nil
       }
       d.rearmHistoryTimer()
       d.logStats()

       select {
       case node := <-nodesCh:
          if err := d.checkDial(node); err != nil {
             d.log.Trace("Discarding dial candidate", "id", node.ID(), "ip", node.IPAddr(), "reason", err)
          } else {
             d.startDial(newDialTask(node, _dynDialedConn_))
          }
       case node := <-d.addStaticCh:
          id := node.ID()
          _, exists := d.static[id]
          d.log.Trace("Adding static node", "id", id, "ip", node.IPAddr(), "added", !exists)
          if exists {
             continue loop
          }
          task := newDialTask(node, _staticDialedConn_)
          d.static[id] = task
          if d.checkDial(node) == nil {
             d.addToStaticPool(task)
          }
       // 省略一些不重要代码...
    }

    d.historyTimer.Stop()
    for range d.dialing {
       <-d.doneCh
    }
    d.wg.Done()
}
```

当执行 DialTask 过程中，会尝试使用 dialer 与目标节点建立一个 tcp 连接，连接建立后之后，就会调用 setupFunc 方法，这个方法其实就是 Server 结构提的 setUpConn。

在连接建立后，节点之间会通过 RLPx（Recursive Length Prefix encoding）协议进行消息传递。RLPx 是一种用于以太坊网络中的消息编码和传输的协议。

首先建立的所有连接会被包裹一层 RLPx 传输协议的实现层 struct。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/server.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/server.go) 的 482 行:

```go
if srv.newTransport == nil {
    srv.newTransport = newRLPx
}
```

[https://github.com/ethereum/go-ethereum/blob/master/p2p/server.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/server.go) 的 949 行:

```go
// SetupConn runs the handshakes and attempts to add the connection
// as a peer. It returns when the connection has been added as a peer
// or the handshakes have failed.
func (srv *Server) SetupConn(fd net.Conn, flags connFlag, dialDest *enode.Node) error {
    c := &conn{fd: fd, flags: flags, cont: make(chan error)}
    if dialDest == nil {
       c.transport = srv.newTransport(fd, nil)
    } else {
       c.transport = srv.newTransport(fd, dialDest.Pubkey())
    }

    err := srv.setupConn(c, dialDest)
    if err != nil {
       if !c.is(_inboundConn_) {
          markDialError(err)
       }
       c.close(err)
    }
    return err
}
```

被处理好的连接在最终 setupConn 方法中添加 checkpointAddPeer 中，当被其他 goroutine 消费时，将这个连接包装成 Peer。

建立好连接之后会使用 Peer 结构体维护其状态。

会使用 runPeer 执行 Peer 的 run 方法，run 方法会启动两个 goroutine 执行 readLoop 和 pingLoop,然后执行 startProtocols 方法:

[https://github.com/ethereum/go-ethereum/blob/master/p2p/peer.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/peer.go) 第 247 行。

```go
func (p *Peer) run() (remoteRequested bool, err error) {
    var (
       writeStart = make(chan struct{}, 1)
       writeErr   = make(chan error, 1)
       readErr    = make(chan error, 1)
       reason     DiscReason // sent to the peer
    )
    p.wg.Add(2)
    go p.readLoop(readErr)
    go p.pingLoop()

    // Start all protocol handlers.
    writeStart <- struct{}{}
    p.startProtocols(writeStart, writeErr)
    // 省略不重要代码...
 }
```

在 startProtocols 方法中，汇之星 proto.Run 方法把自己注册到 ethHandler 结构中，在节点需要向外广播消息时，能被引用到。

readLoop 中会循环的读取 Peer 中连接中返回的消息，并处理该消息。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/peer.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/peer.go) 第 321 行：

```go
func (p *Peer) readLoop(errc chan<- error) {
    defer p.wg.Done()
    for {
       msg, err := p.rw.ReadMsg()
       if err != nil {
          errc <- err
          return
       }
       msg.ReceivedAt = time.Now()
       if err = p.handle(msg); err != nil {
          errc <- err
          return
       }
    }
}
```

pingLoop 中则是定时发送 ping 消息，并处理收到的 ping 消息。

[https://github.com/ethereum/go-ethereum/blob/master/p2p/peer.go](https://github.com/ethereum/go-ethereum/blob/master/p2p/peer.go) 第 297 行：

```go
func (p *Peer) pingLoop() {
    defer p.wg.Done()

    ping := time.NewTimer(_pingInterval_)
    defer ping.Stop()

    for {
       select {
       case <-ping.C:
          if err := SendItems(p.rw, _pingMsg_); err != nil {
             p.protoErr <- err
             return
          }
          ping.Reset(_pingInterval_)

       case <-p.pingRecv:
          SendItems(p.rw, _pongMsg_)

       case <-p.closed:
          return
       }
    }
}
```

当有消息需要从 peer 中读取或者写入时，都需要通过这一层 RLPx 协议的实现层读取。

由于相对宽松的使用方式，使以太坊在对协议的拓展上面非常便利，只需要实现出 net.Conn 接口的 Read 和 Write 方法即可，可以完全与底层协议脱离。

以太坊的 P2P 消息分为多种类型，包括区块消息、交易消息、状态同步消息等。节点会根据需要发送和接收这些消息来同步区块链和传播交易。

[https://github.com/ethereum/go-ethereum/blob/master/eth/protocols/eth/protocol.go](https://github.com/ethereum/go-ethereum/blob/master/eth/protocols/eth/protocol.go)
