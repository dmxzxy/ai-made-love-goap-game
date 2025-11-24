-- 移动到敌方基地
local Action = require("goap.action")

local MoveToBase = {}
setmetatable(MoveToBase, {__index = Action})
MoveToBase.__index = MoveToBase

function MoveToBase.new()
    local self = Action.new("MoveToBase", 1)
    setmetatable(self, MoveToBase)
    
    -- 前置条件：无
    self.preconditions = {}
    
    -- 效果：到达基地范围
    self.effects = {
        inBaseRange = true
    }
    
    self.cost = 4  -- 成本较高，优先攻击单位
    
    return self
end

function MoveToBase:checkProceduralPrecondition(agent)
    -- 必须有敌方基地且基地存活
    if not agent.enemyBase or agent.enemyBase.isDead then
        return false
    end
    
    -- 检查附近是否还有敌人单位
    local nearbyEnemies = 0
    for _, enemy in ipairs(agent.enemies) do
        if enemy.health > 0 and not enemy.isDead then
            local dx = enemy.x - agent.x
            local dy = enemy.y - agent.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance < 300 then
                nearbyEnemies = nearbyEnemies + 1
            end
        end
    end
    
    -- 只有当附近敌人很少时才考虑攻击基地
    return nearbyEnemies <= 1
end

function MoveToBase:perform(agent, dt)
    if not agent.enemyBase or agent.enemyBase.isDead then
        return true
    end
    
    -- 计算到基地的距离
    local dx = agent.enemyBase.x - agent.x
    local dy = agent.enemyBase.y - agent.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- 如果在攻击范围内，行动完成
    if distance <= agent.attackRange + 30 then
        agent.worldState.inBaseRange = true
        return true
    end
    
    -- 移动向基地
    local angle = math.atan2(dy, dx)
    agent.x = agent.x + math.cos(angle) * agent.moveSpeed * dt
    agent.y = agent.y + math.sin(angle) * agent.moveSpeed * dt
    agent.angle = angle
    
    return false  -- 继续移动
end

return MoveToBase
