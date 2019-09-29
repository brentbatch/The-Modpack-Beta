-- Nuke.lua --

Nuke = class()
--Nuke.poseWeightCount = 0

Nuke.fireDelay = 20 --ticks (0.5 seconds)
--Nuke.fuseDelay = 0.0625


--[[ Server ]]

-- (Event) Called upon creation on server
function Nuke.server_onCreate( self )
	self:server_init()
end

-- (Event) Called when script is refreshed (in [-dev])
function Nuke.server_onRefresh( self )
	self:server_init()
end

-- Initialize Nuke
function Nuke.server_init( self )
	self.alive = true
	self.counting = false
	self.fireDelayProgress = 0

	-- Default values. Overwritten by data.
	self.destructionLevel = 10
	self.destructionRadius = 100.0
	self.impulseRadius = 200.0
	self.impulseMagnitude = 1000.0

	-- Read data from interactive.json. See "scripted": "data".
	if self.data then
		if self.data.destructionLevel then
			self.destructionLevel = self.data.destructionLevel
		end
		if self.data.destructionRadius then
			self.destructionRadius = self.data.destructionRadius
		end
		if self.data.impulseRadius then
			self.impulseRadius = self.data.impulseRadius
		end
		if self.data.impulseMagnitude then
			self.impulseMagnitude = self.data.impulseMagnitude
		end
	end
end

-- (Event) Called upon game tick. (40 times a second)
function Nuke.server_onFixedUpdate( self, timeStep )
	sm.physics.applyImpulse(self.shape, sm.vec3.new(0,0,1)* self.shape.mass/50, true, sm.shape.getUp(self.shape)*-1)
	if self.counting then
		self.fireDelayProgress = self.fireDelayProgress + 1
		if self.fireDelayProgress >= self.fireDelay then
			self:server_tryExplode()
		end
	end
end

-- Attempt to create an explosion
function Nuke.server_tryExplode( self )
	if self.alive then
		self.alive = false
		self.counting = false
		self.fireDelayProgress = 0

		-- Create explosion
		sm.physics.explode( self.shape.worldPosition, self.destructionLevel, self.destructionRadius, self.impulseRadius, self.impulseMagnitude, self.explosionEffectName, self.shape )
		sm.shape.destroyPart( self.shape )
	end
end

-- (Event) Called upon getting hit by a projectile.
function Nuke.server_onProjectile( self, hitPos, hitTime, hitVelocity, hitType )
	if self.alive then
		if self.counting then
			self.fireDelayProgress = self.fireDelayProgress + self.fireDelay * 0.5
		else
			-- Trigger explosion countdown
			self:server_startCountdown()
			self.network:sendToClients( "client_hitActivation", hitPos )
		end
	end
end

-- (Event) Called upon getting hit by a sledgehammer.
function Nuke.server_onSledgehammer( self, hitPos, player )
	if self.alive then
		if self.counting then
			self.fireDelayProgress = self.fireDelayProgress + self.fireDelay * 0.5
		else
			-- Trigger explosion countdown
			self:server_startCountdown()
			self.network:sendToClients( "client_hitActivation", hitPos )
		end
	end
end

-- (Event) Called upon collision with an explosion nearby
function Nuke.server_onExplosion( self, center, destructionLevel )
	-- Explode within a few ticks
	if self.alive then
		self.fireDelay = 5
		self.counting = true
	end
end

