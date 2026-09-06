TOOL.Name = "Position Localizer"
TOOL.Category = "GStory Developer Tools"
TOOL.AddToMenu = true 

TOOL.ClientConVar["tag"] = "Entity" 


function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl( "textbox", {label = "Tag", command = "gstool_poslocalizer_tag" } )
end 

TOOL.EntitySet = {}

if CLIENT then

	TOOL.Information = {

		{ name = "info"},
		{ name = "desc" },

		-- Stage 0: Select An Origin Entity
		{name = "left_origin", stage = 0},
		-- Stage 1: Add / Remove Entities 

		{name = "left_entityinteract", stage = 1},
		{name = "right_deleteall", stage = 1},
		{name = "reload_print", stage = 1}


	}

    language.Add("tool.gstool_poslocalizer.name", "Position Localizer")
    language.Add("tool.gstool_poslocalizer.desc", "Given an origin entity, prints out a table of any other selected entities with their position relative to that of the origin and their angle.")

	-- Stage 0 
	language.Add("tool.gstool_poslocalizer.left_origin", "Chooses An Origin Entity")

	-- Stage 1
	language.Add("tool.gstool_poslocalizer.left_entityinteract", "Adds / Removes An Entity From The List")
	language.Add("tool.gstool_poslocalizer.right_deleteall", "Resets The Current Entity System")
	language.Add("tool.gstool.poslocalizer.reload_print", "Prints Table In Lua Syntax")




end

local function AddOnRemoveCallback(self, ent)
	ent:CallOnRemove( tostring(self), function(ent2) 
		local id = ent2:EntIndex()
		self.EntitySet[ id ] = nil 
	end )
end 

function TOOL:LeftClick( tr )
	local ent = tr.Entity 

	if not IsValid(ent) or ent:IsWorld() then return false end 

	if self:GetStage() == 0 then 
		self.OriginEntityPos = ent:GetPos()
		self.OriginEntityAng = ent:GetAngles()
		self:SetStage( 1 )
	elseif self:GetStage() == 1 then
		local id = ent:EntIndex() 
		if self.EntitySet[ id ] then 
			self.EntitySet[id] = nil
		end
	
		local convar = self:GetClientInfo("tag")
		
		self.EntitySet[ id ] = convar
		AddOnRemoveCallback(self, ent)

	end 

	return true 

end

function TOOL:Reload( )
	if not self:GetStage() == 1 then return false end  

	local set = self.EntitySet 
	
	print("{")
	for id, tag in pairs( set ) do 
		local ent = Entity(id)

		local strToPrint = "[" .. tag .. id .. "] =  {%s},"

		--Vector Info
		local angles = self.OriginEntityAng
		local entvector = ent:GetPos() - self.OriginEntityPos
		entvector:Rotate(-1 * angles )
		local vectorInfo = string.format( "pos = Vector( %s ), ", string.Replace( tostring( entvector ), " ", ",") )

		--Angle Info 
		local entangles = ent:GetAngles() - angles 
		local angleInfo = string.format("ang = Angles( %s ), ", string.Replace( tostring( entangles ), " ", ","))

		--Class info 
		local classInfo = string.format("class = %s, ", ent:GetClass())

		-- Model Info 
		local modelInfo = string.format("mdl = %s", ent:GetModel())

		strToPrint = string.format( strToPrint, vectorInfo .. angleInfo .. classInfo .. modelInfo )

		print( strToPrint )

	end 

	print("}")

	return false 
end 

function TOOL:RightClick()
	if not self:GetStage() == 1 then return false end 

	for k, _ in pairs( self.EntitySet ) do 
		self.EntitySet[ k ] = nil 
	end 

	self:SetStage( 0 )

	return false 
end 
