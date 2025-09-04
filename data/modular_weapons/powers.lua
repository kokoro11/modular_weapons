--[[ local inspect = require("inspect") ]]

local World = Hyperspace.App.world
local StatBoost = Hyperspace.StatBoost
local StatBoostDefinition = Hyperspace.StatBoostDefinition
local StatBoostManager = Hyperspace.StatBoostManager.GetInstance()
mods.modularWeapons.StatBoostDefinitionGC = getmetatable(StatBoostDefinition)[".instance"].__gc
getmetatable(StatBoostDefinition)[".instance"].__gc = nil

local getPlayerCrewList = mods.modularWeapons.getPlayerCrewList

---@type table<string, Hyperspace.ActivatedPowerDefinition>
local powerDefStore = {}
---@type table<string, Hyperspace.StatBoostDefinition>
local statBoostDefStore = {}
--local miscStatBoostDefStore = {}
--mods.modularWeapons.__nogc = miscStatBoostDefStore

script.on_internal_event(Defines.InternalEvents.POWER_READY, function(power, result)
    if result ~= 1 then
        ---@diagnostic disable-next-line: missing-return-value
        return
    end
    local powerName = power.def.buttonLabel.data
    if not powerDefStore[powerName] or power.crew.table.modularWeaponsPowers[powerName] then
        ---@diagnostic disable-next-line: missing-return-value
        return
    end
    ---@diagnostic disable-next-line: return-type-mismatch
    return 1, 23
end)

local function initCrewPower(crew, powerName)
    if not powerName then
        return false
    end
    local statBoostDef = statBoostDefStore[powerName]
    local powerDef = statBoostDef.powerChange
    local crewPowers = crew.extend.crewPowers
    for i = 0, crewPowers:size() - 1 do
        local power = crewPowers[i]
        if power.enabled and power.def == powerDef then
            --print("initCrewPower:found")
            return false
        end
    end
    StatBoostManager:CreateTimedAugmentBoost(StatBoost(statBoostDef), crew)
    return true
end

---@param crew Hyperspace.CrewMember
local function checkCrewPowerStatus(crew)
    local powers = crew.table.modularWeaponsPowers
    local toAdd = false
    for key, _ in pairs(powers) do
        toAdd = initCrewPower(crew, key) or toAdd
    end
    return toAdd
end

local forceRecheckCounter = -1
function mods.modularWeapons.forceRecheckPowers()
    forceRecheckCounter = 10
end

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipMgr)
    if shipMgr.iShipId ~= 0 or not World.bStartedGame or forceRecheckCounter < 0 then
        return
    end
    if forceRecheckCounter > 0 then
        forceRecheckCounter = forceRecheckCounter - 1
        return
    end
    --print("forceRecheck:begin")
    local crewList = getPlayerCrewList()
    local toAdd = false
    for i = 1, #crewList do
        toAdd = checkCrewPowerStatus(crewList[i]) or toAdd
    end
    if toAdd then
        forceRecheckCounter = 5
        return
    end
    forceRecheckCounter = -1
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function()
    local crewList = getPlayerCrewList()
    for i = 1, #crewList do
        local crew = crewList[i]
        for powerName in pairs(crew.table.modularWeaponsPowers) do
            StatBoostManager:CreateTimedAugmentBoost(StatBoost(statBoostDefStore[powerName]), crew)
        end
    end
end)

