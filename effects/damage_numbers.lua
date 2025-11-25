-- 浮动伤害数字系统
local DamageNumbers = {}

local numberPool = {}
local maxNumbers = 100

-- 创建单个伤害数字
local function createDamageNumber(x, y, damage, isCrit, isHeal)
    return {
        x = x,
        y = y,
        damage = damage,
        life = 1.5,  -- 显示时长
        maxLife = 1.5,
        alpha = 1,
        vx = (math.random() - 0.5) * 30,
        vy = -80 - math.random() * 40,
        isCrit = isCrit,
        isHeal = isHeal,
        scale = isCrit and 1.5 or 1.0,
        rotation = (math.random() - 0.5) * 0.3
    }
end

-- 初始化
function DamageNumbers.init()
    numberPool = {}
end

-- 添加伤害数字
function DamageNumbers.add(x, y, damage, isCrit, isHeal)
    if #numberPool < maxNumbers then
        table.insert(numberPool, createDamageNumber(x, y, damage, isCrit, isHeal))
    end
end

-- 更新
function DamageNumbers.update(dt)
    for i = #numberPool, 1, -1 do
        local num = numberPool[i]
        
        -- 更新位置
        num.x = num.x + num.vx * dt
        num.y = num.y + num.vy * dt
        
        -- 减速
        num.vx = num.vx * 0.95
        num.vy = num.vy * 0.98
        
        -- 更新生命值
        num.life = num.life - dt
        num.alpha = num.life / num.maxLife
        
        -- 缩放动画
        if num.life > num.maxLife * 0.8 then
            local t = (num.maxLife - num.life) / (num.maxLife * 0.2)
            num.scale = (num.isCrit and 1.5 or 1.0) * (0.5 + t * 0.5)
        end
        
        -- 移除
        if num.life <= 0 then
            table.remove(numberPool, i)
        end
    end
end

-- 绘制
function DamageNumbers.draw()
    for _, num in ipairs(numberPool) do
        love.graphics.push()
        love.graphics.translate(num.x, num.y)
        love.graphics.rotate(num.rotation)
        love.graphics.scale(num.scale, num.scale)
        
        local text = tostring(math.floor(num.damage))
        
        -- 设置颜色
        if num.isHeal then
            -- 治疗：绿色
            love.graphics.setColor(0.2, 1, 0.3, num.alpha)
        elseif num.isCrit then
            -- 暴击：金色 + 外发光
            love.graphics.setColor(1, 0.3, 0.1, num.alpha * 0.5)
            love.graphics.print(text, -2, -2)
            love.graphics.print(text, 2, -2)
            love.graphics.print(text, -2, 2)
            love.graphics.print(text, 2, 2)
            love.graphics.setColor(1, 0.9, 0.2, num.alpha)
        else
            -- 普通伤害：白色
            love.graphics.setColor(1, 1, 1, num.alpha)
        end
        
        -- 绘制阴影
        love.graphics.setColor(0, 0, 0, num.alpha * 0.5)
        love.graphics.print(text, 1, 1)
        
        -- 绘制主文本
        if num.isHeal then
            love.graphics.setColor(0.2, 1, 0.3, num.alpha)
        elseif num.isCrit then
            love.graphics.setColor(1, 0.9, 0.2, num.alpha)
        else
            love.graphics.setColor(1, 1, 1, num.alpha)
        end
        love.graphics.print(text, 0, 0)
        
        love.graphics.pop()
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- 清空
function DamageNumbers.clear()
    numberPool = {}
end

return DamageNumbers
