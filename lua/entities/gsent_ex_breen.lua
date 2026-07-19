ENT.Type = "anim" 
ENT.Base = "gsent_base" 
ENT.PrintName = "Dr. Breen Statue Example" 
ENT.Author = "E_Man" 
ENT.Category = "gStory (Entities)"  
ENT.Purpose = "Example usage of tasks and some module functions"
ENT.Spawnable = true 



if (CLIENT) then return end

AddCSLuaFile()

local Task = gs_entmodule.Task
local Tasks = Task.Tasks

PrintTable(Tasks)

ENT.Faction = "FACTION_GMOD"
ENT.Attitude = D_HT

ENT.Model = "models/props_trainstation/trashcan_indoor001b.mdl"
ENT.ModelScale = 2

ENT.InitialHealth = 100
ENT.InitialMaxHealth = 100

ENT.HasPhysics = false

ENT.SolidType = SOLID_VPHYSICS
ENT.MoveType = MOVETYPE_NONE
ENT.PhysicsSolidType = SOLID_VPHYSICS

ENT.COVOffset = -80

ENT.GS_Detectable = true 

ENT.InitialTasks = { "Sensory_SightSystem", "AdminCannon_OnWatch", "EnemyManagement_Sight" }


-- ============================================================================
-- GSENT Hooks
-- ============================================================================

function ENT:GSENT_Initialize() 

end 

function ENT:GSENT_Think() end 

function ENT:GSENT_PreTaskInitialization( task ) end 

function ENT:GSENT_PostTaskInitialization( task ) end 

function ENT:GSENT_PreTaskRemoval( task ) end 

function ENT:GSENT_PostTaskRemoval( task ) end 

function ENT:GSENT_PreNewState(oldTask, newTask, stateFlag) end 

function ENT:GSENT_PostNewState(oldTask, newTask, stateFlag) end 

function ENT:GSENT_OnTakeDamage(attacker, inflictor, dmginfo) end 

function ENT:GSENT_OnDeath( attacker, inflictor, dmginfo ) 
self:Dissolve(2)
self.DontDie = true
end

function ENT:GSENT_Use(activator, caller, useType, value) end 

function ENT:GSENT_OnRemove() end