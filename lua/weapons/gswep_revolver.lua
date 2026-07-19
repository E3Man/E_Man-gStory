SWEP.PrintName      = "[gStory] Revolver" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "USP w/ steroids"
SWEP.Base = "gswep_base"
SWEP.Spawnable      = false 

/* -----------------------------------------------------
--- ATTRIBUTES
*/ -----------------------------------------------------

SWEP.WorldModel = "models/weapons/w_357.mdl"

SWEP.ReloadTime = 2

SWEP.Primary.Automatic = true 
SWEP.Secondary.Automatic = false

SWEP.Primary.CanShoot = true 
SWEP.Secondary.CanShoot = false 

SWEP.MaxClip1Size = 6 
SWEP.MaxClip2Size = 0 

SWEP.DefaultClip1 = 6
SWEP.DefaultClip2 = 0

SWEP.HoldType = "revolver" 

SWEP.PrimaryCooldown = 0.74
SWEP.SecondaryCooldown = 0.2 

SWEP.Primary.BulletConfig = {
    Damage      = 37,
    Force       = 10,
    NumShots    = 1,            -- How many pellets per shot (set >1 for shotguns)
    Delay       = 0.3,          -- Time between shots
    Spread      = Vector(0.01745, 0.01745, 0),
    TracerName  = "Tracer",     -- Options: "Tracer", "AR2Tracer", "ToolTracer", etc.
    TracerFreq  = 1,            -- Draw a tracer every X bullets
    ShootSound  = "Weapon_357.Single"
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
        owner:AddGesture(ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER, true)
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

local revolverReloadSounds = {
    "weapons/357/357_reload4.wav",
    "weapons/357/357_reload3.wav",
    "weapons/357/357_spin1.wav"
}

function SWEP:GSWEP_ReloadPrimary() 
  
    self:GS_ReloadPrimary( ACT_HL2MP_GESTURE_RELOAD_REVOLVER )
    self:PlaySoundSequence( revolverReloadSounds )
end 

function SWEP:GSWEP_ReloadSecondary() end 






