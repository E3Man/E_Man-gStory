ENT.Base = "gsnpc_base" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.Type = "nextbot"
ENT.PrintName = "Mingebag Infantry" -- The name that will appear in the spawn menu.
ENT.Author = "E_Man" -- The author's name for this Entity.
ENT.Category = "gStory" -- The category for this Entity in the spawn menu.
ENT.Purpose = "[REDACTED]" -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.
ENT.AdminOnly = true

list.Set( "NPC", "gsnpc_conscript_mgb", {
	Name = "Mingebag Conscript",
	Class = "gsnpc_conscript_mgb",
	Category = "gStory NPCs"
})

if (CLIENT) then return end 

AddCSLuaFile()

local Task = gs_aimodule.Task 
local Tasks = Task.Tasks 

ENT.Model = "models/player/kleiner.mdl"  -- Model used by the NPC
ENT.Bodygroup = {}                       -- Bodygroups to set on the model

--- WEAPONS & BACKPACK ---
ENT.Weapon = {"gswep_m4a1"}         -- Weapon used by the NPC. Will also be put in its inventory
ENT.Inventory = {}                 -- Additional weapons to put in the NPC's inventory

--- BEHAVIOUR ---
ENT.Faction = "FACTION_MINGEBAGS"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.UseLineOfSight = true                -- Whether the NPC needs line of sight to detect enemies

ENT.InitialMaxHealth = 100
ENT.InitialHealth = 100

ENT.MeleeAttackCooldown = 0.8

--- TASKS --- 

ENT.InitialTasks = { {name = "EnemyManagement_Sight"}, {name = "TacticalAI_Patrol"}, {name = "AI_ShootEnemy"}, {name = "SensoryAI_PanicOnOtherKilled"} }

ENT.PreferredCombatTask = "TacticalAI_CircularStrafe"

--- MAIN HOOKS --- 

local function GraduationCap(ent)
    if not IsValid(ent) then return end
  
    local boneIndex = ent:LookupBone("ValveBiped.Bip01_Head1")
    if not boneIndex then return end 
    local hat = ents.Create("prop_dynamic") 

   	hat:SetModel("models/player/items/humans/graduation_cap.mdl")

    hat:Spawn()
	hat:Activate()

	hat:SetMoveType(MOVETYPE_NONE)



    


	hat:SetParent(ent, boneIndex)
	hat:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL))	

    ent.GraduationCap = hat 



    return hat
end

function ENT:GSAI_OnKilled()
	self.GraduationCap:Remove()
end 

function ENT:GSAI_Initialize()
    gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )
	GraduationCap(self)
end
