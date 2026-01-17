gs_aimodule = gs_aimodule or {}
gs_aimodule.Task = gs_aimodule.Task or {}

local Task  = gs_aimodule.Task 
local Tasks = Task.Tasks 

-- Define constant outside to avoid recalculating
local DANGER_RADIUS_SQ = 1000000 -- (1000 * 1000)

local function DangerGenerator(self, area, fromArea, ladder, elevator, length)
    if not IsValid(self.CurEnemy) then return 0 end

    -- Optimization: Use built-in DistToSqr to avoid creating a new Vector object
    -- This saves memory and CPU on every single pathfinding node check
    local distSq = area:GetCenter():DistToSqr(self.CurEnemy:GetPos())

    if distSq < DANGER_RADIUS_SQ then
        -- Optimization: Calculate danger based on Squared Distance.
        -- This avoids math.sqrt entirely.
        -- The curve is slightly different (non-linear), but effectively tells the AI 
        -- "It is very bad to be close, and okay to be far," which is what you want.
        local dangerLevel = 1 - (distSq / DANGER_RADIUS_SQ)
        
        return dangerLevel * 4000 
    end

    return 0
end

local function distSqr(self, ent)
    local pos1, pos2 = self:GetPos(), ent:GetPos()

    local dist = pos1:DistToSqr(pos2)

    return dist 
end 


-- Tactical AI Idle Task - Shared between Gmodder and Infantry
Tasks["TacticalAI_Idle"] = {
    ["OnTaskInitialization"] = function(self) 
         gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )
    end, 
    ["RunBehaviour"] = function(self)
       
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
        Task.AddTask( self, self.PreferredCombatTask )
    end,
    ["OnTaskTermination"] = function(self)
        local forward = self:GetForward()
        gs_aimodule.Movement.AimAtVector( self, forward )
    end
}

local signs = {
    1,
    -1 
}

Tasks["TacticalAI_DogFight"] = {
    ["RunBehaviour"] = function(self)
        if not IsValid(self.CurEnemy) then return end 
        
        local ePos = self.CurEnemy:GetPos()
        local eForward = self.CurEnemy:GetForward()
        
      
        local dist = math.random(300, 700)
        local dir = (math.random(1, 2) == 1) and 1 or -1
        
   
        local targetPos = ePos + (eForward * dist * dir)

     
        targetPos.z = self:GetPos().z 

        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)
     
        self:MoveToPos(targetPos, { 
            facetoward = self.CurEnemy, 
            lookahead = math.random(50, 2000)
        }, DangerGenerator)
        
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end, 
    ["OnEnemyRemoved"] = function(self, ent)
        if #self.Enemies ~= 0 then return end 
        -- Optimization: Use RunPIdleTask directly if available, or AddTask
        Task.RunPIdleTask(self) 
    end
}

Tasks["AI_ShootEnemy"] = {
    ["Think"] = function(self)
            if IsValid(self.CurEnemy) and IsValid(self.Weapon) then 
                local enemyPos = self.CurEnemy:GetPos()
                self.loco:FaceTowards( enemyPos )
                if not self:Visible(self.CurEnemy) then return end
   
                
                if distSqr(self, self.CurEnemy) > (self.RangedAttackRange or 3000)^2 then 
                    return 
                end 
                

            gs_aimodule.Movement.AimAtVector(self, self.CurEnemy:GetPos() + Vector(0,10,0))
            gs_aimodule.PerformActionWithCooldown(self, "Shoot", 0.1, function(self, inCooldown)
                if inCooldown then return end 
             
                self.Weapon:PrimaryAttack()
            end )
        end 
    end 
}