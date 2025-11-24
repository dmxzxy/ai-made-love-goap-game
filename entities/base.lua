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
    
    -- 生产单位（如果未达到上限且有足够资源）
    if currentUnitCount < self.maxUnits then
        -- 如果没有当前生产，选择一个兵种开始生产
        if not self.currentProduction then
            self.currentProduction = self:chooseUnitToProduce(minerCount)
        end
        
        if self.currentProduction then
            local cost = self.unitCosts[self.currentProduction]
            
            -- 检查资源是否足够
            if self.resources >= cost then
                self.productionCooldown = self.productionCooldown + dt
                self.productionProgress = self.productionCooldown / self.productionTime
                
                if self.productionCooldown >= self.productionTime then
                    -- 消耗资源，生产单位
                    self.resources = self.resources - cost
                    self.productionCooldown = 0
                    self.productionProgress = 0
                    self.unitsProduced = self.unitsProduced + 1
                    
                    local producedUnit = self.currentProduction
                    self.currentProduction = nil  -- 清除当前生产
                    
                    return true, producedUnit  -- 通知需要生产新单位和兵种类型
                end
            else
                -- 资源不足，暂停生产进度
                self.productionProgress = 0
            end
        end
    else
        self.productionProgress = 0
        self.currentProduction = nil
    end
    
    return false, nil
end

-- 选择要生产的兵种（基于策略）
function Base:chooseUnitToProduce(minerCount)
    minerCount = minerCount or 0
    
    -- 前期优先生产矿工发展经济
    if minerCount < 3 and self.resources >= 40 then
        return "Miner"
    end
    
    -- 策略：根据资源量和随机性选择多样化兵种
    local rand = math.random()
    
    if self.resources < 60 then
        -- 资源不足，生产矿工或士兵
        if minerCount < 5 and rand < 0.4 then
            return "Miner"
        elseif rand < 0.7 then
            return "Soldier"
        else
            return "Scout"  -- 便宜的快速单位
        end
    end
    
    -- 丰富的兵种组合
    if minerCount < 5 and rand < 0.1 then
        return "Miner"  -- 10% 继续补充矿工
    elseif self.resources >= 100 and rand < 0.15 then
        return "Tank"  -- 5% 坦克
    elseif self.resources >= 90 and rand < 0.22 then
        return "Demolisher"  -- 7% 爆破兵
    elseif self.resources >= 85 and rand < 0.30 then
        return "Ranger"  -- 8% 游侠
    elseif self.resources >= 80 and rand < 0.42 then
        return "Sniper"  -- 12% 狙击手
    elseif self.resources >= 75 and rand < 0.52 then
        return "Healer"  -- 10% 医疗兵
    elseif self.resources >= 70 and rand < 0.67 then
        return "Gunner"  -- 15% 机枪手
    elseif self.resources >= 55 and rand < 0.80 then
        return "Scout"  -- 13% 侦察兵
    else
        return "Soldier"  -- 20% 士兵
    end
end

function Base:takeDamage(damage, isCrit)
    if self.isDead then return 0 end
    
    local actualDamage = damage
    if isCrit then
        actualDamage = damage * 2
    end
    
    -- 护甲减免
    actualDamage = actualDamage * (1 - self.armor)
    self.health = self.health - actualDamage
    self.flashTime = 0.15
    
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
    self.resources = self.resources - barracksData.cost
    
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
    
    -- 优先建造步兵营房（最便宜且实用）
    if #self.barracks == 0 and self.resources >= 150 then
        return self:buildBarracks("Infantry", Barracks)
    end
    
    -- 第二个建造侦察营（便宜且快速）
    if #self.barracks == 1 and self.resources >= 140 then
        return self:buildBarracks("ScoutCamp", Barracks)
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

return Base
