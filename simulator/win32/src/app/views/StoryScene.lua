local StoryScene = class("StoryScene", function()
    return cc.Scene:create()
end)

local csv = require("lua-csv/lua/csv.lua")

local rootNode
local currentSect -- 當前所在段落
local speakerLabel -- 說話者名字的文字
local textLabel -- 說話內容文字
local csvFile -- 劇本文檔csv
local parsedScript -- 該段落的逐行劇本

function StoryScene:ctor(sect)
    currentSect = sect
    rootNode = cc.CSLoader:createNode("Story/Story/StoryScene.csb")
    self:addChild(rootNode)

    speakerLabel = rootNode:getChildByName("TextBg"):getChildByName("Speaker")
    speakerLabel:setString("test name")
    textLabel = rootNode:getChildByName("TextBg"):getChildByName("Text")
    textLabel:setString("test string")
    rootNode:getChildByName("Btn_next"):addTouchEventListener(self.next)

    csvFile = csv.open(cc.FileUtils:getInstance():getWritablePath() .. "Server/Story.csv")
    parsedScript = self:parseStoryScript(currentSect[3])
    self:nextDialog()
end

-- 按鈕callbacks
function StoryScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end
function StoryScene:next(type)
    if type == ccui.TouchEventType.ended then
        StoryScene:nextDialog()
    end
end

-- 讀取劇本
function StoryScene:parseStoryScript(sect)
    local script = {}
    local read = false
    local speakerID, speakerName, text
    for fields in csvFile:lines() do
        if read then -- 讀取該段落
            if fields[1] == "S" then -- 段落結束
                return script
            elseif fields[1] == "T" then -- 讀取文字
                speakerID = fields[2]
                speakerName = fields[3]
                if speakerName == "" then -- 使用預設名稱
                    speakerName = self:getSpeakerName(fields[2])
                end
                text = fields[4]
            elseif fields[1] == "" then -- 同speaker繼續講話
                text = fields[4]
            end
            table.insert(script, {
                speakerID,
                speakerName,
                text
            })
        else -- 還沒進到該段落
            if fields[1] == "L" and fields[2] == sect then
                script["SectionTitle"] = fields[3]
                read = true
            end
        end
    end
end
function StoryScene:getSpeakerName(id)
    if id == "" then return ""
    elseif id == "0" then return "主人公"
    elseif id == "100" then return "海原教授"
    elseif id == "101" then return "所長"
    elseif id == "1" then return "媞古"
    elseif id == "2" then return "莎美"
    elseif id == "3" then return "露露塔"
    elseif id == "4" then return "芭冷"
    end
end

-- 播放劇本
function StoryScene:nextDialog()
    if #parsedScript == 0 then -- 退回段落選單
        table.remove(currentSect)
        local scene = require("app/views/StorySectionScene.lua"):create(currentSect)
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
        return
    end
    speakerLabel:setString(parsedScript[1][2])
    textLabel:setString(parsedScript[1][3])
    table.remove(parsedScript, 1)
end

return StoryScene