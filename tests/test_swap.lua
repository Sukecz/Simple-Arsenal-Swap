local ns = {}

local function loadModule(path)
    local chunk = assert(loadfile(path))
    chunk("SimpleArsenalSwap", ns)
end

loadModule("Defaults.lua")
loadModule("ApiCompat.lua")

local inventory = { [16] = 1001, [17] = 1002 }
ns.ApiCompat.GetInventoryItemID = function(_, slot)
    return inventory[slot]
end

ns.Database = {
    sets = {
        A = {
            main = { itemID = 1001, equipLoc = "INVTYPE_WEAPON" },
            off = { itemID = 1002, equipLoc = "INVTYPE_SHIELD" },
        },
        B = {
            main = { itemID = 2001, equipLoc = "INVTYPE_2HWEAPON" },
            off = nil,
        },
    },
}
function ns.Database:GetSet(key)
    return self.sets[key]
end
function ns.Database:IsReady()
    return true
end
function ns.Database:GetSetName(key)
    return key == "B" and "Damage" or "Tank"
end

ns.L = {
    ARSENAL_A = "Arsenal A",
    ARSENAL_B = "Arsenal B",
    SWAP_SUCCESS = "%s equipped",
}

local shownMessage
ns.ApiCompat.ShowCombatMessage = function(_, message)
    shownMessage = message
end

loadModule("Swap.lua")

local macro = ns.Swap:BuildMacro(ns.Database.sets.A, ns.Database.sets.B)
local expected = table.concat({
    "/run SimpleArsenalSwap_ToggleOutOfCombat()",
    "/equipslot [combat] 16 item:1001",
    "/equipslot [combat] 17 item:1002",
    "/equipslot [combat] 16 item:2001",
}, "\n")
assert(macro == expected, macro)
assert(#macro <= ns.Constants.MAX_MACRO_BYTES)
assert(ns.Swap:GetActiveSet() == "A")
assert(ns.Swap:GetTargetSetKey() == "B")

inventory[16], inventory[17] = 2001, nil
assert(ns.Swap:GetActiveSet() == "B")
assert(ns.Swap:GetTargetSetKey() == "A")

inventory[16], inventory[17] = 3001, nil
assert(ns.Swap:GetActiveSet() == nil)
assert(ns.Swap:GetTargetSetKey() == "A")

local mainOnly = {
    main = { itemID = 4001, equipLoc = "INVTYPE_WEAPON" },
    off = nil,
}
assert(ns.Swap:IsSetEquipped(mainOnly, 4001, 9999), "empty 1H off slot should be ignored")
assert(not ns.Swap:IsSetEquipped(ns.Database.sets.B, 2001, 9999), "2H set requires an empty off hand")

inventory[16], inventory[17] = 1001, 1002
ns.Swap:BeginSwapAttempt("B")
assert(not ns.Swap:OnEquipmentChanged())
assert(shownMessage == nil)
inventory[16], inventory[17] = 2001, nil
assert(ns.Swap:OnEquipmentChanged())
assert(shownMessage == "Damage equipped")
assert(ns.Swap.pendingTargetKey == nil)

shownMessage = nil
inventory[16], inventory[17] = 1001, 1002
ns.ApiCompat.IsCombatLocked = function() return true end
local ok, reason = ns.Swap:ToggleOutOfCombat()
assert(not ok and reason == "combat")
assert(ns.Swap.pendingTargetKey == "B", "the protected combat macro path must record its target")
inventory[16], inventory[17] = 2001, nil
assert(ns.Swap:OnEquipmentChanged())
assert(shownMessage == "Damage equipped")

ns.Database.sets.B = {
    main = ns.Database.sets.A.main,
    off = ns.Database.sets.A.off,
}
ns.Database.sets.A.off = nil
inventory[16], inventory[17] = 1001, 1002
assert(ns.Swap:GetActiveSet() == "B", "explicit off-hand match must take precedence")
assert(ns.Swap:GetTargetSetKey() == "A")

local inCombat = false
ns.ApiCompat.IsCombatLocked = function() return inCombat end
local attributes = {}
ns.Swap.button = {
    SetAttribute = function(_, key, value)
        assert(not inCombat, "secure attributes must never be changed in combat")
        attributes[key] = value
    end,
}
ns.Swap:RefreshSecureButton()
local beforeCombat = attributes.macrotext
inCombat = true
ns.Database.sets.B.main = { itemID = 4001, equipLoc = "INVTYPE_2HWEAPON" }
ns.Swap:RefreshSecureButton()
assert(ns.Swap.refreshPending and attributes.macrotext == beforeCombat)
assert(not ns.Swap:SetBinding("K"))
assert(not ns.Swap:ClearBinding())
inCombat = false
ns.Swap:OnCombatEnded()
assert(not ns.Swap.refreshPending and attributes.macrotext ~= beforeCombat)

local action = ns.Constants.BINDING_ACTION
local bindings = { K = action, L = action, M = "JUMP" }
local saves = 0
local failNew = true
local failClear = false
ns.ApiCompat.GetBindingKey = function() return "K", "L" end
GetBindingAction = function(key) return bindings[key] or "" end
SetBindingClick = function(key)
    if key == "M" and failNew then return false end
    bindings[key] = action
    return true
end
SetBinding = function(key, value)
    if key == "L" and failClear then return false end
    bindings[key] = value
    return true
end
GetCurrentBindingSet = function() return 2 end
SaveBindings = function(set) assert(set == 2); saves = saves + 1 end
assert(not ns.Swap:SetBinding("M"))
assert(bindings.K == action and bindings.L == action and bindings.M == "JUMP" and saves == 0)
failNew, failClear = false, true
assert(not ns.Swap:SetBinding("M"))
assert(bindings.K == action and bindings.L == action and bindings.M == "JUMP" and saves == 0)
failClear = false
assert(ns.Swap:SetBinding("M"))
assert(bindings.K == nil and bindings.L == nil and bindings.M == action and saves == 1)

print("test_swap.lua: ok")
