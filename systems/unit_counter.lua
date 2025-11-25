-- 兵种克制系统
local UnitCounter = {}

-- 克制关系表
-- 克制者对被克制者造成额外伤害
UnitCounter.counterMatrix = {
    -- 坦克克制近战单位
    Tank = {
        Soldier = 1.5,    -- 坦克对士兵额外50%伤害
        Scout = 1.4,      -- 对侦察兵额外40%
    },
    
    -- 狙击手克制远程单位
    Sniper = {
        Gunner = 1.6,     -- 狙击手对机枪手额外60%
        Ranger = 1.4,     -- 对游侠额外40%
        Sniper = 1.3,     -- 狙击手对狙（先手优势）
    },
    
    -- 侦察兵克制狙击手（快速接近）
    Scout = {
        Sniper = 1.5,
        Ranger = 1.3,
    },
    
    -- 机枪手克制轻甲单位（火力压制）
    Gunner = {
        Scout = 1.4,
        Soldier = 1.2,
    },
    
    -- 爆破兵克制建筑
    Demolisher = {
        Tower = 2.0,      -- 对防御塔双倍伤害
        Base = 1.5,       -- 对基地额外50%
    },
    
    -- 士兵克制矿工（基础兵种）
    Soldier = {
        Miner = 1.8,
    },
    
    -- 游侠克制低护甲目标
    Ranger = {
        Healer = 1.7,
        Miner = 1.5,
    },
    
    -- 治疗兵被所有战斗单位克制（脆弱）
    Healer = {
        -- 治疗兵不克制任何单位
    }
}

-- 获取伤害加成
function UnitCounter.getDamageMultiplier(attackerClass, targetClass)
    if not attackerClass or not targetClass then
        return 1.0
    end
    
    -- 检查克制关系
    if UnitCounter.counterMatrix[attackerClass] then
        local multiplier = UnitCounter.counterMatrix[attackerClass][targetClass]
        if multiplier then
            return multiplier
        end
    end
    
    return 1.0
end

-- 检查是否克制
function UnitCounter.isCounter(attackerClass, targetClass)
    return UnitCounter.getDamageMultiplier(attackerClass, targetClass) > 1.0
end

-- 获取被克制的单位列表
function UnitCounter.getCounteredBy(unitClass)
    local counters = {}
    for attackerClass, targets in pairs(UnitCounter.counterMatrix) do
        if targets[unitClass] then
            table.insert(counters, {
                class = attackerClass,
                multiplier = targets[unitClass]
            })
        end
    end
    return counters
end

-- 获取克制的单位列表
function UnitCounter.getCounters(unitClass)
    local counters = {}
    if UnitCounter.counterMatrix[unitClass] then
        for targetClass, multiplier in pairs(UnitCounter.counterMatrix[unitClass]) do
            table.insert(counters, {
                class = targetClass,
                multiplier = multiplier
            })
        end
    end
    return counters
end

return UnitCounter
