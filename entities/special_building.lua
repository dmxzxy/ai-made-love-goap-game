-- Special Buildings System
local SpecialBuilding = {}
SpecialBuilding.__index = SpecialBuilding

-- Special building types with unique abilities
SpecialBuilding.types = {
    ResearchLab = {
        name = "Research Lab",
        cost = 200,
        buildTime = 8,
        color = {0.4, 0.6, 0.9},
        size = 30,
        health = 350,
        description = "Reduces tech research time by 25%",
        effect = "researchSpeed",
        effectValue = 0.25,
        radius = 0  -- Global effect
    },
    MedicalStation = {
        name = "Medical Station",
        cost = 180,
        buildTime = 7,
        color = {0.3, 0.9, 0.5},
        size = 28,
        health = 300,
        description = "Nearby units regenerate 2 HP/sec",
        effect = "areaRegen",
        effectValue = 2,
        radius = 300
    },
    Arsenal = {
        name = "Arsenal",
        cost = 250,
        buildTime = 10,
        color = {0.9, 0.5, 0.3},
        size = 32,
        health = 400,
        description = "Nearby units gain +15% damage",
        effect = "areaDamage",
        effectValue = 0.15,
        radius = 350
    },
    TrainingGround = {
        name = "Training Ground",
        cost = 150,
        buildTime = 6,
        color = {0.7, 0.7, 0.4},
        size = 35,
        health = 280,
        description = "Reduces unit production time by 20%",
        effect = "productionSpeed",
        effectValue = 0.20,
        radius = 0  -- Global effect
    },
    Fortress = {
        name = "Fortress",
        cost = 300,
        buildTime = 12,
        color = {0.5, 0.5, 0.5},
        size = 38,
        health = 600,
        description = "Nearby units gain +20% health and armor",
        effect = "areaDefense",
        effectValue = 0.20,
        radius = 400
    },
    ResourceDepot = {
        name = "Resource Depot",
        cost = 120,
        buildTime = 5,
        color = {0.9, 0.8, 0.4},
        size = 26,
        health = 250,
        description = "Increases resource storage by 30%",
        effect = "storage",
        effectValue = 0.30,
        radius = 0  -- Global effect
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
    self.isBuilding = true
    self.buildProgress = 0
    self.buildTime = config.buildTime
    self.isComplete = false
    
    -- Animation
    self.pulseTimer = 0
    
    return self
end

function SpecialBuilding.update(self, dt)
    if self.isDead then return end
    
    -- Building progress
    if not self.isComplete then
        self.buildProgress = self.buildProgress + dt
        if self.buildProgress >= self.buildTime then
            self.isComplete = true
            print(string.format("%s completed for %s team", self.name, self.team))
        end
        return
    end
    
    -- Animation
    self.pulseTimer = self.pulseTimer + dt
end

function SpecialBuilding.draw(self, offsetX, offsetY)
    if self.isDead then return end
    
    local x = self.x - offsetX
    local y = self.y - offsetY
    
    -- Don't draw if off screen
    if x < -50 or x > 1650 or y < -50 or y > 950 then
        return
    end
    
    if not self.isComplete then
        -- Building in progress
        love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
        love.graphics.rectangle("fill", x - self.size/2, y - self.size/2, self.size, self.size, 4, 4)
        
        -- Progress bar
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", x - self.size/2, y + self.size/2 + 5, self.size, 6)
        love.graphics.setColor(0.3, 0.8, 0.3)
        local progress = math.min(self.buildProgress / self.buildTime, 1)
        love.graphics.rectangle("fill", x - self.size/2, y + self.size/2 + 5, self.size * progress, 6)
    else
        -- Completed building
        local pulse = math.sin(self.pulseTimer * 2) * 0.1 + 0.9
        love.graphics.setColor(self.color[1] * pulse, self.color[2] * pulse, self.color[3] * pulse, 0.9)
        love.graphics.rectangle("fill", x - self.size/2, y - self.size/2, self.size, self.size, 5, 5)
        
        -- Border
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x - self.size/2, y - self.size/2, self.size, self.size, 5, 5)
        love.graphics.setLineWidth(1)
        
        -- Effect radius visualization (if has area effect)
        if self.radius > 0 then
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.1)
            love.graphics.circle("fill", x, y, self.radius)
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.3)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", x, y, self.radius)
        end
        
        -- Icon/Symbol
        love.graphics.setColor(1, 1, 1, 0.9)
        local iconText = ""
        if self.buildingType == "ResearchLab" then
            iconText = "R"
        elseif self.buildingType == "MedicalStation" then
            iconText = "+"
        elseif self.buildingType == "Arsenal" then
            iconText = "A"
        elseif self.buildingType == "TrainingGround" then
            iconText = "T"
        elseif self.buildingType == "Fortress" then
            iconText = "F"
        elseif self.buildingType == "ResourceDepot" then
            iconText = "D"
        end
        love.graphics.print(iconText, x - 6, y - 10, 0, 1.8, 1.8)
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

function SpecialBuilding.takeDamage(self, amount)
    if self.isDead or not self.isComplete then return end
    
    self.health = self.health - amount
    if self.health <= 0 then
        self.health = 0
        self.isDead = true
        print(string.format("%s destroyed!", self.name))
    end
end

-- Apply building effects to units in range
function SpecialBuilding.applyEffects(self, units)
    if not self.isComplete or self.isDead then return end
    
    for _, unit in ipairs(units) do
        if not unit.isDead and unit.team == self.team then
            local distance = math.sqrt((unit.x - self.x)^2 + (unit.y - self.y)^2)
            
            if self.radius == 0 or distance <= self.radius then
                -- Mark unit as affected by this building
                if not unit.buildingEffects then
                    unit.buildingEffects = {}
                end
                unit.buildingEffects[self.effect] = self.effectValue
            end
        end
    end
end

return SpecialBuilding
