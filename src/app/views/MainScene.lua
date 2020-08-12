local MainScene = class("MainScene", function()
    return cc.Scene:create()
end)

require("json")

cc.exports.playerID = -1

local rootNode
local menuBtns = {}
local menuBtnPos = {}
local menuBtnAnimFunc

function MainScene:ctor(id)
    playerID = id

    rootNode = cc.CSLoader:createNode("MainScene/MainScene.csb")
    self:addChild(rootNode)

    -- 選單按鈕
    menuBtns = {
        rootNode:getChildByName("Btns"):getChildByName("Btn_player"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_lab"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_battle"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_kacha"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_story")
    }
    menuBtns[1]:addTouchEventListener(self.enterPlayerScene)
    menuBtns[2]:addTouchEventListener(self.enterLabScene)
    menuBtns[3]:addTouchEventListener(self.enterBattleScene)
    menuBtns[4]:addTouchEventListener(self.enterKachaScene)
    menuBtns[5]:addTouchEventListener(self.enterStoryScene)
    menuBtnPos = {
        cc.p(menuBtns[1]:getPosition()),
        cc.p(menuBtns[2]:getPosition()),
        cc.p(menuBtns[3]:getPosition()),
        cc.p(menuBtns[4]:getPosition()),
        cc.p(menuBtns[5]:getPosition())
    }
    -- 選單按鈕左右滾動效果
    local menuAnimDur = 0.5 -- 選單按鈕滾動速度(時間長度)
    menuBtnAnimFunc = function(btn, to)
        btn:setEnabled(false)
        btn:stopAllActions()
        if to == 1 then
            btn:runAction(cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[1]),
            cc.ScaleTo:create(menuAnimDur, 0.01),
            cc.FadeTo:create(menuAnimDur, 0)
            ))
        elseif to == 2 then
            btn:runAction(cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[2]),
            cc.ScaleTo:create(menuAnimDur, 0.6),
            cc.FadeTo:create(menuAnimDur, 204)
            ))
        elseif to == 3 then
            btn:runAction(cc.Sequence:create(
            cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[3]),
            cc.ScaleTo:create(menuAnimDur, 1),
            cc.FadeTo:create(menuAnimDur, 204)
            ),
            cc.CallFunc:create(function() btn:setEnabled(true) end)))
        elseif to == 4 then
            btn:runAction(cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[4]),
            cc.ScaleTo:create(menuAnimDur, 0.6),
            cc.FadeTo:create(menuAnimDur, 204)
            ))
        elseif to == 5 then
            btn:runAction(cc.Spawn:create(
            cc.MoveTo:create(menuAnimDur, menuBtnPos[5]),
            cc.ScaleTo:create(menuAnimDur, 0.01),
            cc.FadeTo:create(menuAnimDur, 0)
            ))
        end
    end
    local menuLeftBtn = rootNode:getChildByName("Btns"):getChildByName("Btn_left")
    menuLeftBtn:addTouchEventListener(self.menuLeft)
    local menuRightBtn = rootNode:getChildByName("Btns"):getChildByName("Btn_right")
    menuRightBtn:addTouchEventListener(self.menuRight)
end

function MainScene:enterPlayerScene(type)
    if type == ccui.TouchEventType.ended then
        print("個人頁面")
    end
end

function MainScene:enterLabScene(type)
    if type == ccui.TouchEventType.ended then
        print("研究室")
    end
end

function MainScene:enterBattleScene(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/BattleModeScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(1, scene))
    end
end

function MainScene:enterKachaScene(type)
    if type == ccui.TouchEventType.ended then
        print("轉蛋")
    end
end

function MainScene:enterStoryScene(type)
    if type == ccui.TouchEventType.ended then
        print("圖書館")
    end
end

function MainScene:menuLeft(type)
    if type == ccui.TouchEventType.ended then
        for i = 1, 5 do
            menuBtnAnimFunc(menuBtns[i], (i - 2) % 5 + 1)
        end
        table.insert(menuBtns, table.remove(menuBtns, 1))
    end
end

function MainScene:menuRight(type)
    if type == ccui.TouchEventType.ended then
        for i = 1, 5 do
            menuBtnAnimFunc(menuBtns[i], i % 5 + 1)
        end
        table.insert(menuBtns, 1, table.remove(menuBtns))
    end
end

return MainScene