local BattleScene = class("BattleScene", function()
    return cc.Scene:create()
end)

require("json")
local opponent = require("player.lua"):new()

local rootNode
local quesLayout, ansLayout -- layout
local domainText -- 題目類型&領域
local qText, qText2, qText3 -- 題目文字
local correctAns -- 當前題目的正確答案
local ansPnlTF, ansPnlCH -- 選項panel
local ansBtnO, ansBtnX, ansBtnA, ansBtnB, ansBtnC, ansBtnD -- 選項按鈕
local currentAnsBtns = {} -- 當前這一題的選項按鈕們
local feedbackT, feedbackF -- 答對答錯文字
local sfxQues, sfxCorrect, sfxWrong -- 答題音效
local enterCountdownText -- 開場倒數文字
local countdownText -- 倒數文字
local countdownNum -- 倒數秒數
local playerHealthBar, opponentHealthBar, healthRec -- 血條
local isWaiting = false -- 是否正在等待另一名玩家
local skillBtn -- 開技能的按鈕
local skillMark -- 技能CD標示
local isBehind = false -- 玩家是否正在落後
local vicLayer, defLayer -- 勝負結算畫面
local waitLayer -- 等待畫面

function BattleScene:ctor()
    rootNode = cc.CSLoader:createNode("Battle/BattleScene.csb")
    self:addChild(rootNode)
    quesLayout = rootNode:getChildByName("Question")
    domainText = quesLayout:getChildByName("DomainText")
    qText = quesLayout:getChildByName("Text")
    qText2 = quesLayout:getChildByName("Text2")
    qText3 = quesLayout:getChildByName("Text3")

    quesLayout:setVisible(false) -- 隱藏題目layout

    ansLayout = rootNode:getChildByName("Answer")
    ansPnlTF = ansLayout:getChildByName("TF")
    ansBtnO = ansPnlTF:getChildByName("O")
    ansBtnO:addTouchEventListener(self.answerO)
    ansBtnX = ansPnlTF:getChildByName("X")
    ansBtnX:addTouchEventListener(self.answerX)

    ansPnlCH = ansLayout:getChildByName("CH")
    ansBtnA = ansPnlCH:getChildByName("A")
    ansBtnA:addTouchEventListener(self.answerA)
    ansBtnB = ansPnlCH:getChildByName("B")
    ansBtnB:addTouchEventListener(self.answerB)
    ansBtnC = ansPnlCH:getChildByName("C")
    ansBtnC:addTouchEventListener(self.answerC)
    ansBtnD = ansPnlCH:getChildByName("D")
    ansBtnD:addTouchEventListener(self.answerD)

    feedbackT = rootNode:getChildByName("Answer_feedback"):getChildByName("Correct")
    feedbackF = rootNode:getChildByName("Answer_feedback"):getChildByName("Wrong")

    enterCountdownText = rootNode:getChildByName("StartCountdown")
    countdownText = ansLayout:getChildByName("Countdown")
    skillBtn = ansLayout:getChildByName("SkillButton")
    skillBtn:addTouchEventListener(self.skillOnClick)
    skillMark = rootNode:getChildByName("SkillCooldownMark")

    ansLayout:setVisible(false) -- 隱藏答案layout

    playerHealthBar = rootNode:getChildByName("PlayerHealth")
    opponentHealthBar = rootNode:getChildByName("OpponentHealth")
    healthRec = playerHealthBar:getBoundingBox() -- 取得血條BoundingBox
    playerHealthBar:setScaleY(0)
    opponentHealthBar:setScaleY(0)

    vicLayer = cc.CSLoader:createNode("Battle/Gameover/Victory/VictoryLayer.csb")
    vicLayer:getChildByName("Layout"):getChildByName("Button_again")
    :addTouchEventListener(self.playAgain)
    vicLayer:getChildByName("Layout"):getChildByName("Button_return")
    :addTouchEventListener(self.returnMain)
    vicLayer:setVisible(false)
    rootNode:addChild(vicLayer)

    defLayer = cc.CSLoader:createNode("Battle/Gameover/Defeat/DefeatLayer.csb")
    defLayer:getChildByName("Layout"):getChildByName("Button_again")
    :addTouchEventListener(self.playAgain)
    defLayer:getChildByName("Layout"):getChildByName("Button_return")
    :addTouchEventListener(self.returnMain)
    defLayer:setVisible(false)
    rootNode:addChild(defLayer)

    -- 設定等待畫面
    waitLayer = cc.CSLoader:createNode("WaitingRoom/WaitingLayer.csb")
    rootNode:addChild(waitLayer)
    waitLayer:getChildByName("Bg"):runAction(cc.RepeatForever:create(cc.RotateBy:create(10, 360)))

    -- 設定頭像
    if player.id == 2 then
        local playerIcon = rootNode:getChildByName("StaticPanel"):getChildByName("PlayerIcon")
        local opponentIcon = rootNode:getChildByName("StaticPanel"):getChildByName("OpponentIcon")
        local p1x, p1y = playerIcon:getPosition()
        local p2x, p2y = opponentIcon:getPosition()
        playerIcon:setPosition(p2x, p2y)
        opponentIcon:setPosition(p1x, p1y)
    end

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

    -- 隨機種子
    math.randomseed(os.time())

    -- 註冊倒數Update
    rootNode:scheduleUpdateWithPriorityLua(function(dt) self:countdownUpdate(dt) end, 0)
    rootNode:pause()

    -- 場景載入後1秒鐘開始出題
    rootNode:runAction(cc.Sequence:create(
    cc.DelayTime:create(1),
    cc.CallFunc:create(self.enterRoom)))
