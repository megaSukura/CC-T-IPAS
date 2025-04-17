local basalt = require("/lib/BasaltMaster/init")
local toolkit = require("/lib/mineIPAS/UItoolkit")
local APS = require("autoPreparationSystem")

if basalt then
APS.setPrintFunction(function(text)
    basalt:debug(text)
end)
end
local monitor = peripheral.find("monitor")
local monitorFrame = basalt.addMonitor()
monitorFrame:setMonitor(monitor)
local mainFrame = toolkit.makeTaggedFrame(monitorFrame)
local craftThread = mainFrame:addThread("craftThread")

local settingPage = mainFrame.addPage("Setting", colors.lightGray)
local initPage = mainFrame.addPage("Init", colors.lightGray)
local itemListReadPage = mainFrame.addPage(" Read Item List", colors.lightGray)
local craftTaskPage = mainFrame.addPage("Task", colors.lightGray)

-- #region 设置页面
settingPage:setLayoutDirection("column"):setLayoutAlignItems("stretch")
    :setLayoutPadding({5,4})
    :setLayoutGap(2)

settingPage:addButton("CPUsettingButton"):onClick(function(self)
    APS.loadCPUsConfig()
    --弹出CPU设置界面
    local popup,content,confirm,cancel = toolkit.createSimpleDialog(mainFrame, "{parent.w/2-13}", "{parent.h/2-7}", 25, 14, "cpu setting",true,true)
    local textFild= content:addTextfield():setHeight(5)
    for cpu,_ in pairs(APS.craftingCPUs) do
        BPrintTable(basalt,cpu)
        textFild:addLine(cpu)
    end
    confirm:onClick(function(self)
        --保存设置
        -- 清空:注意,这里不能直接={}来清空,因为这样会导致原表的引用丢失,无法保存
        for key,_ in pairs(APS.craftingCPUs) do
            APS.craftingCPUs[key] = nil
        end
        for i,cpu in pairs(textFild:getLines()) do
            APS.craftingCPUs[cpu] = true
        end
        APS.saveCPUsConfig()
        if APS.isInit() then
            APS.loadCPUsConfig()
            APS.initFreeCPU()
        end
        popup:close()
    end)
end):setText("CPU setting")
--#endregion

--#region 初始化页面
initPage:setLayoutDirection("column")
    :setLayoutJustifyContent("center"):setLayoutAlignItems("center")
    :setLayoutGap(2)
local initPageTable = {
    {
        type = "Label",
        text = "Auto Preparation",
        fontSize = 2
    },
    {
        name = "startLabel",
        type = "Label",
        text = "-System-",
        fontSize = 2,
        background = colors.gray
    },
    {
        type = "Button",
        name = "startButton",
        text = "Start",
        background = colors.green,
        border = colors.gray,
    },
    {
        type = "Button",
        name = "settingButton",
        text = "Setting",
        background = colors.lightBlue,
        border = colors.gray,
    }
}
local initPageObj = toolkit.createUIFromTable(initPage, initPageTable)
-- toolkit.createAlert(mainFrame,"{parent.w/2-20}","{parent.h/2-6}",40,20,"")
initPageObj.startButton:onClick(function(self)
    --初始化,初始化失败则弹出提示,初始化成功则跳转到下一页
    if APS.init() then
        mainFrame.topBar:selectItem(3)
    else
        toolkit.createAlert(mainFrame,"{parent.w/2-20}","{parent.h/2-6}",40,20,"Initialization failed!")
    end
end)
initPageObj.settingButton:onClick(function(self)
    mainFrame.topBar:selectItem(1)
end)
-- #endregion

-- #region 读取物品列表页面
itemListReadPage:setLayoutAlignItems("stretch")
local itemListReadTable = {
    type = "split",
    splitDirection = "row",
    splitNum = 2,
    childGrow = { 1.5, 1 },
    childShrink = { 1.5, 1 },
    childrenNames = { "itemListRight", "itemOperationLeft" },
    splitChildren = {
        {
            layoutDirection = "column",
            layoutJustifyContent = "center",
            layoutAlignItems = "stretch",
            children = {
                {
                    type = "Label",
                    text = "Task list summary",
                    background = colors.lightBlue,
                    textAlign = "center",
                },
                {
                    type = "List",
                    name = "taskList",
                    flexGrow = 1,
                }
            }
        },
        {
            layoutDirection = "column",
            layoutJustifyContent = "flex-end",
            layoutAlignItems = "stretch",
            layoutPadding = {5,1},
            layoutGap = 1,
            children = {
                {
                    type = "Button",
                    name = "readButton",
                    text = "read ltem list",
                    border = colors.white,
                    background = colors.lightBlue,
                },
                {
                    type = "Button",
                    name = "StartButton",
                    text = "Start->",
                    border = colors.white,
                    background = colors.green,
                }
            }
        }
    }
}
local itemListReadObj = toolkit.createUIFromTable(itemListReadPage, itemListReadTable)
-- 按下刷新按钮,尝试导出物品列表中的物品,并获得需要制作的任务列表
itemListReadObj.readButton:onClick(function(self)
    APS.getData()
    itemListReadObj.taskList:clear()
    
    for i,task in ipairs(APS.itemsList) do
        local taskStr = task.id.." x"..task.quantity
        itemListReadObj.taskList:addItem(taskStr)
    end
end)
-- 按下开始按钮,并跳转到下一页
itemListReadObj.StartButton:onClick(function(self)
    mainFrame.topBar:selectItem(4)
end)

