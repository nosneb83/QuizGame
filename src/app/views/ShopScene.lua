local ShopScene = class("ShopScene", function()
    return cc.Scene:create()
end)

local rootNode

function ShopScene:ctor()
    rootNode = cc.CSLoader:createNode("Shop/ShopScene.csb")
    self:addChild(rootNode)
    rootNode:getChildByName("Btn_return")
    :addTouchEventListener(self.mainPage)
end

-- 按鈕callbacks
function ShopScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

return ShopScene