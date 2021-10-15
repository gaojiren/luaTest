local vm = require("vm")
local data = require("data")

vm:Start()

data.diamond = 500

vm:OnDestroy()

data.diamond = 400

print("boot3 end")
