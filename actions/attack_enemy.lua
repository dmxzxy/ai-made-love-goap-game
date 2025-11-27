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
    
    -- 扩大攻击判定范围，允许轻微的追击
    local attackRange = agent.attackRange * 1.2  -- 增加20%容错
    if agent.target == agent.enemyBase then
        attackRange = attackRange + 50
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
    
    -- 更新冷却时间（冷却期间也可以做微调整）
    if agent.attackCooldown > 0 then
        -- 冷却期间：保持面向目标，允许微移动
        local dx = agent.target.x - agent.x
        local dy = agent.target.y - agent.y
        agent.angle = math.atan2(dy, dx)
        
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- 冷却期间也允许位置微调（不要傻站着）
        if not agent.target.towerType and not agent.target.isBase then
            -- 近战单位：小幅环绕移动
            if agent.attackRange < 150 and distance > agent.radius * 3 then
                local strafeAngle = math.random() < 0.5 and math.pi/2 or -math.pi/2
                local strafeX = math.cos(agent.angle + strafeAngle) * 10 * dt
                local strafeY = math.sin(agent.angle + strafeAngle) * 10 * dt
                agent.x = agent.x + strafeX
                agent.y = agent.y + strafeY
            end
            
            -- 远程单位：保持最佳射程
            if agent.attackRange >= 150 then
                local optimalRange = agent.attackRange * 0.8
                if distance < optimalRange * 0.6 then
                    -- 后退
                    agent.x = agent.x - (dx / distance) * agent.moveSpeed * 0.2 * dt
                    agent.y = agent.y - (dy / distance) * agent.moveSpeed * 0.2 * dt
                elseif distance > optimalRange * 1.3 then
                    -- 前进
                    agent.x = agent.x + (dx / distance) * agent.moveSpeed * 0.2 * dt
                    agent.y = agent.y + (dy / distance) * agent.moveSpeed * 0.2 * dt
                end
            end
        end
        
        return false  -- 还在冷却中，继续等待
    end
    
    -- 面向目标
    local dx = agent.target.x - agent.x
    local dy = agent.target.y - agent.y
    agent.angle = math.atan2(dy, dx)
    
    -- 暴击判定
    local isCrit = math.random() < agent.critChance
    
    -- 攻击前特效（子弹轨迹）
    local Particles = require("effects.particles")
    if agent.unitClass == "Sniper" or agent.unitClass == "Ranger" then
        -- 远程单位：子弹轨迹
        Particles.createBulletTrail(agent.x, agent.y, agent.target.x, agent.target.y, agent.color)
    elseif agent.unitClass == "Gunner" then
        -- 机枪手：连续子弹
        for i = 1, 3 do
            Particles.createBulletTrail(
                agent.x + (math.random() - 0.5) * 10, 
                agent.y + (math.random() - 0.5) * 10, 
                agent.target.x, agent.target.y, 
                {1, 0.8, 0.3}
            )
        end
    else
        -- 近战单位：火花效果
        Particles.createSparks(agent.x + dx * 0.3, agent.y + dy * 0.3, {1, 0.7, 0.3}, 5)
    end
    
    -- 攻击
    local damage = agent.attackDamage
    
    -- 兵种克制系统加成
    local UnitCounter = require("systems.unit_counter")
    local targetClass = agent.target.unitClass or (agent.target.towerType and "Tower") or nil
    local counterMultiplier = UnitCounter.getDamageMultiplier(agent.unitClass, targetClass)
    
    -- 对防御塔造成额外伤害 (75% bonus)
    local damageMultiplier = 1.0
    if agent.target.towerType then
        damageMultiplier = 1.75  -- 对塔的伤害提升75%
    end
    
    -- 应用克制加成
    damageMultiplier = damageMultiplier * counterMultiplier
    
    local finalDamage = damage * damageMultiplier
    local actualDamage = agent.target:takeDamage(finalDamage, isCrit, agent)  -- 传递攻击者
    
    -- 设置攻击冷却和状态
    agent.attackCooldown = agent.attackSpeed
    agent.isAttacking = true
    
    -- 增加仇恨值（当对敌人或基地造成伤害时）
    if actualDamage > 0 and agent.target.team and agent.team then
        if _G.addHatred then
            local hatredAmount = actualDamage * 0.5  -- 每点伤害产生0.5点仇恨
            if agent.target.towerType then
                hatredAmount = hatredAmount * 1.5  -- 攻击建筑产生更多仇恨
            elseif agent.target == agent.enemyBase or agent.target.isBase then
                hatredAmount = hatredAmount * 3  -- 攻击基地产生大量仇恨
            end
            _G.addHatred(agent.team, agent.target.team, hatredAmount)
        end
    end
    
    -- 克制提示
    if counterMultiplier > 1.0 and actualDamage > 0 then
        agent:addDamageNumber(string.format("克制! x%.1f", counterMultiplier), {1, 0.8, 0}, false)
    end
    
    -- 创建攻击特效
    agent:createAttackEffect(agent.target.x, agent.target.y)
    
    if actualDamage > 0 then
        -- 只在暴击或对基地攻击时打印日志
        if isCrit or agent.target == agent.enemyBase then
            local targetType = (agent.target == agent.enemyBase) and "BASE" or "Enemy"
            local targetHealth = agent.target.health
            print(string.format("[%s] Attacking %s! Damage: %.1f%s Health: %.1f", 
                agent.team, targetType, actualDamage, isCrit and " (CRIT)" or "", targetHealth))
        end
    end
    
    -- 继续攻击，不返回 true（除非目标死亡会在下次调用时返回true）
    return false
end

return AttackEnemy
