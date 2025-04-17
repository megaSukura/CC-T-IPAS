local utils = require("utils")
local wrapText = utils.wrapText

return {
    basalt = function(basalt)

        local mainFrame
        local debugFrame
        local debugList
        local debugLabel
        local debugExitButton

        local function createDebuggingFrame()
            --local breakpoint = nil+1
            if(mainFrame==nil)then mainFrame = basalt.getMainFrame() end
            local minW = 16
            local minH = 6
            local maxW = 99
            local maxH = 99
            local w, h = mainFrame:getSize()
            debugFrame = mainFrame:addMovableFrame("basaltDebuggingFrame"):setSize(w-10, h-6):setBackground(colors.black):setForeground(colors.white):setZ(100):hide()
            debugFrame:addPane():setSize("{parent.w}", 1):setPosition(1, 1):setBackground(colors.cyan):setForeground(colors.black)
            debugFrame:setPosition(-w, h/2-debugFrame:getHeight()/2):setBorder(colors.cyan)
            local resizeButton = debugFrame:addButton()
                :setPosition("{parent.w-1}", "{parent.h-1}"):setZ(100)
                :setSize(1, 1)
                :setText("\133")
                :setForeground(colors.black)
                :setBackground(colors.cyan)
                :onClick(function() end)
                :onDrag(function(self, event, btn, xOffset, yOffset)
                    local w, h = debugFrame:getSize()
                    local wOff, hOff = w, h
                    if(w+xOffset-1>=minW)and(w+xOffset-1<=maxW)then
                        wOff = w+xOffset-1
                    end
                    if(h+yOffset-1>=minH)and(h+yOffset-1<=maxH)then
                        hOff = h+yOffset-1
                    end
                    debugFrame:setSize(wOff, hOff)
                end)

            debugExitButton = debugFrame:addButton():setText("Close"):setPosition("{parent.w - 6}", 1):setSize(7, 1):setBackground(colors.red):setForeground(colors.white):onClick(function() 
                debugFrame:animatePosition(-w, h/2-debugFrame:getHeight()/2, 0.5,0,"easeInOutCirc")
            end)
            debugList = debugFrame:addList()
                        :setSize("{parent.w - 3}", "{parent.h - 3}")
                        :setPosition(2, 2)
                        :setBackground(colors.black)
                        :setForeground(colors.white)
                        :setSelectionColor(colors.white, colors.black)
            if(debugLabel==nil)then 
                --breakpoint = nil+1
                debugLabel = mainFrame:addLabel()
                :setPosition(1, "{parent.h-1}")
                :setBackground(colors.black)
                :setForeground(colors.white)
                :setZ(10000)
                :show()
                :onClick(function()
                    debugFrame:show()
                    debugFrame:animatePosition(w/2-debugFrame:getWidth()/2, h/2-debugFrame:getHeight()/2, 0.5,0,"easeInOutCirc")
                end)
                
            end
        end

        return {
            debug = function(...)
                local args = { ... }
                if(mainFrame==nil)then 
                    mainFrame = basalt.getMainFrame() 
                    if(mainFrame~=nil)then
                        createDebuggingFrame()
                    else
                        print(...) return
                    end
                end
                if (mainFrame:getName() ~= "basaltDebuggingFrame") then
                    if (mainFrame ~= debugFrame) then
                        debugLabel:setParent(mainFrame)
                    end
                end
                local str = ""
                for key, value in pairs(args) do
                    str = str .. tostring(value) .. (#args ~= key and ", " or "")
                end
                debugLabel:setText("[Debug] " .. str)
                for k,v in pairs(wrapText(str, debugList:getWidth()))do
                    debugList:addItem(v)
                end
                if (debugList:getItemCount() > 500) then
                    debugList:removeItem(1)
                end
                debugList:setValue(debugList:getItem(debugList:getItemCount()))
                if(debugList.getItemCount() > debugList:getHeight())then
                    debugList:setOffset(debugList:getItemCount() - debugList:getHeight())
                end
                debugLabel:show()
            end
            ,
            saveDebug = function()
                local file = fs.open("debug.txt", "w")
                for i = 1, debugList:getItemCount() do
                    file.writeLine(debugList:getItem(i).text or "")
                end
                file.close()
            end
        }
    end
}