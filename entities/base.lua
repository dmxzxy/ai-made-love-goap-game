-- 基地类
local Base = {}
Base.__index = Base

function Base.new(x, y, team, color)
    local self = setmetatable({}, Base)
    
    self.x = x
    self.y = y
    self.team = team
    self.color = color
    self.size = 60  -- 基地尺寸
    
    -- 基地属性
    self.maxHealth = 1000
    self.health = 1000
    self.armor = 0.3  -- 30%护甲
    
    -- 资源系统
    self.resources = 200  -- 初始资源
    self.maxResources = 800  -- 最大资源存储（提高上限）
    self.miningRange = 150  -- 采集范围
    self.miningRate = 3  -- 基础每秒采集速度（降低基础速度）
    self.nearbyResources = {}  -- 范围内的资源点
    self.minerBonus = 0  -- 矿工提供的额外采集速度
    
    -- 生产系统和成本
    self.productionCooldown = 0
    self.productionTime = 8  -- 基础生产时间
    self.maxUnits = 25  -- 最大单位数量限制（提高到25）
    self.unitsProduced = 0
    self.currentProduction = nil  -- 当前生产的兵种
    
    -- 兵种成本
    self.unitCosts = {
        Miner = 40,      -- 矿工：便宜的经济单位
        Soldier = 50,    -- 士兵：基础战斗单位
        Scout = 55,      -- 侦察兵：快速单位
        Gunner = 70,     -- 机枪手：火力压制
        Sniper = 80,     -- 狙击手：远程精准
        Healer = 75,     -- 医疗兵：辅助治疗
        Tank = 100,      -- 坦克：重装单位
        Demolisher = 90, -- 爆破兵：攻城单位
        Ranger = 85      -- 游侠：超远程
    }
    
    -- 兵营系统
    self.barracks = {}  -- 建造的兵营列表
    self.maxBarracks = 6  -- 最大兵营数量（提高到6）
    self.barracksBuildQueue = {}  -- 兵营建造队列
    self.isConstructing = false
    self.constructionProgress = 0
    
    -- 防御塔系统
    self.towers = {}  -- 建造的防御塔列表
    self.maxTowers = 4  -- 最大防御塔数量
    self.towerCosts = {
        Arrow = 150,
        Cannon = 250,
        Laser = 300,
        Frost = 200
    }
    
    -- 战术AI系统（新增）
    self.strategy = {
        mode = "economy",  -- 当前策略：economy（发展经济）、defensive（防守）、offensive（进攻）、desperate（绝境反击）
        reservedGold = 150,  -- 保留资源（用于紧急重建矿工）
        waveSize = 0,  -- 当前波次积攒的兵力
        waveTarget = 3,  -- 目标波次规模（3-5个单位一波）
        lastWaveTime = 0,  -- 上次发起进攻的时间
        waveInterval = 15,  -- 波次间隔（秒）
        minMinerCount = 2,  -- 最低矿工数量保障
        economyPhaseTime = 60,  -- 发展经济阶段持续时间（秒）
        startTime = love.timer.getTime(),
    }
    
    -- 视觉效果
    self.flashTime = 0
    self.isDead = false
    self.deathTime = 0
    
    -- 生产进度条
    self.productionProgress = 0
    
    return self
end

function Base:update(dt, currentUnitCount, resources, minerCount)
    if self.isDead then
        self.deathTime = self.deathTime + dt
        return nil, nil
    end
    
    if self.health <= 0 then
        self.isDead = true
        self.deathTime = 0
        print(string.format("[%s] BASE DESTROYED!", self.team:upper()))
        return nil, nil
    end
    
    -- 受击闪烁效果
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    
    -- 自动采集附近的资源
    self.nearbyResources = resources or {}
    local mined = 0
    local totalMiningRate = self.miningRate + self.minerBonus  -- 基础速度 + 矿工加成
    
    for _, resource in ipairs(self.nearbyResources) do
        if not resource.depleted then
            local dx = resource.x - self.x
            local dy = resource.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance <= self.miningRange then
                local amount = totalMiningRate * dt
                local actualMined = resource:mine(amount)
                mined = mined + actualMined
            end
        end
    end
    
    -- 添加采集的资源
    if mined > 0 then
        self.resources = math.min(self.maxResources, self.resources + mined)
    end
    
    -- 生产单位（基于战术AI决策）
    if currentUnitCount < self.maxUnits then
        -- 检查是否有足够的可用资源（扣除保留金）
        local availableGold = math.max(0, self.resources - self.strategy.reservedGold)
        
        -- 如果没有当前生产，选择一个兵种开始生产
        if not self.currentProduction then
            self.currentProduction = self:chooseUnitToProduce(minerCount, currentUnitCount)
        end
        
        if self.currentProduction then
            local cost = self.unitCosts[self.currentProduction]
            
            -- 检查资源是否足够（使用可用资源而非总资源）
            if availableGold >= cost then
                self.productionCooldown = self.productionCooldown + dt
                self.productionProgress = self.productionCooldown / self.productionTime
                
                if self.productionCooldown >= self.productionTime then
                    -- 消耗资源，生产单位
                    self.resources = math.max(0, self.resources - cost)
                    self.productionCooldown = 0
                    self.productionProgress = 0
                    self.unitsProduced = self.unitsProduced + 1
                    
                    local producedUnit = self.currentProduction
                    self.currentProduction = nil  -- 清除当前生产
                    
                    return true, producedUnit  -- 通知需要生产新单位和兵种类型
                end
            else
                -- 资源不足（考虑保留金），暂停生产进度
                self.productionProgress = 0
            end
        end
    else
        self.productionProgress = 0
        self.currentProduction = nil
    end
    
    return false, nil
