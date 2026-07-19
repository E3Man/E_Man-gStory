gs_aimodule = gs_aimodule or {}
gs_aimodule.Task = gs_aimodule.Task or {}

local Task  = gs_aimodule.Task 
local Tasks = Task.Tasks 

local Factions = gs_aimodule.Factions 

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function makeSet(list)
   
    local set = {}
    for _, value in pairs(list) do
        set[value] = true
    end
    return set
end

local function distSqr(self, ent)
    local pos1, pos2 = self:GetPos(), ent:GetPos()
    local dist = pos1:DistToSqr(pos2)
    return dist 
end 

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
        
        return dangerLevel * 7000 
    end

    return 0
end

local function VisibilityCost(self, area, fromArea, ladder, elevator, length)
    local areaPos = area:GetCenter()
    local enemyPos = self.CurEnemy and self.CurEnemy:GetPos() or vector_origin 

    if not self.CurEnemy:VisibleVec( areaPos ) then 
        return 5000
    end 

    return 0
end

-- Motion option helpers
local hasEnemyMotionOptions = {
    [true] = ACT_RUN,
    [false] = ACT_WALK
}

-- ============================================================================
-- SENSORIAL TASKS
-- ============================================================================

local function SightUpdateFunc(self, inCooldown)
    if inCooldown then  return end 
    gs_aimodule.UpdateSightList(self)

end

Tasks["SensoryAI_SightSystem"] = {
    ["Think"] = function(self)
        gs_aimodule.PerformActionWithCooldown(self, "UpdateSight", 0.3,  SightUpdateFunc)
    end 
}

Tasks["SensoryAI_PanicOnOtherKilled"] = {
    ["OnOtherKilled"] = function(self, ent)
        if Factions.GetDisposition(self, ent) ~= D_LI then return end 

        local dist = self:GetRangeSquaredTo( ent ) 

        if dist > 250000 then return end  

        local braveryCoefficient = self.BraveryCoefficient and 1/self.BraveryCoefficient or 1

        local stressThreshold = self.StressThreshold or 100

        self.PanicMeter = self.PanicMeter or 0 

        local meter = self.PanicMeter 

        

        if meter >= stressThreshold then 
            Task.RunPreferredTaskFor(self, "Panic") 
            self.PanicMeter = math.Clamp( meter - stressThreshold, 0, stressThreshold ) -- Leftover fear
            return 
        end 

        self.PanicMeter = meter + math.random(3, 14) * braveryCoefficient 
        
    end 
}

Tasks["SensoryAI_IdleOnNoEnemies"] = {
    ["OnEnemyRemoved"] = function(self, ent)
        if #self.Enemies ~= 0 then return end 
        Task.RunPreferredTaskFor(self, "Idle")
    end,
    Priority = 50
}

Tasks["SensoryAI_CombatOnEnemies"] = {
    ["OnSetEnemy"] = function(self, ent)
        if not IsValid(ent) then return end
        Task.RunPreferredTaskFor(self, "Combat")
    end,
    Priority = 50
}

Tasks["SensoryAI_FlagIdle"] = {
    ["PreTaskInitialization"] = function(self, task)
        if self.IsIdle then return end 

    

        local preferred = self.PreferredIdleTask
        if istable(preferred) then
            self.IsIdle = makeSet(preferred)[task] 
        elseif isstring(preferred) then 
            self.IsIdle = task == preferred 
        end 




    end,
    ["TaskRemoval"] = function(self, task)
        if not self.IsIdle then return end 

        local preferred = self.PreferredIdleTask
       if istable(preferred) then
            self.IsIdle = makeSet(preferred)[task] 
        elseif isstring(preferred) then 
            self.IsIdle = task == preferred 
        end 

      
    
    end,
    Priority = 100
}

Tasks["SensoryAI_ResumeAnimOnLand"] = {
    ["OnLandOnGround"] = function(self, ent)
        gs_aimodule.Movement.SetActivity(self, self.CentralActivity, true)

    end 
}

-- ============================================================================
-- SHARED TACTICAL TASKS
-- ============================================================================

-- Idle Task - Shared between multiple NPCs

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
    ["OnTaskTermination"] = function(self)
        local forward = self:GetForward()
        gs_aimodule.Movement.AimAtVector( self, forward )
    end
}

-- Patrol Task - Navigate using navmesh to random areas

local runWalkDice = {
    ACT_WALK,
    ACT_RUN
}

