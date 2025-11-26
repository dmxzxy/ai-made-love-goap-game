-- 战斗单位
local Planner = require("goap.planner")
local FindTarget = require("actions.find_target")
local MoveToEnemy = require("actions.move_to_enemy")
local AttackEnemy = require("actions.attack_enemy")
local Idle = require("actions.idle")
-- 暂时禁用Retreat以确保游戏稳定运行
-- local Retreat = require("actions.retreat")

-- 延迟加载特效系统（避免循环依赖）
local Particles, DamageNumbers

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
        self.radius = 18  -- 标准大小
        self.isMiner = true
        self.miningRate = normalRandom(6, 9)  -- 每秒采集速度（4-6→6-9）
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
        self.radius = 19  -- 稍小但可见
        
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
        self.radius = 22  -- 中等偏大
        
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
        self.radius = 28  -- 大体型，更易识别
        
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
        self.radius = 16  -- 小巧快速
        
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
    
    -- 侦查系统
    self.visionRange = 300  -- 基础视野范围
    if unitClass == "Scout" then
        self.visionRange = 500  -- 侦察兵视野更远
    elseif unitClass == "Sniper" or unitClass == "Ranger" then
        self.visionRange = 400  -- 远程单位视野较远
    elseif unitClass == "Miner" then
        self.visionRange = 250  -- 矿工视野较短
    end
    self.discoveredEnemies = {}  -- 已发现的敌人列表
    self.lastDiscoveryTime = 0  -- 上次发现敌人的时间
    
    -- 升级系统（老兵特效）
    self.kills = 0          -- 击杀数
    self.level = 1          -- 等级（1-5）
    self.experience = 0     -- 经验值
    self.expForNextLevel = 3  -- 下一级所需经验
    self.levelUpEffect = 0  -- 升级特效时间
    
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
    self.enemyTowers = {}  -- 敌方防御塔引用
    
    -- 战斗反应系统
    self.lastAttacker = nil  -- 最后一个攻击我的敌人
    self.lastAttackedTime = 0  -- 上次被攻击的时间
    self.aggroRadius = 350  -- 仇恨范围（200→350，更大的视野）
    
    -- 减速效果
    self.slowedUntil = 0
    self.originalSpeed = nil
    self.isFrozen = false
    
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
        
        -- 死亡特效
        if not Particles then
            Particles = require("effects.particles")
        end
        Particles.createDeathExplosion(self.x, self.y, self.color, self.radius / 20)
        Particles.createSmoke(self.x, self.y, {0.3, 0.3, 0.3}, 8)
        addCameraShake(2)
        
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
    
    -- 升级特效倒计时
    if self.levelUpEffect > 0 then
        self.levelUpEffect = self.levelUpEffect - dt
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
    
    -- 检查减速效果是否结束
    if self.slowedUntil > 0 and love.timer.getTime() > self.slowedUntil then
        if self.originalSpeed then
            self.moveSpeed = self.originalSpeed
            self.originalSpeed = nil
        end
        self.slowedUntil = 0
        self.isFrozen = false
    end
    
    -- 矿工特殊逻辑
    if self.isMiner then
        self:updateMinerBehavior(dt)
        return  -- 矿工不使用GOAP系统
    end
    
    -- 侦查系统：扫描视野范围内的敌人
    if not self.isMiner then
        self:updateVision()
    end
    
    -- 初始化卡住检测变量
    if not self.stuckCheckTimer then
        self.stuckCheckTimer = 0
        self.lastStuckCheckPos = {x = self.x, y = self.y}
        self.consecutiveStuckChecks = 0
    end
    
    -- 卡住检测：每0.5秒检查一次位置
    self.stuckCheckTimer = self.stuckCheckTimer + dt
    if self.stuckCheckTimer >= 0.5 then
        local dx = self.x - self.lastStuckCheckPos.x
        local dy = self.y - self.lastStuckCheckPos.y
        local moveDist = math.sqrt(dx * dx + dy * dy)
        
        -- 如果有目标但移动距离很小（< 5像素），认为可能卡住
        if self.target and moveDist < 5 and not self.isAttacking then
            self.consecutiveStuckChecks = self.consecutiveStuckChecks + 1
            
            -- 连续3次检测到卡住（1.5秒），强制重新选择目标
            if self.consecutiveStuckChecks >= 3 then
                print(string.format("[%s %s] Stuck detected! Switching target...", self.team, self.unitClass))
                self:reevaluateTarget()
                self.consecutiveStuckChecks = 0  -- 重置计数
                self.currentPlan = nil  -- 重新规划
            end
        else
            self.consecutiveStuckChecks = 0  -- 移动正常，重置计数
        end
        
        -- 更新检查位置
        self.lastStuckCheckPos.x = self.x
        self.lastStuckCheckPos.y = self.y
        self.stuckCheckTimer = 0
    end
    
    -- 战斗反应：被攻击时立即反击（更强的反应）
    if self.lastAttacker and (love.timer.getTime() - self.lastAttackedTime < 3) then
        if not self.lastAttacker.isDead and self.lastAttacker.health > 0 then
            local dx = self.lastAttacker.x - self.x
            local dy = self.lastAttacker.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            -- 攻击者在范围内
            if dist <= self.aggroRadius then
                -- 如果没有目标，立即反击
                if not self.target or self.target.isDead or self.target.health <= 0 then
                    self.target = self.lastAttacker
                    self.currentPlan = nil
                    print(string.format("[%s %s] Counter-attacking attacker!", self.team, self.unitClass))
                else
                    -- 即使有目标，如果攻击者更近，也切换目标
                    local currentDx = self.target.x - self.x
                    local currentDy = self.target.y - self.y
                    local currentDist = math.sqrt(currentDx * currentDx + currentDy * currentDy)
                    
                    -- 攻击者比当前目标近80px以上，立即切换
                    if dist < currentDist - 80 then
                        self.target = self.lastAttacker
                        self.currentPlan = nil
                        print(string.format("[%s %s] Switching to closer attacker! (%.0f < %.0f)", 
                            self.team, self.unitClass, dist, currentDist))
                    end
                end
            end
        end
    end
    
    -- 实时目标重新评估：更频繁检查（每0.8秒）
    self.targetReevalTimer = (self.targetReevalTimer or 0) + dt
    if self.targetReevalTimer >= 0.8 then  -- 从1.5秒改为0.8秒，更快响应
        self.targetReevalTimer = 0
        self:reevaluateTarget()
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
    local totalPushX = 0
    local totalPushY = 0
    local collisionCount = 0
    
    -- 与盟友的碰撞（更强的推力）
    for _, ally in ipairs(self.allies) do
        if ally ~= self and not ally.isDead and ally.health > 0 then
            local dx = self.x - ally.x
            local dy = self.y - ally.y
            local distance = math.sqrt(dx * dx + dy * dy)
            local minDistance = self.radius + ally.radius + 5  -- 增加最小间距
            
            if distance < minDistance and distance > 0 then
                -- 计算推开力（提高推力）
                local overlap = minDistance - distance
                local pushStrength = 1.2  -- 从0.5提高到1.2
                local pushX = (dx / distance) * overlap * pushStrength
                local pushY = (dy / distance) * overlap * pushStrength
                
                -- 累积推力
                totalPushX = totalPushX + pushX
                totalPushY = totalPushY + pushY
                collisionCount = collisionCount + 1
                
                -- 也推开盟友（互相推）
                if not ally.isAttacking then  -- 攻击中的单位不被推动
                    ally.x = ally.x - pushX * 0.5
                    ally.y = ally.y - pushY * 0.5
                end
            end
        end
    end
    
    -- 与敌人的碰撞（中等推力）
    for _, enemy in ipairs(self.enemies) do
        if not enemy.isDead and enemy.health > 0 then
            local dx = self.x - enemy.x
            local dy = self.y - enemy.y
            local distance = math.sqrt(dx * dx + dy * dy)
            local minDistance = self.radius + enemy.radius + 3
            
            if distance < minDistance and distance > 0 then
                -- 计算推开力
                local overlap = minDistance - distance
                local pushStrength = 0.8  -- 从0.3提高到0.8
                local pushX = (dx / distance) * overlap * pushStrength
                local pushY = (dy / distance) * overlap * pushStrength
                
                totalPushX = totalPushX + pushX
                totalPushY = totalPushY + pushY
                collisionCount = collisionCount + 1
            end
        end
    end
    
    -- 应用累积的推力
    if collisionCount > 0 then
        self.x = self.x + totalPushX
        self.y = self.y + totalPushY
        
        -- 如果碰撞太多，标记为拥堵
        if collisionCount >= 4 then
            self.isCrowded = true
            self.crowdedTimer = (self.crowdedTimer or 0) + dt
        else
            self.isCrowded = false
            self.crowdedTimer = 0
        end
    else
        self.isCrowded = false
        self.crowdedTimer = 0
    end
    
    -- 无边界限制 - 单位可以移动到任何位置
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

