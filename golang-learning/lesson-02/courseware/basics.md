# 第2期教案：GORM 基础与 CRUD

## 1. 学习目标

通过本课程的学习，你将能够：

- 理解 ORM 与 GORM 的基本概念与优势
- 熟悉 GORM 的安装、初始化、模型定义流程
- 掌握自动迁移和基础 CRUD 的完整用法
- 能够编写规范的条件查询与链式调用

## 2. 核心知识点

### 2.1 ORM 与 GORM 概述

#### 什么是 ORM？

ORM（Object-Relational Mapping，对象关系映射）是一种编程技术，用于在面向对象编程语言和关系型数据库之间建立映射关系。

#### 为什么需要 ORM？

相比直接编写 SQL，ORM 提供了以下优势：

1. **提高生产效率**：减少重复的 SQL 编写，专注于业务逻辑
2. **模型同步**：代码中的模型定义与数据库结构保持一致
3. **组合能力**：通过链式调用灵活组合查询条件
4. **跨数据库支持**：同一套代码可以适配不同的数据库
5. **类型安全**：编译时检查，减少运行时错误

#### GORM 简介

GORM 是 Go 语言中最流行的 ORM 框架，具有以下特点：

- Go 社区使用最广泛的 ORM
- 支持多种数据库驱动：SQLite、MySQL、PostgreSQL、SQL Server、ClickHouse 等；本课程示例使用 SQLite（零配置），生产常用 MySQL/PostgreSQL
- 提供自动迁移、钩子、事务、关联等强大功能
- 活跃的社区和详尽的文档

**官方文档**：https://gorm.io/

### 2.2 安装与初始化

#### 项目结构

```
lesson-02/examples/
├── basics/          # 基础示例
│   ├── setup_test.go
│   ├── crud_test.go
│   └── query_builder_test.go
├── db/              # 数据库文件存储目录
├── go.mod           # 依赖管理
└── .env             # 环境变量配置
```

#### 安装依赖

```bash
cd lesson-02/examples
go mod tidy
```

#### 数据库驱动

GORM 支持多种数据库，本课程默认使用 SQLite（无需额外安装），生产环境可替换为 MySQL 或 PostgreSQL。

**支持的数据库驱动**：
- SQLite: `gorm.io/driver/sqlite`
- MySQL: `gorm.io/driver/mysql`
- PostgreSQL: `gorm.io/driver/postgres`

#### 数据库连接配置

参考示例：`examples/testutil/helpers.go`

**核心配置项**：

1. **Logger**：控制 SQL 日志输出
   - `logger.Silent`：无日志
   - `logger.Error`：仅错误
   - `logger.Warn`：错误和警告
   - `logger.Info`：所有 SQL 查询（开发推荐）

2. **NamingStrategy**：自定义命名策略
   - `TablePrefix`：表名前缀
   - `SingularTable`：使用单数表名
   - `NoLowerCase`：禁用自动小写

3. **连接池配置**（在 `*sql.DB` 上配置）：
   - `SetMaxIdleConns`：最大空闲连接数
   - `SetMaxOpenConns`：最大打开连接数
   - `SetConnMaxLifetime`：连接最大生存时间

#### 环境变量配置

通过 `.env` 文件配置数据库类型和连接信息。**说明**：Go 标准库不会自动加载 `.env`；本课程示例在运行测试时由 `testutil` 包通过 `godotenv` 读取 `examples/.env` 并注入到进程环境变量。若在非测试的 `main` 中也要使用 `.env`，需在程序入口显式调用 `godotenv.Load(".env")`。

```env
# 数据库类型：sqlite, mysql, postgres
TEST_DB_TYPE=sqlite

# MySQL 连接字符串
TEST_MYSQL_DSN=root:password@tcp(localhost:3306)/testdb?charset=utf8mb4&parseTime=True&loc=Local

# PostgreSQL 连接字符串（建议加 TimeZone 如 TimeZone=Asia/Shanghai）
TEST_POSTGRES_DSN=host=localhost user=postgres password=password dbname=testdb port=5432 sslmode=disable TimeZone=Asia/Shanghai
```

#### 模型定义

参考示例：`examples/basics/setup_test.go`

**常用 GORM 标签**：

