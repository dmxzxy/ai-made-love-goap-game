-- 粒子特效系统
local Particles = {}

-- 粒子对象池
local particlePool = {}
local maxParticles = 2000

-- 粒子类型
local ParticleTypes = {
    BULLET = "bullet",
    EXPLOSION = "explosion",
    BLOOD = "blood",
    SPARK = "spark",
    SMOKE = "smoke",
    LASER_BEAM = "laser_beam",
    MUZZLE_FLASH = "muzzle_flash",
    DEATH = "death",
    HIT = "hit",
    GOLD = "gold",
    ENERGY = "energy"
}

-- 创建单个粒子
local function createParticle(x, y, vx, vy, life, color, size, particleType)
    return {
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        life = life,
        maxLife = life,
        color = color,
        size = size,
        type = particleType,
        alpha = 1,
        gravity = 0,
        rotation = math.random() * math.pi * 2,
        rotationSpeed = (math.random() - 0.5) * 4
    }
end

-- 初始化粒子系统
function Particles.init()
    particlePool = {}
end

-- 更新所有粒子
function Particles.update(dt)
    for i = #particlePool, 1, -1 do
        local p = particlePool[i]
        
        -- 更新位置
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        
        -- 应用重力
        p.vy = p.vy + p.gravity * dt
        
        -- 更新旋转
        p.rotation = p.rotation + p.rotationSpeed * dt
        
        -- 更新生命值
        p.life = p.life - dt
        
        -- 更新透明度（渐隐效果）
        p.alpha = p.life / p.maxLife
        
        -- 移除死亡粒子
        if p.life <= 0 then
            table.remove(particlePool, i)
        end
    end
end

-- 绘制所有粒子
function Particles.draw()
    for _, p in ipairs(particlePool) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        
        if p.type == ParticleTypes.BULLET then
            -- 子弹：小圆点 + 拖尾
            love.graphics.circle("fill", p.x, p.y, p.size)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha * 0.3)
            love.graphics.circle("fill", p.x - p.vx * 0.02, p.y - p.vy * 0.02, p.size * 0.7)
            
        elseif p.type == ParticleTypes.LASER_BEAM then
            -- 激光束：长条形
            love.graphics.circle("fill", p.x, p.y, p.size * 1.5)
            
        elseif p.type == ParticleTypes.EXPLOSION or p.type == ParticleTypes.DEATH then
            -- 爆炸/死亡：渐变圆圈
            love.graphics.circle("fill", p.x, p.y, p.size * (1.5 - p.alpha * 0.5))
            
        elseif p.type == ParticleTypes.BLOOD or p.type == ParticleTypes.HIT then
            -- 血液/击中：小方块
            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            love.graphics.rotate(p.rotation)
            love.graphics.rectangle("fill", -p.size/2, -p.size/2, p.size, p.size)
            love.graphics.pop()
            
        elseif p.type == ParticleTypes.SPARK then
            -- 火花：线条
            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            love.graphics.rotate(p.rotation)
            love.graphics.rectangle("fill", 0, -p.size/4, p.size * 3, p.size/2)
            love.graphics.pop()
            
        elseif p.type == ParticleTypes.SMOKE then
            -- 烟雾：扩散圆
            local smokeSize = p.size * (2 - p.alpha)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha * 0.4)
            love.graphics.circle("fill", p.x, p.y, smokeSize)
            
        elseif p.type == ParticleTypes.GOLD then
            -- 金币：闪光圆点
            love.graphics.circle("fill", p.x, p.y, p.size)
            love.graphics.setColor(1, 1, 0.5, p.alpha * 0.5)
            love.graphics.circle("fill", p.x, p.y, p.size * 1.5)
            
        elseif p.type == ParticleTypes.ENERGY then
            -- 能量：发光方块
            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            love.graphics.rotate(p.rotation)
            love.graphics.rectangle("fill", -p.size/2, -p.size/2, p.size, p.size)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha * 0.3)
            love.graphics.rectangle("fill", -p.size, -p.size, p.size * 2, p.size * 2)
            love.graphics.pop()
            
        else
            -- 默认：圆形
            love.graphics.circle("fill", p.x, p.y, p.size)
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- 添加粒子到池中
local function addParticle(particle)
    if #particlePool < maxParticles then
        table.insert(particlePool, particle)
    end
end

-- 创建子弹轨迹特效
function Particles.createBulletTrail(x, y, targetX, targetY, color)
    local angle = math.atan2(targetY - y, targetX - x)
    local speed = 800
    
    for i = 1, 3 do
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        local p = createParticle(
            x, y,
            vx + (math.random() - 0.5) * 50,
            vy + (math.random() - 0.5) * 50,
            0.3 + math.random() * 0.2,
            color or {1, 0.9, 0.3},
            2 + math.random() * 2,
            ParticleTypes.BULLET
        )
        addParticle(p)
    end
end

-- 创建爆炸特效
function Particles.createExplosion(x, y, color, intensity)
    intensity = intensity or 1
    local count = math.floor(15 * intensity)
    
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 100 + math.random() * 150 * intensity
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        
        local p = createParticle(
            x, y,
            vx, vy,
            0.4 + math.random() * 0.3,
            color or {1, 0.5, 0.1},
            4 + math.random() * 4 * intensity,
            ParticleTypes.EXPLOSION
        )
        p.gravity = 200
        addParticle(p)
    end
    
    -- 中心闪光
    for i = 1, 3 do
        local p = createParticle(
            x, y, 0, 0,
            0.2,
            {1, 1, 0.8},
            20 * intensity,
            ParticleTypes.EXPLOSION
        )
        addParticle(p)
    end
