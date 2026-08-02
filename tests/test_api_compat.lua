local ns = {}

local function loadModule(path)
    local chunk = assert(loadfile(path))
    chunk("SimpleArsenalSwap", ns)
end

loadModule("ApiCompat.lua")

assert(ns.ApiCompat:IsMainHandType("INVTYPE_WEAPON"))
assert(ns.ApiCompat:IsMainHandType("INVTYPE_WEAPONMAINHAND"))
assert(ns.ApiCompat:IsMainHandType("INVTYPE_2HWEAPON"))
assert(not ns.ApiCompat:IsMainHandType("INVTYPE_SHIELD"))

assert(ns.ApiCompat:IsOffHandType("INVTYPE_WEAPON"))
assert(ns.ApiCompat:IsOffHandType("INVTYPE_WEAPONOFFHAND"))
assert(ns.ApiCompat:IsOffHandType("INVTYPE_SHIELD"))
assert(ns.ApiCompat:IsOffHandType("INVTYPE_HOLDABLE"))
assert(not ns.ApiCompat:IsOffHandType("INVTYPE_2HWEAPON"))

assert(ns.ApiCompat:IsTwoHanded({ equipLoc = "INVTYPE_2HWEAPON" }))
assert(not ns.ApiCompat:IsTwoHanded({ equipLoc = "INVTYPE_WEAPON" }))

print("test_api_compat.lua: ok")
