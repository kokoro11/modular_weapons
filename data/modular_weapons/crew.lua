local floor = math.floor
local TextLibrary = Hyperspace.Text
local Global = Hyperspace.Global.GetInstance()
local GetShipManager = Global.GetShipManager
local playerVariables = Hyperspace.playerVariables
local hsUserdataTable = getmetatable(Hyperspace.ShipManager)[".instance"][".get"].table

local getPlayerCrewList = mods.modularWeapons.getPlayerCrewList
local forceRecheckPowers = mods.modularWeapons.forceRecheckPowers
local TEXTS = mods.modularWeapons.texts

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_CREWMEMBER, function(crew)
    local crewTable = {}
    crew.table.modularWeapons = crewTable
    crew.table.modularWeaponsInstalledCharge = false
    crew.table.modularWeaponsPowers = {}
    crewTable.installed = {}
    crewTable.status = false
    crewTable.attribute = false
end)

local STATUS_MODULE = 0
local ATTRIBUTE_MODULE = 1

---@alias CrewModuleFunctions {
---     type: integer,
---     mask: integer,
---     power?: string,
---     attach?: fun(crew: Hyperspace.CrewMember),
---     remove?: fun(crew: Hyperspace.CrewMember),
---     statBoost?: fun(crew: Hyperspace.CrewMember, stat: Hyperspace.CrewStat, amount: number, value: boolean): number, boolean}
---@type table<string, CrewModuleFunctions>
local CREW_MODULES = {
    bio = { type = STATUS_MODULE, mask = 1 << 0, power = "_mw_power_effect_bio" },
    cooldown = { type = STATUS_MODULE, mask = 1 << 1, power = "_mw_power_effect_cooldown" },
    lockdown = { type = STATUS_MODULE, mask = 1 << 2, power = "_mw_power_effect_lockdown" },
    pierce = { type = STATUS_MODULE, mask = 1 << 3, power = "_mw_power_effect_pierce" },
    stun = { type = STATUS_MODULE, mask = 1 << 4, power = "_mw_power_effect_stun" },
    adapt = { type = STATUS_MODULE, mask = 1 << 5, power = "_mw_power_effect_adapt" }, -- dlc
    chain = { type = STATUS_MODULE, mask = 1 << 6, power = "_mw_power_effect_chain" }, -- dlc

    accuracy = { type = ATTRIBUTE_MODULE, mask = 1 << 16, power = "_mw_power_effect_accuracy" },
    fire = { type = ATTRIBUTE_MODULE, mask = 1 << 17, power = "_mw_power_effect_fire" },
    hull = { type = ATTRIBUTE_MODULE, mask = 1 << 18, power = "_mw_power_effect_hull" },
    power = { type = ATTRIBUTE_MODULE, mask = 1 << 19, power = "_mw_power_effect_power" },
    charge = { type = ATTRIBUTE_MODULE, mask = 1 << 20, }, -- dlc
}

CREW_MODULES.charge.attach = function(crew)
    crew.table.modularWeaponsInstalledCharge = true
end

CREW_MODULES.charge.remove = function(crew)
    crew.table.modularWeaponsInstalledCharge = false
end

local function checkCrewModuleStatus(crewTable, powers)
    for k in pairs(powers) do
        powers[k] = nil
    end
    ---@type string | false
    local hasStatus = false
    ---@type string | false
    local hasAttribute = false
    for moduleLower in pairs(crewTable.installed) do
        local module = CREW_MODULES[moduleLower]
        if module then
            local str = TEXTS.modules[moduleLower].short()
            if module.type == STATUS_MODULE then
                hasStatus = str
            else
                hasAttribute = str
            end
            local powerName = module.power
            if powerName then
                powers[powerName] = true
            end
        end
    end
    crewTable.status = hasStatus
    crewTable.attribute = hasAttribute
    forceRecheckPowers()
end

local SAVE_ID_PREFIX = "$UWM:CMI:0:"