-- 重新评估目标：选择最优目标
function Agent:reevaluateTarget()
    if self.isMiner then return end  -- 矿工不参与战斗
    
    local bestTarget = nil
    local bestScore = -math.huge
    local currentDist = math.huge
    
    -- 如果有当前目标，计算距离
    if self.target and not self.target.isDead and self.target.health > 0 then
        local dx = self.target.x - self.x
        local dy = self.target.y - self.y
        currentDist = math.sqrt(dx * dx + dy * dy)
    else
        self.target = nil  -- 清除无效目标
    end
    
    -- 评估所有敌方单位
    for _, enemy in ipairs(self.enemies) do
        if not enemy.isDead and enemy.health > 0 then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            -- 只考虑合理范围内的目标（攻击范围的3倍）
            if dist <= self.aggroRadius then
                -- 计算目标优先级分数
                local score = 0
                
                -- 1. 距离因素（越近越好）- 大幅提高权重
                local distScore = 1000 / (dist + 10)
                score = score + distScore * 3.5  -- 从2.5提高到3.5，让距离影响更大
                
                -- 2. 极近目标加成 - 100px内的目标获得额外分数
                if dist < 100 then
                    score = score + 150  -- 新增：非常近的目标高优先级
                elseif dist < 200 then
                    score = score + 80   -- 新增：较近的目标中等加成
                end
                
                -- 3. 血量因素（优先攻击残血目标）
                local hpPercent = enemy.health / enemy.maxHealth
                if hpPercent < 0.3 then
                    score = score + 80  -- 残血目标高优先级
                elseif hpPercent < 0.5 then
                    score = score + 40
                end
                
                -- 4. 单位类型优先级
                if enemy.unitClass == "Healer" then
                    score = score + 100  -- 优先击杀治疗
                elseif enemy.unitClass == "Sniper" then
                    score = score + 70  -- 优先击杀狙击手
                elseif enemy.unitClass == "Miner" then
                    score = score + 30  -- 矿工次优先
                end
                
                -- 5. 威胁等级（高攻击力的敌人）
                if enemy.attackDamage > 20 then
                    score = score + 50
                end
                
                -- 6. 当前目标粘性（降低粘性，让切换更容易）
                if self.target == enemy then
                    score = score + 40  -- 从60降低到40，减少切换阻力
                end
                
                -- 7. 正在攻击我的敌人优先级大幅提高
                if enemy == self.lastAttacker then
                    score = score + 180  -- 从100提高到180，更积极反击
                end
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = enemy
                end
            end
        end
    end
    
    -- 评估敌方防御塔（当它们构成威胁时）
    if self.enemyTowers then
        for _, tower in ipairs(self.enemyTowers) do
            if not tower.isDead and tower.health > 0 then
                local dx = tower.x - self.x
                local dy = tower.y - self.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                -- 只考虑一定范围内的防御塔
                if dist <= self.aggroRadius * 1.5 then
                    local score = 0
                    
                    -- 1. 距离因素 - 更近的塔更危险
                    local distScore = 800 / (dist + 10)
                    score = score + distScore * 2.0
                    
                    -- 2. 塔的威胁等级 - 根据塔的类型和伤害
                    local towerThreat = tower.damage or 10
                    score = score + towerThreat * 2
                    
                    -- 3. 塔的血量 - 优先攻击残血的塔
                    local hpPercent = tower.health / tower.maxHealth
                    if hpPercent < 0.3 then
                        score = score + 120  -- 残血塔高优先级
                    elseif hpPercent < 0.5 then
                        score = score + 60
                    end
                    
                    -- 4. 如果塔在射程内且正在威胁自己，提高优先级
                    if dist <= (tower.range or 200) + 50 then
                        score = score + 150  -- 在塔的射程内，优先拆塔
                    end
                    
                    -- 5. 当前目标粘性
                    if self.target == tower then
                        score = score + 80  -- 继续攻击当前塔
                    end
                    
                    -- 6. 塔的优先级适中 - 低于敌军，但高于基地
                    score = score * 0.7  -- 塔的优先级低于敌军
                    
                    if score > bestScore then
                        bestScore = score
                        bestTarget = tower
                    end
                end
            end
        end
    end
    
    -- 评估敌方基地（优先级最低，只有在没有更好目标时才攻击）
    if self.enemyBases then
        for _, enemyBase in ipairs(self.enemyBases) do
            if not enemyBase.isDead then
                local dx = enemyBase.x - self.x
                local dy = enemyBase.y - self.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                -- 基地基础分数极低
                local score = 200 / (dist + 100)  -- 大幅降低基础分数
                
                -- 检查附近是否有敌军或防御塔
                local nearbyEnemies = 0
                local nearbyTowers = 0
                
                -- 检查敌军
                for _, enemy in ipairs(self.enemies) do
                    if not enemy.isDead and enemy.health > 0 then
                        local ex = enemy.x - self.x
                        local ey = enemy.y - self.y
                        local edist = math.sqrt(ex * ex + ey * ey)
                        if edist < 400 then  -- 扩大检查范围
                            nearbyEnemies = nearbyEnemies + 1
                        end
                    end
                end
                
                -- 检查防御塔
                if self.enemyTowers then
                    for _, tower in ipairs(self.enemyTowers) do
                        if not tower.isDead and tower.health > 0 then
                            local tx = tower.x - self.x
                            local ty = tower.y - self.y
                            local tdist = math.sqrt(tx * tx + ty * ty)
                            if tdist < 400 then
                                nearbyTowers = nearbyTowers + 1
                            end
                        end
                    end
                end
                
                -- 只有在附近既没有敌军也没有塔时，才考虑攻击基地
                if nearbyEnemies == 0 and nearbyTowers == 0 then
                    score = score + 80  -- 即使加成后，分数仍然很低
                else
                    -- 附近有威胁时，基地优先级极低
                    score = score * 0.3
                end
                
                -- 如果正在攻击基地，给予一些粘性（避免频繁切换）
                if self.target == enemyBase then
                    score = score + 30
                end
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = enemyBase
                end
            end
        end
    end
    
    -- 如果找到了更好的目标，切换目标
    if bestTarget and bestTarget ~= self.target then
        local oldTarget = self.target
        self.target = bestTarget
        self.currentPlan = nil  -- 重新规划路径
        
        -- 输出目标切换信息，区分不同的目标类型
        local targetType = "Unknown"
        if bestTarget.unitClass then
            targetType = bestTarget.unitClass
        elseif bestTarget.towerType then
            targetType = "Tower-" .. bestTarget.towerType
        elseif bestTarget.isBase then
            targetType = "BASE"
        end
        
        local dx = bestTarget.x - self.x
        local dy = bestTarget.y - self.y
        local newDist = math.sqrt(dx * dx + dy * dy)
        
        print(string.format("[%s %s] Target switch: %s (dist:%.0f score:%.1f)", 
            self.team, self.unitClass, targetType, newDist, bestScore))
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
function Agent:takeDamage(damage, isCrit, attacker)
    if self.isDead then return 0 end
    
    -- 延迟加载特效系统
    if not Particles then
        Particles = require("effects.particles")
        DamageNumbers = require("effects.damage_numbers")
    end
    
    -- 记录攻击者（用于反击）
    if attacker and not self.isMiner then
        self.lastAttacker = attacker
        self.lastAttackedTime = love.timer.getTime()
    end
    
    -- 闪避判定
    if math.random() < self.dodgeChance then
        self:addDamageNumber("DODGE", {0.5, 1, 0.5}, true)
        Particles.createHitEffect(self.x, self.y - self.radius, {0.5, 1, 0.5})
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
    
    -- 检查是否被击杀
    if self.health <= 0 and attacker and not attacker.isDead then
        attacker:addKill()  -- 攻击者获得击杀奖励
    end
    
    -- 创建击中特效
    if isCrit then
        Particles.createSparks(self.x, self.y, {1, 0.9, 0.3}, 12)
        addCameraShake(3)  -- 暴击震动
    else
        Particles.createBloodSplatter(self.x, self.y, self.color)
        Particles.createHitEffect(self.x, self.y - self.radius, {1, 0.8, 0.3})
    end
    
    return actualDamage
