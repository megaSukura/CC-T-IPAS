--[[
    mineIPAS
    Imformation Processing and Analysis System
    是minecraft computerCraft mod中的一个基于Basalt库的信息处理和分析系统
    主要功能:
    1.信息处理
        ■来自"设备"：原始信息、来自另一系统
        ■自定义生成：本地变量，其他信息的组合
        ■处理：过滤、转换、计算
        ■分析：统计、图表

    2.信息展示
        ■ui自定义（一定自由度）
            a.组合，保存
        ■控件

    3.输出
        ■另一系统
        ■设备：专用设备，红石信号

--]]

--[[
    1.定义"信息":
        * 信息是一个对象，有属性和变更事件
        * 信息的处理本质是处理后信息对源信息对象变更事件的监听,然后刷新自身,形成一个信息处理链
        * 信息的展示和输出是对某信息的监听,然后不同的输出方式以不同的方式对信息进行输出(如ui,红石信号,另一系统)
    信息从源头到输出的流程:
        1.信息源                input
        2.信息处理(中间信息)     process and analysis
        3.信息输出              output
--]]
--[[
    "split" cpy from basalt
--]]
local sub,find,reverse,rep,insert,len = string.sub,string.find,string.reverse,string.rep,table.insert,string.len
local split = function (str, delimiter)
    local results = {}
    if str == "" or delimiter == "" then
        return results
    end
    local start = 1
    local delim_start, delim_end = find(str, delimiter, start)
        while delim_start do
            insert(results, sub(str, start, delim_start - 1))
            start = delim_end + 1
            delim_start, delim_end = find(str, delimiter, start)
        end
    insert(results, sub(str, start))
    return results
end

local IPAS = {}

-- 1.定义"信息"

