# MIDI Controller Configuration for Hammerspoon

This project is a Hammerspoon configuration for MIDI controllers

## Supported Controllers

- **Melbourne Instruments Roto-Control**
- **FaderFox UC4**

## Supported Applications

### Rekordbox

The following actions are supported in Rekordbox:

- Play/Pause: Toggle playback of current track
- Previous Track: Jump to previous track or restart current track
- Next Track: Jump to next track
- Jump Forward: Quick seek forward in current track
- Jump Backward: Quick seek backward in current track
- Volume Control: Adjust master volume
- Launch/Hide: Show or hide the application

## Controller Commands

### Roto-Control

The Roto-Control MIDI controller supports the following commands:

- System Mute: Toggle system audio mute
- Rekordbox Play/Pause: Toggle track playback
- Rekordbox Previous Track: Jump to previous track
- Rekordbox Next Track: Jump to next track
- Rekordbox Launch/Hide: Show/hide Rekordbox
- System Volume: Control system audio volume
- Rekordbox Volume: Control Rekordbox master volume
- Rekordbox Jump Back: Seek backward in track
- Rekordbox Jump Forward: Seek forward in track

### Faderfox UC4

The Faderfox UC4 MIDI controller supports the following commands:

- System Mute: Toggle system audio mute
- System Volume: Control system audio volume

## Installation

### Hammerspoon

Hammerspoon is a macOS automation tool that allows you to write Lua scripts to control your system. You can install it using Homebrew:

```bash
brew install --cask hammerspoon
```

### Project Setup

1. Clone this repository to your local machine.
2. Copy the `init.lua` file from the `configs` directory to your Hammerspoon configuration directory. This is typically `~/.hammerspoon/`.
3. Copy the `MidiController.spoon` directory to your Hammerspoon spoons directory. This is typically `~/.hammerspoon/Spoons/`.

## Usage

### Roto-Control

Before you can use the Roto-Control configuration, you need to set up a default mapping of buttons and knobs. This can be done in the Roto-Control software.

To use the Roto-Control configuration, you need to add it to your `init.lua` file. Here's an example of how to do this:

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
