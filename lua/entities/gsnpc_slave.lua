ENT.Base = "gsnpc_base" -- Specifies that this Entity is based on the 'base_gmodentity', inheriting its functionality.
ENT.Type = "nextbot"
ENT.PrintName = "Fodder Slave" -- The name that will appear in the spawn menu.
ENT.Author = "E_Man" -- The author's name for this Entity.
ENT.Category = "gStory" -- The category for this Entity in the spawn menu.
ENT.Purpose = "A soul enslaved to overwhelm the gmodders." -- The purpose of this Entity.
ENT.Spawnable = true -- Specifies whether this Entity can be spawned by players in the spawn menu.

list.Set( "NPC", "gsnpc_slave", {
	Name = "MingeTrooper",
	Class = "gsnpc_slave",
	Category = "gStory NPCs"
})

if (CLIENT) then return end 

AddCSLuaFile()

local Task = gs_aimodule.Task 
local Tasks = Task.Tasks 

ENT.Model = "models/player/police.mdl"  -- Model used by the NPC
ENT.Bodygroup = {}                       -- Bodygroups to set on the model

--- WEAPONS & BACKPACK ---
ENT.Weapon = {"gswep_usp", "gswep_smg1"}         -- Weapon used by the NPC. Will also be put in its inventory
ENT.Inventory = {}                 -- Additional weapons to put in the NPC's inventory

--- BEHAVIOUR ---
ENT.Faction = "FACTION_MINGEBAGS"         -- Faction the NPC belongs to
ENT.Attitude = D_HT                      -- Default attitude of the NPC towards other NPCs
ENT.UseLineOfSight = true                -- Whether the NPC needs line of sight to detect enemies



ENT.InitialMaxHealth = 80
ENT.InitialHealth = 80

ENT.MeleeAttackCooldown = 0.8

ENT.RangedAttackRange = 2000



ENT.InitialMotionStats = {
    speed = 300
}

ENT.PreferredCombatTask = "FodderAI_MeatShield"
ENT.PreferredIdleTask   = "TacticalAI_Idle"

ENT.InitialTasks = { {name = "EnemyManagement_Sight"}, {name = "TacticalAI_Idle"}, {name = "AI_ShootEnemy"} }

local function MelonHead(ent)
    if not IsValid(ent) then return end
  
    local boneIndex = ent:LookupBone("ValveBiped.Bip01_Head1")
    if not boneIndex then return end 

    local melon = ents.Create("prop_dynamic") 

    melon:SetModel("models/props_junk/watermelon01.mdl")

    melon:Spawn()
    
    local bonePos, boneAng = ent:GetBonePosition(boneIndex)
    
    melon:SetPos(bonePos)
    melon:SetAngles(boneAng)
 
    melon:SetParent(ent)
    
    melon:FollowBone(ent, boneIndex)

    melon:SetLocalPos(Vector(4, 0, 0)) 
    melon:SetLocalAngles(Angle(0, 0, 0))

    ent.MelonHead = melon 

    return melon
end

local combatTasks = {
    "FodderAI_MeatShield",
    "FodderAI_Flanker"
}

function ENT:GSAI_Initialize()
    gs_aimodule.Movement.SetActivity( self, ACT_IDLE, true )
    
    self:SetColor( Color(255, 0, 0) )
    MelonHead(self)
    

end 

function ENT:GSAI_OnKilled()
   
    if IsValid(self.MelonHead) then 
    self.MelonHead:Remove()
    end 

    self:EmitSound("npc/overwatch/radiovoice/die"..math.random(3)..".wav", 90, math.random(60, 180), 2)
end