local function PowerDef(desc)
    local def = Hyperspace.ActivatedPowerDefinition()
    def:AssignIndex()
    def.hasSpecialPower = true
    -- HOTKEY_FIRST 0
    -- HOTKEY_ALWAYS 1
    -- HOTKEY_NEVER 2
    def.onHotkey = desc.onHotkey or 1
    def.cooldown = desc.cooldown or 10
    def.initialCooldownFraction = desc.initialCooldownFraction or 1
    -- JUMP_COOLDOWN_FULL 0
    -- JUMP_COOLDOWN_RESET 1
    -- JUMP_COOLDOWN_CONTINUE 2
    def.jumpCooldown = desc.jumpCooldown or 0
    if desc.cooldownColor then
        def.cooldownColor = Graphics.GL_Color(
            (desc.cooldownColor[1] or 255) / 255,
            (desc.cooldownColor[2] or 255) / 255,
            (desc.cooldownColor[3] or 255) / 255,
            desc.cooldownColor[4] or 1
        )
    end
    if desc.sounds then
        for i = 1, #desc.sounds do
            def.sounds:push_back(desc.sounds[i])
        end
    end
    if desc.damage then
        for key, value in pairs(desc.damage) do
            def.damage[key] = value
        end
    end
    def.shipFriendlyFire = desc.shipFriendlyFire or false
    def.buttonLabel.data = desc.name
    def.buttonLabel.isLiteral = false
    def.tooltip.data = desc.name .. "_tooltip"
    def.tooltip.isLiteral = false
    def.effectAnim = desc.effectAnim or ""
    def.animFrame = desc.animFrame or -1
    def.powerCharges = desc.powerCharges or 1
    def.initialCharges = desc.initialCharges or 999
    def.chargesPerJump = desc.chargesPerJump or 999
    def.selfHealth = desc.selfHealth or 0
    def.activateWhenReady = desc.activateWhenReady or false
    def.activateReadyEnemies = desc.activateReadyEnemies or false
    local descTempPower = desc.tempPower
    if descTempPower then
        def.hasTemporaryPower = true
        local defTempPower = def.tempPower
        defTempPower.duration = descTempPower.duration or 10
        defTempPower.baseVisible = descTempPower.baseVisible or true
        defTempPower.animSheet = descTempPower.animSheet or ""
        defTempPower.effectAnim = descTempPower.effectAnim or ""
        defTempPower.animFrame = descTempPower.animFrame or -1
        defTempPower.effectFinishAnim = descTempPower.effectFinishAnim or ""
        if descTempPower.cooldownColor then
            defTempPower.cooldownColor = Graphics.GL_Color(
                (descTempPower.cooldownColor[1] or 255) / 255,
                (descTempPower.cooldownColor[2] or 255) / 255,
                (descTempPower.cooldownColor[3] or 255) / 255,
                descTempPower.cooldownColor[4] or 1
            )
        end
        if descTempPower.sounds then
            for i = 1, #descTempPower.sounds do
                defTempPower.sounds:push_back(descTempPower.sounds[i])
            end
        end
        if descTempPower.statBoosts then
            for i = 1, #descTempPower.statBoosts do
                defTempPower.statBoosts:push_back(descTempPower.statBoosts[i])
            end
        end
        if descTempPower.selfStatBoost then
            for key, value in pairs(descTempPower.selfStatBoost) do
                local toggleValue = defTempPower[key]
                toggleValue.enabled = true
                toggleValue.value = value
            end
        end
    end
    if desc.statBoosts then
        for i = 1, #desc.statBoosts do
            def.statBoosts:push_back(desc.statBoosts[i])
        end
    end
    --print(tostring(powerDef))
    return def
end

