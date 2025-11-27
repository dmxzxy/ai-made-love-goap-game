-- Special Buildings System (Refactored - Simplified)
local SpecialBuilding = {}
SpecialBuilding.__index = SpecialBuilding

-- Special building types with unique abilities
SpecialBuilding.types = {
    -- === 资源类建筑 ===
    ResourceDepot = {
        name = "Resource Depot",
        cost = 120,
        buildTime = 5,
        color = {1, 0.85, 0.3},
        size = 45,
        health = 250,
        description = "+500 capacity",
        effect = "resourceStorage",
        effectValue = 500,
        category = "resource",
        radius = 0
    },
    GoldMine = {
        name = "Gold Mine",
        cost = 200,
        buildTime = 8,
        color = {1, 0.95, 0.1},
        size = 50,
        health = 400,
        description = "+8$/sec",
        effect = "passiveIncome",
        effectValue = 8,
        category = "resource",
        radius = 0
    },
    TradingPost = {
        name = "Trading Post",
        cost = 150,
        buildTime = 6,
        color = {0.9, 1, 0.5},
        size = 42,
        health = 280,
        description = "+60% miner speed",
        effect = "minerSpeed",
        effectValue = 0.60,
        category = "support",
        radius = 0
    },
    
    -- === 防御类建筑 ===
    Fortress = {
        name = "Fortress",
        cost = 300,
        buildTime = 12,
        color = {0.6, 0.6, 0.7},
        size = 50,
        health = 800,
        description = "+40% HP +30% armor",
        effect = "fortressAura",
        effectValue = 0.40,
        category = "defense",
        radius = 450
    },
    Bunker = {
        name = "Bunker",
        cost = 250,
        buildTime = 10,
        color = {0.5, 0.5, 0.4},
        size = 46,
        health = 500,
        description = "+50% defense heal 5/s",
        effect = "bunkerProtection",
        effectValue = 0.50,
        category = "defense",
        radius = 250
    },
    Watchtower = {
        name = "Watchtower",
        cost = 180,
        buildTime = 7,
        color = {0.7, 0.7, 0.9},
        size = 42,
        health = 350,
        description = "+100% vision +50% range",
        effect = "enhancedVision",
        effectValue = 1.0,
        category = "defense",
        radius = 600
    },
    
    -- === 军事类建筑 ===
    Arsenal = {
        name = "Arsenal",
        cost = 250,
        buildTime = 10,
        color = {1, 0.6, 0.4},
        size = 44,
        health = 400,
        description = "+35% damage +25% crit",
        effect = "combatBoost",
        effectValue = 0.35,
        category = "military",
        radius = 400
    },
    TrainingGround = {
        name = "Training Ground",
        cost = 150,
        buildTime = 6,
        color = {0.8, 0.8, 0.5},
        size = 46,
        health = 280,
        description = "-40% time spawn faster",
        effect = "fastProduction",
        effectValue = 0.40,
        category = "military",
        radius = 0
    },
    CommandCenter = {
        name = "Command Center",
        cost = 320,
        buildTime = 13,
        color = {0.6, 0.7, 1},
        size = 50,
        health = 480,
        description = "+15 units capacity",
        effect = "unitCapIncrease",
        effectValue = 15,
        category = "military",
        radius = 0
    },
    
    -- === 生产类建筑（合并为综合工厂）===
    UniversalFactory = {
        name = "Universal Factory",
        cost = 150,
        buildTime = 6,
        color = {0.7, 0.6, 0.4},
        size = 50,
        health = 400,
        description = "Produces all unit types",
        effect = "unitProduction",
        effectValue = 1,
        producesUnit = "Soldier",  -- 默认生产士兵
        productionTime = 2.0,
        productionCost = 35,
        category = "production",
        radius = 0
    },
    
    -- === 支援类建筑 ===
    MedicalStation = {
        name = "Medical Station",
        cost = 180,
        buildTime = 7,
        color = {0.4, 1, 0.6},
        size = 42,
        health = 300,
        description = "+8 HP/s heal aura",
        effect = "healingAura",
        effectValue = 8,
        category = "support",
        radius = 400
    },
    SupplyDepot = {
        name = "Supply Depot",
        cost = 140,
        buildTime = 5,
        color = {0.8, 0.8, 0.7},
        size = 40,
        health = 300,
        description = "+30% speed",
        effect = "movementBoost",
        effectValue = 0.30,
        category = "support",
        radius = 0
    }
}

