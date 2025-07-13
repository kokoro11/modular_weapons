mods.modularWeapons = {}

local Settings = Hyperspace.Settings
local TextMeta = {
    __index = function(texts)
        return texts['']
    end,
    __call = function(texts, ...)
        local success, result = pcall(string.format, texts[Settings.language], ...)
        if success then
            return result
        else
            log("ERROR: " .. result)
            return texts[Settings.language]
        end
    end
}

---@alias Text table<string, string> | fun(...): string
---@param texts table<string, string>
---@return Text
function mods.modularWeapons.Text(texts)
    setmetatable(texts, TextMeta)
    return texts
end

local Text = mods.modularWeapons.Text
local ErrorMeta = {
    __index = function(_, entry)
        return Text {
            [''] = "ERROR_Text_entry_not_found_[" .. entry .. "]"
        }
    end
}

function mods.modularWeapons.TextCollection()
    local collection = {}
    setmetatable(collection, ErrorMeta)
    return collection
end

-- Manually charge a weapon (by Multiverse team)
---@param weapon Hyperspace.ProjectileFactory
---@param mod number
function mods.modularWeapons.chargeWeapon(weapon, mod)
    local subCooldown = weapon.subCooldown
    if not weapon.powered or subCooldown.second > subCooldown.first then
        return
    end
    local cooldown = weapon.cooldown
    local oldFirst = cooldown.first
    local oldSecond = cooldown.second
    local time_increment = Hyperspace.FPS.SpeedFactor / 16

    cooldown.first = math.min(cooldown.first + time_increment * mod, cooldown.second)

    if cooldown.second == cooldown.first and oldFirst < oldSecond and weapon.chargeLevel < weapon.blueprint.chargeLevels then
        weapon.chargeLevel = weapon.chargeLevel + 1
        weapon.weaponVisual.boostLevel = 0
        weapon.weaponVisual.boostAnim:SetCurrentFrame(0)
        if weapon.chargeLevel < weapon.blueprint.chargeLevels then cooldown.first = 0 end
    else
        subCooldown.first = math.min(subCooldown.first + time_increment, subCooldown.second)
    end
end

---@param weapon Hyperspace.ProjectileFactory
---@param mod number
function mods.modularWeapons.slowdownWeapon(weapon, mod)
    local cooldown = weapon.cooldown
    if cooldown.first <= 0 or cooldown.second <= 0 or cooldown.first >= cooldown.second then
        return
    end
    local time_increment = Hyperspace.FPS.SpeedFactor / 16
    cooldown.first = math.max(cooldown.first - time_increment * mod, 0)
end

---@param weapon Hyperspace.ProjectileFactory
---@return integer
function mods.modularWeapons.totalShots(weapon)
    if weapon.blueprint.typeName == "BEAM" then
        return 1
    end
    local shots = weapon.numShots
    local chargeLevels = weapon.blueprint.chargeLevels
    if chargeLevels > 0 then
        shots = shots * chargeLevels
    end
    local size = weapon.blueprint.miniProjectiles:size()
    if size > 0 then
        shots = shots * size
    end
    return shots
end

---@param damage Hyperspace.Damage
---@param n integer
function mods.modularWeapons.addDamage(damage, n)
    local hullDamage = damage.iDamage
    local sysDamage = damage.iDamage + damage.iSystemDamage
    local ionDamage = damage.iIonDamage
    local persDamage = damage.iPersDamage
    if hullDamage > 0 then
        hullDamage = hullDamage + n
    end
    if sysDamage > 0 then
        sysDamage = sysDamage + n
    end
    if ionDamage > 0 then
        ionDamage = ionDamage + n
    end
    if persDamage > 0 then
        persDamage = persDamage + n
    end
    damage.iDamage = hullDamage
    damage.iSystemDamage = sysDamage - hullDamage
    damage.iIonDamage = ionDamage
    damage.iPersDamage = persDamage
end
