-- Resource node for mining
local Resource = {}
Resource.__index = Resource

function Resource.new(x, y)
    local self = setmetatable({}, Resource)
    
    self.x = x
    self.y = y
    self.size = 30
    self.resources = 2500  -- 增加资源总量（1500→2500）
    self.maxResources = 2500
    self.miningRate = 10
    self.depleted = false
    self.pulseTime = math.random() * math.pi * 2
    
    return self
end

function Resource:update(dt)
    self.pulseTime = self.pulseTime + dt * 2
    
    if self.resources <= 0 then
        self.depleted = true
    end
end

function Resource:mine(amount)
    if self.depleted then
        return 0
    end
    
    local mined = math.min(amount, self.resources)
    self.resources = self.resources - mined
    
    if self.resources <= 0 then
        self.depleted = true
        print(string.format("Resource at (%.0f, %.0f) depleted!", self.x, self.y))
    end
    
    return mined
end

function Resource:draw()
    if self.depleted then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        love.graphics.circle("fill", self.x, self.y, self.size * 0.6)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.circle("line", self.x, self.y, self.size * 0.6)
        return
    end
    
    local pulse = 1.0 + math.sin(self.pulseTime) * 0.1
    love.graphics.setColor(1, 0.8, 0, 0.7)
    love.graphics.circle("fill", self.x, self.y, self.size * pulse)
    
    love.graphics.setColor(1, 1, 0, 0.3)
    love.graphics.circle("fill", self.x, self.y, self.size * pulse * 1.3)
    
    love.graphics.setColor(0.8, 0.6, 0)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.size * pulse)
    love.graphics.setLineWidth(1)
    
    local percent = self.resources / self.maxResources
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("%.0f", self.resources), 
        self.x - 15, self.y - 8, 0, 0.8, 0.8)
    
    local barWidth = self.size * 2
    local barHeight = 4
    local barX = self.x - barWidth / 2
    local barY = self.y + self.size + 5
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.rectangle("fill", barX, barY, barWidth * percent, barHeight)
end

return Resource
