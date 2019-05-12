squarefan = class( nil )
squarefan.maxChildCount = 0
squarefan.maxParentCount = -1
squarefan.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
squarefan.connectionOutput = sm.interactable.connectionType.none
squarefan.colorNormal = sm.color.new(0xffff00ff)
squarefan.colorHighlight = sm.color.new(0xffff00ff)
squarefan.poseWeightCount = 1
squarefan.strength = 1

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
	local logic = false
	local speed = 100
	local hasnumberinput = false
	local parents = self.interactable:getParents()
	for k, v in pairs(parents) do
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			if not hasnumberinput then speed = 0 end
			hasnumberinput = true
			speed = speed + v.power
		else
			--logic 
			if v.power ~= 0 then logic = true end
		end
	end
	speed = speed / 100
	
	if logic and speed ~= 0 then
		local position = self.shape.worldPosition
	
		local right = sm.shape.getRight(self.shape)
		local up = sm.shape.getAt(self.shape)
		local raydir = sm.shape.getUp(self.shape)*7.5*speed
		
		local power = self.shape.mass * self.strength * speed
		
		local cancelout = 150
		local fraction = 0
		for i=-4,4  do -- 100 raycasts: 
			for j=-4,4 do
				local rayposstart = (up*i + right*j)/4.6
				local hit, result = sm.physics.raycast(position + rayposstart, position + rayposstart + raydir)
				if hit then
					local distance = raydir:length()*result.fraction
					local loss = 10/(distance*7/7.5/math.abs(speed)+3)^2-0.1
					if result.type == "body" then
						sm.physics.applyImpulse(result:getShape(), raydir:normalize()*power*loss/cancelout, true)
					elseif result.type == "character" then
						
						local drag = result:getCharacter().velocity*-1.2
						local id = result:getCharacter().id
						if squarefan_playerspulsed[id] == nil then
							squarefan_playerspulsed[id] = {}
							squarefan_playerspulsed[id].vec = sm.vec3.new(0,0,0)
							squarefan_playerspulsed[id].n = 0
							squarefan_playerspulsed[id].ostime = os.clock()
						end
						squarefan_playerspulsed[id].vec = squarefan_playerspulsed[id].vec +   (drag+ raydir:normalize()*power*33*loss/cancelout)
						squarefan_playerspulsed[id].n = squarefan_playerspulsed[id].n + 1
						if squarefan_playerspulsed and (squarefan_playerspulsed[id] == nil or (os.clock() - squarefan_playerspulsed[id].ostime)>0.01) then
							sm.physics.applyImpulse(result:getCharacter(), squarefan_playerspulsed[id].vec/squarefan_playerspulsed[id].n)
							squarefan_playerspulsed[id].ostime = os.clock()
							squarefan_playerspulsed[id].vec = sm.vec3.new(0,0,0)
							squarefan_playerspulsed[id].n = 0
						end
					end
					fraction = fraction + 7.5*speed*result.fraction
				else
					fraction = fraction + 7.5*speed
				end
				--pull from other dir
				local hit2, result2 = sm.physics.raycast(position + rayposstart, position + rayposstart - raydir)
				if hit2 then
					local distance = raydir:length()*result2.fraction
					local loss = 10/(distance*7/7.5/math.abs(speed)+3)^2-0.1
					if result2.type == "body" then
						sm.physics.applyImpulse(result2:getShape(), raydir:normalize()*power*loss/cancelout, true)
					elseif result2.type == "character" then
					
						local drag = result2:getCharacter().velocity*-1.2
						local id = result2:getCharacter().id
						if squarefan_playerspulsed[id] == nil then
							squarefan_playerspulsed[id] = {}
							squarefan_playerspulsed[id].vec = sm.vec3.new(0,0,0)
							squarefan_playerspulsed[id].n = 0
							squarefan_playerspulsed[id].ostime = os.clock()
						end
						squarefan_playerspulsed[id].vec = squarefan_playerspulsed[id].vec +   (drag+ raydir:normalize()*power*33*loss/cancelout)
						squarefan_playerspulsed[id].n = squarefan_playerspulsed[id].n + 1
						if squarefan_playerspulsed and (squarefan_playerspulsed[id] == nil or (os.clock() - squarefan_playerspulsed[id].ostime)>0.01) then
							sm.physics.applyImpulse(result2:getCharacter(), squarefan_playerspulsed[id].vec/squarefan_playerspulsed[id].n)
							squarefan_playerspulsed[id].ostime = os.clock()
							squarefan_playerspulsed[id].vec = sm.vec3.new(0,0,0)
							squarefan_playerspulsed[id].n = 0
						end
					end
					fraction = fraction + 7.5*speed*result2.fraction/5
				else
					fraction = fraction + 7.5*speed/5
				end
				
			end
		end
		local f = (12.5/fraction)^(1/20)
		sm.physics.applyImpulse(self.shape, sm.vec3.new(0,0,-f*power), false)
	end
end


function squarefan.client_onCreate( self )
	self.pose = 0
end

function squarefan.client_onUpdate( self, dt )

	local logic = false
	local speed = 100
	local hasnumberinput = false
	local parents = self.interactable:getParents()
	for k, v in pairs(parents) do
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			if not hasnumberinput then speed = 0 end
			hasnumberinput = true
			speed = v.power + v.power
		else
			--logic 
			if v.power ~= 0 then logic = true end
		end
	end
	speed = speed / 100
	
	if logic and speed ~= 0 then
		local power = self.shape.mass * self.strength * speed
		self.pose = (self.pose + power/70000*1.5)%1
		self.interactable:setPoseWeight(0, self.pose)
	end
end

function squarefan.client_onInteract(self)
end




