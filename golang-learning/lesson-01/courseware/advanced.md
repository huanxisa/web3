# 第1期 - 进阶特性部分课件

## 课程目标
- 掌握Go语言的接口和多态
- 理解并发编程的核心概念
- 学会使用Goroutine和Channel
- 掌握并发安全技术
- 完成并发编程实践

---

## 第一部分：接口和多态

### 1. 接口的定义和实现

在Go语言中，**接口（interface）**用来描述一组方法签名，任何类型只要实现了接口中声明的全部方法，就被视为满足该接口。Go不要求显式声明“implements”，这被称为**隐式实现**：类型的结构和功能自然地决定了它属于哪个接口。这样的设计让代码更松耦合，也便于我们在不改动已有类型的前提下，为它们赋予新的行为。

由于接口是基于行为的抽象，多种类型可以同时实现同一个接口。比如矩形、圆形都可以实现 `Shape` 接口，只要提供 `Area()` 和 `Perimeter()` 两个方法即可。调用方只关心接口，不关心具体类型，让我们轻松实现多态。

```go
// 定义接口
type Shape interface {
    Area() float64
    Perimeter() float64
}

// 实现接口（隐式实现）
type Rectangle struct {
    Width, Height float64
}

func (r Rectangle) Area() float64 {
    return r.Width * r.Height
}

func (r Rectangle) Perimeter() float64 {
    return 2 * (r.Width + r.Height)
}

// 多个类型实现同一接口
type Circle struct {
    Radius float64
}

func (c Circle) Area() float64 {
    return math.Pi * c.Radius * c.Radius
}

func (c Circle) Perimeter() float64 {
    return 2 * math.Pi * c.Radius
}

// 接口作为参数
func PrintShapeInfo(s Shape) {
    fmt.Printf("Area: %.2f, Perimeter: %.2f\n", 
        s.Area(), s.Perimeter())
}
```

> 课堂提示：示例代码 `lesson-01/examples/advanced/01-interface.go` 在此基础上扩展了三角形实现、可直接运行的数据库示例以及 `WriterCloser` 组合接口的演示，运行 `go run lesson-01/examples/advanced/01-interface.go` 可以看到完整输出。

### 2. 空接口和类型断言

> 课堂提示：空接口 `interface{}` 在 Go 1.18 之前常被用来临时存放“任意类型”，如今更多用于需要和标准库互操作的场景（例如 `fmt` 包、`encoding/json`）以及处理确实不确定类型的数据。

- 空接口使用场景  
  - `fmt.Println`、`log.Print` 等变长参数需要接受任意类型。  
  - `encoding/json` 反序列化到 `map[string]interface{}`，让我们按键提取动态字段。  
  - 抽象事件总线、消息队列时，可以先用空接口承载载荷，后续配合断言或注册回调处理。
- 最佳实践提醒  
  - 提前约定空接口中可能出现的具体类型，配合文档或命名约束。  
  - 优先考虑具体类型或泛型（Go 1.18+），空接口是兜底方案。  
  - 使用类型断言或 `type switch` 时，一定要处理失败分支，避免 `panic`。

```go
// 空接口可以表示任何类型
var value interface{}

value = 42
value = "hello"
value = []int{1, 2, 3}

// 类型断言
func doSomething(v interface{}) {
    // 方式1：类型断言 非常有意思
    if str ok:=v.(string) ok{
        fmt.Println("字符串类型："+str)
    }
    if str, ok := v.(string); ok {
        fmt.Println("是字符串:", str)
    }

    switch data :=v.(type){
        case int: fmt.Println("整数:",data)
        default: fmt.Println("unknow type")
    }
    // 方式2：type switch
    switch data := v.(type) {
    case int:
        fmt.Println("整数:", data)
    case string:
        fmt.Println("字符串:", data)
    case []int:
        fmt.Println("整数切片:", data)
    default:
        fmt.Println("未知类型")
    }
}

func main() {
    // 常见用法：从 map[string]interface{} 中取值并断言具体类型
    payload := map[string]interface{}{
        "id":    1001,
        "name":  "golang",
        "extra": []string{"interface", "assertion"},
    }

    if id, ok := payload["id"].(int); ok {
        fmt.Println("ID:", id)
    }

    // 断言失败时要有兜底处理
    if tags, ok := payload["extra"].([]string); ok {
        fmt.Println("tags:", tags)
    } else {
        fmt.Println("extra 字段不是期望的 []string")
    }
}
```

### 3. 接口组合

```go
// 定义多个接口
type Reader interface {
    Read([]byte) (int, error)
}

type Writer interface {
    Write([]byte) (int, error)
}

// 接口组合
type ReadWriter interface {
    Reader
    Writer
}

// 使用
type File struct {
    name string
}

func (f *File) Read(data []byte) (int, error) {
    // 实现读操作
    return 0, nil
}

func (f *File) Write(data []byte) (int, error) {
    // 实现写操作
    return 0, nil
}
```

### 4. 实战：实现多态性系统

```go
// 定义一个数据库接口
type Database interface {
    Connect() error
    Query(sql string) (interface{}, error)
    Close() error
}

// 实现MySQL数据库
type MySQL struct {
    connection string
}

func (m *MySQL) Connect() error {
    // 连接MySQL
    return nil
}

func (m *MySQL) Query(sql string) (interface{}, error) {
    // 执行查询
    return []string{"result1", "result2"}, nil
}

func (m *MySQL) Close() error {
    // 关闭连接
    return nil
}

// 实现PostgreSQL数据库
type PostgreSQL struct {
    connection string
}

func (p *PostgreSQL) Connect() error {
    // 连接PostgreSQL
    return nil
}

func (p *PostgreSQL) Query(sql string) (interface{}, error) {
    // 执行查询
    return []string{"result1", "result2"}, nil
}

func (p *PostgreSQL) Close() error {
    // 关闭连接
    return nil
}

// 多态使用
func ExecuteQuery(db Database, sql string) {
    db.Connect()
    defer db.Close()
    
    result, err := db.Query(sql)
    if err != nil {
        panic(err)
    }
    fmt.Println("Result:", result)
}
```

### 5. 嵌入实现接口与 has-a / is-a 辨析

Go 没有类继承，多态主要靠**接口 + 实现**。结构体通过**嵌入**（embed）另一种类型时，会获得被嵌入类型的方法，从而可以“少写代码”就实现接口，形式像 Java 的 has-a，效果像 is-a。

**形式区别（核心在“有没有字段名”）**：

| 写法 | 含义 | 是否自动拥有内层类型的方法 | 能否直接当接口用 |
|------|------|----------------------------|------------------|
| `inner SomeType`（**无**字段名） | **嵌入**，方法会提升到外层 | 是 | 是，只需补写要覆盖的方法 |
| `inner SomeType`（**有**字段名，如 `inner`） | **组合**（has-a），持有一个字段 | 否 | 否，需手写转发或自己实现 |

**示例**：

```go
type Greeter interface { SayHello() string }

type DefaultGreeter struct{}
func (DefaultGreeter) SayHello() string { return "Hello" }

// Has-a：有字段名，不会自动拥有方法
type ServerA struct {
    greeter DefaultGreeter  // 必须通过 s.greeter.SayHello() 调用，或手写 SayHello 转发
}

// Is-a（嵌入）：无字段名，自动拥有 DefaultGreeter 的方法
type ServerB struct {
    DefaultGreeter         // 可直接当作 Greeter 用，需要时再在外层定义 SayHello 覆盖
}
```

**和 Java 的对应**：写法上像 Java 的 has-a（结构体里“有一个”别的类型），但 Go 对**无名字段**做了方法提升，行为上像 is-a（自动满足接口、可覆盖）。有名字段就是单纯的 has-a，不会提升方法。

**接口也可以嵌入接口**：在接口里同样可以只写类型名、不写“字段名”，从而把其他接口的**方法声明**合并进来。例如第 3 节的 `ReadWriter` 就是通过嵌入 `Reader` 和 `Writer` 得到全部方法声明：

```go
type ReadWriter interface {
    Reader   // 嵌入：ReadWriter 拥有 Read
    Writer   // 嵌入：ReadWriter 拥有 Write
}
```

这样实现 `ReadWriter` 的类型必须同时实现 `Read` 和 `Write`。接口嵌入只合并“方法集合”，不涉及具体类型或实现，和结构体嵌入的“方法提升”是同一套“只写类型名即嵌入”的语法。

### 6. 省略与重命名：Go 里几种常见含义

Go 里“省略”或“只写一部分”在不同语法位置有不同约定，统一理解有助于少踩坑。

