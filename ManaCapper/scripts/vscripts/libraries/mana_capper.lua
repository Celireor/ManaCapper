--[[

Instructions:

1). Place libraries/timers.lua in scripts/vscripts/libraries if it's not already there
2). Place libraries/mana_capper.lua in scripts/vscripts/libraries
3). Call ManaCapper:OnActivate() in the Activate() function in addon_game_mode.lua (or your custom activate function found in whatever).
4). Place item_mana_modifier in scripts/npc/npc_items_custom.txt
5). Modify scripts/kv/ManaCapper.kv to flag/unflag heroes for mana capping

]]--


if not ManaCapper then
	ManaCapper = {}
	ManaCapper.applier = CreateItem("item_mana_modifier", nil, nil)
	ManaCapper.whitelistedData = LoadKeyValues("scripts/kv/ManaCapper.kv")
end

function ManaCapper:Think()
	
	if not IsValidEntity(self) then
		return
	end
	
	local MaxMana = self:GetMaxMana()
	if MaxMana ~= self.ManaCapper.mana_cap then
	
		local added_mana_stacks = self.ManaCapper.mana_cap - MaxMana
		local mana_modifier = added_mana_stacks + self.ManaCapper.ManaCapStacks --current_mana_modifier
		self.ManaCapper.ManaCapStacks = mana_modifier
		
		if mana_modifier >= 0 then
			if not self:HasModifier("modifier_mana_bonus") then
				ManaCapper.applier:ApplyDataDrivenModifier(self, self, "modifier_mana_bonus", {})
			end
			self:SetModifierStackCount("modifier_mana_bonus", ManaCapper.applier, mana_modifier)
			self:RemoveModifierByNameAndCaster("modifier_mana_penalty", ManaCapper.applier)
		elseif mana_modifier < 0 then
			if not self:HasModifier("modifier_mana_penalty") then
				ManaCapper.applier:ApplyDataDrivenModifier(self, self, "modifier_mana_penalty", {})
			end
			self:RemoveModifierByNameAndCaster("modifier_mana_bonus", ManaCapper.applier)
			self:SetModifierStackCount("modifier_mana_penalty", ManaCapper.applier, -mana_modifier)
		end
	end
	
	self:CalculateStatBonus()
	return 0.25
end

function ManaCapper:ForceSetMaxMana (hero, mana_cap)
	if not hero.ManaCapper then
		hero.ManaCapper = {}
		hero.ManaCapper.mana_cap = mana_cap
		hero.ManaCapper.ManaCapStacks = 0
	
		hero.ManaCapper.Think = ManaCapper.Think
	end
	
	Timers:CreateTimer(hero.ManaCapper.Think, hero)
end

function ManaCapper:LogNPC(keys)
	local npc = EntIndexToHScript(keys.entindex)
	local unitName = npc:GetUnitName()
	if npc:IsRealHero() and npc.bFirstSpawned == nil then	
        npc.bFirstSpawned = true
		if (ManaCapper.whitelistedData[unitName]) then
			ManaCapper:ForceSetMaxMana(npc, ManaCapper.whitelistedData[unitName])
		end
    end
end

function ManaCapper:OnActivate() 
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(ManaCapper, 'LogNPC'), self)
end
