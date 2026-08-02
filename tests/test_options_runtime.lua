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
    function widget:GetText() return self.text end
    function widget:SetTextColor() end
    function widget:SetJustifyH() end
    function widget:SetAutoFocus() end
    function widget:SetMaxLetters() end
    function widget:SetFontObject() end
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
    function widget:ClearFocus() self.focused = false end
    function widget:HasFocus() return self.focused == true end

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
local addonBindingKey
local bindingActions = { K = "JUMP" }
GetBindingKey = function(action)
    if action == "CLICK SimpleArsenalSwapSecureButton:LeftButton" then
        return addonBindingKey
    end
    return nil
end
GetBindingAction = function(key)
    return bindingActions[key] or ""
end
GetBindingText = function(value, prefix)
    if prefix == "BINDING_NAME_" and value == "JUMP" then
        return "Jump"
    end
    return value
end
SetBinding = function(key)
    if key == addonBindingKey then
        addonBindingKey = nil
    end
    bindingActions[key] = nil
    return true
end
SetBindingClick = function(key)
    addonBindingKey = key
    bindingActions[key] = "CLICK SimpleArsenalSwapSecureButton:LeftButton"
    return true
end
GetCurrentBindingSet = function() return 1 end
SaveBindings = function() end
StaticPopupDialogs = {}
local shownPopup
StaticPopup_Show = function(name, textArg1, textArg2)
    shownPopup = { name = name, textArg1 = textArg1, textArg2 = textArg2 }
end
CANCEL = "Cancel"
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
assert(SimpleArsenalSwapDB and SimpleArsenalSwapDB.schemaVersion == 2)
assert(ns.Swap.button)
assert(ns.Swap.button:GetAttribute("type") == "macro")
assert(type(SimpleArsenalSwap_ToggleOutOfCombat) == "function")
assert(type(SlashCmdList.SIMPLEARSENALSWAP) == "function")

local frame = ns.Options:CreateFrame()
assert(frame and frame.setA and frame.setB)
assert(frame.hotkey.text == ns.L.NOT_BOUND)
assert(frame.status.text == ns.L.CONFIGURE_BOTH)

frame.setA.title:SetText("Tank")
frame.setA.title.scripts.OnEnterPressed(frame.setA.title)
assert(ns.Database:GetSetName("A") == "Tank")
assert(frame.setA.title.text == "Tank")

ns.Options:StartBindingCapture()
ns.Options:OnBindingKeyDown("K")
assert(shownPopup and shownPopup.textArg1 == "K" and shownPopup.textArg2 == "Jump")
assert(addonBindingKey == nil, "a conflicting binding must not be replaced before confirmation")
StaticPopupDialogs[shownPopup.name].OnAccept()
assert(addonBindingKey == "K", "accepting the dialog should replace the binding")
assert(frame.hotkey.text == "K")

bindingActions.L = "OPENALLBAGS"
ns.Options:StartBindingCapture()
ns.Options:OnBindingKeyDown("L")
assert(addonBindingKey == "K")
StaticPopupDialogs[shownPopup.name].OnCancel()
assert(addonBindingKey == "K", "cancelling the dialog must keep the existing addon binding")
assert(bindingActions.L == "OPENALLBAGS", "cancelling must preserve the conflicting action")

print("test_options_runtime.lua: ok")