- `primaryKey`：主键
- `size:64`：字段长度（字符串）
- `not null`：非空约束
- `uniqueIndex`：唯一索引；可写 `uniqueIndex:idx_email` 指定索引名
- `index`：普通索引；可写 `index:idx_status`
- `default:value`：默认值
- `autoCreateTime`：创建时自动写入当前时间
- `autoUpdateTime`：创建/更新时自动写入当前时间
- `type:datetime`：指定列类型（如 `datetime`、`text`）；不写时由 GORM 根据 Go 类型推断
- `column:custom_name`：指定列名，不写则默认蛇形命名（如 `CreatedAt` → `created_at`）

**示例**：

```go
type User struct {
    ID        uint      `gorm:"primaryKey"`
    Name      string    `gorm:"size:64;not null"`
    Email     string    `gorm:"size:128;uniqueIndex;not null"`
    Age       uint8     `gorm:"not null"`
    Status    string    `gorm:"size:16;default:active;index"`
    CreatedAt time.Time `gorm:"autoCreateTime"`
    UpdatedAt time.Time `gorm:"autoUpdateTime"`
}
```

#### 自动迁移（AutoMigrate）

**作用**：
- 自动创建表（如果不存在）
- 添加新列（如果结构体有新字段）
- 创建索引（根据标签）

**注意事项**：
- ⚠️ **不会删除已存在的列**
- ⚠️ **不会修改现有数据**（不会做数据迁移）
- ⚠️ **不会删除索引**
- ⚠️ **不会修改已有列的类型**（部分数据库下仅添加新列）；若要改类型需手写 SQL 或使用迁移工具

**使用示例**：

```go
if err := db.AutoMigrate(&User{}); err != nil {
    log.Fatalf("auto migrate: %v", err)
}
```

### 2.3 基础 CRUD 操作

参考示例：`examples/basics/crud_test.go`

#### Create（创建）

**单条插入**：

```go
user := User{Name: "Alice", Email: "alice@example.com", Age: 28}
if err := db.Create(&user).Error; err != nil {
    // 处理错误
}
// Create 后，user.ID 会自动填充
```

**批量插入**：

```go
users := []User{
    {Name: "Alice", Email: "alice@example.com"},
    {Name: "Bob", Email: "bob@example.com"},
}
if err := db.Create(&users).Error; err != nil {
    // 处理错误
}
```

**控制字段插入**：

- `Select`：只插入指定字段（未选中的字段使用零值或数据库默认值）
- `Omit`：排除指定字段（被排除的字段不写入 INSERT，由零值或数据库默认值填充）

```go
// Select：只插入 Name、Email、Age，其他字段（如 Status）为表默认值
user := User{Name: "Alice", Email: "alice@example.com", Age: 28, Status: "custom"}
db.Select("Name", "Email", "Age").Create(&user)  // INSERT 时只包含 name, email, age

// Omit：插入时排除 Status 和 UpdatedAt，由数据库默认或零值填充
user2 := User{Name: "Bob", Email: "bob@example.com", Age: 30, Status: "active"}
db.Omit("Status", "UpdatedAt").Create(&user2)   // INSERT 不包含 status, updated_at
```

**批量分批插入（CreateInBatches）**：数据量较大时可用 `CreateInBatches` 按批插入，避免单条 SQL 过长并利于控制内存。

```go
users := make([]User, 1000) // 假设 1000 条
if err := db.CreateInBatches(users, 100).Error; err != nil {
    // 每批 100 条执行一次 INSERT
}
```

#### Read（查询）

**First**：获取按主键排序的「第一条」记录，找不到时返回 `gorm.ErrRecordNotFound`。

**方法签名**：`First(dest interface{}, conds ...interface{})`

- **第 1 个参数（必填）**：`dest`，传入要写入结果的模型指针（如 `&user`）。
- **第 2 个起（可选）**：`conds`，可变参数，不传时表示「无条件取全表第一条（按主键升序）」；传参时用于构造 WHERE 条件，常见写法如下：

| 写法 | 含义 |
|------|------|
| `db.First(&user)` | 无条件，取主键最小的那条 |
| `db.First(&user, 1)` | 主键等于 1（等价于 `WHERE id = 1`，主键名为 `id` 时） |
| `db.First(&user, "email = ?", "alice@example.com")` | 条件：`email = ?`，后续为占位参数 |
| `db.First(&user, User{Email: "alice@example.com"})` | 按结构体非零字段生成等值条件（Email = ...） |

