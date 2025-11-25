-- 开始菜单系统 (观战模式)
local StartMenu = {}

StartMenu.active = true
StartMenu.selectedTeamCount = 4
StartMenu.hoverButton = nil
StartMenu.showPreparation = false  -- 战斗准备界面
StartMenu.teamCommanders = {}  -- 存储每个队伍的指挥官

-- 按钮布局定义（统一管理所有按钮坐标）
local BUTTON_LAYOUT = {
    -- 主菜单按钮（水平居中：1600/2 - width/2）
    teamCount2 = {x = 650, y = 320, width = 300, height = 75},
    teamCount3 = {x = 650, y = 410, width = 300, height = 75},
    teamCount4 = {x = 650, y = 500, width = 300, height = 75},
    next = {x = 650, y = 600, width = 300, height = 80},
    quitMain = {x = 650, y = 695, width = 300, height = 70},
    -- 准备界面按钮
    start = {x = 575, y = 670, width = 450, height = 90},
    back = {x = 1210, y = 705, width = 180, height = 60}
}

function StartMenu.init()
    StartMenu.active = true
    StartMenu.selectedTeamCount = 4
    StartMenu.hoverButton = nil
    StartMenu.showPreparation = false
    StartMenu.teamCommanders = {}
end

function StartMenu.update(dt)
    -- 更新悬停状态
    local mx, my = love.mouse.getPosition()
    StartMenu.hoverButton = nil
    
    if not StartMenu.showPreparation then
        -- 主菜单悬停检测
        for name, btn in pairs(BUTTON_LAYOUT) do
            if name:match("teamCount") or name == "next" or name == "quitMain" then
                if mx >= btn.x and mx <= btn.x + btn.width and
                   my >= btn.y and my <= btn.y + btn.height then
                    StartMenu.hoverButton = name
                    break
                end
            end
        end
    else
        -- 准备界面悬停检测
        for name, btn in pairs(BUTTON_LAYOUT) do
            if (name == "start" or name == "back") then
                if mx >= btn.x and mx <= btn.x + btn.width and
                   my >= btn.y and my <= btn.y + btn.height then
                    StartMenu.hoverButton = name
                    break
                end
            end
        end
    end
end

