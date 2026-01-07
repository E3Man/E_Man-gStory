
local function sign(x) 
    if x > 0 then return 1 end 
    if x < 0 then return -1 end 
    return 0
end 


-- movement.lua
-- Movement / animation packet definitions for gs_aimodule
--
-- Changes: Modularized animation packet system
-- - Added registration API: Movement.RegisterAnimPacket/Unregister/Get
-- - Entities may set `self.CurAnimPacket` (string name) or pass packet tables to Movement.SetActivity
-- - Movement.ApplyHoldTypeAnimPacket now uses registered packets and clears stale packets
-- - Backwards compatible: `gs_aimodule.AnimPackets` still points to the default mapping (gStory_HoldTypeToAnim)
--
-- Example:
-- local pkt = { ply = { [ACT_IDLE] = ACT_HL2MP_IDLE_PISTOL }, npc = { [ACT_IDLE] = ACT_IDLE_ANGRY_PISTOL } }
-- gs_aimodule.Movement.RegisterAnimPacket("example_pistol", pkt)
-- self.CurAnimPacket = "example_pistol"
-- gs_aimodule.Movement.SetActivity(self, ACT_IDLE, true)


gs_aimodule = gs_aimodule or {}
gs_aimodule.Movement = gs_aimodule.Movement or {}
local Movement = gs_aimodule.Movement

-- Base, used for "normal" hold type
gStory_Anim_None = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE,
        [ACT_WALK] = ACT_HL2MP_WALK,
        [ACT_RUN] = ACT_HL2MP_RUN,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH
    },
    npc = {
        [ACT_IDLE] = ACT_IDLE,
        [ACT_WALK] = ACT_WALK,
        [ACT_RUN] = ACT_RUN,
        [ACT_CROUCHIDLE] = ACT_CROUCHIDLE,
        [ACT_WALK_CROUCH] = ACT_WALK_CROUCH
    }
}

-- Pistol / small one-handed weapons
gStory_Anim_Pistol = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_PISTOL,
        [ACT_WALK] = ACT_HL2MP_WALK_PISTOL,
        [ACT_RUN] = ACT_HL2MP_RUN_PISTOL,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_PISTOL,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_PISTOL
    },
    npc = {
        [ACT_IDLE] = ACT_IDLE_ANGRY_PISTOL,
        [ACT_WALK] = ACT_WALK_AIM_PISTOL,
        [ACT_RUN] = ACT_RUN_PISTOL,
        [ACT_CROUCHIDLE] = ACT_CROUCHIDLE_AGITATED,
        [ACT_WALK_CROUCH] = ACT_WALK_CROUCH
    }
}

-- Revolver (uses pistol-style animations; some bases add a revolver reload)
gStory_Anim_Revolver = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_REVOLVER,
        [ACT_WALK] = ACT_HL2MP_WALK_REVOLVER,
        [ACT_RUN] = ACT_HL2MP_RUN_REVOLVER,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_REVOLVER,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_REVOLVER
    },
    NPC = gStory_Anim_Pistol.npc
}

-- Dual pistols
gStory_Anim_Duel = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_DUEL,
        [ACT_WALK] = ACT_HL2MP_WALK_DUEL,
        [ACT_RUN] = ACT_HL2MP_RUN_DUEL,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_DUEL or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_DUEL or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_None.npc
}

-- SMG / rifles with vertical grip
gStory_Anim_SMG = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_SMG1,
        [ACT_WALK] = ACT_HL2MP_WALK_SMG1,
        [ACT_RUN] = ACT_HL2MP_RUN_SMG1,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_SMG1,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_SMG1
    },
    npc = {
        [ACT_IDLE] = ACT_IDLE_SMG1_STIMULATED,
        [ACT_WALK] = ACT_WALK_AIM_RIFLE,
        [ACT_RUN] = ACT_RUN_AIM_RIFLE,
        [ACT_CROUCHIDLE] = ACT_CROUCHIDLE_STIMULATED,
        [ACT_WALK_CROUCH] = ACT_WALK_CROUCH_AIM_RIFLE
    }
}

