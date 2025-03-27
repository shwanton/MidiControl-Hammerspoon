--- === Midi Device ===
---
--- MIDI controller support for Hammerspoon
---
--- Provides a framework for handling MIDI controller input and output in Hammerspoon.
--- Supports configurable MIDI channels, control change handlers, and utility functions
--- for MIDI value conversion and debouncing.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Midi Controller"
obj.version = "0.0.1"
obj.author = "Shawn Dempsey"
obj.homepage = "https://github.com/shwanton/hammerspoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- Midi.logger
obj.logger = hs.logger.new('Midi Controller')
obj.logger.setLogLevel('debug')

-- Internal state
obj._device = nil
obj._config = nil
obj._lastUpdateTime = 0
obj._debounceDelay = 0.5 -- 500 milliseconds

--- Midi.utils
obj.utils = {
    --- Midi.utils.percentageToMidi(percentage) -> number
    --- Function
    --- Convert a percentage value (0-100) to MIDI value (0-127)
    ---
    --- Parameters:
    ---  * percentage - A number between 0 and 100
    ---
    --- Returns:
    ---  * A number between 0 and 127
    percentageToMidi = function(percentage)
        return math.floor((percentage / 100) * 127)
    end,
    --- Midi.utils.midiToPercentage(midiValue) -> number
    --- Function
    --- Convert a MIDI value (0-127) to percentage (0-100)
    ---
    --- Parameters:
    ---  * midiValue - A number between 0 and 127
    ---
    --- Returns:
    ---  * A number between 0 and 100
    midiToPercentage = function(midiValue)
        return math.floor((midiValue / 127) * 100)
    end,
    --- Midi.utils.debounce(handler, delay) -> function
    --- Function
    --- Debounce a function call to prevent it from executing too frequently
    ---
    --- Parameters:
    ---  * handler - The function to debounce
    ---  * delay - The delay in seconds before the function can be called again
    ---
    --- Returns:
    ---  * A debounced function
    debounce = function(handler, delay)
        delay = delay or obj._debounceDelay
        local timer
        return function(...)
            local args = table.pack(...)
            if timer then timer:stop() end
            timer = hs.timer.doAfter(delay, function()
                handler(table.unpack(args, 1, args.n))
            end)
        end
    end
}

--- Midi:init()
--- Method
--- Initialize the MIDI controller
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Midi object
function obj:init()
    self._device = nil
    self._config = nil
    self.logger = hs.logger.new('Midi')
    self.logger.d("MIDI Devices:\n" .. hs.inspect(hs.midi.devices()))
    return self
end

--- Midi:setLogLevel(level)
--- Method
--- Set the log level for the MIDI controller
---
--- Parameters:
---  * level - The log level to set (debug, info, warn, error)
---
--- Returns:
---  * None
function obj:setLogLevel(level)
    self.logger.setLogLevel(level)
end

--- Midi:_handleControlChange(midiMessage, config)
--- Function
--- Internal handler for MIDI control change messages
---
--- Parameters:
---  * midiMessage - A table containing the MIDI message:
---    * channel - The MIDI channel (1-16)
---    * ccNumber - The control change number
---    * ccValue - The control change value (0-127)
---  * config - The config object for this device
---
--- Returns:
---  * Void
function obj:_handleControlChange(midiMessage, config)
    if midiMessage.channel ~= (config.channel) then
        self.logger.e("Channel does not match config channel")
        return
    end

    local ccHandler = config.ccHandlers[midiMessage.ccNumber]
    if ccHandler then
        ccHandler(self, midiMessage.ccValue)
    end
end

--- Midi:addControllerConfig(config)
--- Method
--- Add a configuration for a MIDI controller
---
--- Parameters:
---  * config - A table containing the MIDI configuration:
---    * name - Name of the MIDI device
---    * channel - (optional) MIDI channel to use (1-16, defaults to 1)
---    * handlers - Table of CC handlers
---    * setInitialValues - (optional) Table of initial CC values
---
--- Returns:
---  * None
function obj:addControllerConfig(config)
    if not config.name then
        self.logger.e("Configuration missing device name")
        return
    end
    self._config = config

    self.logger.i("MIDI Control Loaded: " .. config.name)
end

--- Midi:sendControlChange(midiMessage, deviceName)
--- Method
--- Send a MIDI CC message to a specific device
---
--- Parameters:
---  * midiMessage - A table containing the MIDI message:
---    * channel - MIDI channel (1-16)
---    * ccNumber - The CC number to send
---    * value - The value to send (0-127)
---  * deviceName - Name of the device to send to
---
--- Returns:
---  * None
function obj:sendControlChange(midiMessage)
    if not self._device then
        self.logger.e("No MIDI device found")
        return
    end
    self._device:sendCommand("controlChange", {
        controllerNumber = midiMessage.ccNumber,
        controllerValue = midiMessage.ccValue,
        channel = midiMessage.channel - 1 -- MIDI channels are 1-16, but Hammerspoon uses 0-15
    })
    self.logger.d("Sent CC: " .. hs.inspect(midiMessage))
end

--- Midi:start()
--- Method
--- Start MIDI control with all registered configurations
---
--- Parameters:
---  * None
---
--- Returns:
---  * void
function obj:start()
    if not self._config then
        self.logger.e("No MIDI configurations provided")
        return
    end

    self._device = hs.midi.new(self._config.name)
    if not self._device then
        self.logger.e("Failed to create MIDI device: " .. self._config.name)
        return
    end

    -- Create a closure to capture self
    self._device:callback(function(object, deviceName, commandType, description, metadata)
        if metadata.data == 'f8' then -- ignore clock messages
            return
        end

        if deviceName ~= self._config.name then
            self.logger.e("Device name does not match config name")
            return
        end

        self.logger.d(self._config.name .. " callback: " .. hs.inspect(metadata))

        if commandType == "controlChange" then
            local channel = metadata.channel + 1 -- MIDI channels are 1-16, but Hammerspoon uses 0-15
            local message = {
                channel = channel,
                ccNumber = metadata.controllerNumber,
                ccValue = metadata.controllerValue,
            }
            self.logger.d("Receive CC: " .. hs.inspect(message))
            local ccHandler = self._config.ccHandlers[message.ccNumber]
            if ccHandler then
                ccHandler(self, message)
            end
        end
    end)

    if self._config.initialTx then
        for ccNumber, txHandler in pairs(self._config.initialTx) do
            local message = {
                channel = self._config.channel,
                ccNumber = ccNumber,
                ccValue = 0,
            }
            self.logger.d("Intial Transmit: " .. hs.inspect(message))
            txHandler(self, message)
        end
    end

    self.logger.i("MIDI Device Started: " .. self._config.name)
end

--- Midi:stop()
--- Method
--- Stop MIDI control and cleanup
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:stop()
    if self._device then
        self._device:callback(nil)
    end
    self.logger.i("MIDI Control stopped for: " .. self._config.name)
end

return obj
