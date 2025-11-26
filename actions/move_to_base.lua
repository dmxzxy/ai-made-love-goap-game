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
    
    -- 避障：检查前方盟友拥堵
    local avoidX = 0
    local avoidY = 0
    local nearbyCount = 0
    
    for _, ally in ipairs(agent.allies) do
        if ally ~= agent and not ally.isDead and ally.health > 0 then
            local allyDx = ally.x - agent.x
            local allyDy = ally.y - agent.y
            local allyDist = math.sqrt(allyDx * allyDx + allyDy * allyDy)
            
            if allyDist < 50 then
                nearbyCount = nearbyCount + 1
                avoidX = avoidX - allyDx / (allyDist + 1)
                avoidY = avoidY - allyDy / (allyDist + 1)
            end
        end
    end
    
    -- 拥堵时混合避障方向
    if nearbyCount >= 3 then
        moveX = moveX * 0.6 + avoidX * 0.4
        moveY = moveY * 0.6 + avoidY * 0.4
        local newLen = math.sqrt(moveX * moveX + moveY * moveY)
        if newLen > 0 then
            moveX = moveX / newLen
            moveY = moveY / newLen
        end
    end
    
    -- 拥堵时添加随机偏移
    if agent.isCrowded and agent.crowdedTimer > 0.5 then
        local randomAngle = (math.random() - 0.5) * 0.5
        local cos = math.cos(randomAngle)
        local sin = math.sin(randomAngle)
        local newMoveX = moveX * cos - moveY * sin
        local newMoveY = moveX * sin + moveY * cos
        moveX = newMoveX
        moveY = newMoveY
    end
    
    -- 移动
    agent.x = agent.x + moveX * agent.moveSpeed * dt
    agent.y = agent.y + moveY * agent.moveSpeed * dt
    agent.angle = math.atan2(moveY, moveX)
    
    return false  -- 继续移动
end

return MoveToBase