---@alias StatBoostDesc {
--- stat: Hyperspace.CrewStat | string,
--- boostType?: Hyperspace.StatBoostDefinition.BoostType | string,
--- boostSource?: Hyperspace.StatBoostDefinition.BoostSource | string,
--- shipTarget?: Hyperspace.StatBoostDefinition.ShipTarget | string,
--- crewTarget?: Hyperspace.StatBoostDefinition.CrewTarget | string,
--- droneTarget?: Hyperspace.StatBoostDefinition.DroneTarget | string,
--- affectsSelf?: boolean,
--- cloneClear?: boolean,
--- jumpClear?: boolean,
--- powerChange?: Hyperspace.ActivatedPowerDefinition,
--- amount?: number,
--- value?: boolean,
--- duration?: number,
--- boostAnim?: string,
---}
--- Create a StatBoostDefinition from a description table.
---@param desc StatBoostDesc
---@return Hyperspace.StatBoostDefinition?
local function StatBoostDef(desc)
    if not desc.stat then
        return nil
    end
    local def = StatBoostDefinition()
    def:GiveId()
    def.isRoomBased = false
    ---@diagnostic disable-next-line: assign-type-mismatch
    def.stat = type(desc.stat) == "number" and desc.stat or Hyperspace.CrewStat[desc.stat]
    if desc.boostType then
        ---@diagnostic disable-next-line: assign-type-mismatch
        def.boostType = type(desc.boostType) == "number" and desc.boostType or
            StatBoostDefinition.BoostType[desc.boostType]
    end
    if desc.boostSource then
        ---@diagnostic disable-next-line: assign-type-mismatch
        def.boostSource = type(desc.boostSource) == "number" and desc.boostSource or
            StatBoostDefinition.BoostSource[desc.boostSource]
    end
    if desc.shipTarget then
        ---@diagnostic disable-next-line: assign-type-mismatch
        def.shipTarget = type(desc.shipTarget) == "number" and desc.shipTarget or
            StatBoostDefinition.ShipTarget[desc.shipTarget]
    end
    if desc.crewTarget then
        ---@diagnostic disable-next-line: assign-type-mismatch
        def.crewTarget = type(desc.crewTarget) == "number" and desc.crewTarget or
            StatBoostDefinition.CrewTarget[desc.crewTarget]
    end
    if desc.droneTarget then
        ---@diagnostic disable-next-line: assign-type-mismatch
        def.droneTarget = type(desc.droneTarget) == "number" and desc.droneTarget or
            StatBoostDefinition.DroneTarget[desc.droneTarget]
    end
    def.affectsSelf = desc.affectsSelf or false
    def.cloneClear = desc.cloneClear or true
    def.jumpClear = desc.jumpClear or true
    if desc.powerChange then
        def.powerChange = desc.powerChange
    end
    def.amount = desc.amount or 0
    def.isBool = (desc.value ~= nil)
    def.value = desc.value or false
    def.duration = desc.duration or -1
    def.boostAnim = desc.boostAnim or ""
    --miscStatBoostDefStore[#miscStatBoostDefStore + 1] = def
    return def
end
mods.modularWeapons.StatBoostDef = StatBoostDef

---@param desc StatBoostDesc
---@return Hyperspace.StatBoostDefinition?
local function AugmentStatBoostDef(desc)
    desc.boostSource = StatBoostDefinition.BoostSource.AUGMENT
    desc.shipTarget = StatBoostDefinition.ShipTarget.ALL
    desc.crewTarget = StatBoostDefinition.CrewTarget.ALL
    desc.droneTarget = StatBoostDefinition.DroneTarget.ALL
    desc.affectsSelf = false
    return StatBoostDef(desc)
end

local function createPowerStatBoostDef(powerDesc)
    local powerName = powerDesc.name
    if not powerName then
        return
    end
    local def = StatBoostDefinition()
    def:GiveId()
    def.isRoomBased = false
    def.stat = Hyperspace.CrewStat.POWER_EFFECT
    def.boostType = StatBoostDefinition.BoostType.ADD
    def.boostSource = StatBoostDefinition.BoostSource.AUGMENT
    def.shipTarget = StatBoostDefinition.ShipTarget.ALL
    def.crewTarget = StatBoostDefinition.CrewTarget.ALL
    def.droneTarget = StatBoostDefinition.DroneTarget.ALL
    def.affectsSelf = false
    def.amount = -1
    def.cloneClear = false
    def.jumpClear = true
    local powerDef = PowerDef(powerDesc)
    powerDefStore[powerName] = powerDef
    def.powerChange = powerDef
    def.duration = -1
    statBoostDefStore[powerName] = def
end

createPowerStatBoostDef {
    name = "_mw_power_effect_bio",
    cooldown = 45,
    sounds = { "smallExplosion", },
    damage = {
        iPersDamage = 2,
        bFriendlyFire = false,
    },
    shipFriendlyFire = false,
    cooldownColor = { 38, 130, 152, 1 },
    effectAnim = "bio_bomb_detinate",
    --animFrame = 8,
    powerCharges = 2,
    tempPower = {
        duration = 15,
        cooldownColor = { 198, 198, 198, 1 },
        sounds = { "decloak", },
        selfStatBoost = {
            canMove = false,
            canMan = false,
            canRepair = false,
            canSabotage = false,
        },
        statBoosts = {
            StatBoostDef {
                stat = Hyperspace.CrewStat.DAMAGE_TAKEN_MULTIPLIER,
                boostType = "MULT",
                boostSource = "CREW",
                shipTarget = "CURRENT_ROOM",
                crewTarget = "ENEMIES",
                droneTarget = "CREW",
                affectsSelf = false,
                amount = 1.5,
                boostAnim = "spores_debuff",
            },
        }
    },
}

createPowerStatBoostDef {
    name = "_mw_power_effect_cooldown",
    cooldown = 45,
    sounds = { "mantisSplat1", "mantisSplat2", "mantisSplat3", },
    cooldownColor = { 171, 223, 255, 1 },
    powerCharges = 2,
    tempPower = {
        duration = 15,
        effectAnim = "pheromones_f",
        cooldownColor = { 215, 126, 195, 1 },
        sounds = { "mantisSplat1", "mantisSplat2", "mantisSplat3", },
        selfStatBoost = {
            moveSpeedMultiplier = 1.5,
            damageMultiplier = 1.5,
            repairSpeed = 1.5,
            sabotageSpeedMultiplier = 1.5,
            doorDamageMultiplier = 1.5,
            healSpeed = 1.5,
            stunMultiplier = 0.5,
            fireDamageMultiplier = 1.5,
            suffocationModifier = 1.5,
        },
    },
}

createPowerStatBoostDef {
    name = "_mw_power_effect_lockdown",
    cooldown = 60,
    sounds = { "lockdown1", "lockdown2", },
    damage = { bLockdown = true, },
    cooldownColor = { 125, 175, 175, 1 },
    effectAnim = "explosion_crystal",
    powerCharges = 2,
}

createPowerStatBoostDef {
    name = "_mw_power_effect_pierce",
    cooldown = 45,
    cooldownColor = { 220, 35, 200, 1 },
    powerCharges = 2,
    effectAnim = "breach_bomb_detinate",
    sounds = { "multiexplosion", },
    damage = {
        iSystemDamage = 1,
        breachChance = 10,
        bFriendlyFire = false,
    },
    shipFriendlyFire = true,
    tempPower = {
        duration = 15,
        cooldownColor = { 198, 198, 198, 1 },
        sounds = { "decloak", },
        selfStatBoost = {
            sabotageSpeedMultiplier = 1.5,
        }
    },
}

createPowerStatBoostDef {
    name = "_mw_power_effect_stun",
    cooldown = 45,
    cooldownColor = { 255, 228, 0, 1 },
    powerCharges = 2,
    effectAnim = "stun_bomb_detinate",
    sounds = { "multiexplosion", },
    damage = {
        iIonDamage = 1,
        stunChance = 10,
        iStun = 5,
        bFriendlyFire = false,
    },
    shipFriendlyFire = true,
    tempPower = {
        duration = 15,
        cooldownColor = { 255, 242, 140, 1 },
        sounds = { "decloak", },
        selfStatBoost = {
            stunMultiplier = 0,
            resistsMindControl = true,
        }
    },
}

createPowerStatBoostDef {
    name = "_mw_power_effect_accuracy",
    cooldown = 45,
    cooldownColor = { 255, 155, 0, 1 },
    powerCharges = 2,
    sounds = { "laser_pierce", },
    tempPower = {
        duration = 15,
        cooldownColor = { 100, 67, 96, 1 },
        sounds = { "decloak", },
        selfStatBoost = {
            damageMultiplier = 0.5,
            rangedDamageMultiplier = 4,
            sabotageSpeedMultiplier = 2,
        }
    },
}

createPowerStatBoostDef {
    name = "_mw_power_effect_fire",
    cooldown = 45,
    cooldownColor = { 255, 102, 0, 1 },
    powerCharges = 2,
    effectAnim = "explosion_random",
    sounds = { "fireBomb", },
    damage = {
        fireChance = 10,
        bFriendlyFire = true,
    },
    shipFriendlyFire = true,
    tempPower = {
        duration = 15,
        cooldownColor = { 235, 132, 112, 1 },
        sounds = { "decloak", },
        selfStatBoost = {
            canBurn = false,
            fireDamageMultiplier = 0,
        },
        statBoosts = {
            StatBoostDef {
                stat = Hyperspace.CrewStat.FIRE_DAMAGE_MULTIPLIER,
                boostType = "MULT",
                boostSource = "CREW",
                shipTarget = "CURRENT_ROOM",
                crewTarget = "ALLIES",
                droneTarget = "CREW",
                affectsSelf = false,
                amount = 0.25,
            },
        }
    },
}

createPowerStatBoostDef {
    name = "_mw_power_effect_hull",
    cooldown = 45,
    cooldownColor = { 240, 65, 120, 1 },
    powerCharges = 2,
    effectAnim = "cultivator_spore_explosion",
    sounds = { "shieldsUp", },
    tempPower = {
        duration = 15,
        cooldownColor = { 240, 130, 180, 1 },
        effectAnim = "energy_shield_buff",
        sounds = { "shieldsDown", },
        selfStatBoost = {
            allDamageTakenMultiplier = 0.5,
        },
        statBoosts = {
            StatBoostDef {
                stat = Hyperspace.CrewStat.MAX_HEALTH,
                boostType = "MULT",
                boostSource = "CREW",
                shipTarget = "CURRENT_ROOM",
                crewTarget = "ALLIES",
                droneTarget = "CREW",
                affectsSelf = true,
                amount = 1.5,
                boostAnim = "spores_buff",
            },
        }
    },
}

createPowerStatBoostDef {
    name = "_mw_power_effect_power",
    cooldown = 30,
    cooldownColor = { 250, 250, 90, 1 },
    powerCharges = 2,
    sounds = { "batteryStart", },
    tempPower = {
        duration = 30,
        cooldownColor = { 250, 250, 90, 1 },
        effectAnim = "unique_turzil_shield_buff",
        sounds = { "batteryStop", },
        selfStatBoost = {
            allDamageTakenMultiplier = 0.7,
        },
        statBoosts = {
            StatBoostDef {
                stat = Hyperspace.CrewStat.BONUS_POWER,
                boostType = "ADD",
                boostSource = "CREW",
                shipTarget = "ALL",
                crewTarget = "SELF",
                droneTarget = "ALL",
                affectsSelf = true,
                amount = 2,
            },
        }
    },
}

createPowerStatBoostDef {
    name = "_mw_power_effect_adapt",
    cooldown = 12,
    jumpCooldown = 1,
    cooldownColor = { 255, 45, 80, 1 },
    powerCharges = 5,
    initialCooldownFraction = 0,
    activateWhenReady = true,
    activateReadyEnemies = false,
    sounds = { "temporalSlow", },
}

createPowerStatBoostDef {
    name = "_mw_power_effect_chain",
    cooldown = 12,
    jumpCooldown = 1,
    cooldownColor = { 255, 45, 80, 1 },
    powerCharges = 5,
    initialCooldownFraction = 0,
    activateWhenReady = true,
    activateReadyEnemies = false,
    sounds = { "temporalFast", },
}

---@type table<string, Hyperspace.StatBoostDefinition[]>
local powerOnStatBoostDefs = {
    ["_mw_power_effect_adapt"] = {
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.DAMAGE_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 1.25,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.RANGED_DAMAGE_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 0.64,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.SABOTAGE_SPEED_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 1.25,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.MAX_HEALTH,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 1.25,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.MOVE_SPEED_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 0.8,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.DOOR_DAMAGE_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 2,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.REPAIR_SPEED_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 0.8,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.HEAL_SPEED_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 0.8,
            duration = -1,
        },
    },
    ["_mw_power_effect_chain"] = {
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.DAMAGE_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 0.8,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.RANGED_DAMAGE_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 1.5625,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.SABOTAGE_SPEED_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 0.8,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.MAX_HEALTH,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 0.8,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.MOVE_SPEED_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 2,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.DOOR_DAMAGE_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 2,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.REPAIR_SPEED_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 1.25,
            duration = -1,
        },
        AugmentStatBoostDef {
            stat = Hyperspace.CrewStat.HEAL_SPEED_MULTIPLIER,
            boostType = "MULT",
            cloneClear = false,
            jumpClear = true,
            amount = 1.25,
            duration = -1,
        },
    },
}

script.on_internal_event(Defines.InternalEvents.ACTIVATE_POWER, function(power)
    local defs = powerOnStatBoostDefs[power.def.buttonLabel.data]
    if not defs then
        return
    end
    for i = 1, #defs do
        StatBoostManager:CreateTimedAugmentBoost(StatBoost(defs[i]), power.crew)
    end
end)
