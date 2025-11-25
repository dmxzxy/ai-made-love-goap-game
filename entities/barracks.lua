-- Barracks for specialized unit production
local Barracks = {}
Barracks.__index = Barracks

-- Barracks types with different specializations
Barracks.types = {
    Infantry = {
        name = "Infantry Barracks",
        cost = 100,  -- 150→100
        buildTime = 4,  -- 5→4
        producesUnit = "Soldier",
        productionTime = 1.5,  -- 2→1.5
        productionCost = 28,  -- 40→28
        color = {0.6, 0.4, 0.2},
        description = "Produces Soldiers faster and cheaper"
    },
    Heavy = {
        name = "Heavy Barracks",
        cost = 180,  -- 250→180
        buildTime = 6,  -- 8→6
        producesUnit = "Tank",
        productionTime = 3,  -- 4→3
        productionCost = 55,  -- 80→55
        color = {0.5, 0.5, 0.5},
        description = "Produces Tanks at reduced cost"
    },
    Sniper = {
        name = "Sniper Tower",
        cost = 140,  -- 200→140
        buildTime = 5,  -- 6→5
        producesUnit = "Sniper",
        productionTime = 2.5,  -- 3→2.5
        productionCost = 42,  -- 60→42
        color = {0.3, 0.6, 0.3},
        description = "Produces Snipers at reduced cost"
    },
    Armory = {
        name = "Armory",
        cost = 130,  -- 180→130
        buildTime = 5,  -- 6→5
        producesUnit = "Gunner",
        productionTime = 2,  -- 2.5→2
        productionCost = 38,  -- 55→38
        color = {0.7, 0.3, 0.3},
        description = "Produces Gunners at reduced cost"
    },
    ScoutCamp = {
        name = "Scout Camp",
        cost = 100,  -- 140→100
        buildTime = 3,  -- 4→3
        producesUnit = "Scout",
        productionTime = 1.2,  -- 1.5→1.2
        productionCost = 32,  -- 45→32
        color = {0.4, 0.7, 0.9},
        description = "Produces fast Scouts for reconnaissance"
    },
    Hospital = {
        name = "Field Hospital",
        cost = 160,  -- 220→160
        buildTime = 5,  -- 7→5
        producesUnit = "Healer",
        productionTime = 2.8,  -- 3.5→2.8
        productionCost = 42,  -- 60→42
        color = {1, 1, 1},
        description = "Produces Healers to support troops"
    },
    Workshop = {
        name = "Demolition Workshop",
        cost = 170,  -- 240→170
        buildTime = 5,  -- 7→5
        producesUnit = "Demolisher",
        productionTime = 3,  -- 3.8→3
        productionCost = 48,  -- 70→48
        color = {0.9, 0.5, 0.1},
        description = "Produces Demolishers for siege warfare"
    },
    RangerPost = {
        name = "Ranger Post",
        cost = 150,  -- 210→150
        buildTime = 5,  -- 6→5
        producesUnit = "Ranger",
        productionTime = 2.5,  -- 3.2→2.5
        productionCost = 45,  -- 65→45
        color = {0.2, 0.5, 0.2},
        description = "Produces Rangers with extreme range"
    }
}

function Barracks.new(x, y, barracksType, team, teamColor)
    local self = setmetatable({}, Barracks)
    
    self.x = x
    self.y = y
    self.type = barracksType
    self.team = team
    self.teamColor = teamColor
    
    local typeData = Barracks.types[barracksType]
    self.name = typeData.name
    self.producesUnit = typeData.producesUnit
    self.productionTime = typeData.productionTime
    self.productionCost = typeData.productionCost
    self.color = typeData.color
    self.description = typeData.description
    
    self.size = 40
    self.health = 300
    self.maxHealth = 300
    self.isDead = false
    
    -- Building state
    self.isBuilding = true
    self.buildProgress = 0
    self.buildTime = typeData.buildTime
    
    -- Production state
    self.productionProgress = 0
    self.isProducing = false
    self.unitsProduced = 0
    
    return self
end

