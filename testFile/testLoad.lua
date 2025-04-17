B = {200}
local up = function()
    B[1] = B[1] + 1
    return B
end
print(load(
[[
    print(5)
    local t=up()
    t[1]=t[1]+1
    
]]
, "test", "t", {print=print,up=up})())
print(B[1])