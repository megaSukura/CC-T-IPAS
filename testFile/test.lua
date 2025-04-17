local basalt = require("lib/basalt")
local w, h = term.getSize()
local main = basalt.createFrame("mainFrame")
local function visualButton(btn)
    btn:onClick(function(self) btn:setBackground(colors.black) btn:setForeground(colors.lightGray) end)
    btn:onClickUp(function(self) btn:setBackground(colors.gray) btn:setForeground(colors.black) end)
    btn:onLoseFocus(function(self) btn:setBackground(colors.gray) btn:setForeground(colors.black) end)
end
--menuBar
if main then
    --
    main:onClick(function(self, button, x, y)
        basalt.debug("mainFrame:onClick " .. button .. " " .. x .. " " .. y)
    end)
    --
    local sheet1 = main:addFrame("sheet1"):setPosition(1, 2):setBackground(colors.lightGray):setSize(w, h - 1)
    local sheet2 = main:addFrame("sheet2"):setPosition(1, 2):setBackground(colors.brown):setSize(w, h - 1):hide()
    local sheet3 = main:addFrame("sheet3"):setPosition(1, 2):setBackground(colors.cyan):setSize(w, h - 1):hide()
    --
    local menuBar = main:addMenubar("mainMenuBar"):
                        addItem("sheet1"):
                        addItem("sheet2"):
                        addItem("sheet3"):
                        setBackground(colors.gray):
                        setSize(w, 1):
                        setSpace(5):
                        setScrollable():
                        show()
                        :onChange(function(self)
                            sheet1:hide()
                            sheet2:hide()
                            sheet3:hide()
                            if self:getValue().text == "sheet1" then
                                    sheet1:show()
                            elseif self:getValue().text == "sheet2" then
                                    sheet2:show()
                            elseif self:getValue().text == "sheet3" then
                                    sheet3:show()
                            end
                        end)
                        sheet1:addPane():setSize("parent.w - 2", 1):setPosition(2, 6):setBackground(false, "\183", colors.purple)
    
    local button_s_1 = sheet1:addButton("button_s_1"):setText("Button"):setSize(12, 3):setPosition(3, 2):onClick(function()
        basalt.debug("Button clicked")
    end):show()
    visualButton(button_s_1)
    
    
    -- sheet2
    sheet2:addPane():setSize("parent.w - 2", 1):setPosition(2,2):setBackground(false, "\183", colors.purple)
    
end

basalt.autoUpdate()