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
    
    -- 评估所有敌方单位（最高优先级）
    for _, enemy in ipairs(agent.enemies) do
        if enemy.health > 0 and not enemy.isDead then
            local dx = enemy.x - agent.x
            local dy = enemy.y - agent.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- 敌方单位基础分数很高
            local score = 2000 / (distance + 10)
            
            -- 血量加成
            local hpPercent = enemy.health / enemy.maxHealth
            if hpPercent < 0.3 then
                score = score + 200
            elseif hpPercent < 0.5 then
                score = score + 100
            end
            
            -- 单位类型加成
            if enemy.unitClass == "Healer" then
                score = score + 300
            elseif enemy.unitClass == "Sniper" then
                score = score + 200
            end
            
            if score > bestScore then
                bestScore = score
                bestTarget = enemy
            end
        end
    end
    
    -- 评估防御塔（中等优先级）
    if agent.enemyTowers then
        for _, tower in ipairs(agent.enemyTowers) do
            if not tower.isDead and tower.health > 0 and not tower.isBuilding then
                local dx = tower.x - agent.x
                local dy = tower.y - agent.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                -- 塔的基础分数低于敌军
                local score = 800 / (distance + 10)
                
                -- 如果在塔的射程内，大幅提高优先级
                if distance < (tower.range or 200) + 50 then
                    score = score + 500  -- 受到威胁时优先拆塔
                end
                
                -- 残血塔优先
                local hpPercent = tower.health / tower.maxHealth
                if hpPercent < 0.3 then
                    score = score + 300
                elseif hpPercent < 0.5 then
                    score = score + 150
                end
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = tower
                end
            end
        end
    end
    
    -- 评估所有敌方基地（最低优先级，只有在没有更好目标时）
    if agent.enemyBases then
        for _, enemyBase in ipairs(agent.enemyBases) do
            if enemyBase and not enemyBase.isDead then
                local dx = enemyBase.x - agent.x
                local dy = enemyBase.y - agent.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                -- 基地分数极低
                local score = 100 / (distance + 100)
                
                -- 检查附近是否有威胁
                local hasNearbyThreats = false
                for _, enemy in ipairs(agent.enemies) do
                    if enemy.health > 0 and not enemy.isDead then
                        local ex = enemy.x - agent.x
                        local ey = enemy.y - agent.y
                        if math.sqrt(ex * ex + ey * ey) < 400 then
                            hasNearbyThreats = true
                            break
                        end
                    end
                end
                
                if not hasNearbyThreats and agent.enemyTowers then
                    for _, tower in ipairs(agent.enemyTowers) do
                        if not tower.isDead and tower.health > 0 then
                            local tx = tower.x - agent.x
                            local ty = tower.y - agent.y
                            if math.sqrt(tx * tx + ty * ty) < 400 then
                                hasNearbyThreats = true
                                break
                            end
                        end
                    end
                end
                
                -- 只有在没有威胁时才考虑攻击基地
                if not hasNearbyThreats then
                    score = score + 50
                else
                    score = score * 0.2  -- 有威胁时分数极低
                end
                
                -- 仇恨值加成：对仇恨高的队伍优先攻击
                if _G.getHatred then
                    local hatred = _G.getHatred(agent.team, enemyBase.team)
                    score = score + hatred * 0.5  -- 仇恨值每100点增加50分
                end
                
                -- 添加随机因素，避免所有单位都攻击同一个基地
                score = score + math.random() * 20
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = enemyBase
                end
            end
        end
    end
    
    if bestTarget then
        local targetType = bestTarget.unitClass or (bestTarget.towerType and "Tower") or "Base"
        print(string.format("[%s] Target acquired: %s (score: %.1f)", 
            agent.team, targetType, bestScore))
    end
    
    agent.target = bestTarget
    return true
end

return FindTarget
