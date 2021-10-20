local binding = require("rdatabinding")
local data_raw = require("data_raw")

---@class attr
---@field attack number 攻击
---@field defence number 防御

---@class data
---@field coin number 金币
---@field diamond number 钻石
---@field level number 等级
---@field attr attr 属性
local data = binding.bindable(data_raw)


---@class dataKey
dataKey = {
    --- 金币
    coin = "coin",
    --- 钻石
    diamond = "diamond",
    --- 属性
    attr = {
        _ = "attr",
        --- 攻击
        attack = "attr.attack",
        --- 防御
        defence = "attr.defence"
    }
}

---@param t table
---@param key dataKey
function data:watch(key, func)
    binding.On(self, key, func)
end

return data
