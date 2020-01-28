--[[
	Copyright (c) 2019 Scrap Essentials Team
]]--


local description = sm.json.open("$MOD_DATA/description.json")
local __localId = description.localId -- the localid of the mod loading this file

-- ANTI COPY: (only prevents edit when compiled)
local allowedMods = {-- high, low
	[2231331700]	= {[651579252]	= {[2505189363] = {[1679441306] = true }}}, -- SE              84ff6b74-26d6-4f74-9552-27f3641a3d9a
	[96000016]		= {[2199931473]	= {[2238364114] = {[487542551] = true }}},  -- MP beta local   05b8d810-8320-4a51-856a-b9d21d0f4f17
	[1205729538]	= {[2964865479]	= {[2399973361] = {[3860742921] = true }}}, -- MP beta         47ddf902-b0b8-41c7-8f0c-aff1e61e4309
}

local uuid = __localId:gsub('-','')
local uuid1, uuid2, uuid3, uuid4 = tonumber(uuid:sub(0,8),16), tonumber(uuid:sub(9,16),16), tonumber(uuid:sub(17,24),16), tonumber(uuid:sub(25,32),16)

if sm.player.getAllPlayers()[1].name ~= "Brent Batch" and 
allowedMods[uuid1] and allowedMods[uuid1][uuid2] and allowedMods[uuid1][uuid2][uuid3] and allowedMods[uuid1][uuid2][uuid3][uuid4] then
	while true do sm.log.error("YOU ARE NOT ALLOWED TO COPY THIS SCRIPT, THY FOUL THIEF") end
end



stickyBomb = {} -- MANAGER
stickyBomb.bombs = {} -- { [spawnedscript.shape.id] = { {type,target,detonationTime,pointLocal,normalLocal},{},{} },      }
stickyBomb.server_queued = {}

local someFuckingNumber = 0 -- 'uuid replacement' , scrap uuid implementation sucks

function stickyBomb.server_onCreate(self, ...)
	--print('stickyBomb.client_onCreate')
	
end

function stickyBomb.server_onFixedUpdate(self, dt)
	--print('stickyBomb.server_onFixedUpdate', self.server_queued)
	for key, v in pairs(self.server_queued) do --devPrint('server_queued')
		local position, velocity, detonationTime = unpack(v)
		someFuckingNumber = someFuckingNumber + 1
		self.network:sendToClients("client_createBomb", {someFuckingNumber, position, velocity, detonationTime, sm.physics.getGravity()/10})
		self.server_queued[key] = nil
	end
	
	for id, bomb in pairs(self.bombs) do
		if bomb.detonationTime < dt and not bomb.done then
								--position, level, destructionRadius, impulseRadius, magnitude
			sm.physics.explode( bomb.position + bomb.velocity * dt,  6, 0.13, 0.5, 1, "PropaneTank - ExplosionSmall")
			bomb.done = true
		end
		if not bomb.type then -- sad bomb has no target, raycast for one
			local hit, result = sm.physics.raycast( bomb.position, bomb.position + bomb.velocity * dt * 1.1)
			if hit then
				local type = result.type
				local target;
				local position = result.pointWorld + result.normalWorld/8
				local velocity = sm.vec3.new(0,0,0)
				local pointLocal;
				if type == "body" then
					target = result:getShape()
					velocity = target.velocity
					pointLocal = target:transformPoint(result.pointWorld + result.normalWorld/16)
				end
				if type == "character" then 
					target = result:getCharacter()
					velocity = target.velocity
				end
				
				self.network:sendToClients("client_setBombTarget", {id, type, position, velocity, target, pointLocal, bomb.detonationTime, bomb.grav})
			end
		end
	end
end

--client: 

function stickyBomb.client_createBomb(self, data)
	local id, position, velocity, detonationTime, gravity = unpack(data)
	local bomb = {effect = sm.effect.createEffect("CannonShot"), position = position, velocity = velocity, detonationTime = detonationTime, grav = gravity}
	bomb.effect:setPosition( position )
	bomb.effect:setVelocity( velocity)
	bomb.effect:start()
	self.bombs[id] = bomb
	--table.insert(self.bombs, bomb)
end


function stickyBomb.client_onCreate(self, ...)
	print('stickyBomb.client_onCreate')
	
	--ask server for existing projectiles ? 
end

function stickyBomb.client_setBombTarget(self, data)
	local id, type, position, velocity, target, pointLocal, detonationTime, gravity = unpack(data)
	local bomb = self.bombs[id]
	if not bomb then -- this client joined and this bomb doesn't exist yet, create it cuz its possible :)
		self:client_createBomb({id, position, velocity, detonationTime, gravity})
		bomb = self.bombs[id]
	end
	bomb.type = type
	bomb.position = position
	bomb.velocity = velocity
	bomb.target = target
	bomb.pointLocal = pointLocal
end

function stickyBomb.client_onFixedUpdate(self,dt)
	--print('stickyBomb.client_onFixedUpdate')
	for id, bomb in pairs(self.bombs) do
		-- flight path:
		if bomb.type then
			if bomb.type == "body" then
				if sm.exists(bomb.target) then
					bomb.velocity = bomb.target.velocity
					bomb.position = bomb.target.worldPosition + bomb.target.worldRotation * bomb.pointLocal
				else
					bomb.type, bomb.target = nil, nil -- drops bomb
				end
			elseif bomb.type == "character" then
				if sm.exists(bomb.target) then -- TODO: pointLocal
					bomb.velocity = bomb.target.velocity
					bomb.position = bomb.target.worldPosition + bomb.target.velocity * dt
				else
					bomb.type, bomb.target = nil, nil -- drops bomb
				end
				
			end
			bomb.detonationTime = bomb.detonationTime - dt
		else
			bomb.velocity = bomb.velocity*0.975 - sm.vec3.new(0,0,bomb.grav*dt*10) 
			bomb.position = bomb.position + bomb.velocity* dt
		end
		
		-- animate bullet:
		bomb.effect:setPosition(bomb.position)
		bomb.effect:setVelocity(bomb.velocity)
		
		if bomb.detonationTime < 0 then
			bomb.effect:setPosition(sm.vec3.new(0,0,1000000))
			bomb.effect:stop()
			self.bombs[id] = nil
		end
	end
	
end

function stickyBomb.client_onRefresh(self)
	--print('hostblock.client_onRefresh')
end

function stickyBomb.onDestroy(self)
	print('stickyBomb onDestroy')
	for k, bomb in pairs(self.bombs) do
		bomb.effect:stop()
		self.bombs[k] = nil
	end
end


-- API for scripted parts:
-- scripted parts will perform the following functions to initialize the above globalscript


function stickyBomb.server_spawnBomb(pos, velocity, detonationTime) -- can be called from server or from client, it's best to call from server tho
	if not sm.isHost then return end
	
	table.insert(stickyBomb.server_queued, {pos, velocity, detonationTime})
end


