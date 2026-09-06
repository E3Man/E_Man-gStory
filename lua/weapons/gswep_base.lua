gs_aimodule = gs_aimodule or {}

SWEP.PrintName      = "[gStory] Base Weapon" 
SWEP.Author         = "E_Man" 
SWEP.Instructions   = "Base Weapon... heh."
SWEP.Spawnable      = false 

/* -----------------------------------------------------
--- ATTRIBUTES
*/ -----------------------------------------------------

SWEP.GS_WEP = true

SWEP.WorldModel = "models/weapons/w_smg1.mdl"
SWEP.ReloadTime = 3

SWEP.Primary.Automatic = true 
SWEP.Secondary.Automatic = false
SWEP.Primary.CanShoot = true 
SWEP.Secondary.CanShoot = false 

SWEP.MaxClip1Size = -1 
SWEP.MaxClip2Size = 0 
SWEP.DefaultClip1 = -1 
SWEP.DefaultClip2 = 0

SWEP.HoldType = "smg" 

SWEP.PrimaryCooldown = 0.2
SWEP.SecondaryCooldown = 0.2  

SWEP.PrimaryShoots = true 
SWEP.PrimaryWastesAmmo = true 

SWEP.Primary.BulletConfig = {
    Damage      = 10,
    Force       = 5,
    NumShots    = 1,
    Delay       = 0.1,
    Spread      = Vector(0.02, 0.02, 0),
    TracerName  = "Tracer",
    TracerFreq  = 1,
    ShootSound  = "Weapon_SMG1.Single"
}

SWEP.Secondary.BulletConfig = {
    Damage      = 10,
    Force       = 5,
    NumShots    = 1,
    Delay       = 0.1,
    Spread      = Vector(0.02, 0.02, 0),
    TracerName  = "Tracer",
    TracerFreq  = 1,
    ShootSound  = "Weapon_SMG1.Single"
}

/* -----------------------------------------------------
--- CUSTOM HOOKS (For Inheritance)
*/ -----------------------------------------------------

function SWEP:GSWEP_PrimaryAttack() end 
function SWEP:GSWEP_SecondaryAttack() end 
function SWEP:GSWEP_FireBullet(bulletConfig) end 
function SWEP:GSWEP_Initialize() end 
function SWEP:GSWEP_CanPrimaryAttack() end 
function SWEP:GSWEP_CanSecondaryAttack() end 
function SWEP:GSWEP_Think() end 
function SWEP:GSWEP_ReloadPrimary() end 
function SWEP:GSWEP_ReloadSecondary() end 

/* -----------------------------------------------------
--- CUSTOM API FUNCTIONS (Avoiding Engine Names)
*/ -----------------------------------------------------

function SWEP:GS_GetClip1()
    return self.Clip1Contents or 0
end 

function SWEP:GS_GetClip2()
    return self.Clip2Contents or 0
end 

function SWEP:GS_HasAmmoInClip1()
    return self:GS_GetClip1() ~= 0 
end 

function SWEP:GS_HasAmmoInClip2()
    return self:GS_GetClip2() ~= 0 
end 

function SWEP:GS_SetClip1(num)
    self.Clip1Contents = num or 0
end 

function SWEP:GS_SetClip2(num) 
    self.Clip2Contents = num or 0
end 

function SWEP:GS_TakeFromClip1(num)
    local totalLeft = self:GS_GetClip1() - num 
    -- Clamp uses MaxClip1Size; if -1 (infinite), we handle that logic in firing
    local totalClamped = math.max(0, totalLeft)
    self:GS_SetClip1( totalClamped )
end 

function SWEP:GS_TakeFromClip2(num)
    local totalLeft = self:GS_GetClip2() - num 
    local totalClamped = math.max(0, totalLeft)
    self:GS_SetClip2( totalClamped )
end 

function SWEP:GS_IsPrimaryReady()
    return CurTime() >= self:GetNextPrimaryFire() and not self.IsReloading
end 

function SWEP:GS_IsSecondaryReady()
    return CurTime() >= self:GetNextSecondaryFire() and not self.IsReloading
end 

function SWEP:GS_ReloadPrimary(act)
    local owner = self:GetOwner()
    if not IsValid(owner) or self.IsReloading then return end 

    if act then 
        local id = owner:AddGesture( act, true ) 
        self:SetLayerPlaybackRate( id, 1 / self.ReloadTime )
    end
    self.IsReloading = true 
    
    timer.Simple(self.ReloadTime, function()
        if not IsValid(self) then return end
        self.IsReloading = false 
        self:GS_SetClip1( self.MaxClip1Size )
    end )
