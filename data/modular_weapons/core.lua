-- Projectile:GetType()
-- 0 = Projectile
-- 1 = LaserBlast
-- 2 = Asteroid
-- 3 = Missile
-- 4 = BombProjectile
-- 5 = BeamWeapon
-- 6 = PDSFire

local addDamage = mods.modularWeapons.addDamage
local totalShots = mods.modularWeapons.totalShots
local slowdownWeapon = mods.modularWeapons.slowdownWeapon
local TEXTS = mods.modularWeapons.texts

local STATUS_MODULE = 0
local ATTRIBUTE_MODULE = 1
local MAX_BOOST = 3

---@alias ModuleFunctions {
---     type: integer,
---     attach?: fun(w: Hyperspace.ProjectileFactory),
---     remove?: fun(w: Hyperspace.ProjectileFactory),
---     fire?: fun(p: Hyperspace.Projectile, w:Hyperspace.ProjectileFactory),
---     compatible?: fun(w: Hyperspace.ProjectileFactory): boolean }
---@type table<string, ModuleFunctions>
local MODULES = {
    bio = { type = STATUS_MODULE },
    cooldown = { type = STATUS_MODULE },
    lockdown = { type = STATUS_MODULE },
    pierce = { type = STATUS_MODULE },
    stun = { type = STATUS_MODULE },
    adapt = { type = STATUS_MODULE }, -- dlc
    chain = { type = STATUS_MODULE }, -- dlc

    accuracy = { type = ATTRIBUTE_MODULE },
    fire = { type = ATTRIBUTE_MODULE },
    hull = { type = ATTRIBUTE_MODULE },
    power = { type = ATTRIBUTE_MODULE },
    charge = { type = ATTRIBUTE_MODULE }, -- dlc
}

local MODULES_STATUS = {
    'bio',
    'cooldown',
    'lockdown',
    'pierce',
    'stun',
    'adapt',
    'chain',
}

local MODULES_ATTRIBUTE = {
    'accuracy',
    'fire',
    'hull',
    'power',
    'charge',
}

---@param moduleLower string
---@param weapon Hyperspace.ProjectileFactory
---@return boolean
local function isCompatibleModule(moduleLower, weapon)
    local module = MODULES[moduleLower]
    return module and (module.compatible == nil or module.compatible(weapon))
end

function MODULES.bio.fire(proj)
    local damage = proj.damage
    damage.iPersDamage = damage.iPersDamage + 2
end

function MODULES.lockdown.fire(proj)
    local damage = proj.damage
    damage.bLockdown = true
end

function MODULES.pierce.fire(proj)
    local damage = proj.damage
    damage.iShieldPiercing = damage.iShieldPiercing + 1
    damage.breachChance = damage.breachChance + 3
end

function MODULES.stun.fire(proj)
    local damage = proj.damage
    damage.stunChance = damage.stunChance + 10
    damage.iStun = damage.iStun + 10
end

function MODULES.adapt.attach(weapon)
    Hyperspace.ships.player.weaponSystem:ForceDecreasePower(99)
    weapon.requiredPower = weapon.requiredPower + 1
end

function MODULES.adapt.remove(weapon)
    Hyperspace.ships.player.weaponSystem:ForceDecreasePower(99)
    weapon.requiredPower = weapon.requiredPower - 1
end

function MODULES.adapt.fire(proj, weapon)
    local volleys = weapon.table.modularWeapons.volleys
    if volleys > 0 then
        addDamage(proj.damage, volleys)
    end
end

function MODULES.accuracy.fire(proj)
    if proj:GetType() == 5 then
        local damage = proj.damage
        damage.iShieldPiercing = damage.iShieldPiercing + 1
    else
        local customDamage = proj.extend.customDamage
        customDamage.accuracyMod = customDamage.accuracyMod + 20
    end
end

function MODULES.fire.fire(proj)
    local damage = proj.damage
    damage.fireChance = damage.fireChance + 3
end

function MODULES.hull.fire(proj)
    local damage = proj.damage
    damage.bHullBuster = true
    damage.breachChance = damage.breachChance + 3
end

function MODULES.power.attach(weapon)
    Hyperspace.ships.player.weaponSystem:ForceDecreasePower(99)
    weapon.requiredPower = weapon.requiredPower + 1
