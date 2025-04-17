local tHex = require("tHex")
local sub,rep = string.sub,string.rep

return function(drawTerm)
    local terminal = drawTerm or term.current()
    local mirrorTerm
    local width, height = terminal.getSize()
    local cacheT = {}
    local cacheBG = {}
    local cacheFG = {}

    local emptySpaceLine
    local emptyColorLines = {}
    
    local function createEmptyLines()
        emptySpaceLine = rep(" ", width)
        for n = 0, 15 do
            local nColor = 2 ^ n
            local sHex = tHex[nColor]
            emptyColorLines[nColor] = rep(sHex, width)
        end
    end
    ----
    createEmptyLines()

    local function recreateWindowArray()
        createEmptyLines()
        local emptyText = emptySpaceLine
        local emptyFG = emptyColorLines[colors.white]
        local emptyBG = emptyColorLines[colors.black]
        for currentY = 1, height do
            cacheT[currentY] = sub(cacheT[currentY] == nil and emptyText or cacheT[currentY] .. emptyText:sub(1, width - cacheT[currentY]:len()), 1, width)
            cacheFG[currentY] = sub(cacheFG[currentY] == nil and emptyFG or cacheFG[currentY] .. emptyFG:sub(1, width - cacheFG[currentY]:len()), 1, width)
            cacheBG[currentY] = sub(cacheBG[currentY] == nil and emptyBG or cacheBG[currentY] .. emptyBG:sub(1, width - cacheBG[currentY]:len()), 1, width)
        end
    end
    recreateWindowArray()

    local function blit(x, y, t, fg, bg)
        if #t == #fg and #t == #bg then
            if y >= 1 and y <= height then
                if x + #t > 0 and x <= width then
                    local startN = x < 1 and 1 - x + 1 or 1
                    local endN = x + #t > width and width - x + 1 or #t

                    local oldCacheT, oldCacheFG, oldCacheBG = cacheT[y], cacheFG[y], cacheBG[y]
                    if(not t or not fg or not bg)then return end
                    if(not oldCacheT or not oldCacheFG or not oldCacheBG)then return end
                    local newCacheT = sub(oldCacheT, 1, x - 1) .. sub(t, startN, endN)
                    local newCacheFG = sub(oldCacheFG, 1, x - 1) .. sub(fg, startN, endN)
                    local newCacheBG = sub(oldCacheBG, 1, x - 1) .. sub(bg, startN, endN)

                    if x + #t <= width then
                        newCacheT = newCacheT .. sub(oldCacheT, x + #t, width)
                        newCacheFG = newCacheFG .. sub(oldCacheFG, x + #t, width)
                        newCacheBG = newCacheBG .. sub(oldCacheBG, x + #t, width)
                    end

                    cacheT[y], cacheFG[y], cacheBG[y] = newCacheT,newCacheFG,newCacheBG
                end
            end
        end
    end
    
    local function setText(x, y, t)
        if y >= 1 and y <= height then
            if x + #t > 0 and x <= width then
                local newCacheT
                local oldCacheT = cacheT[y] or emptySpaceLine
                local startN, endN = 1, #t

                if x < 1 then
                    startN = 1 - x + 1
                    endN = width - x + 1
                elseif x + #t > width then
                    endN = width - x + 1
                end

                newCacheT = sub(oldCacheT, 1, x - 1) .. sub(t, startN, endN)

                if x + #t <= width then
                    newCacheT = newCacheT .. sub(oldCacheT, x + #t, width)
                end

                cacheT[y] = newCacheT
            end
        end
    end

    local function setBg(x, y, bg)
        if y >= 1 and y <= height then
            if x + #bg > 0 and x <= width then
                local newCacheBG
                local oldCacheBG = cacheBG[y] or emptyColorLines[colors.black]
                local startN, endN = 1, #bg

                if x < 1 then
                    startN = 1 - x + 1
                    endN = width - x + 1
                elseif x + #bg > width then
                    endN = width - x + 1
                end

                newCacheBG = sub(oldCacheBG, 1, x - 1) .. sub(bg, startN, endN)

                if x + #bg <= width then
                    newCacheBG = newCacheBG .. sub(oldCacheBG, x + #bg, width)
                end

                cacheBG[y] = newCacheBG
            end
        end
    end

    local function setFg(x, y, fg)
        if y >= 1 and y <= height then
            if x + #fg > 0 and x <= width then
                local newCacheFG
                local oldCacheFG = cacheFG[y] or emptyColorLines[colors.white]
                local startN, endN = 1, #fg

                if x < 1 then
                    startN = 1 - x + 1
                    endN = width - x + 1
                elseif x + #fg > width then
                    endN = width - x + 1
                end

                newCacheFG = sub(oldCacheFG, 1, x - 1) .. sub(fg, startN, endN)

                if x + #fg <= width then
                    newCacheFG = newCacheFG .. sub(oldCacheFG, x + #fg, width)
                end

                cacheFG[y] = newCacheFG
            end
        end
    end

    local drawHelper = {
        setSize = function(w, h)
            width, height = w, h
            recreateWindowArray()
        end,

        setMirror = function(mirror)
            mirrorTerm = mirror
        end,

        setBg = function(x, y, colorStr)
            setBg(x, y, colorStr)
        end,

        setText = function(x, y, text)
            setText(x, y, text)
        end,

        setFg = function(x, y, colorStr)
            setFg(x, y, colorStr)
        end,

        blit = function(x, y, t, fg, bg)
            blit(x, y, t, fg, bg)
        end,

        drawBackgroundBox = function(x, y, width, height, bgCol)
            local colorStr = rep(tHex[bgCol], width)
            for n = 1, height do
                setBg(x, y + (n - 1), colorStr)
            end
        end,
        drawForegroundBox = function(x, y, width, height, fgCol)
            local colorStr = rep(tHex[fgCol], width)
            for n = 1, height do
                setFg(x, y + (n - 1), colorStr)
            end
        end,
        drawTextBox = function(x, y, width, height, symbol)
            local textStr = rep(symbol, width)
            for n = 1, height do
                setText(x, y + (n - 1), textStr)
            end
        end,

        update = function()
            local xC, yC = terminal.getCursorPos()
            local isBlinking = false
            if (terminal.getCursorBlink ~= nil) then
                isBlinking = terminal.getCursorBlink()
            end
            terminal.setCursorBlink(false)
            if(mirrorTerm~=nil)then mirrorTerm.setCursorBlink(false) end
            for n = 1, height do
                terminal.setCursorPos(1, n)
                -- terminal.blit(cacheT[n], cacheFG[n], cacheBG[n])
                pcall(terminal.blit, cacheT[n], cacheFG[n], cacheBG[n])
                if(mirrorTerm~=nil)then 
                    mirrorTerm.setCursorPos(1, n) 
                    mirrorTerm.blit(cacheT[n], cacheFG[n], cacheBG[n])
                end
            end
            terminal.setBackgroundColor(colors.black)
            terminal.setCursorBlink(isBlinking)
            terminal.setCursorPos(xC, yC)
            if(mirrorTerm~=nil)then 
                mirrorTerm.setBackgroundColor(colors.black)
                mirrorTerm.setCursorBlink(isBlinking)
                mirrorTerm.setCursorPos(xC, yC)
            end
            
        end,

        setTerm = function(newTerm)
            terminal = newTerm
        end,
    }
    return drawHelper
end