function StartMenu.draw()
    if not StartMenu.active then return end
    
    -- 动态背景
    love.graphics.setColor(0.02, 0.02, 0.08, 0.95)
    love.graphics.rectangle("fill", 0, 0, 1600, 900)
    
    -- 背景装饰线
    for i = 1, 20 do
        local alpha = (math.sin(love.timer.getTime() * 0.5 + i * 0.3) + 1) * 0.05
        love.graphics.setColor(0.1, 0.2, 0.3, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(0, i * 45, 1600, i * 45)
    end
    love.graphics.setLineWidth(1)
    
    if not StartMenu.showPreparation then
        -- 主菜单界面
        -- 主标题（居中，考虑缩放）
        local scale = 4
        local printWidth = 1600 / scale
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.printf("GOAP", 0, 92, printWidth, "center", 0, scale, scale)
        love.graphics.setColor(1, 0.85, 0.3)
        love.graphics.printf("GOAP", 0, 90, printWidth, "center", 0, scale, scale)
        
        scale = 2
        printWidth = 1600 / scale
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf("Strategic Warfare", 0, 162, printWidth, "center", 0, scale, scale)
        love.graphics.setColor(0.7, 0.85, 1)
        love.graphics.printf("Strategic Warfare", 0, 160, printWidth, "center", 0, scale, scale)
        
        -- 副标题
        scale = 1.0
        printWidth = 1600 / scale
        love.graphics.setColor(0.5, 0.6, 0.7)
        love.graphics.printf("Goal-Oriented Action Planning Battle System", 0, 180, printWidth, "center", 0, scale, scale)
        
        -- 观战模式标识框
        local modeBoxX = 550
        local modeBoxY = 210
        local modeBoxW = 500
        local modeBoxH = 70
        
        love.graphics.setColor(0.15, 0.25, 0.4, 0.8)
        love.graphics.rectangle("fill", modeBoxX, modeBoxY, modeBoxW, modeBoxH, 8, 8)
        love.graphics.setColor(0.4, 0.7, 1, 0.8)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", modeBoxX, modeBoxY, modeBoxW, modeBoxH, 8, 8)
        love.graphics.setLineWidth(1)
        
        local scale = 1.3
        local printWidth = 1600 / scale
        love.graphics.setColor(1, 0.95, 0.6)
        love.graphics.printf("SPECTATOR MODE", 0, modeBoxY + 10, printWidth, "center", 0, scale, scale)
        scale = 0.85
        printWidth = 1600 / scale
        love.graphics.setColor(0.8, 0.9, 1)
        love.graphics.printf("Watch AI teams battle with random commanders", 0, modeBoxY + 40, printWidth, "center", 0, scale, scale)
        
        -- 队伍选择标题
        scale = 1.2
        printWidth = 1600 / scale
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SELECT TEAM COUNT", 0, 290, printWidth, "center", 0, scale, scale)
        
        -- 队伍数量按钮
        local teamButtons = {
            {name = "teamCount2", text = "2 TEAMS BATTLE", count = 2},
            {name = "teamCount3", text = "3 TEAMS BATTLE", count = 3},
            {name = "teamCount4", text = "4 TEAMS BATTLE", count = 4}
        }
        
        for _, btnData in ipairs(teamButtons) do
            local btn = BUTTON_LAYOUT[btnData.name]
            local selected = (StartMenu.selectedTeamCount == btnData.count)
            local hover = (StartMenu.hoverButton == btnData.name)
            
            -- 按钮背景
            if selected then
                love.graphics.setColor(0.25, 0.55, 0.85, 0.9)
            elseif hover then
                love.graphics.setColor(0.35, 0.45, 0.6, 0.9)
            else
                love.graphics.setColor(0.15, 0.2, 0.3, 0.85)
            end
            love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 12, 12)
            
            -- 按钮边框
            if selected then
                love.graphics.setColor(0.4, 0.75, 1)
                love.graphics.setLineWidth(4)
            elseif hover then
                love.graphics.setColor(0.6, 0.7, 0.8)
                love.graphics.setLineWidth(3)
            else
                love.graphics.setColor(0.4, 0.5, 0.6)
                love.graphics.setLineWidth(2)
            end
            love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 12, 12)
            love.graphics.setLineWidth(1)
            
            -- 按钮文字（垂直居中，考虑缩放）
            local fontSize = 14  -- LÖVE默认字体大小
            local scale = 1.6
            local textHeight = fontSize * scale
            local textY = btn.y + (btn.height - textHeight) / 2
            -- printf的宽度需要除以缩放因子，这样缩放后才能正确对齐
            local printWidth = btn.width / scale
            local printX = btn.x
            love.graphics.setColor(0, 0, 0, 0.4)
            love.graphics.printf(btnData.text, printX, textY + 2, printWidth, "center", 0, scale, scale)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(btnData.text, printX, textY, printWidth, "center", 0, scale, scale)
        end
        
        -- NEXT按钮
        local nextBtn = BUTTON_LAYOUT.next
        local hover = (StartMenu.hoverButton == "next")
        
        if hover then
            love.graphics.setColor(0.35, 0.75, 0.35, 0.95)
        else
            love.graphics.setColor(0.25, 0.6, 0.25, 0.9)
        end
        love.graphics.rectangle("fill", nextBtn.x, nextBtn.y, nextBtn.width, nextBtn.height, 15, 15)
        
        love.graphics.setColor(0.5, 1, 0.5)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", nextBtn.x, nextBtn.y, nextBtn.width, nextBtn.height, 15, 15)
        love.graphics.setLineWidth(1)
        
        local fontSize = 14
        local scale = 2
        local textHeight = fontSize * scale
        local textY = nextBtn.y + (nextBtn.height - textHeight) / 2
        local printWidth = nextBtn.width / scale
        local printX = nextBtn.x
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf("NEXT >>", printX, textY + 2, printWidth, "center", 0, scale, scale)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("NEXT >>", printX, textY, printWidth, "center", 0, scale, scale)
        
        -- QUIT按钮justify
        local quitBtn = BUTTON_LAYOUT.quitMain
        hover = (StartMenu.hoverButton == "quitMain")
        
        if hover then
            love.graphics.setColor(0.75, 0.35, 0.35, 0.95)
        else
            love.graphics.setColor(0.5, 0.25, 0.25, 0.9)
        end
        love.graphics.rectangle("fill", quitBtn.x, quitBtn.y, quitBtn.width, quitBtn.height, 10, 10)
        
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", quitBtn.x, quitBtn.y, quitBtn.width, quitBtn.height, 10, 10)
        love.graphics.setLineWidth(1)
        
        local fontSize = 14
        local scale = 1.5
        local textHeight = fontSize * scale
        local textY = quitBtn.y + (quitBtn.height - textHeight) / 2
        local printWidth = quitBtn.width / scale
        local printX = quitBtn.x
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("QUIT", printX, textY, printWidth, "center", 0, scale, scale)
    else
        -- 战斗准备界面
        StartMenu.drawPreparation()
    end
    
    -- 版本信息
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.print("v2.0 - AI-Generated GOAP Strategy Game", 12, 875, 0, 0.85, 0.85)
end