**注意**：主键查询时，若表的主键列名不是 `id`，需用 `Where` 显式写条件；复合主键时需传多个值。

```go
var user User
// 使用条件
if err := db.Where("email = ?", "alice@example.com").First(&user).Error; err != nil {
    if errors.Is(err, gorm.ErrRecordNotFound) {
        // 记录不存在
    }
}
// 使用主键（第一个可选参数为主键值）
db.First(&user, 1)
```

**Take**：获取一条记录，**不附加 ORDER BY**，因此是「符合条件中的任意一条」（顺序由数据库实现决定）。找不到时同样返回 `gorm.ErrRecordNotFound`，需用 `errors.Is(err, gorm.ErrRecordNotFound)` 判断。

```go
var user User
if err := db.Take(&user).Error; err != nil {
    if errors.Is(err, gorm.ErrRecordNotFound) {
        // 无记录
    }
}
// 带条件时：取符合条件的一条（任意一条，无顺序保证）
db.Where("status = ?", "active").Take(&user)
```

**First 和 Take 的区别**（用法像，语义不同）：

| 方法 | 生成的 SQL 特点 | 适用场景 |
|------|------------------|----------|
| **First** | 会按**主键升序**排序再取第一条（`ORDER BY primary_key ASC LIMIT 1`） | 需要「确定的一条」：例如主键最小的那条、或「符合条件里 ID 最小的」 |
| **Take** | **不**加 ORDER BY，直接 `LIMIT 1`，返回哪条由数据库决定 | 只需要「任意一条」即可，不关心顺序，有时比 First 少一次排序 |

举例：`db.Where("status = ?", "active").First(&user)` 得到的是 status=active 里**主键最小**的那条；`db.Where("status = ?", "active").Take(&user)` 得到的是其中**任意一条**。若业务要求「同条件多次查询结果一致」，用 **First**；若只是「随便取一条」用 **Take** 即可。

**Last**：按主键排序取最后一条记录（与 First 相反）。

```go
var user User
db.Last(&user)  // 主键最大的那条
db.Where("status = ?", "active").Last(&user)
```

**Find**：获取所有匹配记录（找不到返回空切片）

```go
var users []User
db.Where("status = ?", "active").Find(&users)
```

**Model 方法**：用来指定「当前链式操作针对的是哪张表、哪个模型」。

- **`Model(&User{})`**：传入**类型**（空结构体即可），表示后续的 `Select`、`Where`、`Scan`、`Count`、`Pluck` 等都在 **users** 表上执行。当查询结果要写入**别的结构体**（如 `UserSummary`）或基本类型时，GORM 无法从目标推断表名，必须用 `Model` 指明从哪张表查。
- **`Model(&user)`**：传入**某条记录的指针**，表示后续操作针对这条记录（常用于 `Updates`、`Update`、`Delete`），GORM 会加上主键条件。

因此 `db.Model(&User{}).Select("name", "email").Scan(&summaries)` 的含义是：在 **users** 表上做 SELECT name, email，并把结果扫描到 `summaries`（类型为 `[]UserSummary`）。

**Scan**：扫描到自定义结构体或 map，常用于只查部分字段或聚合结果。

```go
type UserSummary struct {
    Name   string
    Email  string
}
var summaries []UserSummary
db.Model(&User{}).Select("name", "email").Scan(&summaries)

// 扫描到 map（单条）
var result map[string]interface{}
db.Model(&User{}).Select("name", "email").Where("id = ?", 1).Scan(&result)

// 扫描到基本类型（如 Count 结果）
var count int64
db.Model(&User{}).Where("status = ?", "active").Count(&count)
```

**Pluck**：将单列查询为切片，适合只取一列（如 ID 列表、名称列表）。

```go
var ids []uint
db.Model(&User{}).Where("status = ?", "active").Pluck("id", &ids)

var names []string
db.Model(&User{}).Pluck("name", &names)
```

#### Update（更新）

**Save**：更新所有字段（包括零值）

```go
user.Name = "New Name"
db.Save(&user)
```

**Updates**：更新指定字段（忽略零值）

```go
// 使用结构体
db.Model(&user).Updates(User{Age: 31, Status: "vip"})

// 使用 map（推荐，避免零值问题）
db.Model(&user).Updates(map[string]any{"age": 31, "status": "vip"})
```

**Select + Updates**：只更新指定字段（可避免零值被误更新）

