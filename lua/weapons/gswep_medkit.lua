SWEP.PrintName      = "[gStory] Medkit" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "MEDICCC!!"
SWEP.Base = "gswep_base"
SWEP.Spawnable      = false 

/* -----------------------------------------------------
--- ATTRIBUTES
*/ -----------------------------------------------------

SWEP.WorldModel = "models/weapons/w_medkit.mdl"

SWEP.ReloadTime = 2

SWEP.Primary.Automatic = true 
SWEP.Secondary.Automatic = false

SWEP.Primary.CanShoot = false
SWEP.Secondary.CanShoot = false 

SWEP.MaxClip1Size = 45
SWEP.MaxClip2Size = 0 

SWEP.DefaultClip1 = 45
SWEP.DefaultClip2 = 0

SWEP.HoldType = "slam" 

SWEP.PrimaryCooldown = 0.15
SWEP.SecondaryCooldown = 0.2 

SWEP.Primary.BulletConfig = {
    Damage      = 4,
    Force       = 5,
    NumShots    = 1,            -- How many pellets per shot (set >1 for shotguns)
    Delay       = 0.1,          -- Time between shots
    Spread      = Vector(0.04362, 0.04362, 0),
    TracerName  = "Tracer",     -- Options: "Tracer", "AR2Tracer", "ToolTracer", etc.
    TracerFreq  = 1,            -- Draw a tracer every X bullets
    ShootSound  = "Weapon_SMG1.Single"
}

SWEP.Secondary.BulletConfig = {
    Damage      = 10,
    Force       = 5,
    NumShots    = 1,            -- How many pellets per shot (set >1 for shotguns)
    Delay       = 0.1,          -- Time between shots
    Spread      = Vector(0.02, 0.02, 0),
    TracerName  = "Tracer",     -- Options: "Tracer", "AR2Tracer", "ToolTracer", etc.
    TracerFreq  = 1,            -- Draw a tracer every X bullets
    ShootSound  = "Weapon_SMG1.Single"
}

/* -----------------------------------------------------
--- CUSTOM HOOKS
*/ -----------------------------------------------------

function SWEP:GSWEP_PrimaryAttack()
    local owner = self:GetOwner()

    -- 1. Safety check to ensure owner exists
    if not IsValid(owner) then return end



 
    owner:AddGesture(ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM, true)
   
    local aimVec = owner:GetForward()
    local startPos = owner:GetPos() + Vector(0,0,50)
    local endPos = startPos + (aimVec * 160) 

    debugoverlay.Line(startPos, endPos, 0.5, Color(255,255,255), true)

    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        filter = owner 
    })

    

    if SERVER then
        local ent = tr.Entity

       
        if tr.Hit and IsValid(ent) and (ent:IsPlayer() or ent.GS_AI) then
            
            local healAmount = 25
            local currentHealth = ent:Health()
            local maxHealth = ent:GetMaxHealth()

            if currentHealth < maxHealth then
    
                ent:SetHealth(math.min(maxHealth, currentHealth + healAmount))

    
                ent:EmitSound("HealthVial.Touch") 
                
     
            end
        else
            self:EmitSound("Weapon_Crowbar.Single")
        end
    end
end

function SWEP:GSWEP_SecondaryAttack() end 

function SWEP:GSWEP_FireBullet(bulletConfig) end 

function SWEP:GSWEP_Initialize() 

end 

function SWEP:GSWEP_CanPrimaryAttack() 
    return true 
end 

function SWEP:GSWEP_CanSecondaryAttack() 
    return true 
end 

function SWEP:GSWEP_Think() end 

function SWEP:GSWEP_ReloadPrimary() 

end 

function SWEP:GSWEP_ReloadSecondary() end 






