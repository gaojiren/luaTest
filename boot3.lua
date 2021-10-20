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

local vm = require("vm")
local data = require("data")

vm:Start()
print("======== start =========")
data.diamond = 500
data.coin = 10
data.attr.attack = 100
print("======== onDestroy =========")
vm:OnDestroy()

data.diamond = 400
data.coin = 1

--table.log(data)
print("======== boot3 end =========")
