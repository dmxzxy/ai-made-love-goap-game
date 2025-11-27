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
    
    -- 如果在攻击范围内，立即完成移动（更积极）
    local attackRange = agent.attackRange * 0.9  -- 稍微提前完成移动，减少延迟
    if agent.target == agent.enemyBase then
        attackRange = attackRange + 30
    end
    
    if distance <= attackRange then
        return true  -- 立即完成，进入攻击
    end
    
    -- ===== 移动中攻击功能 =====
    -- 检查攻击范围内是否有敌人，有则优先攻击
    if agent.enemies and (agent.attackCooldown or 0) <= 0 then
        local closestEnemy = nil
        local closestDist = math.huge
        
        for _, enemy in ipairs(agent.enemies) do
            if not enemy.isDead and enemy.health > 0 then
                local eDx = enemy.x - agent.x
                local eDy = enemy.y - agent.y
                local eDist = math.sqrt(eDx * eDx + eDy * eDy)
                
                -- 在攻击范围内
                if eDist <= agent.attackRange and eDist < closestDist then
                    closestEnemy = enemy
                    closestDist = eDist
                end
            end
        end
        
        -- 如果找到攻击范围内的敌人，进行攻击
        if closestEnemy then
            -- 执行攻击
            agent.isAttacking = true
            agent.attackCooldown = 1 / agent.attackSpeed
            
            -- 朝向敌人
            local attackAngle = math.atan2(closestEnemy.y - agent.y, closestEnemy.x - agent.x)
            agent.angle = attackAngle
            
            -- 造成伤害
            closestEnemy.health = closestEnemy.health - agent.attackDamage
            closestEnemy.lastAttacker = agent
            closestEnemy.lastAttackedTime = love.timer.getTime()
            
            -- 伤害数字效果
            if closestEnemy.addDamageNumber then
                closestEnemy:addDamageNumber("-" .. agent.attackDamage, {1, 0.3, 0.3})
            end
            
            -- 粒子效果
            if _G.Particles and _G.Particles.createHit then
                _G.Particles.createHit(closestEnemy.x, closestEnemy.y, agent.color)
            end
        end
    end
    
    -- 计算基础移动方向
    local moveX = dx / distance
    local moveY = dy / distance
    
    -- 避障：检查前方是否有盟友拥堵
    local avoidX = 0
    local avoidY = 0
    local nearbyCount = 0
    
    for _, ally in ipairs(agent.allies) do
        if ally ~= agent and not ally.isDead and ally.health > 0 then
            local allyDx = ally.x - agent.x
            local allyDy = ally.y - agent.y
            local allyDist = math.sqrt(allyDx * allyDx + allyDy * allyDy)
            
            -- 检查前方50px范围内的盟友
            if allyDist < 50 then
                nearbyCount = nearbyCount + 1
                -- 添加避开力
                avoidX = avoidX - allyDx / (allyDist + 1)
                avoidY = avoidY - allyDy / (allyDist + 1)
            end
        end
    end
    
    -- 如果前方拥堵（3个以上盟友），添加避障偏移
    if nearbyCount >= 3 then
        -- 混合避障方向和目标方向
        moveX = moveX * 0.6 + avoidX * 0.4
        moveY = moveY * 0.6 + avoidY * 0.4
        
        -- 重新归一化
        local newLen = math.sqrt(moveX * moveX + moveY * moveY)
        if newLen > 0 then
            moveX = moveX / newLen
            moveY = moveY / newLen
        end
    end
    
    -- 移动向目标（带避障）
    local speed = agent.moveSpeed
    
    -- 拥堵时随机添加小偏移，帮助分散
    if agent.isCrowded and agent.crowdedTimer > 0.5 then
        local randomAngle = (math.random() - 0.5) * 0.5  -- ±0.25弧度
        local cos = math.cos(randomAngle)
        local sin = math.sin(randomAngle)
        local newMoveX = moveX * cos - moveY * sin
        local newMoveY = moveX * sin + moveY * cos
        moveX = newMoveX
        moveY = newMoveY
    end
    
    agent.x = agent.x + moveX * speed * dt
    agent.y = agent.y + moveY * speed * dt
    
    return false
end

return MoveToEnemy