function Barracks:update(dt, resources)
    if self.isDead then
        return false, nil
    end
    
    -- Building phase
    if self.isBuilding then
        self.buildProgress = self.buildProgress + dt
        if self.buildProgress >= self.buildTime then
            self.isBuilding = false
            self.buildProgress = 0
            print(string.format("[%s] %s construction complete!", 
                self.team:upper(), self.name))
        end
        return false, nil
    end
    
    -- Production phase
    if not self.isProducing and resources >= self.productionCost then
        self.isProducing = true
        self.productionProgress = 0
    end
    
    if self.isProducing then
        self.productionProgress = self.productionProgress + dt
        
        if self.productionProgress >= self.productionTime then
            self.productionProgress = 0
            self.isProducing = false
            self.unitsProduced = self.unitsProduced + 1
            return true, self.producesUnit, self.productionCost
        end
    end
    
    return false, nil, 0
end

function Barracks:takeDamage(damage)
    if self.isDead then return end
    
    self.health = self.health - damage
    
    if self.health <= 0 then
        self.health = 0
        self.isDead = true
        print(string.format("[%s] %s destroyed!", self.team:upper(), self.name))
    end
end

function Barracks:getSpawnPosition()
    local angle = math.random() * math.pi * 2
    local distance = self.size + 30
    return self.x + math.cos(angle) * distance,
           self.y + math.sin(angle) * distance
end

function Barracks:draw()
    if self.isDead then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.rectangle("fill", self.x - self.size/2, self.y - self.size/2, 
            self.size, self.size)
        return
    end
    
    -- Building phase visualization
    if self.isBuilding then
        local progress = self.buildProgress / self.buildTime
        
        -- Construction scaffold
        love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
        love.graphics.rectangle("fill", self.x - self.size/2, self.y - self.size/2, 
            self.size, self.size)
        
        -- Progress fill
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.7)
        love.graphics.rectangle("fill", self.x - self.size/2, 
            self.y - self.size/2 + self.size * (1 - progress), 
            self.size, self.size * progress)
        
        -- Border
        love.graphics.setColor(self.teamColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x - self.size/2, self.y - self.size/2, 
            self.size, self.size)
        love.graphics.setLineWidth(1)
        
        -- Build progress text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%.0f%%", progress * 100), 
            self.x - 12, self.y - 5, 0, 0.8, 0.8)
        
        return
    end
    
    -- Completed barracks
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x - self.size/2, self.y - self.size/2, 
        self.size, self.size)
    
    -- Team color accent
    love.graphics.setColor(self.teamColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", self.x - self.size/2, self.y - self.size/2, 
        self.size, self.size)
    love.graphics.setLineWidth(1)
    
    -- Inner detail
    love.graphics.setColor(self.color[1] * 0.7, self.color[2] * 0.7, self.color[3] * 0.7)
    love.graphics.rectangle("fill", self.x - self.size/3, self.y - self.size/3, 
        self.size * 0.66, self.size * 0.66)
    
    -- Health bar
    local barWidth = self.size
    local barHeight = 6
    local healthPercent = self.health / self.maxHealth
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x - barWidth/2, self.y - self.size/2 - 12, 
        barWidth, barHeight)
    
    local healthColor = {0.2 + (1 - healthPercent) * 0.8, healthPercent * 0.8, 0.2}
    love.graphics.setColor(healthColor)
    love.graphics.rectangle("fill", self.x - barWidth/2, self.y - self.size/2 - 12, 
        barWidth * healthPercent, barHeight)
    
    -- Production indicator
    if self.isProducing then
        local prodPercent = self.productionProgress / self.productionTime
        love.graphics.setColor(0, 1, 1, 0.8)
        love.graphics.rectangle("fill", self.x - barWidth/2, self.y + self.size/2 + 6, 
            barWidth * prodPercent, 4)
        
        love.graphics.setColor(0.5, 1, 1)
        love.graphics.print(string.format("%.0f%%", prodPercent * 100), 
            self.x - 12, self.y + self.size/2 + 12, 0, 0.7, 0.7)
    end
    
    -- Unit type icon
    love.graphics.setColor(1, 1, 1, 0.9)
    local unitInitial = self.producesUnit:sub(1, 1)
    love.graphics.print(unitInitial, self.x - 5, self.y - 8, 0, 1.5, 1.5)
end

return Barracks
