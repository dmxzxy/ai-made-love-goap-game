-- 攻击敌人行动
local Action = require("goap.action")

local AttackEnemy = {}
AttackEnemy.__index = AttackEnemy
setmetatable(AttackEnemy, {__index = Action})

function AttackEnemy.new()
    local self = Action.new("AttackEnemy", 1)  -- 降低cost使其更优先
    setmetatable(self, AttackEnemy)
    self:addPrecondition("hasTarget", true)
    self:addPrecondition("inRange", true)
    self:addEffect("attacking", true)  -- 添加攻击效果
    self.attackCooldown = 0
    return self
end

function AttackEnemy:checkProceduralPrecondition(agent)
    if not agent.target then
        return false
    end
    
    -- 检查目标是否存活
    local targetAlive = false
    if agent.target == agent.enemyBase then
        targetAlive = not agent.target.isDead
    else
        targetAlive = agent.target.health > 0
    end
    
    if not targetAlive then
        return false
    end
    
    local dx = agent.target.x - agent.x
    local dy = agent.target.y - agent.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- 基地可以从稍远处攻击
    local attackRange = agent.attackRange
    if agent.target == agent.enemyBase then
        attackRange = attackRange + 30
    end
    
    return distance <= attackRange
end

function AttackEnemy:perform(agent, dt)
    if not agent.target then
        return true
    end
    
    -- 检查目标是否存活
    local targetAlive = false
    if agent.target == agent.enemyBase then
        targetAlive = not agent.target.isDead
    else
        targetAlive = (agent.target.health > 0 and not agent.target.isDead)
    end
    
    if not targetAlive then
        print(string.format("[%s] Attack target lost", agent.team))
        return true
    end
    
    -- 更新冷却时间
    if self.attackCooldown > 0 then
        self.attackCooldown = self.attackCooldown - dt
        return false
    end
    
    -- 面向目标
    local dx = agent.target.x - agent.x
    local dy = agent.target.y - agent.y
    agent.angle = math.atan2(dy, dx)
    
    -- 暴击判定
    local isCrit = math.random() < agent.critChance
    
    -- 攻击
    local damage = agent.attackDamage
    local actualDamage = agent.target:takeDamage(damage, isCrit)
    self.attackCooldown = agent.attackSpeed
    
    -- 创建攻击特效
    agent:createAttackEffect(agent.target.x, agent.target.y)
    
    if actualDamage > 0 then
        local targetType = (agent.target == agent.enemyBase) and "BASE" or "Enemy"
        local targetHealth = agent.target.health
        print(string.format("[%s] Attacking %s! Damage: %.1f%s Health: %.1f", 
            agent.team, targetType, actualDamage, isCrit and " (CRIT)" or "", targetHealth))
    end
    
    -- 继续攻击，不返回 true（除非目标死亡会在下次调用时返回true）
    return false
end

return AttackEnemy
