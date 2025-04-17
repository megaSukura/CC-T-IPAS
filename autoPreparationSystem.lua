--# AutoCraftSystem #--
--库/设置--------------------------------------------

-- 加载CPUs配置文件
local function loadCPUsConfig(path)
    local cpus = {}
    local file = fs.open(path, "r")
    if file then
        for line in file.readLine do
            local key = line:match("(.*)=.*true")
            if key then
                cpus[key] = true
            end
        end
        file.close()
    else
        print("Failed to open CPUs config file")
        return nil
    end
    return cpus
end
local cpusConfigPath = "cpus_config.txt"

--初始化设备------------------------------------
local reader, AEbridge, targetInventory, targetInventoryName, monitor, redstone
local function initPeripheral()
    ----方块阅读器
     reader = peripheral.find("blockReader")
    ----ME桥
     AEbridge = peripheral.find("meBridge")
    ----目标箱子
     targetInventory = peripheral.find("inventory")

    if targetInventory then
        targetInventoryName = peripheral.getName(targetInventory)
    end
    ----显示器
     monitor = peripheral.find("monitor")
    if monitor ~= nil then
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.setTextScale(0.5)
        term.redirect(monitor)
    end
    ----红石信号
    redstone = peripheral.find("redstoneIntegrator")
end

--函数/对象--------------------------------------------

----初始化

local function initPeripherals()
    initPeripheral()
    --检查设备
    if reader == nil then
        print("blockReader not found")
        return false
    end
    --print("blockReader connected\n")
    if AEbridge == nil then
        print("meBridge not found")
        return false
    end
    --print("meBridge connected\n")
    if targetInventory == nil then
        print("inventory not found")
        return false
    end
    --print("inventory connected\n")
    if redstone == nil then
        print("redstoneIntegrator not found")
        return false
    end
    --print("redstoneIntegrator connected\n")
    return true
end

----读取相关
local function deepPrint(tbl, indent, maxDepth)
    indent = indent or 0
    maxDepth = maxDepth or math.huge
    local indentStr = string.rep("  ", indent)

    for k, v in pairs(tbl) do
        if type(v) == "table" and indent < maxDepth then
            print(indentStr .. tostring(k) .. ":")
            deepPrint(v, indent + 1, maxDepth)
        else
            print(indentStr .. tostring(k) .. ": " .. tostring(v))
        end
    end
end
local function findTableWithKey(tbl, key)
    for k, v in pairs(tbl) do
        if k == key then
            return v
        elseif type(v) == "table" then
            local result = findTableWithKey(v, key)
            if result then
                return result
            end
        end
    end
    return nil
end
local function extractItemsInClipboard(data)
    local items = {}
    local Items = findTableWithKey(data, "Items") or findTableWithKey(data, "Item") or { print("Can't find Items") }

    for _, item in pairs(Items) do
        if not item.tag then
            print("Can't find \"tag\" in " .. item.id)
            goto continue
        end
        if not item.tag.Pages then
            print("Can't find \"Pages\" in " .. item.id)
            goto continue
        end
        local pages = item.tag.Pages
        for page_index, page in pairs(pages) do
            for entry_index, entry in pairs(page.Entries) do
                local id = entry.Icon.id
                local quantity = 1
                local match = string.match(entry.Text, "n x(%d+)")
                if match then
                    quantity = tonumber(match) or 1
                end
                table.insert(items, { id = id, quantity = quantity })
            end
        end
        ::continue::
    end
    return items
end
local function readData()
    local data = reader.getBlockData()
    local items = extractItemsInClipboard(data)
    return items
end

----AE相关
local function exportItemToPeripheral(itemID, count)
    local item = {
        name = itemID,
        count = count,
    }
    local result = AEbridge.exportItemToPeripheral(item, targetInventoryName)
    --print("try export " .. itemID .. " x " .. count .. " to " .. targetInventoryName)
    --print("export success num: " .. result)
    return result
end


----AutoCraftSystem相关

local busyCPUs = {} --繁忙CPU:记录当前正在合成的CPU:{cpuName->string}
local freeCPU = {} --空闲CPU:记录当前空闲的CPU:{cpuName->string}
--初始化空闲CPU
local function initFreeCPU()
    local _cpus = AEbridge.getCraftingCPUs()
    for index, value in ipairs(_cpus) do
        --如果是craftingCPUs中的CPU
        if craftingCPUs[value.name] then
            if value.isBusy == false then
                freeCPU[value.name] = true
                print("freeCPU: " .. value.name)
            end
        end
    end
