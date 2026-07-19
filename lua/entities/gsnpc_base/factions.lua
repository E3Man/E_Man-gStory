gs_aimodule = gs_aimodule or {}
gs_aimodule.Factions =  gs_aimodule.Factions or {}

local Factions = gs_aimodule.Factions 



-- Format: ["FACTION_NAME"] = Disposition (D_LI, D_HT, D_NU)
-- Converted from the old [Disposition] = { faction1, ... } layout

/*
Faction: Gmodders
Lore: Your usual gmod players, consisting of users, admins, and long-standing gags within the gmod culture. They're the main 
victims of the conflict War of The Servers 2. 
*/

Factions.FACTION_GMOD = { -- Gmodders, admins, gmod memes
    ["FACTION_ARC"] = D_LI,   -- Anomaly Research Center
    ["FACTION_WPD"] = D_LI,   -- World Protectors Division
    ["FACTION_MINGEBAGS"] = D_HT,
    ["FACTION_MEATY"] = D_HT,
    ["FACTION_SHADOW"] = D_HT
}

/*
Faction: Mingebags
Lore: Brought back to gmod by a yet unknown entity, the mingebags, now a militarized and organized faction, have the intentions
of taking revenge against the gmodders, who defeated them in the original War of The Servers.
*/

Factions.FACTION_MINGEBAGS = {
    ["FACTION_ARC"] = D_HT,
    ["FACTION_WPD"] = D_HT,
    ["FACTION_GMOD"] = D_HT,
    ["FACTION_MEATY"] = D_HT,
    ["FACTION_SHADOW"] = D_HT
}

/*
Faction: World Protectors Division (WPD)
Lore: An elite group formed after the events of War of the Servers, their objective is to intercept and eradicate any
anomalies that have the intentions of triggering a world-ending event. 
*/

Factions.FACTION_WPD = {
    ["FACTION_GMOD"] = D_LI,
    ["FACTION_MINGEBAGS"] = D_HT,
    ["FACTION_MEATY"] = D_HT,
    ["FACTION_ARC"] = D_NU,
    ["FACTION_SHADOW"] = D_NU
}

/*
Faction: Anomaly Research Center (ARC)
Lore: A group formed to collectively research the enigmatic map gm_construct 13 and its anomalous nature. They're set to 
eradicate and experiment with any gmod anomalies they encounter. 
*/

Factions.FACTION_ARC = {
    ["FACTION_GMOD"] = D_LI,
    ["FACTION_MINGEBAGS"] = D_HT,
    ["FACTION_MEATY"] = D_HT,
    ["FACTION_SHADOW"] = D_HT,
    ["FACTION_WPD"] = D_NU
}

/*
Faction: Shadow Man's Apparition Army
Lore: An army forged by the ancient, urban legend, shadow man. He built the army in fear that a world-ending event would occur
without him being prepared. He wants to be left alone. He may occasionally send apparitions to fight mingebags for causing the
conflict in the first place. 
*/

Factions.FACTION_SHADOW = {
    ["FACTION_GMOD"] = D_NU,
    ["FACTION_WPD"] = D_NU,
    ["FACTION_ARC"] = D_NU,
    ["FACTION_MINGEBAGS"] = D_HT,
    ["FACTION_MEATY"] = D_HT
}

/*
Faction: Meaty's Army
Lore: An ancient, russian urban legend that made his appearances in the early days of GMod. He's described as a fleshy, monstrous
figure with the desire to haunt every player's nightmares. With the rise of a new conflict, he seeks to build a powerful, flesh
army out of anything that's a player—whether it's a gmodder or a mingebag. 
*/

Factions.FACTION_MEATY = {
    ["FACTION_GMOD"] = D_HT,
    ["FACTION_WPD"] = D_HT,
    ["FACTION_ARC"] = D_HT,
    ["FACTION_MINGEBAGS"] = D_HT,
    ["FACTION_SHADOW"] = D_HT
}

-- Dispositions considered hostile. Build table safely in case some constants aren't defined.
local HostileDispositions = {}
HostileDispositions[ D_HT ] = true
HostileDispositions[ D_FR ] = true 

-- Utility: resolve a faction name from either an entity or a raw string
function Factions.ResolveFaction( maybeEntityOrString )
    if not maybeEntityOrString then return nil end
    if type( maybeEntityOrString ) == "string" then return maybeEntityOrString end

    if IsValid( maybeEntityOrString ) then
        if maybeEntityOrString.Faction and type( maybeEntityOrString.Faction ) == "string" then
            return maybeEntityOrString.Faction
        end
        if maybeEntityOrString.GetFaction and type( maybeEntityOrString.GetFaction ) == "function" then
            local ok, val = pcall( maybeEntityOrString.GetFaction, maybeEntityOrString )
            if ok and type(val) == "string" then return val end
        end
    end

    return nil
