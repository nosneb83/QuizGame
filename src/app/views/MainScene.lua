local MainScene = class("MainScene", function()
    return cc.Scene:create()
end)

require("json")
cc.exports.storyFile = {}

local rootNode
local nameText, premText, coinText
local bmBtns = {}
local menuBtns = {}
local menuBtnPos = {}
local menuBtnAnimFunc
local chatLayer, chatInput-- 聊天室Layer, InputField
local msgList, msgPrefab -- 訊息列表, prefab
local isChatting, hasNewMsg -- 聊天中, 有新訊息
local chatroomBtn

function MainScene:ctor()
    rootNode = cc.CSLoader:createNode("MainScene/MainScene.csb")
    self:addChild(rootNode)

    local statusBar = rootNode:getChildByName("StatusBar")
    nameText = statusBar:getChildByName("NameText")
    premText = statusBar:getChildByName("PremText")
    coinText = statusBar:getChildByName("CoinText")
    bmBtns = {
        statusBar:getChildByName("Bookmark1"),
        statusBar:getChildByName("Bookmark2"),
        statusBar:getChildByName("Bookmark3"),
        statusBar:getChildByName("Bookmark4"),
        statusBar:getChildByName("Bookmark5")
    }

    -- 選單按鈕
    menuBtns = {
        rootNode:getChildByName("Btns"):getChildByName("Btn_player"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_lab"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_battle"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_kacha"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_story")
    }
    menuBtns[1]:addTouchEventListener(self.enterPlayerScene)
    menuBtns[2]:addTouchEventListener(self.enterLabScene)
    menuBtns[3]:addTouchEventListener(self.enterBattleScene)
    menuBtns[4]:addTouchEventListener(self.enterKachaScene)
    menuBtns[5]:addTouchEventListener(self.enterStoryScene)
    menuBtnPos = {
        cc.p(menuBtns[1]:getPosition()),
        cc.p(menuBtns[2]:getPosition()),
        cc.p(menuBtns[3]:getPosition()),
        cc.p(menuBtns[4]:getPosition()),
        cc.p(menuBtns[5]:getPosition())
    }
    -- 選單按鈕左右滾動效果
    local menuAnimDur = 0.5 -- 選單按鈕滾動速度(時間長度)
    menuBtnAnimFunc = function(btn, to)
        btn:setEnabled(false)
        btn:stopAllActions()
        if to == 1 then
            btn:runAction(cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[1]),
            cc.ScaleTo:create(menuAnimDur, 0.01),
            cc.FadeTo:create(menuAnimDur, 0)
            ))
        elseif to == 2 then
            btn:runAction(cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[2]),
            cc.ScaleTo:create(menuAnimDur, 0.6),
            cc.FadeTo:create(menuAnimDur, 204)
            ))
        elseif to == 3 then
            btn:runAction(cc.Sequence:create(
            cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[3]),
            cc.ScaleTo:create(menuAnimDur, 1),
            cc.FadeTo:create(menuAnimDur, 204)
            ),
            cc.CallFunc:create(function() btn:setEnabled(true) end)))
        elseif to == 4 then
            btn:runAction(cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[4]),
            cc.ScaleTo:create(menuAnimDur, 0.6),
            cc.FadeTo:create(menuAnimDur, 204)
            ))
        elseif to == 5 then
            btn:runAction(cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[5]),
            cc.ScaleTo:create(menuAnimDur, 0.01),
            cc.FadeTo:create(menuAnimDur, 0)
            ))
        end
    end
    local menuLeftBtn = rootNode:getChildByName("Btns"):getChildByName("Btn_left")
    menuLeftBtn:addTouchEventListener(self.menuLeft)
    local menuRightBtn = rootNode:getChildByName("Btns"):getChildByName("Btn_right")
    menuRightBtn:addTouchEventListener(self.menuRight)

    -- 聊天室Layer
    chatLayer = cc.CSLoader:createNode("MainScene/ChatroomLayer.csb")
    rootNode:addChild(chatLayer)
    chatLayer:setVisible(false)
    chatroomBtn = rootNode:getChildByName("ChatroomBtn")
    chatroomBtn:setPressedActionEnabled(true)
    chatroomBtn:setZoomScale(-0.1)
    chatroomBtn:addTouchEventListener(self.openChatroom)
    chatLayer:getChildByName("Btn_return"):addTouchEventListener(self.closeChatroom)
    chatLayer:getChildByName("ChatPanel"):getChildByName("SendBtn")
    :addTouchEventListener(self.chat)
    chatInput = chatLayer:getChildByName("ChatPanel"):getChildByName("InputField")
    msgList = chatLayer:getChildByName("ChatPanel"):getChildByName("MsgList")
    msgPrefab = chatLayer:getChildByName("MsgPrefab")
    isChatting, hasNewMsg = false, false

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

    -- 更新UI
    self:updateUI()

    -- 跟server要劇情檔
    if #storyFile == 0 then
        local jsonObj = {
            op = "FETCH_STORY"
        }
        socket:send(json.encode(jsonObj))
    end
