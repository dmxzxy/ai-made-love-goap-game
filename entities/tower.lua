-- 防御塔系统
local Tower = {}
Tower.__index = Tower

-- 防御塔类型配置
local towerTypes = {
    -- 箭塔：快速射击，中等伤害（平衡调整）
    Arrow = {
        name = "Arrow Tower",
        cost = 150,
        buildTime = 6,
        damage = 12,  -- 降低伤害（从22→12）
        attackSpeed = 1.8,  -- 减慢射击（从1.5→1.8）
        range = 220,  -- 减少射程（从280→220）
        color = {0.8, 0.6, 0.3},
        size = 22,
        health = 280,  -- 降低血量（从350→280）
        description = "Fast-firing tower with moderate range"
    },
    
    -- 炮塔：高伤害，溅射伤害（平衡调整）
    Cannon = {
        name = "Cannon Tower",
        cost = 250,
        buildTime = 10,
        damage = 45,  -- 大幅降低伤害（从85→45）
        attackSpeed = 0.6,  -- 减慢射速（从0.5→0.6）
        range = 260,  -- 减少射程（从320→260）
        splashRadius = 80,  -- 减小溅射范围（从100→80）
        color = {0.5, 0.5, 0.6},
        size = 28,
        health = 480,  -- 降低血量（从600→480）
        description = "Powerful splash damage, slow firing rate"
    },
    
    -- 激光塔：持续伤害，远程（平衡调整）
    Laser = {
        name = "Laser Tower",
        cost = 300,
        buildTime = 12,
        damage = 20,  -- 降低持续伤害（从35→20）
        attackSpeed = 10,
        range = 320,  -- 减少射程（从400→320）
        color = {0.3, 0.8, 1},
        size = 25,
        health = 350,  -- 降低血量（从400→350）
        description = "Long-range continuous damage beam"
    },
    
    -- 冰冻塔：减速+伤害（平衡调整）
    Frost = {
        name = "Frost Tower",
        cost = 200,
        buildTime = 8,
        damage = 8,  -- 降低伤害（从15→8）
        attackSpeed = 1.2,  -- 减慢攻击（从1.0→1.2）
        range = 210,  -- 减少射程（从260→210）
        slowEffect = 0.5,  -- 减弱减速效果（从0.4→0.5，即减速50%）
        slowDuration = 2.0,   -- 缩短持续时间（从2.5→2.0）
        color = {0.5, 0.8, 1},
        size = 24,
        health = 280,  -- 降低血量（从320→280）
        description = "Slows enemies by 50% for 2 seconds"
    }
}

function Tower.new(x, y, team, towerType)
    local self = setmetatable({}, Tower)
    
    local config = towerTypes[towerType]
    if not config then
        print("Unknown tower type: " .. towerType)
        return nil
    end
    
    -- 基本属性
    self.x = x
    self.y = y
    self.team = team
    self.towerType = towerType
    self.name = config.name
    self.cost = config.cost
    
    -- 战斗属性
    self.health = config.health
    self.maxHealth = config.health
    self.damage = config.damage
    self.attackSpeed = config.attackSpeed
    self.range = config.range
    self.splashRadius = config.splashRadius
    self.slowEffect = config.slowEffect
    self.slowDuration = config.slowDuration
    
    -- 视觉属性
    self.color = config.color
    self.size = config.size
    self.description = config.description
    
    -- 状态
    self.isDead = false
    self.buildProgress = 0
    self.buildTime = config.buildTime
    self.isBuilding = true
    
    -- 攻击状态
    self.target = nil
    self.attackCooldown = 0
    self.laserTarget = nil
    self.laserTime = 0
    
    -- 统计
    self.kills = 0
    self.damageDealt = 0
    
    -- 视觉效果
    self.shootEffect = nil
    self.rotationAngle = 0
    self.particles = {}  -- 粒子效果
    self.muzzleFlash = 0  -- 枪口闪光
    
    return self
end

