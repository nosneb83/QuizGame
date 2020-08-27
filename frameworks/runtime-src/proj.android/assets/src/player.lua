local Player = class("Player")

function Player:ctor()
    self.id = 0
    self.name = ""
    self.char = 1
    self.bm = 0
    self.bmp = 0
    self.coin = 0
end

function Player:loginInit(jsonObj)
    self.id = jsonObj["id"]
    self.name = jsonObj["name"]
    self.char = jsonObj["char"]
    self.bm = jsonObj["bm"]
    self.bmp = jsonObj["bmp"]
    self.coin = jsonObj["coin"]
    self.skillCD = 15
    -- print("login init success")
end

function Player:isSkillReady()
    if self == nil then return false end
    -- if self.health <= self.skillReadyTime then
    --     return true
    -- elseif self.tempHealth <= self.skillReadyTime then
    --     return true
    -- else return false end
    if self.skillGauge >= self.skillCD then return true
    else return false end
end

return Player