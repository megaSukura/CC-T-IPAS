return function(name, basalt)
    local base = basalt.getObject("VisualObject")(name, basalt)
    base:setType("ChangeableObject")

    base:addProperty("ChangeHandler", "function", nil)
        local isRaw = false
    base:addProperty("Value", "any", nil, false, function(self, value)
        local _value = self:getValue()
        if (not isRaw and value ~= _value) then
            local valueChangedHandler = self:getChangeHandler()
            if(valueChangedHandler~=nil)then
                valueChangedHandler(self, value)
            end
            self:sendEvent("value_changed", value)
        end

        if isRaw then isRaw=false end
        return value
    end,nil,nil,false)
    local object = {
        onChange = function(self, ...)
            for _,v in pairs(table.pack(...))do
                if(type(v)=="function")then
                    self:registerEvent("value_changed", v)
                end
            end
            return self
        end,
        rawSetValue = function(self, value)
            isRaw = true
            return base:setValue(value)
        end,
    }

    object.__index = object
    return setmetatable(object, base)
end