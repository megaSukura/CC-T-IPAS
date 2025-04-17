--[[
    规范:
    1.每个文件返回一组create函数,每个create函数对应一个更新器
    2.每个create函数返回一个新的**无参**函数:update(),update()返回的是更新的值
    3.每个create函数的参数不能有函数,只能是IPAS对象和updaters对象+简单的数据类型(前两者必有)
    4.每个create函数的名字不能重复
]]

-- 基本外设信息和监控

return {
    -- 获取所有连接的外设列表
    createPeripheralListUpdater = function(IPAS, updaters)
        local value = {}
        return function()
            value = peripheral.getNames()
            return value
        end
    end,
    
    -- 监控特定外设是否存在
    createPeripheralPresentUpdater = function(IPAS, updaters, peripheralName)
        local value = false
        return function()
            value = peripheral.isPresent(peripheralName)
            return value
        end
    end,
    
    -- 获取外设的类型
    createPeripheralTypeUpdater = function(IPAS, updaters, peripheralName)
        local value = ""
        return function()
            if peripheral.isPresent(peripheralName) then
                value = peripheral.getType(peripheralName)
            else
                value = "not_present"
            end
            return value
        end
    end,
    
    -- 获取外设的方法列表
    createPeripheralMethodsUpdater = function(IPAS, updaters, peripheralName)
        local value = {}
        return function()
            if peripheral.isPresent(peripheralName) then
                value = peripheral.getMethods(peripheralName)
            else
                value = {}
            end
            return value
        end
    end,
    
    -- 获取调制解调器(modem)的开放频道
    createModemChannelsUpdater = function(IPAS, updaters, peripheralName)
        local value = {}
        return function()
            local modem = peripheral.wrap(peripheralName)
            if modem and modem.isWireless then
                -- 获取modem的开放频道
                if modem.getOpenChannels then
                    value = modem.getOpenChannels()
                end
            end
            return value
        end
    end,
    
    -- 网络消息接收器 (非阻塞实现)
    createNetworkMessageUpdater = function(IPAS, updaters, channel)
        local value = {hasMessage = false, message = nil, sender = "", time = 0}
        channel = channel or 1 -- 默认监听频道1
        
        -- 打开指定频道
        local function openChannel()
            for name, wrapped in pairs(updaters.peripherals) do
                if wrapped.isWireless and wrapped.isWireless() then
                    wrapped.open(channel)
                    return true
                end
            end
            
            -- 尝试找到无线调制解调器并打开频道
            for _, name in ipairs(peripheral.getNames()) do
                local p = peripheral.wrap(name)
                if p and p.isWireless and p.isWireless() then
                    p.open(channel)
                    return true
                end
            end
            return false
        end
        
        -- 尝试打开频道
        openChannel()
        
        return function()
            -- 检查是否有modem事件，但不阻塞
            local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message", 0)
            
            if event and senderChannel == channel then
                value = {
                    hasMessage = true,
                    message = message,
                    sender = modemSide,
                    distance = senderDistance or 0,
                    reply = replyChannel or 0,
                    time = os.time()
                }
            else
                -- 保留上一条消息，但标记为非新消息
                value.hasMessage = false
            end
            return value
        end
    end,
    
    -- 监控器分辨率更新器
    createMonitorSizeUpdater = function(IPAS, updaters, peripheralName)
        local value = {width = 0, height = 0}
        return function()
            local monitor = peripheral.wrap(peripheralName)
            if monitor and monitor.getSize then
                local width, height = monitor.getSize()
                value = {width = width, height = height}
            end
            return value
        end
    end
} 