end

-- 玩家進入房間
function BattleScene:enterRoom()
    local jsonObj = {
        op = "ENTER_ROOM",
        room = 100,
        id = player.id
    }
    isWaiting = true
    socket:send(json.encode(jsonObj))
    print("send")
end

-- 下一題
function BattleScene:nextQuestion()
    local jsonObj = {
        op = "CLIENT_READY"
    }
    socket:send(json.encode(jsonObj))
end

-- 答題回饋
local feedbackDuration = 2
function BattleScene:answerO(type)
    if type == ccui.TouchEventType.ended then BattleScene:answer(1) end
end
function BattleScene:answerX(type)
    if type == ccui.TouchEventType.ended then BattleScene:answer(2) end
end
function BattleScene:answerA(type)
    if type == ccui.TouchEventType.ended then BattleScene:answer(1) end
end
function BattleScene:answerB(type)
    if type == ccui.TouchEventType.ended then BattleScene:answer(2) end
end
function BattleScene:answerC(type)
    if type == ccui.TouchEventType.ended then BattleScene:answer(3) end
end
function BattleScene:answerD(type)
    if type == ccui.TouchEventType.ended then BattleScene:answer(4) end
end
function BattleScene:answer(playerAns)
    self:setAnsBtnsEnabled(false)
    local timeUsed = self:stopCountdown()
    if playerAns == correctAns then
        self:showFeedback(feedbackT, feedbackF)
        cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Buzzer01-mp3/Quiz-Buzzer01-1.mp3")
    else
        self:showFeedback(feedbackF, feedbackT)
        cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Wrong_Buzzer01-mp3/Quiz-Wrong_Buzzer01-1.mp3")
    end
    local jsonObj = {
        op = "ANSWER",
        id = player.id,
        cor = playerAns == correctAns,
        time = timeUsed
    }
    socket:send(json.encode(jsonObj))
end
function BattleScene:showFeedback(showing, hiding)
    hiding:stopAllActions()
    hiding:runAction(cc.Hide:create())
    showing:stopAllActions()
    showing:runAction(cc.Sequence:create(cc.Show:create(), cc.DelayTime:create(feedbackDuration), cc.Hide:create()))
end

-- 進房倒數
function BattleScene:countDown(jsonObj)
    waitLayer:setVisible(false)

    -- 血量初始化
    player.health = 60
    player.tempHealth = 60
    opponent.health = 60

    -- 數字
    local initScale = cc.ScaleTo:create(0, 5)
    local fadeIn = cc.FadeIn:create(0.3)
    local scaleTo = cc.ScaleTo:create(0.3, 2)
    local fadeOut = cc.FadeOut:create(0)
    local count = cc.Sequence:create(initScale, cc.Spawn:create(fadeIn, scaleTo),
    cc.DelayTime:create(0.5), fadeOut, cc.DelayTime:create(0.2))

    -- 執行動作
    playerHealthBar:runAction(cc.ScaleTo:create(2, 1, 1))
    opponentHealthBar:runAction(cc.ScaleTo:create(2, 1, 1))
    enterCountdownText:runAction(cc.Sequence:create(
    cc.DelayTime:create(0.5),
    cc.CallFunc:create(function() enterCountdownText:setString("3") end),
    count,
    cc.CallFunc:create(function() enterCountdownText:setString("2") end),
    count,
    cc.CallFunc:create(function() enterCountdownText:setString("1") end),
    count,
    cc.CallFunc:create(function()
        quesLayout:setVisible(true)
        ansLayout:setVisible(true)
        self:setSkillCDMarkPos()
        self:showQuestion(jsonObj)
    end)))

    -- 播音效
    local function countSound()
        cc.SimpleAudioEngine:getInstance():playEffect("SFX/count3.mp3")
    end
    local sound = cc.CallFunc:create(countSound)
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.01), sound))
end

