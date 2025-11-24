-- 空闲行动
local Action = require("goap.action")

local Idle = {}
Idle.__index = Idle
setmetatable(Idle, {__index = Action})

function Idle.new()
    local self = Action.new("Idle", 10)
    setmetatable(self, Idle)
    -- 没有前置条件
    self:addEffect("idle", true)
    return self
end

function Idle:checkProceduralPrecondition(agent)
    return true
end

function Idle:perform(agent, dt)
    -- 什么都不做
    return false
end

return Idle
