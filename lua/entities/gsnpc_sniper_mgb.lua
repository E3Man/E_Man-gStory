ENT.Base = "gsnpc_base" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.Type = "nextbot"
ENT.PrintName = "Mingebag Sniper" -- The name that will appear in the spawn menu.
ENT.Author = "E_Man" -- The author's name for this Entity.
ENT.Category = "gStory" -- The category for this Entity in the spawn menu.
ENT.Purpose = "[REDACTED]" -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.
ENT.AdminOnly = true

list.Set( "NPC", "gsnpc_sniper_mgb", {
	Name = "Mingebag Sniper",
	Class = "gsnpc_sniper_mgb",
	Category = "gStory NPCs"
})

if (CLIENT) then return end 

AddCSLuaFile()

local Task = gs_aimodule.Task 
local Tasks = Task.Tasks 

ENT.Model = "models/player/kleiner.mdl"  -- Model used by the NPC
ENT.Bodygroup = {}                       -- Bodygroups to set on the model

--- WEAPONS & BACKPACK ---
ENT.Weapon = "gswep_awp"          -- Weapon used by the NPC. Will also be put in its inventory
ENT.Inventory = {"gswep_smg1"}                 -- Additional weapons to put in the NPC's inventory

--- BEHAVIOUR ---
ENT.Faction = "FACTION_MINGEBAGS"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.UseLineOfSight = true                -- Whether the NPC needs line of sight to detect enemies



ENT.InitialMaxHealth = 100
ENT.InitialHealth = 100

ENT.MinimumEnemyDistance = 700

ENT.MeleeAttackCooldown = 0.8

--- TASKS --- 

ENT.InitialTasks = { {name = "EnemyManagement_Sight"}, {name = "TacticalAI_SniperCamp"}, {name = "AI_ShootEnemy"}, {name = "SensoryAI_PanicOnOtherKilled"} }

ENT.PreferredCombatTask = "TacticalAI_SniperCamp"
ENT.PreferredIdleTask = "TacticalAI_SniperCamp"

--- MAIN HOOKS --- 

function ENT:GSAI_Initialize()
    gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )
    
    self:SetSkin(2)
end
