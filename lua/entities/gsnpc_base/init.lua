AddCSLuaFile()

include( "entities/gsnpc_base/gsmodule.lua" )
include( "entities/gsnpc_base/pathfind.lua" )
include( "entities/gsnpc_base/shared.lua" )

local Task = gs_aimodule.Task

/*
---------------------------------------------------------------------
-- gStory Nexbot Base 
*/

/*--------------------------------------------------------------------
-- ATTRIBUTES
*/

--- HEALTH ---
ENT.InitialMaxHealth = 100
ENT.InitialHealth = math.huge

--- VISUALS --- 
ENT.Model = "models/combine_soldier.mdl"  -- Model used by the NPC
ENT.Bodygroup = {}                       -- Bodygroups to set on the model

--- WEAPONS & BACKPACK ---
ENT.Weapon = nil                -- Weapon used by the NPC. Will also be put in its inventory
ENT.Inventory = {}                 -- Additional weapons to put in the NPC's inventory

--- BEHAVIOUR ---
ENT.Faction = "FACTION_GMODDER"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.UseLineOfSight = true                -- Whether the NPC needs line of sight to detect enemies
ENT.SightDistance = 2000                 -- Maximum distance at which the NPC can see enemies
ENT.HearingDistance = 1000               -- Maximum distance at which the NPC can hear enemies
ENT.FOV = 90                               -- Field of view angle for sight detection

ENT.UsesEnemyMemory = false 



ENT.MeleeAttackCooldown = 4

ENT.EnemyManagement_Sight_OLS_RE = true -- On Sight Lost, Remove Enemy?
ENT.EnemyManagement_Sight_OLS_DURE = 300 -- On Sight Lost, Distance Until Remove Enemy?

ENT.EnemySorter = "Distance"

--- TASK --- 
ENT.InitialTasks = {{name = "EnemyManagement_Sight"}}

/*--------------------------------------------------------------------
-- CUSTOM HOOKS

[NOTE: Custom functions as attributes are highly avoided to avoid having repeated logic accross multiple NPCs. 
Instead, prefer using global functions in the different modules provided with npcdd_base. This avoids excessive use of memory.]

[ NOTE II: Using inherited hooks is preferred over using custom hooks whenever possible.  However, for vital hooks, 
 a custom one is preferred to avoid breaking functionality if an inherited hook is forgotten to be called. ]

*/

--- OnInitialize ---
-- Called when the NPC is initialized

function ENT:GSAI_Initialize() end

function ENT:GSAI_Think() end 

function ENT:GSAI_OnKilled( dmginfo ) end

function ENT:GSAI_OnOtherKilled( ent, dmginfo ) end

function ENT:GSAI_OnInjured( dmginfo ) end

function ENT:GSAI_OnEntitySight( entity ) end

function ENT:GSAI_OnEntitySightLost( entity ) end

function ENT:GSAI_OnIgnite() end

function ENT:GSAI_OnSwitchWeapons(weapon) end 

function ENT:GSAI_OnEquipWeapon( weapon ) end 

function ENT:GSAI_OnUnequipWeapon( weapon ) end 

function ENT:GSAI_OnWeaponDropped( weapon ) end 

function ENT:GSAI_OnWeaponPickedUp( weapon ) end 

function ENT:GSAI_OnSetEnemy( ent ) end 

function ENT:GSAI_OnEnemyRemoved( ent ) end -- Called when the bot no longer has an enemy

function ENT:GSAI_OnRememberEnemy( ent, pos ) end

function ENT:GSAI_OnForgetEnemy( ent ) end 
  
/*--------------------------------------------------------------------
-- HOOKS
*/

Task.Tasks[ "task_sight" ] = {
    ["OnEntitySight"] = function( self, entity )
        print("Omg hi " .. entity:GetClass())
    end 
}

function ENT:Initialize()

    self:AddFlags(FL_OBJECT)
    self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

    gs_aimodule.InitializeAI( self )
    self:GSAI_Initialize()
    if self.InitialTasks then 
        for _, taskData in ipairs( self.InitialTasks ) do 
            local taskName = taskData.name 
            local taskArgs = taskData.args 
            gs_aimodule.Task.AddTask(self, taskName, taskArgs)
        end 
    end 
    self.InitialTasks = nil 

  

end 

function ENT:Think()
    -- Run the custom base think
    self:GSAI_Think()
    
    -- Run parallel task ticks
    Task.CallHookFromTask( self, "Think" )
end

-- 1. SIGHT/SENSORY RELAY
function ENT:OnEntitySight( ent )
    if GetConVar("gstory_ai_ignoreplayers"):GetBool() and ent:IsPlayer() then return end 
    self:GSAI_OnEntitySight( ent )
    Task.CallHookFromTask( self, "OnEntitySight", ent )
end

function ENT:OnEntitySightLost( ent )

    self:GSAI_OnEntitySightLost( ent )
    Task.CallHookFromTask( self, "OnEntitySightLost", ent )
end

-- 2. COMBAT/DAMAGE RELAY
function ENT:OnInjured( dmginfo )
    local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()

    self:GSAI_OnInjured( attacker, inflictor, dmginfo )
    Task.CallHookFromTask( self, "OnInjured", attacker, inflictor, dmginfo )
end

function ENT:OnOtherKilled( victim, dmginfo )
    self:GSAI_OnOtherKilled( victim, dmginfo )
    Task.CallHookFromTask( self, "OnOtherKilled", victim, dmginfo )

    if victim == self.CurEnemy then 
        gs_aimodule.SetEnemy( self, nil )
    end
end

-- 3. ENVIRONMENTAL RELAY
function ENT:OnIgnite()
    self:GSAI_OnIgnite()
    Task.CallHookFromTask( self, "OnIgnite" )
end



function ENT:RunBehaviour()
    while true do 
        Task.CallHookFromTask( self, "RunBehaviour" )
     
      
        coroutine.yield()
    end
end 

function ENT:OnKilled( dmginfo )
    self:GSAI_OnKilled(dmginfo)
    Task.CallHookFromTask( self, "OnKilled", dmginfo )
    
    self:BecomeRagdoll( dmginfo )
    gs_aimodule.RemoveAllInventoryWeapons( self )
end 

function ENT:OnSetEnemy( ent ) 
    self:GSAI_OnSetEnemy(ent)
    Task.CallHookFromTask( self, "OnSetEnemy", ent )
end 



function ENT:OnRememberEnemy( ent, pos ) 
    self:GSAI_OnRememberEnemy( ent, pos )
    Task.CallHookFromTask(self, "OnRememberEnemy", ent)
end

function ENT:OnForgetEnemy( ent ) 
    self:GSAI_OnForgetEnemy(ent)
    Task.CallHookFromTask(self, "OnForgetEnemy", ent)
end 

function ENT:OnEnemyAdded( ent )
    self:GSAI_OnEnemyAdded(ent)
    Task.CallHookFromTask( self, "OnEnemyAdded", ent )
end 

function ENT:OnEnemyRemoved( ent ) 
    self:GSAI_OnForgetEnemy(ent)
    Task.CallHookFromTask(self, "OnEnemyRemoved", ent)
end 

function ENT:BodyUpdate()
    local vel = self.loco:GetVelocity()
    local velDot = vel:Dot( vel )

    if velDot > 0.00001 then 
        self:BodyMoveXY()
        return
    end

	self:FrameAdvance()
end 