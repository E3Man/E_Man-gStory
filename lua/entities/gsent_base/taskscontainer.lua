gs_entmodule = gs_entmodule or {}
gs_entmodule.Task = gs_entmodule.Task or {}
gs_aimodule = gs_aimodule or {}

local Factions = gs_aimodule.Factions

local Task  = gs_entmodule.Task 
local Tasks = Task.Tasks 

local function SightUpdateFunc(self, inCooldown)
    if inCooldown then  return end 
    gs_entmodule.UpdateSightList(self)
end

Tasks["Sensory_SightSystem"] = {
    ["Think"] = function(self)
        gs_entmodule.PerformActionWithCooldown(self, "UpdateSight", 0.3,  SightUpdateFunc)
    end 
}

Tasks[ "EnemyManagement_Sight" ] = {
    ["OnEntitySight"] = function(self, ent)
        if not (ent:IsPlayer() or ent:IsNextBot()) then return end 
     

    

        if not Factions.IsHostileTo(self, ent) then return end 
       
            gs_entmodule.AddEnemy( self, ent )
   

            gs_entmodule.SortEnemiesByPriority(self)

            gs_entmodule.ChooseEnemyByPriority( self )

         
    
    end,
    [ "OnEntitySightLost" ] = function( self, ent ) 
        if not Factions.IsHostileTo(self, ent) or not self.RemoveEnemyOnLostSight then return end 
        local disp = self:GetPos() - ent:GetPos()
        local dist = disp:Dot(disp)
        if self.EnemyManagement_Sight_OLS_DURE^2 <= dist then return end 
        
        gs_entmodule.RemoveEnemy(self, ent)
      
        if self.UsesEnemyMemory then 
        gs_entmodule.UpdateEnemyMemory(self, ent, ent:GetPos())
        end 
    end,
    ["OnEnemyRemoved"] = function(self, ent)
        if #self.Enemies == 0 then return  end 

     
        gs_entmodule.SortEnemiesByPriority(self)
        gs_entmodule.ChooseEnemyByPriority( self )  
    end,
    ["OnTakeDamage"] = function(self, attacker, inflictor, dmginfo)
    

        if gs_aimodule.Factions.GetDisposition(self, attacker) == D_LI then return end  

        

        if self.EnemiesSet[ attacker:EntIndex() ] then  gs_entmodule.SetEnemy(self, attacker) print("Ill get yo") return end 


        gs_entmodule.PerformActionWithCooldown(self, "AddEnemyOnInjured", 0.5, function(self, inCooldown)
            if inCooldown then return end 
            
         
            gs_entmodule.AddEnemy(self, attacker)
            gs_entmodule.SortEnemiesByPriority(self)
            gs_entmodule.ChooseEnemyByPriority( self )  
        end)
    end,
    Priority = 100
}

-- ============================================================================
-- Admin Cannon Task
-- ============================================================================

local angleOffset = Angle(80, 0, 00)
local rotationStep = 2

local function sign(x) 
    if x > 0 then return 1 end 
    if x < 0 then return -1 end 
    return 0
end 


local function ThrowMelon( owner )
    local enemy = owner.CurEnemy
    if not enemy then  return end

    local melonmodel = "models/props_junk/CinderBlock01a.mdl"

    local toEnemy = (owner:GetAngles() - angleOffset):Forward() 

    local melon = ents.Create("prop_physics") 
    
    melon:SetModel( melonmodel )
    
    
    melon:SetPos( owner:WorldSpaceCenter() + toEnemy * 70 )

    melon:Spawn()

    local physObj = melon:GetPhysicsObject()

    owner:EmitSound( "weapons/mortar/mortar_fire1.wav", 150, 100 )
    physObj:ApplyForceCenter( toEnemy * 10e+10  )

    timer.Simple(5, function()
        if IsValid(melon) then 
            melon:Remove() 
        end 
    end )


    
end 

Tasks["AdminCannon_Attack"] = {
    ["Think"] = function(self)
        if not self.CurEnemy then return end 
            local targetPosition = self.CurEnemy:GetPos()
            local originPosition = self:WorldSpaceCenter()

            local directionVector = targetPosition - originPosition
            local directionAngles = directionVector:Angle()

            self:SetAngles( directionAngles + angleOffset ) 
            
            gs_entmodule.PerformActionWithCooldown(self, "Shoot", 3, function(ent, inCooldown)
                if inCooldown then return end
                self:SetModelScale( 1.5, 0.1 )
                timer.Simple( 0.1, function() 
                    if not IsValid(self) then return end 
                    ThrowMelon(self)
                    self:SetModelScale(0.6, 0.1)
                    timer.Simple( 0.1, function() 
                    if not IsValid(self) then return end
                        self:SetModelScale(1, 0.1)
                    end )
                end )
        end)
    end,
    ["OnEnemyRemoved"] = function(self, ent)
        if #self.Enemies ~= 0 then return end 
        Task.AddTask( self, "AdminCannon_OnWatch" )
    end, 
    StateFlag = "CombatStatus"
}

Tasks["AdminCannon_OnWatch"] = {
 ["Think"] = function(self) 

            local myAngles = self:GetAngles()

            gs_entmodule.PerformActionWithCooldown( self, "RandomRotate", math.random(2, 7), function(self, inCooldown)
                if inCooldown then return end 

                self.TargetAngle = AngleRand() + angleOffset
            end )

            local diffP = self.TargetAngle.p - myAngles.p
            local diffY = self.TargetAngle.y - myAngles.y 
            local diffR = self.TargetAngle.r - myAngles.r

            local stepP = math.abs(diffP) > rotationStep and rotationStep * sign(diffP) or 0
            local stepY = math.abs(diffY) > rotationStep and rotationStep * sign(diffY) or 0
            local stepR = math.abs(diffR) > rotationStep and rotationStep * sign(diffR) or 0

            self:SetAngles( myAngles + Angle( stepP, stepY, stepR ) )      
 end,
 ["OnSetEnemy"] = function(self, ent)
    Task.AddTask( self, "AdminCannon_Attack" )
 end,
 StateFlag = "CombatStatus"
}

