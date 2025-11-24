-- GOAP Action - 行动基类
local Action = {}
Action.__index = Action

function Action.new(name, cost)
    local self = setmetatable({}, Action)
    self.name = name
    self.cost = cost or 1
    self.preconditions = {}
    self.effects = {}
    self.target = nil
    return self
end

-- 添加前置条件
function Action:addPrecondition(key, value)
    self.preconditions[key] = value
end

-- 添加效果
function Action:addEffect(key, value)
    self.effects[key] = value
end

-- 检查是否可以执行
function Action:checkProceduralPrecondition(agent)
    return true
end

-- 执行行动
function Action:perform(agent, dt)
    return false -- 返回true表示完成
end

return Action
