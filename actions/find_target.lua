-- 寻找目标行动
local Action = require("goap.action")

local FindTarget = {}
FindTarget.__index = FindTarget
setmetatable(FindTarget, {__index = Action})

function FindTarget.new()
    local self = Action.new("FindTarget", 1)
    setmetatable(self, FindTarget)
    self:addPrecondition("hasTarget", false)
    self:addEffect("hasTarget", true)
    return self
end

function FindTarget:checkProceduralPrecondition(agent)
    -- 总是可以寻找目标（敌方单位或基地）
    return true
end

function FindTarget:perform(agent, dt)
    local bestTarget = nil
    local bestScore = -math.huge
    
    -- 首先检查是否有附近的防御塔（高威胁）
    local nearbyTower = nil
    local nearestTowerDist = 300  -- 防御塔威胁范围
    
    if agent.enemyTowers then
        for _, tower in ipairs(agent.enemyTowers) do
            if not tower.isDead and not tower.isBuilding then
                local dx = tower.x - agent.x
                local dy = tower.y - agent.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                -- 如果在防御塔攻击范围内，优先攻击塔
                if distance < tower.range + 50 and distance < nearestTowerDist then
                    nearestTowerDist = distance
                    nearbyTower = tower
                end
            end
        end
    end
    
    if nearbyTower then
        agent.target = nearbyTower
        print(string.format("[%s] Priority target: Enemy tower in range!", agent.team))
        return true
    end
    
    -- 尝试找敌方单位
    local hasLivingEnemies = false
    for _, enemy in ipairs(agent.enemies) do
        if enemy.health > 0 and not enemy.isDead then
            hasLivingEnemies = true
            break
        end
    end
    
    if hasLivingEnemies then
        -- 有存活的敌方单位，优先攻击单位
        local strategy = math.random(1, 3)
        
        for _, enemy in ipairs(agent.enemies) do
            if enemy.health > 0 and not enemy.isDead then
                local dx = enemy.x - agent.x
                local dy = enemy.y - agent.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                local score = 0
                if strategy == 1 then
                    -- 策略1: 优先攻击近的敌人
                    score = 1000 / (distance + 1)
                elseif strategy == 2 then
                    -- 策略2: 优先攻击血少的敌人
                    score = (1 - enemy.health / enemy.maxHealth) * 1000
                else
                    -- 策略3: 综合考虑距离和血量
                    local distanceScore = 500 / (distance + 1)
                    local healthScore = (1 - enemy.health / enemy.maxHealth) * 500
                    score = distanceScore + healthScore
                end
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = enemy
                end
            end
        end
        
        if bestTarget then
            local strategyName = strategy == 1 and "Nearest" or (strategy == 2 and "Weakest" or "Balanced")
            print(string.format("[%s] Target acquired (%s): Enemy HP=%.0f", 
                agent.team, strategyName, bestTarget.health))
        end
    else
        -- 没有存活的敌方单位，目标是敌方基地
        if agent.enemyBase and not agent.enemyBase.isDead then
            bestTarget = agent.enemyBase
            print(string.format("[%s] All enemies down, targeting enemy base!", agent.team))
        end
    end
    
    agent.target = bestTarget
    return true
end

return FindTarget