Tasks["TacticalAI_PatrolChill"] = {
    ["OnTaskInitialization"] = function(self)
        self.PatrolStartPos = self:GetPos()
        self.NextPatrolPoint = nil
    end,
    ["RunBehaviour"] = function(self)
        coroutine.wait(0.3 + 10 * math.random())

        if not IsValid(self.NextPatrolPoint) then
         
            local searchRadius = 1500
            local randomOffset = Vector(math.random(-searchRadius, searchRadius), math.random(-searchRadius, searchRadius), 0)
            local searchPos = self.PatrolStartPos + randomOffset
            
            local area = navmesh.GetNearestNavArea(searchPos)
            if IsValid(area) then
                self.NextPatrolPoint = area:GetClosestPointOnArea(searchPos)
            else
                return
            end
        end
        
        local dice = math.random(1,2)

        local ca = runWalkDice[ dice ]


        gs_aimodule.Movement.SetActivity(self, ca, true)
        self:MoveToPos(self.NextPatrolPoint, { tolerance = 50 })
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end,
    ["Think"] = function(self)
        if self.CurEnemy then return end
        
        -- Check if we've reached the patrol point
        local distToPoint = self:GetPos():DistToSqr(self.NextPatrolPoint or self:GetPos())
        if distToPoint < 2500 then
            self.NextPatrolPoint = nil
        end


    gs_aimodule.PerformActionWithCooldown(self, "UpdateTurnTarget", math.random(4, 7), function(self, inCooldown)
        if inCooldown then return end 
        
        local fwd = self:GetForward()
        local right = self:GetRight()
        

        local horizontalOffset = (math.random() * 2 - 1) * 1.5
        local verticalOffset = (math.random() * 0.4 - 0.2) 
        
       
        self.TurnVector = self:GetPos() + (fwd + (right * horizontalOffset) + (Vector(0,0,1) * verticalOffset)) * 100
    end)

   
    if not self.TurnVector then self.TurnVector = self:GetPos() + self:GetForward() * 100 end

   
    gs_aimodule.Movement.AimAtVectorByDegree(self, self.TurnVector, 2)

    end,
    ["OnTaskTermination"] = function(self)
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end
}

Tasks["TacticalAI_Patrol"] = {
    ["OnTaskInitialization"] = function(self)
        self.PatrolStartPos = self:GetPos()
        self.NextPatrolPoint = nil
    end,
    ["RunBehaviour"] = function(self)
        coroutine.wait(0.3)

        if not IsValid(self.NextPatrolPoint) then
            -- Get a random nav area near the patrol start position
            local searchRadius = 1500
            local randomOffset = Vector(math.random(-searchRadius, searchRadius), math.random(-searchRadius, searchRadius), 0)
            local searchPos = self.PatrolStartPos + randomOffset
            
            local area = navmesh.GetNearestNavArea(searchPos)
            if IsValid(area) then
                self.NextPatrolPoint = area:GetClosestPointOnArea(searchPos)
            else
                return
            end
        end
        
        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)
        self:MoveToPos(self.NextPatrolPoint, { tolerance = 50 })
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end,
    ["Think"] = function(self)
        if self.CurEnemy then return end
        
        -- Check if we've reached the patrol point
        local distToPoint = self:GetPos():DistToSqr(self.NextPatrolPoint or self:GetPos())
        if distToPoint < 2500 then
            self.NextPatrolPoint = nil
        end
    end,
    ["OnTaskTermination"] = function(self)
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end
}



-- ============================================================================
-- TACTICAL COMBAT TASKS
-- ============================================================================

-- DogFight Task - Tactical positioning during combat
Tasks["TacticalAI_DogFight"] = {
    ["RunBehaviour"] = function(self)
        if not IsValid(self.CurEnemy) then return end 
        
        local ePos = self.CurEnemy:GetPos()
        local eForward = self.CurEnemy:GetForward()
        
        local dist = math.random(300, 700)
        local dir = (math.random(1, 2) == 1) and 1 or -1
        
        local targetPos = ePos + (eForward * dist * dir)

        local area = navmesh.GetNearestNavArea(targetPos)
        if IsValid(area) then
            targetPos = area:GetClosestPointOnArea(targetPos)
        else
            return
        end

        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)
     
        self:MoveToPos(targetPos, { 
            faceenemy = true, 
            lookahead = math.random(50, 2000)
        }, DangerGenerator)
        
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end
}

