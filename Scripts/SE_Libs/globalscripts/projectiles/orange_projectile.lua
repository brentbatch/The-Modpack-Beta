--[[
	Copyright (c) 2019 Scrap Essentials Team
]]--


orange_projectile = {}

--position, direction, gravity, friction

-- function orange_projectile.server_onCreate(self, otherProjectiles, ...) end

function orange_projectile.client_onCreate(self, otherProjectiles, position, velocity, gravity, friction)
	--print('orange_projectile.client_onCreate')
	assert(position, "server_spawnProjectile requires vec3 position as parameter #2")
	assert(velocity, "server_spawnProjectile requires vec3 velocity as parameter #3")
	
	self.position = position
	self.velocity = velocity
	self.friction = friction or 0.003
	self.gravity = gravity or 10
	self.alive = 0
	
	self.effect = sm.effect.createEffect("CannonShot")
	self.effect:setPosition( position )
	self.effect:setVelocity(velocity)
	self.effect:start()
	
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), velocity:normalize() )
	sm.effect.playEffect( "CannonAudio", position, direction, rot )
end


function orange_projectile.server_onFixedUpdate(self, dt)
	--print('orange_projectile.server_onFixedUpdate')
	if self.hit then
		sm.physics.explode( self.hit.pointWorld,  6, 0.13, 0.5, 1, "PropaneTank - ExplosionSmall")
	end
end

function orange_projectile.client_onFixedUpdate(self, dt)
	--print('orange_projectile.client_onFixedUpdate')
	if self.hit or self.alive > 120 then -- 120 seconds
		self:destroy()
	end
	self.alive = self.alive + dt
	
	if not self.hit then
		-- has been tested: velocity first, then position
		self.velocity = self.velocity*(1 - self.friction) - sm.vec3.new(0, 0, self.gravity*dt)
		self.position = self.position + self.velocity*dt
		
		--self.effect:setPosition(self.position) -- causes 'flicker'
		self.effect:setVelocity(self.velocity)
		
		local hit, result = self:client_raycast(dt)
		if hit then
			self.hit = result
			self.effect:stop()
		end
	end
end

function orange_projectile.client_raycast(self, dt)
	local right = self.velocity:cross(sm.vec3.new(0,0,1))
	if right:length()<0.001 then right = sm.vec3.new(1,0,0) else right = right:normalize() end
	local up = right:cross(self.velocity):normalize()
	
	up, right = up/8, right/8
	
	for k, offset in pairs({sm.vec3.zero(), up + right, up - right, -up + right, -up - right}) do
		local hit, result = sm.physics.raycast( self.position + offset, self.position + offset + self.velocity*dt*1.1 )
		if hit then
			return hit, result
		end
	end
	return false
end

function orange_projectile.client_onDestroy(self)
	
end



