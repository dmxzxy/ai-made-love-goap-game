-- GOAP 战斗游戏主文件
local Agent = require("entities.agent")
local Base = require("entities.base")
local Resource = require("entities.resource")
local Barracks = require("entities.barracks")
local Tower = require("entities.tower")

-- 全局变量
local redTeam = {}
local blueTeam = {}
local redBase = nil
local blueBase = nil
local resources = {}  -- 资源点列表
local gameOver = false
local winner = nil
local frameCount = 0
local debugInfo = {}
local selectedAgent = nil  -- 当前选中的角色
local selectedBase = nil   -- 当前选中的基地
local selectedBarracks = nil  -- 当前选中的兵营
local selectedTower = nil  -- 当前选中的防御塔

-- 战斗数据统计
local battleStats = {
    red = {
        kills = 0,
        deaths = 0,
        damageDealt = 0,
        damageReceived = 0,
        unitsProduced = 0,
        goldSpent = 0,
        goldMined = 0,
        buildingsBuilt = 0,
        towerKills = 0
    },
    blue = {
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
}

-- 摄像机系统
local camera = {
    x = 600,         -- 摄像机初始偏移X（看向中间偏左）
    y = 300,         -- 摄像机初始偏移Y（看向中间偏上）
    scale = 0.8,     -- 初始缩放比例（缩小以看到更大视野）
    minScale = 0.3,  -- 最小缩放（可以看到整个战场）
    maxScale = 2.0,  -- 最大缩放
    isDragging = false,
    dragStartX = 0,
    dragStartY = 0,
    dragStartCamX = 0,
    dragStartCamY = 0
}

function love.load()
    -- 设置窗口
    love.window.setTitle("GOAP Battle Game - Strategic Warfare")
    love.window.setMode(1600, 900)  -- 标准窗口
    
    -- 实际游戏世界更大（可以通过摄像机浏览）
    WORLD_WIDTH = 2400
    WORLD_HEIGHT = 1200
    
    print("=== Game Loading ===")
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))  -- 设置随机种子

    -- 重置战斗统计
    battleStats = {
        red = {kills = 0, deaths = 0, damageDealt = 0, damageReceived = 0, unitsProduced = 0, goldSpent = 0, goldMined = 0, buildingsBuilt = 0, towerKills = 0},
        blue = {kills = 0, deaths = 0, damageDealt = 0, damageReceived = 0, unitsProduced = 0, goldSpent = 0, goldMined = 0, buildingsBuilt = 0, towerKills = 0}
    }

    -- 创建基地（调整位置适应新地图）
    redBase = Base.new(150, 600, "red", {1, 0.2, 0.2})
    blueBase = Base.new(2250, 600, "blue", {0.2, 0.2, 1})
    print("Bases created: Red and Blue")
    
    -- 创建更多资源点（16个，优化分布更均匀）
    resources = {}
    -- 红方区域资源（5个）
    table.insert(resources, Resource.new(250, 300))
    table.insert(resources, Resource.new(250, 600))
    table.insert(resources, Resource.new(250, 900))
    table.insert(resources, Resource.new(450, 450))
    table.insert(resources, Resource.new(450, 750))
    
    -- 中立区资源（6个，增加争夺性）
    table.insert(resources, Resource.new(800, 200))
    table.insert(resources, Resource.new(800, 600))
    table.insert(resources, Resource.new(800, 1000))
    table.insert(resources, Resource.new(1600, 200))
    table.insert(resources, Resource.new(1600, 600))
    table.insert(resources, Resource.new(1600, 1000))
    
    -- 蓝方区域资源（5个）
    table.insert(resources, Resource.new(1950, 450))
    table.insert(resources, Resource.new(1950, 750))
    table.insert(resources, Resource.new(2150, 300))
    table.insert(resources, Resource.new(2150, 600))
    table.insert(resources, Resource.new(2150, 900))
    print(string.format("Created %d resource points", #resources))
    
    -- 初始单位数量（增加到5个矿工）
    local initialCount = 5
    print(string.format("Initial units per team: %d Miners (for fairness)", initialCount))
    
    -- 创建红队初始单位（全部矿工）
    for i = 1, initialCount do
        local x, y = redBase:getSpawnPosition()
        y = y + (i - 2) * 60  -- 垂直分布
        local agent = Agent.new(x, y, "red", {1, 0.2, 0.2}, "Miner")
        agent.angle = 0  -- 朝向右边
        agent.myBase = redBase
        agent.resources = resources
        table.insert(redTeam, agent)
        print(string.format("Red #%d [Miner]: HP=%.0f Speed=%.0f", 
            i, agent.health, agent.moveSpeed))
    end
    
    -- 创建蓝队初始单位（全部矿工）
    for i = 1, initialCount do
        local x, y = blueBase:getSpawnPosition()
        y = y + (i - 2) * 60  -- 垂直分布
        local agent = Agent.new(x, y, "blue", {0.2, 0.2, 1}, "Miner")
        agent.angle = math.pi  -- 朝向左边
        agent.myBase = blueBase
        agent.resources = resources
        table.insert(blueTeam, agent)
        print(string.format("Blue #%d [Miner]: HP=%.0f Speed=%.0f", 
            i, agent.health, agent.moveSpeed))
    end
    
    -- 设置引用（矿工不需要敌人引用，但保留以便后续战斗单位使用）
    for _, agent in ipairs(redTeam) do
        agent.enemies = blueTeam
        agent.allies = redTeam
        agent.enemyBase = blueBase
        agent.enemyTowers = blueBase.towers
    end
    for _, agent in ipairs(blueTeam) do
        agent.enemies = redTeam
        agent.allies = blueTeam
        agent.enemyBase = redBase
        agent.enemyTowers = redBase.towers
    end
    
    print("=== Game Loaded ===")

end

function love.update(dt)
    frameCount = frameCount + 1
    
    if gameOver then
        return
    end
    
    -- 更新资源点
    for _, resource in ipairs(resources) do
        resource:update(dt)
    end
    
    -- 更新基地和生产单位
    local redAlive = 0
    local redMiners = 0
    for _, agent in ipairs(redTeam) do
        if agent.health > 0 and not agent.isDead then
            redAlive = redAlive + 1
            if agent.isMiner then
                redMiners = redMiners + 1
            end
        end
    end
    
    local blueAlive = 0
    local blueMiners = 0
    for _, agent in ipairs(blueTeam) do
        if agent.health > 0 and not agent.isDead then
            blueAlive = blueAlive + 1
            if agent.isMiner then
                blueMiners = blueMiners + 1
            end
        end
    end
    
    -- 重置矿工加成（每帧重新计算）
    redBase.minerBonus = redMiners * 2  -- 每个矿工提供+2采集速度
    blueBase.minerBonus = blueMiners * 2
    
    -- 更新红方基地
    local shouldSpawnRed, unitClass = redBase:update(dt, redAlive, resources, redMiners)
    if shouldSpawnRed and unitClass and redAlive < redBase.maxUnits then
        local x, y = redBase:getSpawnPosition()
        local agent = Agent.new(x, y, "red", {1, 0.2, 0.2}, unitClass)
        agent.angle = 0
        agent.enemies = blueTeam
        agent.allies = redTeam
        agent.enemyBase = blueBase
        agent.enemyTowers = blueBase.towers
        agent.myBase = redBase
        agent.resources = resources
        table.insert(redTeam, agent)
        battleStats.red.unitsProduced = battleStats.red.unitsProduced + 1
        print(string.format("[Red] %s spawned! Total: %d (Miners: %d)", unitClass, redAlive + 1, redMiners))
    end
    
    -- 红方兵营自动建造和生产
    if frameCount % 300 == 0 then  -- 每5秒尝试建造兵营
        redBase:tryAutoBuildBarracks(Barracks)
    end
    
    -- 红方防御塔自动建造（每10秒尝试）
    if frameCount % 600 == 100 then
        redBase:tryAutoBuildTower(Tower)
    end
    
    -- 更新红方防御塔
    for i = #redBase.towers, 1, -1 do
        local tower = redBase.towers[i]
        tower:update(dt, blueTeam)
        if tower.isDead then
            table.remove(redBase.towers, i)
        end
    end
    
    for i, barracks in ipairs(redBase.barracks) do
        local shouldSpawn, unitType, cost = barracks:update(dt, redBase.resources)
        if shouldSpawn and unitType and redAlive < redBase.maxUnits and redBase.resources >= cost then
            redBase.resources = math.max(0, redBase.resources - cost)
            battleStats.red.goldSpent = battleStats.red.goldSpent + cost
            local x, y = barracks:getSpawnPosition()
            local agent = Agent.new(x, y, "red", {1, 0.2, 0.2}, unitType)
            agent.angle = 0
            agent.enemies = blueTeam
            agent.allies = redTeam
            agent.enemyBase = blueBase
            agent.enemyTowers = blueBase.towers
            agent.myBase = redBase
            agent.resources = resources
            table.insert(redTeam, agent)
            battleStats.red.unitsProduced = battleStats.red.unitsProduced + 1
            print(string.format("[Red Barracks %d] %s spawned! Total: %d", i, unitType, redAlive + 1))
        end
    end
    
    -- 更新蓝方基地
    local shouldSpawnBlue, unitClassBlue = blueBase:update(dt, blueAlive, resources, blueMiners)
    if shouldSpawnBlue and unitClassBlue and blueAlive < blueBase.maxUnits then
        local x, y = blueBase:getSpawnPosition()
        local agent = Agent.new(x, y, "blue", {0.2, 0.2, 1}, unitClassBlue)
        agent.angle = math.pi
        agent.enemies = redTeam
        agent.allies = blueTeam
        agent.enemyBase = redBase
        agent.enemyTowers = redBase.towers
        agent.myBase = blueBase
        agent.resources = resources
        table.insert(blueTeam, agent)
        battleStats.blue.unitsProduced = battleStats.blue.unitsProduced + 1
        print(string.format("[Blue] %s spawned! Total: %d (Miners: %d)", unitClassBlue, blueAlive + 1, blueMiners))
    end
    
    -- 蓝方兵营自动建造和生产
    if frameCount % 300 == 0 then  -- 每5秒尝试建造兵营
        blueBase:tryAutoBuildBarracks(Barracks)
    end
    
    -- 蓝方防御塔自动建造（每10秒尝试，错开时间）
    if frameCount % 600 == 400 then
        blueBase:tryAutoBuildTower(Tower)
    end
    
    -- 更新蓝方防御塔
    for i = #blueBase.towers, 1, -1 do
        local tower = blueBase.towers[i]
        tower:update(dt, redTeam)
        if tower.isDead then
            table.remove(blueBase.towers, i)
        end
    end
    
    for i, barracks in ipairs(blueBase.barracks) do
        local shouldSpawn, unitType, cost = barracks:update(dt, blueBase.resources)
        if shouldSpawn and unitType and blueAlive < blueBase.maxUnits and blueBase.resources >= cost then
            blueBase.resources = math.max(0, blueBase.resources - cost)
            battleStats.blue.goldSpent = battleStats.blue.goldSpent + cost
            local x, y = barracks:getSpawnPosition()
            local agent = Agent.new(x, y, "blue", {0.2, 0.2, 1}, unitType)
            agent.angle = math.pi
            agent.enemies = redTeam
            agent.allies = blueTeam
            agent.enemyBase = redBase
            agent.enemyTowers = redBase.towers
            agent.myBase = blueBase
            agent.resources = resources
            table.insert(blueTeam, agent)
            battleStats.blue.unitsProduced = battleStats.blue.unitsProduced + 1
            print(string.format("[Blue Barracks %d] %s spawned! Total: %d", i, unitType, blueAlive + 1))
        end
    end
    
    -- 更新所有单位
    for _, agent in ipairs(redTeam) do
        agent:update(dt)
    end
    for _, agent in ipairs(blueTeam) do
        agent:update(dt)
    end
    
    -- 检查游戏是否结束（基地被摧毁）
    if redBase.isDead then
        gameOver = true
        winner = "Blue Team"
        print(string.format("=== GAME OVER === Blue Team destroyed Red Base! Time: %.1fs", frameCount / 60))
    elseif blueBase.isDead then
        gameOver = true
        winner = "Red Team"
        print(string.format("=== GAME OVER === Red Team destroyed Blue Base! Time: %.1fs", frameCount / 60))
    end
    
    -- 更新统计信息
    debugInfo.redAlive = redAlive
    debugInfo.blueAlive = blueAlive
    debugInfo.redBaseHP = redBase.health
    debugInfo.blueBaseHP = blueBase.health
end

function love.draw()
    -- 背景
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
    
    -- 保存原始变换
    love.graphics.push()
    
    -- 应用摄像机变换
    love.graphics.translate(-camera.x, -camera.y)
    love.graphics.scale(camera.scale, camera.scale)
    
    -- 绘制分隔线（居中）
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.line(1200, 0, 1200, 1200)
    
    -- 绘制标题
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("GOAP Battle - Strategic Warfare", 20, 20, 0, 2, 2)
    love.graphics.print("GOAP Battle - Base Defense", 20, 20, 0, 2, 2)
    
    -- 绘制基地
    redBase:draw()
    blueBase:draw()
    
    -- 绘制兵营
    for _, barracks in ipairs(redBase.barracks) do
        barracks:draw()
    end
    for _, barracks in ipairs(blueBase.barracks) do
        barracks:draw()
    end
    
    -- 绘制防御塔
    for _, tower in ipairs(redBase.towers) do
        tower:draw()
    end
    for _, tower in ipairs(blueBase.towers) do
        tower:draw()
    end
    
    -- 绘制资源节点
    for _, resource in ipairs(resources) do
        resource:draw()
    end
    
    -- 绘制所有单位
    for _, agent in ipairs(redTeam) do
        agent:draw()
    end
    for _, agent in ipairs(blueTeam) do
        agent:draw()
    end
    
    -- 恢复变换（UI在摄像机之外绘制）
    love.graphics.pop()
    
    -- === UI层（不受摄像机影响）===
    
    -- 顶部深色半透明背景条
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
    love.graphics.print("GOAP STRATEGIC WARFARE", 22, 14, 0, 1.9, 1.9)
    love.graphics.setColor(1, 0.9, 0.3)
    love.graphics.print("GOAP", 20, 12, 0, 1.9, 1.9)
    love.graphics.setColor(0.8, 0.8, 0.95)
    love.graphics.print(" STRATEGIC WARFARE", 100, 12, 0, 1.9, 1.9)
    
    -- 战斗时间（带背景圆圈）
    love.graphics.setColor(0.3, 0.7, 0.3, 0.25)
    love.graphics.circle("fill", 665, 28, 20)
    love.graphics.setColor(0.7, 0.95, 0.7)
    love.graphics.print(string.format("%.1fs", frameCount / 60), 690, 16, 0, 1.3, 1.3)
    love.graphics.setColor(0.5, 0.9, 0.5, 0.8)
    love.graphics.circle("line", 650, 28, 10)
    love.graphics.circle("fill", 650, 28, 3)
    
    -- 摄像机信息（科技感面板）
    love.graphics.setColor(0.15, 0.25, 0.4, 0.4)
    love.graphics.rectangle("fill", 1185, 10, 405, 35, 5, 5)
    love.graphics.setColor(0.3, 0.6, 0.9, 0.6)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", 1185, 10, 405, 35, 5, 5)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.4, 0.75, 1)
    love.graphics.print(string.format("Zoom: %.2fx | Pos: (%.0f, %.0f)", 
        camera.scale, camera.x, camera.y), 1200, 18, 0, 1.05, 1.05)
    
    -- 左侧红方信息面板（升级设计）
    local leftPanelX = 10
    local leftPanelY = 65
    local panelWidth = 260
    local panelHeight = 200
    
    -- 红方背景面板（带渐变+光晕）
    love.graphics.setColor(0.15, 0.02, 0.02, 0.92)
    love.graphics.rectangle("fill", leftPanelX, leftPanelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setColor(0.3, 0.05, 0.05, 0.5)
    love.graphics.rectangle("fill", leftPanelX, leftPanelY, panelWidth, 45, 10, 10)
    
    -- 发光边框
    love.graphics.setColor(1, 0.2, 0.2, 0.3)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", leftPanelX - 1, leftPanelY - 1, panelWidth + 2, panelHeight + 2, 10, 10)
    love.graphics.setColor(1, 0.3, 0.3, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", leftPanelX, leftPanelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- 红方标题栏（立体效果）
    love.graphics.setColor(0.8, 0.15, 0.15)
    love.graphics.rectangle("fill", leftPanelX, leftPanelY, panelWidth, 42, 10, 10)
    love.graphics.setColor(1, 0.2, 0.2, 0.4)
    love.graphics.rectangle("fill", leftPanelX, leftPanelY, panelWidth, 20, 10, 10)
    
    -- 标题文字
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.print("RED TEAM", leftPanelX + 72, leftPanelY + 11, 0, 1.6, 1.6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("RED TEAM", leftPanelX + 70, leftPanelY + 9, 0, 1.6, 1.6)
    
    -- 装饰三角形
    love.graphics.setColor(1, 0.4, 0.4, 0.6)
    love.graphics.polygon("fill", 
        leftPanelX + 15, leftPanelY + 18,
        leftPanelX + 25, leftPanelY + 13,
        leftPanelX + 25, leftPanelY + 23)
    
    if debugInfo.redAlive then
        local y = leftPanelY + 52
        local lineH = 26
        
        -- 数据项（带图标和进度条）
        -- 单位数
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Units:", leftPanelX + 15, y, 0, 1.1, 1.1)
        love.graphics.setColor(0.5, 1, 0.5)
        love.graphics.print(string.format("%d/%d", debugInfo.redAlive, redBase.maxUnits), 
            leftPanelX + 170, y, 0, 1.15, 1.15)
        -- 进度条
        local progress = debugInfo.redAlive / redBase.maxUnits
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
        love.graphics.rectangle("fill", leftPanelX + 15, y + 18, panelWidth - 30, 4, 2, 2)
        love.graphics.setColor(0.5, 1, 0.5, 0.8)
        love.graphics.rectangle("fill", leftPanelX + 15, y + 18, (panelWidth - 30) * progress, 4, 2, 2)
        
        y = y + lineH
        -- 基地血量
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Base HP:", leftPanelX + 15, y, 0, 1.1, 1.1)
        local hpPercent = (debugInfo.redBaseHP or 0) / redBase.maxHealth
        if hpPercent > 0.6 then
            love.graphics.setColor(0.5, 1, 0.5)
        elseif hpPercent > 0.3 then
            love.graphics.setColor(1, 1, 0.5)
        else
            love.graphics.setColor(1, 0.4, 0.4)
        end
        love.graphics.print(string.format("%.0f%%", hpPercent * 100), 
            leftPanelX + 170, y, 0, 1.15, 1.15)
        -- 血条
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
        love.graphics.rectangle("fill", leftPanelX + 15, y + 18, panelWidth - 30, 4, 2, 2)
        if hpPercent > 0.6 then
            love.graphics.setColor(0.3, 0.9, 0.3, 0.9)
        elseif hpPercent > 0.3 then
            love.graphics.setColor(1, 0.9, 0.3, 0.9)
        else
            love.graphics.setColor(1, 0.3, 0.3, 0.9)
        end
        love.graphics.rectangle("fill", leftPanelX + 15, y + 18, (panelWidth - 30) * hpPercent, 4, 2, 2)
        
        y = y + lineH
        -- 兵营
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Barracks:", leftPanelX + 15, y, 0, 1.1, 1.1)
        love.graphics.setColor(0.7, 0.7, 1)
        love.graphics.print(string.format("%d/%d", #redBase.barracks, redBase.maxBarracks), 
            leftPanelX + 170, y, 0, 1.15, 1.15)
        
        y = y + lineH
        -- 防御塔
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Towers:", leftPanelX + 15, y, 0, 1.1, 1.1)
        love.graphics.setColor(1, 0.8, 0.5)
        love.graphics.print(string.format("%d/%d", #redBase.towers, redBase.maxTowers), 
            leftPanelX + 170, y, 0, 1.15, 1.15)
        
        y = y + lineH
        -- 资源（带金币效果）
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Gold:", leftPanelX + 15, y, 0, 1.1, 1.1)
        love.graphics.setColor(1, 0.9, 0.1)
        local goldAmount = math.floor(math.max(0, redBase.resources))
        love.graphics.print(string.format("$%d", goldAmount), 
            leftPanelX + 170, y, 0, 1.2, 1.2)
        -- 金币闪烁效果
        if goldAmount > 500 then
            local pulse = math.sin(love.timer.getTime() * 3) * 0.3 + 0.7
            love.graphics.setColor(1, 0.95, 0.3, pulse)
            love.graphics.circle("fill", leftPanelX + 245, y + 8, 4)
        end
    end
    
    -- 右侧蓝方信息面板（对称设计）
    local rightPanelX = 1600 - panelWidth - 10
    local rightPanelY = 65
    
    -- 蓝方背景面板
    love.graphics.setColor(0.02, 0.02, 0.15, 0.92)
    love.graphics.rectangle("fill", rightPanelX, rightPanelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setColor(0.05, 0.05, 0.3, 0.5)
    love.graphics.rectangle("fill", rightPanelX, rightPanelY, panelWidth, 45, 10, 10)
    
    -- 发光边框
    love.graphics.setColor(0.2, 0.2, 1, 0.3)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", rightPanelX - 1, rightPanelY - 1, panelWidth + 2, panelHeight + 2, 10, 10)
    love.graphics.setColor(0.3, 0.3, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", rightPanelX, rightPanelY, panelWidth, panelHeight, 10, 10)
    love.graphics.setLineWidth(1)
    
    -- 蓝方标题栏
    love.graphics.setColor(0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", rightPanelX, rightPanelY, panelWidth, 42, 10, 10)
    love.graphics.setColor(0.2, 0.2, 1, 0.4)
    love.graphics.rectangle("fill", rightPanelX, rightPanelY, panelWidth, 20, 10, 10)
    
    -- 标题文字
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.print("BLUE TEAM", rightPanelX + 67, rightPanelY + 11, 0, 1.6, 1.6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("BLUE TEAM", rightPanelX + 65, rightPanelY + 9, 0, 1.6, 1.6)
    
    -- 装饰三角形
    love.graphics.setColor(0.4, 0.4, 1, 0.6)
    love.graphics.polygon("fill", 
        rightPanelX + panelWidth - 15, rightPanelY + 18,
        rightPanelX + panelWidth - 25, rightPanelY + 13,
        rightPanelX + panelWidth - 25, rightPanelY + 23)
    
    if debugInfo.blueAlive then
        local y = rightPanelY + 52
        local lineH = 26
        
        -- 单位数
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Units:", rightPanelX + 15, y, 0, 1.1, 1.1)
        love.graphics.setColor(0.5, 1, 0.5)
        love.graphics.print(string.format("%d/%d", debugInfo.blueAlive, blueBase.maxUnits), 
            rightPanelX + 170, y, 0, 1.15, 1.15)
        local progress = debugInfo.blueAlive / blueBase.maxUnits
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
        love.graphics.rectangle("fill", rightPanelX + 15, y + 18, panelWidth - 30, 4, 2, 2)
        love.graphics.setColor(0.5, 1, 0.5, 0.8)
        love.graphics.rectangle("fill", rightPanelX + 15, y + 18, (panelWidth - 30) * progress, 4, 2, 2)
        
        y = y + lineH
        -- 基地血量
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Base HP:", rightPanelX + 15, y, 0, 1.1, 1.1)
        local hpPercent = (debugInfo.blueBaseHP or 0) / blueBase.maxHealth
        if hpPercent > 0.6 then
            love.graphics.setColor(0.5, 1, 0.5)
        elseif hpPercent > 0.3 then
            love.graphics.setColor(1, 1, 0.5)
        else
            love.graphics.setColor(1, 0.4, 0.4)
        end
        love.graphics.print(string.format("%.0f%%", hpPercent * 100), 
            rightPanelX + 170, y, 0, 1.15, 1.15)
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
        love.graphics.rectangle("fill", rightPanelX + 15, y + 18, panelWidth - 30, 4, 2, 2)
        if hpPercent > 0.6 then
            love.graphics.setColor(0.3, 0.9, 0.3, 0.9)
        elseif hpPercent > 0.3 then
            love.graphics.setColor(1, 0.9, 0.3, 0.9)
        else
            love.graphics.setColor(1, 0.3, 0.3, 0.9)
        end
        love.graphics.rectangle("fill", rightPanelX + 15, y + 18, (panelWidth - 30) * hpPercent, 4, 2, 2)
        
        y = y + lineH
        -- 兵营
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Barracks:", rightPanelX + 15, y, 0, 1.1, 1.1)
        love.graphics.setColor(0.7, 0.7, 1)
        love.graphics.print(string.format("%d/%d", #blueBase.barracks, blueBase.maxBarracks), 
            rightPanelX + 170, y, 0, 1.15, 1.15)
        
        y = y + lineH
        -- 防御塔
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Towers:", rightPanelX + 15, y, 0, 1.1, 1.1)
        love.graphics.setColor(1, 0.8, 0.5)
        love.graphics.print(string.format("%d/%d", #blueBase.towers, blueBase.maxTowers), 
            rightPanelX + 170, y, 0, 1.15, 1.15)
        
        y = y + lineH
        -- 资源
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Gold:", rightPanelX + 15, y, 0, 1.1, 1.1)
        love.graphics.setColor(1, 0.9, 0.1)
        local goldAmount = math.floor(math.max(0, blueBase.resources))
        love.graphics.print(string.format("$%d", goldAmount), 
            rightPanelX + 170, y, 0, 1.2, 1.2)
        if goldAmount > 500 then
            local pulse = math.sin(love.timer.getTime() * 3) * 0.3 + 0.7
            love.graphics.setColor(1, 0.95, 0.3, pulse)
            love.graphics.circle("fill", rightPanelX + 245, y + 8, 4)
        end
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
    love.graphics.print("R-Click+Drag=Move | Wheel=Zoom | L-Click=Select | R=Restart", 
        900, bottomBarY + 24, 0, 0.9, 0.9)
    
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
        frameCount = 0
        love.load()
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
    if button == 2 then  -- 右键拖拽摄像机
        camera.isDragging = true
        camera.dragStartX = x
        camera.dragStartY = y
        camera.dragStartCamX = camera.x
        camera.dragStartCamY = camera.y
        return
    end
    
    if button == 1 then  -- 左键点击
        -- 将屏幕坐标转换为世界坐标
        local worldX = (x + camera.x) / camera.scale
        local worldY = (y + camera.y) / camera.scale
        
        -- 如果已经有选中的对象，点击任何地方都关闭信息面板
        if selectedAgent or selectedBase or selectedBarracks or selectedTower then
            selectedAgent = nil
            selectedBase = nil
            selectedBarracks = nil
            selectedTower = nil
            return
        end
        
        -- 检查是否点击了防御塔
        for _, tower in ipairs(redBase.towers) do
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
        
        for _, tower in ipairs(blueBase.towers) do
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
        
        -- 检查是否点击了兵营
        for _, barracks in ipairs(redBase.barracks) do
            if not barracks.isDead then
                if worldX >= barracks.x - barracks.size/2 and worldX <= barracks.x + barracks.size/2 and
                   worldY >= barracks.y - barracks.size/2 and worldY <= barracks.y + barracks.size/2 then
                    selectedBarracks = barracks
                    return
                end
            end
        end
        
        for _, barracks in ipairs(blueBase.barracks) do
            if not barracks.isDead then
                if worldX >= barracks.x - barracks.size/2 and worldX <= barracks.x + barracks.size/2 and
                   worldY >= barracks.y - barracks.size/2 and worldY <= barracks.y + barracks.size/2 then
                    selectedBarracks = barracks
                    return
                end
            end
        end
        
        -- 检查是否点击了基地
        if redBase and not redBase.isDead then
            if worldX >= redBase.x - redBase.size/2 and worldX <= redBase.x + redBase.size/2 and
               worldY >= redBase.y - redBase.size/2 and worldY <= redBase.y + redBase.size/2 then
                selectedBase = redBase
                return
            end
        end
        
        if blueBase and not blueBase.isDead then
            if worldX >= blueBase.x - blueBase.size/2 and worldX <= blueBase.x + blueBase.size/2 and
               worldY >= blueBase.y - blueBase.size/2 and worldY <= blueBase.y + blueBase.size/2 then
                selectedBase = blueBase
                return
            end
        end
        
        -- 检查是否点击了某个角色
        for _, agent in ipairs(redTeam) do
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
        
        for _, agent in ipairs(blueTeam) do
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
