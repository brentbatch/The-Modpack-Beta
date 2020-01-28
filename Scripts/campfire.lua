dofile "SE_Loader.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.
if campfire and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end 


campfire = class( globalscript )
campfire.maxParentCount = 1
campfire.maxChildCount = 0
campfire.connectionInput = sm.interactable.connectionType.logic
campfire.connectionOutput = sm.interactable.connectionType.none
campfire.colorNormal = sm.color.new( 0x009999ff  )
campfire.colorHighlight = sm.color.new( 0x11B2B2ff  )
campfire.poseWeightCount = 1

function campfire.server_onCreate( self ) 
	self.trackedShapes = {}
end

function campfire.server_onRefresh( self )
	--self:server_onCreate()
end

function campfire.server_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	if parent then -- logic parent has control
		if parent.active then
			self.interactable.active = true
			self:server_tryFire()
		else
			self.interactable.active = false
		end
		
	elseif self.interactable.active then
		self:server_tryFire()
	end
end

function campfire.server_onProjectile(self, ...)
	self.interactable.active = not self.interactable.active
end

function campfire.server_tryFire( self ) -- self.shape.at is the side flame is on
	-- bullet: (sync send, async/sync behaviour, spread is sync)
	local foundobjects = {}
	local shape = self.shape
	for _, offset in pairs({sm.vec3.new(0,0,0),(self.shape.right+self.shape.up)*0.25,(self.shape.right-self.shape.up)*0.25,(-self.shape.right+self.shape.up)*0.25,-(self.shape.right+self.shape.up)*0.25}) do
		local hit, result = sm.physics.raycast(self.shape.worldPosition + offset, self.shape.worldPosition + offset + sm.vec3.new(0,0,4))--16 blocks up
		if hit then
			if result.type == "character" then
				portedFire.server_spawnFire(
					result.pointWorld,
					sm.vec3.new(0,0,1),
					result
				)
			elseif result.type == "body" then
				local shape = result:getShape()
				if not foundobjects[shape.id] then foundobjects[shape.id] = {distance = 16, shape = shape} end
				if foundobjects[shape.id].distance > result.fraction*16 then
					foundobjects[shape.id].distance = result.fraction*16
					foundobjects[shape.id].result = result
				end
			end
		end
	end
	for shapeid, foundobject in pairs(foundobjects) do -- create tracker if it doesn't exist yet
		if not self.trackedShapes[shapeid] then self.trackedShapes[shapeid] = { timer = 0, shape = foundobject.shape } end
	end
	for shapeid, trackedShape in pairs(self.trackedShapes) do
		if foundobjects[shapeid] then -- count up/spawn fire
			trackedShape.timer = trackedShape.timer + 1/(7*foundobjects[shapeid].distance^1.8)
			if trackedShape.timer > 1 then
				portedFire.server_spawnFire(
					foundobjects[shapeid].result.pointWorld,
					sm.vec3.new(0,0,10),
					foundobjects[shapeid].result
				)
				
				self.trackedShapes[shapeid] = nil
			end
		else -- count down/remove
			trackedShape.timer = trackedShape.timer - 0.1/40 -- 10 sec
			if trackedShape.timer < 0 then
				self.trackedShapes[shapeid] = nil
			end
		end
	end
end

function campfire.server_onInteract(self)
	self.interactable.active = not self.interactable.active
end

-- Client

function campfire.client_onCreate( self )
	self:client_attachScript("portedFire")
	self.shooteffect = sm.effect.createEffect("flames", self.interactable)
	self.shooteffect:setOffsetRotation( sm.vec3.getRotation(sm.vec3.new( 0, 1, 0 ),sm.vec3.new( 0, 0, 1 )))
	self.shooteffect:setOffsetPosition( sm.vec3.new( 0, 0.25, 0 ))
end
function campfire.client_onRefresh(self)
	self:client_onCreate()
end

function campfire.client_onInteract(self)
	self.network:sendToServer('server_onInteract')
end


function campfire.client_onUpdate( self, deltaTime ) -- animation of shooting flame & trigger
	if self.interactable.active then
		if not self.shooteffect:isPlaying() then
			self.shooteffect:start()
		end
	else
		if self.shooteffect:isPlaying() then
			self.shooteffect:stop()
		end
	end
end

function campfire.client_onDestroy(self)
	self.shooteffect:stop()
end
