local addonName, ns = ...

local Options = {}
ns.Options = Options

local L = ns.L
local BINDING_CONFIRM_DIALOG = "SIMPLE_ARSENAL_SWAP_CONFIRM_BINDING"

local function createBackdropFrame(frameType, name, parent, template)
    local backdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
    return CreateFrame(frameType, name, parent, template or backdropTemplate)
end

local function setPanelBackdrop(frame, alpha)
    if type(frame.SetBackdrop) ~= "function" then
        return
    end
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, alpha or 0.92)
end

local function formatKey(key)
    if type(key) ~= "string" or key == "" then
        return L.NOT_BOUND
    end
    if type(GetBindingText) == "function" then
        local text = GetBindingText(key, "KEY_")
        if type(text) == "string" and text ~= "" then
            return text
        end
    end
    return key
end

local function isModifierKey(key)
    return key == "LSHIFT" or key == "RSHIFT"
        or key == "LCTRL" or key == "RCTRL"
        or key == "LALT" or key == "RALT"
        or key == "LMETA" or key == "RMETA"
end

local function buildBindingKey(key)
    if isModifierKey(key) then
        return nil
    end

    local parts = {}
    if IsControlKeyDown and IsControlKeyDown() then
        parts[#parts + 1] = "CTRL"
    end
    if IsAltKeyDown and IsAltKeyDown() then
        parts[#parts + 1] = "ALT"
    end
    if IsShiftKeyDown and IsShiftKeyDown() then
        parts[#parts + 1] = "SHIFT"
    end
    parts[#parts + 1] = key
    return table.concat(parts, "-")
end

function Options:CreateItemSlot(parent, setKey, slotKey, labelText, x)
    local button = createBackdropFrame("Button", nil, parent)
    button:SetSize(58, 58)
    button:SetPoint("TOPLEFT", x, -48)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    setPanelBackdrop(button, 0.75)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 5, -5)
    button.icon:SetPoint("BOTTOMRIGHT", -5, 5)
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    button.disabledTexture = button:CreateTexture(nil, "OVERLAY")
    button.disabledTexture:SetAllPoints(button.icon)
    button.disabledTexture:SetColorTexture(0.05, 0.05, 0.05, 0.72)
    button.disabledTexture:Hide()

    button.label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetPoint("TOP", button, "BOTTOM", 0, -4)
    button.label:SetText(labelText)

    button.setKey = setKey
    button.slotKey = slotKey

    local function receiveItem()
        Options:ReceiveItem(button)
    end

    button:SetScript("OnReceiveDrag", receiveItem)
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            Options:ClearSlot(button)
        elseif type(GetCursorInfo) == "function" and GetCursorInfo() == "item" then
            receiveItem()
        end
    end)
    button:SetScript("OnEnter", function(self)
        local set = ns.Database:GetSet(self.setKey)
        local item = set and set[self.slotKey]
        if item and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(item.itemLink or ("item:" .. item.itemID))
            GameTooltip:Show()
        elseif self.disabledReason and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.disabledReason, 1, 0.82, 0)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    return button
end

function Options:CreateSetPanel(parent, setKey, title, x)
    local panel = createBackdropFrame("Frame", nil, parent)
    panel:SetSize(205, 130)
    panel:SetPoint("TOPLEFT", x, -58)
    setPanelBackdrop(panel, 0.58)

    panel.title = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    panel.title:SetSize(150, 22)
    panel.title:SetPoint("TOP", 0, -7)
    panel.title:SetAutoFocus(false)
    panel.title:SetMaxLetters(24)
    if GameFontNormal and type(panel.title.SetFontObject) == "function" then
        panel.title:SetFontObject(GameFontNormal)
    end
    panel.title:SetJustifyH("CENTER")
    panel.title:SetText(title)
    panel.title:SetScript("OnEnterPressed", function(self)
        Options:SaveSetName(panel)
        self:ClearFocus()
    end)
    panel.title:SetScript("OnEditFocusLost", function()
        Options:SaveSetName(panel)
    end)
    panel.title:SetScript("OnEscapePressed", function(self)
        self:SetText(ns.Database:GetSetName(setKey))
        self:ClearFocus()
    end)
    panel.title:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L.NAME_TOOLTIP, 1, 0.82, 0)
            GameTooltip:Show()
        end
    end)
    panel.title:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
    panel.setKey = setKey

    panel.main = self:CreateItemSlot(panel, setKey, "main", L.MAIN_HAND, 34)
    panel.off = self:CreateItemSlot(panel, setKey, "off", L.OFF_HAND, 113)
    return panel
