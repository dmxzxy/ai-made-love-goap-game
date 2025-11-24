-- 测试GOAP规划器
local Planner = require("goap.planner")
local FindTarget = require("actions.find_target")
local MoveToEnemy = require("actions.move_to_enemy")
local AttackEnemy = require("actions.attack_enemy")

print("=== Testing GOAP Planner ===")

local planner = Planner.new()
print("Planner created:", planner)

local actions = {
    FindTarget.new(),
    MoveToEnemy.new(),
    AttackEnemy.new()
}
print("Actions created:", #actions)

for i, action in ipairs(actions) do
    print(string.format("  Action %d: %s (cost=%d)", i, action.name, action.cost))
    print("    Preconditions:", action.preconditions.hasTarget, action.preconditions.inRange)
    print("    Effects:", action.effects.hasTarget, action.effects.inRange)
end

local worldState = {
    hasTarget = false,
    inRange = false
}
print("\nWorld State:", "hasTarget=" .. tostring(worldState.hasTarget), "inRange=" .. tostring(worldState.inRange))

local goalState = {
    inRange = true
}
print("Goal State:", "inRange=" .. tostring(goalState.inRange))

print("\nPlanning...")
local plan = planner:plan(actions, worldState, goalState)

if plan then
    print("Plan found with", #plan, "actions:")
    for i, action in ipairs(plan) do
        print("  " .. i .. ": " .. action.name)
    end
else
    print("No plan found!")
end

print("\n=== Test Complete ===")
