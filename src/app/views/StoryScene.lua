local StoryScene = class("StoryScene", function()
    return cc.Scene:create()
end)

local csv = require("lua-csv/lua/csv.lua")
local utf8 = require 'lua-utf8'

local rootNode
local scheduler = cc.Director:getInstance():getScheduler()
local currentSect -- 當前所在段落
local dialogBg, dialogBgList -- 對話框背景
local speakerLabel -- 說話者名字的文字
local textLabel -- 說話內容文字
local currentText -- 當前文字
local csvFile -- 劇本文檔csv
local parsedScript -- 該段落的逐行劇本
local typewriterTime
local typewritingSpd = 0.025

function StoryScene:ctor(sect)
    currentSect = sect
    rootNode = cc.CSLoader:createNode("Story/Story/StoryScene.csb")
    self:addChild(rootNode)

    dialogBg = rootNode:getChildByName("Dialog"):getChildByName("Bg")
    dialogBgList = {
        dialogBg:getChildByName("Player"),
        dialogBg:getChildByName("Luluta"),
        dialogBg:getChildByName("Normal"),
        dialogBg:getChildByName("Palung"),
        dialogBg:getChildByName("Same"),
        dialogBg:getChildByName("Teko"),
        dialogBg:getChildByName("Text")
    }

    speakerLabel = rootNode:getChildByName("Dialog"):getChildByName("Speaker")
    speakerLabel:setString("")
    textLabel = rootNode:getChildByName("Dialog"):getChildByName("Text")
    textLabel:setString("")
    rootNode:getChildByName("Btn_next"):addTouchEventListener(self.next)

    csvFile = csv.open(cc.FileUtils:getInstance():getWritablePath() .. "Server/Story.csv")
    parsedScript = self:parseStoryScript(currentSect[3])
    rootNode:runAction(cc.Sequence:create(
    cc.DelayTime:create(sceneTransTime + 0.25),
    cc.CallFunc:create(self.nextDialog)))

    -- 打字機效果
    self:scheduleUpdateWithPriorityLua(function(dt)
        self:typewriting(dt)
    end, 0)
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
        if typewriterTime == nil then
            StoryScene:nextDialog()
        else
            typewriterTime = 100
        end
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
                    speakerName = self:getSpeakerName(speakerID)
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
function StoryScene:changeDialogBg(id)
    for _, v in ipairs(dialogBgList) do
        v:setVisible(false)
    end
    if id == "" then dialogBgList[3]:setVisible(true)
    elseif id == "0" then dialogBgList[1]:setVisible(true)
    elseif id == "100" then dialogBgList[3]:setVisible(true)
    elseif id == "101" then dialogBgList[3]:setVisible(true)
    elseif id == "1" then dialogBgList[6]:setVisible(true)
    elseif id == "2" then dialogBgList[5]:setVisible(true)
    elseif id == "3" then dialogBgList[2]:setVisible(true)
    elseif id == "4" then dialogBgList[4]:setVisible(true)
    end
    dialogBgList[7]:setVisible(true)
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
    StoryScene:changeDialogBg(parsedScript[1][1])
    speakerLabel:setString(parsedScript[1][2]) -- 說話者
    currentText = parsedScript[1][3] -- 講的話
    table.remove(parsedScript, 1)
    -- 打字機效果歸零
    typewriterTime = 0
end

-- 打字機效果
function StoryScene:typewriting(dt)
    if typewriterTime == nil then return end
    typewriterTime = typewriterTime + dt
    local showStrLen = math.min(utf8.len(currentText), typewriterTime / typewritingSpd)
    textLabel:setString(utf8.sub(currentText, 1, showStrLen))
    if showStrLen == utf8.len(currentText) then
        typewriterTime = nil
    end
end

return StoryScene