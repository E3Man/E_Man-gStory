SWEP.PrintName      = "[gStory] Hax Mind-Gun" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "HAAAAX!! HAAAAX!!"
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

SWEP.HoldType = "magic" 

SWEP.PrimaryCooldown = 2
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

local monitors =  {
    "models/props_lab/monitor02.mdl",
    "models/props_lab/monitor01a.mdl"
}

local function ThrowMonitor( owner )
    local enemy = owner.CurEnemy 
    if not enemy then return end
    
    local enemyPos = enemy:WorldSpaceCenter()
    local ownerPos = owner:WorldSpaceCenter()
    
    local toEnemy = enemyPos - ownerPos 

    toEnemy:Normalize()

    local model = monitors[ math.random(2) ]

    local monitor = ents.Create("prop_physics") 
    
    monitor:SetModel( model )
    
    
    monitor:SetPos( owner:WorldSpaceCenter() + owner:GetForward() * 80 )

    monitor:Spawn()

    local physObj = monitor:GetPhysicsObject()

    physObj:ApplyForceCenter( toEnemy * 1000000 )

    timer.Simple(3, function()
        if IsValid(monitor) then 
            monitor:Remove() 
        end 
    end )

    
    
end 

function SWEP:GSWEP_PrimaryAttack()
    local owner = self:GetOwner()

    ThrowMonitor(owner) 
    owner:EmitSound("vo/npc/male01/hacks01.wav")
    
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






