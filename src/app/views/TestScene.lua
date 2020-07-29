local TestScene = class("TestScene", function()
    return cc.Scene:create()
end)

local rootNode

function TestScene:ctor()
    rootNode = cc.CSLoader:createNode("TestScene.csb")
    self:addChild(rootNode)
end

return TestScene