-- 战斗单位
local Planner = require("goap.planner")
local FindTarget = require("actions.find_target")
local MoveToEnemy = require("actions.move_to_enemy")
local AttackEnemy = require("actions.attack_enemy")
local Idle = require("actions.idle")
-- 暂时禁用Retreat以确保游戏稳定运行
-- local Retreat = require("actions.retreat")

local Agent = {}
Agent.__index = Agent

function Agent.new(x, y, team, color, unitClass)
    local self = setmetatable({}, Agent)
    
    -- 位置和显示
    self.x = x
    self.y = y
    self.angle = 0
    self.radius = 20
    self.team = team
    self.color = color or {1, 1, 1}
    self.unitClass = unitClass or "Soldier"  -- 兵种类型
    
    -- 属性（平衡的随机性）
    -- 使用正态分布让属性更集中在中间值
    local function normalRandom(min, max)
        local mid = (min + max) / 2
        local range = (max - min) / 2
        -- 使用三个随机数的平均值来近似正态分布
        local r = (math.random() + math.random() + math.random()) / 3
        return mid + (r - 0.5) * 2 * range
    end
    
    -- 根据兵种设置不同属性
    if unitClass == "Miner" then
        -- 矿工：不战斗，专门采集资源
        self.health = normalRandom(60, 80)
        self.maxHealth = self.health
        self.moveSpeed = normalRandom(70, 90)  -- 移动快
        self.attackDamage = 0  -- 不攻击
        self.attackRange = 0
        self.attackSpeed = 0
        self.critChance = 0
        self.dodgeChance = normalRandom(0.2, 0.35)  -- 高闪避
        self.armor = 0
        self.hasRegen = false
        self.hasBerserk = false
        self.radius = 15
        self.isMiner = true
        self.miningRate = normalRandom(4, 6)  -- 每秒采集速度
        self.miningRange = 50  -- 采集范围（必须靠近资源）
        self.carryCapacity = 50  -- 携带上限
        self.carriedResources = 0  -- 当前携带资源
        self.targetResource = nil  -- 目标资源点
        self.returningToBase = false  -- 是否返回基地
        
    elseif unitClass == "Sniper" then
        -- 狙击手：高伤害、超远射程、低血量、慢速
        self.health = normalRandom(60, 80)
        self.maxHealth = self.health
        self.moveSpeed = normalRandom(50, 70)
        self.attackDamage = normalRandom(30, 45)
        self.attackRange = normalRandom(180, 220)
        self.attackSpeed = normalRandom(1.5, 2.0)  -- 攻击慢
        self.critChance = normalRandom(0.4, 0.6)  -- 高暴击
        self.dodgeChance = math.random() * 0.15
        self.armor = math.random() * 0.1
        self.hasRegen = false
        self.hasBerserk = false
        self.radius = 18  -- 稍小
        
    elseif unitClass == "Gunner" then
        -- 机枪手：高射速、中等伤害、中等血量、固定阵地
        self.health = normalRandom(110, 140)
        self.maxHealth = self.health
        self.moveSpeed = normalRandom(40, 60)  -- 移动慢
        self.attackDamage = normalRandom(8, 12)  -- 单次伤害低
        self.attackRange = normalRandom(110, 140)
        self.attackSpeed = normalRandom(0.3, 0.5)  -- 攻击快
        self.critChance = math.random() * 0.15
        self.dodgeChance = math.random() * 0.1
        self.armor = normalRandom(0.2, 0.35)  -- 高护甲
        self.hasRegen = false
        self.hasBerserk = false
        self.radius = 22  -- 稍大
        
    elseif unitClass == "Tank" then
        -- 坦克兵：超高血量、高护甲、低伤害、慢速
        self.health = normalRandom(160, 200)
        self.maxHealth = self.health
        self.moveSpeed = normalRandom(35, 55)
        self.attackDamage = normalRandom(10, 16)
        self.attackRange = normalRandom(70, 90)
        self.attackSpeed = normalRandom(1.2, 1.6)
        self.critChance = math.random() * 0.1
        self.dodgeChance = math.random() * 0.05
        self.armor = normalRandom(0.35, 0.5)  -- 超高护甲
        self.hasRegen = math.random() < 0.5  -- 50%概率再生
        self.regenRate = normalRandom(3, 6)
        self.hasBerserk = false
        self.radius = 25  -- 大体型
        
    elseif unitClass == "Scout" then
        -- 侦察兵：超高速度、低血量、中等伤害、高闪避
        self.health = normalRandom(50, 70)
        self.maxHealth = self.health
        self.moveSpeed = normalRandom(120, 160)  -- 超快
        self.attackDamage = normalRandom(15, 22)
        self.attackRange = normalRandom(100, 130)
        self.attackSpeed = normalRandom(0.6, 0.9)
        self.critChance = normalRandom(0.25, 0.4)  -- 高暴击
        self.dodgeChance = normalRandom(0.3, 0.5)  -- 超高闪避
        self.armor = 0
        self.hasRegen = false
        self.hasBerserk = false
        self.radius = 14  -- 小体型
        
    elseif unitClass == "Healer" then
        -- 医疗兵：治疗友军、低战斗力
        self.health = normalRandom(70, 90)
        self.maxHealth = self.health
        self.moveSpeed = normalRandom(60, 80)
        self.attackDamage = normalRandom(5, 10)  -- 低攻击
        self.attackRange = normalRandom(80, 100)
        self.attackSpeed = normalRandom(1.5, 2.0)
        self.critChance = 0
        self.dodgeChance = normalRandom(0.15, 0.25)
        self.armor = normalRandom(0.1, 0.2)
        self.hasRegen = true
        self.regenRate = normalRandom(8, 12)  -- 自己高回复
        self.hasBerserk = false
        self.radius = 16
        self.isHealer = true
        self.healRange = 120  -- 治疗范围
        self.healRate = normalRandom(15, 25)  -- 治疗速度
        self.healCooldown = 0
        
    elseif unitClass == "Demolisher" then
        -- 爆破兵：对建筑高伤害、范围伤害
        self.health = normalRandom(100, 130)
        self.maxHealth = self.health
        self.moveSpeed = normalRandom(50, 70)
        self.attackDamage = normalRandom(35, 50)  -- 高伤害
        self.attackRange = normalRandom(60, 80)  -- 短射程
        self.attackSpeed = normalRandom(2.0, 2.5)  -- 攻击慢
        self.critChance = normalRandom(0.2, 0.3)
        self.dodgeChance = normalRandom(0.05, 0.1)
        self.armor = normalRandom(0.15, 0.25)
        self.hasRegen = false
        self.hasBerserk = false
        self.radius = 20
        self.isDemolisher = true
        self.splashRange = 80  -- 溅射范围
        self.baseDamageBonus = 2.0  -- 对基地和建筑2倍伤害
        
    elseif unitClass == "Ranger" then
        -- 游侠：超远射程、移动射击、中等伤害
        self.health = normalRandom(80, 100)
        self.maxHealth = self.health
        self.moveSpeed = normalRandom(80, 110)
        self.attackDamage = normalRandom(18, 28)
        self.attackRange = normalRandom(220, 280)  -- 超远射程
        self.attackSpeed = normalRandom(1.0, 1.4)
        self.critChance = normalRandom(0.3, 0.45)
        self.dodgeChance = normalRandom(0.2, 0.3)
        self.armor = normalRandom(0.05, 0.15)
        self.hasRegen = false
        self.hasBerserk = false
        self.radius = 17
        self.isRanger = true
        self.canMoveAndShoot = true  -- 可以边移动边射击
        
    else  -- Soldier - 普通士兵
        self.health = normalRandom(90, 140)
        self.maxHealth = self.health
        self.moveSpeed = normalRandom(60, 100)
        self.attackDamage = normalRandom(12, 22)
        self.attackRange = normalRandom(80, 130)
        self.attackSpeed = normalRandom(0.7, 1.3)
        self.critChance = math.random() * 0.3
        self.dodgeChance = math.random() * 0.2
        self.armor = math.random() * 0.25
        self.hasRegen = math.random() < 0.35
        self.regenRate = self.hasRegen and normalRandom(2, 5) or 0
        self.hasBerserk = math.random() < 0.3
        self.berserkThreshold = normalRandom(0.25, 0.4)
        self.isBerserk = false
    end
    
    -- 通用属性初始化
    if not self.hasRegen then
        self.regenRate = 0
    end
    if not self.hasBerserk then
        self.berserkThreshold = 0
        self.isBerserk = false
    end
    
    -- 视觉效果
    self.flashTime = 0  -- 受击闪烁
    self.damageNumbers = {}  -- 伤害数字
    self.attackEffect = nil  -- 攻击特效
    self.deathTime = 0  -- 死亡动画时间
    self.isDead = false
    self.regenEffect = 0  -- 恢复特效
    
    -- GOAP相关
    self.planner = Planner.new()
    
    self.actions = {
        FindTarget.new(),
        MoveToEnemy.new(),
        AttackEnemy.new(),
        Idle.new()
    }
    
    -- 暂时禁用Retreat
    -- if Retreat then
    --     table.insert(self.actions, 4, Retreat.new())
    -- end
    
    self.currentPlan = nil
    self.currentAction = nil
    self.currentActionIndex = 1
    
    -- 世界状态
    self.worldState = {
        hasTarget = false,
        inRange = false,
        attacking = false,
        idle = false
    }
    
    -- 目标状态（始终尝试攻击敌人）
    self.goalState = {
        attacking = true  -- 目标是攻击敌人或基地
    }
    
    -- 士气系统
    self.moraleRatio = 1.0  -- 初始满士气
    
    -- 引用
    self.target = nil
    self.enemies = {}
    self.allies = {}
    self.enemyBase = nil  -- 敌方基地引用
    
    return self
