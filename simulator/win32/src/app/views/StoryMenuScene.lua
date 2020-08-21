local StoryMenuScene = class("StoryMenuScene", function()
    return cc.Scene:create()
end)

local rootNode
local returnBtn, homeBtn -- 返回前頁按鈕
local currentLayer, menuLayer, mainStoryLayer -- 選單layer
local mainStoryBtn -- 選擇劇情按鈕
local chap0Btn -- 選擇章節按鈕

function StoryMenuScene:ctor(layer)
    rootNode = cc.CSLoader:createNode("Story/Menu/StoryMenuScene.csb")
    self:addChild(rootNode)
    returnBtn = rootNode:getChildByName("Btn_return")
    homeBtn = rootNode:getChildByName("Btn_home")
    homeBtn:addTouchEventListener(self.mainPage)

    menuLayer = cc.CSLoader:createNode("Story/Menu/MenuLayer.csb")
    rootNode:addChild(menuLayer)
    mainStoryBtn = menuLayer:getChildByName("Btn_MainStory")
    mainStoryBtn:addTouchEventListener(self.mainStory)
    menuLayer:setVisible(false)

    mainStoryLayer = cc.CSLoader:createNode("Story/Menu/MainStoryLayer.csb")
    rootNode:addChild(mainStoryLayer)
    chap0Btn = mainStoryLayer:getChildByName("Btn_Chap0")
    chap0Btn:addTouchEventListener(self.chap0)
    mainStoryLayer:setVisible(false)

    currentLayer = menuLayer
    self:displayLayer(layer)
end

-- 按鈕callbacks
function StoryMenuScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function StoryMenuScene:menu(type)
    if type == ccui.TouchEventType.ended then
        StoryMenuScene:displayLayer("Menu")
    end
end
function StoryMenuScene:mainStory(type)
    if type == ccui.TouchEventType.ended then
        StoryMenuScene:displayLayer("MainStory")
    end
end
function StoryMenuScene:chap0(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/StorySectionScene.lua"):create({
            "MainStory", -- 劇情
            "MainStory_0" -- 章節
        })
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function StoryMenuScene:displayLayer(layer)
    if layer == nil then layer = "Menu" end
    currentLayer:setVisible(false)
    if layer == "Menu" then
        menuLayer:setVisible(true)
        currentLayer = menuLayer
        returnBtn:addTouchEventListener(self.mainPage)
        homeBtn:setVisible(false)
    elseif layer == "MainStory" then
        mainStoryLayer:setVisible(true)
        currentLayer = mainStoryLayer
        returnBtn:addTouchEventListener(self.menu)
        homeBtn:setVisible(true)
    end
end

return StoryMenuScene