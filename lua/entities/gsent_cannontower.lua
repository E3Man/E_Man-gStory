ENT.Type = "anim" 
ENT.Base = "gsent_base" 
ENT.PrintName = "Admin Cannon Tower" 
ENT.Author = "E_Man" 
ENT.Category = "gStory (Entities)"  
ENT.Purpose = "Automatize the automated. Isn't that cool?"
ENT.Spawnable = true 



if (CLIENT) then return end

AddCSLuaFile()




ENT.Faction = "FACTION_GMOD"
ENT.Attitude = D_HT

ENT.Model = "models/props_phx/games/chess/white_rook.mdl"
ENT.ModelScale = 4

ENT.InitialHealth = 100000
ENT.InitialMaxHealth = 100000

ENT.HasPhysics = false

ENT.SolidType = SOLID_VPHYSICS
ENT.MoveType = MOVETYPE_VPHYSICS
ENT.PhysicsSolidType = SOLID_VPHYSICS

ENT.COVOffset = -80

ENT.GS_Detectable = false

ENT.InitialTasks = {"ACTower_OnCannonDeath", "ACTower_OnTowerRemoval"}


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