-- AR2 / rifles without vertical grip
gStory_Anim_AR2 = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_AR2,
        [ACT_WALK] = ACT_HL2MP_WALK_AR2,
        [ACT_RUN] = ACT_HL2MP_RUN_AR2,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_AR2 or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_AR2 or ACT_HL2MP_WALK_CROUCH
    },
    npc = {
        [ACT_IDLE] = ACT_IDLE_AIM_RIFLE_STIMULATED,
        [ACT_WALK] = ACT_WALK_RIFLE_STIMULATED,
        [ACT_RUN] = ACT_RUN_RIFLE_STIMULATED,
        [ACT_CROUCHIDLE] = ACT_CROUCHIDLE_AIM_STIMULATED,
        [ACT_WALK_CROUCH] = ACT_WALK_CROUCH_AIM_RIFLE
    }
}

-- Shotguns
gStory_Anim_Shotgun = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_SHOTGUN,
        [ACT_WALK] = ACT_HL2MP_WALK_SHOTGUN,
        [ACT_RUN] = ACT_HL2MP_RUN_SHOTGUN,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_SHOTGUN or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_SHOTGUN or ACT_HL2MP_WALK_CROUCH
    },
    npc = {
        [ACT_IDLE] = ACT_IDLE_SHOTGUN_AGITATED,
        [ACT_WALK] = ACT_WALK_AIM_SHOTGUN,
        [ACT_RUN] = ACT_RUN_AIM_SHOTGUN,
        [ACT_CROUCHIDLE] = ACT_CROUCHIDLE_AIM_STIMULATED,
        [ACT_WALK_CROUCH] = ACT_WALK_CROUCH_AIM_RIFLE
    }
}

-- RPG / shoulder-mounted
gStory_Anim_RPG = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_RPG,
        [ACT_WALK] = ACT_HL2MP_WALK_RPG,
        [ACT_RUN] = ACT_HL2MP_RUN_RPG,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_RPG or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_RPG or ACT_HL2MP_WALK_CROUCH
    },
    npc = {
        [ACT_IDLE] = ACT_IDLE_ANGRY_RPG,
        [ACT_WALK] = ACT_WALK_RPG,
        [ACT_RUN] = ACT_RUN_RPG,
        [ACT_CROUCHIDLE] = ACT_CROUCHIDLE_AIM_STIMULATED,
        [ACT_WALK_CROUCH] = ACT_WALK_CROUCH_RPG
    }
}

-- Physgun / gravity gun
gStory_Anim_Physgun = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_PHYSGUN,
        [ACT_WALK] = ACT_HL2MP_WALK_PHYSGUN,
        [ACT_RUN] = ACT_HL2MP_RUN_PHYSGUN,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_PHYSGUN or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_PHYSGUN or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_None.npc
}

-- Crossbow
gStory_Anim_Crossbow = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_CROSSBOW,
        [ACT_WALK] = ACT_HL2MP_WALK_CROSSBOW,
        [ACT_RUN] = ACT_HL2MP_RUN_CROSSBOW,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_CROSSBOW or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_CROSSBOW or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_AR2.npc
}

-- Camera (hold up in front of face)
gStory_Anim_Camera = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_CAMERA,
        [ACT_WALK] = ACT_HL2MP_WALK_CAMERA,
        [ACT_RUN] = ACT_HL2MP_RUN_CAMERA,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_CAMERA or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_CAMERA or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_None.npc
}

-- SLAM / explosives
gStory_Anim_SLAM = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_SLAM,
        [ACT_WALK] = ACT_HL2MP_WALK_SLAM,
        [ACT_RUN] = ACT_HL2MP_RUN_SLAM,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_SLAM or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_SLAM or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_None.npc
}

-- Grenade (similar to melee/throwing)
gStory_Anim_Grenade = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_GRENADE,
        [ACT_WALK] = ACT_HL2MP_WALK_GRENADE,
        [ACT_RUN] = ACT_HL2MP_RUN_GRENADE,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_GRENADE or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_GRENADE or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_None.npc
}

-- Melee / crowbar
gStory_Anim_Melee = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_MELEE,
        [ACT_WALK] = ACT_HL2MP_WALK_MELEE,
        [ACT_RUN] = ACT_HL2MP_RUN_MELEE,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_MELEE or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_MELEE or ACT_HL2MP_WALK_CROUCH
    },
    npc = {
        [ACT_IDLE] = ACT_IDLE_MELEE,
        [ACT_WALK] = ACT_WALK_AGITATED,
        [ACT_RUN] = ACT_RUN_AGITATED,
        [ACT_CROUCHIDLE] = ACT_CROUCHIDLE_AGITATED,
        [ACT_WALK_CROUCH] = ACT_WALK_CROUCH
    }
}