end

-- 创建血液飞溅
function Particles.createBloodSplatter(x, y, color)
    for i = 1, 10 do
        local angle = math.random() * math.pi * 2
        local speed = 50 + math.random() * 100
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        
        local p = createParticle(
            x, y,
            vx, vy,
            0.5 + math.random() * 0.3,
            color or {0.8, 0.1, 0.1},
            2 + math.random() * 3,
            ParticleTypes.BLOOD
        )
        p.gravity = 300
        addParticle(p)
    end
end

-- 创建火花特效
function Particles.createSparks(x, y, color, count)
    count = count or 8
    
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 100 + math.random() * 150
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        
        local p = createParticle(
            x, y,
            vx, vy,
            0.3 + math.random() * 0.2,
            color or {1, 0.8, 0.3},
            3 + math.random() * 2,
            ParticleTypes.SPARK
        )
        p.gravity = 150
        addParticle(p)
    end
end

-- 创建烟雾效果
function Particles.createSmoke(x, y, color, count)
    count = count or 5
    
    for i = 1, count do
        local vx = (math.random() - 0.5) * 30
        local vy = -20 - math.random() * 30
        
        local p = createParticle(
            x + (math.random() - 0.5) * 10,
            y + (math.random() - 0.5) * 10,
            vx, vy,
            1.0 + math.random() * 0.5,
            color or {0.3, 0.3, 0.3},
            8 + math.random() * 6,
            ParticleTypes.SMOKE
        )
        addParticle(p)
    end
end

-- 创建激光束特效
function Particles.createLaserBeam(x, y, targetX, targetY, color)
    local angle = math.atan2(targetY - y, targetX - x)
    local distance = math.sqrt((targetX - x)^2 + (targetY - y)^2)
    local steps = math.floor(distance / 20)
    
    for i = 1, steps do
        local t = i / steps
        local px = x + (targetX - x) * t
        local py = y + (targetY - y) * t
        
        local p = createParticle(
            px, py,
            (math.random() - 0.5) * 20,
            (math.random() - 0.5) * 20,
            0.1 + math.random() * 0.1,
            color or {0.3, 0.8, 1},
            3 + math.random() * 2,
            ParticleTypes.LASER_BEAM
        )
        addParticle(p)
    end
end

-- 创建死亡爆炸
function Particles.createDeathExplosion(x, y, color, size)
    size = size or 1
    
    -- 外圈碎片
    for i = 1, 20 do
        local angle = (i / 20) * math.pi * 2
        local speed = 100 + math.random() * 100
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        
        local p = createParticle(
            x, y,
            vx, vy,
            0.6 + math.random() * 0.4,
            color or {1, 0.3, 0.1},
            3 + math.random() * 4 * size,
            ParticleTypes.DEATH
        )
        p.gravity = 250
        addParticle(p)
    end
    
    -- 中心冲击波
    for i = 1, 3 do
        local p = createParticle(
            x, y, 0, 0,
            0.3,
            {1, 1, 1},
            30 * size,
            ParticleTypes.EXPLOSION
        )
        addParticle(p)
    end
end

-- 创建击中特效
function Particles.createHitEffect(x, y, color)
    for i = 1, 6 do
        local angle = math.random() * math.pi * 2
        local speed = 50 + math.random() * 80
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        
        local p = createParticle(
            x, y,
            vx, vy,
            0.3 + math.random() * 0.2,
            color or {1, 1, 0.3},
            2 + math.random() * 2,
            ParticleTypes.HIT
        )
        addParticle(p)
    end
end

-- 创建金币飞行特效
function Particles.createGoldEffect(x, y, targetX, targetY)
    local angle = math.atan2(targetY - y, targetX - x)
    local speed = 200 + math.random() * 100
    local vx = math.cos(angle) * speed
    local vy = math.sin(angle) * speed
    
    for i = 1, 3 do
        local p = createParticle(
            x + (math.random() - 0.5) * 10,
            y + (math.random() - 0.5) * 10,
            vx + (math.random() - 0.5) * 50,
            vy + (math.random() - 0.5) * 50,
            0.8 + math.random() * 0.3,
            {1, 0.9, 0.2},
            3 + math.random() * 2,
            ParticleTypes.GOLD
        )
        addParticle(p)
    end
end

-- 创建能量脉冲
function Particles.createEnergyPulse(x, y, color, size)
    for i = 1, 12 do
        local angle = (i / 12) * math.pi * 2
        local speed = 80 + math.random() * 60
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        
        local p = createParticle(
            x, y,
            vx, vy,
            0.4 + math.random() * 0.3,
            color or {0.3, 0.8, 1},
            size or (3 + math.random() * 3),
            ParticleTypes.ENERGY
        )
        addParticle(p)
    end
end

-- 获取粒子数量（调试用）
function Particles.getCount()
    return #particlePool
end

-- 清空所有粒子
function Particles.clear()
    particlePool = {}
end

return Particles
