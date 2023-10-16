AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

if SERVER then
	function ENT:Initialize()  
		self:SetSolid(SOLID_BBOX)
		
		local bbox = (self.max-self.min)/2
	
		self:PhysicsInitBox(-bbox, bbox)
		self:SetCollisionBoundsWS(self.min,self.max)
	
		self:SetTrigger(true)
		self:DrawShadow(false)
		self:SetNotSolid(true)
		self:SetNoDraw(false)
	
		self.Phys = self:GetPhysicsObject()
		if(self.Phys and self.Phys:IsValid()) then
			self.Phys:Sleep()
			self.Phys:EnableCollisions(false)
		end
	end

	function ENT:StartTouch(ent)  
		if(ent:IsValid() && ent:IsPlayer()) then
			GAMEMODE:SetNoJump(ent,true,self.targetpos,self.targetang)
		end
	end

	function ENT:EndTouch(ent)  
		if(ent:IsValid() && ent:IsPlayer()) then
			GAMEMODE:SetNoJump(ent,false)
		end
	end
else
	function ENT:Initialize() 
	end 

	function ENT:Draw()
	end
end