end

-- 更新战术策略
function Base:updateStrategy(minerCount, currentUnitCount, enemyUnitCount)
    local currentTime = love.timer.getTime()
    local gameTime = currentTime - self.strategy.startTime
    
    minerCount = minerCount or 0
    currentUnitCount = currentUnitCount or 0
    enemyUnitCount = enemyUnitCount or 0
    
    -- 绝境模式：矿工全灭或濒临崩溃
    if minerCount == 0 or (self.health < 300 and currentUnitCount < 5) then
        self.strategy.mode = "desperate"
        self.strategy.reservedGold = 80  -- 降低保留资源，孤注一掷
        self.strategy.waveTarget = 2  -- 快速小波次
        return
    end
    
    -- 经济发展模式：游戏前60秒或矿工不足
    if gameTime < self.strategy.economyPhaseTime or minerCount < self.strategy.minMinerCount then
        self.strategy.mode = "economy"
        self.strategy.reservedGold = 150  -- 保留资源重建经济
        self.strategy.waveTarget = 2  -- 少量兵力防守
        return
    end
    
    -- 防守模式：敌方兵力优势或基地受损
    if enemyUnitCount > currentUnitCount + 5 or self.health < 700 then
        self.strategy.mode = "defensive"
        self.strategy.reservedGold = 120
        self.strategy.waveTarget = 4  -- 积攒更多兵力
        return
    end
    
    -- 进攻模式：兵力优势且资源充足
    if currentUnitCount > enemyUnitCount + 3 and self.resources > 300 then
        self.strategy.mode = "offensive"
        self.strategy.reservedGold = 100
        self.strategy.waveTarget = 5  -- 大波次进攻
        return
    end
    
    -- 默认均衡模式
    self.strategy.mode = "defensive"
    self.strategy.reservedGold = 120
    self.strategy.waveTarget = 3
end

-- 选择要生产的兵种（基于战术策略）
function Base:chooseUnitToProduce(minerCount, currentUnitCount)
    minerCount = minerCount or 0
    currentUnitCount = currentUnitCount or 0
    
    -- 绝境模式：优先重建矿工
    if self.strategy.mode == "desperate" then
        if minerCount == 0 and self.resources >= 40 then
            return "Miner"
        end
        -- 然后快速生产便宜单位
        if self.resources >= 55 then
            return math.random() < 0.5 and "Scout" or "Soldier"
        elseif self.resources >= 50 then
            return "Soldier"
        end
        return nil
    end
    
    -- 经济模式：优先补充矿工
    if self.strategy.mode == "economy" then
        if minerCount < self.strategy.minMinerCount and self.resources >= 40 then
            return "Miner"
        end
        if minerCount < 4 and self.resources >= 100 then
            return "Miner"
        end
        -- 少量防守兵力
        if self.resources >= 60 then
            local rand = math.random()
            if rand < 0.4 then
                return "Soldier"
            elseif rand < 0.7 then
                return "Scout"
            else
                return "Gunner"
            end
        end
        return nil
    end
    
    -- 防守模式：平衡兵种
    if self.strategy.mode == "defensive" then
        -- 确保最低矿工数
        if minerCount < 3 and self.resources >= 80 then
            return "Miner"
        end
        
        local rand = math.random()
        if self.resources >= 100 and rand < 0.15 then
            return "Tank"  -- 重装防守
        elseif self.resources >= 80 and rand < 0.30 then
            return "Sniper"  -- 远程火力
        elseif self.resources >= 75 and rand < 0.45 then
            return "Healer"  -- 续航能力
        elseif self.resources >= 70 and rand < 0.65 then
            return "Gunner"  -- 火力压制
        elseif self.resources >= 55 and rand < 0.80 then
            return "Scout"  -- 机动性
        else
            return "Soldier"  -- 基础单位
        end
    end
    
    -- 进攻模式：高质量进攻单位
    if self.strategy.mode == "offensive" then
        -- 保持少量矿工
        if minerCount < 2 and self.resources >= 100 then
            return "Miner"
        end
        
        local rand = math.random()
        if self.resources >= 100 and rand < 0.20 then
            return "Tank"  -- 突破手
        elseif self.resources >= 90 and rand < 0.35 then
            return "Demolisher"  -- 攻城单位
        elseif self.resources >= 85 and rand < 0.50 then
            return "Ranger"  -- 超远程压制
        elseif self.resources >= 80 and rand < 0.65 then
            return "Sniper"  -- 狙击威胁目标
        elseif self.resources >= 70 and rand < 0.80 then
            return "Gunner"  -- 火力输出
        else
            return "Soldier"  -- 填充兵力
        end
    end
    
    return nil
