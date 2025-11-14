-- Kai'Sa Champion Script
-- Rewritten for improved structure and maintainability

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================
local pred = module.internal("pred")
local TS = module.internal('TS')
local orb = module.internal("orb")
local EvadeInternal = module.seek("evade")

-- ============================================================================
-- DAMAGE CALCULATION UTILITIES
-- ============================================================================
local DamageCalculator = {}

function DamageCalculator.GetTotalAD(obj)
    obj = obj or player
    return (obj.baseAttackDamage + obj.flatPhysicalDamageMod) * obj.percentPhysicalDamageMod
end

function DamageCalculator.GetBonusAD(obj)
    obj = obj or player
    return ((obj.baseAttackDamage + obj.flatPhysicalDamageMod) * obj.percentPhysicalDamageMod) - obj.baseAttackDamage
end

function DamageCalculator.GetTotalAP(obj)
    obj = obj or player
    return obj.flatMagicDamageMod * obj.percentMagicDamageMod
end

function DamageCalculator.PhysicalReduction(target, damageSource)
    damageSource = damageSource or player
    local armor = ((target.bonusArmor * damageSource.percentBonusArmorPenetration) + 
                   (target.armor - target.bonusArmor)) * damageSource.percentArmorPenetration
    local lethality = (damageSource.physicalLethality * 0.4) + 
                      ((damageSource.physicalLethality * 0.6) * (damageSource.levelRef / 18))
    
    if armor >= 0 then
        return 100 / (100 + (armor - lethality))
    else
        return 2 - (100 / (100 - (armor - lethality)))
    end
end

function DamageCalculator.MagicReduction(target, damageSource)
    damageSource = damageSource or player
    local magicResist = (target.spellBlock * damageSource.percentMagicPenetration) - 
                        damageSource.flatMagicPenetration
    
    if magicResist >= 0 then
        return 100 / (100 + magicResist)
    else
        return 2 - (100 / (100 - magicResist))
    end
end

function DamageCalculator.CalculateAADamage(target, damageSource)
    damageSource = damageSource or player
    if not target then return 0 end
    return DamageCalculator.GetTotalAD(damageSource) * 
           DamageCalculator.PhysicalReduction(target, damageSource)
end

function DamageCalculator.CalculatePhysicalDamage(target, damage, damageSource)
    damageSource = damageSource or player
    if not target then return 0 end
    return damage * DamageCalculator.PhysicalReduction(target, damageSource)
end

function DamageCalculator.CalculateMagicDamage(target, damage, damageSource)
    damageSource = damageSource or player
    if not target then return 0 end
    return damage * DamageCalculator.MagicReduction(target, damageSource)
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================
local Utils = {}

function Utils.GetAARange(target)
    return player.attackRange + player.boundingRadius + (target and target.boundingRadius or 0)
end

function Utils.GetShieldedHealth(damageType, target)
    local shield = 0
    if damageType == "AD" then
        shield = target.physicalShield
    elseif damageType == "AP" then
        shield = target.magicalShield
    elseif damageType == "ALL" then
        shield = target.allShield
    end
    return target.health + shield
end

function Utils.CheckBuffType(obj, bufftype)
    if not obj then return false end
    
    for i = 0, obj.buffManager.count - 1 do
        local buff = obj.buffManager:get(i)
        if buff and buff.valid and buff.type == bufftype and (buff.stacks > 0 or buff.stacks2 > 0) then
            return true
        end
    end
    return false
end

function Utils.CheckBuff(obj, buffname)
    if not obj then return false end
    
    for i = 0, obj.buffManager.count - 1 do
        local buff = obj.buffManager:get(i)
        if buff and buff.valid and buff.name == buffname and buff.stacks == 1 then
            return true
        end
    end
    return false
end

function Utils.CheckBuffContains(obj, buffname)
    if not obj then return false end
    
    for i = 0, obj.buffManager.count - 1 do
        local buff = obj.buffManager:get(i)
        if buff and buff.valid and buff.name:find(buffname) and (buff.stacks > 0 or buff.stacks2 > 0) then
            return true
        end
    end
    return false
end

function Utils.IsValidTarget(object)
    return object and 
           not object.isDead and 
           object.isVisible and 
           object.isTargetable and 
           not Utils.CheckBuffType(object, 17)
end

function Utils.GetDistanceSqr(p1, p2)
    p2 = p2 or player
    local dx = p1.x - p2.x
    local dz = (p1.z or p1.y) - (p2.z or p2.y)
    return dx * dx + dz * dz
end

function Utils.GetDistance(p1, p2)
    return math.sqrt(Utils.GetDistanceSqr(p1, p2))
end

-- ============================================================================
-- SPELL CASTING STATE MANAGEMENT
-- ============================================================================
local CastState = {
    on_end_func = nil,
    on_end_time = 0,
    spell_map = {}
}

function CastState.SetEndCallback(callback, windUpTime)
    if os.clock() + windUpTime > CastState.on_end_time then
        CastState.on_end_func = callback
        CastState.on_end_time = os.clock() + windUpTime
        orb.core.set_pause(math.huge)
    end
