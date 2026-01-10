function ENT:GetAimVector()

            local muzzleId  = self.Weapon:LookupAttachment("muzzle")
        local muzzleAtt = self.Weapon:GetAttachment(muzzleId) 


        local angle = muzzleAtt.Ang

        return angle:Forward()

end 

function ENT:GetShootPos()
       local muzzleId  = self.Weapon:LookupAttachment("muzzle")
       local muzzleAtt = self.Weapon:GetAttachment(muzzleId) 


       local position = muzzleAtt.Pos

    return position
end 

function ENT:ViewPunch() end 