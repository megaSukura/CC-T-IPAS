--[[
    规范:
    1.每个文件返回一组create函数,每个create函数对应一个更新器
    2.每个create函数返回一个新的**无参**函数:update(),update()返回的是更新的值
    3.每个create函数的参数不能有函数,只能是IPAS对象和updaters对象+简单的数据类型(前两者必有)
    4.每个create函数的名字不能重复
]]

-- 适用于CC:Tweaked的环境监测功能
-- 注意：部分功能需要额外模组支持

return {
    -- 红石信号强度监测 (原版CC功能)
    createRedstoneSignalUpdater = function(IPAS, updaters, side)
        local value = 0
        side = side or "all" -- 可选参数，默认检测所有方向
        
        return function()
            if side == "all" then
                local signals = {
                    front = redstone.getInput("front"),
                    back = redstone.getInput("back"),
                    left = redstone.getInput("left"),
                    right = redstone.getInput("right"),
                    top = redstone.getInput("top"),
                    bottom = redstone.getInput("bottom")
                }
                value = signals
            else
                value = redstone.getInput(side)
            end
            return value
        end
    end,
    
    -- 游戏内时间监测 (原版CC功能)
    createGameTimeUpdater = function(IPAS, updaters)
        local value = 0
        return function()
            value = os.time() -- 游戏内时间 (0-24000)
            return value
        end
    end,
    
    -- 游戏内天数监测 (原版CC功能)
    createGameDayUpdater = function(IPAS, updaters)
        local value = 0
        return function()
            -- 一天有24000 ticks，从0点开始
            value = math.floor(os.day())
            return value
        end
    end,
    
    -- 检测是否为夜晚 (基于游戏时间)
    createIsNightUpdater = function(IPAS, updaters)
        local value = false
        return function()
            local time = os.time()
            -- 游戏中大约13000-23000是夜晚
            value = (time >= 13000 and time < 23000)
            return value
        end
    end,
    
    -- GPS位置监测 (原版CC功能，需要无线调制解调器和GPS设置)
    createGPSLocationUpdater = function(IPAS, updaters)
        local value = {x=0, y=0, z=0, success=false}
        return function()
            local x, y, z = gps.locate(2) -- 2秒超时
            if x and y and z then
                value = {x=x, y=y, z=z, success=true}
            else
                value.success = false
            end
            return value
        end
    end,
    
    -- 命令执行结果监测 (原版CC功能，需要命令电脑)
    createCommandResultUpdater = function(IPAS, updaters, command)
        local value = {success=false, output=""}
        command = command or "time query daytime" -- 默认命令
        
        return function()
            if commands then
                local success, output = commands.exec(command)
                value = {success=success, output=output or ""}
            else
                value = {success=false, output="Commands API not available"}
            end
            return value
        end
    end,
    
    -- 计算机外部输入监测 (键盘/鼠标事件)
    createUserInputUpdater = function(IPAS, updaters, timeout)
        local value = {event="none", data={}}
        timeout = timeout or 0.1 -- 默认等待时间
        
        return function()
            local event, p1, p2, p3 = os.pullEvent(timeout)
            if event then
                if event == "key" or event == "key_up" or event == "char" then
                    value = {event=event, data={key=p1, held=p2}}
                elseif event == "mouse_click" or event == "mouse_up" or event == "mouse_drag" then
                    value = {event=event, data={button=p1, x=p2, y=p3}}
                elseif event == "monitor_touch" then
                    value = {event=event, data={side=p1, x=p2, y=p3}}
                else
                    value = {event=event, data={p1=p1, p2=p2, p3=p3}}
                end
            else
                value = {event="none", data={}}
            end
            return value
        end
    end,
    
    -- 检测计算机周围的方块 (需要地质分析仪或挖掘海龟)
    createSurroundingBlocksUpdater = function(IPAS, updaters)
        local value = {front="unknown", up="unknown", down="unknown"}
        
        return function()
            -- 检查是否有turtle API
            if turtle then
                local success, data = turtle.inspect()
                if success then
                    value.front = data.name
                end
                
                success, data = turtle.inspectUp()
                if success then
                    value.up = data.name
                end
                
                success, data = turtle.inspectDown()
                if success then
                    value.down = data.name
                end
            end
            return value
        end
    end
} 