end

--=================主程序相关函数=================--
--将inventory的所有东西导出到meBridge
local function exportAllItemsToAEbridge()
    local invItems = targetInventory.list() or {}
    for _,itemInfo in pairs(invItems) do
        AEbridge.importItemFromPeripheral({ name = itemInfo.name, count = itemInfo.count }, targetInventoryName)
    end
end
--读取数据
local itemsList
local function getData()
    itemsList = readData()
end
--任务
local task={}
local failedTask={}
local function tasking(onAddTask,onStartTask,onSuccessTask,onFailedTask)
    --尝试导出物品,并记录导出失败的物品作为任务
    for i, item in pairs(itemsList) do
        local result = exportItemToPeripheral(item.id, item.quantity)
        if result ~= item.quantity then
            table.insert(task, { id = item.id, quantity = item.quantity - result })
            onAddTask(item.id, item.quantity - result)
        end
    end
    --尝试合成任务
    while true do
        --维护busyCPUs
        os.sleep(0.2)
        for cpuName, cpu in pairs(busyCPUs) do
            if not AEbridge.isItemCrafting({ name = cpu.itemID }, cpuName) then --合成的CPU空闲
                --os.sleep(1)
                freeCPU[cpuName] = true
                --检查合成结果
                local sysItem = AEbridge.getItem({ name = cpu.itemID })
                if not sysItem or sysItem.amount < cpu.count then
                    table.insert(failedTask, { id = cpu.itemID, quantity = cpu.count })
                    onFailedTask(cpu.itemID, cpu.count, cpuName)
                else -- 合成成功
                    onSuccessTask(cpu.itemID, cpu.count, cpuName)
                    --导出
                    local result = exportItemToPeripheral(cpu.itemID, cpu.count)
                    if result ~= cpu.count then -- 导出失败
                        table.insert(task, { id = cpu.itemID, quantity = cpu.count - result })
                        onAddTask(cpu.itemID, cpu.count - result)
                    end
                end
                busyCPUs[cpuName] = nil
            end
        end
        os.sleep(0.2)
        --分配任务
        for cpu, _ in pairs(freeCPU) do
            if #task == 0 then
                break
            end
            --os.sleep(1)
            local t = table.remove(task, 1)
            freeCPU[cpu] = nil
            AEbridge.craftItem({ name = t.id, count = t.quantity }, cpu)
            busyCPUs[cpu] = { itemID = t.id, count = t.quantity }
            onStartTask(t.id, t.quantity, cpu)
        end
        -- 如果任务池为空,且所有CPU空闲,则退出
        if #task == 0 and next(busyCPUs) == nil then
            break
        end
    end
end


--=================主程序=================--

local function main()
    if not initPeripherals() then
        print("Initialization failed")
        return
    end
    exportAllItemsToAEbridge()

    getData()
    tasking(function (id, quantity)
        print("Add task: " .. id .. " x " .. quantity)
    end, function (id, quantity, cpu)
        print("Start task: " .. id .. " x " .. quantity .. " on " .. cpu)
    end, function (id, quantity, cpu)
        print("Success task: " .. id .. " x " .. quantity .. " on " .. cpu)
    end, function (id, quantity, cpu)
        print("Failed task: " .. id .. " x " .. quantity .. " on " .. cpu)
    end)
        
    for i, item in pairs(failedTask) do
        print(": " .. item.id .. " x " .. item.quantity)
    end

    return failedTask
end

--$ AutoCraftSystem $--
return{
    cpusConfigPath = cpusConfigPath,
    reader = reader,
    AEbridge = AEbridge,
    targetInventory = targetInventory,
    targetInventoryName = targetInventoryName,
    monitor = monitor,
    redstone = redstone,

    busyCPUs = busyCPUs,
    freeCPU = freeCPU,
    itemsList = itemsList,
    task = task,
    failedTask = failedTask,

    -- functions
    loadCPUsConfig = loadCPUsConfig,
    initPeripherals = initPeripherals,
    findTableWithKey = findTableWithKey,
    extractItemsInClipboard = extractItemsInClipboard,
    readData = readData,
    exportItemToPeripheral = exportItemToPeripheral,
    initFreeCPU = initFreeCPU,
    exportAllItemsToAEbridge = exportAllItemsToAEbridge,
    getData = getData,
    tasking = tasking,
    
    main = main
}