end

function CastState.ClearCallback()
    CastState.on_end_func = nil
    orb.core.set_pause(0)
end

function CastState.OnCastQ(spell)
    CastState.SetEndCallback(CastState.ClearCallback, spell.windUpTime)
end

function CastState.OnCastW(spell)
    CastState.SetEndCallback(CastState.ClearCallback, spell.windUpTime)
end

function CastState.OnCastE(spell)
    CastState.SetEndCallback(CastState.ClearCallback, spell.windUpTime)
end

function CastState.OnCastR(spell)
    CastState.SetEndCallback(CastState.ClearCallback, spell.windUpTime)
end

function CastState.OnDash()
    local t = player.path.serverPos2D:dist(player.path.point2D[1]) / player.path.dashSpeed
    if os.clock() + t > CastState.on_end_time then
        CastState.on_end_func = CastState.ClearCallback
        CastState.on_end_time = os.clock() + t
        orb.core.set_pause(0)
    end
end

-- ============================================================================
-- SPELL DEFINITIONS
-- ============================================================================
local Spells = {
    Q = {
        slot = 0,
        last = 0,
        result = {
            seg = nil,
            obj = nil,
        },
        predinput = {
            delay = 0.25,
            radius = 600,
            dashRadius = 0,
            boundingRadiusModSource = 0,
            boundingRadiusModTarget = 0,
        },
    },
    
    W = {
        slot = 1,
        last = 0,
        range = 3000,
        result = {
            seg = nil,
            obj = nil,
        },
        predinput = {
            delay = 0.40000000596046,
            width = 150,
            speed = 1750,
            boundingRadiusMod = 1,
            collision = {
                hero = true,
                minion = true,
                wall = true,
            },
        },
    },
    
    E = {
        slot = 2,
    },
    
    R = {
        slot = 3,
    },
}

-- ============================================================================
-- MENU CONFIGURATION
-- ============================================================================
local menu = menu("Nicky Kais'sa", "[Nicky] Kai'Sa")

menu:header("q", "[Q] Icathian Rain")
menu:boolean('combo_q', 'Use in Combo [Q]', true)
menu.combo_q:set('tooltip', 'Will only be used if no minion in range')

menu:header("w", "[W] Void Seeker")
menu:dropdown('combo_w', 'Use in Combo [W]', 1, {'Only on CC', 'Always', 'Never'})
menu:slider('combo_w_slider', "[Combo] Maximum range to check", 1000, 500, 2500, 100)
menu:boolean('ks_w', 'Use to Killsteal', true)
menu:slider('ks_w_slider', "[Killsteal] Maximum range to check", 2000, 500, 2500, 100)

menu:header("flee", "Flee Settings")
menu:keybind('flee_key', 'Key', 'T', nil)
menu:boolean('flee_e', 'Use E', true)

TS.load_to_menu(menu)

-- ============================================================================
-- TARGET SELECTION
-- ============================================================================
local TargetSelector = {}

function TargetSelector.IsValidCombatTarget(res, obj, dist)
    if dist > 1000 then
        res.obj = obj
        return true
    end
    return false
end

function TargetSelector.GetTarget()
    return TS.get_result(TargetSelector.IsValidCombatTarget).obj
end

-- ============================================================================
-- SPELL LOGIC
-- ============================================================================
local SpellLogic = {}

function SpellLogic.IsReady(spellSlot)
    return player:spellSlot(spellSlot).state == 0
end

function SpellLogic.GetWDamage(target)
    local baseDamage = 20 + (25 * (player.levelRef - 1))
    local adRatio = DamageCalculator.GetTotalAD() * 1.5
    local apRatio = DamageCalculator.GetTotalAP() * 0.45
    local totalDamage = baseDamage + adRatio + apRatio
    return DamageCalculator.CalculateMagicDamage(target, totalDamage)
end

function SpellLogic.CastQ()
    player:castSpell("self", Spells.Q.slot)
    orb.core.set_server_pause()
end

function SpellLogic.CastW()
    local target = TargetSelector.GetTarget()
    if not Utils.IsValidTarget(target) or Utils.GetDistance(target) > Spells.W.range then
        return
    end
    
    local wpred = pred.linear.get_prediction(Spells.W.predinput, target)
    if not wpred then return end
    
    if not pred.collision.get_prediction(Spells.W.predinput, wpred, target) then
        player:castSpell("pos", Spells.W.slot, vec3(wpred.endPos.x, game.mousePos.y, wpred.endPos.y))
    end
end

function SpellLogic.CastE()
    player:castSpell("self", Spells.E.slot)
    orb.core.set_server_pause()
end