| 场景 | 省略 / 默认 | 不省略 / 显式 | 说明 |
|------|-------------|----------------|------|
| **结构体字段** | 只写类型、不写字段名 → **嵌入**，方法提升 | 写 `名字 类型` → 普通字段（has-a） | 上面第 5 节已详述 |
| **接口内** | 只写接口类型名 → **嵌入**，合并方法声明（如 `Reader`、`Writer`） | 接口不能写“字段名”，只能列方法或嵌入接口 | 第 3 节 ReadWriter、第 5 节接口嵌入示例 |
| **import 包** | 不写别名 → 使用路径**最后一段**作为包名（如 `import "x/y/foo"` 用 `foo`） | `import 别名 "path"` → 用别名访问该包 | 重命名常用于包名冲突或过长路径 |
| **import 仅副作用** | `import _ "path"` → 只执行 init，**不能**用该包里的名字 | — | 空白标识符表示“不用名字” |
| **import 当前作用域** | `import . "path"` → 该包导出名**直接**在当前文件可用，不写包名 | 一般 import 后要写 `pkg.Name` | 易命名冲突，一般仅测试或小范围用 |
| **空白标识符 `_`** | 忽略赋值、忽略 range 的 key 或 value、忽略类型断言结果等 | 写变量名则绑定到该变量 | `_` 表示“这里有意不用” |
| **复合字面量** | 省略键（如 `T{a, b}`）→ 按**字段声明顺序**依次赋值 | 写键（如 `T{X: a, Y: b}`）→ 按名赋值 | 省略键时顺序必须与结构体一致 |

**import 示例**：

```go
import (
    "fmt"                    // 省略别名 → 用 fmt
    f "fmt"                  // 重命名 → 用 f.Println
    _ "database/sql/driver"  // 省略名且用 _ → 只执行 init，不能写 driver.xxx
    . "math"                 // 点导入 → 本文件里可直接写 Pi、Sqrt，不写 math.
)
```

**小结**：结构体里**省略字段名**= 嵌入（is-a 效果）；import 里**省略别名**= 用路径最后一段；用 **`_`** 表示“占位但不用”；用 **`.`** 表示“把包名省掉、直接当当前包用”。其它省略（如复合字面量省略键）则各有语法规定，按上面表格对应即可。

---

## 第二部分：Goroutine入门

### 实战演示：课程示例代码

**示例路径：** `lesson-01/examples/advanced/02-goroutine.go`

**运行方式：**
```bash
go run lesson-01/examples/advanced/02-goroutine.go
```

**示例覆盖的核心知识点：**
- `basicGoroutine()`：并发启动多个goroutine，体验调度顺序的不确定性。
- `waitGroupDemo()`：使用`sync.WaitGroup`等待协程完成，避免主协程提前退出。
- `channelDemo()` 与 `bufferedChannelDemo()`：演示无缓冲与有缓冲channel的发送、接收与关闭。
- `selectDemo()`、`timeoutDemo()`、`nonBlockingDemo()`：展示`select`在多路复用、超时控制与非阻塞通信中的用法。
- `loopSelectDemo()`、`quitChannelDemo()`、`closedChannelDemo()`：演示在循环监听中动态屏蔽已关闭channel、使用退出信号以及读取关闭后零值。
- `fairnessDemo()`：展示`select`面对多个就绪case时的公平性。

> 课堂建议：运行示例时，可以注释/解注部分函数调用，观察输出顺序的变化，加深对调度和同步机制的理解。

### 1. Goroutine的创建和使用

```go
// 基本的goroutine
func sayHello() {
    fmt.Println("Hello from goroutine!")
}

func main() {
    // 启动goroutine
    go sayHello()
    
    // 等待goroutine完成（简单方式） todo：这个地方只需要写个单位就行？
    time.Sleep(time.Second) 
}

// 使用WaitGroup等待
func main() {
    var wg sync.WaitGroup
    
    for i := 0; i < 3; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()
            fmt.Printf("Goroutine %d\n", id)
        }(i)
    }
    
    wg.Wait()
}

func main(){
    var wg sync.WaitGroup
    for i:=0,i<3,i++{
        wg.add(1)
        go func(){
            //通过闭包来共享这个wg变量，然后通知到主协程
        defer wg.Done()
        //doSomething
        }()
    }
    wg.Wai()
}

// 协程泄漏示例（错误的做法）
func leakExample() {
    ch := make(chan int)
    
    go func() {
        ch <- 1 // 永远阻塞，因为没有人接收
    }()
    
    // 应该使用缓冲channel或者接收值
}

func leakExample(){
    //通过 chan管道来写作，效果类似阻塞队列
    ch:=make(chan int)
    go func（）
}
```

### 2. Channel通信机制

```go
// 无缓冲channel（同步）
func channelDemo() {
    ch := make(chan int)
    
    go func() {
        ch <- 42 // 发送数据
    }()
    
    value := <-ch // 接收数据
    fmt.Println(value)
}

// 缓冲channel（异步）
func bufferedChannelDemo() {
    ch := make(chan int, 3) // 缓冲区大小为3
    
    ch <- 1
    ch <- 2
    ch <- 3
    // ch <- 4 // 这里会阻塞，因为缓冲区满了
    
    fmt.Println(<-ch) // 1
    fmt.Println(<-ch) // 2
    fmt.Println(<-ch) // 3
}

//同步和异步是由于中间有一个容器把生产出来的任务存下来了，然后等消费者不忙了然后执行
// channel关闭
func closeChannelDemo() {
    ch := make(chan int, 3)
    ch <- 1
    ch <- 2
    ch <- 3
    close(ch)
    
    // 关闭后的channel仍然可以读取
    // 不能再发送数据
    for value := range ch {
        fmt.Println(value)
    }
}
```

> 示例源码中的 `closedChannelDemo()` 使用 `select` + `default` 的写法，帮助学员看到关闭 channel 后立即返回零值且 `ok=false` 的行为。

### 3. Select语句

#### 3.1 什么是Select？

`select` 是Go语言中用于处理多个channel操作的专用语句，类似于 `switch` 语句，但专门用于channel通信。

**核心概念：**
- `select` 允许goroutine同时等待多个channel操作
- 它会阻塞，直到其中一个case可以执行
- 如果有多个case同时就绪，会**随机选择**一个执行
- 可以用于实现超时、非阻塞操作等并发模式

**基本语法：**
```go
select {
case msg1 := <-ch1:
    // 处理ch1的消息
case msg2 := <-ch2:
    // 处理ch2的消息
case ch3 <- value:
    // 向ch3发送数据
default:
    // 如果所有case都阻塞，执行default（可选）
}
```

#### 3.2 Select的工作原理

**执行流程：**

1. **检查所有case**：`select` 会检查每个case中的channel操作是否可以立即执行
2. **选择就绪的case**：
   - 如果有多个case就绪，**随机选择**一个执行
   - 如果只有一个case就绪，执行该case
   - 如果所有case都阻塞，执行`default`（如果有）
3. **阻塞等待**：如果没有`default`且所有case都阻塞，`select`会阻塞，直到某个case就绪

**关键特性：**
- **随机选择**：当多个case同时就绪时，Go会随机选择一个，这保证了公平性
- **非阻塞**：使用`default`可以实现非阻塞操作
- **超时控制**：结合`time.After`可以实现超时机制

#### 3.3 Select的使用场景

**1. 多路复用（Multiplexing）**

同时监听多个channel，哪个先有数据就处理哪个：

```go
func selectDemo() {
    ch1 := make(chan string)
    ch2 := make(chan string)
    
    go func() {
        time.Sleep(1 * time.Second)
        ch1 <- "from ch1"
    }()
    
    go func() {
        time.Sleep(2 * time.Second)
        ch2 <- "from ch2"
    }()
    
    // 随机选择一个就绪的channel
    select {
    case msg1 := <-ch1:
        fmt.Println(msg1)  // 可能输出："from ch1"
    case msg2 := <-ch2:
        fmt.Println(msg2)  // 可能输出："from ch2"
    }
    // 输出取决于哪个channel先有数据
}
```

**2. 超时控制（Timeout）**

为channel操作设置超时时间，避免无限等待：

```go
func timeoutDemo() {
    ch := make(chan string)
    
    go func() {
        time.Sleep(2 * time.Second)
        ch <- "result"
    }()
    
    select {
    case msg := <-ch:
        fmt.Println("收到:", msg)
    case <-time.After(1 * time.Second):
        fmt.Println("超时了")  // 1秒后输出这个
    }
    // 因为发送需要2秒，但超时是1秒，所以会输出"超时了"
}
```

> 示例 `timeoutDemo()` 中发送端刻意延迟 2 秒，超时设置为 1 秒，现场演示时会输出“超时了”，便于说明 `time.After` 的用法。

**3. 非阻塞操作（Non-blocking）**

使用`default`实现非阻塞的channel操作：

```go
func nonBlockingDemo() {
    ch := make(chan int)
    
    // 非阻塞接收
    select {
    case value := <-ch:
        fmt.Println("收到:", value)
    default:
        fmt.Println("没有值可读（非阻塞）")  // 立即输出这个
    }
    
    // 非阻塞发送
    select {
    case ch <- 42:
        fmt.Println("发送成功")
    default:
        fmt.Println("channel已满，发送失败")
    }
}
```

