local addonName, ns = ...

local ApiCompat = {}
ns.ApiCompat = ApiCompat

local MAIN_HAND_TYPES = {
    INVTYPE_WEAPON = true,
    INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_2HWEAPON = true,
}

local OFF_HAND_TYPES = {
    INVTYPE_WEAPON = true,
    INVTYPE_WEAPONOFFHAND = true,
    INVTYPE_SHIELD = true,
    INVTYPE_HOLDABLE = true,
}

function ApiCompat:IsMainHandType(equipLoc)
    return type(equipLoc) == "string" and MAIN_HAND_TYPES[equipLoc] == true
end

function ApiCompat:IsOffHandType(equipLoc)
    return type(equipLoc) == "string" and OFF_HAND_TYPES[equipLoc] == true
end

function ApiCompat:IsTwoHanded(item)
    return type(item) == "table" and item.equipLoc == "INVTYPE_2HWEAPON"
end

function ApiCompat:GetInventoryItemID(slotID)
    if type(GetInventoryItemID) == "function" then
        return GetInventoryItemID("player", slotID)
    end

    local link = type(GetInventoryItemLink) == "function" and GetInventoryItemLink("player", slotID)
    if type(link) == "string" then
        return tonumber(link:match("item:(%d+)"))
    end

    return nil
end

function ApiCompat:GetCursorItem()
    if type(GetCursorInfo) ~= "function" then
        return nil, "no-cursor-api"
    end

    local cursorType, itemID, itemLink = GetCursorInfo()
    if cursorType ~= "item" then
        return nil, "not-item"
    end

    itemID = tonumber(itemID) or (type(itemLink) == "string" and tonumber(itemLink:match("item:(%d+)")))
    if not itemID then
        return nil, "missing-id"
    end

    local name, canonicalLink, equipLoc, icon
    if type(GetItemInfo) == "function" then
        name, canonicalLink, _, _, _, _, _, _, equipLoc, icon = GetItemInfo(itemLink or itemID)
    end

    if type(GetItemInfoInstant) == "function" then
        local _, _, _, instantEquipLoc, instantIcon = GetItemInfoInstant(itemLink or itemID)
        equipLoc = equipLoc or instantEquipLoc
        icon = icon or instantIcon
    end

    if not equipLoc then
        return nil, "missing-info"
    end

    return {
        itemID = itemID,
        itemLink = canonicalLink or itemLink or ("item:" .. itemID),
        name = name or ("Item " .. itemID),
        icon = icon,
        equipLoc = equipLoc,
    }
end

function ApiCompat:GetItemCount(item)
    if type(item) ~= "table" or not item.itemID or type(GetItemCount) ~= "function" then
        return 0
    end

    return tonumber(GetItemCount(item.itemID, false, false)) or 0
end

function ApiCompat:EquipItem(item, slotID)
    if type(item) ~= "table" or not item.itemID or type(EquipItemByName) ~= "function" then
        return false
    end

    EquipItemByName(item.itemLink or ("item:" .. item.itemID), slotID)
    return true
end

function ApiCompat:GetBindingKey(action)
    if type(GetBindingKey) ~= "function" then
        return nil
    end

    return GetBindingKey(action)
end

function ApiCompat:GetBindingLabel(action)
    if type(GetBindingText) == "function" then
        local label = GetBindingText(action, "BINDING_NAME_")
        if type(label) == "string" and label ~= "" then
            return label
        end
    end

    return action
end

function ApiCompat:IsCombatLocked()
    return type(InCombatLockdown) == "function" and InCombatLockdown() or false
end

function ApiCompat:ClearCursor()
    if type(ClearCursor) == "function" then
        ClearCursor()
    end
end

function ApiCompat:GetSwapMessageFrame()
    if self.swapMessageFrame then
        return self.swapMessageFrame
    end
    if type(CreateFrame) ~= "function" or not UIParent then
        return nil
    end

    local frame = CreateFrame("ScrollingMessageFrame", "SimpleArsenalSwapSwapMessage", UIParent)
    frame:SetSize(640, 90)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    frame:SetFrameStrata("HIGH")
    frame:SetJustifyH("CENTER")
    frame:SetFading(true)
    frame:SetFadeDuration(0.6)
    frame:SetTimeVisible(1.5)
    frame:SetMaxLines(1)
    if type(STANDARD_TEXT_FONT) == "string" and type(frame.SetFont) == "function" then
        frame:SetFont(STANDARD_TEXT_FONT, 32, "OUTLINE")
    elseif GameFontNormalHuge and type(frame.SetFontObject) == "function" then
        frame:SetFontObject(GameFontNormalHuge)
    end

    self.swapMessageFrame = frame
    return frame
end

function ApiCompat:ShowCombatMessage(message, red, green, blue)
    if type(message) ~= "string" or message == "" then
        return nil
    end

    red = red or 0.2
    green = green or 1
    blue = blue or 0.2

    local messageFrame = self:GetSwapMessageFrame()
    if messageFrame and type(messageFrame.AddMessage) == "function" then
        messageFrame:AddMessage(message, red, green, blue)
        return "large-overlay"
    end

    if tostring(SHOW_COMBAT_TEXT) ~= "0"
        and type(CombatText_AddMessage) == "function"
        and type(CombatText_StandardScroll) == "function" then
        CombatText_AddMessage(message, CombatText_StandardScroll, red, green, blue)
        return "combat-text"
    end

    if UIErrorsFrame and type(UIErrorsFrame.AddMessage) == "function" then
        UIErrorsFrame:AddMessage(message, red, green, blue, 1)
        return "ui-errors"
    end

    return nil
end
