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
