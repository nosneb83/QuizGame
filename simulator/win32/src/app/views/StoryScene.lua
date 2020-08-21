local StoryeScene = class("StoryeScene", function()
    return cc.Scene:create()
end)

local csv = require("lua-csv/lua/csv.lua")

local rootNode
local speaker -- 說話者名字的文字
local text -- 說話內容文字

function StoryeScene:ctor()
    -- self.addChild(cc.CSLoader:createNode("Story/Story/Bg/BgRoomLayer.csb"))
    rootNode = cc.CSLoader:createNode("Story/Story/StoryScene.csb")
    self:addChild(rootNode)

    speaker = rootNode:getChildByName("TextBg"):getChildByName("Speaker")
    speaker:setString("test name")
    text = rootNode:getChildByName("TextBg"):getChildByName("Text")
    text:setString("test string")
    rootNode:getChildByName("Btn_next"):addTouchEventListener(self.next)

    -- local f, msg = csv.open(cc.FileUtils:getInstance():getWritablePath() .. "Server/Story.csv")
    -- dump(f)
    -- print(msg)
    -- for fields in f:lines() do
    --     for i, v in ipairs(fields) do print(i, v) end
    -- end
end

-- 按鈕callbacks
function StoryeScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function StoryeScene:next(type)
    if type == ccui.TouchEventType.ended then
        print("next line")
    end
end

return StoryeScene