-- 設定技能CD箭頭位置
function BattleScene:setSkillCDMarkPos()
    if player.tempHealth == nil then
        player.skillReadyTime = player.health - player.skillCD
    else
        player.skillReadyTime = math.min(player.health, player.tempHealth) - player.skillCD
    end
    if player.skillReadyTime < 0 then
        skillMark:setVisible(false)
        return
    end
    local skillMarkX = healthRec.x + healthRec.width
    local skillMarkY = healthRec.y + healthRec.height * player.skillReadyTime / 60
    skillMark:setVisible(true):setPosition(skillMarkX, skillMarkY)
end

-- 答題倒數
function BattleScene:startCountdown()
    countdownNum = 10
    countdownText:setString(string.format("%.2f", countdownNum))
    rootNode:resume()
end
function BattleScene:countdownUpdate(dt)
    if countdownNum == nil then return end
    countdownNum = math.max(0, countdownNum - dt)
    -- 倒數數字
    countdownText:setString(string.format("%.2f", countdownNum))
    -- 血條隨時間慢慢遞減
    player.tempHealth = math.max(0, player.health - 10 + countdownNum)
    playerHealthBar:setScaleY(player.tempHealth / 60)
    skillBtn:setEnabled(player:isSkillReady())
    -- 血量歸零直接gameover
    if player.tempHealth == 0 then
        self:surrender()
        return
    end
    -- 時間用盡時視為答錯
    if countdownNum == 0 then
        self:answer(5)
    end
end
function BattleScene:stopCountdown()
    local timeUsed = nil
    if countdownNum ~= nil then timeUsed = 10 - countdownNum end
    countdownNum = nil
    countdownText:setString("")
    rootNode:pause()
    return timeUsed
end

-- 技能
function BattleScene:skillOnClick(type)
    if type == ccui.TouchEventType.ended then
        skillBtn:setEnabled(false)
        BattleScene:setSkillCDMarkPos()
        -- 顯示答案選項
        ansBtnO:setVisible(correctAns == 1)
        ansBtnX:setVisible(correctAns == 2)
        ansBtnA:setVisible(correctAns == 1)
        ansBtnB:setVisible(correctAns == 2)
        ansBtnC:setVisible(correctAns == 3)
        ansBtnD:setVisible(correctAns == 4)
        -- 領先時多顯示一個選項
        if isBehind == false then
            local rand = math.random(3)
            if rand == correctAns then rand = 4 end
            if rand == 1 then
                ansBtnO:setVisible(true)
                ansBtnA:setVisible(true)
            elseif rand == 2 then
                ansBtnX:setVisible(true)
                ansBtnB:setVisible(true)
            elseif rand == 3 then
                ansBtnC:setVisible(true)
            elseif rand == 4 then
                ansBtnD:setVisible(true)
            end
        end
    end
end

-- 提前結束 (投降 or 時間用盡)
function BattleScene:surrender()
    self:setAnsBtnsEnabled(false)
    local timeUsed = self:stopCountdown()
    local jsonObj = {
        op = "SURRENDER",
        id = player.id,
        time = timeUsed
    }
    socket:send(json.encode(jsonObj))
end

-- 戰鬥結束
function BattleScene:gameover(win)
    self:setAnsBtnsEnabled(false)
    self:stopCountdown()
    if win then
        vicLayer:setVisible(true)
    else
        defLayer:setVisible(true)
    end
