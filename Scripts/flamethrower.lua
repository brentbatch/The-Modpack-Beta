
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



flamethrower = class( nil )
flamethrower.maxParentCount = 1
flamethrower.maxChildCount = 0
flamethrower.connectionInput = sm.interactable.connectionType.logic
flamethrower.connectionOutput = sm.interactable.connectionType.none
flamethrower.colorNormal = sm.color.new( 0x009999ff  )
flamethrower.colorHighlight = sm.color.new( 0x11B2B2ff  )
flamethrower.poseWeightCount = 1
flamethrower.fireDelay = 11 --ticks
flamethrower.bulletlivetime = 7
flamethrower.firetime = 7

function flamethrower.server_onCreate( self ) 
	self:server_init()
end

function flamethrower.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function flamethrower.server_onRefresh( self )
	self:server_init()
end

function flamethrower.server_onFixedUpdate( self, dt )
	if not self.canFire then
		self.fireDelayProgress = self.fireDelayProgress + 1
		if self.fireDelayProgress >= self.fireDelay then
			self.fireDelayProgress = 0
			self.canFire = true	
		end
	end
	self:server_tryFire()
	local parent = self.interactable:getSingleParent()
	if parent then
		self.parentActive = parent:isActive()
	end
	
	for k, bullet in pairs(self.bullets) do
		--predict collision detect:
		local hit, result =  sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 )
		if hit then
			bullet.alive = 100
			server_createfire(self, nil , result, true, false)
		end
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
	
end



function flamethrower.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and self.canFire then
			-- bullet: (sync send, async/sync behaviour, spread is sync)
			self.canFire = false
			local dir = sm.noise.gunSpread(-self.shape.right, 7 ) * 20 * math.random(9800,10000)/10000
			local extra = dir*dir:dot(self.shape.velocity)*0.0015 -- velocity correction
			if extra:dot(dir) > 0 then dir = dir + extra end  -- velocity correction
			self.network:sendToClients( "client_onShoot", {dir = dir, gravity = sm.physics.getGravity()/10})
			
			-- fire (sync send, async behaviour)
			local hit, result =  sm.physics.raycast( self.shape.worldPosition, self.shape.worldPosition - self.shape.right*1.5 )
			if hit then
				server_createfire(self, nil , result, true, false)
			end
		end
	end
	server_fireSpread(self, dt) -- calc fireSpread and spawn fires
end

-- Client

function flamethrower.client_onCreate( self )
	self:client_init()
end
function flamethrower.client_onRefresh(self)
	--self:client_init()
