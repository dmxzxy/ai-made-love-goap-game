-- 撤退行动（血量低时）
local Action = require("goap.action")

local Retreat = {}
Retreat.__index = Retreat
setmetatable(Retreat, {__index = Action})

function Retreat.new()
    local self = Action.new("Retreat", 3)
    setmetatable(self, Retreat)
    self:addPrecondition("lowHealth", true)
    self:addEffect("safe", true)
    return self
end

function Retreat:checkProceduralPrecondition(agent)
    -- 血量低于40%时考虑撤退
    return agent.health / agent.maxHealth < 0.4
end

function Retreat:perform(agent, dt)
    -- 远离最近的敌人
    local closestEnemy = nil
    local closestDistance = math.huge
    
    for _, enemy in ipairs(agent.enemies) do
        if enemy.health > 0 and not enemy.isDead then
            local dx = enemy.x - agent.x
            local dy = enemy.y - agent.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < closestDistance then
                closestDistance = distance
                closestEnemy = enemy
            end
        end
    end
    
    if closestEnemy then
        local dx = agent.x - closestEnemy.x
        local dy = agent.y - closestEnemy.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > 0 then
            -- 远离敌人
            agent.angle = math.atan2(dy, dx)
            agent.x = agent.x + (dx / distance) * agent.moveSpeed * dt
            agent.y = agent.y + (dy / distance) * agent.moveSpeed * dt
            
            -- 限制在屏幕内
            agent.x = math.max(50, math.min(1150, agent.x))
            agent.y = math.max(50, math.min(750, agent.y))
        end
    end
    
    -- 如果血量恢复或距离足够远，停止撤退
    if agent.health / agent.maxHealth > 0.5 or closestDistance > 200 then
        return true
    end
    
    return false
end

return Retreat
