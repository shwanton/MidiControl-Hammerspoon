# MIDI Controller Configuration for Hammerspoon

## Supported Controllers

- **Melbourne Instruments Roto-Control**
- **FaderFox UC4**

## Supported Applications

### System

- System Volume: Control system audio volume
- System Mute: Toggle system audio mute

### Rekordbox

- Play/Pause: Toggle playback of current track
- Previous Track: Jump to previous track or restart current track
- Next Track: Jump to next track
- Jump Forward: Quick seek forward in current track
- Jump Backward: Quick seek backward in current track
- Launch/Hide: Show or hide the application

## Installation

### Hammerspoon

Hammerspoon is a macOS automation tool that allows you to write Lua scripts to control your system. You can install it using Homebrew:

```bash
brew install --cask hammerspoon
```

### Project Setup

1. Clone this repository to your local machine.
2. Copy the `MidiController.spoon` directory to your Hammerspoon spoons directory. This is typically `~/.hammerspoon/Spoons/`.

## Usage

### Roto-Control

Before you can use the Roto-Control configuration, you need to set up a default mapping of buttons and knobs. This can be done in the Roto-Control software.
Example configuration in `rotocontrol` folder

To use the Roto-Control configuration, you need to add it to your `init.lua` file.
```lua
local MidiController = hs.loadSpoon("MidiController")
local rotocontrolConfig = require("controllers.rotocontrol"):createConfig()

MidiController:addControllerConfig(rotocontrolConfig)
MidiController:start()
```

### Faderfox

```lua
local MidiController = hs.loadSpoon("MidiController")
local faderfoxConfig = require("controllers.faderfox_uc4"):createConfig()

MidiController:addControllerConfig(faderfoxConfig)
MidiController:start()
```
