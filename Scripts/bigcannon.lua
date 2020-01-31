

bigcannon = class( nil )
bigcannon.maxParentCount = 1
bigcannon.maxChildCount = 0
bigcannon.connectionInput = sm.interactable.connectionType.logic
bigcannon.connectionOutput = sm.interactable.connectionType.none
bigcannon.colorNormal = sm.color.new( 0x009999ff  )
bigcannon.colorHighlight = sm.color.new( 0x11B2B2ff  )
bigcannon.poseWeightCount = 1
bigcannon.fireDelay = 20 --ticks
bigcannon.minForce = 35
bigcannon.maxForce = 40
bigcannon.spreadDeg = 0.5

function bigcannon.server_onCreate( self ) 
	self:server_init()
end

function bigcannon.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function bigcannon.server_onRefresh( self )
	self:server_init()
end

function bigcannon.server_onFixedUpdate( self, timeStep )
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
			if bullet.hit or bullet.alive > 200 then --lives for 2 sec, clean up after
				if bullet.hit then
					--position, level, destructionRadius, impulseRadius, magnitude
					sm.physics.explode( bullet.result, 6, 0.4, 1, 0.1,"PropaneTank - ExplosionSmall")
				end
				self.bullets[k] = nil
			end
		end
	end
end

function bigcannon.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and not self.parentActive and self.canFire then
			self.canFire = false
			--local firePos = sm.vec3.new( 0.0, 0.0, 0.375 )
			
			local fireForce = math.random( self.minForce, self.maxForce )
			local dir = sm.noise.gunSpread( self.shape.up, self.spreadDeg )
			
			self.network:sendToClients( "client_onShoot", {dir = dir*fireForce, gravity = sm.physics.getGravity()})
			
			local mass = 50
			local impulse = -dir * fireForce * mass
			sm.physics.applyImpulse( self.shape, impulse, true )
		end
	end
end

-- Client

function bigcannon.client_onCreate( self )
	self.boltValue = 0.0
	--self.shootEffect = sm.effect.createEffect( "Shot", self.interactable )
	self.bullets = {}
end

function bigcannon.client_onFixedUpdate( self, dt )
	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - dt * 5
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
	--print(self.bullets)
	for k, bullet in pairs(self.bullets) do
		if bullet then
			if bullet.hit or bullet.alive > 200 then --lives for 2 sec, clean up after
				bullet.effect:stop()
			end
			if bullet and not bullet.hit then --movement
				
				bullet.direction = bullet.direction*0.997 - sm.vec3.new(0,0,bullet.grav*dt)
				
				local right = sm.vec3.new(0,0,1):cross(bullet.direction)
				if right:length()<0.001 then right = sm.vec3.new(1,0,0) else right = right:normalize() end
				local up = self.shape.up:cross(right)
				
				--predicted collision detect:  -- now has a bigger collision 'box'
				--raycast & other crap
				local hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 )
				if not hit then 
					hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 + up/4 + right/4)
					if not hit then 
						hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 + up/4 - right/4)
						if not hit then 
							hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 - up/4 - right/4)
							if not hit then 
								hit, result = sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 - up/4 + right/4)
							end
						end
					end
				end
				if hit then
					bullet.hit = true
					bullet.result = result.pointWorld
					bullet.effect:setPosition(sm.vec3.new(0,0,1000000))
				else
					bullet.pos = bullet.pos + bullet.direction * dt
					--bullet.direction = bullet.direction - sm.vec3.new(0,0,1) -- gravity on bullet => would unsync clients and host
					--bullet.effect:setPosition(bullet.pos)
					bullet.effect:setVelocity(bullet.direction)
					bullet.alive = bullet.alive + dt
				end
			end
		end
	end
end

function bigcannon.client_onShoot( self, data )
	self.boltValue = 1.0
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	--self.shootEffect:start()
	local position = self.shape.worldPosition + self.shape.up*0.2
	local bullet = {effect = sm.effect.createEffect("BigCannonShot"), pos = position, direction = data.dir, alive = 0, grav = data.gravity} -- -  self.shape.up*0.5
	bullet.effect:setPosition( position + self.shape.up)
	bullet.effect:start()
	sm.effect.playEffect( "CannonAudio", position, data.dir, rot ) 
	self.bullets[#self.bullets+1] = bullet
end


function getLocal(shape, vec)
    return sm.vec3.new(sm.shape.getRight(shape):dot(vec), sm.shape.getAt(shape):dot(vec), sm.shape.getUp(shape):dot(vec))
end
