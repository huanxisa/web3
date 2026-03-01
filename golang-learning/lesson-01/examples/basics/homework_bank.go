package main

import (
	"fmt"
	"sort"
	"time"
)

type Transaction struct {
	Amount      float64
	Timestamp   time.Time
	Description string
}

type BankAccount struct {
	Balance       float64
	Owner         string
	AccountNumber string
	transactions  []Transaction
}

func NewBankAccount(owner, accountNumber string) *BankAccount {
	return &BankAccount{
		Balance:       0,
		Owner:         owner,
		AccountNumber: accountNumber,
		transactions:  make([]Transaction, 10)}
}

func (b *BankAccount) Deposit(amount float64) {
	b.Balance += amount
	b.transactions = append(b.transactions, Transaction{
		Amount:      amount,
		Timestamp:   time.Now(),
		Description: "Deposit " + fmt.Sprintf("%.2f", amount),
	})
}

func (b *BankAccount) Withdraw(amount float64) {
	if b.Balance < amount {
		panic("余额不足")
	}
	b.Balance -= amount
	b.transactions = append(b.transactions, Transaction{
		Amount:      amount,
		Timestamp:   time.Now(),
		Description: "Withdraw " + fmt.Sprintf("%.2f", amount),
	})
}

func (b *BankAccount) GetBalance() float64 {
	return b.Balance
}

func (b *BankAccount) GetTransactions() []Transaction {
	return b.transactions
}

// GetTransaction 返回 [start, end] 时间范围内的交易（假定 transactions 按 Timestamp 升序）
func (b *BankAccount) GetTransaction(start, end time.Time) []Transaction {
	txs := b.transactions
	n := len(txs)
	// 下界：第一个 Timestamp >= start 的索引
	lower := sort.Search(n, func(i int) bool {
		return !txs[i].Timestamp.Before(start)
	})
	// 上界：第一个 Timestamp > end 的索引（不包含）
	upper := sort.Search(n, func(i int) bool {
		return txs[i].Timestamp.After(end)
	})
	if lower >= upper {
		return nil
	}
	return txs[lower:upper]
}