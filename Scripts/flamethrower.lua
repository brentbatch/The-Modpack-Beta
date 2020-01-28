dofile "SE_Loader.lua"


-- the following code prevents re-load of this file, except if in '-dev' mode.
if flamethrower and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end 


flamethrower = class( globalscript )
flamethrower.maxParentCount = 1
flamethrower.maxChildCount = 0
flamethrower.connectionInput = sm.interactable.connectionType.logic
flamethrower.connectionOutput = sm.interactable.connectionType.none
flamethrower.colorNormal = sm.color.new( 0x009999ff  )
flamethrower.colorHighlight = sm.color.new( 0x11B2B2ff  )
flamethrower.poseWeightCount = 1
flamethrower.fireDelay = 11 --ticks

function flamethrower.server_onCreate( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function flamethrower.server_onRefresh( self )
	self:server_onCreate()
end

function flamethrower.server_onFixedUpdate( self, dt )
	if not self.canFire then
		self.fireDelayProgress = self.fireDelayProgress + 1
		if self.fireDelayProgress >= self.fireDelay then
			self.fireDelayProgress = 0
			self.canFire = true	
		end
	end
	self:server_tryFire(dt)
	local parent = self.interactable:getSingleParent()
	if parent then
		self.parentActive = parent:isActive()
	end
	
end



function flamethrower.server_tryFire( self, dt )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and self.canFire then
			-- bullet: (sync send, async/sync behaviour, spread is sync)
			self.canFire = false
			local dir = sm.noise.gunSpread(-self.shape.right, 7 ) * 20 * math.random(9800,10000)/10000
			local extra = dir*dir:dot(self.shape.velocity)*0.0015 -- velocity correction
			if extra:dot(dir) > 0 then dir = dir + extra end  -- velocity correction
		
			-- fire (sync send, async behaviour)
			local hit, result =  sm.physics.raycast( self.shape.worldPosition, self.shape.worldPosition - self.shape.right*1.5 )
			
			portedFire.server_spawnFire(
				self.shape.worldPosition - self.shape.right*1.3 + self.shape.at*0.1 + self.shape.velocity * dt * 2, -- delay correction
				dir,
				result
			)
		end
	end
end

-- Client

function flamethrower.client_onCreate( self )
	self:client_attachScript("portedFire")
	self.boltValue = 0.0
	self.shooteffect = sm.effect.createEffect("flame", self.interactable)
	self.shooteffect:setOffsetRotation(  sm.vec3.getRotation(sm.vec3.new( 1, 0, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:setOffsetPosition( sm.vec3.new( -5/4, 1/6.5, -1/100 ))
	self.time = 0
end
function flamethrower.client_onRefresh(self)
	--self:client_onCreate()
end


function flamethrower.client_onDestroy(self)
	self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
	self.shooteffect:stop()
end

function flamethrower.client_onUpdate( self, deltaTime ) -- animation of shooting flame & trigger
	self.time = self.time + deltaTime
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() then
			if not self.shooteffect:isPlaying() or self.time > 0.8 then
				self.shooteffect:setOffsetPosition( sm.vec3.new( -5/4, 1/6.5, -1/100 ))
				self.shooteffect:start()
				self.time = 0
			end
		else
			if self.shooteffect:isPlaying() then
				self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
				self.shooteffect:stop()
			end
		end
	end
	if self.boltValue > 0.0 and (not parent or not parent:isActive()) then
		self.boltValue = self.boltValue - deltaTime * 10
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
end





biglighter = class( globalscript )
biglighter.maxParentCount = 1
biglighter.maxChildCount = 0
biglighter.connectionInput = sm.interactable.connectionType.logic
biglighter.connectionOutput = sm.interactable.connectionType.none
biglighter.colorNormal = sm.color.new( 0x009999ff  )
biglighter.colorHighlight = sm.color.new( 0x11B2B2ff  )
biglighter.poseWeightCount = 1
biglighter.fireDelay = 3 --ticks

function biglighter.server_onCreate( self ) 
	self:server_init()
end

function biglighter.server_init( self ) 
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false
end

function biglighter.server_onRefresh( self )
	self:server_init()
end

function biglighter.server_onFixedUpdate( self, timeStep )
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
end



function biglighter.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and self.canFire then
			self.canFire = false
			
			-- fire (sync send, async behaviour)
			local dir = sm.noise.gunSpread(-self.shape.right, 30 )*3
			local hit, result =  sm.physics.raycast( self.shape.worldPosition, self.shape.worldPosition + dir )
			if hit then
				portedFire.server_spawnFire(
					self.shape.worldPosition - self.shape.right/4, 
					dir,
					result
				)
			end
		end
	end
end

-- Client

function biglighter.client_onCreate( self )
	self:client_attachScript("portedFire")
	self.boltValue = 0.0
	self.shooteffect = sm.effect.createEffect("flame", self.interactable)
	self.shooteffect:setOffsetRotation(  sm.vec3.getRotation(sm.vec3.new( 1, 0, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:setOffsetPosition( sm.vec3.new( -5/4, 1/13, -1/100 ))
	self.time = 0
end
function biglighter.client_onRefresh(self)
	self:client_onCreate()
end


function biglighter.client_onDestroy(self)
	self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
	self.shooteffect:stop()
end

function biglighter.client_onUpdate( self, deltaTime ) -- animation of shooting flame & trigger
	self.time = self.time + deltaTime
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() then
			if not self.shooteffect:isPlaying() or self.time > 0.8 then
				self.shooteffect:setOffsetPosition( sm.vec3.new( -5/4, 1/13, -1/100 ))
				self.shooteffect:start()
				self.time = 0
			end
		else
			if self.shooteffect:isPlaying() then
				self.shooteffect:setOffsetPosition( sm.vec3.new( 1000, 1000, 100000 ))
				self.shooteffect:stop()
			end
		end
	end
	if self.boltValue > 0.0 and (not parent or not parent:isActive()) then
		self.boltValue = self.boltValue - deltaTime * 10
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
end


