SWEP.PrintName      = "[gStory] SMG1" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "USP with a higer shoot rate"
SWEP.Base = "gswep_base"
SWEP.Spawnable      = false 

/* -----------------------------------------------------
--- ATTRIBUTES
*/ -----------------------------------------------------

SWEP.WorldModel = "models/weapons/w_smg1.mdl"

SWEP.ReloadTime = 2

SWEP.Primary.Automatic = true 
SWEP.Secondary.Automatic = false

SWEP.Primary.CanShoot = true 
SWEP.Secondary.CanShoot = false 

SWEP.MaxClip1Size = 45
SWEP.MaxClip2Size = 0 

SWEP.DefaultClip1 = 45
SWEP.DefaultClip2 = 0

SWEP.HoldType = "smg" 

SWEP.PrimaryCooldown = 0.2
SWEP.SecondaryCooldown = 0.2 

SWEP.Primary.BulletConfig = {
    Damage      = 10,
    Force       = 5,
    NumShots    = 1,            -- How many pellets per shot (set >1 for shotguns)
    Delay       = 0.1,          -- Time between shots
    Spread      = Vector(0.02, 0.02, 0),
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
   
    print(self.Clip1Contents)
    print(self:GS_HasAmmoInClip1())

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
    print("COOL SHIT")
    self:GS_ReloadPrimary( ACT_HL2MP_GESTURE_RELOAD_SMG1 )
    self:GetOwner():EmitSound("weapons/smg1/smg1_reload.wav")
end 

function SWEP:GSWEP_ReloadSecondary() end 






