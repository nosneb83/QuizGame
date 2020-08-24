local CharScene = class("CharScene", function()
    return cc.Scene:create()
end)

local rootNode

function CharScene:ctor()
    rootNode = cc.CSLoader:createNode("Char/CharScene.csb")
    self:addChild(rootNode)
    rootNode:getChildByName("Btn_return")
    :addTouchEventListener(self.mainPage)
end

-- 按鈕callbacks
function CharScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

return CharScene