-- (Event) Called upon collision with another object
function Nuke.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )

	local collisionDirection = (selfPointVelocity - otherPointVelocity):normalize()
	local diffVelocity = (selfPointVelocity - otherPointVelocity):length()
	local selfPointVelocityLength = selfPointVelocity:length()
	local otherPointVelocityLength = otherPointVelocity:length()
	local scaleFraction = 1.0 - ( self.fireDelayProgress / self.fireDelay )
	local dotFraction = math.abs( collisionDirection:dot( collisionNormal ) )

	--old collision
	local hardTrigger = ( selfPointVelocityLength >= 10 * scaleFraction or otherPointVelocityLength >= 10 * scaleFraction ) and diffVelocity > 10 * scaleFraction
	local lightTrigger = ( ( selfPointVelocityLength >= 4 * scaleFraction and selfPointVelocityLength < 10 * scaleFraction and diffVelocity >= 4 * scaleFraction ) or ( otherPointVelocityLength >= 4 * scaleFraction and otherPointVelocityLength < 10 * scaleFraction and diffVelocity >= 4 * scaleFraction ) )

	-- new collision 
	--local hardTrigger = diffVelocity * dotFraction >= 10 * scaleFraction
	--local lightTrigger = diffVelocity * dotFraction >= 6 * scaleFraction

	if self.alive then
		if hardTrigger  then
			-- Trigger explosion immediately
			self.counting = true
			self.fireDelayProgress = self.fireDelayProgress + self.fireDelay
		elseif lightTrigger then
			-- Trigger explosion countdown
			if not self.counting then
				self:server_startCountdown()
				self.network:sendToClients( "client_hitActivation", collisionPosition )
			else
				self.fireDelayProgress = self.fireDelayProgress + self.fireDelay * ( 1.0 - scaleFraction )
			end
		end
	end
end

-- Start countdown and update clients
function Nuke.server_startCountdown( self )
	self.counting = true
	self.network:sendToClients( "client_startCountdown" )
end


--[[ Client ]]

-- (Event) Called upon creation on client
function Nuke.client_onCreate( self )
	self.client_counting = false
	--self.client_fuseDelayProgress = 0
	self.client_fireDelayProgress = 0
	--self.client_poseScale = 0
	self.client_effect_doOnce = true

	-- Default values. Overwritten by data.
--	self.explosionEffectName = "PropaneTank - ExplosionBig"
--	self.activateEffectName = "PropaneTank - ActivateBig"
	self.explosionEffectName = "Nuke - Explosion"
	self.activateEffectName = "Nuke - Activate"

	-- Read data from interactive.json. See "scripted": "data".
	if self.data then
		if self.data.effectExplosion then
			self.explosionEffectName = self.data.effectExplosion
		end
		if self.data.effectActivate then
			self.activateEffectName = self.data.effectActivate
		end
	end

--	self.singleHitEffect = sm.effect.createEffect( "PropaneTank - SingleActivate", self.interactable )
	self.singleHitEffect = sm.effect.createEffect( "Nuke - SingleActivate", self.interactable )
	self.activateEffect = sm.effect.createEffect( self.activateEffectName, self.interactable )
end

-- (Event) Called upon every frame. (Same as fps)
function Nuke.client_onUpdate( self, dt )
	if self.client_counting then
		--self.interactable:setPoseWeight( 0,(self.client_fuseDelayProgress*1.5) +self.client_poseScale )
		--self.client_fuseDelayProgress = self.client_fuseDelayProgress + dt
		--self.client_poseScale = self.client_poseScale +(0.25*dt)

		--if self.client_fuseDelayProgress >= self.fuseDelay then
		--	self.client_fuseDelayProgress = self.client_fuseDelayProgress - self.fuseDelay
		--end

		self.client_fireDelayProgress = self.client_fireDelayProgress + dt
		self.activateEffect:setParameter( "progress", self.client_fireDelayProgress / ( self.fireDelay * ( 1 / 40 ) ) )
	end
end

-- Called from server upon getting triggered by a hit
function Nuke.client_hitActivation( self, hitPos )
	local localPos = self.shape:transformPoint( hitPos )

	local smokeDirection = ( hitPos - self.shape.worldPosition ):normalize()
	local worldRot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), smokeDirection )
	local localRot = self.shape:transformRotation( worldRot )

	self.singleHitEffect:start()
	self.singleHitEffect:setOffsetRotation( localRot )
	self.singleHitEffect:setOffsetPosition( localPos )
end

-- Called from server upon countdown start
function Nuke.client_startCountdown( self )
	self.client_counting = true
	self.activateEffect:start()

	local offsetRotation = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) ) * sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 0, 1, 0 ) )
	self.activateEffect:setOffsetRotation( offsetRotation )
end
