ENT.Base = "gsnpc_base" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.Type = "nextbot"
ENT.PrintName = "Healer" -- The name that will appear in the spawn menu.
ENT.Author = "E_Man" -- The author's name for this Entity.
ENT.Category = "gStory" -- The category for this Entity in the spawn menu.
ENT.Purpose = "MEDIIICC!" -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.

list.Set( "NPC", "gsnpc_healer", {
	Name = "Healer",
	Class = "gsnpc_healer",
	Category = "gStory NPCs"
})

if (CLIENT) then return end 

AddCSLuaFile()

local Task = gs_aimodule.Task 
local Tasks = Task.Tasks 

ENT.Model = "models/player/Group03m/male_07.mdl"  -- Model used by the NPC
ENT.Bodygroup = {}                       -- Bodygroups to set on the model

--- WEAPONS & BACKPACK ---
ENT.Weapon = "gswep_medkit"         -- Weapon used by the NPC. Will also be put in its inventory
ENT.Inventory = {}                 -- Additional weapons to put in the NPC's inventory

--- BEHAVIOUR ---
ENT.Faction = "FACTION_GMOD"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.UseLineOfSight = true                -- Whether the NPC needs line of sight to detect enemies


ENT.InitialMaxHealth = 100 
ENT.InitialHealth = 100

ENT.MeleeAttackCooldown = 0.8

ENT.RangedAttackRange = 2000

ENT.Medic = true 

ENT.PreferredCombatTask = "MedicAI_ApproachWounded"
ENT.PreferredIdleTask   = "MedicAI_LookForWounded"

ENT.InitialMotionStats = {
    speed = 400
}

ENT.CentralActivityToMotion = {
    [ACT_RUN] = { speed = 600 }
}


ENT.InitialTasks = { {name = "EnemyManagement_Sight"}, {name = "MedicAI_QueueWounded"}, {name = "MedicAI_LookForWounded"} }

function ENT:GSAI_Initialize()
    gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )
    
    self.HealQueue = {}
end 

function ENT:GSAI_OnKilled()
   
end




