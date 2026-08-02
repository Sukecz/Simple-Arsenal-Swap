local function newWidget()
    local widget = {
        shown = true,
        attributes = {},
        scripts = {},
    }

    function widget:SetSize() end
    function widget:SetWidth() end
    function widget:SetHeight() end
    function widget:SetPoint() end
    function widget:SetAllPoints() end
    function widget:SetFrameStrata() end
    function widget:SetFrameLevel() end
    function widget:GetFrameLevel() return 1 end
    function widget:SetClampedToScreen() end
    function widget:SetMovable() end
    function widget:EnableMouse() end
    function widget:EnableKeyboard() end
    function widget:SetPropagateKeyboardInput() end
    function widget:RegisterForDrag() end
    function widget:RegisterForClicks() end
    function widget:RegisterEvent() end
    function widget:UnregisterEvent() end
    function widget:SetBackdrop() end
    function widget:SetBackdropColor() end
    function widget:SetColorTexture() end
    function widget:SetTexture(value) self.texture = value end
    function widget:SetDesaturated() end
    function widget:SetText(value) self.text = value end
    function widget:SetTextColor() end
    function widget:SetJustifyH() end
    function widget:SetOwner() end
    function widget:SetHyperlink() end
    function widget:SetAttribute(key, value) self.attributes[key] = value end
    function widget:GetAttribute(key) return self.attributes[key] end
    function widget:SetScript(name, callback) self.scripts[name] = callback end
    function widget:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
    function widget:CreateTexture() return newWidget() end
    function widget:CreateFontString() return newWidget() end
    function widget:Show() self.shown = true end
    function widget:Hide() self.shown = false end
    function widget:SetShown(value) self.shown = value and true or false end
    function widget:IsShown() return self.shown end
    function widget:Raise() end
    function widget:StartMoving() end
    function widget:StopMovingOrSizing() end
    function widget:LockHighlight() end
    function widget:UnlockHighlight() end

    return widget
end

UIParent = newWidget()
BackdropTemplateMixin = {}
GameTooltip = newWidget()
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
CreateFrame = function()
    return newWidget()
end
GetInventoryItemID = function() return nil end
GetBindingKey = function() return nil end
InCombatLockdown = function() return false end

local ns = {}
local function loadModule(path)
    local chunk = assert(loadfile(path))
    chunk("SimpleArsenalSwap", ns)
end

loadModule("Locales/enUS.lua")
loadModule("Defaults.lua")
loadModule("ApiCompat.lua")
loadModule("Database.lua")
loadModule("Swap.lua")
loadModule("Options.lua")
loadModule("SlashCommands.lua")
loadModule("Core.lua")

ns.Core:OnEvent("ADDON_LOADED", "SimpleArsenalSwap")
assert(SimpleArsenalSwapDB and SimpleArsenalSwapDB.schemaVersion == 1)
assert(ns.Swap.button)
assert(ns.Swap.button:GetAttribute("type") == "macro")
assert(type(SimpleArsenalSwap_ToggleOutOfCombat) == "function")
assert(type(SlashCmdList.SIMPLEARSENALSWAP) == "function")

local frame = ns.Options:CreateFrame()
assert(frame and frame.setA and frame.setB)
assert(frame.hotkey.text == ns.L.NOT_BOUND)
assert(frame.status.text == ns.L.CONFIGURE_BOTH)

print("test_options_runtime.lua: ok")