end

-- 添加伤害数字
function Agent:addDamageNumber(text, color, isCrit)
    -- 延迟加载特效系统
    if not DamageNumbers then
        DamageNumbers = require("effects.damage_numbers")
    end
    
    -- 使用新的伤害数字系统
    local damage = tonumber(text) or 0
    DamageNumbers.add(self.x, self.y - self.radius, damage, isCrit, false)
    
    -- 保留旧系统作为备份
    table.insert(self.damageNumbers, {
        text = text,
        x = self.x + math.random(-20, 20),
        y = self.y - self.radius - 20,
        time = 0,
        color = color,
        isCrit = isCrit
    })
end

-- 击杀奖励（升级系统）
function Agent:addKill()
    self.kills = self.kills + 1
    self.experience = self.experience + 1
    
    -- 检查升级
    if self.experience >= self.expForNextLevel and self.level < 5 then
        self:levelUp()
    end
end

-- 升级
function Agent:levelUp()
    self.level = self.level + 1
    self.experience = 0
    self.expForNextLevel = self.expForNextLevel + 2  -- 每级需要更多经验
    
    -- 升级特效
    self.levelUpEffect = 1.5  -- 1.5秒升级特效
    
    -- 属性提升（10%全属性）
    local boost = 1.1
    self.maxHealth = self.maxHealth * boost
    self.health = self.maxHealth  -- 升级回满血
    self.attackDamage = self.attackDamage * boost
    self.moveSpeed = self.moveSpeed * boost
    self.attackRange = self.attackRange * 1.05  -- 射程提升5%
    
    -- 半径增大（视觉效果）
    self.radius = self.radius * 1.05
    
    -- 创建升级特效
    if not Particles then
        Particles = require("effects.particles")
    end
    Particles.createEnergyPulse(self.x, self.y, {1, 1, 0.3}, 5)
    Particles.createEnergyPulse(self.x, self.y, self.color, 8)
    addCameraShake(1)
    
    -- 触发升级通知
    if BattleNotifications then
        BattleNotifications.unitLeveledUp(self.team, self.unitClass, self.level)
    end
    
    print(string.format("[%s] LEVEL UP! %s reached Level %d (Kills: %d)", 
        self.team, self.unitClass, self.level, self.kills))
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
    
    -- 移动摇摆动画
    local bobOffset = 0
    local time = love.timer.getTime()
    if self.currentAction and self.currentAction.name == "MoveToEnemy" then
        bobOffset = math.sin(time * 8) * 3  -- 上下摇摆
    end
    
    -- 升级特效（金色光环）
    if self.levelUpEffect > 0 then
        local effectAlpha = self.levelUpEffect / 1.5
        local pulse = 0.7 + math.sin(time * 15) * 0.3
        
        -- 外层爆发光环
        love.graphics.setColor(1, 1, 0.3, effectAlpha * 0.4 * pulse)
        love.graphics.circle("fill", self.x, self.y + bobOffset, self.radius * (2.5 - effectAlpha))
        
        -- 中层闪光
        love.graphics.setColor(1, 0.9, 0.5, effectAlpha * 0.6)
        love.graphics.circle("fill", self.x, self.y + bobOffset, self.radius * (1.8 - effectAlpha * 0.5))
        
        -- 旋转星星（等级标识）
        for i = 1, self.level do
            local angle = (i / self.level) * math.pi * 2 + time * 3
            local dist = self.radius * 2.5
            local sx = self.x + math.cos(angle) * dist
            local sy = self.y + bobOffset + math.sin(angle) * dist
            love.graphics.setColor(1, 1, 0, effectAlpha)
            love.graphics.circle("fill", sx, sy, 3)
        end
    end
    
    -- 等级光环（常驻，老兵发光）
    if self.level > 1 then
        local levelColor = {
            [2] = {0.8, 1, 0.8},    -- 2级：淡绿
            [3] = {0.8, 0.8, 1},    -- 3级：淡蓝
            [4] = {1, 0.8, 1},      -- 4级：淡紫
            [5] = {1, 1, 0.5}       -- 5级：金色
        }
        local color = levelColor[self.level] or {1, 1, 1}
        local pulse = 0.3 + math.sin(time * 4) * 0.2
        love.graphics.setColor(color[1], color[2], color[3], pulse)
        love.graphics.circle("line", self.x, self.y + bobOffset, self.radius + 4)
        love.graphics.circle("line", self.x, self.y + bobOffset, self.radius + 6)
    end
    
    -- 绘制攻击范围圈（半透明，士气影响透明度）
    if self.currentAction and self.currentAction.name == "AttackEnemy" then
        local rangeAlpha = 0.1 * (0.5 + moraleRatio * 0.5)
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], rangeAlpha)
        love.graphics.circle("fill", self.x, self.y + bobOffset, self.attackRange)
    end
    
    -- 绘制攻击特效（增强版）
    if self.attackEffect then
        local progress = self.attackEffect.time / 0.3
        local alpha = 1 - progress
        
        -- 攻击闪光线
        love.graphics.setColor(1, 1, 0.3, alpha * 0.6)
        love.graphics.setLineWidth(5)
        love.graphics.line(self.x, self.y + bobOffset, self.attackEffect.targetX, self.attackEffect.targetY)
        love.graphics.setColor(1, 0.8, 0.2, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(self.x, self.y + bobOffset, self.attackEffect.targetX, self.attackEffect.targetY)
        love.graphics.setLineWidth(1)
        
        -- 攻击冲击波
        love.graphics.setColor(1, 0.8, 0.2, alpha * 0.5)
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
        local pulse = 0.3 + math.sin(time * 10) * 0.2
        love.graphics.setColor(1, 0.2, 0, pulse)
        love.graphics.circle("fill", self.x, self.y + bobOffset, self.radius + 5)
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
    
    -- 绘制身体（根据兵种使用不同形状）
    love.graphics.setColor(bodyColor)
    
    if self.unitClass == "Tank" then
        -- 坦克：方形
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.angle)
        love.graphics.rectangle("fill", -self.radius, -self.radius, self.radius * 2, self.radius * 2)
        love.graphics.pop()
    elseif self.unitClass == "Sniper" or self.unitClass == "Ranger" then
        -- 狙击手/游侠：细长菱形
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.angle)
        love.graphics.polygon("fill",
            self.radius * 1.3, 0,
            0, -self.radius * 0.6,
            -self.radius * 0.8, 0,
            0, self.radius * 0.6)
        love.graphics.pop()
    elseif self.unitClass == "Scout" then
        -- 侦察兵：三角形
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.angle)
        love.graphics.polygon("fill",
            self.radius * 1.2, 0,
            -self.radius * 0.8, -self.radius,
            -self.radius * 0.8, self.radius)
        love.graphics.pop()
    elseif self.unitClass == "Healer" then
        -- 医疗兵：十字形（圆圈+十字）
        love.graphics.circle("fill", self.x, self.y, self.radius * 0.8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(4)
        love.graphics.line(self.x - self.radius * 0.6, self.y, self.x + self.radius * 0.6, self.y)
        love.graphics.line(self.x, self.y - self.radius * 0.6, self.x, self.y + self.radius * 0.6)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(bodyColor)
    elseif self.unitClass == "Demolisher" then
        -- 爆破兵：六边形
        local sides = 6
        local vertices = {}
        for i = 0, sides - 1 do
            local angle = (i / sides) * math.pi * 2
            table.insert(vertices, self.x + math.cos(angle) * self.radius)
            table.insert(vertices, self.y + math.sin(angle) * self.radius)
        end
        love.graphics.polygon("fill", vertices)
    elseif self.unitClass == "Gunner" then
        -- 机枪手：八边形
        local sides = 8
        local vertices = {}
        for i = 0, sides - 1 do
            local angle = (i / sides) * math.pi * 2
            table.insert(vertices, self.x + math.cos(angle) * self.radius)
            table.insert(vertices, self.y + math.sin(angle) * self.radius)
        end
        love.graphics.polygon("fill", vertices)
    else
        -- 士兵/矿工：标准圆形
        love.graphics.circle("fill", self.x, self.y, self.radius)
    end
    
    -- 绘制边框
    love.graphics.setColor(0, 0, 0)
    if self.unitClass == "Tank" then
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.angle)
        love.graphics.rectangle("line", -self.radius, -self.radius, self.radius * 2, self.radius * 2)
        love.graphics.pop()
    elseif self.unitClass == "Sniper" or self.unitClass == "Ranger" then
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.angle)
        love.graphics.polygon("line",
            self.radius * 1.3, 0,
            0, -self.radius * 0.6,
            -self.radius * 0.8, 0,
            0, self.radius * 0.6)
        love.graphics.pop()
    elseif self.unitClass == "Scout" then
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.angle)
        love.graphics.polygon("line",
            self.radius * 1.2, 0,
            -self.radius * 0.8, -self.radius,
            -self.radius * 0.8, self.radius)
        love.graphics.pop()
    elseif self.unitClass == "Healer" then
        love.graphics.circle("line", self.x, self.y, self.radius * 0.8)
    elseif self.unitClass == "Demolisher" then
        local sides = 6
        local vertices = {}
        for i = 0, sides - 1 do
            local angle = (i / sides) * math.pi * 2
            table.insert(vertices, self.x + math.cos(angle) * self.radius)
            table.insert(vertices, self.y + math.sin(angle) * self.radius)
        end
        love.graphics.polygon("line", vertices)
    elseif self.unitClass == "Gunner" then
        local sides = 8
        local vertices = {}
        for i = 0, sides - 1 do
            local angle = (i / sides) * math.pi * 2
            table.insert(vertices, self.x + math.cos(angle) * self.radius)
            table.insert(vertices, self.y + math.sin(angle) * self.radius)
        end
        love.graphics.polygon("line", vertices)
    else
        love.graphics.circle("line", self.x, self.y, self.radius)
    end
    
    -- 绘制方向指示器（武器/炮管）
    if not self.isMiner then
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.rotate(self.angle)
        
        if self.unitClass == "Tank" then
            -- 坦克炮管
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", 0, -4, self.radius + 8, 8)
        elseif self.unitClass == "Sniper" or self.unitClass == "Ranger" then
            -- 狙击枪
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.setLineWidth(2)
            love.graphics.line(0, 0, self.radius + 10, 0)
            love.graphics.setLineWidth(1)
        elseif self.unitClass == "Gunner" then
            -- 机枪
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", 0, -3, self.radius + 5, 6)
        else
            -- 标准武器
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.rectangle("fill", 0, -2, self.radius + 3, 4)
        end
        
        love.graphics.pop()
    end
    
    -- 绘制兵种文字标识
    love.graphics.setColor(1, 1, 1)
    local classSymbol = ""
    if self.unitClass == "Sniper" then
        classSymbol = "S"
    elseif self.unitClass == "Gunner" then
        classSymbol = "G"
    elseif self.unitClass == "Tank" then
        classSymbol = "T"
    elseif self.unitClass == "Scout" then
        classSymbol = "SC"
    elseif self.unitClass == "Healer" then
        classSymbol = "+"
    elseif self.unitClass == "Demolisher" then
        classSymbol = "D"
    elseif self.unitClass == "Ranger" then
        classSymbol = "R"
    elseif self.unitClass == "Miner" then
        classSymbol = "M"
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

