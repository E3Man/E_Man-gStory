AddCSLuaFile()

local Task = gs_aimodule.Task 
local Tasks = Task.Tasks 

include("entities/gsnpc_gmodder/shared.lua")


ENT.Model = "models/player/Group03/male_07.mdl"  -- Model used by the NPC
ENT.Bodygroup = {}                       -- Bodygroups to set on the model

--- WEAPONS & BACKPACK ---
ENT.Weapon = "gswep_smg1"         -- Weapon used by the NPC. Will also be put in its inventory
ENT.Inventory = {}                 -- Additional weapons to put in the NPC's inventory

--- BEHAVIOUR ---
ENT.Faction = "FACTION_WPD"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.UseLineOfSight = true                -- Whether the NPC needs line of sight to detect enemies
ENT.SightDistance = 7000                 -- Maximum distance at which the NPC can see enemies
ENT.HearingDistance = 1000               -- Maximum distance at which the NPC can hear enemies
ENT.FOV = 180   

ENT.InitialMaxHealth = 100
ENT.InitialHealth = 100

ENT.MeleeAttackCooldown = 0.8




--- TASKS --- 

ENT.InitialTasks = { {name = "EnemyManagement_Sight"}, {name = "TacticalAI_Idle"}, {name = "AI_ShootEnemy"} }




--- MAIN HOOKS --- 



function ENT:GSAI_Initialize()
    gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )
    


    self:SetSkin(2)
   
end 



