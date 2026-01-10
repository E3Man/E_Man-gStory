AddCSLuaFile()

local Task = gs_aimodule.Task 
local Tasks = Task.Tasks 



include("entities/gsnpc_skelly/shared.lua")

ENT.Model = "models/player/skeleton.mdl"  -- Model used by the NPC
ENT.Bodygroup = {}                       -- Bodygroups to set on the model

--- WEAPONS & BACKPACK ---
ENT.Weapon = nil            -- Weapon used by the NPC. Will also be put in its inventory
ENT.Inventory = {}                 -- Additional weapons to put in the NPC's inventory

--- BEHAVIOUR ---
ENT.Faction = "FACTION_SKELETON"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.UseLineOfSight = true                -- Whether the NPC needs line of sight to detect enemies
ENT.SightDistance = 2000                 -- Maximum distance at which the NPC can see enemies
ENT.HearingDistance = 1000               -- Maximum distance at which the NPC can hear enemies
ENT.FOV = 180       

ENT.InitialHealth = 10

ENT.MeleeAttackCooldown = 0.8

ENT.AnimPacketSet = { -- How the entity will react to specific holdtypes or animation packets
    none = {
        ply = {
            [ ACT_IDLE ] = ACT_HL2MP_IDLE_ZOMBIE,
            [ ACT_WALK ] = ACT_HL2MP_WALK_ZOMBIE, 
            [ ACT_RUN ] = ACT_HL2MP_RUN_ZOMBIE, 
        }
    }
}

local function MeleeAttack( self, cool, target ) 
    if cool then return end 


            local dmginfo = DamageInfo()
            dmginfo:SetDamageType(bit.bor(DMG_SLASH, DMG_CLUB))
            dmginfo:SetDamage( math.random(3, 7) )
            dmginfo:SetAttacker( self )
            

            target:TakeDamageInfo( dmginfo )
            self:AddGesture(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2)
            if target:IsPlayer() then 
                target:ViewPunch( Angle( -10, 0, 0 ) )
            end 

end 

--- TASKS --- 

ENT.InitialTasks = { {name = "EnemyManagement_Sight"}, {name = "Skellie_EnemyHandler"}  }





Tasks[ "Skellie_ChaseEnemy" ] = {
    ["RunBehaviour"] = function(self)
        if not IsValid( self.CurEnemy ) then Task.RemoveTask( self, "Skellie_ChaseEnemy" ) return end
        local dist = self:GetPos():DistToSqr(self.CurEnemy:GetPos())
        if dist < 30^2 then return end 
        gs_aimodule.Movement.SetActivity(self, ACT_RUN, "ply")
        self:ChaseEntity(self.CurEnemy, {tolerance = 30})
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, "ply")
    end,
    ["Think"] = function(self)
        if not IsValid(self.CurEnemy) then return end 
        local dist = self:GetPos():DistToSqr(self.CurEnemy:GetPos())
        if dist < 70^2 then 
            gs_aimodule.PerformActionWithCooldown(self, "MeleeAttack", self.MeleeAttackCooldown, MeleeAttack, self.CurEnemy)
        end 

    end, 
    ["OnTaskTermination"] = function(self)
         gs_aimodule.Movement.SetActivity(self, ACT_IDLE, "ply")
    end 
}

Tasks[ "Skellie_Hunt" ] = {
    ["RunBehaviour"] = function(self)
    
        local plys = player.GetAll()
        local trgt = plys[ math.random( #plys ) ]
        gs_aimodule.Movement.SetActivity(self, ACT_RUN, "ply")
        self:MoveToPos( trgt:GetPos() )
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, "ply")
    end 
}

Tasks["Skellie_EnemyHandler"] = {
    ["OnSetEnemy"] = function( self, ent )
        if not ent or not IsValid(ent) then Task.RemoveTask( self, "Skellie_ChaseEnemy" ) return end 
   
        Task.AddTask( self, "Skellie_ChaseEnemy" )
    end,
    ["OnEnemyRemoved"] = function( self, ent )
        if #self.Enemies ~= 0 then return end 
        
        Task.AddTask(self, "Skellie_Hunt")
    end 
}


--- MAIN HOOKS --- 



function ENT:GSAI_Initialize()
    gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )

    self:SetSkin(2)


    Task.AddTask(self, "Skellie_Hunt")
   
end 

function ENT:GSAI_Think()
    
end 

function ENT:GSAI_OnKilled( dmginfo )
    self:EmitSound("npc/stalker/stalker_die"..math.random(1,2)..".wav", 70, math.random(30, 100), 1)



end 