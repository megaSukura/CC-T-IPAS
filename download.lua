-- [[ ComputerCraft Repository Downloader (using filelist.txt) ]]
-- Usage:
-- 1. Modify the filelistUrl and repoBaseUrl below to match your repository.
-- 2. Save this script (e.g. as 'getrepo').
-- 3. Run in CC terminal: getrepo

-- ========== Configuration ==========

-- Raw URL of filelist.txt
-- Example: "https://raw.githubusercontent.com/YourUsername/YourRepo/main/filelist.txt"
local filelistUrl = ""

-- Base Raw URL for repository files (must end with slash!)
-- Example: "https://raw.githubusercontent.com/YourUsername/YourRepo/main/"
local repoBaseUrl = ""

-- Local root directory for saving files (empty string "" means CC computer root "/")
-- If you want to download everything to a subdirectory, e.g. "myproject/", set it here
local localBaseDir = "" -- For example, can be set to "my_project/" (ensure trailing slash)

-- ========== Utility Functions ==========
local completion = require "cc.completion"
local input = function(prompt)
    print(prompt)
    local choices = {
        "https://",
        "https://raw.githubusercontent.com/",
        "https://raw.githubusercontent.com/megaSukura/CC-T-IPAS/refs/heads/main/",
        "https://raw.githubusercontent.com/megaSukura/CC-T-IPAS/refs/heads/main/filelist.txt"
    }
    return read(nil,nil,function(text) return completion.choice(text, choices) end,nil)
end

-- Print error message (usually displayed in red)
local function printError(...)
    local oldColor = term.getTextColor()
    term.setTextColor(colors.red)
    print( '[===ERROR===] ' .. ...)
    term.setTextColor(oldColor)
end
-- Ensure directory exists
local function ensureDir(path)
    local parts = {}
    -- Split path by /, handling leading and trailing slashes
    path = path:gsub("^/+", ""):gsub("/+$", "")
    for part in string.gmatch(path, "([^/]+)") do
        table.insert(parts, part)
    end

    -- If path is like "myprogram.lua", no directory creation needed
    -- We only care about directory parts in paths containing /
    if #parts <= 1 and not string.find(path, "/") then
        -- print("Path contains no directories: " .. path)
        return true -- Assume root directory or just a filename
    end

    -- If the path itself is a file, we need to create its parent directory
    -- Remove the last part (filename) to leave only directory structure
    if #parts > 0 then
        if fs.exists(path) and not fs.isDir(path) then
             -- File exists, remove filename part to create its parent directory
             table.remove(parts)
        elseif not fs.exists(path) then
             -- Path doesn't exist, also remove filename part, assuming it's a file path
             table.remove(parts)
        end
    end


    local currentPath = ""
    -- If localBaseDir is not empty and path doesn't start with /, add it in front
    if localBaseDir ~= "" and string.sub(path, 1, 1) ~= "/" then
       currentPath = localBaseDir
       if not fs.exists(currentPath) then
           print("Creating base directory: " .. currentPath)
           fs.makeDir(currentPath)
       elseif not fs.isDir(currentPath) then
           printError("Error: Base path '" .. currentPath .. "' exists but is not a directory!")
           return false
       end
    end


    for i, part in ipairs(parts) do
        -- Build path, handling root directory and subsequent directories
        if currentPath == "" or currentPath == localBaseDir then
            -- If starting from root or baseDir
             if string.sub(path, 1, 1) == "/" and i == 1 and localBaseDir == "" then
                 -- Absolute path, and no base dir
                 currentPath = "/" .. part
             elseif currentPath == "" then
                 -- Relative path, first part
                 currentPath = part
             else
                 -- First part based on baseDir
                 currentPath = currentPath .. part
             end
        else
            currentPath = currentPath .. "/" .. part
        end

        if not fs.exists(currentPath) then
            print("  Creating directory: " .. currentPath)
            local success, err = pcall(fs.makeDir, currentPath)
            if not success then
                printError("  Error: Failed to create directory - " .. (err or "unknown error"))
                return false
            end
        elseif not fs.isDir(currentPath) then
            printError("  Error: '" .. currentPath .. "' exists but is not a directory!")
            return false
        end
    end
    return true
end