**4. 循环监听（Loop with Select）**

在循环中使用`select`持续监听多个channel：

```go
func loopSelect() {
    ch1 := make(chan int)
    ch2 := make(chan string)
    done := make(chan bool)
    
    go func() {
        for i := 0; i < 5; i++ {
            ch1 <- i
            time.Sleep(100 * time.Millisecond)
        }
        close(ch1)
    }()
    
    go func() {
        for i := 0; i < 3; i++ {
            ch2 <- fmt.Sprintf("msg-%d", i)
            time.Sleep(150 * time.Millisecond)
        }
        close(ch2)
    }()
    
    // 持续监听，直到所有channel都关闭
    for {
        select {
        case val, ok := <-ch1:
            if !ok {
                ch1 = nil  // 关闭的channel设为nil，select会忽略它
                continue
            }
            fmt.Println("ch1:", val)
        case msg, ok := <-ch2:
            if !ok {
                ch2 = nil
                continue
            }
            fmt.Println("ch2:", msg)
        default:
            // 如果没有数据，可以做其他事情
            if ch1 == nil && ch2 == nil {
                fmt.Println("所有channel已关闭")
                return
            }
        }
    }
}
```

**5. 退出信号（Quit Channel）**

使用`select`处理退出信号：

```go
func quitChannelDemo() {
    jobs := make(chan int)
    quit := make(chan bool)
    
    // 工作goroutine
    go func() {
        for {
            select {
            case job := <-jobs:
                fmt.Printf("处理任务: %d\n", job)
            case <-quit:
                fmt.Println("收到退出信号")
                return
            }
        }
    }()
    
    // 发送任务
    for i := 0; i < 5; i++ {
        jobs <- i
    }
    
    // 发送退出信号
    quit <- true
    time.Sleep(100 * time.Millisecond)
}
```

#### 3.4 Select的执行机制详解

**1. 随机选择的公平性**

当多个case同时就绪时，Go会**随机选择**一个，这保证了公平性：

```go
func fairnessDemo() {
    ch1 := make(chan int)
    ch2 := make(chan int)
    
    // 同时向两个channel发送数据
    go func() {
        for i := 0; i < 10; i++ {
            ch1 <- i
        }
        close(ch1)
    }()
    
    go func() {
        for i := 0; i < 10; i++ {
            ch2 <- i * 10
        }
        close(ch2)
    }()
    
    // 持续接收，随机选择就绪的channel
    for i := 0; i < 20; i++ {
        select {
        case val, ok := <-ch1:
            if !ok {
                ch1 = nil
                continue
            }
            fmt.Printf("ch1: %d\n", val)
        case val, ok := <-ch2:
            if !ok {
                ch2 = nil
                continue
            }
            fmt.Printf("ch2: %d\n", val)
        }
    }
    // 输出顺序是随机的，体现了公平性
}
```

> 源码 `fairnessDemo()` 会同时关闭两个 channel 并持续 `select`，运行后可以观察不同运行下的输出顺序，便于说明公平性。

**2. Select的阻塞行为**

```go
// 没有default：会阻塞
select {
case <-ch1:
    // ...
case <-ch2:
    // ...
}
// 如果ch1和ch2都阻塞，select会一直等待

// 有default：不会阻塞
select {
case <-ch1:
    // ...
case <-ch2:
    // ...
default:
    // 立即执行这个
}
// 如果ch1和ch2都阻塞，立即执行default
```

**3. 关闭channel的处理**

当channel关闭后：
- 从关闭的channel接收数据，会立即返回零值，`ok`为`false`
- 向关闭的channel发送数据，会panic
- 在select中，关闭的channel可以设置为`nil`，select会忽略它

```go
func closedChannelDemo() {
    ch := make(chan int)
    close(ch)
    
    select {
    case val, ok := <-ch:
        fmt.Printf("val: %d, ok: %v\n", val, ok)  // val: 0, ok: false
    default:
        fmt.Println("default")
    }
}
```

#### 3.5 Select的常见模式

**模式1：超时模式**
```go
select {
case result := <-ch:
    // 处理结果
case <-time.After(3*time.Second):
    fmt.Println("有点慢啊")
case <-time.After(5 * time.Second):
    // 超时处理
    return errors.New("操作超时")
}
```

**模式2：取消模式**
```go
ctx, cancel := context.WithCancel(context.Background())
defer cancel()

select {
case result := <-ch:
    // 处理结果
case <-ctx.Done():
    // 取消操作
    return ctx.Err()
}
```

**context 设计理念与常用方法**

- **设计理念**：`context` 用来在调用链中传递「请求域」信息（取消信号、截止时间、键值），并在一处取消时让整条链都能收到。典型场景：HTTP 请求、RPC、多级 goroutine，父级取消则子级应一并退出。
- **常用创建方式**：
  - `context.Background()`：根 context，一般用于 main、初始化、测试、以及所有「已知从当前开始建树」的入口。下面案例中的根 context 都用它（如 `context.WithCancel(context.Background())`）。
  - `context.TODO()`：占位根 context，**行为与 Background() 相同**（都是空 context），用在「暂时还不确定根 context 从哪来」的占位，便于以后替换成真实传入的 ctx；例如库函数将来会由调用方传入 ctx，当前先写 `ctx := context.TODO()`。
  - `ctx, cancel := context.WithCancel(parent)`：可取消；调用 `cancel()` 后 `ctx.Done()` 关闭。
  - `ctx, cancel := context.WithTimeout(parent, d)`：带超时；**入参是「相对时长」**（如 `2*time.Second`），从调用时刻起算，到期或 `cancel()` 都会关闭 `ctx.Done()`。
  - `ctx, cancel := context.WithDeadline(parent, t)`：带截止时间；**入参是「绝对时间」**（如 `time.Now().Add(2*time.Second)` 或某个固定 `time.Time`）。**与 WithTimeout 的区别**：WithTimeout(parent, d) 等价于 WithDeadline(parent, time.Now().Add(d))；选哪个只看你手头是「时长」还是「截止时刻」更方便。
  - `ctx := context.WithValue(parent, key, val)`：在链上挂键值，子级用 `ctx.Value(key)` 取。
- **常用方法**：
  - `ctx.Done()`：返回只读 channel，context 被取消或超时时关闭，用于 select 中配合退出。
  - `ctx.Err()`：取消后返回原因，如 `context.Canceled`、`context.DeadlineExceeded`，未取消时为 nil。
  - `ctx.Deadline()`：若有截止时间则返回 (deadline, true)，否则 (zero, false)。
  - `ctx.Value(key)`：取 WithValue 挂载的值，无则返回 nil。
- **使用约定**：context 作为函数第一个参数传递；收到 `<-ctx.Done()` 后应尽快返回，并把 `ctx.Err()` 向上层返回；不要用 context 传业务可选参数，只传请求域相关数据。

**使用案例**

- **补充：Background / TODO 与 WithDeadline / WithTimeout**

```go
// Background()：作为根 context，下面所有案例的 parent 都用它 todo
ctx := context.Background()

// TODO()：占位用，行为同 Background()，语义是「这里以后会换成调用方传入的 ctx」
func placeholderHandler() {
    ctx := context.TODO() // 暂时没有调用方传入的 ctx，先占位
    _ = ctx
}

// WithTimeout = 相对时长；WithDeadline = 绝对截止时间（二者等价关系如下）
deadline := time.Now().Add(3 * time.Second)
ctxT, cancelT := context.WithTimeout(context.Background(), 3*time.Second)
ctxD, cancelD := context.WithDeadline(context.Background(), deadline)
defer cancelT()
defer cancelD()
// ctxT 与 ctxD 都是 3 秒后过期，仅入参形式不同：时长 vs 绝对时间
```

- **案例1：WithCancel — 父取消则子退出**

```go
ctx, cancel := context.WithCancel(context.Background())
defer cancel()

go func() {
    for {
        select {
        case <-ctx.Done():
            fmt.Println("子 goroutine 收到取消，退出:", ctx.Err())
            return
        default:
            time.Sleep(500 * time.Millisecond)
            fmt.Println("子 goroutine 工作中...")
        }
    }
}()

time.Sleep(2 * time.Second)
cancel() // 父主动取消，上面 goroutine 会退出
time.Sleep(500 * time.Millisecond)
```

- **案例2：WithTimeout — 带超时的等待**

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()

ch := make(chan string, 1)
go func() {
    time.Sleep(3 * time.Second) // 模拟慢操作
    ch <- "result"
}()

select {
case v := <-ch:
    fmt.Println("收到:", v)
case <-ctx.Done():
    fmt.Println("超时或取消:", ctx.Err()) // 会走这里，输出 context.DeadlineExceeded
}
```

- **案例3：WithValue — 在调用链中传递请求 ID**

```go
type ctxKey string
const requestIDKey ctxKey = "requestID"

