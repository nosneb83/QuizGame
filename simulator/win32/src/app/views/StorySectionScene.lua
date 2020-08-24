local StorySectionScene = class("StorySectionScene", function()
    return cc.Scene:create()
end)

local rootNode
local currentChap -- 當前所在章節
local premText
local bmBtns = {}

function StorySectionScene:ctor(chap)
    currentChap = chap
    rootNode = cc.CSLoader:createNode("Story/ChooseSection/" .. currentChap[2] .. ".csb")
    self:addChild(rootNode)
    rootNode:getChildByName("Btn_return")
    :addTouchEventListener(self.backToStory)
    rootNode:getChildByName("Btn_home")
    :addTouchEventListener(self.mainPage)

    -- 狀態列
    local bmBar = rootNode:getChildByName("BookmarkBar")
    premText = bmBar:getChildByName("PremText")
    premText:setString("+" .. tostring(math.min(999, player.bmp)))
    bmBtns = {
        bmBar:getChildByName("Bookmark1"),
        bmBar:getChildByName("Bookmark2"),
        bmBar:getChildByName("Bookmark3"),
        bmBar:getChildByName("Bookmark4"),
        bmBar:getChildByName("Bookmark5")
    }
    for i = 1, #bmBtns do
        bmBtns[i]:setEnabled(i <= player.bm)
    end

    -- 段落按鈕
    rootNode:getChildByName("SectionBtns"):getChildByName("Btn_Sect1")
    :addTouchEventListener(self.sect)
    rootNode:getChildByName("SectionBtns"):getChildByName("Btn_Sect2")
    :addTouchEventListener(self.sect)
    rootNode:getChildByName("SectionBtns"):getChildByName("Btn_Sect3")
    :addTouchEventListener(self.sect)
    rootNode:getChildByName("SectionBtns"):getChildByName("Btn_Sect4")
    :addTouchEventListener(self.sect)
    rootNode:getChildByName("SectionBtns"):getChildByName("Btn_Sect5")
    :addTouchEventListener(self.sect)

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
function StorySectionScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function StorySectionScene:backToStory(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/StoryMenuScene.lua"):create(currentChap[1])
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function StorySectionScene:sect(type)
    if type == ccui.TouchEventType.ended then
        if player.bm == 0 then return end
        -- 叫server扣書籤
        local jsonObj = {
            op = "PAY_BOOKMARK",
            id = player.id
        }
        socket:send(json.encode(jsonObj))
        player.bm = player.bm - 1
        -- 進入劇情
        local sectStr = "0_1_" .. tostring(self:getTag())
        table.insert(currentChap, sectStr) -- 段落6
        local scene = require("app/views/StoryScene.lua"):create(currentChap)
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

-- Handle Server Op
function StorySectionScene:handleOp(jsonObj)
    dump(jsonObj)
end

return StorySectionScene