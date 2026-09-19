local ns = {}

local function loadModule(path)
    local chunk = assert(loadfile(path))
    chunk("SimpleArsenalSwap", ns)
end

loadModule("ApiCompat.lua")

local cursorID = 1001
GetCursorInfo = function() return "item", cursorID, "item:" .. cursorID end
local info = function()
    return "Sword", "item:1001", 2, 10, 1, "Weapon", "Sword", 1, "INVTYPE_WEAPON", 123
end
local instant = function() return 1001, "Weapon", "Sword", "INVTYPE_WEAPON", 123 end
local count = function(id, bank, uses)
    assert(id == 1001 and bank == false and uses == false)
    return 1
end
local equipped
local equip = function(link, slot) equipped = { link, slot } end
local sentinel = {}
_G._ = sentinel
for _, modern in ipairs({ false, true }) do
    C_Item = modern and { GetItemInfo = info, GetItemInfoInstant = instant,
        GetItemCount = count, EquipItemByName = equip } or nil
    GetItemInfo = not modern and info or nil
    GetItemInfoInstant = not modern and instant or nil
    GetItemCount = not modern and count or nil
    EquipItemByName = not modern and equip or nil
    local item = assert(ns.ApiCompat:GetCursorItem())
    assert(item.name == "Sword" and item.equipLoc == "INVTYPE_WEAPON" and item.icon == 123)
    assert(_G._ == sentinel, "item capture must not write to the global underscore")
    assert(ns.ApiCompat:GetItemCount(item) == 1)
    assert(ns.ApiCompat:EquipItem(item, 16))
    assert(equipped[1] == "item:1001" and equipped[2] == 16)
end
-- Namespaced APIs take precedence, including when old globals still exist.
GetItemInfo = function() error("legacy API should not run") end
assert(ns.ApiCompat:GetCursorItem().name == "Sword")
C_Item.GetItemInfo = function() return nil end
local uncached = assert(ns.ApiCompat:GetCursorItem())
assert(uncached.equipLoc == "INVTYPE_WEAPON" and uncached.icon == 123)
assert(uncached.name == "Item 1001")
InCombatLockdown = function() return true end
equipped = nil
assert(not ns.ApiCompat:EquipItem(uncached, 16))
assert(equipped == nil, "direct item API must not equip during combat")
InCombatLockdown = nil
C_Item = nil
GetItemInfo, GetItemInfoInstant, GetItemCount, EquipItemByName = nil, nil, nil, nil
assert(ns.ApiCompat:GetCursorItem() == nil)
assert(ns.ApiCompat:GetItemCount(uncached) == 0)
assert(not ns.ApiCompat:EquipItem(uncached, 16))

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

local combatMessage
SHOW_COMBAT_TEXT = "1"
CombatText_StandardScroll = function() end
CombatText_AddMessage = function(message, scroll, red, green, blue)
    combatMessage = { message, scroll, red, green, blue }
end
local largeMessageFrame = {}
function largeMessageFrame:SetSize(width, height) self.width, self.height = width, height end
function largeMessageFrame:SetPoint() end
function largeMessageFrame:SetFrameStrata() end
function largeMessageFrame:SetJustifyH() end
function largeMessageFrame:SetFading() end
function largeMessageFrame:SetFadeDuration() end
function largeMessageFrame:SetTimeVisible() end
function largeMessageFrame:SetMaxLines() end
function largeMessageFrame:SetFont(path, size, flags)
    self.fontPath, self.fontSize, self.fontFlags = path, size, flags
end
function largeMessageFrame:AddMessage(message, red, green, blue)
    self.message = { message, red, green, blue }
end
UIParent = {}
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
CreateFrame = function(frameType, name, parent)
    assert(frameType == "ScrollingMessageFrame")
    assert(name == "SimpleArsenalSwapSwapMessage")
    assert(parent == UIParent)
    return largeMessageFrame
end
assert(ns.ApiCompat:ShowCombatMessage("Arsenal A equipped") == "large-overlay")
assert(largeMessageFrame.fontSize == 32)
assert(largeMessageFrame.message[1] == "Arsenal A equipped")

ns.ApiCompat.swapMessageFrame = nil
CreateFrame = nil
UIParent = nil
assert(ns.ApiCompat:ShowCombatMessage("Arsenal A equipped") == "combat-text")
assert(combatMessage[1] == "Arsenal A equipped")
assert(combatMessage[2] == CombatText_StandardScroll)

local fallbackMessage
SHOW_COMBAT_TEXT = "0"
UIErrorsFrame = {
    AddMessage = function(_, message, red, green, blue)
        fallbackMessage = { message, red, green, blue }
    end,
}
assert(ns.ApiCompat:ShowCombatMessage("Arsenal B equipped") == "ui-errors")
assert(fallbackMessage[1] == "Arsenal B equipped")

print("test_api_compat.lua: ok")
