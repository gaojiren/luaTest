local function __dump(var, level)
    local rval = {}
    table.insert(rval, "{")
    for k, v in pairs(var) do
        if type(v) == "table" and getmetatable(var) ~= v then
            if k ~= "__base" then
                table.insert(rval, string.format("%s%s=%s", string.rep("    ", level), k, __dump(v, level + 1)))
            end
        elseif type(v) ~= "function" then
            table.insert(rval, string.format("%s%s=%s", string.rep("    ", level), k, tostring(v)))
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

-- ---@class myTableType
-- myTableType = {
--     a = "a",
--     b = "b",
--     c = {
--         x = {
--             p = {
--                 _ = "c.x.p",
--                 w = "c.x.p.w"
--             },
--             q = "c.x.q"
--         },
--         y = "c.y",
--         z = "c.z"
--     }
-- }

local binding = require("rdatabinding")

local rawTable = {
    a = 1,
    b = {[1] = "b1", [2] = "b2"},
    c = {
        x = {
            p = {
                w = "w"
            },
            q = 222
        },
        y = 22,
        z = 33
    }
}

---@class rawTable
---@field a number
---@field b number[]
---@field c any
local myTable = binding.bindable(rawTable)

local valueChanged = function(val, old)
    print("====== 全局监听 =======")
    print("old value:")
    table.log(old)
    print("new value:")
    table.log(val)
end

local aValueChanged = function(val, old)
    print("====== a value changed =======")
    print("value = " .. val, ", oldValue = ", old)
    print()
end

local bValueChanged = function(val, old)
    print("====== b value changed =======")
    print("old value:")
    table.log(old)
    print("new value:")
    table.log(val)
    print()
end

local cValueChanged = function(val, old)
    print("====== c value changed =======")
    print("old value:")
    table.log(old)
    print("new value:")
    table.log(val)
end

local cxpValueChanged = function(val, old)
    print("====== c.x.p value changed =======")
    print("old value:")
    table.log(old)
    print("new value:")
    table.log(val)
end

local tag = binding.On(myTable, "*", valueChanged)
local tag_a = binding.On(myTable, "a", aValueChanged)
local tag_b = binding.On(myTable, "b", bValueChanged)
local tag_c = binding.On(myTable, "c", cValueChanged)
local tag_cxp = binding.On(myTable, "c.x.p", cxpValueChanged)

-- 优化批量操作
-- RawSet(key, val)
-- Apply()

-- myTable.a = 999999
-- myTable.a = 123456
-- myTable.b[2] = "b2222"
-- myTable.b.remove(2)
-- myTable.b.remove(1)
-- myTable.b.insert("b4") -- insert到指定索引
-- myTable.b[4] = "b33333" -- 请使用insert添加到新索引 否则回调时，无法计算正确old, new
-- myTable.c.y = 2222
myTable.c.x.p.w = "wwww"
-- myTable.c = {}
-- myTable.c = nil
-- myTable.a = 111
-- print(myTable.c.x.p.w)

-- 遍历table
-- for k, v in pairs(myTable) do
--     print(k, v)
-- end

print("********print table***********")
-- local myDump = myTable.dump()
-- table.log(myTable.dump())

-- 需要处理unwatch
binding.Off(myTable, "c.x.p", tag_cxp)
binding.Off(myTable, "c", tag_cxp)
binding.Off(myTable, "*", tag)
myTable.c.x.p.w = -9999

-- binding.watch(
--     myTable,
--     "a",
--     function(val, old)
--         print("value = " .. val, ", oldValue = ", old)
--     end
-- )
-- myTable.a = 111
-- myTable.c = {}

-- table.log(myTable)

-- local other = {}
-- binding.bind(myTable, "a", other, "a")
-- myTable.a = 11
-- myTable.b = 22
-- log(other)

-- local function bindable(init)
--     local t = {}
--     t.watch = function(self, key, func)
--         local binds = self.bind____
--         binds[key] = binds[key] or {}
--         local bind = binds[key]
--         bind[#bind + 1] = func
--         return #bind
--     end
--     local mt
--     mt = {
--         bind____ = {},
--         __index = function(table, param)
--             return mt[param]
--         end,
--         __newindex = function(table, key, value)
--             local v_old = mt[key]
--             if v_old == value then
--                 return
--             end
--             mt[key] = value
--             local slots = mt.bind____[key]
--             if slots then
--                 for _, v in ipairs(slots) do
--                     v(value, v_old)
--                 end
--             end
--         end
--     }
--     setmetatable(t, mt)
--     for k, v in pairs(init) do
--         t[k] = v
--     end
--     return t
-- end

-- ---@class data
-- ---@field x number
-- ---@field y number
-- local data = bindable({a = 1, b = 2, dir = {x = 0, y = 0}})

-- local dataType = {
--     a = "a",
--     b = "b",
--     dir = {x = "dir.x", y = "dir.y"}
-- }

-- data:watch(
--     "a",
--     function(val, old)
--         print("变化了:", "新:", val, "旧:", old)
--     end
-- )

-- data.a = 123
-- data.a = 234
-- -- data.y = 22
-- -- data.x_watch(function(val) print(val) end)
-- -- data.x = 111
-- -- data.x = 222
-- -- data.y = 333

-- -- log(getmetatable(data))
