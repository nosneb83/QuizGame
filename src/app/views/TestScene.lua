local TestScene = class("TestScene", function()
    return cc.Scene:create()
end)

socket = require("LuaTcpSocket"):new():init()
require("json")

local rootNode
local testBtn
local questionText
local correctAns
local ansPnlTF, ansPnlCH
local ansBtnO, ansBtnX, ansBtnA, ansBtnB, ansBtnC, ansBtnD
local feedbackT, feedbackF

function TestScene:ctor()
    rootNode = cc.CSLoader:createNode("TestScene.csb")
    self:addChild(rootNode)
    testBtn = rootNode:getChildByName("Button_1")
    testBtn:addTouchEventListener(self.testOnclick)
    questionText = rootNode:getChildByName("Question"):getChildByName("Text")

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

    feedbackT = rootNode:getChildByName("Answer_feedback"):getChildByName("Correct")
    feedbackF = rootNode:getChildByName("Answer_feedback"):getChildByName("Wrong")

    -- socket連線
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
    -- socket:connect("172.29.18.171", "8888")
    socket:connect("127.0.0.1", "8888")

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
local feedbackDuration = 1
function TestScene:answerO(type)
    if type == ccui.TouchEventType.ended then TestScene:answer("O") end
end
function TestScene:answerX(type)
    if type == ccui.TouchEventType.ended then TestScene:answer("X") end
end
function TestScene:answerA(type)
    if type == ccui.TouchEventType.ended then TestScene:answer("A") end
end
function TestScene:answerB(type)
    if type == ccui.TouchEventType.ended then TestScene:answer("B") end
end
function TestScene:answerC(type)
    if type == ccui.TouchEventType.ended then TestScene:answer("C") end
end
function TestScene:answerD(type)
    if type == ccui.TouchEventType.ended then TestScene:answer("D") end
end
function TestScene:answer(playerAns)
    if playerAns == correctAns then
        self:showFeedback(feedbackT, feedbackF)
    else
        self:showFeedback(feedbackF, feedbackT)
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
            questionText:setString(jsonObj["ques"][1])
            correctAns = jsonObj["ans"][1]
            self:showAnsPnl(ansPnlTF, ansPnlCH)
        elseif jsonObj["qtype"] == "CH" then -- 選擇題
            questionText:setString(jsonObj["ques"][1])
            ansBtnA:setTitleText(jsonObj["ans"][1])
            ansBtnB:setTitleText(jsonObj["ans"][2])
            ansBtnC:setTitleText(jsonObj["ans"][3])
            ansBtnD:setTitleText(jsonObj["ans"][4])
            correctAns = "A"
            self:showAnsPnl(ansPnlCH, ansPnlTF)
        elseif jsonObj["qtype"] == "CL" then -- 聯想題
            questionText:setString(jsonObj["ques"][1])
            ansBtnA:setTitleText(jsonObj["ans"][1])
            ansBtnB:setTitleText(jsonObj["ans"][2])
            ansBtnC:setTitleText(jsonObj["ans"][3])
            ansBtnD:setTitleText(jsonObj["ans"][4])
            correctAns = "A"
            self:showAnsPnl(ansPnlCH, ansPnlTF)
        end
    end
end
function TestScene:showAnsPnl(showing, hiding)
    hiding:setVisible(false)
    showing:setVisible(true)
end

return TestScene