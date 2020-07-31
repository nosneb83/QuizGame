local MainScene = class("MainScene", cc.load("mvc").ViewBase)

MainScene.RESOURCE_FILENAME = "MainScene.csb"

local rootNode

function MainScene:onCreate()
    -- printf("resource node = %s", tostring(self:getResourceNode()))
    --[[ you can create scene with following comment code instead of using csb file.
    -- add background image
    display.newSprite("HelloWorld.png")
        :move(display.center)
        :addTo(self)

    -- add HelloWorld label
    cc.Label:createWithSystemFont("Hello World", "Arial", 40)
        :move(display.cx, display.cy + 200)
        :addTo(self)
    ]]
    rootNode = self:getResourceNode()
    local startBtn = rootNode:getChildByName("StartBtn")
    startBtn:addTouchEventListener(self.enterTestScene)
end

function MainScene:enterTestScene(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/TestScene.lua"):create()
        -- 淡入過場
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(1, scene))
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

return MainScene