```go
db.Model(&user).Select("Age", "Status").Updates(User{Age: 31, Status: "vip"})
```

**Update**：更新单个字段（第一个参数为列名，第二个为值）。

```go
db.Model(&user).Update("status", "vip")
db.Model(&user).Where("id = ?", user.ID).Update("age", 31)
```

**批量更新**：

```go
db.Model(&User{}).Where("status = ?", "inactive").Updates(map[string]any{"status": "pending"})
```

#### Delete（删除）

**说明**：若模型包含 `DeletedAt gorm.DeletedAt` 字段，GORM 会启用软删除，`Delete` 仅设置 `deleted_at` 而不物理删除；未启用软删除时则为物理删除。软删除详见进阶章节。

**删除单条记录**：

```go
// 方式1：使用实例
db.Delete(&user)

// 方式2：使用主键
db.Delete(&User{}, user.ID)
```

**批量删除**：

```go
db.Where("status = ?", "inactive").Delete(&User{})
```

**验证删除**：

```go
err := db.First(&User{}, user.ID).Error
if !errors.Is(err, gorm.ErrRecordNotFound) {
    // 记录仍然存在
}
```

### 2.4 条件查询，链式调用，原生sql的使用

参考示例：`examples/basics/query_builder_test.go`

#### Where 条件查询

**基本条件（占位符防注入）**：

```go
db.Where("status = ?", "active").Find(&users)
```

**多条件**：

```go
db.Where("status = ? AND age > ?", "active", 25).Find(&users)
```

**使用结构体 / map 条件**：Where 可传入结构体或 map，GORM 会将非零字段转为等值条件（零值不参与条件）。

```go
db.Where(&User{Status: "active", Age: 28}).Find(&users)
db.Where(map[string]interface{}{"status": "active", "age": 28}).Find(&users)
```

**OR 条件**：

```go
db.Where("status = ?", "active").Or("status = ?", "pending").Find(&users)
db.Where("status IN ?", []string{"active", "pending"}).Find(&users)  // 等价写法
```

**LIKE 查询**：

```go
db.Where("email LIKE ?", "%@example.com").Find(&users)  // 以 '@example.com' 结尾
db.Where("email LIKE ?", "a%").Find(&users)            // 以 'a' 开头
```

**IN 查询**：

```go
db.Where("status IN ?", []string{"active", "pending"}).Find(&users)
```

**BETWEEN 查询**：

```go
db.Where("age BETWEEN ? AND ?", 20, 30).Find(&users)
```

**NOT / 不等于**：

```go
db.Where("status <> ?", "inactive").Find(&users)
db.Not("status", "inactive").Find(&users)
```

#### Select 指定字段

```go
// 只查询指定字段（提高性能）
db.Select("id", "name", "email").Find(&users)
```

#### Order 排序

```go
db.Order("created_at desc").Find(&users)  // 降序
db.Order("age asc").Find(&users)         // 升序
// 多字段排序
db.Order("status asc, age desc").Find(&users)
db.Order("created_at desc").Order("id asc").Find(&users)  // 先按时间降序，再按 ID 升序
```

#### Limit 和 Offset（分页）

```go
// Limit: 限制返回记录数
db.Limit(10).Find(&users)

// Offset: 跳过记录数
db.Offset(10).Limit(10).Find(&users)  // 第2页，每页10条
```

#### Scopes（作用域）

Scopes 允许将通用查询条件提取为可复用函数。

**定义 Scope**：

```go
func activeUsers() func(db *gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB {
        return db.Where("status = ?", "active")
    }
}
```

**使用 Scope**：

```go
db.Scopes(activeUsers()).Find(&users)
```

**分页 Scope 示例**：

```go
func paginate(page, size int) func(db *gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB {
        if page <= 0 {
            page = 1
        }
        if size <= 0 {
            size = 10
        }
        offset := (page - 1) * size
        return db.Offset(offset).Limit(size)
    }
}

// 使用
db.Scopes(paginate(1, 10)).Find(&users)
```

**组合多个 Scope**：

```go
db.Scopes(activeUsers(), paginate(1, 10)).Find(&users)
```

#### 聚合查询

**Count**：统计数量

```go
var count int64
db.Model(&User{}).Where("status = ?", "active").Count(&count)
```

**Group By**：分组统计

