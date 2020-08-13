package battle

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net"
	"questions"
	"sync"
	"time"
)

type player struct {
	id     int
	health float64
}

var rooms map[int][]*player

// RoomState 0:等待 1:戰鬥 2:傷害&輸贏
var RoomState = 0

// EnterRoom 進入房間
func EnterRoom(roomNum int, id int) {
	// 初始化map
	if rooms == nil {
		rooms = make(map[int][]*player)
	}
	// 無論房間是否存在，都可以直接append玩家
	rooms[roomNum] = append(rooms[roomNum], &player{id, 100.0})

	log()
}

// LeaveRoom 離開房間
func LeaveRoom(id int) {
	// 從房間裡刪掉這個玩家
	for k, players := range rooms {
		var newPlayerList []*player
		for _, p := range players {
			if p.id != id {
				newPlayerList = append(newPlayerList, p)
			}
		}
		rooms[k] = newPlayerList
	}

	log()
}

func log() {
	for k, v := range rooms {
		fmt.Println("room", k, "has", len(v), "players")
		for _, p := range v {
			fmt.Println("player", p.id)
		}
	}
}

var questionList []questions.QuestionObj

// StartBattle 開始戰鬥
func StartBattle(id1 int, id2 int, conn1 net.Conn, conn2 net.Conn, wg1 *sync.WaitGroup) {
	defer wg1.Done()

	questionList = questions.ReadQuestionsFromCSV()

	sendQuestion(conn1, conn2)

	wg := sync.WaitGroup{}
	wg.Add(2)

	go receive(conn1, conn2, &wg)
	go receive(conn2, conn1, &wg)

	for {
		wg.Wait()
		sendQuestion(conn1, conn2)
		wg.Add(2)
	}
}

func receive(connSelf net.Conn, connOther net.Conn, wg *sync.WaitGroup) {
	buf := make([]byte, 1024)
	var msg string
	for {
		n, _ := connSelf.Read(buf)
		fmt.Println("msg:", string(buf[:n]))
		if n == 0 { // 離線
			// battle.LeaveRoom(playerID)
			return
		}

		msg = string(buf[:n])
		fmt.Printf("battle : %s\n", msg) // server印出訊息

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
		case "ANSWER":
			connSelf.Write([]byte(msg))
			connOther.Write([]byte(msg))
			time.Sleep(2 * time.Second)
			wg.Done()
			fmt.Println("done")
		}
	}
}

func sendQuestion(conn1 net.Conn, conn2 net.Conn) {
	randQuestion := questionList[rand.Intn(len(questionList))]
	q, _ := json.Marshal(map[string]interface{}{
		"op":     "SEND_QUESTION",
		"domain": randQuestion.Domain,
		"difcty": randQuestion.Difcty,
		"qtype":  randQuestion.QType,
		"ques":   randQuestion.Ques,
		"ans":    randQuestion.Ans})
	conn1.Write([]byte(q))
	conn2.Write([]byte(q))
}
