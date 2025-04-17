--[[
    规范:
    1.每个文件返回一组create函数,每个create函数对应一个更新器
    2.每个create函数返回一个新的**无参**函数:update(),update()返回的是更新的值
    3.每个create函数的参数不能有函数,只能是IPAS对象和updaters对象+简单的数据类型(前两者必有)
    4.每个create函数的名字不能重复
]]

return {
    -- 获取指定位置存储设备的全部物品信息
    createInventoryListUpdater = function(IPAS, updaters, peripheralName)
        local value = {}
        return function()
            local peripheral = peripheral.wrap(peripheralName)
            if peripheral and peripheral.list then
                value = peripheral.list()
            end
            return value
        end
    end,

    -- 获取指定位置存储设备中物品的总数量
    createInventoryItemCountUpdater = function(IPAS, updaters, peripheralName)
        local value = 0
        return function()
            local peripheral = peripheral.wrap(peripheralName)
            if peripheral and peripheral.list then
                local items = peripheral.list()
                local count = 0
                for slot, item in pairs(items) do
                    count = count + item.count
                end
                value = count
            end
            return value
        end
    end,

    -- 获取指定位置存储设备中特定物品的数量
    createSpecificItemCountUpdater = function(IPAS, updaters, peripheralName, itemName)
        local value = 0
        return function()
            local peripheral = peripheral.wrap(peripheralName)
            if peripheral and peripheral.list then
                local items = peripheral.list()
                local count = 0
                for slot, item in pairs(items) do
                    if item.name == itemName then
                        count = count + item.count
                    end
                end
                value = count
            end
            return value
        end
    end,

    -- 获取存储设备的可用空槽数量
    createInventoryFreeSlotUpdater = function(IPAS, updaters, peripheralName)
        local value = 0
        return function()
            local peripheral = peripheral.wrap(peripheralName)
            if peripheral and peripheral.size then
                local size = peripheral.size()
                local items = peripheral.list()
                value = size - #items
            end
            return value
        end
    end
} 