func handler(ctx context.Context) {
    ctx = context.WithValue(ctx, requestIDKey, "req-123")
    doDB(ctx)
}

func doDB(ctx context.Context) {
    id, _ := ctx.Value(requestIDKey).(string)
    fmt.Println("请求 ID:", id) // 输出 请求 ID: req-123
}

handler(context.Background())
```

**协程中传递 context**：可以用 `go doDB(ctx)` 在协程里执行，同一份 `ctx` 会传进协程；若上层调用 `cancel()`，协程里也能通过 `ctx.Done()` 感知并退出。例如：

```go
func handlerAsync(ctx context.Context) {
    ctx = context.WithValue(ctx, requestIDKey, "req-123")
    go doDB(ctx) // 协程中执行，ctx 照常传递
}

// doDB 若需支持取消，可在长操作中轮询 ctx.Done()
func doDBWithCancel(ctx context.Context) {
    id, _ := ctx.Value(requestIDKey).(string)
    select {
    case <-ctx.Done():
        fmt.Println("请求被取消, id:", id)
        return
    default:
        fmt.Println("请求 ID:", id)
        // 模拟耗时操作，期间若 ctx 被取消可提前 return
    }
}
```

- **案例4：多级 goroutine 统一取消**

```go
ctx, cancel := context.WithCancel(context.Background())
defer cancel()

for i := 0; i < 3; i++ {
    go func(id int) {
        <-ctx.Done()
        fmt.Printf("worker %d 退出\n", id)
    }(i)
}

time.Sleep(100 * time.Millisecond)
cancel() // 一次取消，上面 3 个 goroutine 都会收到 Done() 并退出
time.Sleep(200 * time.Millisecond)
```

**模式3：优先级模式**

**注意**：单纯一个 `select` 里并列多个 `case <-ch` 时，若**多个 channel 同时有数据**，Go 会**随机选一个**执行，**不会**按 case 顺序或“紧急优先”。下面左栏写法**不能**保证紧急优先。

若要**真正优先处理紧急**，需要先**非阻塞地看紧急 channel**，没有再看普通 channel（右栏）：

```go
// todo：错误理解：select 不会按 case 顺序优先，多路就绪时随机选
select {
case urgent := <-urgentChan:
    handleUrgent(urgent)
case normal := <-normalChan:
    handleNormal(normal)
default:
    doIdleWork()
}

// 正确做法：先单独看紧急 channel（非阻塞），没有再处理普通
select {
case urgent := <-urgentChan:
    handleUrgent(urgent)
default:
    select {
    case normal := <-normalChan:
        handleNormal(normal)
    default:
        doIdleWork()
    }
}
```

**模式4：心跳模式**
```go
ticker := time.NewTicker(1 * time.Second)
defer ticker.Stop()

for {
    select {
    case <-ticker.C:
        // 定期执行的任务
        heartbeat()
    case msg := <-messages:
        // 处理消息
        handleMessage(msg)
    }
}
```

#### 3.6 Select的注意事项

**1. 避免空的select**
```go
// ❌ 错误：空的select会永远阻塞
select {}

// ✅ 正确：至少有一个case
select {
case <-ch:
    // ...
}
```

**2. 处理关闭的channel**
```go
// ✅ 正确：检查channel是否关闭
select {
case val, ok := <-ch:
    if !ok {
        ch = nil  // 设置为nil，select会忽略它
        continue
    }
    // 处理val
}
```

**3. 避免在select中发送到nil channel**
```go
var ch chan int  // nil channel

// ⚠️ 注意：向nil channel发送会永远阻塞
select {
case ch <- 42:  // 这会永远阻塞
    fmt.Println("发送成功")
default:
    fmt.Println("不会执行到这里")
}
```

**4. 在循环中使用select**
```go
// ✅ 正确：使用break退出select，继续循环
for {
    select {
    case <-ch:
        // 处理
        break  // 只退出select，不退出for循环
    }
}

// ✅ 正确：使用标签退出外层循环
loop:
for {
    select {
    case <-ch:
        break loop  // 退出外层for循环
    }
}
```

**5. Select的性能考虑**
- `select`本身性能开销很小
- 但频繁使用`default`可能浪费CPU（忙等待）
- 在循环中使用`select`时，可以考虑添加适当的延迟

#### 3.7 实战示例

```go
// 基本select
func selectDemo() {
    ch1 := make(chan string)
    ch2 := make(chan string)
    
    go func() {
        time.Sleep(1 * time.Second)
        ch1 <- "from ch1"
    }()
    
    go func() {
        time.Sleep(2 * time.Second)
        ch2 <- "from ch2"
    }()
    
    // 随机选择一个就绪的channel
    select {
    case msg1 := <-ch1:
        fmt.Println(msg1)
    case msg2 := <-ch2:
        fmt.Println(msg2)
    }
}

// select with timeout
func timeoutDemo() {
    ch := make(chan string)
    
    go func() {
        time.Sleep(2 * time.Second)
        ch <- "result"
    }()
    
    select {
    case msg := <-ch:
        fmt.Println("收到:", msg)
    case <-time.After(1 * time.Second):
        fmt.Println("超时了")
    }
}

// select with default（非阻塞）
func nonBlockingDemo() {
    ch := make(chan int)
    
    select {
    case value := <-ch:
        fmt.Println(value)
    default:
        fmt.Println("没有值可读")
    }
}
```
### chan 和 select 额外补充资料

#### 1. 动态数量的 channel 怎么 select？

语言自带的 `select { case v := <-ch1: ... case v := <-ch2: ... }` 的 case 数量必须在**编译期**写死。若 channel 数量是**运行时**才确定的（例如从 slice 里来），需要用 **`reflect.Select`** 在「多个 channel」上做多路等待：

```go
import "reflect"

// chs 是 []chan T 或 []<-chan T，动态长度
func selectDynamic(chs []chan int) {
	cases := make([]reflect.SelectCase, len(chs))
	for i, ch := range chs {
		cases[i] = reflect.SelectCase{
			Dir:  reflect.SelectRecv,
			Chan: reflect.ValueOf(ch),
		}
	}
	chosen, recv, ok := reflect.Select(cases) // 谁先就绪选谁
	// chosen 是下标，recv 是收到的值，ok 表示 channel 是否未关闭
	_ = chosen
	_ = recv
	_ = ok
}
```

- **Dir**：`reflect.SelectRecv`（接收）、`reflect.SelectSend`（发送）、`reflect.SelectDefault`（default）。
- **Chan**：`reflect.ValueOf(ch)`，ch 为 nil 时该 case 会被忽略。

#### 2. `case ch <- x` 的用法示例

select 里除了「从 channel 收」还可以「往 channel 发」，谁先不阻塞就执行谁。典型用法：**非阻塞发送**或**多路「收/发」一起等**。

```go
ch := make(chan int, 1)
ch <- 1 // 已有一个元素

select {
case v := <-ch:
    fmt.Println("收到", v)
case ch <- 2:
    fmt.Println("发送成功")
default:
    fmt.Println("ch 满且无数据可读")
}
// 若 ch 有缓冲且未满，可能走 case ch <- 2；若已有数据可读，可能走 case v := <-ch
```

**常见场景**：向多个 worker 发任务，谁先能收就发给谁（多路 `case taskCh <- task`）；或同时等「收到结果」和「超时」（`case <-time.After(...)`）。

---

#### 3. channel 声明与用法速查

channel 同时涉及「类型 + 方向 + 操作」，下面按类型、创建、操作、参数、select 罗列，便于对照。

**（1）类型（3 种）**

| 写法 | 含义 | 能做的操作 |
|------|------|------------|
| `chan T` | 双向 channel，元素类型 T | 可发送、可接收 |
| `<-chan T` | 只读 channel | 只能**接收**（`x := <-ch`） |
| `chan<- T` | 只写 channel | 只能**发送**（`ch <- x`） |

记忆：箭头指向 channel = 接收；箭头从 channel 指出 = 发送。

**（2）创建与变量声明**

| 写法 | 含义 |
|------|------|
| `make(chan T)` | 无缓冲 channel（发送会阻塞直到有人接收） |
| `make(chan T, n)` | 带缓冲 channel，容量 n |
| `var ch chan T` | ch 为 nil，未初始化，不能直接用 |
| `ch := make(chan int)` | 创建并赋值给变量（常见写法） |

**（3）操作（发送 / 接收 / 关闭）**

| 写法 | 含义 |
|------|------|
| `ch <- x` | 发送：把 x 发到 ch |
| `x := <-ch` | 接收：从 ch 读一个值赋给 x |
| `<-ch` | 接收但丢弃值 |
| `x, ok := <-ch` | 接收；ch 已关闭时 x 为零值，ok 为 false |
| `close(ch)` | 关闭 ch（只能由发送方关闭，且只关一次） |

**（4）在函数参数里（类型 + 方向）**

| 参数写法 | 含义 |
|----------|------|
| `ch chan T` | 双向，函数里可读可写 |
| `ch <-chan T` | 只读，函数里只能 `<-ch` |
| `ch chan<- T` | 只写，函数里只能 `ch <- x` |

**（5）与 channel 相关的控制流**

| 写法 | 含义 |
|------|------|
| `for v := range ch` | 从 ch 一直接收，直到 ch 被 close |
| `select { case v := <-ch: ... }` | 多路 channel，谁先就绪执行谁（接收） |
| `select { case ch <- x: ... }` | 多路 channel，谁先就绪执行谁（发送） |

**（6）nil / 已关闭 的约定**

| 情况 | 行为 |
|------|------|
| 向 nil channel 发送 | 一直阻塞 |
| 从 nil channel 接收 | 一直阻塞 |
| 关闭 nil channel | panic |
| 向已关闭的 channel 发送 | panic |
| 从已关闭的 channel 接收 | 不阻塞，返回零值 + ok=false |
| 关闭已关闭的 channel | panic |

**（7）按「你在写什么」快速查**

- 写**类型** → `chan T` / `<-chan T` / `chan<- T`
- **建 channel** → `ch := make(chan T)` 或 `make(chan T, n)`
- **发/收** → 发：`ch <- x`；收：`x := <-ch` 或 `x, ok := <-ch`
- **参数只读/只写** → `<-chan T`（只读）、`chan<- T`（只写）
- **channel 数量动态** → 用 `reflect.Select` 在 slice 上多路等待

---

### 4. 实战：生产者消费者模式

```go
func producer(ch chan<- int) {
    for i := 0; i < 10; i++ {
        ch <- i
        time.Sleep(100 * time.Millisecond)
    }
    close(ch)
}

