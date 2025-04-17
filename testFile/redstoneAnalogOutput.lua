--Basalt configurated installer
local filePath = "/lib/BasaltMaster/init.lua"
--local filePath = "basalt.lua" 
--local filePath = "lib/basalt.lua"
-- if not(fs.exists(filePath))then
--     shell.run("pastebin run ESs1mg7P packed true "..filePath:gsub(".lua", "")) -- this is an alternative to the wget command
-- end

-- toastonrye's example: Redstone Analog Output
local basalt = require(filePath:gsub(".lua", "")) -- here you can change the variablename in any variablename you want default: basalt
local w, h = term.getSize() -- dimensions to use when drawing the sub frame

local main = basalt.createFrame()
 :show()
 :setBackground(colours.blue) -- using colours to easily determine what frame I'm in
 local sub = main:addFrame()
 :setPosition(2,2)
 :setSize(w-2,h-2)
 :setBackground(colours.lightBlue)
 :setZ(-1)

local rFrame = sub:addMovableFrame("redstoneFrame")
 :setPosition(1,1)
 :setSize(25,5)
 :setBackground(colours.red)

-- Redstone Analog Output
local redstoneAnalog = rFrame:addLabel() -- label that displays the value of the slider & Redstone output
 :setPosition(18,3):setText("1")

redstone.setAnalogOutput("left", 1) -- initialize the redstone output to 1, to match the above label

rFrame:addLabel() -- draw a label on the frame
 :setText("Redstone Analog Output")
 :setPosition(1,2)
 
local slider = rFrame:addSlider()
 :setPosition(1,3)
 :setMaxValue(15) -- max value of the slider, default 8. Redstone has 15 levels (16 including 0)
 :setSize(15,1) -- draw the slider to this size, without this redstoneAnalog value can have decimals
local sc = sub:addScrollbar():setPosition(31, 1):setSize(15, 1):setScrollAmount(10):setBarType("horizontal")
 slider:onChange(function(self) -- when the slider value changes, change the Redstone output to match
 redstone.setAnalogOutput("left", tonumber(self:getValue()))
 redstoneAnalog:setText(self:getValue())
 basalt.debug(self:getValue())
end)
sub:addButton()
:setPosition(1, 10)
 :setText("shutdown")
 :onClick(function(self)
 basalt.stopUpdate()
end)
local graphFrame = sub:addMovableFrame()
 :setPosition(1, 9)
 :setSize(45, 11)
 :setBackground(colours.white)
 :setForeground(colours.red)
 graphFrame:addLabel():setText("Graph"):setPosition(1, 1)
local aGraph = graphFrame:addGraph():setMaxValue(15):setPosition(1, 2):setSize(45, 10):setGraphType("line"):setBackground(colours.white):setForeground(colours.red)
aGraph:addDataPoint(3):addDataPoint(5):addDataPoint(7):addDataPoint(9):addDataPoint(11):addDataPoint(3):addDataPoint(1):addDataPoint(15)
local aThread = main:addThread()
aThread:start(function(self)
 while true do
    os.sleep(1)
    aGraph:addDataPoint(math.random(1, 15))
    end
end)
main:addLabel()
 :setText("basalt v"..basalt.getVersion())
    :setPosition(1, "{parent.h-1}")
    :setForeground(colours.red)
    
basalt.autoUpdate()
