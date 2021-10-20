local binding = {}
local rawget = rawget
local rawset = rawset
local getmetatable = getmetatable
local setmetatable = setmetatable
local oldIpairs = ipairs
local oldPairs = pairs

function dump(tb)
    return function()
        local tmp = {}
        local mtb = getmetatable(tb) or tb
        for k, v in pairs(mtb) do
            if type(v) == "funcion" or string.find(k, "__") then
            else
                if type(v) == "table" then
                    tmp[k] = dump(v)()
                else
                    tmp[k] = v
                end
            end
        end
        return tmp
    end
end

function filter(template, src, needFilter)
    if type(src) ~= "table" or not needFilter then
        return src
    end
    local outTalbe = {}
    for k, v in pairs(template) do
        if type(src[k]) == "table" then
            outTalbe[k] = filter(v, src[k], needFilter)
        else
            outTalbe[k] = src[k]
        end
    end
    return outTalbe
end

local function choose(tb, func)
    local choose = {}
    for k, v in oldPairs(tb) do
        if func(k, v) then
            choose[k] = v
        end
    end
    return choose
end

function table.indexOf(list, target, from, useMaxN)
    local len = useMaxN or #list
    if from == nil then
        from = 1
    end
    for i = from, len do
        if list[i] == target then
            return i
        end
    end
    return -1
end

function format4reading(tableOrNot)
    if type(tableOrNot) == "table" and getmetatable(tableOrNot) then
        return tableOrNot.dump()
    end
    return tableOrNot
end

ipairs = function(arr)
    local meta_t = getmetatable(arr)
    if meta_t and meta_t.__ipairs then
        return meta_t.__ipairs(arr)
    end
    return oldIpairs(arr)
end

pairs = function(arr)
    local meta_t = getmetatable(arr)
    if meta_t and meta_t.__pairs then
        return meta_t.__pairs(arr)
    end
    return oldPairs(arr)
end

--- 通知注册者
---@param mt table metatable
---@param key string
---@param v_old any 原始值，可以为bool, number, nil, string 也可以是table
---@param v_new any 最新值，可以为bool, number, nil, string 也可以是table
---@param needFilter boolean 是否需要过滤掉非改变字段
function notify(mt, key, v_old, v_new, needFilter)
    local binds = mt.bind____[key]
    if not binds then
        return
    end
    for i = 1, #binds do
        local v = binds[i]
        if type(v) == "function" then
            v_new = filter(v_old, v_new, needFilter)
            v(format4reading(v_new), format4reading(v_old))
        end
    end
end

--- 通知变化，逐级冒泡
---@param mt table metatable
---@param key string
---@param v_old any 原始值，可以为bool, number, nil, string 也可以是table
---@param v_new any 最新值，可以为bool, number, nil, string 也可以是table
---@param needFilter boolean 是否需要过滤掉非改变字段
function valueChangedNotify(mt, key, v_old, v_new, needFilter)
    --- 如存在上一级，向上级查找
    if mt.parent____ ~= nil then
        valueChangedNotify(
            mt.parent____,
            mt.parentkey____,
            {[key] = v_old},
            mt.parent____[mt.parentkey____].dump(),
            needFilter
        )
    end
    --- 处理普通注册
    notify(mt, key, v_old, v_new, needFilter)
    --- 处理通配符注册
    notify(mt, "*", {[key] = format4reading(v_old)}, {[key] = v_new}, needFilter)
end

function binding.bindable(init, parentkey, parent)
    local t = {}
    local mt
    mt = {
        --- 记录父级信息，回调时可以追溯到上层
        parent____ = parent,
        parentkey____ = parentkey,
        bind____ = {},
        maxn____ = {}, -- no table.maxn in lua5.3
        __index = function(tb, key)
            --- 新增insert函数，保证数据存储在metatable中
            if key == "insert" then
                return function(...)
                    local args = table.pack(...)
                    local mt = getmetatable(tb)
                    local v_old = tb.dump()
                    if #args > 1 then
                        table.insert(mt, args[1], args[2])
                    else
                        table.insert(mt, args[1])
                    end
                    -- 触发一下回调
                    mt["parent____"]:valueChangedNotify(mt["parentkey____"], v_old, tb.dump(), false)
                end
            end

            --- 新增remove函数，保证数据存储在metatable中
            if key == "remove" then
                return function(pos)
                    local mt = getmetatable(tb)
                    local v_old = tb.dump()
                    table.remove(mt, pos)
                    mt["parent____"]:valueChangedNotify(mt["parentkey____"], v_old, tb.dump(), false)
                end
            end

            if key == "dump" then
                return dump(tb)
            end

            if key == "valueChangedNotify" then
                return valueChangedNotify
            end

            return mt[key]
        end,
        __newindex = function(tb, key, value)
            local v_old = mt[key]
            if v_old == value then
                return
            end
            if type(value) == "table" then
                local metatableValue = getmetatable(value)
                if metatableValue == nil or not metatableValue["bind____"] then
                    value = binding.bindable(value, key, tb)
                end
            end
            mt[key] = value
            tb.valueChangedNotify(mt, key, v_old, value, true)
        end,
        __ipairs = function(t)
            return oldIpairs(mt)
        end,
        __pairs = function(t)
            local mtWithoutFuncNorInner =
                choose(
                mt,
                function(k, v)
                    return type(v) ~= "function" and (type(v) ~= "table" or (k ~= "bind____" and k ~= "maxn____"))
                end
            )
            return oldPairs(mtWithoutFuncNorInner)
        end
    }
    setmetatable(t, mt)
    if type(init) == "table" then
        for k, v in pairs(init) do
            if type(v) == "table" then
                rawset(mt, k, binding.bindable(v, k, t))
            else
                rawset(mt, k, v)
            end
        end
    end
    return t
end

function binding.On(t, key, func)
    if not key or not func then
        return
    end
    local firstAccessKey = string.match(key, "(%a*)%.")
    -- print(firstAccessKey)
    if firstAccessKey and type(t[firstAccessKey]) == "table" then
        -- local secondAccessKey = string.match(key, "%a*%.(%a*)%.*")
        local remainAccesskeys = string.match(key, "%a*%.(.*)")
        -- print(secondAccessKey)
        return binding.On(t[firstAccessKey], remainAccesskeys, func)
    end

    local binds = t.bind____
    if not binds[key] then
        binds[key] = {}
    end
    local bind = binds[key]
    table.insert(bind, func)
end

function binding.Off(t, key, func)
    local firstAccessKey = string.match(key, "(%a*)%.")
    -- print(firstAccessKey)
    if firstAccessKey and type(t[firstAccessKey]) == "table" then
        local remainAccesskeys = string.match(key, "%a*%.(.*)")
        binding.Off(t[firstAccessKey], remainAccesskeys, func)
        return
    end

    local binds = t.bind____
    if binds[key] then
        local bind = binds[key]
        local index = table.indexOf(bind, func)
        table.remove(bind, index)
    end
end
return binding
