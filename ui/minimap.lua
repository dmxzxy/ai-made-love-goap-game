-- 小地图系统
local Minimap = {}

-- 小地图配置
local config = {
    x = 20,             -- 左侧位置（右侧被面板占据）
    y = 300,            -- 中间偏上位置
    width = 200,        -- 恢复标准宽度
    height = 200,       -- 恢复标准高度
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
function Minimap.draw(teams, teamCount, teamConfigs, resources, worldWidth, worldHeight)
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
    
    -- 绘制所有队伍的基地、建筑和单位
    local teamUnitCounts = {}
    
    for i = 1, teamCount do
        local config = teamConfigs[i]
        local teamData = teams[config.name]
        
        if teamData and teamData.base then
            local base = teamData.base
            local color = config.color
            
            -- 绘制基地
            if base and not base.isDead then
                local x, y = worldToMinimap(base.x, base.y, worldWidth, worldHeight)
                local healthRatio = base.health / base.maxHealth
                love.graphics.setColor(color[1], color[2], color[3], 0.9)
                love.graphics.circle("fill", x, y, 6)
                love.graphics.setColor(color[1] * 1.5, color[2] * 1.5, color[3] * 1.5, 0.6)
                love.graphics.circle("fill", x, y, 8)
                
                -- 血量环
                love.graphics.setColor(0, 1, 0, 0.8)
                love.graphics.arc("line", "open", x, y, 10, -math.pi/2, -math.pi/2 + healthRatio * math.pi * 2)
            end
            
            -- 绘制防御塔
            if base.towers then
                for _, tower in ipairs(base.towers) do
                    if not tower.isDead then
                        local x, y = worldToMinimap(tower.x, tower.y, worldWidth, worldHeight)
                        love.graphics.setColor(color[1], color[2], color[3], 0.6)
                        love.graphics.rectangle("fill", x - 2, y - 2, 4, 4)
                    end
                end
            end
            
            -- 绘制兵营
            if base.barracks then
                for _, barracks in ipairs(base.barracks) do
                    local x, y = worldToMinimap(barracks.x, barracks.y, worldWidth, worldHeight)
                    love.graphics.setColor(color[1] * 1.2, color[2] * 1.2, color[3] * 1.2, 0.5)
                    love.graphics.rectangle("fill", x - 1.5, y - 1.5, 3, 3)
                end
            end
            
            -- 绘制单位
            local unitCount = 0
            if teamData.units then
                for _, agent in ipairs(teamData.units) do
                    if not agent.isDead then
                        local x, y = worldToMinimap(agent.x, agent.y, worldWidth, worldHeight)
                        love.graphics.setColor(color[1], color[2], color[3], 0.7)
                        love.graphics.circle("fill", x, y, 1.5)
                        unitCount = unitCount + 1
                    end
                end
            end
            
            teamUnitCounts[i] = {
                name = config.displayName or config.name,
                count = unitCount,
                color = color
            }
        end
    end
    
    -- 标题
    love.graphics.setColor(0.8, 0.9, 1, 0.9)
    love.graphics.print("MINIMAP", config.x + 5, config.y - 20, 0, 0.9, 0.9)
    
    -- 单位统计（多队伍显示）
    local statsY = config.y + config.height + 5
    for i, data in ipairs(teamUnitCounts) do
        local shortName = data.name:sub(1, 1)  -- 取首字母
        love.graphics.setColor(data.color[1], data.color[2], data.color[3], 0.8)
        local text = shortName .. ":" .. data.count
        local textX = config.x + 5 + (i - 1) * 40
        love.graphics.print(text, textX, statsY, 0, 0.8, 0.8)
    end
    
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
