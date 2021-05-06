dofile "SE_Loader.lua"


cucumbercrosssbow = class( nil )
cucumbercrosssbow.maxParentCount = 1
cucumbercrosssbow.maxChildCount = 0
cucumbercrosssbow.connectionInput = sm.interactable.connectionType.logic
cucumbercrosssbow.connectionOutput = sm.interactable.connectionType.none
cucumbercrosssbow.colorNormal = sm.color.new( 0x009999ff  )
cucumbercrosssbow.colorHighlight = sm.color.new( 0x11B2B2ff  )
cucumbercrosssbow.poseWeightCount = 1
cucumbercrosssbow.fireDelay = 20 --ticks
cucumbercrosssbow.minForce = 95
cucumbercrosssbow.maxForce = 100
cucumbercrosssbow.spreadDeg = 1

function cucumbercrosssbow.server_onCreate( self ) 
	self:server_init()
end

function cucumbercrosssbow.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function cucumbercrosssbow.server_onRefresh( self )
	self:server_init()
end

function cucumbercrosssbow.server_onFixedUpdate( self, timeStep )
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
			if bullet.hit or bullet.alive > 200 then
				if bullet.hit then 
					sm.projectile.shapeFire( self.shape, "potato", getLocal(self.shape,bullet.hit - self.shape.worldPosition - bullet.direction*timeStep*1.05), getLocal(self.shape,bullet.direction) ) 
					sm.projectile.shapeFire( self.shape, "potato", getLocal(self.shape,bullet.hit - self.shape.worldPosition - bullet.direction*timeStep*2.1), getLocal(self.shape,bullet.direction) ) 
					sm.projectile.shapeFire( self.shape, "potato", getLocal(self.shape,bullet.hit - self.shape.worldPosition), getLocal(self.shape,bullet.direction) )  
				end
			end
		end
	end
end

function cucumbercrosssbow.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and not self.parentActive and self.canFire then
			self.canFire = false
			--local firePos = sm.vec3.new( 0.0, 0.0, 0.375 )
			
			local fireForce = math.random( self.minForce, self.maxForce )
			local dir = sm.noise.gunSpread( self.shape.up, self.spreadDeg )
			
			self.network:sendToClients( "client_onShoot", {dir = dir*fireForce, gravity = sm.physics.getGravity()})
			
			local mass = 50
			local impulse =  -dir * fireForce * mass
			sm.physics.applyImpulse( self.shape, impulse, true )
		end
	end
end

-- Client

function cucumbercrosssbow.client_onCreate( self )
	self.boltValue = 0.0
	self.bullets = {}
end

function cucumbercrosssbow.client_onFixedUpdate( self, dt )
	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - dt * 2
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
	
	for k, bullet in pairs(self.bullets) do
		if bullet then
			if bullet.hit or bullet.alive > 200 then --lives for 2 sec, clean up after
				bullet.effect:setPosition(sm.vec3.new(0,0,1000000))
				bullet.effect:stop()
				self.bullets[k] = nil
			end
			if bullet and not bullet.hit then --movement
				bullet.direction = bullet.direction*0.997 - sm.vec3.new(0,0,bullet.grav*dt)
				
				--predicted collision detect:
				local hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 )
				if hit then
					bullet.hit = result.pointWorld
				else
					bullet.pos = bullet.pos + bullet.direction * dt
					bullet.effect:setPosition(bullet.pos - bullet.direction*dt) -- aesthetic
					bullet.effect:setVelocity(bullet.direction)
					bullet.alive = bullet.alive + dt
				end
			end
		end
	end
end

function cucumbercrosssbow.client_onShoot( self, data )
	self.boltValue = 1.0
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	--self.shootEffect:start()
	local position = self.shape.worldPosition 
	local bullet = {effect = sm.effect.createEffect("CrosssBowShot"), pos = position , direction = data.dir, alive = 0, grav= data.gravity}
	bullet.effect:setPosition( position )
	bullet.effect:setRotation(rot)
	bullet.effect:start()
	table.insert(self.bullets, bullet)
end

function getLocal(shape, vec)
    return sm.vec3.new(sm.shape.getRight(shape):dot(vec), sm.shape.getAt(shape):dot(vec), sm.shape.getUp(shape):dot(vec))
end
