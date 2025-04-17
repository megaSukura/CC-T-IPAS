return function (basalt,container,IPAS,toolkit)
    

    if not basalt then
        error("Basalt not found")
    end

    if not IPAS then
        error("IPAS not found")
    end

    if not toolkit then
        error("UItoolkit not found")
    end
    --[[
    -后台
        -信息区
            -信息列表
                -操作区
                    -添加信息[按钮]
                    :弹窗
                    -删除信息[按钮]
                    :弹窗
                    -信息筛选[输入框]
                -当前信息列表
                    -信息名称[标签]
                    -信息类型[标签]
                    -信息值[标签]
            -信息详情
                -基本信息
                    -信息名称
                    -信息类型
                    -信息值
                    -信息描述(todo)
                -meta信息(可更改)
                    -inputInfos[下拉框]
                    -meta参数[弹窗]
            
        -处理器区
            -处理器列表
                -操作区
                    -添加处理器[按钮]
                    :弹窗
                    -删除处理器[按钮]
                    :弹窗
                    -处理器筛选[输入框]
                -当前处理器列表
                    -处理器名称[标签]
                    -处理器描述[标签]
            -处理器详情
                -基本信息
                    -处理器名称[标签]
                    -处理器描述[标签]
                    -输入类型[表标签]
                    -输出类型[标签]
                    -处理器代码[标签]

        -自定义前台区


    -前台:按照自定义显示

    ]]
    --#region IPAS_UI toolkit
    local print_r = function (table,filter)
        BPrintTable(basalt,table,filter)
    end
    --onConfirm(selected,selected.text,selected.args)
    local function createInfosSelector(infos,onConfirm)
    local list ={}
    for k,v in pairs(infos)do
        table.insert(list, { text = v.name, bgCol = colors.lightGray, fgCol = colors.black, args = v})      
        end

    local selecter = toolkit.createListSelector(container,"{parent.w/2-15}", "{parent.h/2-5}", 30, 15,"Select Info",true,true,list,onConfirm)
    end
    local function createInfosSelectorButton(_container,infos,onConfirm)
        local button = _container:addButton():onClickUp(function()
            createInfosSelector(infos,onConfirm)
        end):setText("Select Infos")
        return button
    end

    local function createInfoDetail(_container,info)
        local infoDetail = {
            type = "split",
            name = "infoDetail",
            splitDirection = "row",
            splitNum = 2,
            childGrow = {1, 2},
            childShrink = {1, 2},
            childNames = {"baseInfo", "metaInfo"},
            splitChildren = {
                {
                    --border = colors.black,
                    layoutDirection = "column",
                    layoutGap = 1,
                    layoutPadding = 1,
                    layoutJustifyContent = "flex-start",
                    background = colors.gray,
                    baseDraw = true,
                    border = colors.black,
                    children = {
                        {
                            type = "Label",
                            text = "Info Name:\n"..info.name,
                            fontSize = 1
                        },
                        {
                            type = "Label",
                            text = "Info Type:\n"..info.type,
                            fontSize = 1
                        },
                        {
                            type = "Label",
                            flexGrow = 1,
                            text = "Info Value:\n"..(toolkit.tableToString(info:getValue())),
                            fontSize = 1
                        }
                    }
                },
                {
                    --border = colors.black,
                    layoutDirection = "column",
                    layoutGap = 1,
                    layoutPadding = 1,
                    layoutJustifyContent = "center",
                    children = {
                        {
                            type = "Label",
                            text = "Meta Info:",
                        }
                    }
                }
            }
        }
        local infoDetailObj = toolkit.createUIFromTable(_container,infoDetail)
        --listeners
        local infoListenersList = (toolkit.labeledLayout(infoDetailObj["baseInfo"],"listeners:")):addList():setSize(5,1)
        infoListenersList:setFlexGrow(1):setFlexShrink(1):setWidth(9)
        :onGetFocus(function(self)self:setHeight(math.min(5,self:getItemCount()))end)
        --:onLoseFocus(function(self)self:setHeight(1)end)
        :onSelect(function(self)self:selectItem(1)end):addItem("num:"..(toolkit.tableCount(info.listeners) or 0))
        for k,v in pairs(info.listeners)do
            infoListenersList:addItem(k or "nil")
        end
        --listening
        local infoListeningList = (toolkit.labeledLayout(infoDetailObj["baseInfo"],"listenings:")):addList():setSize(5,1)
        infoListeningList:setFlexGrow(1):setFlexShrink(1):setWidth(9)
        :onGetFocus(function(self)self:setHeight(math.min(5,self:getItemCount()))end)
        --:onLoseFocus(function(self)self:setHeight(1)end)
        :onSelect(function(self)self:selectItem(1)end):addItem("num:"..(toolkit.tableCount(info.listenings) or 0))
        for k,v in pairs(info.listenings)do
            infoListeningList:addItem(v.name or "nil")
        end
        -- --
        --metadata
        local copydata = setmetatable({}, {__mode = "v"})
        infoDetailObj["metaInfo"]:setLayoutJustifyContent("flex-start")
        if info.metadata and next(info.metadata) then -- 有metadata 或者 metadata不为空

            local copyinputInfos
            for k,v in pairs(info.metadata)do
                if k~="inputInfos" then
                    copydata[k] = v
                else
                   copyinputInfos = v--setmetatable( v, {__mode = "v"})
                end
            end
            local deepKeys = toolkit.getDeepKeys(copydata)
            --按key字符串顺序排序
            local sortedKeys = {}
            for k,v in pairs(deepKeys) do
                table.insert(sortedKeys,k)
            end
            table.sort(sortedKeys)
            for k , key in pairs(sortedKeys)do
                local v = copydata[key]
                -- 根据value的类型生成对应的UI
                local inputLayout
                if type(v) == "number" then
                    inputLayout = toolkit.createSliderInput(infoDetailObj["metaInfo"],key,-100,100,v,function(value)
                        copydata[key] = value
                        --toolkit.setDeepKeys(info.metadata,copydata)
                    end)
                elseif type(v) == "string" then
                    inputLayout = toolkit.createStringInput(infoDetailObj["metaInfo"],key,v,function(value)
                        copydata[key] = value
                        --toolkit.setDeepKeys(info.metadata,copydata)
                    end)
                elseif type(v) == "boolean" then
                    inputLayout = toolkit.createSwitchInput(infoDetailObj["metaInfo"],key,v,function(value)
                        copydata[key] = value
                        --toolkit.setDeepKeys(info.metadata,copydata)
                    end)
                end
            end
            --inputInfos

            if copyinputInfos then
                for k,v in pairs(copyinputInfos)do
                    local inputInfoLayout = toolkit.labeledLayout(infoDetailObj["metaInfo"],k)
                    local inputInfoSelectorButton = createInfosSelectorButton(inputInfoLayout,IPAS.Infos,function(selected,selectedText,selectedArgs)
                        copyinputInfos[k] = selectedArgs[1]
                        toolkit.setDeepKeys(info.metadata,{inputInfos=copyinputInfos})
                        info:getValue()
                    end)
                    inputInfoSelectorButton:setText(v and v.name or "nil")
                end                
            end
            
        else
            infoDetailObj["metaInfo"]:addButton():setText("Set Value"):onClickUp(function()
                local value_typ= type(info.value)
                toolkit.valueEditorPopup(container,"info value",value_typ,function ()
                    return info.value
                end,
                function (value)
                    info.setValue(value)
                    --info:getValue()
                    infoDetailObj["infoDetail"]:getParent():removeChild(infoDetailObj["infoDetail"])
                    createInfoDetail(_container,info)
                end)
        end)
        end
        infoDetailObj["metaInfo"]:addButton():setText("Refesh"):onClickUp(function()
            print_r(info.metadata)
            toolkit.setDeepKeys(info.metadata,copydata)
            info:getValue()
            infoDetailObj["infoDetail"]:getParent():removeChild(infoDetailObj["infoDetail"])
            createInfoDetail(_container,info)
            print_r(info.metadata)
        end):setFlexOrder(-1)


















        return infoDetailObj
    end
    local function createInfoList(List,infos,DetailContainer)
        List:clear()
        for k,v in pairs(IPAS.Infos)do
            List:addItem(v.name)
        end
        List:onSelect(function(self,e,value)
            local selected = IPAS.Infos[value.text ]
            if selected then
                DetailContainer:removeChildren()
                createInfoDetail(DetailContainer,selected)
            end
        end)        
    end
    ----create info
    local function createInfoCreationElment(_container,infoType)
        if infoType == "number" then
            local newInfoData={name="newInfo",type="number",value=0,meta={}}
            _container:addLabel():setText("number Name:")
            local nameInput = _container:addInput():setDefaultText("newInfo"):onChange(function(self,e,value)
                newInfoData.name = value
            end)
            _container:addLabel():setText("default Value:")
            local defaultInput = _container:addInput():setInputType("number"):onChange(function(self,e,value)
                newInfoData.value = tonumber(value) or 0
            end)
            return function () return newInfoData end
        elseif infoType == "string" then
            local newInfoData={name="newInfo",type="string",value="",meta={}}
            _container:addLabel():setText("string Name:")
            local nameInput = _container:addInput():setDefaultText("newInfo"):onChange(function(self,e,value)
                newInfoData.name = value
            end)
            _container:addLabel():setText("default Value:")
            local defaultInput = _container:addInput():onChange(function(self,e,value)
                newInfoData.value = value
            end)
            return function () return newInfoData end 
        elseif infoType == "boolean" then
            local newInfoData={name="newInfo",type="boolean",value=false,meta={}}
            _container:addLabel():setText("boolean Name:")
            local nameInput = _container:addInput():setDefaultText("newInfo"):onChange(function(self,e,value)
                newInfoData.name = value
            end)
            _container:addLabel():setText("default Value:")
            local defaultInput = _container:addSwitch():onChange(function(self,e,value)
                newInfoData.value = value
            end)
            return function () return newInfoData end
        elseif infoType == "table{any}" then
            --使用load()函数(相信用户输入的lua代码XD)
            local newInfoData={name="newInfo",type="table{any}",value={},meta={}}
            _container:addLabel():setText("table Name:")
            local nameInput = _container:addInput():setDefaultText("newInfo"):onChange(function(self,e,value)
                newInfoData.name = value
            end)
            _container:addLabel():setText("default Value:")
            local _code="return {}"
            local defaultInput = _container:addInput():onChange(function(self,e,value)
                _code = value
            end)
            return function ()
                --[[如果用户直接输入{xxxx},在开头添加return]]
                if not string.find(_code,"return") then
                    _code = "return ".._code
                end
                local f,e = load(_code)
                if f then
                    newInfoData.value = f()
                else
                    basalt:debug(e)
                end
                return newInfoData
            end
        end
    end
    local function createBaseInfoPopup(parent)
    local dataGetter
    local popup,content,confirm,cancel = toolkit.createSimpleDialog(parent, "{parent.w/2-10}", "{parent.h/2-5}", 41, 24, "create Base Info",true,true)
    local selectInfoType = content:addDropdown():addItem("number"):addItem("string"):addItem("boolean"):addItem("table{any}"):setFlexGrow(1)
    :onSelect(function(self)
        content:removeChild(self)
        dataGetter =createInfoCreationElment(content,self:getValue().text)
    end)
    confirm:onClickUp(function()
        if dataGetter then
            local data = dataGetter()
            --print_r(data)
            IPAS.CreateInfo(data.name,data.type,data.value,nil,data.meta)
            popup:remove()
        end
    end)
    end
    local function createProcessedInfoElement(_container,data)
        local usedProcessor = IPAS.processorInfos[data.processorName]
        _container:addLabel():setText("Using Processor:"..data.processorName)
        _container:addLabel():setText("Input Info:")
        for k,v in pairs(usedProcessor.requireInfoNames)do
            _container:addLabel():setText(v..":")
            createInfosSelectorButton(_container,IPAS.Infos,function(selected,selectedText,selectedArgs)
                data.inputInfos[v] = selectedArgs[1]
            end):setText("Select "..v)
        end
        _container:addLabel():setText("New Info Name:")
        local newInfoNameInput = _container:addInput():setDefaultText("newInfo"):onChange(function(self,e,value)
            data.newInfoName = value
        end)
        if usedProcessor.requireMetaNames and next(usedProcessor.requireMetaNames) then
            _container:addLabel():setText("Meta:")
            for k,v in pairs(usedProcessor.requireMetaNames)do
                _container:addLabel():setText(v..":")
                local metaInput = _container:addInput():onChange(function(self,e,value)
                    data.meta[v] = value
                end)
            end
        end
    end
    local function createProcessInfoCreationPopup(parent)
        local data={processorName="",inputInfos={},newInfoName="",meta={}}
        local popup,content,confirm,cancel = toolkit.createSimpleDialog(parent, "{parent.w/2-10}", "{parent.h/2-5}", 41, 24, "create Processor",true,true)
        content:addLabel():setText("Select processor:")
        local processorSelector = content:addDropdown():setFlexGrow(1)
        for k,v in pairs(IPAS.processorInfos)do
            processorSelector:addItem(k)
        end
        processorSelector:onSelect(function(self)
            data.processorName = self:getValue().text
            content:removeChild(self)
            createProcessedInfoElement(content,data)
        end)

        confirm:onClickUp(function()
            IPAS.ProcessInfos(data.processorName,data.inputInfos,data.newInfoName,data.meta)
            popup:remove()
        end)

    end
    ----------------prossor
    --[[
        processorInfo结构:
        processorInfos[processorName]={
            processorName,
            requireInfoNames,:列表
            requireTypes, :字典(key:inputInfoName,value:inputInfoType)
            outputInfoType,
            requireMetaNames,:列表
            code
        }
    ]]
    local function createProcessorDetail(_container,processorInfo,processorName)
        local processorDetail = {
            type = "layout",
            layoutDirection = "column",
            layoutAlignItems = "stretch",
            layoutGap = 1,
            layoutPadding = 1,
            flexGrow = 1,
            name = "processorDetail",
            children = {
                {
                    type = "Label",
                    text = "Processor Name:\n"..processorName,
                },
                {
                    type="Pane",
                    background = colors.gray,
                    backgroundSymbol = "\127",
                    height = 1,
                    flexMinHeight = 1,
                },
                {
                    type = "Label",
                    flexGrow = 1,
                    text = "Require Infos:\n"..toolkit.tableToString(processorInfo.requireInfoNames),
                },
                {
                    type = "Label",
                    flexGrow = 1,
                    text = "Input Types:\n"..toolkit.tableToString(processorInfo.requireTypes),
                },
                {
                    type = "Label",
                    text = "Output Type:\n"..processorInfo.outputInfoType,
                },
                {
                    type = "Label",
                    flexGrow = 1,
                    text = "Require Metas:\n"..toolkit.tableToString(processorInfo.requireMetaNames),
                },
                {
                    type = "Label",
                    flexGrow = 1,
                    text = "Processor Code:\n"..processorInfo.code,
                }
            }
        }
        local processorDetailObj = toolkit.createUIFromTable(_container,processorDetail)
        return processorDetailObj
        
    end

    local function createProcessorList(List,DetailContainer)
        List:clear()
        for k,v in pairs(IPAS.processorInfos)do
            List:addItem(k)
        end
        List:onSelect(function(self,e,value)
            local selected = IPAS.processorInfos[value.text ]
            if selected then
                DetailContainer:removeChildren()
                createProcessorDetail(DetailContainer,selected,value.text)
            end
        end)
    end

    local createProcessorCreationPopup = function(parent)
        local data={}
        local popup,content,confirm,cancel = toolkit.createSimpleDialog(parent, "{parent.w/2-10}", "{parent.h/2-5}", 41, 24, "create Processor",true,true)
        content:addLabel():setText("Processor Name:")
        local processorNameInput = content:addInput():setDefaultText("newProcessor"):onChange(function(self,e,value)
            data.processorName = value
        end)
        content:addLabel():setText("Require Infos:")
        local requireInfoNamesInput = content:addInput():onChange(function(self,e,value)
            data.requireInfoNames = toolkit.split(value,",")
        end)
        content:addLabel():setText("Input Types:")
        local requireTypesInput = content:addInput():onChange(function(self,e,value)
            local _split = toolkit.split(value,",")
            local _dict = {}
            for k,v in pairs(_split)do
                local _split2 = toolkit.split(v,":")
                _dict[_split2[1]] = _split2[2]
            end
            data.requireTypes = _dict
        end)
        content:addLabel():setText("Output Type:")
        local outputInfoTypeInput = content:addInput():onChange(function(self,e,value)
            data.outputInfoType = value
        end)
        content:addLabel():setText("Require Metas:")
        local requireMetaNamesInput = content:addInput():onChange(function(self,e,value)
            data.requireMetaNames = toolkit.split(value,",")
        end)
        content:addLabel():setText("Processor Code:")
        local codeInput = content:addInput():onChange(function(self,e,value)
            data.code = value
        end)
        confirm:onClickUp(function()
            IPAS.LoadProcessor(data.processorName,data.requireInfoNames,data.requireTypes,data.outputInfoType,data.requireMetaNames,data.code)
            popup:remove()
        end)
    end



    --#endregion

    local layoutTable = {
        {
            type = "split",
            splitDirection = "column",
            splitNum = 2,
            childGrow = {1, 8},
            childShrink = {0, 8},
            childNames = {"header", "main"},
            width= "{parent.w-2}",
            height = "{parent.h-2}",
            splitChildren = {
                {
                    flexGrow = 1,
                    children = {
                        { --如果这个container只有一个子对象,那么这个{}可以省略
                            type = "split",
                            splitDirection = "row",
                            splitNum = 3,
                            childGrow = {1, 2, 4},
                            childShrink = {0, 0, 0},
                            splitChildren = {
                                {
                                    layoutDirection = "column",
                                    layoutGap = 1,
                                    center = true,
                                    border = colors.cyan,
                                    children = {
                                        {
                                            type = "Label",
                                            text = "IPAS",
                                            fontSize = 2
                                        },
                                        {
                                            type = "Label",
                                            text = "-backspace-"
                                        }
                                    }
                                },
                                {
                                    --center = true,
                                    layoutDirection = "column",
                                    layoutPadding = 1,
                                    layoutAlignItems = "flex-start",
                                    children = {
                                        {
                                            type = "Label",
                                            text = "Base Infomation:",
                                            fontSize = 1
                                        },
                                        {
                                            type = "Label",
                                            name = "time Label",
                                            text = "time:"
                                        },
                                        {
                                            type = "Label",
                                            name = "computer Label",
                                            text = "computer:"
                                        },
                                        {
                                            type = "Label",
                                            name = "wether Label",
                                            text = "wether:"
                                        }
                                    }
                                },
                                {
                                    --center = true,
                                    layoutGap = 1,
                                    layoutAlignItems = "stretch",
                                    layoutPadding = 1,
                                    children = {
                                        {
                                            type = "Button",
                                            name = "SaveButton",
                                            text = "Save",
                                            flexGrow = 1,
                                            flexShrink = 1,
                                            background = colors.lightBlue
                                        },
                                        {
                                            type = "Button",
                                            name = "LoadButton",
                                            text = "Load",
                                            flexGrow = 1,
                                            flexShrink = 1,
                                            background = colors.green
                                        },
                                        {
                                            type = "Button",
                                            name = "Button3",
                                            text = "Button3",
                                            flexGrow = 1,
                                            flexShrink = 1,
                                            background = colors.blue
                                        }
                                    }
                                }
                            }
                        }
                    }
                },
                {
                    baseDraw = true,
                    background = colors.pink,
                    children = {}
                }
            }
        }
    }

    local harvestObj = toolkit.createUIFromTable(container,layoutTable)
    harvestObj.SaveButton:onClickUp(function()IPAS.Save()end)
    harvestObj.LoadButton:onClickUp(function()IPAS.Load()end)
    --#region
    local mainTaged = toolkit.makeTaggedFrame(harvestObj.main:addFrame():setFlexGrow(1):setFlexShrink(1):setBaseDraw(false))
    -- infos area  ##################################################
    local infosArea = mainTaged.addPage("infosArea",colors.lightGray)
    infosArea:setLayoutAlignItems("stretch")
    local infoslayoutTable = {
        type = "split",
        background = colors.lightGray,
        baseDraw = true,
        BgSymbol = "\127",
        border = colors.gray,
        splitDirection = "row",
        splitNum = 2,
        childGrow = {1, 4},
        childShrink = {1, 4},
        childNames = {nil, "infosDetailLayout"},
        layoutGap = 0,
        splitChildren = {
            {
                --border = colors.black,
                layoutPadding = {1,1,0,1},
                layoutAlignItems = "stretch",
                layoutDirection = "column",
                children = {
                    {
                        type = "Label",
                        text = "Infos List:",
                    },
                    {
                        type = "Button",
                        text = "Refesh",
                        name = "RefeshInfosListButton",
                    },
                    {
                        type = "Button",
                        text = "Add Base Info",
                        name = "AddbaseInfoButton",
                    },
                    {
                        type = "Button",
                        text = "Add Processed Info",
                        name = "AddProcessedInfoButton",
                    },
                    {
                        type = "List",
                        name = "infosList",
                        flexGrow = 1,
                    }
                }
            },
            {
                --border = colors.black,
                layoutPadding = 1,
                layoutAlignItems = "stretch",
                layoutDirection = "column",
                children={
                    
                }
            }
        }
    }
    local infosObj = toolkit.createUIFromTable(infosArea,infoslayoutTable)
    

    
    createInfoList(infosObj.infosList,IPAS.Infos,infosObj.infosDetailLayout)
    infosObj.RefeshInfosListButton:onClickUp(function()
        createInfoList(infosObj.infosList,IPAS.Infos,infosObj.infosDetailLayout)
    end)
    
    infosObj.AddbaseInfoButton:onClickUp(function()
        createBaseInfoPopup(container)
    end)
    infosObj.AddProcessedInfoButton:onClickUp(function()
        createProcessInfoCreationPopup(container)
    end)
















    -- processors area  ##################################################
    --[[
        processorInfo结构:
        processorInfos[processorName]={
            processorName,
            requireInfoNames,:列表
            requireTypes, :字典(key:inputInfoName,value:inputInfoType)
            outputInfoType,
            requireMetaNames,:列表
            code
        }
    ]]
    local processorsArea = mainTaged.addPage("processorsArea",colors.lightGray)
    processorsArea:setLayoutAlignItems("stretch")
    local processorslayoutTable = {
        type = "split",
        background = colors.lightGray,
        baseDraw = true,
        BgSymbol = "\127",
        border = colors.gray,
        splitDirection = "row",
        splitNum = 2,
        childGrow = {1, 4},
        childShrink = {1, 4},
        childNames = {nil, "processorsDetailLayout"},
        layoutGap = 0,
        splitChildren = {
            {
                --border = colors.black,
                layoutPadding = {1,1,0,1},
                layoutAlignItems = "stretch",
                layoutDirection = "column",
                children = {
                    {
                        type = "Label",
                        text = "Processors List:",
                    },
                    {
                        type = "Button",
                        text = "Refesh",
                        name = "RefeshProcessorsListButton",
                    },
                    {
                        type = "Button",
                        text = "Add Processor",
                        name = "AddProcessorButton",
                    },
                    {
                        type = "List",
                        name = "processorsList",
                        flexGrow = 1,
                    }
                }
            },
            {
                --border = colors.black,
                layoutPadding = 1,
                layoutAlignItems = "stretch",
                layoutDirection = "column",
                children={
                    
                }
            }
        }
    }
    local processorsObj = toolkit.createUIFromTable(processorsArea,processorslayoutTable)

    createProcessorList(processorsObj.processorsList,processorsObj.processorsDetailLayout)
    processorsObj.RefeshProcessorsListButton:onClickUp(function()
        createProcessorList(processorsObj.processorsList,processorsObj.processorsDetailLayout)
    end)
    processorsObj.AddProcessorButton:onClickUp(function()
        createProcessorCreationPopup(container)
    end)



    -- updater area  ##################################################
    local updaterArea = mainTaged.addPage("updaterArea",colors.lightGray)
    updaterArea:setLayoutAlignItems("stretch")
    local updaterlayoutTable = {
        type = "split",
        background = colors.lightGray,
        baseDraw = true,
        BgSymbol = "\127",
        border = colors.gray,
        splitDirection = "row",
        splitNum = 2,
        childGrow = {1, 4},
        childShrink = {1, 4},
        childNames = {nil, "updaterDetailLayout"},
        layoutGap = 0,
        splitChildren = {
            {
                --border = colors.black,
                layoutPadding = {1,1,0,1},
                layoutAlignItems = "stretch",
                layoutDirection = "column",
                children = {
                    {
                        type = "Label",
                        text = "Updater Bindings:",
                    },
                    {
                        type = "Button",
                        text = "Refesh",
                        name = "RefeshUpdaterListButton",
                    },
                    {
                        type = "Button",
                        text = "Add Updater Binding",
                        name = "AddUpdaterBindingButton",
                    },
                    {
                        type = "Label",
                        text = "Update Interval(s):",
                    },
                    {
                        type = "Slider",
                        name = "updateTimeSlider",
                        minValue = 0.1,
                        maxValue = 10,
                        value = IPAS.updateTime,
                    },
                    {
                        type = "List",
                        name = "updaterList",
                        flexGrow = 1,
                    }
                }
            },
            {
                --border = colors.black,
                layoutPadding = 1,
                layoutAlignItems = "stretch",
                layoutDirection = "column",
                children = {
                    
                }
            }
        }
    }

    local updaterObj = toolkit.createUIFromTable(updaterArea, updaterlayoutTable)

    -- Display updater binding details
    local function createUpdaterDetail(_container, updaterBinding)
        local updaterDetail = {
            type = "layout",
            layoutDirection = "column",
            layoutAlignItems = "stretch",
            layoutGap = 1,
            layoutPadding = 1,
            flexGrow = 1,
            name = "updaterDetail",
            children = {
                {
                    type = "Label",
                    text = "Binding Name:\n" .. updaterBinding.updaterName .. "-" .. updaterBinding.infoName,
                },
                {
                    type = "Pane",
                    background = colors.gray,
                    backgroundSymbol = "\127",
                    height = 1,
                    flexMinHeight = 1,
                },
                {
                    type = "Label",
                    text = "Updater Group:\n" .. updaterBinding.updaterGroupName,
                },
                {
                    type = "Label",
                    text = "Updater Name:\n" .. updaterBinding.updaterName,
                },
                {
                    type = "Label",
                    text = "Bound Info:\n" .. updaterBinding.infoName,
                },
                {
                    type = "Label",
                    flexGrow = 1,
                    text = "Parameters:\n" .. toolkit.tableToString(updaterBinding.params),
                },
                {
                    type = "Button",
                    text = "Delete Binding",
                    background = colors.red,
                    onClick = function()
                        IPAS.updateBindings[updaterBinding.updaterName .. "-" .. updaterBinding.infoName] = nil
                        createUpdaterList(updaterObj.updaterList, IPAS.updateBindings, updaterObj.updaterDetailLayout)
                    end
                }
            }
        }
        
        local updaterDetailObj = toolkit.createUIFromTable(_container, updaterDetail)
        return updaterDetailObj
    end

    -- Create list of updater bindings
    local function createUpdaterList(List, updaterBindings, DetailContainer)
        List:clear()
        for k, v in pairs(IPAS.updateBindings) do
            List:addItem(k)
        end
        
        List:onSelect(function(self, e, value)
            local bindingKey = value.text
            local selected = IPAS.updateBindings[bindingKey]
            if selected then
                DetailContainer:removeChildren()
                createUpdaterDetail(DetailContainer, selected)
            end
        end)
    end

    -- Create updater binding popup
    local function createUpdaterBindingPopup(parent)
        local data = {
            infoName = "",
            updaterGroupName = "",
            updaterName = "",
            params = {}
        }
        
        local popup, content, confirm, cancel = toolkit.createSimpleDialog(parent, "{parent.w/2-10}", "{parent.h/2-5}", 41, 24, "Create Updater Binding", true, true)
        
        -- 创建标记区域以便后续替换UI
        content:setLayoutGap(1):setLayoutPadding({1,1,1,1})
        local infoSelectionArea = content:addLayout():setFlexGrow(0.1):setFlexBasis(2):setFlexMinHeight(2)
        local updaterSelectionArea = content:addLayout():setFlexGrow(0.1):setFlexBasis(2):setFlexMinHeight(2)
        local updaterNameArea = content:addLayout():setFlexGrow(0.1):setFlexBasis(2):setFlexMinHeight(2)
        local parametersArea = content:addLayout():setFlexGrow(0.1):setFlexBasis(3):setFlexMinHeight(3)
        
        -- Info selection
        infoSelectionArea:addLabel():setText("Select Info:"):setBackground(colors.lightGray)
        local infoSelector = createInfosSelectorButton(infoSelectionArea, IPAS.Infos, function(selected, selectedText, selectedArgs)
            data.infoName = selectedArgs[1].name
        end)
        
        -- Updater group selection
        updaterSelectionArea:addLabel():setText("Select Updater Group:"):setBackground(colors.lightGray)
        local updaterGroupDropdown = updaterSelectionArea:addDropdown()
        for k, v in pairs(IPAS.updaters) do
            if type(v) == "table" then
                updaterGroupDropdown:addItem(k)
            end
        end
        
        -- When group is selected, show updater names
        updaterGroupDropdown:onSelect(function(self)
            data.updaterGroupName = self:getValue().text
            
            -- 清空之前的UI
            updaterNameArea:removeChildren()
            parametersArea:removeChildren()
            
            -- 添加新UI
            updaterNameArea:addLabel():setText("Select Updater:"):setBackground(colors.lightGray)
            local updaterNameDropdown = updaterNameArea:addDropdown()
            for k, v in pairs(IPAS.updaters[data.updaterGroupName]) do
                updaterNameDropdown:addItem(k)
            end
            
            updaterNameDropdown:onSelect(function(self)
                data.updaterName = self:getValue().text
                
                -- 清空之前的参数UI
                parametersArea:removeChildren()
                
                -- 添加参数输入
                parametersArea:addLabel():setText("Parameters (comma separated):"):setBackground(colors.lightGray)
                local paramsInput = parametersArea:addInput():onChange(function(self, e, value)
                    -- 智能解析参数：尝试转换为适当的数据类型
                    local rawParams = toolkit.split(value, ",")
                    local processedParams = {}
                    
                    for i, param in ipairs(rawParams) do
                        param = param:match("^%s*(.-)%s*$") -- 去除首尾空格
                        
                        -- 尝试转换为数字
                        local num = tonumber(param)
                        if num then
                            processedParams[i] = num
                        -- 尝试识别布尔值
                        elseif param == "true" then
                            processedParams[i] = true
                        elseif param == "false" then
                            processedParams[i] = false
                        -- 保持为字符串
                        else
                            processedParams[i] = param
                        end
                    end
                    
                    data.params = processedParams
                end)
            end)
        end)
        
        confirm:onClickUp(function()
            if data.infoName ~= "" and data.updaterGroupName ~= "" and data.updaterName ~= "" then
                IPAS.CreateUpdateBinding(data.infoName, data.updaterGroupName, data.updaterName, table.unpack(data.params))
                createUpdaterList(updaterObj.updaterList, IPAS.updateBindings, updaterObj.updaterDetailLayout)
                popup:remove()
            end
        end)
    end

    -- Add update time control
    -- local updateTimeLayout = toolkit.labeledLayout(updaterArea, "Update Interval(s)")
    -- local updateTimeSlider = toolkit.createSliderInput(updateTimeLayout, "", 0.1, 10, IPAS.updateTime, function(value)
    --     IPAS.updateTime = value
    -- end)
    -- updateTimeSlider:setFlexOrder(-1)

    -- Instead, binding the slider from layout table
    updaterObj.updateTimeSlider:onChange(function(self, _, value)
        IPAS.updateTime = value
    end)

    -- Bind button events
    updaterObj.RefeshUpdaterListButton:onClickUp(function()
        createUpdaterList(updaterObj.updaterList, IPAS.updateBindings, updaterObj.updaterDetailLayout)
    end)

    updaterObj.AddUpdaterBindingButton:onClickUp(function()
        createUpdaterBindingPopup(container)
    end)

    -- Initial load of updater list
    createUpdaterList(updaterObj.updaterList, IPAS.updateBindings, updaterObj.updaterDetailLayout)



    --#endregion

    -- frontend area  ##################################################
    local frontendArea = mainTaged.addPage("frontendArea", colors.lightGray)
    frontendArea:setLayoutAlignItems("stretch")
    local frontendLayoutTable = {
        type = "split",
        background = colors.lightGray,
        baseDraw = true,
        BgSymbol = "\127",
        border = colors.gray,
        splitDirection = "row",
        splitNum = 2,
        childGrow = {1, 4},
        childShrink = {1, 4},
        childNames = {nil, "frontendDetailLayout"},
        layoutGap = 0,
        splitChildren = {
            {
                --border = colors.black,
                layoutPadding = {1,1,0,1},
                layoutAlignItems = "stretch",
                layoutDirection = "column",
                children = {
                    {
                        type = "Label",
                        text = "Frontend Display:",
                    },
                    {
                        type = "Button",
                        text = "Refresh",
                        name = "RefreshDisplayItemsButton",
                    },
                    {
                        type = "Button",
                        text = "Add Display Item",
                        name = "AddDisplayItemButton",
                    },
                    {
                        type = "Button",
                        text = "Configure Monitor",
                        name = "ConfigMonitorButton",
                    },
                    {
                        type = "Button",
                        text = "Start Frontend",
                        name = "StartFrontendButton",
                        background = colors.green,
                    },
                    {
                        type = "Button",
                        text = "Stop Frontend",
                        name = "StopFrontendButton",
                        background = colors.red,
                    },
                    {
                        type = "List",
                        name = "displayItemsList",
                        flexGrow = 1,
                    }
                }
            },
            {
                --border = colors.black,
                layoutPadding = 1,
                layoutAlignItems = "stretch",
                layoutDirection = "column",
                children = {
                    
                }
            }
        }
    }

    local frontendObj = toolkit.createUIFromTable(frontendArea, frontendLayoutTable)

    -- 确保前台已初始化
    IPAS.initFrontend(basalt)
    
    -- 绑定前台控制按钮
    frontendObj.StartFrontendButton:onClickUp(function()
        IPAS.startFrontend()
    end)
    
    frontendObj.StopFrontendButton:onClickUp(function()
        IPAS.stopFrontend()
    end)

    -- 显示项详情
    local function createDisplayItemDetail(_container, displayItem)
        local displayItemDetail = {
            type = "layout",
            layoutDirection = "column",
            layoutAlignItems = "stretch",
            layoutGap = 1,
            layoutPadding = 1,
            flexGrow = 1,
            name = "displayItemDetail",
            children = {
                {
                    type = "Label",
                    text = "Display Item ID:\n" .. displayItem.id,
                },
                {
                    type = "Pane",
                    background = colors.gray,
                    backgroundSymbol = "\127",
                    height = 1,
                    flexMinHeight = 1,
                },
                {
                    type = "Label",
                    text = "Info Name:\n" .. displayItem.infoName,
                },
                {
                    type = "Label",
                    text = "Display Name:\n" .. displayItem.displayName,
                },
                {
                    type = "Label",
                    text = "Position: (" .. displayItem.x .. ", " .. displayItem.y .. ")",
                },
                {
                    type = "Label",
                    text = "Width: " .. displayItem.width,
                },
                {
                    type = "Label",
                    text = "Format: " .. displayItem.format,
                },
                {
                    type = "Button",
                    text = "Edit Item",
                    name = "EditDisplayItemButton",
                    background = colors.blue
                },
                {
                    type = "Button",
                    text = "Delete Item",
                    name = "DeleteDisplayItemButton",
                    background = colors.red
                }
            }
        }
        
        local displayItemDetailObj = toolkit.createUIFromTable(_container, displayItemDetail)
        return displayItemDetailObj
    end


    --向前定义
    local createDisplayItemsList
    -- 创建显示项编辑弹窗
    local function createDisplayItemEditPopup(parent, displayItem)
        local popup, content, confirm, cancel = toolkit.createSimpleDialog(parent, "{parent.w/2-15}", "{parent.h/2-10}", 30, 20, "Edit Display Item", true, true)
        
        content:setLayoutGap(1):setLayoutPadding({1,1,1,1})
        
        -- 显示名称
        content:addLabel():setText("Display Name:"):setBackground(colors.lightGray)
        local displayNameInput = content:addInput():setValue(displayItem.displayName)
        
        -- 位置X
        content:addLabel():setText("Position X:"):setBackground(colors.lightGray)
        local xInput = content:addInput():setValue(tostring(displayItem.x)):setInputType("number")
        
        -- 位置Y
        content:addLabel():setText("Position Y:"):setBackground(colors.lightGray)
        local yInput = content:addInput():setValue(tostring(displayItem.y)):setInputType("number")
        
        -- 宽度
        content:addLabel():setText("Width:"):setBackground(colors.lightGray)
        local widthInput = content:addInput():setValue(tostring(displayItem.width)):setInputType("number")
        
        -- 格式
        content:addLabel():setText("Format (eg. %s, %.2f):"):setBackground(colors.lightGray)
        local formatInput = content:addInput():setValue(displayItem.format)
        
        confirm:onClickUp(function()
            displayItem.displayName = displayNameInput:getValue()
            displayItem.x = tonumber(xInput:getValue()) or 1
            displayItem.y = tonumber(yInput:getValue()) or 1
            displayItem.width = tonumber(widthInput:getValue()) or 10
            displayItem.format = formatInput:getValue()
            
            frontendObj.frontendDetailLayout:removeChildren()
            createDisplayItemDetail(frontendObj.frontendDetailLayout, displayItem)
            createDisplayItemsList(frontendObj.displayItemsList, IPAS.frontendConfig.displayItems, frontendObj.frontendDetailLayout)
            popup:remove()
        end)
    end

    -- 显示项列表
    local function createDisplayItemsList(List, displayItems, DetailContainer)
        List:clear()
        for _, item in ipairs(displayItems) do
            List:addItem(item.displayName)
        end
        
        List:onSelect(function(self, e, value)
            local selected = nil
            for _, item in ipairs(IPAS.frontendConfig.displayItems) do
                if item.displayName == value.text then
                    selected = item
                    break
                end
            end
            
            if selected then
                DetailContainer:removeChildren()
                local harvestobj= createDisplayItemDetail(DetailContainer, selected)
                harvestobj.EditDisplayItemButton:onClickUp(function()
                    createDisplayItemEditPopup(container, selected)
                end)
                harvestobj.DeleteDisplayItemButton:onClickUp(function()
                    IPAS.RemoveDisplayItem(selected.id)
                    createDisplayItemsList(frontendObj.displayItemsList, IPAS.frontendConfig.displayItems, frontendObj.frontendDetailLayout)
                end)
            end
        end)
    end

    -- 创建显示项添加弹窗
    local function createDisplayItemAddPopup(parent)
        local popup, content, confirm, cancel = toolkit.createSimpleDialog(parent, "{parent.w/2-15}", "{parent.h/2-10}", 30, 20, "Add Display Item", true, true)
        
        content:setLayoutGap(1):setLayoutPadding({1,1,1,1})
        
        local data = {
            infoName = "",
            displayName = "",
            x = 1,
            y = 3,
            width = 20,
            format = "%s"
        }
        
        -- 信息选择
        content:addLabel():setText("Select Info:"):setBackground(colors.lightGray)
        local infoSelector = createInfosSelectorButton(content, IPAS.Infos, function(selected, selectedText, selectedArgs)
            data.infoName = selectedArgs[1].name
            data.displayName = selectedArgs[1].name
        end)
        
        -- 显示名称
        content:addLabel():setText("Display Name:"):setBackground(colors.lightGray)
        local displayNameInput = content:addInput():onChange(function(self, e, value)
            data.displayName = value
        end)
        
        -- 位置X
        content:addLabel():setText("Position X:"):setBackground(colors.lightGray)
        local xInput = content:addInput():setValue("1"):setInputType("number"):onChange(function(self, e, value)
            data.x = tonumber(value) or 1
        end)
        
        -- 位置Y
        content:addLabel():setText("Position Y:"):setBackground(colors.lightGray)
        local yInput = content:addInput():setValue("3"):setInputType("number"):onChange(function(self, e, value)
            data.y = tonumber(value) or 3
        end)
        
        -- 宽度
        content:addLabel():setText("Width:"):setBackground(colors.lightGray)
        local widthInput = content:addInput():setValue("20"):setInputType("number"):onChange(function(self, e, value)
            data.width = tonumber(value) or 20
        end)
        
        -- 格式
        content:addLabel():setText("Format (eg. %s, %.2f):"):setBackground(colors.lightGray)
        local formatInput = content:addInput():setValue("%s"):onChange(function(self, e, value)
            data.format = value
        end)
        
        confirm:onClickUp(function()
            if data.infoName ~= "" then
                IPAS.AddDisplayItem(data.infoName, data.displayName, data.x, data.y, data.width, data.format)
                createDisplayItemsList(frontendObj.displayItemsList, IPAS.frontendConfig.displayItems, frontendObj.frontendDetailLayout)
                popup:remove()
            end
        end)
    end

    -- 创建监视器配置弹窗
    local function createMonitorConfigPopup(parent)
        local popup, content, confirm, cancel = toolkit.createSimpleDialog(parent, "{parent.w/2-15}", "{parent.h/2-10}", 30, 20, "Configure Monitor", true, true)
        
        content:setLayoutGap(1):setLayoutPadding({1,1,1,1})
        
        local data = {
            monitorName = "terminal",
            items = {}
        }
        
        -- 监视器选择
        content:addLabel():setText("Select Monitor:"):setBackground(colors.lightGray)
        local monitorDropdown = content:addDropdown():addItem("terminal")
        
        -- 查找外部监视器
        for _, name in ipairs(peripheral.getNames()) do
            if peripheral.getType(name) == "monitor" then
                monitorDropdown:addItem(name)
            end
        end
        
        monitorDropdown:onSelect(function(self)
            data.monitorName = self:getValue().text
        end)
        
        -- 创建显示项选择器
        content:addLabel():setText("Select Display Items:"):setBackground(colors.lightGray)
        local itemsContainer = content:addLayout():setLayoutDirection("column"):setLayoutGap(1):setFlexGrow(0.1):setFlexBasis(2):setFlexMinHeight(2)
        
        -- 添加所有显示项的复选框
        local checkboxes = {}
        for _, item in ipairs(IPAS.frontendConfig.displayItems) do
            local checkbox = itemsContainer:addCheckbox():setText(item.displayName)
            checkbox.displayItemId = item.id
            table.insert(checkboxes, checkbox)
        end
        
        confirm:onClickUp(function()
            local selectedItems = {}
            for _, checkbox in ipairs(checkboxes) do
                if checkbox:getValue() then
                    table.insert(selectedItems, checkbox.displayItemId)
                end
            end
            
            IPAS.ConfigureMonitor(data.monitorName, selectedItems)
            popup:remove()
        end)
    end

    -- 初始化显示项列表
    createDisplayItemsList(frontendObj.displayItemsList, IPAS.frontendConfig.displayItems, frontendObj.frontendDetailLayout)
    
    -- 绑定按钮事件
    frontendObj.AddDisplayItemButton:onClickUp(function()
        createDisplayItemAddPopup(container)
    end)
    
    frontendObj.ConfigMonitorButton:onClickUp(function()
        createMonitorConfigPopup(container)
    end)

    frontendObj.RefreshDisplayItemsButton:onClickUp(function()
        createDisplayItemsList(frontendObj.displayItemsList, IPAS.frontendConfig.displayItems, frontendObj.frontendDetailLayout)
    end)



    --#endregion


end