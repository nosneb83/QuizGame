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

return MainScene