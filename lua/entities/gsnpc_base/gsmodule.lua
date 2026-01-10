-- =====================================================
-- gStory AI Module (consolidated)
-- All gs_aimodule functions and branches centralized here.
-- Sections: Utilities, Task system, Movement (Anim Packets + funcs), AI init, Weapon & Inventory
-- =====================================================

gs_aimodule = {}
gs_aimodule.nextbots = {}

-- -------------------------
-- Utilities
-- -------------------------
function gs_aimodule.Warn(str)
    MsgC(Color(220,68,27), "[ gStory AI ] [? WARNING ?] " .. tostring(str) .. "\n")
end

function gs_aimodule.ThrowError(err)
    -- Use MsgC (typo fixed) so errors are visible in console
    MsgC(Color(220,27,27), "[ gStory AI ] [! ERROR !] " .. tostring(err) .. "\n")
end

-- -------------------------
-- Faction System (split to `factions.lua`)
-- -------------------------
include("entities/gsnpc_base/factions.lua")

-- -------------------------
-- Task system (split to `tasks.lua`)
-- -------------------------
include("entities/gsnpc_base/tasks.lua")




-- -------------------------
-- Movement / Animation packets (split to `movement.lua`)
-- -------------------------
include("entities/gsnpc_base/movement.lua")

-- -------------------------
-- Movement / Animation packets (split to `movement.lua`)
-- -------------------------
include("entities/gsnpc_base/enemy_sorters.lua")

include("entities/gsnpc_base/attributes.lua")

-- Include all NPC init.lua files 
include("entities/gsnpc_skelly/init.lua")
include("entities/gsnpc_ebot/init.lua")

function gs_aimodule.RemoveAllRemoveCallbacks(self)
    if not IsValid(self) then return end
    if not self.RemoveCallbacks then return end

    for id, cb in pairs(self.RemoveCallbacks) do
        local ent = cb.ent
        if IsValid(ent) then
            ent:RemoveCallOnRemove(cb.key)
        end
        self.RemoveCallbacks[id] = nil
    end

    self.RemoveCallbacks = nil
end 

-- -------------------------
-- AI Initialization
-- -------------------------
function gs_aimodule.InitializeAI(self)
    if not self.Inventory then self.Inventory = {} end

    local mdl = self.Model

    self:SetModel(mdl)
    self:SetFOV(self.FOV)
    self:SetMaxVisionRange(self.SightDistance)

    self:SetHealth(self.InitialHealth or self.InitialMaxHealth)
    self:SetMaxHealth(self.InitialMaxHealth or self.InitialHealth)

    gs_aimodule.Movement.ApplyHoldTypeAnimPacket(self)


    if self.Weapon then
        gs_aimodule.GiveWeapon(self, self.Weapon)    
    end

    -- Register a cleanup callback so when this NPC is removed we also remove any callbacks we created on other entities
    gs_aimodule.AddRemoveCallback(self, self, "self_cleanup", gs_aimodule.RemoveAllRemoveCallbacks, self) 

    table.insert( gs_aimodule.nextbots, self )

end

-- -------------------------
-- Weapon & Inventory management
-- -------------------------
function gs_aimodule.HandWeapon(self, weapon)
    if not IsValid(weapon) then return end
    weapon:SetMoveType(MOVETYPE_NONE)
    weapon:SetParent(self)
    weapon:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL))
end

function gs_aimodule.GiveWeapon(self, weaponClass)
    local wep = ents.Create(weaponClass)
    if not IsValid(wep) then return end

    wep:Spawn()
    wep:Activate()

    gs_aimodule.RegisterWeaponInInv(self, wep)
    gs_aimodule.EquipWeapon(self, wep)


    return wep
end

