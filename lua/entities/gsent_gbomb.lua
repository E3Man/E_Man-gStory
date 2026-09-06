ENT.Type = "anim" 
ENT.Base = "gsent_base" 
ENT.PrintName = "gBomb" 
ENT.Author = "E_Man" 
ENT.Category = "gStory (Entities)"  
ENT.Purpose = "A rope bomb that does not even use the rope. Who even designed this?"
ENT.Spawnable = true 



if (CLIENT) then return end

AddCSLuaFile()

print("The module:", gs_aimodule)
local Task = gs_aimodule.Task
local Tasks = Task.Tasks



ENT.Faction = "FACTION_GMOD"
ENT.Attitude = D_HT

ENT.Model = "models/dynamite/dynamite.mdl"
ENT.ModelScale = 1

ENT.InitialHealth = 100
ENT.InitialMaxHealth = 100

ENT.HasPhysics = true

ENT.SolidType = SOLID_VPHYSICS
ENT.MoveType = MOVETYPE_VPHYSICS
ENT.PhysicsSolidType = SOLID_VPHYSICS

ENT.GS_Detectable = false 

ENT.InitialTasks = { "GBomb_ExplosionSequence" }


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
end

function ENT:GSENT_Use(activator, caller, useType, value) end 

function ENT:GSENT_OnRemove() end