---@param crew Hyperspace.CrewMember
---@param moduleLower string
---@param noSave? boolean
local function attachCrewModule(crew, moduleLower, noSave)
    local module = CREW_MODULES[moduleLower]
    if not module then
        return
    end
    local crewTable = crew.table.modularWeapons
    crewTable.installed[moduleLower] = module.statBoost or true
    if not noSave then
        local idStr = SAVE_ID_PREFIX .. floor(crew.extend.selfId)
        playerVariables[idStr] = playerVariables[idStr]| module.mask
    end
    checkCrewModuleStatus(crewTable, crew.table.modularWeaponsPowers)
    --initCrewPower(crew, module.power)
    if module.attach then
        module.attach(crew)
    end
end

---@param crew Hyperspace.CrewMember
---@param moduleLower string
---@param noSave? boolean
local function removeCrewModule(crew, moduleLower, noSave)
    local crewTable = crew.table.modularWeapons
    crewTable.installed[moduleLower] = nil
    checkCrewModuleStatus(crewTable, crew.table.modularWeaponsPowers)
    local module = CREW_MODULES[moduleLower]
    if not module then
        return
    end
    if not noSave then
        local idStr = SAVE_ID_PREFIX .. floor(crew.extend.selfId)
        playerVariables[idStr] = playerVariables[idStr] & (~module.mask)
    end
    --removeCrewPower(crew, module.power)
    if module.remove then
        module.remove(crew)
    end
end

mods.multiverse.on_load_game(function()
    local crewList = getPlayerCrewList()
    for i = 1, #crewList do
        local crew = crewList[i]
        local idStr = SAVE_ID_PREFIX .. floor(crew.extend.selfId)
        ---@diagnostic disable-next-line: param-type-mismatch
        if playerVariables:has_key(idStr) then
            local saveData = playerVariables[idStr]
            for moduleLower, module in pairs(CREW_MODULES) do
                if (module.mask & saveData) ~= 0 then
                    attachCrewModule(crew, moduleLower, true)
                end
            end
        end
    end
end)

--[[ function MODULES.lockdown.statBoost(crew, stat, amount, value)
    if stat == Hyperspace.CrewStat.POWER_EFFECT then

    end
    --Hyperspace.PowerResourceDefinition
    local a = Hyperspace.StatBoostDefinition()
    a.hasPowerList = true
    local b = Hyperspace.CrewDefinition.powerDefs
    local c = b[0]

    return amount, value
end ]]

if Hyperspace.version.major > 1 or (Hyperspace.version.major == 1 and Hyperspace.version.minor >= 20) then
    ---@param crew Hyperspace.CrewMember
    local function statBoosts(crew, stat, _, amount, _)
        -- Hyperspace.CrewStat.POWER_MAX_CHARGES == 59
        -- Hyperspace.CrewStat.POWER_CHARGES_PER_JUMP == 60
        -- Hyperspace.CrewStat.POWER_RECHARGE_MULTIPLIER == 42
        if stat == 42 then
            if hsUserdataTable(crew).modularWeaponsInstalledCharge then
                return 0, amount * 1.5
            else
                return
            end
        end
        if not ((stat == 59 or stat == 60) and hsUserdataTable(crew).modularWeaponsInstalledCharge) then
            return
        end
        local ce = crew.extend
        local crewPowers = ce.crewPowers
        for i = 0, crewPowers:size() - 1 do
            local p = crewPowers[i]
            --if p.enabled or p.def.disabledCharges == 2 then
            if p.enabled then
                p.modifiedPowerCharges = p.modifiedPowerCharges + 1
            end
        end
        local ress = ce.powerResources
        for i = 0, ress:size() - 1 do
            local p = ress[i]
            --if p.enabled or p.def.disabledCharges == 2 then
            if p.enabled then
                p.modifiedPowerCharges = p.modifiedPowerCharges + 1
            end
        end
    end
    ---@diagnostic disable-next-line: undefined-field
    script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_POST, statBoosts)
else
    script.on_init(function ()
        print("[UWM] Warning: Your Hyperspace version is lower than 1.20.")
        print("[UWM] Warning: Crew Charge Module will not work properly.")
    end)