function gs_aimodule.EquipWeapon(self, wep)
    if not (IsValid(self) and wep) then return end 

    if self.Weapon and not isstring(self.Weapon) then
        gs_aimodule.UnequipWeapon(self)
    end

    if isstring(wep) then 
        for i, weapon in ipairs( self.Inventory ) do 
            if not IsValid(weapon) then continue end 
            local class = weapon:GetClass()

            if wep == class then 
                gs_aimodule.EquipWeapon(self, weapon)
            end 
        end 
    end 

    pcall(function() wep:OwnerChanged() end)
    pcall(function() wep:Equip(self) end)

    gs_aimodule.ShowWeapon(self, wep)
    gs_aimodule.HandWeapon(self, wep)

    self.Weapon = wep

    gs_aimodule.Movement.ApplyHoldTypeAnimPacket(self)
end

function gs_aimodule.HideWeapon(wep)
    if not IsValid(wep) then return end
    wep:AddEffects(EF_NODRAW)
end

function gs_aimodule.ShowWeapon(wep)
    if not IsValid(wep) then return end
    wep:RemoveEffects(EF_NODRAW)
end

function gs_aimodule.RegisterWeaponInInv(self, wep)
    if not (IsValid(self) and IsValid(wep)) then return end

    wep:SetOwner(self)

    local inv = self.Inventory or {}

    -- Prevent duplicates
    if table.KeyFromValue(inv, wep) then return end

    table.insert(inv, wep)
    self.Inventory = inv

    wep:CallOnRemove("gs_wep_removeCall", function()
        local inventoryPosition = table.KeyFromValue(inv, wep)
        if inventoryPosition then
            table.remove(inv, inventoryPosition)
        end
    end)
end

function gs_aimodule.RemoveWeaponFromInventory(self, wep)
    local inventoryPosition = gs_aimodule.GetWeaponInvPos(self, wep)

    if not inventoryPosition then return end

    wep:RemoveCallOnRemove("gs_wep_removeCall")

    table.remove(self.Inventory, inventoryPosition)
end

function gs_aimodule.GetWeaponInvPos(self, wep)
    local inv = self.Inventory or {}
    local inventoryPosition = table.KeyFromValue(inv, wep)
    return inventoryPosition
end

function gs_aimodule.DropWeapon(self, wep, forceApplied)
    local inventoryPosition = gs_aimodule.GetWeaponInvPos(self, wep)
    if not inventoryPosition then return end

    gs_aimodule.RemoveWeaponFromInventory(self, wep)

    wep:RemoveEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL))
    wep:SetParent()

    wep:SetMoveType(MOVETYPE_VPHYSICS)
    local pos = self:GetBonePosition(self:LookupBone("ValveBiped.Bip01_R_Hand"))
    if pos then wep:SetPos(pos) end

    local physObj = wep:GetPhysicsObject()
    if IsValid(physObj) then physObj:ApplyForceCenter(forceApplied) end
end

function gs_aimodule.RemoveAllInventoryWeapons(self)
    for invPos = #self.Inventory, 1, -1 do
        local wep = self.Inventory[invPos]
        table.remove(self.Inventory, invPos)

        if IsValid(wep) then
            wep:Remove()
        end
    end
end

function gs_aimodule.UnequipWeapon(self)
    if IsValid(self.Weapon) then
        gs_aimodule.HideWeapon(self.Weapon)
    end
    self.Weapon = nil
    gs_aimodule.Movement.ApplyHoldTypeAnimPacket(self)
end

function gs_aimodule.AcquireWeapon( self, wep ) -- Adds weapon to the bot's inventory, but doesn't automatically equip it
    gs_aimodule.HideWeapon( wep )
    gs_aimodule.HandWeapon( self, wep )

    gs_aimodule.RegisterWeaponInInv( self, wep )
end 

function gs_aimodule.SetupInventory( self )
    if not IsValid( self ) then return end 

    local inventory = self.Inventory 
    for i, weaponClass in ipairs( inventory ) do 
        local wep = ents.Create( weaponClass ) 
        if not (IsValid(wep) and IsValid( self )) then continue end 
        
        gs_aimodule.AcquireWeapon( self, wep )
        
    end
end 

-- -------------------------
-- Enemy Memory Management 
-- -------------------------