end

function Base:takeDamage(damage, isCrit, attacker)
    if self.isDead then return 0 end
    
    local actualDamage = damage
    if isCrit then
        actualDamage = damage * 2
    end
    
    -- 护甲减免
    actualDamage = actualDamage * (1 - self.armor)
    self.health = self.health - actualDamage
    self.flashTime = 0.15
    
    -- 触发基地受攻击警告（每5秒最多一次）
    if not self.lastWarningTime or (love.timer.getTime() - self.lastWarningTime) > 5 then
        self.lastWarningTime = love.timer.getTime()
        -- 全局函数调用（将在main.lua中定义）
        if BattleNotifications then
            BattleNotifications.baseUnderAttack(self.team)
        end
    end
    
    return actualDamage
end

function Base:draw()
    if self.isDead then
        -- 死亡动画
        local alpha = math.max(0, 1 - self.deathTime * 0.5)
        love.graphics.setColor(0.3, 0.3, 0.3, alpha * 0.5)
        love.graphics.rectangle("fill", self.x - self.size/2, self.y - self.size/2, 
            self.size, self.size)
        return
    end
    
    -- 基地主体（方形）
    local bodyColor = self.color
    if self.flashTime > 0 then
        bodyColor = {1, 1, 1}
    end
    
    love.graphics.setColor(bodyColor)
    love.graphics.rectangle("fill", self.x - self.size/2, self.y - self.size/2, 
        self.size, self.size)
    
    -- 基地护甲外圈
    love.graphics.setColor(0.5, 0.5, 1, 0.3)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", self.x - self.size/2 - 4, self.y - self.size/2 - 4, 
        self.size + 8, self.size + 8)
    love.graphics.setLineWidth(1)
    
    -- 绘制边框
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x - self.size/2, self.y - self.size/2, 
        self.size, self.size)
    love.graphics.setLineWidth(1)
    
    -- 绘制基地标识（中心十字）
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.line(self.x - 20, self.y, self.x + 20, self.y)
    love.graphics.line(self.x, self.y - 20, self.x, self.y + 20)
    
    -- 血条
    local barWidth = self.size
    local barHeight = 8
    local barX = self.x - barWidth / 2
    local barY = self.y - self.size/2 - 20
    
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
    
    -- 血量数字
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("%.0f/%.0f", self.health, self.maxHealth), 
        barX + 5, barY - 2, 0, 0.7, 0.7)
    
    -- 资源条（在血条下方）
    local resBarY = barY + barHeight + 3
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, resBarY, barWidth, 4)
    
    local resourcePercent = self.resources / self.maxResources
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.rectangle("fill", barX, resBarY, barWidth * resourcePercent, 4)
    
    -- 资源数字
    love.graphics.setColor(1, 1, 0)
    love.graphics.print(string.format("$%.0f", self.resources), 
        barX + 5, resBarY - 2, 0, 0.6, 0.6)
    
    -- 生产进度条（在基地下方）
    if self.productionProgress > 0 then
        local prodBarY = self.y + self.size/2 + 10
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", barX, prodBarY, barWidth, 5)
        
        love.graphics.setColor(0, 1, 1)
        love.graphics.rectangle("fill", barX, prodBarY, barWidth * self.productionProgress, 5)
        
        -- 生产提示（包含兵种和成本）
        if self.currentProduction then
            local cost = self.unitCosts[self.currentProduction]
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(string.format("Building %s ($%d) %.0f%%", 
                self.currentProduction, cost, self.productionProgress * 100), 
                barX - 10, prodBarY + 8, 0, 0.6, 0.6)
        end
    elseif self.resources < self.unitCosts.Soldier then
        -- 资源不足提示
        love.graphics.setColor(1, 0.5, 0.5, 0.5 + math.sin(love.timer.getTime() * 3) * 0.3)
        love.graphics.print("Need Resources!", 
            barX + 5, self.y + self.size/2 + 10, 0, 0.7, 0.7)
    end
    
    -- 基地标签
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("%s BASE", self.team:upper()), 
        self.x - 30, self.y + self.size/2 + 30, 0, 1, 1)
