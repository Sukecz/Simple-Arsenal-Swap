local ns = {}

local function loadModule(path)
    local chunk = assert(loadfile(path))
    chunk("SimpleArsenalSwap", ns)
end

loadModule("Defaults.lua")
loadModule("ApiCompat.lua")
loadModule("Database.lua")

local validMain = {
    itemID = 1001,
    itemLink = "item:1001",
    name = "Test Sword",
    icon = 123,
    equipLoc = "INVTYPE_WEAPON",
}
local validShield = {
    itemID = 1002,
    itemLink = "item:1002",
    name = "Test Shield",
    icon = 456,
    equipLoc = "INVTYPE_SHIELD",
}
local twoHanded = {
    itemID = 1003,
    itemLink = "item:1003",
    name = "Test Greatsword",
    icon = 789,
    equipLoc = "INVTYPE_2HWEAPON",
}

local db = ns.Database:Initialize({
    frame = { point = "INVALID", x = 9000, y = -9000 },
    sets = {
        A = { main = validMain, off = validShield },
        B = { main = twoHanded, off = validShield },
    },
})

assert(db.frame.point == "CENTER")
assert(db.frame.x == 5000 and db.frame.y == -5000)
assert(db.sets.A.main.itemID == 1001)
assert(db.sets.A.off.itemID == 1002)
assert(db.sets.B.main.itemID == 1003)
assert(db.sets.B.off == nil, "two-handed main hand must clear the off hand")
assert(ns.Database:IsReady())

assert(ns.Database:SetItem("A", "main", twoHanded))
assert(ns.Database:GetSet("A").off == nil)
assert(not ns.Database:SetItem("A", "off", validShield), "2H off hand must remain disabled")
assert(ns.Database:ClearItem("B", "main"))
assert(not ns.Database:IsReady())

print("test_database.lua: ok")
