
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}
local prefabs = {}

-- Custom starting items
local start_inv = {
}

local function onkilled(inst, data)
	inst.components.hunger:DoDelta(10)
	inst.components.sanity:DoDelta(10)
end

local function onhitother(attacker, inst, damage, stimuli)
	for i = 1,10 do
		inst:DoTaskInTime(10-i, function()
			inst.components.health:DoDelta(-5)
		end)
	end
end

local function onhungerchange(inst, data, forcesilent)
	if inst.components.hunger:GetPercent() >= 0.5 then
		inst.components.combat.damagemultiplier = 0.75
	elseif inst.components.hunger:GetPercent() <= 0.5 then
		inst.components.combat.damagemultiplier = 1.25
	end
end

local function updatestats(inst)
	if TheWorld.state.phase == "day" then
		inst.components.sanity.dapperness = -TUNING.DAPPERNESS_SMALL
	elseif TheWorld.state.phase == "dusk" then
		inst.components.sanity.dapperness = 0
	elseif TheWorld.state.phase == "night" then
		inst.components.sanity.dapperness = 0
	end
end
	
-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when reviving from ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "plagueandrot_speed_mod", 1)
	
	updatestats(inst)
end

local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
   inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "plagueanrot_speed_mod")
end

-- When loading or spawning the character
local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
	
	updatestats(inst)
end


-- This initializes for both the server and client. Tags can be added here.
local common_postinit = function(inst) 
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "esctemplate.tex" )
end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
	-- choose which sounds this character will play
	inst.soundsname = "willow"
	
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    --inst.talker_path_override = "dontstarve_DLC001/characters/"
	
	-- Stats	
	inst.components.health:SetMaxHealth(175)
	inst.components.hunger:SetMax(200)
	inst.components.sanity:SetMax(120)
	
	-- Damage multiplier (optional)
    inst.components.combat.damagemultiplier = 1
	inst.components.combat:SetDefaultDamage(50)
	inst.components.combat.onhitotherfn = onhitother
	
	-- Hunger rate (optional)
	inst.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE
	
	inst.components.temperature.mintemp = 1
	inst.components.temperature.hurtrate = 2.5
	
	inst:ListenForEvent("killed", onkilled)
	inst:ListenForEvent("hungerdelta", onhungerchange)
	inst:WatchWorldState("startday", function(inst) updatestats(inst) end)
	inst:WatchWorldState("startdusk", function(inst) updatestats(inst) end)
	inst:WatchWorldState("startnight", function(inst) updatestats(inst) end)
	updatestats(inst)
	
	inst.components.eater.old_eat = inst.components.eater.Eat
	function inst.components.eater:Eat(food)
		if self:CanEat(food) then
			if food ~= nil and food.components.perishable ~= nil and (food.components.perishable:IsStale() or food.components.perishable:IsSpoiled()) then
				return false
			end
		end
		return inst.components.eater:old_eat(food)
	end
	
	inst:AddTag("monster")
	
	inst.OnLoad = onload
    inst.OnNewSpawn = onload
	
end

return MakePlayerCharacter("esctemplate", prefabs, assets, common_postinit, master_postinit, start_inv)