func consumer(ch <-chan int, id int) {
    for value := range ch {
        fmt.Printf("Consumer %d received: %d\n", id, value)
        time.Sleep(50 * time.Millisecond)
    }
}

func main() {
    ch := make(chan int, 5)
    
    go producer(ch)
    
    // 多个消费者
    for i := 0; i < 3; i++ {
        go consumer(ch, i)
    }
    
    time.Sleep(2 * time.Second)
}
```

**拓展示例：使用 `goroutine` + `select` 管理停止信号**

```go
func producer(ctx context.Context, id int, queue chan<- int) {
    defer log.Printf("producer %d exit", id)

    for {
        item := rand.Intn(1000)
        select {
        case queue <- item:
            log.Printf("producer %d -> %d\n", id, item)
        case <-ctx.Done():
            return
        }
        time.Sleep(300 * time.Millisecond)
    }
}

func consumer(ctx context.Context, id int, queue <-chan int) {
    defer log.Printf("consumer %d exit", id)

    for {
        select {
        case item := <-queue:
            log.Printf("consumer %d <- %d\n", id, item)
        case <-ctx.Done():
            return
        }
    }
}

func main() {
    rand.Seed(time.Now().UnixNano())

    queue := make(chan int, 5)
    ctx, cancel := context.WithCancel(context.Background())

    for i := 0; i < 2; i++ {
        go producer(ctx, i+1, queue)
    }

    for i := 0; i < 3; i++ {
        go consumer(ctx, i+1, queue)
    }

    time.Sleep(3 * time.Second)
    cancel()
    time.Sleep(500 * time.Millisecond)

    fmt.Println("done")
}
```

> 要点：`queue` 用作缓冲队列，`select` 既能处理数据通路，又能监听 `ctx.Done()` 实现优雅退出，避免 goroutine 泄漏。

---

## 第三部分：并发安全

### 1. Mutex和RWMutex

```go
// 使用Mutex保护共享资源
type SafeCounter struct {
    mu    sync.Mutex
    count int
}

type MutexExample stuct {
    lock sync.Mutex
    count int
}

func (e *MutexExample) Increnent(){
    e.lock.Lock()
    defer lock.Unlock()
    e.count++
}

func (e *MutexExample) Decrease(){
    e.lock.Lock()
    defer e.lock.Unlock()
    e.count--
}

func (sc *SafeCounter) Increment() {
    sc.mu.Lock()
    defer sc.mu.Unlock()
    sc.count++
}

func (sc *SafeCounter) GetCount() int {
    sc.mu.Lock()
    defer sc.mu.Unlock()
    return sc.count
}

// 使用RWMutex（读多写少场景）
type SafeData struct {
    mu     sync.RWMutex
    data   map[string]int
}

func (sd *SafeData) Read(key string) int {
    sd.mu.RLock() // 读锁
    defer sd.mu.RUnlock()
    return sd.data[key]
}

func (sd *SafeData) Write(key string, value int) {
    sd.mu.Lock() // 写锁
    defer sd.mu.Unlock()
    sd.data[key] = value
}
```

### 2. WaitGroup同步

```go
func waitGroupDemo() {
    var wg sync.WaitGroup
    mu := sync.Mutex{}
    sum := 0
    
    // 启动多个goroutine
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()
            
            // 执行一些工作
            time.Sleep(100 * time.Millisecond)
            
            // 更新共享变量
            mu.Lock()
            sum += id
            mu.Unlock()
        }(i)
    }
    
    wg.Wait() // 等待所有goroutine完成
    fmt.Println("Sum:", sum)
}
```

**与 Java JUC 的对应：** `sync.WaitGroup` 可以类比为 Java 的 **CountDownLatch**，都是「计数到 0 再继续」的同步方式：`Add(n)` 相当于设定或增加计数，`Done()` 相当于 `countDown()`，`Wait()` 相当于 `await()`。区别在于 CountDownLatch 的计数一般在创建时固定，而 WaitGroup 可以随时 `Add`，因此更适合「边启动 goroutine 边增加计数」的写法，更灵活。

### 3. Context上下文控制

#### 3.1 什么是Context？

`context.Context` 是Go语言标准库中用于**跨goroutine传递取消信号、超时、截止时间和请求范围值**的标准方式。它是并发控制的核心工具。

**核心概念：**
- Context在多个goroutine之间传播控制信号
- Context是不可变的，每次派生都会创建新的Context
- Context是线程安全的，可以安全地在多个goroutine中使用
- Context形成树形结构，父Context取消时，所有子Context也会被取消

**主要用途：**
1. **取消控制**：取消长时间运行的操作
2. **超时控制**：为操作设置超时时间
3. **截止时间**：设置操作必须完成的最后期限
4. **传递值**：在请求范围内传递元数据（如trace ID、用户ID等）

#### 3.2 Context的类型

Go提供了几种创建Context的方法：

**1. context.Background()**

根Context，通常用于main函数、初始化或测试中。它永远不会被取消、没有值、没有截止时间。

```go
func main() {
    ctx := context.Background()
    // 作为根context使用
}
```

**2. context.TODO()**

当不确定使用哪个Context时使用，通常是占位符，表示"稍后会替换成真正的Context"。

```go
func someFunction() {
    ctx := context.TODO()  // 待完善
    // ...
}
```

**3. context.WithCancel(parent)**

创建可取消的Context，返回Context和cancel函数。调用cancel函数会取消该Context及其所有子Context。

```go
ctx, cancel := context.WithCancel(context.Background())
defer cancel()  // 确保释放资源
```

**4. context.WithTimeout(parent, timeout)**

创建有超时时间的Context，超时后自动取消。等价于`WithDeadline(parent, time.Now().Add(timeout))`。

```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()  // 即使未超时也应该调用，释放资源
```

**5. context.WithDeadline(parent, deadline)**

创建有截止时间的Context，到达截止时间后自动取消。

```go
deadline := time.Now().Add(10 * time.Second)
ctx, cancel := context.WithDeadline(context.Background(), deadline)
defer cancel()
```

**6. context.WithValue(parent, key, value)**

创建携带键值对的Context，用于传递请求范围的数据。**不要滥用！**

```go
type contextKey string
const userIDKey contextKey = "userID"

