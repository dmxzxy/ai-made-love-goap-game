-- Commander System
local Commander = {}

-- Commander Definitions
Commander.commanders = {
    {
        id = 1,
        name = "Iron General",
        title = "Offense Specialist",
        icon = "",
        description = "Excels at rapid offense and direct combat",
        perks = {
            {
                name = "Damage +20%",
                type = "damageBonus",
                value = 0.2
            },
            {
                name = "Attack Speed +15%",
                type = "attackSpeedBonus",
                value = 0.15
            },
            {
                name = "Unit Cost -10%",
                type = "costReduction",
                value = 0.1
            }
        }
    },
    {
        id = 2,
        name = "Guardian",
        title = "Defense Master",
        icon = "",
        description = "Excels at defense and attrition warfare",
        perks = {
            {
                name = "Health +30%",
                type = "healthBonus",
                value = 0.3
            },
            {
                name = "Structure Health +40%",
                type = "structureHealthBonus",
                value = 0.4
            },
            {
                name = "Auto Regeneration",
                type = "regeneration",
                value = 3  -- 3 HP per second
            }
        }
    },
    {
        id = 3,
        name = "Resource Tycoon",
        title = "Economy Expert",
        icon = "",
        description = "Excels at economic development and resource management",
        perks = {
            {
                name = "Mining Speed +40%",
                type = "miningSpeedBonus",
                value = 0.4
            },
            {
                name = "Storage Capacity +60%",
                type = "storageBonus",
                value = 0.6
            },
            {
                name = "Starting Resources +200",
                type = "startingResources",
                value = 200
            }
        }
    },
    {
        id = 4,
        name = "Tactical Master",
        title = "Versatile Commander",
        icon = "",
        description = "Balanced development with tactical superiority",
        perks = {
            {
                name = "Movement Speed +25%",
                type = "speedBonus",
                value = 0.25
            },
            {
                name = "Vision Range +40%",
                type = "visionBonus",
                value = 0.4
            },
            {
                name = "Critical Rate +10%",
                type = "critBonus",
                value = 0.1
            }
        }
    }
}

-- Player selected commander
Commander.playerCommander = nil

function Commander.selectCommander(commanderId)
    for _, cmd in ipairs(Commander.commanders) do
        if cmd.id == commanderId then
            Commander.playerCommander = cmd
            print(string.format("Selected Commander: %s - %s", cmd.name, cmd.title))
            return true
        end
    end
    return false
end

-- Apply commander bonuses to unit
function Commander.applyToUnit(unit, commanderData)
    if not commanderData then return end
    
    for _, perk in ipairs(commanderData.perks) do
        if perk.type == "damageBonus" then
            unit.attackDamage = unit.attackDamage * (1 + perk.value)
        elseif perk.type == "healthBonus" then
            unit.maxHealth = unit.maxHealth * (1 + perk.value)
            unit.health = unit.maxHealth
        elseif perk.type == "attackSpeedBonus" then
            unit.attackSpeed = unit.attackSpeed / (1 + perk.value)
        elseif perk.type == "speedBonus" then
            unit.moveSpeed = unit.moveSpeed * (1 + perk.value)
        elseif perk.type == "visionBonus" then
            unit.aggroRadius = unit.aggroRadius * (1 + perk.value)
        elseif perk.type == "regeneration" then
            if not unit.isMiner then
                unit.hasRegen = true
                unit.regenRate = perk.value
            end
        elseif perk.type == "critBonus" then
            unit.critChance = unit.critChance + perk.value
        elseif perk.type == "miningSpeedBonus" and unit.isMiner then
            unit.miningRate = unit.miningRate * (1 + perk.value)
        end
    end
end

-- Apply commander bonuses to base
function Commander.applyToBase(base, commanderData)
    if not commanderData then return end
    
    for _, perk in ipairs(commanderData.perks) do
        if perk.type == "storageBonus" then
            base.maxResources = base.maxResources * (1 + perk.value)
        elseif perk.type == "structureHealthBonus" then
            base.maxHealth = base.maxHealth * (1 + perk.value)
            base.health = base.maxHealth
        elseif perk.type == "startingResources" then
            base.resources = base.resources + perk.value
        elseif perk.type == "miningSpeedBonus" then
            base.miningRate = base.miningRate * (1 + perk.value)
        elseif perk.type == "costReduction" then
            -- Reduce all unit costs
            for unitType, cost in pairs(base.unitCosts) do
                base.unitCosts[unitType] = math.floor(cost * (1 - perk.value))
            end
        end
    end
end

-- Get commander information
function Commander.getCommanderInfo(commanderId)
    for _, cmd in ipairs(Commander.commanders) do
        if cmd.id == commanderId then
            return cmd
        end
    end
    return nil
end

-- AI randomly selects commander
function Commander.selectRandomCommander()
    local randomId = math.random(1, #Commander.commanders)
    return Commander.commanders[randomId]
end

return Commander