end

function Options:SaveSetName(panel)
    if not panel or not panel.title then
        return
    end
    ns.Database:SetSetName(panel.setKey, panel.title:GetText())
    panel.title:SetText(ns.Database:GetSetName(panel.setKey))
    self:RefreshStatus()
end

function Options:CreateFrame()
    if self.frame then
        return self.frame
    end

    self:RegisterBindingConflictDialog()

    local frame = createBackdropFrame("Frame", "SimpleArsenalSwapOptions", UIParent)
    frame:SetSize(470, 315)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    setPanelBackdrop(frame, 0.96)

    local position = ns.Database.data.frame
    frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
    frame:SetScript("OnDragStart", function(self)
        if not ns.ApiCompat:IsCombatLocked() then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        ns.Database:SaveFramePosition(self)
    end)
    frame:SetScript("OnHide", function(self)
        ns.Database:SaveFramePosition(self)
        Options:StopBindingCapture()
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -16)
    frame.title:SetText(L.ADDON_NAME)

    frame.help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.help:SetPoint("TOPLEFT", 20, -38)
    frame.help:SetPoint("TOPRIGHT", -20, -38)
    frame.help:SetJustifyH("CENTER")
    frame.help:SetText(L.DRAG_HELP)

    frame.setA = self:CreateSetPanel(frame, "A", L.ARSENAL_A, 20)
    frame.setB = self:CreateSetPanel(frame, "B", L.ARSENAL_B, 245)

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.status:SetPoint("TOPLEFT", 22, -205)
    frame.status:SetPoint("TOPRIGHT", -22, -205)
    frame.status:SetJustifyH("CENTER")
    frame.status:SetHeight(32)

    frame.hotkeyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.hotkeyLabel:SetPoint("BOTTOMLEFT", 24, 28)
    frame.hotkeyLabel:SetText(L.HOTKEY .. ":")

    frame.hotkey = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.hotkey:SetSize(180, 24)
    frame.hotkey:SetPoint("LEFT", frame.hotkeyLabel, "RIGHT", 10, 0)
    frame.hotkey:SetScript("OnClick", function()
        Options:StartBindingCapture()
    end)

    frame.clearHotkey = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.clearHotkey:SetSize(62, 24)
    frame.clearHotkey:SetPoint("LEFT", frame.hotkey, "RIGHT", 6, 0)
    frame.clearHotkey:SetText(L.CLEAR)
    frame.clearHotkey:SetScript("OnClick", function()
        Options:ClearBinding()
    end)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.close:SetSize(62, 24)
    frame.close:SetPoint("BOTTOMRIGHT", -18, 18)
    frame.close:SetText(L.CLOSE)
    frame.close:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame.capture = CreateFrame("Frame", nil, frame)
    frame.capture:SetAllPoints(frame)
    frame.capture:SetFrameLevel(frame:GetFrameLevel() + 20)
    frame.capture:EnableKeyboard(true)
    if type(frame.capture.SetPropagateKeyboardInput) == "function" then
        frame.capture:SetPropagateKeyboardInput(false)
    end
    frame.capture:Hide()
    frame.capture:SetScript("OnKeyDown", function(_, key)
        Options:OnBindingKeyDown(key)
    end)

    self.frame = frame
    self:Refresh()
    frame:Hide()
    return frame
end

