

grenades = class( nil )
grenades.maxParentCount = 1
grenades.maxChildCount = 0
grenades.connectionInput = sm.interactable.connectionType.logic
grenades.connectionOutput = sm.interactable.connectionType.none
grenades.colorNormal = sm.color.new( 0x009999ff  )
grenades.colorHighlight = sm.color.new( 0x11B2B2ff  )
grenades.poseWeightCount = 1
grenades.fireDelay = 20 --ticks
grenades.minForce = 15
grenades.maxForce = 20
grenades.livetime = 5

function grenades.server_onCreate( self ) 
	self:server_init()
end

function grenades.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
	self.livetime = grenades.livetime * (1 + (math.random()-0.5)/10 )
end

function grenades.server_onRefresh( self )
	self:server_init()
end

function grenades.server_onFixedUpdate( self, timeStep )
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
		if bullet then
			if bullet.alive > bullet.livetime then
				--position, level, destructionRadius, impulseRadius, magnitude
				sm.physics.explode( bullet.pos, 6, 2, 4, 20, "CornShot - ExplosionSmall")
				
			end
		end
	end
end

function grenades.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and not self.parentActive and self.canFire then
			self.canFire = false
			
			
			
			local dir = sm.noise.gunSpread( self.shape.up, 1 ) * math.random( self.minForce, self.maxForce ) 
			local extra = dir*dir:dot(self.shape.velocity)*1.5
			if extra:dot(dir) > 0 then dir = dir+ extra end
			self.network:sendToClients( "client_onShoot",  {dir = dir, gravity = sm.physics.getGravity()/10, livetime = grenades.livetime * (1 + (math.random()-0.5)/10 )})
			
			
			local dir = sm.vec3.new( 0.0, 0.0, 1.0 )
			local mass = 50
			local impulse = dir * -dir:normalize() * mass
			sm.physics.applyImpulse( self.shape, impulse )
		end
	end
end

-- Client

function grenades.client_onCreate( self )
	self.boltValue = 0.0
	self.bullets = {}
	
	--[[
	self.time = 0
	self.effect = sm.effect.createEffect("CornShot")
	self.effect:start()
	self.effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) ) )
	]]
end

function grenades.client_onFixedUpdate( self, dt )
	--print(self.bullets)
	for k, bullet in pairs(self.bullets) do
		if bullet then
			if bullet.alive + dt > bullet.livetime then --lives for 2 sec, clean up after
				bullet.effect:setPosition(sm.vec3.new(0,0,1000000))
				bullet.effect:stop()
			end
			--predicted collision detect: 
			--raycast & other crap
			bullet.direction = bullet.direction*0.997 - sm.vec3.new(0,0,bullet.grav *0.1)
			local hit, result =  sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 )
			if hit then
				--bounce:
				local normal = result.normalWorld
				
				local rotation = sm.vec3.getRotation(bullet.direction, normal)
		--[[	
	local test1 = rotation*sm.vec3.new( 0, 0, 1 )
	print(test1 , test1.y/test1.x)
	rot.w = rot.w*1.01
	local test1 = rotation*sm.vec3.new( 0, 0, 1 )
	print(test1 , test1.y/test1.x)
	]]	
				rotation.w  = rotation.w *-9
				bullet.spin = rotation
				
				bullet.direction = sm.vec3.rotate( - bullet.direction, math.rad(180), normal)*0.75 + normal*0.05
			end
			
			bullet.pos = bullet.pos + bullet.direction* dt
			bullet.effect:setVelocity(bullet.direction)
			bullet.alive = bullet.alive + dt
			
			if bullet.spin then
				if bullet.rotation then bullet.rotation = sm.vec3.getRotation(bullet.direction, bullet.rotation * (bullet.spin * bullet.direction))
				else bullet.rotation = bullet.spin end
				bullet.effect:setRotation(bullet.rotation)
			end
		end
		if bullet.alive - dt > bullet.livetime then
			self.bullets[k] = nil
		end
	end
end

function grenades.client_onShoot( self, data )
	self.boltValue = 1.0
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	
	local position = self.shape.worldPosition + self.shape.up*0.5
	local bullet = {effect = sm.effect.createEffect("CornShot"), pos = position, direction = data.dir, alive = 0, grav = data.gravity, livetime = data.livetime}
	bullet.effect:setPosition( position )
	bullet.effect:setRotation( rot )
	bullet.effect:start()
	self.bullets[#self.bullets+1] = bullet
end

function grenades.client_onUpdate( self, deltaTime )

	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - deltaTime * 10
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end

	--[[
	self.time = self.time + deltaTime
	
	local direction = sm.vec3.new( 0, 0, 1 )
	self.effect:setPosition( self.shape.worldPosition )
	--self.effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), direction:rotateX( self.time * math.pi ) ) )]]
