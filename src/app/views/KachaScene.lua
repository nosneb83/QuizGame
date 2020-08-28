local KachaScene = class("KachaScene", function()
    return cc.Scene:create()
end)

local rootNode
local nameText, premText, coinText, bmBtns

function KachaScene:ctor()
    rootNode = cc.CSLoader:createNode("Shop/KachaScene.csb")
    self:addChild(rootNode)
    rootNode:getChildByName("Btn_return")
    :addTouchEventListener(self.mainPage)

    -- 玩家狀態列
    local statusBar = rootNode:getChildByName("StatusBar")
    nameText = statusBar:getChildByName("NameText")
    premText = statusBar:getChildByName("PremText")
    coinText = statusBar:getChildByName("CoinText")
    bmBtns = {
        statusBar:getChildByName("Bookmark1"),
        statusBar:getChildByName("Bookmark2"),
        statusBar:getChildByName("Bookmark3"),
        statusBar:getChildByName("Bookmark4"),
        statusBar:getChildByName("Bookmark5")
    }
    self:updateUI()
end

-- 按鈕callbacks
function KachaScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

-- 更新UI
function KachaScene:updateUI()
    nameText:setString(player.name)
    premText:setString("+" .. tostring(math.min(999, player.bmp)))
    coinText:setString(string.comma_value(tostring(player.coin)))
    for i = 1, #bmBtns do
        bmBtns[i]:setEnabled(i <= player.bm)
    end
end

return KachaScene