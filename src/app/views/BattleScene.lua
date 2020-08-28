local BattleScene = class("BattleScene", function()
    return cc.Scene:create()
end)

require("json")
local opponent = require("player.lua"):new()
local utf8 = require('utf8_simple')

local rootNode
local quesLayout, ansLayout -- layout
local playerIcon, opponentIcon -- 雙方頭像
local playerO, playerX, opponentO, opponentX -- 雙方頭像OX
local domainText -- 題目類型&領域
local qText, qText2, qText3 -- 題目文字
local correctAns, correctAnsStr -- 當前題目的正確答案, 答案string
local ansPnlTF, ansPnlCH -- 選項panel
local ansBtnO, ansBtnX, ansBtnA, ansBtnB, ansBtnC, ansBtnD -- 選項按鈕
local selects = {} -- 選項選擇框
local currentAnsBtns = {} -- 當前這一題的選項按鈕們
local feedbackT, feedbackF -- 答對答錯文字
local sfxQues, sfxCorrect, sfxWrong -- 答題音效
local enterCountdownText -- 開場倒數文字
local countdownText, timeBar -- 倒數文字
local countdownNum -- 倒數秒數
local countdownSpd = 1 -- 倒數速度
local playerHealthBar, opponentHealthBar, healthRec -- 血條
local isWaiting = false -- 是否正在等待另一名玩家
local skillBtn, skillBtnMask -- 開技能的按鈕, 遮罩
-- local skillMark -- 技能CD標示
local isBehind = false -- 玩家是否正在落後
local vicLayer, defLayer -- 勝負結算畫面
local waitLayer -- 等待畫面
local dmgSpd, easeAmount = 1.2, 3 -- 扣血動畫速度, 平滑度

-- 技能相關 --
local freezeTime = 0
local freezeImg
-------------
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

    -- 選項選擇框
    selects = {
        ansBtnO:getChildByName("Selected"),
        ansBtnX:getChildByName("Selected"),
        ansBtnA:getChildByName("Selected"),
        ansBtnB:getChildByName("Selected"),
        ansBtnC:getChildByName("Selected"),
        ansBtnD:getChildByName("Selected")
    }

    enterCountdownText = rootNode:getChildByName("StartCountdown")
    -- countdownText = ansLayout:getChildByName("Countdown")
    countdownText = quesLayout:getChildByName("TimeText")
    timeBar = quesLayout:getChildByName("TimeBar")
    skillBtn = ansLayout:getChildByName("SkillButton")
    skillBtn:setZoomScale(-0.1)
    skillBtn:setPressedActionEnabled(true)
    skillBtn:addTouchEventListener(self.skillOnClick)
    -- skillMark = rootNode:getChildByName("SkillCooldownMark")
    skillBtnMask = ansLayout:getChildByName("SkillBtnMask")
    ansLayout:setVisible(false) -- 隱藏答案layout

    -- 血條
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
    waitLayer = cc.CSLoader:createNode("Battle/WaitingRoom/WaitingLayer.csb")
    rootNode:addChild(waitLayer)
    waitLayer:getChildByName("Bg"):runAction(cc.RepeatForever:create(cc.RotateBy:create(40, 360)))

    -- 雙方頭像
    local staticPanel = rootNode:getChildByName("StaticPanel")
    playerIcon = {
        staticPanel:getChildByName("PlayerIcon"):getChildByName("Teko"),
        staticPanel:getChildByName("PlayerIcon"):getChildByName("Same"),
        staticPanel:getChildByName("PlayerIcon"):getChildByName("Luluta")
    }
    opponentIcon = {
        staticPanel:getChildByName("OpponentIcon"):getChildByName("Teko"),
        staticPanel:getChildByName("OpponentIcon"):getChildByName("Same"),
        staticPanel:getChildByName("OpponentIcon"):getChildByName("Luluta")
    }

    -- 頭像答對答錯OX
    playerO = staticPanel:getChildByName("PlayerO")
    playerX = staticPanel:getChildByName("PlayerX")
    opponentO = staticPanel:getChildByName("OpponentO")
    opponentX = staticPanel:getChildByName("OpponentX")

    -- 設定技能按鈕圖片
    self:setSkillBtnTexture(true)

    -- 凍結框
    freezeImg = rootNode:getChildByName("Freeze")

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
    if type == ccui.TouchEventType.ended then
        selects[1]:setVisible(true)
        BattleScene:answer(1)
    end
