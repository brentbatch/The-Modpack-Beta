--[[
	Copyright (c) 2019 Brent Batch
	Contact: Brent Batch#9261 on discord
]]--


local reload = customFire and customFire.client_reload -- gets old already existing scriptclass from before reload if it exists. (exec 'reload()' at the end of this script tho)


customFire = {} -- MANAGER

customFire.server_queued_fire = {}
customFire.server_queued_water = {}
customFire.server_queued_steam = {}
customFire.fires = {}
customFire.fires_chunked = {} -- for water to interact with.
customFire.waters = {}
customFire.steam = {} -- with temperature

--[[fire:
		effect
		type = "body", "character", "static", "dynamic"
		spreadFactor -- chance to spread
		target = character / body / static / false
		lifetime
		friction
		gravity
		position
		velocity
		intensity -- depends on density
		
		
]]
--[[water:
		type = "dynamic", "flowing"
		effect
		lifetime -- goes down when touching terrain
		friction
		gravity
		position
		velocity


]]
--[[steam: -- 1 raycast up , use normal to shift, also 4 more raycasts slanted up to avoid clipping walls
		effect
		temperature
		 -- no lifetime, condense into water when 
		

]]


local amountFires = 0

-- API for scripted parts:
-- scripted parts will perform the following functions to initialize the above globalscript
function customFire.server_spawnFire(self, data)
	if not sm.isHost then return end
	data = data or {}
	
	local localPosition = 	data.localPosition or 	false
	local localVelocity = 	data.localVelocity or 	false
	local position = 		data.position or 		assert(false, "position parameter needs to be filled in")
	local velocity = 		data.velocity or 		assert(false, "velocity parameter needs to be filled in")
	
	local gravity = 		data.gravity or			(sm.isServerMode() and sm.physics.getGravity() or 10)
	local friction = 		data.friction or 		0.003 -- 0.3%
	local effect = 			data.effect or 			"flameslight"
	local intensity =		data.intensity or		0.6
	
	local lifetime = 		data.lifetime or 		math.random(30,70)/10 -- 3-7 sec
	local oil = 			data.oil or 			false
	local source = 			data.source or 			"part" -- "part", "oilfire", "characterfire", "fire" -- decides spread of other fires
	local priority = 		data.priority or 		false -- in case density check needs to be overruled. 
	
	local spreadFactor = 	data.spreadFactor or 	30 -- %
	local spreadDistance =	data.spreadDistance or 	0.7 -- meters
	
	local level =			data.destructionLevel or 	4
	local destrRadius = 	data.destructionRadius or   0.35
	local impulseRadius =	data.impulseRadius or       0.1
	local magnitude =		data.magnitude or           5
	--						data.raycast
	
	
	local raycast = data.raycast
	
	if raycast and raycast.valid then
		position = raycast.pointWorld
	end
	
	amountFires = 0
	
	local density = 0
	local smallestDistance = 100
	
	local characterDuplicateCheck = raycast and raycast.type == "character"
	local character = characterDuplicateCheck and raycast:getCharacter()
	characterDuplicateCheck = (character and sm.exists(character))
	local characterId = characterDuplicateCheck and character.id
	local isCharacterDuplicate = false
	
	local superSmallDistance = 0 
	
	local light = true
	
	local temperatureEfficiency = 1
	local inverseDistanceSum = 1
	
	local soundDensity = 1
	
	for k, v in pairs(customFire.fires) do
		-- only attached fires, terrain or to body/character
		if (v.type == "static" or (v.target and sm.exists(v.target))) and v.lifetime > 1.5 then -- 1.5 sec overlap
		
			local distance = (position - v.position):length()
			if distance > 0.1 then -- don't let really close fires throw this out of wack. -> 0.1
				density = density + 1/(distance)
				if distance < smallestDistance then 
					smallestDistance = distance
				end
				local efficiency = v.temperature / v.targetTemperature
				temperatureEfficiency = temperatureEfficiency + efficiency / distance
				inverseDistanceSum = inverseDistanceSum + 1 / distance -- makes it so distant fires have less effect on this efficiency
			else
				superSmallDistance = superSmallDistance + 1
				if superSmallDistance == 2 then 
					return --print('super small distance violation', superSmallDistance)
				end
			end
			
			if v.light and distance < 0.6 then
				light = false
			end
			if v.sounds then
				soundDensity = soundDensity + 1/distance
			end
		end
		if characterDuplicateCheck and
			v.type == "character" and v.target and sm.exists(v.target) and 
			v.target.id == characterId then
				isCharacterDuplicate = k
				break -- can break
		end
		amountFires = amountFires + 1
	end
	
	local efficiency = temperatureEfficiency / inverseDistanceSum
	
	if superSmallDistance >= 2 then --print('super small distance violation', superSmallDistance)
		return -- can't allow this.
	end 
	
	local sound = (soundDensity < 4) and density/3 or false -- using density for volume
	
	--print("amountFires",amountFires, density)
	if amountFires > 420 then return end -- hard limit (particles don't work after this)
	
	if raycast and raycast.valid then
	
		if raycast.type == "body" then
		
			local target = raycast:getShape()
			if not target or not sm.exists(target) then return end
			
			local material = target:getMaterial()
			local shapeUuid = tostring(target.shapeUuid)
			local smallBodyMass = raycast:getBody().mass < 60
			
			
			local fuse = shapeUuid == "0987b4fe-18fb-4c85-9238-026f204d00e8"
			if shapeUuid == "82e504c3-4317-4953-8c70-e594f7397b23" --[[campfire]] and sm.isServerMode() then
				target.interactable.active = true
				return
			end
			
			
			if not priority then
				if smallBodyMass then
					if smallestDistance < 0.12 then return end  --print(smallestDistance,"< 0.4 distance violated - 'body' fire spawn halted")
				else
					if smallestDistance < 0.3 then return end  --print(smallestDistance,"< 0.4 distance violated - 'body' fire spawn halted") 
				end
				
				if density > 30 then  --print(density, "> 15 density violated - 'body' fire spawn halted")
					return
				end
				
				if not fuse and not oil then
					local materialCatchChance;
					if smallBodyMass then
						materialCatchChance = ({ Cardboard = 90, Plastic = 85, Wood = 80})[material] or 1
					else
						materialCatchChance = ({ Cardboard = 80, Plastic = 65, Wood = 50})[material] or 1
					end
					if math.random(100) > materialCatchChance then 
						return
					end
				end
			else
				-- priority fire!!!
				if not smallBodyMass and not fuse and not oil then
					local materialCatchChance = ({ Cardboard = 90, Plastic = 85, Wood = 80})[material] or 5
					if math.random(100) > materialCatchChance then
						return 
					end
				end
			end
			
			if not data.lifetime then -- not determined by source
				lifetime = fuse and 3 or ({ Cardboard = 4, Plastic = 7, Wood = 12})[material] or lifetime
				lifetime = math.random((lifetime-3)*100, (lifetime+4)*100)/100
			end
			spreadFactor = data.spreadFactor or math.random(5,40)
			spreadDistance = data.spreadDistance or math.random(4,11)/10
			
			if oil or fuse then
				spreadFactor = data.spreadFactor or math.random(40,70)
				spreadDistance = data.spreadDistance or math.random(7,20)/10
			end
			
			if smallBodyMass then
				destrRadius = 0.4 -- bigger explosion for small shit (x1.5)
				lifetime = lifetime > 3 and lifetime - 2 or lifetime
				spreadDistance = spreadDistance * 1.7
			end
			
			local pointLocal = target:transformPoint(raycast.pointWorld)
			local normalLocal = raycast.normalLocal
			

			--intensity = sm.util.clamp(0.6/(density/3 + 0.1),0,0.6)
			local temperature = (density * 10 + 500) * efficiency
			
			local thisThing = oil and "oilfire" or "fire"  --"part", "oilfire", "fire"
			local oil = (source == "part" and oil)
			
			table.insert(customFire.server_queued_fire, {"body", target, pointLocal, normalLocal, lifetime, temperature, spreadFactor, spreadDistance, oil, thisThing, gravity, friction, effect, intensity, level, destrRadius, impulseRadius, magnitude, light, sound})
			
			
		elseif raycast.type == "character" then
		
			if not oil and math.random(100) > 30 then return end -- catch chance
		
			local target = raycast:getCharacter()
			if not target or not sm.exists(target) then return end
			
			lifetime = math.random(100, 150)/10 -- 10-15 sec
			
			if oil then
				spreadFactor = math.random(20,60)
				spreadDistance = 1.5
			else
				spreadFactor = math.random(5,40)
				spreadDistance = 1
			end
			
			local thisThing = "characterfire" --"part", "oilfire", , "fire"
			local oil = (source == "part" and oil)
			local temperature = (density * 10 + 500) * efficiency
			
			-- isCharacterDuplicate -- contains key if lighting player on fire that is already on fire
			table.insert(customFire.server_queued_fire, {"character", target, lifetime, temperature, spreadFactor, spreadDistance, oil, thisThing, isCharacterDuplicate, gravity, friction, effect, intensity, level, destrRadius, impulseRadius, magnitude, light, sound})
			
		elseif raycast.type == "terrainSurface" or raycast.type == "terrainAsset" then
			
			if oil then
				spreadFactor = math.random(15,50)
			else
				if math.random(100) > 15 then -- catch chance
					return 
				end
				if density > 15 then   --print(density, "> 15 density violated - 'terrain' fire spawn halted")
					return 
				end
				if smallestDistance < 0.7 then   --print(smallestDistance,"< 0.4 distance violated - 'terrain' fire spawn halted")
					return 
				end
				spreadFactor = math.random(3,15)
			end
			local normalWorld = raycast.normalWorld
			
			local thisThing = "fire" --"part", "oilfire", , "fire"
			local oil = (source == "part" and oil)
			local temperature = (density * 10 + 500) * efficiency
			
			table.insert(customFire.server_queued_fire, {"static", position, normalWorld, lifetime, temperature, spreadFactor, spreadDistance, oil, thisThing, gravity, friction, effect, intensity, level, destrRadius, impulseRadius, magnitude, light, sound})
		else
			-- unsupported surface (lift, vision, joint)
			return
		end
	else
		-- no raycast hit, = projectile fire
		if (localPosition or localVelocity) and (not self.shape or not sm.exists(self.shape)) then return end
		
		local thisThing = source --"part", "oilfire", "fire"
		local oil = (source == "part" and oil)
		
		local temperature = (density * 10 + 500) * efficiency
			
		table.insert(customFire.server_queued_fire, {"dynamic", self.shape, localPosition, localVelocity, position, velocity, lifetime, temperature, oil, thisThing, gravity, friction, effect, intensity, level, destrRadius, impulseRadius, magnitude, light, sound})
	end
end


function customFire.server_spawnWater(self, data)
	if not sm.isHost then return end
	
	--[[data:
		type = "dynamic", "flowing" -- dynamic = thrown in air
		power = 120 -- amount per tick it removes from fire temperature
		radius = 1.2
		lifetime -- goes down when touching terrain
		position 
		velocity
		friction
		gravity
		effect
	]]
	local dynamic = 	data.dynamic or 	false
	local position = 	data.position or 	assert(false, "position parameter needs to be filled in")
	local velocity = 	data.velocity or 	sm.vec3.new(0,0,0)
	local lifetime = 	data.lifetime or 	20
	local power = 		data.power or 		200
	local radius = 		data.radius or 		16 -- 4 meters (length2)
	local intensity = 	data.intensity or 	1

	for k, fire in pairs(customFire.fires) do
		local distance = (position - fire.position):length2()
		if distance < radius then
			local effectiveness = intensity / ( 1 + distance )
			fire.temperature = fire.temperature - effectiveness * power
		end
	end
		
	--local water = {dynamic, position, velocity, lifetime, power, radius, intensity}
	--table.insert( customFire.server_queued_water, water)
end


function customFire.server_spawnSteam(self, data)
	if not sm.isHost then return end
	
	
end


















function customFire.server_onCreate(self, ...)
	--print('customFire.client_onCreate')
end

function customFire.server_onFixedUpdate(self, dt)

	for k, data in pairs(self.server_queued_fire) do -- pipe it to the clients
		self.network:sendToClients("client_createFire", data)
		self.server_queued_fire[k] = nil
	end
	
	for k, data in pairs(self.server_queued_water) do -- pipe it to the clients
		local dynamic, position, velocity, lifetime, power, radius, intensity = unpack(data)
		
		if dynamic then
			--self.network:sendToClients("client_createWater", data)
		end
		
		self.server_queued_water[k] = nil
	end
	
	local doFireSpread = amountFires < 350
	for k, fire in pairs(self.fires) do
		if doFireSpread then 
			self:server_fireSpread(k, fire, dt) 
		end
		if fire.temperature < 0 then
			self.network:sendToClients("client_killFire", {k})
		end
		fire.temperature = sm.util.lerp(fire.temperature, fire.targetTemperature, dt)
		if fire.lifetime <= dt and not fire.done then
			sm.physics.explode( fire.position, fire.level, fire.destructionRadius, fire.impulseRadius ,fire.magnitude )
			fire.done = true
		end
	end
end


function customFire.server_fireSpread(self, key, fire, dt)
	
	if fire.type == "body" and not sm.exists(fire.target) then
		--print('fire ded')
		for x = 1,10 do -- try 10x
			local normal = fire.normalWorld
			local random = sm.vec3.random() * math.random(25)/20 -- 0.05-1.25 meters
			local tangent = random - normal * random:dot(normal)
			local hit, result = sm.physics.raycast(
				fire.position + normal * 0.25 + tangent,
				fire.position - normal * 0.5 + tangent * 0.3
			)
			if (hit and result.type == "body") then
				--print('found place to nest new', hit, result)
				customFire.server_spawnFire({}, {
					position = fire.position, 
					velocity = fire.velocity,
					priority = true,
					lifetime = fire.lifetime + 0.5,
					raycast = result,
					source = fire.source
				})
				fire.done = true -- found new place to nest. no need to explode.
				return -- no more firespread, target ded anyway
			end
		end
	end
	
	if fire.type == "dynamic" or math.random(100) > fire.spreadFactor then return end
	local randomsign = math.random(1,2) == 1 and 1 or -1
	
	-- randomspread:
	if fire.type == "body" and fire.target and sm.exists(fire.target) then
		if fire.lifetime > 3 then return end
		local position = fire.position
		local normal = fire.normalWorld
			
		local random = sm.vec3.random() * fire.spreadDistance
		local tangent = random - normal * random:dot(normal)
		
		local hit, result = sm.physics.raycast( 
			position + normal * 0.35 + tangent,
			position - normal * 0.5 + tangent * 0.5) -- can 'climb' around corners
		if not hit then
			hit, result = sm.physics.raycast( -- no hit, try hit other side or something
				position,
				position + sm.noise.gunSpread(normal, 30) )
		end
		if hit or math.random(1000) == 1 then -- small chance it creates a fire, even if no ray hit  ('sparkles')
			customFire.server_spawnFire({}, {
				position = (result.valid and result.pointWorld) or fire.position, 
				velocity = fire.target.velocity + tangent * 3 + sm.vec3.new(0,0,5),
				raycast = result,
				source = fire.source
			})
		end
		
	elseif fire.type == "character" and fire.target and sm.exists(fire.target) then
		local position = fire.target.worldPosition
		local normal = sm.vec3.new(0,0, randomsign) -- up or down ish
		
		local random = sm.vec3.random() * fire.spreadDistance
		local tangent = random - normal * random:dot(normal)
		local hit, result = sm.physics.raycast( 
			position, 
			position + normal + sm.noise.gunSpread(tangent, 90) )
		if hit and 
			(
				result.type ~= "character" or -- don't hit itself.
				result:getCharacter().id ~= fire.target.id
			) then
			customFire.server_spawnFire({}, {
				position = result.pointWorld, 
				velocity = fire.velocity,
				raycast = result,
				source = fire.source
			})
		end
		
	elseif fire.type == "static" then
		local position = fire.position
		local normal = sm.vec3.new(0,0,1)
		
		local random = sm.vec3.random()  * fire.spreadDistance
		local tangent = random - normal * random:dot(normal)
		
		local hit, result = sm.physics.raycast( 
			position + normal,
			position + normal * 0.5 + sm.noise.gunSpread(tangent, 15) 
		)
		if hit then
			customFire.server_spawnFire({}, {
				position = result.pointWorld, 
				velocity = fire.velocity,
				raycast = result,
				source = fire.source
			})
		end
		
	end
	
	-- ALSO: upwards draft of fire:
	if math.random(200) == 1 then -- TODO: instead do: 'track shapes and give them a timer/temperature?'
		--print('updraft')
		local position = fire.position
		local hit, result = sm.physics.raycast( 
			position + sm.vec3.new(0,0,0.4),
			position + sm.noise.gunSpread(sm.vec3.new(0,0,4), 20) )
			
		if hit and math.random(1,math.ceil(sm.util.clamp(16*result.fraction, 1, 16))) == 1 then
			--print('updraft successfull')
			customFire.server_spawnFire({}, {
				position = result.pointWorld, 
				velocity = fire.velocity,
				raycast = result,
				source = fire.source
			})
		end
	end


end




-- CLIENT:

function customFire.client_onCreate(self, ...)
	--print('customFire.client_onCreate')
	--ask server for existing projectiles ? 
end

function customFire.client_killFire(self, data)
	local id = unpack(data)
	local fire = customFire.fires[id]
	if not fire then return end
	local position = fire.position
	--sm.effect.playEffect("Extinguished_fire", position)
	--sm.particle.createParticle( "steam", position, nil, sm.color.new(0.8,0.8,1.0))
	if fire.sounds then
		for k, eff in pairs(fire.sounds) do
			eff:stop()
		end
	end
	fire.effect:stop()
	customFire.fires[id] = nil
end

function customFire.client_createFire(self, data)
	local fireType = data[1]
	
	local target, pointLocal, normalLocal, lifetime, temperature, spreadFactor, spreadDistance, oil, thisThing, gravity, friction, effect, intensity, level, destrRadius, impulseRadius, magnitude, light, sound;
	local isCharacterDuplicate;
	local position, normalWorld;
	local sourceShape, localPosition, localVelocity, velocity;	
	-- define local vars ^
	
	local projectile = {}
	
	
	if fireType == "body" then
		fireType, target, pointLocal, normalLocal, lifetime, temperature, spreadFactor, spreadDistance, oil, thisThing, gravity, friction, effect, intensity, level, destrRadius, impulseRadius, magnitude, light, sound = unpack(data)
		
			if not target or not sm.exists(target) then return end
			normalWorld = target.worldRotation * normalLocal
			position = target.worldPosition + target.worldRotation * pointLocal
			velocity = target.velocity
		
	elseif fireType == "character" then
		fireType, target, lifetime, temperature, spreadFactor, spreadDistance, oil, thisThing, isCharacterDuplicate, gravity, friction, effect, intensity, level, destrRadius, impulseRadius, magnitude, light, sound = unpack(data)
		
			if not target or not sm.exists(target) then return end
			position = target.worldPosition
			velocity = target.velocity
			
			if isCharacterDuplicate then -- prevent dupe fire on a character
				local firstFire = self.fires[isCharacterDuplicate]
				if firstFire then
					firstFire.lifetime = lifetime
					return
				end
			end
		
	elseif fireType == "static" then
		fireType, position, normalWorld, lifetime, temperature, spreadFactor, spreadDistance, oil, thisThing, gravity, friction, effect, intensity, level, destrRadius, impulseRadius, magnitude, light, sound = unpack(data)
		
			position = position + normalWorld/20
			velocity = sm.vec3.zero()
		
	elseif fireType == "dynamic" then
		fireType, sourceShape, localPosition, localVelocity, position, velocity, lifetime, temperature, oil, thisThing, gravity, friction, effect, level, intensity, destrRadius, impulseRadius, magnitude, light, sound = unpack(data)
		
			if (localPosition or localVelocity) and
			(not sourceShape or not sm.exists(sourceShape)) then 
				return  -- can't do local if there is no shape
			end
			
			if localPosition then
				position = sourceShape.worldPosition + sourceShape.worldRotation * position
			end
			if localVelocity then
				velocity = sourceShape.worldRotation * velocity
			end
	else 
		-- network call got corrupted
		return
	end
	
	projectile.type = fireType
	projectile.target = target -- nil for dynamic and static
	
	projectile.position = position
	projectile.velocity = velocity
	
	projectile.pointLocal = pointLocal -- only for "body"
	projectile.normalLocal = normalLocal -- only for "body"
	
	projectile.normalWorld = normalWorld -- only for "static" and "body"
	
	projectile.lifetime = lifetime
	projectile.temperature = temperature
	projectile.targetTemperature = temperature
	projectile.spreadFactor = spreadFactor -- nil for dynamic
	projectile.spreadDistance = spreadDistance -- nil for dynamic
	projectile.oil = oil
	projectile.source = thisThing
	projectile.gravity = gravity
	projectile.friction = friction
	
	projectile.light = light
	local effect = sm.effect.createEffect( light and "flameslight" or "flames")
	effect:setPosition(position)
	effect:setVelocity(velocity)
	--effect:setParameter("intensity", intensity)
	effect:start()
	projectile.effect = effect
	
	if sound and false then -- effects not included in this mod. also: todo: use vanilla scrap mechanic sound
		local volume = math.min(sound/2 + 1,3) -- 1-30
		projectile.sounds = {}
		local sounds = {
			{sm.effect.createEffect("fire_rolling_sound"),  1, 		16, 1 }, -- snow on tv
			{sm.effect.createEffect("fire_rolling_sound"),  0.03,	50, 8 }, -- concrete grinding
			{sm.effect.createEffect("fire_collision_sound"), 1, 		3, 0 }, -- wood popping
			{sm.effect.createEffect("fire_collision_sound"), 1, 		5, 6 } -- lots of small stones falling
		}
		for k, v in pairs(sounds) do 
			local eff, size, velocity, material = unpack(v)
			eff:setParameter("Size",     size)
			eff:setParameter("Velocity_max_50", velocity*volume)
			eff:setParameter("Material", material)
			eff:setPosition(projectile.position)
			eff:setVelocity(projectile.velocity)
			eff:start()
			table.insert(projectile.sounds, eff)
		end
	end
	
	projectile.level = level
	projectile.intensity = intensity
	projectile.destructionRadius = destrRadius
	projectile.impulseRadius = impulseRadius
	projectile.magnitude = magnitude
	
	--print('client created fire:\n',{lifetime = lifetime, fireType = fireType, position = position, source = source})
	
	table.insert(customFire.fires, projectile)
end


function customFire.client_onFixedUpdate(self,dt)

	for k, fire in pairs(self.fires) do
		fire.lifetime = fire.lifetime - dt
		
		if fire.type == "body" then 
		
			if fire.target and sm.exists(fire.target) then
				fire.position = fire.target.worldPosition + fire.target.worldRotation * fire.pointLocal + fire.normalWorld/8
				fire.velocity = fire.target.velocity
				fire.normalWorld = fire.target.worldRotation * fire.normalLocal
				
			else-- DEAD
				fire.lifetime = 0
			end
			
		elseif fire.type == "character" then
			if fire.target and sm.exists(fire.target) then
				fire.velocity = fire.target.velocity
				fire.position = fire.target.worldPosition + fire.velocity * dt
				fire.lifetime = fire.lifetime - fire.velocity:length() / 200
			else
				fire.lifetime = 0
			end
		elseif fire.type == "dynamic" then
					
			-- has been tested: velocity first, then position
			fire.velocity = fire.velocity*(1 - fire.friction) - sm.vec3.new(0, 0, fire.gravity*dt)
			fire.position = fire.position + fire.velocity*dt
			
			local hit, result = sm.physics.raycast(fire.position, fire.position + fire.velocity * dt * 1.1)
			if hit then
				customFire.server_spawnFire({}, {
					position = fire.position, 
					velocity = fire.velocity,
					raycast = result,
					oil = fire.oil,
					source = fire.source
				})
				fire.position = result.pointWorld
				fire.velocity = sm.vec3.zero()
				
				fire.lifetime = -1 -- no explosion on server
			end
		end
			
		
		fire.effect:setPosition(fire.position)
		fire.effect:setVelocity(fire.velocity)
		
		if fire.sounds then
			for k, eff in pairs(fire.sounds) do
				eff:setPosition(fire.position)
				eff:setVelocity(fire.velocity)
			end
		end
		
		if fire.lifetime <= 0 then
			fire.effect:stop()
			if fire.sounds then
				for k, eff in pairs(fire.sounds) do
					eff:stop()
				end
			end
			self.fires[k] = nil
		end
	end
end


function customFire.client_onRefresh(self)
	--print('customFire.client_onRefresh')
end

function customFire.client_onDestroy(self)
	print('customFire onDestroy')
	for k, fire in pairs(self.fires) do
		if fire.sounds then
			for k, eff in pairs(fire.sounds) do
				eff:stop()
			end
		end
		fire.effect:stop()
		fire = nil
	end
end




if reload then reload() end -- makes globalscript reload this properly when this file gets updated.