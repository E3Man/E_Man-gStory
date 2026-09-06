SWEP.PrintName      = "[gStory] AR2" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "Whenever they ask you whether you want a combine toy, never decline the offer."
SWEP.Base = "gswep_base"
SWEP.Spawnable      = false 

/* -----------------------------------------------------
--- ATTRIBUTES
*/ -----------------------------------------------------

SWEP.WorldModel = "models/weapons/w_mach_m249para.mdl"

SWEP.ReloadTime = 7

SWEP.Primary.Automatic = true 
SWEP.Secondary.Automatic = false

SWEP.Primary.CanShoot = true 
SWEP.Secondary.CanShoot = false 

SWEP.MaxClip1Size = 200
SWEP.MaxClip2Size = 0 

SWEP.DefaultClip1 = 200
SWEP.DefaultClip2 = 0

SWEP.HoldType = "shotgun" 

SWEP.PrimaryCooldown = 0.1
SWEP.SecondaryCooldown = 0.2 

SWEP.Primary.BulletConfig = {
    Damage      = 9,
    Force       = 7,
    NumShots    = 1,            -- How many pellets per shot (set >1 for shotguns)
    Delay       = 0.07,          -- Time between shots
    Spread      = Vector(0.15, 0.15, 0.2),
    TracerName  = "Tracer",     -- Options: "Tracer", "AR2Tracer", "ToolTracer", etc.
    TracerFreq  = 1,            -- Draw a tracer every X bullets
    ShootSound  = "weapons/m249/m249-1.wav"
}

SWEP.Secondary.BulletConfig = {
    Damage      = 10,
    Force       = 5,
    NumShots    = 1,            -- How many pellets per shot (set >1 for shotguns)
    Delay       = 0.1,          -- Time between shots
    Spread      = Vector(0.02, 0.02, 0),
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

local playSequence = {
    "weapons/m249/m249_boxout.wav",
    "weapons/m249/m249_boxin.wav",
    "weapons/m249/m249_chain.wav"
}

function SWEP:GSWEP_ReloadPrimary() 
    self:GS_ReloadPrimary( ACT_HL2MP_GESTURE_RELOAD_AR2 )
    self:PlaySoundSequence(playSequence)
end 

function SWEP:GSWEP_ReloadSecondary() end 




