package main

import "fmt"

type Student struct {
	Name  string
	Age   int
	Score int
	ID    int
}

func NewStudent(name string, age, score, ID int) *Student {
	return &Student{
		Name:  name,
		Age:   age,
		Score: score,
		ID:    ID,
	}
}

type Teacher struct {
	Name    string
	Age     int
	Subject string
	ID      int
}

func NewTeacher(name, subject string, age, ID int) *Teacher {
	return &Teacher{
		Name:    name,
		Age:     age,
		Subject: subject,
		ID:      ID,
	}
}

type Class struct {
	ID       int
	Name     string
	Teacher  *Teacher
	students map[int]*Student
}

func NewClass(id int, name string, teacher *Teacher, students map[int]*Student) *Class {
	return &Class{
		ID:       id,
		Name:     name,
		Teacher:  teacher,
		students: students,
	}
}

func (c *Class) AddStudent(student *Student) {
	c.students[student.ID] = student
}

func (c *Class) RemoveStudent(student *Student) {
	delete(c.students, student.ID)
}

func (c *Class) GetStudent(id int) *Student {
	return c.students[id]
}

func (c *Class) GetStudents() map[int]*Student {
	return c.students
}

func (c *Class) GetTeacher() *Teacher {
	return c.Teacher
}
func main() {
	student := NewStudent("John", 20, 100, 1)
	teacher := NewTeacher("Jane", "Math", 30, 1)
	class := NewClass(1, "Math", teacher, make(map[int]*Student))
	class.AddStudent(student)
	fmt.Println(*class.GetStudent(1))
}
