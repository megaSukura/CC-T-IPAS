local utils = require("utils")
local tHex = require("tHex")

return function(name, basalt)
    -- Button
    local base = basalt.getObject("VisualObject")(name, basalt)
    base:setType("Button")

    base:setSize(12, 3)
    base:setZ(5)

    base:addProperty("text", "string", "Button", false,function (self, value)
        if value:len() > self:getWidth() then
            self:setWidth(value:len()+2)
        end
    end)
    base:addProperty("textHorizontalAlign", {"left", "center", "right"}, "center")
    base:addProperty("textVerticalAlign", {"left", "center", "right"}, "center")
    base:combineProperty("textAlign", "textHorizontalAlign", "textVerticalAlign")

    local _originalColor = {}
    base:onClick(function(self)
        if _originalColor[1]==nil then
        _originalColor = {self:getBackground(), self:getForeground()}
        end
        self:setBackground(colors.black)
        self:setForeground(colors.lightGray)
    end)
    base:onClickUp(function(self)
        self:setBackground(_originalColor[1])
        self:setForeground(_originalColor[2])
        
    end)
    base:onLoseFocus(function(self)
        self:setBackground(_originalColor[1])
        self:setForeground(_originalColor[2])
        
    end)

    local object = {
        getBase = function(self)
            return base
        end,

        draw = function(self)
            base.draw(self)
            self:addDraw("button", function()
                local w,h = self:getSize()
                local textHorizontalAlign = self:getTextHorizontalAlign()
                local textVerticalAlign = self:getTextVerticalAlign()
                local verticalAlign = utils.getTextVerticalAlign(h, textVerticalAlign)
                local text = self:getText()
                local xOffset
                if(textHorizontalAlign=="center")then
                    xOffset = math.floor((w - text:len()) / 2)
                elseif(textHorizontalAlign=="right")then
                    xOffset = w - text:len()
                end

                self:addText(xOffset + 1, verticalAlign, text)
                self:addFg(xOffset + 1, verticalAlign, tHex[self:getForeground() or colors.white]:rep(text:len()))
            end)
        end,
    }
    object.__index = object
    return setmetatable(object, base)
end