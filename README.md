# MuseLab debug env
1. 安裝 Git
2. 安裝 MySQL
3. 安裝 Golang 套件: go-sql-driver
```
> go get -u github.com/go-sql-driver/mysql
```
4. 安裝 VS Code 的插件: luaide-lite
5. 把程式碼 clone 下來
https://github.com/nosneb83/QuizGame
6. 把 QuizGame\Server 加進 GOPATH
7. Server\src\db\db.go:14行開始, 輸入 DB 資料, 如下:
```go
14  // DB連線資訊
15  const (
16      USERNAME = "benson"
17      PASSWORD = "bensonli"
18      NETWORK  = "tcp"
19      SERVER   = "172.29.19.70"
20      PORT     = 3306
21      DATABASE = "game"
22  )
```
8. Server\src\Server.go:241行, 註解拿掉 (用來新增table)
```go
241  db.CreateTablePlayers()
```
9. 執行 Server 程式
```
> go run .\src\Server.go
```
10. src\app\views\LoginScene.lua:66行, 把 IP 改成 Server IP (在本機上可改成 localhost)
```lua
66  socket:connect("127.0.0.1", "8888")
```
11. Start Debug
```
F5
```