ctx := context.WithValue(context.Background(), userIDKey, "user123")
```

#### 3.3 Context的基本使用

**1. 取消控制示例**

```go
func cancellableDemo() {
	fmt.Println("=== 可取消的Context ===")
	
	ctx, cancel := context.WithCancel(context.Background())
	
	// 启动工作goroutine
	go func() {
		for {
			select {
			case <-ctx.Done():
				fmt.Println("Goroutine收到取消信号:", ctx.Err())
				return
			default:
				fmt.Println("工作中...")
				time.Sleep(500 * time.Millisecond)
			}
		}
	}()
	
	// 工作2秒后取消
	time.Sleep(2 * time.Second)
	fmt.Println("发送取消信号")
	cancel()
	
	// 等待goroutine退出
	time.Sleep(500 * time.Millisecond)
}
```

**2. 超时控制示例**

```go
func timeoutContextDemo() {
	fmt.Println("=== 超时Context ===")
	
	// 设置1秒超时
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()
	
	ch := make(chan string)
	
	// 模拟一个耗时2秒的操作
	go func() {
		time.Sleep(2 * time.Second)
		ch <- "result"
	}()
	
	select {
	case result := <-ch:
		fmt.Println("收到结果:", result)
	case <-ctx.Done():
		fmt.Println("操作超时:", ctx.Err())  // 输出: context deadline exceeded
	}
}
```

**3. 截止时间示例**

```go
func deadlineContextDemo() {
	fmt.Println("=== 截止时间Context ===")
	
	// 设置3秒后的截止时间
	deadline := time.Now().Add(3 * time.Second)
	ctx, cancel := context.WithDeadline(context.Background(), deadline)
	defer cancel()
	
	// 检查剩余时间
	if d, ok := ctx.Deadline(); ok {
		fmt.Printf("截止时间: %v, 剩余: %v\n", d, time.Until(d))
	}
	
	// 等待超过截止时间
	time.Sleep(4 * time.Second)
	
	select {
	case <-ctx.Done():
		fmt.Println("已超过截止时间:", ctx.Err())
	default:
		fmt.Println("未超时")
	}
}
```

**4. 传递值示例**

```go
type contextKey string

const (
	requestIDKey contextKey = "requestID"
	userIDKey    contextKey = "userID"
)

func valueContextDemo() {
	fmt.Println("=== Context传递值 ===")
	
	// 创建携带值的context
	ctx := context.Background()
	ctx = context.WithValue(ctx, requestIDKey, "req-123")
	ctx = context.WithValue(ctx, userIDKey, "user-456")
	
	// 在函数中读取值
	processRequest(ctx)
}

func processRequest(ctx context.Context) {
	if reqID := ctx.Value(requestIDKey); reqID != nil {
		fmt.Printf("Request ID: %v\n", reqID)
	}
	
	if userID := ctx.Value(userIDKey); userID != nil {
		fmt.Printf("User ID: %v\n", userID)
	}
}
```

#### 3.4 Context的高级使用场景

**场景1：级联取消（父取消，子也取消）**

```go
func cascadeCancelDemo() {
	fmt.Println("=== 级联取消示例 ===")
	
	// 创建父context
	parentCtx, parentCancel := context.WithCancel(context.Background())
	defer parentCancel()
	
	// 创建子context
	childCtx1, cancel1 := context.WithCancel(parentCtx)
	defer cancel1()
	
	childCtx2, cancel2 := context.WithCancel(parentCtx)
	defer cancel2()
	
	// 启动子goroutine
	go worker(childCtx1, "Worker 1")
	go worker(childCtx2, "Worker 2")
	
	time.Sleep(1 * time.Second)
	
	// 取消父context，所有子context也会被取消
	fmt.Println("取消父context")
	parentCancel()
	
	time.Sleep(500 * time.Millisecond)
}

func worker(ctx context.Context, name string) {
	for {
		select {
		case <-ctx.Done():
			fmt.Printf("%s: 收到取消信号\n", name)
			return
		default:
			fmt.Printf("%s: 工作中...\n", name)
			time.Sleep(300 * time.Millisecond)
		}
	}
}
```

**场景2：HTTP请求超时控制**

```go
func httpRequestDemo() {
	// 创建5秒超时的context
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	// 创建HTTP请求
	req, err := http.NewRequestWithContext(ctx, "GET", "https://example.com", nil)
	if err != nil {
		fmt.Println("创建请求失败:", err)
		return
	}
	
	// 发送请求
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			fmt.Println("请求超时")
		} else {
			fmt.Println("请求失败:", err)
		}
		return
	}
	defer resp.Body.Close()
	
	fmt.Println("请求成功:", resp.StatusCode)
}
```

**场景3：数据库查询超时**

```go
func databaseQueryDemo(db *sql.DB) {
	// 创建3秒超时的context
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	
	// 执行查询
	rows, err := db.QueryContext(ctx, "SELECT * FROM users WHERE active = ?", true)
	if err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			fmt.Println("数据库查询超时")
		} else {
			fmt.Println("查询失败:", err)
		}
		return
	}
	defer rows.Close()
	
	// 处理结果
	for rows.Next() {
		// ...
	}
}
```

**场景4：多个goroutine协同工作**

```go
func multiWorkerDemo() {
	fmt.Println("=== 多worker协同工作 ===")
	
	ctx, cancel := context.WithCancel(context.Background())
	var wg sync.WaitGroup
	
	// 启动多个worker
	for i := 1; i <= 3; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for {
				select {
				case <-ctx.Done():
					fmt.Printf("Worker %d: 退出\n", id)
					return
				default:
					fmt.Printf("Worker %d: 处理任务\n", id)
					time.Sleep(500 * time.Millisecond)
				}
			}
		}(i)
	}
	
	// 工作2秒后取消所有worker
	time.Sleep(2 * time.Second)
	fmt.Println("发送取消信号给所有worker")
	cancel()
	
	// 等待所有worker退出
	wg.Wait()
	fmt.Println("所有worker已退出")
}
```

**场景5：Context在Pipeline中的应用**

```go
func pipelineDemo() {
	fmt.Println("=== Pipeline示例 ===")
	
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	
	// Stage 1: 生成数据
	dataCh := generateData(ctx)
	
	// Stage 2: 处理数据
	processedCh := processData(ctx, dataCh)
	
	// Stage 3: 输出结果
	for result := range processedCh {
		fmt.Println("最终结果:", result)
	}
	
	fmt.Println("Pipeline完成")
}

func generateData(ctx context.Context) <-chan int {
	ch := make(chan int)
	go func() {
		defer close(ch)
		for i := 0; i < 10; i++ {
			select {
			case <-ctx.Done():
				fmt.Println("生成器: 收到取消信号")
				return
			case ch <- i:
				fmt.Println("生成器: 生成", i)
				time.Sleep(300 * time.Millisecond)
			}
		}
	}()
	return ch
}

func processData(ctx context.Context, input <-chan int) <-chan int {
	ch := make(chan int)
	go func() {
		defer close(ch)
		for data := range input {
			select {
			case <-ctx.Done():
				fmt.Println("处理器: 收到取消信号")
				return
			case ch <- data * 2:
				fmt.Println("处理器: 处理", data, "->", data*2)
			}
		}
	}()
	return ch
}
```

#### 3.5 Context的最佳实践

**1. 传递Context的规则**

✅ **正确做法：**
```go
// 将Context作为第一个参数传递
func DoSomething(ctx context.Context, arg1 string, arg2 int) error {
	// ...
}

// 方法中也应遵循相同规则
func (s *Service) Process(ctx context.Context, data string) error {
	// ...
}
```

❌ **错误做法：**
```go
// 不要把Context放在struct中
type Service struct {
	ctx context.Context  // 不推荐
	// ...
}

// 不要把Context作为最后一个参数
func DoSomething(arg1 string, arg2 int, ctx context.Context) error {
	// ...
}
```

> **若不遵守的后果：** 把 Context 放进 struct 或放在参数最后，会破坏「ctx 作为首参」的惯例，中间层、包装函数难以统一透传；把 ctx 存进 struct 还会让 Context 的生命周期与请求/调用脱钩（struct 可能长期存活），导致取消信号或请求范围的值被误用到其他请求，难以排查。

**2. 不要存储Context**

❌ **错误做法：**
```go
type Server struct {
	ctx context.Context  // 不要这样做
}

func (s *Server) Start() {
	s.ctx = context.Background()  // 不要这样做
}
```

✅ **正确做法：**
```go
type Server struct {
	// 不存储context
}

func (s *Server) Start(ctx context.Context) {
	// 直接使用传入的context
}
```

> **若不遵守的后果：** Context 是请求/调用粒度的，存进长期存在的 struct 后，同一个 context 会被复用到多次请求或调用，导致 A 请求的取消、超时或 WithValue 影响 B 请求；父 context 已取消时仍持有引用也会产生难以理解的行为，甚至造成 goroutine/资源无法及时回收。

**3. 不要传递nil Context**

❌ **错误做法：**
```go
func DoWork(ctx context.Context) {
	// ...
}

// 调用时
DoWork(nil)  // 不要传nil
```

✅ **正确做法：**
```go
// 如果不确定用什么context，使用context.TODO()
DoWork(context.TODO())

// 或者使用context.Background()
DoWork(context.Background())
```

> **若不遵守的后果：** 对 nil Context 调用 `ctx.Done()`、`ctx.Err()`、`ctx.Value()`、`ctx.Deadline()` 会**直接 panic**；若上层未做 nil 判断就向下传递，整条调用链都可能崩溃，且难以在测试或生产中发现。

**4. Context.Value使用原则**

只用于传递请求范围的数据，不要用于传递可选参数。

✅ **适合使用Context.Value的场景：**
- Request ID（请求追踪）
- User ID（用户认证）
- Trace ID（分布式追踪）
- Request-scoped metadata

❌ **不适合使用Context.Value的场景：**
- 函数的可选参数
- 配置信息
- 依赖注入

```go
// ✅ 正确：传递请求范围的元数据
type contextKey string
const requestIDKey contextKey = "requestID"

