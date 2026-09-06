gs_aimodule = gs_aimodule or {}
gs_aimodule.EnemySorters = {}

local EnemySorters = gs_aimodule.EnemySorters

function EnemySorters.Distance(self, ent1, ent2)
    if not (IsValid(ent1) and IsValid(ent2) ) then return end

    local selfPos = self:GetPos()
    local dis1, dis2 = selfPos - ent1:GetPos(), selfPos - ent2:GetPos()
    local dot1, dot2 = dis1:Dot( dis1 ), dis2:Dot(dis2)

    return dot1 < dot2 
end 