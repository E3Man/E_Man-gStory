SWEP.PrintName      = "[gStory] GBomber" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "Bombs! We need more bombs!"
SWEP.Base = "gswep_base"
SWEP.Spawnable      = false 

/* -----------------------------------------------------
--- ATTRIBUTES
*/ -----------------------------------------------------

SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"

SWEP.ReloadTime = 6

SWEP.Primary.Automatic = true 
SWEP.Secondary.Automatic = false

SWEP.Primary.CanShoot = true 
SWEP.Secondary.CanShoot = false 

SWEP.MaxClip1Size = 6
SWEP.MaxClip2Size = 0 

SWEP.DefaultClip1 = 6
SWEP.DefaultClip2 = 0

SWEP.HoldType = "rpg" 

SWEP.PrimaryShoots = false
SWEP.PrimaryWastesAmmo = true 


SWEP.PrimaryCooldown = 0.5
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



local function ThrowBomb( owner )
    local enemy = owner.CurEnemy 
    if not enemy then return end
    
    local enemyPos = enemy:WorldSpaceCenter()
    local ownerPos = owner:WorldSpaceCenter()
    
    local toEnemy = enemyPos - ownerPos 

    

    local melon = ents.Create("gsent_gbomb") 
    

    
    
    melon:SetPos( owner:GetShootPos() + owner:GetForward() * 95 )

    melon:Spawn()

    local physObj = melon:GetPhysicsObject()

    physObj:SetMass( 20 )

    physObj:ApplyForceCenter( owner:GetAimVector() * 10e+3 ) 



    
    
end 

function SWEP:GSWEP_PrimaryAttack()
    local owner = self:GetOwner()

    ThrowBomb(owner) 
    owner:EmitSound("weapons/grenade_launcher1.wav")
    
end



function SWEP:GSWEP_CanPrimaryAttack() 
    return true 
end 

function SWEP:GSWEP_ReloadPrimary() 
    self:GS_ReloadPrimary()
  
end 
