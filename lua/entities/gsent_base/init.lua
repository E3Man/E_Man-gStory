AddCSLuaFile()

include("entities/gsent_base/shared.lua")
include("entities/gsent_base/gsent_module.lua")

local Task = gs_entmodule.Task

ENT.GS_ENT = true 
ENT.GS_Detectable = false 

ENT.Model = "models/maxofs2d/companion_doll.mdl"
ENT.ModelScale = 1

ENT.InitialMaxHealth = 0  -- [For Reference]
ENT.InitialHealth = 0 -- [For Reference]

ENT.SolidType = SOLID_VPHYSICS 
ENT.MoveType = MOVETYPE_VPHYSICS 
ENT.PhysicsSolidType = SOLID_VPHYSICS 

ENT.HasPhysics = true 
ENT.Mass = nil -- [For Reference]

ENT.UseType = SIMPLE_USE 



ENT.Faction = "FACTION_GMOD"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.SightDistance = 4000                 -- Maximum distance at which the NPC can see enemies
ENT.FOV = 120                      -- Field of view angle for sight detection

ENT.UsesEnemyMemory = false 

ENT.SortEnemies = true

ENT.EnemyManagement_Sight_OLS_RE = true -- On Sight Lost, Remove Enemy?
ENT.EnemyManagement_Sight_OLS_DURE = 300 -- On Sight Lost, Distance Until Remove Enemy?

ENT.EnemySorter = "Distance"

ENT.InitialTasks = {}


-- ============================================================================
-- GSENT Hooks
-- ============================================================================

function ENT:GSENT_Initialize() end 

function ENT:GSENT_Think() end 

function ENT:GSENT_PreTaskInitialization( task ) end 

function ENT:GSENT_PostTaskInitialization( task ) end 

function ENT:GSENT_PreTaskRemoval( task ) end 

function ENT:GSENT_PostTaskRemoval( task ) end 

function ENT:GSENT_PreNewState(oldTask, newTask, stateFlag) end 

function ENT:GSENT_PostNewState(oldTask, newTask, stateFlag) end 

function ENT:GSENT_OnTakeDamage(attacker, inflictor, dmginfo) end 

function ENT:GSENT_OnDeath( attacker, inflictor, dmginfo ) end

function ENT:GSENT_Use(activator, caller, useType, value) end 

function ENT:GSENT_OnRemove() end

function ENT:GSENT_OnEntitySight(ent) end 

function ENT:GSENT_OnEntitySightLost(ent) end 

function ENT:GSENT_OnSetEnemy( ent ) end 

function ENT:GSENT_OnEnemyRemoved( ent ) end -- Called when the entity no longer has an enemy

function ENT:GSENT_OnRememberEnemy( ent, pos ) end

function ENT:GSENT_OnForgetEnemy( ent ) end 



-- ============================================================================
-- Hooks
-- ============================================================================

function ENT:Initialize() 
    self:GSENT_Initialize()
    gs_entmodule.InitializeEntity(self)
end

function ENT:Think() 
    self:GSENT_Think()
    Task.CallHookFromTask(self, "Think")
end

function ENT:Use(activator, caller, useType, value) 
    self:GSENT_Think(activator, caller, useType, value)
    Task.CallHookFromTask(self, "Use", activator, caller, useType, value)
end

function ENT:OnRemove() 
    self:GSENT_OnRemove()
    Task.CallHookFromTask(self, "OnRemove")
end

function ENT:PreTaskInitialization( task ) 
    self.GSENT_PreTaskInitialization(task)
    Task.CallHookFromTask( self, "PreTaskInitialization", task )
end 

function ENT:PostTaskInitialization( task ) 
    self:GSENT_PostTaskInitialization(task)
    Task.CallHookFromTask( self, "PostTaskInitialization" )
end 

function ENT:PreTaskRemoval( task ) 
    self:GSENT_PreTaskRemoval(task)
    Task.CallHookFromTask( self, "PreTaskRemoval" )
end 

function ENT:PostTaskRemoval( task ) 
    self:GSENT_PostTaskRemoval( task )
    Task.CallHookFromTask( self, "PreTaskRemoval" )
end 

function ENT:PreNewState(oldTask, newTask, stateFlag) 
    self:GSENT_PreNewState( oldTask, newTask, stateFlag )
    Task.CallHookFromTask( self, "PreNewState", oldTask, newTask, stateFlag )
end 

function ENT:PostNewState(oldTask, newTask, stateFlag) 
    self:GSENT_PostNewState( oldTask, newTask, stateFlag )
    Task.CallHookFromTask( self, "PostNewState", oldTask, newTask, stateFlag )
end 

function ENT:OnTakeDamage( dmginfo ) 

    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()
    
    self:GSENT_OnTakeDamage( attacker, inflictor, dmginfo )
    Task.CallHookFromTask( self, "OnTakeDamage", attacker, inflictor, dmginfo )

    -- Apply the damage to the entity's health
    local currentHealth = self:Health()
    local damageAmount = dmginfo:GetDamage()
    self:SetHealth(currentHealth - damageAmount)

    -- Apply physical force from the impact
        self:TakePhysicsDamage(dmginfo)


    if self:GetMaxHealth() != 0 and self:Health() <= 0 then 
        self:OnDeath(attacker, inflictor, dmginfo)
        if self.DontDie then return end 
        self:Remove()
    end 
end 

function ENT:OnDeath(attacker, inflictor, dmginfo) 
    self:GSENT_OnDeath( attacker, inflictor, dmginfo )
    Task.CallHookFromTask( self, "OnDeath", attacker, inflictor, dmginfo )
end 

function ENT:Internal_OnEntitySight(ent)
    self:GSENT_OnEntitySight(ent)
    Task.CallHookFromTask(self, "OnEntitySight", ent)
end 

function ENT:Internal_OnEntitySightLost(ent) 
    self:GSENT_OnEntitySightLost(ent)
    Task.CallHookFromTask(self, "OnEntitySightLost", ent)
end 

function ENT:OnSetEnemy( ent ) 
    self:GSENT_OnSetEnemy(ent)
    Task.CallHookFromTask( self, "OnSetEnemy", ent )
end 



function ENT:OnRememberEnemy( ent, pos ) 
    self:GSENT_OnRememberEnemy( ent, pos )
    Task.CallHookFromTask(self, "OnRememberEnemy", ent)
end

function ENT:OnForgetEnemy( ent ) 
    self:GSENT_OnForgetEnemy(ent)
    Task.CallHookFromTask(self, "OnForgetEnemy", ent)
end 

function ENT:OnEnemyAdded( ent )
    self:GSENT_OnEnemyAdded(ent)
    Task.CallHookFromTask( self, "OnEnemyAdded", ent )
end 

function ENT:OnEnemyRemoved( ent ) 
    self:GSENT_OnForgetEnemy(ent)
    Task.CallHookFromTask(self, "OnEnemyRemoved", ent)
end 