```go
type StatusCount struct {
    Status string
    Total  int64
}
var counts []StatusCount
db.Model(&User{}).
    Select("status, COUNT(*) as total").
    Group("status").
    Scan(&counts)
```

#### 链式调用的特点

1. **顺序无关**：查询条件的构建顺序不影响最终 SQL
2. **可组合**：每个方法返回 `*gorm.DB`，可以继续链式调用
3. **延迟执行**：只有在调用 `Find`、`First`、`Scan` 等方法时才执行 SQL

**示例**：

```go
// 以下两种写法等价
db.Where("status = ?", "active").Order("age desc").Limit(10).Find(&users)
db.Limit(10).Order("age desc").Where("status = ?", "active").Find(&users)
```

#### 原生 SQL 使用方式与示例

当链式查询无法满足复杂需求时，可以直接执行原生 SQL。常用方式如下：

- `db.Raw(sql, args...).Scan(dest)`：执行 SELECT，将结果映射到结构体或切片
- `db.Exec(sql, args...)`：执行 INSERT/UPDATE/DELETE 等，返回 `result.RowsAffected`、`result.Error`
- `db.Raw(sql, args...).Rows()`：返回 `*sql.Rows`，需调用方 `defer rows.Close()` 并自行遍历
- `db.Raw(sql, args...).Row()`：返回单行，配合 `row.Scan(...)` 使用

**查询示例**：

```go
type StatusSummary struct {
    Status string
    Total  int64
    AvgAge float64
}

var stats []StatusSummary
// AddDate(years, months, days int)：在当前时间上加减年/月/日，返回新时间，不修改原值
// AddDate(0, -1, 0) 表示「1 个月前」；(0, 0, -30) 表示「30 天前」
start := time.Now().AddDate(0, -1, 0)
end := time.Now()

err := db.Raw(`
    SELECT status, COUNT(*) AS total, AVG(age) AS avg_age
    FROM users
    WHERE created_at BETWEEN ? AND ?
    GROUP BY status
`, start, end).Scan(&stats).Error

if err != nil {
    log.Fatalf("query failed: %v", err)
}
```

**执行语句示例**：

```go
// AddDate(0, 0, -30)：30 天前，用于筛选「超过 30 天未登录」
threshold := time.Now().AddDate(0, 0, -30)
result := db.Exec(
    "UPDATE users SET status = ? WHERE last_login_at < ?",
    "inactive",
    threshold,
)

if result.Error != nil {
    log.Fatalf("exec failed: %v", result.Error)
}

fmt.Printf("affected rows: %d\n", result.RowsAffected)
```

**其他常用链式方法**：

- **Distinct**：对指定列去重，对应 SQL 的 `SELECT DISTINCT status FROM users`。
  - **`db.Model(&User{}).Distinct("status").Find(&users)`**：结果写入 `[]User`，**每一行是一个 User，但只有 `Status` 有值**，其他字段为零值；行数 = 表里 status 有多少种取值（例如 `["active", "inactive", "pending"]` 三种就返回 3 条 User）。
  - **`db.Model(&User{}).Distinct("status").Pluck("status", &statuses)`**：结果写入 `[]string`（或 `[]int` 等），**直接得到去重后的 status 值列表**，例如 `statuses == []string{"active", "inactive", "pending"}`。若只需要「有哪些不同的 status」，用 Pluck 更合适。
- **更新/删除后检查影响行数**：`res := db.Model(&User{}).Where(...).Updates(...)`，用 `res.RowsAffected` 和 `res.Error` 判断是否更新成功及影响行数

## 3. 关键概念总结

### 3.1 ORM 三大优势

1. **生产效率**：减少重复代码，提高开发速度
2. **模型同步**：代码模型与数据库结构保持一致
3. **组合能力**：通过链式调用灵活组合查询

### 3.2 重要区别

**Create / Save / Updates 的区别**：

- `Create`：插入新记录
- `Save`：保存记录（插入或更新所有字段）
- `Updates`：更新指定字段（忽略零值）

**Find / Scan / Pluck 的区别**：

- `Find`：查询到与模型一致的结构体（或切片）
- `Scan`：查询到自定义结构体、map 或基本类型（常用于部分字段、聚合结果）
- `Pluck`：单列查询为切片（如 `[]uint`、`[]string`）

**Create vs CreateInBatches**：`Create` 适合单条或小批量；大批量插入用 `CreateInBatches(slice, batchSize)` 可避免单条 SQL 过长并便于控制内存。

