local StorySectionScene = class("StorySectionScene", function()
    return cc.Scene:create()
end)

local rootNode
local currentStory -- 目前所在劇情
local currentChap -- 目前所在章節
local premText
local bmBtns = {}

function StorySectionScene:ctor(story, chapter)
    currentStory = story
    currentChap = chapter
    rootNode = cc.CSLoader:createNode("Story/ChooseSection/" .. currentChap .. ".csb")
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
        local scene = require("app/views/StoryMenuScene.lua"):create("MainStory")
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

return StorySectionScene