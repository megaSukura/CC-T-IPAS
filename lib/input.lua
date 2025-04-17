---@author megaSKR
---@version 1.0.0
---@date 2025-04-18
---@description 一个用于输入的库，支持在任意位置匹配所有选项或指定位置匹配选项


---@param replaceChar string|nil 替换字符
---@param history table|nil 历史记录
---@param matchFunc string|function 匹配函数,如果是字符串则表示匹配函数名,如果是函数则直接使用
---@param choices table|nil 选项列表
---@param default string|nil 默认值
local input = function(replaceChar, history, matchFunc,choices , default)

--- 在任意位置匹配所有选项
---@param choices table 选项列表
---@return function 匹配函数
---example:
--- local msg = read(nil, history, choiceMatchAll({ "apple", "orange", "banana", "strawberry" }), "app")
--- print(msg)
local choiceMatchAll = function(choices)
        local matchFunc= function(text)
        -- 如果输入有空格，则从空格后开始匹配
        local lastSpace = text:find(" [^%s]*$")
        local prefix = ""
        
        if lastSpace then
            prefix = text:sub(1, lastSpace)
            text = text:sub(lastSpace + 1)
        end
        
        -- 查找所有匹配的选项
        local matches = {}
        for _, choice in ipairs(choices) do
            if choice:sub(1, #text) == text then
                -- 添加选项时去除已输入的内容
                table.insert(matches, choice:sub(#text + 1))
            end
        end
        
        return matches
        end
        return matchFunc
    end


--- 在不同位置匹配不同选项
---@param choices table 选项字典
---@return function 匹配函数
---example:
--- local msg = read(nil, history, choiceMatchPos({
---     [1] = { "apple", "orange", "banana", "strawberry" },
---     [2] = { "red", "green", "blue", "yellow" },
---     [3] = { "cat", "dog", "bird", "fish" }
--- }), "app")
--- print(msg)
local choiceMatchPos = function(choices)
    --choices 是一个字典，key为位置，value为选项列表
    return function(text)
        -- 分割输入文本，获取当前位置
        local parts = {}
        for part in string.gmatch(text..(" "), "([^%s]*)%s") do
            table.insert(parts, part)
        end
        
        local position = #parts
        local currentText = parts[position] or ""
        
        -- 如果当前位置没有对应的选项列表，返回空
        if not choices[position] then
            return {}
        end
        
        -- 查找当前位置匹配的选项
        local matches = {}
        for _, choice in ipairs(choices[position]) do
            if choice:sub(1, #currentText) == currentText then
                -- 添加选项时去除已输入的内容
                table.insert(matches, choice:sub(#currentText + 1))
            end
        end
        
        return matches
    end
end
local Func
if matchFunc == 'choiceMatchAll' and choices then
    Func = choiceMatchAll(choices)
elseif matchFunc == 'choiceMatchPos' and choices then
    Func = choiceMatchPos(choices)
elseif type(matchFunc) == 'function' then
    Func = matchFunc
else
    error('matchFunc must be a function or a string')
end

return read(replaceChar, history, Func, default)

end

local inputAll =function(replaceChar, history,choices,default)
    return input(replaceChar, history, 'choiceMatchAll', choices, default)
end

local inputPos =function(replaceChar, history,choices,default)
    return input(replaceChar, history, 'choiceMatchPos', choices, default)
end

return {
    input = input,
    inputAll = inputAll,
    inputPos = inputPos
}