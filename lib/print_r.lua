return function( t,func_prt,filter,special_char)  
    if func_prt then
       print = func_prt
    end

    local braces = special_char or "{}" --为了避免有时候{}会被当做特殊输入，所以添加可以替换的功能
    local left_brace = string.sub(braces, 1, 1)
    local right_brace = string.sub(braces, 2, 2)

    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    pos = tostring(pos)
                    if (type(val)=="table") then
                        if getmetatable(t)and getmetatable(t)["__tostring"]~=nil then
                            print(indent.."["..pos.."] => "..tostring(t).." "..left_brace)
                        else
                            print(indent.."["..pos.."] => "..left_brace)
                        end
                        
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6)..right_brace)
                    elseif (type(val)=="string") and(filter==nil or filter(val)) then
                        print(indent.."["..pos..'] => "'..val..'"')
                    elseif filter==nil or filter(val) then
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
                local mt = getmetatable(t)
                if mt then
                    print(indent.."__metatable => "..left_brace)
                    sub_print_r(mt, indent..string.rep(" ", string.len("__")+3))
                    print(indent..string.rep(" ", string.len("__")+2)..right_brace)
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        if getmetatable(t)and getmetatable(t)["__tostring"]~=nil then
            print(tostring(t).." "..left_brace)
        else
            print("table "..left_brace)
        end
        sub_print_r(t,"  ")
        print(right_brace)
    else
        sub_print_r(t,"  ")
    end
    print()
end