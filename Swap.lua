local addonName, ns = ...

local Swap = {}
ns.Swap = Swap

local C = ns.Constants

local function itemToken(item)
    if type(item) ~= "table" or not tonumber(item.itemID) then
        return nil
    end

    return "item:" .. math.floor(tonumber(item.itemID))
end

local function appendCombatSet(lines, set)
    if type(set) ~= "table" or not set.main then
        return
    end

    lines[#lines + 1] = "/equipslot [combat] " .. C.MAIN_HAND_SLOT .. " " .. itemToken(set.main)
    if set.off and not ns.ApiCompat:IsTwoHanded(set.main) then
        lines[#lines + 1] = "/equipslot [combat] " .. C.OFF_HAND_SLOT .. " " .. itemToken(set.off)
    end
end

function Swap:BuildMacro(setA, setB)
    local lines = {
        "/run SimpleArsenalSwap_ToggleOutOfCombat()",
    }

    if setA and setA.main and setB and setB.main then
        appendCombatSet(lines, setA)
        appendCombatSet(lines, setB)
    end

    return table.concat(lines, "\n")
end

function Swap:IsSetEquipped(set, mainItemID, offItemID)
    if type(set) ~= "table" or not set.main then
        return false
    end

    if tonumber(mainItemID) ~= tonumber(set.main.itemID) then
        return false
    end

    if ns.ApiCompat:IsTwoHanded(set.main) then
        return offItemID == nil
    end

    if set.off then
        return tonumber(offItemID) == tonumber(set.off.itemID)
    end

    return true
end

function Swap:GetActiveSet()
    local mainItemID = ns.ApiCompat:GetInventoryItemID(C.MAIN_HAND_SLOT)
    local offItemID = ns.ApiCompat:GetInventoryItemID(C.OFF_HAND_SLOT)

    if self:IsSetEquipped(ns.Database:GetSet("A"), mainItemID, offItemID) then
        return "A"
    end
    if self:IsSetEquipped(ns.Database:GetSet("B"), mainItemID, offItemID) then
        return "B"
    end

    return nil
end

function Swap:GetTargetSetKey()
    return self:GetActiveSet() == "A" and "B" or "A"
end

function Swap:FindMissingItem(set)
    if type(set) ~= "table" then
        return nil
    end

    local equippedMain = ns.ApiCompat:GetInventoryItemID(C.MAIN_HAND_SLOT)
    local equippedOff = ns.ApiCompat:GetInventoryItemID(C.OFF_HAND_SLOT)
    local items = {
        { item = set.main, equipped = equippedMain },
        { item = set.off, equipped = equippedOff },
    }

    for _, entry in ipairs(items) do
        if entry.item and tonumber(entry.equipped) ~= tonumber(entry.item.itemID)
            and ns.ApiCompat:GetItemCount(entry.item) < 1 then
            return entry.item
        end
    end

    return nil
end

function Swap:ClearSwapAttempt(attemptID)
    if attemptID and self.pendingAttemptID ~= attemptID then
        return
    end

    self.pendingAttemptID = nil
    self.pendingTargetKey = nil
    self.pendingStartedAt = nil
end

function Swap:BeginSwapAttempt(targetKey)
    self.nextAttemptID = (self.nextAttemptID or 0) + 1
    local attemptID = self.nextAttemptID
    self.pendingAttemptID = attemptID
    self.pendingTargetKey = targetKey
    self.pendingStartedAt = type(GetTime) == "function" and GetTime() or 0

    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(3, function()
            self:ClearSwapAttempt(attemptID)
        end)
    end

    return attemptID
end

function Swap:OnEquipmentChanged()
    if not self.pendingTargetKey then
        return false
    end

    if type(GetTime) == "function" and self.pendingStartedAt
        and GetTime() - self.pendingStartedAt > 3 then
        self:ClearSwapAttempt()
        return false
    end

    if self:GetActiveSet() ~= self.pendingTargetKey then
        return false
    end

    local targetKey = self.pendingTargetKey
    self:ClearSwapAttempt()
    local arsenalName = ns.Database:GetSetName(targetKey)
    ns.ApiCompat:ShowCombatMessage(string.format(ns.L.SWAP_SUCCESS, arsenalName), 0.2, 1, 0.2)
    return true
end

function Swap:ToggleOutOfCombat()
    if not ns.Database:IsReady() then
        ns.Core:Print(ns.L.STATUS_INCOMPLETE)
        return false, "incomplete"
    end

    local targetKey = self:GetTargetSetKey()
    local target = ns.Database:GetSet(targetKey)
    local attemptID = self:BeginSwapAttempt(targetKey)
    if ns.ApiCompat:IsCombatLocked() then
        return false, "combat"
    end

    local missing = self:FindMissingItem(target)
    if missing then
        self:ClearSwapAttempt(attemptID)
        ns.Core:Print(string.format(ns.L.MISSING_ITEM, missing.itemLink or missing.name))
        return false, "missing"
    end

    if not ns.ApiCompat:EquipItem(target.main, C.MAIN_HAND_SLOT) then
        self:ClearSwapAttempt(attemptID)
        return false, "failed"
    end
    if target.off and not ns.ApiCompat:IsTwoHanded(target.main) then
        if not ns.ApiCompat:EquipItem(target.off, C.OFF_HAND_SLOT) then
            self:ClearSwapAttempt(attemptID)
            return false, "failed"
        end
    end

    return true, targetKey
end

function Swap:CreateSecureButton()
    if self.button then
        return self.button
    end

    self.button = CreateFrame("Button", C.SECURE_BUTTON_NAME, nil, "SecureActionButtonTemplate")
    self.button:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    if type(GetCVarBool) == "function" then
        self.button:SetAttribute("useOnKeyDown", GetCVarBool("ActionButtonUseKeyDown"))
    end
    self:RefreshSecureButton()
    return self.button
end

function Swap:RefreshSecureButton()
    if not self.button then
        return
    end
    if ns.ApiCompat:IsCombatLocked() then
        self.refreshPending = true
        return
    end

    local macroText = self:BuildMacro(ns.Database:GetSet("A"), ns.Database:GetSet("B"))
    if #macroText > C.MAX_MACRO_BYTES then
        ns.Core:Print("The generated swap action is too long and was not activated.")
        return
    end

    self.button:SetAttribute("type", "macro")
    self.button:SetAttribute("macrotext", macroText)
    self.refreshPending = false
end

function Swap:OnCombatEnded()
    if self.refreshPending then
        self:RefreshSecureButton()
    end
end

function Swap:GetBindingKey()
    return ns.ApiCompat:GetBindingKey(C.BINDING_ACTION)
end

function Swap:ClearBinding()
    if ns.ApiCompat:IsCombatLocked() then
        return false, "combat"
    end

    local changed = false
    local attempts = 0
    local key = self:GetBindingKey()
    while key and attempts < 8 do
        attempts = attempts + 1
        local ok = SetBinding(key)
        if ok == false then
            return false, "failed"
        end
        changed = true
        key = self:GetBindingKey()
    end

    if key then
        return false, "failed"
    end

    if changed and type(SaveBindings) == "function" then
        SaveBindings(GetCurrentBindingSet())
    end
    return true
end

function Swap:SetBinding(key)
    if ns.ApiCompat:IsCombatLocked() then
        return false, "combat"
    end
    if type(key) ~= "string" or key == "" or type(SetBindingClick) ~= "function" then
        return false, "invalid"
    end

    local cleared, clearReason = self:ClearBinding()
    if not cleared then
        return false, clearReason
    end
    local ok = SetBindingClick(key, C.SECURE_BUTTON_NAME, "LeftButton")
    if ok == false then
        return false, "failed"
    end
    if type(SaveBindings) == "function" then
        SaveBindings(GetCurrentBindingSet())
    end
    return true
end
