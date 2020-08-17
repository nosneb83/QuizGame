local LoginScene = class("LoginScene", cc.load("mvc").ViewBase)

LoginScene.RESOURCE_FILENAME = "Login/LoginScene.csb"

socket = require("LuaTcpSocket"):new():init()

local rootNode
local acInput, pwInput
local promptPanel, promptText
local regPanel, regYesBtn, regNoBtn
local regDupPanel, regDupBtn

function LoginScene:onCreate()
    rootNode = self:getResourceNode()
    dump(cc.p(rootNode:getPosition()))
    local startBtn = rootNode:getChildByName("StartBtn")
    startBtn:addTouchEventListener(self.login)

    acInput = rootNode:getChildByName("Input"):getChildByName("UserIDInput")
    pwInput = rootNode:getChildByName("Input"):getChildByName("PasswordInput")

    promptPanel = rootNode:getChildByName("Prompt")
    promptText = promptPanel:getChildByName("Text")
    promptPanel:getChildByName("Y"):addTouchEventListener(function()
        promptPanel:setVisible(false)
    end)

    regPanel = rootNode:getChildByName("Confirm")
    regYesBtn = regPanel:getChildByName("Y")
    regYesBtn:addTouchEventListener(self.register)
    regNoBtn = regPanel:getChildByName("N")
    regNoBtn:addTouchEventListener(function()
        regPanel:setVisible(false)
    end)

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
    -- socket:connect("172.29.18.171", "8888")
    socket:connect("127.0.0.1", "8888")
end

function LoginScene:login(type)
    if type == ccui.TouchEventType.ended then
        local jsonObj = {
            op = "LOGIN",
            ac = acInput:getString(),
            pw = pwInput:getString()
        }
        socket:send(json.encode(jsonObj))
    end
end

function LoginScene:register(type)
    if type == ccui.TouchEventType.ended then
        local jsonObj = {
            op = "REGISTER",
            ac = acInput:getString(),
            pw = pwInput:getString()
        }
        socket:send(json.encode(jsonObj))
        regPanel:setVisible(false)
    end
end

function LoginScene:handleOp(jsonObj)
    dump(jsonObj)
    local op = jsonObj["op"]
    if op == "LOGIN_SUCCESS" then
        -- 進入主畫面
        local scene = require("app/views/MainScene.lua"):create(jsonObj["id"])
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(1, scene))
    elseif op == "WRONG_PW" then
        promptPanel:setVisible(true)
    elseif op == "ACCOUNT_NOT_FOUND" then
        regPanel:setVisible(true)
    end
end

-- 自己實作字串分割 (相當於Golang的strings.SplitAfter)
function string.splitAfter(s, sep)
    local tab = {}
    while true do
        local n = string.find(s, sep)
        if n then
            local first = string.sub(s, 1, n)
            s = string.sub(s, n + 1, #s)
            table.insert(tab, first)
        else
            table.insert(tab, s)
            break
        end
    end
    return tab
end

-- Fisher-Yates shuffle
function math.shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

return LoginScene