-- Two-handed sword
gStory_Anim_Melee2 = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_MELEE2,
        [ACT_WALK] = ACT_HL2MP_WALK_MELEE2,
        [ACT_RUN] = ACT_HL2MP_RUN_MELEE2,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_MELEE2 or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_MELEE2 or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_None.npc
}

-- Knife
gStory_Anim_Knife = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_KNIFE,
        [ACT_WALK] = ACT_HL2MP_WALK_KNIFE,
        [ACT_RUN] = ACT_HL2MP_RUN_KNIFE,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_KNIFE or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_KNIFE or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_Melee
}

-- Fist / unarmed
gStory_Anim_Fist = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_FIST,
        [ACT_WALK] = ACT_HL2MP_WALK_FIST,
        [ACT_RUN] = ACT_HL2MP_RUN_FIST,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_FIST or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_FIST or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_None.npc
}

-- Passive / lowered stance
gStory_Anim_Passive = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_PASSIVE,
        [ACT_WALK] = ACT_HL2MP_WALK_PASSIVE,
        [ACT_RUN] = ACT_HL2MP_RUN_PASSIVE,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_PASSIVE or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_PASSIVE or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_None.npc
}

-- Magic / telekinesis-like hold
gStory_Anim_Magic = {
    ply = {
        [ACT_IDLE] = ACT_HL2MP_IDLE_MAGIC,
        [ACT_WALK] = ACT_HL2MP_WALK_MAGIC,
        [ACT_RUN] = ACT_HL2MP_RUN_MAGIC,
        [ACT_CROUCHIDLE] = ACT_HL2MP_IDLE_CROUCH_MAGIC or ACT_HL2MP_IDLE_CROUCH,
        [ACT_WALK_CROUCH] = ACT_HL2MP_WALK_CROUCH_MAGIC or ACT_HL2MP_WALK_CROUCH
    },
    npc = gStory_Anim_None.npc
}

-- Helper table to map hold type names to animation tables
gStory_HoldTypeToAnim = {
    none = gStory_Anim_None,
    pistol = gStory_Anim_Pistol,
    revolver = gStory_Anim_Revolver,
    duel = gStory_Anim_Duel,
    smg = gStory_Anim_SMG,
    ar2 = gStory_Anim_AR2,
    shotgun = gStory_Anim_Shotgun,
    rpg = gStory_Anim_RPG,
    physgun = gStory_Anim_Physgun,
    crossbow = gStory_Anim_Crossbow,
    camera = gStory_Anim_Camera,
    slam = gStory_Anim_SLAM,
    normal = gStory_Anim_None,
    grenade = gStory_Anim_Grenade,
    melee = gStory_Anim_Melee,
    melee2 = gStory_Anim_Melee2,
    knife = gStory_Anim_Knife,
    fist = gStory_Anim_Fist,
    passive = gStory_Anim_Passive,
    magic = gStory_Anim_Magic
}

gs_aimodule.AnimPackets = gStory_HoldTypeToAnim

-- ENT.CurAnimPacket : string | The name of the current animation packet
-- ENT.CurPacketSet  : table | The table containing all the entity's main animation packets

-- Keep a local reference to the module object
local Movement = gs_aimodule.Movement or {}
gs_aimodule.Movement = Movement




-- Apply motion stats to the locomotion object
function Movement.ApplyMotionStats(self, statsData)
    local maxSpeed = statsData.speed or 100
    local acceleration = statsData.acceleration or 100
    local deceleration = statsData.deceleration or 100

    local loco = self.loco
    if not loco then return end

    loco:SetDesiredSpeed(maxSpeed)
    loco:SetAcceleration(acceleration)
    loco:SetDeceleration(deceleration)
end

local function ResolveAnimPacket( self, centralActivity, branch )
    local animPacketSet = self.AnimPacketSet or gStory_HoldTypeToAnim
    local curAnimPacket = self.CurAnimPacket or "none"
    local animPacket = animPacketSet[ curAnimPacket ] 

    local anim = animPacket[ branch ][ centralActivity ] 

    if not anim then 
        local packetSetStr = tostring( animPacketSet or gStory_HoldTypeToAnim )
        local animPacketStr = tostring( animPacket )
        local WarnMsg = string.format("Central act enumerated %d wasn't found in animation packet %s in the following animation packet set: %s", centralActivity, animPacketStr, packetSetStr)
        gs_aimodule.Warn( WarnMsg )

        return gStory_HoldTypeToAnim[ curAnimPacket ][ branch ][ centralActivity ]
    end 

    return anim 
    
