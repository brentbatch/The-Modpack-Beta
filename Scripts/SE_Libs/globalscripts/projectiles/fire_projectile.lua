--[[
	Copyright (c) 2019 Scrap Essentials Team
]]--

-- PLEASE DO READ MY COMMENTS IF YOU PLAN ON EDITING AND USING THIS.
-->> DM ME ON DISCORD FOR PERMISSION OF USAGE: Brent Batch#9261 https://discord.gg/MhTK6DX

fire_projectile = {}

local amountFires = 0

-- happens before the other functions, can return 'false' to prevent this fire from initializing.
function fire_projectile.server_onCreate(self, otherProjectiles, position, velocity, raycastResult, lifetime, oil, gravity, friction--[[, ...]])
	--print('fire_projectile.server_onCreate')
	assert(position, "server_spawnProjectile requires vec3 position as parameter #2")
	assert(velocity, "server_spawnProjectile requires vec3 velocity as parameter #3")
	
	local position = raycastResult and raycastResult.valid and raycastResult.pointWorld or position
	
	if amountFires > 80 then 
		--sm.log.error('[time:'..sm.game.getCurrentTick()..'] Fire: TOO MANY FIRES ('..amountFires..')') 
		return false 
	end
	
	local density = 0
	local smallestDistance = 100
	local smallestSolidDistance = 100
	local solidFireDensity = 0 -- fires that are attached, doesn't count fires being 'shot'
	
	for k, v in pairs(otherProjectiles) do
		if v.fire and (not v.target or sm.exists(v.target) and v.alive < v.lifetime - 0.5) then -- no invalid/about to die fires in this calc
			local distance = (position - v.position):length2()
			if distance > 0.0001 then
				density = density + 1/(distance)
				if distance < smallestDistance then smallestDistance = distance end
				if v.type then
					solidFireDensity = solidFireDensity + 1/(distance)
					if distance < smallestSolidDistance then smallestSolidDistance = distance end
				end
			end
		end
	end
	--print(amountFires,'density',density)
	
	-- defaults:
	self.fire = true -- NOTE: all projectiles with the 'fire' property NEED: "type", "alive", "lifetime", "position" !!!!!
	self.friction = friction or 0.003
	self.gravity = gravity or 10
	self.lifetime = math.random(100,300)/100-- sec
	self.position = position
	self.velocity = velocity
	self.spread_chance = 30 -- %
	self.intensity = 0.6
	
	-- chances, density checks, & handling raycastResult:
	
	if raycastResult and raycastResult.valid then 
		--devPrint('valid raycast', raycastResult)
		if raycastResult.type == "body" then
			
			--devPrint('shape', density)
			if smallestSolidDistance < 0.7 or -- fire needs to be at least 2 blocks away
				math.random(100) > 80 and not oil or -- % chance,  density has to be below
				solidFireDensity > (oil and 8 or 5) then 
				--devPrint(smallestSolidDistance, solidFireDensity)
				return false 
			end
			
			local shape = raycastResult:getShape()
			self.target = shape -- position can be calculated using pointLocal and target
			if not sm.exists(self.target) then return false end
			
			if not oil and math.random(100) > (({ Cardboard = 95, Plastic = 85, Wood = 75})[shape:getMaterial()] or 10) then 
				return false -- extra special chances per material
			end
			
			self.velocity = self.target.velocity
			self.pointLocal = shape:transformPoint(raycastResult.pointWorld - raycastResult.normalWorld/8)
			self.normalWorld = raycastResult.normalWorld
			self.normalLocal = raycastResult.normalLocal
			self.lifetime = 
				(tostring(shape.shapeUuid) == "0987b4fe-18fb-4c85-9238-026f204d00e8" --[[fuse]] and 8) or
				({ Cardboard = 6, Plastic = 8, Wood = 12})[shape:getMaterial()] or 3
			self.lifetime = math.random(self.lifetime*100 - 200, self.lifetime*100 + 200)/100 -- between +2,-2 sec
			self.type = "body"
			self.spread_chance = math.random(30,60) -- %
			self.intensity = sm.util.clamp(0.6/(density/3 + 0.1),0,0.6)
			
		elseif raycastResult.type == "terrainSurface" or raycastResult.type == "terrainAsset" then
		
			--devPrint('terrain', solidFireDensity, oil)
			if math.random(100) > 15 and not oil or solidFireDensity > 3 then return false end -- % chance,  density has to be below
			self.velocity = sm.vec3.zero()
			self.friction = 0.9
			self.gravity = 0
			self.type = "terrain"
			self.spread_chance = math.random(1,20) -- %
			
		elseif raycastResult.type == "character" then
		
			--devPrint('character')
			if math.random(100) > 30 and not oil then return false end -- % chance,  no density check as character client_onCreate to fix it. (has to be fixed on client btw! (sync!))
			self.target = raycastResult:getCharacter() -- position from target
			if not sm.exists(self.target) then return false end
			self.velocity = self.target.velocity
			self.position = self.target.worldPosition
			self.lifetime = math.random(1000,1500)/100
			self.type = "character"
			self.spread_chance = math.random(30,50) -- %
			
		else
			--sm.log.error('Fire: Hit unknown entity, cannot spawn fire here')
			return false
		end
	else
		--devPrint('air')
		if math.random(100) > 80 or density > 7 then return false end -- 80% chance,  density has to be below 3 fires/m²
		self.lifetime = math.random(200,500)/100 -- seconds
		self.spread_chance = math.random(1,5)
	end

	self.lifetime = lifetime or self.lifetime -- lifetime can be overwritten
	self.alive = 0
