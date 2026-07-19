AddCSLuaFile()

-- =====================================================
-- gStory Entity Module
-- All abstraction layers for gStory entities can be found here
-- I love not killing myself hardcoding everything into every single entity 
-- =====================================================

gs_entmodule = {}
gs_entmodule.Task = {}

local Task = gs_entmodule.Task 

-- =====================================================
-- Inclusions
-- =====================================================

include("entities/gsent_base/tasks.lua")

-- =====================================================
-- Functions
-- =====================================================

function gs_entmodule.Warn(str)
    MsgC(Color(220,68,27), "[ gStory AI ] [? WARNING ?] " .. tostring(str) .. "\n")
end

function gs_entmodule.ThrowError(err)
    -- Use MsgC (typo fixed) so errors are visible in console
    MsgC(Color(220,27,27), "[ gStory AI ] [! ERROR !] " .. tostring(err) .. "\n")
end


function gs_entmodule.RemoveAllRemoveCallbacks(self)
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

function gs_entmodule.InitializeEntity(self)
    if not SERVER then return end 

    self:SetModel(self.Model)
    self:SetModelScale( 1,0 )

    if self.InitialMaxHealth or self.InitialHealth then 
    self:SetMaxHealth( self.InitialMaxHealth or self.InitialHealth )
    self:SetHealth(self.InitialHealth or self.InitialMaxHealth)
    end 

    self:PhysicsInit( self.PhysicsSolidType )
    self:SetMoveType( self.MoveType )
    self:SetSolid( self.SolidType )
    local phys = self:GetPhysicsObject() 
    if phys:IsValid() and self.HasPhysics then 
        phys:Wake()
    end

    self.Enemies = {}
    self.EnemiesSet = {}

    self:SetUseType( self.UseType )

    if self.Mass then 
        self:SetMass( self.Mass )
    end 

    for _, task in ipairs(self.InitialTasks) do
        if isstring(task) then 
            Task.AddTask(self, task)
        elseif istable(task) then 
            local taskName = task.name 
            local taskArgs = task.args 
            Task.AddTask(self, taskName, unpack(taskArgs))
        end 
    end 

    gs_entmodule.AddRemoveCallback(self, self, "self_cleanup", gs_aimodule.RemoveAllRemoveCallbacks, self) 

end 

function gs_entmodule.PerformActionWithCooldown(self, actionName, cooldown, func, ...)
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
        gs_entmodule.ThrowError("Error in PerformActionWithCooldown callback for '" .. tostring(actionName) .. "': " .. tostring(err))
    end

    -- Only update last occurrence if the action actually ran (i.e., not on cooldown)
    if not inCooldown then
        self[lastKey] = CurTime()
    end

    return not inCooldown
end 

function gs_entmodule.AddRemoveCallback(self, ent, id, func, ...)
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

function gs_entmodule.RemoveRemoveCallback(self, entOrIndex, id)
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

function gs_entmodule.ConeOfSight(self)
    local offset = self.COVOffset or 0 

    local eyes = self:WorldSpaceCenter()
   
    local fovtorad = math.rad(self.FOV)

    local forward = self:GetForward() * self.SightDistance

    local sightTable = ents.FindInCone( eyes, forward, self.SightDistance, fovtorad )

    return makeSet(sightTable)
end 

function gs_entmodule.PVSOfSight(self)
    return makeSet(ents.FindInPVS(self))
end 

function gs_entmodule.UpdateSightList(self)
    local previousSighted = self.SightedEntities or {}-- Entities from last check
    local currentSight = gs_entmodule.ConeOfSight(self) -- Current entities in sight

    -- Step 1: Detect newly sighted entities
    for ent, _ in pairs(currentSight) do 
        if previousSighted[ent] then 
            
            previousSighted[ent] = nil 
            continue 
        end 
        
        
        if IsValid(ent) then
            self:Internal_OnEntitySight(ent)
        end
    end 

    -- Step 2: Remaining entities in previousSighted are the ones we just lost sight of
    for ent, _ in pairs(previousSighted) do 
        if IsValid(ent) then
            self:Internal_OnEntitySightLost(ent)
        end
    end 

    
    self.SightedEntities = currentSight 
end