function Tower:update(dt, enemies)
    if self.isDead then return end
    
    -- 建造中
    if self.isBuilding then
        self.buildProgress = self.buildProgress + dt
        if self.buildProgress >= self.buildTime then
            self.isBuilding = false
            print(string.format("[%s] %s completed!", self.team, self.name))
        end
        return
    end
    
    -- 更新射击冷却
    if self.attackCooldown > 0 then
        self.attackCooldown = self.attackCooldown - dt
    end
    
    -- 更新射击效果
    if self.shootEffect then
        self.shootEffect.time = self.shootEffect.time + dt
        if self.shootEffect.time > 0.3 then
            self.shootEffect = nil
        end
    end
    
    -- 更新粒子效果
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.alpha = p.life / p.maxLife
        end
    end
    
    -- 更新枪口闪光
    if self.muzzleFlash > 0 then
        self.muzzleFlash = self.muzzleFlash - dt * 10
    end
    
    -- 激光塔特殊逻辑
    if self.towerType == "Laser" and self.laserTarget then
        if self.laserTarget.isDead or self.laserTarget.health <= 0 then
            self.laserTarget = nil
            self.laserTime = 0
        else
            local dx = self.laserTarget.x - self.x
            local dy = self.laserTarget.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist <= self.range then
                self.laserTime = self.laserTime + 1
                if self.laserTime >= self.attackSpeed then
                    self.laserTarget = nil
                    self.laserTime = 0
                end
                -- 持续伤害
                self:dealDamage(self.laserTarget, self.damage * dt)
                self.rotationAngle = math.atan2(dy, dx)
                return
            else
                self.laserTarget = nil
                self.laserTime = 0
            end
        end
    end
    
    -- 寻找目标
    if not self.target or self.target.isDead or self.target.health <= 0 then
        self.target = self:findTarget(enemies)
    end
    
    if self.target then
        local dx = self.target.x - self.x
        local dy = self.target.y - self.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- 目标脱离范围
        if distance > self.range then
            self.target = nil
            return
        end
        
        -- 朝向目标
        self.rotationAngle = math.atan2(dy, dx)
        
        -- 攻击
        if self.attackCooldown <= 0 then
            self:attack(self.target, enemies)
            self.attackCooldown = 1 / self.attackSpeed
        end
    end
end

function Tower:findTarget(enemies)
    local nearestEnemy = nil
    local nearestDist = math.huge
    
    for _, enemy in ipairs(enemies) do
        if not enemy.isDead and enemy.health > 0 then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            if dist <= self.range and dist < nearestDist then
                nearestDist = dist
                nearestEnemy = enemy
            end
        end
    end
    
    return nearestEnemy
end

function Tower:attack(target, enemies)
    self.muzzleFlash = 1  -- 触发枪口闪光
    
    -- 加载特效系统
    local Particles = require("effects.particles")
    
    if self.towerType == "Cannon" then
        -- 炮塔：强化溅射伤害
        self:dealDamage(target, self.damage)
        
        -- 炮弹轨迹特效
        Particles.createBulletTrail(self.x, self.y, target.x, target.y, {1, 0.6, 0.2})
        
        -- 爆炸特效
        Particles.createExplosion(target.x, target.y, {1, 0.5, 0.1}, 1.5)
        addCameraShake(4)
        
        -- 更大范围的溅射伤害
        local splashCount = 0
        for _, enemy in ipairs(enemies) do
            if enemy ~= target and not enemy.isDead and enemy.health > 0 then
                local dx = enemy.x - target.x
                local dy = enemy.y - target.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                if dist <= self.splashRadius then
                    local splashDamage = self.damage * 0.6  -- 提升溅射伤害比例
                    self:dealDamage(enemy, splashDamage)
                    splashCount = splashCount + 1
                end
            end
        end
        
        self.shootEffect = {x = target.x, y = target.y, time = 0, type = "explosion"}
        
        -- 创建爆炸粒子（保留原有系统）
        for i = 1, 15 do
            local angle = math.random() * math.pi * 2
            local speed = 50 + math.random() * 100
            table.insert(self.particles, {
                x = target.x,
                y = target.y,
                vx = math.cos(angle) * speed,
                vy = math.sin(angle) * speed,
                life = 0.5,
                maxLife = 0.5,
                color = {1, 0.5 + math.random() * 0.3, 0},
                size = 3 + math.random() * 2,
                alpha = 1
            })
        end
        
    elseif self.towerType == "Laser" then
        -- 激光塔：持续锁定
        self.laserTarget = target
        self.laserTime = 0
        
        -- 激光束特效
        Particles.createLaserBeam(self.x, self.y, target.x, target.y, {0.3, 0.8, 1})
        
    elseif self.towerType == "Frost" then
        -- 冰冻塔：增强减速效果
        self:dealDamage(target, self.damage)
        
        -- 冰冻轨迹
        Particles.createBulletTrail(self.x, self.y, target.x, target.y, {0.5, 0.8, 1})
        Particles.createEnergyPulse(target.x, target.y, {0.5, 0.9, 1}, 3)
        
        -- 应用更强的减速效果
        if not target.slowedUntil or target.slowedUntil < love.timer.getTime() then
            target.originalSpeed = target.moveSpeed
        end
        target.slowedUntil = love.timer.getTime() + self.slowDuration
        target.moveSpeed = (target.originalSpeed or target.moveSpeed) * self.slowEffect
        target.isFrozen = true
        
        self.shootEffect = {x = target.x, y = target.y, time = 0, type = "frost"}
        
        -- 创建冰霜粒子（保留原有系统）
        for i = 1, 8 do
            local angle = math.random() * math.pi * 2
            local speed = 30 + math.random() * 50
            table.insert(self.particles, {
                x = target.x,
                y = target.y,
                vx = math.cos(angle) * speed,
                vy = math.sin(angle) * speed,
                life = 0.8,
                maxLife = 0.8,
                color = {0.5, 0.8 + math.random() * 0.2, 1},
                size = 2 + math.random() * 2,
                alpha = 1
            })
        end
        
    else
        -- 箭塔：快速攻击
        self:dealDamage(target, self.damage)
        self.shootEffect = {x = target.x, y = target.y, time = 0, type = "arrow"}
        
        -- 箭矢特效
        Particles.createBulletTrail(self.x, self.y, target.x, target.y, {0.8, 0.6, 0.3})
        Particles.createSparks(target.x, target.y, {1, 0.8, 0.4}, 4)
        
        -- 创建箭矢轨迹粒子
        for i = 1, 3 do
            local dx = target.x - self.x
            local dy = target.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            local ratio = (i / 3)
            table.insert(self.particles, {
                x = self.x + dx * ratio,
                y = self.y + dy * ratio,
                vx = 0,
                vy = 0,
                life = 0.2,
                maxLife = 0.2,
                color = {0.8, 0.6, 0.2},
                size = 3,
                alpha = 1
            })
        end
    end
