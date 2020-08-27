local CharScene = class("CharScene", function()
    return cc.Scene:create()
end)

local rootNode
local chars -- 立繪
local tabs -- 分頁按鈕
local layers -- 角色資訊頁面
local currentShowingChar -- 現在顯示的角色

function CharScene:ctor()
    rootNode = cc.CSLoader:createNode("Char/CharScene.csb")
    self:addChild(rootNode)
    rootNode:getChildByName("Btn_return")
    :addTouchEventListener(self.mainPage)
    if player.char == 0 then player.char = 1 end

    -- 立繪
    chars = {
        rootNode:getChildByName("Chars"):getChildByName("Teko"),
        rootNode:getChildByName("Chars"):getChildByName("Same")
    }

    -- 分頁按鈕
    tabs = {
        rootNode:getChildByName("CharInfo"):getChildByName("IntroBtn"),
        rootNode:getChildByName("CharInfo"):getChildByName("SkillBtn"),
        rootNode:getChildByName("CharInfo"):getChildByName("RelatBtn")
    }
    for _, v in ipairs(tabs) do
        v:addTouchEventListener(self.switchTab)
    end

    -- 角色資訊頁面
    layers = {
        cc.CSLoader:createNode("Char/IntroLayer1.csb"),
        cc.CSLoader:createNode("Char/SkillLayer1.csb"),
        cc.CSLoader:createNode("Char/RelatLayer1.csb"),
        cc.CSLoader:createNode("Char/IntroLayer2.csb"),
        cc.CSLoader:createNode("Char/SkillLayer2.csb"),
        cc.CSLoader:createNode("Char/RelatLayer2.csb")
    }
    rootNode:getChildByName("CharInfo"):addChild(layers[1])
    rootNode:getChildByName("CharInfo"):addChild(layers[2])
    rootNode:getChildByName("CharInfo"):addChild(layers[3])
    rootNode:getChildByName("CharInfo"):addChild(layers[4])
    rootNode:getChildByName("CharInfo"):addChild(layers[5])
    rootNode:getChildByName("CharInfo"):addChild(layers[6])
    self:showChar(player.char)

    rootNode:getChildByName("CharMenu"):getChildByName("Teko")
    :addTouchEventListener(self.chooseChar)
    rootNode:getChildByName("CharMenu"):getChildByName("Same")
    :addTouchEventListener(self.chooseChar)
    
    -- socket設定
    local function ReceiveCallback(msg)
        -- 把每個{}分割開
        local opStrs = string.splitAfter(msg, "}")
        table.remove(opStrs, #opStrs)
        -- 一個一個輪流decode
        for i = 1, #opStrs do
            local jsonObj = json.decode(opStrs[i])
            self:handleOp(jsonObj)
        end
    end
    socket:setReceiveCallback(ReceiveCallback)
end

-- 切換當前顯示角色
function CharScene:showChar(char)
    currentShowingChar = char
    self:showUI(currentShowingChar * 3 - 2)
    for k, v in ipairs(chars) do
        v:setVisible(k == char)
    end
    for k, v in ipairs(tabs) do
        v:setEnabled(k ~= 1)
    end
end

-- 切換頁面
function CharScene:showUI(layer)
    for _, v in ipairs(layers) do
        v:setVisible(false)
    end
    layers[layer]:setVisible(true)
end

-- 按鈕callbacks
function CharScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function CharScene:chooseChar(type)
    if type == ccui.TouchEventType.ended then
        CharScene:showChar(self:getTag())
    end
end
function CharScene:switchTab(type)
    if type == ccui.TouchEventType.ended then
        CharScene:showUI(currentShowingChar * 3 - 3 + self:getTag())
        for k, v in ipairs(tabs) do
            v:setEnabled(k ~= self:getTag())
        end
    end
end

-- 處理server訊息
function CharScene:handleOp(jsonObj)
    dump(jsonObj)
    local op = jsonObj["op"]
    if op == "CHAT" then
        
    end
end

return CharScene