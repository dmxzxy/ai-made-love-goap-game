-- GOAP 战斗游戏主文件
local Agent = require("entities.agent")
local Base = require("entities.base")
local Resource = require("entities.resource")
local Barracks = require("entities.barracks")
local Tower = require("entities.tower")
local SpecialBuilding = require("entities.special_building")
local Particles = require("effects.particles")
local DamageNumbers = require("effects.damage_numbers")
local Minimap = require("ui.minimap")
local BattleNotifications = require("ui.battle_notifications")
local StartMenu = require("ui.start_menu")
local Commander = require("systems.commander")

-- 多方博弈配置
local TEAM_COUNT = 4  -- 可以设置为 2, 3, 或 4
local TEAM_CONFIGS = {
    {name = "red", color = {1, 0.2, 0.2}, displayName = "RED"},
    {name = "blue", color = {0.2, 0.2, 1}, displayName = "BLUE"},
    {name = "green", color = {0.2, 1, 0.2}, displayName = "GREEN"},
    {name = "yellow", color = {1, 1, 0.2}, displayName = "YELLOW"}
}

-- 游戏状态
local gameStarted = false

-- 全局变量（使用通用teams结构）
local teams = {}  -- teams[teamName] = {units = {}, base = nil, stats = {}}
local resources = {}
local gameOver = false
local winner = nil
local frameCount = 0
local debugInfo = {}
local selectedAgent = nil
local selectedBase = nil
local selectedBarracks = nil
local selectedTower = nil
local selectedSpecialBuilding = nil
local showMinimap = true  -- 小地图显示开关
local specialBuildings = {}  -- Special buildings list

-- 兼容性别名（保持旧代码兼容）
local redTeam, blueTeam, redBase, blueBase

-- 战斗数据统计（动态初始化）
local battleStats = {}

-- 初始化队伍统计
local function initBattleStats()
    battleStats = {}
    for i = 1, TEAM_COUNT do
        local teamName = TEAM_CONFIGS[i].name
        battleStats[teamName] = {
            kills = 0,
            deaths = 0,
            damageDealt = 0,
            damageReceived = 0,
            unitsProduced = 0,
            goldSpent = 0,
            goldMined = 0,
            buildingsBuilt = 0,
            towerKills = 0
        }
    end
end

-- 摄像机系统
local camera = {
    x = 800,         -- 摄像机初始偏移X（适配新地图，看向中间）
    y = 450,         -- 摄像机初始偏移Y（适配新地图，看向中间）
    scale = 0.6,     -- 初始缩放比例（缩小以看到更大的地图）
    minScale = 0.3,  -- 最小缩放（可以看到整个战场）
    maxScale = 2.0,  -- 最大缩放
    isDragging = false,
    dragStartX = 0,
    dragStartY = 0,
    dragStartCamX = 0,
    dragStartCamY = 0,
    shakeX = 0,      -- 屏幕震动X偏移
    shakeY = 0,      -- 屏幕震动Y偏移
    shakeIntensity = 0  -- 震动强度
}

function love.load()
    -- 设置窗口
    love.window.setTitle("GOAP Battle Game - Multi-Team Strategic Warfare")
    love.window.setMode(1600, 900)
    
    -- 初始化开始菜单
    StartMenu.init()
    gameStarted = false
end