-- 战斗准备界面
function StartMenu.drawPreparation()
    local Commander = require("systems.commander")
    local TEAM_CONFIGS = {
        {name = "red", color = {1, 0.2, 0.2}, displayName = "RED"},
        {name = "blue", color = {0.2, 0.2, 1}, displayName = "BLUE"},
        {name = "green", color = {0.2, 1, 0.2}, displayName = "GREEN"},
        {name = "yellow", color = {1, 1, 0.2}, displayName = "YELLOW"}
    }
    
    -- 标题
    local scale = 2.5
    local printWidth = 1600 / scale
    love.graphics.setColor(1, 0.9, 0.5)
    love.graphics.printf("BATTLE PREPARATION", 0, 50, printWidth, "center", 0, scale, scale)
    
    scale = 1.3
    printWidth = 1600 / scale
    love.graphics.setColor(0.7, 0.8, 0.9)
    love.graphics.printf(string.format("%d Teams Battle Royale", StartMenu.selectedTeamCount), 0, 110, printWidth, "center", 0, scale, scale)
    
    -- 计算布局（横向一行排列）
    local cardWidth = 300
    local cardHeight = 400
    local spacing = 35
    local totalWidth = cardWidth * StartMenu.selectedTeamCount + spacing * (StartMenu.selectedTeamCount - 1)
    local startX = (1600 - totalWidth) / 2
    local startY = 200
    
    -- 为每个队伍分配指挥官（如果还没有的话）
    if #StartMenu.teamCommanders == 0 then
        for i = 1, StartMenu.selectedTeamCount do
            table.insert(StartMenu.teamCommanders, Commander.selectRandomCommander())
        end
    end
    
    -- 绘制队伍卡片（横向一行排列）
    for i = 1, StartMenu.selectedTeamCount do
        local config = TEAM_CONFIGS[i]
        local commander = StartMenu.teamCommanders[i]
        
        -- 计算位置（一行排列）
        local x = startX + (i - 1) * (cardWidth + spacing)
        local y = startY
        
        -- 卡片背景
        love.graphics.setColor(0.08, 0.08, 0.15, 0.95)
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 10, 10)
        
        -- 队伍颜色头部
        love.graphics.setColor(config.color[1] * 0.6, config.color[2] * 0.6, config.color[3] * 0.6, 0.9)
        love.graphics.rectangle("fill", x, y, cardWidth, 60, 10, 10)
        love.graphics.setColor(config.color[1] * 0.3, config.color[2] * 0.3, config.color[3] * 0.3, 0.7)
        love.graphics.rectangle("fill", x, y, cardWidth, 30, 10, 10)
        
        -- 边框
        love.graphics.setColor(config.color[1], config.color[2], config.color[3], 0.8)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight, 10, 10)
        love.graphics.setLineWidth(1)
        
        -- 队伍名称
        local scale = 1.8
        local printWidth = cardWidth / scale
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.printf(config.displayName .. " TEAM", x, y + 14, printWidth, "center", 0, scale, scale)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(config.displayName .. " TEAM", x, y + 12, printWidth, "center", 0, scale, scale)
        
        -- 分隔线
        love.graphics.setColor(0.5, 0.5, 0.6, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.line(x + 20, y + 70, x + cardWidth - 20, y + 70)
        love.graphics.setLineWidth(1)
        
        -- 指挥官信息
        local textY = y + 85
        local scale = 1.1
        local printWidth = cardWidth / scale
        love.graphics.setColor(1, 0.9, 0.4)
        love.graphics.printf("COMMANDER", x, textY, printWidth, "center", 0, scale, scale)
        
        textY = textY + 30
        scale = 1.5
        printWidth = cardWidth / scale
        love.graphics.setColor(1, 1, 0.8)
        love.graphics.printf(commander.name, x, textY, printWidth, "center", 0, scale, scale)
        
        textY = textY + 35
        scale = 1.1
        printWidth = cardWidth / scale
        love.graphics.setColor(0.7, 0.85, 1)
        love.graphics.printf(commander.title, x, textY, printWidth, "center", 0, scale, scale)
        
        -- 特性列表
        textY = textY + 40
        love.graphics.setColor(0.6, 0.8, 0.6)
        love.graphics.printf("PERKS:", x + 25, textY, cardWidth - 50, "left", 0, 1.0, 1.0)
        
        textY = textY + 28
        for j, perk in ipairs(commander.perks) do
            love.graphics.setColor(0.5, 1, 0.5)
            love.graphics.printf("• " .. perk.name, x + 25, textY, cardWidth - 50, "left", 0, 0.95, 0.95)
            textY = textY + 24
        end
    end
    
    -- 开始战斗按钮
    local startBtn = BUTTON_LAYOUT.start
    local hover = (StartMenu.hoverButton == "start")
    
    -- 脉冲效果
    local pulse = math.sin(love.timer.getTime() * 3) * 0.1 + 0.9
    
    if hover then
        love.graphics.setColor(0.3 * pulse, 0.8 * pulse, 0.3 * pulse, 0.95)
    else
        love.graphics.setColor(0.2 * pulse, 0.65 * pulse, 0.2 * pulse, 0.9)
    end
    love.graphics.rectangle("fill", startBtn.x, startBtn.y, startBtn.width, startBtn.height, 15, 15)
    
    love.graphics.setColor(0.4, 1, 0.4)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", startBtn.x, startBtn.y, startBtn.width, startBtn.height, 15, 15)
    love.graphics.setLineWidth(1)
    
    local fontSize = 14
    local scale = 2.2
    local textHeight = fontSize * scale
    local textY = startBtn.y + (startBtn.height - textHeight) / 2
    local printWidth = startBtn.width / scale
    local printX = startBtn.x
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.printf("START BATTLE", printX, textY + 2, printWidth, "center", 0, scale, scale)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("START BATTLE", printX, textY, printWidth, "center", 0, scale, scale)
    
    -- 返回按钮
    local backBtn = BUTTON_LAYOUT.back
    hover = (StartMenu.hoverButton == "back")
    
    if hover then
        love.graphics.setColor(0.5, 0.5, 0.6, 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.4, 0.85)
    end
    love.graphics.rectangle("fill", backBtn.x, backBtn.y, backBtn.width, backBtn.height, 8, 8)
    
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", backBtn.x, backBtn.y, backBtn.width, backBtn.height, 8, 8)
    love.graphics.setLineWidth(1)
    
    local fontSize = 14
    local scale = 1.3
    local textHeight = fontSize * scale
    textY = backBtn.y + (backBtn.height - textHeight) / 2
    local printWidth = backBtn.width / scale
    local printX = backBtn.x
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("< BACK", printX, textY, printWidth, "center", 0, scale, scale)
end

function StartMenu.mousepressed(x, y, button)
    if not StartMenu.active or button ~= 1 then return false end
    
    if not StartMenu.showPreparation then
        -- 主菜单界面
        -- 队伍数量选择
        for i = 2, 4 do
            local btnName = "teamCount" .. i
            local btn = BUTTON_LAYOUT[btnName]
            if x >= btn.x and x <= btn.x + btn.width and
               y >= btn.y and y <= btn.y + btn.height then
                StartMenu.selectedTeamCount = i
                return true
            end
        end
        
        -- Next按钮 - 进入准备界面
        local nextBtn = BUTTON_LAYOUT.next
        if x >= nextBtn.x and x <= nextBtn.x + nextBtn.width and
           y >= nextBtn.y and y <= nextBtn.y + nextBtn.height then
            StartMenu.showPreparation = true
            StartMenu.teamCommanders = {}  -- 重置指挥官
            -- 重新分配指挥官
            local Commander = require("systems.commander")
            for i = 1, StartMenu.selectedTeamCount do
                table.insert(StartMenu.teamCommanders, Commander.selectRandomCommander())
            end
            return true
        end
        
        -- 退出按钮
        local quitBtn = BUTTON_LAYOUT.quitMain
        if x >= quitBtn.x and x <= quitBtn.x + quitBtn.width and
           y >= quitBtn.y and y <= quitBtn.y + quitBtn.height then
            love.event.quit()
        end
    else
        -- 战斗准备界面
        -- 开始战斗按钮
        local startBtn = BUTTON_LAYOUT.start
        if x >= startBtn.x and x <= startBtn.x + startBtn.width and
           y >= startBtn.y and y <= startBtn.y + startBtn.height then
            return "start"
        end
        
        -- 返回按钮
        local backBtn = BUTTON_LAYOUT.back
        if x >= backBtn.x and x <= backBtn.x + backBtn.width and
           y >= backBtn.y and y <= backBtn.y + backBtn.height then
            StartMenu.showPreparation = false
            StartMenu.teamCommanders = {}
            return true
        end
    end
    
    return false
end

return StartMenu
