local StorySectionScene = class("StorySectionScene", function()
    return cc.Scene:create()
end)

local rootNode
local currentChap -- 當前所在章節
local currentSect
local premText
local bmBtns = {}
local outOfBMPanel -- 書籤沒了panel

function StorySectionScene:ctor(chap)
    currentChap = chap
    dump(currentChap)
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
    self:updateUI()

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

    -- 書籤沒了panel
    outOfBMPanel = rootNode:getChildByName("OutOfBM")
    outOfBMPanel:getChildByName("Y")
    :addTouchEventListener(function() outOfBMPanel:setVisible(false) end)

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

-- 更新書籤UI
function StorySectionScene:updateUI()
    for i = 1, #bmBtns do
        bmBtns[i]:setEnabled(i <= player.bm)
    end
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
        -- 檢查有沒有讀到劇本
        print("len(storyFile) = " .. tostring(#storyFile))
        -- 段落編號
        currentSect = "0_1_" .. tostring(self:getTag())
        -- 叫server扣書籤
        local jsonObj = {
            op = "PAY_BOOKMARK",
            id = player.id,
            sect = currentSect
        }
        socket:send(json.encode(jsonObj))
    end
end

-- Handle Server Op
function StorySectionScene:handleOp(jsonObj)
    dump(jsonObj)
    local op = jsonObj["op"]
    if op == "PLAY_STORY" then
        player.bm = jsonObj["bm"]
        player.bmp = jsonObj["bmp"]
        self:updateUI()
        -- 進入劇情
        table.insert(currentChap, currentSect)
        local scene = require("app/views/StoryScene.lua"):create(currentChap)
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    elseif op == "OUT_OF_BOOKMARK" then
        -- 告訴玩家書籤沒了
        outOfBMPanel:setVisible(true)
    end
end

return StorySectionScene