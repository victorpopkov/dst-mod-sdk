std = {
    max_code_line_length = 100,
    max_comment_line_length = 150,
    max_line_length = 100,
    max_string_line_length = 100,

    globals = {
        "_G",
        "Class",
        "package",
        "table",
    },

    -- std.read_globals should include only the "native" Lua-related stuff
    read_globals = {
        "arg",
        "assert",
        "debug",
        "env",
        "getmetatable",
        "ipairs",
        "json",
        "math",
        "next",
        "os",
        "pairs",
        "print",
        "rawget",
        "rawset",
        "require",
        "setmetatable",
        "string",
        "tonumber",
        "tostring",
        "type",
        "unpack",
    },
}

files["**/*.lua"] = {
    max_code_line_length = 100,
    max_comment_line_length = 150,
    max_line_length = 100,
    max_string_line_length = 100,

    -- globals
    globals = {
        "AssertDebugError",
        "AssertDebugErrorCalls",
        "AssertDebugErrorInvalidArg",
        "AssertDebugErrorInvalidArgCalls",
        "AssertDebugErrorInvalidArgCalls",
        "AssertDebugString",
        "AssertDebugStringCalls",
        "ClassRegistry",
        "KnownModIndex",
        "LoadSDK",
        "RunInSandboxSafe",
        "SendRPCToServer",
        "SetTestModule",
        "TestArg",
        "TestArgNumber",
        "TestArgPercent",
        "TestArgPlayer",
        "TestArgPoint",
        "TestArgRecipe",
        "TestArgRecipes",
        "TestArgSeason",
        "TestArgString",
        "TestArgUnitInterval",
        "TestArgUnsigned",
        "TestArgUnsignedInteger",
        "TestDebugError",
        "TestDebugErrorCalls",
        "TestDebugString",
        "TestDebugStringCalls",
        "TestRemoteInvalid",
        "TestRemoteValid",
        "TestReturnFalse",
        "TestReturnNil",
        "TestReturnTrue",
        "ToVector3",
        "Vector3",
    },
    read_globals = {
        "ACTIONS",
        "AllPlayers",
        "AllRecipes",
        "AssertChainNil",
        "AssertModuleGetter",
        "AssertModuleSetter",
        "AssertReturnSelf",
        "BRANCH",
        "BufferedAction",
        "CONTROL_MOVE_DOWN",
        "CONTROL_MOVE_LEFT",
        "CONTROL_MOVE_RIGHT",
        "CONTROL_MOVE_UP",
        "Empty",
        "ENCODE_SAVES",
        "EQUIPSLOTS",
        "GetModConfigData",
        "GetValidRecipe",
        "GROUND",
        "InGamePlay",
        "IsRecipeValid",
        "KillThreadsWithID",
        "kleifileexists",
        "MODS_ROOT",
        "newproxy",
        "PREFAB_SKINS_IDS",
        "PREFABFILES",
        "RESOLUTION_X",
        "RESOLUTION_Y",
        "ReturnValueFn",
        "ReturnValuesFn",
        "RPC",
        "SavePersistentString",
        "scheduler",
        "SetDebugEntity",
        "SetPause",
        "shallowcopy",
        "softresolvefilepath",
        "StartNextInstance",
        "StartThread",
        "STRINGS",
        "TableCount",
        "TableHasValue",
        "TheFrontEnd",
        "TheInput",
        "TheNet",
        "ThePlayer",
        "TheSim",
        "TheWorld",
        "TrackedAssert",
        "TrimString",
        "TUNING",
        "USER_HISTORY_EXPIRY_TIME",
    },
}