end
function BattleScene:playAgain(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/BattleScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function BattleScene:returnMain(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/BattleModeScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

-- Handle Server Op
function BattleScene:handleOp(jsonObj)
    dump(jsonObj)
    -- 處理指令
    local op = jsonObj["op"]
    if op == "SEND_QUESTION" then
        if isWaiting then
            print("is waiting")
            self:countDown(jsonObj)
            isWaiting = false
        else
            print("not waiting")
            self:showQuestion(jsonObj)
        end
    elseif op == "BATTLE_RESULT" then
        if jsonObj["id"] == player.id then
            player.health = jsonObj["health"]
            local s = cc.ScaleTo:create(0.7, 1, player.health / 60)
            local e = cc.EaseInOut:create(s, 3)
            playerHealthBar:runAction(e)
        else
            opponent.health = jsonObj["health"]
            local s = cc.ScaleTo:create(0.7, 1, opponent.health / 60)
            local e = cc.EaseInOut:create(s, 3)
            opponentHealthBar:runAction(e)
        end
    elseif op == "BATTLE_OVER" then
        self:gameover(jsonObj["win"])
    end
end

-- 顯示題目和選項
function BattleScene:showQuestion(jsonObj)
    local qType, domain
    -- 題型
    if jsonObj["qtype"] == "TF" then -- 是非題
        qType = "是非題"
        qText:setString(jsonObj["ques"][1])
        qText2:setString("")
        qText3:setString("")
        if jsonObj["ans"][1] == "O" then
            correctAns = 1
        else
            correctAns = 2
        end
        self:showAnsPnl(ansPnlTF, ansPnlCH)
        self:setAnsBtnsEnabled(true, ansBtnO, ansBtnX)
    elseif jsonObj["qtype"] == "CH" then -- 選擇題
        qType = "選擇題"
        qText:setString(jsonObj["ques"][1])
        qText2:setString("")
        qText3:setString("")
        local ansStr = jsonObj["ans"][1]
        math.shuffle(jsonObj["ans"])
        ansBtnA:setTitleText(jsonObj["ans"][1])
        ansBtnB:setTitleText(jsonObj["ans"][2])
        ansBtnC:setTitleText(jsonObj["ans"][3])
        ansBtnD:setTitleText(jsonObj["ans"][4])
        for k, v in ipairs(jsonObj["ans"]) do
            if v == ansStr then correctAns = k break end
        end
        self:showAnsPnl(ansPnlCH, ansPnlTF)
        self:setAnsBtnsEnabled(true, ansBtnA, ansBtnB, ansBtnC, ansBtnD)
    elseif jsonObj["qtype"] == "CL" then -- 聯想題
        qType = "聯想題"
        qText:setString("提示1: " .. jsonObj["ques"][1])
        qText2:setVisible(false)
        qText2:setString("提示2: " .. jsonObj["ques"][2])
        qText3:setVisible(false)
        qText3:setString("提示3: " .. jsonObj["ques"][3])
        local ansStr = jsonObj["ans"][1]
        math.shuffle(jsonObj["ans"])
        ansBtnA:setTitleText(jsonObj["ans"][1])
        ansBtnB:setTitleText(jsonObj["ans"][2])
        ansBtnC:setTitleText(jsonObj["ans"][3])
        ansBtnD:setTitleText(jsonObj["ans"][4])
        for k, v in ipairs(jsonObj["ans"]) do
            if v == ansStr then correctAns = k break end
        end
        self:showAnsPnl(ansPnlCH, ansPnlTF)
        self:setAnsBtnsEnabled(true, ansBtnA, ansBtnB, ansBtnC, ansBtnD)
        self:showClues(3)
    else qType = "" return end
    -- 題目領域
    if jsonObj["domain"] == "AL" then domain = "雜學"
    elseif jsonObj["domain"] == "SC" then domain = "理科"
    elseif jsonObj["domain"] == "LI" then domain = "文科"
    elseif jsonObj["domain"] == "NE" then domain = "時事"
    elseif jsonObj["domain"] == "AC" then domain = "ACG"
    elseif jsonObj["domain"] == "AR" then domain = "藝術"
    elseif jsonObj["domain"] == "SO" then domain = "社會"
    elseif jsonObj["domain"] == "SP" then domain = "運動"
    else domain = "" return end
    domainText:setString(qType .. " / " .. domain)
    -- 新題目出現的音效
    cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Question02-mp3/Quiz-Question02-1.mp3")
    -- 開始倒數
    self:startCountdown()
    -- 偵測是否落後
    isBehind = player.health < opponent.health
end

-- 聯想題顯示提示
function BattleScene:showClues(delay)
    local delayAct = cc.DelayTime:create(delay)
    local delayAct2 = cc.DelayTime:create(delay + delay)
    local showAct = cc.Show:create()
    local seq = cc.Sequence:create(delayAct, showAct)
    local seq2 = cc.Sequence:create(delayAct2, showAct)
    qText2:runAction(seq)
    qText3:runAction(seq2)
end

function BattleScene:showAnsPnl(showing, hiding)
    hiding:setVisible(false)
    showing:setVisible(true)
end
function BattleScene:setAnsBtnsEnabled(enabled, ...)
    if select('#', ...) > 0 then
        currentAnsBtns = { ... }
    end
    if #currentAnsBtns > 0 then
        -- print("# of btn = " .. #currentAnsBtns)
        for _, v in ipairs(currentAnsBtns) do
            v:setVisible(true):setEnabled(enabled)
        end
    end
    skillBtn:setEnabled(player.isSkillReady())
end
function BattleScene:shuffleAns(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

return BattleScene