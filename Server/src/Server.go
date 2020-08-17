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

	player := new(player.Player)

	// 開一個goroutine來傳訊息給client
	player.Ch = make(chan string, 8)
	go func(player p, conn net.Conn) {
		for msg := range player.Ch {
			conn.Write([]byte(msg))
		}
	}(player, conn)

	// 接收&處理訊息
	buf := make([]byte, 1024)
	var msgRecv string
	for {
		n, _ := conn.Read(buf)
		if n == 0 { // 離線
			// fmt.Printf("%s [%s] 離線\n", client.name, addr)
			// delete(onlinemap, addr)
			playerLogout(player)
			battle.LeaveRoom(player.ID)
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
			db.RegisterNewPlayer(jsonObj["ac"].(string), jsonObj["pw"].(string))
			playerLogin(jsonObj["ac"].(string), jsonObj["pw"].(string), player)
		case "LOGIN":
			playerLogin(jsonObj["ac"].(string), jsonObj["pw"].(string), player)
		case "ENTER_ROOM":
			// battle.EnterRoom(int(jsonObj["room"].(float64)), int(jsonObj["id"].(float64)))
			if waitingPlayerConn == nil { // 目前沒有人在等
				fmt.Println("no one waiting")
				waitingPlayerID = player.ID
				waitingPlayerConn = conn
				waitingPlayerWg = sync.WaitGroup{}
				waitingPlayerWg.Add(1)
				waitingPlayerWg.Wait()
			} else { // 有人在等，可出發
				fmt.Println("go to battle!!")
				battle.StartBattle(waitingPlayerID, player.ID, waitingPlayerConn, conn, &waitingPlayerWg)
				waitingPlayerID = -1
				waitingPlayerConn = nil
			}
		}
	}
}

// 玩家登入
func playerLogin(ac string, pw string, player p) {
	result := db.CheckAccount(ac, pw)

	var msgSend []byte
	switch result {
	case 0: // 帳密正確
		db.FetchPlayerData(ac, player)
		msgSend, _ = json.Marshal(map[string]interface{}{
			"op":    "LOGIN_SUCCESS",
			"id":    player.ID,
			"name":  player.Name,
			"token": player.Token})
		player.Ch <- string(msgSend)
		Players[player.ID] = player
		fmt.Println("Player", player.Name, "(ID:", player.ID, ") 登入, 目前線上有", len(Players), "名玩家")
	case 1: // 無帳號
		msgSend, _ = json.Marshal(map[string]interface{}{
			"op": "ACCOUNT_NOT_FOUND"})
		player.Ch <- string(msgSend)
	case 2: // 密碼錯誤
		msgSend, _ = json.Marshal(map[string]interface{}{
			"op": "WRONG_PW"})
		player.Ch <- string(msgSend)
	}
}

// 從DB讀取玩家資料
func fetchPlayerData(player p) {

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
	listener, _ := net.Listen("tcp", "127.0.0.1:8888")
	defer listener.Close()

	for {
		// 有新的client連進來
		conn, _ := listener.Accept()
		// 開一個goroutine來handle這個client
		go handleConnection(conn)
	}
}
