--[[
	Copyright (c) 2019 Brent Batch
	Contact: Brent Batch#9261 on discord
]]--


-- in case this script crashes in server_onFixedUpdate or client_onFixedUpdate: reload scriptclass that uses this script.
local reload = customProjectile and customProjectile.client_reload 
-- Required for script reloads.
-- gets old already existing scriptclass from before reload if it exists. (exec 'reload()' at the end of this script tho)

customProjectile = {}
customProjectile.server_queued = {}
customProjectile.projectiles = {}

function customProjectile.server_onCreate(self)
	print('customProjectile.server_onCreate')
	
end

local function split(str, sep)
   local result = {}
   local regex = ("([^%s]+)"):format(sep)
   for each in str:gmatch(regex) do
      table.insert(result, each)
   end
   return result
end

function customProjectile.server_onFixedUpdate(self,dt)
	for k, data in pairs(self.server_queued) do
		self.network:sendToClients("client_createProjectile", data)
		self.server_queued[k] = nil
	end
	
	for k, proj in pairs(customProjectile.projectiles) do
		if proj.hit or proj.lifetime < 0 then
			local replaceImpact = false
			
			if proj.server_onCollision and type(proj.server_onCollision) == "string" then
				local search = _G
				for k, v in pairs(split(proj.server_onCollision,".")) do
					search = search[v]
					if not search then break end
				end
				if search and type(search) == "function" then
					pcall(search,proj) -- found function, 'search' is the collide function we need to call!
					replaceImpact = true
				end
			end
			if not replaceImpact then
				sm.physics.explode( (proj.hit) and proj.hit.pointWorld or proj.position,  proj.destructionLevel, proj.destructionRadius, proj.impulseRadius, proj.magnitude, proj.explodeEffect)
			end
		end
	end
end




function customProjectile.client_onRefresh(self)
	-- any global variables need to be re-set here
	-- before customProjectile.client_onRefresh gets called, the client_onDestroy will be called to destroy any malfunctioning projectiles.
	print('customProjectile.client_onRefresh')
	-- you might want to call self:client_onCreate()
end


function customProjectile.client_onCreate(self, ...)
	print('customProjectile.client_onCreate')
end

function customProjectile.client_createProjectile(self, data)
	local shape, localPosition, localVelocity, position, velocity, rotation, acceleration, gravity, friction, effect, size, lifetime, audio, destructionLevel, destructionRadius, impulseRadius, magnitude, explodeEffect, server_onCollision = unpack(data)
	
	if (localPosition or localVelocity) and
	(shape == nil or not sm.exists(shape)) then 
		return  -- can't do local if there is no shape
	end
	
	if localPosition then
		position = shape.worldPosition + shape.worldRotation * position
	end
	if localVelocity then
		velocity = shape.worldRotation * velocity
	end
	
	local success, effect = pcall(sm.effect.createEffect, effect)
	if not success then sm.log.error(effect) return end -- if effect doesn't exist, just return
	effect:setPosition(position)
	--effect:setVelocity(velocity)
	if velocity:length2() > 0.0001 then
		effect:setRotation(sm.vec3.getRotation( rotation, velocity:normalize() ))
	end
	effect:start()
	if audio and audio ~= "" then
		local success, err = pcall(sm.effect.playEffect, audio, position, velocity) -- can't crash because of this plz
		if not success then sm.log.error(err) end
	end
	
	local projectile = { 
		effect = effect,
		position = position,
		velocity = velocity,
		rotation = rotation,
		acceleration = acceleration,
		gravity = gravity,
		friction = friction,
		size = size,
		lifetime = lifetime,
		destructionLevel = destructionLevel,
		destructionRadius = destructionRadius,
		impulseRadius = impulseRadius,
		magnitude = magnitude,
		explodeEffect = explodeEffect,
		server_onCollision = server_onCollision
	}
	
	table.insert(customProjectile.projectiles, projectile)
end


function customProjectile.client_onFixedUpdate(self,dt)
	for k, proj in pairs(customProjectile.projectiles) do
		if proj.hit or proj.lifetime < 0 then 
			proj.effect:setPosition(sm.vec3.new(0,0,10000))
			proj.effect:stop()
			customProjectile.projectiles[k] = nil
		end
		
		if proj and not proj.hit then
			proj.lifetime = proj.lifetime - dt
			
			-- acceleration (can be used for rockets)
			if proj.acceleration ~= 0 then proj.velocity = proj.velocity + proj.velocity:normalize()*proj.acceleration end
			
			-- has been tested: velocity first, then position
			proj.velocity = proj.velocity*(1 - proj.friction) - sm.vec3.new(0, 0, proj.gravity*dt)
			
			local hit, result = self:client_projectileRaycast(proj, dt)
			if hit then
				proj.hit = result
				proj.effect:setPosition(sm.vec3.new(0,0,10000))
				proj.effect:stop()
			end
			
			proj.position = proj.position + proj.velocity*dt
			

			proj.effect:setPosition(proj.position) -- causes 'flicker', we don't use this shit
			--proj.effect:setVelocity(proj.velocity) --setVelocity doesn't work as it did in 0.3 anymore
			if proj.velocity:length2() > 0.0001 then
				proj.effect:setRotation(sm.vec3.getRotation( proj.rotation, proj.velocity:normalize() ))
			end
			
		end
		
	end