end 

-- Central activity setter that supports packets by name or by table
function Movement.SetActivity(self, centralActivity, isPlayer, packet)
    local branch = isPlayer and "ply" or "npc"
    local act 

    if packet then 
        act = packet[ branch ][ centralActivity ]
            if not act then 
                gs_aimodule.Warn( "Couldn't set activity—Input packet doesn't contain the specified central activity!" ) 
                return 
            end 
        self:StartActivity( act )
    end 

    local anim   = ResolveAnimPacket( self, centralActivity, branch )
    if anim then 
        act = anim 
    else 
        gs_aimodule.Warn( "Couldn0t set activity—ResolveAnimPacket returned nil!" )
        return 
    end 

    self:StartActivity( act )

end

-- Apply hold-type-based packet for the entity. This now uses the registered packet system.
function Movement.ApplyHoldTypeAnimPacket(self)
    local weapon = self.Weapon
    local holdtype

    -- If weapon is an entity, prefer the instance method
    if IsValid(weapon) and weapon.GetHoldType then
        holdtype = weapon:GetHoldType()
    -- If weapon is provided as a class name (string), try to read stored weapon data
    elseif isstring(weapon) then
        local stored = weapons.GetStored(weapon)
        if stored and stored.HoldType then
            holdtype = stored.HoldType
        end
    end

    -- Only apply if a registered packet exists for this hold type
    if holdtype and Movement.GetAnimPacket(holdtype) then
        self.CurAnimPacket = holdtype
    else
        -- If there's no packet, clear current packet to fall back to defaults
        self.CurAnimPacket = "none"
    end
end

function Movement.AimAtTarget(self, target)
    if not IsValid(self) or not IsValid(target) then return end

    
    local dirVector = (target:GetPos() - self:GetPos())
    local targetAngles = dirVector:Angle()

   
    local myAngles = self:GetAngles()

    
    local diff = targetAngles - myAngles


    diff:Normalize()
    
    -- Set the pose parameters for yaw and pitch
    self:SetPoseParameter("aim_yaw", diff.y)
    self:SetPoseParameter("aim_pitch", diff.p)
end

function Movement.AimAtVector( self, pos )

   
    if not IsValid(self) or not pos then return end

    
    local dirVector = (pos - self:GetPos())
    local targetAngles = dirVector:Angle()

   
    local myAngles = self:GetAngles()

    
    local diff = targetAngles - myAngles


    diff:Normalize()
    
    -- Set the pose parameters for yaw and pitch
    self:SetPoseParameter("aim_yaw", diff.y)
    self:SetPoseParameter("aim_pitch", diff.p)
end 

function Movement.AimAtVectorByDegree( self, pos )
        
   -- if (not IsValid(self)) or (not IsValid(pos)) or (not speed) then  return end

    
    
    local dirVector = (pos - self:GetPos())
    local targetAngles = dirVector:Angle()

    local myAngles = self:GetAngles()

    local currentY = self:GetPoseParameter("aim_yaw") -- Get the current amount of degrees in the yaw
    local currentP = self:GetPoseParameter("aim_pitch") -- Get the current amount of degrees in the pitch

   
    
    local diff = targetAngles - myAngles -- How much we want to rotate it
    diff:Normalize() -- Normalize it (Duh)

    local unitSignY = sign( diff.y - currentY ) -- To which direction should the nextbot's yaw (And pitch) rotate to? (Defined by the sign of the diff)
    local unitSignP = sign( diff.p - currentP)


    local pDiff = diff.p - currentP
    local yDiff = diff.y - currentY 



    if math.abs(yDiff) > speed then
        self:SetPoseParameter("aim_yaw", currentY + unitSignY * speed)
    else
        self:SetPoseParameter("aim_yaw", diff.y)
    end

    if math.abs(pDiff) > speed then
        self:SetPoseParameter("aim_pitch", currentP + unitSignP * speed)
    else
        self:SetPoseParameter("aim_pitch", diff.p)
    end
 

end 

gs_aimodule.Movement = Movement