end

function MODULES.power.remove(weapon)
    Hyperspace.ships.player.weaponSystem:ForceDecreasePower(99)
    weapon.requiredPower = weapon.requiredPower - 1
end

function MODULES.power.fire(proj)
    addDamage(proj.damage, 1)
end

function MODULES.charge.attach(weapon)
    local weaponTable = weapon.table.modularWeapons
    weaponTable.origNumShots = weapon.numShots
    weapon.numShots = math.min(weapon.numShots, 1)
    weaponTable.totalShots = totalShots(weapon)
end

function MODULES.charge.remove(weapon)
    local weaponTable = weapon.table.modularWeapons
    weapon.numShots = weaponTable.origNumShots
    weaponTable.totalShots = totalShots(weapon)
end

function MODULES.charge.compatible(weapon)
    return weapon.blueprint.typeName ~= "BEAM" and weapon.numShots > 1
end

script.on_internal_event(Defines.InternalEvents_CONSTRUCT_PROJECTILE_FACTORY, function(weapon)
    weapon.table.modularWeapons = {}
    local weaponTable = weapon.table.modularWeapons
    weaponTable.installed = {}
    weaponTable.status = false
    weaponTable.attribute = false
    weaponTable.totalShots = totalShots(weapon)
    weaponTable.shots = 0
    weaponTable.volleys = 0
    weaponTable.origNumShots = weapon.numShots
end)

local function checkModuleStatus(weaponTable)
    ---@type string | false
    local hasStatus = false
    ---@type string | false
    local hasAttribute = false
    for moduleLower in pairs(weaponTable.installed) do
        local module = MODULES[moduleLower]
        if module then
            --local str = string.gsub(moduleLower, "^%l", string.upper)
            local str = TEXTS.modules[moduleLower].short()
            if module.type == STATUS_MODULE then
                hasStatus = str
            else
                hasAttribute = str
            end
        end
    end
    weaponTable.status = hasStatus
    weaponTable.attribute = hasAttribute
end

local function attachModule(weapon, moduleLower)
    local moduleFunctions = MODULES[moduleLower]
    if not moduleFunctions then
        return
    end
    local weaponTable = weapon.table.modularWeapons
    weaponTable.installed[moduleLower] = true
    checkModuleStatus(weaponTable)
    local fireFunction = moduleFunctions.fire
    if fireFunction then
        weaponTable.installed[moduleLower] = fireFunction
    end
    local attachFunction = moduleFunctions.attach
    if attachFunction then
        attachFunction(weapon)
    end
end

local function removeModule(weapon, moduleLower)
    local moduleFunctions = MODULES[moduleLower]
    if not moduleFunctions then
        return
    end
    local weaponTable = weapon.table.modularWeapons
    weaponTable.installed[moduleLower] = nil
    checkModuleStatus(weaponTable)
    local removeFunction = moduleFunctions.remove
    if removeFunction then
        removeFunction(weapon)
    end
end

local emptyReq = Hyperspace.ChoiceReq()

