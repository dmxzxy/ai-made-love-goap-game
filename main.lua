-- GOAP 战斗游戏主文件
local Agent = require("entities.agent")
local Base = require("entities.base")
local Resource = require("entities.resource")

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

function love.load()
    -- 设置窗口
    love.window.setTitle("GOAP Battle Game - Base Defense")
    love.window.setMode(1200, 800)
    
    print("=== Game Loading ===")
    math.randomseed(tostring(os.time()):reverse():sub(1, 7))  -- 设置随机种子

    -- 创建基地
    redBase = Base.new(100, 400, "red", {1, 0.2, 0.2})
    blueBase = Base.new(1100, 400, "blue", {0.2, 0.2, 1})
    print("Bases created: Red and Blue")
    
    -- 创建资源点
    resources = {}
    -- 红方附近的资源
    table.insert(resources, Resource.new(200, 300))
    table.insert(resources, Resource.new(200, 500))
    -- 中间的资源（争夺点）
    table.insert(resources, Resource.new(600, 250))
    table.insert(resources, Resource.new(600, 550))
    -- 蓝方附近的资源
    table.insert(resources, Resource.new(1000, 300))
    table.insert(resources, Resource.new(1000, 500))
    print(string.format("Created %d resource points", #resources))
    
    -- 初始单位数量（双方相同）
    local initialCount = 3
    print(string.format("Initial units per team: %d", initialCount))
    
    -- 随机选择兵种的函数
    local function getRandomUnitClass()
        local rand = math.random()
        if rand < 0.5 then
            return "Soldier"  -- 50% 普通士兵
        elseif rand < 0.7 then
            return "Sniper"   -- 20% 狙击手
        elseif rand < 0.9 then
            return "Gunner"   -- 20% 机枪手
        else
            return "Tank"     -- 10% 坦克兵
        end
    end
    
    -- 创建红队初始单位
    for i = 1, initialCount do
        local x, y = redBase:getSpawnPosition()
        y = y + (i - 2) * 60  -- 垂直分布
        local unitClass = getRandomUnitClass()
        local agent = Agent.new(x, y, "red", {1, 0.2, 0.2}, unitClass)
        agent.angle = 0  -- 朝向右边
        table.insert(redTeam, agent)
        print(string.format("Red #%d [%s]: HP=%.0f ATK=%.0f RNG=%.0f", 
            i, unitClass, agent.health, agent.attackDamage, agent.attackRange))
    end
    
    -- 创建蓝队初始单位
    for i = 1, initialCount do
        local x, y = blueBase:getSpawnPosition()
        y = y + (i - 2) * 60  -- 垂直分布
        local unitClass = getRandomUnitClass()
        local agent = Agent.new(x, y, "blue", {0.2, 0.2, 1}, unitClass)
        agent.angle = math.pi  -- 朝向左边
        table.insert(blueTeam, agent)
        print(string.format("Blue #%d [%s]: HP=%.0f ATK=%.0f RNG=%.0f", 
            i, unitClass, agent.health, agent.attackDamage, agent.attackRange))
    end
    
    -- 设置引用
    for _, agent in ipairs(redTeam) do
        agent.enemies = blueTeam
        agent.allies = redTeam
        agent.enemyBase = blueBase
    end
    for _, agent in ipairs(blueTeam) do
        agent.enemies = redTeam
        agent.allies = blueTeam
        agent.enemyBase = redBase
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
    for _, agent in ipairs(redTeam) do
        if agent.health > 0 and not agent.isDead then
            redAlive = redAlive + 1
        end
    end
    
    local blueAlive = 0
    for _, agent in ipairs(blueTeam) do
        if agent.health > 0 and not agent.isDead then
            blueAlive = blueAlive + 1
        end
    end
    
    -- 更新红方基地
    local shouldSpawnRed, unitClass = redBase:update(dt, redAlive, resources)
    if shouldSpawnRed and unitClass and redAlive < redBase.maxUnits then
        local x, y = redBase:getSpawnPosition()        local agent = Agent.new(x, y, "red", {1, 0.2, 0.2}, unitClass)
        agent.angle = 0
        agent.enemies = blueTeam
        agent.allies = redTeam
        agent.enemyBase = blueBase
        table.insert(redTeam, agent)
        print(string.format("[Red] %s spawned! Total: %d", unitClass, redAlive + 1))
    end
    
    -- 更新蓝方基地
    local shouldSpawnBlue, unitClassBlue = blueBase:update(dt, blueAlive, resources)
    if shouldSpawnBlue and unitClassBlue and blueAlive < blueBase.maxUnits then
        local x, y = blueBase:getSpawnPosition()
        local agent = Agent.new(x, y, "blue", {0.2, 0.2, 1}, unitClassBlue)
        agent.angle = math.pi
        agent.enemies = redTeam
        agent.allies = blueTeam
        agent.enemyBase = redBase
        table.insert(blueTeam, agent)
        print(string.format("[Blue] %s spawned! Total: %d", unitClassBlue, blueAlive + 1))
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
    
    -- 绘制分隔线
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.line(600, 0, 600, 800)
    
    -- 绘制标题
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("GOAP Battle - Base Defense", 20, 20, 0, 2, 2)
    
    -- 绘制基地
    redBase:draw()
    blueBase:draw()
    
    -- 绘制资源节点
    for _, resource in ipairs(resources) do
        resource:draw()
    end
    
    -- 绘制队伍标签和统计
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.print("Red Team", 50, 60, 0, 1.5, 1.5)
    if debugInfo.redAlive then
        love.graphics.print(string.format("Units: %d/%d", 
            debugInfo.redAlive, redBase.maxUnits), 50, 85, 0, 1, 1)
        love.graphics.print(string.format("Base: %.0f/%.0f", 
            debugInfo.redBaseHP or 0, redBase.maxHealth), 50, 105, 0, 1, 1)
    end
    
    love.graphics.setColor(0.2, 0.2, 1)
    love.graphics.print("Blue Team", 1000, 60, 0, 1.5, 1.5)
    if debugInfo.blueAlive then
        love.graphics.print(string.format("Units: %d/%d", 
            debugInfo.blueAlive, blueBase.maxUnits), 1000, 85, 0, 1, 1)
        love.graphics.print(string.format("Base: %.0f/%.0f", 
            debugInfo.blueBaseHP or 0, blueBase.maxHealth), 1000, 105, 0, 1, 1)
    end
    
    -- 绘制所有单位
    for _, agent in ipairs(redTeam) do
        agent:draw()
    end
    for _, agent in ipairs(blueTeam) do
        agent:draw()
    end
    
    -- 绘制战斗时间
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(string.format("Frame: %d | Battle Time: %.1fs", 
        frameCount, frameCount / 60), 450, 20, 0, 0.8, 0.8)
    
    -- 如果游戏结束，显示胜利者
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 250, 250, 700, 300)
        
        -- 边框
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", 250, 250, 700, 300)
        love.graphics.setLineWidth(1)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GAME OVER", 430, 280, 0, 3, 3)
        
        -- 胜利者颜色
        if winner == "Red Team" then
            love.graphics.setColor(1, 0.3, 0.3)
        else
            love.graphics.setColor(0.3, 0.3, 1)
        end
        love.graphics.print(winner .. " Wins!", 420, 360, 0, 2.5, 2.5)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("Battle Duration: %.1f seconds", frameCount / 60), 390, 430, 0, 1.2, 1.2)
        love.graphics.print("Press R to Start New Battle", 410, 480, 0, 1.3, 1.3)
    end
    
    -- 绘制说明和图例
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Goal: Destroy enemy base | Bases produce units every 8s (max 10)", 20, 750, 0, 0.8, 0.8)
    love.graphics.print("Classes: Soldier(balanced) | S=Sniper(high dmg) | G=Gunner(fast fire) | T=Tank(armored)", 20, 770, 0, 0.8, 0.8)
    
    -- 绘制选中角色的详细信息
    if selectedAgent and not selectedAgent.isDead and selectedAgent.health > 0 then
        local infoX = 300
        local infoY = 150
        local infoWidth = 600
        local infoHeight = 450
        
        -- 半透明背景
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight)
        
        -- 边框
        love.graphics.setColor(selectedAgent.color[1], selectedAgent.color[2], selectedAgent.color[3], 0.8)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight)
        love.graphics.setLineWidth(1)
        
        -- 标题
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("=== AGENT INFO ===", infoX + 200, infoY + 15, 0, 1.5, 1.5)
        
        -- 基本信息
        local y = infoY + 55
        local lineHeight = 25
        
        love.graphics.setColor(selectedAgent.color)
        love.graphics.print(string.format("Team: %s", selectedAgent.team:upper()), infoX + 30, y, 0, 1.2, 1.2)
        
        y = y + lineHeight
        -- 兵种信息
        local classColor = {1, 1, 0.5}
        if selectedAgent.unitClass == "Sniper" then
            classColor = {1, 0.5, 1}
        elseif selectedAgent.unitClass == "Gunner" then
            classColor = {1, 0.7, 0.3}
        elseif selectedAgent.unitClass == "Tank" then
            classColor = {0.5, 1, 0.5}
        end
        love.graphics.setColor(classColor)
        love.graphics.print(string.format("Class: %s", selectedAgent.unitClass), infoX + 30, y, 0, 1.2, 1.2)
        
        y = y + lineHeight
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(string.format("Position: (%.0f, %.0f)", selectedAgent.x, selectedAgent.y), infoX + 30, y)
        
        y = y + lineHeight + 10
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("--- Combat Stats ---", infoX + 30, y, 0, 1.1, 1.1)
        
        y = y + lineHeight + 5
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.print(string.format("Health: %.0f / %.0f (%.0f%%)", 
            selectedAgent.health, selectedAgent.maxHealth, 
            (selectedAgent.health / selectedAgent.maxHealth) * 100), infoX + 30, y)
        
        y = y + lineHeight
        love.graphics.setColor(1, 0.5, 0.3)
        local displayDamage = selectedAgent.baseDamage or selectedAgent.attackDamage
        love.graphics.print(string.format("Attack Damage: %.1f", displayDamage), infoX + 30, y)
        if selectedAgent.isBerserk then
            love.graphics.setColor(1, 0.3, 0)
            love.graphics.print(string.format(" (BERSERK: x%.1f = %.1f)", 
                selectedAgent.berserkPower or 1.5, selectedAgent.attackDamage), infoX + 230, y)
        elseif selectedAgent.moraleRatio and selectedAgent.moraleRatio < 1.0 then
            love.graphics.setColor(1, 1, 0.3)
            love.graphics.print(string.format(" (Morale: x%.2f = %.1f)", 
                1.0 + (selectedAgent.moraleRatio - 1.0) * 0.3, selectedAgent.attackDamage), infoX + 230, y)
        end
        
        y = y + lineHeight
        love.graphics.setColor(0.7, 0.7, 1)
        love.graphics.print(string.format("Attack Range: %.0f", selectedAgent.attackRange), infoX + 30, y)
        
        y = y + lineHeight
        love.graphics.setColor(0.5, 1, 1)
        love.graphics.print(string.format("Move Speed: %.0f", selectedAgent.moveSpeed), infoX + 30, y)
        
        y = y + lineHeight
        love.graphics.setColor(1, 1, 0.5)
        love.graphics.print(string.format("Critical Chance: %.0f%%", selectedAgent.critChance * 100), infoX + 30, y)
        
        y = y + lineHeight
        love.graphics.setColor(0.5, 1, 0.5)
        love.graphics.print(string.format("Dodge Chance: %.0f%%", selectedAgent.dodgeChance * 100), infoX + 30, y)
        
        y = y + lineHeight
        love.graphics.setColor(0.7, 0.7, 1)
        love.graphics.print(string.format("Armor: %.0f%% damage reduction", selectedAgent.armor * 100), infoX + 30, y)
        
        y = y + lineHeight + 10
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("--- Special Abilities ---", infoX + 30, y, 0, 1.1, 1.1)
        
        y = y + lineHeight + 5
        love.graphics.setColor(0.3, 1, 0.3)
        if selectedAgent.hasRegen then
            love.graphics.print("[Heart] Regeneration: +1 HP/sec", infoX + 30, y)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("No Regeneration", infoX + 30, y)
        end
        
        y = y + lineHeight
        love.graphics.setColor(1, 0.5, 0.3)
        if selectedAgent.hasBerserk then
            if selectedAgent.isBerserk then
                love.graphics.print(string.format("[Fire] BERSERK ACTIVE! (%.1fx damage)", 
                    selectedAgent.berserkPower or 1.5), infoX + 30, y)
            else
                love.graphics.print(string.format("[Fire] Berserk Available (triggers at %.0f%% HP)", 
                    selectedAgent.berserkThreshold * 100), infoX + 30, y)
            end
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("No Berserk Ability", infoX + 30, y)
        end
        
        y = y + lineHeight + 10
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("--- Morale System ---", infoX + 30, y, 0, 1.1, 1.1)
        
        y = y + lineHeight + 5
        local aliveAllies = 0
        local totalAllies = 0
        for _, ally in ipairs(selectedAgent.allies) do
            totalAllies = totalAllies + 1
            if ally ~= selectedAgent and ally.health > 0 and not ally.isDead then
                aliveAllies = aliveAllies + 1
            end
        end
        local moralePercent = (selectedAgent.moraleRatio or 1.0) * 100
        local moraleColor
        if moralePercent > 70 then
            moraleColor = {0.3, 1, 0.3}
        elseif moralePercent > 40 then
            moraleColor = {1, 1, 0.3}
        else
            moraleColor = {1, 0.5, 0.3}
        end
        love.graphics.setColor(moraleColor)
        love.graphics.print(string.format("Morale: %.0f%% (Allies: %d/%d alive)", 
            moralePercent, aliveAllies, totalAllies - 1), infoX + 30, y)
        
        y = y + lineHeight + 10
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("--- Current Status ---", infoX + 30, y, 0, 1.1, 1.1)
        
        y = y + lineHeight + 5
        love.graphics.setColor(0.8, 0.8, 1)
        if selectedAgent.currentAction then
            love.graphics.print("Action: " .. selectedAgent.currentAction.name, infoX + 30, y)
        else
            love.graphics.print("Action: Planning...", infoX + 30, y)
        end
        
        y = y + lineHeight
        if selectedAgent.target then
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.print(string.format("Target: Enemy at (%.0f, %.0f) HP=%.0f", 
                selectedAgent.target.x, selectedAgent.target.y, selectedAgent.target.health), infoX + 30, y)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Target: None", infoX + 30, y)
        end
        
        -- 关闭提示
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.print("Click anywhere to close", infoX + 200, infoY + infoHeight - 30, 0, 1.1, 1.1)
    end
    
    -- 绘制选中基地的详细信息
    if selectedBase and not selectedBase.isDead then
        local infoX = 350
        local infoY = 200
        local infoWidth = 500
        local infoHeight = 350
        
        -- 半透明背景
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight)
        
        -- 边框
        love.graphics.setColor(selectedBase.color[1], selectedBase.color[2], selectedBase.color[3], 0.8)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight)
        love.graphics.setLineWidth(1)
        
        -- 标题
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("=== BASE INFO ===", infoX + 160, infoY + 15, 0, 1.8, 1.8)
        
        local y = infoY + 60
        local lineHeight = 30
        
        -- 基地信息
        love.graphics.setColor(selectedBase.color)
        love.graphics.print(string.format("Team: %s", selectedBase.team:upper()), infoX + 40, y, 0, 1.4, 1.4)
        
        y = y + lineHeight + 10
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.print(string.format("Health: %.0f / %.0f (%.0f%%)", 
            selectedBase.health, selectedBase.maxHealth, 
            (selectedBase.health / selectedBase.maxHealth) * 100), infoX + 40, y, 0, 1.2, 1.2)
        
        y = y + lineHeight
        love.graphics.setColor(0.7, 0.7, 1)
        love.graphics.print(string.format("Armor: %.0f%% damage reduction", 
            selectedBase.armor * 100), infoX + 40, y, 0, 1.2, 1.2)
        
        y = y + lineHeight
        love.graphics.setColor(1, 1, 0.7)
        love.graphics.print(string.format("Position: (%.0f, %.0f)", 
            selectedBase.x, selectedBase.y), infoX + 40, y, 0, 1.1, 1.1)
        
        y = y + lineHeight + 15
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("--- Resource Economy ---", infoX + 40, y, 0, 1.2, 1.2)
        
        y = y + lineHeight
        love.graphics.setColor(1, 0.84, 0)
        love.graphics.print(string.format("Resources: $%d / $%d", 
            selectedBase.resources, selectedBase.maxResources), infoX + 40, y, 0, 1.1, 1.1)
        
        y = y + lineHeight
        love.graphics.setColor(0.9, 0.9, 0.5)
        love.graphics.print(string.format("Mining Rate: $%.0f/sec | Range: %.0f", 
            selectedBase.miningRate, selectedBase.miningRange), infoX + 40, y, 0, 1, 1)
        
        y = y + lineHeight + 5
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Unit Costs:", infoX + 40, y, 0, 1.1, 1.1)
        y = y + lineHeight - 5
        love.graphics.setColor(0.7, 0.9, 0.7)
        love.graphics.print(string.format("  Soldier: $%d | Gunner: $%d", 
            selectedBase.unitCosts.Soldier, selectedBase.unitCosts.Gunner), infoX + 50, y, 0, 0.95, 0.95)
        y = y + lineHeight - 5
        love.graphics.print(string.format("  Sniper: $%d | Tank: $%d", 
            selectedBase.unitCosts.Sniper, selectedBase.unitCosts.Tank), infoX + 50, y, 0, 0.95, 0.95)
        
        y = y + lineHeight + 15
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("--- Production System ---", infoX + 40, y, 0, 1.2, 1.2)
        
        y = y + lineHeight
        love.graphics.setColor(0.5, 1, 1)
        love.graphics.print(string.format("Production Speed: %.1f seconds/unit", 
            selectedBase.productionTime), infoX + 40, y, 0, 1.1, 1.1)
        
        y = y + lineHeight
        love.graphics.setColor(1, 0.8, 0.5)
        love.graphics.print(string.format("Max Units: %d", 
            selectedBase.maxUnits), infoX + 40, y, 0, 1.1, 1.1)
        
        y = y + lineHeight
        love.graphics.setColor(0.8, 1, 0.8)
        love.graphics.print(string.format("Units Produced: %d", 
            selectedBase.unitsProduced), infoX + 40, y, 0, 1.1, 1.1)
        
        if selectedBase.productionProgress > 0 then
            y = y + lineHeight
            love.graphics.setColor(0.3, 1, 1)
            love.graphics.print(string.format("Current Production: %.0f%%", 
                selectedBase.productionProgress * 100), infoX + 40, y, 0, 1.1, 1.1)
        end
        
        -- 关闭提示
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print("Click anywhere to close", infoX + 150, infoY + infoHeight - 35, 0, 1.2, 1.2)
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
        frameCount = 0
        love.load()
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then  -- 左键点击
        -- 如果已经有选中的对象，点击任何地方都关闭信息面板
        if selectedAgent or selectedBase then
            selectedAgent = nil
            selectedBase = nil
            return
        end
        
        -- 检查是否点击了基地
        if redBase and not redBase.isDead then
            if x >= redBase.x - redBase.size/2 and x <= redBase.x + redBase.size/2 and
               y >= redBase.y - redBase.size/2 and y <= redBase.y + redBase.size/2 then
                selectedBase = redBase
                return
            end
        end
        
        if blueBase and not blueBase.isDead then
            if x >= blueBase.x - blueBase.size/2 and x <= blueBase.x + blueBase.size/2 and
               y >= blueBase.y - blueBase.size/2 and y <= blueBase.y + blueBase.size/2 then
                selectedBase = blueBase
                return
            end
        end
        
        -- 检查是否点击了某个角色
        for _, agent in ipairs(redTeam) do
            if not agent.isDead and agent.health > 0 then
                local dx = x - agent.x
                local dy = y - agent.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance <= agent.radius then
                    selectedAgent = agent
                    return
                end
            end
        end
        
        for _, agent in ipairs(blueTeam) do
            if not agent.isDead and agent.health > 0 then
                local dx = x - agent.x
                local dy = y - agent.y
                local distance = math.sqrt(dx * dx + dy * dy)
                if distance <= agent.radius then
                    selectedAgent = agent
                    return
                end
            end
        end
    end
end
