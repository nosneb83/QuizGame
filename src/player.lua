local Player = class("Player")

function Player:ctor()
    print("create player")
end

function Player:loginInit(jsonObj)
    self.id = jsonObj["id"]
    self.name = jsonObj["name"]
    self.bm = jsonObj["bm"]
    self.bmp = jsonObj["bmp"]
    self.coin = jsonObj["coin"]
    print("login init success")
end

return Player