---@param slot number
---@param weapon Hyperspace.ProjectileFactory
---@param playerShip Hyperspace.ShipManager
---@return Hyperspace.LocationEvent
local function createSlotEvent(slot, weapon, playerShip)
    local eventGen = Hyperspace.Event
    local blueprints = Hyperspace.Blueprints
    local event = eventGen:CreateEvent("_MW_EVENT_TEMPLATE_MODIFY_WEAPON_SLOT", 0, false)
    event.eventName = "_MW_EVENT_MODIFY_WEAPON_SLOT_" .. slot
    local weaponTable = weapon.table.modularWeapons
    local installed = weaponTable.installed
    local text = "\n" .. TEXTS.weapon_name(weapon.name, (next(installed) == nil) and TEXTS.none() or "")
    for moduleLower in pairs(installed) do
        local moduleUpper = string.upper(moduleLower)
        local removeEvent = eventGen:CreateEvent("_MW_EVENT_TEMPLATE_MODULE_REMOVE", 0, false)
        local fullName = TEXTS.modules[moduleLower].full()
        removeEvent.eventName = "_MW_EVENT_MODULE_REMOVE_" .. slot .. "_" .. moduleUpper
        removeEvent.stuff.weapon = blueprints:GetWeaponBlueprint("MODULE_" .. moduleUpper)
        event:AddChoice(removeEvent, TEXTS.remove_module(fullName), emptyReq, true)
        text = text .. "\n" .. TEXTS.installed_module_entry(fullName, TEXTS.modules[moduleLower].effects())
    end
    local origText = event.text:GetText()
    event.text.data = origText .. text
    event.text.isLiteral = true
    local invalidEvent = eventGen:GetBaseEvent("_MW_EVENT_OPTION_INVALID", 0, false, -1)
    if not weaponTable.status then
        for _, moduleLower in ipairs(MODULES_STATUS) do
            local moduleUpper = string.upper(moduleLower)
            if not installed[moduleLower] and playerShip:HasEquipment("MODULE_" .. moduleUpper, true) > 0 then
                local fullName = TEXTS.modules[moduleLower].full()
                if isCompatibleModule(moduleLower, weapon) then
                    local attachEvent = eventGen:CreateEvent("_MW_EVENT_TEMPLATE_MODULE_ATTACH", 0, false)
                    local effects = TEXTS.modules[moduleLower].effects()
                    attachEvent.eventName = "_MW_EVENT_MODULE_ATTACH_" .. slot .. "_" .. moduleUpper
                    attachEvent.stuff.removeItem = "MODULE_" .. moduleUpper
                    event:AddChoice(attachEvent, TEXTS.attach_module(fullName, effects), emptyReq, false)
                else
                    event:AddChoice(invalidEvent, TEXTS.cannot_attach_module(fullName), emptyReq, true)
                end
            end
        end
    end
    if not weaponTable.attribute then
        for _, moduleLower in ipairs(MODULES_ATTRIBUTE) do
            local moduleUpper = string.upper(moduleLower)
            if not installed[moduleLower] and playerShip:HasEquipment("MODULE_" .. moduleUpper, true) > 0 then
                local fullName = TEXTS.modules[moduleLower].full()
                if isCompatibleModule(moduleLower, weapon) then
                    local attachEvent = eventGen:CreateEvent("_MW_EVENT_TEMPLATE_MODULE_ATTACH", 0, false)
                    local effects = TEXTS.modules[moduleLower].effects()
                    attachEvent.eventName = "_MW_EVENT_MODULE_ATTACH_" .. slot .. "_" .. moduleUpper
                    attachEvent.stuff.removeItem = "MODULE_" .. moduleUpper
                    event:AddChoice(attachEvent, TEXTS.attach_module(fullName, effects), emptyReq, false)
                else
                    event:AddChoice(invalidEvent, TEXTS.cannot_attach_module(fullName), emptyReq, true)
                end
            end
        end
    end
    --Hyperspace.App.gui.equipScreen:GetCargoHold()
    return event
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
    if event.eventName ~= "_MW_EVENT_MODIFY_WEAPON" then
        return
    end
    local playerShip = Hyperspace.ships.player
    local weaponSys = playerShip.weaponSystem
    if not weaponSys then
        return
    end
    local weapons = weaponSys.weapons
    local size = weapons:size()
    if size <= 0 then
        return
    end
    local invalidEvent = Hyperspace.Event:GetBaseEvent("_MW_EVENT_OPTION_INVALID", 0, false, -1)
    for i = 0, size - 1 do
        ---@type Hyperspace.ProjectileFactory
        local weapon = weapons[i]
        local bpName = weapon.blueprint.name
        if string.sub(bpName, 1, 7) ~= "MODULE_" and string.sub(bpName, 1, 8) ~= "MODULAR_" then
            event:AddChoice(createSlotEvent(i, weapon, playerShip), TEXTS.modify_slot(i + 1, weapon.name), emptyReq, true)
        else
            event:AddChoice(invalidEvent, TEXTS.cannot_modify_slot(i + 1, weapon.name), emptyReq, true)
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.POST_CREATE_CHOICEBOX, function(box, event)
    local name = event.eventName
    if string.sub(name, 1, 17) ~= "_MW_EVENT_MODULE_" then
        return
    end
    local op = string.sub(name, 18, 24)
    local isAttach = (op == "ATTACH_")
    local isRemove = (op == "REMOVE_")
    if not (isAttach or isRemove) then
        return
    end
    local slot = tonumber(string.sub(name, 25, 25))
    if not slot then
        return
    end
    local moduleUpper = string.sub(name, 27)
    local moduleLower = string.lower(moduleUpper)
    if not MODULES[moduleLower] then
        return
    end
    local weapon = Hyperspace.ships.player.weaponSystem.weapons[slot]
    if isAttach then
        attachModule(weapon, moduleLower)
    else
        removeModule(weapon, moduleLower)
    end
