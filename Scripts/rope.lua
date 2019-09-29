function print()   end

local getRight = sm.shape.getRight
local getAt = sm.shape.getAt
local getUp = sm.shape.getUp

local getWorldPosition = sm.shape.getWorldPosition
local raycast = sm.physics.raycast
local applyImpulse = sm.physics.applyImpulse

local getBodies = sm.body.getCreationBodies
local getMass = sm.body.getMass

function getCreationMass(body)
	local total = 0
	for k,o in pairs(getBodies(body)) do
		total = total + getMass(o)
	end
	return total
end

local newVec = sm.vec3.new
local lenVec = sm.vec3.length

local getX = sm.vec3.getX
local getY = sm.vec3.getY
local getZ = sm.vec3.getZ

local clamp = sm.util.clamp
local isAnyOf = sm.util.isAnyOf
local getLocal = sm.shape.transformPoint

function getGlobal(shape, vec)
	return sm.shape.getRight(shape)* vec.x + sm.shape.getAt(shape) * vec.y + sm.shape.getUp(shape) * vec.z
end

Hitwo_Rope = class( nil )
Hitwo_Rope.maxChildCount = 10
Hitwo_Rope.maxParentCount = 10
Hitwo_Rope.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
Hitwo_Rope.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
Hitwo_Rope.colorNormal = sm.color.new(0xff0000ff)
Hitwo_Rope.colorHighlight = sm.color.new(0xff3333ff)
Hitwo_Rope.poseWeightCount = 3

function Hitwo_Rope.server_onCreate( self )
end

function Hitwo_Rope.server_onDestroy(self)
end

function Hitwo_Rope.server_onRefresh( self )
end

function Hitwo_Rope.server_init( self )
end

function Hitwo_Rope.client_setPair(self, pair)
	self.pair = pair
end

function Hitwo_Rope.server_setPair(self, pair)
	self.interactable:setActive(pair ~= nil)
	self.pair = pair
end

function Hitwo_Rope.setPair(self, pair)
	self.pair = pair
	if sm.isHost then
		self.network:sendToClients("client_setPair",pair)
		self.interactable:setActive(pair ~= nil)
	else
		self.network:sendToServer("server_setPair",pair)
	end
end

function Hitwo_Rope.server_onFixedUpdate( self, dt )
	local control = false
	local reel = 0
	
	for k,o in pairs(self.interactable:getParents()) do
		local power = o:getPower()
		if power ~= 0 then
			color = tostring(o:getShape().color)
			if color == "eeeeeeff" then
				control = true
			elseif color == "7f7f7fff" then
				self:setPair(nil)
			elseif color == "f5f071ff" then
				reel = reel - 0.05
			elseif color == "e2db13ff" then
				reel = reel + 0.05
			else
				reel = reel + o:getPower() * 0.05
			end
		end
	end
	
	if control and not self.prevControl then
		self.prevControl = true
		local startPos = self.shape:getWorldPosition()
		local destPos = startPos + self.shape.up * 25
		local hit, res = raycast(startPos,destPos)
		if hit then
			local shape = res:getShape()
			if shape then
				local wpos = getWorldPosition(shape)
				print(shape)
				self:setPair({shape,getLocal(shape,res.pointWorld)})
			end
		end
	elseif not control and self.prevControl then
		self.prevControl = false
	end
	
	if self.pair then
		if reel ~= 0 and self.maxLength ~= nil then
			self.maxLength = clamp(self.maxLength + reel,0.25,125)
		end
		
		local pos = getWorldPosition(self.shape)
		local succ, pairPos = pcall(getWorldPosition,self.pair[1])
		
		if not succ then
			self:setPair(nil)
			return
		end
		
		local globalOffset = getGlobal(self.pair[1],self.pair[2])
		
		local vecToPair = pairPos + globalOffset - pos
		local currentLength = lenVec(vecToPair)
		
		if self.maxLength == nil then
			self.maxLength = currentLength
		end
		
		if currentLength - self.maxLength > 20 then
			self:setPair(nil)
			return
		end
		
		local err = currentLength-self.maxLength
		err = err > 0 and err or 0
		
		local prev_err = 0
		if self.prev_err then
			prev_err = err
		end
		
		local ropeVectorNormal = vecToPair:normalize()
		
		local mass1 = getCreationMass(self.shape.body)
		local mass2 = getCreationMass(self.pair[1].body)
		local mass = mass1 < mass2 and mass1 or mass2
		
		local force = ropeVectorNormal * (((err * 0.4 * mass) + ((err-prev_err) * 2 * mass)))
		
		self.prev_err = err
		
		print(currentLength/self.maxLength)

		if currentLength > self.maxLength then
			applyImpulse(
				self.shape,
				force,
				true
			)
			applyImpulse(
				self.pair[1],
				-force,
				true,
				globalOffset
			)
		end
	else
		if self.maxLength then
			self.maxLength = nil
		end
	end
end

function Hitwo_Rope.client_onCreate( self )
	self.interactable:setPoseWeight(0,0.5)
	self.interactable:setPoseWeight(1,0.5)
	self.interactable:setPoseWeight(2,0.5)
end

function Hitwo_Rope.client_onUpdate( self, dt )
	if self.pair then
		local pair = self.pair[1]
		local pos = getWorldPosition(self.shape)
		local pairPos = getWorldPosition(pair) + getGlobal(pair,self.pair[2])
		local locVec = getLocal(self.shape,pairPos)
		
		self.interactable:setPoseWeight(0,1 - (0.5 + getX(locVec) * 0.002))
		self.interactable:setPoseWeight(1,(0.5 + getY(locVec) * 0.002))
		self.interactable:setPoseWeight(2,1 - (0.5 + getZ(locVec) * 0.002))
	else
		self.interactable:setPoseWeight(0,0.5)
		self.interactable:setPoseWeight(1,0.5)
		self.interactable:setPoseWeight(2,0.5)
	end
end