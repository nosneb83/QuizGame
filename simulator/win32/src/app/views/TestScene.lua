local TestScene = class("TestScene", function()
    return cc.Scene:create()
end)

require("json")

local rootNode
local testBtn
local qText, qText2, qText3
local correctAns
local ansPnlTF, ansPnlCH
local ansBtnO, ansBtnX, ansBtnA, ansBtnB, ansBtnC, ansBtnD
local ansBtns = {}
local feedbackT, feedbackF
local sfxQues, sfxCorrect, sfxWrong

function TestScene:ctor()
    rootNode = cc.CSLoader:createNode("TestScene.csb")
    self:addChild(rootNode)
    testBtn = rootNode:getChildByName("Button_1")
    testBtn:addTouchEventListener(self.testOnclick)
    qText = rootNode:getChildByName("Question"):getChildByName("Text")
    qText2 = rootNode:getChildByName("Question"):getChildByName("Text2")
    qText3 = rootNode:getChildByName("Question"):getChildByName("Text3")

    ansPnlTF = rootNode:getChildByName("Answer_TF")
    ansBtnO = rootNode:getChildByName("Answer_TF"):getChildByName("O"):getChildByName("Button")
    ansBtnO:addTouchEventListener(self.answerO)
    ansBtnX = rootNode:getChildByName("Answer_TF"):getChildByName("X"):getChildByName("Button")
    ansBtnX:addTouchEventListener(self.answerX)

    ansPnlCH = rootNode:getChildByName("Answer_CH")
    ansBtnA = rootNode:getChildByName("Answer_CH"):getChildByName("A"):getChildByName("Button")
    ansBtnA:addTouchEventListener(self.answerA)
    ansBtnB = rootNode:getChildByName("Answer_CH"):getChildByName("B"):getChildByName("Button")
    ansBtnB:addTouchEventListener(self.answerB)
    ansBtnC = rootNode:getChildByName("Answer_CH"):getChildByName("C"):getChildByName("Button")
    ansBtnC:addTouchEventListener(self.answerC)
    ansBtnD = rootNode:getChildByName("Answer_CH"):getChildByName("D"):getChildByName("Button")
    ansBtnD:addTouchEventListener(self.answerD)
    ansBtns = { ansBtnA, ansBtnB, ansBtnC, ansBtnD }

    feedbackT = rootNode:getChildByName("Answer_feedback"):getChildByName("Correct")
    feedbackF = rootNode:getChildByName("Answer_feedback"):getChildByName("Wrong")

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

    -- Random Seed
    math.randomseed(os.time())

    self:scheduleUpdateWithPriorityLua(function(dt) self:update(dt) end, 0)
end

function TestScene:testOnclick(type)
    if type == ccui.TouchEventType.ended then
        TestScene:nextQuestion()
    end
end

-- 下一題
function TestScene:nextQuestion()
    print("client ready")
    local jsonObj = {
        op = "CLIENT_READY"
    }
    socket:send(json.encode(jsonObj))
end

-- 答題回饋
local feedbackDuration = 2
function TestScene:answerO(type)
    if type == ccui.TouchEventType.ended then TestScene:answer(1) end
end
function TestScene:answerX(type)
    if type == ccui.TouchEventType.ended then TestScene:answer(2) end
end
function TestScene:answerA(type)
    if type == ccui.TouchEventType.ended then TestScene:answer(1) end
end
function TestScene:answerB(type)
    if type == ccui.TouchEventType.ended then TestScene:answer(2) end
end
function TestScene:answerC(type)
    if type == ccui.TouchEventType.ended then TestScene:answer(3) end
end
function TestScene:answerD(type)
    if type == ccui.TouchEventType.ended then TestScene:answer(4) end
end
function TestScene:answer(playerAns)
    if playerAns == correctAns then
        self:showFeedback(feedbackT, feedbackF)
        cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Buzzer01-mp3/Quiz-Buzzer01-1.mp3")
    else
        self:showFeedback(feedbackF, feedbackT)
        cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Wrong_Buzzer01-mp3/Quiz-Wrong_Buzzer01-1.mp3")
    end
    rootNode:runAction(cc.Sequence:create(cc.DelayTime:create(feedbackDuration), cc.CallFunc:create(self.nextQuestion)))
end
function TestScene:showFeedback(showing, hiding)
    hiding:stopAllActions()
    hiding:runAction(cc.Hide:create())
    showing:stopAllActions()
    showing:runAction(cc.Sequence:create(cc.Show:create(), cc.DelayTime:create(feedbackDuration), cc.Hide:create()))
end

-- Game Loop
function TestScene:update(dt)

end

-- Handle Server Op
function TestScene:handleOp(jsonObj)
    dump(jsonObj)
    -- 處理指令
    local op = jsonObj["op"]
    if op == "SEND_QUESTION" then
        if jsonObj["qtype"] == "TF" then -- 是非題
            qText:setString(jsonObj["ques"][1])
            qText2:setString("")
            qText3:setString("")
            if jsonObj["ans"][1] == "O" then
                correctAns = 1
            else
                correctAns = 2
            end
            self:showAnsPnl(ansPnlTF, ansPnlCH)
        elseif jsonObj["qtype"] == "CH" then -- 選擇題
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
        elseif jsonObj["qtype"] == "CL" then -- 聯想題
            qText:setString("提示1: " .. jsonObj["ques"][1])
            qText2:setVisible(false)
            qText2:setString("提示2: " .. jsonObj["ques"][2])
            qText3:setVisible(false)
            qText3:setString("提示3: " .. jsonObj["ques"][3])
            ansBtnA:setTitleText(jsonObj["ans"][1])
            ansBtnB:setTitleText(jsonObj["ans"][2])
            ansBtnC:setTitleText(jsonObj["ans"][3])
            ansBtnD:setTitleText(jsonObj["ans"][4])
            correctAns = "A"
            self:showAnsPnl(ansPnlCH, ansPnlTF)
            self:showClues(3)
        else
            return
        end
        -- 新題目出現的音效
        cc.SimpleAudioEngine:getInstance():playEffect("SFX/Quiz-Question02-mp3/Quiz-Question02-1.mp3")
    end
end
function TestScene:showClues(delay)
    local delayAct = cc.DelayTime:create(delay)
    local delayAct2 = cc.DelayTime:create(delay + delay)
    local showAct = cc.Show:create()
    local seq = cc.Sequence:create(delayAct, showAct)
    local seq2 = cc.Sequence:create(delayAct2, showAct)
    qText2:runAction(seq)
    qText3:runAction(seq2)
end
function TestScene:showAnsPnl(showing, hiding)
    hiding:setVisible(false)
    showing:setVisible(true)
end
function TestScene:shuffleAns(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

return TestScene