--[[
	Copyright (c) 2019 Brent Batch
	
	Notice:
	- request permission from Brent Batch first before copying this script.
	- upon given permission any modifications will be notified to Brent Batch.
]]--
dofile "SE_Loader.lua"


grenadelauncher = class( nil )
grenadelauncher.maxParentCount = 1
grenadelauncher.maxChildCount = 0
grenadelauncher.connectionInput = sm.interactable.connectionType.logic
grenadelauncher.connectionOutput = sm.interactable.connectionType.none
grenadelauncher.colorNormal = sm.color.new( 0x009999ff  )
grenadelauncher.colorHighlight = sm.color.new( 0x11B2B2ff  )
grenadelauncher.poseWeightCount = 1
grenadelauncher.fireDelay = 20 --ticks
grenadelauncher.minForce = 15
grenadelauncher.maxForce = 20
grenadelauncher.livetime = 5

function grenadelauncher.server_onCreate( self ) 
	self:server_init()
end

function grenadelauncher.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
	self.livetime = grenadelauncher.livetime * (1 + (math.random()-0.5)/10 )
end

function grenadelauncher.server_onRefresh( self )
	self:server_init()
end

function grenadelauncher.server_onFixedUpdate( self, timeStep )
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

function grenadelauncher.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and not self.parentActive and self.canFire then
			self.canFire = false
			
			
			
			local dir = sm.noise.gunSpread( self.shape.up, 1 ) * math.random( self.minForce, self.maxForce ) + self.shape.velocity
			self.network:sendToClients( "client_onShoot",  {dir = dir, gravity = sm.physics.getGravity()/10, livetime = grenadelauncher.livetime * (1 + (math.random()-0.5)/10 )})
			
			
			local mass = 50
			local impulse = dir * -mass
			sm.physics.applyImpulse( self.shape, impulse, true )
		end
	end
end

-- Client

function grenadelauncher.client_onCreate( self )
	self.boltValue = 0.0
	self.bullets = {}
	
	--[[
	self.time = 0
	self.effect = sm.effect.createEffect("CornShot")
	self.effect:start()
	self.effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) ) )
	]]
end

function grenadelauncher.client_onFixedUpdate( self, dt )
	--print(self.bullets)
	for k, bullet in pairs(self.bullets) do
		if bullet then
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
			bullet.effect:setPosition(bullet.pos)
			bullet.effect:setVelocity(bullet.direction)
			bullet.alive = bullet.alive + dt
			
			if bullet.spin then
				if bullet.rotation then bullet.rotation = sm.vec3.getRotation(bullet.direction, bullet.rotation * (bullet.spin * bullet.direction))
				else bullet.rotation = bullet.spin end
				bullet.effect:setRotation(bullet.rotation)
			end
			
			if bullet.alive + dt > bullet.livetime then --lives for 2 sec, clean up after
				bullet.effect:setPosition(sm.vec3.new(0,0,1000))
				bullet.effect:setScale(sm.vec3.new(0,0,0.0001))
				bullet.effect:stop()
			end
		end
		if bullet.alive - dt > bullet.livetime then
			self.bullets[k] = nil
		end
	end
end

function grenadelauncher.client_onShoot( self, data )
	self.boltValue = 1.0
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	
	local position = self.shape.worldPosition + self.shape.up*0.5
	local bullet = {effect = sm.effect.createEffect("CornShot"), pos = position, direction = data.dir, alive = 0, grav = data.gravity, livetime = data.livetime}
	bullet.effect:setPosition( position )
	bullet.effect:setRotation( rot )
	bullet.effect:start()
	self.bullets[#self.bullets+1] = bullet
end

function grenadelauncher.client_onUpdate( self, deltaTime )

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
