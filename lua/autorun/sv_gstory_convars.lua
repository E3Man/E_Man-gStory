

/* ----------------------------------------------
--- CONVARS
*/ ----------------------------------------------

/* ----------------------------------------------
--- AI
*/ ----------------------------------------------

CreateConVar( "gstory_ai_ignoreplayers", "0", FCVAR_NOTIFY, "Makes gStory AI ignore players")
cvars.AddChangeCallback( "gstory_ai_ignoreplayers", function(convar, oldvalue, newvalue)
    local nextbots = gs_aimodule.nextbots 
    if newvalue == "0" then return end

    for i, nextbot in ipairs( nextbots ) do 
        if not IsValid(nextbot) then continue end 
        for k, enemy in ipairs( nextbot.Enemies ) do 
            if not (IsValid(enemy) and enemy:IsPlayer() ) then continue end 
            gs_aimodule.RemoveEnemy(nextbot, enemy) 
        end 
    end 

end )