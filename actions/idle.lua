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
    -- 如果是矿工，保持原地待命
    if agent.isMiner then
        return false
    end
    
    -- 战斗单位：向地图中央移动（增加中央战场活跃度）
    local WORLD_CENTER_X = 1600  -- 地图中心X (3200/2)
    local WORLD_CENTER_Y = 900   -- 地图中心Y (1800/2)
    
    local dx = WORLD_CENTER_X - agent.x
    local dy = WORLD_CENTER_Y - agent.y
    local distToCenter = math.sqrt(dx * dx + dy * dy)
    
    -- 如果离中心较远（>400），向中心移动
    if distToCenter > 400 then
        local dirX = dx / distToCenter
        local dirY = dy / distToCenter
        
        agent.x = agent.x + dirX * agent.moveSpeed * dt
        agent.y = agent.y + dirY * agent.moveSpeed * dt
        agent.angle = math.atan2(dy, dx)
    end
    
    return false
end

return Idle