end

function Tower:dealDamage(target, damage)
    target.health = target.health - damage
    self.damageDealt = self.damageDealt + damage
    
    if target.health <= 0 and not target.isDead then
        self.kills = self.kills + 1
    end
    
    -- 添加伤害数字显示
    if target.addDamageNumber then
        target:addDamageNumber(math.floor(damage), {1, 0.5, 0})
    end
end

function Tower:takeDamage(damage, isCrit, attacker)
    if self.isDead or self.isBuilding then return 0 end
    
    local actualDamage = damage
    if isCrit then
        actualDamage = damage * 1.5  -- 防御塔受到暴击也有加成
    end
    
    self.health = self.health - actualDamage
    if self.health <= 0 then
        self.isDead = true
        print(string.format("[%s] %s destroyed!", self.team, self.name))
    end
    
    return actualDamage
end

function Tower:draw()
    if self.isDead then return end
    
    -- 建造中显示
    if self.isBuilding then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        love.graphics.circle("fill", self.x, self.y, self.size)
        
        -- 建造进度
        love.graphics.setColor(1, 1, 1)
        local progress = self.buildProgress / self.buildTime
        love.graphics.arc("fill", self.x, self.y, self.size, -math.pi/2, -math.pi/2 + math.pi * 2 * progress)
        
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print(string.format("%.0f%%", progress * 100), 
            self.x - 15, self.y - 8, 0, 0.8, 0.8)
        return
    end
    
    -- 攻击范围（半透明圆圈）
    if self.target then
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.1)
        love.graphics.circle("fill", self.x, self.y, self.range)
    end
    
    -- 塔底座（八边形）
    love.graphics.setColor(0.2, 0.2, 0.2)
    local baseVertices = {}
    for i = 0, 7 do
        local angle = i * math.pi / 4
        table.insert(baseVertices, self.x + math.cos(angle) * (self.size + 8))
        table.insert(baseVertices, self.y + math.sin(angle) * (self.size + 8))
    end
    love.graphics.polygon("fill", baseVertices)
    
    -- 塔身（根据类型绘制不同形状）
    if self.towerType == "Cannon" then
        -- 重炮塔：六边形塔身
        love.graphics.setColor(self.color[1] * 0.8, self.color[2] * 0.8, self.color[3] * 0.8)
        local vertices = {}
        for i = 0, 5 do
            local angle = i * math.pi / 3
            table.insert(vertices, self.x + math.cos(angle) * self.size)
            table.insert(vertices, self.y + math.sin(angle) * self.size)
        end
        love.graphics.polygon("fill", vertices)
        love.graphics.setColor(self.color[1], self.color[2], self.color[3])
        love.graphics.circle("fill", self.x, self.y, self.size * 0.6)
    elseif self.towerType == "Laser" then
        -- 激光塔：方形塔身 + 中心能量核心
        love.graphics.setColor(self.color[1] * 0.7, self.color[2] * 0.7, self.color[3] * 0.7)
        love.graphics.rectangle("fill", self.x - self.size, self.y - self.size, self.size * 2, self.size * 2)
        love.graphics.setColor(0.2, 0.8, 1, 0.8)
        love.graphics.circle("fill", self.x, self.y, self.size * 0.5)
        -- 能量脉冲效果
        local pulse = math.sin(love.timer.getTime() * 3) * 0.2 + 0.8
        love.graphics.setColor(0.5, 1, 1, pulse)
        love.graphics.circle("fill", self.x, self.y, self.size * 0.3)
    elseif self.towerType == "Frost" then
        -- 冰霜塔：菱形塔身 + 冰晶装饰
        love.graphics.setColor(self.color[1] * 0.8, self.color[2] * 0.8, self.color[3] * 0.8)
        love.graphics.polygon("fill",
            self.x, self.y - self.size,
            self.x + self.size, self.y,
            self.x, self.y + self.size,
            self.x - self.size, self.y)
        love.graphics.setColor(0.6, 0.9, 1, 0.7)
        for i = 0, 3 do
            local angle = i * math.pi / 2 + math.pi / 4
            local r = self.size * 0.6
            love.graphics.polygon("fill",
                self.x + math.cos(angle) * r, self.y + math.sin(angle) * r,
                self.x + math.cos(angle + 0.5) * r * 0.4, self.y + math.sin(angle + 0.5) * r * 0.4,
                self.x + math.cos(angle - 0.5) * r * 0.4, self.y + math.sin(angle - 0.5) * r * 0.4)
        end
    else
        -- 箭塔：圆形塔身 + 箭袋装饰
        love.graphics.setColor(self.color[1] * 0.8, self.color[2] * 0.8, self.color[3] * 0.8)
        love.graphics.circle("fill", self.x, self.y, self.size)
        love.graphics.setColor(0.6, 0.4, 0.2)
        love.graphics.circle("fill", self.x, self.y, self.size * 0.6)
        -- 箭矢装饰
        for i = 0, 2 do
            local angle = i * math.pi * 2 / 3
            love.graphics.setColor(0.8, 0.6, 0.3)
            love.graphics.line(
                self.x + math.cos(angle) * self.size * 0.3,
                self.y + math.sin(angle) * self.size * 0.3,
                self.x + math.cos(angle) * self.size * 0.7,
                self.y + math.sin(angle) * self.size * 0.7)
        end
    end
    
    -- 边框（团队颜色高亮）
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.size + 2)
    love.graphics.setLineWidth(1)
    
    -- 炮管/武器系统
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotationAngle)
    
    if self.towerType == "Cannon" then
        -- 重炮：双管炮塔
        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.rectangle("fill", 0, -10, self.size + 15, 8)
        love.graphics.rectangle("fill", 0, 2, self.size + 15, 8)
        love.graphics.setColor(0.15, 0.15, 0.2)
        love.graphics.circle("fill", self.size + 15, -6, 5)
        love.graphics.circle("fill", self.size + 15, 6, 5)
    elseif self.towerType == "Laser" then
        -- 激光炮：三棱镜发射器
        love.graphics.setColor(0.1, 0.4, 0.7)
        love.graphics.polygon("fill",
            0, -6,
            self.size + 8, -3,
            self.size + 8, 3,
            0, 6)
        love.graphics.setColor(0.3, 0.8, 1)
        love.graphics.circle("fill", self.size + 8, 0, 4)
    elseif self.towerType == "Frost" then
        -- 冰霜炮：冰锥发射器
        love.graphics.setColor(0.2, 0.5, 0.7)
        love.graphics.polygon("fill",
            0, -5,
            self.size + 5, -8,
            self.size + 10, 0,
            self.size + 5, 8,
            0, 5)
        love.graphics.setColor(0.7, 0.95, 1)
        love.graphics.polygon("fill",
            self.size + 5, 0,
            self.size + 10, -3,
            self.size + 10, 3)
    else
        -- 箭塔：复合弓
        love.graphics.setColor(0.5, 0.3, 0.15)
        love.graphics.rectangle("fill", 0, -3, self.size + 5, 6)
        love.graphics.setColor(0.7, 0.5, 0.2)
        love.graphics.arc("line", "open", 0, 0, self.size, -math.pi/3, math.pi/3)
    end
    
    love.graphics.pop()
    
    -- 枪口闪光效果
    if self.muzzleFlash > 0 then
        love.graphics.setColor(1, 1, 0, self.muzzleFlash)
        local flashX = self.x + math.cos(self.rotationAngle) * self.size
        local flashY = self.y + math.sin(self.rotationAngle) * self.size
        love.graphics.circle("fill", flashX, flashY, 8)
    end
    
    -- 激光束
    if self.laserTarget and not self.laserTarget.isDead then
        love.graphics.setLineWidth(4)
        love.graphics.setColor(0.3, 0.8, 1, 0.8)
        love.graphics.line(self.x, self.y, self.laserTarget.x, self.laserTarget.y)
        
        -- 激光核心
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.line(self.x, self.y, self.laserTarget.x, self.laserTarget.y)
        love.graphics.setLineWidth(1)
        
        -- 激光击中特效
        love.graphics.setColor(0.5, 1, 1, 0.6)
        love.graphics.circle("fill", self.laserTarget.x, self.laserTarget.y, 8)
    end
    
    -- 绘制粒子效果
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    -- 射击效果
    if self.shootEffect then
        local alpha = 1 - (self.shootEffect.time / 0.3)
        if self.shootEffect.type == "explosion" then
            -- 爆炸效果（更强）
            love.graphics.setColor(1, 0.5, 0, alpha)
            local size = 20 + self.shootEffect.time * 50
            love.graphics.circle("fill", self.shootEffect.x, self.shootEffect.y, size)
            love.graphics.setColor(1, 0.8, 0, alpha * 0.5)
            love.graphics.circle("fill", self.shootEffect.x, self.shootEffect.y, size * 1.3)
        elseif self.shootEffect.type == "frost" then
            -- 冰霜效果
            love.graphics.setColor(0.5, 0.8, 1, alpha)
            local size = 15 + self.shootEffect.time * 30
            love.graphics.circle("fill", self.shootEffect.x, self.shootEffect.y, size)
        elseif self.shootEffect.type == "arrow" then
            -- 箭矢命中
            love.graphics.setColor(1, 0.8, 0, alpha)
            love.graphics.circle("fill", self.shootEffect.x, self.shootEffect.y, 8)
        end
    end
    if self.towerType == "Laser" and self.laserTarget then
        love.graphics.setColor(0.3, 0.8, 1, 0.8)
        love.graphics.setLineWidth(4)
        love.graphics.line(self.x, self.y, self.laserTarget.x, self.laserTarget.y)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.line(self.x, self.y, self.laserTarget.x, self.laserTarget.y)
        love.graphics.setLineWidth(1)
        
        -- 激光击中特效
        local t = love.timer.getTime()
        for i = 1, 3 do
            local angle = t * 10 + i * math.pi * 2 / 3
            local r = 10 + math.sin(t * 5) * 5
            love.graphics.setColor(0.5, 1, 1, 0.8)
            love.graphics.circle("fill", 
                self.laserTarget.x + math.cos(angle) * r,
                self.laserTarget.y + math.sin(angle) * r, 3)
        end
    end
    
    -- 射击效果
    if self.shootEffect then
        local alpha = 1 - (self.shootEffect.time / 0.3)
        if self.shootEffect.type == "explosion" then
            -- 爆炸效果
            love.graphics.setColor(1, 0.5, 0, alpha)
            local radius = 10 + self.shootEffect.time * 60
            love.graphics.circle("fill", self.shootEffect.x, self.shootEffect.y, radius)
            love.graphics.setColor(1, 0.8, 0, alpha * 0.5)
            love.graphics.circle("fill", self.shootEffect.x, self.shootEffect.y, radius * 0.7)
        elseif self.shootEffect.type == "frost" then
            -- 冰冻效果
            love.graphics.setColor(0.5, 0.8, 1, alpha)
            for i = 1, 6 do
                local angle = i * math.pi / 3
                local dist = self.shootEffect.time * 30
                love.graphics.circle("fill",
                    self.shootEffect.x + math.cos(angle) * dist,
                    self.shootEffect.y + math.sin(angle) * dist, 5)
            end
        else
            -- 箭矢轨迹
            love.graphics.setColor(0.8, 0.6, 0.3, alpha)
            love.graphics.line(self.x, self.y, self.shootEffect.x, self.shootEffect.y)
        end
    end
    
    -- 生命条
    local barWidth = self.size * 2
    local barHeight = 5
    local barX = self.x - barWidth / 2
    local barY = self.y - self.size - 15
    
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    love.graphics.setColor(0.2, 1, 0.2)
    local healthPercent = self.health / self.maxHealth
    love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
    
    -- 塔类型标识
    love.graphics.setColor(1, 1, 1)
    local label = self.towerType:sub(1, 1)  -- 首字母
    love.graphics.print(label, self.x - 5, self.y - 8, 0, 1.2, 1.2)
end

-- 获取塔的配置信息
function Tower.getTypes()
    return towerTypes
end

return Tower
