package db

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

// DB連線資訊
const (
	USERNAME = "root"
	PASSWORD = "bensonli"
	NETWORK  = "tcp"
	SERVER   = "127.0.0.1"
	PORT     = 3306
	DATABASE = "game"
)

// PlayerData 玩家資料
type PlayerData struct {
	ID       int
	Account  string
	Password string
	Name     string
}

var db *sql.DB

// InitDB 初始化DB
func InitDB() {
	conn := fmt.Sprintf("%s:%s@%s(%s:%d)/%s", USERNAME, PASSWORD, NETWORK, SERVER, PORT, DATABASE)
	db, _ = sql.Open("mysql", conn)

	// 驗證是否連上 db
	if err := db.Ping(); err != nil {
		fmt.Println("MySQL connection failed:", err)
		return
	}
	fmt.Println("MySQL connection succeeded")

	// DB.SetMaxOpenConns(100)
	// DB.SetMaxIdleConns(10)
	// DB.SetConnMaxLifetime(100 * time.Second)
}

// CreateTablePlayers 建立玩家資料表
func CreateTablePlayers() {
	sql := `CREATE TABLE IF NOT EXISTS players(
		id INT NOT NULL AUTO_INCREMENT,
		account VARCHAR(64) NULL,
		password VARCHAR(64) NULL,
		name VARCHAR(64) NULL,
		PRIMARY KEY (id))`
	if _, err := db.Exec(sql); err != nil {
		fmt.Println("Create table failed:", err)
		return
	}
	fmt.Println("Create table succeeded")
}

// RegisterNewPlayer 註冊新帳號
func RegisterNewPlayer(ac string, pw string) {
	sql := `INSERT INTO players (account, password) VALUES (?, ?)`
	if _, err := db.Exec(sql, ac, pw); err != nil {
		fmt.Println("Insert data failed:", err)
		return
	}
	fmt.Println("Insert data succeeded")
}

// CheckAccount 確認帳密
func CheckAccount(ac string, pw string) bool {
	sql := `SELECT id FROM players WHERE account = ? AND password = ?`
	row := db.QueryRow(sql, ac, pw)
	var id int
	if err := row.Scan(&id); err != nil {
		fmt.Printf("%v\n", err)
		return false
	}
	return true
}

////////////////////////
// from xuchao's blog //
////////////////////////

// User 表结构体定义
type User struct {
	ID         int    `json:"id" form:"id"`
	Username   string `json:"username" form:"username"`
	Password   string `json:"password" form:"password"`
	Status     int    `json:"status" form:"status"` // 0 正常状态， 1删除
	Createtime int64  `json:"createtime" form:"createtime"`
}

func main() {
	conn := fmt.Sprintf("%s:%s@%s(%s:%d)/%s", USERNAME, PASSWORD, NETWORK, SERVER, PORT, DATABASE)
	DB, err := sql.Open("mysql", conn)
	if err != nil {
		fmt.Println("connection to mysql failed:", err)
		return
	}

	DB.SetConnMaxLifetime(100 * time.Second) //最大连接周期，超时的连接就close
	DB.SetMaxOpenConns(100)                  //设置最大连接数
	createTable(DB)
	insertData(DB)
	queryOne(DB)
	queryMulti(DB)
	updateData(DB)
	deleteData(DB)
}

func createTable(DB *sql.DB) {
	sql := `CREATE TABLE IF NOT EXISTS users(
	id INT(4) PRIMARY KEY AUTO_INCREMENT NOT NULL,
	username VARCHAR(64),
	password VARCHAR(64),
	status INT(4),
	createtime INT(10)
	); `

	if _, err := DB.Exec(sql); err != nil {
		fmt.Println("create table failed:", err)
		return
	}
	fmt.Println("create table successd")
}

//插入数据
func insertData(DB *sql.DB) {
	result, err := DB.Exec("insert INTO users(username,password) values(?,?)", "test", "123456")
	if err != nil {
		fmt.Printf("Insert data failed,err:%v", err)
		return
	}
	lastInsertID, err := result.LastInsertId() //获取插入数据的自增ID
	if err != nil {
		fmt.Printf("Get insert id failed,err:%v", err)
		return
	}
	fmt.Println("Insert data id:", lastInsertID)

	rowsaffected, err := result.RowsAffected() //通过RowsAffected获取受影响的行数
	if err != nil {
		fmt.Printf("Get RowsAffected failed,err:%v", err)
		return
	}
	fmt.Println("Affected rows:", rowsaffected)
}

//查询单行
func queryOne(DB *sql.DB) {
	user := new(User) //用new()函数初始化一个结构体对象
	row := DB.QueryRow("select id,username,password from users where id=?", 1)
	//row.scan中的字段必须是按照数据库存入字段的顺序，否则报错
	if err := row.Scan(&user.ID, &user.Username, &user.Password); err != nil {
		fmt.Printf("scan failed, err:%v\n", err)
		return
	}
	fmt.Println("Single row data:", *user)
}

//查询多行
func queryMulti(DB *sql.DB) {
	user := new(User)
	rows, err := DB.Query("select id,username,password from users where id = ?", 2)

	defer func() {
		if rows != nil {
			rows.Close() //关闭掉未scan的sql连接
		}
	}()
	if err != nil {
		fmt.Printf("Query failed,err:%v\n", err)
		return
	}
	for rows.Next() {
		err = rows.Scan(&user.ID, &user.Username, &user.Password) //不scan会导致连接不释放
		if err != nil {
			fmt.Printf("Scan failed,err:%v\n", err)
			return
		}
		fmt.Println("scan successd:", *user)
	}
}

//更新数据
func updateData(DB *sql.DB) {
	result, err := DB.Exec("UPDATE users set password=? where id=?", "111111", 1)
	if err != nil {
		fmt.Printf("Insert failed,err:%v\n", err)
		return
	}
	fmt.Println("update data successd:", result)

	rowsaffected, err := result.RowsAffected()
	if err != nil {
		fmt.Printf("Get RowsAffected failed,err:%v\n", err)
		return
	}
	fmt.Println("Affected rows:", rowsaffected)
}

//删除数据
func deleteData(DB *sql.DB) {
	result, err := DB.Exec("delete from users where id=?", 1)
	if err != nil {
		fmt.Printf("Insert failed,err:%v\n", err)
		return
	}
	fmt.Println("delete data successd:", result)

	rowsaffected, err := result.RowsAffected()
	if err != nil {
		fmt.Printf("Get RowsAffected failed,err:%v\n", err)
		return
	}
	fmt.Println("Affected rows:", rowsaffected)
}
