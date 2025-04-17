--[[
    规范:
    1.每个文件返回一组create函数,每个create函数对应一个更新器
    2.每个create函数返回一个新的**无参**函数:update(),update()返回的是更新的值
    3.每个create函数的参数不能有函数,只能是IPAS对象和updaters对象+简单的数据类型(前两者必有)
    4.每个create函数的名字不能重复
]]

-- 适用于支持能量API的设备
-- 如Industrial Foregoing, Mekanism, Thermal 等模组的机器和储能设备

return {
    -- 获取当前储存的能量
    createEnergyStoredUpdater = function(IPAS, updaters, peripheralName)
        local value = 0
        return function()
            local peripheral = peripheral.wrap(peripheralName)
            if peripheral then
                -- 尝试不同模组的能量API
                if peripheral.getEnergy then 
                    value = peripheral.getEnergy()
                elseif peripheral.getEnergyStored then
                    value = peripheral.getEnergyStored()
                elseif peripheral.energy and peripheral.energy.getEnergy then
                    value = peripheral.energy.getEnergy()
                end
            end
            return value
        end
    end,

    -- 获取最大能量容量
    createEnergyCapacityUpdater = function(IPAS, updaters, peripheralName)
        local value = 0
        return function()
            local peripheral = peripheral.wrap(peripheralName)
            if peripheral then
                -- 尝试不同模组的能量API
                if peripheral.getMaxEnergy then 
                    value = peripheral.getMaxEnergy()
                elseif peripheral.getMaxEnergyStored then
                    value = peripheral.getMaxEnergyStored()
                elseif peripheral.energy and peripheral.energy.getMaxEnergy then
                    value = peripheral.energy.getMaxEnergy()
                end
            end
            return value
        end
    end,

    -- 获取能量存储百分比
    createEnergyPercentUpdater = function(IPAS, updaters, peripheralName)
        local value = 0
        return function()
            local peripheral = peripheral.wrap(peripheralName)
            if peripheral then
                local stored = 0
                local capacity = 1 -- 避免除以零
                
                -- 获取存储量
                if peripheral.getEnergy then 
                    stored = peripheral.getEnergy()
                elseif peripheral.getEnergyStored then
                    stored = peripheral.getEnergyStored()
                elseif peripheral.energy and peripheral.energy.getEnergy then
                    stored = peripheral.energy.getEnergy()
                end
                
                -- 获取容量
                if peripheral.getMaxEnergy then 
                    capacity = peripheral.getMaxEnergy()
                elseif peripheral.getMaxEnergyStored then
                    capacity = peripheral.getMaxEnergyStored()
                elseif peripheral.energy and peripheral.energy.getMaxEnergy then
                    capacity = peripheral.energy.getMaxEnergy()
                end
                
                if capacity > 0 then
                    value = (stored / capacity) * 100
                end
            end
            return value
        end
    end,

    -- 获取能量生产/消耗率 (如果设备支持)
    createEnergyFlowRateUpdater = function(IPAS, updaters, peripheralName)
        local lastEnergy = 0
        local value = 0
        
        return function()
            local peripheral = peripheral.wrap(peripheralName)
            if peripheral then
                local currentEnergy = 0
                
                -- 获取当前能量
                if peripheral.getEnergy then 
                    currentEnergy = peripheral.getEnergy()
                elseif peripheral.getEnergyStored then
                    currentEnergy = peripheral.getEnergyStored()
                elseif peripheral.energy and peripheral.energy.getEnergy then
                    currentEnergy = peripheral.energy.getEnergy()
                end
                
                -- 计算变化率
                value = currentEnergy - lastEnergy
                lastEnergy = currentEnergy
            end
            return value
        end
    end
} 