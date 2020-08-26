local StoryScene = class("StoryScene", function()
    return cc.Scene:create()
end)

-- local csv = require("lua-csv/lua/csv.lua")
-- local utf8 = require 'lua-utf8'
local utf8 = require('utf8_simple')

local rootNode
local scheduler = cc.Director:getInstance():getScheduler()
local currentSect, nextSectStr -- 當前所在段落, 下一段落
local btnNext -- 下一句
local storyBgs -- 劇情背景
local speakerImgs -- 角色立繪
local dialogBg, dialogBgList -- 對話框背景
local speakerLabel -- 說話者名字的文字
local textLabel -- 說話內容文字
local currentText -- 當前文字
-- local csvFile -- 劇本文檔csv
local parsedScript -- 該段落的逐行劇本
local contPanel, outOfBMPanel -- 繼續觀看panel, 書籤沒了panel
-- 打字機效果
local typewriterTime
local typewritingSpd = 0.04

function StoryScene:ctor(sect)
    currentSect = sect
    rootNode = cc.CSLoader:createNode("Story/Story/StoryScene.csb")
    self:addChild(rootNode)

    local storyBgRoot = rootNode:getChildByName("Bg")
    storyBgs = {
        storyBgRoot:getChildByName("01"),
        storyBgRoot:getChildByName("02"),
        storyBgRoot:getChildByName("03"),
        storyBgRoot:getChildByName("04"),
        storyBgRoot:getChildByName("05"),
        storyBgRoot:getChildByName("06"),
        storyBgRoot:getChildByName("07"),
        storyBgRoot:getChildByName("08"),
        storyBgRoot:getChildByName("09"),
        storyBgRoot:getChildByName("10"),
        storyBgRoot:getChildByName("11"),
        storyBgRoot:getChildByName("12"),
        storyBgRoot:getChildByName("13"),
        storyBgRoot:getChildByName("14"),
        storyBgRoot:getChildByName("15")
    }

    local speakerImgRoot = rootNode:getChildByName("Dialog"):getChildByName("CharImgs")
    speakerImgs = {
        speakerImgRoot:getChildByName("Teko"),
        speakerImgRoot:getChildByName("Same"),
        speakerImgRoot:getChildByName("Luluta"),
        speakerImgRoot:getChildByName("Palung"),
        speakerImgRoot:getChildByName("UharaP"),
        speakerImgRoot:getChildByName("YangP")
    }

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
    textLabel = rootNode:getChildByName("Dialog"):getChildByName("Text")
    self:initUI()
    btnNext = rootNode:getChildByName("Btn_next")
    btnNext:addTouchEventListener(self.next)

    contPanel = rootNode:getChildByName("Continue")
    contPanel:getChildByName("Y")
    :addTouchEventListener(self.nextSect)
    contPanel:getChildByName("N")
    :addTouchEventListener(self.backToSect)
    outOfBMPanel = rootNode:getChildByName("OutOfBM")
    outOfBMPanel:getChildByName("Y")
    :addTouchEventListener(self.backToSect)

    -- local path = cc.FileUtils:getInstance():fullPathForFilename("Story.csv")
    -- csvFile = csv.open(path)
    parsedScript = self:parseStoryScript(currentSect[3])
    StoryScene:changeStoryBg(parsedScript[1][4])
    rootNode:runAction(cc.Sequence:create(
    cc.DelayTime:create(sceneTransTime + 0.25),
    cc.CallFunc:create(self.nextDialog)))

    -- 打字機效果
    rootNode:scheduleUpdateWithPriorityLua(function(dt)
        self:typewriting(dt)
    end, 0)

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

-- UI初始化
function StoryScene:initUI()
    rootNode:stopAllActions()
    for _, v in ipairs(speakerImgs) do
        v:setVisible(false)
    end
    for _, v in ipairs(dialogBgList) do
        v:setVisible(false)
    end
    speakerLabel:setString("")
    textLabel:setString("")
end