end 

/* -----------------------------------------------------
--- ENGINE HOOKS
*/ -----------------------------------------------------

if CLIENT then return end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)

    -- Initialize custom ammo variables
    local initClip1 = (self.DefaultClip1 != -1) and self.DefaultClip1 or self.MaxClip1Size
    local initClip2 = (self.DefaultClip2 != -1) and self.DefaultClip2 or self.MaxClip2Size
    
    self:GS_SetClip1(initClip1)
    self:GS_SetClip2(initClip2)

    self:GSWEP_Initialize()
end 

function SWEP:PrimaryAttack()
    if not self:GS_IsPrimaryReady()  then return end 
    if not self.Primary.CanShoot then return end 

    if not ( self:GSWEP_CanPrimaryAttack()) then 
        return 
    end 



    if not self:GS_HasAmmoInClip1() then 
        self:GSWEP_ReloadPrimary()
        return 
    end 

    self:GSWEP_PrimaryAttack()

    if self:GS_GetClip1() > 0 and self.PrimaryWastesAmmo then 
        self:GS_TakeFromClip1(1)
    end 

    local delay = self.PrimaryCooldown or 0.1
    self:SetNextPrimaryFire( CurTime() + delay )

    if not (self.PrimaryShoots) then return end  






    local config = self.Primary.BulletConfig or {}
    local bullet = {
        Attacker = self.Owner,
        Inflictor = self,
        Num         = config.NumShots   or 1,
        Src         = self.Owner:GetShootPos(),
        Dir         = self.Owner:GetAimVector(),
        Spread      = config.Spread     or Vector(0, 0, 0),
        Tracer      = config.TracerFreq or 1,
        TracerName  = config.TracerName or "Tracer",
        Force       = config.Force      or 1,
        Damage      = config.Damage     or 10,
        AmmoType    = self.Primary.Ammo
    }

    self:GSWEP_FireBullet(bullet)
    self:FireBullets(bullet)
    self:EmitSound( config.ShootSound or "Weapon_Pistol.Single" )
    

    

end

function SWEP:SecondaryAttack()
    -- Check if the internal cooldown has passed
    if not self:GS_IsSecondaryReady() then return end 

    -- 1. Check custom constraints via inherited hook
    -- If it returns false and we have ammo, trigger the custom reload hook
    if not (self:GSWEP_CanSecondaryAttack()) then 
        return 
    end 

    if not self:GS_HasAmmoInClip2() then 
        self:GSWEP_ReloadSecondary()
        return
    end 

    -- 2. Call the custom attack hook (for logic like animations or alerts)
    self:GSWEP_SecondaryAttack()

    

    local delay = self.SecondaryCooldown or 0.1
    self:SetNextSecondaryFire(CurTime() + delay)
    -- 4. Safety check to see if secondary fire is enabled at all
    if not self.Secondary.CanShoot then return end 

    local config = self.Secondary.BulletConfig or {}
    local bullet = {
        Attacker = self.Owner,
        Inflictor = self,
        Num         = config.NumShots   or 1,
        Src         = self.Owner:GetShootPos(),
        Dir         = self.Owner:GetAimVector(),
        Spread      = config.Spread     or Vector(0, 0, 0),
        Tracer      = config.TracerFreq or 1,
        TracerName  = config.TracerName or "Tracer",
        Force       = config.Force      or 1,
        Damage      = config.Damage     or 10,
        AmmoType    = self.Secondary.Ammo
    }

    -- 5. Final custom hook before firing (allows modifying the 'bullet' table by reference)
    self:GSWEP_FireBullet(bullet)

    -- 6. Execute the shot and sound
    self:FireBullets(bullet)
    self:EmitSound(config.ShootSound or "Weapon_Pistol.Single")
    
    -- 7. Handle custom ammo consumption
    if self:GS_GetClip2() > 0 then 
        self:GS_TakeFromClip2(1)
    end 
    
    -- 8. Set timing for the next shot

end

function SWEP:PlaySoundSequence(sounds, index, pause)
    index = index or 1
    if index > #sounds then return end
    
    local sound = sounds[index]

    if not IsValid(self:GetOwner()) then return end 

    self:GetOwner():EmitSound(sound)
    
    timer.Simple(SoundDuration(sound) + (pause or 0.2), function()
        if not IsValid(self) then return end 
        self:PlaySoundSequence(sounds, index + 1, pause) 
    end)
end