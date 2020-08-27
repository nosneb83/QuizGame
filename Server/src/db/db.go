package db

import (
	"database/sql"
	"fmt"
	"player"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

type p = *player.Player

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
		id 				INT NOT NULL AUTO_INCREMENT,
		account 		VARCHAR(20) NOT NULL DEFAULT '',
		password 		VARCHAR(20) NOT NULL DEFAULT '',
		name 			VARCHAR(20) NOT NULL DEFAULT '',
		bookmark 		INT NOT NULL DEFAULT 0,
		bookmarkprem 	INT NOT NULL DEFAULT 0,
		coin 			INT NOT NULL DEFAULT 0,
		vipstamp 		INT NOT NULL DEFAULT 0,
		vipexpire 		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		lastlogin 		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
		logindays 		INT NOT NULL DEFAULT 0,
		pvpwins 		INT NOT NULL DEFAULT 0,
		pvptotal 		INT NOT NULL DEFAULT 0,
		alcorr 			INT NOT NULL DEFAULT 0,
		altotal 		INT NOT NULL DEFAULT 0,
		sccorr 			INT NOT NULL DEFAULT 0,
		sctotal 		INT NOT NULL DEFAULT 0,
		licorr 			INT NOT NULL DEFAULT 0,
		litotal 		INT NOT NULL DEFAULT 0,
		necorr 			INT NOT NULL DEFAULT 0,
		netotal 		INT NOT NULL DEFAULT 0,
		accorr 			INT NOT NULL DEFAULT 0,
		actotal 		INT NOT NULL DEFAULT 0,
		arcorr 			INT NOT NULL DEFAULT 0,
		artotal 		INT NOT NULL DEFAULT 0,
		socorr 			INT NOT NULL DEFAULT 0,
		sototal 		INT NOT NULL DEFAULT 0,
		spcorr 			INT NOT NULL DEFAULT 0,
		sptotal 		INT NOT NULL DEFAULT 0,
		mainstory 		INT NOT NULL DEFAULT 0,
		char1unlock		TINYINT(1) NOT NULL DEFAULT 0,
		char1relat 		INT NOT NULL DEFAULT 0,
		char1story 		INT NOT NULL DEFAULT 0,
		char2unlock 	TINYINT(1) NOT NULL DEFAULT 0,
		char2relat 		INT NOT NULL DEFAULT 0,
		char2story 		INT NOT NULL DEFAULT 0,
		char3unlock 	TINYINT(1) NOT NULL DEFAULT 0,
		char3relat 		INT NOT NULL DEFAULT 0,
		char3story 		INT NOT NULL DEFAULT 0,
		char4unlock 	TINYINT(1) NOT NULL DEFAULT 0,
		char4relat 		INT NOT NULL DEFAULT 0,
		char4story 		INT NOT NULL DEFAULT 0,
		PRIMARY KEY (id))`
	if _, err := db.Exec(sql); err != nil {
		fmt.Println("Create table failed:", err)
		return
	}
	fmt.Println("Create table succeeded")
}

// RegisterNewPlayer 註冊新帳號
func RegisterNewPlayer(ac string, pw string, name string) {
	sql := `INSERT INTO players (account, password, name) VALUES (?, ?, ?)`
	if _, err := db.Exec(sql, ac, pw, name); err != nil {
		fmt.Println("Insert data failed:", err)
		return
	}
	fmt.Println("Insert data succeeded")
}

// NewAccountDuplicate 檢查新帳號是否重複
func NewAccountDuplicate(ac string) bool {
	sql := `SELECT account FROM players WHERE account = ?`
	row := db.QueryRow(sql, ac)
	var account string
	if err := row.Scan(&account); err != nil {
		return false
	}
	return true
}

// CheckAccount 確認帳密 (return 0:正確 1:無帳號 2:密碼錯誤)
func CheckAccount(ac string, pw string) int {
	sql := `SELECT password FROM players WHERE account = ?`
	row := db.QueryRow(sql, ac)
	var password string
	if err := row.Scan(&password); err != nil {
		fmt.Printf("%v\n", err)
		return 1
	}
	if pw != password {
		return 2
	}

	// 更新最後登入時間
	sql = `UPDATE players SET lastlogin = CURRENT_TIMESTAMP WHERE account = ?`
	if _, err := db.Exec(sql, ac); err != nil {
		fmt.Println("Update failed:", err)
	}
	return 0
}

// FetchPlayerData 從DB讀取玩家資料
func FetchPlayerData(ac string, player p) {
	sql := `SELECT id, name, bookmark, bookmarkprem, coin FROM players WHERE account = ?`
	row := db.QueryRow(sql, ac)
	var id, bm, bmp, coin int
	var name string
	if err := row.Scan(&id, &name, &bm, &bmp, &coin); err != nil {
		fmt.Println("讀取玩家資料失敗")
		return
	}
	player.ID = id
	player.Name = name
	player.Bookmark = bm
	player.BookmarkPrem = bmp
	player.Coin = coin
}

// UpdateBookmark 更新玩家書籤數量
func UpdateBookmark(player p) {
	sql := `UPDATE players SET bookmark = ? WHERE id = ?`
	if _, err := db.Exec(sql, player.Bookmark, player.ID); err != nil {
		fmt.Println("Update failed:", err)
	}
}

// UpdateBMP 更新玩家有償書籤數量
func UpdateBMP(player p) {
	sql := `UPDATE players SET bookmarkprem = ? WHERE id = ?`
	if _, err := db.Exec(sql, player.BookmarkPrem, player.ID); err != nil {
		fmt.Println("Update failed:", err)
	}
}

// UpdateCoin 更新玩家金幣數量
func UpdateCoin(player p) {
	sql := `UPDATE players SET coin = ? WHERE id = ?`
	if _, err := db.Exec(sql, player.Coin, player.ID); err != nil {
		fmt.Println("Update failed:", err)
	}
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
