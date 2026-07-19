gs_aimodule = gs_aimodule or {}
local Tasks = gs_aimodule.Task.Tasks 

local Factions = gs_aimodule.Factions

Tasks[ "EnemyManagement_Sight" ] = {
    ["OnEntitySight"] = function(self, ent)
        if not (ent.GS_Detectable) then return end 
     

    

        if not Factions.IsHostileTo(self, ent) then return end 
       
            gs_aimodule.AddEnemy( self, ent )
   

            gs_aimodule.SortEnemiesByPriority(self)

            gs_aimodule.ChooseEnemyByPriority( self )

         
    
    end,
    [ "OnEntitySightLost" ] = function( self, ent ) 
        if not Factions.IsHostileTo(self, ent) or not self.RemoveEnemyOnLostSight then return end 
        local disp = self:GetPos() - ent:GetPos()
        local dist = disp:Dot(disp)
        if self.EnemyManagement_Sight_OLS_DURE^2 <= dist then return end 
        
        gs_aimodule.RemoveEnemy(self, ent)
      
        if self.UsesEnemyMemory then 
        gs_aimodule.UpdateEnemyMemory(self, ent, ent:GetPos())
        end 
    end,
    ["OnEnemyRemoved"] = function(self, ent)
        if #self.Enemies == 0 then return  end 

     
        gs_aimodule.SortEnemiesByPriority(self)
        gs_aimodule.ChooseEnemyByPriority( self )  
    end,
    ["OnInjured"] = function(self, attacker, inflictor, dmginfo)
    

        if gs_aimodule.Factions.GetDisposition(self, attacker) == D_LI then return end  

        

        if self.EnemiesSet[ attacker:EntIndex() ] then  gs_aimodule.SetEnemy(self, attacker) return end 


        gs_aimodule.PerformActionWithCooldown(self, "AddEnemyOnInjured", 0.5, function(self, inCooldown)
            if inCooldown then return end 
            
         
            gs_aimodule.AddEnemy(self, attacker)
            gs_aimodule.SortEnemiesByPriority(self)
            gs_aimodule.ChooseEnemyByPriority( self )  
        end)
    end,
    Priority = 100
}

Tasks["NoFriendlyFire"] = {
    ["OnInjured"] = function(self,  attacker, inflictor, dmginfo)
        if gs_aimodule.Factions.GetDisposition(self, attacker) != D_LI then return end 
        
        dmginfo:SetDamage(0)
    end 
}