end

function Agent:update(dt)
    if self.isDead then
        self.deathTime = self.deathTime + dt
        return
    end
    
    if self.health <= 0 then
        self.isDead = true
        self.deathTime = 0
        return
    end
    
    -- 更新视觉效果
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    if self.attackEffect then
        self.attackEffect.time = self.attackEffect.time + dt
        if self.attackEffect.time > 0.3 then
            self.attackEffect = nil
        end
    end
    
    -- 生命恢复
    if self.hasRegen and self.health < self.maxHealth then
        self.health = math.min(self.maxHealth, self.health + self.regenRate * dt)
        self.regenEffect = (self.regenEffect + dt * 5) % (math.pi * 2)
    end
    
    -- 狂暴状态检查
    if self.hasBerserk and not self.isBerserk then
        if self.health / self.maxHealth < self.berserkThreshold then
            self.isBerserk = true
            -- 狂暴效果有随机性
            local berserkPower = 1.3 + math.random() * 0.4  -- 1.3-1.7倍加成
            self.berserkPower = berserkPower  -- 保存以供信息面板使用
            self.attackDamage = self.attackDamage * berserkPower
            self.attackSpeed = self.attackSpeed * (0.6 + math.random() * 0.2)  -- 攻击更快
            self.moveSpeed = self.moveSpeed * (1.2 + math.random() * 0.3)  -- 移动更快
            print(string.format("[%s] BERSERK MODE! Power: %.1fx", self.team, berserkPower))
            self:addDamageNumber("BERSERK!", {1, 0.5, 0}, true)
        end
    end
    
    -- 更新伤害数字
    for i = #self.damageNumbers, 1, -1 do
        local dmg = self.damageNumbers[i]
        dmg.time = dmg.time + dt
        dmg.y = dmg.y - 30 * dt
        if dmg.time > 1.5 then
            table.remove(self.damageNumbers, i)
        end
    end
    
    -- 矿工特殊逻辑
    if self.isMiner then
        self:updateMinerBehavior(dt)
        return  -- 矿工不使用GOAP系统
    end
    
    -- 更新世界状态
    self:updateWorldState()
    
    -- 碰撞检测和推开
    self:handleCollisions(dt)
    
    -- 如果没有计划或当前行动完成，重新规划
    if not self.currentPlan or self.currentActionIndex > #self.currentPlan then
        self:makePlan()
    end
    
    -- 执行当前行动
    if self.currentPlan and self.currentActionIndex <= #self.currentPlan then
        self.currentAction = self.currentPlan[self.currentActionIndex]
        
        if not self.currentAction then
            print(string.format("[%s] ERROR: currentAction is nil! Index=%d, PlanLength=%d", 
                self.team, self.currentActionIndex, #self.currentPlan))
            self.currentPlan = nil
            return
        end
        
        -- 检查行动的程序性前置条件
        if self.currentAction:checkProceduralPrecondition(self) then
            local completed = self.currentAction:perform(self, dt)
            if completed then
                print(string.format("[%s] Completed action: %s", self.team, self.currentAction.name))
                self.currentActionIndex = self.currentActionIndex + 1
            end
        else
            -- 如果前置条件不满足，重新规划
            print(string.format("[%s] Action %s precondition failed, replanning", self.team, self.currentAction.name))
            self.currentPlan = nil
        end
    else
        -- 没有计划，尝试重新规划
        self:makePlan()
    end
end

-- 处理单位间碰撞
function Agent:handleCollisions(dt)
    -- 与盟友的碰撞
    for _, ally in ipairs(self.allies) do
        if ally ~= self and not ally.isDead and ally.health > 0 then
            local dx = self.x - ally.x
            local dy = self.y - ally.y
            local distance = math.sqrt(dx * dx + dy * dy)
            local minDistance = self.radius + ally.radius
            
            if distance < minDistance and distance > 0 then
                -- 计算推开力
                local overlap = minDistance - distance
                local pushX = (dx / distance) * overlap * 0.5
                local pushY = (dy / distance) * overlap * 0.5
                
                -- 推开双方
                self.x = self.x + pushX
                self.y = self.y + pushY
                ally.x = ally.x - pushX
                ally.y = ally.y - pushY
            end
        end
    end
    
    -- 与敌人的碰撞（轻微推开，防止重叠）
    for _, enemy in ipairs(self.enemies) do
        if not enemy.isDead and enemy.health > 0 then
            local dx = self.x - enemy.x
            local dy = self.y - enemy.y
            local distance = math.sqrt(dx * dx + dy * dy)
            local minDistance = self.radius + enemy.radius
            
            if distance < minDistance and distance > 0 then
                -- 计算推开力（敌人碰撞推力更小）
                local overlap = minDistance - distance
                local pushX = (dx / distance) * overlap * 0.3
                local pushY = (dy / distance) * overlap * 0.3
                
                self.x = self.x + pushX
                self.y = self.y + pushY
            end
        end
    end
    
    -- 边界限制
    self.x = math.max(self.radius, math.min(1200 - self.radius, self.x))
    self.y = math.max(self.radius, math.min(800 - self.radius, self.y))
end

function Agent:updateWorldState()
    -- 更新是否有目标（可以是单位或基地）
    if self.target then
        if self.target == self.enemyBase then
            self.worldState.hasTarget = not self.target.isDead
        else
            self.worldState.hasTarget = (self.target.health > 0)
        end
    else
        self.worldState.hasTarget = false
    end
    
    -- 更新是否在攻击范围内
    if self.target then
        -- 检查目标是否存活
        local targetAlive = false
        if self.target == self.enemyBase then
            targetAlive = not self.target.isDead
        else
            targetAlive = self.target.health > 0
        end
        
        if targetAlive then
            local dx = self.target.x - self.x
            local dy = self.target.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- 基地可以从稍远处攻击
            local attackRange = self.attackRange
            if self.target == self.enemyBase then
                attackRange = attackRange + 30
            end
            
            self.worldState.inRange = (distance <= attackRange)
        else
            self.worldState.inRange = false
            -- 如果目标死亡，清除目标以便寻找新目标
            self.target = nil
            self.worldState.attacking = false
        end
    else
        self.worldState.inRange = false
    end
    
    -- 更新攻击状态（如果在范围内且有目标就认为在攻击）
    self.worldState.attacking = (self.worldState.hasTarget and self.worldState.inRange)
    
    -- 士气系统：根据存活的盟友数量调整能力
    local aliveAllies = 0
    local totalAllies = 0
    for _, ally in ipairs(self.allies) do
        totalAllies = totalAllies + 1
        if ally ~= self and ally.health > 0 and not ally.isDead then
            aliveAllies = aliveAllies + 1
        end
    end
    
    -- 计算并保存士气比率（供draw函数使用）
    self.moraleRatio = totalAllies > 1 and (aliveAllies / (totalAllies - 1)) or 1.0
    
    -- 士气影响：盟友越多，士气越高（1.0 - 1.3倍加成）
    if totalAllies > 1 then
        local moraleBoost = 1.0 + (aliveAllies / (totalAllies - 1)) * 0.3
        -- 暂存原始值以便每次更新
        if not self.baseDamage then
            self.baseDamage = self.attackDamage / (self.isBerserk and 1.5 or 1.0)
        end
        -- 只在非狂暴状态应用士气加成
        if not self.isBerserk then
            local oldDamage = self.attackDamage
            self.attackDamage = self.baseDamage * moraleBoost
            -- 士气变化较大时输出日志
            if math.abs(moraleBoost - 1.0) > 0.15 and not self.lastMoraleLog or 
               math.abs((self.lastMoraleLog or 1.0) - moraleBoost) > 0.1 then
                print(string.format("[%s] Morale: %.0f%% (Allies: %d/%d, DMG: %.1f -> %.1f)", 
                    self.team, self.moraleRatio * 100, aliveAllies, totalAllies - 1,
                    self.baseDamage, self.attackDamage))
                self.lastMoraleLog = moraleBoost
            end
        end
    end
end

function Agent:makePlan()
    local oldPlan = self.currentPlan
    self.currentPlan = self.planner:plan(self.actions, self.worldState, self.goalState)
    self.currentActionIndex = 1
    
    -- 只在计划改变时输出调试信息
    if not oldPlan or not self.currentPlan or 
       (oldPlan and self.currentPlan and #oldPlan ~= #self.currentPlan) then
        if self.currentPlan then
            print(string.format("[%s] New plan with %d actions:", self.team, #self.currentPlan))
            for i, action in ipairs(self.currentPlan) do
                print(string.format("  %d: %s", i, action.name))
            end
        else
            print(string.format("[%s] No plan found! State: hasTarget=%s inRange=%s", 
                self.team, 
                tostring(self.worldState.hasTarget), 
                tostring(self.worldState.inRange)))
        end
    end
end

-- 受到伤害
function Agent:takeDamage(damage, isCrit)
    if self.isDead then return 0 end
    
    -- 闪避判定
    if math.random() < self.dodgeChance then
        self:addDamageNumber("DODGE", {0.5, 1, 0.5}, true)
        return 0
    end
    
    local actualDamage = damage
    if isCrit then
        actualDamage = damage * 2
    end
    
    -- 护甲减免
    actualDamage = actualDamage * (1 - self.armor)
    
    self.health = self.health - actualDamage
    self.flashTime = 0.1
    
    -- 添加伤害数字
    local color = isCrit and {1, 1, 0} or {1, 0.3, 0.3}
    if self.armor > 0.2 then
        color = {0.7, 0.7, 1}  -- 高护甲显示蓝色
    end
    self:addDamageNumber(string.format("%.0f", actualDamage), color, isCrit)
    
    return actualDamage
end

-- 添加伤害数字
function Agent:addDamageNumber(text, color, isCrit)
    table.insert(self.damageNumbers, {
        text = text,
        x = self.x + math.random(-20, 20),
        y = self.y - self.radius - 20,
        time = 0,
        color = color,
        isCrit = isCrit
    })
end

-- 创建攻击特效
function Agent:createAttackEffect(targetX, targetY)
    self.attackEffect = {
        targetX = targetX,
        targetY = targetY,
        time = 0
    }
end

function Agent:draw()
    -- 死亡动画
    if self.isDead then
        local alpha = math.max(0, 1 - self.deathTime * 2)
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha * 0.5)
        local scale = 1 + self.deathTime * 0.5
        love.graphics.circle("fill", self.x, self.y, self.radius * scale)
        return
    end
    
    if self.health <= 0 then
        return
    end
    
    -- 使用之前计算好的士气比率，如果没有则默认为1.0
    local moraleRatio = self.moraleRatio or 1.0
    
    -- 绘制攻击范围圈（半透明，士气影响透明度）
    if self.currentAction and self.currentAction.name == "AttackEnemy" then
        local rangeAlpha = 0.1 * (0.5 + moraleRatio * 0.5)
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], rangeAlpha)
        love.graphics.circle("fill", self.x, self.y, self.attackRange)
    end
    
    -- 绘制攻击特效
    if self.attackEffect then
        local progress = self.attackEffect.time / 0.3
        local alpha = 1 - progress
        love.graphics.setColor(1, 1, 0, alpha)
        love.graphics.setLineWidth(3)
        love.graphics.line(self.x, self.y, self.attackEffect.targetX, self.attackEffect.targetY)
        love.graphics.setLineWidth(1)
        
        -- 攻击冲击波
        love.graphics.circle("line", self.attackEffect.targetX, self.attackEffect.targetY, progress * 30)
    end
    
    -- 受击闪烁效果
    local bodyColor = self.color
    if self.flashTime > 0 then
        bodyColor = {1, 1, 1}
    end
    
    -- 士气影响：低士气时身体颜色变暗
    local moraleColorMod = 0.6 + moraleRatio * 0.4
    
    -- 狂暴状态发光
    if self.isBerserk then
        local pulse = 0.3 + math.sin(love.timer.getTime() * 10) * 0.2
        love.graphics.setColor(1, 0.2, 0, pulse)
        love.graphics.circle("fill", self.x, self.y, self.radius + 5)
        bodyColor = {
            math.min(1, bodyColor[1] + 0.3),
            bodyColor[2] * 0.7,
            bodyColor[3] * 0.7
        }
    else
        -- 非狂暴状态才应用士气颜色影响
        bodyColor = {
            bodyColor[1] * moraleColorMod,
            bodyColor[2] * moraleColorMod,
            bodyColor[3] * moraleColorMod
        }
    end
    
    -- 生命恢复光环
    if self.hasRegen and self.health < self.maxHealth then
        love.graphics.setColor(0, 1, 0, 0.3)
        local regenSize = self.radius + math.sin(self.regenEffect) * 3
        love.graphics.circle("line", self.x, self.y, regenSize)
    end
    
    -- 绘制身体（圆圈）
    love.graphics.setColor(bodyColor)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    
    -- 绘制边框
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", self.x, self.y, self.radius)
    
    -- 绘制兵种标识
    love.graphics.setColor(1, 1, 1)
    local classSymbol = ""
    if self.unitClass == "Sniper" then
        classSymbol = "S"
    elseif self.unitClass == "Gunner" then
        classSymbol = "G"
    elseif self.unitClass == "Tank" then
        classSymbol = "T"
    end
    if classSymbol ~= "" then
        love.graphics.print(classSymbol, self.x - 5, self.y - 7, 0, 1, 1)
    end
    
    -- 绘制方向线
    love.graphics.setColor(0, 0, 0)
    local lineLength = self.radius * 1.5
    local endX = self.x + math.cos(self.angle) * lineLength
    local endY = self.y + math.sin(self.angle) * lineLength
    love.graphics.line(self.x, self.y, endX, endY)
    
    -- 绘制血条
    local barWidth = self.radius * 2
    local barHeight = 5
    local barX = self.x - barWidth / 2
    local barY = self.y - self.radius - 10
    
    -- 血条背景
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    -- 当前血量
    local healthPercent = self.health / self.maxHealth
    if healthPercent > 0.6 then
        love.graphics.setColor(0, 1, 0)
    elseif healthPercent > 0.3 then
        love.graphics.setColor(1, 1, 0)
    else
        love.graphics.setColor(1, 0, 0)
    end
    love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
    
    -- 士气条（在血条下方）
    local moraleBarY = barY + barHeight + 2
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, moraleBarY, barWidth, 3)
    
    -- 士气颜色渐变：红->黄->绿
    local moraleColor
    if moraleRatio > 0.7 then
        moraleColor = {0, 1, 0}  -- 绿色（高士气）
    elseif moraleRatio > 0.4 then
        moraleColor = {1, 1, 0}  -- 黄色（中等）
    else
        moraleColor = {1, 0.3, 0}  -- 橙红色（低士气）
    end
    love.graphics.setColor(moraleColor)
    love.graphics.rectangle("fill", barX, moraleBarY, barWidth * moraleRatio, 3)
    
    -- 绘制伤害数字
    for _, dmg in ipairs(self.damageNumbers) do
        local alpha = 1 - (dmg.time / 1.5)
        love.graphics.setColor(dmg.color[1], dmg.color[2], dmg.color[3], alpha)
        local scale = dmg.isCrit and 1.5 or 1
        love.graphics.print(dmg.text, dmg.x, dmg.y, 0, scale, scale)
    end
    
    -- 绘制护甲外圈（如果有高护甲）
    if self.armor > 0.2 then
        love.graphics.setColor(0.5, 0.5, 1, 0.4)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", self.x, self.y, self.radius + 3)
        love.graphics.setLineWidth(1)
    end
    
    -- 绘制狂暴光环
    if self.isBerserk then
        local pulse = 5 + math.sin(love.timer.getTime() * 15) * 2
        love.graphics.setColor(1, 0.3, 0, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", self.x, self.y, self.radius + pulse)
        love.graphics.setLineWidth(1)
    end
    
    -- 绘制再生标识（小绿点在身体上闪烁）
    if self.hasRegen then
        local alpha = 0.5 + math.sin(love.timer.getTime() * 6) * 0.3
        love.graphics.setColor(0, 1, 0, alpha)
        love.graphics.circle("fill", self.x, self.y - self.radius + 5, 3)
    end
    
    -- 矿工特殊显示
    if self.isMiner then
        -- 显示到目标资源的连线（采集中）
        if self.targetResource and not self.returningToBase then
            local dx = self.targetResource.x - self.x
            local dy = self.targetResource.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance <= self.miningRange then
                -- 正在采集，显示绿色连线
                love.graphics.setColor(0, 1, 0, 0.4)
                love.graphics.setLineWidth(2)
                love.graphics.line(self.x, self.y, self.targetResource.x, self.targetResource.y)
                love.graphics.setLineWidth(1)
                
                -- 采集动画（粒子效果）
                local t = love.timer.getTime()
                for i = 1, 3 do
                    local progress = (t * 2 + i * 0.3) % 1
                    local px = self.x + (self.targetResource.x - self.x) * progress
                    local py = self.y + (self.targetResource.y - self.y) * progress
                    love.graphics.setColor(1, 0.84, 0, 1 - progress)
                    love.graphics.circle("fill", px, py, 3)
                end
            else
                -- 正在移动到资源，显示半透明线
                love.graphics.setColor(0.5, 0.5, 0.5, 0.2)
                love.graphics.setLineWidth(1)
                love.graphics.line(self.x, self.y, self.targetResource.x, self.targetResource.y)
            end
        end
        
        -- 返回基地时显示箭头
        if self.returningToBase and self.myBase then
            love.graphics.setColor(0, 0.5, 1, 0.3)
            love.graphics.setLineWidth(1)
            love.graphics.line(self.x, self.y, self.myBase.x, self.myBase.y)
        end
        
        -- 显示携带的资源
        if self.carriedResources > 0 then
            love.graphics.setColor(1, 0.84, 0, 0.8)
            love.graphics.circle("fill", self.x + self.radius - 5, self.y - self.radius + 5, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(tostring(math.floor(self.carriedResources)), 
                self.x + self.radius + 2, self.y - self.radius, 0, 0.6, 0.6)
        end
        
        -- 矿工图标（十字镐）
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.line(self.x - 3, self.y, self.x + 3, self.y)
        love.graphics.line(self.x, self.y - 3, self.x, self.y + 3)
    end
end

-- 矿工行为更新
function Agent:updateMinerBehavior(dt)
    -- 碰撞检测
    self:handleCollisions(dt)
    
    -- 如果满载，返回基地
    if self.carriedResources >= self.carryCapacity then
        self.returningToBase = true
        self.targetResource = nil
    end
    
    if self.returningToBase then
        -- 移动到基地
        if self.myBase then
            local dx = self.myBase.x - self.x
            local dy = self.myBase.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < 60 then
                -- 到达基地，卸载资源
                self.myBase.resources = math.min(self.myBase.maxResources, 
                    self.myBase.resources + self.carriedResources)
                self.myBase.minerBonus = (self.myBase.minerBonus or 0)  -- 确保有值
                self.carriedResources = 0
                self.returningToBase = false
            else
                -- 移动向基地
                local angle = math.atan2(dy, dx)
                self.x = self.x + math.cos(angle) * self.moveSpeed * dt
                self.y = self.y + math.sin(angle) * self.moveSpeed * dt
                self.angle = angle
            end
        end
    else
        -- 寻找并采集资源
        if not self.targetResource or self.targetResource.depleted then
            -- 寻找最近的资源点
            local nearestResource = nil
            local nearestDist = math.huge
            
            if self.resources then
                for _, resource in ipairs(self.resources) do
                    if not resource.depleted then
                        local dx = resource.x - self.x
                        local dy = resource.y - self.y
                        local dist = math.sqrt(dx * dx + dy * dy)
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestResource = resource
                        end
                    end
                end
            end
            
            self.targetResource = nearestResource
        end
        
        if self.targetResource then
            local dx = self.targetResource.x - self.x
            local dy = self.targetResource.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance <= self.miningRange then
                -- 必须在范围内才能采集资源
                local mined = self.targetResource:mine(self.miningRate * dt)
                self.carriedResources = math.min(self.carryCapacity, self.carriedResources + mined)
                
                -- 停止移动，面向资源点
                self.angle = math.atan2(dy, dx)
            else
                -- 距离太远，移动到资源点
                local angle = math.atan2(dy, dx)
                self.x = self.x + math.cos(angle) * self.moveSpeed * dt
                self.y = self.y + math.sin(angle) * self.moveSpeed * dt
                self.angle = angle
            end
        end
    end
end

return Agent