function SpecialBuilding.new(x, y, team, buildingType)
    local self = setmetatable({}, SpecialBuilding)
    
    local config = SpecialBuilding.types[buildingType]
    if not config then
        print("Unknown special building type: " .. buildingType)
        return nil
    end
    
    -- Basic properties
    self.x = x
    self.y = y
    self.team = team
    self.buildingType = buildingType
    self.name = config.name
    self.cost = config.cost
    
    -- Stats
    self.health = config.health
    self.maxHealth = config.health
    
    -- Visual
    self.color = config.color
    self.size = config.size
    self.description = config.description
    
    -- Effect properties
    self.effect = config.effect
    self.effectValue = config.effectValue
    self.radius = config.radius
    
    -- State
    self.isDead = false
    self.buildProgress = 0
    self.buildTime = config.buildTime
    self.isComplete = false
    
    -- Animation
    self.pulseTimer = 0
    
    -- Secondary effect
    self.secondaryEffect = config.secondaryEffect
    self.secondaryValue = config.secondaryValue
    
    -- Unit production properties (for production buildings)
    if config.producesUnit then
        self.producesUnit = config.producesUnit
        self.productionTime = config.productionTime
        self.productionCost = config.productionCost
        self.productionTimer = 0
        self.isProducing = false
    end
    
    return self
end

-- Get building category for visual differentiation
function SpecialBuilding:getBuildingCategory()
    local resourceTypes = {"ResourceDepot", "GoldMine", "TradingPost"}
    local defenseTypes = {"Fortress", "Bunker", "Watchtower"}
    local militaryTypes = {"Arsenal", "TrainingGround", "CommandCenter"}
    local productionTypes = {"UniversalFactory"}
    
    for _, t in ipairs(resourceTypes) do
        if self.buildingType == t then return "resource" end
    end
    for _, t in ipairs(defenseTypes) do
        if self.buildingType == t then return "defense" end
    end
    for _, t in ipairs(militaryTypes) do
        if self.buildingType == t then return "military" end
    end
    for _, t in ipairs(productionTypes) do
        if self.buildingType == t then return "production" end
    end
    return "support"
end

-- Draw octagon shape
function SpecialBuilding:drawOctagon(cx, cy, radius, isLine)
    local points = {}
    for i = 0, 7 do
        local angle = (i / 8) * math.pi * 2
        table.insert(points, cx + math.cos(angle) * radius)
        table.insert(points, cy + math.sin(angle) * radius)
    end
    if isLine then
        love.graphics.polygon("line", points)
    else
        love.graphics.polygon("fill", points)
    end
end

-- Draw diamond shape
function SpecialBuilding:drawDiamond(cx, cy, radius, isLine)
    local points = {
        cx, cy - radius,          -- top
        cx + radius, cy,          -- right
        cx, cy + radius,          -- bottom
        cx - radius, cy           -- left
    }
    if isLine then
        love.graphics.polygon("line", points)
    else
        love.graphics.polygon("fill", points)
    end
end

-- Draw hexagon shape
function SpecialBuilding:drawHexagon(cx, cy, radius, isLine)
    local points = {}
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2 - math.pi / 2
        table.insert(points, cx + math.cos(angle) * radius)
        table.insert(points, cy + math.sin(angle) * radius)
    end
    if isLine then
        love.graphics.polygon("line", points)
    else
        love.graphics.polygon("fill", points)
    end
end

-- Draw pentagon shape (for production buildings)
function SpecialBuilding:drawPentagon(cx, cy, radius, isLine)
    local points = {}
    for i = 0, 4 do
        local angle = (i / 5) * math.pi * 2 - math.pi / 2
        table.insert(points, cx + math.cos(angle) * radius)
        table.insert(points, cy + math.sin(angle) * radius)
    end
    if isLine then
        love.graphics.polygon("line", points)
    else
        love.graphics.polygon("fill", points)
    end
end

