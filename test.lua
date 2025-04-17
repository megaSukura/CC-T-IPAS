local basalt = require("/lib/BasaltMaster/init")
local toolkit = require("/lib/mineIPAS/UItoolkit")

local mainFrame = toolkit.makeTaggedFrame(basalt.createFrame())

local settingPage = mainFrame.addPage("Setting", colors.lightGray)
local initPage = mainFrame.addPage("Init", colors.lightGray)
local itemListReadPage = mainFrame.addPage(" Read Item List", colors.lightGray)
local craftTaskPage = mainFrame.addPage("Task", colors.lightGray)

-- #region 设置页面
settingPage:setLayoutDirection("column"):setLayoutAlignItems("stretch")
    :setLayoutPadding({5,4})
    :setLayoutGap(2)
local CPUList = {"CPU1", "CPU2", "CPU3", "CPU4", "CPU5", "CPU6", "CPU7", "CPU8", "CPU9", "CPU10"}
settingPage:addButton("CPUsettingButton"):onClick(function(self)
    --弹出CPU设置界面
    local popup,content,confirm,cancel = toolkit.createSimpleDialog(mainFrame, "{parent.w/2-10}", "{parent.h/2-5}", 41, 24, "cpu setting",true,true)
    local textFild= content:addTextfield()
    for i,cpu in ipairs(CPUList) do
        textFild:addLine(cpu)
    end
    confirm:onClick(function(self)
        --保存设置
        CPUList = {} -- 清空
        for i,cpu in ipairs(textFild:getLines()) do
            CPUList[i] = cpu
        end
        BPrintTable(basalt,CPUList)
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
    --检查peripheral,初始化,初始化失败则弹出提示,初始化成功则跳转到下一页
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
                    name = "deleteButton",
                    text = "Delete selected Task",
                    border = colors.white,
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
-- 按下删除按钮,删除选中的任务

--#endregion

--#region 任务页面
craftTaskPage:setLayoutDirection("column"):setLayoutPadding({2,3})
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
        flexGrow = 1,
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
        layoutAlignItems = "stretch",
        layoutPadding = 0,
        baseDraw = false,
        height = 3,
        children = {
            {
                type = "Label",
                text = "failed task: ",
                fontSize = 2
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
--#endregion





mainFrame.topBar:selectItem(2)
basalt.autoUpdate() -- Starts the auto update loop