Tasks["TacticalAI_SneakyRush"] = {
    ["RunBehaviour"] = function(self)
    local enemy = self.CurEnemy 
    if not IsValid(enemy) then return end 

    local ePos = enemy:GetPos()
    local minDist = self.MinimumEnemyDistance


    local randomAngle = math.random() * 2 * math.pi

    local offsetX = math.cos(randomAngle) * minDist
    local offsetY = math.sin(randomAngle) * minDist

    local finalPos = gs_aimodule.GetNearestPointTo(Vector(ePos.x + offsetX, ePos.y + offsetY, ePos.z))
        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)
     
        self:MoveToPos(finalPos, { 
            faceenemy = true, 
            lookahead = math.random(50, 500) 
        })
        
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
        

    end 
}

Tasks["TacticalAI_SniperCamp"] = {
    ["OnTaskInitialization"] = function(self) 
        self.CampPos = self:GetPos()
        self.StrafeNextDirectionChange = 0
        self.StrafeDirection = 0  -- -1 for left, 1 for right
        gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )
    end, 
    ["RunBehaviour"] = function(self) 
        if self.CurEnemy and self:GetRangeSquaredTo( self.CurEnemy) < self.MinimumEnemyDistance^2 then 
            self.CloseQuarterCombat = true 
            local enemy = self.CurEnemy 
            Tasks["TacticalAI_Strafe"].RunBehaviour(self) 
            return 
        end 

        if self:GetRangeSquaredTo( self.CampPos ) > 50^2 then 
            self.CloseQuarterCombat = false 
            gs_aimodule.Movement.SetActivity( self, ACT_RUN, true )
            self:MoveToPos(self.CampPos) 
            gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )             
        end 

    end,
    ["Think"] = function(self)
        if self.CloseQuarterCombat and not self.CloseQuarterCombat_WeaponReady then 
            self.CloseQuarterCombat_WeaponReady = true 
            gs_aimodule.EquipWeapon(self, "gswep_smg1") 
            print("SMG1 Equipped")
        elseif  not self.CloseQuarterCombat and self.CloseQuarterCombat_WeaponReady then 
            self.CloseQuarterCombat_WeaponReady = false
            gs_aimodule.EquipWeapon(self, self.PreviousWeapon)      
            print("oh")
        end 
    end 
}

local function NextbotHop(self, inCooldown)
    if inCooldown then return end
    gs_aimodule.Movement.Jump(self)
end 

Tasks["TacticalAI_SpamHop"] = {
    ["Think"] = function(self)
        if self.IsMoving then 
            gs_aimodule.PerformActionWithCooldown( self, "FightHop", math.random(2, 4), NextbotHop )
        end 
    end 
}


-- Shooting Task - Generic ranged attack behavior
Tasks["AI_ShootEnemy"] = {
    ["OnEntitySight"] = function(self, ent)
        if IsValid(ent) and ent == self.CurEnemy then 
            self.EnemyIsVisible = true 
        end 
    end, 
    ["OnEntitySightLost"] = function(self, ent)
        if IsValid(ent) and ent == self.CurEnemy then 
            self.EnemyIsVisible = false 
            gs_aimodule.Movement.AimAtVector(self, self:WorldSpaceCenter() + self:GetForward())
        end 
    end, 
    ["Think"] = function(self)
            if IsValid(self.CurEnemy) and IsValid(self.Weapon) then 
                local enemyPos = self.CurEnemy:GetPos()
                if not self:Visible(self.CurEnemy) then return end 
                
                self.loco:FaceTowards( enemyPos )
            
                if distSqr(self, self.CurEnemy) > (self.RangedAttackRange or 3000)^2 then 
                    return 
                end 
                
            local aimVector = self:GSAI_HeadTarget( self.CurEnemy ) or self.CurEnemy:GetPos()
            gs_aimodule.Movement.AimAtVector(self, aimVector )
            gs_aimodule.PerformActionWithCooldown(self, "Shoot", 0.1, function(self, inCooldown)
                if inCooldown then return end 
             
                self.Weapon:PrimaryAttack()
            end )
        end 
    end 
}



-- ============================================================================
-- FODDER/SLAVE TASKS
-- ============================================================================

-- Meat Shield Task - Rush towards enemy
Tasks["FodderAI_MeatShield"] = {
    ["RunBehaviour"] = function(self)
        if not IsValid(self.CurEnemy) then return end 
        
        local enemyPos = self.CurEnemy:GetPos()
        local selfPos = self:GetPos()
        

        local dirToEnemy = (enemyPos - selfPos):GetNormalized()
        
   
        local targetDist = math.random(200, 400)
        local targetPos = enemyPos - (dirToEnemy * targetDist) 
        targetPos.z = selfPos.z 
        
        local area = navmesh.GetNearestNavArea(targetPos)
        if IsValid(area) then
            targetPos = area:GetClosestPointOnArea(targetPos)
        else
            Task.AddTask(self, "TacticalAI_Strafe")
            return
        end
        
        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)

        self:MoveToPos(targetPos, { 
            tolerance = 20,
            faceenemy = true, 
            lookahead = 100,
            timeout = 1.2 
        })
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end
}


