// 类 select/poll 模型：多个网络协程 + 一个工作协程
// 每个连接一个 goroutine 读入并写入专属 channel，一个 worker 用 select 多路等待

package main

import (
	"bufio"
	"fmt"
	"io"
	"net"
	"sync"
	"time"
)

const (
	numConns   = 3
	serverAddr = "127.0.0.1:9999"
)

// 每个连接上读到的消息（带来源标识，便于 worker 处理）
type msg struct {
	connID int
	data   string
}

// SelectPollServer 启动「多网络协程 + 单工作协程」的 TCP 服务
func SelectPollServer() {
	listener, err := net.Listen("tcp", serverAddr)
	if err != nil {
		fmt.Println("Listen error:", err)
		return
	}
	defer listener.Close()
	addr := listener.Addr().(*net.TCPAddr)
	fmt.Printf("Select/Poll 服务监听 %s（共 %d 路连接，1 个工作协程）\n", addr, numConns)

	// 为每路连接准备一个 channel，供网络协程 → 工作协程
	var chs [numConns]chan msg

	// 接受固定数量连接
	conns := make([]net.Conn, numConns)
	for i := 0; i < numConns; i++ {
		c, err := listener.Accept()
		if err != nil {
			fmt.Println("Accept error:", err)
			return
		}
		defer c.Close()
		conns[i] = c
		fmt.Printf("  连接 %d 已建立\n", i+1)
	}

	// 多个网络协程：每个连接一个，阻塞读并写入对应 channel
	for i := 0; i < numConns; i++ {
		id := i + 1
		conn := conns[i]
		chs[i] = make(chan msg)
		go func() {
			networkGoroutine(id, conn, chs[i])
		}()
	}

	// 单个工作协程：select 多路等待，谁先到谁先处理
	go selectPollWorker(ch1, ch2, ch3)

	// 保持运行一段时间以便观察（实际可改为从 channel 收退出信号）
	time.Sleep(5 * time.Second)
	fmt.Println("服务退出")
}

// networkGoroutine 网络协程：从 conn 读数据，写入 ch，读完后关闭 ch
func networkGoroutine(connID int, conn net.Conn, ch chan<- msg) {
	defer close(ch)
	rd := bufio.NewReader(conn)
	for {
		line, err := rd.ReadString('\n')
		if err != nil {
			if err != io.EOF {
				fmt.Printf("[conn %d] read err: %v\n", connID, err)
			}
			return
		}
		ch <- msg{connID: connID, data: line}
	}
}

// selectPollWorker 工作协程：仅此一个，用 select 在多个 channel 上等待
func selectPollWorker(ch1, ch2, ch3 <-chan msg) {
	closed := 0
	for closed < 3 {
		select {
		case m, ok := <-ch1:
			if !ok {
				closed++
				continue
			}
			fmt.Printf("[worker] 来自连接 %d: %s", m.connID, m.data)
		case m, ok := <-ch2:
			if !ok {
				closed++
				continue
			}
			fmt.Printf("[worker] 来自连接 %d: %s", m.connID, m.data)
		case m, ok := <-ch3:
			if !ok {
				closed++
				continue
			}
			fmt.Printf("[worker] 来自连接 %d: %s", m.connID, m.data)
		}
	}
	fmt.Println("[selectPollWorker] 所有连接已关闭，退出")
}

// RunSelectPollDemo 启动服务并启动多个客户端连接、发送数据，演示 select/poll 模型
func RunSelectPollDemo() {
	var wg sync.WaitGroup

	wg.Add(1)
	go func() {
		defer wg.Done()
		SelectPollServer()
	}()

	time.Sleep(200 * time.Millisecond)

	// 多个客户端协程：分别连接并发送数据，由服务端「多网络协程 + 单工作协程」处理
	for i := 0; i < numConns; i++ {
		id := i + 1
		wg.Add(1)
		go func() {
			defer wg.Done()
			conn, err := net.Dial("tcp", serverAddr)
			if err != nil {
				fmt.Printf("客户端 %d 连接失败: %v\n", id, err)
				return
			}
			defer conn.Close()
			for j := 0; j < 2; j++ {
				fmt.Fprintf(conn, "client %d message %d\n", id, j+1)
				time.Sleep(100 * time.Millisecond)
			}
		}()
	}

	wg.Wait()
}
