package main

import (
	"db"
	"encoding/json"
	"fmt"
	"math/rand"
	"net"
	"questions"
)

const battlePlayerCount = 3

var userNum int = 0 // client流水號
var message = make(chan string)
var onlinemap map[string]clientData = make(map[string]clientData)
var token []int

var chanNum string

// var questionList []questions.QuestionObj

type clientData struct {
	name     string
	conn     net.Conn
	id       int
	heroType int
	ready    bool
}

// server為每個client開一個goroutine來handle
func handleConnection(conn net.Conn) {
	defer conn.Close()

	addr, client := registerNewGuest(conn)

	var haschat = make(chan bool)

	// 讀取題庫
	questionList := questions.ReadQuestionsFromCSV()
	fmt.Println(questionList)

	// 開一個goroutine來接收來自client的訊息
	go func() {
		buf := make([]byte, 1024)
		var msg string
		for {
			n, _ := conn.Read(buf)
			if n == 0 { // 離線
				fmt.Printf("%s [%s] 離線\n", client.name, addr)
				delete(onlinemap, addr)
				// token 歸還
				// fmt.Println("client name =", client.name, ", client id =", client.id)
				token = append(token, client.id)
				// fmt.Println(token)
				// broadcast(fmt.Sprintf("2 %s 下線囉", client.name), addr)
				return
			}

			msg = string(buf[:n])
			// msg = parseInput(msg)
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
				playerLogin(conn, jsonObj["ac"].(string), jsonObj["pw"].(string))
			case "CLIENT_READY":
				// fmt.Println("question list length =", len(questionList))
				randQuestion := questionList[rand.Intn(len(questionList))]
				q, _ := json.Marshal(map[string]interface{}{
					"op":     "SEND_QUESTION",
					"domain": randQuestion.Domain,
					"difcty": randQuestion.Difcty,
					"qtype":  randQuestion.QType,
					"ques":   randQuestion.Ques,
					"ans":    randQuestion.Ans})
				conn.Write([]byte(q))
			}
			// if jsonObj["op"] == "CREATE_PLAYER" { // 大廳列表
			// 	client = lobbyAddPlayer(addr, client, jsonObj)
			// 	broadcastIncludeSelf(msg)
			// } else if jsonObj["op"] == "PLAYER_ENTER_BATTLE" {
			// 	createBattleChar(client)
			// } else if jsonObj["inputType"] != "" {
			// 	broadcastIncludeSelf(msg)
			// }

			haschat <- true
		}
	}()
	for {
		select {
		case <-haschat:
		}
	}
}

// 玩家登入
func playerLogin(conn net.Conn, ac string, pw string) {
	playerExists := db.CheckAccount(ac, pw)
	var msg []byte
	if playerExists {
		msg, _ = json.Marshal(map[string]interface{}{
			"op": "LOGIN_SUCCESS"})
	} else {
		msg, _ = json.Marshal(map[string]interface{}{
			"op": "LOGIN_FAIL"})
	}
	conn.Write(msg)
}

// 新user加入聊天室
func registerNewGuest(conn net.Conn) (string, clientData) {
	addr := conn.RemoteAddr().String()
	client := clientData{"User" + fmt.Sprintf("%d", userNum), conn, 0, 0, false}
	userNum++
	fmt.Printf("%s [%s] 登入\n", client.name, addr)

	// 目前大廳有誰
	for _, client := range onlinemap {
		if !client.ready {
			continue
		}
		readyPlayer, err := json.Marshal(map[string]interface{}{
			"op":         "CREATE_PLAYER",
			"playerName": client.name,
			"heroType":   client.heroType})
		if err != nil {
			fmt.Println("Marshal err: ", err)
		}
		conn.Write([]byte(readyPlayer))
	}

	// 新client加入server線上列表
	onlinemap[addr] = client

	return addr, client
}

// 大廳加入新玩家
func lobbyAddPlayer(addr string, client clientData, jsonObj map[string]interface{}) clientData {
	// 建立玩家資料
	client.name = jsonObj["playerName"].(string)
	client.heroType = int(jsonObj["heroType"].(float64))
	client.ready = true
	client.id = token[0]
	token = token[1:]
	fmt.Println(token)
	onlinemap[addr] = client

	// Assign Player ID
	playerIDAssign, err := json.Marshal(map[string]interface{}{
		"op":       "ASSIGN_ID",
		"playerID": client.id})
	if err != nil {
		fmt.Println("Marshal err: ", err)
	}
	client.conn.Write([]byte(playerIDAssign))

	// 當所有玩家都ready 即開始戰鬥
	if checkReady() {
		battleStartMsg, err := json.Marshal(map[string]interface{}{
			"op": "BATTLE_START"})
		if err != nil {
			fmt.Println("Marshal err: ", err)
		}
		broadcastIncludeSelf(string(battleStartMsg))
	}

	return client
}

// 檢查是否所有人都ready
func checkReady() bool {
	readyCount := 0
	for _, client := range onlinemap {
		if client.ready {
			readyCount++
		} else {
			return false
		}
	}
	return readyCount >= battlePlayerCount
}

// 戰鬥場景建立各玩家角色
func createBattleChar(client clientData) {
	battleCharData, err := json.Marshal(map[string]interface{}{
		"op":         "CREATE_BATTLE_CHAR",
		"playerName": client.name,
		"playerID":   client.id,
		"heroType":   client.heroType})
	if err != nil {
		fmt.Println("Marshal err: ", err)
	}
	broadcastIncludeSelf(string(battleCharData))
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
	// db.CreateTablePlayers()
	// db.RegisterNewPlayer("testAC", "testPW")

	// TCP 連線
	// listener, _ := net.Listen("tcp", "0.0.0.0:8888")
	listener, _ := net.Listen("tcp", "127.0.0.1:8888")

	// // 製作 play token
	// token = append(token, 1, 2, 3, 4)
	// rand.Seed(time.Now().UnixNano())
	// rand.Shuffle(len(token), func(i, j int) {
	// 	token[i], token[j] = token[j], token[i]
	// })
	// fmt.Println(token)

	for {
		// 有新的client連進來
		conn, _ := listener.Accept()
		// 開一個goroutine來handle這個client
		go handleConnection(conn)
	}
}
