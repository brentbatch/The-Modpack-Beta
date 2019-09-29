
-- conveyor.lua --
conveyor = class( nil )
conveyor.maxParentCount = 1
conveyor.maxChildCount = 1
conveyor.connectionInput =  sm.interactable.connectionType.logic + 1024
conveyor.connectionOutput = 1024
conveyor.colorNormal = sm.color.new( 0x334C1Cff )
conveyor.colorHighlight = sm.color.new( 0x4B6633ff )
conveyor.poseWeightCount = 1

function conveyor.server_onCreate( self ) 
	self:server_init()
end

function conveyor.server_init( self ) 
	self.pose = 0
	self.sources = {
		[1] = sm.vec3.new(-0.255,0.15,0.125-0.50),
		[2] = sm.vec3.new(-0.255,0.15,0.125-0.25),
		[3] = sm.vec3.new(-0.255,0.15,0.125+0.00),
		[4] = sm.vec3.new(-0.255,0.15,0.125+0.25),
		                       
		[5] = sm.vec3.new( 0.255,-0.15,0.125-0.50),
		[6] = sm.vec3.new( 0.255,-0.15,0.125-0.25),
		[7] = sm.vec3.new( 0.255,-0.15,0.125+0.00),
		[8] = sm.vec3.new( 0.255,-0.15,0.125+0.25)
	}                          
	self.destinations = {           
		[1] = sm.vec3.new( 0.255,0.15,0.125-0.50),
		[2] = sm.vec3.new( 0.255,0.15,0.125-0.25),
		[3] = sm.vec3.new( 0.255,0.15,0.125+0.00),
		[4] = sm.vec3.new( 0.255,0.15,0.125+0.25),
		                       
		[5] = sm.vec3.new(-0.255,-0.15,0.125-0.50),
		[6] = sm.vec3.new(-0.255,-0.15,0.125-0.25),
		[7] = sm.vec3.new(-0.255,-0.15,0.125+0.00),
		[8] = sm.vec3.new(-0.255,-0.15,0.125+0.25)
	}
	--if bodies == nil then bodies = {} end
	if pulsed == nil then pulsed = {} end
	if playerspulsed == nil then playerspulsed = {} end
end	

function conveyor.server_onRefresh( self )
	self:server_init()
end


function conveyor.server_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	local hey = os.clock()
	if parent and parent:isActive() then
		self.interactable:setActive(true)
		--raycasts:
		
		local position = self.shape.worldPosition
		local direction = 1
		
		for k, raypoint in pairs(self.sources) do
			local hit, result = sm.physics.raycast(position + getGlobal(self.shape, raypoint*direction),
													position + getGlobal(self.shape, self.destinations[k]*direction))
			if hit then
				--self.network:sendToClients("client_particle", position + getGlobal(self.shape, raypoint*direction))
				--self.network:sendToClients("client_particle", position + getGlobal(self.shape, self.destinations[k]*direction))
				
				local forcedirection = (getGlobal(self.shape, (self.destinations[k]*direction)) - getGlobal(self.shape, raypoint*direction)):normalize()
				if result.type == "body" then
					
					--local mass = result:getShape().mass
					local velocity = result:getBody():getVelocity()
					local drag = velocity/-2
					drag.z = drag.z/2
					local offset = sm.vec3.new(0,0, result:getBody().worldPosition.z - result.pointWorld.z   )*-0.8
					--print(offset)
					local id = result:getBody().id
					if pulsed and (pulsed[id] == nil or (os.clock() - pulsed[id])>0.01) and id ~= self.shape:getBody().id then
						--print(os.clock())
						sm.physics.applyImpulse(result:getBody(), ((forcedirection + drag)*120 + sm.vec3.new(0,0,11/0.95466))* result:getBody().mass*dt, true, offset)
					end
					pulsed[id] = os.clock()
					
				elseif result.type == "terrainSurface" then
				
				
				elseif result.type == "character" then
					local drag = result:getCharacter().velocity/-15
					
					local id = result:getCharacter().id
					if playerspulsed and (playerspulsed[id] == nil or (os.clock() - playerspulsed[id])>0.01) then
						sm.physics.applyImpulse(result:getCharacter(), (forcedirection*0.42 + drag)* result:getCharacter().mass)
					end
					pulsed[id] = os.clock()
				end
				
			end
		end
		
	elseif self.interactable:isActive() then
		self.interactable:setActive(false)
	end
