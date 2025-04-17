

local function layoutObjectPlugin(base, basalt)
    if base._HadFlex then
        return base
    end
    base._HadFlex = true
    local baseWidth, baseHeight = base:getSize()
        base:addProperty("FlexGrow", "number", 0)
        base:addProperty("FlexShrink", "number", 0)
        base:addProperty("FlexBasis", "any","auto",false,nil
        ,function(self, value, parentDir)
            if value == "auto" then
                if parentDir == "row" or parentDir == "row-reverse" then
                    return self:getWidth()
                elseif parentDir == "column" or parentDir == "column-reverse" then
                    return self:getHeight()
                end
                return value
            else
                return value
            end
        end)
        base:addProperty("FlexOrder", "number", 0)

        --0意味着无限制
        base:addProperty("FlexMaxWidth", "number", math.huge,false, function(self, value)
            if value < self:getFlexMinWidth() and value ~= 0 then
                value = self:getFlexMinWidth()
            end
            if value == 0 then
                value = math.huge
            end
            --跟新
            local width, height = self:getSize()
            if width > value then
                self:setSize(value, height, true)
            end
            return value
        end)
        base:addProperty("FlexMaxHeight", "number", math.huge,false, function(self, value)
            if value < self:getFlexMinHeight() and value ~= 0 then
                value = self:getFlexMinHeight()
            end
            if value == 0 then
                value = math.huge
            end
            --跟新
            local width, height = self:getSize()
            if height > value then
                self:setSize(width, value, true)
            end
            return value
        end)
        base:addProperty("FlexMinWidth", "number", 1,false, function(self, value)
            if value > self:getFlexMaxWidth() then
                value = self:getFlexMaxWidth()
            end
            --跟新
            -- local width, height = self:getSize()
            -- if width < value then
            --     self:setSize(value, height, true)
            -- end
            return value
        end)
        base:addProperty("FlexMinHeight", "number", 1,false, function(self, value)
            if value > self:getFlexMaxHeight() then
                value = self:getFlexMaxHeight()
            end
            --跟新
            -- local width, height = self:getSize()
            -- if height < value then
            --     self:setSize(width, value, true)
            -- end
            return value
        end)

    local object = {
        getBaseSize = function(self)
            return baseWidth, baseHeight
        end,

        getBaseWidth = function(self)
            return baseWidth
        end,

        getBaseHeight = function(self)
            return baseHeight
        end,

        setSize = function(self, width, height, rel, internalCall)
            base.setSize(self, width, height, rel)
           if not internalCall then
                baseWidth, baseHeight = base:getSize()
            end
            return self
        end,
    }

    object.__index = object
    return setmetatable(object, base)
end

-----归并排序,因为table.sort是不稳定排序,所以这里自己实现一个稳定排序
function MergeSort(arr, compare)
    local len = #arr
    if len < 2 then
        return arr
    end
    local mid = math.floor(len / 2)
    local left = {}
    local right = {}
    for i = 1, mid do
        table.insert(left, arr[i])
    end
    for i = mid + 1, len do
        table.insert(right, arr[i])
    end
    return Merge(MergeSort(left, compare), MergeSort(right, compare), compare)
end

function Merge(left, right, compare)
    local result = {}
    while #left > 0 and #right > 0 do
        if compare(left[1], right[1]) then
            table.insert(result, table.remove(left, 1))
        else
            table.insert(result, table.remove(right, 1))
        end
    end
    while #left > 0 do
        table.insert(result, table.remove(left, 1))
    end
    while #right > 0 do
        table.insert(result, table.remove(right, 1))
    end
    return result
end

