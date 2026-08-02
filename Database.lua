local addonName, ns = ...

local Database = {}
ns.Database = Database

local VALID_POINTS = {
    TOP = true,
    BOTTOM = true,
    LEFT = true,
    RIGHT = true,
    CENTER = true,
    TOPLEFT = true,
    TOPRIGHT = true,
    BOTTOMLEFT = true,
    BOTTOMRIGHT = true,
}

local function copyItem(item)
    if type(item) ~= "table" then
        return nil
    end

    local itemID = tonumber(item.itemID)
    local equipLoc = type(item.equipLoc) == "string" and item.equipLoc or nil
    if not itemID or itemID <= 0 or not equipLoc then
        return nil
    end

    return {
        itemID = math.floor(itemID),
        itemLink = type(item.itemLink) == "string" and item.itemLink or ("item:" .. math.floor(itemID)),
        name = type(item.name) == "string" and item.name or ("Item " .. math.floor(itemID)),
        icon = item.icon,
        equipLoc = equipLoc,
    }
end

local function sanitizeSet(set)
    set = type(set) == "table" and set or {}
    local main = copyItem(set.main)
    local off = copyItem(set.off)

    if main and not ns.ApiCompat:IsMainHandType(main.equipLoc) then
        main = nil
    end
    if off and not ns.ApiCompat:IsOffHandType(off.equipLoc) then
        off = nil
    end
    if main and ns.ApiCompat:IsTwoHanded(main) then
        off = nil
    end

    return {
        main = main,
        off = off,
    }
end

function Database:Initialize(saved)
    saved = type(saved) == "table" and saved or {}
    local frame = type(saved.frame) == "table" and saved.frame or {}
    local sets = type(saved.sets) == "table" and saved.sets or {}

    self.data = {
        schemaVersion = ns.Constants.SCHEMA_VERSION,
        frame = {
            point = VALID_POINTS[frame.point] and frame.point or ns.Defaults.frame.point,
            relativePoint = VALID_POINTS[frame.relativePoint] and frame.relativePoint or ns.Defaults.frame.relativePoint,
            x = math.max(-5000, math.min(5000, tonumber(frame.x) or ns.Defaults.frame.x)),
            y = math.max(-5000, math.min(5000, tonumber(frame.y) or ns.Defaults.frame.y)),
        },
        sets = {
            A = sanitizeSet(sets.A),
            B = sanitizeSet(sets.B),
        },
    }

    SimpleArsenalSwapDB = self.data
    return self.data
end

function Database:GetSet(setKey)
    return self.data and self.data.sets and self.data.sets[setKey]
end

function Database:SetItem(setKey, slotKey, item)
    local set = self:GetSet(setKey)
    if not set or (slotKey ~= "main" and slotKey ~= "off") then
        return false
    end

    local copied = copyItem(item)
    if slotKey == "main" then
        if copied and not ns.ApiCompat:IsMainHandType(copied.equipLoc) then
            return false
        end
        set.main = copied
        if copied and ns.ApiCompat:IsTwoHanded(copied) then
            set.off = nil
        end
    else
        if copied and not ns.ApiCompat:IsOffHandType(copied.equipLoc) then
            return false
        end
        if set.main and ns.ApiCompat:IsTwoHanded(set.main) then
            return false
        end
        set.off = copied
    end

    return true
end

function Database:ClearItem(setKey, slotKey)
    return self:SetItem(setKey, slotKey, nil)
end

function Database:IsReady()
    local setA = self:GetSet("A")
    local setB = self:GetSet("B")
    return setA and setA.main and setB and setB.main and true or false
end

function Database:SaveFramePosition(frame)
    if not self.data or not frame or type(frame.GetPoint) ~= "function" then
        return
    end

    local point, _, relativePoint, x, y = frame:GetPoint(1)
    self.data.frame.point = VALID_POINTS[point] and point or "CENTER"
    self.data.frame.relativePoint = VALID_POINTS[relativePoint] and relativePoint or self.data.frame.point
    self.data.frame.x = tonumber(x) or 0
    self.data.frame.y = tonumber(y) or 0
end