end)

script.on_internal_event(Defines.InternalEvents.WEAPON_RENDERBOX, function(weapon, _, _, l1, l2, l3)
    local weaponTable = weapon.table.modularWeapons
    local installed = weaponTable.installed
    if next(installed) == nil then
        return Defines.Chain.CONTINUE, l1, l2, l3
    end
    local text = ''
    if weaponTable.attribute then
        text = text .. weaponTable.attribute
    end
    if weaponTable.status then
        text = text .. weaponTable.status
    end
    local volleys = weaponTable.volleys
    if volleys > 0 and (installed.chain or installed.adapt) then
        text = text .. '+' .. volleys
    end
    if #l2 > 0 then
        return Defines.Chain.CONTINUE, l1, l2, l3 .. text
    else
        return Defines.Chain.CONTINUE, l1, text, l3
    end
end)

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(proj, weapon)
    local weaponTable = weapon.table.modularWeapons
    local installed = weaponTable.installed
    for _, fireFunction in pairs(installed) do
        if fireFunction ~= true then
            fireFunction(proj, weapon)
        end
    end
    local shots = weaponTable.shots + 1
    if shots >= weaponTable.totalShots then
        weaponTable.shots = 0
        weaponTable.volleys = math.min(weaponTable.volleys + 1, MAX_BOOST)
    else
        weaponTable.shots = shots
    end
end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipMgr)
    local weaponSys = shipMgr.weaponSystem
    if not weaponSys or weaponSys.iHackEffect >= 2 then
        return
    end
    local weapons = weaponSys.weapons
    local size = weapons:size()
    for i = 0, size - 1 do
        local weapon = weapons[i]
        local weaponTable = weapon.table.modularWeapons
        if weapon.powered then
            local installed = weaponTable.installed
            if installed.power then
                slowdownWeapon(weapon, 0.2)
            end
            if installed.adapt then
                slowdownWeapon(weapon, 0.2)
            end
        else
            weaponTable.shots = 0
            weaponTable.volleys = 0
        end
    end
end)

---@param shipMgr Hyperspace.ShipManager
local function resetWeapons(shipMgr)
    local weaponSys = shipMgr.weaponSystem
    if not weaponSys or weaponSys.iHackEffect >= 2 then
        return
    end
    local weapons = weaponSys.weapons
    local size = weapons:size()
    for i = 0, size - 1 do
        local weapon = weapons[i]
        local weaponTable = weapon.table.modularWeapons
        weaponTable.shots = 0
        weaponTable.volleys = 0
    end
end

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, resetWeapons)
script.on_internal_event(Defines.InternalEvents.ON_WAIT, resetWeapons)

script.on_internal_event(Defines.InternalEvents.WEAPON_COOLDOWN_MOD, function(weapon, mod)
    local weaponTable = weapon.table.modularWeapons
    local installed = weaponTable.installed
    if next(installed) == nil then
        return Defines.Chain.CONTINUE, mod
    end
    if installed.charge then
        mod = mod * 0.5 / math.max(weaponTable.origNumShots, 1)
    end
    if installed.cooldown then
        mod = mod * 0.8
    end
    if installed.chain then
        mod = mod * (1 - 0.1 * weaponTable.volleys)
    end
    return Defines.Chain.CONTINUE, mod
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, function(shipMgr, _, location, damage, _, beamHit)
    if damage.bLockdown and beamHit == Defines.BeamHit.NEW_ROOM then
        local ship = shipMgr.ship
        local room = ship:GetSelectedRoomId(location.x, location.y, true)
        ship:LockdownRoom(room, location)
    end
    return Defines.Chain.CONTINUE, beamHit
end)
