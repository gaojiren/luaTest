local binding = require("rdatabinding")

local raw = {
    coin = 100,
    diamond = 200,
}

---@class data
---@field coin number
---@field diamond number
local data = binding.bindable(raw)

return data