-- IPAS 前台显示模块

local IPASFrontend = {}

-- 前台框架容器
local frontendFrames = {}
local isRunning = false
local frontendThread = nil

-- 停止前台显示
IPASFrontend.stop = function()
    isRunning = false
    
    -- 清除所有前台框架
    for name, frame in pairs(frontendFrames) do
        frame:remove()
    end
    frontendFrames = {}
end

-- 格式化信息值
local function formatInfoValue(info, format)
    local value = info:getValue()
    local valueType = type(value)
    
    -- 处理不同类型的值
    if valueType == "table" then
        -- 转字符串
        local result = ""
        print_table(value,function(line)
            if not line then
                result = result .. "\n"
            else
                result = result .. line .. "\n"
            end
        end,nil,"[]")
        -- error("string len:"..#result)
        return string.format(format, result)
    elseif valueType == "boolean" then
        return string.format(format, value and "true" or "false")
    else
        return string.format(format, tostring(value))
    end
end

-- 更新监视器显示
local function updateMonitor(monitorFrame, monitorConfig, settings)
    -- 检查框架是否有效
    if not monitorFrame or not monitorFrame.getType or monitorFrame:getType() == nil then
        return
    end
    
    -- 安全地移除子元素
    pcall(function()
        monitorFrame:removeChildren()
    end)
    
    -- 设置背景
    monitorFrame:setBackground(settings.defaultColors.background)
    
    -- 绘制标题
    local title = monitorFrame:addLabel()
        :setPosition(1, 1)
        :setSize("{parent.w}", 1)
        :setText("IPAS Monitor: " .. monitorConfig.name)
        :setForeground(settings.defaultColors.header)
        :setBackground(colors.gray)
    
    -- 查找并显示所有配置的信息项
    local y = 3
    for _, itemId in ipairs(monitorConfig.items) do
        -- 查找显示项
        local displayItem = nil
        for _, item in ipairs(IPASFrontend.IPAS.frontendConfig.displayItems) do
            if item.id == itemId then
                displayItem = item
                break
            end
        end
        
        if displayItem then
            local info = IPASFrontend.IPAS.Infos[displayItem.infoName]
            if info then
                -- 显示标签
                local label = monitorFrame:addLabel()
                    :setPosition(displayItem.x, y)
                    :setText(displayItem.displayName .. ": ")
                    :setForeground(settings.defaultColors.text)
                
                -- 显示值
                local valueText = formatInfoValue(info, displayItem.format)
                -- error("=====log=========:"..valueText)
                local value = monitorFrame:addLabel()
                    :setPosition(displayItem.x + #displayItem.displayName + 2, y)
                    :setText(valueText)
                    :setForeground(settings.defaultColors.text)
                
                y = y + value:getHeight()
            else
                -- 信息不存在，显示错误
                local errorLabel = monitorFrame:addLabel()
                    :setPosition(displayItem.x, y)
                    :setText("Error: Info '" .. displayItem.infoName .. "' not found")
                    :setForeground(settings.defaultColors.error)
                
                y = y + errorLabel:getHeight()
            end
        end
    end
end

-- 刷新所有监视器显示
local function refreshAllMonitors()
    -- 检查是否正在运行
    if not isRunning then
        return
    end
    
    local settings = IPASFrontend.IPAS.frontendConfig.settings
    
    -- 更新所有监视器
    for _, monitorConfig in ipairs(IPASFrontend.IPAS.frontendConfig.monitors) do
        local frame = frontendFrames[monitorConfig.name]
        if frame then
            -- 使用pcall避免一个监视器的错误影响所有监视器
            pcall(function()
                updateMonitor(frame, monitorConfig, settings)
            end)
        end
    end
end

-- 前台显示更新循环
local function frontendUpdateLoop()
    local settings = IPASFrontend.IPAS.frontendConfig.settings
    
    while isRunning do
        -- 使用pcall包装刷新调用，避免错误导致线程终止
        pcall(refreshAllMonitors)
        
        -- 更新间隔不应小于0.05秒
        local refreshRate = settings.refreshRate or 0.5
        if refreshRate < 0.05 then refreshRate = 0.05 end
        
        os.sleep(refreshRate)
    end
end

-- 启动前台显示
IPASFrontend.start = function(self)
    if isRunning then
        return
    end
    local settings = self.IPAS.frontendConfig.settings
    
    -- 停止任何正在运行的实例
    self.stop()
    
    -- 检查配置
    if not self.IPAS.frontendConfig.monitors or #self.IPAS.frontendConfig.monitors == 0 then
        return -- 没有配置监视器，直接返回
    end
    
    -- 发现所有监视器
    local monitors = {}
    monitors["terminal"] = term.current() -- 添加当前终端
    
    -- 查找外部监视器
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "monitor" then
            monitors[name] = peripheral.wrap(name)
        end
    end
    
    -- 为每个配置的监视器创建框架
    for _, monitorConfig in ipairs(self.IPAS.frontendConfig.monitors) do
        local monitor = monitors[monitorConfig.name]
        
        if monitor then
            -- 设置监视器缩放
            if monitorConfig.name ~= "terminal" and monitor.setTextScale then
                pcall(function() monitor.setTextScale(settings.textScale) end)
            end
            
            -- 创建监视器框架
            local frame
            
            -- 使用pcall避免错误中断程序
            local success = pcall(function()
                if monitorConfig.name == "terminal" then
                    frame = self.basalt.addFrame()
                else
                    frame = self.basalt.addMonitor()
                    frame:setMonitor(monitor)
                end

                -- 存储框架引用
                frontendFrames[monitorConfig.name] = frame
            end)
            
            -- 初始更新监视器显示
            updateMonitor(frame, monitorConfig, settings)
            
            -- 如果创建失败，记录错误
            if not success then
                frontendFrames[monitorConfig.name] = nil
            end
        end
    end
    
    -- 标记为运行中
    isRunning = true
    
    -- 启动更新线程，只有在成功创建了至少一个框架时才启动
    local frameCount = 0
    for _ in pairs(frontendFrames) do frameCount = frameCount + 1 end
    
    if frameCount > 0 then
        -- 使用Basalt的Thread来管理前台更新
        -- error(type(self.basalt))
        frontendThread = self.basalt.getActiveFrame():addThread()
        frontendThread:start(frontendUpdateLoop)
    end
end

return IPASFrontend