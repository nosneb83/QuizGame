package battle

import "fmt"

type player struct {
	id     int
	health float64
}

type room struct {
	roomNum int
	players []player
}

var rooms []*room

// EnterRoom 進入房間
func EnterRoom(roomNum int, id int) {
	targetRoom := new(room)
	for _, v := range rooms {
		if v.roomNum == roomNum {
			targetRoom = v
		}
	}
	if len(targetRoom.players) == 0 { // 查無此房
		fmt.Println("Room Not Found")
		targetRoom.roomNum = roomNum
		targetRoom.players = append(targetRoom.players, player{id, 100.0})
		rooms = append(rooms, targetRoom)
	} else {
		fmt.Println("Room Found")
		targetRoom.players = append(targetRoom.players, player{id, 100.0})
	}

	for _, v := range rooms {
		if v.roomNum == roomNum {
			for _, p := range v.players {
				fmt.Println("players in room:", p.id)
			}
		}
	}
}
