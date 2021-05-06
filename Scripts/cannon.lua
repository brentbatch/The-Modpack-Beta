--[[
	Copyright (c) 2019 Brent Batch
	Contact: Brent Batch#9261 on discord
]]--
dofile "SE_Loader.lua"


cannon = class( globalscript )
cannon.maxParentCount = 1
cannon.maxChildCount = 0
cannon.connectionInput = sm.interactable.connectionType.logic
cannon.connectionOutput = sm.interactable.connectionType.none
cannon.colorNormal = sm.color.new( 0x009999ff  )
cannon.colorHighlight = sm.color.new( 0x11B2B2ff  )
cannon.fireDelay = 20 --ticks
cannon.minForce = 35
cannon.maxForce = 40
cannon.spreadDeg = 1

function cannon.server_onRefresh( self )
	self:server_onCreate()
end

function cannon.client_onCreate(self)
	self:client_attachScript("customProjectile")
end

function cannon.server_onCreate( self ) 
	self.projectileConfiguration = {
		localPosition = true,			-- when true, position is relative to shape position and rotation
	    localVelocity = true,			-- when true, position is relative to shape position and rotation
	    position = sm.vec3.new(0,0,0.5), -- required
	    velocity = sm.vec3.new(0,0,37), -- required
	    --acceleration = 0, 			-- default: 0  				adds (acceleration*normalized velocity) to velocity each tick,
	    --friction = 0.003, 			-- default: 0.003			velocity = velocity*(1-friction)
	    --gravity = 10, 				-- default: gamegrav or 10	adds (gravity*dt) to velocity each tick
	    effect = "CannonShot", 			-- default: "CannonShot"	effect used for the projectile
	    size = 1, 						-- default: 1 (blocks)		used for projectile collision detection
	    lifetime = 60, 					-- default: 30 (seconds)	projectile will explode after this amount of time in air
	    spawnAudio = "CannonAudio", 	-- default: nil (no audio)	effect used for the audio upon spawn
	    destructionLevel = 6, 			-- default: 6				1: cardboard, 2: cautionblock(plastic), 3: wood, 4: concrete(stone), 5: metal, 6: everything?
	    destructionRadius = 0.13, 		-- default: 0.13 (meters)	1 meter = 4 blocks
	    impulseRadius = 1, 				-- default: 0.5	(meters)	radius in which players/blocks will be pushed
	    magnitude = 3, 					-- default: 10				defines how hard players/blocks will be pushed
		explodeEffect = "PropaneTank - ExplosionSmall" 			-- default: "PropaneTank - ExplosionSmall" 	effect used for explosion
	}
	self.server_spawnProjectile = customProjectile.server_spawnProjectile
end

function cannon.server_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	local active = parent and parent.active

	if active and not self.timeout then
		self.timeout = self.fireDelay
		
		local fireForce = math.random( self.minForce, self.maxForce )
		local dir = sm.noise.gunSpread( sm.vec3.new(0,0,1), self.spreadDeg )
		
		self.projectileConfiguration.velocity = dir * fireForce
		self:server_spawnProjectile(self.projectileConfiguration)
		
		local mass = 50
		local impulse = -dir * fireForce * mass
		sm.physics.applyImpulse( self.shape, impulse, true )
	end
	
	if self.timeout then -- lazy way to generate timeout
		self.timeout = self.timeout - 1
		if self.timeout < 0 and not active then
			self.timeout = nil
		end
	end
end









