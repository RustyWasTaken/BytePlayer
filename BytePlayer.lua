-- 888888b.            888            8888888b.  888                                    
-- 888  "88b           888            888   Y88b 888                                    
-- 888  .88P           888            888    888 888                                    
-- 8888888K.  888  888 888888 .d88b.  888   d88P 888  8888b.  888  888  .d88b.  888d888 
-- 888  "Y88b 888  888 888   d8P  Y8b 8888888P"  888     "88b 888  888 d8P  Y8b 888P"   
-- 888    888 888  888 888   88888888 888        888 .d888888 888  888 88888888 888     
-- 888   d88P Y88b 888 Y88b. Y8b.     888        888 888  888 Y88b 888 Y8b.     888     
-- 8888888P"   "Y88888  "Y888 "Y8888  888        888 "Y888888  "Y88888  "Y8888  888     
--                 888                                             888                  
--            Y8b d88P                                        Y8b d88P                  
--            "Y88P"                                          "Y88P"                   
-- By ImBadAtNamesLol

local version = "BytePlayer 1.1.6 [Alpha]"
local changelog = [[
Changelog:
- Queue now scrolls properly
- Increased queue list to 8 songs
]]

local s = peripheral.find("speaker")
local current = ""
local song = ""
local artist = ""
local dfpwm = require("cc.audio.dfpwm")
local playlist = {}
local currentSongIndex = 1  -- Track the index of the current song in the playlist

-- Function to load a playlist based on the given filename
local function loadPlaylist(filename)
    local path = fs.combine(shell.dir(), filename)
    if fs.exists(path) then
        local file = fs.open(path, "r")
        local content = file.readAll()
        file.close()

        -- Assuming the playlist is in Lua format (similar to the "playlist" file)
        local success, result = pcall(loadstring(content))
        if success and result and type(result) == "table" and result.playlist then
            return result.playlist
        else
            print("Error loading playlist: " .. filename)
        end
    else
        print("Playlist not found: " .. filename)
    end

    return {}  -- Return an empty playlist if loading fails
end

-- Function to display changelog for a short duration
local function displayChangelog()
    term.clear()
    term.setCursorPos(1, 1)
    print(changelog)
    sleep(1)  -- Display changelog for 1 second
    term.clear()
end

-- Display changelog before running
displayChangelog()

-- Prompt the user to input a file name
print("Enter the playlist file name:")
local filename = read()

-- Load the playlist based on the provided file name
playlist = loadPlaylist(filename)

-- Function to play the selected song
function playSelectedSong(selectedIndex)
    local selected = playlist[selectedIndex]
    if selected then
        song = selected["title"]
        artist = selected["artist"]
        current = selected["url"]
        local data, err = http.get(current, nil, true)
        if data then
            local decoder = dfpwm.make_decoder()
            while true do
                local chunk = data.read(16 * 1024)
                if not chunk then
                    break
                end

                local buffer = decoder(chunk)
                while not s.playAudio(buffer) do
                    os.pullEvent("speaker_audio_empty")
                end
            end
            current = ""  -- Reset the 'current' variable after playing the selected song
        else
            printError("Error getting data for song: " .. song)
            printError("Error details: " .. tostring(err))
        end
    end
end

-- Function to play the current playlist
function music()
    while true do
        for i = currentSongIndex, #playlist do
            local v = playlist[i]

            if v and v["title"] and v["artist"] and v["url"] then
                song = v["title"]
                artist = v["artist"]
                current = v["url"]

                local data, err = http.get(current, nil, true)

                if data then
                    local decoder = dfpwm.make_decoder()

                    while true do
                        local chunk = data.read(16 * 1024)

                        if not chunk then
                            break
                        end

                        local buffer = decoder(chunk)

                        while not s.playAudio(buffer) do
                            os.pullEvent("speaker_audio_empty")
                        end
                    end

                    current = ""
                else
                    printError("Error getting data for song: " .. song)
                    printError("Error details: " .. tostring(err))
                end
            else
                printError("Error loading song at index " .. i)
            end

            currentSongIndex = i + 1  -- Move to the next song after playing the current one

            if currentSongIndex > #playlist then
                currentSongIndex = 1  -- Restart playlist after reaching the end
            end
        end
    end
end

function display()
    term.setTextColor(colors.gray)  -- Text color
    term.setBackgroundColor(colors.lightGray)  -- Background color
    term.setCursorBlink(false)

    local screenWidth, screenHeight = term.getSize()
    local maxDisplaySongs = 9  -- Maximum number of songs to display at a time
    local scrollOffset = 0  -- Variable to track the scrolling offset
    local scrollThreshold = 3  -- Start scrolling at the third song

    while true do
        term.clear()

        local xPosition = screenWidth - string.len(version) + 1
        term.setCursorPos(xPosition, 1)
        term.write(version)

        if current then
            -- Center the song and artist 7/8 down
            local xPositionSong = math.floor((screenWidth - string.len(song)) / 2) + 1
            local yPositionSong = math.floor(screenHeight * 7 / 8) - 1
            term.setCursorPos(xPositionSong, yPositionSong)
            term.write(song)

            local xPositionArtist = math.floor((screenWidth - string.len(artist)) / 2) + 1
            local yPositionArtist = math.floor(screenHeight * 7 / 8)
            term.setCursorPos(xPositionArtist, yPositionArtist)
            term.write(artist)
        else
            term.setCursorPos(1, math.floor(screenHeight * 7 / 8) - 1)
            term.write("Nothing is playing")
        end

        -- Display the queue in the center of the screen
        local queueText = "Queue"
        local xPositionQueue = math.floor((screenWidth - string.len(queueText)) / 2)
        local yPositionQueue = math.floor(screenHeight / 3) - 3  -- Adjust this value to raise the queue

        term.setCursorPos(xPositionQueue, yPositionQueue)
        term.write(queueText)

        local startDisplayIndex = currentSongIndex
        local endDisplayIndex = currentSongIndex + maxDisplaySongs - 1

        for i = startDisplayIndex, endDisplayIndex do
            local displayIndex = i - startDisplayIndex + 1  -- Use startDisplayIndex instead of scrollOffset

            if displayIndex >= 1 and displayIndex <= maxDisplaySongs then
                local title = playlist[i].title .. " | " .. playlist[i].artist
                local xPositionTitle = xPositionQueue + math.floor((string.len(queueText) - string.len(title)) / 2) + 1
                local yPositionTitle = yPositionQueue + displayIndex

                term.setCursorPos(xPositionTitle, yPositionTitle)

                if i == currentSongIndex then
                    term.setTextColor(colors.white)
                    term.setBackgroundColor(colors.gray)
                    term.write("> " .. title .. " ")
                else
                    term.setTextColor(colors.gray)
                    term.setBackgroundColor(colors.lightGray)
                    term.write("  " .. title .. " ")
                end
            end
        end

        -- Adjust scroll offset based on the current song index
        if currentSongIndex >= scrollThreshold then
            scrollOffset = currentSongIndex - scrollThreshold
        else
            scrollOffset = 0
        end

        term.setTextColor(colors.gray)  -- Reset text color for the rest of the screen
        term.setBackgroundColor(colors.lightGray)  -- Reset background color for the rest of the screen
        sleep(0.5)  -- Adjusted sleep time
    end
end

-- Main function to orchestrate everything
function main()
    parallel.waitForAll(music, display)
end

-- Initialize and run the program
main()
