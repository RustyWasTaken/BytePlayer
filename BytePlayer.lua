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

local version = "BytePlayer 1.1.3 [Alpha]"
local changelog = [[
Changelog:
- Added playlist selection based on user input
- Prompt user for playlist file name
- Display changelog for 1 second before running
- Added functional queue
- Added auto replay function
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
        local data = http.get(current, nil, true)
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
        end
    end
end

-- Function to play the current playlist
function music()
    while true do
        for i = currentSongIndex, #playlist do
            local v = playlist[i]
            song = v["title"]
            artist = v["artist"]
            current = v["url"]
            local data = http.get(current, nil, true)
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
            end
            currentSongIndex = i + 1  -- Move to the next song after playing the current one
        end
        currentSongIndex = 1  -- Restart playlist after reaching the end
        sleep()
    end
end

-- Function to display the playlist and user interface
function display()
    term.setTextColor(colors.gray)  -- Text color
    term.setBackgroundColor(colors.lightGray)  -- Background color
    term.setCursorBlink(false)

    local screenWidth, screenHeight = term.getSize()
    local maxDisplaySongs = 13  -- Maximum number of songs to display at a time

    while true do
        term.clear()

        local xPosition = math.floor(screenWidth / 2) - math.floor(string.len(version) / 2) + 1
        term.setCursorPos(xPosition, 1)
        term.write(version)

        -- Display the queue in the middle of the screen
        local queueText = "Queue:"
        local xPositionQueue = math.floor((screenWidth - string.len(queueText)) / 2)
        local yPositionQueue = math.floor(screenHeight / 2) - math.floor(maxDisplaySongs / 2) + 1

        term.setCursorPos(xPositionQueue, yPositionQueue)
        term.write(queueText)

        local middleSongIndex = math.floor(currentSongIndex + maxDisplaySongs / 2)

        for i = middleSongIndex - math.floor(maxDisplaySongs / 2), middleSongIndex + math.floor(maxDisplaySongs / 2) do
            -- Check if the index is within the valid range
            if i >= 1 and i <= #playlist then
                local title = playlist[i].title .. " | " .. playlist[i].artist
                local xPositionTitle = xPositionQueue + math.floor((string.len(queueText) - string.len(title)) / 2) + 1
                local yPositionTitle = yPositionQueue + i - middleSongIndex + 1
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

        if current then
            -- Center the song and artist above the queue
            local xPositionSong = math.floor(screenWidth / 2) - math.floor(string.len(song) / 2) + 1
            local yPositionSong = yPositionQueue - 2
            term.setCursorPos(xPositionSong, yPositionSong)
            term.write(song)

            local xPositionArtist = math.floor(screenWidth / 2) - math.floor(string.len(artist) / 2) + 1
            local yPositionArtist = yPositionSong + 1
            term.setCursorPos(xPositionArtist, yPositionArtist)
            term.write(artist)
        else
            term.setCursorPos(1, yPositionQueue + maxDisplaySongs + 2)
            term.write("Nothing is playing")
        end

        term.setTextColor(colors.gray)  -- Reset text color for the rest of the screen
        term.setBackgroundColor(colors.lightGray)  -- Reset background color for the rest of the screen
        sleep()
    end
end

-- Main function to orchestrate everything
function main()
    parallel.waitForAll(music, display)
end

-- Initialize and run the program
main()
