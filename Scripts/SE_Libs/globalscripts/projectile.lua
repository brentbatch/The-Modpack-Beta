--[[
	Copyright (c) 2019 Scrap Essentials Team
]]--

-- SHELL SCRIPT, manages projectiles it spawns

local __projectile = { -- only referencable in this file in this mod.
	classes = {},
	scripts = {},
	queuedScripts = {}
}

local description = sm.json.open("$MOD_DATA/description.json")
local __localId = description.localId -- the localid of the mod loading this file

-- ANTI COPY: (only prevents copy when compiled)
if sm.player.getAllPlayers()[1].name ~= "Brent Batch" and __localId ~= "84ff6b74-26d6-4f74-9552-27f3641a3d9a" --[[SE]] and __localId ~= "05b8d810-8320-4a51-856a-b9d21d0f4f17" --[[mp beta local]] and __localId ~= "47ddf902-b0b8-41c7-8f0c-aff1e61e4309" --[[mp beta]] then -- allowedMods
	assert(false, "YOU ARE NOT ALLOWED TO COPY THIS SCRIPT, THY FOUL THIEF")
	while true do end
end

for scriptname, projectile_script in pairs(sm.jsonReader.readFile("Scripts/SE_Libs/globalscripts/projectiles/projectileList.json") or {}) do
	-- __localId..scriptname so it's 'random' but still unique (no cross mod collision)
	dofile("$CONTENT_"..__localId.."/Scripts/SE_Libs/globalscripts/projectiles/"..projectile_script.script)
	__projectile.classes[__localId..":"..scriptname] = _G[projectile_script.class]
	print('projectileScript loading:',projectile_script)
end


-- a SINGLE globalscript, this could be a script taking care of all fire instances, or all custom projectiles
projectile = {} -- MANAGER

-- network callback, subscripts will call this: 
function projectile.script_callback(self, data) 
	local scriptUUID, functionName = data[1], data[2]
	
	if __projectile.scripts[scriptUUID] and __projectile.scripts[scriptUUID][functionName] then
		__projectile.scripts[scriptUUID][functionName]( __projectile.scripts[scriptUUID], data[3] )
	elseif __projectile.scripts[scriptUUID] then
		sm.log.error("lua "..(sm.isServerMode( ) and "client" or "server").." request - callback does not exist: '"..functionName.."'")
	end
end



function projectile.server_onCreate(self, ...)
	
end

function projectile.server_onFixedUpdate(self, dt)
	--print('projectilescript.server_onFixedUpdate')
	for uuid, instance in pairs(__projectile.scripts) do
		if instance.server_onFixedUpdate then
			instance:server_onFixedUpdate(dt)
		end
	end
	for uuid, queued in pairs(__projectile.queuedScripts) do-- go create the projectile on client!
		self.network:sendToClients("client_addProjectile", queued)
		__projectile.queuedScripts[uuid] = nil
	end
end


--client: 

function projectile.client_onCreate(self, ...)
	--print('projectilescript.client_onCreate')
	
	--ask server for existing projectiles ? 
end

function projectile.client_onFixedUpdate(self,dt)
	--print('projectilescript.client_onFixedUpdate')
	for k, instance in pairs(__projectile.scripts) do
		if instance.client_onFixedUpdate then
			instance:client_onFixedUpdate(dt)
		end
	end
end

function projectile.client_addProjectile(self, queued)
	local uuid, __scriptName, server_data, data = queued[1], queued[2], queued[3][1], queued[3][2]
	
	local instance = class(__projectile.classes[__scriptName])
	for k, v in pairs(server_data) do instance[k] = v end
	
	instance.uuid = uuid
	instance.__script = __scriptName
	instance.network = {
		sendToClients = function(_, clientFunction, data) -- TODO: sm.isServerMode( )
			self.network:sendToClients("script_callback", {uuid, clientFunction, data})
		end,
		sendToServer = function(_, serverFunction, data) -- TODO: sm.isServerMode( )
			self.network:sendToServer("script_callback", {uuid, serverFunction, data})
		end
	}
	
	function instance.destroy(self)
		if instance.client_onDestroy then
			instance:client_onDestroy()
		end
		__projectile.scripts[uuid] = nil
	end
	
	__projectile.scripts[uuid] = instance
	--print('projectile.client_addProjectile', queued)
	
	instance:client_onCreate(__projectile.scripts, unpack(data))--might require network, so adding network first
end

function projectile.onDestroy(self)
	print('projectileScript onDestroy')
	for k, instance in pairs(__projectile.scripts) do
		instance:destroy()
	end
end



-- API for scripted parts:
-- scripted parts will perform the following functions to initialize the above globalscript
Projectile = {}
local didOnce = false
function Projectile.client_init(self, scriptclass)
	sm.globalScript.client_init(self, scriptclass)
	if not didOnce then
		didOnce = true
		sm.globalScript.server_addScript("projectile" --[[,params]]) -- "projectile" from globalscripts.json
	end
end

-- function so scripted parts can spawn projectile instances
function Projectile.server_spawnProjectile(scriptName, ...) -- params like, shape it's attached to , or whatever
	if not sm.isHost then return end
	local __scriptName = sm.jsonReader.getDescription().localId..":"..scriptName
	local script = __projectile.classes[__scriptName]
	
	assert(script, "projectile.server_spawnProjectile: "..scriptName.." does not exist!")
	--print('Projectile.server_spawnProjectile', scriptName)
	
	local uuid = tostring(sm.uuid.new())	
	local self = {}
	if script.server_onCreate then
		local canCreate = script.server_onCreate(self, __projectile.scripts, ...) -- give all scripts so it can do a density check
		if canCreate ~= false then
			__projectile.queuedScripts[uuid] = {uuid, __scriptName, {self, {}}} -- raycastresult over the network kills all data send
		end
	else
		__projectile.queuedScripts[uuid] = {uuid, __scriptName, {self, {...}}}
	end
end


