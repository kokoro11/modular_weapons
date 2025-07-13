local Text = mods.modularWeapons.Text
local TextCollection = mods.modularWeapons.TextCollection

local texts = TextCollection()
mods.modularWeapons.texts = texts

texts.modules = TextCollection()

texts.modules.bio = TextCollection()
texts.modules.bio.short = Text {
    [''] = "Rad",
    ['zh-Hans'] = '辐射',
}
texts.modules.bio.full = Text {
    [''] = "RAD",
    ['zh-Hans'] = '辐射',
}
texts.modules.bio.effects = Text {
    [''] = "+30 crew damage",
    ['zh-Hans'] = '+30点船员伤害',
}

texts.modules.cooldown = TextCollection()
texts.modules.cooldown.short = Text {
    [''] = "Cool",
    ['zh-Hans'] = '冷却',
}
texts.modules.cooldown.full = Text {
    [''] = "Cooldown",
    ['zh-Hans'] = '冷却',
}
texts.modules.cooldown.effects = Text {
    [''] = "-20%% charge time",
    ['zh-Hans'] = '-20%%充能时间',
}

texts.modules.lockdown = TextCollection()
texts.modules.lockdown.short = Text {
    [''] = "Lock",
    ['zh-Hans'] = '封锁',
}
texts.modules.lockdown.full = Text {
    [''] = "Lockdown",
    ['zh-Hans'] = '封锁',
}
texts.modules.lockdown.effects = Text {
    [''] = "Applies lockdown",
    ['zh-Hans'] = '封锁舱室',
}

texts.modules.pierce = TextCollection()
texts.modules.pierce.short = Text {
    [''] = "Pierce",
    ['zh-Hans'] = '穿透',
}
texts.modules.pierce.full = Text {
    [''] = "Pierce",
    ['zh-Hans'] = '穿透',
}
texts.modules.pierce.effects = Text {
    [''] = "+1 shield pierce, +30%% breach chance",
    ['zh-Hans'] = '+1层护盾穿透，+30%%破舱率',
}

texts.modules.stun = TextCollection()
texts.modules.stun.short = Text {
    [''] = "Neural",
    ['zh-Hans'] = '眩晕',
}
texts.modules.stun.full = Text {
    [''] = "Neural",
    ['zh-Hans'] = '眩晕',
}
texts.modules.stun.effects = Text {
    [''] = "+100%% stun chance, +10s stun duration",
    ['zh-Hans'] = '+100%%眩晕率，+10秒眩晕时长',
}

texts.modules.accuracy = TextCollection()
texts.modules.accuracy.short = Text {
    [''] = "Acc",
    ['zh-Hans'] = '精度',
}
texts.modules.accuracy.full = Text {
    [''] = "Accuracy",
    ['zh-Hans'] = '精度',
}
texts.modules.accuracy.effects = Text {
    [''] = "+20%% accuracy buff, +1 shield pierce for beam weapons",
    ['zh-Hans'] = '+20%%命中率加成，光束武器+1层护盾穿透',
}

texts.modules.fire = TextCollection()
texts.modules.fire.short = Text {
    [''] = "Fire",
    ['zh-Hans'] = '引火',
}
texts.modules.fire.full = Text {
    [''] = "Firestarter",
    ['zh-Hans'] = '引火',
}
texts.modules.fire.effects = Text {
    [''] = "+30%% fire chance",
    ['zh-Hans'] = '+30%%起火率',
}

texts.modules.hull = TextCollection()
texts.modules.hull.short = Text {
    [''] = "Hull",
    ['zh-Hans'] = '破舰',
}
texts.modules.hull.full = Text {
    [''] = "Hullbust",
    ['zh-Hans'] = '破舰',
}
texts.modules.hull.effects = Text {
    [''] = "x2 damage on systemless rooms, +30%% breach chance",
    ['zh-Hans'] = '对空舱室造成2倍伤害，+30%%破舱率',
}

texts.modules.power = TextCollection()
texts.modules.power.short = Text {
    [''] = "Pwr",
    ['zh-Hans'] = '强能',
}
texts.modules.power.full = Text {
    [''] = "Power",
    ['zh-Hans'] = '强能',
}
texts.modules.power.effects = Text {
    [''] = "+1 power cost, -20%% charge speed, +1 all damage (if it has any)",
    ['zh-Hans'] = '+1格能耗，-20%%秒充能速度，+1所有伤害（如果有的话）',
}

texts.modules.charge = TextCollection()
texts.modules.charge.short = Text {
    [''] = "Charge",
    ['zh-Hans'] = '充能',
}
texts.modules.charge.full = Text {
    [''] = "Charge",
    ['zh-Hans'] = '充能',
}
texts.modules.charge.effects = Text {
    [''] = "Divides charge time by twice the number of shots but also reduces number of shots to 1. Incompatible with beam weapons and single burst weapons",
    ['zh-Hans'] = '将充能时间除以两倍的弹体数但会将弹体数降为1，与光束武器和单发武器不兼容',
}

texts.modules.adapt = TextCollection()
texts.modules.adapt.short = Text {
    [''] = "Adapt",
    ['zh-Hans'] = '自适',
}
texts.modules.adapt.full = Text {
    [''] = "Adaptive",
    ['zh-Hans'] = '自适',
}
texts.modules.adapt.effects = Text {
    [''] = "+1 power cost, -20%% charge speed, +1 all damage (if it has any) after each volley, up to 3 times",
    ['zh-Hans'] = '+1格能耗，-20%%秒充能速度，每发后+1所有伤害（如果有的话），最多3次',
}

texts.modules.chain = TextCollection()
texts.modules.chain.short = Text {
    [''] = "Chain",
    ['zh-Hans'] = '链式',
}
texts.modules.chain.full = Text {
    [''] = "Chain",
    ['zh-Hans'] = '链式',
}
texts.modules.chain.effects = Text {
    [''] = "-10%% charge time after each volley, up to 3 times",
    ['zh-Hans'] = '每发后-10%%秒充能时间，最多3次',
}

texts.none = Text {
    [''] = "None",
    ['zh-Hans'] = '无',
}

texts.modify_slot = Text {
    [''] = "Modify Slot %s: %s",
    ['zh-Hans'] = '配置槽位%s的武器：%s',
}

texts.cannot_modify_slot = Text {
    [''] = "Cannot modify Slot %s: %s",
    ['zh-Hans'] = '无法配置槽位%s的武器：%s',
}

texts.weapon_name = Text {
    [''] = "Currently Modifying Weapon: %s\nInstalled modules: %s",
    ['zh-Hans'] = '正在配置的武器：%s\n已安装模块：%s',
}

texts.installed_module_entry = Text {
    [''] = "[%s]: %s",
    ['zh-Hans'] = '[%s]：%s',
}

texts.remove_module = Text {
    [''] = "Detach the %s Module",
    ['zh-Hans'] = '移除%s模块',
}

texts.attach_module = Text {
    [''] = "Install the %s Module\n[Effects: %s]",
    ['zh-Hans'] = '安装%s模块\n[效果：%s]',
}

texts.cannot_attach_module = Text {
    [''] = "Cannot attach %s Module",
    ['zh-Hans'] = '无法安装%s模块',
}
