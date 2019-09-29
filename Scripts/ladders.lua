
ladder = class( nil )
ladder.maxChildCount = 0
ladder.maxParentCount = 0
ladder.connectionInput = 0
ladder.connectionOutput = 0
ladder.colorNormal = sm.color.new(0x000000ff)
ladder.colorHighlight = sm.color.new(0x000000ff)
ladder.poseWeightCount = 1

function ladder.server_onCreate( self )
	self:server_init()
end
function ladder.server_onRefresh( self )
	self:server_init()
end
function ladder.server_init( self )
	if ladder_playerspulsed == nil then ladder_playerspulsed = {} end
end

function ladder.server_onFixedUpdate( self, dt )
	local grav = sm.physics.getGravity()
	local position = self.shape.worldPosition
	
	local localX = sm.shape.getRight(self.shape)
	local localY = sm.shape.getAt(self.shape)
	local localZ = sm.shape.getUp(self.shape)
	
	
	--self.network:sendToClients("client_particle", position +)
	
	--self.network:sendToClients("client_particle", position + getGlobal(self.shape, raypoint*direction))
	local pulse = sm.vec3.new(0,0,grav/0.50*dt)
	for k, player in pairs(sm.player.getAllPlayers()) do
		if player.character == nil then return 0 end
		local playerpos = player.character.worldPosition
		
		local localpos = getLocal(self.shape, playerpos - position)
		
		-- x = sideways , y = distance , z = up
		-- center = 0, 0.5, z
		
		local id = player.id
		local drag = player.character.velocity*-dt*5
		if not (ladder_playerspulsed and (ladder_playerspulsed[id] == nil or (os.clock() - ladder_playerspulsed[id])>0.01)) then
			pulse = sm.vec3.new(0,0,0) 
			drag = sm.vec3.new(0,0,0)
		end -- only antigrav once per tick
		local positioningx = getGlobal(self.shape, sm.vec3.new( - localpos.x,0,0))/3.5
			
		if math.abs(localZ.z)>0.9 then -- normal mode
			if math.abs(localpos.x)<1/3 and math.abs(localpos.y)<0.75 and localpos.z > -0.6 and localpos.z<1.2 then
				
				-- let player go up when close to it
				if (ladder_playerspulsed and (ladder_playerspulsed[id] == nil or (os.clock() - ladder_playerspulsed[id])>0.01)) then
					pulse = pulse + sm.vec3.new(0,0, (0.5-math.abs(localpos.y)))*1.5
				end
				
				-- keep player positioned in middle of front of ladder
				local positioningy = getGlobal(self.shape, sm.vec3.new(0,0.5 - localpos.y,0))/2.1
				
				if localpos.y < 0 then positioningy = getGlobal(self.shape, sm.vec3.new(0,-0.5 - localpos.y,0))/2.3 end
				--print(positioningy)
				pulse = pulse + positioningx + positioningy
				
				sm.physics.applyImpulse(player.character, (pulse + drag)*player.character.mass)
				ladder_playerspulsed[id] = os.clock()
			end
			
		else -- monkeybar mode
			if math.abs(localpos.x)<1/3 and math.abs(localpos.y)<1.5 and localpos.z > -0.6 and localpos.z<1.2 then
				-- keep player positioned in middle of front of ladder
				
				local holdingvalue = (1.3 - localpos.y)/2.5
				local positioningy = getGlobal(self.shape, sm.vec3.new(0,holdingvalue,0))
				
				if localpos.y < 0 then positioningy = getGlobal(self.shape, sm.vec3.new(0,-0.5 - localpos.y,0))/2.3 end
				
				pulse = pulse + positioningx + positioningy -- bugs for some reason
				--print(positioningy)
				
				sm.physics.applyImpulse(player.character, (pulse + drag/3)*player.character.mass)
				ladder_playerspulsed[id] = os.clock()
			end
		end
		
	end
	self.hadparent = haslogic
end

function ladder.client_particle(self, location)
	sm.particle.createParticle( "construct_welding", location)
end


function getLocal(shape, vec)
    return sm.vec3.new(sm.shape.getRight(shape):dot(vec), sm.shape.getAt(shape):dot(vec), sm.shape.getUp(shape):dot(vec))
end

function getGlobal(shape, vec)
    return sm.shape.getRight(shape)* vec.x + sm.shape.getAt(shape) * vec.y + sm.shape.getUp(shape) * vec.z
end