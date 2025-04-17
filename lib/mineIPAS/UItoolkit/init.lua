
local clamp = function(value, min, max)
    return math.min(math.max(value, min), max)
end
local isContain = function (table,element)
    for _,v in pairs(table) do
        if v == element then
            return true
        end
    end
    return false
    
end
local function split(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

local function tableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
    
end
local function tableToString(t,filter)
    local str=""
    local writeRow = function(rowStr)
        if str == "" then
            str = rowStr or"\n"
        else
            str = str.."\n"..(rowStr or"\n")
        end
    end
    print_table(t,writeRow,filter)
    return str
end

----
local toolkit = {}
----
local function makeResizeable(frame, minW, minH, maxW, maxH)
    frame:addProperty("Resizeable", "boolean", true)
    minW = minW or 4
    minH = minH or 4
    maxW = maxW or 99
    maxH = maxH or 99
    local btn = frame:addButton()
        :setIgnoreOffset(true)
        :setPosition("{parent.w-1}", "{parent.h-1}")
        :setSize(1, 1)
        :setText("/")
        :setForeground(colors.black)
        :setBackground(colors.black)
        :onDrag(function(self, _, _, xOffset, yOffset)
            if not frame:getResizeable() then
                return
            end
            local w, h = frame:getSize()
            local wOff, hOff = w, h
            if(w+xOffset-1>=minW)and(w+xOffset-1<=maxW)then
                wOff = w+xOffset-1
            end
            if(h+yOffset-1>=minH)and(h+yOffset-1<=maxH)then
                hOff = h+yOffset-1
            end
            frame:setSize(wOff, hOff)
        end)
    return frame
end

--
local function makeTaggedFrame(frame)
    local topBar = frame:addMenubar()
                    :setPosition(1,1)
                    :setSize("{parent.w}",1)
                    :setBackground(colors.lightGray)
                    :setIgnoreOffset(true)
local onTopBarSelect = function (self)
    local cont = self:getItemCount()
    for i=1,cont do
        local item = self:getItem(i)
        if item.text == self:getValue().text then
            --print_r(item.args[1])
            item.args[1]:show()
        else
            item.args[1]:hide()
        end
    end
end

local addPage = function (name,BackgroundColor,tabFrotColor,tabBgColor)
    BackgroundColor = BackgroundColor or colors.white
    tabFrotColor = tabFrotColor or colors.white
    tabBgColor = tabBgColor or colors.gray
    local page = frame:addLayout()
                    :setPosition(1,2)
                    :setSize("{parent.w-1}","{parent.h-2}")
                    :setBackground(BackgroundColor)
                    --:show()
                    :hide()
    topBar:addItem(name,tabBgColor,tabFrotColor,page)
    :onSelect(onTopBarSelect)
    return page
    end
    frame.addPage = addPage
    frame.topBar = topBar
    
    return frame
end

--组合控件:弹出框
local function createPopup(container, x, y, w, h, title,Draggable,Resizable)
    local popup = container:addMovableFrame()
        :setPosition(x, y)
        :setSize(w, h)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setBorder(colors.black)
        :setDraggable(Draggable)
        
    
    local title = popup:addLabel()
        :setPosition(1, 1)
        :setText(title)
        :setForeground(colors.black)
        :setBackground(colors.white)
    local closeF = function()
        
        local targetX , targetY = popup:getPosition()
        targetY = - popup:getHeight()
        popup:animatePosition(targetX,targetY,0.2,0,"easeInOutCirc",function()
            container:removeChild(popup)
        end)
        --container:removeChild(popup)
    end
    local close = popup:addButton()
        :setPosition("{parent.w-1}", 1)
        :setSize(1, 1)
        :setText("X")
        :setForeground(colors.black)
        :setBackground(colors.red)
        :onClickUp(closeF)
    local content = popup:addLayout()
        :setPosition(2, 2)
        :setSize("{parent.w-3}", "{parent.h-3}")
        :setBackground(colors.lightGray)
        :setLayoutPadding({0,0})
        if Resizable then
            popup=makeResizeable(popup)
        end
    container:setImportant(popup)
    popup:setFocus()
    content:setFocus()
    popup.content = content
    popup.title = title
    popup.close = closeF
    return popup,content
end
--组合控件:带标签的布局
local function addLabeledLayout(parent,labelText,labelColor,direction,pandding)
     labelColor = labelColor or colors.black
    pandding = pandding or 0
    direction = direction or "row"
    local labelLength = #labelText
    local layout = parent:addLayout():setSize(1,1)
    :setAutoLayout(true):setLayoutDirection(direction):setLayoutPadding(pandding):setLayoutAlignItems("center")
    local label = layout:addLabel():setText(labelText):setBackground(colors.nothing):setIgnoreOffset(true)
    layout:setBackground(parent:getBackground())
    label:setForeground(labelColor)
    label:setFlexMinWidth(labelLength+1):setFlexMaxHeight(1)
    layout.label = label
    layout.setLabelText = function(self,text)
        self.label:setText(text)
    end
    return layout , label
    
end

--组合控件:简单对话框
local function createSimpleDialog(container, x, y, w, h, title,Draggable,Resizable)
    local popup,content = createPopup(container, x, y, w, h, title,Draggable,Resizable)
    content:setLayoutDirection("column"):setLayoutAlignItems("stretch"):setLayoutPadding({0,0,0,0}):setLayoutGap(1)

    local restSpace =content:addLayout():setLayoutDirection("row"):setLayoutAlignItems("flex-end"):setLayoutJustifyContent("flex-end"):setLayoutGap(1):setLayoutPadding(1)
                                        :setFlexGrow(0.1):setFlexShrink(999):setFlexBasis(2):setFlexOrder(999):setFlexMinHeight(2)--:setBorder(colors.red)
                                        :setBackground(content:getBackground())
    local confirm = restSpace:addButton():setText("Confirm"):setFlexGrow(1):setFlexShrink(1):setFlexBasis(2):setFlexMinWidth(3)
    local cancel = restSpace:addButton():setText("Cancel"):setFlexGrow(1):setFlexShrink(1):setFlexBasis(2):setFlexMinWidth(3)

    cancel:onClickUp(popup.close)

    popup.confirmButton = confirm
    popup.cancelButton = cancel

    return popup,content,confirm,cancel,restSpace
end
--组合控件:提示框
local function createAlert(container, x, y, w, h, text,onConfirm,onCancel)
    local popup,content,confirm,cancel = createSimpleDialog(container, x, y, w, h, "Alert",true,true)
    local label = content:addLabel():setText(text):setFlexGrow(1):setFlexShrink(1):setFlexBasis(5):setFlexOrder(1)
    confirm:onClickUp(onConfirm, popup.close)
    cancel:onClickUp(onCancel)
    return popup,content,confirm,cancel,label
end
--组合控件:列表选择器
 -- items = { {text = "item1",bg=,fg=,args={}}, ...}
local function createListSelector(container, x, y, w, h, title,Draggable,Resizable,items,onConfirm)
    local popup,content,confirm,cancel = createSimpleDialog(container, x, y, w, h, title,Draggable,Resizable)
    local items = items or {}
    local itemNum = #items
    content:setLayoutPadding({1,1,0,1})
    local list = content:addList():setFlexGrow(0.1):setFlexBasis(clamp(itemNum,1,3)):setFlexMinHeight(clamp(itemNum,1,3)):setFlexOrder(1)

    list:setFocus()
    for i=1,itemNum do
        list:addItem(items[i].text,items[i].bg,items[i].fg,items[i].args)
    end
    confirm:onClickUp(function()
        local selected = list:getValue()
        if selected and onConfirm then
            onConfirm(selected,selected.text,selected.args)
        end
    end)
    confirm:onClickUp(popup.close)

    popup.list = list
    return popup,content,confirm,cancel,list
end
--组合控件:通用列表
local function createGenericList(parent,title,direction,auto,pandding,gap,alignItems,justifyContent)
    direction = direction or "column"
    auto = auto or false
    pandding = pandding or {0,1,1,1}
    gap = gap or 1
    alignItems = alignItems or "flex-start"
    justifyContent = justifyContent or "flex-start"
    local layout = parent:addLayout()
    :setAutoLayout(auto):setLayoutDirection(direction):setLayoutPadding(pandding):setLayoutGap(gap):setLayoutAlignItems(alignItems):setLayoutJustifyContent(justifyContent)
    layout:setBackground(parent:getBackground())
    layout:setBorder(colors.black)
    if parent:getType() == "layout" then
        layout:setFlexGrow(1):setFlexShrink(0):setFlexBasis(5)
    end
    layout:addLabel():setText(title):setForeground(colors.black):setBackground(parent:getBackground()):setFlexOrder(-1)
    return layout
    
end
--组合控件:滑条输入框
local function createSliderInput(parent,label, min, max, defaultValue,onValueChange)
    local layout = parent:addLayout():setLayoutDirection("row"):setLayoutPadding(1):setLayoutGap(1):setLayoutAlignItems("center")
    layout:setFlexShrink(1):setHeight(5):setAutoLayout(true)
    layout:setBackground(parent:getBackground())
    layout.label = layout:addLabel():setText(label):setForeground(colors.black):setBackground(parent:getBackground()):setFlexGrow(1):setFlexShrink(0)

    layout.slider = layout:addSlider():setFlexGrow(5):setFlexShrink(0):setSymbolForeground(colors.lightBlue)
    layout.slider:setMaxValue(max-min):setValue(defaultValue-min)

    layout.input = layout:addInput():setFlexGrow(1):setFlexShrink(0)
    layout.input:setInputType("number")
    layout.input:setValue(tostring(defaultValue))

    layout.slider:onChange(function(self,e, value)
        layout.input:rawSetValue(tostring(value+min))
        if onValueChange then
            onValueChange(value+min)
        end
    end)
    layout.input:onChange(function(self,e, value)
        local num = tonumber(value)
        if num then
            num = clamp(num,min,max)
            layout.slider:setValue(num-min)
            if onValueChange then
                onValueChange(num)
            end
        end
    end)
    layout.input:onLoseFocus(function(self)
        local num = tonumber(self:getValue())
        if num then
            num = clamp(num,min,max)
            self:setValue(tostring(num))
        end
    end)
    
    return layout
end
--组合控件:数值编辑器
local function createNumberEditorPopup(parent,title, min, max, getter, setter)
    local popup,content,confirm,cancel = createSimpleDialog(parent, "{parent.w/2-10}", "{parent.h/2-5}", 25, 14, title,true,false)
    local dirtyValue = getter()
    local inputLayout = createSliderInput(content,"Value",min,max,getter(),function(value)
        dirtyValue = value
    end)
    inputLayout.input:setValue(tostring(getter()))
    confirm:onClickUp(function()
        
        if dirtyValue then
            dirtyValue = clamp(dirtyValue,min,max)
            setter(dirtyValue)
        end
    end)
    confirm:onClickUp(popup.close)
    return popup,content,confirm,cancel,inputLayout
end
--组合控件:字符串输入框
local function createStringInput(parent,label,defaultValue,onValueChange)
    local layout = parent:addLayout():setLayoutDirection("row"):setLayoutPadding(1):setLayoutGap(1):setLayoutAlignItems("center")
    layout:setFlexShrink(1):setHeight(5):setAutoLayout(true)
    layout:setBackground(parent:getBackground())
    layout.label = layout:addLabel():setText(label):setForeground(colors.black):setBackground(parent:getBackground()):setFlexGrow(1):setFlexShrink(0)

    layout.input = layout:addInput():setFlexGrow(5):setFlexShrink(0):setWidth(10)
    layout.input:setValue(defaultValue)
    layout.input:onChange(function(self,e, value)
        if onValueChange then
            onValueChange(value)
        end
    end)
    return layout
end
--组合控件:字符串编辑器
local function createStringEditorPopup(parent,title, getter, setter)
    local popup,content,confirm,cancel = createSimpleDialog(parent, "{parent.w/2-10}", "{parent.h/2-5}", 25, 14, title,true,true)
    local dirtyValue = getter()
    local inputLayout = createStringInput(content,"Value",getter(),function(value)
        dirtyValue = value
    end)
    confirm:onClickUp(function()
        if dirtyValue then
            setter(dirtyValue)
        end
    end)
    confirm:onClickUp(popup.close)
    return popup,content,confirm,cancel,inputLayout
end
--组合控件:switch(开关)输入框
local function createSwitchInput(parent,label,defaultValue,onValueChange)
    local layout = parent:addLayout():setLayoutDirection("row"):setLayoutPadding(1):setLayoutGap(1):setLayoutAlignItems("center")
    layout:setFlexShrink(1):setHeight(5):setAutoLayout(true)
    layout:setBackground(parent:getBackground())
    layout.label = layout:addLabel():setText(label):setForeground(colors.black):setBackground(parent:getBackground()):setFlexGrow(5):setFlexShrink(0)

    layout.switch = layout:addSwitch():setFlexGrow(1):setFlexShrink(0):setWidth(3)
    layout.switch:setValue(defaultValue)
    layout.switch:onChange(function(self,e, value)
        if onValueChange then
            onValueChange(value)
        end
    end)
    return layout
end
--组合控件:布尔编辑器
local function createBooleanEditorPopup(parent,title, getter, setter)
    local popup,content,confirm,cancel = createSimpleDialog(parent, "{parent.w/2-10}", "{parent.h/2-5}", 25, 14, title,true,false)
    local dirtyValue = getter()
    local inputLayout = createSwitchInput(content,"Value",getter(),function(value)
        dirtyValue = value
    end)
    confirm:onClickUp(function()
        if dirtyValue then
            setter(dirtyValue)
        end
    end)
    confirm:onClickUp(popup.close)
    return popup,content,confirm,cancel,inputLayout
end
-- 生成table里deep的基础对象对应的UI
-- 找到table里的所有底层对象和key(只保留最底层的对象的key:以XXX-XXX-XXX的形式)
local function getDeepKeys(t,keys,preKey)
    keys = keys or {}
    for k,v in pairs(t) do
        if type(v) == "table" then
            getDeepKeys(v,keys,preKey and preKey.."-"..k or k)
        else
            keys[preKey and preKey.."-"..k or k] = v
        end
    end
    return keys
end
-- 根据deepKeys反过来修改table的值
local function setDeepKeys(t,deepKeys)
    for k,v in pairs(deepKeys) do
        local keys = split(k, "-")
        local temp = t
        if #keys>1 then
            for i=1,#keys-1 do
                local numKey = tonumber(keys[i])
                if numKey then
                    temp = temp[numKey]
                else
                    temp = temp[keys[i]]
                end
            end
            
        else
            temp = t
        end
        temp[keys[#keys]] = v
    end
    return t
end

--组合控件:table编辑器
local function createTableEditorPopup(parent,title, getter, setter)
    local popup,content,confirm,cancel = createSimpleDialog(parent, "{parent.w/2-10}", "{parent.h/2-5}", 41, 24, title,true,true)
    local dirtyValue = getter()
    local inputLayouts = {}
    local deepValue = getDeepKeys(dirtyValue)
    for k,v in pairs(deepValue) do
        -- 根据value的类型生成对应的UI
        local inputLayout
        if type(v) == "number" then
            inputLayout = createSliderInput(content,k,-1000,1000,v,function(value)
                deepValue[k] = value
            end)
        elseif type(v) == "string" then
            inputLayout = createStringInput(content,k,v,function(value)
                deepValue[k] = value
            end)
        elseif type(v) == "boolean" then
            inputLayout = createSwitchInput(content,k,v,function(value)
                deepValue[k] = value
            end)
        end
    end
    
    confirm:onClickUp(function()
        setDeepKeys(dirtyValue,deepValue)
        if dirtyValue then
            setter(dirtyValue)
        end
    end)
    confirm:onClickUp(popup.close)
    return popup,content,confirm,cancel,inputLayouts
end

local function createValueEditorPopup(parent,title,typ,getter,setter)
    local popup,content,confirm,cancel
    if typ == "number" then
        popup,content,confirm,cancel = createNumberEditorPopup(parent,title, -1000, 1000, getter, setter)
    elseif typ == "string" then
        popup,content,confirm,cancel = createStringEditorPopup(parent,title, getter, setter)
    elseif typ == "boolean" then
        popup,content,confirm,cancel = createBooleanEditorPopup(parent,title, getter, setter)
    elseif typ == "table" then
        popup,content,confirm,cancel = createTableEditorPopup(parent,title, getter, setter)
    end
    return popup,content,confirm,cancel
    
end


















------------------------------------------------
--SplitSpace 被废弃,改用NSplitSpace
-- local function createSplitSpace(container,direction,firstGrow,secondGrow,firstShrink,secondShrink,firstMin,secondMin)
--     direction = direction or "column"
--     firstGrow = firstGrow or 1
--     secondGrow = secondGrow or 1
--     firstShrink = firstShrink or 0
--     secondShrink = secondShrink or 0
--     firstMin = firstMin or 0
--     secondMin = secondMin or 0
--     local layout = container:addLayout()
--     :setAutoLayout(false):setLayoutDirection(direction):setLayoutPadding(0):setLayoutGap(0):setLayoutAlignItems("stretch")

--     layout:setBackground(container:getBackground()):setBaseDraw(false)
--     container:setBaseDraw(false)
--     --layout:setBorder(colors.red)
--     if container:getType() == "Layout" then
--         layout:setFlexGrow(1):setFlexShrink(0):setFlexBasis(1)
--     end
--     local first = layout:addLayout():setLayoutDirection(direction):setLayoutPadding(0):setLayoutGap(0):setLayoutAlignItems("stretch"):setAutoLayout(false)
--     --local first = layout:addFrame()
--     first:setBackground(container:getBackground())--:setBorder(colors.blue)
--     first:setFlexGrow(firstGrow):setFlexShrink(firstShrink):setFlexBasis(firstMin)
--     first:setBaseDraw(false)
--     local second = layout:addLayout():setLayoutDirection(direction):setLayoutPadding(0):setLayoutGap(0):setLayoutAlignItems("stretch"):setAutoLayout(false)
--     --local second = layout:addFrame()
--     second:setBackground(container:getBackground())--:setBorder(colors.purple)
--     second:setFlexGrow(secondGrow):setFlexShrink(secondShrink):setFlexBasis(secondMin)
--     second:setBaseDraw(false)
--     layout.first = first
--     layout.second = second

--     return layout,first,second
-- end
--lyout组合控件:分割空间
local function createNSplitSpace(container,selfname,direction,splitNum,grow,shrink,min,names)
    direction = direction or "column"
    
    if type(grow)~="table" then
        error("grow must be a table")
    end
    if type(shrink)~="table" then
        error("shrink must be a table")
    end
    if min and type(min)~="table" then
        error("min must be a table")
    end
    if names and type(names)~="table" then
        error("names must be a table")
    elseif not names then
        names = {}
    end
    
    local layout = container:addLayout(selfname)
    :setAutoLayout(false):setLayoutDirection(direction):setLayoutPadding(0):setLayoutGap(0):setLayoutAlignItems("stretch")
    layout:setBackground(container:getBackground()):setBaseDraw(false)
    container:setBaseDraw(false)
    if container:getType() == "Layout" then
        layout:setFlexGrow(1):setFlexShrink(0):setFlexBasis(1)
    end
    layout["split"] = setmetatable({},{__mode="v"}) -- !!:弱引用,防止内存泄漏
    for i=1,splitNum do
        local split = layout:addLayout(names[i]):setLayoutDirection(direction):setLayoutPadding(0):setLayoutGap(0):setLayoutAlignItems("stretch"):setAutoLayout(false)
        split:setBackground(container:getBackground())
        split:setFlexGrow(grow[i]):setFlexShrink(shrink[i])
        if min then
            split:setFlexBasis(min[i])
        else
            split:setFlexBasis(0)
        end
        split:setBaseDraw(false)
        layout["split"][i] = split
    end
    return layout
end

--⭐⭐⭐⭐⭐
-- @param container: 容器
-- @param table: 一个table,包含了所有的UI元素的属性
-- @return harvestObj: 一个弱引用的table,包含了所有设置了name的对象
local function createUIFromTable(container, table)
    --如果table直接含有type属性,则判断为单个元素
    if table.type then
        table = {table}
    end
    local harvestObj = setmetatable({},{__mode="v"}) -- --所有设置了name的对象,弱引用
    for _, item in ipairs(table) do
        local obj
        if item.type == "split" then
            obj = createNSplitSpace(container,item.name, item.splitDirection or "column", item.splitNum or 2, item.childGrow or {1, 1}, item.childShrink or {0, 0}, item.childBasis or nil,item.childNames or nil)
            if item.name then harvestObj[item.name] = obj end
            for i, splitChild in ipairs(item.splitChildren or {}) do -- 注意这里是splitChildren,而不是children
                --splitChild无法修改属性,所以这里专门设置
                for key, value in pairs(splitChild) do
                    if key ~= "type" and key ~= "children"  then
                        local method = "set" .. key:gsub("^%l", string.upper)
                        if obj["split"][i][method] then
                            obj["split"][i][method](obj["split"][i], value)
                        end
                    end
                end
                local subH= createUIFromTable(obj["split"][i], splitChild.children)
                for k,v in pairs(subH) do
                    harvestObj[k] = v
                end
                if item.childNames and item.childNames[i] then harvestObj[item.childNames[i]] = obj["split"][i] end
            end
        else
            local method = "add" .. item.type:gsub("^%l", string.upper)
            if container[method] then
                obj = container[method](container,item.name)
                if item.name then harvestObj[item.name] = obj end
            end
        end

        if obj then
            for key, value in pairs(item) do
                if key ~= "type" and key ~= "children" then
                    local method = "set" .. key:gsub("^%l", string.upper)
                    if obj[method] then
                        obj[method](obj, value)
                    end
                end
            end

            if item.children and item.type ~= "split" --[[and isContain(obj:getTypes(),"Container")]] then
                local subH= createUIFromTable(obj, item.children)
                for k,v in pairs(subH) do
                    harvestObj[k] = v
                end
            end
        end
    end
    return harvestObj
end
--#region

-- -- MVC -- --
--controller
-- @param observable: 被观察者
-- @param observeFuncName: 被观察者的方法名
-- @param observer: 观察者
-- @param observerFuncName: 观察者的方法名,如果为空则直接调用observer
-- 信息流向: 当observable的observeFuncName对应事件发生时,observer的observerFuncName对应方法被调用
-- 例子1: bind(someButton, "onClickUp", someObject, "someMethod")
-- 例子2: bind(someInput,"onChange",someObject,"someMethod")
local function bind(observable, observeFuncName, observer, observerFuncName)
    if observerFuncName then
        observable[observeFuncName](observable, function (...)
            observer[observerFuncName](observer, ...)
        end)
    else
        observable[observeFuncName](observable, function (...)
            observer(...)
        end)
    end
end

local function wrapFunction(wrapFunc,requireParams,isUnpack)
    --requireParams: 一个table,包含了所有需要的参数的位置
    --如:{2,1} 表示第一个参数是第二个参数,第二个参数是第一个参数
    --如{1} 只需要第一个参数
    return function(...)
        local params = {...}
        local newParams = {}
        if type(requireParams)=="table" then
            for _,v in ipairs(requireParams) do
                table.insert(newParams,params[v])
            end
        else
            newParams = params
        end
        if isUnpack then
            return wrapFunc(table.unpack(newParams))
        else
            return wrapFunc(newParams)
        end
    end
end

local function wrapObserver(observer,wrapFuncName,requireParams,isUnpack)
    return function(...)
        local params = {...}
        local newParams = {}
        if type(requireParams)=="table" then
            for _,v in ipairs(requireParams) do
                table.insert(newParams,params[v])
            end
        else
            newParams = params
        end

        if isUnpack then
            observer[wrapFuncName](observer,table.unpack(newParams))
        else
            observer[wrapFuncName](observer,newParams)
        end
    end
end

--综合例子
--bind(someButton, "onClickUp", wrapObserver(someInfoBoj,"setValue",{3,4},false))
--bind(someInput,"onChange",wrapObserver(someInfoBoj,"setValue",{2},true))


--#endregion
--
















--
toolkit={
    clamp=clamp
    ,isContain=isContain
    ,split=split
    ,getDeepKeys=getDeepKeys
    ,setDeepKeys=setDeepKeys
    ,tableCount=tableCount
    ,tableToString=tableToString
    ,
    makeResizeable=makeResizeable
    ,makeTaggedFrame=makeTaggedFrame,taggedFrame=makeTaggedFrame
    ,createPopup=createPopup,popup=createPopup
    ,addLabeledLayout=addLabeledLayout,labeledLayout=addLabeledLayout
    ,createSimpleDialog=createSimpleDialog,simpleDialog=createSimpleDialog
    ,createAlert=createAlert,alert=createAlert
    ,createListSelector=createListSelector,listSelector=createListSelector
    ,createGenericList=createGenericList,genericList=createGenericList
    ,createSliderInput=createSliderInput,sliderInput=createSliderInput
    ,createNumberEditorPopup=createNumberEditorPopup,numberEditorPopup=createNumberEditorPopup
    ,createStringInput=createStringInput,stringInput=createStringInput
    ,createStringEditorPopup=createStringEditorPopup,stringEditorPopup=createStringEditorPopup
    ,createSwitchInput=createSwitchInput,switchInput=createSwitchInput
    ,createBooleanEditorPopup=createBooleanEditorPopup,booleanEditorPopup=createBooleanEditorPopup
    ,createTableEditorPopup=createTableEditorPopup,tableEditorPopup=createTableEditorPopup
    ,createValueEditorPopup=createValueEditorPopup,valueEditorPopup=createValueEditorPopup
    ,
    createNSplitSpace=createNSplitSpace,nSplitSpace=createNSplitSpace
    ,createUIFromTable=createUIFromTable
    ,
    bind=bind
    ,wrapFunction=wrapFunction
    ,wrapObserver=wrapObserver
    
}
return toolkit