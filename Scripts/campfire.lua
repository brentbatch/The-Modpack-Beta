
-- variables : 
flamedata = {}
-- odds of spreading fire: -- lower = more chance of spread
flamedata.odds_character = 5
flamedata.odds_shape = 13
flamedata.odds_other = 15 -- ground
flamedata.odds_fuse = 12
-- maximum amount of raycasts done when fire is killed by shape split:
flamedata.split_shape_reignite_tries = 20
-- maximum amount of raycasts done when fire dies of natural cause: (lifetime)
flamedata.fire_shape_dead_spread_tries = 5 -- to asure most of the creation burns up
-- minimum time before a player on fire gets a refreshed flame & timer:
flamedata.character_reignire_min_time = 2.5
-- lifetime
flamedata.lifetime_default = 3
flamedata.lifetime_fire_cardboard = 3 -- gets added to default
flamedata.lifetime_fire_plastic = 5 -- gets added to default
flamedata.lifetime_fire_wood = 9 --         "
flamedata.lifetime_fire_character = 9
flamedata.lifetime_fire_ground = 1
flamedata.lifetime_fire_fuse = 0
-- when spreading, offset fire raycaststartpos and raycastlength with radius:
flamedata.firespread_offset_character = 0.2
flamedata.firespread_radius_character = 1
flamedata.firespread_offset_shape = 0.2
flamedata.firespread_radius_shape = 0.5
flamedata.firespread_offset_shape_split = 0.2 -- don't touch -- reingite after force-killZ fire by shape split
flamedata.firespread_radius_shape_split = 0.5 -- don't touch
flamedata.firespread_offset_ground = 0.1
flamedata.firespread_radius_ground = 0.5
flamedata.firespread_offset_fuse = 0.3
flamedata.firespread_radius_fuse = 1
-- density of fires:
flamedata.fire_density_default = 1.2 -- 1.2 fires per 4x4x4 area
flamedata.fire_density_character = 3 -- allows for players to easely catch fire when REALLY close to a fire
flamedata.fire_density_shapes = 2.25 -- per 4x4x4 blocks
flamedata.fire_density_fuse = 2.1
-- player fire will go out faster when player has speed:
flamedata.character_fire_run_out = 1/350 -- higher = goes out faster when running
-- maximum fires in a world, to not kill fps
flamedata.maxfires = 80



campfire = class( nil )
campfire.maxParentCount = 1
campfire.maxChildCount = 0
campfire.connectionInput = sm.interactable.connectionType.logic
campfire.connectionOutput = sm.interactable.connectionType.none
campfire.colorNormal = sm.color.new( 0x009999ff  )
campfire.colorHighlight = sm.color.new( 0x11B2B2ff  )
campfire.poseWeightCount = 1

function campfire.server_onCreate( self ) 
	self.trackedShapes = {}
end

function campfire.server_onRefresh( self )
	--self:server_onCreate()
end

function campfire.server_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent.active then
			self:server_tryFire()
		end
		self.ON = false -- logic parent has control now
		
	elseif self.ON then
		self.starttime = self.starttime or os.time()
		self:server_tryFire()
	end
	if self.starttime and os.time() ~= self.time then
		print(os.time()-self.starttime)
		self.time = os.time()
	end
	
	for k, fire in pairs(self.fires) do
		if fire then
			--print(fire)
			if fire.alive + dt> fire.lifetime and not fire.done then
				--position, level, destructionRadius, impulseRadius, magnitude
				sm.physics.explode( fire.pos, 4, 0.2, 0.1, 0.1)
				fire.done = true
			end
		end
	end
	server_fireSpread(self, dt) -- calc fireSpread and spawn fires
end

function campfire.server_onProjectile(self, ...)
	self.ON = not self.ON
	self:server_sendState()	
end