local function EnemyRemovalMemoryHook( self, enemy )
    if not IsValid( enemy ) or not IsValid( self ) then return end 

    local enemyIndex = enemy:EntIndex()

    gs_aimodule.AddRemoveCallback(self, enemy, "ememory_" .. enemyIndex, gs_aimodule.UpdateEnemyMemory, self, enemy) 
end 

function gs_aimodule.UpdateEnemyMemory( self, enemy, pos )

    local enemyIndex = enemy:EntIndex() 

    if not ( IsValid(self) and IsValid(enemy) and pos) then 
        if not pos and IsValid(enemy) then 
            self.EnemyMemory[ enemyIndex ] = nil 
            self:OnForgetEnemy( enemy )
            return 
        end 
        gs_aimodule.Warn( "Cannot update enemy memory—self, enemy or pos are invalid!" )
    end 

    self.EnemyMemory = self.EnemyMemory or {}

    local enemyData  = { ent = enemy, pos = pos } -- pos is the last position in which the enemy was seen. 


    self.EnemyMemory[ enemyIndex ] = enemyData
    EnemyRemovalMemoryHook( self, enemy )

    self:OnRememberEnemy( enemy, pos )
end 

function gs_aimodule.GetEnemyMemory( self, enemy )
    if not (IsValid( self ) and IsValid(enemy)) then return end 

    local enemyIndex = enemy:EntIndex()
    local enemyData  = self.EnemyMemory[ enemyIndex ]

    return enemyData 
end 



function gs_aimodule.SetEnemy( self, ent )
    if not ( IsValid(self) ) then return end 
    
    if IsValid(ent) then 
    if GetConVar("gstory_ai_ignoreplayers"):GetBool() and ent:IsPlayer() then return end 
    end 
    
    -- If no entity provided, clear current enemy
    if not ( ent or IsValid(ent) ) then
        ent = self.CurEnemy
        if IsValid(ent) then
            -- Remove registered per-entity enemy callback
            self.CurEnemy = nil 
            gs_aimodule.RemoveEnemy( self, ent )
        end
        return 
    end 

    -- Remove previous enemy callback if it exists and is different
    local old = self.CurEnemy
    if IsValid(old) and old ~= ent then
        gs_aimodule.RemoveRemoveCallback(self, old, "enemy")
    end

    self.CurEnemy = ent 
    gs_aimodule.AddEnemy( self, ent )


    self:OnSetEnemy( self, ent )

end 

function gs_aimodule.InterruptCoroutine(self)
    self.CoroutineInterrupted = true 
    timer.Simple( 0.1, function() 
        if IsValid( self ) then 
            self.CoroutineInterrupted = false 
        end 
    end )
end 

function gs_aimodule.AddEnemy( self, ent )
    if GetConVar("gstory_ai_ignoreplayers"):GetBool() and ent:IsPlayer() then return end
    if not ( IsValid(self) and IsValid( ent ) ) then return end 
    self.Enemies = self.Enemies or {}

    local enemies = self.Enemies 

    if table.HasValue( enemies, ent ) then return end 

    table.insert( enemies, ent )

    -- Notify that an enemy was added
    if self.OnEnemyAdded then
        pcall(function() self:OnEnemyAdded(ent) end)
    end

    gs_aimodule.AddRemoveCallback(self, ent, "EnemyRemoval", function()
        gs_aimodule.RemoveEnemy(self, ent)
    end )

end 

function gs_aimodule.RemoveEnemy( self, ent )
    -- Allow passing removed/invalid entities by accepting entity or entity index
    if not ( IsValid(self) and ent and self.Enemies ) then return end

    local enemies = self.Enemies 

    local enemyIndexPos
    if type(ent) == "number" then
        -- ent is an index
        for i, e in ipairs(enemies) do
            if IsValid(e) and e:EntIndex() == ent then
                enemyIndexPos = i
                break
            end
        end
    else
        enemyIndexPos = table.KeyFromValue( enemies, ent )
    end

    if enemyIndexPos then 
        local removed = table.remove( enemies, enemyIndexPos )

        if removed == self.CurEnemy then 
            gs_aimodule.SetEnemy( self, nil )
          
        end 

        -- Notify that an enemy was removed
        if self.OnEnemyRemoved then
             self:OnEnemyRemoved(removed or ent) 
        end
    end

