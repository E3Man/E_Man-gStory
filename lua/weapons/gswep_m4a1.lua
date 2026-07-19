SWEP.PrintName      = "[gStory] AR2" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "Whenever they ask you whether you want a combine toy, never decline the offer."
SWEP.Base = "gswep_base"
SWEP.Spawnable      = false 

/* -----------------------------------------------------
--- ATTRIBUTES
*/ -----------------------------------------------------

SWEP.WorldModel = "models/weapons/w_rif_m4a1.mdl"

SWEP.ReloadTime = 2.5

SWEP.Primary.Automatic = true 
SWEP.Secondary.Automatic = false

SWEP.Primary.CanShoot = true 
SWEP.Secondary.CanShoot = false 

SWEP.MaxClip1Size = 30
SWEP.MaxClip2Size = 0 

SWEP.DefaultClip1 = 30
SWEP.DefaultClip2 = 0

SWEP.HoldType = "smg" 

SWEP.PrimaryCooldown = 0.05
SWEP.SecondaryCooldown = 0.2 

SWEP.Primary.BulletConfig = {
    Damage      = 8,
    Force       = 17,
    NumShots    = 1,            -- How many pellets per shot (set >1 for shotguns)        
    Spread      = Vector(0.0698,0.0698, 0),
    TracerName  = "Tracer",     -- Options: "Tracer", "AR2Tracer", "ToolTracer", etc.
    TracerFreq  = 1,            -- Draw a tracer every X bullets
    ShootSound  = "weapons/m4a1/m4a1_unsil-1.wav"
}

SWEP.Secondary.BulletConfig = {
    Damage      = 10,
    Force       = 5,
    NumShots    = 1,            -- How many pellets per shot (set >1 for shotguns)       
    Spread      = Vector(0,0,0),
    TracerName  = "Tracer",     -- Options: "Tracer", "AR2Tracer", "ToolTracer", etc.
    TracerFreq  = 1,            -- Draw a tracer every X bullets
    ShootSound  = "Weapon_AR2.Single"
}

/* -----------------------------------------------------
--- CUSTOM HOOKS
*/ -----------------------------------------------------

function SWEP:GSWEP_PrimaryAttack() 
    local owner = self:GetOwner()
    owner:AddGesture(ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1, true)
    
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

local reloadSound = {
    "weapons/m4a1/m4a1_clipout.wav",
    "weapons/m4a1/m4a1_clipin.wav",
    "weapons/m4a1/m4a1_boltpull.wav"
}

function SWEP:GSWEP_ReloadPrimary() 
    self:GS_ReloadPrimary( ACT_HL2MP_GESTURE_RELOAD_SMG1 )
    self:PlaySoundSequence(reloadSound)
end 

function SWEP:GSWEP_ReloadSecondary() end 






