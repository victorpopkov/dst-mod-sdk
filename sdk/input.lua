----
-- Handles input functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.Input
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local Input = {}

local SDK

--- Helpers
-- @section helpers

local function GetKeyFromConfig(config)
    local key = GetModConfigData(config, SDK.modname)
    return key and (type(key) == "number" and key or _G[key]) or -1
end

--- General
-- @section general

--- Checks if it's a move control.
-- @tparam number control
-- @treturn number
function Input.IsControlMove(control)
    return control == CONTROL_MOVE_UP
        or control == CONTROL_MOVE_DOWN
        or control == CONTROL_MOVE_LEFT
        or control == CONTROL_MOVE_RIGHT
end

--- Adds a config key down handler.
-- @tparam string config
-- @tparam function fn
-- @tparam[opt] boolean can_handle_key
function Input.AddConfigKeyDownHandler(config, fn, can_handle_key)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        TheInput:AddKeyDownHandler(config_key, can_handle_key ~= nil and function()
            if SDK.FrontEnd.CanHandleKey() then
                return fn()
            end
        end or fn)
    end
end

--- Adds a config key handler.
-- @tparam string config
-- @tparam function fn
-- @tparam[opt] boolean can_handle_key
function Input.AddConfigKeyHandler(config, fn, can_handle_key)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        TheInput:AddKeyHandler(function(key, down)
            if key == config_key then
                if can_handle_key ~= nil and SDK.FrontEnd.CanHandleKey() then
                    return fn(down)
                else
                    fn(down)
                end
            end
        end)
    end
end

--- Adds a config key up handler.
-- @tparam string config
-- @tparam function fn
-- @tparam[opt] boolean can_handle_key
function Input.AddConfigKeyUpHandler(config, fn, can_handle_key)
    local config_key = GetKeyFromConfig(config)
    if fn and config_key then
        TheInput:AddKeyUpHandler(config_key, can_handle_key ~= nil and function()
            if SDK.FrontEnd.CanHandleKey() then
                return fn()
            end
        end or fn)
    end
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.Input
function Input._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, Input, "Input")
end

return Input
