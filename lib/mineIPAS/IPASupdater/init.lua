-- IPAS 的更新器(updater)模块
local updaters = {
    peripherals = {}
}
local peripheralsName = peripheral.getNames()

for k, v in pairs(peripheralsName) do
    updaters.peripherals[v] = peripheral.wrap(v)
end

--获取所有的更新器,本目录下的所有文件,除了init.lua

local files = fs.list("lib/mineIPAS/IPASupdater")
if files then
    for k, v in pairs(files) do
        if v ~= "init.lua" then
            v = string.sub(v, 1, -5) -- 去掉后缀.lua
            local updater = require("/lib/mineIPAS/IPASupdater/" .. v)
            updaters[v] = updater -- 注意是一组create函数:使用时例如updaters.blockUpdater.createEnergyStoreUpdater(IPAS,updaters,peripheralName)
        end
    end
end

--[[
    规范:
    1.每个文件返回一组create函数,每个create函数对应一个更新器
    2.每个create函数返回一个新的**无参**函数:uptate(),uptate()返回的是更新的值
    3.每个create函数的参数不能有函数,只能是IPAS对象和updaters对象+简单的数据类型(前两者必有)
    4.每个create函数的名字不能重复
    例子:
    blockUpdater.lua:
    return {
        createEnergyStoreUpdater = function(IPAS,updaters,peripheralName)
            local value = 0
            return function() -- 这个函数是update函数
                value = updaters.peripherals[peripheralName].getEnergyStored()
                return value
            end
        end
    }
    这个例子中,createEnergyStoreUpdater是一个create函数,它返回一个update函数,这个update函数返回的是一个值,这个值是peripheralName这个外设的储能量
]]
































return updaters