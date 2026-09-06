gs_aimodule = gs_aimodule or {}
gs_aimodule = gs_aimodule or gs_aimodule
gs_aimodule.Task = gs_aimodule.Task or gs_aimodule.Task or {}
gs_aimodule.Task = gs_aimodule.Task or gs_aimodule.Task

local Factions = gs_aimodule.Factions
local Task = gs_aimodule.Task
local Tasks = Task.Tasks

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
            
            gs_aimodule.PerformActionWithCooldown(self, "Shoot", 3, function(ent, inCooldown)
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

            gs_aimodule.PerformActionWithCooldown( self, "RandomRotate", math.random(2, 7), function(self, inCooldown)
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

-- ============================================================================
-- G-Bomb
-- ============================================================================

local gBombInfoDefault = {}

Tasks["GBomb_ExplosionSequence"] = {
    ["OnTaskInitialization"] = function(self, gbombInfo, startFrequency, minFrequency, detonationTime)
        self.DetonationTime = detonationTime or 7
        self.StartFrequency = startFrequency or 1.5
        self.MinFrequency   = minFrequency or 0.1  
        self.StartTime      = CurTime()
        self.DetonationFrequency = self.StartFrequency
        self.gBombInfo = gbombInfo or gBombInfoDefault
    end, 

    ["Think"] = function(self)
        local elapsedTime = CurTime() - self.StartTime

       
        if elapsedTime >= self.DetonationTime then
        local selfPos = self:GetPos()
        local effectData = EffectData()

        effectData:SetOrigin( selfPos )
        effectData:SetScale(1) 

        util.Effect("Explosion", effectData) 
            local gbombInfo = self.gBombInfo
            util.BlastDamage( self, gbombInfo.attacker or self, selfPos, gbombInfo.radius or 220, gbombInfo.damage or 120 )
            self:Remove()
            return
        end

       
        gs_aimodule.PerformActionWithCooldown(self, "Detonate", self.DetonationFrequency, function(self, inCooldown) 
            if inCooldown then return end

            self:EmitSound("weapons/grenade/tick1.wav")

            local minHalf = self.MinFrequency / 2 
            self:SetModelScale( self.ModelScale * 1.5  , minHalf)
            self:SetColor( Color(255, 0,0,255) )
            timer.Simple( minHalf, function() 
                if not IsValid(self) then return end
                self:SetColor( Color(255, 255,255,255) )
                self:SetModelScale( self.ModelScale, minHalf)  
            end )


          
            local remainingRatio = 1 - (elapsedTime / self.DetonationTime)

           
            self.DetonationFrequency = math.max(self.MinFrequency, self.StartFrequency * (remainingRatio ^ 2))
        end)
    end 
}

Tasks["ACTower_OnCannonDeath"] = {
    ["OnTaskInitialization"] = function(self)
        print("yooo")
        self.AdminCannon = nil

        if (self.CannonsHad or 0) == 5 then 
            Task.AddTask(self, "GBomb_ExplosionSequence", {radius = 500})
            return
        end 

        timer.Simple(1, function()
            if not IsValid(self) then return end 

            print(self:GetClass())
            local cannon = ents.Create("gsent_admincannon")
            cannon:SetPos( self:GetPos() + Vector(0, 0, 90) )
            cannon:Spawn()

            cannon.RookTower = self 
            self.AdminCannon = cannon

            Task.AddTask(cannon, "AdminCannon_AdviseDeathToTower")
            self.CannonsHad = (self.CannonsHad or 0) + 1
         end)  
        Task.RemoveTask(self, "ACTower_OnCannonDeath")
    end
}

Tasks["ACTower_OnTowerRemoval"] = {
    ["OnRemove"] = function(self)
        print("gg1")
        if not IsValid(self.AdminCannon) then return end
        print("gg2")
        self.AdminCannon:OnDeath( DamageInfo() )
    end 
}

Tasks["AdminCannon_AdviseDeathToTower"] = {
    ["OnRemove"] = function(self)
        print("gg")
        if not IsValid(self.RookTower) then return end
        Task.AddTask( self.RookTower, "ACTower_OnCannonDeath" )
        self.RookTower = nil
    end 
}
