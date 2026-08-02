local addonName, ns = ...

local Core = {}
ns.Core = Core

function Core:Print(message)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffd8b240Simple Arsenal Swap:|r " .. tostring(message))
    elseif type(print) == "function" then
        print("Simple Arsenal Swap: " .. tostring(message))
    end
end

function Core:Initialize()
    ns.Database:Initialize(SimpleArsenalSwapDB)
    _G["BINDING_NAME_" .. ns.Constants.BINDING_ACTION] = ns.L.ADDON_NAME
    SimpleArsenalSwap_ToggleOutOfCombat = function()
        return ns.Swap:ToggleOutOfCombat()
    end
    ns.Swap:CreateSecureButton()
    ns.SlashCommands:Register()
end

function Core:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= addonName then
            return
        end
        self:Initialize()
        self.frame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        ns.Swap:RefreshSecureButton()
        self:Print(ns.L.READY_LOGIN)
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.Swap:OnCombatEnded()
        if ns.Options.frame and ns.Options.frame:IsShown() then
            ns.Options:Refresh()
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE_DELAYED"
        or event == "GET_ITEM_INFO_RECEIVED" then
        ns.Swap:RefreshSecureButton()
        if ns.Options.frame and ns.Options.frame:IsShown() then
            ns.Options:Refresh()
        end
    elseif event == "UPDATE_BINDINGS" then
        if ns.Options.frame and ns.Options.frame:IsShown() then
            ns.Options:Refresh()
        end
    end
end

Core.frame = CreateFrame("Frame")
Core.frame:RegisterEvent("ADDON_LOADED")
Core.frame:RegisterEvent("PLAYER_LOGIN")
Core.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
Core.frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
Core.frame:RegisterEvent("BAG_UPDATE_DELAYED")
Core.frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
Core.frame:RegisterEvent("UPDATE_BINDINGS")
Core.frame:SetScript("OnEvent", function(_, event, ...)
    Core:OnEvent(event, ...)
end)
