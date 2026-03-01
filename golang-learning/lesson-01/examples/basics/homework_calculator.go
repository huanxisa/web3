package main

import (
	"errors"
	"fmt"
)

// Calculator 结构体
type HomeWorkCalculator struct {
	history []string
}

// NewHomeWorkCalculator 创建新的作业计算器
func NewHomeWorkCalculator() *HomeWorkCalculator {
	return &HomeWorkCalculator{
		history: make([]string, 0),
	}
}

func (c *HomeWorkCalculator) Add(numbers ...float64) (float64, error) {
	total := 0.0
	for _, num := range numbers {
		total += num
	}
	c.AddHistory(fmt.Sprintf("Add: %v = %.2f", numbers, total))
	return total, nil
}

func (c *HomeWorkCalculator) Sub(a float64, b ...float64) (float64, error) {
	start := a
	// 历史格式: "Sub: 被减数 - 减数1 - 减数2 - ... = 结果"
	record := fmt.Sprintf("Sub: %.2f", start)
	for _, num := range b {
		a -= num
		record += fmt.Sprintf(" - %.2f", num)
	}
	record += fmt.Sprintf(" = %.2f", a)
	c.AddHistory(record)
	return a, nil
}

func (c *HomeWorkCalculator) Mul(a ...float64) (float64, error) {
	if len(a) == 0 {
		return 0, errors.New("至少需要输入一个数字")
	}
	total := 1.0
	for _, num := range a {
		total *= num
	}
	c.AddHistory(fmt.Sprintf("Mul: %v = %.2f", a, total))
	return total, nil
}

func (c *HomeWorkCalculator) Div(a float64, b ...float64) (float64, error) {
	if len(b) == 0 {
		return 0, errors.New("至少需要输入一个数字")
	}
	total := a
	for _, num := range b {
		if num == 0 {
			return 0, errors.New("除数不能为0")
		}
		total /= num
	}
	c.AddHistory(fmt.Sprintf("Div: %.2f ÷ %v = %.2f", a, b, total))
	return total, nil
}

func (c *HomeWorkCalculator) AddHistory(record string) {
	c.history = append(c.history, record)
}

func (c *HomeWorkCalculator) RemoveHistory() {
	c.history = c.history[:0]
}

func main() {
	calc := NewHomeWorkCalculator()
	calc.Add(1.0, 2.0, 3.0, 4.0, 5.0)
}