end

-- 获取单位生成位置
function Base:getSpawnPosition()
    local offsetX = (self.team == "red") and 80 or -80
    return self.x + offsetX, self.y + math.random(-30, 30)
end

-- 建造兵营
function Base:buildBarracks(barracksType, Barracks)
    if #self.barracks >= self.maxBarracks then
        print(string.format("[%s] Cannot build more barracks! (Max: %d)", 
            self.team:upper(), self.maxBarracks))
        return false
    end
    
    local barracksData = Barracks.types[barracksType]
    if not barracksData then
        print(string.format("[%s] Invalid barracks type: %s", 
            self.team:upper(), barracksType))
        return false
    end
    
    if self.resources < barracksData.cost then
        print(string.format("[%s] Not enough resources to build %s! Need: $%d, Have: $%d", 
            self.team:upper(), barracksData.name, barracksData.cost, self.resources))
        return false
    end
    
    -- 计算兵营位置（采用网格布局避免重叠）
    local barracksCount = #self.barracks
    local row = math.floor(barracksCount / 3)  -- 每行3个
    local col = barracksCount % 3
    
    -- 基地左右两侧布局
    local offsetX = (self.team == "red") and 1 or -1
    local baseX = self.x + offsetX * (150 + col * 100)  -- 横向间隔100
    local baseY = self.y - 100 + row * 120  -- 纵向间隔120
    
    local barrackX = baseX
    local barrackY = baseY
    
    -- 创建兵营
    local barracks = Barracks.new(barrackX, barrackY, barracksType, self.team, self.color)
    table.insert(self.barracks, barracks)
    
    -- 扣除资源
    self.resources = math.max(0, self.resources - barracksData.cost)
    
    print(string.format("[%s] Building %s at position %d (Cost: $%d, Remaining: $%d)", 
        self.team:upper(), barracksData.name, #self.barracks, 
        barracksData.cost, self.resources))
    
    return true
end

-- 尝试自动建造兵营
function Base:tryAutoBuildBarracks(Barracks)
    if #self.barracks >= self.maxBarracks then
        return false
    end
    
    -- 所有可用的兵营类型
    local allBarracksTypes = {"Infantry", "Armory", "Sniper", "Heavy", "ScoutCamp", "Hospital", "Workshop", "RangerPost"}
    
    -- 优先建造防御！确保至少有1座塔后再建兵营
    if #self.barracks == 0 then
        if #self.towers == 0 and self.resources < 300 then
            -- 如果还没有塔且资源不够建塔+兵营，等待建塔
            return false
        end
        -- 有塔了或资源充足，建造步兵营房
        if self.resources >= 150 then
            return self:buildBarracks("Infantry", Barracks)
        end
    end
    
    -- 第二个兵营：确保至少有2座塔
    if #self.barracks == 1 then
        if #self.towers < 2 and self.resources < 340 then
            -- 优先建第二座塔
            return false
        end
        if self.resources >= 140 then
            return self:buildBarracks("ScoutCamp", Barracks)
        end
    end
    
    -- 之后根据资源随机建造多样化兵营
    if self.resources >= 250 then
        local rand = math.random()
        local barrackType
        
        if rand < 0.15 then
            barrackType = "Infantry"
        elseif rand < 0.28 then
            barrackType = "ScoutCamp"
        elseif rand < 0.40 then
            barrackType = "Armory"
        elseif rand < 0.52 then
            barrackType = "Sniper"
        elseif rand < 0.64 then
            barrackType = "RangerPost"
        elseif rand < 0.76 then
            barrackType = "Hospital"
        elseif rand < 0.88 then
            barrackType = "Workshop"
        else
            barrackType = "Heavy"
        end
        
        local barracksData = Barracks.types[barrackType]
        if self.resources >= barracksData.cost then
            return self:buildBarracks(barrackType, Barracks)
        end
    end
    
    return false
