local function __dump(var, level)
    local rval = {}
    table.insert(rval, "{")
    for k, v in pairs(var) do
        if type(v) == "table" and getmetatable(var) ~= v then
            if k ~= "__base" and k ~= "parent____" then
                table.insert(rval, string.format("%s%s = %s", string.rep("    ", level), k, __dump(v, level + 1)))
            end
        elseif type(v) ~= "function" and k ~= "parentkey____" then
            table.insert(rval, string.format("%s%s = %s", string.rep("    ", level), k, tostring(v)))
        end
    end
    table.insert(rval, string.format("%s}", string.rep("    ", level - 1)))
    return table.concat(rval, "\n")
end

table.log = function(inst)
    if inst == nil then
        print(nil)
        return
    end
    if type(inst) ~= "table" then
        print(inst)
        return
    end
    print(__dump(inst, 1))
end

local binding = require("rdatabinding")

local playerRaw = {
    coin = 100,
    diamond = 200,
    attr = {
        attack = 50,
        defence = 60
    }
}

local redpointRaw = {
    inventory = {
        equip = 0,
        material = 0
    },
    skill = 0
}

---@class playerRaw
---@field coin number
---@field diamond number
local player = binding.bindable(playerRaw)

---@class redpointRaw
---@field inventory table
---@field skill number
local redpoint = binding.bindable(redpointRaw)

table.log(player)
table.log(redpoint)

local onCoinChanged = function(newValue, oldValue)
    print("coin = " .. newValue)
    player.diamond = player.diamond - 1
end
local onDiamondChanged = function(newValue, oldValue)
    print("diamond = " .. newValue)
end
binding.On(player, "coin", onCoinChanged)
binding.On(player, "diamond", onDiamondChanged)

local onSkillRPChanged = function(newValue, oldValue)
    print("skill redpoint changed : " .. newValue)
end
binding.On(redpoint, "skill", onSkillRPChanged)

player.coin = 1000
player.diamond = 2000

redpoint.skill = 1

binding.Off(player, "coin", onCoinChanged)
binding.Off(player, "diamond", onDiamondChanged)

player.coin = 3000
player.diamond = 4000

print("执行完毕...")