end

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

local emptyReq = Hyperspace.ChoiceReq()

---@param crew Hyperspace.CrewMember
---@param playerShip Hyperspace.ShipManager
---@return Hyperspace.LocationEvent
local function createCrewEvent(crew, playerShip)
    local eventGen = Hyperspace.Event
    local blueprints = Hyperspace.Blueprints
    local event = eventGen:CreateEvent("_MW_EVENT_TEMPLATE_MODIFY_CREW_SELFID", 0, false)
    local selfId = math.floor(crew.extend.selfId)
    event.eventName = "_MW_EVENT_MODIFY_CREW_SELFID_" .. selfId
    local crewTable = crew.table.modularWeapons
    local installed = crewTable.installed
    local text = "\n" .. TEXTS.crew_name(crew:GetLongName(), (next(installed) == nil) and TEXTS.none() or "")
    for moduleLower in pairs(installed) do
        local moduleUpper = string.upper(moduleLower)
        local removeEvent = eventGen:CreateEvent("_MW_EVENT_TEMPLATE_CREW_MODULE_REMOVE", 0, false)
        local fullName = TEXTS.modules[moduleLower].full()
        removeEvent.eventName = "_MW_EVENT_CREW_MODULE_REMOVE_" .. selfId .. "_" .. moduleUpper
        removeEvent.stuff.weapon = blueprints:GetWeaponBlueprint("MODULE_" .. moduleUpper)
        event:AddChoice(removeEvent, TEXTS.remove_module(fullName), emptyReq, true)
        local effects
        if CREW_MODULES[moduleLower].power then
            local ability = TextLibrary:GetText("_mw_power_effect_" .. moduleLower)
            local tooltip = TextLibrary:GetText("_mw_power_effect_" .. moduleLower .. "_tooltip")
            effects = TEXTS.crew_power_effect(ability, tooltip)
        else
            effects = TEXTS.modules[moduleLower].crew_effects()
        end
        text = text .. "\n" .. TEXTS.installed_module_entry(fullName, effects)
    end
    event.text.data = event.text:GetText() .. text
    event.text.isLiteral = true
    local invalidEvent = eventGen:GetBaseEvent("_MW_EVENT_OPTION_INVALID", 0, false, -1)
    if not crewTable.status then
        for _, moduleLower in ipairs(MODULES_STATUS) do
            local moduleUpper = string.upper(moduleLower)
            if not installed[moduleLower] and playerShip:HasEquipment("MODULE_" .. moduleUpper, true) > 0 then
                local fullName = TEXTS.modules[moduleLower].full()
                if true then
                    local attachEvent = eventGen:CreateEvent("_MW_EVENT_TEMPLATE_CREW_MODULE_ATTACH", 0, false)
                    local effects
                    if CREW_MODULES[moduleLower].power then
                        local ability = TextLibrary:GetText("_mw_power_effect_" .. moduleLower)
                        local tooltip = TextLibrary:GetText("_mw_power_effect_" .. moduleLower .. "_tooltip")
                        effects = TEXTS.crew_power_effect(ability, tooltip)
                    else
                        effects = TEXTS.modules[moduleLower].crew_effects()
                    end
                    attachEvent.eventName = "_MW_EVENT_CREW_MODULE_ATTACH_" .. selfId .. "_" .. moduleUpper
                    attachEvent.stuff.removeItem = "MODULE_" .. moduleUpper
                    event:AddChoice(attachEvent, TEXTS.attach_module(fullName, effects), emptyReq, false)
                else
                    event:AddChoice(invalidEvent, TEXTS.cannot_attach_module(fullName), emptyReq, true)
                end
            end
        end
    end
    if not crewTable.attribute then
        for _, moduleLower in ipairs(MODULES_ATTRIBUTE) do
            local moduleUpper = string.upper(moduleLower)
            if not installed[moduleLower] and playerShip:HasEquipment("MODULE_" .. moduleUpper, true) > 0 then
                local fullName = TEXTS.modules[moduleLower].full()
                if true then
                    local attachEvent = eventGen:CreateEvent("_MW_EVENT_TEMPLATE_CREW_MODULE_ATTACH", 0, false)
                    local effects
                    if CREW_MODULES[moduleLower].power then
                        local ability = TextLibrary:GetText("_mw_power_effect_" .. moduleLower)
                        local tooltip = TextLibrary:GetText("_mw_power_effect_" .. moduleLower .. "_tooltip")
                        effects = TEXTS.crew_power_effect(ability, tooltip)
                    else
                        effects = TEXTS.modules[moduleLower].crew_effects()
                    end
                    attachEvent.eventName = "_MW_EVENT_CREW_MODULE_ATTACH_" .. selfId .. "_" .. moduleUpper
                    attachEvent.stuff.removeItem = "MODULE_" .. moduleUpper
                    event:AddChoice(attachEvent, TEXTS.attach_module(fullName, effects), emptyReq, false)
                else
                    event:AddChoice(invalidEvent, TEXTS.cannot_attach_module(fullName), emptyReq, true)
                end
            end
        end
    end
    return event
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
    if event.eventName ~= "_MW_EVENT_MODIFY_CREW" then
        return
    end
    local crewList = getPlayerCrewList()
    local size = #crewList
    if size <= 0 then
        return
    end
    local playerShip = GetShipManager(Global, 0)
    local invalidEvent = Hyperspace.Event:GetBaseEvent("_MW_EVENT_OPTION_INVALID", 0, false, -1)
    for i = 1, size do
        local crew = crewList[i]
        if true then
            local crewTable = crew.table.modularWeapons
            local installedMods = (crewTable.attribute or "") .. (crewTable.status or "")
            event:AddChoice(createCrewEvent(crew, playerShip), TEXTS.modify_crew(crew:GetLongName(), installedMods),
                emptyReq, true)
        else
            event:AddChoice(invalidEvent, TEXTS.cannot_modify_crew(i, crew:GetLongName()), emptyReq, true)
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.POST_CREATE_CHOICEBOX, function(box, event)
    local name = event.eventName
    if string.sub(name, 1, 22) ~= "_MW_EVENT_CREW_MODULE_" then
        return
    end
    local op = string.sub(name, 23, 29)
    local isAttach = (op == "ATTACH_")
    local isRemove = (op == "REMOVE_")
    if not (isAttach or isRemove) then
        return
    end
    local selfId, moduleUpper = string.match(string.sub(name, 30), "^(%d+)_(.+)$")
    selfId = tonumber(selfId)
    if not (selfId and moduleUpper) then
        return
    end
    local moduleLower = string.lower(moduleUpper)
    if not CREW_MODULES[moduleLower] then
        return
    end
    local crewList = getPlayerCrewList()
    local selectedCrew = nil
    for i = 1, #crewList do
        local crew = crewList[i]
        if crew.extend.selfId == selfId then
            selectedCrew = crew
            break
        end
    end
    if not selectedCrew then
        return
    end
    if isAttach then
        attachCrewModule(selectedCrew, moduleLower)
    else
        removeCrewModule(selectedCrew, moduleLower)
    end
end)

local cApp = Hyperspace.App
local world = cApp.world
---@type vector<Hyperspace.CrewMember>
local pSelectedCrew = nil
local Mouse = Hyperspace.Mouse
script.on_init(function()
    pSelectedCrew = cApp.gui.crewControl.potentialSelectedCrew
end)
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not (world.bStartedGame and pSelectedCrew:size() == 1) then
        return
    end
    local tooltip = Mouse.tooltip
    if #tooltip <= 0 then
        return
    end
    local crewTable = pSelectedCrew[0].table.modularWeapons
    local installed = crewTable.installed
    if next(installed) == nil then
        return
    end
    local installedMods = (crewTable.attribute or "") .. (crewTable.status or "")
    Mouse:SetTooltip(tooltip .. TEXTS.crew_installed_modules(installedMods))
end)