-- 侦查系统：扫描视野范围内的敌人
function Agent:updateVision()
    if not self.enemies then return end
    
    local currentTime = love.timer.getTime()
    
    -- 扫描视野范围内的敌人
    for _, enemy in ipairs(self.enemies) do
        if not enemy.isDead and enemy.health > 0 then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- 在视野范围内
            if distance <= self.visionRange then
                if not self.discoveredEnemies[enemy] then
                    -- 首次发现敌人
                    self.discoveredEnemies[enemy] = true
                    self.lastDiscoveryTime = currentTime
                    
                    -- 通知队伍发现敌人（可以触发警报或共享视野）
                    if _G.teams and _G.teams[self.team] then
                        local teamData = _G.teams[self.team]
                        if not teamData.discoveredEnemies then
                            teamData.discoveredEnemies = {}
                        end
                        if not teamData.discoveredEnemies[enemy.team] then
                            teamData.discoveredEnemies[enemy.team] = currentTime
                            print(string.format("[%s] Discovered enemy team: %s!", self.team:upper(), enemy.team:upper()))
                        end
                    end
                end
            end
        end
    end
    
    -- 扫描敌方基地
    if self.enemyBases then
        for _, base in ipairs(self.enemyBases) do
            if not base.isDead then
                local dx = base.x - self.x
                local dy = base.y - self.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance <= self.visionRange then
                    -- 发现敌方基地
                    if _G.teams and _G.teams[self.team] then
                        local teamData = _G.teams[self.team]
                        if not teamData.discoveredEnemies then
                            teamData.discoveredEnemies = {}
                        end
                        if not teamData.discoveredEnemies[base.team] then
                            teamData.discoveredEnemies[base.team] = currentTime
                            print(string.format("[%s] Discovered enemy base: %s!", self.team:upper(), base.team:upper()))
                        end
                    end
                end
            end
        end
    end
end

return Agent