end

-- when server_onCreate is defined: server 'self' will be copied to client and client gets no extra args.
function fire_projectile.client_onCreate(self, otherProjectiles)
	amountFires = amountFires + 1
	--print('fire_projectile.client_onCreate')
	--devPrint('creating effect', self.position, self.velocity)
	self.effect = sm.effect.createEffect("flames")
	self.effect:setPosition(self.position)
	self.effect:setVelocity(self.velocity)
	self.effect:setParameter("intensity", self.intensity)
	self.effect:start()
	
	if self.type == "character" then
		for k, v in pairs(otherProjectiles) do
			if v.fire and 
				v.type == "character" and 
				v.uuid ~= self.uuid and 
				v.target and sm.exists(v.target) and v.target.id == self.target.id and
				v.alive < v.lifetime - 0.1 then
				-- found a fire that already targets this character and is short lived
				-- make it live longer
				v.alive = 0
				self:destroy()
				--devPrint('CHARACTER: OPTMIZATION')
				return
			end
		end
	end
end


function fire_projectile.server_onFixedUpdate(self, dt)
	--print('fire_projectile.server_onFixedUpdate')
	if self.alive > self.lifetime - dt then
		sm.physics.explode( self.position, 4, 0.4, 0.1, 0.1)
	end
	
	if self.type == "body" and not sm.exists(self.target) then
		--devPrint('serverpanic')
		for x=1,4 do
			local normal = self.normalWorld
			local random = sm.vec3.random()
			local tangent = random - normal * random:dot(normal)
			local hit, result = sm.physics.raycast( 
				self.position + normal * 0.25 + tangent * 0.5,
				self.position - normal * 0.5 + tangent
			)
			if (hit and result.type == "body") then
				--devPrint('client, try to spawn new', hit, result)
				Projectile.server_spawnProjectile("fire_projectile", -- host hack, goes to server_
					self.position, 
					self.velocity,
					result,
					nil, true-- overwrite lifetime
				)
				return
			end
		end
		return
	end
	
	-- TODO: FIRESPREAD: write material check, only light wood, plastic or cardboard
	
	
	-- FIRESPREAD: 
	
	if amountFires < 75 and -- firespread stops at 230 fires
		math.random(100) < self.spread_chance then
	
		local randomsign = ({-1,1})[math.random(1,2)]
	
		if self.type == "body" then
			local position = self.target.worldPosition + self.target.worldRotation * self.pointLocal
			local normal = self.target.worldRotation * self.normalLocal
				
			local random = sm.vec3.random() * 1.1
			local tangent = random - normal * random:dot(normal)
			local hit, result = sm.physics.raycast( 
				position + normal * 0.4 + tangent * 0.5, 
				position - normal * 0.5 + tangent )
			if not hit then
				hit, result = sm.physics.raycast( 
					position, 
					position + sm.noise.gunSpread(normal, 30) )
			end
			if (hit and 
					(
						result.type ~= "body" or -- if it hits a body, certain materials catch fires more easely
						(
							result.type == "body" and 
							math.random(100) < (({ Cardboard = 95, Plastic = 85, Wood = 75})[result:getShape():getMaterial()] or 10)
						)
					)
				) or 
				(not hit and math.random(900) == 1) then -- small chance it creates a fire, even if no ray hit  ('sparkles')
				
				Projectile.server_spawnProjectile("fire_projectile",
					(result.valid and result.pointWorld) or self.position, 
					self.target.velocity + tangent * 3 + sm.vec3.new(0,0,5),
					result
				)
			end
			
		elseif self.type == "character" then
			local position = self.target.worldPosition
			local normal = sm.vec3.new(0,0, randomsign) -- up or down ish
			
			local random = sm.vec3.random() * 0.8
			local tangent = random - normal * random:dot(normal)
			local hit, result = sm.physics.raycast( 
				position, 
				position + normal + sm.noise.gunSpread(tangent, 40) )
			if hit and 
				(not result.valid or 
					result.type ~= "character" or 
					result:getCharacter().id ~= self.target.character.id) then
				Projectile.server_spawnProjectile("fire_projectile",
					result.pointWorld, 
					self.target.velocity,
					result
				)
			end
			
		elseif self.type == "terrain" then
			-- terrain fires don't spread
			
		else -- other fires, prob flying
			local position = self.position
			local normal = self.velocity:length2() > 0.001 and self.velocity:normalize() or sm.vec3.new(0,0,1)
			
			local random = sm.vec3.random() * 2
			local tangent = random - normal * random:dot(normal)
			
			local hit, result = sm.physics.raycast( 
				position,
				position + sm.noise.gunSpread(normal * randomsign, 15) + tangent )
			
			if hit then
				Projectile.server_spawnProjectile("fire_projectile",
					result.pointWorld, 
					self.velocity,
					result
				)
			end
			
		end
		
		-- ALSO: upwards draft of fire:
		if math.random(200) == 1 then -- TODO: instead do: 'track shapes and give them a timer/temperature?'
			--devPrint('updraft')
			local position = self.position
			local hit, result = sm.physics.raycast( 
				position + sm.noise.gunSpread(sm.vec3.new(0,0,0.3),40),
				position + sm.noise.gunSpread(sm.vec3.new(0,0,4), 15) )
				
			if hit and math.random(1,math.ceil(sm.util.clamp(16*result.fraction, 1, 16))) == 1 then
				--devPrint('updraft successfull')
				Projectile.server_spawnProjectile("fire_projectile",
					result.pointWorld, 
					self.velocity,
					result
				)
			end
		end
	end
	
