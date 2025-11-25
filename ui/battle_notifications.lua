-- 战斗提示系统
local BattleNotifications = {}

-- 通知队列
local notifications = {}
local maxNotifications = 5
local notificationDuration = 4  -- 显示4秒

-- 通知类型配置
local notificationTypes = {
    baseAttack = {
        icon = "!",
        color = {1, 0.2, 0.2},
        bgColor = {0.3, 0.05, 0.05, 0.9},
        sound = true
    },
    unitLevelUp = {
        icon = "+",
        color = {1, 1, 0.3},
        bgColor = {0.3, 0.3, 0.05, 0.9},
        sound = true
    },
    buildingComplete = {
        icon = "B",
        color = {0.3, 1, 0.3},
        bgColor = {0.05, 0.3, 0.05, 0.9},
        sound = false
    },
    towerBuilt = {
        icon = "T",
        color = {0.5, 0.8, 1},
        bgColor = {0.05, 0.1, 0.3, 0.9},
        sound = false
    },
    resourceDepleted = {
        icon = "$",
        color = {1, 0.8, 0.3},
        bgColor = {0.3, 0.2, 0.05, 0.9},
        sound = false
    },
    victory = {
        icon = "V",
        color = {1, 1, 1},
        bgColor = {0.2, 0.6, 0.2, 0.95},
        sound = true
    }
}

-- 初始化
function BattleNotifications.init()
    notifications = {}
end

-- 添加通知
function BattleNotifications.add(message, notifType, team)
    notifType = notifType or "baseAttack"
    local config = notificationTypes[notifType] or notificationTypes.baseAttack
    
    -- 检查是否有相同消息（防止刷屏）
    local currentTime = love.timer.getTime()
    for _, notif in ipairs(notifications) do
        if notif.message == message and (currentTime - notif.createdAt) < 2 then
            return  -- 2秒内相同消息不重复显示
        end
    end
    
    local notification = {
        message = message,
        type = notifType,
        config = config,
        team = team,
        life = notificationDuration,
        maxLife = notificationDuration,
        createdAt = currentTime,
        alpha = 0,  -- 淡入效果
        offsetY = -20  -- 下滑效果
    }
    
    table.insert(notifications, 1, notification)  -- 新消息在顶部
    
    -- 限制通知数量
    while #notifications > maxNotifications do
        table.remove(notifications)
    end
    
    -- 播放音效（如果配置了）
    if config.sound then
        -- 使用屏幕震动作为"音效"的视觉替代
        if addCameraShake then
            addCameraShake(2)
        end
    end
end

-- 更新
function BattleNotifications.update(dt)
    for i = #notifications, 1, -1 do
        local notif = notifications[i]
        
        -- 更新生命值
        notif.life = notif.life - dt
        
        -- 淡入动画
        if notif.alpha < 1 then
            notif.alpha = math.min(1, notif.alpha + dt * 3)
        end
        
        -- 下滑动画
        if notif.offsetY < 0 then
            notif.offsetY = math.min(0, notif.offsetY + dt * 60)
        end
        
        -- 移除过期通知
        if notif.life <= 0 then
            table.remove(notifications, i)
        end
    end
end

-- 绘制
function BattleNotifications.draw()
    local startX = 520
    local startY = 70
    local width = 560
    local height = 45
    local spacing = 10
    
    for i, notif in ipairs(notifications) do
        local y = startY + (i - 1) * (height + spacing) + notif.offsetY
        local alpha = notif.alpha
        
        -- 过期淡出
        if notif.life < 0.5 then
            alpha = alpha * (notif.life / 0.5)
        end
        
        -- 背景框（带阴影）
        love.graphics.setColor(0, 0, 0, alpha * 0.3)
        love.graphics.rectangle("fill", startX + 3, y + 3, width, height, 8, 8)
        
        love.graphics.setColor(
            notif.config.bgColor[1],
            notif.config.bgColor[2],
            notif.config.bgColor[3],
            notif.config.bgColor[4] * alpha
        )
        love.graphics.rectangle("fill", startX, y, width, height, 8, 8)
        
        -- 边框
        love.graphics.setColor(
            notif.config.color[1],
            notif.config.color[2],
            notif.config.color[3],
            alpha * 0.8
        )
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", startX, y, width, height, 8, 8)
        love.graphics.setLineWidth(1)
        
        -- 图标背景
        love.graphics.setColor(
            notif.config.color[1],
            notif.config.color[2],
            notif.config.color[3],
            alpha * 0.3
        )
        love.graphics.rectangle("fill", startX + 5, y + 5, 35, 35, 4, 4)
        
        -- 图标
        love.graphics.setColor(
            notif.config.color[1],
            notif.config.color[2],
            notif.config.color[3],
            alpha
        )
        love.graphics.print(notif.config.icon, startX + 15, y + 8, 0, 2, 2)
        
        -- 消息文本
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(notif.message, startX + 50, y + 8, 0, 1.1, 1.1)
        
        -- 团队标识（如果有）
        if notif.team then
            local teamColor = notif.team == "red" and {1, 0.3, 0.3} or {0.3, 0.3, 1}
            love.graphics.setColor(teamColor[1], teamColor[2], teamColor[3], alpha)
            love.graphics.print(string.upper(notif.team), startX + 50, y + 24, 0, 0.9, 0.9)
        end
        
        -- 生命条
        local lifeRatio = notif.life / notif.maxLife
        love.graphics.setColor(
            notif.config.color[1],
            notif.config.color[2],
            notif.config.color[3],
            alpha * 0.5
        )
        love.graphics.rectangle("fill", startX, y + height - 3, width * lifeRatio, 3)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- 清空所有通知
function BattleNotifications.clear()
    notifications = {}
end

-- 快捷方法
function BattleNotifications.baseUnderAttack(team)
    BattleNotifications.add(
        string.format("%s Base Under Attack!", team == "red" and "RED" or "BLUE"),
        "baseAttack",
        team
    )
end

function BattleNotifications.unitLeveledUp(team, unitClass, level)
    BattleNotifications.add(
        string.format("%s reached Level %d!", unitClass, level),
        "unitLevelUp",
        team
    )
end

function BattleNotifications.buildingComplete(team, buildingType)
    BattleNotifications.add(
        string.format("%s completed!", buildingType),
        "buildingComplete",
        team
    )
end

function BattleNotifications.towerBuilt(team, towerType)
    BattleNotifications.add(
        string.format("%s Tower built!", towerType),
        "towerBuilt",
        team
    )
end

function BattleNotifications.resourceDepleted(x, y)
    BattleNotifications.add(
        string.format("Resource depleted at (%.0f, %.0f)", x, y),
        "resourceDepleted"
    )
end

function BattleNotifications.victory(team)
    BattleNotifications.add(
        string.format("%s TEAM WINS!", team == "red" and "RED" or "BLUE"),
        "victory",
        team
    )
end

return BattleNotifications