function SpecialBuilding:update(dt)
    if self.isDead then return end
    
    -- Building progress
    if not self.isComplete then
        self.buildProgress = self.buildProgress + dt
        if self.buildProgress >= self.buildTime then
            self.isComplete = true
            local category = self:getBuildingCategory()
            print(string.format("★★★ [%s] %s COMPLETED! Category: %s, Size: %d ★★★", 
                self.team:upper(), self.name, category:upper(), self.size))
        end
        return
    end
    
    -- Unit production (for production buildings)
    if self.producesUnit and self.isComplete then
        if not self.isProducing then
            self.isProducing = true
            self.productionTimer = 0
        else
            self.productionTimer = self.productionTimer + dt
        end
    end
    
    -- Animation
    self.pulseTimer = self.pulseTimer + dt
end

-- Check if production is ready and return unit info
function SpecialBuilding:checkProduction(availableResources)
    if not self.producesUnit or not self.isComplete or self.isDead then
        return false, nil, 0
    end
    
    if self.productionTimer >= self.productionTime and availableResources >= self.productionCost then
        -- Reset timer
        self.productionTimer = 0
        return true, self.producesUnit, self.productionCost
    end
    
    return false, nil, 0
end

-- Get spawn position for produced units
function SpecialBuilding:getSpawnPosition()
    local offsetX = (math.random() - 0.5) * 30
    local offsetY = (math.random() - 0.5) * 30
    return self.x + offsetX, self.y + self.size + 10 + offsetY
end

