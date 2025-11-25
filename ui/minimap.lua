-- 小地图系统
local Minimap = {}

-- 小地图配置
local config = {
    x = 1380,           -- 右下角位置
    y = 680,
    width = 200,
    height = 200,
    padding = 10,
    borderWidth = 3,
    backgroundColor = {0.05, 0.05, 0.1, 0.9},
    borderColor = {0.3, 0.6, 1, 0.8},
    gridColor = {0.15, 0.15, 0.25, 0.4}
}

-- 世界坐标到小地图坐标的转换
local function worldToMinimap(worldX, worldY, worldWidth, worldHeight)
    local scaleX = config.width / worldWidth
    local scaleY = config.height / worldHeight
    return 
        config.x + worldX * scaleX,
        config.y + worldY * scaleY
end

-- 绘制小地图
function Minimap.draw(redTeam, blueTeam, redBase, blueBase, resources, worldWidth, worldHeight)
    -- 背景
    love.graphics.setColor(config.backgroundColor)
    love.graphics.rectangle("fill", config.x, config.y, config.width, config.height, 5, 5)
    
    -- 边框（渐变效果）
    love.graphics.setColor(config.borderColor[1], config.borderColor[2], config.borderColor[3], 0.4)
    love.graphics.setLineWidth(config.borderWidth + 2)
    love.graphics.rectangle("line", config.x - 1, config.y - 1, config.width + 2, config.height + 2, 5, 5)
    love.graphics.setColor(config.borderColor)
    love.graphics.setLineWidth(config.borderWidth)
    love.graphics.rectangle("line", config.x, config.y, config.width, config.height, 5, 5)
    love.graphics.setLineWidth(1)
    
    -- 网格
    love.graphics.setColor(config.gridColor)
    for i = 1, 3 do
        local x = config.x + (config.width / 4) * i
        love.graphics.line(x, config.y, x, config.y + config.height)
    end
    for i = 1, 3 do
        local y = config.y + (config.height / 4) * i
        love.graphics.line(config.x, y, config.x + config.width, y)
    end
    
    -- 中线
    love.graphics.setColor(0.3, 0.3, 0.4, 0.6)
    love.graphics.setLineWidth(2)
    local centerX = config.x + config.width / 2
    love.graphics.line(centerX, config.y, centerX, config.y + config.height)
    love.graphics.setLineWidth(1)
    
    -- 区域着色
    love.graphics.setColor(1, 0.2, 0.2, 0.08)
    love.graphics.rectangle("fill", config.x, config.y, config.width / 3, config.height)
    love.graphics.setColor(0.2, 0.2, 1, 0.08)
    love.graphics.rectangle("fill", config.x + config.width * 2/3, config.y, config.width / 3, config.height)
    
    -- 绘制资源点
    if resources then
        for _, resource in ipairs(resources) do
            if resource and resource.amount and resource.amount > 0 then
                local x, y = worldToMinimap(resource.x, resource.y, worldWidth, worldHeight)
                local alpha = math.min(1, resource.amount / 500)
                love.graphics.setColor(1, 0.9, 0.2, alpha * 0.8)
                love.graphics.circle("fill", x, y, 3)
                love.graphics.setColor(1, 1, 0.5, alpha * 0.4)
                love.graphics.circle("fill", x, y, 5)
            end
        end
    end
    
    -- 绘制基地
    if redBase and not redBase.isDead then
        local x, y = worldToMinimap(redBase.x, redBase.y, worldWidth, worldHeight)
        local healthRatio = redBase.health / redBase.maxHealth
        love.graphics.setColor(1, 0.2, 0.2, 0.9)
        love.graphics.circle("fill", x, y, 6)
        love.graphics.setColor(1, 0.5, 0.5, 0.6)
        love.graphics.circle("fill", x, y, 8)
        
        -- 血量环
        love.graphics.setColor(0, 1, 0, 0.8)
        love.graphics.arc("line", "open", x, y, 10, -math.pi/2, -math.pi/2 + healthRatio * math.pi * 2)
    end
    
    if blueBase and not blueBase.isDead then
        local x, y = worldToMinimap(blueBase.x, blueBase.y, worldWidth, worldHeight)
        local healthRatio = blueBase.health / blueBase.maxHealth
        love.graphics.setColor(0.2, 0.2, 1, 0.9)
        love.graphics.circle("fill", x, y, 6)
        love.graphics.setColor(0.5, 0.5, 1, 0.6)
        love.graphics.circle("fill", x, y, 8)
        
        -- 血量环
        love.graphics.setColor(0, 1, 0, 0.8)
        love.graphics.arc("line", "open", x, y, 10, -math.pi/2, -math.pi/2 + healthRatio * math.pi * 2)
    end
    
    -- 绘制防御塔
    if redBase and redBase.towers then
        for _, tower in ipairs(redBase.towers) do
            if not tower.isDead then
                local x, y = worldToMinimap(tower.x, tower.y, worldWidth, worldHeight)
                love.graphics.setColor(1, 0.3, 0.3, 0.6)
                love.graphics.rectangle("fill", x - 2, y - 2, 4, 4)
            end
        end
    end
    
    if blueBase and blueBase.towers then
        for _, tower in ipairs(blueBase.towers) do
            if not tower.isDead then
                local x, y = worldToMinimap(tower.x, tower.y, worldWidth, worldHeight)
                love.graphics.setColor(0.3, 0.3, 1, 0.6)
                love.graphics.rectangle("fill", x - 2, y - 2, 4, 4)
            end
        end
    end
    
    -- 绘制兵营
    if redBase and redBase.barracks then
        for _, barracks in ipairs(redBase.barracks) do
            local x, y = worldToMinimap(barracks.x, barracks.y, worldWidth, worldHeight)
            love.graphics.setColor(1, 0.5, 0.3, 0.5)
            love.graphics.rectangle("fill", x - 1.5, y - 1.5, 3, 3)
        end
    end
    
    if blueBase and blueBase.barracks then
        for _, barracks in ipairs(blueBase.barracks) do
            local x, y = worldToMinimap(barracks.x, barracks.y, worldWidth, worldHeight)
            love.graphics.setColor(0.3, 0.5, 1, 0.5)
            love.graphics.rectangle("fill", x - 1.5, y - 1.5, 3, 3)
        end
    end
    
    -- 绘制单位（聚合显示，避免过于密集）
    local redCount = 0
    local blueCount = 0
    
    if redTeam then
        for _, agent in ipairs(redTeam) do
            if not agent.isDead then
                local x, y = worldToMinimap(agent.x, agent.y, worldWidth, worldHeight)
                love.graphics.setColor(1, 0.3, 0.3, 0.7)
                love.graphics.circle("fill", x, y, 1.5)
                redCount = redCount + 1
            end
        end
    end
    
    if blueTeam then
        for _, agent in ipairs(blueTeam) do
            if not agent.isDead then
                local x, y = worldToMinimap(agent.x, agent.y, worldWidth, worldHeight)
                love.graphics.setColor(0.3, 0.3, 1, 0.7)
                love.graphics.circle("fill", x, y, 1.5)
                blueCount = blueCount + 1
            end
        end
    end
    
    -- 标题
    love.graphics.setColor(0.8, 0.9, 1, 0.9)
    love.graphics.print("MINIMAP", config.x + 5, config.y - 20, 0, 0.9, 0.9)
    
    -- 单位统计
    love.graphics.setColor(1, 0.4, 0.4, 0.8)
    love.graphics.print("R:" .. redCount, config.x + 5, config.y + config.height + 5, 0, 0.8, 0.8)
    love.graphics.setColor(0.4, 0.4, 1, 0.8)
    love.graphics.print("B:" .. blueCount, config.x + config.width - 30, config.y + config.height + 5, 0, 0.8, 0.8)
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- 检查鼠标是否在小地图上
function Minimap.isMouseOver(mouseX, mouseY)
    return mouseX >= config.x and mouseX <= config.x + config.width and
           mouseY >= config.y and mouseY <= config.y + config.height
end

-- 小地图点击转世界坐标（用于快速定位）
function Minimap.minimapToWorld(mouseX, mouseY, worldWidth, worldHeight)
    if not Minimap.isMouseOver(mouseX, mouseY) then
        return nil, nil
    end
    
    local relX = (mouseX - config.x) / config.width
    local relY = (mouseY - config.y) / config.height
    
    return relX * worldWidth, relY * worldHeight
end

return Minimap