function SpellLogic.GetQPrediction()
    if Spells.Q.last == game.time then
        return Spells.Q.result
    end
    
    Spells.Q.last = game.time
    Spells.Q.result = nil
    
    -- Count nearby minions
    local minionCount = 0
    for i = 0, objManager.minions.size[TEAM_ENEMY] - 1 do
        local minion = objManager.minions[TEAM_ENEMY][i]
        if minion and not minion.isDead and minion.isVisible then
            local distSqr = player.path.serverPos:distSqr(minion.path.serverPos)
            if distSqr <= (Spells.Q.predinput.radius * Spells.Q.predinput.radius) then
                minionCount = minionCount + 1
            end
        end
    end
    
    -- Only use Q if no minions nearby
    if minionCount == 0 then
        local target = TS.get_result(function(res, obj, dist)
            if dist > 1000 then return false end
            
            if pred.present.get_prediction(Spells.Q.predinput, obj) then
                res.obj = obj
                return true
            end
            return false
        end).obj
        
        if target then
            Spells.Q.result = target
        end
    end
    
    return Spells.Q.result
end

function SpellLogic.CanUseQ()
    if not SpellLogic.IsReady(Spells.Q.slot) then
        return false
    end
    return SpellLogic.GetQPrediction() ~= nil
end

-- ============================================================================
-- KILLSTEAL LOGIC
-- ============================================================================
local Killsteal = {}

function Killsteal.TryKillstealW()
    if not SpellLogic.IsReady(Spells.W.slot) then
        return false
    end
    
    local target = TS.get_result(function(res, obj, dist)
        if dist >= menu.ks_w_slider:get() then
            return false
        end
        
        -- Don't killsteal if target is in AA range and can be killed with 2 AAs
        if dist <= Utils.GetAARange(obj) then
            local aaDamage = DamageCalculator.CalculateAADamage(obj)
            if (aaDamage * 2) > Utils.GetShieldedHealth("AD", obj) then
                return false
            end
        end
        
        -- Check if W can kill
        if SpellLogic.GetWDamage(obj) > Utils.GetShieldedHealth("AP", obj) then
            local seg = pred.linear.get_prediction(Spells.W.predinput, obj)
            
            if seg and seg.startPos:distSqr(seg.endPos) <= (Spells.W.range * Spells.W.range) then
                local col = pred.collision.get_prediction(Spells.W.predinput, seg, obj)
                if not col then
                    res.obj = obj
                    res.seg = seg
                    return true
                end
            end
        end
        
        return false
    end)
    
    if target.obj and target.seg then
        player:castSpell("pos", Spells.W.slot, vec3(target.seg.endPos.x, target.obj.y, target.seg.endPos.y))
        return true
    end
    
    return false
end

-- ============================================================================
-- COMBAT LOGIC
-- ============================================================================
local Combat = {}

function Combat.HandleFlee()
    if not menu.flee_key:get() then
        return false
    end
    
    if not orb.menu.movement.minimap:get() and minimap.on_map(game.cursorPos) then
        orb.combat.move_to_cursor()
    else
        player:move(mousePos)
    end
    
    if menu.flee_e:get() and SpellLogic.IsReady(Spells.E.slot) then
        SpellLogic.CastE()
        return true
    end
    
    return false
end

function Combat.HandleEBuff()
    if not (orb.combat.is_active() or orb.menu.hybrid:get() or 
            orb.menu.last_hit:get() or orb.menu.lane_clear:get()) then
        return
    end
    
    if Utils.CheckBuff(player, "kaisae") then
        if not orb.menu.movement.minimap:get() and minimap.on_map(game.cursorPos) then
            orb.combat.move_to_cursor()
        else
            player:move(mousePos)
        end
    end
end

function Combat.HandleCombo()
    if not orb.combat.is_active() then
        return
    end
    
    if menu.combo_w:get() ~= 3 then
        SpellLogic.CastW()
    end
end

function Combat.OnAfterAttack()
    if not orb.combat.is_active() then
        return
    end
    
    if menu.combo_q:get() and SpellLogic.CanUseQ() then
        SpellLogic.CastQ()
        orb.combat.set_invoke_after_attack(false)
    end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================
local function OnTick()
    -- Check for pending callbacks
    if CastState.on_end_func and os.clock() + network.latency > CastState.on_end_time then
        CastState.on_end_func()
    end
    
    -- Handle flee mode
    if Combat.HandleFlee() then
        return
    end
    
    -- Handle E buff movement
    Combat.HandleEBuff()
    
    -- Handle killsteal
    if menu.ks_w:get() then
        Killsteal.TryKillstealW()
    end
    
    -- Handle combo
    Combat.HandleCombo()
end

local function OnRecvSpell(spell)
    if spell.owner.ptr ~= player.ptr then
        return
    end
    
    if CastState.spell_map[spell.name] then
        CastState.spell_map[spell.name](spell)
    end
end

local function OnRecvPath(obj)
    if obj.ptr == player.ptr and obj.path.isDashing then
        CastState.OnDash()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
CastState.spell_map["KaisaQ"] = CastState.OnCastQ
CastState.spell_map["KaisaW"] = CastState.OnCastW
CastState.spell_map["KaisaE"] = CastState.OnCastE
CastState.spell_map["KaisaR"] = CastState.OnCastR

orb.combat.register_f_pre_tick(OnTick)
orb.combat.register_f_after_attack(Combat.OnAfterAttack)
cb.add(cb.spell, OnRecvSpell)
cb.add(cb.path, OnRecvPath)