func handler(w http.ResponseWriter, r *http.Request) {
	requestID := generateRequestID()
	ctx := context.WithValue(r.Context(), requestIDKey, requestID)
	
	processRequest(ctx, r)
}

// ❌ 错误：用Context传递配置
ctx := context.WithValue(context.Background(), "config", config)  // 不要这样做
```

> **若不遵守的后果：** 用 Context 传可选参数、配置或依赖会形成「隐式入参」：函数签名看不出真实依赖，单测必须凑齐各种 key 的 context；配置也不是请求范围的，容易在跨请求复用上产生歧义。用 Context 做依赖注入还会让生命周期和请求脱钩，不利于理解和维护。

**5. 总是调用cancel函数**

```go
// ✅ 正确：使用defer确保cancel被调用
func DoWork() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()  // 即使未超时，也要调用cancel释放资源
	
	// ...
}

// ❌ 错误：忘记调用cancel
func DoWork() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	// 忘记调用cancel，会造成资源泄漏
	
	// ...
}
```

> **若不遵守的后果：** 不调用 `cancel` 会导致**资源泄漏**：WithCancel/WithTimeout/WithDeadline 创建的 context 会一直持有其 channel 和（若有）定时器，父 context 也会保留对子节点的引用，无法被 GC 回收；WithTimeout 的 timer 不停止会持续触发。官方文档明确说明不调用 cancel 会泄漏，高并发下会拖垮进程。

**6. 检查Context是否已取消**

```go
func DoWork(ctx context.Context) error {
	// 在开始工作前检查
	if err := ctx.Err(); err != nil {
		return err
	}
	
	// 在长时间操作中定期检查
	for i := 0; i < 1000; i++ {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}
		
		// 执行工作
		doSomething(i)
	}
	
	return nil
}
```

> **若不遵守的后果：** 长时间操作中不检查 `ctx.Done()` 或 `ctx.Err()`，则请求已取消或超时后 goroutine 仍会继续执行，白占 CPU 和内存；用户已离开或超时，服务端仍在处理，无法把取消信号传递到下游，导致延迟升高、资源浪费，甚至产生重复或无效写操作。

**7. Context错误处理**

```go
func handleContextError(ctx context.Context) {
	err := ctx.Err()
	
	switch err {
	case context.Canceled:
		fmt.Println("操作被取消")
	case context.DeadlineExceeded:
		fmt.Println("操作超时")
	case nil:
		fmt.Println("Context仍然有效")
	default:
		fmt.Println("未知错误:", err)
	}
}
```

> **若不遵守的后果：** 不区分 `context.Canceled` 与 `context.DeadlineExceeded`，或与普通错误一视同仁，会导致错误的业务逻辑：例如被用户取消的请求被当成可重试错误反复重试、超时与主动取消无法在日志或监控中区分、无法给用户或上游返回合适的提示，增加排查成本和误告警。

#### 3.6 Context实战示例

**完整示例：构建一个支持取消和超时的任务系统**

```go
package main

import (
	"context"
	"fmt"
	"math/rand"
	"sync"
	"time"
)

// Task 表示一个任务
type Task struct {
	ID       int
	Duration time.Duration
}

// TaskManager 任务管理器
type TaskManager struct {
	tasks []Task
	mu    sync.Mutex
}

// AddTask 添加任务
func (tm *TaskManager) AddTask(task Task) {
	tm.mu.Lock()
	defer tm.mu.Unlock()
	tm.tasks = append(tm.tasks, task)
}

// ExecuteTask 执行单个任务
func (tm *TaskManager) ExecuteTask(ctx context.Context, task Task) error {
	fmt.Printf("任务 %d: 开始执行\n", task.ID)
	
	// 模拟任务执行
	select {
	case <-time.After(task.Duration):
		fmt.Printf("任务 %d: 执行完成\n", task.ID)
		return nil
	case <-ctx.Done():
		fmt.Printf("任务 %d: 被取消 (%v)\n", task.ID, ctx.Err())
		return ctx.Err()
	}
}

// ExecuteAll 执行所有任务
func (tm *TaskManager) ExecuteAll(ctx context.Context) {
	var wg sync.WaitGroup
	
	tm.mu.Lock()
	tasks := tm.tasks
	tm.mu.Unlock()
	
	for _, task := range tasks {
		wg.Add(1)
		go func(t Task) {
			defer wg.Done()
			tm.ExecuteTask(ctx, t)
		}(task)
	}
	
	wg.Wait()
	fmt.Println("所有任务处理完成")
}

func main() {
	// 创建任务管理器
	tm := &TaskManager{}
	
	// 添加任务
	rand.Seed(time.Now().UnixNano())
	for i := 1; i <= 5; i++ {
		tm.AddTask(Task{
			ID:       i,
			Duration: time.Duration(rand.Intn(3)+1) * time.Second,
		})
	}
	
	// 创建带超时的context
	ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
	defer cancel()
	
	// 启动监听取消信号的goroutine
	go func() {
		time.Sleep(2 * time.Second)
		fmt.Println("\n⚠️  手动触发取消信号")
		cancel()
	}()
	
	// 执行所有任务
	fmt.Println("开始执行任务...")
	tm.ExecuteAll(ctx)
	
	// 检查context状态
	if ctx.Err() == context.DeadlineExceeded {
		fmt.Println("\n❌ 任务执行超时")
	} else if ctx.Err() == context.Canceled {
		fmt.Println("\n❌ 任务被手动取消")
	} else {
		fmt.Println("\n✅ 所有任务正常完成")
	}
}
```

#### 3.7 Context常见问题

**Q1: Context.Value会有性能问题吗？**

A: Context.Value的查找是链式查找，性能是O(n)，n是context链的深度。因此：
- 不要嵌套太深
- 不要频繁调用Value
- 考虑在函数入口处一次性提取所需的值

**Q2: 为什么不能在struct中存储Context？**

A: Context的生命周期通常绑定到请求，存储在struct中会导致：
- 生命周期混乱
- 难以控制取消信号的传播
- 可能导致goroutine泄漏

**Q3: Context.WithValue的key为什么要用自定义类型？**

A: 使用自定义类型作为key可以避免不同包之间的key冲突。

```go
// ✅ 正确
type contextKey string
const myKey contextKey = "myKey"

// ❌ 不推荐
const myKey = "myKey"  // string类型容易冲突
```
> Go 里 key 是否“相同”要看类型 + 值。每个包定义自己的 key 类型，类型不同就算字符串一样也是不同的 key

**Q4: 如何在多层函数调用中传递Context？**

A: 将Context作为第一个参数逐层传递：

```go
func Handler(ctx context.Context) {
	// 传递给下一层
	Service(ctx)
}

func Service(ctx context.Context) {
	// 传递给下一层
	Repository(ctx)
}

func Repository(ctx context.Context) {
	// 使用context
}
```

> **配套示例：** `lesson-01/examples/advanced/03-context.go` 包含了本节所有示例的可运行代码。运行 `go run lesson-01/examples/advanced/03-context.go` 可以看到完整的演示效果。

### 4. 实战：并发安全的计数器

```go
type SafeCounter struct {
    mu       sync.RWMutex
    counters map[string]int
}

func NewSafeCounter() *SafeCounter {
    return &SafeCounter{
        counters: make(map[string]int),
    }
}

func (sc *SafeCounter) Increment(key string) {
    sc.mu.Lock()
    defer sc.mu.Unlock()
    sc.counters[key]++
}

func (sc *SafeCounter) Get(key string) int {
    sc.mu.RLock()
    defer sc.mu.RUnlock()
    return sc.counters[key]
}