local function EnemyRemovalMemoryHook( self, enemy )
    if not IsValid( enemy ) or not IsValid( self ) then return end 

    local enemyIndex = enemy:EntIndex()

    gs_entmodule.AddRemoveCallback(self, enemy, "ememory_" .. enemyIndex, gs_entmodule.UpdateEnemyMemory, self, enemy) 
end 

function gs_entmodule.UpdateEnemyMemory( self, enemy, pos )

    local enemyIndex = enemy:EntIndex() 

    if not ( IsValid(self) and IsValid(enemy) and pos) then 
        if not pos and IsValid(enemy) then 
            self.EnemyMemory[ enemyIndex ] = nil 
            self:OnForgetEnemy( enemy )
            return 
        end 
        gs_entmodule.Warn( "Cannot update enemy memory—self, enemy or pos are invalid!" )
    end 

    self.EnemyMemory = self.EnemyMemory or {}

    local enemyData  = { ent = enemy, pos = pos } -- pos is the last position in which the enemy was seen. 


    self.EnemyMemory[ enemyIndex ] = enemyData
    EnemyRemovalMemoryHook( self, enemy )

    self:OnRememberEnemy( enemy, pos )
end 

function gs_entmodule.GetEnemyMemory( self, enemy )
    if not (IsValid( self ) and IsValid(enemy)) then return end 

    local enemyIndex = enemy:EntIndex()
    local enemyData  = self.EnemyMemory[ enemyIndex ]

    return enemyData 
end 



function gs_entmodule.SetEnemy( self, ent, fromRemoveEnemy )
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
            if fromRemoveEnemy then return end 
            gs_entmodule.RemoveEnemy( self, ent )
        end
        return 
    end 

    -- Remove previous enemy callback if it exists and is different
    local old = self.CurEnemy
    if IsValid(old) and old ~= ent then
        gs_entmodule.RemoveRemoveCallback(self, old, "enemy")
    end

    self.CurEnemy = ent 
    gs_entmodule.AddEnemy( self, ent )


    self:OnSetEnemy( ent )

end 


function gs_entmodule.AddEnemy( self, ent )
    if GetConVar("gstory_ai_ignoreplayers"):GetBool() and ent:IsPlayer() then return end
    if not ( IsValid(self) and IsValid( ent ) ) then return end 

    local enemies = self.Enemies 



    if self.EnemiesSet[ ent:EntIndex() ] then return end 

    table.insert( enemies, ent )
    self.EnemiesSet[ ent:EntIndex() ] = true 

    -- Notify that an enemy was added
    if self.OnEnemyAdded then
        pcall(function() self:OnEnemyAdded(ent) end)
    end

    gs_entmodule.AddRemoveCallback(self, ent, "EnemyRemoval", function()
        gs_entmodule.RemoveEnemy(self, ent)
    end )

end 

function gs_entmodule.RemoveEnemy( self, ent )
    -- Allow passing removed/invalid entities by accepting entity or entity index
    if not ( IsValid(self) and ent and self.Enemies ) then return end

    local enemies = self.Enemies 

    

    local enemyIndexPos = table.KeyFromValue( enemies, ent )


    if enemyIndexPos then 
        local removed = table.remove( enemies, enemyIndexPos )

        self.EnemiesSet[ removed:EntIndex() ] = nil

        if removed == self.CurEnemy then 
            gs_entmodule.SetEnemy( self, nil, true )
          
        end 

        -- Notify that an enemy was removed
        if self.OnEnemyRemoved then
             self:OnEnemyRemoved(removed or ent) 
        end
    end

end 

function gs_entmodule.ChooseEnemyByPriority(self, attempt)
    if not (IsValid( self ) and self.Enemies ) then return end 

    attempt = attempt or 0

    if attempt > 5 then return end 



    local enemies = self.Enemies
    local enemy   = enemies[ 1 ] 

    if enemy and IsValid(enemy) then 
        gs_entmodule.SetEnemy(self, enemy)
    else 
        if not enemy then return end 
        gs_entmodule.RemoveEnemy( self, enemy )
        gs_entmodule.ChooseEnemyByPriority( self, attempt + 1 )
     
    end
end 
    
function gs_entmodule.SortEnemiesByPriority( self, sortFunc )
    if not self.SortEnemies then return end 
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