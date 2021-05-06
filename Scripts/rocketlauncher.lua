--[[
	Copyright (c) 2019 Brent Batch
	Contact: Brent Batch#9261 on discord
]]--
dofile "SE_Loader.lua"


rocketlauncher = class( globalscript )
rocketlauncher.maxParentCount = 1
rocketlauncher.maxChildCount = 0
rocketlauncher.connectionInput = sm.interactable.connectionType.logic
rocketlauncher.connectionOutput = sm.interactable.connectionType.none
rocketlauncher.colorNormal = sm.color.new( 0x009999ff  )
rocketlauncher.colorHighlight = sm.color.new( 0x11B2B2ff  )
rocketlauncher.fireDelay = 20 --ticks
rocketlauncher.minForce = 1
rocketlauncher.maxForce = 1.02
rocketlauncher.livetime = 20
rocketlauncher.spreadDeg = 3

function rocketlauncher.server_onRefresh( self )
	self:server_onCreate()
end

function rocketlauncher.client_onCreate(self)
	self:client_attachScript("customProjectile")
end

function rocketlauncher.server_onCreate( self ) 
	self.projectileConfiguration = {
		localPosition = true,			-- when true, position is relative to shape position and rotation
	    localVelocity = true,			-- when true, position is relative to shape position and rotation
	    position = sm.vec3.new(-0.5,0,0), -- required
	    velocity = sm.vec3.new(-1,0,0),	-- required
		rotation = sm.vec3.new(0,0,-1), -- default: vec3(0,0,1) 	getRotation(rotationValue, projectileVelocity:normalize())
	    acceleration = 0.9, 			-- default: 0  				adds (acceleration*normalized velocity) to velocity each tick,
	    friction = 0.002, 				-- default: 0.003			velocity = velocity*(1-friction)
	    gravity = 0.5, 					-- default: gamegrav or 10	adds (gravity*dt) to velocity each tick
	    effect = "Rocket", 				-- default: "CannonShot"	effect used for the projectile
	    size = 1, 						-- default: 1 (blocks)		used for projectile collision detection
	    lifetime = 60, 					-- default: 30 (seconds)	projectile will explode after this amount of time in air
	    --spawnAudio = "CannonAudio", 	-- default: nil (no audio)	effect used for the audio upon spawn
	    destructionLevel = 6, 			-- default: 6				1: cardboard, 2: cautionblock(plastic), 3: wood, 4: concrete(stone), 5: metal, 6: everything?
	    destructionRadius = 6.5, 		-- default: 0.13 (meters)	1 meter = 4 blocks
	    impulseRadius = 8, 				-- default: 0.5	(meters)	radius in which players/blocks will be pushed
	    magnitude = 30, 				-- default: 10				defines how hard players/blocks will be pushed
		explodeEffect = "PropaneTank - ExplosionBig" 			-- default: "PropaneTank - ExplosionSmall" 	effect used for explosion
	}
	self.server_spawnProjectile = customProjectile.server_spawnProjectile
end

function rocketlauncher.server_onFixedUpdate( self, timeStep )
	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if active and not self.timeout then
		self.timeout = self.fireDelay
		
		local fireForce = math.random( self.minForce, self.maxForce )
		local dir = sm.noise.gunSpread( sm.vec3.new(-1,0,0), self.spreadDeg )
		local extra = dir*dir:dot(self.shape:transformPoint(self.shape.worldPosition + self.shape.velocity))*1.3
		if extra:dot(dir) > 0 then dir = dir + extra end
		
		self.projectileConfiguration.velocity = dir * fireForce
		self:server_spawnProjectile(self.projectileConfiguration)
	end
	
	if self.timeout then -- lazy way to generate timeout
		self.timeout = self.timeout - 1
		if self.timeout < 0 and not active then
			self.timeout = nil
		end
	end
end



















