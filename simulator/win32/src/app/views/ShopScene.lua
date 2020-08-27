local ShopScene = class("ShopScene", function()
    return cc.Scene:create()
end)

local rootNode
local nameText, premText, coinText, bmBtns

function ShopScene:ctor()
    rootNode = cc.CSLoader:createNode("Shop/ShopScene.csb")
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

    -- 購買按鈕
    rootNode:getChildByName("BuyCoin1"):addTouchEventListener(self.buyCoin)
    rootNode:getChildByName("BuyCoin2"):addTouchEventListener(self.buyCoin)
    rootNode:getChildByName("BuyBookmark1"):addTouchEventListener(self.buyBookmark)
    rootNode:getChildByName("BuyBookmark2"):addTouchEventListener(self.buyBookmark)
    
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
end

-- 按鈕callbacks
function ShopScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function ShopScene:buyCoin(type)
    if type == ccui.TouchEventType.ended then
        local coin = self:getTag() * 100
        local jsonObj = {
            op = "BUY_COIN",
            amount = coin
        }
        socket:send(json.encode(jsonObj))
    end
end
function ShopScene:buyBookmark(type)
    if type == ccui.TouchEventType.ended then
        local bmp = self:getTag()
        local jsonObj = {
            op = "BUY_BMP",
            amount = bmp
        }
        socket:send(json.encode(jsonObj))
    end
end

-- 更新UI
function ShopScene:updateUI()
    nameText:setString(player.name)
    premText:setString("+" .. tostring(math.min(999, player.bmp)))
    coinText:setString(string.comma_value(tostring(player.coin)))
    for i = 1, #bmBtns do
        bmBtns[i]:setEnabled(i <= player.bm)
    end
end

-- 處理server訊息
function ShopScene:handleOp(jsonObj)
    dump(jsonObj)
    local op = jsonObj["op"]
    if op == "UPDATE_COIN" then
        player.coin = jsonObj["coin"]
        self:updateUI()
    elseif op == "UPDATE_BMP" then
        if jsonObj["err"] == "COIN_NOT_ENOUGH" then
            print("錢不夠")
        else
            player.coin = jsonObj["coin"]
            player.bmp = jsonObj["bmp"]
            self:updateUI()
        end
    end
end

return ShopScene