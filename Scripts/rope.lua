Rope = class()	Rope.maxChildCount = 10	Rope.maxParentCount = 10	Rope.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power	Rope.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power	Rope.colorNormal = sm.color.new(0xff0000ff)	Rope.colorHighlight = sm.color.new(0xff3333ff)	Rope.poseWeightCount = 3		function Rope.server_onFixedUpdate( self, dt ) 	  local doRaycast = false	  local deltalength = 0	  	  for k, parent in pairs(self.interactable:getParents()) do	    local power = parent.power	    if power ~= 0 then	      color = tostring(parent:getShape().color) 	      if color == "eeeeeeff" then 	        doRaycast = true 	      elseif color == "222222ff" then 	        self:server_setConnectedShape() 	      elseif color == "f5f071ff" then 	        deltalength = deltalength - 0.05 	      elseif color == "e2db13ff" then 	        deltalength = deltalength + 0.05 	      else 	        deltalength = deltalength + power * 0.05 	      end 	    end 	  end 	   	  if doRaycast and not self.didRaycast then 	    local startPos = self.shape.worldPosition 	    local destPos = startPos + self.shape.up * 25 	    local hit, result = sm.physics.raycast(startPos,destPos) 	    if hit and result.type == "body" or result.type == "shape" then 	      local shape = result:getShape() 	      self:server_setConnectedShape({shape,sm.shape.transformPoint(shape,result.pointWorld)}) 	    end 	  end 	  self.didRaycast = doRaycast 	   	  if self.connectedShape then     	    if not sm.exists(self.connectedShape[1]) then self:server_setConnectedShape() return end 	     	    local globalOffset = getGlobal(self.connectedShape[1], self.connectedShape[2]) 	    local ropeVector = self.connectedShape[1].worldPosition + globalOffset - self.shape.worldPosition 	    local currentLength = ropeVector:length() 	     	    if not self.maxLength then 	      self.maxLength = currentLength 	    end 	    if deltalength ~= 0 then 	      self.maxLength = sm.util.clamp(self.maxLength + deltalength, 0.25, 125) 	    end 	     	    local err = currentLength - self.maxLength 	    if err > 20 then 	      self:server_setConnectedShape() 	      return 	    end 	    if err < 0 then return end 	     	    if not self.prev_err then self.prev_err = err end 	     	     	    local selfShape = self.shape 	    local remoteShape = self.connectedShape[1] 	    local mass1 = getTotalMass(selfShape.body) 	    local mass2 = getTotalMass(remoteShape.body) 	    local mass = (mass1 < mass2) and mass1 or mass2 	     	    local force = ropeVector:normalize() * (((err * 0.4 * mass) + ((err - self.prev_err) * 5 * mass))) 	     	    self.prev_err = err 	     	    sm.physics.applyTorque( selfShape.body, sm.body.getAngularVelocity( selfShape.body ) * dt * mass1 * -0.5 , true ) 	    sm.physics.applyTorque( remoteShape.body, sm.body.getAngularVelocity( remoteShape.body ) * dt * mass2 * -0.5 , true ) 	     	    sm.physics.applyImpulse( selfShape, force, true ) 	    sm.physics.applyImpulse( remoteShape, -force, true, globalOffset ) 	  else 	    if self.maxLength then 	      self.maxLength = nil 	    end 	  end	end		function Rope.server_setConnectedShape(self, connectedShape)	  self.network:sendToClients("client_setConnectedShape",connectedShape)	  self.interactable.active = not not connectedShape	end		function Rope.server_clientRequestConnected(self)	  if not self.connectedShape then return end	  self.network:sendToClients("client_setConnectedShape",self.connectedShape)	end				function Rope.client_setConnectedShape(self, connectedShape)	  self.connectedShape = connectedShape	end			function Rope.client_onCreate( self )	  self:client_reset()	  self.network:sendToServer("server_clientRequestConnected")	end		function Rope.client_onUpdate( self, dt )	  if self.connectedShape and sm.exists(self.connectedShape[1]) then	    local connectedShape = self.connectedShape[1]	    local connectedPosition = connectedShape.worldPosition + connectedShape.velocity * dt + getGlobal(connectedShape, self.connectedShape[2])	    local ropeVec = sm.shape.transformPoint(self.shape, connectedPosition)	    	    --[[ -- try to fix the janky wire: [doesn't work]	    --local angvel = sm.body.getAngularVelocity( self.shape.body ) * dt	    --	    --ropeVec = sm.vec3.rotateY( ropeVec, angvel.y)	    --ropeVec = sm.vec3.rotateX( ropeVec, angvel.x)	    --ropeVec = sm.vec3.rotateZ( ropeVec, angvel.z)]]	    	    self.interactable:setPoseWeight(0, 0.5 - (ropeVec.x) * 0.002)	    self.interactable:setPoseWeight(1, 0.5 + (ropeVec.y) * 0.002)	    self.interactable:setPoseWeight(2, 0.5 - (ropeVec.z) * 0.002)	  else	    self:client_reset()	  end	end		function Rope.client_reset(self)	  if not sm.exists(self.interactable) then return end	  for i=0,2 do	    self.interactable:setPoseWeight(i,0.5)	  end	end			function getTotalMass(body)	  local x = 0	  for _, body in pairs(body:getCreationBodies()) do	    x = x + body.mass	  end	  return x	end		function getGlobal(shape, vec)	  return shape.right * vec.x + shape.at * vec.y + shape.up * vec.z	end