end 

function gs_aimodule.ChooseEnemyByPriority(self, attempt)
    if not (IsValid( self ) and self.Enemies ) then return end 

    attempt = attempt or 0

    if attempt > 5 then return end 



    local enemies = self.Enemies
    local enemy   = enemies[ 1 ] 

    if enemy and IsValid(enemy) then 
        gs_aimodule.SetEnemy(self, enemy)
    else 
        if not enemy then return end 
        gs_aimodule.RemoveEnemy( self, enemy )
        gs_aimodule.ChooseEnemyByPriority( self, attempt + 1 )
    end
end 
    
function gs_aimodule.SortEnemiesByPriority( self, sortFunc )
    if not ( IsValid(self) and self.Enemies  ) then return end 

    if #self.Enemies < 2 then return end 

    local sorters = gs_aimodule.EnemySorters

    if isstring(sortFunc) or not sortFunc then 
        sortFunc = sorters[sortFunc or self.EnemySorter] or sorters.Distance 
    end 

    local enemies = self.Enemies 

    table.sort( enemies, function(ent1, ent2)
        return sortFunc(self, ent1, ent2)
    end )
end 



function gs_aimodule.PerformActionWithCooldown(self, actionName, cooldown, func, ...)
    -- Normalize keys
    local lastKey = "LastActionOccurrence_" .. actionName
    local timeKey = "TimeSinceAction_" .. actionName

    -- Compute time since last occurrence. If mil, treat is as infinity
    local last = self[lastKey]
    local timeSince = last and (CurTime() - last) or math.huge
    self[timeKey] = timeSince

    local inCooldown = timeSince < (cooldown or 0)

    -- Execute callback, passing whether we are in cooldown
    local ok, err = pcall(func, self, inCooldown, ...)
    if not ok then
        gs_aimodule.ThrowError("Error in PerformActionWithCooldown callback for '" .. tostring(actionName) .. "': " .. tostring(err))
    end

    -- Only update last occurrence if the action actually ran (i.e., not on cooldown)
    if not inCooldown then
        self[lastKey] = CurTime()
    end

    return not inCooldown
end 

function gs_aimodule.AddRemoveCallback(self, ent, id, func, ...)
    -- Validate inputs
    if not (IsValid(self) and IsValid(ent) and (type(id) == "string" or type(id) == "number") and type(func) == "function") then return false end

    self.RemoveCallbacks = self.RemoveCallbacks or {}

   
    local storageKey = tostring(id) .. "_" .. tostring(ent:EntIndex())
    local callKey = tostring(self:EntIndex()) .. "_" .. tostring(id) .. "_" .. tostring(ent:EntIndex())

 
    local existing = self.RemoveCallbacks[storageKey]
    if existing and IsValid(existing.ent) then
        existing.ent:RemoveCallOnRemove(existing.key)
    end

  
    ent:CallOnRemove(callKey, func, ...)

 
    self.RemoveCallbacks[storageKey] = { ent = ent, key = callKey, id = id }

    return true
end 

function gs_aimodule.RemoveRemoveCallback(self, entOrIndex, id)
    -- Requires id and the entity or its ent index to remove a specific registration
    if not (IsValid(self) and id and (type(id) == "string" or type(id) == "number") and self.RemoveCallbacks) then return false end

    local entIndex
    if type(entOrIndex) == "number" then
        entIndex = entOrIndex
    elseif entOrIndex and entOrIndex.EntIndex then
        entIndex = entOrIndex:EntIndex()
    else
        return false
    end

    local storageKey = tostring(id) .. "_" .. tostring(entIndex)
    local cb = self.RemoveCallbacks[storageKey]
    if not cb then return false end

    if IsValid(cb.ent) then
        cb.ent:RemoveCallOnRemove(cb.key)
    end

    self.RemoveCallbacks[storageKey] = nil

    return true
end 