-- Flanker Task - Movimientos tácticos de flanqueo por los lados
Tasks["FodderAI_Flanker"] = {
    ["RunBehaviour"] = function(self)
        if not IsValid(self.CurEnemy) then return end 
        
        local enemyPos = self.CurEnemy:GetPos()
        local selfPos = self:GetPos()
        


        local dirToEnemy = (enemyPos - selfPos):GetNormalized()
        

        local perpendicularRight = Vector(-dirToEnemy.y, dirToEnemy.x, 0)

        local sideFactor = (math.random(1, 2) == 1) and -1 or 1

        local forwardDist = math.random(150, 350)
        local sideDist = math.random(450, 750) * sideFactor
        

        local targetPos = selfPos + (dirToEnemy * forwardDist) + (perpendicularRight * sideDist)
        targetPos.z = selfPos.z

   
        local area = navmesh.GetNearestNavArea(targetPos)
        if IsValid(area) then
            targetPos = area:GetClosestPointOnArea(targetPos)
        else
          
            return
        end

        -- 5. MOVIMIENTO SEGURO
        self.loco:FaceTowards(enemyPos)
        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)
        
        self:MoveToPos(targetPos, { 
            tolerance = 30,
            lookahead = 100, 
            faceenemy = true,
            timeout = 2.0 
        })
        
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end
}

Tasks["FodderAI_Circler"] = {
    ["RunBehaviour"] = function(self) 
        if not IsValid(self.CurEnemy) then return end 

        local enemy = self.CurEnemy 
        local ePos = enemy:GetPos() 

        minDist = self.MinimumEnemyDistance
        maxDist = self.RangedAttackRange 
        
        local randomX = math.random(minDist,  maxDist)
        local randomY = math.random(minDist, maxDist)

        local Z = ePos.z 

        local targetPos = self.CurEnemy:GetPos() + Vector( randomX, randomY, Z )

        local pos = gs_aimodule.GetRandomPointNearVector( targetPos ) 

        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)
        self:MoveToPos(targetPos, { 
            faceenemy = true, 
            lookahead = 200 
        })
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
        coroutine.wait(1, 30)

    end     
}



-- ============================================================================
-- HEALER TASKS
-- ============================================================================

-- Heal Wounded Task - Direct healing
Tasks["MedicAI_HealWounded"] = {
    ["Think"] = function(self)
        if #self.HealQueue == 0 then return end 
        
        local toHeal = self.HealQueue[1]

        if not IsValid(toHeal) then return end 

        self.loco:FaceTowards(toHeal:GetPos())

        if distSqr(self, toHeal) > 14400 then return end 

        gs_aimodule.PerformActionWithCooldown( self, "UseMedkit", 2, function(self, inCooldown) 
            if inCooldown then return end 

            if not IsValid(self.Weapon) then return end

            self.Weapon:PrimaryAttack()
        end )
    end 
}

-- Queue Wounded Task - Track and prioritize injured allies
Tasks["MedicAI_QueueWounded"] = {
    ["OnEntitySight"] = function(self, ent)
       
        if  gs_aimodule.Factions.GetDisposition(self, ent) ~= D_LI then return end 

        

        local maxHealth = ent:GetMaxHealth()
        local curHealth = ent:Health()
        local healthRatio = curHealth / maxHealth 

        if healthRatio < 0.75 then 
            table.insert( self.HealQueue, ent )
           
            Task.RunPreferredTaskFor(self, "Combat")
        end 
    end,
    ["Think"] = function(self)
        if #self.HealQueue == 0 then return end 

        local toHeal = self.HealQueue[1]

        if not IsValid( toHeal )  then table.remove( self.HealQueue, 1 ) return end 

        local maxHealth = toHeal:GetMaxHealth()
        local curHealth = toHeal:Health()
        local healthRatio = curHealth / maxHealth 

        if  healthRatio >= 1 then 
            table.remove( self.HealQueue, 1 )
        
        end 
    end 
}

