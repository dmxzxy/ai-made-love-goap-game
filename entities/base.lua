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
    self.maxResources = 500  -- 最大资源存储
    self.miningRange = 150  -- 采集范围
    self.miningRate = 5  -- 每秒采集速度
    self.nearbyResources = {}  -- 范围内的资源点
    
    -- 生产系统和成本
    self.productionCooldown = 0
    self.productionTime = 8  -- 基础生产时间
    self.maxUnits = 10  -- 最大单位数量限制
    self.unitsProduced = 0
    self.currentProduction = nil  -- 当前生产的兵种
    
    -- 兵种成本
    self.unitCosts = {
        Soldier = 50,
        Sniper = 80,
        Gunner = 70,
        Tank = 100
    }
    
    -- 视觉效果
    self.flashTime = 0
    self.isDead = false
    self.deathTime = 0
    
    -- 生产进度条
    self.productionProgress = 0
    
    return self
end

function Base:update(dt, currentUnitCount, resources)
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
    for _, resource in ipairs(self.nearbyResources) do
        if not resource.depleted then
            local dx = resource.x - self.x
            local dy = resource.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance <= self.miningRange then
                local amount = self.miningRate * dt
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
            self.currentProduction = self:chooseUnitToProduce()
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
function Base:chooseUnitToProduce()
    -- 简单策略：根据资源量和随机性选择
    local rand = math.random()
    
    if self.resources < 60 then
        -- 资源不足，只能生产士兵
        return "Soldier"
    elseif self.resources >= 100 and rand < 0.15 then
        return "Tank"  -- 15% 坦克
    elseif self.resources >= 80 and rand < 0.35 then
        return "Sniper"  -- 20% 狙击手
    elseif self.resources >= 70 and rand < 0.55 then
        return "Gunner"  -- 20% 机枪手
    else
        return "Soldier"  -- 45% 士兵
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

return Base