fan = class( nil )
fan.maxChildCount = 0
fan.maxParentCount = -1
fan.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
fan.connectionOutput = sm.interactable.connectionType.none
fan.colorNormal = sm.color.new(0xffff00ff)
fan.colorHighlight = sm.color.new(0xffff00ff)
fan.poseWeightCount = 1
fan.strength = 1

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
	local logic = false
	local speed = 100
	local hasnumberinput = false
	local parents = self.interactable:getParents()
	for k, v in pairs(parents) do
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			if not hasnumberinput then speed = 0 end
			hasnumberinput = true
			speed = speed + v.power
		else
			--logic 
			if v.power ~= 0 then logic = true end
		end
	end
	speed = speed / 100
	
	if logic and speed ~= 0 then
		local position = self.shape.worldPosition
	
		local right = sm.shape.getRight(self.shape)
		local up = sm.shape.getAt(self.shape)
		local raydir = sm.shape.getUp(self.shape)*7.5*speed
		
		local power = self.shape.mass * self.strength * speed
		
		local fraction = 0
		for i=-4,4  do -- 49 raycasts: 
			for j=-4,4 do
				local rayposstart = (up*i + right*j)/4.6
				if rayposstart:length() < 3.5/4 then --within 3.5 blocks, inside circle
					local hit, result = sm.physics.raycast(position + rayposstart, position + rayposstart + raydir)
					if hit then
						local distance = raydir:length()*result.fraction
						local loss = 10/(distance*7/7.5/math.abs(speed)+3)^2-0.1
						if result.type == "body" then
							sm.physics.applyImpulse(result:getShape(), raydir:normalize()*power*loss/91, true)
						elseif result.type == "character" then
						
						
							local drag = result:getCharacter().velocity*-1.2
							local id = result:getCharacter().id
							if normalfan_playerspulsed[id] == nil then
								normalfan_playerspulsed[id] = {}
								normalfan_playerspulsed[id].vec = sm.vec3.new(0,0,0)
								normalfan_playerspulsed[id].n = 0
								normalfan_playerspulsed[id].ostime = os.clock()
							end
							normalfan_playerspulsed[id].vec = normalfan_playerspulsed[id].vec +  drag + raydir:normalize()*power*loss/2.9
							normalfan_playerspulsed[id].n = normalfan_playerspulsed[id].n + 1
							if normalfan_playerspulsed and (normalfan_playerspulsed[id] == nil or (os.clock() - normalfan_playerspulsed[id].ostime)>0.01) then
								sm.physics.applyImpulse(result:getCharacter(), normalfan_playerspulsed[id].vec/normalfan_playerspulsed[id].n)
								normalfan_playerspulsed[id].ostime = os.clock()
								normalfan_playerspulsed[id].vec = sm.vec3.new(0,0,0)
								normalfan_playerspulsed[id].n = 0
							end
						end
						fraction = fraction + 7.5*speed*result.fraction
					else
						fraction = fraction + 7.5*speed
					end
					--pull from other dir
					local hit2, result2 = sm.physics.raycast(position + rayposstart, position + rayposstart - raydir)
					
					if hit2 then
						local distance = raydir:length()*result2.fraction
						local loss = 10/(distance*7/7.5/math.abs(speed)+3)^2-0.1
						if result2.type == "body" then
							sm.physics.applyImpulse(result2:getShape(), raydir:normalize()*power*loss/91, true)
						elseif result2.type == "character" then
							
							local drag = result2:getCharacter().velocity*-1.2
							local id = result2:getCharacter().id
							if normalfan_playerspulsed[id] == nil then
								normalfan_playerspulsed[id] = {}
								normalfan_playerspulsed[id].vec = sm.vec3.new(0,0,0)
								normalfan_playerspulsed[id].n = 0
								normalfan_playerspulsed[id].ostime = os.clock()
							end
							normalfan_playerspulsed[id].vec = normalfan_playerspulsed[id].vec +  drag + raydir:normalize()*power*loss/2.9
							normalfan_playerspulsed[id].n = normalfan_playerspulsed[id].n + 1
							if normalfan_playerspulsed and (normalfan_playerspulsed[id] == nil or (os.clock() - normalfan_playerspulsed[id].ostime)>0.01) then
								sm.physics.applyImpulse(result2:getCharacter(), normalfan_playerspulsed[id].vec/normalfan_playerspulsed[id].n)
								normalfan_playerspulsed[id].ostime = os.clock()
								normalfan_playerspulsed[id].vec = sm.vec3.new(0,0,0)
								normalfan_playerspulsed[id].n = 0
							end
							
						end
						fraction = fraction + 7.5*speed*result2.fraction/5
					else
						fraction = fraction + 7.5*speed
					end
				end
			end
		end
		local f = (12.5/fraction)^(1/20)
		sm.physics.applyImpulse(self.shape, sm.vec3.new(0,0,-f*power), false)
	end
end


function fan.client_onCreate( self )
	self.pose = 0
end

function fan.client_onUpdate( self, dt )

	local logic = false
	local speed = 100
	local hasnumberinput = false
	local parents = self.interactable:getParents()
	for k, v in pairs(parents) do
		if v:getType() == "scripted" and tostring(v:getShape():getShapeUuid()) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" --[[tickbutton]] then
			-- number
			if not hasnumberinput then speed = 0 end
			hasnumberinput = true
			speed = v.power + v.power
		else
			--logic 
			if v.power ~= 0 then logic = true end
		end
	end
	speed = speed / 100
	
	if logic and speed ~= 0 then
		local power = self.shape.mass * self.strength * speed
		self.pose = (self.pose + power/70000*1.5)%1
		self.interactable:setPoseWeight(0, self.pose)
	end
end

function fan.client_onInteract(self)
end