-- Look For Wounded Task - Patrol while searching for wounded allies
Tasks["MedicAI_LookForWounded"] = {
    ["RunBehaviour"] = function(self)
        local hasEnemies = #self.Enemies ~= 0 
        local howToMove = hasEnemyMotionOptions[hasEnemies]

 
        local randomDir = Vector(math.random(-800, 800), math.random(-800, 800), 0)
        local targetPos = self:GetPos() + randomDir


        local area = navmesh.GetNearestNavArea(targetPos)
        local finalPos = targetPos

        if IsValid(area) then
          
            finalPos = area:GetClosestPointOnArea(targetPos)
        else
            
            return 
        end

        -- 3. Execute Movement
        gs_aimodule.Movement.SetActivity(self, howToMove, true)
        
      
        self:MoveToPos(finalPos, {maxage = 5, tolerance = 50})
        
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end
}

-- Approach Wounded Task - Move behind target for backstabbing behavior
Tasks["MedicAI_ApproachWounded"] = {
    ["OnTaskInitialization"] = function(self)
        Task.AddTask(self, "MedicAI_HealWounded")
     
    end,  
    ["RunBehaviour"] = function(self)
        if #self.HealQueue == 0 then print("Queue's empty. Looking for more patients!") Task.RunPreferredTaskFor(self, "Idle") return end 
        
        local toHeal = self.HealQueue[1]
        if not IsValid(toHeal) then  return end 
        
        if distSqr(self, toHeal) <= 8100 then return end 
        
        local hasEnemies = #self.Enemies ~= 0 
        local howToMove = hasEnemyMotionOptions[hasEnemies]
        
        -- Position behind the target (backstabbing behavior)
        local backstabPos = toHeal:GetPos() - (toHeal:GetForward() * 70)

        gs_aimodule.Movement.SetActivity(self, howToMove, true)
        self:MoveToPos(backstabPos, {tolerance = 10, facetoward = toHeal})
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end,
    ["OnTaskTermination"] = function(self)
        Task.RemoveTask(self, "MedicAI_HealWounded")
        
    end 
}

-- ============================================================================
-- PANIC TASKS
-- ============================================================================

-- Run toward a random spot in panic
Tasks["PanicAI_BreakPosture"] = {
    ["RunBehaviour"] = function(self)
        local pos = self:GetPos()
        local rad = math.random(800, 2400)
    
        local loco = self.loco 

        local stepHeight = loco:GetStepHeight()
        local dropHeight = loco:GetDeathDropHeight()

        local areas = navmesh.Find(pos, rad, stepHeight, dropHeight)

        local area = areas[math.random( #areas )]

        if area then 
            local tgtPos = area:GetCenter()
            gs_aimodule.Movement.SetActivity( self, ACT_RUN, true )
            local status = self:MoveToPos( tgtPos, {facetoward = self.CurEnemy} )
            gs_aimodule.Movement.SetActivity( self, ACT_CROUCHIDLE, true )
            coroutine.wait(math.random(1, 9))
            gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )

        end 

      
        Task.RunPIdleOrCombatTask(self)
    end 
}

-- ============================================================================
-- STRAFING COMBAT TASK
-- ============================================================================

-- TacticalAI_Strafe - Strafes around the enemy in close combat
Tasks["TacticalAI_Strafe"] = {
    ["OnTaskInitialization"] = function(self)
        self.StrafeNextDirectionChange = 0
        self.StrafeDirection = 0  
    end,
    ["RunBehaviour"] = function(self)
        if not IsValid(self.CurEnemy) then return end

        local enemyPos = self.CurEnemy:GetPos()
        local selfPos = self:GetPos()

   
        if CurTime() >= self.StrafeNextDirectionChange then
            self.StrafeDirection = (math.random(1, 2) == 1) and 1 or -1
            self.StrafeNextDirectionChange = CurTime() + math.random(1.5, 3.5)
        end

     
        local right = math.random(1,2) == 1 and self:GetForward() or self:GetRight()
        local strafeDistance = self.StrafeStrafeDistance or 150 
        local strafeOffset = right * self.StrafeDirection * strafeDistance
        local targetPos = selfPos + strafeOffset

      
        local area = navmesh.GetNearestNavArea(targetPos)
        if IsValid(area) then
            targetPos = area:GetClosestPointOnArea(targetPos)
        else
           
            self.StrafeDirection = -self.StrafeDirection
            self.StrafeNextDirectionChange = CurTime() + 0.5
            return 
        end

       
        self.loco:FaceTowards(enemyPos)
        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)
        

        self:MoveToPos(targetPos, { tolerance = 30, lookahead = 60, faceenemy = true, timeout = 1.5 })
        
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)

        if not IsValid(self.CurEnemy) then return end

        local distToEnemy = selfPos:DistToSqr(enemyPos)
        local switchDistance = (self.StrafePushSwitchDistance or 2000) ^ 2

        if distToEnemy > switchDistance then
            Task.AddTask(self, "TacticalAI_Push")
        end

        if math.random(1,10) == 1 then 
            if not self:IsAbleToSee( self.CurEnemy ) then 
                Task.AddTask(self, "TacticalAI_Push")
            end 
        end 
    end, 
    ["OnTaskTermination"] = function(self)
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end
}



