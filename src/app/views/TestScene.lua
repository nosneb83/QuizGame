local TestScene = class("TestScene", function()
    return cc.Scene:create()
end)

socket = require("LuaTcpSocket"):new():init()
require("json")

local rootNode
local testBtn
local questionText
local answer
local answerBtnT, answerBtnF

function TestScene:ctor()
    rootNode = cc.CSLoader:createNode("TestScene.csb")
    self:addChild(rootNode)
    testBtn = rootNode:getChildByName("Button_1")
    testBtn:addTouchEventListener(self.testOnclick)
    questionText = rootNode:getChildByName("Question"):getChildByName("Text")

    answerBtnT = rootNode:getChildByName("Answer_TF"):getChildByName("T"):getChildByName("Button")
    answerBtnT:addTouchEventListener(self.answerT)
    answerBtnF = rootNode:getChildByName("Answer_TF"):getChildByName("F"):getChildByName("Button")
    answerBtnF:addTouchEventListener(self.answerF)

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
    socket:connect("172.29.18.171", "8888")

    self:scheduleUpdateWithPriorityLua(function(dt) self:update(dt) end, 0)
end

function TestScene:testOnclick(type)
    if type == ccui.TouchEventType.ended then
        print("client ready")
        local jsonObj = {
            op = "CLIENT_READY"
        }
        socket:send(json.encode(jsonObj))
    end
end

function TestScene:answerT(type)
    if type == ccui.TouchEventType.ended then
        if answer then
            print("Correct Answer !!")
        else
            print("Wrong Answer !!")
        end
    end
end

function TestScene:answerF(type)
    if type == ccui.TouchEventType.ended then
        if answer then
            print("Wrong Answer !!")
        else
            print("Correct Answer !!")
        end
    end
end

-- Game Loop
function TestScene:update(dt)

end

-- Handle Server Op
function TestScene:handleOp(jsonObj)
    -- dump(jsonObj)
    -- 處理指令
    local op = jsonObj["op"]
    if op == "SEND_QUESTION" then
        questionText:setString(jsonObj["question"])
        answer = jsonObj["answer"]
    end
    -- if op == "ASSIGN_ID" then
    --     playerID = jsonObj["playerID"]
    --     print("set id = " .. playerID)
    -- elseif op == "CREATE_PLAYER" then
    --     local item = readyListItemPrefab:clone()
    --     item:getChildByName("PlayerName"):setString(jsonObj["playerName"])
    --     self:addSpriteAnim(item, jsonObj["heroType"], cc.p(40, 40), 1)
    --     readyList:pushBackCustomItem(item)
    -- elseif op == "BATTLE_START" then
    --     -- print("into battle !!")
    --     self:countDown()
    --     -- local scene = require("app/views/BattleScene.lua"):create()
    --     -- cc.Director:getInstance():replaceScene(scene)
    -- end
end

return TestScene