end

-- 建造防御塔
function Base:buildTower(towerType, Tower)
    if #self.towers >= self.maxTowers then
        print(string.format("[%s] Max towers reached (%d/%d)", self.team, #self.towers, self.maxTowers))
        return false
    end
    
    local cost = self.towerCosts[towerType]
    if not cost then
        print("Unknown tower type: " .. towerType)
        return false
    end
    
    if self.resources < cost then
        return false
    end
    
    -- 扣除资源
    self.resources = math.max(0, self.resources - cost)
    
    -- 智能防御塔布局：只在敌人方向建塔
    local towerCount = #self.towers
    local angle, distance
    
    if self.team == "red" then
        -- 红方基地在左侧(x=150)，敌人在右侧
        -- 只在右侧和两侧前方建塔（0度到180度范围，避开后方）
        -- 第一层：正前方防御（0度方向）
        -- 第二层：右上和右下（45度和-45度）
        -- 第三层：上方和下方（90度和-90度）
        local angleOptions = {
            0,           -- 正前方
            math.pi / 6,   -- 右上30度
            -math.pi / 6,  -- 右下30度
            math.pi / 4,   -- 右上45度
            -math.pi / 4,  -- 右下45度
            math.pi / 3,   -- 右上60度
            -math.pi / 3,  -- 右下60度
            math.pi / 2,   -- 正上方
            -math.pi / 2   -- 正下方
        }
        angle = angleOptions[(towerCount % #angleOptions) + 1]
        distance = 120 + math.floor(towerCount / #angleOptions) * 40
    else
        -- 蓝方基地在右侧(x=2250)，敌人在左侧
        -- 只在左侧和两侧前方建塔（180度方向为中心）
        local angleOptions = {
            math.pi,           -- 正前方（左）
            math.pi + math.pi / 6,   -- 左上30度
            math.pi - math.pi / 6,   -- 左下30度
            math.pi + math.pi / 4,   -- 左上45度
            math.pi - math.pi / 4,   -- 左下45度
            math.pi + math.pi / 3,   -- 左上60度
            math.pi - math.pi / 3,   -- 左下60度
            math.pi / 2,       -- 正上方
            -math.pi / 2       -- 正下方
        }
        angle = angleOptions[(towerCount % #angleOptions) + 1]
        distance = 120 + math.floor(towerCount / #angleOptions) * 40
    end
    
    local towerX = self.x + math.cos(angle) * distance
    local towerY = self.y + math.sin(angle) * distance
    
    local tower = Tower.new(towerX, towerY, self.team, towerType)
    table.insert(self.towers, tower)
    
    print(string.format("[%s] Building %s tower at (%.0f, %.0f) [angle: %.0f deg], cost: %d, remaining: %.0f", 
        self.team, towerType, towerX, towerY, math.deg(angle), cost, self.resources))
    
    return true
end

-- 尝试自动建造防御塔
function Base:tryAutoBuildTower(Tower)
    if #self.towers >= self.maxTowers then
        return false
    end
    
    -- 第一座塔：优先建造箭塔（资源达到150就建）
    if #self.towers == 0 and self.resources >= 150 then
        return self:buildTower("Arrow", Tower)
    end
    
    -- 第二座塔：资源达到200就建（更早建第二座塔）
    if #self.towers == 1 and self.resources >= 200 then
        if math.random() < 0.6 then
            return self:buildTower("Frost", Tower)  -- 优先冰冻塔（控制）
        else
            return self:buildTower("Arrow", Tower)
        end
    end
    
    -- 后续塔：根据资源和策略建造
    if self.resources >= 300 then
        -- 资源充足，建造高级塔
        local rand = math.random()
        if rand < 0.35 then
            return self:buildTower("Laser", Tower)
        elseif rand < 0.65 then
            return self:buildTower("Cannon", Tower)
        else
            return self:buildTower("Frost", Tower)
        end
    elseif self.resources >= 200 then
        -- 中等资源，冰冻塔或箭塔
        if math.random() < 0.6 then
            return self:buildTower("Frost", Tower)
        else
            return self:buildTower("Arrow", Tower)
        end
    elseif self.resources >= 150 then
        return self:buildTower("Arrow", Tower)
    end
    
    return false
end

return Base
