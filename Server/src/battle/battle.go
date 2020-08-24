package battle

import (
	"encoding/json"
	"fmt"
	"math"
	"math/rand"
	"player"
	"questions"
	"time"
)

type p *player.Player

// type room1V1 struct {
// 	ID      int         // 房號
// 	State   int         // 房間狀態 0:等待中 1:戰鬥中
// 	Ch      chan string // 玩家答題等等訊息從這傳入
// 	Players map[int]p
// }

// func (r *room1V1) Join(player p) {
// 	r.Players[player.ID] = player
// 	if len(r.Players) == 2 {
// 		go r.StartBattle()
// 		r.Players = make(map[int]p)
// 	}
// }

// func (r *room1V1) StartBattle() {

// }

var waitingRoom1V1 map[int]p = make(map[int]p) // k:id, v:playerObj
var waitingRoomCh chan map[string]interface{} = make(chan map[string]interface{})

// Join1V1 玩家加入1V1等待房
func Join1V1(player p) chan map[string]interface{} {
	waitingRoom1V1[player.ID] = player
	battleCh := waitingRoomCh
	if len(waitingRoom1V1) == 2 {
		go Battle1V1(waitingRoom1V1, waitingRoomCh)
		waitingRoom1V1 = make(map[int]p)
		waitingRoomCh = make(chan map[string]interface{})
		fmt.Println("open another room")
	}
	return battleCh
}

var questionList []questions.QuestionObj

// Battle1V1 開始1V1戰鬥
func Battle1V1(players map[int]p, ch chan map[string]interface{}) {
	// 玩家血量初始化
	for _, v := range players {
		v.Health = 60.0
	}
	// 出題
	questionList = questions.ReadQuestionsFromCSV()
	rand.Seed(time.Now().UTC().UnixNano())
	sendQuestion(players)
	// 接收玩家答案
	receivedAnswer := make([]map[string]interface{}, 0, 2)
	for {
		jsonObj := <-ch
		if jsonObj["op"] == "SURRENDER" {
			for _, v := range players {
				msgSend, _ := json.Marshal(map[string]interface{}{
					"op":     "BATTLE_RESULT",
					"id":     jsonObj["id"],
					"health": 0.0})
				v.Ch <- string(msgSend)
				msgSend, _ = json.Marshal(map[string]interface{}{
					"op":  "BATTLE_OVER",
					"win": v.ID != int(jsonObj["id"].(float64))})
				v.Ch <- string(msgSend)
			}
			break
		}
		receivedAnswer = append(receivedAnswer, jsonObj)
		// 計算雙方扣血
		if len(receivedAnswer) == 2 {
			bothCorrect := true
			slowestAns := make(map[string]interface{})
			slowestAns["time"] = float64(-1.0)
			for _, v := range receivedAnswer {
				// 扣掉消耗的時間
				players[int(v["id"].(float64))].Health -= v["time"].(float64)
				// 答錯扣血
				if !v["cor"].(bool) {
					players[int(v["id"].(float64))].Health -= 7.0
					bothCorrect = false
				}
				// 找出答比較慢的人
				if v["time"].(float64) > slowestAns["time"].(float64) {
					slowestAns = v
				}
			}
			// 雙方都答對時, 較慢者扣血
			if bothCorrect {
				players[int(slowestAns["id"].(float64))].Health -= 3.0
			}
			// 處理完畢, 通知client演出
			loser := &player.Player{ID: -1, Health: 0.0}
			for _, v := range players {
				if v.Health <= loser.Health {
					loser = v
				}
				msgSend, _ := json.Marshal(map[string]interface{}{
					"op":     "BATTLE_RESULT",
					"id":     v.ID,
					"health": math.Max(0.0, v.Health)})
				for _, vv := range players {
					vv.Ch <- string(msgSend)
				}
			}
			// 清空答案
			receivedAnswer = receivedAnswer[:0]
			// 判斷是否gameover
			if loser.ID != -1 {
				time.Sleep(2 * time.Second)
				for _, v := range players {
					msgSend, _ := json.Marshal(map[string]interface{}{
						"op":  "BATTLE_OVER",
						"win": v.ID != loser.ID})
					v.Ch <- string(msgSend)
				}
				break
			} else {
				// 印出玩家血量
				for _, v := range players {
					fmt.Println("Player ID:", v.ID, ", Health:", v.Health)
				}
				// 出下一題
				time.Sleep(2 * time.Second)
				sendQuestion(players)
			}
		}
	}
}

func sendQuestion(players map[int]p) {
	randQuestion := questionList[rand.Intn(len(questionList))]
	q, _ := json.Marshal(map[string]interface{}{
		"op":     "SEND_QUESTION",
		"domain": randQuestion.Domain,
		"difcty": randQuestion.Difcty,
		"qtype":  randQuestion.QType,
		"ques":   randQuestion.Ques,
		"ans":    randQuestion.Ans})
	for _, v := range players {
		v.Ch <- string(q)
	}
}

// LeaveWaitingRoom 等待中離線
func LeaveWaitingRoom(id int) {
	delete(waitingRoom1V1, id)
}
