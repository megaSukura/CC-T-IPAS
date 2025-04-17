--测试".."对含有"{}"的表的输出
local value = {
    a = 1,
    b = 2,
    c = 3
}
local  str = "*"
print_table(value,function(line)
    if not line then
        str = str .. "\n"
    else
        str = str .. line .. "\n"
    end
end)
error(str)