func (sc *SafeCounter) GetAll() map[string]int {
    sc.mu.RLock()
    defer sc.mu.RUnlock()
    
    result := make(map[string]int)
    for k, v := range sc.counters {
        result[k] = v
    }
    return result
}
```

---

## 第四部分：GMP调度机制

### 1. Goroutine背后的执行模型

Go 运行时采用 **G-M-P（Goroutine、Machine、Processor）调度模型** 支撑高并发。三者职责分别是：

- `G`（Goroutine）：用户级协程，包含栈、状态等上下文，是被调度的基本单元。
- `M`（Machine）：映射到操作系统线程，用于真正执行 `G`。
- `P`（Processor）：逻辑处理器，持有可运行 `G` 的本地队列，并维护内存分配缓存。

只有当 `G` 绑定到 `P`，再由拥有该 `P` 的某个 `M` 执行时，协程才会真正运行，形成 `G → P → M` 的执行链路。[参考](https://go.cyub.vip/gmp/gmp-model/)

### 2. 调度关键机制

- **本地队列优先**：`M` 首先从自身绑定的 `P` 的本地队列中取 `G`，避免全局锁。
- **Work Stealing**：本地队列为空时，`M` 会从其他 `P` 窃取一半就绪 `G`，保证均衡。
- **全局队列兜底**：全局可运行队列确保没有 `P` 被饿死。
- **自旋复用线程**：没有可运行 `G` 时，`M` 会短暂自旋等待，减少频繁创建/销毁线程。
- **Hand Off 机制**：当 `G` 因系统调用阻塞，`P` 会解绑并交给其他空闲 `M`，维持整体吞吐。

### 3. 实用调试建议

- 通过 `GODEBUG=schedtrace=1000` 观察 `gomaxprocs`、`threads`、`runqueue` 等调度指标。
- 使用 `go tool trace` 获取更详细的时间线视图，分析 `G` 的生命周期。
- 结合 `WaitGroup`、`context` 管理 `G` 的退出和取消，可以更好地配合调度器。[参考](https://go.cyub.vip/gmp/gmp-model/)

**配套示例：** `lesson-01/examples/advanced/06-gmp.go` 会创建一批 CPU 密集型 goroutine，并调整 `GOMAXPROCS`。可搭配命令  
`GODEBUG=schedtrace=1000,scheddetail=1 go run lesson-01/examples/advanced/06-gmp.go` 现场观察调度日志。

课堂演示建议：结合 `runtime.GOMAXPROCS`、`schedtrace` 输出以及示例 `loopSelectDemo()`、`workerPool` 等场景，让学员直观看到调度模型对任务分发与线程利用率的影响。

#### 日志解析示例

课堂可先运行 `06-gmp.go` 并捕获 `schedtrace` 日志（示例日志存放在 `lesson-01/examples/advanced/gmp.log`）。引导学员按以下顺序阅读：

1. **时间与概要行**（如 `SCHED 1000ms`）：关注 `gomaxprocs`、`threads`、`idleprocs`、`runqueue` 等全局指标，判断当前是否存在排队或空闲。
2. **P 列表**：观察 `status`、`runqsize`、`m` 等字段，讨论为什么某些 `P` 空闲、某些 `P` 上有 backlog，以及 `syscalltick` 激增意味着什么。
3. **M 列表**：确认线程是否处于 `spinning` 或 `blocked`，说明 Goroutine 进入阻塞时 runtime 如何复用/挂起 M。
4. **G 列表**：结合 `status=1/2/4`，让学员识别 `sync.WaitGroup.Wait`、`chan send/receive` 等典型阻塞场景，理解 G 与 M、P 的绑定关系。

延伸问题：调低 `schedtrace` 的采样间隔（如 `schedtrace=100`）或调节 `GOMAXPROCS`，让学员比较日志变化，巩固 Work Stealing 和 Hand Off 的概念。[参考](https://go.cyub.vip/gmp/gmp-model/)

---

## 第五部分：并发编程最佳实践（5分钟）

### 1. 常见错误和陷阱

```go
// ❌ 错误1：没有等待goroutine
go someFunc() // goroutine还没执行完，main就结束了

// ✅ 正确
var wg sync.WaitGroup
wg.Add(1)
go func() {
    defer wg.Done()
    someFunc()
}()
wg.Wait()

// ❌ 错误2：闭包捕获循环变量 在循环变量中采用闭包接收循环参数 todo：是不是意味着即使不是循环，如果采用闭包来捕获变量也有可能造成结果的不可预知性,比如说变量在主协程后面更改了，而启动的协程由于调度的时机不同所以看到的变量不一样

//协程里可以用闭包；但要避免闭包去捕获「会变且你希望固定成启动时那一刻」的变量，这类变量应通过参数传入
for i := 0; i < 3; i++ {
    go func() {
        fmt.Println(i) // 可能输出都是3
    }()
}

// ✅ 正确
for i := 0; i < 3; i++ {
    go func(id int) {
        fmt.Println(id) // 输出正确的值
    }(i)
}

// ❌ 错误3：channel没有关闭
go func() {
    for i := 0; i < 10; i++ {
        ch <- i
    }
    // 忘记close(ch)
}()
> 不关闭的话，接收方无法区分「暂时没数据」和「已经发完」，只好用别的约定,不能安全地用 for range,该关不关会放大这类「不明原因的阻塞」，排查成本高。

// ❌ 错误4：在goroutine中不使用recover
go func() {
    panic("oops") // 会导致整个程序崩溃
}()
> 使用上的取舍
默认用 error（包括 errors.New）：错误通过返回值一层层传上去，由调用方决定怎么处理，符合 Go 的惯用法。
少用 panic：只在“继续执行没有意义”时用（如启动时配置/依赖缺失、明显是程序 bug 的“不可能”分支），或在明确会 recover 的顶层（如 HTTP 框架里接住 panic 避免整个进程挂掉）。
一句话：errors.New() 是造一个错误值并正常返回；panic() 是立刻终止当前执行并向上崩。一个走“返回值 + 判断”，一个走“异常式控制流”，用法和语义都不同

// ✅ 正确
go func() {
    defer func() {
        if r := recover(); r != nil {
            fmt.Println("捕获panic:", r)
        }
    }()
    // 可能panic的代码
}()
```

### 2. 性能优化建议

```go
// 1. 避免频繁创建goroutine
// ❌ 不好：在循环中频繁创建
for _, item := range items {
    go func(it Item) {
        process(it)
    }(item)
}

// ✅ 更好：使用worker pool
func workerPool(items []Item, numWorkers int) {
    jobs := make(chan Item, len(items))
    
    // 启动worker
    for w := 0; w < numWorkers; w++ {
        go func() {
            for item := range jobs {
                process(item)
            }
        }()
    }
    
    // 发送任务
    for _, item := range items {
        jobs <- item
    }
    close(jobs)
    
    // 等待完成...
}

// 2. 使用缓冲channel提高性能
ch := make(chan int, 100) // 根据实际情况设置缓冲区大小

// 3. 合理使用context超时
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
```

---

## 第六部分：标准库与项目实战

### 1. 常用标准库

```go
// JSON编解码
type Person struct {
    Name string `json:"name"`
    Age  int    `json:"age"`
}

func jsonDemo() {
    p := Person{Name: "Alice", Age: 30}
    
    // 编码
    data, _ := json.Marshal(p)
    fmt.Println(string(data))
    
    // 解码
    var p2 Person
    json.Unmarshal(data, &p2)
    fmt.Println(p2)
}

// 文件操作
func fileDemo() {
    // 读取文件
    data, err := ioutil.ReadFile("file.txt")
    if err != nil {
        panic(err)
    }
    fmt.Println(string(data))
    
    // 写入文件
    err = ioutil.WriteFile("output.txt", []byte("Hello"), 0644)
    if err != nil {
        panic(err)
    }
}

// 时间处理
func timeDemo() {
    now := time.Now()
    fmt.Println("当前时间:", now)
    fmt.Println("格式化:", now.Format("2006-01-02 15:04:05"))
    
    // 解析时间
    t, _ := time.Parse("2006-01-02", "2024-01-01")
    fmt.Println("解析的时间:", t)
    
    // 计算时间差
    duration := time.Now().Sub(t)
    fmt.Println("时间差:", duration)
}

// 加密哈希
func hashDemo() {
    data := "Hello World"
    
    // SHA256
    h := sha256.New()
    h.Write([]byte(data))
    fmt.Printf("SHA256: %x\n", h.Sum(nil))
    
    // MD5
    m := md5.New()
    m.Write([]byte(data))
    fmt.Printf("MD5: %x\n", m.Sum(nil))
}
```

### 2. 项目实战：构建一个简单的Web爬虫

参见实战代码：`examples/practice/web-crawler.go`

---

## 课后作业

1. **接口练习：**
   - 实现一个支付系统
   - 支持多种支付方式（支付宝、微信、银行卡）
   - 使用接口实现多态

2. **并发练习：**
   - 实现一个并发安全的日志系统
   - 使用goroutine异步写入日志
   - 使用WaitGroup确保所有日志都被写入

3. **综合练习：**
   - 实现一个简单的任务调度器
   - 支持并发执行多个任务
   - 使用context控制任务超时

---

## 总结

通过本部分学习，你应该掌握：

1. ✅ 接口的定义和实现
2. ✅ 空接口和类型断言
3. ✅ 接口组合和多态
4. ✅ Goroutine的创建和使用
5. ✅ Channel的通信机制
6. ✅ Select语句的使用
7. ✅ GMP调度机制原理
8. ✅ 并发安全（Mutex、RWMutex）
9. ✅ WaitGroup同步
10. ✅ Context上下文控制
11. ✅ 并发编程的最佳实践
12. ✅ 常用标准库的使用

**恭喜！** 你已经掌握了Go语言的核心语法和并发编程！