-----
return function(name, basalt)
    -- Layout
    -- 简单的布局,没有wrap即不会换行
    -- 有方向,有间距,有对齐
    -- 会自动调整子元素的位置,大小
    -- 不会主动调整自己的大小
    local base = basalt.getObject("ScrollableFrame")(name, basalt)
    base:setType("Layout")

    local updateLayout = true

    base:addProperty("LayoutDirection", {"row", "column", "row-reverse", "column-reverse"},"row",false, function(self, value)
        updateLayout = true
    end)

    base:addProperty("LayoutJustifyContent", {"flex-start", "flex-end", "center", "space-between", "space-around"},"flex-start",false, function(self, value)
        updateLayout = true
    end)

    base:addProperty("LayoutAlignItems", {"flex-start", "flex-end", "center", "stretch"},"flex-start",false, function(self, value)
        updateLayout = true
    end)

    base:addProperty("LayoutGap", "number", 0,false, function(self, value)
        updateLayout = true
    end)
    -- 间距:上右下左
    base:addProperty("LayoutPadding", "any", {0, 0, 0, 0}, false, function(self, value)
        if type(value) == "number" then
            value = {value, value, value, value}
        elseif type(value) == "table" then
            if #value == 1 then
                value = {value[1], value[1], value[1], value[1]}
            elseif #value == 2 then
                value = {value[1], value[2], value[1], value[2]}
            elseif #value == 4 then
                -- do nothing
            else
                value = {0, 0, 0, 0}
            end
        end
        updateLayout = true
        return value
    end)

    base:addProperty("LayoutSusggestWidth", "number", 1)
    base:addProperty("LayoutSusggestHeight", "number", 1)
    base:combineProperty("LayoutSusggestSize", "LayoutSusggestWidth", "LayoutSusggestHeight")
    base:addProperty("AutoLayout", "boolean", false)-- 自动调整大小,默认关闭

    local function getLayoutPaddingP(self,pos)
        local padding = self:getLayoutPadding()
        local post = { "top" , "right" , "bottom" , "left" }
        if pos then
            if pos == post[1] then
                return padding[1]
            elseif pos == post[2] then
                return padding[2]
            elseif pos == post[3] then
                return padding[3]
            elseif pos == post[4] then
                return padding[4]
            else
                return padding
            end
        else
            return padding
        end
    end

    local children = setmetatable({}, {__mode = "kv"})
    local function orderChildren()
        -- table.sort(children, function(a, b) -- 不稳定排序
        --     return a:getFlexOrder() < b:getFlexOrder()
        -- end)
        children=MergeSort(children, function(a, b) -- 稳定排序
            return a:getFlexOrder() <= b:getFlexOrder()
        end)
    end

    --
    --计算剩余空间
    local function calculateRemainingSpace(self, totalFlexBasis, gap, width, height, direction)
        local remainingSpace = 0
        if direction == "row" or direction == "row-reverse" then
            remainingSpace = width - totalFlexBasis - (gap * (#children - 1)) - self:getLayoutPadding()[2] - self:getLayoutPadding()[4]
        elseif direction == "column" or direction == "column-reverse" then
            remainingSpace = height - totalFlexBasis - (gap * (#children - 1)) - self:getLayoutPadding()[1] - self:getLayoutPadding()[3]
        end
        return remainingSpace
    end
    --

    local function applyLayout(self)
        --basalt:debug("applyLayout")
        local direction = self:getLayoutDirection()
        local justifyContent = self:getLayoutJustifyContent()
        local alignItems = self:getLayoutAlignItems()
        local gap = self:getLayoutGap()
        local width, height = self:getSize()
        local panddingTop=self:getLayoutPadding()[1]
        local panddingRight=self:getLayoutPadding()[2]
        local panddingBottom=self:getLayoutPadding()[3]
        local panddingLeft=self:getLayoutPadding()[4]
        local x, y = 1, 1
        orderChildren()
        --主轴
        --1. 计算总的flex基数
        local totalFlexBasis = 0
        for _, child in ipairs(children) do
            
                local childBasis = child:getFlexBasis(direction)
                if type(childBasis) == "table" then
                    if direction == "row" or direction == "row-reverse" then
                        totalFlexBasis = totalFlexBasis + childBasis[1]
                    elseif direction == "column" or direction == "column-reverse" then
                        totalFlexBasis = totalFlexBasis + childBasis[2]
                    end
                else
                    totalFlexBasis = totalFlexBasis + childBasis
                end
                
        end
        --2. 计算剩余空间
        local remainingSpace = calculateRemainingSpace(self, totalFlexBasis, gap, width, height, direction)
        if remainingSpace < 0 then--如果剩余空间小于0
            
            --3. 计算收缩因子
            local totalShrink = 0
            for _, child in ipairs(children) do
                totalShrink = totalShrink + child:getFlexShrink()
            end
            --4. 计算收缩空间,并调整大小,并调整位置
            local shrinkSpace = - remainingSpace -- 收缩空间:剩余空间的绝对值
            local cursorX ,cursorY = 1, 1
            -- 4.5. 调整游标位置
            if direction == "row" then
                cursorX = cursorX + getLayoutPaddingP(self,"left")
            elseif direction == "column" then
                cursorY = cursorY + getLayoutPaddingP(self,"top")
            elseif direction == "row-reverse" then
                cursorX = cursorX + width - getLayoutPaddingP(self,"right")
            elseif direction == "column-reverse" then
                cursorY = cursorY + height - getLayoutPaddingP(self,"bottom")
            end

            for _, child in ipairs(children) do
                local childFlexShrink = child:getFlexShrink()
                local childFlexBasis = child:getFlexBasis(direction)
                local childWidth, childHeight = child:getSize()
                local childMinWidth, childMinHeight = child:getFlexMinWidth(), child:getFlexMinHeight()
                local childShrinkSpace = ((childFlexShrink / totalShrink) * shrinkSpace)
                
                if totalShrink == 0 then
                    childShrinkSpace = 0
                end
                if direction == "row" or direction == "row-reverse" then
                    --不小于最小宽度
                    if childFlexBasis - childShrinkSpace < childMinWidth then
                        childShrinkSpace = childFlexBasis - childMinWidth
                    end
                    child:setSize(childFlexBasis - childShrinkSpace, childHeight, true)
                    
                elseif direction == "column" or direction == "column-reverse" then
                    --不小于最小高度
                    if childFlexBasis - childShrinkSpace < childMinHeight then
                        childShrinkSpace = childFlexBasis - childMinHeight
                    end
                    child:setSize(childWidth, childFlexBasis - childShrinkSpace, true)
                end
                remainingSpace = remainingSpace + childShrinkSpace
                --调整位置
                childWidth, childHeight = child:getSize()
                if direction == "row"  then
                    child:setPosition(cursorX,1, true) -- 注意这里的1,是因为现在只处理主轴,交叉轴的位置,还没有处理
                    cursorX = cursorX + childWidth+gap
                elseif direction == "column" then
                    child:setPosition(1,cursorY, true)
                    cursorY = cursorY + childHeight+gap
                elseif direction == "row-reverse" then
                    child:setPosition(cursorX-childWidth,1, true)
                    cursorX = cursorX - childWidth-gap
                elseif direction == "column-reverse" then
                    child:setPosition(1,cursorY-childHeight, true)
                    cursorY = cursorY - childHeight-gap
                end
            end

        elseif remainingSpace>=0 then
            --5. 计算增长因子
            local totalGrow = 0
            for _, child in ipairs(children) do
                totalGrow = totalGrow + child:getFlexGrow()
            end
            --6. 计算增长空间,并调整大小,并调整位置
            local growSpace = remainingSpace -- 增长空间
            local cursorX ,cursorY = 1, 1
            -- 6.5. 调整游标位置
            if direction == "row" then
                cursorX = cursorX + getLayoutPaddingP(self,"left")
            elseif direction == "column" then
                
                cursorY = cursorY + getLayoutPaddingP(self,"top")
            elseif direction == "row-reverse" then
                cursorX = cursorX + width - getLayoutPaddingP(self,"right")
            elseif direction == "column-reverse" then
                cursorY = cursorY + height - getLayoutPaddingP(self,"bottom")
            end
            for _, child in ipairs(children) do
                local childFlexGrow = child:getFlexGrow()
                local childFlexBasis = child:getFlexBasis(direction)
                local childWidth, childHeight = child:getSize()
                --childWidth = math.floor(childWidth+0.5)
                --childHeight = math.floor(childHeight+0.5)
                local childMaxWidth, childMaxHeight = child:getFlexMaxWidth(), child:getFlexMaxHeight()
                local childGrowSpace = totalGrow == 0 and 0 or (childFlexGrow / totalGrow) * growSpace
                local n_childGrowSpace = math.floor(childGrowSpace+0.5)
                growSpace = growSpace - (n_childGrowSpace-childGrowSpace)--这里是为了在四舍五入的情况下,保证总增长空间不变
                childGrowSpace= n_childGrowSpace
                if direction == "row" or direction == "row-reverse" then
                    --不大于最大宽度
                    if childFlexBasis + childGrowSpace > childMaxWidth and childMaxWidth ~= 0 then
                        childGrowSpace = childMaxWidth - childFlexBasis
                    end
                    
                    child:setSize(childFlexBasis + childGrowSpace, childHeight, true)
                elseif direction == "column" or direction == "column-reverse" then
                    --不大于最大高度
                    if childFlexBasis + childGrowSpace > childMaxHeight and childMaxHeight ~= 0 then
                        childGrowSpace = childMaxHeight - childFlexBasis
                    end
                    
                    child:setSize(childWidth, childFlexBasis + childGrowSpace, true)
                end
                remainingSpace = remainingSpace - childGrowSpace
                -- 如果剩余空间大于0,则剩余空间按JustifyContent分配
            end
            --增长的位置调整在for外面--
            if remainingSpace == 0 or justifyContent == "flex-start" or justifyContent == "flex-end" or justifyContent == "center" then
                --调整游标位置
                if justifyContent == "flex-start" then
                    -- do nothing
                elseif justifyContent == "flex-end" then
                    --调整游标
                    if direction == "row" then
                        cursorX = cursorX + remainingSpace
                    elseif direction == "column" then
                        cursorY = cursorY + remainingSpace
                    elseif direction == "row-reverse" then
                        cursorX = cursorX - remainingSpace
                    elseif direction == "column-reverse" then
                        cursorY = cursorY - remainingSpace
                    end
                elseif justifyContent == "center" then
                    --调整游标
                    if direction == "row" then
                        cursorX = cursorX + remainingSpace / 2
                    elseif direction == "column" then
                        cursorY = cursorY + remainingSpace / 2
                    elseif direction == "row-reverse" then
                        cursorX = cursorX - remainingSpace / 2
                    elseif direction == "column-reverse" then
                        cursorY = cursorY - remainingSpace / 2
                    end
                    cursorX = math.floor(cursorX+0.5)
                    cursorY = math.floor(cursorY+0.5)
                end
                --调整位置
                for _, child in ipairs(children) do
                    local childWidth, childHeight = child:getSize()
                    --childWidth = math.floor(childWidth+0.5)
                    childHeight = math.floor(childHeight+0.5)
                    if direction == "row"  then
                        child:setPosition(cursorX,1, true) -- 注意这里的1,是因为现在只处理主轴,交叉轴的位置,还没有处理
                        cursorX = cursorX + childWidth+gap
                    elseif direction == "column" then
                        
                        child:setPosition(1,cursorY, true)
                        cursorY = cursorY + childHeight+gap
                        
                    elseif direction == "row-reverse" then
                        child:setPosition(cursorX-childWidth,1, true)
                        cursorX = cursorX - childWidth-gap
                    elseif direction == "column-reverse" then
                        child:setPosition(1,cursorY-childHeight, true)
                        cursorY = cursorY - childHeight-gap
                    end
                end
            
            elseif justifyContent == "space-between" then
                --调整游标位置
                --do nothing
                --调整位置
                local newGap = remainingSpace / (#children - 1)
                for _, child in ipairs(children) do
                    local childWidth, childHeight = child:getSize()
                    if direction == "row"  then
                        child:setPosition(cursorX,1, true) -- 注意这里的1,是因为现在只处理主轴,交叉轴的位置,还没有处理
                        cursorX = cursorX + childWidth+newGap
                    elseif direction == "column" then
                        child:setPosition(1,cursorY, true)
                        cursorY = cursorY + childHeight+newGap
                    elseif direction == "row-reverse" then
                        child:setPosition(cursorX-childWidth,1, true)
                        cursorX = cursorX - childWidth-newGap
                    elseif direction == "column-reverse" then
                        child:setPosition(1,cursorY-childHeight, true)
                        cursorY = cursorY - childHeight-newGap
                    end
                end
            elseif justifyContent == "space-around" then
                --调整游标位置
                local newGapHalf = remainingSpace / (#children * 2) --注意这里是2倍,因为是两边
                if direction == "row"  then
                    cursorX = cursorX + newGapHalf
                elseif direction == "column" then
                    cursorY = cursorY + newGapHalf
                elseif direction == "row-reverse" then
                    cursorX = cursorX - newGapHalf
                elseif direction == "column-reverse" then
                    cursorY = cursorY - newGapHalf
                end
                -- 调整位置
                local newGap = newGapHalf * 2
                for _, child in ipairs(children) do
                    local childWidth, childHeight = child:getSize()
                    if direction == "row"  then
                        child:setPosition(cursorX,1, true) -- 注意这里的1,是因为现在只处理主轴,交叉轴的位置,还没有处理
                        cursorX = cursorX + childWidth+newGap
                    elseif direction == "column" then
                        child:setPosition(1,cursorY, true)
                        cursorY = cursorY + childHeight+newGap
                    elseif direction == "row-reverse" then
                        child:setPosition(cursorX-childWidth,1, true)
                        cursorX = cursorX - childWidth-newGap
                    elseif direction == "column-reverse" then
                        child:setPosition(1,cursorY-childHeight, true)
                        cursorY = cursorY - childHeight-newGap
                    end
                end

            elseif justifyContent == "space-evenly" then
                --调整游标位置
                local newGap = remainingSpace / (#children + 1)
                if direction == "row"  then
                    cursorX = cursorX + newGap
                elseif direction == "column" then
                    cursorY = cursorY + newGap
                elseif direction == "row-reverse" then
                    cursorX = cursorX - newGap
                elseif direction == "column-reverse" then
                    cursorY = cursorY - newGap
                end
                -- 调整位置
                for _, child in ipairs(children) do
                    local childWidth, childHeight = child:getSize()
                    if direction == "row"  then
                        child:setPosition(cursorX,1, true) -- 注意这里的1,是因为现在只处理主轴,交叉轴的位置,还没有处理
                        cursorX = cursorX + childWidth+newGap
                    elseif direction == "column" then
                        child:setPosition(1,cursorY, true)
                        cursorY = cursorY + childHeight+newGap
                    elseif direction == "row-reverse" then
                        child:setPosition(cursorX-childWidth,1, true)
                        cursorX = cursorX - childWidth-newGap
                    elseif direction == "column-reverse" then
                        child:setPosition(1,cursorY-childHeight, true)
                        cursorY = cursorY - childHeight-newGap
                    end
                end
                
                
                
                
            end

        end

        --如果剩余空间仍不为0,计算SuggestSize,注意这里只处理了主轴
        if remainingSpace ~= 0 then
            --basalt:debug("remainingSpace:"..remainingSpace)
            if direction == "row" or direction == "row-reverse" then
                self:setLayoutSusggestSize(width - remainingSpace, height)
            elseif direction == "column" or direction == "column-reverse" then
                self:setLayoutSusggestSize( width, height - remainingSpace)
            end
        else
            self:setLayoutSusggestSize(width, height)
        end



        --交叉轴
        --1.按alignItems调整位置
        local suggestWidth, suggestHeight = self:getLayoutSusggestSize()
        local suggestCrossSize = 0
        if alignItems == "stretch" then
            
            for _, child in ipairs(children) do
                local childWidth, childHeight = child:getSize()
                local childMinWidth, childMinHeight = child:getFlexMinWidth(), child:getFlexMinHeight()
                local childMaxWidth, childMaxHeight = child:getFlexMaxWidth(), child:getFlexMaxHeight()

                if direction == "row" or direction == "row-reverse" then
                    local targetHeight = height - panddingTop - panddingBottom
                    targetHeight = math.min(childMaxHeight, math.max(childMinHeight, targetHeight))
                    child:setSize(childWidth, targetHeight, true)
                    suggestCrossSize = math.max(suggestCrossSize, targetHeight)-- 计算交叉轴的推荐大小
                    --设置位置
                    child:setY(panddingTop+1, true)
                    
                elseif direction == "column" or direction == "column-reverse" then
                    local targetWidth = width - panddingLeft - panddingRight
                    targetWidth = math.min(childMaxWidth, math.max(childMinWidth, targetWidth))
                    child:setSize(targetWidth, childHeight, true)
                    suggestCrossSize = math.max(suggestCrossSize, targetWidth)-- 计算交叉轴的推荐大小
                    --设置位置
                    child:setX(panddingLeft+1, true)
                end
            end
            if direction == "row" or direction == "row-reverse" then
                self:setLayoutSusggestSize(suggestWidth, suggestCrossSize+panddingBottom+panddingTop)
            elseif direction == "column" or direction == "column-reverse" then
                self:setLayoutSusggestSize(suggestCrossSize+panddingLeft+panddingRight, suggestHeight)
            end

        elseif alignItems == "flex-start" then
            --do nothing for size
            --设置位置
            if direction == "row" or direction == "row-reverse" then
                for _, child in ipairs(children) do
                    child:setY(panddingTop+1, true)
                    suggestCrossSize = math.max(suggestCrossSize, child:getHeight()+panddingTop+panddingBottom)
                end
                self:setLayoutSusggestSize(suggestWidth, suggestCrossSize)
            elseif direction == "column" or direction == "column-reverse" then
                for _, child in ipairs(children) do
                    child:setX(panddingLeft+1, true)
                    suggestCrossSize = math.max(suggestCrossSize, child:getWidth()+panddingLeft+panddingRight)
                end
                self:setLayoutSusggestSize(suggestCrossSize, suggestHeight)
            end
        elseif alignItems == "flex-end" then
            --do nothing for size
            --设置位置
            if direction == "row" or direction == "row-reverse" then
                for _, child in ipairs(children) do
                    local childWidth, childHeight = child:getSize()
                    local targetY = height - panddingBottom - childHeight
                    targetY = math.floor(targetY+0.5)
                    child:setY(targetY, true)
                    suggestCrossSize = math.max(suggestCrossSize, child:getHeight()+panddingTop+panddingBottom)
                end
                self:setLayoutSusggestSize(suggestWidth, suggestCrossSize)
            elseif direction == "column" or direction == "column-reverse" then
                for _, child in ipairs(children) do
                    local childWidth, childHeight = child:getSize()
                    local targetX = width - panddingRight - childWidth
                    targetX = math.floor(targetX+0.5)
                    child:setX(targetX, true)
                    suggestCrossSize = math.max(suggestCrossSize, child:getWidth()+panddingLeft+panddingRight)
                end
                self:setLayoutSusggestSize(suggestCrossSize, suggestHeight)
            end
        elseif alignItems == "center" then
            --do nothing for size
            --设置位置
            if direction == "row" or direction == "row-reverse" then
                for _, child in ipairs(children) do
                    local childWidth, childHeight = child:getSize()
                    local targetY = (height + panddingTop - panddingBottom - childHeight+1) / 2
                    targetY = math.max(1,math.floor(targetY+0.5))
                    child:setY(targetY, true)
                    suggestCrossSize = math.max(suggestCrossSize, child:getHeight()+panddingTop+panddingBottom)
                end
                self:setLayoutSusggestSize(suggestWidth, suggestCrossSize)
            elseif direction == "column" or direction == "column-reverse" then
                for _, child in ipairs(children) do
                    local childWidth, childHeight = child:getSize()
                    local targetX = (width + panddingLeft - panddingRight - childWidth+1) / 2
                    targetX = math.max(1,math.floor(targetX+0.5))
                    child:setX(targetX, true)
                    suggestCrossSize = math.max(suggestCrossSize, child:getWidth()+panddingLeft+panddingRight)
                end
                self:setLayoutSusggestSize(suggestCrossSize, suggestHeight)
            end

        end






        --结束
        updateLayout = false
        --自动调整大小
        if self:getAutoLayout() then
            self:applySuggestSize()
            --将自己的最大最小大小设置为推荐大小
            local suggestWidth, suggestHeight = self:getLayoutSusggestSize()
            if suggestWidth~=self:getWidth() or suggestHeight~=self:getHeight() then
                if self.getFlexMaxWidth and self.getFlexMaxHeight then
                    self:setFlexMaxWidth(suggestWidth)
                    self:setFlexMinWidth(suggestWidth)
                    self:setFlexMaxHeight(suggestHeight)
                    self:setFlexMinHeight(suggestHeight)
                    --updateLayout = true
                end
            end
        end
    end

    
    

local isIn = function(t, value)
    for i, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end
    
    local object = {
        
        updateLayout = function(self)
            updateLayout = true
        end,

        applySuggestSize = function(self)
            local w,h = self:getSize()
            local suggestWidth, suggestHeight = self:getLayoutSusggestSize()
            self:setSize(suggestWidth, suggestHeight, true)
            local n_w,n_h = self:getSize()
            if w ~= n_w or h ~= n_h then
                updateLayout = true
            end
        end,

        setCenter = function(self)
            self:setLayoutJustifyContent("center")
            self:setLayoutAlignItems("center")
            return self
        end,

        customEventHandler = function(self, event, ...)
            base.customEventHandler(self, event, ...)
            if event == "basalt_FrameResize" then
                updateLayout = true
            end
        end,

        draw = function(self)
            base.draw(self)
            self:addDraw("flexboxDraw", function()
                if updateLayout then
                    basalt:debug("updateLayout")
                    applyLayout(self)
                end
            end, 1)
        end,

        addChild = function(self, child)
            if child._HadFlex==nil then
                child = layoutObjectPlugin(child, basalt)
                if(isIn(children,child)==false)then
                    table.insert(children, child)
                end
            end
            
            base.addChild(self, child)
            updateLayout = true
            return child
        end,
        removeChild = function(self, child)
            base.removeChild(self, child)
            for i, v in pairs(children) do
                if v == child then
                    table.remove(children, i)
                    child:hide()
                    --collectgarbage("collect")
                    break
                end
            end
            updateLayout = true
            return child
        end,
        removeChildren = function(self)
            base.removeChildren(self)
            children = {}
            updateLayout = true
        end,
}

    for k, _ in pairs(basalt.getObjects()) do
        object["add" .. k] = function(self, name)
            local baseChild = base["add" .. k](self, name)
            
            local child = layoutObjectPlugin(baseChild, basalt)
            -- if(isIn(children,child)==false)then
            --     basalt:debug("2add child:"..child:getName())
            --     table.insert(children, child)
            -- end
            updateLayout = true
            return child
        end
    end

    
    object.__index = object
    return setmetatable(object, base)
end