function SpecialBuilding:draw(offsetX, offsetY)
    if self.isDead then return end
    
    -- 直接使用世界坐标，因为摄像机变换已经在外部应用
    local x = self.x
    local y = self.y
    
    -- Don't draw if far off screen (optimization)
    -- Note: These bounds are in world coordinates
    if x < -200 or x > WORLD_WIDTH + 200 or y < -200 or y > WORLD_HEIGHT + 200 then
        return
    end
    
    if not self.isComplete then
        -- Building in progress
        love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
        love.graphics.rectangle("fill", x - self.size/2, y - self.size/2, self.size, self.size, 4, 4)
        
        -- Progress bar (更粗)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", x - self.size/2, y + self.size/2 + 5, self.size, 10)
        love.graphics.setColor(0.3, 0.8, 0.3)
        local progress = math.min(self.buildProgress / self.buildTime, 1)
        love.graphics.rectangle("fill", x - self.size/2, y + self.size/2 + 5, self.size * progress, 10)
        
        -- 显示建造中的名称和进度百分比（更大）
        love.graphics.setColor(1, 1, 1, 1)
        local progressPercent = math.floor(progress * 100)
        love.graphics.print(string.format("%s %d%%", self.name, progressPercent), x - 45, y + self.size/2 + 18, 0, 1.0, 1.0)
    else
        -- Completed building
        local pulse = math.sin(self.pulseTimer * 2) * 0.15 + 0.85
        
        -- 根据建筑类型绘制不同形状
        local buildingCategory = self:getBuildingCategory()
        
        -- 绘制背景光晕（更大更明显）
        local glowPulse = math.sin(self.pulseTimer * 3) * 0.2 + 0.3
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], glowPulse * 0.5)
        love.graphics.circle("fill", x, y, self.size * 0.8)
        
        -- 主体颜色（更亮）
        love.graphics.setColor(self.color[1] * pulse, self.color[2] * pulse, self.color[3] * pulse, 0.95)
        
        if buildingCategory == "resource" then
            -- 资源类：圆角矩形 + 粗金色边框
            love.graphics.rectangle("fill", x - self.size/2, y - self.size/2, self.size, self.size, 10, 10)
            love.graphics.setColor(1, 0.95, 0.2, 1)
            love.graphics.setLineWidth(4)
            love.graphics.rectangle("line", x - self.size/2, y - self.size/2, self.size, self.size, 10, 10)
            love.graphics.setLineWidth(1)
            
            -- 额外的内部边框
            love.graphics.setColor(1, 1, 0.5, 0.6)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x - self.size/2 + 4, y - self.size/2 + 4, self.size - 8, self.size - 8, 8, 8)
            love.graphics.setLineWidth(1)
            
        elseif buildingCategory == "defense" then
            -- 防御类：八边形 + 粗灰色边框
            self:drawOctagon(x, y, self.size/2)
            love.graphics.setColor(0.8, 0.8, 0.9, 1)
            love.graphics.setLineWidth(4)
            self:drawOctagon(x, y, self.size/2, true)
            love.graphics.setLineWidth(1)
            
            -- 内部八边形
            love.graphics.setColor(0.9, 0.9, 1, 0.6)
            love.graphics.setLineWidth(2)
            self:drawOctagon(x, y, self.size/2 - 4, true)
            love.graphics.setLineWidth(1)
            
        elseif buildingCategory == "military" then
            -- 军事类：菱形 + 粗红色边框
            self:drawDiamond(x, y, self.size/2)
            love.graphics.setColor(1, 0.4, 0.3, 1)
            love.graphics.setLineWidth(4)
            self:drawDiamond(x, y, self.size/2, true)
            love.graphics.setLineWidth(1)
            
            -- 内部菱形
            love.graphics.setColor(1, 0.6, 0.5, 0.6)
            love.graphics.setLineWidth(2)
            self:drawDiamond(x, y, self.size/2 - 4, true)
            love.graphics.setLineWidth(1)
            
        elseif buildingCategory == "production" then
            -- 生产类：五边形 + 粗橙色边框
            self:drawPentagon(x, y, self.size/2)
            love.graphics.setColor(1, 0.7, 0.3, 1)
            love.graphics.setLineWidth(4)
            self:drawPentagon(x, y, self.size/2, true)
            love.graphics.setLineWidth(1)
            
            -- 内部五边形
            love.graphics.setColor(1, 0.85, 0.5, 0.6)
            love.graphics.setLineWidth(2)
            self:drawPentagon(x, y, self.size/2 - 4, true)
            love.graphics.setLineWidth(1)
            
        else
            -- 支援类：圆形 + 粗绿色边框
            love.graphics.circle("fill", x, y, self.size/2)
            love.graphics.setColor(0.4, 1, 0.6, 1)
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", x, y, self.size/2)
            love.graphics.setLineWidth(1)
            
            -- 内部圆形
            love.graphics.setColor(0.6, 1, 0.8, 0.6)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", x, y, self.size/2 - 4)
            love.graphics.setLineWidth(1)
        end
        
        -- Effect radius visualization (if has area effect)
        if self.radius > 0 then
            local alphaPulse = math.sin(self.pulseTimer * 3) * 0.05 + 0.15
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], alphaPulse)
            love.graphics.circle("fill", x, y, self.radius)
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.4)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", x, y, self.radius)
            love.graphics.setLineWidth(1)
            
            -- 特殊效果粒子
            -- 医疗站：治疗波动
            if self.buildingType == "MedicalStation" then
                local healPulse = math.sin(self.pulseTimer * 4) * 0.3 + 0.5
                love.graphics.setColor(0.3, 1, 0.5, healPulse)
                love.graphics.circle("line", x, y, self.radius * 0.5)
                love.graphics.circle("line", x, y, self.radius * 0.75)
            end
            
            -- 护盾生成器：能量护盾
            if self.buildingType == "ShieldGenerator" then
                local shieldPulse = math.sin(self.pulseTimer * 5) * 0.2 + 0.4
                love.graphics.setColor(0.3, 0.7, 1, shieldPulse)
                for i = 1, 3 do
                    love.graphics.circle("line", x, y, self.radius * (0.3 + i * 0.2))
                end
            end
            
            -- 武器库：战斗光环
            if self.buildingType == "Arsenal" then
                local combatPulse = math.sin(self.pulseTimer * 6) * 0.3 + 0.4
                love.graphics.setColor(0.9, 0.5, 0.3, combatPulse)
                love.graphics.setLineWidth(3)
                love.graphics.circle("line", x, y, self.radius * 0.8)
                love.graphics.setLineWidth(1)
            end
            
            -- 堡垒：防御场
            if self.buildingType == "Fortress" then
                local fortressPulse = math.sin(self.pulseTimer * 3) * 0.2 + 0.3
                love.graphics.setColor(0.5, 0.5, 0.5, fortressPulse)
                love.graphics.setLineWidth(4)
                love.graphics.circle("line", x, y, self.radius)
                love.graphics.setLineWidth(1)
            end
        end
        
        -- Icon/Symbol
        local iconText = ""
        local iconScale = 1.5  -- 更大的默认尺寸
        
        -- 资源类
        if self.buildingType == "ResourceDepot" then 
            iconText = "D"
        elseif self.buildingType == "GoldMine" then 
            iconText = "$"
            iconScale = 2.0
        elseif self.buildingType == "TradingPost" then 
            iconText = "T"
        -- 防御类
        elseif self.buildingType == "Fortress" then 
            iconText = "F"
            iconScale = 1.8
        elseif self.buildingType == "Bunker" then 
            iconText = "B"
        elseif self.buildingType == "Watchtower" then 
            iconText = "W"
        -- 军事类
        elseif self.buildingType == "Arsenal" then 
            iconText = "A"
        elseif self.buildingType == "TrainingGround" then 
            iconText = "Tr"
            iconScale = 1.2
        elseif self.buildingType == "CommandCenter" then 
            iconText = "C"
            iconScale = 1.8
        -- 生产类
        elseif self.buildingType == "UniversalFactory" then
            iconText = "UF"
            iconScale = 1.2
        -- 支援类
        elseif self.buildingType == "MedicalStation" then 
            iconText = "+"
            iconScale = 2.0
        elseif self.buildingType == "SupplyDepot" then 
            iconText = "Sp"
            iconScale = 1.2
        end
        
        -- 图标背景（让图标更清晰）
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.circle("fill", x, y, 16)
        -- 绘制图标
        love.graphics.setColor(1, 1, 1, 1)
        local textWidth = love.graphics.getFont():getWidth(iconText) * iconScale
        love.graphics.print(iconText, x - textWidth/2, y - 10, 0, iconScale, iconScale)
        
        -- 显示建筑类别标签（更大更明显）
        local category = self:getBuildingCategory()
        local categoryText = ""
        local categoryColor = {1, 1, 1}
        if category == "resource" then
            categoryText = "[RESOURCE]"
            categoryColor = {1, 0.95, 0.2}
        elseif category == "defense" then
            categoryText = "[DEFENSE]"
            categoryColor = {0.8, 0.8, 1}
        elseif category == "military" then
            categoryText = "[MILITARY]"
            categoryColor = {1, 0.4, 0.3}
        elseif category == "production" then
            categoryText = "[PRODUCTION]"
            categoryColor = {1, 0.7, 0.3}
        else
            categoryText = "[SUPPORT]"
            categoryColor = {0.4, 1, 0.6}
        end
        -- 类别标签背景
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", x - self.size/2 - 8, y - self.size/2 - 25, 90, 18, 3, 3)
        -- 类别标签文字
        love.graphics.setColor(categoryColor[1], categoryColor[2], categoryColor[3], 1)
        love.graphics.print(categoryText, x - self.size/2 - 5, y - self.size/2 - 23, 0, 0.65, 0.65)
        
        -- 显示建筑名称（更大更明显，带背景）
        local nameWidth = love.graphics.getFont():getWidth(self.name) * 0.9
        -- 名称背景
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", x - nameWidth/2 - 5, y + self.size/2 + 3, nameWidth + 10, 20, 3, 3)
        -- 名称文字
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(self.name, x - nameWidth/2, y + self.size/2 + 6, 0, 0.9, 0.9)
        
        -- 显示建筑效果（更大更清晰，带背景）
        if self.description then
            local descWidth = love.graphics.getFont():getWidth(self.description) * 0.65
            -- 描述背景
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", x - descWidth/2 - 3, y + self.size/2 + 24, descWidth + 6, 15, 2, 2)
            -- 描述文字
            love.graphics.setColor(0.9, 1, 0.9, 1)
            love.graphics.print(self.description, x - descWidth/2, y + self.size/2 + 26, 0, 0.65, 0.65)
        end
        
        -- 显示实时工作状态（更大更明显）
        if self.effect == "passiveIncome" then
            -- 金矿显示收入（带背景和金币图标）
            local statusText = string.format("+%d$/s", self.effectValue)
            local statusWidth = love.graphics.getFont():getWidth(statusText) * 1.0
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", x - statusWidth/2 - 5, y - self.size/2 - 30, statusWidth + 10, 18, 3, 3)
            love.graphics.setColor(1, 0.95, 0.2, 1)
            love.graphics.print(statusText, x - statusWidth/2, y - self.size/2 - 28, 0, 1.0, 1.0)
        elseif self.effect == "healingAura" then
            -- 医疗站显示治疗
            local statusText = string.format("+%d HP/s", self.effectValue)
            local statusWidth = love.graphics.getFont():getWidth(statusText) * 0.9
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", x - statusWidth/2 - 5, y - self.size/2 - 30, statusWidth + 10, 18, 3, 3)
            love.graphics.setColor(0.4, 1, 0.6, 1)
            love.graphics.print(statusText, x - statusWidth/2, y - self.size/2 - 28, 0, 0.9, 0.9)
        elseif self.effect == "combatBoost" then
            -- 武器库显示攻击加成
            local statusText = string.format("+%d%% DMG", math.floor(self.effectValue * 100))
            local statusWidth = love.graphics.getFont():getWidth(statusText) * 0.85
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", x - statusWidth/2 - 5, y - self.size/2 - 30, statusWidth + 10, 18, 3, 3)
            love.graphics.setColor(1, 0.5, 0.3, 1)
            love.graphics.print(statusText, x - statusWidth/2, y - self.size/2 - 28, 0, 0.85, 0.85)
        end
    end
    
    -- Health bar
    if self.health < self.maxHealth then
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", x - self.size/2, y - self.size/2 - 8, self.size, 4)
        love.graphics.setColor(0.3, 0.9, 0.3)
        love.graphics.rectangle("fill", x - self.size/2, y - self.size/2 - 8, 
            self.size * (self.health / self.maxHealth), 4)
    end
