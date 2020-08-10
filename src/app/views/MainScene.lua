local MainScene = class("MainScene", function()
    return cc.Scene:create()
end)

require("json")

local rootNode

function MainScene:ctor()
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
    rootNode = cc.CSLoader:createNode("MainScene.csb")
    self:addChild(rootNode)
    
    local btn_pvp = rootNode:getChildByName("Btn_Pvp")
    btn_pvp:addTouchEventListener(self.enterTestScene)
end

function MainScene:enterTestScene(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/TestScene.lua"):create()
        -- 淡入過場
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(1, scene))
    end
end

return MainScene