end


function conveyor.client_playsound(self, sound)
	sm.audio.play(sound, self.shape:getWorldPosition())
end
function conveyor.client_particle(self, location)
	sm.particle.createParticle( "construct_welding", location)
end

function conveyor.server_changemode(self)
	self.mode = self.mode == 0 and 1 or 0
end


function conveyor.client_onInteract(self)
	self.network:sendToServer("server_changemode")
end
function conveyor.server_onDestroy( self )
	
end

function conveyor.client_onUpdate(self)
	local parent = self.interactable:getSingleParent()
	if parent and parent:isActive() then
		local uv = 100-(os.clock()*77)%100
		self.interactable:setUvFrameIndex(uv)
	end
end

function listlength(list)
	local l = 0
	for k, v in pairs(list) do
		l = l + 1
	end
	return l
end

function shapeexists(shape)
	local test = shape:getId()
	return true
end

function getGlobal(shape, vec)
    return sm.shape.getRight(shape)* vec.x + sm.shape.getAt(shape) * vec.y + sm.shape.getUp(shape) * vec.z
end




-- conveyorend.lua --
conveyorend = class( nil )
conveyorend.maxParentCount = 1
conveyorend.maxChildCount = 1
conveyorend.connectionInput =  sm.interactable.connectionType.logic + 1024
conveyorend.connectionOutput = 1024
conveyorend.colorNormal = sm.color.new( 0x334C1Cff )
conveyorend.colorHighlight = sm.color.new( 0x4B6633ff )
conveyorend.poseWeightCount = 1

function conveyorend.server_onCreate( self ) 
	self:server_init()
end

function conveyorend.server_init( self ) 
	self.pose = 0
	self.sources = {
		[1] = sm.vec3.new(-0.18,0.15,0.125-0.50),
		[2] = sm.vec3.new(-0.18,0.15,0.125-0.25),
		[3] = sm.vec3.new(-0.18,0.15,0.125+0.00),
		[4] = sm.vec3.new(-0.18,0.15,0.125+0.25),
		                      
		[5] = sm.vec3.new( 0.18,-0.15,0.125-0.50),
		[6] = sm.vec3.new( 0.18,-0.15,0.125-0.25),
		[7] = sm.vec3.new( 0.18,-0.15,0.125+0.00),
		[8] = sm.vec3.new( 0.18,-0.15,0.125+0.25)
	}                        
	self.destinations = {         
		[1] = sm.vec3.new( 0.18,0.15,0.125-0.50),
		[2] = sm.vec3.new( 0.18,0.15,0.125-0.25),
		[3] = sm.vec3.new( 0.18,0.15,0.125+0.00),
		[4] = sm.vec3.new( 0.18,0.15,0.125+0.25),
		                      
		[5] = sm.vec3.new(-0.18,-0.15,0.125-0.50),
		[6] = sm.vec3.new(-0.18,-0.15,0.125-0.25),
		[7] = sm.vec3.new(-0.18,-0.15,0.125+0.00),
		[8] = sm.vec3.new(-0.18,-0.15,0.125+0.25)
	}
	self.sourcesside = {
		[1] = sm.vec3.new(-0.22,0.15,0.125-0.50),
		[2] = sm.vec3.new(-0.22,0.15,0.125-0.25),
		[3] = sm.vec3.new(-0.22,0.15,0.125+0.00),
		[4] = sm.vec3.new(-0.22,0.15,0.125+0.25)
	}
	self.destinationsside=
	{
		[1] = sm.vec3.new(-0.22,-0.15,0.125-0.50),
		[2] = sm.vec3.new(-0.22,-0.15,0.125-0.25),
		[3] = sm.vec3.new(-0.22,-0.15,0.125+0.00),
		[4] = sm.vec3.new(-0.22,-0.15,0.125+0.25)
	}
	--if bodies == nil then bodies = {} end
	if pulsed == nil then pulsed = {} end
	if playerspulsed == nil then playerspulsed = {} end
end	

function conveyorend.server_onRefresh( self )
	self:server_init()
end


