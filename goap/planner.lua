-- GOAP Planner - 用于生成行动计划
local Planner = {}
Planner.__index = Planner

function Planner.new()
    local self = setmetatable({}, Planner)
    return self
end

-- 检查前置条件是否满足
function Planner:checkConditions(conditions, worldState)
    for key, value in pairs(conditions) do
        if worldState[key] ~= value then
            return false
        end
    end
    return true
end

-- A* 算法寻找最优行动序列
function Planner:plan(availableActions, worldState, goal)
    -- 使用A*算法寻找最优路径
    local openList = {}
    local closedList = {}
    
    -- 起始节点
    local startNode = {
        state = self:copyTable(worldState),
        cost = 0,
        actions = {},
        heuristic = self:calculateHeuristic(worldState, goal)
    }
    
    table.insert(openList, startNode)
    
    local maxIterations = 1000
    local iterations = 0
    
    while #openList > 0 and iterations < maxIterations do
        iterations = iterations + 1
        
        -- 找到f值最小的节点
        table.sort(openList, function(a, b)
            return (a.cost + a.heuristic) < (b.cost + b.heuristic)
        end)
        
        local current = table.remove(openList, 1)
        
        -- 检查是否达到目标
        if self:checkConditions(goal, current.state) then
            return current.actions
        end
        
        table.insert(closedList, current)
        
        -- 扩展节点
        for _, action in ipairs(availableActions) do
            if self:checkConditions(action.preconditions, current.state) then
                local newState = self:applyEffects(self:copyTable(current.state), action.effects)
                
                -- 检查是否已在closed list中
                local inClosed = false
                for _, closed in ipairs(closedList) do
                    if self:statesEqual(closed.state, newState) then
                        inClosed = true
                        break
                    end
                end
                
                if not inClosed then
                    -- 浅复制 actions 数组（不要深度复制action对象，保留它们的metatable）
                    local newActions = {}
                    for i, act in ipairs(current.actions) do
                        newActions[i] = act
                    end
                    table.insert(newActions, action)
                    
                    local newNode = {
                        state = newState,
                        cost = current.cost + action.cost,
                        actions = newActions,
                        heuristic = self:calculateHeuristic(newState, goal)
                    }
                    
                    table.insert(openList, newNode)
                end
            end
        end
    end
    
    return nil
end

-- 计算启发式值（未满足的目标数量）
function Planner:calculateHeuristic(state, goal)
    local count = 0
    for key, value in pairs(goal) do
        if state[key] ~= value then
            count = count + 1
        end
    end
    return count
end

-- 应用效果到状态
function Planner:applyEffects(state, effects)
    for key, value in pairs(effects) do
        state[key] = value
    end
    return state
end

-- 复制表
function Planner:copyTable(t)
    local copy = {}
    for key, value in pairs(t) do
        if type(value) == "table" then
            copy[key] = self:copyTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- 比较两个状态是否相等
function Planner:statesEqual(state1, state2)
    for key, value in pairs(state1) do
        if state2[key] ~= value then
            return false
        end
    end
    for key, value in pairs(state2) do
        if state1[key] ~= value then
            return false
        end
    end
    return true
end

return Planner
