require "busted.runner"()

describe("#sdk SDK.Remote", function()
    -- setup
    local match

    -- before_each initialization
    local SDK
    local Remote

    setup(function()
        match = require "luassert.match"
    end)

    before_each(function()
        -- globals
        _G.TheNet = mock({
            SendRemoteExecute = Empty,
        })

        _G.TheSim = mock({
            GetPosition = Empty,
            ProjectScreenPos = function()
                return 1, 0, 3
            end,
        })

        -- initialization
        SDK = require "sdk/sdk"
        SDK.path = "./"
        SDK.SetIsSilent(true)

        SDK.Utils = require "sdk/utils"
        SDK.Utils._DoInit(SDK)

        Remote = require "sdk/remote"
        Remote._DoInit(SDK)

        -- spies
        Remote.Send = spy.on(Remote, "Send")
        SDK.Debug.String = spy.on(SDK.Debug, "String")
    end)

    teardown(function()
        _G.TheNet = nil
        _G.TheSim = nil
    end)

    local function TestDebugString(fn, ...)
        local args = { ... }
        it("should debug string", function()
            assert.spy(SDK.Debug.String).was_not_called()
            fn()
            assert.spy(SDK.Debug.String).was_called(1)
            assert.spy(SDK.Debug.String).was_called_with(unpack(args))
        end)
    end

    local function TestSendRemoteExecuteWasCalled(fn, ...)
        local args = { ..., 1, 3 }
        it("should call TheSim:SendRemoteExecute()", function()
            assert.spy(_G.TheNet.SendRemoteExecute).was_not_called()
            fn()
            assert.spy(_G.TheNet.SendRemoteExecute).was_called(1)
            assert.spy(_G.TheNet.SendRemoteExecute).was_called_with(
                match.is_ref(_G.TheNet),
                unpack(args)
            )
        end)
    end

    describe("general", function()
        describe("GatherPlayers()", function()
            TestDebugString(function()
                Remote.GatherPlayers()
            end, "[remote]", "Gather players")

            TestSendRemoteExecuteWasCalled(function()
                Remote.GatherPlayers()
            end, "c_gatherplayers()")
        end)

        describe("Rollback()", function()
            describe("when no days are passed", function()
                TestDebugString(function()
                    Remote.Rollback()
                end, "[remote]", "Rollback", "(0 days)")

                TestSendRemoteExecuteWasCalled(function()
                    Remote.Rollback()
                end, "TheNet:SendWorldRollbackRequestToServer(0)")
            end)

            describe("when 1 day is passed", function()
                TestDebugString(function()
                    Remote.Rollback(1)
                end, "[remote]", "Rollback", "(1 day)")

                TestSendRemoteExecuteWasCalled(function()
                    Remote.Rollback(1)
                end, 'TheNet:SendWorldRollbackRequestToServer(1)')
            end)

            describe("when 3 day is passed", function()
                TestDebugString(function()
                    Remote.Rollback(3)
                end, "[remote]", "Rollback", "(3 days)")

                TestSendRemoteExecuteWasCalled(function()
                    Remote.Rollback(3)
                end, "TheNet:SendWorldRollbackRequestToServer(3)")
            end)
        end)

        describe("Send()", function()
            describe("when different data types are passed", function()
                TestSendRemoteExecuteWasCalled(function()
                    Remote.Send('%d, %0.2f, "%s"', { 1, .12345, "test" })
                end, '1, 0.12, "test"')
            end)

            it("should call TheSim:GetPosition()", function()
                assert.spy(_G.TheSim.GetPosition).was_not_called()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                assert.spy(_G.TheSim.GetPosition).was_called(1)
                assert.spy(_G.TheSim.GetPosition).was_called_with(match.is_ref(_G.TheSim))
            end)

            it("should call TheSim:ProjectScreenPos()", function()
                assert.spy(_G.TheSim.ProjectScreenPos).was_not_called()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
                assert.spy(_G.TheSim.ProjectScreenPos).was_called(1)
                assert.spy(_G.TheSim.ProjectScreenPos).was_called_with(match.is_ref(_G.TheSim))
            end)

            TestSendRemoteExecuteWasCalled(function()
                Remote.Send('TheWorld:PushEvent("ms_setseason", "%s")', { "autumn" })
            end, 'TheWorld:PushEvent("ms_setseason", "autumn")')
        end)
    end)
end)