function conveyorend.server_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	if parent and parent:isActive() then
		self.interactable:setActive(true)
		--raycasts:
		local position = self.shape.worldPosition
		local direction = 1
		--self.network:sendToClients("client_particle", position + getGlobal(self.shape, self.destinationsside[1]*direction))
		for k, raypoint in pairs(self.sourcesside) do
			local hit, result = sm.physics.raycast(position + getGlobal(self.shape, raypoint*direction),
													position + getGlobal(self.shape, self.destinationsside[k]*direction))
			if hit then
				local forcedirection = (getGlobal(self.shape, (self.destinationsside[k]*direction))- getGlobal(self.shape, raypoint*direction)):normalize()*-1
				if result.type == "body" then
					
					--local mass = result:getShape().mass
					local velocity = result:getBody():getVelocity()
					local drag = velocity/-2
					drag.z = drag.z/2
					local offset = sm.vec3.new(0,0, result:getBody().worldPosition.z - result.pointWorld.z   )*-0.8
					--print(offset)
					local id = result:getBody().id
						--print(os.clock())
					sm.physics.applyImpulse(result:getBody(), ((forcedirection + drag)*10 + sm.vec3.new(0,0,10/0.95466))* result:getBody().mass*dt, true, offset)
					
				elseif result.type == "terrainSurface" then
				
				
				elseif result.type == "character" then
					--print('o')
					local drag = result:getCharacter().velocity/-15
					local id = result:getCharacter().id
					if playerspulsed and (playerspulsed[id] == nil or (os.clock() - playerspulsed[id])>0.02) then
						sm.physics.applyImpulse(result:getCharacter(), (forcedirection*0.42 + drag)* result:getCharacter().mass)
					end
					pulsed[id] = os.clock()
				end
			end
			
		end
		for k, raypoint in pairs(self.sources) do
			local hit, result = sm.physics.raycast(position + getGlobal(self.shape, raypoint*direction),
													position + getGlobal(self.shape, self.destinations[k]*direction))
			if hit then
				--self.network:sendToClients("client_particle", position + getGlobal(self.shape, raypoint*direction))
				--self.network:sendToClients("client_particle", position + getGlobal(self.shape, self.destinations[k]*direction))
				
				local forcedirection = (getGlobal(self.shape, (self.destinations[k]*direction))- getGlobal(self.shape, raypoint*direction)):normalize()
				if result.type == "body" then
					
					--local mass = result:getShape().mass
					local velocity = result:getBody():getVelocity()
					local drag = velocity/-2
					drag.z = drag.z/2
					local offset = sm.vec3.new(0,0, result:getBody().worldPosition.z - result.pointWorld.z   )*-0.8
					--print(offset)
					local id = result:getBody().id
					if pulsed and (pulsed[id] == nil or (os.clock() - pulsed[id])>0.02) and id ~= self.shape:getBody().id then
						--print(os.clock())
						sm.physics.applyImpulse(result:getBody(), ((forcedirection + drag)*50 + sm.vec3.new(0,0,10/0.95466))* result:getBody().mass*dt, true, offset)
					end
					pulsed[id] = os.clock()
					
				elseif result.type == "terrainSurface" then
				
				
				elseif result.type == "character" then
					local drag = result:getCharacter().velocity/-15
					
					local id = result:getCharacter().id
					if playerspulsed and (playerspulsed[id] == nil or (os.clock() - playerspulsed[id])>0.02) then
						sm.physics.applyImpulse(result:getCharacter(), (forcedirection*0.42 + drag)* result:getCharacter().mass)
					end
					pulsed[id] = os.clock()
				end
				
			end
		end
		
	elseif self.interactable:isActive() then
		self.interactable:setActive(false)
	end
end
function conveyorend.client_particle(self, location)
	sm.particle.createParticle( "construct_welding", location)
end

function conveyorend.server_changemode(self)
	self.mode = self.mode == 0 and 1 or 0
end

function conveyorend.client_onInteract(self)
	self.network:sendToServer("server_changemode")
end
function conveyorend.server_onDestroy( self )
	
end

function conveyorend.client_onFixedUpdate(self)
	local parent = self.interactable:getSingleParent()
	if parent and parent:isActive() then
		local uv = 100-(os.clock()*78)%100
		self.interactable:setUvFrameIndex(uv)
	end
end

