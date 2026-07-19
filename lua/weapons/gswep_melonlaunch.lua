SWEP.PrintName      = "[gStory] Melon Launch" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "Who knew melons could be such effective projectiles at high velocities."
SWEP.Base = "gswep_base"
SWEP.Spawnable      = false 

/* -----------------------------------------------------
--- ATTRIBUTES
*/ -----------------------------------------------------

SWEP.WorldModel = ""

SWEP.ReloadTime = 2

SWEP.Primary.Automatic = true 
SWEP.Secondary.Automatic = false

SWEP.Primary.CanShoot = false
SWEP.Secondary.CanShoot = false 

SWEP.MaxClip1Size = 45
SWEP.MaxClip2Size = 0 

SWEP.DefaultClip1 = 45
SWEP.DefaultClip2 = 0

SWEP.HoldType = "normal" 

SWEP.PrimaryCooldown = 0.3
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

local melonmodel =  "models/props_junk/watermelon01.mdl"


local function ThrowMelon( owner )
    local enemy = owner.CurEnemy 
    if not enemy then return end
    
    local enemyPos = enemy:WorldSpaceCenter()
    local ownerPos = owner:WorldSpaceCenter()
    
    local toEnemy = enemyPos - ownerPos 

    toEnemy:Normalize()

    

    local melon = ents.Create("prop_physics") 
    
    melon:SetModel( melonmodel )
    
    
    melon:SetPos( owner:WorldSpaceCenter() + owner:GetForward() * 95 )

    melon:Spawn()

    local physObj = melon:GetPhysicsObject()

    physObj:ApplyForceCenter( toEnemy * 10e+8 )

    timer.Simple(5, function()
        if IsValid(melon) then 
            melon:Remove() 
        end 
    end )

    
    
end 

function SWEP:GSWEP_PrimaryAttack()
    local owner = self:GetOwner()

    ThrowMelon(owner) 
    owner:EmitSound("weapons/physcannon/energy_bounce"..math.random(1,2)..".wav")
    
end



function SWEP:GSWEP_CanPrimaryAttack() 
    return true 
end 