end
function flamethrower.client_init(self)
	self.bullets = {}
	self.fires = {}
	self.boltValue = 0.0
	self.shooteffect = sm.effect.createEffect("flame", self.interactable)
	self.shooteffect:setOffsetRotation(  sm.vec3.getRotation(sm.vec3.new( 1, 0, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:setOffsetPosition( sm.vec3.new( -5/4, 1/6.5, -1/100 ))
	self.time = 0
end


function flamethrower.client_onFixedUpdate( self, dt )
	for k, bullet in pairs(self.bullets) do
		if bullet then 
			-- flight path:
			bullet.direction = bullet.direction*0.975 - sm.vec3.new(0,0,bullet.grav*dt*10) 
			
			-- animate bullet:
			bullet.pos = bullet.pos + bullet.direction* dt
			bullet.effect:setPosition(bullet.pos)
			bullet.effect:setVelocity(bullet.direction)
			bullet.alive = bullet.alive + dt
		end
		if bullet.alive + dt > flamethrower.bulletlivetime then
			bullet.effect:setPosition(sm.vec3.new(0,0,1000000))
			bullet.effect:stop()
			self.bullets[k] = nil
		end
	end
	local x = 0
	for k, v in pairs(self.bullets) do x = x + 1 end
	--print(x) 
	firebehaviour(self, dt)
end


function flamethrower.client_onDestroy(self)
	self.bullets = nil
	for k, fire in pairs(self.fires) do
		fire.effect:setPosition(sm.vec3.new(0,0,1000000))
		fire.effect:stop()
		self.fires[k] = nil
	end
	self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
	self.shooteffect:stop()
end

function flamethrower.client_onShoot( self, data ) -- new bullet
	self.boltValue = 1.0
	local position = self.shape.worldPosition-self.shape.right*1.3 + self.shape.at*0.1
	local bullet = {effect = sm.effect.createEffect("flames"), pos = position, direction = data.dir, alive = 0, grav = data.gravity}
	bullet.effect:setPosition( position )
	bullet.effect:setVelocity( bullet.direction)
	bullet.effect:start()
	table.insert(self.bullets, bullet)
end

function flamethrower.client_onUpdate( self, deltaTime ) -- animation of shooting flame & trigger
	self.time = self.time + deltaTime
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() then
			if not self.shooteffect:isPlaying() or self.time > 0.8 then
				self.shooteffect:setOffsetPosition( sm.vec3.new( -5/4, 1/6.5, -1/100 ))
				self.shooteffect:start()
				self.time = 0
			end
		else
			if self.shooteffect:isPlaying() then
				self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
				self.shooteffect:stop()
			end
		end
	end
	if self.boltValue > 0.0 and (not parent or not parent:isActive()) then
		self.boltValue = self.boltValue - deltaTime * 10
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
end

function flamethrower.client_spawnfire(self, data)  -- the network link to send fire to clients
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
		firetype = character
		density = flamedata.fire_density_character
	elseif result.type == "body" then
		if tostring(result:getShape().shapeUuid) == "0987b4fe-18fb-4c85-9238-026f204d00e8" --[[fuse]] then
			firetype = shape
			density = flamedata.fire_density_fuse
		else
			firetype = shape
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
			fire.effect:setPosition(sm.vec3.new(0,0,1000000))
			fire.effect:stop()
			self.fires[k] = nil
		end
	end
end











biglighter = class( nil )
biglighter.maxParentCount = 1
biglighter.maxChildCount = 0
biglighter.connectionInput = sm.interactable.connectionType.logic
biglighter.connectionOutput = sm.interactable.connectionType.none
biglighter.colorNormal = sm.color.new( 0x009999ff  )
biglighter.colorHighlight = sm.color.new( 0x11B2B2ff  )
biglighter.poseWeightCount = 1
biglighter.fireDelay = 3 --ticks
biglighter.bulletlivetime = 1.8
biglighter.firetime = 7

function biglighter.server_onCreate( self ) 
	self:server_init()
end

function biglighter.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function biglighter.server_onRefresh( self )
	self:server_init()
end

function biglighter.server_onFixedUpdate( self, timeStep )
	if not self.canFire then
		self.fireDelayProgress = self.fireDelayProgress + 1
		if self.fireDelayProgress >= self.fireDelay then
			self.fireDelayProgress = 0
			self.canFire = true	
		end
	end
	self:server_tryFire()
	local parent = self.interactable:getSingleParent()
	if parent then
		self.parentActive = parent:isActive()
	end
	for k, fire in pairs(self.fires) do
		if fire then
			if fire.alive + timeStep > fire.lifetime and not fire.done then
				--position, level, destructionRadius, impulseRadius, magnitude
				sm.physics.explode( fire.pos, 4, 0.2, 0.1, 0.1)
				fire.done = true
			end
		end
	end
end



function biglighter.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and self.canFire then
			self.canFire = false
			
			-- fire (sync send, async behaviour)
			local dir = sm.noise.gunSpread(-self.shape.right, 30 )*3
			local hit, result =  sm.physics.raycast( self.shape.worldPosition, self.shape.worldPosition + dir )
			if hit then
				server_createfire(self, nil , result, false, false)
			end
		end
	end
	server_fireSpread(self, dt) -- calc fireSpread and spawn fires
end

-- Client

function biglighter.client_onCreate( self )
	self:client_init()
end
function biglighter.client_onRefresh(self)
	--self:client_init()
end
function biglighter.client_init(self)
	self.boltValue = 0.0
	self.fires = {}
	self.shooteffect = sm.effect.createEffect("flame", self.interactable)
	self.shooteffect:setOffsetRotation(  sm.vec3.getRotation(sm.vec3.new( 1, 0, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:setOffsetPosition( sm.vec3.new( -5/4, 1/13, -1/100 ))
	self.time = 0
end


function biglighter.client_onFixedUpdate( self, dt )
	firebehaviour(self, dt)
	
	local x = 0
	for k, v in pairs(self.fires) do x = x + 1 end
	--print(x) 
end


function biglighter.client_onDestroy(self)
	for k, fire in pairs(self.fires) do
		fire.effect:setPosition(sm.vec3.new(0,0,1000000))
		fire.effect:stop()
		self.fires[k] = nil
	end
	self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
	self.shooteffect:stop()
end

function biglighter.client_onUpdate( self, deltaTime ) -- animation of shooting flame & trigger
	self.time = self.time + deltaTime
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() then
			if not self.shooteffect:isPlaying() or self.time > 0.8 then
				self.shooteffect:setOffsetPosition( sm.vec3.new( -5/4, 1/13, -1/100 ))
				self.shooteffect:start()
				self.time = 0
			end
		else
			if self.shooteffect:isPlaying() then
				self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
				self.shooteffect:stop()
			end
		end
	end
	if self.boltValue > 0.0 and (not parent or not parent:isActive()) then
		self.boltValue = self.boltValue - deltaTime * 10
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
end

function biglighter.client_spawnfire(self, data)  -- the network link to send fire to clients
	spawnfire(self, data.position, data.target, data.oil)
end