end
function BattleScene:answerX(type)
    if type == ccui.TouchEventType.ended then
        selects[2]:setVisible(true)
        BattleScene:answer(2)
    end
end
function BattleScene:answerA(type)
    if type == ccui.TouchEventType.ended then
        selects[3]:setVisible(true)
        BattleScene:answer(1)
    end
end
function BattleScene:answerB(type)
    if type == ccui.TouchEventType.ended then
        selects[4]:setVisible(true)
        BattleScene:answer(2)
    end
end
function BattleScene:answerC(type)
    if type == ccui.TouchEventType.ended then
        selects[5]:setVisible(true)
        BattleScene:answer(3)
    end
end
function BattleScene:answerD(type)
    if type == ccui.TouchEventType.ended then
        selects[6]:setVisible(true)
        BattleScene:answer(4)
    end
end
function BattleScene:answer(playerAns)
    self:setAnsBtnsEnabled(false)
    local timeUsed = self:stopCountdown()
    -- if playerAns == correctAns then
    --     self:showFeedback(feedbackT, feedbackF)
    --     cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Buzzer01-mp3/Quiz-Buzzer01-1.mp3")
    -- else
    --     self:showFeedback(feedbackF, feedbackT)
    --     cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Wrong_Buzzer01-mp3/Quiz-Wrong_Buzzer01-1.mp3")
    -- end
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

-- 顯示頭像OX
function BattleScene:showOX(id, cor)
    if id == player.id then
        if cor then
            playerO:setVisible(true)
            cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Buzzer01-mp3/Quiz-Buzzer01-1.mp3")
        else
            playerX:setVisible(true)
            cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Wrong_Buzzer01-mp3/Quiz-Wrong_Buzzer01-1.mp3")
        end
    else
        if cor then opponentO:setVisible(true)
        else opponentX:setVisible(true) end
    end
end
function BattleScene:hideOX()
    playerO:setVisible(false)
    playerX:setVisible(false)
    opponentO:setVisible(false)
    opponentX:setVisible(false)
end

-- 進房倒數
function BattleScene:countDown(jsonObj)
    waitLayer:setVisible(false)

    -- 血量初始化
    player.health = 60
    player.tempHealth = 60
    opponent.health = 60

    -- 技能初始化
    player.skillGauge = 0

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
        -- self:setSkillCDMarkPos()
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
-- function BattleScene:setSkillCDMarkPos()
-- if player.tempHealth == nil then
--     player.skillReadyTime = player.health - player.skillCD
-- else
--     player.skillReadyTime = math.min(player.health, player.tempHealth) - player.skillCD
-- end
-- if player.skillReadyTime < 0 then
--     skillMark:setVisible(false)
--     return
-- end
-- local skillMarkX = healthRec.x + healthRec.width
-- local skillMarkY = healthRec.y + healthRec.height * player.skillReadyTime / 60
-- skillMark:setVisible(true):setPosition(skillMarkX, skillMarkY)
-- end
-- 答題倒數
function BattleScene:startCountdown()
    countdownNum = 10
    countdownText:setString(string.format("%.2f", countdownNum))
    timeBar:setScaleX(1)
    rootNode:resume()
end
function BattleScene:countdownUpdate(dt)
    if countdownNum == nil then return end
    countdownNum = math.max(0, countdownNum - dt * countdownSpd)
    -- 倒數數字
    countdownText:setString(string.format("%.2f", countdownNum))
    timeBar:setScaleX(math.max(0, countdownNum / 10))
    -- -- 血條隨時間慢慢遞減
    -- player.tempHealth = math.max(0, player.health - 10 + countdownNum)
    -- playerHealthBar:setScaleY(player.tempHealth / 60)
    -- skillBtn:setEnabled(player:isSkillReady())
    -- -- 血量歸零直接gameover
    -- if player.tempHealth == 0 then
    --     self:surrender()
    --     return
    -- end
    -- 凍結技能判斷
    if freezeTime > 0 then
        freezeTime = freezeTime - dt
        if freezeTime <= 0 then self:setFreeze(false) end
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
    timeBar:setScaleX(0)
    rootNode:pause()
    return timeUsed
end

