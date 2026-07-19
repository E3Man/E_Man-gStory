ENT.Base = "gsnpc_base" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.Type = "nextbot"
ENT.PrintName = "Gmodder Combatant" -- The name that will appear in the spawn menu.
ENT.Author = "E_Man" -- The author's name for this Entity.
ENT.Category = "gStory" -- The category for this Entity in the spawn menu.
ENT.Purpose = "Elite gmodder fighter" -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.
ENT.AdminOnly = true

list.Set( "NPC", "gsnpc_combatant", {
	Name = "Gmodder Combatant",
	Class = "gsnpc_combatant",
	Category = "gStory NPCs"
})

if (CLIENT) then return end 

AddCSLuaFile()

local Task = gs_aimodule.Task 
local Tasks = Task.Tasks 

ENT.Model = gs_aimodule.GmodderPlayerModels  -- Model used by the NPC
ENT.Bodygroup = {}                       -- Bodygroups to set on the model

--- WEAPONS & BACKPACK ---
ENT.Weapon = {"gswep_revolver", "gswep_smg1", "gswep_shotgun", "gswep_ar2"}          -- Weapon used by the NPC. Will also be put in its inventory
ENT.Inventory = {}                 -- Additional weapons to put in the NPC's inventory

--- BEHAVIOUR ---
ENT.Faction = "FACTION_GMOD"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.UseLineOfSight = true                -- Whether the NPC needs line of sight to detect enemies
ENT.SightDistance = 7000                 -- Maximum distance at which the NPC can see enemies
ENT.HearingDistance = 1000               -- Maximum distance at which the NPC can hear enemies
ENT.FOV = 180   

ENT.InitialMaxHealth = 100
ENT.InitialHealth = 100

ENT.MeleeAttackCooldown = 0.8

ENT.BraveryCoefficient = 3



--- TASKS --- 

ENT.InitialTasks = { {name = "EnemyManagement_Sight"}, {name = "TacticalAI_Patrol"}, {name = "AI_ShootEnemy"}, {name = "SensoryAI_PanicOnOtherKilled"} }

ENT.PreferredCombatTask = {"FodderAI_Flanker", "TacticalAI_DogFight"}
ENT.PreferredIdleTask = {"TacticalAI_Patrol", "TacticalAI_PatrolChill"} 


--- MAIN HOOKS --- 

function ENT:GSAI_Initialize()
    gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )
end