end

function SpecialBuilding:takeDamage(amount)
    if self.isDead or not self.isComplete then return end
    
    self.health = self.health - amount
    if self.health <= 0 then
        self.health = 0
        self.isDead = true
        print(string.format("%s destroyed!", self.name))
    end
end

-- Apply building effects to units in range
function SpecialBuilding:applyEffects(units)
    if not self.isComplete or self.isDead then return end
    
    for _, unit in ipairs(units) do
        if not unit.isDead and unit.team == self.team then
            local distance = math.sqrt((unit.x - self.x)^2 + (unit.y - self.y)^2)
            
            if self.radius == 0 or distance <= self.radius then
                -- Mark unit as affected by this building
                if not unit.buildingEffects then
                    unit.buildingEffects = {}
                end
                
                -- 主效果
                unit.buildingEffects[self.effect] = self.effectValue
                
                -- 副效果
                if self.secondaryEffect then
                    unit.buildingEffects[self.secondaryEffect] = self.secondaryValue
                end
                
                -- 特殊效果立即应用
                -- 医疗站治疗
                if self.effect == "healingAura" and unit.health and unit.maxHealth and unit.health < unit.maxHealth then
                    unit.health = math.min(unit.maxHealth, unit.health + self.effectValue * 0.016)  -- 假设60fps
                end
                
                -- 瞭望塔提升视野
                if self.effect == "enhancedVision" and unit.visionRange then
                    if not unit.baseVisionRange then
                        unit.baseVisionRange = unit.visionRange
                    end
                    unit.visionRange = unit.baseVisionRange * (1 + self.effectValue)
                end
                
                -- 堡垒光环
                if self.effect == "fortressAura" and unit.maxHealth then
                    if not unit.baseMaxHealth then
                        unit.baseMaxHealth = unit.maxHealth
                    end
                    unit.maxHealth = unit.baseMaxHealth * (1 + self.effectValue)
                    if unit.health then
                        unit.health = math.min(unit.health, unit.maxHealth)
                    end
                end
                
                -- 战斗加成
                if self.effect == "combatBoost" and unit.damage then
                    if not unit.baseDamage then
                        unit.baseDamage = unit.damage
                    end
                    unit.damage = unit.baseDamage * (1 + self.effectValue)
                end
                
                -- 移动加成
                if self.effect == "movementBoost" and unit.speed then
                    if not unit.baseSpeed then
                        unit.baseSpeed = unit.speed
                    end
                    unit.speed = unit.baseSpeed * (1 + self.effectValue)
                end
                
                -- 能量护盾
                if self.effect == "energyShield" and unit.maxHealth then
                    if not unit.shield then
                        unit.shield = 0
                        unit.maxShield = unit.maxHealth * 0.5
                    end
                    -- 护盾再生
                    if self.secondaryEffect == "shieldRegen" and unit.shield < unit.maxShield then
                        unit.shield = math.min(unit.maxShield, unit.shield + self.secondaryValue * 0.016)
                    end
                end
            end
        end
    end
end

return SpecialBuilding
