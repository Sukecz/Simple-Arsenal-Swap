local addonName, ns = ...

ns.Constants = {
    SCHEMA_VERSION = 1,
    MAIN_HAND_SLOT = 16,
    OFF_HAND_SLOT = 17,
    SECURE_BUTTON_NAME = "SimpleArsenalSwapSecureButton",
    BINDING_ACTION = "CLICK SimpleArsenalSwapSecureButton:LeftButton",
    MAX_MACRO_BYTES = 255,
}

ns.Defaults = {
    schemaVersion = ns.Constants.SCHEMA_VERSION,
    frame = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 80,
    },
    sets = {
        A = {
            main = nil,
            off = nil,
        },
        B = {
            main = nil,
            off = nil,
        },
    },
}