function Options:RegisterBindingConflictDialog()
    if type(StaticPopupDialogs) ~= "table" or StaticPopupDialogs[BINDING_CONFIRM_DIALOG] then
        return
    end

    StaticPopupDialogs[BINDING_CONFIRM_DIALOG] = {
        text = L.BINDING_REPLACE_CONFIRM,
        button1 = L.BINDING_REPLACE,
        button2 = CANCEL or "Cancel",
        OnAccept = function()
            local pending = Options.pendingBindingConfirmation
            Options.pendingBindingConfirmation = nil
            if pending then
                Options:ApplyBinding(pending.key)
            end
        end,
        OnCancel = function()
            Options.pendingBindingConfirmation = nil
            Options:StopBindingCapture()
            Options:SetMessage(L.BINDING_NOT_REPLACED, false)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function Options:SetMessage(message, red)
    if not self.frame then
        return
    end
    self.frame.status:SetTextColor(red and 1 or 0.9, red and 0.25 or 0.85, red and 0.25 or 0.35)
    self.frame.status:SetText(message or "")
end

function Options:ReceiveItem(button)
    if ns.ApiCompat:IsCombatLocked() then
        self:SetMessage(L.COMBAT_LOCKED, true)
        ns.ApiCompat:ClearCursor()
        return
    end

    local item, reason = ns.ApiCompat:GetCursorItem()
    if not item then
        self:SetMessage(reason == "missing-info" and L.ITEM_DATA_MISSING or L.NO_CURSOR_ITEM, true)
        ns.ApiCompat:ClearCursor()
        return
    end

    local valid = button.slotKey == "main"
        and ns.ApiCompat:IsMainHandType(item.equipLoc)
        or button.slotKey == "off" and ns.ApiCompat:IsOffHandType(item.equipLoc)
    if not valid then
        self:SetMessage(button.slotKey == "main" and L.INVALID_MAIN or L.INVALID_OFF, true)
        ns.ApiCompat:ClearCursor()
        return
    end

    if not ns.Database:SetItem(button.setKey, button.slotKey, item) then
        self:SetMessage(button.slotKey == "main" and L.INVALID_MAIN or L.INVALID_OFF, true)
        ns.ApiCompat:ClearCursor()
        return
    end

    ns.ApiCompat:ClearCursor()
    ns.Swap:RefreshSecureButton()
    self:Refresh()
end

function Options:ClearSlot(button)
    if ns.ApiCompat:IsCombatLocked() then
        self:SetMessage(L.COMBAT_LOCKED, true)
        return
    end
    ns.Database:ClearItem(button.setKey, button.slotKey)
    ns.Swap:RefreshSecureButton()
    self:Refresh()
end

function Options:RefreshItemSlot(button)
    local set = ns.Database:GetSet(button.setKey)
    local item = set and set[button.slotKey]
    local offDisabled = button.slotKey == "off" and set and ns.ApiCompat:IsTwoHanded(set.main)

    button.disabledReason = offDisabled and L.TWO_HANDED or nil
    button.disabledTexture:SetShown(offDisabled)
    button.icon:SetDesaturated(offDisabled)
    button.icon:SetTexture(item and item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
end

function Options:RefreshStatus()
    if not ns.Database:IsReady() then
        self:SetMessage(L.CONFIGURE_BOTH, true)
        return
    end

    local active = ns.Swap:GetActiveSet()
    if active == "A" then
        self:SetMessage(string.format(L.ACTIVE_SET, ns.Database:GetSetName("A")), false)
    elseif active == "B" then
        self:SetMessage(string.format(L.ACTIVE_SET, ns.Database:GetSetName("B")), false)
    else
        self:SetMessage(string.format(L.ACTIVE_OTHER, ns.Database:GetSetName("A")), false)
    end
end

function Options:Refresh()
    if not self.frame then
        return
    end

    self:RefreshItemSlot(self.frame.setA.main)
    self:RefreshItemSlot(self.frame.setA.off)
    self:RefreshItemSlot(self.frame.setB.main)
    self:RefreshItemSlot(self.frame.setB.off)
    if type(self.frame.setA.title.HasFocus) ~= "function" or not self.frame.setA.title:HasFocus() then
        self.frame.setA.title:SetText(ns.Database:GetSetName("A"))
    end
    if type(self.frame.setB.title.HasFocus) ~= "function" or not self.frame.setB.title:HasFocus() then
        self.frame.setB.title:SetText(ns.Database:GetSetName("B"))
    end
    self.frame.hotkey:SetText(formatKey(ns.Swap:GetBindingKey()))
    self:RefreshStatus()

    local active = ns.Swap:GetActiveSet()
    self.frame.setA.title:SetTextColor(active == "A" and 0.2 or 1, active == "A" and 1 or 0.82, active == "A" and 0.2 or 0)
    self.frame.setB.title:SetTextColor(active == "B" and 0.2 or 1, active == "B" and 1 or 0.82, active == "B" and 0.2 or 0)
end

function Options:Show()
    local frame = self:CreateFrame()
    frame:Show()
    frame:Raise()
    self:Refresh()
end

function Options:StartBindingCapture()
    if ns.ApiCompat:IsCombatLocked() then
        self:SetMessage(L.COMBAT_LOCKED, true)
        return
    end

    self.frame.capture:Show()
    if type(self.frame.capture.SetPropagateKeyboardInput) == "function" then
        self.frame.capture:SetPropagateKeyboardInput(false)
    end
    self.frame.hotkey:SetText(L.PRESS_A_KEY)
    self.frame.hotkey:LockHighlight()
end

function Options:StopBindingCapture()
    if not self.frame or not self.frame.capture then
        return
    end
    self.frame.capture:Hide()
    self.frame.hotkey:UnlockHighlight()
    self.frame.hotkey:SetText(formatKey(ns.Swap:GetBindingKey()))
end

function Options:ApplyBinding(bindingKey)
    local ok = ns.Swap:SetBinding(bindingKey)
    self:StopBindingCapture()
    if ok then
        self:SetMessage(string.format(L.BINDING_SAVED, formatKey(bindingKey)), false)
    else
        self:SetMessage(L.BINDING_FAILED, true)
    end
end

function Options:OnBindingKeyDown(key)
    if key == "ESCAPE" then
        self:StopBindingCapture()
        self:SetMessage(L.CAPTURE_CANCELLED, false)
        return
    end
    if key == "BACKSPACE" or key == "DELETE" then
        self:ClearBinding()
        return
    end

    local bindingKey = buildBindingKey(key)
    if not bindingKey then
        return
    end

    local existingAction = type(GetBindingAction) == "function" and GetBindingAction(bindingKey) or ""
    if existingAction ~= "" and existingAction ~= ns.Constants.BINDING_ACTION then
        local actionLabel = ns.ApiCompat:GetBindingLabel(existingAction)
        self:StopBindingCapture()
        self.pendingBindingConfirmation = {
            key = bindingKey,
            actionLabel = actionLabel,
        }
        if type(StaticPopup_Show) == "function" and type(StaticPopupDialogs) == "table"
            and StaticPopupDialogs[BINDING_CONFIRM_DIALOG] then
            StaticPopup_Show(BINDING_CONFIRM_DIALOG, formatKey(bindingKey), actionLabel)
        else
            self.pendingBindingConfirmation = nil
            self:SetMessage(string.format(L.BINDING_USED, formatKey(bindingKey), actionLabel), true)
        end
        return
    end

    self:ApplyBinding(bindingKey)
end

function Options:ClearBinding()
    local ok, reason = ns.Swap:ClearBinding()
    self:StopBindingCapture()
    if ok then
        self:SetMessage(L.BINDING_CLEARED, false)
    else
        self:SetMessage(reason == "combat" and L.COMBAT_LOCKED or L.BINDING_FAILED, true)
    end
end
