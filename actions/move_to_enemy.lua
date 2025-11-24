-- 移动到敌人行动
local Action = require("goap.action")

local MoveToEnemy = {}
MoveToEnemy.__index = MoveToEnemy
setmetatable(MoveToEnemy, {__index = Action})

function MoveToEnemy.new()
    local self = Action.new("MoveToEnemy", 1)
    setmetatable(self, MoveToEnemy)
    self:addPrecondition("hasTarget", true)
    self:addEffect("inRange", true)
    return self
end

function MoveToEnemy:checkProceduralPrecondition(agent)
    -- 目标可以是单位或基地
    if not agent.target then
        return false
    end
    
    -- 检查是否是基地目标
    if agent.target == agent.enemyBase then
        return not agent.target.isDead
    end
    
    -- 检查是否是单位目标
    return agent.target.health > 0
end

function MoveToEnemy:perform(agent, dt)
    if not agent.target then
        return true
    end
    
    -- 检查目标是否还存活
    local targetAlive = false
    if agent.target == agent.enemyBase then
        targetAlive = not agent.target.isDead
    else
        targetAlive = agent.target.health > 0
    end
    
    if not targetAlive then
        return true
    end
    
    local dx = agent.target.x - agent.x
    local dy = agent.target.y - agent.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- 更新朝向
    agent.angle = math.atan2(dy, dx)
    
    -- 如果在攻击范围内，停止移动（基地可以从稍远处攻击）
    local attackRange = agent.attackRange
    if agent.target == agent.enemyBase then
        attackRange = attackRange + 30
    end
    
    if distance <= attackRange then
        return true
    end
    
    -- 移动向目标
    local speed = agent.moveSpeed
    agent.x = agent.x + (dx / distance) * speed * dt
    agent.y = agent.y + (dy / distance) * speed * dt
    
    return false
end

return MoveToEnemy