Tasks["TacticalAI_CircularStrafe"] = {
    ["OnTaskInitialization"] = function(self)
        self.StrafeCenter = self:GetPos()
    end, 
    ["RunBehaviour"] = function(self)
        if not IsValid(self.CurEnemy) then return end 

        local enemyPos = self.CurEnemy:GetPos()
        local selfPos = self:GetPos()
        
        local minDist = 100
        local maxDist = 200
        local randomAngle = math.random() * 2 * math.pi 
        local randDist = math.random(minDist, maxDist)
        
        local xPos = math.cos(randomAngle) * randDist  
        local yPos = math.sin(randomAngle) * randDist 


        local targetPos = gs_aimodule.GetNearestPointTo(self.StrafeCenter + Vector(xPos, yPos, selfPos.z))
        

        if not targetPos then 
            Task.AddTask(self, "TacticalAI_Strafe")
            return 
        end 

        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)
       
        self:MoveToPos(targetPos, { tolerance = 15, lookahead = 100, faceenemy = true })
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)

        if not IsValid(self.CurEnemy) then return end

        local distToEnemy = selfPos:DistToSqr(enemyPos)
        local switchDistance = (self.StrafePushSwitchDistance or 2000) ^ 2

        if distToEnemy > switchDistance or (self:Visible(self.CurEnemy) and distToEnemy > (switchDistance / 2)) then
            Task.AddTask(self, "TacticalAI_Push")
        end

        
        if math.random(1,10) == 1 then 
            if not self:IsAbleToSee( self.CurEnemy ) then 
                Task.AddTask(self, "TacticalAI_Push")
            end 
        end
    end 
}

-- ============================================================================
-- PUSHING COMBAT TASK
-- ============================================================================

-- TacticalAI_Push - Pushes directly towards the enemy
Tasks["TacticalAI_Push"] = {
    ["RunBehaviour"] = function(self)
        if not IsValid(self.CurEnemy) then return end

        local enemyPos = self.CurEnemy:GetPos()
        gs_aimodule.Movement.SetActivity(self, ACT_RUN, true)

        local targetPos = enemyPos

        -- Validate with navmesh
        local area = navmesh.GetNearestNavArea(targetPos)
        if IsValid(area) then
            targetPos = area:GetClosestPointOnArea(targetPos)
        end

        self:MoveToPos(targetPos, { faceenemy = true, lookahead = 500, maxage = 8 })
    end,
    ["Think"] = function(self)
        if not IsValid(self.CurEnemy) then return end

        local selfPos = self:GetPos()
        local distToEnemy = selfPos:DistToSqr(self.CurEnemy:GetPos())
        local switchDistance = (self.StrafePushSwitchDistance or 2000) ^ 2

        -- Check if enemy is close enough, switch to preferred combat task
        if distToEnemy < switchDistance then
            Task.RunPreferredTaskFor(self, "Combat")
        end
    end,
    ["OnTaskTermination"] = function(self)
        gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)
    end
}

-- ============================================================================
-- GOAL TASK
-- ============================================================================



Tasks["AI_GoToGoal"] = {
    ["RunBehaviour"] = function(self)
        if not self.PositionGoal then return end 
        local targetPos 
        local area = navmesh.GetNearestNavArea( self.PositionGoal )
        if IsValid(area) then 
            targetPos = area:GetCenter()
        end 

        if not IsValid(targetPos) then return end 

        self:MoveToPos(targetPos, { lookahead = 200, maxage = 8 })
        self.PositionGoal = nil 
        gs_aimodule.RunPreferredTaskFor(self, "Idle")
    end 
}



Tasks["AI_GoalTaskManager"] = {
    ["PreTaskInitialization"] = function(self, task)
        if not (self.IsIdle and self.PositionGoal) then return end 
            gs_aimodule.AddTask(self, "AI_GoToGoal") 
    end
}

