local filePath = "/lib/BasaltMaster/init.lua"
local basalt = require(filePath:gsub(".lua", ""))
local utils = require("utils")
local w, h = term.getSize()
local print_r = function (table,filter)
    BPrintTable(basalt,table,filter)
end
local debug = basalt.debug
local IPAS = require("/lib/mineIPAS/IPAS")
local toolkit = require("/lib/mineIPAS/UItoolkit")



local mainFrame = basalt.createFrame()
 :show()
 mainFrame:addLabel():setFontSize(3):setText("IPAS"):setPosition("{parent.w/2-19}", "{parent.h/2-3}")
local topBar = mainFrame:addMenubar()
                    :setPosition(1,1)
                    :setSize("{parent.w}",1)
local onTopBarSelect = function (self)
    local cont = self:getItemCount()
    for i=1,cont do
        local item = self:getItem(i)
        if item.text == self:getValue().text then
            item.args[1]:show()
        else
            item.args[1]:hide()
        end
    end
end
local addPage = function (name,BackgroundColor)
    BackgroundColor = BackgroundColor or colors.white
    local page = mainFrame:addFrame()
                    :setPosition(1,2)
                    :setSize("{parent.w}","{parent.h-1}")
                    :setBackground(BackgroundColor)
                    :hide()
    topBar:addItem(name,colors.gray,colors.white,page)
    :onSelect(onTopBarSelect)
    return page
end

local IPAS_UI = require("/lib/mineIPAS/IPAS_UI")
local pageContainer = addPage("IPAS",colors.lightGray)
IPAS_UI(basalt,pageContainer,IPAS,toolkit)

-- 加载IPAS保存的数据
pcall(IPAS.Load)

-- 启动IPAS更新循环
pageContainer:addThread():start(IPAS.UpdateAllLoop)

-- 选择IPAS选项卡（默认显示）
topBar:selectItem(1)

mainFrame:addLabel()
 :setText("basalt v"..basalt.getVersion())
    :setPosition("{parent.w-15}", "{parent.h-1}")
    :setForeground(colours.red)
    :setZ(100)
    :onClick(function(self)
        basalt.stopUpdate()
    end)

-- 启动Basalt自动更新
basalt.autoUpdate()
