// 本文件仅用于说明 Go 中 "has a" 与 "is a"（嵌入）在形式上的区别。
// 因含 //go:build ignore，普通 go build 不会编译此文件；阅读完可删除。
//
//go:build ignore

package main

// ========== 假设有这样一个接口 ==========
type Greeter interface {
	SayHello() string
}

// ========== 以及一个已实现该接口的类型 ==========
type DefaultGreeter struct{}

func (DefaultGreeter) SayHello() string {
	return "Hello (default)"
}

// ========== 1. Has-a：持有一个字段，有名字 ==========
// 形式：结构体里有一个「带名字」的字段，类型是 DefaultGreeter。
// 不会自动拥有 DefaultGreeter 的方法，不能当作 Greeter 用，要自己转发。
type ServerWithHasA struct {
	greeter DefaultGreeter // 有名字的字段 → has-a
	// 其他业务字段...
}

// 想对外表现成 Greeter，必须手写方法，内部调用 s.greeter.SayHello()
func (s *ServerWithHasA) SayHello() string {
	return s.greeter.SayHello()
}

// 若没有上面这个 SayHello，ServerWithHasA 就不实现 Greeter 接口。

// ========== 2. Is-a（嵌入）：无名字段，只有类型 ==========
// 形式：结构体里有一个「没有名字」的字段，只有类型名。
// 会自动拥有 DefaultGreeter 的所有方法（方法提升），可直接当作 Greeter 用。
type ServerWithIsA struct {
	DefaultGreeter // 无名字段，只有类型 → 嵌入，效果像 is-a
	// 其他业务字段...
}

// 不需要写 SayHello：ServerWithIsA 已经通过嵌入「继承」了 SayHello。
// 若要自定义行为，可以再定义同名方法，即「覆盖」嵌入的方法：
// func (s *ServerWithIsA) SayHello() string { return "custom" }

// ========== 使用方式对比 ==========
func exampleUsage() {
	// Has-a：必须自己实现接口方法（或像上面那样手写转发）
	var _ Greeter = (*ServerWithHasA)(nil) // 能赋值，因为手写了 SayHello

	// Is-a：不用写 SayHello 就实现了接口
	var _ Greeter = (*ServerWithIsA)(nil)

	// 形式区别总结：
	// - Has-a:  greeter DefaultGreeter  （有字段名 greeter）
	// - Is-a:    DefaultGreeter         （无字段名，只有类型）
}
