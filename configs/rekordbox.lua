-- Rekordbox configuration for Hammerspoon
-- Provides automation and control for Rekordbox DJ software

local obj = {}

-- Constants
local VOLUME_STEP_SIZE = 10   -- Maximum steps for volume adjustment
local VOLUME_STEP_DELAY = 0.1 -- 100ms between steps
local REKORDBOX_BUNDLE_ID = "com.pioneerdj.rekordboxdj"

-- Logger setup
obj.logger = hs.logger.new('rekordbox')
obj.logger.setLogLevel('debug')

-- Debug alert function
local function debugAlert(message)
    obj.logger.d(message)
end

-- AX element dump function for debugging
local function dumpAX(el, level)
    level = level or 0
    if not el then return end
    local indent = string.rep("  ", level)
    local role = el:attributeValue("AXRole") or "NO ROLE"
    local help = el:attributeValue("AXHelp") or ""
    obj.logger.d(indent .. role .. " / " .. help)

    local children = el:attributeValue("AXChildren")
    if children then
        for _, child in ipairs(children) do
            dumpAX(child, level + 1)
        end
    end
end

local function findElement(el, matcher)
    if not el then return nil end
    if matcher(el) then return el end
    local queue = { el }
    while #queue > 0 do
        local current = table.remove(queue, 1)
        if matcher(current) then return current end
        local children = current:attributeValue("AXChildren")
        if children then
            for _, child in ipairs(children) do
                table.insert(queue, child)
            end
        end
    end
    return nil
end

-- Application state management
local function isAppRunning(bundleID)
    local app = hs.application.get(bundleID)
    return app and app:isRunning()
end

local function isAppHidden(bundleID)
    local app = hs.application.get(bundleID)
    return app and app:isHidden()
end

local function launchOrFocus(bundleID)
    if isAppRunning(bundleID) then
        hs.application.launchOrFocusByBundleID(bundleID)
    else
        debugAlert("Launching " .. bundleID)
        hs.application.launchOrFocusByBundleID(bundleID)
    end
end

local function hideApp(bundleID)
    local app = hs.application.get(bundleID)
    if app and app:isRunning() then
        app:hide()
    end
end

-- Tooltip handling
local function dismissTooltipsWithMouse()
    local win = obj.getWindow()
    if not win then return false end

    local currentPos = hs.mouse.absolutePosition()
    local winFrame = win:attributeValue("AXFrame")
    if not winFrame then return false end

    local safeX = winFrame.x + winFrame.w - 20
    local safeY = winFrame.y + 20

    hs.mouse.absolutePosition({ x = safeX, y = safeY })
    hs.timer.usleep(100000) -- 0.1 seconds delay
    hs.eventtap.leftClick({ x = safeX, y = safeY })

    hs.timer.doAfter(0.15, function()
        hs.mouse.absolutePosition(currentPos)
    end)

    local app = hs.application.get(REKORDBOX_BUNDLE_ID)
    if app then
        app:hide()
        hs.timer.usleep(100000)
        app:activate()
        hs.timer.usleep(100000)
    end

    hs.mouse.absolutePosition(currentPos)
    hs.timer.usleep(100000)

    return true
end

-- Enhanced element finder with tooltip handling
local function findRekordboxElement(win, matcher)
    local result = findElement(win, matcher)
    if result then
        obj.logger.d("Element found without dismissing tooltips.")
        return result
    end

    if not dismissTooltipsWithMouse() then
        obj.logger.d("Failed to dismiss tooltips.")
        return nil
    end

    hs.timer.usleep(100000)
    result = findElement(obj.getWindow(), matcher)
    if result then
        obj.logger.d("Element found after dismissing tooltips.")
        return result
    else
        obj.logger.d("Element not found after dismissing tooltips.")
        return nil
    end
end

-- Window management
function obj.getWindow()
    local app = hs.application.get(REKORDBOX_BUNDLE_ID)
    if not app then
        debugAlert("Rekordbox not running")
        return nil
    end
    local axApp = hs.axuielement.applicationElement(app)
    if not axApp then
        debugAlert("Could not access Rekordbox accessibility element")
        return nil
    end
    local windows = axApp:attributeValue("AXWindows")
    if not windows or #windows == 0 then
        debugAlert("No Rekordbox window")
        return nil
    end
    return windows[1]
end

-- UI element identification
local function isAbletonLinkButton(el)
    if el:attributeValue("AXRole") ~= "AXButton" then
        return false
    end
    local helpText = el:attributeValue("AXHelp") or ""
    return helpText:find("Ableton Link") ~= nil
end

local function validExportWindow()
    local win = obj.getWindow()
    if not win then return nil end

    local linkButton = findElement(win, isAbletonLinkButton)
    debugAlert("Only supported in Export mode")
    if linkButton then return nil end

    return win
