# MIDI Controller Configuration for Hammerspoon

## Hammerspoon Installation

[Hammerspoon](https://www.hammerspoon.org) is a macOS automation tool that allows you to write Lua scripts to control your system.

You can install Hammerspoon in two ways:

1. [Download the latest release](https://github.com/Hammerspoon/hammerspoon/releases/latest) and drag the application to `/Applications/`

2. Install with Homebrew:

```sh
brew install --cask hammerspoon
```

## Spoon Setup 

Choose one of the following methods to install the MidiController spoon:

### 1. Download the Spoon from GitHub

Download the [zip file](https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives) from this repo and extract it into your Spoons folder at `~/.hammerspoon/Spoons`

### 2. Git checkout with local copy

Clone the repo to your machine
```sh
git clone git@github.com:shwanton/MidiController.spoon.git
```

Copy the cloned repo your Hammerspoon Spoons directory 
```sh
cp MidController.spoon ~/.hammerspoon/Spoons/
```

### 3. Git Submodule in Hammerspoon folder

Clone this repository to your `~/.hammerspoon` folder as a git submodule:
```sh
cd ~/.hammerspoon

git submodule add git@github.com:shwanton/MidiController.spoon.git ./Spoons/MidiController.spoon

git submodule update --init --recursive
```

## Usage

### Controller Configuration

Before using a MIDI controller, you need to set up a CC mapping.
An example midi configuration for the Roto-Setup app is available in the `rotocontrol` folder. 
For the FaderFox UC4, configuration is done on the controller.

#### Roto-Control
```lua
local rotocontrolConfig = require("rotocontrol"):createConfig()
```

#### Faderfox
```lua
local faderfoxConfig = require("faderfox_uc4"):createConfig()
```

### Loading and Starting the Controller

Load the `MidiController` Spoon, pass in your configuration, and start the controller:

```lua
local MidiController = hs.loadSpoon("MidiController")
MidiController:addControllerConfig(rotocontrolConfig)
MidiController:start()
```

## Example `init.lua`

```lua
local function reloadConfig(files)
  for _, file in pairs(files) do
    if file:sub(-4) == '.lua' then
      hs.reload()
    end
  end
end

hs.hotkey.bind({"shift", "cmd", "ctrl"}, "R", function()
  hs.reload()
  hs.alert.show("Config loaded")
end)

hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reloadConfig):start()
hs.alert.show("Hammerspoon config loaded")

local MidiController = hs.loadSpoon("MidiController")
MidiController:setLogLevel('debug')

local rotocontrolConfig = require("rotocontrol"):createConfig()
MidiController:addControllerConfig(rotocontrolConfig)

MidiController:start()
```

## Debugging

Enable debug logging with:
```lua
MidiController:setLogLevel('debug')
```

## Adding Your Own Controller

1. Create a new controller file in the `./controllers` directory
2. The name must match the connected name from this output:
   ```lua
   print(hs.inspect(hs.midi.devices()))
   ```

3. Set the MIDI channel and CC map:
   ```lua
   obj.name = "Faderfox UC4"  -- Exact name from hs.midi.devices()
   obj.id = "ff_uc4"          -- Short identifier for your code
   obj.channel = 2            -- MIDI channel to listen on
   obj.ccMap = {
       SYSTEM_MUTE = 13,      -- CC number for system mute
       SYSTEM_VOLUME = 31,    -- CC number for system volume
   }
   ```

4. Implement your CC handlers:
   ```lua
   ccHandlers = {
       [self.ccMap.SYSTEM_VOLUME] = self.receiveSystemVolume,
       [self.ccMap.SYSTEM_MUTE] = self.receiveSystemMute,
   },
   ```

5. If your device can receive MIDI, initialize CC values to their correct starting values:
   ```lua
   initialTx = {
       [self.ccMap.SYSTEM_VOLUME] = self.transmitSystemVolume,
   },
   ```