-- 開技能
function BattleScene:skillOnClick(type)
    if type == ccui.TouchEventType.ended then
        -- reset技能按鈕
        player.skillGauge = 0
        BattleScene:setSkillBtnGauge(0)
        BattleScene:setSkillBtnEnabled(false)

        if player.char == 1 then
            -------------------------
            -- 技能: 二選一/秒答
            -------------------------
            -- 落後秒答
            if isBehind then
                if correctAnsStr == "O" then BattleScene:answerO(2)
                elseif correctAnsStr == "X" then BattleScene:answerX(2)
                elseif correctAnsStr == "1" then BattleScene:answerA(2)
                elseif correctAnsStr == "2" then BattleScene:answerB(2)
                elseif correctAnsStr == "3" then BattleScene:answerC(2)
                elseif correctAnsStr == "4" then BattleScene:answerD(2)
                end
            end
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

        elseif player.char == 2 then
            -------------------------
            -- 技能: 對方題目打亂
            -------------------------
            local jsonObj = {
                op = "SKILL_SHUFFLE",
                selfID = player.id
            }
            socket:send(json.encode(jsonObj))

        elseif player.char == 3 then
            -------------------------
            -- 技能: 倒數緩速/凍結
            -------------------------
            BattleScene:setFreeze(true)
        end
    end
end
function BattleScene:setFreeze(freeze)
    if freeze then
        freezeTime = 4
        freezeImg:setVisible(true) -- 顯示冰框
        timeBar:setColor(cc.c3b(152, 217, 254)) -- 時間條藍色
        if isBehind then countdownSpd = 0
        else countdownSpd = 0.33 end
    else
        freezeImg:setVisible(false) -- 隱藏冰框
        timeBar:setColor(cc.c3b(255, 241, 0)) -- 時間條黃色
        countdownSpd = 1
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
    -- 處理指令
    local op = jsonObj["op"]
    if op == "SEND_QUESTION" then -- 出題
        if isWaiting then
            print("is waiting")
            self:countDown(jsonObj)
            isWaiting = false
        else
            print("not waiting")
            self:showQuestion(jsonObj)
        end
    elseif op == "BATTLE_INIT" then -- 設定雙方資訊
        local staticPanel = rootNode:getChildByName("StaticPanel")
        if jsonObj["id"] == player.id then
            staticPanel:getChildByName("PlayerName"):setString(jsonObj["name"])
            for k, v in ipairs(playerIcon) do
                v:setVisible(k == jsonObj["char"])
            end
        else
            staticPanel:getChildByName("OpponentName"):setString(jsonObj["name"])
            for k, v in ipairs(opponentIcon) do
                v:setVisible(k == jsonObj["char"])
            end
        end
    elseif op == "BATTLE_RESULT" then -- 演出雙方扣血
        dump(jsonObj)
        self:showOX(jsonObj["id"], jsonObj["cor"])
        if jsonObj["id"] == player.id then
            local dmg = player.health - jsonObj["health"]
            player.health = jsonObj["health"]
            local s = cc.ScaleTo:create(dmgSpd, 1, player.health / 60)
            local e = cc.EaseInOut:create(s, easeAmount)
            playerHealthBar:runAction(e)
            -- 累積技能能量
            player.skillGauge = player.skillGauge + dmg
            self:setSkillBtnGauge()
        else
            opponent.health = jsonObj["health"]
            local s = cc.ScaleTo:create(dmgSpd, 1, opponent.health / 60)
            local e = cc.EaseInOut:create(s, easeAmount)
            opponentHealthBar:runAction(e)
        end
    elseif op == "BATTLE_OVER" then -- 演出勝負
        dump(jsonObj)
        self:gameover(jsonObj["win"])
    end
end

