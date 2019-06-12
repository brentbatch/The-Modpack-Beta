squarefan = class( nil )
squarefan.maxChildCount = 0
squarefan.maxParentCount = -1
squarefan.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
squarefan.connectionOutput = sm.interactable.connectionType.none
squarefan.colorNormal = sm.color.new(0xffff00ff)
squarefan.colorHighlight = sm.color.new(0xffff00ff)
squarefan.poseWeightCount = 1



function squarefan.server_onCreate( self )
	self:server_init()
end

function squarefan.server_onRefresh( self )
	self:server_init()
end

function squarefan.server_init( self )
	if squarefan_playerspulsed == nil then squarefan_playerspulsed = {} end
end


function squarefan.server_onFixedUpdate( self, dt )
	local speed = fanfunctions.getSpeed(self)
	
	fanfunctions.apply()
	
	if speed ~= 0 then
		local position = self.shape.worldPosition
	
		local right = sm.shape.getRight(self.shape)
		local up = sm.shape.getAt(self.shape)
		local raydir = sm.shape.getUp(self.shape)*7.5*speed
		
		for i=-4,4  do -- 100 raycasts: 
			for j=-4,4 do
				local rayposstart = (up*i + right*j)/4.6
				fanfunctions.fanCast( position + rayposstart, raydir, speed)
				fanfunctions.fanCast( position + rayposstart, raydir * -1, speed*-1)
			end
		end
		sm.physics.applyImpulse( self.shape, sm.vec3.new(0,0,952.5 * speed) * -1)
	end
end


function squarefan.client_onCreate( self )
	self.pose = 0
	self.interactable:setAnimEnabled( "AnimY", true )
end

function squarefan.client_onUpdate( self, dt )
	local speed = fanfunctions.getSpeed(self)
	
	if speed ~= 0 then
		local power = self.shape.mass * speed
		self.pose = (self.pose + power/70000*1.5)%1
		self.interactable:setAnimProgress( "AnimY", self.pose)
	end
end

function squarefan.client_onInteract(self)
end


--=============================================================--

-- server functions:

if not wind then wind = {lasttick = sm.game.getCurrentTick(), pulses = {}} end


fanfunctions = {}
function fanfunctions.getSpeed(self)
	local logic = false
	local speed = nil
	local parents = self.interactable:getParents()
	for k, v in pairs(parents) do
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			speed = (speed or 0) + v.power
		else
			--logic 
			if v.active then logic = true end
		end
	end
	return (logic and ((speed or 100) / 100) or 0)
end


function fanfunctions.fanCast( raystart, raydir, speed) -- returns distance
	local hit, result = sm.physics.raycast(raystart, raystart + raydir)
	if hit then
		local distance = raydir:length() * result.fraction
		
		local loss = 10/(distance+4)
		
		local impulse = raydir:normalize() * speed * loss^(2)
		
		
		if result.type == "body" then
			local shape = result:getShape()
			wind.pulses[shape.id] = { pulse = (wind.pulses[shape.id] and wind.pulses[shape.id].pulse or sm.vec3.new(0,0,0)) + impulse , ref = shape }
			
		elseif result.type == "character" then
			local character = result:getCharacter()
			local drag = result:getCharacter().velocity*-0.15
			wind.pulses[character.id] = { pulse = (wind.pulses[character.id] and wind.pulses[character.id].pulse or sm.vec3.new(0,0,0)) + impulse*5 + drag , ref = character }
		end
	end
end

function fanfunctions.apply()
	if wind.lasttick == sm.game.getCurrentTick() then return end
	wind.lasttick = sm.game.getCurrentTick()
	
	for k,windpulse in pairs(wind.pulses) do
		if sm.exists(windpulse.ref) then
			sm.physics.applyImpulse( windpulse.ref, windpulse.pulse, true)
		end
	end
	wind.pulses = {} -- clear table
end

function fanfunctions.getGlobal(shape, vec)
    return shape.right* vec.x + shape.at * vec.y + shape.up * vec.z
end
function fanfunctions.getLocal(shape, vec)
    return sm.vec3.new(shape.right:dot(vec), shape.at:dot(vec), shape.up:dot(vec))
end


--=============================================================--






fan = class( nil )
fan.maxChildCount = 0
fan.maxParentCount = -1
fan.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
fan.connectionOutput = sm.interactable.connectionType.none
fan.colorNormal = sm.color.new(0xffff00ff)
fan.colorHighlight = sm.color.new(0xffff00ff)
fan.poseWeightCount = 1

function fan.server_onCreate( self )
	self:server_init()
end

function fan.server_onRefresh( self )
	self:server_init()
end

function fan.server_init( self )
	if normalfan_playerspulsed == nil then normalfan_playerspulsed = {} end
end


function fan.server_onFixedUpdate( self, dt )
	local speed = fanfunctions.getSpeed(self)
	
	fanfunctions.apply()
	if speed ~= 0 then
		local position = self.shape.worldPosition
	
		local right = self.shape.right
		local up = self.shape.at
		local raydir = self.shape.up*7.5*speed
		
		for i=-4,4  do
			for j=-4,4 do
				local rayposstart = (up*i + right*j)/4.6
				if rayposstart:length() < 3.5/4 then --within 3.5 blocks, inside circle
				
					fanfunctions.fanCast( position + rayposstart, raydir, speed)
					fanfunctions.fanCast( position + rayposstart, raydir * -1, speed*-1)
					
				end
			end
		end
		sm.physics.applyImpulse( self.shape, sm.vec3.new(0,0,574 * speed) * -1)
	end
end


function fan.client_onCreate( self )
	self.pose = 0
	self.interactable:setAnimEnabled( "Fan", true )
end

function fan.client_onUpdate( self, dt )
	local speed = fanfunctions.getSpeed(self)
	
	if speed ~= 0 then
		local power = self.shape.mass * speed
		self.pose = (self.pose + power/70000*1.5)%1
		self.interactable:setAnimProgress( "Fan", self.pose)
	end
end

function fan.client_onInteract(self)
end