function campfire.server_tryFire( self ) -- self.shape.at is the side flame is on
	-- bullet: (sync send, async/sync behaviour, spread is sync)
	local foundobjects = {}
	local shape = self.shape
	for _, offset in pairs({sm.vec3.new(0,0,0),(self.shape.right+self.shape.up)*0.25,(self.shape.right-self.shape.up)*0.25,(-self.shape.right+self.shape.up)*0.25,-(self.shape.right+self.shape.up)*0.25}) do
		local hit, result = sm.physics.raycast(self.shape.worldPosition + offset, self.shape.worldPosition + offset + sm.vec3.new(0,0,4))--16 blocks up
		if hit then
			if result.type == "character" then
				server_createfire(self, nil , result, true, false)
			elseif result.type == "body" then
				local shape = result:getShape()
				if not foundobjects[shape.id] then foundobjects[shape.id] = {distance = 16, shape = shape} end
				if foundobjects[shape.id].distance > result.fraction*16 then
					foundobjects[shape.id].distance = result.fraction*16
					foundobjects[shape.id].result = result
				end
			end
		end
	end
	for shapeid, foundobject in pairs(foundobjects) do -- create tracker if it doesn't exist yet
		if not self.trackedShapes[shapeid] then self.trackedShapes[shapeid] = { timer = 0, shape = foundobject.shape } end
	end
	for shapeid, trackedShape in pairs(self.trackedShapes) do
		if foundobjects[shapeid] then -- count up/spawn fire
			trackedShape.timer = trackedShape.timer + 1/(7*foundobjects[shapeid].distance^1.8)
			if trackedShape.timer > 1 then
				server_createfire(self, nil , foundobjects[shapeid].result, true, false)
				self.trackedShapes[shapeid] = nil
			end
		else -- count down/remove
			trackedShape.timer = trackedShape.timer - 0.1/40 -- 10 sec
			if trackedShape.timer < 0 then
				self.trackedShapes[shapeid] = nil
			end
		end
	end
end

function campfire.server_sendState(self, newstate)
	if newstate ~= nil then self.ON = newstate end
	self.network:sendToClients('client_newState', self.ON)
end

-- Client

