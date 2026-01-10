AddCSLuaFile()

local Task = gs_aimodule.Task 
local Tasks = Task.Tasks 

local function DangerGenerator(self, area, fromArea, ladder, elevator, length)
    if not IsValid(self.CurEnemy) then return 0 end

    local enemyPos = self.CurEnemy:GetPos()
    local areaPos = area:GetCenter()
    local distToEnemy = areaPos:Distance(enemyPos)
    
    -- The "Danger Zone" radius
    local dangerRadius = 1000
    
    if distToEnemy < dangerRadius then
        -- Calculate how "deep" we are in the danger zone (0.0 to 1.0)
        local dangerLevel = 1 - (distToEnemy / dangerRadius)
        
        -- Apply a multiplier. 5000 is high enough that the bot will 
        -- prefer a long detour over walking right past the enemy.
    
        return dangerLevel * 8000 

    end

    return 0
end

include("entities/gsnpc_ebot/shared.lua")

ENT.Model = "models/player/charple.mdl"  -- Model used by the NPC
ENT.Bodygroup = {}                       -- Bodygroups to set on the model

--- WEAPONS & BACKPACK ---
ENT.Weapon = "gswep_smg1"         -- Weapon used by the NPC. Will also be put in its inventory
ENT.Inventory = {}                 -- Additional weapons to put in the NPC's inventory

--- BEHAVIOUR ---
ENT.Faction = "FACTION_E"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.UseLineOfSight = true                -- Whether the NPC needs line of sight to detect enemies
ENT.SightDistance = 7000                 -- Maximum distance at which the NPC can see enemies
ENT.HearingDistance = 1000               -- Maximum distance at which the NPC can hear enemies
ENT.FOV = 180   

ENT.InitialMaxHealth = 100
ENT.InitialHealth = 100

ENT.MeleeAttackCooldown = 0.8




--- TASKS --- 

ENT.InitialTasks = { {name = "EnemyManagement_Sight"}, {name = "EBot_ProtectMaster"} }

local function distSqr(self, ent)
    local pos1, pos2 = self:GetPos(), ent:GetPos()

    local dist = pos1:DistToSqr(pos2)

    return dist 
end 

Tasks["EBot_ProtectMaster"] = {
    ["RunBehaviour"] = function(self)
        if not IsValid(self.Master) then return end 
        local distSqr = distSqr(self, self.Master)
        if distSqr <= 700^2 then return end 
        gs_aimodule.Movement.SetActivity( self, ACT_WALK, true )
        self:ChaseEntity( self.Master, {tolerance = 80, lookahead = math.random(100, 1000)} )
        gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )
    end,
    ["Think"] = function(self) 
        if self.CurEnemy then return end 
        gs_aimodule.PerformActionWithCooldown(self, "Turn", 2, function(self, inCooldown)
            if inCooldown then return end 
            local origin = self:GetPos()
            self.TurnVector =  origin + Vector(  math.random(), math.random(),  math.random())  * self:GetForward()



   
           
        end )
        gs_aimodule.Movement.AimAtVectorByDegree(self, self.TurnVector, math.random(1, 3) )
    end,
    ["OnSetEnemy"] = function(self, ent) 
        if not IsValid(ent) then return end 

        Task.AddTask( self, "EBot_DogFight" )
    end 
}



Tasks["EBot_DogFight"] = {
    ["RunBehaviour"] = function(self)
        if not IsValid(self.CurEnemy) then return end 
         local ePos = self.CurEnemy:GetPos()

        local pos = ePos + ( -1*self.CurEnemy:GetForward() * Vector( math.random(300, 700), math.random(300, 700), 0 ) )
         gs_aimodule.Movement.SetActivity( self, ACT_WALK, true )
     
         self:MoveToPos(pos, { 
            facetoward = self.CurEnemy, 
            lookahead = math.random(50, 3000),
            repath = 2 -- Important: Path updates as the enemy moves
        }, DangerGenerator)
   
         gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )

    end, 
    ["OnEnemyRemoved"] = function(self, ent)
        if #self.Enemies ~= 0 then return end 

        Task.AddTask( self, "EBot_ProtectMaster" )
       
    end 
}


--- MAIN HOOKS --- 



function ENT:GSAI_Initialize()
    gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )

    self.Master = Entity(1)

    gs_aimodule.Factions.SetInstanceRelationship(self, self.Master, D_LI)

    self:SetSkin(2)

    print( self:GetMaxVisionRange() )

   
end 

function ENT:GSAI_Think()
  
            if IsValid(self.CurEnemy) and IsValid(self.Weapon) then 
                if not self:Visible(self.CurEnemy) then return end
            gs_aimodule.Movement.AimAtTarget(self, self.CurEnemy)
            self.loco:FaceTowards( self.CurEnemy:GetPos() )
            gs_aimodule.PerformActionWithCooldown(self, "Shoot", 0.1, function(self, inCooldown)
                if inCooldown then return end 
                self:AddGesture(ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1)
                self.Weapon:PrimaryAttack()
            end )

        end 
end 



