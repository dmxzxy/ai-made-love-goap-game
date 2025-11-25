-- 科技树系统
local TechTree = {}
TechTree.__index = TechTree

-- 科技定义
TechTree.techs = {
    -- 经济科技
    improvedMining = {
        name = "Improved Mining",
        displayName = "改良采矿",
        cost = 300,
        researchTime = 15,
        description = "矿工采集速度+30%",
        category = "economy",
        icon = "⛏",
        effects = {
            miningSpeedBonus = 0.3
        }
    },
    efficientStorage = {
        name = "Efficient Storage",
        displayName = "高效储存",
        cost = 250,
        researchTime = 12,
        description = "资源上限+50%",
        category = "economy",
        icon = "📦",
        effects = {
            storageBonus = 0.5
        }
    },
    
    -- 军事科技
    advancedWeapons = {
        name = "Advanced Weapons",
        displayName = "先进武器",
        cost = 400,
        researchTime = 20,
        description = "所有单位攻击力+25%",
        category = "military",
        icon = "⚔",
        effects = {
            damageBonus = 0.25
        }
    },
    combatArmor = {
        name = "Combat Armor",
        displayName = "战斗护甲",
        cost = 450,
        researchTime = 25,
        description = "所有单位生命值+30%",
        category = "military",
        icon = "🛡",
        effects = {
            healthBonus = 0.3
        }
    },
    tacticalTraining = {
        name = "Tactical Training",
        displayName = "战术训练",
        cost = 350,
        researchTime = 18,
        description = "单位移动速度+20%，攻击速度+15%",
        category = "military",
        icon = "🎯",
        effects = {
            speedBonus = 0.2,
            attackSpeedBonus = 0.15
        }
    },
    
    -- 防御科技
    fortification = {
        name = "Fortification",
        displayName = "强化防御",
        cost = 500,
        researchTime = 30,
        description = "防御塔和基地生命值+50%，防御塔伤害+30%",
        category = "defense",
        icon = "🏰",
        effects = {
            structureHealthBonus = 0.5,
            towerDamageBonus = 0.3
        }
    },
    advancedSensors = {
        name = "Advanced Sensors",
        displayName = "高级传感器",
        cost = 300,
        researchTime = 15,
        description = "单位视野+50%，防御塔射程+20%",
        category = "defense",
        icon = "👁",
        effects = {
            visionBonus = 0.5,
            towerRangeBonus = 0.2
        }
    },
    
    -- 特殊科技
    fieldMedic = {
        name = "Field Medic",
        displayName = "战地医疗",
        cost = 400,
        researchTime = 20,
        description = "所有单位获得缓慢生命恢复",
        category = "special",
        icon = "💊",
        effects = {
            regeneration = true
        }
    },
    rapidDeployment = {
        name = "Rapid Deployment",
        displayName = "快速部署",
        cost = 350,
        researchTime = 15,
        description = "单位生产速度+40%",
        category = "special",
        icon = "⚡",
        effects = {
            productionSpeedBonus = 0.4
        }
    }
}

function TechTree.new(team)
    local self = setmetatable({}, TechTree)
    self.team = team
    self.researchedTechs = {}
    self.currentResearch = nil
    self.researchProgress = 0
    return self
end

function TechTree:update(dt, base)
    if self.currentResearch then
        self.researchProgress = self.researchProgress + dt
        
        local tech = TechTree.techs[self.currentResearch]
        if self.researchProgress >= tech.researchTime then
            -- 研究完成
            self:completeTech(self.currentResearch, base)
        end
    end
end

function TechTree:startResearch(techName, base)
    local tech = TechTree.techs[techName]
    if not tech then
        return false, "Invalid tech"
    end
    
    if self.researchedTechs[techName] then
        return false, "Already researched"
    end
    
    if self.currentResearch then
        return false, "Already researching"
    end
    
    if base.resources < tech.cost then
        return false, "Not enough resources"
    end
    
    base.resources = base.resources - tech.cost
    self.currentResearch = techName
    self.researchProgress = 0
    
    print(string.format("[%s] Started researching: %s", self.team:upper(), tech.displayName))
    return true
end

function TechTree:completeTech(techName, base)
    local tech = TechTree.techs[techName]
    self.researchedTechs[techName] = true
    self.currentResearch = nil
    self.researchProgress = 0
    
    print(string.format("[%s] Research complete: %s", self.team:upper(), tech.displayName))
    
    -- 应用科技效果到基地
    if tech.effects.storageBonus then
        base.maxResources = base.maxResources * (1 + tech.effects.storageBonus)
    end
    if tech.effects.productionSpeedBonus then
        base.productionTime = base.productionTime / (1 + tech.effects.productionSpeedBonus)
    end
    if tech.effects.structureHealthBonus then
        base.maxHealth = base.maxHealth * (1 + tech.effects.structureHealthBonus)
        base.health = base.health * (1 + tech.effects.structureHealthBonus)
    end
end

function TechTree:hasTech(techName)
    return self.researchedTechs[techName] == true
end

function TechTree:getTechBonus(bonusType)
    local total = 0
    for techName, _ in pairs(self.researchedTechs) do
        local tech = TechTree.techs[techName]
        if tech.effects[bonusType] then
            total = total + tech.effects[bonusType]
        end
    end
    return total
end

function TechTree:hasRegeneration()
    return self:hasTech("fieldMedic")
end

return TechTree