-- 按鈕callbacks
function StoryScene:mainPage(type)
    if type == ccui.TouchEventType.ended then
        rootNode:stopAllActions()
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
function StoryScene:nextSect(type)
    if type == ccui.TouchEventType.ended then
        contPanel:setVisible(false)
        -- 檢查還有沒有書籤
        if player.bm > 0 then
            -- 叫server扣書籤
            local jsonObj = {
                op = "PAY_BOOKMARK",
                id = player.id
            }
            -- socket:send(json.encode(jsonObj))
            -- player.bm = player.bm - 1
            -- 播下一段劇情
            btnNext:setEnabled(true)
            currentSect[3] = nextSectStr
            StoryScene:nextDialog()
        else
            -- 告訴玩家書籤沒了
            outOfBMPanel:setVisible(true)
        end
    end
end
function StoryScene:backToSect(type)
    if type == ccui.TouchEventType.ended then
        contPanel:setVisible(false)
        table.remove(currentSect)
        local scene = require("app/views/StorySectionScene.lua"):create(currentSect)
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

-- 讀取劇本
function StoryScene:parseStoryScript(sect)
    local script = {}
    local read = false
    local speakerID, speakerName, text, bg

    -- for fields in csvFile:lines() do
    -- 鬧鬼區 ---------------------------
    -- dump(storyFile[1][1])
    -- print(string.byte(storyFile[1][1], 1, -1))
    -- dump(string.byte(storyFile[2][1]))
    -- dump(string.byte(storyFile[5][1]))
    -- dump(string.byte(storyFile[13][1]))
    -- dump(string.byte(storyFile[15][1]))
    -- dump(string.byte("'"))
    -- dump("L")
    -- dump(string.byte("L"))
    -- dump(storyFile[1][1] == "L")
    -- dump("L" == "L")
    ------------------------------------
    for _, fields in ipairs(storyFile) do
        -- dump(fields)
        if read then -- 讀取該段落
            if fields[1] == "S" then -- 段落結束
                return script
            elseif fields[1] == "B" then -- 改變背景
                bg = fields[2]
            elseif fields[1] == "T" then -- 讀取文字
                speakerID = fields[2]
                speakerName = fields[3]
                if speakerName == "" then -- 使用預設名稱
                    speakerName = self:getSpeakerName(speakerID)
                end
                text = fields[4]
                table.insert(script, {
                    speakerID,
                    speakerName,
                    text,
                    bg
                })
            elseif fields[1] == "" then -- 同speaker繼續講話
                text = fields[4]
                table.insert(script, {
                    speakerID,
                    speakerName,
                    text,
                    bg
                })
            end
        else -- 還沒進到該段落
            if fields[2] == sect then
                script["SectionTitle"] = fields[3]
                script["DefaultBg"] = fields[4]
                bg = fields[4]
                read = true
                print("enter section")
            end
        end
    end
    -- 讀不到該段劇本, 返回上層
    print("Section Not Found")
    table.remove(currentSect)
    local scene = require("app/views/StorySectionScene.lua"):create(currentSect)
    cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
end
function StoryScene:changeStoryBg(bgID) -- 改變背景
    for _, v in ipairs(storyBgs) do
        v:setVisible(false)
    end
    storyBgs[tonumber(bgID)]:setVisible(true)
end
function StoryScene:changeCharImg(id) -- 改變立繪
    for _, v in ipairs(speakerImgs) do
        v:setVisible(false)
    end
    if id == "100" then speakerImgs[5]:setVisible(true)
    elseif id == "101" then speakerImgs[6]:setVisible(true)
    elseif id == "1" then speakerImgs[1]:setVisible(true)
    elseif id == "2" then speakerImgs[2]:setVisible(true)
    elseif id == "3" then speakerImgs[3]:setVisible(true)
    elseif id == "4" then speakerImgs[4]:setVisible(true)
    end
end
function StoryScene:changeDialogBg(id) -- 改變對話框
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
    elseif id == "0" then return player.name
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
        self:initUI()
        btnNext:setEnabled(false)
        -- 讀取下一段劇本
        nextSectStr = string.sub(currentSect[3], 1, 4) .. tostring(tonumber(string.sub(currentSect[3], 5, 5)) + 1)
        parsedScript = StoryScene:parseStoryScript(nextSectStr)
        -- 問玩家要不要繼續
        if parsedScript ~= nil then contPanel:setVisible(true) end
        return
    end
    StoryScene:changeStoryBg(parsedScript[1][4])
    StoryScene:changeCharImg(parsedScript[1][1])
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

-- Handle Server Op
function StoryScene:handleOp(jsonObj)
    dump(jsonObj)
end

return StoryScene