include("entities/gsent_base/shared.lua")

function ENT:Draw()
    self:DrawModel() -- Draws the model of the Entity. This function is called every frame.
end