end

-- 更新UI
function MainScene:updateUI()
    nameText:setString(player.name)
    premText:setString("+" .. tostring(math.min(999, player.bmp)))
    coinText:setString(string.comma_value(tostring(player.coin)))
    for i = 1, #bmBtns do
        bmBtns[i]:setEnabled(i <= player.bm)
    end
end

-- 進入各頁面
function MainScene:enterPlayerScene(type)
    if type == ccui.TouchEventType.ended then
        print("個人頁面")
    end
end
function MainScene:enterLabScene(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/CharScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function MainScene:enterBattleScene(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/BattleModeScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function MainScene:enterKachaScene(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/ShopScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function MainScene:enterStoryScene(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/StoryMenuScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

-- 選單滾動
function MainScene:menuLeft(type)
    if type == ccui.TouchEventType.ended then
        for i = 1, 5 do
            menuBtnAnimFunc(menuBtns[i], i % 5 + 1)
        end
        table.insert(menuBtns, 1, table.remove(menuBtns))
    end
end
function MainScene:menuRight(type)
    if type == ccui.TouchEventType.ended then
        for i = 1, 5 do
            menuBtnAnimFunc(menuBtns[i], (i - 2) % 5 + 1)
        end
        table.insert(menuBtns, table.remove(menuBtns, 1))
    end
end

-- 開啟/關閉聊天室
function MainScene:openChatroom(type)
    if type == ccui.TouchEventType.ended then
        isChatting, hasNewMsg = true, false
        MainScene:setChatIcon()
        chatLayer:setVisible(true)
    end
end
function MainScene:closeChatroom(type)
    if type == ccui.TouchEventType.ended then
        isChatting = false
        chatLayer:setVisible(false)
    end
end

-- 聊天室送出訊息
function MainScene:chat(type)
    if type == ccui.TouchEventType.ended then
        if chatInput:getString() == "" then return end
        local jsonObj = {
            op = "CHAT",
            name = player.name,
            msg = chatInput:getString()
        }
        chatInput:setString("")
        socket:send(json.encode(jsonObj))
    end
end

-- 聊天室按鈕圖案
function MainScene:setChatIcon()
    if hasNewMsg then
        chatroomBtn:loadTextureNormal("MainScene/Chatroom_icon.png")
        chatroomBtn:loadTexturePressed("MainScene/Chatroom_icon_2.png")
    else
        chatroomBtn:loadTextureNormal("MainScene/Chatroom_icon_3.png")
        chatroomBtn:loadTexturePressed("MainScene/Chatroom_icon_4.png")
    end
end

-- 處理server訊息
function MainScene:handleOp(jsonObj)
    local op = jsonObj["op"]
    if op == "CHAT" then -- 顯示聊天訊息
        dump(jsonObj)
        if isChatting == false then
            hasNewMsg = true
            self:setChatIcon()
        end
        local msg = jsonObj["name"] .. " : " .. jsonObj["msg"]
        local msgItem = msgPrefab:clone()
        msgItem:getChildByName("Msg"):setString(msg)
        msgList:pushBackCustomItem(msgItem)
    elseif op == "STORY_FILE" then -- 劇情檔
        storyFile = jsonObj["file"]
    end
end

return MainScene