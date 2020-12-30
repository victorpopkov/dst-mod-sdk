----
-- Different RPC functionality.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-sdk](https://github.com/victorpopkov/dst-mod-sdk)
--
-- @module SDK.RPC
-- @see SDK
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1
----
local RPC = {}

local SDK

local _SendRPCToServer

--- General
-- @section general

--- Checks if `SendRPCToServer()` is enabled.
-- @treturn boolean
function RPC.IsSendToServerEnabled()
    return _SendRPCToServer == nil
end

--- Disables `SendRPCToServer()`.
--
-- Only affects the `SendRPCToServer()` wrapper function Utils.and leaves the `TheNet:SendRPCToServer()`
-- as is.
function RPC.DisableSendToServer()
    if not _SendRPCToServer then
        _SendRPCToServer = SendRPCToServer
        SendRPCToServer = function() end
        SDK.Debug.String("SendRPCToServer: disabled")
    else
        SDK.Debug.String("SendRPCToServer: already disabled")
    end
end

--- Enables `SendRPCToServer()`.
function RPC.EnableSendToServer()
    if _SendRPCToServer then
        SendRPCToServer = _SendRPCToServer
        _SendRPCToServer = nil
        SDK.Debug.String("SendRPCToServer: enabled")
    else
        SDK.Debug.String("SendRPCToServer: already enabled")
    end
end

--- Actions
-- @section actions

--- Walks to a certain point.
-- @tparam Vector3 pt Destination point
function RPC.WalkToPoint(pt)
    SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, pt.x, pt.z)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
-- @tparam SDK sdk
-- @treturn SDK.RPC
function RPC._DoInit(sdk)
    SDK = sdk
    return SDK._DoInitModule(SDK, RPC, "RPC")
end

return RPC
