package main

import (
	"battle"
	"db"
	"encoding/json"
	"fmt"
	"net"
	"player"
	"sync"
)

type p = *player.Player

// var userNum int = 0 // client流水號
// var onlinemap map[string]clientData = make(map[string]clientData)

// var onlinePlayerID []int

// var questionList []questions.QuestionObj

var waitingPlayerID int
var waitingPlayerConn net.Conn = nil
var waitingPlayerWg sync.WaitGroup

type clientData struct {
	name   string
	conn   net.Conn
	id     int
	health float64
}

// Players 目前線上玩家列表
var Players map[int]p = make(map[int]p)

// server為每個client開一個goroutine來handle
func handleConnection(conn net.Conn) {
	defer conn.Close()

	// addr, client := registerNewGuest(conn)

	// 玩家instance
	player := new(player.Player)
	isLogin := false

	// 開一個goroutine來傳訊息給client
	player.Ch = make(chan string, 8)
	go func(player p, conn net.Conn) {
		for msg := range player.Ch {
			conn.Write([]byte(msg))
		}
	}(player, conn)

	// 這個channel用來傳訊息給戰鬥goroutine
	var battleCh chan map[string]interface{}

	// 接收&處理訊息
	buf := make([]byte, 1024)
	var msgRecv string
	for {
		n, _ := conn.Read(buf)
		if n == 0 { // 離線
			// fmt.Printf("%s [%s] 離線\n", client.name, addr)
			// delete(onlinemap, addr)
			if isLogin {
				playerLogout(player)
			}
			// battle.LeaveRoom(player.ID)
			return
		}

		msgRecv = string(buf[:n])
		// fmt.Printf("%s : %s\n", client.name, msg) // server印出訊息
		fmt.Println(msgRecv) // server印出訊息

		///////////////
		// Unmarshal //
		///////////////
		var jsonObj map[string]interface{}
		err := json.Unmarshal([]byte(msgRecv), &jsonObj)
		if err != nil {
			fmt.Println("Unmarshal err:", err)
		}

		/////////////
		// Process //
		/////////////
		switch jsonObj["op"] {
		case "REGISTER":
			db.RegisterNewPlayer(jsonObj["ac"].(string), jsonObj["pw"].(string), jsonObj["name"].(string))
			isLogin = playerLogin(jsonObj["ac"].(string), jsonObj["pw"].(string), player)
		case "LOGIN":
			isLogin = playerLogin(jsonObj["ac"].(string), jsonObj["pw"].(string), player)
		case "ENTER_ROOM":
			// if waitingPlayerConn == nil { // 目前沒有人在等
			// 	fmt.Println("no one waiting")
			// 	waitingPlayerID = player.ID
			// 	waitingPlayerConn = conn
			// 	waitingPlayerWg = sync.WaitGroup{}
			// 	waitingPlayerWg.Add(1)
			// 	waitingPlayerWg.Wait()
			// } else { // 有人在等，可出發
			// 	fmt.Println("go to battle!!")
			// 	battle.StartBattle(waitingPlayerID, player.ID, waitingPlayerConn, conn, &waitingPlayerWg)
			// 	waitingPlayerID = -1
			// 	waitingPlayerConn = nil
			// }
			battleCh = battle.Join1V1(player)
		case "ANSWER":
			battleCh <- jsonObj
		case "SURRENDER":
			battleCh <- jsonObj
		}
	}
}

// 玩家登入
func playerLogin(ac string, pw string, player p) bool {
	result := db.CheckAccount(ac, pw)

	var msgSend []byte
	switch result {
	case 0: // 帳密正確
		db.FetchPlayerData(ac, player)
		if _, ok := Players[player.ID]; ok { // 已在線上
			msgSend, _ = json.Marshal(map[string]interface{}{
				"op": "ALREADY_LOGIN"})
			player.Ch <- string(msgSend)
			return false
		}
		msgSend, _ = json.Marshal(map[string]interface{}{
			"op":   "LOGIN_SUCCESS",
			"id":   player.ID,
			"name": player.Name,
			"bm":   player.Bookmark,
			"bmp":  player.BookmarkPrem,
			"coin": player.Coin})
		player.Ch <- string(msgSend)
		Players[player.ID] = player
		fmt.Println("Player", player.Name, "(ID:", player.ID, ") 登入, 目前線上有", len(Players), "名玩家")
		return true
	case 1: // 無帳號
		msgSend, _ = json.Marshal(map[string]interface{}{
			"op": "ACCOUNT_NOT_FOUND"})
		player.Ch <- string(msgSend)
		return false
	case 2: // 密碼錯誤
		msgSend, _ = json.Marshal(map[string]interface{}{
			"op": "WRONG_PW"})
		player.Ch <- string(msgSend)
		return false
	default:
		return false
	}
}

// 玩家登出
func playerLogout(player p) {
	delete(Players, player.ID)
	fmt.Println("Player", player.Name, "(ID:", player.ID, ") 離線, 目前線上有", len(Players), "名玩家")
}

// 新user加入聊天室
// func registerNewGuest(conn net.Conn) (string, clientData) {
// 	addr := conn.RemoteAddr().String()
// 	client := clientData{"User" + fmt.Sprintf("%d", userNum), conn, 0, 100.0}
// 	userNum++
// 	fmt.Printf("%s [%s] 登入\n", client.name, addr)

// 	// 新client加入server線上列表
// 	onlinemap[addr] = client

// 	return addr, client
// }

// 廣播
// func broadcast(msg string, currentUserAddr string) {
// 	for addr, client := range onlinemap {
// 		if addr == currentUserAddr {
// 			continue // 排除講話的人本身
// 		}
// 		client.conn.Write([]byte(msg))
// 	}
// }
// func broadcastIncludeSelf(msg string) {
// 	for _, client := range onlinemap {
// 		client.conn.Write([]byte(msg))
// 	}
// }

// // 密語
// func privatemsg(msg string, targetUserName string) {
// 	for _, client := range onlinemap {
// 		if client.name == targetUserName {
// 			client.conn.Write([]byte(msg))
// 		}
// 	}
// }
// func pmID(msg string, targetID int) {
// 	for _, client := range onlinemap {
// 		if client.id == targetID {
// 			client.conn.Write([]byte(msg))
// 		}
// 	}
// }

func main() {
	// 連接 MySQL DB
	db.InitDB()
	// db.CreateTablePlayers()

	// TCP 連線
	listener, _ := net.Listen("tcp", "0.0.0.0:8888")
	// listener, _ := net.Listen("tcp", "127.0.0.1:8888")
	defer listener.Close()

	for {
		// 有新的client連進來
		conn, _ := listener.Accept()
		// 開一個goroutine來handle這個client
		go handleConnection(conn)
	}
}
