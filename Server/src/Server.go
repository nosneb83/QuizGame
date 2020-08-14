package main

import (
	"battle"
	"db"
	"encoding/json"
	"fmt"
	"net"
	"sync"
)

var userNum int = 0 // client流水號
var onlinemap map[string]clientData = make(map[string]clientData)

var onlinePlayerID []int

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

// server為每個client開一個goroutine來handle
func handleConnection(conn net.Conn) {
	defer conn.Close()

	addr, client := registerNewGuest(conn)

	var playerID int

	// 讀取題庫
	// questionList := questions.ReadQuestionsFromCSV()
	// fmt.Println(questionList)

	buf := make([]byte, 1024)
	var msg string
	for {
		n, _ := conn.Read(buf)
		if n == 0 { // 離線
			fmt.Printf("%s [%s] 離線\n", client.name, addr)
			delete(onlinemap, addr)
			battle.LeaveRoom(playerID)
			return
		}

		msg = string(buf[:n])
		fmt.Printf("%s : %s\n", client.name, msg) // server印出訊息

		///////////////
		// Unmarshal //
		///////////////
		var jsonObj map[string]interface{}
		err := json.Unmarshal([]byte(msg), &jsonObj)
		if err != nil {
			fmt.Println("Unmarshal err:", err)
		}

		/////////////
		// Process //
		/////////////
		switch jsonObj["op"] {
		case "LOGIN":
			playerID = playerLogin(conn, jsonObj["ac"].(string), jsonObj["pw"].(string))
			fmt.Println("Player ID:", playerID, "Login")
		case "ENTER_ROOM":
			// battle.EnterRoom(int(jsonObj["room"].(float64)), int(jsonObj["id"].(float64)))
			if waitingPlayerConn == nil { // 目前沒有人在等
				fmt.Println("no one waiting")
				waitingPlayerID = playerID
				waitingPlayerConn = conn
				waitingPlayerWg = sync.WaitGroup{}
				waitingPlayerWg.Add(1)
				waitingPlayerWg.Wait()
			} else { // 有人在等，可出發
				fmt.Println("go to battle!!")
				battle.StartBattle(waitingPlayerID, playerID, waitingPlayerConn, conn, &waitingPlayerWg)
				waitingPlayerID = -1
				waitingPlayerConn = nil
			}
		case "CLIENT_READY":
			// fmt.Println("question list length =", len(questionList))
			// randQuestion := questionList[rand.Intn(len(questionList))]
			// q, _ := json.Marshal(map[string]interface{}{
			// 	"op":     "SEND_QUESTION",
			// 	"domain": randQuestion.Domain,
			// 	"difcty": randQuestion.Difcty,
			// 	"qtype":  randQuestion.QType,
			// 	"ques":   randQuestion.Ques,
			// 	"ans":    randQuestion.Ans})
			// conn.Write([]byte(q))
		}
	}
}

// 玩家登入
func playerLogin(conn net.Conn, ac string, pw string) int {
	playerExists, playerID := db.CheckAccount(ac, pw)
	var msg []byte
	if playerExists {
		msg, _ = json.Marshal(map[string]interface{}{
			"op":       "LOGIN_SUCCESS",
			"playerID": playerID})
	} else {
		msg, _ = json.Marshal(map[string]interface{}{
			"op": "LOGIN_FAIL"})
	}
	conn.Write(msg)
	return playerID
}

// 新user加入聊天室
func registerNewGuest(conn net.Conn) (string, clientData) {
	addr := conn.RemoteAddr().String()
	client := clientData{"User" + fmt.Sprintf("%d", userNum), conn, 0, 100.0}
	userNum++
	fmt.Printf("%s [%s] 登入\n", client.name, addr)

	// 新client加入server線上列表
	onlinemap[addr] = client

	return addr, client
}

// 廣播
func broadcast(msg string, currentUserAddr string) {
	for addr, client := range onlinemap {
		if addr == currentUserAddr {
			continue // 排除講話的人本身
		}
		client.conn.Write([]byte(msg))
	}
}
func broadcastIncludeSelf(msg string) {
	for _, client := range onlinemap {
		client.conn.Write([]byte(msg))
	}
}

// 密語
func privatemsg(msg string, targetUserName string) {
	for _, client := range onlinemap {
		if client.name == targetUserName {
			client.conn.Write([]byte(msg))
		}
	}
}
func pmID(msg string, targetID int) {
	for _, client := range onlinemap {
		if client.id == targetID {
			client.conn.Write([]byte(msg))
		}
	}
}

func main() {
	// db init
	db.InitDB()

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
