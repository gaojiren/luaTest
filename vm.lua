local binding = require("rdatabinding")
local data = require("data")

local vm = {}

vm._listeners = {}

function vm:Start()
    --不安全注册消息形式，需要自己手动接触注册
    data:watch(
            dataKey.coin,
            function()
                print("coin value changed")
            end
    )

    --标准注册形式1
    self:On(
            data,
            "diamond",
            function(value, old)
                print("diamond value changed : " .. value)
            end
    )

    --标准注册形式2
    self:On(
            data,
            dataKey.attr.attack,
            function(val, old)
                print("attr.attack changed : " .. val)
            end
    )
end

function vm:On(tb, key, func)
    table.insert(
            self._listeners,
            {
                tb = tb,
                key = key,
                func = func
            }
    )
    binding.On(tb, key, func)
end

function vm:OnDestroy()
    for i, v in ipairs(self._listeners) do
        binding.Off(v.tb, v.key, v.func)
    end
    self._listeners = {}
end

return vm