-- 顯示題目和選項
function BattleScene:showQuestion(jsonObj)
    -- 隱藏選項框
    for _, v in ipairs(selects) do
        v:setVisible(false)
    end
    -- 偵測是否落後
    isBehind = player.health < opponent.health
    -- 技能: 打亂題目
    if jsonObj["shuffle"] then
        jsonObj["ques"][1] = self:shuffleStr(jsonObj["ques"][1])
        jsonObj["ques"][2] = self:shuffleStr(jsonObj["ques"][2])
        jsonObj["ques"][3] = self:shuffleStr(jsonObj["ques"][3])
        if isBehind then
            jsonObj["ans"][1] = self:shuffleStr(jsonObj["ans"][1])
            jsonObj["ans"][2] = self:shuffleStr(jsonObj["ans"][2])
            jsonObj["ans"][3] = self:shuffleStr(jsonObj["ans"][3])
            jsonObj["ans"][4] = self:shuffleStr(jsonObj["ans"][4])
        end
    end
    -- 題型
    local qType, domain
    if jsonObj["qtype"] == "TF" then -- 是非題
        qType = "是非題"
        qText:setString(jsonObj["ques"][1])
        qText2:setString("")
        qText3:setString("")
        if jsonObj["ans"][1] == "O" then
            correctAns = 1
            correctAnsStr = "O"
        else
            correctAns = 2
            correctAnsStr = "X"
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
            if v == ansStr then
                correctAns = k
                correctAnsStr = tostring(k)
                break
            end
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
            if v == ansStr then
                correctAns = k
                correctAnsStr = tostring(k)
                break
            end
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
    -- 隱藏頭像OX
    self:hideOX()
    -- 開始倒數
    self:startCountdown()
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

-- 切換顯示選擇題與是非題選項
function BattleScene:showAnsPnl(showing, hiding)
    hiding:setVisible(false)
    showing:setVisible(true)
end

-- 選項按鈕切換可按/不可按
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
    -- 是否能使用技能
    self:setSkillBtnEnabled(enabled)
end

-- 設定技能按鈕圖片
function BattleScene:setSkillBtnTexture(isInit)
    if isBehind then
        if player.char == 1 then
            skillBtn:loadTextureNormal("Battle/Skill/Cir_Red.png")
        elseif player.char == 2 then
            skillBtn:loadTextureNormal("Battle/Skill/Confuse_Red.png")
        elseif player.char == 3 then
            skillBtn:loadTextureNormal("Battle/Skill/Stop_Red.png")
        end
    else
        if player.char == 1 then
            skillBtn:loadTextureNormal("Battle/Skill/Cir_Orange.png")
        elseif player.char == 2 then
            skillBtn:loadTextureNormal("Battle/Skill/Confuse_Orange.png")
        elseif player.char == 3 then
            skillBtn:loadTextureNormal("Battle/Skill/Stop_Orange.png")
        end
    end
    if isInit == false then return end
    if player.char == 1 then
        skillBtn:loadTexturePressed("Battle/Skill/Cir_Orange_2.png")
        skillBtn:loadTextureDisabled("Battle/Skill/Cir_Orange_2.png")
    elseif player.char == 2 then
        skillBtn:loadTexturePressed("Battle/Skill/Confuse_Orange_2.png")
        skillBtn:loadTextureDisabled("Battle/Skill/Confuse_Orange_2.png")
    elseif player.char == 3 then
        skillBtn:loadTexturePressed("Battle/Skill/Stop_Orange_2.png")
        skillBtn:loadTextureDisabled("Battle/Skill/Stop_Orange_2.png")
    end
end

-- 設定技能按鈕狀態
function BattleScene:setSkillBtnGauge(time) -- 設定遮罩
    if time == nil then time = dmgSpd end
    local s = cc.ScaleTo:create(time, 1, 1 - math.min(1, player.skillGauge / player.skillCD))
    local e = cc.EaseInOut:create(s, easeAmount)
    skillBtnMask:runAction(e)
end
function BattleScene:setSkillBtnEnabled(enabled) -- 設定可不可用
    if enabled == false then skillBtn:setEnabled(false) return end
    if player.skillGauge >= player.skillCD then
        -- if isBehind then -- 落後時按鈕為紅色
        --     skillBtn:loadTextureNormal("Battle/Skill/Cir_red.png")
        -- else
        --     skillBtn:loadTextureNormal("Battle/Skill/Cir_Orange.png")
        -- end
        self:setSkillBtnTexture(false)
        skillBtn:setEnabled(true)
    else
        skillBtn:setEnabled(false)
    end
end

-- 打亂選項
function BattleScene:shuffleAns(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

-- 打亂字串
function BattleScene:shuffleStr(str)
    if str == nil then return "" end
    local letters = {}
    for i, letter, b in utf8.chars(str) do
        table.insert(letters, { letter = letter, rnd = math.random() })
    end
    table.sort(letters, function(a, b) return a.rnd < b.rnd end)
    for i, v in ipairs(letters) do letters[i] = v.letter end
    return table.concat(letters)
end

return BattleScene