function startGame()
    -- 实际游戏世界更大（扩大地图）
    WORLD_WIDTH = 3200  -- 2400→3200
    WORLD_HEIGHT = 1800  -- 1200→1800
    
    -- 应用菜单选择
    TEAM_COUNT = StartMenu.selectedTeamCount
    
    print("=== Game Starting ===")
    print(string.format("Team Count: %d", TEAM_COUNT))
    print("Mode: SPECTATOR - All teams are AI-controlled")
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))

    -- 初始化战斗统计
    initBattleStats()

    -- 初始化所有队伍
    teams = {}
    for i = 1, TEAM_COUNT do
        local config = TEAM_CONFIGS[i]
        teams[config.name] = {
            units = {},
            base = nil,
            config = config
        }
    end
    
    -- 计算基地位置（根据队伍数量）
    -- 中心点：(1600, 900)
    local centerX, centerY = WORLD_WIDTH / 2, WORLD_HEIGHT / 2
    local basePositions = {}
    
    if TEAM_COUNT == 4 then
        -- 4队：十字形分布（上、右、下、左），到中心距离相等
        local distanceFromCenter = 1200  -- 统一距离（扩大）
        basePositions = {
            {x = centerX, y = centerY - distanceFromCenter},  -- 上方（红队）
            {x = centerX + distanceFromCenter, y = centerY},  -- 右方（蓝队）2250, 900
            {x = centerX, y = centerY + distanceFromCenter},  -- 下方（绿队）1600, 1550
            {x = centerX - distanceFromCenter, y = centerY}   -- 左方（黄队）950, 900
        }
    elseif TEAM_COUNT == 3 then
        -- 3队：三角形分布，到中心距离相等
        local distanceFromCenter = 1200  -- 统一距离（扩大）
        local angle120 = math.pi * 2 / 3  -- 120度
        basePositions = {
            {x = centerX, y = centerY - distanceFromCenter},  -- 上方（红队）
            {x = centerX + distanceFromCenter * math.sin(angle120), y = centerY + distanceFromCenter * math.cos(angle120)},  -- 右下（蓝队）
            {x = centerX - distanceFromCenter * math.sin(angle120), y = centerY + distanceFromCenter * math.cos(angle120)}   -- 左下（绿队）
        }
    else
        -- 2队：左右对称，到中心距离相等
        local distanceFromCenter = 1200  -- 统一距离（扩大）
        basePositions = {
            {x = centerX - distanceFromCenter, y = centerY},  -- 左方（红队）
            {x = centerX + distanceFromCenter, y = centerY}   -- 右方（蓝队）
        }
    end
    
    -- 创建基地 - 使用准备界面分配的指挥官
    for i = 1, TEAM_COUNT do
        local config = TEAM_CONFIGS[i]
        local pos = basePositions[i]
        local base = Base.new(pos.x, pos.y, config.name, config.color)
        teams[config.name].base = base
        
        -- 使用准备界面预先分配的指挥官
        local commander = StartMenu.teamCommanders[i]
        if not commander then
            -- 如果没有预分配（不应该发生），随机选择
            commander = Commander.selectRandomCommander()
        end
        Commander.applyToBase(base, commander)
        base.commanderData = commander
        print(string.format("%s Team at (%.0f, %.0f) with Commander: %s (%s)", 
            config.displayName, pos.x, pos.y, commander.name, commander.title))
    end
    
    -- 设置兼容性别名
    redTeam = teams.red.units
    blueTeam = teams.blue.units
    redBase = teams.red.base
    blueBase = teams.blue.base
    
    -- 创建资源点（根据队伍数量动态分布）
    resources = {}
    if TEAM_COUNT == 2 then
        -- 2队模式：左右对称分布，确保公平
        local centerX = WORLD_WIDTH / 2  -- 1600
        
        -- 左侧资源（红队附近）- 5个
        table.insert(resources, Resource.new(450, 350))
        table.insert(resources, Resource.new(350, 550))
        table.insert(resources, Resource.new(550, 700))
        table.insert(resources, Resource.new(350, 900))
        table.insert(resources, Resource.new(500, 1100))
        
        -- 左中区域（偏红队）- 3个
        table.insert(resources, Resource.new(900, 450))
        table.insert(resources, Resource.new(850, 750))
        table.insert(resources, Resource.new(900, 1050))
        
        -- 中央争夺区（完全居中）- 5个
        table.insert(resources, Resource.new(centerX, 400))
        table.insert(resources, Resource.new(centerX, 650))
        table.insert(resources, Resource.new(centerX, 900))
        table.insert(resources, Resource.new(centerX, 1150))
        table.insert(resources, Resource.new(centerX, 1400))
        
        -- 右中区域（偏蓝队）- 3个
        table.insert(resources, Resource.new(2300, 450))
        table.insert(resources, Resource.new(2350, 750))
        table.insert(resources, Resource.new(2300, 1050))
        
        -- 右侧资源（蓝队附近）- 5个
        table.insert(resources, Resource.new(2750, 350))
        table.insert(resources, Resource.new(2850, 550))
        table.insert(resources, Resource.new(2650, 700))
        table.insert(resources, Resource.new(2850, 900))
        table.insert(resources, Resource.new(2700, 1100))
        
    elseif TEAM_COUNT == 3 then
        -- 3队模式：三角形平衡布局
        local centerX, centerY = WORLD_WIDTH / 2, WORLD_HEIGHT / 2  -- 1600, 900
        
        -- 左上区域（红队附近 250,250）- 5个
        table.insert(resources, Resource.new(450, 350))
        table.insert(resources, Resource.new(350, 500))
        table.insert(resources, Resource.new(550, 450))
        table.insert(resources, Resource.new(400, 650))
        table.insert(resources, Resource.new(650, 600))
        
        -- 右上区域（蓝队附近 2950,250）- 5个
        table.insert(resources, Resource.new(2750, 350))
        table.insert(resources, Resource.new(2850, 500))
        table.insert(resources, Resource.new(2650, 450))
        table.insert(resources, Resource.new(2800, 650))
        table.insert(resources, Resource.new(2550, 600))
        
        -- 左下区域（绿队附近 250,1550）- 5个
        table.insert(resources, Resource.new(450, 1450))
        table.insert(resources, Resource.new(350, 1300))
        table.insert(resources, Resource.new(550, 1350))
        table.insert(resources, Resource.new(400, 1150))
        table.insert(resources, Resource.new(650, 1200))
        
        -- 中心争夺区（三角形中心，平衡分布）- 9个
        table.insert(resources, Resource.new(centerX, centerY))  -- 正中心
        table.insert(resources, Resource.new(centerX - 200, centerY - 100))
        table.insert(resources, Resource.new(centerX + 200, centerY - 100))
        table.insert(resources, Resource.new(centerX - 200, centerY + 100))
        table.insert(resources, Resource.new(centerX + 200, centerY + 100))
        table.insert(resources, Resource.new(centerX, centerY - 200))
        table.insert(resources, Resource.new(centerX, centerY + 200))
        table.insert(resources, Resource.new(centerX - 300, centerY))
        table.insert(resources, Resource.new(centerX + 300, centerY))
    else
        -- 4队模式：十字形基地，资源完全对称公平分布
        local centerX, centerY = WORLD_WIDTH / 2, WORLD_HEIGHT / 2  -- 中心点 (1600, 900)
        local distanceFromCenter = 1200  -- 基地到中心的距离（扩大）
        local nearBaseDistance = 300    -- 近基地资源距离（扩大）
        local midDistance = 500         -- 中距离资源（扩大）
        
        -- 每个队伍获得完全相同的资源布局（相对于基地的位置）
        -- 上方（红队 1600,250 附近）- 5个
        table.insert(resources, Resource.new(centerX, centerY - distanceFromCenter + nearBaseDistance))  -- 基地前方
        table.insert(resources, Resource.new(centerX - 150, centerY - distanceFromCenter + 150))  -- 左前
        table.insert(resources, Resource.new(centerX + 150, centerY - distanceFromCenter + 150))  -- 右前
        table.insert(resources, Resource.new(centerX - 100, centerY - distanceFromCenter + 280))  -- 左中
        table.insert(resources, Resource.new(centerX + 100, centerY - distanceFromCenter + 280))  -- 右中
        
        -- 右方（蓝队 2250,900 附近）- 5个
        table.insert(resources, Resource.new(centerX + distanceFromCenter - nearBaseDistance, centerY))  -- 基地前方
        table.insert(resources, Resource.new(centerX + distanceFromCenter - 150, centerY - 150))  -- 上前
        table.insert(resources, Resource.new(centerX + distanceFromCenter - 150, centerY + 150))  -- 下前
        table.insert(resources, Resource.new(centerX + distanceFromCenter - 280, centerY - 100))  -- 上中
        table.insert(resources, Resource.new(centerX + distanceFromCenter - 280, centerY + 100))  -- 下中
        
        -- 下方（绿队 1600,1550 附近）- 5个
        table.insert(resources, Resource.new(centerX, centerY + distanceFromCenter - nearBaseDistance))  -- 基地前方
        table.insert(resources, Resource.new(centerX - 150, centerY + distanceFromCenter - 150))  -- 左前
        table.insert(resources, Resource.new(centerX + 150, centerY + distanceFromCenter - 150))  -- 右前
        table.insert(resources, Resource.new(centerX - 100, centerY + distanceFromCenter - 280))  -- 左中
        table.insert(resources, Resource.new(centerX + 100, centerY + distanceFromCenter - 280))  -- 右中
        
        -- 左方（黄队 950,900 附近）- 5个
        table.insert(resources, Resource.new(centerX - distanceFromCenter + nearBaseDistance, centerY))  -- 基地前方
        table.insert(resources, Resource.new(centerX - distanceFromCenter + 150, centerY - 150))  -- 上前
        table.insert(resources, Resource.new(centerX - distanceFromCenter + 150, centerY + 150))  -- 下前
        table.insert(resources, Resource.new(centerX - distanceFromCenter + 280, centerY - 100))  -- 上中
        table.insert(resources, Resource.new(centerX - distanceFromCenter + 280, centerY + 100))  -- 下中
        
        -- 中心争夺区（核心战场）- 13个，完全对称
        table.insert(resources, Resource.new(centerX, centerY))  -- 正中心
        
        -- 内圈（十字形，4个）
        table.insert(resources, Resource.new(centerX, centerY - 120))      -- 上
        table.insert(resources, Resource.new(centerX + 120, centerY))      -- 右
        table.insert(resources, Resource.new(centerX, centerY + 120))      -- 下
        table.insert(resources, Resource.new(centerX - 120, centerY))      -- 左
        
        -- 外圈（十字形，4个）
        table.insert(resources, Resource.new(centerX, centerY - 240))      -- 上
        table.insert(resources, Resource.new(centerX + 240, centerY))      -- 右
        table.insert(resources, Resource.new(centerX, centerY + 240))      -- 下
        table.insert(resources, Resource.new(centerX - 240, centerY))      -- 左
        
        -- 对角线（4个）
        table.insert(resources, Resource.new(centerX - 85, centerY - 85))  -- 左上
        table.insert(resources, Resource.new(centerX + 85, centerY - 85))  -- 右上
        table.insert(resources, Resource.new(centerX + 85, centerY + 85))  -- 右下
        table.insert(resources, Resource.new(centerX - 85, centerY + 85))  -- 左下
    end
    print(string.format("Created %d resource points for %d teams", #resources, TEAM_COUNT))
    
    -- 为每个队伍创建初始单位
    local initialCount = 8  -- 增加初始矿工数量（5→8）
    print(string.format("Initial units per team: %d Miners", initialCount))
    
    for teamIdx = 1, TEAM_COUNT do
        local config = TEAM_CONFIGS[teamIdx]
        local teamData = teams[config.name]
        local base = teamData.base
        
        for i = 1, initialCount do
            local x, y = base:getSpawnPosition()
            y = y + (i - 3) * 50  -- 垂直分布
            local agent = Agent.new(x, y, config.name, config.color, "Miner")
            
            -- 应用指挥官加成
            if base.commanderData then
                Commander.applyToUnit(agent, base.commanderData)
            end
            
            -- 设置朝向（朝向地图中心）
            local centerX, centerY = WORLD_WIDTH / 2, WORLD_HEIGHT / 2
            agent.angle = math.atan2(centerY - y, centerX - x)
            
            agent.myBase = base
            agent.resources = resources
            table.insert(teamData.units, agent)
            
            print(string.format("%s #%d [Miner]: HP=%.0f Speed=%.0f", 
                config.displayName, i, agent.health, agent.moveSpeed))
        end
    end
    
    -- 设置每个单位的敌人和盟友引用
    for teamIdx = 1, TEAM_COUNT do
        local config = TEAM_CONFIGS[teamIdx]
        local teamData = teams[config.name]
        
        for _, agent in ipairs(teamData.units) do
            agent.allies = teamData.units
            
            -- 敌人是所有其他队伍
            agent.enemies = {}
            agent.enemyBases = {}
            agent.enemyTowers = {}
            
            for otherIdx = 1, TEAM_COUNT do
                if otherIdx ~= teamIdx then
                    local otherConfig = TEAM_CONFIGS[otherIdx]
                    local otherTeam = teams[otherConfig.name]
                    
                    -- 添加敌方单位
                    for _, enemy in ipairs(otherTeam.units) do
                        table.insert(agent.enemies, enemy)
                    end
                    
                    -- 添加敌方基地
                    table.insert(agent.enemyBases, otherTeam.base)
                    
                    -- 添加敌方防御塔
                    for _, tower in ipairs(otherTeam.base.towers) do
                        table.insert(agent.enemyTowers, tower)
                    end
                end
            end
            
            -- 为兼容性设置enemyBase（随机选择一个敌方基地，避免总是攻击同一队伍）
            if #agent.enemyBases > 0 then
                local randomIndex = math.random(1, #agent.enemyBases)
                agent.enemyBase = agent.enemyBases[randomIndex]
            end
        end
    end
    
    print("=== Game Loaded ===")
    
    -- 初始化仇恨系统（每个队伍对其他队伍的仇恨值）
    _G.teamHatred = {}
    for i = 1, TEAM_COUNT do
        local teamName = TEAM_CONFIGS[i].name
        teamHatred[teamName] = {}
        for j = 1, TEAM_COUNT do
            if i ~= j then
                local otherName = TEAM_CONFIGS[j].name
                teamHatred[teamName][otherName] = 0  -- 初始仇恨值为0
            end
        end
    end
    
    -- 初始化特效系统
    Particles.init()
    DamageNumbers.init()
    BattleNotifications.init()
    
    -- 让BattleNotifications全局可访问（供其他模块调用）
    _G.BattleNotifications = BattleNotifications
    
    print("Visual effects systems initialized")

end

-- 增加仇恨值（当一个队伍攻击另一个队伍时）
function addHatred(attackerTeam, victimTeam, amount)
    if not _G.teamHatred then return end
    if not _G.teamHatred[victimTeam] then return end
    if not _G.teamHatred[victimTeam][attackerTeam] then return end
    
    -- 受害者对攻击者的仇恨增加
    _G.teamHatred[victimTeam][attackerTeam] = _G.teamHatred[victimTeam][attackerTeam] + amount
    
    -- 仇恨值上限
    if _G.teamHatred[victimTeam][attackerTeam] > 1000 then
        _G.teamHatred[victimTeam][attackerTeam] = 1000
    end
end

-- 获取对某个队伍的仇恨值
function getHatred(myTeam, targetTeam)
    if not _G.teamHatred then return 0 end
    if not _G.teamHatred[myTeam] then return 0 end
    if not _G.teamHatred[myTeam][targetTeam] then return 0 end
    return _G.teamHatred[myTeam][targetTeam]
end

-- 仇恨值衰减（每秒）
function decayHatred(dt)
    if not _G.teamHatred then return end
    
    local decayRate = 2 * dt  -- 每秒衰减2点
    for teamName, hatredMap in pairs(_G.teamHatred) do
        for targetTeam, value in pairs(hatredMap) do
            if value > 0 then
                hatredMap[targetTeam] = math.max(0, value - decayRate)
            end
        end
    end
end

-- 辅助函数：统计队伍单位
local function countTeamUnits(teamUnits)
    local alive = 0
    local miners = 0
    for _, agent in ipairs(teamUnits) do
        if agent.health > 0 and not agent.isDead then
            alive = alive + 1
            if agent.isMiner then
                miners = miners + 1
            end
        end
    end
    return alive, miners
end

-- 辅助函数：更新单个队伍
local function updateTeam(teamName, dt, Barracks, Tower)
    local teamData = teams[teamName]
    if not teamData or teamData.base.isDead then
        return
    end
    
    local base = teamData.base
    local units = teamData.units
    local alive, miners = countTeamUnits(units)
    
    -- 更新战术策略
    if frameCount % 60 == 0 then
        -- 计算所有敌方单位总数
        local totalEnemies = 0
        for otherIdx = 1, TEAM_COUNT do
            if TEAM_CONFIGS[otherIdx].name ~= teamName then
                local otherTeam = teams[TEAM_CONFIGS[otherIdx].name]
                if otherTeam and not otherTeam.base.isDead then
                    local enemyAlive = countTeamUnits(otherTeam.units)
                    totalEnemies = totalEnemies + enemyAlive
                end
            end
        end
        base:updateStrategy(miners, alive, totalEnemies)
    end
    
    -- 更新基地并生产单位
    base.minerBonus = miners * 2
    local shouldSpawn, unitClass = base:update(dt, alive, resources, miners)
    
    if shouldSpawn and unitClass and alive < base.maxUnits then
        local x, y = base:getSpawnPosition()
        local agent = Agent.new(x, y, teamName, teamData.config.color, unitClass)
        
        -- 应用指挥官加成
        if base.commanderData then
            Commander.applyToUnit(agent, base.commanderData)
        end
        
        -- 应用科技加成
        if base.techTree then
            local damageBonus = base.techTree:getTechBonus("damageBonus")
            local healthBonus = base.techTree:getTechBonus("healthBonus")
            local speedBonus = base.techTree:getTechBonus("speedBonus")
            local attackSpeedBonus = base.techTree:getTechBonus("attackSpeedBonus")
            local visionBonus = base.techTree:getTechBonus("visionBonus")
            
            if damageBonus > 0 then
                agent.attackDamage = agent.attackDamage * (1 + damageBonus)
            end
            if healthBonus > 0 then
                agent.maxHealth = agent.maxHealth * (1 + healthBonus)
                agent.health = agent.maxHealth
            end
            if speedBonus > 0 then
                agent.moveSpeed = agent.moveSpeed * (1 + speedBonus)
            end
            if attackSpeedBonus > 0 then
                agent.attackSpeed = agent.attackSpeed / (1 + attackSpeedBonus)
            end
            if visionBonus > 0 then
                agent.aggroRadius = agent.aggroRadius * (1 + visionBonus)
            end
            if base.techTree:hasRegeneration() and not agent.isMiner then
                agent.hasRegen = true
                agent.regenRate = 2  -- 每秒恢复2点生命
            end
            
            -- 矿工采集加成
            if agent.isMiner then
                local miningBonus = base.techTree:getTechBonus("miningSpeedBonus")
                if miningBonus > 0 then
                    agent.miningRate = agent.miningRate * (1 + miningBonus)
                end
            end
        end
        
        -- 设置朝向
        local centerX, centerY = WORLD_WIDTH / 2, WORLD_HEIGHT / 2
        agent.angle = math.atan2(centerY - y, centerX - x)
        
        -- 设置引用
        agent.myBase = base
        agent.resources = resources
        agent.allies = units
        
        -- 设置所有敌人
        agent.enemies = {}
        agent.enemyBases = {}
        agent.enemyTowers = {}
        for otherIdx = 1, TEAM_COUNT do
            if TEAM_CONFIGS[otherIdx].name ~= teamName then
                local otherTeam = teams[TEAM_CONFIGS[otherIdx].name]
                for _, enemy in ipairs(otherTeam.units) do
                    table.insert(agent.enemies, enemy)
                end
                table.insert(agent.enemyBases, otherTeam.base)
                for _, tower in ipairs(otherTeam.base.towers) do
                    table.insert(agent.enemyTowers, tower)
                end
            end
        end
        if #agent.enemyBases > 0 then
            agent.enemyBase = agent.enemyBases[1]
        end
        
        table.insert(units, agent)
        battleStats[teamName].unitsProduced = battleStats[teamName].unitsProduced + 1
        print(string.format("[%s] %s spawned! Total: %d (Miners: %d) [%s Mode]", 
            teamData.config.displayName, unitClass, alive + 1, miners, base.strategy.mode:upper()))
    end
    
    -- 自动建造兵营和防御塔
    if frameCount % 300 == 0 then
        base:tryAutoBuildBarracks(Barracks)
    end
    if frameCount % 600 == 100 then
        base:tryAutoBuildTower(Tower)
    end
    
    -- AI自动建造特殊建筑（每10秒检查一次）
    if frameCount % 600 == 200 then
        local buildingType = base:shouldBuildSpecialBuilding(specialBuildings)
        if buildingType then
            tryBuildSpecialBuilding(base, buildingType)
        end
    end
    
    -- 更新防御塔
    for i = #base.towers, 1, -1 do
        local tower = base.towers[i]
        -- 防御塔攻击所有敌方单位
        local allEnemies = {}
        for otherIdx = 1, TEAM_COUNT do
            if TEAM_CONFIGS[otherIdx].name ~= teamName then
                local otherTeam = teams[TEAM_CONFIGS[otherIdx].name]
                for _, enemy in ipairs(otherTeam.units) do
                    table.insert(allEnemies, enemy)
                end
            end
        end
        tower:update(dt, allEnemies)
        if tower.isDead then
            table.remove(base.towers, i)
        end
    end
    
    -- 更新兵营生产
    for i, barracks in ipairs(base.barracks) do
        local shouldSpawn, unitType, cost = barracks:update(dt, base.resources)
        local availableGold = math.max(0, base.resources - base.strategy.reservedGold)
        if shouldSpawn and unitType and alive < base.maxUnits and availableGold >= cost then
            base.resources = math.max(0, base.resources - cost)
            battleStats[teamName].goldSpent = battleStats[teamName].goldSpent + cost
            local x, y = barracks:getSpawnPosition()
            local agent = Agent.new(x, y, teamName, teamData.config.color, unitType)
            
            -- 应用指挥官加成
            if base.commanderData then
                Commander.applyToUnit(agent, base.commanderData)
            end
            
            local centerX, centerY = WORLD_WIDTH / 2, WORLD_HEIGHT / 2
            agent.angle = math.atan2(centerY - y, centerX - x)
            
            agent.myBase = base
            agent.resources = resources
            agent.allies = units
            agent.enemies = {}
            agent.enemyBases = {}
            agent.enemyTowers = {}
            for otherIdx = 1, TEAM_COUNT do
                if TEAM_CONFIGS[otherIdx].name ~= teamName then
                    local otherTeam = teams[TEAM_CONFIGS[otherIdx].name]
                    for _, enemy in ipairs(otherTeam.units) do
                        table.insert(agent.enemies, enemy)
                    end
                    table.insert(agent.enemyBases, otherTeam.base)
                    for _, tower in ipairs(otherTeam.base.towers) do
                        table.insert(agent.enemyTowers, tower)
                    end
                end
            end
            if #agent.enemyBases > 0 then
                -- 随机选择一个敌方基地作为初始目标，避免总是攻击同一队伍
                local randomIndex = math.random(1, #agent.enemyBases)
                agent.enemyBase = agent.enemyBases[randomIndex]
            end
            
            table.insert(units, agent)
            battleStats[teamName].unitsProduced = battleStats[teamName].unitsProduced + 1
            print(string.format("[%s Barracks %d] %s spawned! Total: %d", 
                teamData.config.displayName, i, unitType, alive + 1))
        end
    end
    
    -- 更新所有单位
    for _, agent in ipairs(units) do
        agent:update(dt)
    end
end

function love.update(dt)
    -- 如果在开始菜单，只更新菜单
    if not gameStarted then
        StartMenu.update(dt)
        return
    end
    
    frameCount = frameCount + 1
    
    if gameOver then
        return
    end
    
    -- 更新特效系统
    Particles.update(dt)
    DamageNumbers.update(dt)
    BattleNotifications.update(dt)
    
    -- 仇恨值衰减
    decayHatred(dt)
    
    -- 更新摄像机震动
    if camera.shakeIntensity > 0 then
        camera.shakeX = (math.random() - 0.5) * camera.shakeIntensity
        camera.shakeY = (math.random() - 0.5) * camera.shakeIntensity
        camera.shakeIntensity = camera.shakeIntensity * 0.9
        if camera.shakeIntensity < 0.1 then
            camera.shakeIntensity = 0
            camera.shakeX = 0
            camera.shakeY = 0
        end
    end
    
    -- 更新资源点
    for _, resource in ipairs(resources) do
        resource:update(dt)
    end
    
    -- 更新特殊建筑
    for i = #specialBuildings, 1, -1 do
        local building = specialBuildings[i]
        building:update(dt)
        
        -- Remove dead buildings
        if building.isDead then
            table.remove(specialBuildings, i)
        elseif building.isComplete then
            -- 被动收入效果（金矿、贸易站等）
            if building.effect == "passiveIncome" then
                local teamData = teams[building.team]
                if teamData and teamData.base then
                    teamData.base.resources = teamData.base.resources + building.effectValue * dt
                end
            end
            
            -- 建筑修复效果
            if building.effect == "structureRegen" then
                local teamData = teams[building.team]
                if teamData and teamData.base then
                    -- 修复基地
                    if teamData.base.health < teamData.base.maxHealth then
                        teamData.base.health = math.min(
                            teamData.base.maxHealth,
                            teamData.base.health + building.effectValue * dt
                        )
                    end
                    
                    -- 修复防御塔
                    for _, tower in ipairs(teamData.base.towers) do
                        if not tower.isDead and tower.health < tower.maxHealth then
                            local dx = tower.x - building.x
                            local dy = tower.y - building.y
                            local distance = math.sqrt(dx * dx + dy * dy)
                            if distance <= building.radius then
                                tower.health = math.min(
                                    tower.maxHealth,
                                    tower.health + building.effectValue * dt
                                )
                            end
                        end
                    end
                end
            end
            
            -- Apply effects to team units
            for _, teamData in pairs(teams) do
                if teamData.units and teamData.config and teamData.config.name == building.team then
                    building:applyEffects(teamData.units)
                end
            end
        end
    end
    
    -- 更新所有队伍
    for i = 1, TEAM_COUNT do
        updateTeam(TEAM_CONFIGS[i].name, dt, Barracks, Tower)
    end
    
    -- 检查游戏是否结束（只剩一个队伍存活）
    if not gameOver then
        local aliveTeams = {}
        for i = 1, TEAM_COUNT do
            local config = TEAM_CONFIGS[i]
            local teamData = teams[config.name]
            if teamData and not teamData.base.isDead then
                table.insert(aliveTeams, config)
            end
        end
        
        if #aliveTeams == 1 then
            gameOver = true
            winner = aliveTeams[1].displayName .. " Team"
            BattleNotifications.victory(aliveTeams[1].name)
            print(string.format("=== GAME OVER === %s Team VICTORY! Time: %.1fs", 
                aliveTeams[1].displayName, frameCount / 60))
        elseif #aliveTeams == 0 then
            gameOver = true
            winner = "DRAW"
            print("=== GAME OVER === All bases destroyed! DRAW!")
        end
    end
    
    -- 更新统计信息（兼容性）
    if teams.red and teams.blue then
        local redAlive, redMiners = countTeamUnits(teams.red.units)
        local blueAlive, blueMiners = countTeamUnits(teams.blue.units)
        debugInfo.redAlive = redAlive
        debugInfo.blueAlive = blueAlive
        debugInfo.redBaseHP = teams.red.base.health
        debugInfo.blueBaseHP = teams.blue.base.health
    end
end

function love.draw()
    -- 背景
    love.graphics.setBackgroundColor(0.08, 0.08, 0.12)
    
    -- 如果在开始菜单，只绘制菜单
    if not gameStarted then
        StartMenu.draw()
        return
    end
    
    -- 保存原始变换
    love.graphics.push()
    
    -- 应用摄像机变换（包括震动）
    love.graphics.translate(-camera.x + camera.shakeX, -camera.y + camera.shakeY)
    love.graphics.scale(camera.scale, camera.scale)
    
    -- 绘制战场网格背景（传递摄像机信息）
    drawBattlefieldGrid(camera)
    
    -- 绘制所有队伍的基地、兵营、防御塔
    for i = 1, TEAM_COUNT do
        local teamName = TEAM_CONFIGS[i].name
        local teamData = teams[teamName]
        if teamData then
            -- 绘制基地
            if teamData.base then
                teamData.base:draw()
            end
            
            -- 绘制兵营
            if teamData.base and teamData.base.barracks then
                for _, barracks in ipairs(teamData.base.barracks) do
                    barracks:draw()
                end
            end
            
            -- 绘制防御塔
            if teamData.base and teamData.base.towers then
                for _, tower in ipairs(teamData.base.towers) do
                    tower:draw()
                end
            end
        end
    end
    
    -- 绘制资源节点
    for _, resource in ipairs(resources) do
        resource:draw()
    end
    
    -- 绘制特殊建筑
    for _, building in ipairs(specialBuildings) do
        building:draw(camera.x / camera.scale, camera.y / camera.scale)
    end
    
    -- 绘制所有队伍的单位
    for i = 1, TEAM_COUNT do
        local teamName = TEAM_CONFIGS[i].name
        local teamData = teams[teamName]
        if teamData and teamData.units then
            for _, agent in ipairs(teamData.units) do
                agent:draw()
            end
        end
    end
    
    -- 绘制粒子特效
    Particles.draw()
    
    -- 绘制伤害数字
    DamageNumbers.draw()
    
    -- 恢复变换（UI在摄像机之外绘制）
    love.graphics.pop()
    
    -- === UI层（不受摄像机影响）===
    
    -- 顶部信息栏（现代渐变效果）
    love.graphics.setColor(0.05, 0.05, 0.12, 0.95)
    love.graphics.rectangle("fill", 0, 0, 1600, 55)
    love.graphics.setColor(0.15, 0.15, 0.28, 0.5)
    love.graphics.rectangle("fill", 0, 0, 1600, 25)
    
    -- 顶部装饰线
    love.graphics.setColor(0.3, 0.6, 1, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, 55, 1600, 55)
    love.graphics.setLineWidth(1)
    
    -- 游戏标题（带阴影+双色效果）
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(string.format("GOAP %d-TEAM", TEAM_COUNT), 22, 16, 0, 1.6, 1.6)
    love.graphics.setColor(1, 0.9, 0.3)
    love.graphics.print("GOAP", 20, 14, 0, 1.6, 1.6)
    love.graphics.setColor(0.8, 0.8, 0.95)
    love.graphics.print(string.format(" %d-TEAM", TEAM_COUNT), 88, 14, 0, 1.6, 1.6)
    
    -- 观战模式标识
    love.graphics.setColor(1, 1, 0.7, 0.8)
    love.graphics.print("SPECTATOR MODE", 240, 18, 0, 1.1, 1.1)
    
    -- 战斗时间（紧凑设计）
    love.graphics.setColor(0.3, 0.7, 0.3, 0.25)
    love.graphics.circle("fill", 495, 28, 18)
    love.graphics.setColor(0.7, 0.95, 0.7)
    love.graphics.print(string.format("%.1fs", frameCount / 60), 518, 18, 0, 1.2, 1.2)
    love.graphics.setColor(0.5, 0.9, 0.5, 0.8)
    love.graphics.circle("line", 480, 28, 9)
    love.graphics.circle("fill", 480, 28, 3)
    
    -- 摄像机信息（右上角，缩小字号）
    love.graphics.setColor(0.15, 0.25, 0.4, 0.4)
    love.graphics.rectangle("fill", 1360, 10, 230, 35, 5, 5)
    love.graphics.setColor(0.6, 0.8, 1)
    love.graphics.print(string.format("Cam: %.0f,%.0f", camera.x, camera.y), 1370, 14, 0, 0.85, 0.85)
    love.graphics.print(string.format("Zoom: %.0f%%", camera.scale * 100), 1370, 27, 0, 0.85, 0.85)
    
    -- 绘制所有队伍的状态面板（右侧垂直排列）
    local panelWidth = 240  -- 统一面板宽度
    local panelHeight = 180  -- 增加高度以容纳更多信息
    local panelX = 1350  -- 固定在右侧
    local startY = 65  -- 起始Y坐标
    local spacing = 10  -- 面板之间的间距
    
    for i = 1, TEAM_COUNT do
        local config = TEAM_CONFIGS[i]
        local teamData = teams[config.name]
        if not teamData or not teamData.base then
            goto continue
        end
        
        local base = teamData.base
        local alive, miners = countTeamUnits(teamData.units)
        
        -- 计算面板位置（右侧垂直排列）
        local panelY = startY + (i - 1) * (panelHeight + spacing)
        
        -- 背景面板
        love.graphics.setColor(0.02, 0.02, 0.15, 0.92)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 8, 8)
        love.graphics.setColor(0.05, 0.05, 0.3, 0.5)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, 36, 8, 8)
        
        -- 发光边框（使用队伍颜色）
        love.graphics.setColor(config.color[1], config.color[2], config.color[3], 0.3)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", panelX - 1, panelY - 1, panelWidth + 2, panelHeight + 2, 8, 8)
        love.graphics.setColor(config.color[1], config.color[2], config.color[3], 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 8, 8)
        love.graphics.setLineWidth(1)
        
        -- 标题栏
        love.graphics.setColor(config.color[1] * 0.8, config.color[2] * 0.8, config.color[3] * 0.8)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, 36, 8, 8)
        love.graphics.setColor(config.color[1], config.color[2], config.color[3], 0.4)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, 18, 8, 8)
        
        -- 标题文字（缩小字号）
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.print(config.displayName .. " TEAM", panelX + 45, panelY + 9, 0, 1.3, 1.3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(config.displayName .. " TEAM", panelX + 43, panelY + 7, 0, 1.3, 1.3)
        
        -- 装饰三角形
        love.graphics.setColor(config.color[1], config.color[2], config.color[3], 0.6)
        love.graphics.polygon("fill", 
            panelX + 12, panelY + 15,
            panelX + 20, panelY + 11,
            panelX + 20, panelY + 19)
        
        -- 数据显示（缩小字号和行距）
        local y = panelY + 44
        local lineH = 21
        
        -- 单位数
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.print("Units:", panelX + 12, y, 0, 0.85, 0.85)
        love.graphics.setColor(0.5, 1, 0.5)
        love.graphics.print(string.format("%d/%d", alive, base.maxUnits), 
            panelX + 180, y, 0, 0.9, 0.9)
        local progress = alive / base.maxUnits
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
        love.graphics.rectangle("fill", panelX + 12, y + 13, panelWidth - 24, 3, 2, 2)
        love.graphics.setColor(0.5, 1, 0.5, 0.8)
        love.graphics.rectangle("fill", panelX + 12, y + 13, (panelWidth - 24) * progress, 3, 2, 2)
        
        y = y + lineH
        -- 基地血量
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.print("Base HP:", panelX + 12, y, 0, 0.85, 0.85)
        local hpPercent = base.health / base.maxHealth
        if hpPercent > 0.6 then
            love.graphics.setColor(0.5, 1, 0.5)
        elseif hpPercent > 0.3 then
            love.graphics.setColor(1, 1, 0.5)
        else
            love.graphics.setColor(1, 0.4, 0.4)
        end
        love.graphics.print(string.format("%.0f%%", hpPercent * 100), panelX + 180, y, 0, 0.9, 0.9)
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
        love.graphics.rectangle("fill", panelX + 12, y + 13, panelWidth - 24, 3, 2, 2)
        if hpPercent > 0.6 then
            love.graphics.setColor(0.3, 0.9, 0.3, 0.9)
        elseif hpPercent > 0.3 then
            love.graphics.setColor(1, 0.9, 0.3, 0.9)
        else
            love.graphics.setColor(1, 0.3, 0.3, 0.9)
        end
        love.graphics.rectangle("fill", panelX + 12, y + 13, (panelWidth - 24) * hpPercent, 3, 2, 2)
        
        y = y + lineH
        -- 建筑（缩小字号）
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.print(string.format("Barracks: %d  Towers: %d", 
            #base.barracks, #base.towers), panelX + 12, y, 0, 0.8, 0.8)
        
        y = y + lineH
        -- 资源
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.print("Gold:", panelX + 12, y, 0, 0.85, 0.85)
        love.graphics.setColor(1, 0.9, 0.1)
        love.graphics.print(string.format("$%d", math.floor(base.resources)), 
            panelX + 180, y, 0, 0.9, 0.9)
        
        y = y + lineH
        -- 战术模式
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("Strategy:", panelX + 12, y, 0, 0.8, 0.8)
        local modeColors = {
            economy = {0.2, 1, 0.5},
            defensive = {0.5, 0.8, 1},
            offensive = {1, 0.3, 0.3},
            desperate = {1, 0.8, 0.1}
        }
        local modeColor = modeColors[base.strategy.mode] or {1, 1, 1}
        love.graphics.setColor(modeColor)
        love.graphics.print(base.strategy.mode:upper(), panelX + 180, y, 0, 0.8, 0.8)
        
        ::continue::
    end
    
    -- 底部信息栏（现代设计）
    local bottomBarY = 850
    love.graphics.setColor(0.05, 0.05, 0.1, 0.93)
    love.graphics.rectangle("fill", 0, bottomBarY, 1600, 50)
    
    -- 顶部装饰线
    love.graphics.setColor(0.3, 0.6, 1, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, bottomBarY, 1600, bottomBarY)
    love.graphics.setLineWidth(1)
    
    -- 左侧：单位图例（带背景框）
    love.graphics.setColor(0.15, 0.2, 0.3, 0.5)
    love.graphics.rectangle("fill", 10, bottomBarY + 5, 870, 40, 5, 5)
    love.graphics.setColor(0.4, 0.6, 0.8, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", 10, bottomBarY + 5, 870, 40, 5, 5)
    
    love.graphics.setColor(0.7, 0.9, 1)
    love.graphics.print("UNITS:", 20, bottomBarY + 8, 0, 1, 1)
    love.graphics.setColor(0.85, 0.95, 1)
    love.graphics.print("M=Miner  SC=Scout  S=Sniper  G=Gunner  +=Healer  D=Demo  R=Ranger  T=Tank", 
        20, bottomBarY + 24, 0, 0.9, 0.9)
    
    -- 右侧：控制说明（带背景框）
    love.graphics.setColor(0.15, 0.25, 0.2, 0.5)
    love.graphics.rectangle("fill", 890, bottomBarY + 5, 700, 40, 5, 5)
    love.graphics.setColor(0.4, 0.8, 0.6, 0.4)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", 890, bottomBarY + 5, 700, 40, 5, 5)
    
    love.graphics.setColor(0.7, 1, 0.8)
    love.graphics.print("CONTROLS:", 900, bottomBarY + 8, 0, 1, 1)
    love.graphics.setColor(0.85, 1, 0.9)
    love.graphics.print("R-Click+Drag=Move | Wheel=Zoom | L-Click=Select | R=Restart | M=Minimap", 
        900, bottomBarY + 24, 0, 0.85, 0.85)
    
    -- 绘制小地图（带开关）
    if showMinimap then
        -- 计算实际使用的世界边界（基于基地位置）
        local minX, maxX = math.huge, -math.huge
        local minY, maxY = math.huge, -math.huge
        
        for i = 1, TEAM_COUNT do
            local teamName = TEAM_CONFIGS[i].name
            local teamData = teams[teamName]
            if teamData and teamData.base then
                local base = teamData.base
                minX = math.min(minX, base.x - 500)
                maxX = math.max(maxX, base.x + 500)
                minY = math.min(minY, base.y - 500)
                maxY = math.max(maxY, base.y + 500)
            end
        end
        
        -- 如果没有找到基地，使用默认值
        if minX == math.huge then
            minX, maxX = 0, WORLD_WIDTH
            minY, maxY = 0, WORLD_HEIGHT
        end
        
        local worldBounds = {
            minX = minX,
            minY = minY,
            width = maxX - minX,
            height = maxY - minY
        }
        
        Minimap.draw(teams, TEAM_COUNT, TEAM_CONFIGS, resources, worldBounds)
    else
        -- 显示小地图关闭提示（左侧位置）
        love.graphics.setColor(0.3, 0.3, 0.3, 0.6)
        love.graphics.rectangle("fill", 20, 300, 200, 35, 5, 5)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Minimap OFF", 60, 306, 0, 1, 1)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Press M to toggle", 35, 321, 0, 0.75, 0.75)
    end
    
    -- 绘制战斗提示
    BattleNotifications.draw()
    
    -- 如果游戏结束，显示胜利者（现代设计）
    if gameOver then
        -- 暗化背景
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, 1600, 900)
        
        -- 主面板
        love.graphics.setColor(0.08, 0.08, 0.15, 0.96)
        love.graphics.rectangle("fill", 250, 150, 1100, 600, 15, 15)
        
        -- 渐变顶部
        love.graphics.setColor(0.12, 0.12, 0.22, 0.7)
        love.graphics.rectangle("fill", 250, 150, 1100, 80, 15, 15)
        
        -- 外层发光边框
        if winner == "Red Team" then
            love.graphics.setColor(1, 0.2, 0.2, 0.4)
        else
            love.graphics.setColor(0.2, 0.2, 1, 0.4)
        end
        love.graphics.setLineWidth(6)
        love.graphics.rectangle("line", 248, 148, 1104, 604, 15, 15)
        
        -- 内层边框
        love.graphics.setColor(0.5, 0.5, 0.6, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 250, 150, 1100, 600, 15, 15)
        love.graphics.setLineWidth(1)
        
        -- 标题
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print("GAME OVER", 557, 172, 0, 3, 3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GAME OVER", 555, 170, 0, 3, 3)
        
        -- 胜利者宣告（带特效）
        local winY = 235
        if winner == "Red Team" then
            -- 红方胜利光晕
            love.graphics.setColor(1, 0.3, 0.3, 0.2)
            love.graphics.rectangle("fill", 280, winY - 10, 1040, 55, 8, 8)
            
            love.graphics.setColor(0.3, 0, 0, 0.5)
            love.graphics.print("RED TEAM WINS!", 522, winY + 4, 0, 2.5, 2.5)
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.print("RED TEAM WINS!", 520, winY + 2, 0, 2.5, 2.5)
            
            -- 闪烁效果
            local pulse = math.sin(love.timer.getTime() * 4) * 0.3 + 0.7
            love.graphics.setColor(1, 0.5, 0.5, pulse)
            love.graphics.circle("fill", 480, winY + 15, 8)
            love.graphics.circle("fill", 1070, winY + 15, 8)
        else
            -- 蓝方胜利光晕
            love.graphics.setColor(0.3, 0.3, 1, 0.2)
            love.graphics.rectangle("fill", 280, winY - 10, 1040, 55, 8, 8)
            
            love.graphics.setColor(0, 0, 0.3, 0.5)
            love.graphics.print("BLUE TEAM WINS!", 512, winY + 4, 0, 2.5, 2.5)
            love.graphics.setColor(0.3, 0.3, 1)
            love.graphics.print("BLUE TEAM WINS!", 510, winY + 2, 0, 2.5, 2.5)
            
            local pulse = math.sin(love.timer.getTime() * 4) * 0.3 + 0.7
            love.graphics.setColor(0.5, 0.5, 1, pulse)
            love.graphics.circle("fill", 470, winY + 15, 8)
            love.graphics.circle("fill", 1060, winY + 15, 8)
        end
        
        -- 战斗时长
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.print(string.format("Battle Duration: %.1f seconds", frameCount / 60), 540, 300, 0, 1.3, 1.3)
        
        -- 统计标题
        local statY = 345
        love.graphics.setColor(1, 0.95, 0.4)
        love.graphics.print("━━━━━━━ BATTLE STATISTICS ━━━━━━━", 480, statY, 0, 1.4, 1.4)
        
        -- 统计表格背景
        love.graphics.setColor(0.1, 0.1, 0.18, 0.6)
        love.graphics.rectangle("fill", 290, statY + 35, 1020, 270, 8, 8)
        
        -- 表头
        statY = statY + 50
        local lineH = 28
        
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("Metric", 330, statY, 0, 1.2, 1.2)
        
        love.graphics.setColor(1, 0.4, 0.4)
        love.graphics.rectangle("fill", 640, statY - 5, 100, 30, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("RED", 665, statY, 0, 1.2, 1.2)
        
        love.graphics.setColor(0.4, 0.4, 1)
        love.graphics.rectangle("fill", 1080, statY - 5, 100, 30, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("BLUE", 1100, statY, 0, 1.2, 1.2)
        
        -- 数据行
        local stats = {
            {"Units Produced:", battleStats.red.unitsProduced, battleStats.blue.unitsProduced},
            {"Enemy Kills:", battleStats.red.kills, battleStats.blue.kills},
            {"Tower Kills:", battleStats.red.towerKills, battleStats.blue.towerKills},
            {"Gold Spent:", string.format("$%d", math.floor(battleStats.red.goldSpent)), 
                          string.format("$%d", math.floor(battleStats.blue.goldSpent))},
            {"Buildings Built:", battleStats.red.buildingsBuilt, battleStats.blue.buildingsBuilt}
        }
        
        for i, stat in ipairs(stats) do
            statY = statY + lineH
            
            -- 交替行背景
            if i % 2 == 0 then
                love.graphics.setColor(0.15, 0.15, 0.25, 0.4)
                love.graphics.rectangle("fill", 300, statY - 3, 1000, 26, 3, 3)
            end
            
            -- 指标名称
            love.graphics.setColor(0.8, 0.8, 0.9)
            love.graphics.print(stat[1], 330, statY, 0, 1.1, 1.1)
            
            -- 红方数据
            love.graphics.setColor(1, 0.6, 0.6)
            love.graphics.print(tostring(stat[2]), 680, statY, 0, 1.1, 1.1)
            
            -- 蓝方数据
            love.graphics.setColor(0.6, 0.6, 1)
            love.graphics.print(tostring(stat[3]), 1120, statY, 0, 1.1, 1.1)
        end
        
        -- 重启提示（带动画）
        local pulse = math.sin(love.timer.getTime() * 3) * 0.2 + 0.8
        love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        love.graphics.rectangle("fill", 490, 695, 620, 40, 8, 8)
        love.graphics.setColor(0.6, 0.9, 1, pulse)
        love.graphics.print("Press R to Start New Battle", 565, 705, 0, 1.3, 1.3)
    end
    
    -- 绘制选中角色的详细信息（现代美化版）
    if selectedAgent and not selectedAgent.isDead and selectedAgent.health > 0 then
        local infoX = 280
        local infoY = 240
        local infoWidth = 440
        local infoHeight = 420
        
        -- 主背景
        love.graphics.setColor(0.08, 0.08, 0.15, 0.94)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight, 12, 12)
        
        -- 渐变头部
        love.graphics.setColor(selectedAgent.color[1] * 0.3, selectedAgent.color[2] * 0.3, selectedAgent.color[3] * 0.3, 0.7)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, 50, 12, 12)
        
        -- 发光边框
        love.graphics.setColor(selectedAgent.color[1], selectedAgent.color[2], selectedAgent.color[3], 0.4)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", infoX - 1, infoY - 1, infoWidth + 2, infoHeight + 2, 12, 12)
        love.graphics.setColor(selectedAgent.color[1], selectedAgent.color[2], selectedAgent.color[3], 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight, 12, 12)
        love.graphics.setLineWidth(1)
        
        -- 标题文字
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print("UNIT INFO", infoX + 157, infoY + 13, 0, 1.6, 1.6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("UNIT INFO", infoX + 155, infoY + 11, 0, 1.6, 1.6)
        
        -- 基本信息
        local y = infoY + 60
        local lineHeight = 24
        
        -- 单位类型标签
        love.graphics.setColor(selectedAgent.color[1] * 0.8, selectedAgent.color[2] * 0.8, selectedAgent.color[3] * 0.8, 0.5)
        love.graphics.rectangle("fill", infoX + 20, y - 5, infoWidth - 40, 32, 5, 5)
        love.graphics.setColor(selectedAgent.color)
        love.graphics.print(string.format("%s Team - %s", selectedAgent.team:upper(), selectedAgent.unitClass), 
            infoX + 30, y, 0, 1.3, 1.3)
        
        y = y + 40
        -- 健康值（带进度条）
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("Health:", infoX + 30, y, 0, 1.15, 1.15)
        local hpPercent = selectedAgent.health / selectedAgent.maxHealth
        if hpPercent > 0.6 then
            love.graphics.setColor(0.4, 1, 0.4)
        elseif hpPercent > 0.3 then
            love.graphics.setColor(1, 0.9, 0.3)
        else
            love.graphics.setColor(1, 0.4, 0.4)
        end
        love.graphics.print(string.format("%.0f / %.0f", selectedAgent.health, selectedAgent.maxHealth), 
            infoX + 180, y, 0, 1.15, 1.15)
        -- 血条
        love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
        love.graphics.rectangle("fill", infoX + 30, y + 20, infoWidth - 60, 6, 3, 3)
        if hpPercent > 0.6 then
            love.graphics.setColor(0.3, 0.9, 0.3)
        elseif hpPercent > 0.3 then
            love.graphics.setColor(1, 0.8, 0.2)
        else
            love.graphics.setColor(1, 0.3, 0.3)
        end
        love.graphics.rectangle("fill", infoX + 30, y + 20, (infoWidth - 60) * hpPercent, 6, 3, 3)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("line", infoX + 30, y + 20, infoWidth - 60, 6, 3, 3)
        
        y = y + lineHeight + 6
        -- 攻击力
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("Attack:", infoX + 30, y, 0, 1.15, 1.15)
        love.graphics.setColor(1, 0.6, 0.3)
        local displayDamage = selectedAgent.baseDamage or selectedAgent.attackDamage
        love.graphics.print(string.format("%.1f dmg", displayDamage), infoX + 180, y, 0, 1.15, 1.15)
        
        y = y + lineHeight
        -- 攻击范围
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("Range:", infoX + 30, y, 0, 1.15, 1.15)
        love.graphics.setColor(0.6, 0.7, 1)
        love.graphics.print(string.format("%.0f", selectedAgent.attackRange), infoX + 180, y, 0, 1.15, 1.15)
        
        y = y + lineHeight
        -- 移动速度
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("Speed:", infoX + 30, y, 0, 1.15, 1.15)
        love.graphics.setColor(0.4, 1, 1)
        love.graphics.print(string.format("%.0f", selectedAgent.moveSpeed), infoX + 180, y, 0, 1.15, 1.15)
        
        y = y + lineHeight
        -- 护甲
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("Armor:", infoX + 30, y, 0, 1.15, 1.15)
        love.graphics.setColor(0.7, 0.7, 1)
        love.graphics.print(string.format("%.0f%% reduction", selectedAgent.armor * 100), infoX + 180, y, 0, 1.15, 1.15)
        
        y = y + lineHeight + 8
        -- 特殊能力分隔线
        love.graphics.setColor(0.5, 0.5, 0.6, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.line(infoX + 30, y, infoX + infoWidth - 30, y)
        love.graphics.setLineWidth(1)
        
        y = y + 6
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.print("SPECIAL ABILITIES", infoX + 30, y, 0, 1.1, 1.1)
        
        y = y + lineHeight - 2
        local hasAbility = false
        if selectedAgent.hasRegen then
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.print("[Regen] +1 HP/sec", infoX + 30, y, 0, 1.0, 1.0)
            y = y + lineHeight - 6
            hasAbility = true
        end
        if selectedAgent.hasBerserk then
            if selectedAgent.isBerserk then
                love.graphics.setColor(1, 0.3, 0)
                love.graphics.print(string.format("[BERSERK] %.1fx damage!", selectedAgent.berserkPower or 1.5), 
                    infoX + 30, y, 0, 1.0, 1.0)
            else
                love.graphics.setColor(1, 0.7, 0.3)
                love.graphics.print(string.format("[Berserk] Ready (< %.0f%% HP)", 
                    selectedAgent.berserkThreshold * 100), infoX + 30, y, 0, 1.0, 1.0)
            end
            y = y + lineHeight - 6
            hasAbility = true
        end
        
        -- 如果没有特殊能力，显示提示
        if not hasAbility then
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print("None", infoX + 30, y, 0, 1.0, 1.0)
            y = y + lineHeight - 6
        end
        
        y = y + 8
        -- 状态分隔线
        love.graphics.setColor(0.5, 0.5, 0.6, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.line(infoX + 30, y, infoX + infoWidth - 30, y)
        love.graphics.setLineWidth(1)
        
        y = y + 6
        -- 当前状态
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.print("STATUS", infoX + 30, y, 0, 1.1, 1.1)
        
        y = y + lineHeight - 2
        love.graphics.setColor(0.8, 0.8, 1)
        if selectedAgent.currentAction then
            love.graphics.print("Action: " .. selectedAgent.currentAction.name, infoX + 30, y, 0, 1.0, 1.0)
        else
            love.graphics.print("Action: Planning...", infoX + 30, y, 0, 1.0, 1.0)
        end
        
        y = y + lineHeight - 6
        if selectedAgent.target then
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.print(string.format("Target: HP %.0f", selectedAgent.target.health), infoX + 30, y, 0, 1.0, 1.0)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Target: None", infoX + 30, y, 0, 1.0, 1.0)
        end
        
        -- 关闭提示
        love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        love.graphics.rectangle("fill", infoX + 140, infoY + infoHeight - 35, 160, 25, 4, 4)
        love.graphics.setColor(0.8, 0.9, 1, 0.9)
        love.graphics.print("Click to close", infoX + 162, infoY + infoHeight - 30, 0, 1.0, 1.0)
    end
    
    -- 绘制选中基地的详细信息
    if selectedBase and not selectedBase.isDead then
        local infoX = 550
        local infoY = 200
        local infoWidth = 500
        local infoHeight = 480
        
        -- 半透明背景（现代设计）
        love.graphics.setColor(0.08, 0.08, 0.15, 0.94)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight, 12, 12)
        
        -- 渐变头部
        love.graphics.setColor(selectedBase.color[1] * 0.3, selectedBase.color[2] * 0.3, selectedBase.color[3] * 0.3, 0.7)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, 50, 12, 12)
        
        -- 发光边框
        love.graphics.setColor(selectedBase.color[1], selectedBase.color[2], selectedBase.color[3], 0.4)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", infoX - 1, infoY - 1, infoWidth + 2, infoHeight + 2, 12, 12)
        love.graphics.setColor(selectedBase.color[1], selectedBase.color[2], selectedBase.color[3], 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight, 12, 12)
        love.graphics.setLineWidth(1)
        
        -- 标题
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print("BASE INFO", infoX + 182, infoY + 13, 0, 1.6, 1.6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("BASE INFO", infoX + 180, infoY + 11, 0, 1.6, 1.6)
        
        local y = infoY + 60
        local lineHeight = 24
        
        -- 基地信息
        love.graphics.setColor(selectedBase.color)
        love.graphics.print(string.format("Team: %s", selectedBase.team:upper()), infoX + 40, y, 0, 1.3, 1.3)
        
        y = y + lineHeight + 5
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.print(string.format("Health: %.0f / %.0f (%.0f%%)", 
            selectedBase.health, selectedBase.maxHealth, 
            (selectedBase.health / selectedBase.maxHealth) * 100), infoX + 40, y, 0, 1.1, 1.1)
        
        y = y + lineHeight
        love.graphics.setColor(0.7, 0.7, 1)
        love.graphics.print(string.format("Armor: %.0f%% reduction", 
            selectedBase.armor * 100), infoX + 40, y, 0, 1.1, 1.1)
        
        y = y + lineHeight
        love.graphics.setColor(1, 1, 0.7)
        love.graphics.print(string.format("Position: (%.0f, %.0f)", 
            selectedBase.x, selectedBase.y), infoX + 40, y, 0, 1.0, 1.0)
        
        y = y + lineHeight + 8
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.print("RESOURCE ECONOMY", infoX + 40, y, 0, 1.15, 1.15)
        
        y = y + lineHeight
        love.graphics.setColor(1, 0.84, 0)
        love.graphics.print(string.format("Resources: $%d / $%d", 
            selectedBase.resources, selectedBase.maxResources), infoX + 40, y, 0, 1.05, 1.05)
        
        y = y + lineHeight
        love.graphics.setColor(0.9, 0.9, 0.5)
        love.graphics.print(string.format("Mining Rate: $%.0f/sec | Range: %.0f", 
            selectedBase.miningRate, selectedBase.miningRange), infoX + 40, y, 0, 0.95, 0.95)
        
        y = y + lineHeight + 2
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Unit Costs:", infoX + 40, y, 0, 1.05, 1.05)
        y = y + lineHeight - 4
        love.graphics.setColor(0.7, 0.9, 0.7)
        love.graphics.print(string.format("  Soldier: $%d | Gunner: $%d", 
            selectedBase.unitCosts.Soldier, selectedBase.unitCosts.Gunner), infoX + 50, y, 0, 0.9, 0.9)
        y = y + lineHeight - 6
        love.graphics.print(string.format("  Sniper: $%d | Tank: $%d", 
            selectedBase.unitCosts.Sniper, selectedBase.unitCosts.Tank), infoX + 50, y, 0, 0.9, 0.9)
        
        y = y + lineHeight + 6
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.print("PRODUCTION SYSTEM", infoX + 40, y, 0, 1.15, 1.15)
        
        y = y + lineHeight
        love.graphics.setColor(0.5, 1, 1)
        love.graphics.print(string.format("Production Speed: %.1f sec/unit", 
            selectedBase.productionTime), infoX + 40, y, 0, 1.05, 1.05)
        
        y = y + lineHeight
        love.graphics.setColor(1, 0.8, 0.5)
        love.graphics.print(string.format("Max Units: %d", 
            selectedBase.maxUnits), infoX + 40, y, 0, 1.05, 1.05)
        
        y = y + lineHeight
        love.graphics.setColor(0.8, 1, 0.8)
        love.graphics.print(string.format("Units Produced: %d", 
            selectedBase.unitsProduced), infoX + 40, y, 0, 1.05, 1.05)
        
        if selectedBase.productionProgress > 0 then
            y = y + lineHeight
            love.graphics.setColor(0.3, 1, 1)
            love.graphics.print(string.format("Current Production: %.0f%%", 
                selectedBase.productionProgress * 100), infoX + 40, y, 0, 1.05, 1.05)
        end
        
        -- 显示指挥官信息（如果有）
        if selectedBase.commanderData then
            y = y + lineHeight + 6
            love.graphics.setColor(1, 0.9, 0.4)
            love.graphics.print("COMMANDER BONUSES", infoX + 40, y, 0, 1.15, 1.15)
            
            y = y + lineHeight
            love.graphics.setColor(1, 1, 0.8)
            love.graphics.print(selectedBase.commanderData.name, infoX + 40, y, 0, 1.1, 1.1)
            
            y = y + lineHeight - 4
            love.graphics.setColor(0.7, 0.9, 1)
            love.graphics.print(selectedBase.commanderData.title, infoX + 40, y, 0, 0.95, 0.95)
            
            -- 显示特性
            y = y + lineHeight
            love.graphics.setColor(0.6, 1, 0.6)
            for i, perk in ipairs(selectedBase.commanderData.perks) do
                love.graphics.print(perk.name, infoX + 40, y, 0, 0.85, 0.85)
                y = y + 18
            end
        end
        
        -- 关闭提示
        love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        love.graphics.rectangle("fill", infoX + 170, infoY + infoHeight - 35, 160, 25, 4, 4)
        love.graphics.setColor(0.8, 0.9, 1, 0.9)
        love.graphics.print("Click to close", infoX + 192, infoY + infoHeight - 30, 0, 1.0, 1.0)
    end
    
    -- 绘制兵营信息面板
    if selectedBarracks and not selectedBarracks.isDead then
        local infoX, infoY = 820, 200
        local infoWidth, infoHeight = 480, 460
        
        -- 半透明背景（现代设计）
        love.graphics.setColor(0.08, 0.08, 0.15, 0.94)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight, 12, 12)
        
        -- 渐变头部
        love.graphics.setColor(selectedBarracks.color[1] * 0.3, selectedBarracks.color[2] * 0.3, selectedBarracks.color[3] * 0.3, 0.7)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, 50, 12, 12)
        
        -- 发光边框
        love.graphics.setColor(selectedBarracks.color[1], selectedBarracks.color[2], selectedBarracks.color[3], 0.4)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", infoX - 1, infoY - 1, infoWidth + 2, infoHeight + 2, 12, 12)
        love.graphics.setColor(selectedBarracks.color[1], selectedBarracks.color[2], selectedBarracks.color[3], 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight, 12, 12)
        love.graphics.setLineWidth(1)
        
        -- 标题
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print("BARRACKS INFO", infoX + 152, infoY + 13, 0, 1.6, 1.6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("BARRACKS INFO", infoX + 150, infoY + 11, 0, 1.6, 1.6)
        
        local y = infoY + 60
        local lineHeight = 24
        
        -- 兵营信息
        love.graphics.setColor(selectedBarracks.teamColor)
        love.graphics.print(string.format("%s - %s Team", selectedBarracks.name, 
            selectedBarracks.team:upper()), infoX + 40, y, 0, 1.2, 1.2)
        
        y = y + lineHeight + 6
        
        if selectedBarracks.isBuilding then
            -- 建造中
            love.graphics.setColor(1, 0.8, 0.2)
            love.graphics.print("STATUS: UNDER CONSTRUCTION", infoX + 40, y, 0, 1.15, 1.15)
            
            y = y + lineHeight
            love.graphics.setColor(0.5, 1, 0.5)
            love.graphics.print(string.format("Build Progress: %.0f%%", 
                (selectedBarracks.buildProgress / selectedBarracks.buildTime) * 100), 
                infoX + 40, y, 0, 1.05, 1.05)
            
            y = y + lineHeight
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(string.format("Time Remaining: %.1f seconds", 
                selectedBarracks.buildTime - selectedBarracks.buildProgress), 
                infoX + 40, y, 0, 0.95, 0.95)
        else
            -- 已完成
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.print("STATUS: OPERATIONAL", infoX + 40, y, 0, 1.15, 1.15)
            
            y = y + lineHeight + 6
            love.graphics.setColor(1, 0.9, 0.4)
            love.graphics.print("PRODUCTION DETAILS", infoX + 40, y, 0, 1.15, 1.15)
            
            y = y + lineHeight
            love.graphics.setColor(0.5, 1, 1)
            love.graphics.print(string.format("Produces: %s", selectedBarracks.producesUnit), 
                infoX + 40, y, 0, 1.05, 1.05)
            
            y = y + lineHeight
            love.graphics.setColor(1, 0.84, 0)
            love.graphics.print(string.format("Production Cost: $%d", 
                selectedBarracks.productionCost), infoX + 40, y, 0, 1.05, 1.05)
            
            y = y + lineHeight
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.print(string.format("Production Time: %.1f seconds", 
                selectedBarracks.productionTime), infoX + 40, y, 0, 1.05, 1.05)
            
            y = y + lineHeight
            love.graphics.setColor(0.8, 1, 0.8)
            love.graphics.print(string.format("Units Produced: %d", 
                selectedBarracks.unitsProduced), infoX + 40, y, 0, 1.05, 1.05)
            
            if selectedBarracks.isProducing then
                y = y + lineHeight
                love.graphics.setColor(0.3, 1, 1)
                love.graphics.print(string.format("Current Production: %.0f%%", 
                    (selectedBarracks.productionProgress / selectedBarracks.productionTime) * 100), 
                    infoX + 40, y, 0, 1.05, 1.05)
            end
        end
        
        y = y + lineHeight + 8
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.print("STRUCTURE STATS", infoX + 40, y, 0, 1.15, 1.15)
        
        y = y + lineHeight
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.print(string.format("Health: %.0f / %.0f (%.0f%%)", 
            selectedBarracks.health, selectedBarracks.maxHealth,
            (selectedBarracks.health / selectedBarracks.maxHealth) * 100), 
            infoX + 40, y, 0, 1.05, 1.05)
        
        y = y + lineHeight
        love.graphics.setColor(1, 1, 0.7)
        love.graphics.print(string.format("Position: (%.0f, %.0f)", 
            selectedBarracks.x, selectedBarracks.y), infoX + 40, y, 0, 1.0, 1.0)
        
        y = y + lineHeight + 6
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(selectedBarracks.description, infoX + 40, y, 0, 0.95, 0.95)
        
        -- 关闭提示
        love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        love.graphics.rectangle("fill", infoX + 160, infoY + infoHeight - 35, 160, 25, 4, 4)
        love.graphics.setColor(0.8, 0.9, 1, 0.9)
        love.graphics.print("Click to close", infoX + 182, infoY + infoHeight - 30, 0, 1.0, 1.0)
    end
    
    -- 绘制特殊建筑信息面板
    if selectedSpecialBuilding and not selectedSpecialBuilding.isDead then
        local infoX, infoY = 300, 250
        local infoWidth, infoHeight = 420, 350
        
        -- 半透明背景
        love.graphics.setColor(0.08, 0.08, 0.15, 0.94)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight, 12, 12)
        
        -- 渐变头部
        love.graphics.setColor(selectedSpecialBuilding.color[1] * 0.3, 
            selectedSpecialBuilding.color[2] * 0.3, 
            selectedSpecialBuilding.color[3] * 0.3, 0.7)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, 50, 12, 12)
        
        -- 发光边框
        love.graphics.setColor(selectedSpecialBuilding.color[1], 
            selectedSpecialBuilding.color[2], 
            selectedSpecialBuilding.color[3], 0.4)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", infoX - 1, infoY - 1, infoWidth + 2, infoHeight + 2, 12, 12)
        love.graphics.setColor(selectedSpecialBuilding.color[1], 
            selectedSpecialBuilding.color[2], 
            selectedSpecialBuilding.color[3], 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight, 12, 12)
        love.graphics.setLineWidth(1)
        
        -- 标题
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print("SPECIAL BUILDING", infoX + 117, infoY + 13, 0, 1.6, 1.6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("SPECIAL BUILDING", infoX + 115, infoY + 11, 0, 1.6, 1.6)
        
        local y = infoY + 60
        local lineHeight = 24
        
        -- 建筑名称和队伍
        love.graphics.setColor(selectedSpecialBuilding.color)
        love.graphics.print(selectedSpecialBuilding.name, infoX + 40, y, 0, 1.4, 1.4)
        
        y = y + lineHeight + 4
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.print(string.format("Team: %s", selectedSpecialBuilding.team:upper()), 
            infoX + 40, y, 0, 1.1, 1.1)
        
        y = y + lineHeight + 6
        
        if selectedSpecialBuilding.isBuilding then
            -- 建造中
            love.graphics.setColor(1, 0.8, 0.2)
            love.graphics.print("STATUS: UNDER CONSTRUCTION", infoX + 40, y, 0, 1.15, 1.15)
            
            y = y + lineHeight
            love.graphics.setColor(0.5, 1, 0.5)
            love.graphics.print(string.format("Build Progress: %.0f%%", 
                (selectedSpecialBuilding.buildProgress / selectedSpecialBuilding.buildTime) * 100), 
                infoX + 40, y, 0, 1.05, 1.05)
            
            y = y + lineHeight
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(string.format("Time Remaining: %.1f seconds", 
                selectedSpecialBuilding.buildTime - selectedSpecialBuilding.buildProgress), 
                infoX + 40, y, 0, 0.95, 0.95)
        else
            -- 已完成
            love.graphics.setColor(0.3, 1, 0.3)
            love.graphics.print("STATUS: OPERATIONAL", infoX + 40, y, 0, 1.15, 1.15)
            
            y = y + lineHeight + 6
            love.graphics.setColor(1, 0.9, 0.4)
            love.graphics.print("SPECIAL EFFECT", infoX + 40, y, 0, 1.15, 1.15)
            
            y = y + lineHeight
            love.graphics.setColor(0.7, 1, 0.7)
            love.graphics.print(selectedSpecialBuilding.description, 
                infoX + 40, y, infoWidth - 80, "left", 0, 1.0, 1.0)
            
            y = y + lineHeight * 2 + 10
            if selectedSpecialBuilding.radius > 0 then
                love.graphics.setColor(0.5, 0.9, 1)
                love.graphics.print(string.format("Effect Radius: %.0f", 
                    selectedSpecialBuilding.radius), infoX + 40, y, 0, 1.0, 1.0)
            else
                love.graphics.setColor(0.9, 0.9, 1)
                love.graphics.print("Effect: Global (all team units)", 
                    infoX + 40, y, 0, 1.0, 1.0)
            end
        end
        
        y = y + lineHeight + 8
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.print("STRUCTURE STATS", infoX + 40, y, 0, 1.15, 1.15)
        
        y = y + lineHeight
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.print(string.format("Health: %.0f / %.0f (%.0f%%)", 
            selectedSpecialBuilding.health, selectedSpecialBuilding.maxHealth,
            (selectedSpecialBuilding.health / selectedSpecialBuilding.maxHealth) * 100), 
            infoX + 40, y, 0, 1.05, 1.05)
        
        y = y + lineHeight
        love.graphics.setColor(1, 1, 0.7)
        love.graphics.print(string.format("Position: (%.0f, %.0f)", 
            selectedSpecialBuilding.x, selectedSpecialBuilding.y), infoX + 40, y, 0, 1.0, 1.0)
        
        -- 关闭提示
        love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        love.graphics.rectangle("fill", infoX + 130, infoY + infoHeight - 35, 160, 25, 4, 4)
        love.graphics.setColor(0.8, 0.9, 1, 0.9)
        love.graphics.print("Click to close", infoX + 152, infoY + infoHeight - 30, 0, 1.0, 1.0)
    end
end

function love.keypressed(key)
    if key == "r" then
        -- 重启游戏
        redTeam = {}
        blueTeam = {}
        redBase = nil
        blueBase = nil
        gameOver = false
        winner = nil
        selectedAgent = nil
        selectedBase = nil
        selectedBarracks = nil
        selectedSpecialBuilding = nil
        specialBuildings = {}
        frameCount = 0
        love.load()
    elseif key == "m" then
        -- 切换小地图显示
        showMinimap = not showMinimap
        print(string.format("Minimap %s", showMinimap and "ON" or "OFF"))
    elseif key == "escape" then
        love.event.quit()
    end
end

-- Helper function to build special buildings
function tryBuildSpecialBuilding(base, buildingType)
    local config = SpecialBuilding.types[buildingType]
    if not config then
        print("Unknown building type: " .. buildingType)
        return
    end
    
    if base.resources >= config.cost then
        -- Find a position near the base
        local angle = math.random() * math.pi * 2
        local distance = 100 + math.random() * 50
        local x = base.x + math.cos(angle) * distance
        local y = base.y + math.sin(angle) * distance
        
        -- 建筑可以放置在任何位置（无边界限制）
        
        -- Create the building
        local building = SpecialBuilding.new(x, y, base.team, buildingType)
        table.insert(specialBuildings, building)
        
        -- Deduct cost
        base.resources = base.resources - config.cost
        
        print(string.format("%s team built %s at (%.0f, %.0f) for $%d", 
            base.team, config.name, x, y, config.cost))
        
        -- Update stats
        if battleStats[base.team] then
            battleStats[base.team].goldSpent = battleStats[base.team].goldSpent + config.cost
            battleStats[base.team].buildingsBuilt = battleStats[base.team].buildingsBuilt + 1
        end
    else
        print(string.format("Not enough resources! Need $%d, have $%d", 
            config.cost, base.resources))
    end
end

function love.mousepressed(x, y, button)
    -- 处理开始菜单点击
    if not gameStarted then
        local result = StartMenu.mousepressed(x, y, button)
        if result == "start" then
            gameStarted = true
            StartMenu.active = false
            startGame()
        end
        return
    end
    
    if button == 2 then  -- 右键拖拽摄像机
        camera.isDragging = true
        camera.dragStartX = x
        camera.dragStartY = y
        camera.dragStartCamX = camera.x
        camera.dragStartCamY = camera.y
        return
    end
    
    if button == 1 then  -- 左键点击
        -- 检查是否点击小地图（优先处理）
        if Minimap.isMouseOver(x, y) then
            -- 计算世界边界（与绘制时相同）
            local minX, maxX = math.huge, -math.huge
            local minY, maxY = math.huge, -math.huge
            
            for i = 1, TEAM_COUNT do
                local teamName = TEAM_CONFIGS[i].name
                local teamData = teams[teamName]
                if teamData and teamData.base then
                    local base = teamData.base
                    minX = math.min(minX, base.x - 500)
                    maxX = math.max(maxX, base.x + 500)
                    minY = math.min(minY, base.y - 500)
                    maxY = math.max(maxY, base.y + 500)
                end
            end
            
            if minX == math.huge then
                minX, maxX = 0, WORLD_WIDTH
                minY, maxY = 0, WORLD_HEIGHT
            end
            
            local worldBounds = {
                minX = minX,
                minY = minY,
                width = maxX - minX,
                height = maxY - minY
            }
            
            local worldX, worldY = Minimap.minimapToWorld(x, y, worldBounds)
            if worldX and worldY then
                -- 快速定位到点击位置（居中到屏幕）
                camera.x = worldX
                camera.y = worldY
                return
            end
        end
        
        -- 将屏幕坐标转换为世界坐标
        local worldX = (x + camera.x) / camera.scale
        local worldY = (y + camera.y) / camera.scale
        
        -- 如果已经有选中的对象，点击任何地方都关闭信息面板
        if selectedAgent or selectedBase or selectedBarracks or selectedTower or selectedSpecialBuilding then
            selectedAgent = nil
            selectedBase = nil
            selectedBarracks = nil
            selectedTower = nil
            selectedSpecialBuilding = nil
            return
        end
        
        -- 检查是否点击了特殊建筑
        for _, building in ipairs(specialBuildings) do
            if not building.isDead then
                local dx = worldX - building.x
                local dy = worldY - building.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance <= building.size then
                    selectedSpecialBuilding = building
                    return
                end
            end
        end
        
        -- 检查是否点击了防御塔
        for teamIdx = 1, TEAM_COUNT do
            local config = TEAM_CONFIGS[teamIdx]
            local teamData = teams[config.name]
            local base = teamData.base
            
            if base then
                for _, tower in ipairs(base.towers) do
                    if not tower.isDead then
                        local dx = worldX - tower.x
                        local dy = worldY - tower.y
                        local distance = math.sqrt(dx * dx + dy * dy)
                        if distance <= tower.size then
                            selectedTower = tower
                            return
                        end
                    end
                end
            end
        end
        
        -- 检查是否点击了兵营
        for teamIdx = 1, TEAM_COUNT do
            local config = TEAM_CONFIGS[teamIdx]
            local teamData = teams[config.name]
            local base = teamData.base
            
            if base then
                for _, barracks in ipairs(base.barracks) do
                    if not barracks.isDead then
                        if worldX >= barracks.x - barracks.size/2 and worldX <= barracks.x + barracks.size/2 and
                           worldY >= barracks.y - barracks.size/2 and worldY <= barracks.y + barracks.size/2 then
                            selectedBarracks = barracks
                            return
                        end
                    end
                end
            end
        end
        
        -- 检查是否点击了基地
        for teamIdx = 1, TEAM_COUNT do
            local config = TEAM_CONFIGS[teamIdx]
            local teamData = teams[config.name]
            local base = teamData.base
            
            if base and not base.isDead then
                if worldX >= base.x - base.size/2 and worldX <= base.x + base.size/2 and
                   worldY >= base.y - base.size/2 and worldY <= base.y + base.size/2 then
                    selectedBase = base
                    return
                end
            end
        end
        
        -- 检查是否点击了某个角色
        for teamIdx = 1, TEAM_COUNT do
            local config = TEAM_CONFIGS[teamIdx]
            local teamData = teams[config.name]
            
            for _, agent in ipairs(teamData.units) do
                if not agent.isDead and agent.health > 0 then
                    local dx = worldX - agent.x
                    local dy = worldY - agent.y
                    local distance = math.sqrt(dx * dx + dy * dy)
                    if distance <= agent.radius then
                        selectedAgent = agent
                        return
                    end
                end
            end
        end
    end
end

-- 鼠标释放事件
function love.mousereleased(x, y, button)
    if button == 2 then
        camera.isDragging = false
    end
end

-- 鼠标移动事件（处理拖拽）
function love.mousemoved(x, y, dx, dy)
    if camera.isDragging then
        camera.x = camera.dragStartCamX - (x - camera.dragStartX)
        camera.y = camera.dragStartCamY - (y - camera.dragStartY)
    end
end

-- 鼠标滚轮事件（处理缩放）
function love.wheelmoved(x, y)
    local mouseX, mouseY = love.mouse.getPosition()
    
    -- 计算缩放前的世界坐标
    local worldX = (mouseX + camera.x) / camera.scale
    local worldY = (mouseY + camera.y) / camera.scale
    
    -- 更新缩放
    local oldScale = camera.scale
    if y > 0 then
        camera.scale = math.min(camera.maxScale, camera.scale * 1.1)
    elseif y < 0 then
        camera.scale = math.max(camera.minScale, camera.scale * 0.9)
    end
    
    -- 调整摄像机位置以保持鼠标位置下的世界坐标不变
    camera.x = worldX * camera.scale - mouseX
    camera.y = worldY * camera.scale - mouseY
end

-- 绘制战场网格
function drawBattlefieldGrid(cam)
    -- 简洁网格背景（扩大范围，无边界限制）
    love.graphics.setColor(0.15, 0.15, 0.22, 0.3)
    love.graphics.setLineWidth(1)
    
    -- 屏幕尺寸
    local screenWidth = 1600
    local screenHeight = 900
    
    -- 摄像机变换: translate(-cam.x, -cam.y) 然后 scale(cam.scale)
    -- 世界坐标 (wx, wy) 变换到屏幕坐标: sx = (wx - cam.x) * cam.scale
    -- 反过来，屏幕坐标 (0, 0) 对应世界坐标: wx = cam.x / cam.scale
    
    -- 但实际上，translate 是先执行的，所以：
    -- 屏幕 (0, 0) -> 变换前 (cam.x, cam.y) -> 缩放后 (cam.x/scale, cam.y/scale)
    -- 不对！让我重新理解...
    
    -- 正确理解：translate(-cam.x) + scale(s) 的组合效果是：
    -- 世界坐标 (wx, wy) -> 屏幕坐标 (sx, sy) = ((wx - cam.x) * scale, (wy - cam.y) * scale)
    -- 反过来：屏幕 (sx, sy) -> 世界 (wx, wy) = (sx / scale + cam.x, sy / scale + cam.y)
    
    -- 但这里已经在变换之后了，我们需要直接计算世界坐标范围
    -- 屏幕左上角 (0, 0) 对应的世界坐标
    local worldLeft = cam.x / cam.scale
    local worldTop = cam.y / cam.scale
    -- 屏幕右下角 (1600, 900) 对应的世界坐标
    local worldRight = (cam.x + screenWidth) / cam.scale
    local worldBottom = (cam.y + screenHeight) / cam.scale
    
    -- 扩展边距
    local margin = 500
    worldLeft = worldLeft - margin
    worldRight = worldRight + margin
    worldTop = worldTop - margin
    worldBottom = worldBottom + margin
    
    -- 计算网格起始点（对齐100的倍数）
    local startX = math.floor(worldLeft / 100) * 100
    local startY = math.floor(worldTop / 100) * 100
    
    -- 垂直线
    for x = startX, worldRight, 100 do
        love.graphics.line(x, worldTop, x, worldBottom)
    end
    
    -- 水平线
    for y = startY, worldBottom, 100 do
        love.graphics.line(worldLeft, y, worldRight, y)
    end
    
    love.graphics.setLineWidth(1)
end

-- 摄像机震动效果
function addCameraShake(intensity)
    camera.shakeIntensity = math.max(camera.shakeIntensity, intensity)
end