end

function customProjectile.client_projectileRaycast(self, proj, dt)
	local right = proj.velocity:cross(sm.vec3.new(0,0,1))
	if right:length()<0.001 then right = sm.vec3.new(1,0,0) else right = right:normalize() end
	local up = right:cross(proj.velocity):normalize()
	
	up, right = up/8 * proj.size, right/8 * proj.size
	
	for k, offset in pairs({sm.vec3.zero(), up + right, up - right, -up + right, -up - right}) do
		local hit, result = sm.physics.raycast( proj.position + offset, proj.position + offset + proj.velocity*dt*1.1 )
		if hit then
			return hit, result
		end
	end
	return false
end


function customProjectile.client_onDestroy(self) -- properly clean up when remote is destroyed!
	for k, proj in pairs(self.projectiles) do 
		proj.effect:setPosition(sm.vec3.new(0,0,10000))
		proj.effect:stop()
		self.projectiles[k] = nil
	end
end


function customProjectile.server_spawnProjectile(self, data) -- default one, use configured settings, if the scriptclass that uses this copies this function: it has to be reloaded too.
	if not sm.isHost then return end
	data = data or {}
	
	local localPosition = 	data.localPosition or 	false
	local localVelocity = 	data.localVelocity or 	false
	local position = 		data.position or 		assert(false, "position parameter needs to be filled in")
	local velocity = 		data.velocity or 		assert(false, "velocity parameter needs to be filled in")
	local rotation = 		data.rotation or 		sm.vec3.new(0,0,1)
	local acceleration = 	data.acceleration or 	0 -- adds acceleration*normalized velocity per tick to velocity
	local gravity = 		data.gravity or			sm.physics.getGravity()
	local friction = 		data.friction or 		0.003 -- 0.3%
	local effect = 			data.effect or 			"CannonShot"
	local size = 			data.size or 			1
	local lifetime = 		data.lifetime or 		30 -- sec
	local audio = 			data.spawnAudio or 		false
	local server_onCollision = 	data.server_onCollision or 	false
	
	local level =			data.destructionLevel or 	6
	local destrRadius = 	data.destructionRadius or   0.13
	local impulseRadius =	data.impulseRadius or       0.5
	local magnitude =		data.magnitude or           10
	local explodeEffect = 	data.explodeEffect or 		"PropaneTank - ExplosionSmall"
	
	
	table.insert(customProjectile.server_queued, {self.shape, localPosition, localVelocity, position, velocity, rotation, acceleration, gravity, friction, effect, size, lifetime, audio, level, destrRadius, impulseRadius, magnitude, explodeEffect, server_onCollision})
end

function customProjectile.client_spawnProjectile(self, data) -- not recommended
	--[[ default one, 
		on client, 
		skips one tick but has to be done on ALL clients at the same time,
		clients must all have done customProjectile.configureProjectile with the same stuff.
	--]]
	data = data or {}
	
	local localPosition = 	data.localPosition or 	false
	local localVelocity = 	data.localVelocity or 	false
	local position = 		data.position or 		assert(false, "position parameter needs to be filled in")
	local velocity = 		data.velocity or 		assert(false, "velocity parameter needs to be filled in")
	local rotation = 		data.rotation or 		sm.vec3.new(0,0,1)
	local acceleration = 	data.acceleration or 	0 -- adds acceleration*normalized velocity per tick to velocity
	local gravity = 		data.gravity or			10
	local friction = 		data.friction or 		0.003 -- 0.3%
	local effect = 			data.effect or 			"CannonShot"
	local size = 			data.size or 			1
	local lifetime = 		data.lifetime or 		30 -- sec
	local audio = 			data.spawnAudio or 		false
	local server_onCollision = 	data.server_onCollision or 	false
	
	local level =			data.destructionLevel or 	6
	local destrRadius = 	data.destructionRadius or   0.13
	local impulseRadius =	data.impulseRadius or       0.5
	local magnitude =		data.magnitude or           10
	local explodeEffect = 	data.explodeEffect or 		"PropaneTank - ExplosionSmall"
	
	customProjectile.client_createProjectile(customProjectile, {self.shape, localPosition, localVelocity, position, velocity, rotation, acceleration, gravity, friction, effect, size, lifetime, audio, level, destrRadius, impulseRadius, magnitude, explodeEffect, server_onCollision})
end



if reload then reload() end -- makes globalscript reload this properly when this file gets updated.