end


function fire_projectile.client_onFixedUpdate(self, dt)

	if self.type == "body" then
		if not sm.exists(self.target) then -- panic
			--devPrint('clientpanic')
			--[[for x= 1,7 do
				local normal = self.normalWorld
				local random = sm.vec3.random()
				local tangent = random - normal * random:dot(normal)
				local hit, result = sm.physics.raycast( 
					self.position + normal * 0.25 + tangent, 
					self.position - normal * 0.5 - tangent * 0.5
				)
				if (hit and result) or x == 7 then
					--devPrint('client, try to spawn new', hit, result)
					Projectile.server_spawnProjectile("fire_projectile", -- host hack, goes to server_
						self.position, 
						self.velocity,
						result,
						self.lifetime - self.alive + 1-- overwrite lifetime
					)
					self:destroy()
					return
				end
			end]]
			self:destroy()
			return
		end
		
		self.normalWorld = self.target.worldRotation * self.normalLocal--keep track of this in case of die
		self.velocity = self.target.velocity
		self.position = self.target.worldPosition + self.target.worldRotation * self.pointLocal
		
	elseif self.type == "character" then
		if not sm.exists(self.target) then self:destroy() return end
		self.velocity = self.target.velocity
		self.position = self.target.worldPosition
		
	else -- flying air
	
		-- has been tested: velocity first, then position
		self.velocity = self.velocity*(1 - self.friction) - sm.vec3.new(0, 0, self.gravity*dt)
		self.position = self.position + self.velocity*dt
		
		local hit, result = sm.physics.raycast(self.position, self.position + self.velocity * dt * 1.1)
		if hit then
			Projectile.server_spawnProjectile("fire_projectile", -- host hack, goes to server_
				self.position, 
				self.velocity,
				result--, nil, result.type == "terrainSurface" or result.type == "terrainAsset" 
			)
			self.effect:setPosition(result.pointWorld)
			self.effect:setVelocity(sm.vec3.zero())
			self:destroy()
		end
	end
		
	self.effect:setPosition(self.position)
	self.effect:setVelocity(self.velocity)
		
	if self.alive > self.lifetime then
		self:destroy()
	end
	self.alive = self.alive + dt
	
end


function fire_projectile.client_onDestroy(self)
	--print('fire_projectile.client_onDestroy')
	if self.effect then self.effect:stop() end
	amountFires = amountFires - 1
end





















