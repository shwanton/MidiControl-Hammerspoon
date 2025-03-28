--------------------------
-- init.lua
--------------------------

local function reloadConfig(files)
  for _, file in pairs(files) do
    if file:sub(-4) == '.lua' then
      hs.reload()
    end
  end
end

-- Toggle console with auto-clear functionality
local function manageConsole()
  local console = hs.appfinder.windowFromWindowTitle("Hammerspoon Console")

  if console and console:isVisible() then
    hs.closeConsole()
  else
    hs.openConsole(true)
  end
end

-- Toggle Hammerspoon console with state awareness
hs.hotkey.bind({ "shift", "cmd" }, "H", manageConsole)

-- Toggle Hammerspoon console with state awareness
hs.hotkey.bind({ "shift", "cmd" }, "L", function()
  local console = hs.appfinder.windowFromWindowTitle("Hammerspoon Console")
  if console then
    hs.console.clearConsole()
  end
end)

hs.hotkey.bind({ "shift", "cmd", "ctrl" }, "R", function()
  hs.reload()
  hs.alert.show("Config loaded")
end)

hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reloadConfig):start()
hs.alert.show("Hammerspoon config loaded")

local MidiController = hs.loadSpoon("MidiController")
MidiController:setLogLevel('error')
local rotocontrolConfig = require("configs.rotocontrol"):createConfig()
MidiController:addControllerConfig(rotocontrolConfig)
MidiController:start()

-- local MidiController = hs.loadSpoon("MidiController")
-- MidiController:setLogLevel('debug')
-- local faderfoxConfig = require("configs/faderfox_uc4"):createConfig()
-- MidiController:addControllerConfig(faderfoxConfig)
-- MidiController:start()
