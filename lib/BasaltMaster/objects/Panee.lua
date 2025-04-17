return function(name, basalt)
    -- Panee
    local base = basalt.getObject("VisualObject")(name, basalt)
    base:setType("Panee")

    base:setSize(25, 10)
    --变色
    local object = {
        start = function(self,time,thread,color1,color2)
            color1 = color1 or self:getBackground()
            color2 = color2 or colors.nothing
            thread:start(function()
                while true do
                    os.sleep(time)
                    base:setBackground(color1)
                    os.sleep(time)
                    base:setBackground(color2)
                end
            end)
            return thread
        end
}
    
    object.__index = object
    return setmetatable(object, base)
end