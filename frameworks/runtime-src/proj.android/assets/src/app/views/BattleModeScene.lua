local BattleModeScene = class("BattleModeScene", function()
    return cc.Scene:create()
end)

local rootNode
local menuBtns = {}
local menuBtnPos = {}
local menuBtnAnimFunc

function BattleModeScene:ctor()
    rootNode = cc.CSLoader:createNode("BattleMode/BattleModeScene.csb")
    self:addChild(rootNode)
    rootNode:getChildByName("Btn_return"):addTouchEventListener(self.returnMain)

    -- 選單按鈕
    menuBtns = {
        rootNode:getChildByName("Btns"):getChildByName("Btn_event"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_pve"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_1v1"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_room"),
        rootNode:getChildByName("Btns"):getChildByName("Btn_tournament")
    }
    menuBtns[1]:addTouchEventListener(self.enter1)
    menuBtns[2]:addTouchEventListener(self.enter2)
    menuBtns[3]:addTouchEventListener(self.enterBattle)
    menuBtns[4]:addTouchEventListener(self.enter4)
    menuBtns[5]:addTouchEventListener(self.enter5)
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

function BattleModeScene:returnMain(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/MainScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

function BattleModeScene:enter1(type)
    if type == ccui.TouchEventType.ended then
        print("活動")
    end
end

function BattleModeScene:enter2(type)
    if type == ccui.TouchEventType.ended then
        print("PVE")
    end
end

function BattleModeScene:enterBattle(type)
    if type == ccui.TouchEventType.ended then
        local scene = require("app/views/BattleScene.lua"):create()
        cc.Director:getInstance():replaceScene(cc.TransitionFade:create(sceneTransTime, scene))
    end
end

function BattleModeScene:enter4(type)
    if type == ccui.TouchEventType.ended then
        print("約戰")
    end
end

function BattleModeScene:enter5(type)
    if type == ccui.TouchEventType.ended then
        print("錦標賽")
    end
end

function BattleModeScene:menuLeft(type)
    if type == ccui.TouchEventType.ended then
        for i = 1, 5 do
            menuBtnAnimFunc(menuBtns[i], i % 5 + 1)
        end
        table.insert(menuBtns, 1, table.remove(menuBtns))
    end
end

function BattleModeScene:menuRight(type)
    if type == ccui.TouchEventType.ended then
        for i = 1, 5 do
            menuBtnAnimFunc(menuBtns[i], (i - 2) % 5 + 1)
        end
        table.insert(menuBtns, table.remove(menuBtns, 1))
    end
end

return BattleModeScene