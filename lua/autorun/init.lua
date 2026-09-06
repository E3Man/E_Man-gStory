
gs_aimodule = gs_aimodule or {}

include( "autorun/gs_aimodule/module.lua" )

include("autorun/sv_gstory_convars.lua")


/*

Hello, E_Man here!

Before diving deep into the code, I want to express my gratitude to everyone who has supported my work over the years. 
Your encouragement and feedback have been invaluable.

This script is part of a larger project that I've been passionate about, and I hope it brings value to the community.

Thereby, I'd love to share the lore behind gStory, the garry's mod story mode I'm working on.

gStory is set in the universe of Garry's Mod, where the mingebags have been brought back by an unknown, powerful entity.
However, as unexpected as their return may seem, there's something even worse to be worried about;
Their militarization and organization. Not only are they back, they have also acquired intelligence. 

Their organized chaos has allowed them to take over gmod universe, leaving only a small remnant of maps habitable. It is up
to you, player, along with what remains of the community, to take garry's mod back in a high-stakes conflict. 

This story mode will also have the players seeing themselves not as the heroes, but as part of a collective effort.

This is a love letter to the community. This was written in 17/12/2025. Thank you, gmodders!

*/

hook.Add("PlayerSpawn", "GS_PlayerFaction", function(ply)
    ply.Faction = "FACTION_GMOD"
    ply.GS_Detectable = true
end )

hook.Add( "PlayerCanPickupWeapon", "GS_AntiGSWEPPickup", function( ply, weapon )
    return ( weapon.GS_WEP ~= true )
end )

hook.Add("PlayerSay", "GS_RequestMedic", function(ply, txt)
    pattern = "medic"
    txtLower = string.lower(txt) 

    local match = string.match(txtLower, pattern)

    if match  then 
        local gmodMedics = ents.FindByClass("gsnpc_healer")
        for k, medic in ipairs(gmodMedics) do 
            table.insert( medic.HealQueue, ply )
            gs_aimodule.Task.RunPreferredTaskFor(medic, "Combat")
        end 
    end 
end )


hook.Add("PlayerSpawn", "GS_SetPlayerMovementSpeed", function(ply)
    if not GetConVar("gstory_enabled"):GetBool() then return end 
    timer.Simple(0.1, function()
        ply:SetRunSpeed(gs_aimodule.GenericRunSpeed)
    end)
end )

local rawdmginfo = DamageInfo()

hook.Add("OnEntityWaterLevelChanged", "GS_InstantDrown", function(ent)
    if ent.GS_AI and ent.CanInstaDrown then 
        ent:OnKilled( rawdmginfo )
    end 
end )