### 3.3 最佳实践

1. **错误处理**：始终检查错误，特别是使用 `First` 时要检查 `gorm.ErrRecordNotFound`
2. **连接池配置**：根据应用负载合理配置连接池参数
3. **使用 Select**：只查询需要的字段，提高性能
4. **使用 Scopes**：提取通用查询逻辑，提高代码复用性
5. **环境变量**：使用 `.env` 文件管理配置，便于不同环境切换

## 4. 实践练习

### 练习 1：扩展用户模型

根据示例扩展用户模型，增加以下字段：
- `Phone`：电话号码（字符串，唯一索引）
- `LastLoginAt`：最后登录时间（时间类型）

### 练习 2：实现用户操作函数

完成以下操作函数：

1. **新增用户**：创建用户并默认开启激活状态
   ```go
   func CreateUser(db *gorm.DB, name, email string) (*User, error) {
       // 你的实现
   }
   ```

2. **模糊查询**：根据邮箱模糊查询用户列表（支持分页）
   ```go
   func SearchUsersByEmail(db *gorm.DB, emailPattern string, page, size int) ([]User, error) {
       // 你的实现
   }
   ```

3. **批量更新状态**：批量更新用户状态
   ```go
   func UpdateUserStatus(db *gorm.DB, ids []uint, status string) error {
       // 你的实现
   }
   ```

4. **删除过期用户**：删除超过 30 天未登录的用户
   ```go
   func DeleteInactiveUsers(db *gorm.DB) error {
       // 你的实现（注意：软删除将在进阶模块讲解）
   }
   ```

### 练习 3：使用 Scopes

创建一个 `youngUsers` scope，筛选年龄在 18-30 岁之间的用户，并实现分页查询。

## 5. 运行示例代码

### 运行基础示例

```bash
cd lesson-02/examples

# 初始化数据库与自动迁移
go test ./basics -run TestSetupDemo -v

# 完整 CRUD 流程
go test ./basics -run TestCRUDDemo -v

# 条件查询、分页、排序
go test ./basics -run TestQueryBuilderDemo -v
```

### 查看 SQL 日志

在 `examples/testutil/helpers.go` 中的 `NewTestDB`/`newSQLiteDB` 设置 Logger 为 `logger.Info`，即可看到所有 SQL 查询：

```go
Logger: logger.Default.LogMode(logger.Info),
```

### 查看数据库文件

SQLite 数据库文件存储在 `examples/db/` 目录下，可以使用 SQLite 查看工具打开查看。

## 6. 常见问题

### Q: 运行时提示找不到驱动？

A: 确认已经执行 `go mod tidy`，并在代码中正确导入了驱动库。切换到 MySQL/PostgreSQL 时，需要在 `go.mod` 中添加对应驱动。

### Q: AutoMigrate 会删除字段吗？

A: 不会。AutoMigrate 只会添加新字段，不会删除已存在的字段。如需删除字段，需要手动执行 SQL 或使用迁移工具。

### Q: 如何查看生成的 SQL？

A: 将 Logger 设置为 `logger.Info`，运行测试时会输出所有 SQL 语句。

### Q: Find、Scan、Pluck 什么时候用哪个？

A: 
- **Find**：查询完整或部分字段到**与模型相同的结构体**（或切片）
- **Scan**：查询到**自定义结构体、map 或基本类型**，常用于只取几列或聚合（COUNT/AVG 等）
- **Pluck**：只取**一列**到切片（如 `[]uint`、`[]string`）

### Q: .env 里的变量是怎么被程序读到的？

A: Go 不会自动加载 `.env`。本课程示例在**运行测试**时由 `testutil` 包通过 `godotenv.Load()` 读取 `examples/.env` 并调用 `os.Setenv` 注入；之后代码里 `os.Getenv("TEST_DB_TYPE")` 等才能拿到值。若在普通 `main` 中也要用 `.env`，需在入口处调用 `godotenv.Load(".env")`（或指定路径）。

## 7. 下一步学习

- 深入阅读示例代码中的注释
- 完成实践练习
- 学习进阶内容：关联关系、事务、钩子、软删除等
- 将 GORM 与 Web 框架（如 Gin）结合，构建完整的应用

---

**完成以上内容即可掌握 GORM 的基础 CRUD 操作！** 🚀
