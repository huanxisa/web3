package main

import "fmt"

// ========== 1. 泛型函数：单类型参数 ==========
func Print[T any](s []T) {
	for _, v := range s {
		fmt.Print(v, " ")
	}
	fmt.Println()
}

func Print1[T any](s []T) {
	for _, v := range s {
		fmt.Print(v, " ")
	}
	fmt.Println()
}

// ========== 2. 泛型函数：多类型参数 ==========
func Map[K, V any](keys []K, fn func(K) V) []V {
	result := make([]V, len(keys))
	for i, k := range keys {
		result[i] = fn(k)
	}
	return result
}

func Map1[k, v any](keys []k, fn func(k) v) []v {
	result := make([]v, len(keys))
	for i, key := range keys {
		result[i] = fn(key)
	}
	return result
}

// ========== 3. 类型约束：comparable（可 == 比较） ==========
func Contains[T comparable](slice []T, x T) bool {
	for _, v := range slice {
		if v == x {
			return true
		}
	}
	return false
}

// ========== 4. 自定义约束：要求类型有某方法 ==========
type Stringer interface {
	String() string
}

func PrintStringers[T Stringer](items []T) {
	for _, v := range items {
		fmt.Println(v.String())
	}
}

// ========== 5. 联合约束：T 只能是 int | float64 | string ==========
type NumberOrString interface {
	int | float64 | string
}

func Double[T NumberOrString](x T) T {
	// 实际使用时需 type switch 或反射，这里仅作约束示例
	return x
}

// ========== 6. 近似约束 ~T：底层类型为 T 的类型也可 ==========
type MyInt int

type Integer interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64
}

func Sum[T Integer](nums []T) T {
	var sum T
	for _, n := range nums {
		sum += n
	}
	return sum
}

// ========== 7. 泛型类型（结构体） ==========
type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

func (s *Stack[T]) Pop() (T, bool) {
	if len(s.items) == 0 {
		var zero T
		return zero, false
	}
	v := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return v, true
}

// ========== 8. 泛型类型（切片别名） ==========
type Vector[T any] []T

func (v Vector[T]) Last() (T, bool) {
	if len(v) == 0 {
		var zero T
		return zero, false
	}
	return v[len(v)-1], true
}

// ========== 9. 泛型接口 ==========
type Container[T any] interface {
	Len() int
	At(i int) T
}

type SliceContainer[T any] []T

func (s SliceContainer[T]) Len() int   { return len(s) }
func (s SliceContainer[T]) At(i int) T { return s[i] }

func PrintContainer[T any](c Container[T]) {
	for i := 0; i < c.Len(); i++ {
		fmt.Print(c.At(i), " ")
	}
	fmt.Println()
}

// ========== 10. 实例化与调用示例 ==========
func main() {
	// 1. 泛型函数
	Print([]int{1, 2, 3})
	Print([]string{"a", "b", "c"})

	// 2. 多类型参数
	squares := Map([]int{1, 2, 3}, func(x int) int { return x * x })
	Print(squares)

	// 3. comparable
	fmt.Println(Contains([]int{1, 2, 3}, 2))
	fmt.Println(Contains([]string{"a", "b"}, "c"))

	// 5. 联合约束（Double 需具体实现略）
	_ = Double(1)
	_ = Double("hello")

	// 6. 近似约束：MyInt 底层是 int，满足 Integer
	fmt.Println(Sum([]MyInt{1, 2, 3}))
	fmt.Println(Sum([]int{1, 2, 3}))

	// 7. 泛型类型
	st := Stack[int]{}
	st.Push(1)
	st.Push(2)
	if v, ok := st.Pop(); ok {
		fmt.Println("Pop:", v)
	}

	// 8. 泛型切片
	vec := Vector[string]{"x", "y", "z"}
	if last, ok := vec.Last(); ok {
		fmt.Println("Last:", last)
	}

	// 9. 泛型接口
	sc := SliceContainer[int]([]int{10, 20, 30})
	PrintContainer(sc)
}