--#endregion

--#region 任务页面
craftTaskPage:setLayoutDirection("column"):setLayoutPadding({1,1})
    :setLayoutJustifyContent("center"):setLayoutAlignItems("stretch")
    :setLayoutGap(1)

local craftTaskTable = {
    {
        type = "Progressbar",
        name = "taskProgress",
        progress = 10,
        height = 2,
    },
    {
        type = "List",
        name = "logList",
        background = colors.lightGray,
        foreground = colors.black,
        flexGrow = 2,
        flexShrink = 5,
        flexBasis = 2,
    },
    {
        type = "Pane",
        name = "dividingLine",
        background = colors.lightGray,
        height = 1,
    },
    {
        type = "Layout",
        layoutDirection = "row",
        layoutJustifyContent = "space-between",
        layoutAlignItems = "center",
        layoutPadding = 0,
        baseDraw = false,
        height = 3,
        children = {
            {
                type = "Label",
                text = "failed task: ",
                fontSize = 1
            },
            {
                type = "Button",
                name = "retryButton",
                text = "Retry",
                background = colors.green,
                border = colors.black,
            }
        }
    },
    {
        type = "List",
        name = "failedTaskList",
        flexGrow = 1,
        flexBasis = 4,
        flexShrink = 1,
    }
}
local craftTaskObj = toolkit.createUIFromTable(craftTaskPage, craftTaskTable)
craftTaskObj.taskProgress:setProgressBar(colors.green, '/',colors.yellow)
craftTaskObj.dividingLine:setBackground(colors.lightGray, "\183", colors.gray)
craftTaskObj.logList:addItem("Log:")
--在读取物品列表页面中,按下开始按钮,开始准备物品
local function startTask()
    APS.tasking(
        --onAddTask
        function(id,quantity)
            craftTaskObj.logList:addItem("Add task: "..id.." x"..quantity)
            craftTaskObj.taskProgress:setProgress(APS.getTaskProgress())
        end,
        --onStartTask
        function(id,quantity,cpu)
            craftTaskObj.logList:addItem("Start task: "..id.." x"..quantity.." on "..cpu)
        end,
        --onTaskSuccess
        function(id,quantity,cpu)
            craftTaskObj.logList:addItem("Task success: "..id.." x"..quantity.." on "..cpu)
            craftTaskObj.taskProgress:setProgress(APS.getTaskProgress())
        end,
        --onTaskFailed
        function(id,quantity,cpu)
            craftTaskObj.logList:addItem("Task failed: "..id.." x"..quantity.." on "..cpu)
            craftTaskObj.taskProgress:setProgress(APS.getTaskProgress())
            craftTaskObj.failedTaskList:addItem(id.." x"..quantity)
        end,
        --onDone
        function()
            craftTaskObj.logList:addItem("All tasks are done!")
            craftTaskObj.taskProgress:setProgress(APS.getTaskProgress())
        end
    )
end
itemListReadObj.StartButton:onClick(function(self)
    craftTaskObj.logList:clear()
    craftTaskObj.failedTaskList:clear()
    craftTaskObj.taskProgress:setProgress(0)
    if (craftThread:getStatus() or "nil") ~= "suspended" then

        craftThread:start(startTask)

    else
        basalt:debug("task is " .. (craftThread:getStatus() or "nil"))
    end
end)
craftTaskObj.retryButton:onClick(function(self)
    if (craftThread:getStatus() or "nil") ~= "suspended" then
    -- 重试失败的任务,不删除log
    craftTaskObj.logList:addItem("Retry:")
    craftTaskObj.failedTaskList:clear()
    craftTaskObj.taskProgress:setProgress(0)

        craftThread:start(startTask)

    else
        basalt:debug("task is " .. (craftThread:getStatus() or "nil"))
    end
end)


--#endregion




mainFrame.topBar:selectItem(2)
basalt.autoUpdate() -- Starts the auto update loop