-- Download and save a single file
local function downloadAndSaveFile(remotePath, localPath)
    local url = repoBaseUrl .. remotePath
    local targetPath = localBaseDir .. localPath -- Combine base directory and relative path

    print("Downloading: " .. remotePath .. " -> " .. targetPath)

    -- 1. Ensure target directory exists
    if not ensureDir(targetPath) then
        printError("  Failed to create required directories, skipping file: " .. targetPath)
        return false
    end

    -- 2. Make HTTP request
    local response, errorMsg, responseHandle = http.get(url) -- Using new http api style

    -- 3. Handle response
    local success = false
    local content = nil
    if response and type(response) == "table" and response.getResponseCode then -- CC:T / CC 1.80pr1+
        local statusCode = response.getResponseCode()
        if statusCode == 200 then
            content = response.readAll()
            success = true
        else
            printError("  Error: Download failed (HTTP Status: " .. statusCode .. ")")
        end
        response.close() -- Always close handle
    elseif type(response) == "string" then -- Compatible with old CC directly returning content
        content = response
        success = true
        print("  (Old HTTP API mode)")
    else
        printError("  Error: HTTP request failed - " .. (errorMsg or "unknown network error"))
        -- Try to close possible handles (even if failed might return)
        if responseHandle and responseHandle.close then pcall(responseHandle.close) end
        if response and response.close then pcall(response.close) end -- Try again
    end

    -- 4. If download successful, save file
    if success and content then
        local file, writeError = fs.open(targetPath, "w")
        if file then
            file.write(content)
            file.close()
            print("  Successfully saved.")
            return true
        else
            printError("  Error: Cannot write to local file '" .. targetPath .. "' - " .. (writeError or "unknown error"))
            return false
        end
    else
        -- Download failure message already printed above
        return false
    end
end

-- ========== Main Logic ==========

-- 0. input filelistUrl and repoBaseUrl if are empty
if filelistUrl == "" or filelistUrl == nil then
    filelistUrl = input("input filelistUrl: ")
end
if repoBaseUrl == "" or repoBaseUrl == nil then
    repoBaseUrl = input("input repoBaseUrl: ")
end
if localBaseDir == "" or localBaseDir == nil then
    localBaseDir = input("input localBaseDir: ")
end

if type(filelistUrl) ~= 'string' or type(repoBaseUrl) ~= 'string' then
    printError("filelistUrl or repoBaseUrl is not a string")
    return
end
print("Starting repository download...")
print("1. Downloading file list: " .. filelistUrl)

-- 1. Download filelist.txt
local listContent = nil
local listResponse, listError = http.get(filelistUrl)
if listResponse and listResponse.getResponseCode then -- CC:T / CC 1.80+
    local status = listResponse.getResponseCode()
    if status == 200 then
        listContent = listResponse.readAll()
    else
        printError("Error: Cannot download file list (HTTP Status: " .. status .. ")")
    end
    listResponse.close()
elseif type(listResponse) == "string" then -- Old version
    listContent = listResponse
else
    printError("Error: Failed to download file list - " .. (listError or "unknown network error"))
end

-- 2. If file list download successful, download each file
if listContent then
    print("File list downloaded successfully, starting processing...")
    local filesToDownload = {}
    for line in string.gmatch(listContent, "[^\r\n]+") do
        -- Remove possible leading/trailing whitespace
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            table.insert(filesToDownload, line)
        end
    end

    print("Found " .. #filesToDownload .. " files to download.")
    local successCount = 0
    local failCount = 0
    local failFiles = {}
    for i, filePath in ipairs(filesToDownload) do
        print(i .. "/" .. #filesToDownload)
        -- print(i .. "/" .. #filesToDownload) -- Use this line if Sprintf is not available
        if downloadAndSaveFile(filePath, filePath) then -- Default remote path and local path are the same
            successCount = successCount + 1
        else
            failCount = failCount + 1
            table.insert(failFiles, filePath)
        end
        sleep(0.1) -- Brief pause to avoid too rapid requests (optional)
    end

    print("\nDownload complete!")
    print("Success: " .. successCount)
    print("Failed: " .. failCount)
    if failCount > 0 then
        print("\nFailed files:")
        for _, filePath in ipairs(failFiles) do
            print("  " .. filePath)
        end
    end

else
    print("Cannot continue because file list download failed.")
end