end

-- ==========================
-- Instance-specific relationships
-- These let a subject entity declare a disposition (D_HT/D_LI/D_NU/etc)
-- towards a specific target entity instance, overriding faction-level rules
-- ==========================

-- Set a per-instance relationship from subject -> target
function Factions.SetInstanceRelationship(subject, target, disposition)
    if not (IsValid(subject) and IsValid(target)) then return false end
    subject.InstanceRelationships = subject.InstanceRelationships or {}

    local tidx = target:EntIndex()
    subject.InstanceRelationships[tidx] = disposition

    -- Register a cleanup callback so when the target is removed we drop the relationship
    gs_aimodule = gs_aimodule or {}
    gs_aimodule.AddRemoveCallback(subject, target, "relationship_" .. tostring(tidx), function(bot, removedEnt)
        if not IsValid(bot) then return end
        bot.InstanceRelationships = bot.InstanceRelationships or {}
        bot.InstanceRelationships[tidx] = nil

        if bot.OnRelationshipRemoved then
            pcall(function() bot:OnRelationshipRemoved(removedEnt) end)
        end
    end, subject, target)

    return true
end


function Factions.GetInstanceRelationship(subject, target)
    if not (IsValid(subject) and IsValid(target) and subject.InstanceRelationships) then return nil end
    return subject.InstanceRelationships[target:EntIndex()]
end

-- Remove a per-instance relationship (by target ent or index)
function Factions.RemoveInstanceRelationship(subject, targetOrIndex)
    if not (IsValid(subject) and targetOrIndex) then return false end

    local tidx = type(targetOrIndex) == "number" and targetOrIndex or (IsValid(targetOrIndex) and targetOrIndex:EntIndex())
    if not tidx or not subject.InstanceRelationships then return false end

    subject.InstanceRelationships[tidx] = nil

    -- Remove the stored CallOnRemove that was created during SetInstanceRelationship
    gs_aimodule = gs_aimodule or {}
    gs_aimodule.RemoveRemoveCallback(subject, tidx, "relationship_" .. tostring(tidx))

    return true
end

-- Clear all per-instance relationships on a subject
function Factions.ClearAllInstanceRelationships(subject)
    if not IsValid(subject) then return false end

    subject.InstanceRelationships = nil
    gs_aimodule = gs_aimodule or {}
    gs_aimodule.RemoveAllRemoveCallbacks(subject)

    return true
end

-- Returns the disposition value (D_LI/D_HT/D_NU/etc) for subject -> target
-- Accepts entity objects or faction name strings. Returns a disposition constant; prefers an entity's Attitude before hostility
function Factions.GetDisposition( subject, target )
    local subjFaction = Factions.ResolveFaction( subject )
    local tgtFaction  = Factions.ResolveFaction( target )



    local instanceDisposition = Factions.GetInstanceRelationship( subject, target )

    if instanceDisposition then 
        return instanceDisposition 
    end 

    if subjFaction and tgtFaction and Factions[ subjFaction ] and Factions[ subjFaction ][ tgtFaction ] then
        return Factions[ subjFaction ][ tgtFaction ]
    end

    if subjFaction == tgtFaction then
  
        return D_LI 
    end 

    if IsValid( subject ) and subject.Attitude then
        return subject.Attitude
    end

  
    if subjFaction and Factions[ subjFaction ] and Factions[ subjFaction ]._DEFAULT then
        return Factions[ subjFaction ]._DEFAULT
    end


    if (type(subject) == "string") and IsValid( target ) and target.Attitude then
        return target.Attitude
    end

    -- 5) Default to neutral if nothing else is available
    return D_HT

end

-- Returns true if subject (entity or faction string) is hostile to target (entity or faction string).
function Factions.IsHostileTo( subject, target )

    if type(subject) ~= "string" and not IsValid( subject ) then return false end
    if type(target)  ~= "string" and not IsValid( target )  then return false end



  
    if subject == target then return false end

    local subjFaction = Factions.ResolveFaction( subject )
    local tgtFaction  = Factions.ResolveFaction( target )

    if subjFaction and tgtFaction and subjFaction == tgtFaction then return false end


    local disposition = Factions.GetDisposition( subject, target )


    local isHostile = HostileDispositions[ disposition ] == true


   
    return isHostile
end