end





rocket = class( nil )
rocket.maxParentCount = 1
rocket.maxChildCount = 0
rocket.connectionInput = sm.interactable.connectionType.logic
rocket.connectionOutput = sm.interactable.connectionType.none
rocket.colorNormal = sm.color.new( 0x009999ff  )
rocket.colorHighlight = sm.color.new( 0x11B2B2ff  )
rocket.poseWeightCount = 1
rocket.fireDelay = 20 --ticks
rocket.minForce = 1
rocket.maxForce = 1.02
rocket.livetime = 20

function rocket.server_onCreate( self ) 
	self:server_init()
end

function rocket.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function rocket.server_onRefresh( self )
	self:server_init()
end

function rocket.server_onFixedUpdate( self, timeStep )
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
		if bullet then
			if bullet.alive + timeStep > rocket.livetime or bullet.hit then
				--position, level, destructionRadius, impulseRadius, magnitude
				sm.physics.explode( bullet.pos, 6, 6.5, 8, 30, "PropaneTank - ExplosionBig")
				
			end
		end
	end
end

function rocket.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and not self.parentActive and self.canFire then
			self.canFire = false
			
			
			local dir = sm.noise.gunSpread( self.shape.right, 3 ) * -math.random( self.minForce, self.maxForce ) 
			local extra = dir*dir:dot(self.shape.velocity)*1.3
			if extra:dot(dir) > 0 then dir = dir+ extra end
			
			self.network:sendToClients( "client_onShoot", {dir = dir, gravity = sm.physics.getGravity()/10})
		end
	end
end

-- Client

function rocket.client_onCreate( self )
	self.boltValue = 0.0
	self.bullets = {}
	
	--[[
	self.time = 0
	self.effect = sm.effect.createEffect("CornShot")
	self.effect:start()
	self.effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) ) )
	]]
end

function rocket.client_onFixedUpdate( self, dt )
	--print(self.bullets)
	for k, bullet in pairs(self.bullets) do
		if bullet then
			if bullet.alive + dt > rocket.livetime or bullet.hit then --lives for 2 sec, clean up after
				bullet.effect:setPosition(sm.vec3.new(0,0,1000000))
				bullet.effect:stop()
				bullet.alive = rocket.livetime + dt
			end
			--predicted collision detect: 
			--raycast & other crap
			bullet.direction = (bullet.direction + bullet.direction:normalize()*1.2)*0.97 
			local hit, result =  sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 )
			if hit then
				bullet.hit = true
			end
			
			local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, -1 ), bullet.direction )
			bullet.effect:setRotation( rot )
			sm.particle.createParticle( "p_spudgun_basic_impact_potato", bullet.pos, rot, sm.color.new(0.2,0.2,0.2,1) )
			sm.particle.createParticle( "paint_smoke", bullet.pos, rot, sm.color.new(0.2,0.2,0.2,1) )
			
			bullet.pos = bullet.pos + bullet.direction* dt
			bullet.effect:setVelocity(bullet.direction)
			bullet.alive = bullet.alive + dt
			
			if bullet.spin then
				if bullet.rotation then bullet.rotation = sm.vec3.getRotation(bullet.direction, bullet.rotation * (bullet.spin * bullet.direction))
				else bullet.rotation = bullet.spin end
				bullet.effect:setRotation(bullet.rotation)
			end
		end
		if bullet.alive - dt > rocket.livetime then
			self.bullets[k] = nil
		end
	end
end

function rocket.client_onShoot( self, data )
	self.boltValue = 1.0
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, -1 ), data.dir:normalize() )
	
	local position = self.shape.worldPosition -self.shape.right*0.5
	local bullet = {effect = sm.effect.createEffect("Thruster"), pos = position, direction = data.dir, alive = 0, grav = data.gravity}
	bullet.effect:setPosition( position )
	bullet.effect:setRotation( rot )
	bullet.effect:start()
	self.bullets[#self.bullets+1] = bullet
end

function rocket.client_onUpdate( self, deltaTime )

	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - deltaTime * 10
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end

	--[[
	self.time = self.time + deltaTime
	
	local direction = sm.vec3.new( 0, 0, 1 )
	self.effect:setPosition( self.shape.worldPosition )
	--self.effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), direction:rotateX( self.time * math.pi ) ) )]]
end