function campfire.client_onCreate( self )
	self.fires = {}
	self.shooteffect = sm.effect.createEffect("flames", self.interactable)
	self.shooteffect:setOffsetRotation( sm.vec3.getRotation(sm.vec3.new( 0, 1, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:setOffsetPosition( sm.vec3.new( 0, 0.25, 0 ))
	self.network:sendToServer('server_sendState')
end
function campfire.client_onRefresh(self)
	--self:client_onCreate()
end

function campfire.client_newState(self, newstate)
	self.client_ON = newstate
end

function campfire.client_onInteract(self)
	self.network:sendToServer('server_sendState', not self.client_ON)
end

function campfire.client_onFixedUpdate( self, dt )
	firebehaviour(self, dt)
end

function campfire.client_onUpdate( self, deltaTime ) -- animation of shooting flame & trigger
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() then
			if not self.shooteffect:isPlaying() then
				self.shooteffect:start()
			end
		else
			if self.shooteffect:isPlaying() then
				self.shooteffect:stop()
			end
		end
	else
		if self.client_ON then
			if not self.shooteffect:isPlaying() then
				self.shooteffect:start()
			end
		else
			if self.shooteffect:isPlaying() then
				self.shooteffect:stop()
			end
		end
	end
end

function campfire.client_onDestroy(self)
	for k, fire in pairs(self.fires) do
		fire.effect:stop()
		self.fires[k] = nil
	end
	self.shooteffect:stop()
end


function campfire.client_spawnfire(self, data)  -- the network link to send fire to clients
	spawnfire(self, data.position, data.target, data.oil)
end





function getLocal(shape, vec)
    return sm.vec3.new(sm.shape.getRight(shape):dot(vec), sm.shape.getAt(shape):dot(vec), sm.shape.getUp(shape):dot(vec))
end


function getGlobal(shape, vec)
    return  sm.shape.getRight(shape) * vec.x  +  sm.shape.getAt(shape) * vec.y +  sm.shape.getUp(shape) * vec.z 
end

function spawnfire(self, position, target, oil) -- use networking to call!
	-- fire is created here, on client, server handles densityviolation
	
	local firetype = nil
	if type(target) == "Character" then
		firetype = "character"
	elseif type(target) == "Shape" then
		firetype = "shape"
	end
	local reignite = false
	for k, fire in pairs(self.fires) do
		if (position - fire.pos):length() < 3 and 
			fire.firetype == "character" and firetype == "character" and fire.character.id == target.id then
			-- character is already on fire, don't set him on fire again
			reignite = true 
			if fire.alive > flamedata.character_reignire_min_time then
				fire.alive = 0
				fire.effect:start()
			end
		end
	end
	if not reignite then 
		if firetype == "character" then
			local fire = {firetype = "character", character = target,  effect = sm.effect.createEffect("flames"), 
				pos = target.worldPosition + target.velocity, alive = 0, lifetime = flamedata.lifetime_default + flamedata.lifetime_fire_character, oil = oil}
			fire.effect:setPosition(target.worldPosition)
			fire.effect:setVelocity(target.velocity)
			fire.effect:start()
			table.insert(self.fires, fire)
		elseif firetype == "shape" then
			if sm.exists(target) then
				local relative = getLocal(target, position - target.worldPosition)
				local lifetime = flamedata.lifetime_default + (target:getMaterial() == "Cardboard" and flamedata.lifetime_fire_cardboard or 0) + 
								(target:getMaterial() == "Plastic" and flamedata.lifetime_fire_plastic or 0) + 
								(target:getMaterial() == "Wood" and flamedata.lifetime_fire_wood or 0)
								
				if tostring(target.shapeUuid) == "0987b4fe-18fb-4c85-9238-026f204d00e8" --[[fuse]] then
					lifetime = flamedata.lifetime_default + flamedata.lifetime_fire_fuse
				end
				local fire = {firetype = "shape", shape = target, relativepos = relative, effect = sm.effect.createEffect("flames"), 
					pos = position + target.velocity, alive = 0, lifetime = lifetime, oil = oil}
				fire.effect:setPosition(position)
				fire.effect:setVelocity(target.velocity)
				fire.effect:start()
				table.insert(self.fires, fire)
			end
		else 
			local fire = {firetype = "static", effect = sm.effect.createEffect("flames"),
						pos = position, alive = 0, lifetime = flamedata.lifetime_default+flamedata.lifetime_fire_ground, oil = oil}
			fire.effect:setPosition(position)
			fire.effect:start()
			table.insert(self.fires, fire)
		end
	end
end

function server_fireSpread(self, dt) -- server, spawn more fires
	local size = 0
	for k, fire in pairs(self.fires) do size = size + 1 end
	
	for k, fire in pairs(self.fires) do
		if fire then 
			if fire.firetype == "character" then
				if math.random(1,flamedata.odds_character) == 1 then -- odds of spreading fire
					local hit, result =  sm.physics.raycast( fire.character.worldPosition + sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_offset_character),360), 
											fire.character.worldPosition + sm.noise.gunSpread(sm.vec3.new(0,0,-flamedata.firespread_radius_character),360) )
					if hit then
						server_createfire(self, fire, result, false, false)
					end
				end 
			
			elseif fire.firetype == "shape" then 
				if size > flamedata.maxfires then return 0 end
				
				if sm.exists(fire.shape) then
					if tostring(fire.shape.shapeUuid) == "0987b4fe-18fb-4c85-9238-026f204d00e8" --[[fuse]] then
						for x=1,flamedata.odds_fuse do -- odds of spreading fire
							local hit, result =  sm.physics.raycast( fire.pos + sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_offset_fuse),180), 
												fire.pos - sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_radius_fuse),180) )
							if hit then
								server_createfire(self, fire, result, false, false)
							end
						end
					else -- any other shape
						if math.random(1,flamedata.odds_shape) ~= 1 then -- odds of spreading fire
							local hit, result =  sm.physics.raycast( fire.pos - sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_offset_shape),360), 
												fire.pos + sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_radius_shape),360) )
												
							if not hit and math.random(1,200) == 1 then -- spread to floor above:
								hit, result = sm.physics.raycast( fire.pos - sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_offset_shape),360), 
												fire.pos + sm.noise.gunSpread(sm.vec3.new(0,0,4),3) )
								if hit then
									hit = math.random(1,math.ceil(sm.util.clamp(16*result.fraction, 1, 16))) == 1
								end
							end
							if hit then
								server_createfire(self, fire, result, false, false)
							end
						end
					end
					if fire.alive + 1/40 > fire.lifetime then -- end of life, try to spread
						local x = 1
						local createdfire = false
						for x = 1,flamedata.fire_shape_dead_spread_tries do
							if not createdfire then
								local hit, result =  sm.physics.raycast( fire.pos + sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_offset_shape_split),360), 
													fire.pos + sm.noise.gunSpread(sm.vec3.new(0,0,-flamedata.firespread_radius_shape_split),360) )
								if hit then
									server_createfire(self, fire, result, false, true)
									createdfire = (result.type == "character" or result.type == "body")
								end
							end
						end
					end
				elseif fire.lifetime ~= 0 then -- a shape died/split
					--print(os.clock(), 'died')
					-- try to pass fire along!
					local x = 1
					local createdfire = false
					for x = 1,flamedata.split_shape_reignite_tries do
						if not createdfire then
							local hit, result =  sm.physics.raycast( fire.pos + sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_offset_shape_split),360), 
												fire.pos + sm.noise.gunSpread(sm.vec3.new(0,0,-flamedata.firespread_radius_shape_split),360) )
							if hit then
								server_createfire(self, fire, result, false, true)
								createdfire = (result.type == "character" or result.type == "body")
							end
						end
					end
					--print("created:", createdfire)
					fire.lifetime = 0 -- DEAD
					fire.done = true
				end
				
			else
				if size > flamedata.maxfires then return 0 end
				if math.random(1,flamedata.odds_other) ~= 1 then -- odds of spreading fire
					local hit, result = sm.physics.raycast( fire.pos + sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_offset_ground),360), 
										fire.pos + sm.noise.gunSpread(sm.vec3.new(0,0,flamedata.firespread_radius_ground),360) )
					if hit then
						server_createfire(self, fire, result, false, false)
					end
				end 
			
			end
		end
	end
