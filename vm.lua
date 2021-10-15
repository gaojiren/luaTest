local binding = require("rdatabinding")
local data = require("data")

local vm = {}

vm.listeners = {}

function vm:Start()
    self:On(
        data,
        "diamond",
        function(value, old)
            print("diamond value changed : " .. value)
        end
    )
end

function vm:On(tb, key, func)
    table.insert(
        self.listeners,
        {
            tb = tb,
            key = key,
            func = func
        }
    )
    binding.On(tb, key, func)
end

function vm:OnDestroy()
    for i, v in ipairs(self.listeners) do
        binding.Off(v.tb, v.key, v.func)
    end
    self.listeners = {}
end

return vm
