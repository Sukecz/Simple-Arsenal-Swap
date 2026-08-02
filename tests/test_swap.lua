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
assert(shownMessage == "Arsenal B equipped")
assert(ns.Swap.pendingTargetKey == nil)

shownMessage = nil
inventory[16], inventory[17] = 1001, 1002
ns.ApiCompat.IsCombatLocked = function() return true end
local ok, reason = ns.Swap:ToggleOutOfCombat()
assert(not ok and reason == "combat")
assert(ns.Swap.pendingTargetKey == "B", "the protected combat macro path must record its target")
inventory[16], inventory[17] = 2001, nil
assert(ns.Swap:OnEquipmentChanged())
assert(shownMessage == "Arsenal B equipped")

print("test_swap.lua: ok")