end

-- Public API
function obj.launchApp()
    launchOrFocus(REKORDBOX_BUNDLE_ID)
end

function obj.hideApp()
    hideApp(REKORDBOX_BUNDLE_ID)
end

function obj.isAppRunning()
    return isAppRunning(REKORDBOX_BUNDLE_ID)
end

function obj.isAppVisible()
    return not isAppHidden(REKORDBOX_BUNDLE_ID)
end

-- Playback controls
function obj.togglePlayPause()
    local win = validExportWindow()
    if not win then return end

    local function isPlayPauseButton(el)
        return el:attributeValue("AXRole") == "AXButton" and
            el:attributeValue("AXTitle") == "Play/Pause"
    end
    local button = findRekordboxElement(win, isPlayPauseButton)
    if not button then
        debugAlert("Play/Pause button not found")
        return
    end
    button:performAction("AXPress")
    debugAlert("Play/Pause toggled")
end

function obj.prevTrack()
    local win = validExportWindow()
    if not win then return end

    local function isPrevTrackButton(el)
        return el:attributeValue("AXRole") == "AXButton" and
            el:attributeValue("AXHelp") ==
            "Track Search (Backward):\nPlayback returns to the beginning of the track currently playing.\nWhen pressed twice in a row, playback returns to the beginning of the previous track."
    end

    local button = findRekordboxElement(win, isPrevTrackButton)
    if not button then
        debugAlert("Prev Track button not found")
        return
    end
    button:performAction("AXPress")
    debugAlert("Prev Track")
end

function obj.nextTrack()
    local win = validExportWindow()
    if not win then return end

    local function isNextTrackButton(el)
        return el:attributeValue("AXRole") == "AXButton" and
            el:attributeValue("AXHelp") == "Track Search (Forward):\nMove to the beginning of the next track."
    end

    local button = findRekordboxElement(win, isNextTrackButton)
    if not button then
        debugAlert("Next Track button not found")
        return
    end
    button:performAction("AXPress")
    debugAlert("Next Track")
end

function obj.jumpForward()
    local win = validExportWindow()
    if not win then return end

    local function isJumpForwardButton(el)
        return el:attributeValue("AXRole") == "AXButton" and
            el:attributeValue("AXHelp") == "Jump Forward"
    end

    local button = findRekordboxElement(win, isJumpForwardButton)
    if not button then
        debugAlert("Jump Forward button not found")
        return
    end
    button:performAction("AXPress")
end

function obj.jumpBackward()
    local win = validExportWindow()
    if not win then return end

    local function isPrevTrackButton(el)
        return el:attributeValue("AXRole") == "AXButton" and
            el:attributeValue("AXHelp") == "Jump Reverse"
    end

    local button = findRekordboxElement(win, isPrevTrackButton)
    if not button then
        debugAlert("Jump Backward button not found")
        return
    end
    button:performAction("AXPress")
end

-- Volume control
local function findMasterVolumeSlider()
    local win = validExportWindow()
    if not win then return nil end

    local function isMasterVolumeSlider(el)
        if el:attributeValue("AXRole") ~= "AXSlider" then
            return false
        end
        local helpText = el:attributeValue("AXHelp") or ""
        return helpText:find("Master Volume") ~= nil
    end

    local slider = findRekordboxElement(win, isMasterVolumeSlider)
    if not slider then
        debugAlert("Master Volume slider not found")
        return nil
    end
    return slider
end

function obj.getMasterVolume()
    local slider = findMasterVolumeSlider()
    if not slider then
        obj.logger.d("Master Volume slider not found, returning 0")
        return 0
    end
    local value = slider:attributeValue("AXValue")
    if not value then
        obj.logger.d("No volume value found, returning 0")
        return 0
    end
    obj.logger.d("Current Rekordbox volume: " .. value .. "%")
    return value
end

function obj.setVolume(volumeLevel)
    local slider = findMasterVolumeSlider()
    if not slider then
        obj.logger.d("Master Volume slider not found, cannot set volume")
        return
    end
    local currentVolume = slider:attributeValue("AXValue")
    if not currentVolume then
        obj.logger.d("No current volume value found, cannot set volume")
        return
    end

    local delta = volumeLevel - currentVolume
    local absSteps = math.min(math.abs(delta), VOLUME_STEP_SIZE)
    local action = delta > 0 and "AXIncrement" or "AXDecrement"

    obj.logger.d("Setting volume from " .. currentVolume .. "% to " .. volumeLevel .. "%")

    for i = 1, absSteps do
        hs.timer.doAfter((i - 1) * VOLUME_STEP_DELAY, function()
            slider:performAction(action)
        end)
    end
end

return obj