end

function server_createfire(self, fire, result, oil, densityoverwrite) -- server, checks for densityviolations
	-- fire is generated here on server and send to client to start existing
	
	local size = 0
	for k, fire in pairs(self.fires) do size = size + 1 end
	
	local density = flamedata.fire_density_default
	local firetype = nil
	local position = result.pointWorld
	if result.type == "character" then
		firetype = "character"
		density = flamedata.fire_density_character
	elseif result.type == "body" then
		if tostring(result:getShape().shapeUuid) == "0987b4fe-18fb-4c85-9238-026f204d00e8" --[[fuse]] then
			firetype = "shape"
			density = flamedata.fire_density_fuse
		else
			firetype = "shape"
			density = flamedata.fire_density_shapes
		end
	end
	local densityviolation = false
	for k, fire in pairs(self.fires) do
		if (position - fire.pos):length() < 1/density and not densityoverwrite then 
			densityviolation = true
			if (fire.firetype == "character" and (position - fire.pos):length() > 0.5/flamedata.fire_density_character) and false then -- disabled
				densityviolation = false -- player needs to be able to spread fire to stuff more easely
			end
		end
		if (position - fire.pos):length() < 2 and 
			fire.firetype == "character" and firetype == "character" and fire.character.id == result:getCharacter().id then
			if fire.alive > flamedata.character_reignire_min_time then
				densityviolation = false -- push to client side
				-- forcefully re-ignite player on client side
			end
		end
	end
	if not densityviolation then
		local material = (result.type == "body" and result:getShape():getMaterial())
		if (material == "Wood" or material == "Plastic" or material == "Cardboard") or oil then
			-- light creations on fire
			
	if size > flamedata.maxfires then return 0 end
			self.network:sendToClients("client_spawnfire",{position = result.pointWorld, target = result:getShape(), oil = oil})
		end
		if result.type == "character" or oil then  
			-- light nearby players on fire
			self.network:sendToClients("client_spawnfire",{position = result.pointWorld, target = result:getCharacter(), oil = oil})
		end
		if not(result.type == "character" or result.type == "body") and ((fire and fire.oil) or oil) then 
			-- light ground on fire
			
			if size > flamedata.maxfires then return 0 end
			self.network:sendToClients("client_spawnfire",{position = result.pointWorld, target = nil, oil = oil})
		end
	end
end

function firebehaviour(self, dt) -- client , animate fire, make it behave
	for k, fire in pairs(self.fires) do
		if fire then 
			if fire.firetype == "character" then
				fire.effect:setPosition(fire.character.worldPosition)
				fire.effect:setVelocity(fire.character.velocity)
				fire.pos = fire.character.worldPosition + fire.character.velocity*dt
				fire.alive = fire.alive + dt + fire.character.velocity:length()*flamedata.character_fire_run_out
			elseif fire.firetype == "shape" then 
				if sm.exists(fire.shape) then
					fire.effect:setPosition(fire.shape.worldPosition + getGlobal(fire.shape, fire.relativepos)) 
					fire.effect:setVelocity(fire.shape.velocity)
					fire.pos = fire.shape.worldPosition + getGlobal(fire.shape, fire.relativepos) + fire.shape.velocity*dt
					
				else
					-- DEAD
					fire.lifetime = 0
				end
				fire.alive = fire.alive + dt
			else
				fire.alive = fire.alive + dt
			end
			
		end
		
		if fire.alive > fire.lifetime then
			--fire.effect:setPosition(sm.vec3.new(0,0,1000000))
			fire.effect:stop()
			self.fires[k] = nil
		end
	end
end
