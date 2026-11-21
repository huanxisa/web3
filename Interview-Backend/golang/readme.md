参考：[golang面试题](https://ncnlo95gua0y.feishu.cn/wiki/R5AKwxAQviB1fpkai9ncY2VIn4f)
✅ 基础知识
1. 如何在Go中实现并发？
Go通过goroutine来实现并发。
goroutine是Go中轻量级线程实现，也被称为协程。
只需在函数调用前加上go关键字即可启动一个新的goroutine。
Go的并发机制基于CSP模型，通过channel在goroutine之间进行通信。
使用这种方式就不需要显式的锁。
go someFunction()

2. 在Go中，如何处理error？
Go通过返回多个值的方式处理错误，通常函数的最后一个返回值是error类型。可以使用标准库中的errors.New或者fmt.Errorf来创建错误，并通过if判断是否有错误发生。
if err != nil {
    fmt.Println("Error occurred:", err)
}

如果需要打印错误堆栈的信息，可以使用第三方库github.com/pkg/errors和github.com/go-errors/errors，对返回的error包装后再返回，这时error会带上堆栈信息。
除了第三方库，也可以使用runtime包，使用runtime.Stack方法获取堆栈信息，并且额外创建一个结构体，包含错误类型以及堆栈信息。
3. 在Go中，如何声明以及实现一个接口？
接口是由一组方法定义的集合，任何实现了这些方法的类型都自动实现了该接口。声明接口使用type关键字，方法没有实现体。实现接口不需要显式声明实现，而是需要某个类型实现某个接口中所有的方法，就会被认为实现了某个接口。
type Animal interface {
    Speak() string
}

type Dog struct{}

func (d Dog) Speak() string {
    return "Woof"
}

4. Go中，init方法的执行机制是什么？什么场景比较适合使用init方法？
init方法会在包的main函数之前执行，且每个包可以有多个init函数。
根据导入的包的深度，从底层逐层往上执行init函数。
init函数用于初始化包的状态，如设置全局变量或执行其他初始化逻辑。
func init() {
    // 初始化代码
}

5. 声明一个变量有哪些方式？
- 使用var关键字
- 短变量声明（:=）
- 批量声明
var x int
y := 10
var a, b = 1, "hello"

6. Go里面有哪些基础类型？
- 数字类型：byte,rune,int, float32, float64, complex64, complex128
- 字符串类型：string
- 布尔类型：bool
- 派生类型：array, slice, map, struct, pointer, function, channel, interface
其中byte,rune,string这三个类型可以相互转换。
7. 两个nil是否相等？
两个nil值的比较结果取决于它们的类型。例如两个interface{}类型的nil值可以比较，相等。
var a, b interface{} = nil, nil
fmt.Println(a == b) // true

8. 怎么声明一个常量？
使用const关键字声明常量。
const Pi = 3.14

9. 怎么声明一个方法？
方法是和类型关联的函数。声明时将接收者参数放在方法名之前。
type Person struct {
    Name string
}

func (p Person) Greet() string {
    return "Hello, " + p.Name
}

10. 怎么创建一个loop？
使用for关键字来创建循环。Go中没有while或do-while循环。
for i := 0; i < 10; i++ {
    fmt.Println(i)
}

当需要无限循环时仅需声明for 和花括号即可。
for {
    fmt.Println(1)
}
11. 怎么创建一个数组？
使用[]定义数组，数组长度是固定的。
var arr [5]int
arr1 := [3]int{1, 2, 3}
arr2 := [...]int{1, 2, 3}
12. 怎么创建一个切片？切片和数组有什么区别？
切片是数组的动态视图，长度可变。使用[]声明切片，但不指定长度。
slice := []int{1, 2, 3}

切片底层是一个结构体，它持有一个数组的指针，并且额外维护了len和cap字段。
len是当前slice可读的元素的长度。
cap是数组指针指向的数组的长度。
使用append向切片添加元素后，必须使用append返回的切片引用，否则会读不到新添加的元素。
13. 怎么创建一个map？
使用make或直接初始化。
m := make(map[string]int)
m["age"] = 30

也可以像声明一个结构体一样。
m := map[string]int{}
m["gender"] = 1
14. 怎么遍历map？怎么获取map中的指定key的value？怎么删除map中的某个元素？
使用for和range遍历，直接使用key访问value，用delete删除元素。
for k, v := range m {
    fmt.Println(k, v)
}

v := m["key"]

delete(m, "key")

15. 是否可以一边遍历map，一边删除map中的元素？
不建议在遍历时删除元素，这样可能导致未定义的行为。
根据情况不同产生不一样的结果。
16. 哪些类型不能作为map的key？
slice、map、function不能作为map的key。因为它们是引用类型，不能比较是否相等。
17. 怎么创建一个指针？引用指针和使用原始类型有什么区别？
使用&获取变量的指针，使用*解引用。
var x int = 10
var p *int = &x
fmt.Println(*p)

区别在于当作为参数传入方法时，方法内对某个字段修改，如果是原始类型，那么就是改变的是一个副本，不会反应到实参。
如果是把指针作为参数传入方法时，在方法内修改某个字段，就会反应到实参，可以读到方法的改动。
18. 怎么创建一个channel？
使用make创建channel，第二个参数是指定channel长度。
ch := make(chan int)
bufferCh := make(chan int, 3)

19. 有缓冲池和无缓冲的channel的区别？
无缓冲channel在发送和接收时必须同步。
缓冲channel则允许异步发送。
缓冲区满前，可以随时写入，不会阻塞，直到缓冲区满后，写入需要等缓冲区有空余位置。
如果缓冲区没有数据，那么读取会阻塞，只要有数据为止。
ch := make(chan int, 2) // 缓冲区大小为2


20. 如何读取channel？
使用<-操作符读取channel。
value := <-ch

21. 怎么关闭一个channel？读取一个关闭的channel会发生什么？怎么判断一个channel已经被关闭了？
使用close关闭channel，读取关闭的channel会返回零值，判断是否关闭可通过第二个返回值。
close(ch)
v, ok := <-ch

22. 什么是goroutine？怎么使用goroutine？怎么停止一个goroutine？
goroutine是Go中的并发执行单元。使用go关键字启动。
可以通过context或channel控制goroutine的停止。
go someFunction()

23. 如何公开一个方法、结构体、以及属性？对应的，私有方法、结构体和属性什么情况下不能被访问到？
首字母大写的标识符是公开的，小写是私有的。私有的标识符只能在包内访问，无法在包外使用。
24. 怎么创建一个包？包相互之间引用会发生什么？怎么避免或者绕过？
创建包时，在文件头部声明package。包之间引用时，可能产生循环依赖，这在Go中会报错。可以通过重构代码或将公共部分提取出来解决。
25. 包(package)与模块(module)之间的区别是什么？
包是Go代码的基本组织单元，模块是多个包的集合，Go模块用于管理包的版本
26. 怎么编译应用为一个可执行二进制文件？
使用go build命令编译代码。
go build main.go

27. Go中nil的切片(Slice)和空的切片有何不同？
nil的切片没有分配任何底层数组，长度和容量为0；空切片已经分配了底层数组，长度为0，但容量可能大于0。
var s []int // nil切片
s := []int{} // 空切片

28. append关键字如何使用？
append用于向切片添加元素。
slice := []int{1, 2}
slice = append(slice, 3)

29. Go中nil的map和空map有何不同？
nil的map没有分配内存，不能直接存储键值对；空map可以存储键值对，但初始为空。
var m map[string]int // nil map
m = make(map[string]int) // 空 map

30. Golang中有哪些标准库？
常用的标准库包括：
- fmt：格式化I/O
- net/http：网络通信
- os：操作系统功能
- encoding/json：JSON处理
- time：时间处理
31. 函数返回局部变量的指针是否安全？
是安全的。Go的内存管理机制会自动扩展局部变量的生命周期。
✅ 中级Golang问题
1. 如何从panic中恢复？或者说如何拦截panic？
使用recover函数可以从panic中恢复。通常配合defer使用。recover只能在发生panic时使用，并且只能捕获当前goroutine中的panic。
func safeFunc() {
    defer func() {
        if r := recover(); r != nil {
            fmt.Println("Recovered from panic:", r)
        }
    }()
    panic("something went wrong")
}

2. Golang中make和new的区别？
new：分配内存，但不初始化。它返回的是类型的指针，通常用于值类型（如数组、结构体）。
make：只用于创建slice、map和channel，并且会初始化这些数据结构，返回的不是指针而是数据类型的引用。
p := new(int)   // *int类型，值为0
s := make([]int, 0)   // []int类型，空切片

3. Golang中函数和方法的接受者可以是值和指针，它们有什么区别？
- 值接收者：函数操作接收者的副本，不能修改原始值。
- 指针接收者：函数操作接收者的引用，可以修改原始值。
type Person struct {
    Name string
}

func (p Person) SetNameValue(newName string) { p.Name = newName }   // 值接收者
func (p *Person) SetNamePointer(newName string) { p.Name = newName } // 指针接收者

4. Golang中非接口的任意类型T()都能够调用*T的方法吗？反过来呢？
可以。如果是值类型T，可以调用指针接收者的方法，Go会自动将值转为指针。
指针类型也可以调用值接收者的方法。
但是只有接受者是指针类型时，才可以修改原始值。
5. 调用函数传入结构体时，应该传值还是指针？
一般传指针。传值会拷贝整个结构体，性能上可能较慢，尤其是大结构体。传指针可以避免拷贝并允许修改原值。
6. Go中uintptr和unsafe.Pointer的区别？
unsafe.Pointer：是一种通用指针类型，用于不同类型指针之间的转换，不参与指针运算。
uintptr：是一个整数类型，用于存储指针值，可以进行指针运算，但与垃圾回收无关。
var p unsafe.Pointer
var u uintptr

7. 怎么读取一个文件？写入呢？
使用os包中的os.Open读取文件，使用os.Create写入文件。
file, err := os.Open("file.txt")
defer file.Close()

output, err := os.Create("output.txt")
defer output.Close()

8. 描述一下defer关键字的作用？什么时候会用到defer？
defer延迟执行函数，直到当前的函数返回后执行。常用于资源释放操作（如关闭文件、解锁互斥锁）。
defer file.Close()

9. 如果同一个方法中声明多个defer，defer的方法怎么执行？
多个defer按照后进先出的顺序执行（LIFO）。
defer fmt.Println("first")
defer fmt.Println("second") // 会先执行second

10. 在循环内部执行defer会发生什么？
如果在循环中使用defer，每次循环都会推入一个defer操作，这些操作会在fangfa 结束后按逆序执行。
11. defer和return的执行先后顺序如何？
defer的执行顺序是在return语句之后，函数退出之前。因此，defer可以在函数返回值已经确定的情况下进行操作。
12. defer是否可以修改返回值？
可以。如果函数声明了命名返回值，defer中可以修改它。
func test() (result int) {
    defer func() { result++ }()
    return 1
}
// 返回2

13. 如何创建一个自定义类型？它的作用是什么？
使用type关键字定义自定义类型，可以让现有类型更具语义或行为。
type Age int

14. 什么是闭包(closure)？可以在哪些地方使用？
闭包是在函数内声明的匿名函数，可以捕获和引用外部作用域变量。常用于回调函数或工厂函数。
func counter() func() int {
    count := 0
    return func() int {
        count++
        return count
    }
}

15. select关键字的作用？描述一下使用场景？
select用于监听多个channel的操作，适用于处理多路channel的并发操作。通常配合无限循环的for使用。
select {
case msg := <-ch1:
    fmt.Println(msg)
case ch2 <- "hello":
    fmt.Println("sent hello")
}

16. 怎么创建一个匿名结构体？
使用struct{}定义匿名结构体。
person := struct {
    Name string
    Age  int
}{Name: "John", Age: 30}

17. 类型如何强转？如何判断变量是否为指定类型？如果变量可能是多种类型，怎么判断？
使用Type Conversion进行类型转换，使用type assertion判断类型。使用switch来处理多种类型的变量。
var i interface{} = 10
v, ok := i.(int)

switch v := i.(type) {
case int:
    fmt.Println("int")
case string:
    fmt.Println("string")
}

18. 两个map之间如何比较是否相等？
Go中无法直接比较两个map，只能遍历两个map手动比较键值对是否相同。
19. 并发情况下时候可以使用基础数据结构map和slice以及array？会发生什么？
Go的map和slice在并发访问下不安全，可能会发生数据竞态，建议使用sync.Mutex或者sync.Map来保证并发安全。
特别是map，当并发访问时，会强制panic。
20. sync包中提供了哪些基础工具？尝试说出三个以上工具的名称以及作用？
sync.Mutex：互斥锁，保证并发访问的安全。
sync.WaitGroup：用于等待一组goroutine完成。
sync.Once：保证某段代码只执行一次。
21. atomic包下提供的类型怎么使用？
sync/atomic提供对基础类型的原子操作，如增减和交换，通常用于无锁并发编程。
var counter int32
atomic.AddInt32(&counter, 1)

22. 怎么使用context包在一个请求作用域内携带上下文相关的数据？如何读取？
使用context.WithValue将数据添加到context中，使用context.Value读取。
ctx := context.WithValue(context.Background(), "key", "value")
value := ctx.Value("key")

23. strings包提供了哪些处理字符串的方法？
常见方法包括：
- strings.Split：分割字符串
- strings.Join：连接字符串
- strings.Contains：检查子字符串是否存在
- strings.Replace：替换子字符串
24. 如果处理一个操作需要花费一些时间处理，应该怎么添加超时检查？如果还没到超时时间，需要取消这个正在执行的操作，应该怎么做？
可以使用context.WithTimeout设置超时，也可以通过context.CancelFunc取消正在执行的操作。
ctx, cancel := context.WithTimeout(context.Background(), time.Second)
defer cancel()

25. 如何使用encode/json包解析和生成JSON字符串？
使用json.Unmarshal解析JSON，使用json.Marshal生成JSON。
err := json.Unmarshal([]byte(data), &v)
jsonData, err := json.Marshal(v)

26. 在Go中怎么创建一个单元测试用例？怎么在命令行下单独执行某个指定的测试用例？
使用testing包编写测试函数，函数名以Test开头。
func TestSomething(t *testing.T) {
    // test code
}

使用命令行执行指定测试用例：
go test -run TestSomething

27. 怎么主动创建一个error？怎么判断一个error是否是特定的error？常见的判断方式是什么？
使用errors.New或fmt.Errorf创建错误，使用errors.Is或类型断言判断错误。
err := errors.New("error message")
if errors.Is(err, specificError) {
    // handle specific error
}

28. Golang的内存模型，为什么小对象多了会造成gc压力？怎么解决？
大量的小对象会增加垃圾回收的频率，导致性能下降。解决方法包括对象池（sync.Pool）或者避免频繁创建对象。
29. 携程、线程、进程的区别？为什么Goroutine比线程轻量？
- 进程：独立运行的程序，具有自己的内存空间。
- 线程：进程的执行单元，共享内存。
- Goroutine：轻量级的线程，Go运行时管理，调度更高效。
Goroutine比线程轻量是因为它们由Go运行时管理，不需要操作系统的线程调度开销。
30. 为什么channel可以做到线程安全？
channel的内部实现使用了同步机制，保证了发送和接收操作的原子性，从而避免了并发冲突。
31. channel是同步还是异步的？
无缓冲的channel是同步的，缓冲的channel是异步的，直到缓冲区满
32. Go中切片如何扩容？
当切片容量不足时，Go会自动扩容，通常是将容量翻倍。使用append函数时，如果超出当前容量，Go会分配一个新的底层数组并复制元素。
33. Go中map如何扩容？
map在元素增多到一定程度时会自动扩容，重新分配哈希桶来存储更多键值对，具体机制由Go的运行时管理

✅ 高级Golang问题
1. Go中如何排查内存泄漏和性能问题？
Go 提供了一些工具和技术来帮助排查内存泄漏和性能问题：
- pprof：net/http/pprof包可以用于生成程序的性能剖析数据（CPU、内存、goroutine等）。
- trace：使用runtime/trace生成追踪文件，分析程序的调度、内存分配等。
- go tool pprof：通过go tool pprof可以分析内存和 CPU 使用情况。
- GODEBUG=gctrace=1：开启 GC 详细日志输出，了解 GC 的频率和耗时。
- heap dump：通过生成堆快照分析内存使用情况。
- runtime.ReadMemStats：手动读取内存统计信息。
go run main.go
go tool pprof http://localhost:6060/debug/pprof/heap

2. Go中channel的底层数据结构与实现？
Go 中的 channel 是通过队列实现的，有缓冲和无缓冲之分。
- 无缓冲 channel：底层使用一个goroutine队列，读写必须同步，即发送方等待接收方，反之亦然。
- 有缓冲 channel：底层维护一个环形队列，写操作将数据存入队列中，读操作从队列中取数据。如果缓冲区满了，写操作阻塞；如果缓冲区为空，读操作阻塞。 底层使用lock-free数据结构与sync/atomic原子操作来保证并发安全。
3. 什么是Data Race？go中如何定位和避免？
Data Race 是指两个或多个 goroutine 并发访问共享变量，并且至少一个是写操作，且这些操作没有适当的同步机制。
定位：
- 使用 -race 选项检测数据竞争。
go run -race main.go

避免方法：
- 使用互斥锁 sync.Mutex 来保护共享资源。
- 使用 channel 进行消息传递，避免直接共享数据。
4. 如何交叉编译？
Go 提供了非常方便的交叉编译支持，只需设置目标系统的 GOOS 和 GOARCH 环境变量
# 为 Linux 编译
GOOS=linux GOARCH=amd64 go build -o output_binary main.go

5. 如何条件编译？
使用编译标签（build tags）实现条件编译。通过在文件头部注释的形式定义标签，并在编译时指定使用哪个标签。
// +build linux

// linux-specific code

在编译时使用：
go build -tags linux

6. Epoll的原理？
epoll 是 Linux 下的 I/O 多路复用机制，它通过事件驱动模型监听大量文件描述符的变化，避免了传统 select/poll 轮询每个文件描述符。epoll 中 epoll_ctl 添加或删除文件描述符，并且 epoll_wait 用于等待这些文件描述符的事件发生。
- Epoll 工作模式：
  - 水平触发（Level-triggered）：当文件描述符就绪时，epoll_wait 一直返回事件，直到条件不再满足。
  - 边缘触发（Edge-triggered）：文件描述符从未就绪变为就绪时才返回事件，避免重复通知。
7. Golang的GC过程？
Golang 使用的垃圾回收器是三色标记-清除算法：
- 标记阶段：从根对象开始，标记所有可达对象。
- 清除阶段：清除所有未标记的对象，释放其内存。
- 并发GC：标记操作与程序的执行并行，减少停顿时间。
- 增量GC：GC 过程以小步增量执行，避免大停顿。
GOGC 环境变量可以控制垃圾回收的频率。
8. Golang中Goroutine是如何调度的？
Go 运行时使用GMP 模型（Goroutine、Machine、Processor）来调度 goroutine。
- G（Goroutine）：代表每个任务或执行单元。
- M（Machine）：表示底层的操作系统线程。
- P（Processor）：代表逻辑处理器，负责将 goroutine 分配给 M。 调度器通过work stealing、抢占式调度、避免锁竞争来提高效率。
9. 描述一下Golang并发机制？以及它所使用的CSP并发模型？
Go 并发是基于 CSP（Communicating Sequential Processes） 模型的，核心是通过 goroutine 和 channel 进行并发编程：
- goroutine：轻量级线程，由 Go 运行时管理。
- channel：用于 goroutine 之间的通信，避免了共享内存的直接操作。
在 CSP 模型中，任务通过消息传递进行通信，确保线程安全。
10. 怎么查看goroutine的数量？怎么限制goroutine的数量？
查看 Goroutine 数量：
- 可以使用 runtime.NumGoroutine() 查看当前的 goroutine 数量。
限制 Goroutine 数量：
- 使用 sync.WaitGroup 来控制并发数，或者使用 semaphore 实现 Goroutine 池。
wg := sync.WaitGroup{}
sem := make(chan struct{}, 10)  // 限制最多10个并发任务

11. Go中如何实现一个携程池？
使用带缓冲的 channel 或 sync.Pool 来实现协程池：
var wg sync.WaitGroup
pool := make(chan struct{}, 5)  // 限制并发数

for i := 0; i < 10; i++ {
    pool <- struct{}{}
    wg.Add(1)
    go func(i int) {
        defer wg.Done()
        // do work
        <-pool  // 释放协程
    }(i)
}

wg.Wait()

12. Go中select的实现原理？
select 通过监听多个 channel 上的操作来实现多路复用。底层实现为遍历所有 case，然后根据 channel 的状态（阻塞或可用）来决定执行哪个分支。内部使用了锁和同步机制来避免并发访问冲突。
13. 描述一下Golang的栈空间管理？
Golang 的栈是自动管理的，初始栈很小（一般是 2KB 左右），当 Goroutine 需要更多栈空间时，Go 会动态扩展栈空间（通过分配新的栈并拷贝旧栈数据）。Go 的栈是连续的，相较于传统操作系统线程的大栈，它的动态增长使得 Goroutine 非常轻量。
14. 描述下Go的对象在内存中的分配过程？
Go 中对象的内存分配分为两种情况：
- 栈上分配：局部变量和小对象通常分配在栈上。
- 堆上分配：当对象超出作用域或者无法确定生命周期时，会在堆上分配。
Go 通过逃逸分析决定变量是否逃逸到堆。运行时通过 mallocgc 函数分配堆内存，并由垃圾回收器管理堆内存的释放。


✅ 常用框架
1. Gin框架如何文件上传？
Gin 支持文件上传，使用 c.Request.FormFile("file") 获取上传的文件并保存到指定位置。
func uploadFile(c *gin.Context) {
    file, _ := c.FormFile("file")
    c.SaveUploadedFile(file, "./uploads/"+file.Filename)
    c.String(http.StatusOK, "File uploaded successfully")
}

2. Gin如何解决跨域问题？如何配置？
Gin 可以通过中间件来解决跨域问题，常用的方式是使用 gin-contrib/cors 包。
安装：
go get github.com/gin-contrib/cors

配置 CORS 中间件：
import "github.com/gin-contrib/cors"

func main() {
    r := gin.Default()
    r.Use(cors.Default()) // 默认允许所有源

    r.Run(":8080")
}

也可以自定义 CORS 配置：
r.Use(cors.New(cors.Config{
    AllowOrigins: []string{"http://example.com"},
    AllowMethods: []string{"GET", "POST"},
    AllowHeaders: []string{"Origin", "Content-Type"},
}))

3. Gin支持哪些HTTP请求方式？
Gin 支持以下 HTTP 请求方式：
- GET
- POST
- PUT
- DELETE
- PATCH
- OPTIONS
- HEAD
4. 如何在Gin中处理GET和POST请求参数？
GET 请求参数：使用 c.Query("param") 获取 URL 中的查询参数。
POST 请求参数：使用 c.PostForm("param") 获取表单数据，或 c.BindJSON(&obj) 获取 JSON 数据。
// 处理 GET 请求参数
func handleGet(c *gin.Context) {
    name := c.Query("name") // ?name=foo
    c.String(http.StatusOK, "Hello %s", name)
}

// 处理 POST 请求参数
func handlePost(c *gin.Context) {
    name := c.PostForm("name")
    c.String(http.StatusOK, "Received %s", name)
}

5. Gin框架中如何实现路由？
Gin 使用 router := gin.Default() 创建路由实例，通过 router.GET、router.POST 等方法来定义路由，并将处理逻辑绑定到相应的 URL 路径和 HTTP 方法。
r := gin.Default()
r.GET("/ping", func(c *gin.Context) {
    c.JSON(200, gin.H{
        "message": "pong",
    })
})
r.Run(":8080")

6. Gin框架的错误处理方式是怎样的？
Gin 使用 Context.AbortWithError() 或 Context.Abort() 来处理错误。可以在中间件中或控制器中间接调用。可以通过自定义中间件统一处理错误。
func errorMiddleware(c *gin.Context) {
    if err := someOperation(); err != nil {
        c.AbortWithError(http.StatusInternalServerError, err)
    }
}

7. Gin框架如何处理并发请求？
Gin 天然支持并发处理请求，每个请求在一个独立的 goroutine 中运行。Gin 使用 Context 进行请求上下文的管理，不会引起并发冲突。
8. Gin框架中Context的作用是什么？
Context 在 Gin 中用于管理请求的上下文信息。它提供了：
- 读写请求参数（GET/POST 参数、路径参数等）
- 处理响应
- 存储和传递中间件之间共享的数据
- 管理请求生命周期（如超时、错误处理）
9. 如何编一个Docker镜像？
创建 Dockerfile，定义应用的构建步骤。
使用 docker build 构建镜像。
FROM golang:1.17-alpine
WORKDIR /app
COPY . .
RUN go build -o app
CMD ["./app"]

docker build -t my-gin-app .

10. Gorm中，查询一条数据，如果没有查到会怎么样？
如果 GORM 查询不到数据，返回的结果对象为空，err 为 gorm.ErrRecordNotFound。你可以检查 err 以确认是否没有找到记录。
if err := db.First(&user).Error; err != nil {
    if errors.Is(err, gorm.ErrRecordNotFound) {
        // 处理记录未找到的情况
    }
}

11. Gorm中，网络连接失败也会报错，如何与没查到数据区分开？
通过检查返回的 err 是否为 gorm.ErrRecordNotFound 来区分未找到数据和其他错误，如网络错误。
if err := db.First(&user).Error; err != nil {
    if errors.Is(err, gorm.ErrRecordNotFound) {
        // 处理没有数据的情况
    } else {
        // 处理其他错误，如网络问题
    }
}

12. Gorm更新数据时数据位0值被忽略了如何解决？
使用 Select() 方法明确指定要更新的字段，或者使用 Updates 方法可以避免默认忽略零值。
db.Model(&user).Updates(User{Name: "Tom", Age: 0})

或者明确选择字段：
db.Model(&user).Select("Age").Updates(User{Age: 0})

13. Gorm与原生方式相比有什么优势？
自动迁移：通过 AutoMigrate 自动创建和更新数据库表结构。
ORM 特性：通过结构体映射数据库表，避免手写 SQL。
事务管理：内置的事务支持，更方便的控制。
查询构造器：提供链式调用的方式构造查询条件，减少 SQL 拼接的风险。
14. Gorm如何实现1对多和多对多的关系映射？
一对多：使用 hasMany 关系，定义结构体中的关联字段。
type User struct {
    ID    uint
    Name  string
    Posts []Post `gorm:"foreignKey:UserID"`
}

type Post struct {
    ID     uint
    Title  string
    UserID uint
}

多对多：使用 many2many 关系，定义中间表。
type User struct {
    ID    uint
    Name  string
    Books []Book `gorm:"many2many:user_books;"`
}

type Book struct {
    ID    uint
   Title string
   Users []User `gorm:"many2many:user_books;"`
}

15. Gorm查询数据库数据时，如何避免N + 1查询问题？
在使用一对多或多对多关系查询时，GORM 的 Preload 方法可以帮助你避免 N + 1 查询问题。Preload 会提前加载关联的数据，避免每次访问关联字段时单独发出 SQL 查询。
var users []User
db.Preload("Posts").Find(&users)

这会在一个 SQL 查询中加载 users 和他们的 posts，避免多次查询。
16. 如何使用Gorm进行事务管理？
GORM 提供了显式的事务管理功能。你可以通过 Begin 开启事务，并使用 Commit 或 Rollback 结束事务。
tx := db.Begin()

// 执行事务内的操作
if err := tx.Create(&user).Error; err != nil {
    tx.Rollback() // 如果出错，回滚
    return
}

if err := tx.Create(&order).Error; err != nil {
    tx.Rollback() // 出错时回滚
    return
}

tx.Commit() // 一切正常，提交事务

17. Gorm中Preload方法和Joins方法的区别是什么？二者各自适合的场景？
- Preload：通过单独的 SQL 查询来加载关联数据，适用于你不需要复杂条件的关联查询。它会先查询主表，再查询关联表的数据。
db.Preload("Posts").Find(&users)

- Joins：通过 SQL JOIN 语句将数据表连接起来一次性查询所有数据，适合复杂的联表查询，性能可能更高。
db.Joins("JOIN posts ON posts.user_id = users.id").Find(&users)

选择场景：
- 当需要一次性加载关联表数据并且没有复杂的条件时，使用 Preload。
- 当需要在查询中使用复杂条件、筛选或排序时，使用 Joins。
18. 如果结构体和数据库中的表名称对应不上时如何解决？
可以通过 GORM 的 Table 方法或 gorm:"tablename" 标签显式指定结构体对应的表名称。
- 通过标签指定表名：
type User struct {
    ID   uint
    Name string
}

func (User) TableName() string {
    return "custom_user_table"
}

- 在查询时动态指定表名：
db.Table("custom_user_table").Find(&users)

这样即使结构体名与数据库表名不一致，也可以正确映射表。