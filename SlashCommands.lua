local addonName, ns = ...

local SlashCommands = {}
ns.SlashCommands = SlashCommands

function SlashCommands:Handle(message)
    message = type(message) == "string" and message:match("^%s*(.-)%s*$") or ""
    message = string.lower(message)

    if message == "" or message == "options" or message == "config" then
        ns.Options:Show()
    elseif message == "status" then
        if not ns.Database:IsReady() then
            ns.Core:Print(ns.L.STATUS_INCOMPLETE)
        else
            local key = ns.Swap:GetBindingKey()
            if not key then
                ns.Core:Print(ns.L.STATUS_UNBOUND)
            else
                local active = ns.Swap:GetActiveSet()
                ns.Core:Print(active
                    and string.format(ns.L.ACTIVE_SET, ns.Database:GetSetName(active))
                    or string.format(ns.L.ACTIVE_OTHER, ns.Database:GetSetName("A")))
            end
        end
    else
        ns.Core:Print(ns.L.HELP)
    end
end

function SlashCommands:Register()
    SLASH_SIMPLEARSENALSWAP1 = "/sas"
    SLASH_SIMPLEARSENALSWAP2 = "/simplearsenalswap"
    SlashCmdList.SIMPLEARSENALSWAP = function(message)
        SlashCommands:Handle(message)
    end
end
