ENT.Base = "gsnpc_base" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.Type = "nextbot"
ENT.PrintName = "Gmodder" -- The name that will appear in the spawn menu.
ENT.Author = "E_Man" -- The author's name for this Entity.
ENT.Category = "gStory" -- The category for this Entity in the spawn menu.
ENT.Purpose = "[REDACTED]" -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.
ENT.AdminOnly = true

list.Set( "NPC", "gsnpc_gmodder", {
	Name = "Gmodder",
	Class = "gsnpc_gmodder",
	Category = "gStory NPCs"
})

