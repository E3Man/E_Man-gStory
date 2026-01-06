local function defaultGenerator( self, area, fromArea, ladder, elevator, length )
	if ( !IsValid( fromArea ) ) then

		-- first area in path, no cost
		return 0
	
	else
	
		if ( !self.loco:IsAreaTraversable( area ) ) then
			-- our locomotor says we can't move here
			return -1
		end

		-- compute distance traveled along path so far
		local dist = 0

		if ( IsValid( ladder ) ) then
			dist = ladder:GetLength()
		elseif ( length > 0 ) then
			-- optimization to avoid recomputing length
			dist = length
		else
			dist = ( area:GetCenter() - fromArea:GetCenter() ):GetLength()
		end

		local cost = dist + fromArea:GetCostSoFar()

		-- check height change
		local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
		if ( deltaZ >= self.loco:GetStepHeight() ) then
			if ( deltaZ >= self.loco:GetMaxJumpHeight() ) then
				-- too high to reach
				return -1
			end

			-- jumping is slower than flat ground
			local jumpPenalty = 5
			cost = cost + jumpPenalty * dist
		elseif ( deltaZ < -self.loco:GetDeathDropHeight() ) then
			-- too far to drop
			return -1
		end

		return cost
	end
end 



function ENT:ChaseEntity(ent, options)

	local options = options or {}

	local path = Path( "Chase" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Chase( self, ent )

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() ) do

		if self.CoroutineInterrupted == true then return end 

		path:Update( self )

		-- Draw the path (only visible on listen servers or single player)
		if ( options.draw ) then
			path:Draw()
		end

		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then

			self:HandleStuck()

			return "stuck"

		end

		--
		-- If they set maxage on options then make sure the path is younger than it
		--
		if ( options.maxage ) then
			if ( path:GetAge() > options.maxage ) then return "timeout" end
		end

		--
		-- If they set repath then rebuild the path every x seconds
		--
		if ( options.repath ) then
			if ( path:GetAge() > options.repath ) then path:Chase( self, ent ) end
		end

		coroutine.yield()

	end

	return "ok"


end 

function ENT:MoveToPos( pos, options, generator )

	local options = options or {}

	local function finalGenerator(area, fromArea, ladder, elevator, length) 
		local cost = defaultGenerator(self, area, fromArea, ladder, elevator, length)

		if generator then 
		return cost + generator(self, area, fromArea, ladder, elevator, length)
		end 

		return cost
	end 

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, pos, finalGenerator )

	if ( !path:IsValid() ) then return "failed" end

-- Loop while path is valid and not interrupted
	while ( path:IsValid()) do

        if self.CoroutineInterrupted == true then return end 

		path:Update( self )

		-- Draw the path (only visible on listen servers or single player)
		if ( options.draw ) then
			path:Draw()
		end

		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then

			self:HandleStuck()

			return "stuck"

		end

		--
		-- If they set maxage on options then make sure the path is younger than it
		--
		if ( options.maxage ) then
			if ( path:GetAge() > options.maxage ) then return "timeout" end
		end

		--
		-- If they set repath then rebuild the path every x seconds
		--
		if ( options.repath ) then
			if ( path:GetAge() > options.repath ) then path:Compute( self, pos, finalGenerator ) end
		end 

		coroutine.yield()

	end

	-- Return an explicit status when we were interrupted
	if self.CoroutineInterrupted == true then
		return "interrupted"
	end

	return "ok"

end


function ENT:MoveToward( pos, bool )
	self.loco:Approach( pos, 1 )
	if bool then 
		self.loco:FaceTowards( pos )
	end 
end 




