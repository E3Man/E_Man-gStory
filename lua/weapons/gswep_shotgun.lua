SWEP.PrintName      = "[gStory] Shotgun" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "We're pumping 'em minges with this one"
SWEP.Base = "gswep_base"
SWEP.Spawnable      = false 

/* -----------------------------------------------------
--- ATTRIBUTES
*/ -----------------------------------------------------

SWEP.WorldModel = "models/weapons/w_shotgun.mdl"

SWEP.ReloadTime = 3

SWEP.Primary.Automatic = true
SWEP.Secondary.Automatic = false

SWEP.Primary.CanShoot = true 
SWEP.Secondary.CanShoot = false 

SWEP.MaxClip1Size = 6
SWEP.MaxClip2Size = 0 

SWEP.DefaultClip1 = 6
SWEP.DefaultClip2 = 0

SWEP.HoldType = "shotgun" 

SWEP.PrimaryCooldown = 1.0
SWEP.SecondaryCooldown = 0.2 

SWEP.Primary.BulletConfig = {
    Damage      = 6,
    Force       = 5,
    NumShots    = 8,            -- How many pellets per shot (set >1 for shotguns)
    Delay       = 0.1,          -- Time between shots
    Spread      = Vector(0.08716, 0.08716, 0),
    TracerName  = "Tracer",     -- Options: "Tracer", "AR2Tracer", "ToolTracer", etc.
    TracerFreq  = 1,            -- Draw a tracer every X bullets
    ShootSound  = "Weapon_Shotgun.Single"
}

SWEP.Secondary.BulletConfig = {
    Damage      = 10,
    Force       = 5,
    NumShots    = 1,            -- How many pellets per shot (set >1 for shotguns)
    Delay       = 0.1,          -- Time between shots
    Spread      = Vector(0.02, 0.02, 0),
    TracerName  = "Tracer",     -- Options: "Tracer", "AR2Tracer", "ToolTracer", etc.
    TracerFreq  = 1,            -- Draw a tracer every X bullets
    ShootSound  = "Weapon_Shotgun.Single"
}

/* -----------------------------------------------------
--- CUSTOM HOOKS
*/ -----------------------------------------------------

function SWEP:GSWEP_PrimaryAttack() 
    local owner = self:GetOwner()
    owner:AddGesture(ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN, true)
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
    
    self:GS_ReloadPrimary( ACT_HL2MP_GESTURE_RELOAD_SHOTGUN )
    self:GetOwner():EmitSound("weapons/shotgun/shotgun_reload1.wav")
end 

function SWEP:GSWEP_ReloadSecondary() end 






