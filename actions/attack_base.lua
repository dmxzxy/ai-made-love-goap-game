-- 攻击敌方基地
local Action = require("goap.action")

local AttackBase = {}
setmetatable(AttackBase, {__index = Action})
AttackBase.__index = AttackBase

function AttackBase.new()
    local self = Action.new("AttackBase", 1)
    setmetatable(self, AttackBase)
    
    -- 前置条件：无敌人单位（或敌人单位很少），且在基地范围内
    self.preconditions = {
        inBaseRange = true
    }
    
    -- 效果：正在攻击
    self.effects = {
        attacking = true
    }
    
    self.cost = 3  -- 优先级较低
    
    return self
end

function AttackBase:checkProceduralPrecondition(agent)
    -- 必须有敌方基地且基地存活
    if not agent.enemyBase or agent.enemyBase.isDead then
        return false
    end
    
    -- 检查是否在基地攻击范围内
    local dx = agent.enemyBase.x - agent.x
    local dy = agent.enemyBase.y - agent.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    return distance <= agent.attackRange + 30  -- 基地可以从稍远处攻击
end

function AttackBase:perform(agent, dt)
    if not agent.enemyBase or agent.enemyBase.isDead then
        return true  -- 基地已摧毁，行动完成
    end
    
    -- 攻击冷却
    agent.attackCooldown = agent.attackCooldown or 0
    agent.attackCooldown = agent.attackCooldown - dt
    
    if agent.attackCooldown <= 0 then
        agent.attackCooldown = agent.attackSpeed
        
        -- 攻击基地
        local isCrit = math.random() < agent.critChance
        local damage = agent.attackDamage
        
        -- 对建筑物造成额外伤害 (50% bonus for bases)
        local damageMultiplier = 1.5  -- 对基地的伤害提升50%
        local finalDamage = damage * damageMultiplier
        
        local actualDamage = agent.enemyBase:takeDamage(finalDamage, isCrit)
        
        -- 创建攻击特效
        agent:createAttackEffect(agent.enemyBase.x, agent.enemyBase.y)
        
        print(string.format("[%s] Attacking enemy base! Damage: %.1f", 
            agent.team, actualDamage))
    end
    
    return false  -- 持续攻击
end

return AttackBase
