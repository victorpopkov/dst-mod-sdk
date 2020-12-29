require "busted.runner"()

describe("#sdk SDK.PersistentData", function()
    -- setup
    local match

    -- before_each globals (TheWorld)
    local MasterSessionId

    -- before_each initialization
    local SDK
    local PersistentData

    setup(function()
        match = require "luassert.match"
    end)

    teardown(function()
        _G.json = nil
        _G.SavePersistentString = nil
        _G.SDK = nil
        _G.TheSim = nil
        _G.TheWorld = nil
    end)

    before_each(function()
        -- globals
        _G.SavePersistentString = spy.new(Empty)
        _G.json = mock({
            decode = Empty,
            encode = Empty,
        })

        _G.TheSim = mock({
            GetPersistentString = Empty,
        })

        MasterSessionId = "D000000000000000"
        _G.TheWorld = mock({
            net = {
                components = {
                    shardstate = {
                        GetMasterSessionId = ReturnValueFn(MasterSessionId),
                    },
                },
            },
        })

        -- initialization
        SDK = require "sdk/sdk"
        SDK.env = { modname = "dst-mod-sdk" }
        SDK.path = "./"
        SDK.SetIsSilent(true)

        SDK.Debug = require "sdk/debug"
        SDK.Debug._DoInit(SDK)

        SDK.Utils = require "sdk/utils"
        SDK.Utils._DoInit(SDK)

        PersistentData = require "sdk/persistentdata"
        PersistentData._DoInit(SDK)

        -- debug
        SDK.Debug.Error = spy.on(SDK.Debug, "Error")
        SDK.Debug.String = spy.on(SDK.Debug, "String")
    end)

    local function TestDebugErrorNoServerData(fn_name, ...)
        local args = { ... }
        it("should debug error string", function()
            assert.spy(SDK.Debug.Error).was_not_called()
            PersistentData[fn_name](unpack(args))
            assert.spy(SDK.Debug.Error).was_called(1)
            assert.spy(SDK.Debug.Error).was_called_with(
                "[persistent_data]",
                "No server data"
            )
        end)
    end

    local function TestReturnSelf(fn_name, ...)
        local args = { ... }
        it("should return self", function()
            AssertReturnSelf(PersistentData, fn_name, unpack(args))
        end)
    end

    describe("general", function()
        describe("should have a", function()
            describe("getter", function()
                local getters = {
                    data = "GetData",
                    data_original = "GetDataOriginal",
                    mode = "GetMode",
                    name = "GetName",
                    server_expire_time = "GetServerExpireTime",
                    is_dirty = "IsDirty",
                    is_encoded = "IsEncoded",
                }

                for field, getter in pairs(getters) do
                    it(getter .. "()", function()
                        AssertModuleGetter(PersistentData, field, getter)
                    end)
                end
            end)

            describe("setter", function()
                local setters = {
                    is_dirty = "SetIsDirty",
                    is_encoded = "SetIsEncoded",
                    mode = "SetMode",
                    save_name = "SetSaveName",
                    server_expire_time = "SetServerExpireTime",
                }

                for field, setter in pairs(setters) do
                    it(setter .. "()", function()
                        AssertModuleSetter(PersistentData, field, setter, true, nil)
                    end)
                end
            end)
        end)

        describe("Reset()", function()
            before_each(function()
                PersistentData.is_dirty = false
                PersistentData.data = {}
            end)

            it("should set is_dirty to true", function()
                assert.is_false(PersistentData.is_dirty)
                PersistentData.Reset()
                assert.is_true(PersistentData.is_dirty)
            end)

            it("should restore data", function()
                assert.is_same({}, PersistentData.data)
                PersistentData.Reset()
                assert.is_same({ general = {}, servers = {} }, PersistentData.data)
            end)

            TestReturnSelf("Reset")
        end)
    end)

    describe("data", function()
        local time_previous, time_current
        local _os, time

        setup(function()
            -- general
            time_previous = 1586860000
            time_current = 1586860001

            -- globals
            time = spy.new(ReturnValueFn(time_current))

            _os = _G.os
            _G.os.time = time
        end)

        teardown(function()
            _G.os.time = _os.time
        end)

        before_each(function()
            PersistentData.is_dirty = false
            PersistentData.data = {
                general = {},
                servers = {},
            }
        end)

        describe("Get()", function()
            describe("when in the default mode", function()
                before_each(function()
                    PersistentData.mode = PersistentData.DEFAULT
                end)

                describe("and has no data", function()
                    before_each(function()
                        PersistentData.data.general = {}
                    end)

                    it("should debug error string", function()
                        assert.spy(SDK.Debug.Error).was_not_called()
                        PersistentData.Get("foo")
                        assert.spy(SDK.Debug.Error).was_called(1)
                        assert.spy(SDK.Debug.Error).was_called_with(
                            "[persistent_data]",
                            "[get]",
                            "foo"
                        )
                    end)

                    it("should return nil", function()
                        assert.is_nil(PersistentData.Get("foo"))
                    end)

                    describe("when some chain fields are missing", function()
                        it("should return nil", function()
                            AssertChainNil(function()
                                assert.is_nil(PersistentData.Get("foo"))
                            end, PersistentData, "data", "general")
                        end)
                    end)
                end)

                describe("and has data", function()
                    before_each(function()
                        PersistentData.data.general = {
                            foo = "bar",
                        }
                    end)

                    it("should debug string", function()
                        assert.spy(SDK.Debug.String).was_not_called()
                        PersistentData.Get("foo")
                        assert.spy(SDK.Debug.String).was_called(1)
                        assert.spy(SDK.Debug.String).was_called_with(
                            "[persistent_data]",
                            "[get]",
                            "foo"
                        )
                    end)

                    it("should return value", function()
                        assert.is_equal("bar", PersistentData.Get("foo"))
                    end)

                    describe("when some chain fields are missing", function()
                        it("should return nil", function()
                            AssertChainNil(function()
                                assert.is_nil(PersistentData.Get("foo"))
                            end, PersistentData, "data", "general")
                        end)
                    end)
                end)
            end)

            describe("when in the server mode", function()
                before_each(function()
                    PersistentData.mode = PersistentData.SERVER
                end)

                describe("and has no data", function()
                    before_each(function()
                        PersistentData.data.servers = {}
                    end)

                    describe("and in gameplay", function()
                        it("should debug error string", function()
                            assert.spy(SDK.Debug.Error).was_not_called()
                            PersistentData.Get("foo")
                            assert.spy(SDK.Debug.Error).was_called(1)
                            assert.spy(SDK.Debug.Error).was_called_with(
                                "[persistent_data]",
                                "[get]",
                                "[" .. PersistentData.server_id .. "]",
                                "foo"
                            )
                        end)

                        it("should return nil", function()
                            assert.is_nil(PersistentData.Get("foo"))
                        end)

                        describe("when some chain fields are missing", function()
                            it("should return nil", function()
                                PersistentData.data.servers[MasterSessionId] = nil
                                assert.is_nil(PersistentData.Get("foo"))
                                PersistentData.data.servers = nil
                                assert.is_nil(PersistentData.Get("foo"))
                                PersistentData.data = nil
                                assert.is_nil(PersistentData.Get("foo"))
                            end)
                        end)
                    end)
                end)

                describe("and has data", function()
                    before_each(function()
                        PersistentData.data.servers = {
                            [MasterSessionId] = {
                                lastseen = time_previous,
                                data = {
                                    foo = "bar",
                                },
                            },
                        }
                    end)

                    describe("and not in gameplay", function()
                        before_each(function()
                            _G.TheSim = nil
                            _G.TheWorld = nil
                        end)

                        TestDebugErrorNoServerData("Get", "foo")

                        it("should return nil", function()
                            assert.is_nil(PersistentData.Get("foo"))
                        end)
                    end)

                    describe("and in gameplay", function()
                        it("should debug string", function()
                            assert.spy(SDK.Debug.String).was_not_called()
                            PersistentData.Get("foo")
                            assert.spy(SDK.Debug.String).was_called(1)
                            assert.spy(SDK.Debug.String).was_called_with(
                                "[persistent_data]",
                                "[get]",
                                "[" .. PersistentData.server_id .. "]",
                                "foo"
                            )
                        end)

                        it("should return value", function()
                            assert.is_equal("bar", PersistentData.Get("foo"))
                        end)

                        describe("when no value", function()
                            before_each(function()
                                PersistentData.data.servers = {
                                    [MasterSessionId] = {
                                        lastseen = time_previous,
                                        data = {},
                                    },
                                }
                            end)

                            it("should debug error string", function()
                                assert.spy(SDK.Debug.Error).was_not_called()
                                PersistentData.Get("foo")
                                assert.spy(SDK.Debug.Error).was_called(1)
                                assert.spy(SDK.Debug.Error).was_called_with(
                                    "[persistent_data]",
                                    "[get]",
                                    "[" .. PersistentData.server_id .. "]",
                                    "foo"
                                )
                            end)

                            it("should return nil", function()
                                assert.is_nil(PersistentData.Get("foo"))
                            end)
                        end)

                        describe("when some chain fields are missing", function()
                            it("should return nil", function()
                                AssertChainNil(function()
                                    assert.is_nil(PersistentData.Get("foo"))
                                end, PersistentData, "data", "servers", MasterSessionId)
                            end)
                        end)
                    end)
                end)
            end)
        end)

        describe("Set()", function()
            describe("when in the default mode", function()
                before_each(function()
                    PersistentData.mode = PersistentData.DEFAULT
                end)

                it("should debug string", function()
                    assert.spy(SDK.Debug.String).was_not_called()
                    PersistentData.Set("foo", "bar")
                    assert.spy(SDK.Debug.String).was_called(1)
                    assert.spy(SDK.Debug.String).was_called_with(
                        "[persistent_data]",
                        "[set]",
                        "foo:",
                        "bar"
                    )
                end)

                describe("when some chain fields are missing", function()
                    it("should return self", function()
                        AssertChainNil(function()
                            AssertReturnSelf(PersistentData, "Set", "foo", "bar")
                        end, PersistentData, "data")
                    end)
                end)
            end)

            describe("when in the server mode", function()
                before_each(function()
                    PersistentData.mode = PersistentData.SERVER
                    PersistentData.data.servers = {
                        [MasterSessionId] = {
                            lastseen = time_previous,
                            data = {
                                foo = "bar",
                            },
                        },
                    }
                end)

                describe("and not in gameplay", function()
                    before_each(function()
                        _G.TheSim = nil
                        _G.TheWorld = nil
                    end)

                    TestDebugErrorNoServerData("Set", "foo", "bar")

                    describe("when some chain fields are missing", function()
                        it("should return self", function()
                            AssertChainNil(function()
                                AssertReturnSelf(PersistentData, "Set", "foo", "bar")
                            end, PersistentData, "data", "servers", MasterSessionId, "data")
                        end)
                    end)
                end)

                describe("and in gameplay", function()
                    describe("and a server exists", function()
                        it("should debug string", function()
                            assert.spy(SDK.Debug.String).was_not_called()
                            PersistentData.Set("foo", "bar")
                            assert.spy(SDK.Debug.String).was_called(1)
                            assert.spy(SDK.Debug.String).was_called_with(
                                "[persistent_data]",
                                "[set]",
                                "[" .. PersistentData.server_id .. "]",
                                "foo:",
                                "bar"
                            )
                        end)

                        it("should set is_dirty to true", function()
                            assert.is_false(PersistentData.is_dirty)
                            PersistentData.Set("foo", "bar")
                            assert.is_true(PersistentData.is_dirty)
                        end)

                        describe("when some chain fields are missing", function()
                            it("should return self", function()
                                AssertChainNil(function()
                                    AssertReturnSelf(PersistentData, "Set", "foo", "bar")
                                end, PersistentData, "data", "servers")
                            end)
                        end)
                    end)
                end)
            end)

            TestReturnSelf("Set", "foo", "bar")
        end)
    end)

    describe("loading", function()
        describe("Load()", function()
            it("should debug string", function()
                assert.spy(SDK.Debug.String).was_not_called()
                PersistentData.Load()
                assert.spy(SDK.Debug.String).was_called(1)
                assert.spy(SDK.Debug.String).was_called_with(
                    "[persistent_data]",
                    "[load]",
                    string.format("Loading %s...", PersistentData.GetSaveName())
                )
            end)

            it("should call TheSim:GetPersistentString()", function()
                assert.spy(_G.TheSim.GetPersistentString).was_not_called()
                PersistentData.Load()
                assert.spy(_G.TheSim.GetPersistentString).was_called(1)
                assert.spy(_G.TheSim.GetPersistentString).was_called_with(
                    match.is_ref(_G.TheSim),
                    PersistentData.GetSaveName(),
                    match.is_function(),
                    false
                )
            end)

            TestReturnSelf("Load")
        end)

        describe("OnLoad()", function()
            local cb

            before_each(function()
                -- general
                cb = spy.new(Empty)

                -- globals
                _G.TrackedAssert = spy.new(Empty)
            end)

            teardown(function()
                _G.TrackedAssert = nil
            end)

            local function TestEmptyOrNilString(str)
                it("should debug error string", function()
                    assert.spy(SDK.Debug.Error).was_not_called()
                    PersistentData.OnLoad(str)
                    assert.spy(SDK.Debug.Error).was_called(1)
                    assert.spy(SDK.Debug.Error).was_called_with(
                        "[persistent_data]",
                        "[load]",
                        "Failure",
                        "(empty string)"
                    )
                end)

                it("should call the callback if passed with false", function()
                    assert.spy(cb).was_not_called()
                    PersistentData.OnLoad("", cb)
                    assert.spy(cb).was_called(1)
                    assert.spy(cb).was_called_with(false)
                end)
            end

            describe("when passed string is empty", function()
                TestEmptyOrNilString("")
            end)

            describe("when passed string is nil", function()
                TestEmptyOrNilString(nil)
            end)

            describe("when passed string not empty", function()
                local str
                local CleanServers, Save

                setup(function()
                    str = "foo"
                end)

                before_each(function()
                    CleanServers = spy.on(PersistentData, "CleanServers")
                    Save = spy.on(PersistentData, "Save")
                end)

                it("should debug string", function()
                    assert.spy(SDK.Debug.String).was_not_called()
                    PersistentData.OnLoad(str)
                    assert.spy(SDK.Debug.String).was_called(2)
                    assert.spy(SDK.Debug.String).was_called_with(
                        "[persistent_data]",
                        "[load]",
                        "Success",
                        string.format("(length: %d)", string.len(str))
                    )
                end)

                it("should call TrackedAssert()", function()
                    assert.spy(_G.TrackedAssert).was_not_called()
                    PersistentData.OnLoad(str)
                    assert.spy(_G.TrackedAssert).was_called(1)
                    assert.spy(_G.TrackedAssert).was_called_with(
                        "TheSim:GetPersistentString " .. PersistentData.name,
                        match.is_ref(_G.json.decode),
                        str
                    )
                end)

                it("should set is_dirty field to false", function()
                    PersistentData.OnLoad(str)
                    assert.is_false(PersistentData.is_dirty)
                end)

                it("should set data_original field", function()
                    PersistentData.data_original = {}
                    local before = PersistentData.data_original
                    assert.is_equal(before, PersistentData.data_original)
                    PersistentData.OnLoad(str)
                    assert.is_not_equal(before, PersistentData.data_original)
                end)

                it("should set data field", function()
                    PersistentData.data = {}
                    local before = PersistentData.data
                    assert.is_equal(before, PersistentData.data)
                    PersistentData.OnLoad(str)
                    assert.is_not_equal(before, PersistentData.data)
                end)

                it("should call PersistentData.CleanServers()", function()
                    assert.spy(CleanServers).was_not_called()
                    PersistentData.OnLoad(str)
                    assert.spy(CleanServers).was_called(1)
                    assert.spy(CleanServers).was_called_with()
                end)

                it("should call PersistentData.Save()", function()
                    assert.spy(Save).was_not_called()
                    PersistentData.OnLoad(str)
                    assert.spy(Save).was_called(1)
                    assert.spy(Save).was_called_with()
                end)

                it("should call the callback if passed with true", function()
                    assert.spy(cb).was_not_called()
                    PersistentData.OnLoad(str, cb)
                    assert.spy(cb).was_called(1)
                    assert.spy(cb).was_called_with(true)
                end)
            end)
        end)
    end)

    describe("saving", function()
        describe("Save()", function()
            local cb

            before_each(function()
                cb = spy.new(Empty)
            end)

            describe("when is_dirty is true", function()
                before_each(function()
                    PersistentData.is_dirty = true
                end)

                describe("and the name is passed", function()
                    it("should debug string", function()
                        assert.spy(SDK.Debug.String).was_not_called()
                        PersistentData.Save(nil, "Test")
                        assert.spy(SDK.Debug.String).was_called(1)
                        assert.spy(SDK.Debug.String).was_called_with(
                            "[persistent_data]",
                            "[save]",
                            "Saved (Test)"
                        )
                    end)
                end)

                describe("and the name is not passed", function()
                    it("should debug string", function()
                        assert.spy(SDK.Debug.String).was_not_called()
                        PersistentData.Save()
                        assert.spy(SDK.Debug.String).was_called(1)
                        assert.spy(SDK.Debug.String).was_called_with(
                            "[persistent_data]",
                            "[save]",
                            "Saved"
                        )
                    end)
                end)

                it("should set is_dirty field to false", function()
                    assert.is_true(PersistentData.is_dirty)
                    PersistentData.Save()
                    assert.is_false(PersistentData.is_dirty)
                end)

                it("should call json.encode()", function()
                    assert.spy(_G.json.encode).was_not_called()
                    PersistentData.Save()
                    assert.spy(_G.json.encode).was_called(1)
                    assert.spy(_G.json.encode).was_called_with(PersistentData.data)
                end)

                it("should call SavePersistentString()", function()
                    assert.spy(_G.SavePersistentString).was_not_called()
                    PersistentData.Save()
                    assert.spy(_G.SavePersistentString).was_called(1)
                    assert.spy(_G.SavePersistentString).was_called_with(
                        PersistentData.GetSaveName(),
                        nil,
                        PersistentData.is_encoded,
                        nil
                    )
                end)

                it("should call the callback if passed with true", function()
                    assert.spy(cb).was_not_called()
                    PersistentData.Save(cb)
                    assert.spy(cb).was_called(1)
                    assert.spy(cb).was_called_with(true)
                end)
            end)

            describe("when is_dirty field is false", function()
                before_each(function()
                    PersistentData.is_dirty = false
                end)

                it("shouldn't debug string", function()
                    assert.spy(SDK.Debug.String).was_not_called()
                    PersistentData.Save()
                    assert.spy(SDK.Debug.String).was_not_called()
                end)

                it("shouldn't call the SavePersistentString()", function()
                    assert.spy(_G.SavePersistentString).was_not_called()
                    PersistentData.Save()
                    assert.spy(_G.SavePersistentString).was_not_called()
                end)

                it("shouldn't call the callback if passed", function()
                    assert.spy(cb).was_not_called()
                    PersistentData.Save(cb)
                    assert.spy(cb).was_not_called()
                end)
            end)

            TestReturnSelf("Save")
        end)
    end)

    describe("server", function()
        local time_previous, time_current
        local _os, time

        setup(function()
            -- general
            time_previous = 1586860000
            time_current = 1586860001

            -- globals
            time = spy.new(ReturnValueFn(time_current))

            _os = _G.os
            _G.os.time = time
        end)

        teardown(function()
            _G.os.time = _os.time
        end)

        before_each(function()
            PersistentData.is_dirty = false
            PersistentData.server_id = nil
            PersistentData.data = {
                servers = {
                    [MasterSessionId] = {
                        lastseen = time_previous,
                        data = {
                            foo = "bar",
                        },
                    },
                },
            }
        end)

        describe("GetServer()", function()
            describe("when not in gameplay", function()
                before_each(function()
                    _G.TheSim = nil
                    _G.TheWorld = nil
                end)

                it("should set server_id field to nil", function()
                    assert.is_nil(PersistentData.server_id)
                    PersistentData.GetServer()
                    assert.is_nil(PersistentData.server_id)
                end)

                TestDebugErrorNoServerData("GetServer")

                it("should return nil", function()
                    assert.is_nil(PersistentData.GetServer())
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        AssertChainNil(function()
                            assert.is_nil(PersistentData.GetServer())
                        end, PersistentData, "data", "servers", MasterSessionId)
                    end)
                end)
            end)

            describe("when in gameplay", function()
                describe("and has data", function()
                    before_each(function()
                        PersistentData.data.servers = {
                            [MasterSessionId] = {
                                lastseen = time_previous,
                                data = {
                                    foo = "bar",
                                },
                            },
                        }
                    end)

                    it("should set the server_id field", function()
                        PersistentData.GetServer()
                        assert.is_equal(MasterSessionId, PersistentData.server_id)
                    end)

                    it("should refresh the lastseen field", function()
                        assert.is_equal(
                            time_previous,
                            PersistentData.data.servers[MasterSessionId].lastseen
                        )
                        PersistentData.GetServer()
                        assert.is_equal(
                            time_current,
                            PersistentData.data.servers[MasterSessionId].lastseen
                        )
                    end)

                    it("should set is_dirty true", function()
                        PersistentData.GetServer()
                        assert.is_true(PersistentData.is_dirty)
                    end)

                    it("should return server", function()
                        assert.is_same({
                            lastseen = time_current,
                            data = {
                                foo = "bar",
                            },
                        }, PersistentData.GetServer())
                    end)
                end)

                describe("and has no data", function()
                    before_each(function()
                        PersistentData.data.servers = {}
                    end)

                    it("should set the server_id field", function()
                        assert.is_nil(PersistentData.server_id)
                        PersistentData.GetServer()
                        assert.is_equal(MasterSessionId, PersistentData.server_id)
                    end)

                    it("should set is_dirty to true", function()
                        assert.is_false(PersistentData.is_dirty)
                        PersistentData.GetServer()
                        assert.is_true(PersistentData.is_dirty)
                    end)

                    it("should return empty server with default fields", function()
                        assert.is_same({
                            lastseen = time_current,
                            data = {},
                        }, PersistentData.GetServer())
                    end)
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        AssertChainNil(function()
                            assert.is_nil(PersistentData.GetServer())
                        end, PersistentData, "data", "servers")
                    end)
                end)
            end)
        end)

        describe("GetServerID()", function()
            describe("when not in gameplay", function()
                before_each(function()
                    _G.TheSim = nil
                    _G.TheWorld = nil
                end)

                it("should return nil", function()
                    assert.is_nil(PersistentData.GetServerID())
                end)
            end)

            describe("when in gameplay", function()
                it(
                    "should call TheWorld.net.components.shardstate:GetMasterSessionId()",
                    function()
                        assert.spy(_G.TheWorld.net.components.shardstate.GetMasterSessionId)
                              .was_not_called()
                        PersistentData.GetServerID()
                        assert.spy(_G.TheWorld.net.components.shardstate.GetMasterSessionId)
                              .was_called(1)
                        assert.spy(_G.TheWorld.net.components.shardstate.GetMasterSessionId)
                              .was_called_with(match.is_ref(
                            _G.TheWorld.net.components.shardstate
                        ))
                    end
                )

                it("should return the master session id", function()
                    assert.is_equal(MasterSessionId, PersistentData.GetServerID())
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(
                        function()
                            assert.is_nil(PersistentData.GetServerID())
                        end,
                        _G.TheWorld,
                        "net",
                        "components",
                        "shardstate",
                        "GetMasterSessionId"
                    )
                end)
            end)
        end)

        describe("GetServerLastSeen()", function()
            describe("when not in gameplay", function()
                before_each(function()
                    _G.TheSim = nil
                    _G.TheWorld = nil
                end)

                TestDebugErrorNoServerData("GetServerLastSeen")

                it("should return nil", function()
                    assert.is_nil(PersistentData.GetServerLastSeen())
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        PersistentData.data.servers[MasterSessionId].lastseen = nil
                        assert.is_nil(PersistentData.GetServerLastSeen())
                        AssertChainNil(function()
                            assert.is_nil(PersistentData.GetServerLastSeen())
                        end, PersistentData, "data", "servers", MasterSessionId)
                    end)
                end)
            end)

            describe("when in gameplay", function()
                describe("and has data", function()
                    before_each(function()
                        PersistentData.data.servers = {
                            [MasterSessionId] = {
                                lastseen = time_previous,
                                data = {
                                    foo = "bar",
                                },
                            },
                        }
                    end)

                    it("should return the current time", function()
                        assert.is_equal(time_current, PersistentData.GetServerLastSeen())
                    end)
                end)

                describe("and has no data", function()
                    before_each(function()
                        PersistentData.data.servers = {}
                    end)
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        AssertChainNil(function()
                            assert.is_nil(PersistentData.GetServerLastSeen())
                        end, PersistentData, "data", "servers")
                    end)
                end)
            end)
        end)

        describe("GetServerData()", function()
            describe("when not in gameplay", function()
                before_each(function()
                    _G.TheSim = nil
                    _G.TheWorld = nil
                end)

                TestDebugErrorNoServerData("GetServerData")

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        PersistentData.data.servers[MasterSessionId].data = nil
                        assert.is_nil(PersistentData.GetServerData())
                        AssertChainNil(function()
                            assert.is_nil(PersistentData.GetServerData())
                        end, PersistentData, "data", "servers", MasterSessionId)
                    end)
                end)

                it("should return nil", function()
                    assert.is_nil(PersistentData.GetServerData())
                end)
            end)

            describe("when in gameplay", function()
                describe("and has data", function()
                    before_each(function()
                        PersistentData.data.servers = {
                            [MasterSessionId] = {
                                lastseen = time_previous,
                                data = {
                                    foo = "bar",
                                },
                            },
                        }
                    end)

                    it("should return the server data", function()
                        assert.is_same({ foo = "bar" }, PersistentData.GetServerData())
                    end)
                end)

                describe("and has no data", function()
                    before_each(function()
                        PersistentData.data.servers = {}
                    end)

                    it("should return empty server data", function()
                        assert.is_same({}, PersistentData.GetServerData())
                    end)
                end)

                describe("when some chain fields are missing", function()
                    it("should return nil", function()
                        AssertChainNil(function()
                            assert.is_nil(PersistentData.GetServerData())
                        end, PersistentData, "data", "servers")
                    end)
                end)
            end)
        end)

        describe("ServerRefreshLastSeen()", function()
            describe("and not in gameplay", function()
                before_each(function()
                    _G.TheSim = nil
                    _G.TheWorld = nil
                end)

                TestDebugErrorNoServerData("ServerRefreshLastSeen")

                describe("when some chain fields are missing", function()
                    it("should return self", function()
                        AssertChainNil(function()
                            AssertReturnSelf(PersistentData, "ServerRefreshLastSeen")
                        end, PersistentData, "data", "servers", MasterSessionId, "lastseen")
                    end)
                end)
            end)

            describe("and in gameplay", function()
                describe("and has data", function()
                    before_each(function()
                        PersistentData.data.servers = {
                            [MasterSessionId] = {
                                lastseen = time_previous,
                                data = {
                                    foo = "bar",
                                },
                            },
                        }
                    end)

                    it("should refresh the lastseen field", function()
                        assert.is_equal(
                            time_previous,
                            PersistentData.data.servers[MasterSessionId].lastseen
                        )
                        PersistentData.ServerRefreshLastSeen()
                        assert.is_equal(
                            time_current,
                            PersistentData.data.servers[MasterSessionId].lastseen
                        )
                    end)

                    it("should set is_dirty field to true", function()
                        assert.is_false(PersistentData.is_dirty)
                        PersistentData.ServerRefreshLastSeen()
                        assert.is_true(PersistentData.is_dirty)
                    end)
                end)

                describe("and has no data", function()
                    before_each(function()
                        PersistentData.data.servers = {}
                    end)

                    it("should add a server with default fields", function()
                        assert.is_nil(PersistentData.data.servers[MasterSessionId])
                        PersistentData.ServerRefreshLastSeen()
                        assert.is_same({
                            lastseen = time_current,
                            data = {},
                        }, PersistentData.data.servers[MasterSessionId])
                    end)

                    it("should set is_dirty field to true", function()
                        PersistentData.ServerRefreshLastSeen()
                        assert.is_true(PersistentData.is_dirty)
                    end)
                end)

                describe("when some chain fields are missing", function()
                    it("should return self", function()
                        AssertChainNil(function()
                            AssertReturnSelf(PersistentData, "ServerRefreshLastSeen")
                        end, PersistentData, "data", "servers")
                    end)
                end)
            end)

            TestReturnSelf("ServerRefreshLastSeen")
        end)
    end)
end)
