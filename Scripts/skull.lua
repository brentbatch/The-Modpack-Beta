--[[
	Copyright (c) 2019 Brent Batch
	Contact: Brent Batch#9261 on discord
]]--
dofile "SE_Loader.lua"


skull = class( nil )
skull.maxParentCount = 1
skull.maxChildCount = 0
skull.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
skull.connectionOutput = sm.interactable.connectionType.none
skull.colorNormal = sm.color.new( 0x009999ff  )
skull.colorHighlight = sm.color.new( 0x11B2B2ff  )
skull.poseWeightCount = 1
skull.fireDelay = 120 --ticks
skull.livetime = 30 -- sec
skull.dodgeterrain = true

function skull.server_onCreate( self ) 
	self:server_init()
end

function skull.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function skull.server_onRefresh( self )
	self:server_init()
end

function skull.server_onFixedUpdate( self, timeStep )
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
			if bullet.hit then
				--position, level, destructionRadius, impulseRadius, magnitude
				sm.physics.explode( bullet.hit, 6, 0.5, 1, 10, "PropaneTank - ExplosionSmall")
			end
		end
	end
end

function skull.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive()  and self.canFire then
			self.canFire = false
			local dir = sm.noise.gunSpread(self.shape.right, 45 ) * 5 * math.random(7000,10000)/10000
			local extra = dir*dir:dot(self.shape.velocity)*0.001
			if extra:dot(dir) > 0 then dir = dir+ extra end
			
			self.network:sendToClients( "client_onShoot", {dir = dir, player = 0, power = parent.power})
		end
	end
end

-- Client

function skull.client_onCreate( self )
	self.boltValue = 0.0
	self.bullets = {}
end

function skull.client_onFixedUpdate( self, dt )
	--print(self.bullets)
	for k, bullet in pairs(self.bullets) do
		if bullet then
			if bullet.alive + dt > skull.livetime or bullet.hit then --lives for 2 sec, clean up after
				bullet.effect:setPosition(sm.vec3.new(0,0,1000))
				bullet.effect:stop()
				--bullet.effect2:setPosition(sm.vec3.new(0,0,1000000))
				--bullet.effect2:stop()
				bullet.alive = skull.livetime + dt
			end
			
			local distance = math.huge
			local pos = bullet.pos + bullet.direction
			for k, v in pairs(sm.player.getAllPlayers()) do
				local targetdir = (bullet.pos - v.character.worldPosition):normalize()
				local yaw = (180 + math.atan2(targetdir.y,targetdir.x)/math.pi * 180) - (180 + math.atan2(bullet.direction.y,bullet.direction.x)/math.pi * 180)
				yaw = (yaw>180) and yaw-360 or (yaw<-180 and yaw+360 or yaw)
				
				local dist = (bullet.pos - v.character.worldPosition):length() * math.max(0, (175-math.abs(yaw))^2) --10° dead spot behind it
				if dist < distance then
					pos = v.character.worldPosition --+ sm.vec3.new(0,0,0.6)
					distance = dist
				end
			end
			
			if bullet.alive > 2 then
				bullet.direction = (bullet.direction*0.7 + (pos - bullet.pos):normalize()*(0.125*bullet.power + bullet.direction:length()*0.3) )*0.995
			else
				bullet.direction = bullet.direction * 0.988
			end
			
			local hit, result =  sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 )
			if hit and self.dodgeterrain then
				if result.type == "terrainSurface" then
					bullet.direction = bullet.direction*0.1 + sm.vec3.new(0,0,50)
				elseif result.type == "terrainAsset" then
					bullet.direction = bullet.direction*0.1 + sm.vec3.new(0,0,50) + bullet.direction:cross(sm.vec3.new(0,0,1))
				end
			end
			
			local hit, result =  sm.physics.raycast( bullet.pos, bullet.pos + bullet.direction * dt*1.1 )
			if hit then
				bullet.hit = result.pointWorld
			end
			
			
			if not (bullet.alive + dt > skull.livetime or bullet.hit) then
				bullet.pos = bullet.pos + bullet.direction* dt
				bullet.effect:setPosition(bullet.pos)
				bullet.effect:setVelocity(bullet.direction)
				local rot = sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), bullet.direction )
				bullet.effect:setRotation( rot )
			end

			bullet.alive = bullet.alive + dt
			bullet.tick = bullet.tick + 1
		end
		if bullet.alive - dt > skull.livetime then
			self.bullets[k] = nil
		end
	end
end

function skull.client_onShoot( self, data )
	self.boltValue = 1.0
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), data.dir )
	--sm.particle.createParticle( "fire", self.shape.worldPosition-self.shape.right*0.3 + self.shape.at*0.1 , rot, sm.color.new(0,0,0) )
	
	local position = self.shape.worldPosition -- self.shape.up*0.7
	--local bullet = {effect = sm.effect.createEffect("fireskull"),effect2 = sm.effect.createEffect("fireskull"), pos = position, direction = data.dir, alive = 0, power = data.power, tick = 0}
	local bullet = {effect = sm.effect.createEffect("fireskull"), pos = position, direction = data.dir, alive = 0, power = data.power, tick = 0}
	bullet.effect:setPosition( position )
	bullet.effect:setVelocity( bullet.direction)
	bullet.effect:setRotation( rot )
	bullet.effect:start()
	--bullet.effect2:setPosition( position )
	--bullet.effect2:setVelocity( bullet.direction)
	--bullet.effect2:setRotation( rot )
	--bullet.effect2:start()
	self.bullets[#self.bullets+1] = bullet
end

function skull.client_onUpdate( self, deltaTime )

	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - deltaTime * 10
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
end


function getLocal(shape, vec)
    return sm.vec3.new(sm.shape.getRight(shape):dot(vec), sm.shape.getAt(shape):dot(vec), sm.shape.getUp(shape):dot(vec))
end