local function defaultRule(typ)
    return function(self, value)
     local isValid = false

        -- 如果typ以table{开头
        
        if (type(typ)=="string" and  string.sub(typ, 1, 6) == "table{") then
            --则去掉table{和}
            --print("typ",typ,"value",value)
            local types = string.sub(typ, 7, -2)
            --如果types是table,即以{开头,以}结尾
            if (string.find(types, "{") == 1 and string.find(types, "}") == #types) then
                --去掉{}
                types = string.sub(types, 2, -2)
                --然后用逗号分隔
                types = split(types, ",")
                --然后将value递归地用本函数检查
                
            end


            --然后将value递归地用本函数检查
            if (type(value) == "table") then
                for _, v in pairs(value) do
                    --print("  v",v,"types",types)
                    defaultRule(types)(self, v)
                    -- 如果有一个不符合，就会报错
                end
                isValid = true
            else
                --error(self:getType()..": Invalid type for property "..name.."! Expected "..typ..", got ")
            end
        end
    
        if(type(typ)=="string")then
            if string.find(typ, "|")~=nil then
            local types = split(typ, "|")
                for _,v in pairs(types)do
                    --递归地用本函数检查
                    --print(v)
                    if pcall(defaultRule(v),self,value) then
                    isValid = true
                    break
                    end
                end
            else
                --type()函数返回值有:
                --"nil" - 当变量是nil
                --"number" - 当变量是数字
                --"string" - 当变量是字符串
                --"boolean" - 当变量是布尔值
                --"table" - 当变量是表
                --"function" - 当变量是函数
                --"thread" - 当变量是线程
                --"userdata" - 当变量是用户数据
                if(type(value)==typ)then
                    isValid = true
                end
            end
        end
        
        if(type(typ)=="table")then
            for _,v in pairs(typ)do
                if(v==value)then
                    isValid = true
                end
            end
        end
        if(typ=="color")then
            if(type(value)=="string")then
                if(colors[value]~=nil)then
                    isValid = true
                    value = colors[value]
                end
            else
                for _,v in pairs(colors)do
                    if(v==value)then
                        isValid = true
                    end
                end
            end
        end
        if(typ=="char")then
            if(type(value)=="string")then
                if(#value==1)then
                    isValid = true
                end
            end
        end
        if(typ=="any")or(value==nil)or(type(value)=="function")then
            isValid = true
        end
        if(typ=="string")and(type(value)~="function")then
            value = tostring(value)
            isValid = true
        end

        if(not isValid)then
            local t = type(value)
            if(type(typ)=="table")then
                typ = table.concat(typ, ", ")
                t = value
            end
            error(self:getType()..": Invalid type for property ".."! Expected "..typ..", got "..t)
        end
        return value
    end
end
local createInfo = function (name,typ, defaultValue ,getter,metadata)

    if type(name) ~= "string" then
        error("name must be a string, got "..type(name))
    end

    local info = {
        name = name,
        type = typ,
        value = defaultValue,
        getter = getter,
        listeners = {},
        listenings = {},--存储自身监听着谁,为了方便移除监听
        metadata = metadata or {}
    }
    info.getType = function (self)
        return self.type
    end
    info.addListener = function (listener,key)
        if key then
            info.listeners[key] = listener
            return
        end
        info.listeners[listener] = listener -- 如果没有key,则用listener作为key
        
    end
    info.removeListener = function (key)
        local other = info.listeners[key]
        if other then
            info.listeners[key] = nil
            
        end

    end
    info.callChangeListeners = function (value)
        for i,v in pairs(info.listeners) do
            v(info,value)
        end
    end
    info.setValue = function (value,checkRule) -- 注意如果 value 是一个table则引用后修改不会触发事件
        if checkRule~=nil then
            value = checkRule(info,value)
        else
            value = defaultRule(info.type)(info,value)
        end
        local oldValue = info.value
        info.value = value -- 事件触发前先修改值
        for i,v in pairs(info.listeners) do
            v(info,value,oldValue)
        end
    end
    info.getValue = function (self)
        if info.getter then
            local temp = info.getter(self)
            if temp~=self.value then
                self.setValue(temp) -- 如果getter返回的值和当前值不同,则触发事件
                return temp
            end
            return info.value
        else
            return info.value
        end
    end
    info.__tostring = function ()
        return info.name..": "..tostring(info.value)
    end
    info.__index = info

    return info
    
end

--单个IPAS对象有本地的上下文
IPAS.Infos = {}
IPAS.CreateInfo = function (name,typ, defaultValue ,getter,metadata)
    if IPAS.Infos[name] then
        error("Info "..name.." already exists!")
    end
    local info = createInfo(name,typ, defaultValue ,getter,metadata)
    IPAS.Infos[name] = info
    return info
    
end
-------------------------------------
-- 2.信息处理
--信息处理本质是一个自定义getter和setter的过程:监听源信息对象变更事件,然后Set自身的值,如果自身又有监听者,则形成一个信息处理链
--处理功能器:快捷通过输入信息生成一个输出信息的处理功能器,必须拥有类型判断
-- 即通过处理功能器能够生成一个新的信息对象(一次生成只会运行一次)
IPAS.processors = {}
IPAS.processorInfos = {} -- 存储可以使得processor生成的信息
--  创建一个信息处理器
-- processorName:处理器名称
-- requireTypes:处理器需要的信息类型:可以是一个字符串,也可以是一个字符串table,默认要求符合规则
-- processFunc:处理函数,输入是一个信息对象table,和meta,输出是新的值
-- 要求processFunc 生成对应衍生信息,并订阅源信息的变更事件
-- 并且要求处理器将处理器meta参数写在衍生信息的metadata中
local createProcessor = function (processorName,requireInfoNames,requireTypes,outputInfoType,processFunc,requireMetaNames)
    
    local processor = {
        name = processorName,
        requireInfoNames = requireInfoNames,
        requireTypes = requireTypes,--key要求与requireInfoNames对应
        outputInfoType = outputInfoType,
        processFunc = processFunc,
        requireMetaNames = requireMetaNames -- 要求的meta数据的名称
    }


    processor.process = function (self,infos,newInfoName,meta) -- 注意这里infos的key一定要与requireInfoNames对应 ; 注意:infos如果有不同输入为相同info时,一旦某个相同输入变更,则会去掉所有相同输入的监听
        if type(infos)~="table" then
            error("Processor "..self.name.." requires a table of infos, got "..type(infos))
        end

        if type(meta)~="table" then
            error("Processor "..self.name.." requires a table of meta, got "..type(meta))
        end

        for i,v in pairs(self.requireInfoNames) do
            if infos[v] == nil then
                error("Processor "..self.name.." requires info "..v)
            end
        end

        if self.requireMetaNames then
            for i,v in pairs(self.requireMetaNames) do
                if meta[v] == nil then
                    error("Processor "..self.name.." requires meta "..v)
                end
            end
        end
        


        for i,v in pairs(self.requireTypes) do
            local infoTypeTester = defaultRule(v)

            if pcall(infoTypeTester,infos[i]) ==false then
                error("Processor "..self.name.." requires type "..v.." for info "..i..", got "..type(infos[i]))
            end
        end
        

        --测试通过
        meta.inputInfos = infos -- 传递给processFunc的meta参数
        local setInputInfo = function (s,name,newInfo)
            local oldInfo = s.metadata.inputInfos[name]
            s.metadata.inputInfos[name]=newInfo
            oldInfo.removeListener(s.name) -- 移除旧的监听
            newInfo.addListener(function() s:getValue() end,s.name)
            s.listenings[oldInfo.name] = nil
            s.listenings[newInfo.name] = newInfo
        end
        meta.inputInfos=setmetatable(meta.inputInfos,{__index={setInputInfo=setInputInfo}})
       
        local newInfoDefaultValue = self.processFunc(infos,meta) -- 生成新的info的默认值
        local getter = function (s) -- 生成新的info的getter
            return self.processFunc(s.metadata.inputInfos,s.metadata,s) or s.value-- 如果processFunc返回nil,则返回原值
        end
        meta.processorName = self.name --为了保存-读取时能够知道是哪个processor生成的

        local newInfo = createInfo(newInfoName,self.outputInfoType, newInfoDefaultValue,getter,meta)

        for i,v in pairs(infos) do
            v.addListener(function() newInfo:getValue() end,newInfoName) -- 订阅源信息的变更事件
            newInfo.listenings[v.name] = v
        end
        

        return newInfo
    end

    return processor
end
IPAS.CreateProcessor = function (processorName,requireInfoNames,requireTypes,outputInfoType,processFunc,requireMetaNames)
    if IPAS.processors[processorName] then
        error("Processor "..processorName.." already exists!")
    end
    local processor = createProcessor(processorName,requireInfoNames,requireTypes,outputInfoType,processFunc,requireMetaNames)
    IPAS.processors[processorName] = processor
    IPAS.processorInfos[processorName] = {requireInfoNames = requireInfoNames,requireTypes = requireTypes,outputInfoType = outputInfoType,requireMetaNames = requireMetaNames}
    return processor
end
IPAS.ProcessInfos = function (processorName,infos,newInfoName,meta)
    local processor = IPAS.processors[processorName]
    if processor == nil then
        error("Processor "..processorName.." not found!")
    end
    local newInfo= processor:process(infos,newInfoName,meta)
    IPAS.Infos[newInfoName] = newInfo
    return newInfo
end

local ENVBuilder = function (ENV)
    -- 这里添加默认的函数
    ENV["table"] = table
    ENV["string"] = string
    ENV["math"] = math
    ENV["setmetatable"] = setmetatable
    ENV["getmetatable"] = getmetatable
    return ENV
end

-- 利用load()再封装一层
IPAS.LoadProcessor = function (processorName,requireInfoNames,requireTypes,outputInfoType,requireMetaNames,code)
    
    local processorFunc = function (infos,meta,s)
        local processorENV = {IPAS = IPAS,self = s,inputInfos = infos}
        processorENV = ENVBuilder(processorENV)
        for k,v in pairs(requireInfoNames) do
            if infos[v] == nil then
                return s:getValue() -- 如果有一个info没有值,则返回原值
            end
        end
        for i,v in pairs(infos) do
            if not v.value then
                return s:getValue() -- 如果有一个info没有值,则返回原值
                --error("Info "..i.." has no value!")
            end
            processorENV[i] = v.value -- 将infos的*值*传入processorENV,以便在code中使用,而非直接使用info对象,使得code更加简洁(绕过getter,避免循环引用)
        end
        --处理meta
        for i,v in pairs(meta) do
            processorENV[i] = v
        end

        local func,err = load(code, "Processor "..processorName, "t", processorENV)
        if func == nil then
            error("Processor "..processorName.." code error!# "..err)
        end
        return func()
    end


    local generateProcessor= IPAS.CreateProcessor(processorName,requireInfoNames,requireTypes,outputInfoType,processorFunc,requireMetaNames)
    IPAS.processorInfos[processorName].code = code
    return generateProcessor



    end
-------------------------------------
-- 3.updater 信息更新器:用于定时(自动)跟新信息的值:如从外部perhipheral获取信息,然后更新信息的值
IPAS.updaters = require("/lib/mineIPAS/IPASupdater")
IPAS.updateBindings = {}-- 存储所有的"更新-信息"绑定
IPAS.CreateUpdateBinding = function (infoName,updaterGroupName,updaterName,...)
    local updaterCreate = IPAS.updaters[updaterGroupName][updaterName]
    if updaterCreate == nil then
        error("Updater "..updaterName.." not found!")
    end
    local updater = updaterCreate(IPAS,IPAS.updaters,...)
    local info = IPAS.Infos[infoName]
    if info == nil then
        error("Info "..infoName.." not found!")
    end
    local updateBinding = {
        updaterGroupName = updaterGroupName,
        updaterName = updaterName,
        params = {...}, -- 保存参数,要求参数是简单的数据类型
        infoName = infoName,
        updater = updater,
        info = info,
    }
    IPAS.updateBindings[updaterName.."-"..infoName] = updateBinding
    return updateBinding
end

--IPAS 更新所有的绑定

IPAS.UpdateAll = function ()
    for i,v in pairs(IPAS.updateBindings) do
        if v.updater and v.info then
            v.info.setValue(v.updater())
        end
    end
end
IPAS.updateTime = 0.1
IPAS.UpdateAllLoop = function ()
    while true do
        IPAS.UpdateAll()
        os.sleep(IPAS.updateTime)
    end
end


-------------------------------------
--TODO:save-load
--保存:processor;info;updateBinding
--有信息是由processor生成的load时要按照依赖链生成

--加载顺序:加载processor->加载根信息->加载中间信息(由processor生成)->加载updateBinding
--保存顺序:保存updateBinding->保存中间信息->保存根信息->保存processor
---------save----------------
-- 序列化processor
local function serializeProcessors(processors)
    local processorsData = {}
    for name, processor in pairs(processors) do
        table.insert(processorsData, {
            name = name,
            requireInfoNames = processor.requireInfoNames,
            requireTypes = processor.requireTypes,
            outputInfoType = processor.outputInfoType,
            requireMetaNames = processor.requireMetaNames,
            code = processor.code  -- 假设processor对象里有code属性保存着实际的代码字符串
        })
    end
    return processorsData
end

-- 序列化info
local function serializeInfos(infos)
    local infosData = {}
    for name, info in pairs(infos) do
        local iData={
            name = info.name,
            type = info.type,
            value = info.value,
        }
        --更具是否直接创建还是由processor
        if not (info.getter or info.metadata.inputInfos or info.metadata.processorName ) then-- 直接创建
            
            iData.metadata = info.metadata
        else-- 由processor生成
            iData.metadata = {
                processorName = info.metadata.processorName,
                inputInfos = {}
            }
            for inputName, inputInfo in pairs(info.metadata.inputInfos) do
                iData.metadata.inputInfos[inputName] = inputInfo.name
            end
            --其他的metadata
            for k,v in pairs(info.metadata) do
                if k~="processorName" and k~="inputInfos" then
                    iData.metadata[k] = v
                end
            end
        end

        table.insert(infosData, iData)
    end
    return infosData
end

-- 序列化updateBinding
local function serializeUpdateBindings(updateBindings)
    local updateBindingsData = {}
    for name, binding in pairs(updateBindings) do
        table.insert(updateBindingsData, {
            updaterGroupName = binding.updaterGroupName,
            updaterName = binding.updaterName,
            infoName = binding.infoName,
            params = binding.params
        })
    end
    return updateBindingsData
end

-- 保存到文件
local function saveToFile(filename, data)
    local file = io.open(filename, "w")
    if file then
        file:write(textutils.serialiseJSON(data))
        file:close()
    else
        error("Unable to open file for writing: " .. filename)
    end
end

-- 添加前台配置相关的数据结构
IPAS.frontendConfig = {
    displayItems = {}, -- {id = "唯一ID", infoName = "信息名称", displayName = "显示名称", x = 1, y = 1, width = 10, format = "%s"}
    monitors = {}, -- {name = "监视器名称", items = {"显示项ID1", "显示项ID2"}}
    settings = {
        refreshRate = 0.5, -- 前台刷新率（秒）
        textScale = 0.5,   -- 监视器文本缩放
        defaultColors = {
            background = colors.black,
            text = colors.white,
            header = colors.yellow,
            error = colors.red
        }
    }
}

-- 保存前台配置
local function serializeFrontendConfig()
    return {
        displayItems = IPAS.frontendConfig.displayItems,
        monitors = IPAS.frontendConfig.monitors,
        settings = IPAS.frontendConfig.settings
    }
end

-- 修改保存系统函数，添加前台配置
local function saveSystem(filename)
    local data = {
        processors = serializeProcessors(IPAS.processorInfos),
        infos = serializeInfos(IPAS.Infos),
        updateBindings = serializeUpdateBindings(IPAS.updateBindings),
        frontendConfig = serializeFrontendConfig() -- 添加前台配置
    }
    saveToFile(filename, data)
end

---------load----------------
-- 从文件中读取数据
local function loadFromFile(filename)
    local file = io.open(filename, "r")
    if not file then
        error("Unable to open file for reading: " .. filename)
    end
    local content = file:read("*a")
    file:close()
    return textutils.unserialiseJSON(content)
end

-- 重建Processor
local function rebuildProcessors(processorsData)
    for _, pData in ipairs(processorsData) do
        IPAS.LoadProcessor(
            pData.name,
            pData.requireInfoNames,
            pData.requireTypes,
            pData.outputInfoType,
            pData.requireMetaNames,
            pData.code
        )
    end
end

-- 重建Infos，考虑依赖
local function rebuildInfos(infosData)
    local pendingInfos = {}
    
    -- 先尝试重建不需要等待依赖的Infos
    for _, iData in ipairs(infosData) do
        if (not iData.metadata.inputInfos) then
            IPAS.CreateInfo(iData.name, iData.type, iData.value, nil, iData.metadata)
        else
            table.insert(pendingInfos, iData)  -- 需要处理依赖的Info延迟处理
        end
    end

    -- 处理需要依赖的Infos
    while #pendingInfos > 0 do
        local isRemainAlone = true
        for i=#pendingInfos, 1, -1 do
            local iData = pendingInfos[i]
            local canBuild = true
            for _, inputName in ipairs(iData.metadata.inputInfos) do
                if not IPAS.Infos[inputName] then
                    canBuild = false
                    break
                end
            end
            if canBuild then
                -- 重建Info，并从待处理列表中移除
                isRemainAlone = false -- 有Info被处理
                local inputs = {}
                for key, inputName in pairs(iData.metadata.inputInfos) do
                    inputs[key] = IPAS.Infos[inputName] -- 重建Info时，传入依赖的Info对象
                end
                -- 重建Info
                iData.metadata.inputInfos =nil
                IPAS.ProcessInfos(iData.metadata.processorName, inputs, iData.name, iData.metadata)
                table.remove(pendingInfos, i)
            end
        end
        if isRemainAlone then
            break -- 如果没有Info被处理，说明有循环依赖，跳出循环
        end
    end
end

-- 重建UpdateBindings
local function rebuildUpdateBindings(updateBindingsData)
    for _, ubData in ipairs(updateBindingsData) do
        IPAS.CreateUpdateBinding(ubData.infoName, ubData.updaterGroupName, ubData.updaterName, table.unpack(ubData.params or {}))
    end
end

-- 加载前台配置
local function rebuildFrontendConfig(frontendData)
    if not frontendData then return end
    
    IPAS.frontendConfig.displayItems = frontendData.displayItems or {}
    IPAS.frontendConfig.monitors = frontendData.monitors or {}
    IPAS.frontendConfig.settings = frontendData.settings or IPAS.frontendConfig.settings
end

-- 修改加载系统函数，添加前台配置
local function loadSystem(filename)
    local data = loadFromFile(filename)

    -- 按顺序重建系统组件
    rebuildProcessors(data.processors)
    rebuildInfos(data.infos)
    rebuildUpdateBindings(data.updateBindings)
    rebuildFrontendConfig(data.frontendConfig) -- 加载前台配置
end

IPAS.saveSystem = saveSystem
IPAS.loadSystem = loadSystem

IPAS.savePath = "IPAS_save.json"
IPAS.basePath = "/lib/mineIPAS"
function IPAS.Save()
    local files = fs.combine(IPAS.basePath, IPAS.savePath)
    IPAS.saveSystem(files)
end
function IPAS.Load()
    local files = fs.combine(IPAS.basePath, IPAS.savePath)
    IPAS.loadSystem(files)
    
end

-- 前台显示相关API

-- 添加显示项
IPAS.AddDisplayItem = function(infoName, displayName, x, y, width, format)
    if not IPAS.Infos[infoName] then
        error("Info "..infoName.." not found!")
    end
    
    local id = "display_"..os.epoch("utc")
    local item = {
        id = id,
        infoName = infoName,
        displayName = displayName or infoName,
        x = x or 1,
        y = y or 1,
        width = width or 20,
        format = format or "%s"
    }
    
    table.insert(IPAS.frontendConfig.displayItems, item)
    return id
end

-- 移除显示项
IPAS.RemoveDisplayItem = function(id)
    for i, item in ipairs(IPAS.frontendConfig.displayItems) do
        if item.id == id then
            table.remove(IPAS.frontendConfig.displayItems, i)
            
            -- 同时从所有监视器配置中移除
            for _, monitor in ipairs(IPAS.frontendConfig.monitors) do
                for j, itemId in ipairs(monitor.items) do
                    if itemId == id then
                        table.remove(monitor.items, j)
                        break
                    end
                end
            end
            
            return true
        end
    end
    return false
end

-- 配置监视器
IPAS.ConfigureMonitor = function(monitorName, itemIds)
    -- 查找现有配置
    local existingConfig
    for i, monitor in ipairs(IPAS.frontendConfig.monitors) do
        if monitor.name == monitorName then
            existingConfig = monitor
            break
        end
    end
    
    if existingConfig then
        existingConfig.items = itemIds
    else
        table.insert(IPAS.frontendConfig.monitors, {
            name = monitorName,
            items = itemIds
        })
    end
end

-- 更新前台设置
IPAS.UpdateFrontendSettings = function(settings)
    for k, v in pairs(settings) do
        IPAS.frontendConfig.settings[k] = v
    end
end

IPAS.__index = IPAS

-- 加载前台模块
local IPASFrontend = require("/lib/mineIPAS/IPASFrontend")

-- 初始化前台模块
IPAS.initFrontend = function(basalt)
    if not basalt then
        error("Basalt is required to initialize frontend")
    end
    
    -- 向前台模块传递IPAS引用和Basalt
    IPASFrontend.IPAS = IPAS
    IPASFrontend.basalt = basalt
end

-- 启动前台显示
IPAS.startFrontend = function()
    IPASFrontend:start()
end

-- 停止前台显示
IPAS.stopFrontend = function()
    IPASFrontend:stop()
end

return IPAS