local Zone = {
	MStart = 0,
	MEnd = 1,
	BStart = 2,
	BEnd = 3,
	FS = 5,
	AC = 4,
	BAC = 7, 
	NAC = 6
}

local DrawArea = {
	[Zone.MStart] = Color( 255, 255, 255 ),
	[Zone.MEnd] = Settings:GetValue("EndZone"),
	[Zone.BStart] = Settings:GetValue("BonusStart"),
	[Zone.BEnd] = Settings:GetValue("BonusEnd"),
	[Zone.FS] = Color( 0, 80, 255 ),
	[Zone.AC] = Color(153, 0, 153, 100),
	[Zone.BAC] = Color(0, 0, 153, 100),
	[Zone.NAC] = Color(140, 140, 140, 100)	
}

local DrawMaterial = Material( "sprites/jscfixtimer" )

function ENT:Initialize() end
 
function ENT:Think()
	local rm, rma = self:GetCollisionBounds()

	local Min = self:GetPos() + rm - Vector( -100, -100, 0 )
	local Max = self:GetPos() + rma + Vector( -100, -100, 0 )

	self:SetRenderBounds( rm, rma )
end

-- Edited: justa
-- Show ACs

function ENT:Draw()
	-- Color refresh
	DrawArea[Zone.MStart] = Color( 255, 255, 255 )
	DrawArea[Zone.MEnd] = Settings:GetValue("EndZone")
	DrawArea[Zone.BStart] = Settings:GetValue("BonusStart")
	DrawArea[Zone.BEnd] = Settings:GetValue("BonusEnd")

	if not DrawArea[ self:GetZoneType() ] then return end
	
	local rm, rma = self:GetCollisionBounds()
	local Min = self:GetPos() + rm - Vector( -100, -100, 0 )
	local Max = self:GetPos() + rma + Vector( -100, -100, 0 )

	local Col, Width = DrawArea[ self:GetZoneType() ], 1
	local B1, B2, B3, B4 = Vector(Min.x, Min.y, Min.z), Vector(Min.x, Max.y, Min.z), Vector(Max.x, Max.y, Min.z), Vector(Max.x, Min.y, Min.z)
	local T1, T2, T3, T4 = Vector(Min.x, Min.y, Max.z), Vector(Min.x, Max.y, Max.z), Vector(Max.x, Max.y, Max.z), Vector(Max.x, Min.y, Max.z)
	
	if table.HasValue({Zone.AC, Zone.BAC, Zone.NAC}, self:GetZoneType()) and (GetConVar("kawaii_anticheats"):GetInt() == 1) then
		render.DrawBox( self:GetPos(), Angle(0, 0, 0), rm, rma, Col )
	elseif table.HasValue({Zone.AC, Zone.BAC, Zone.NAC}, self:GetZoneType()) and (GetConVar("kawaii_anticheats"):GetInt() == 0) then
		return
	end

	render.SetMaterial( DrawMaterial )
	render.DrawBeam( B1, B2, Width, 0, 1, Col )
	render.DrawBeam( B2, B3, Width, 0, 1, Col )
	render.DrawBeam( B3, B4, Width, 0, 1, Col )
	render.DrawBeam( B4, B1, Width, 0, 1, Col )
		
	render.DrawBeam( T1, T2, Width, 0, 1, Col )
	render.DrawBeam( T2, T3, Width, 0, 1, Col )
	render.DrawBeam( T3, T4, Width, 0, 1, Col )
	render.DrawBeam( T4, T1, Width, 0, 1, Col )
	
	render.DrawBeam( B1, T1, Width, 0, 1, Col )
	render.DrawBeam( B2, T2, Width, 0, 1, Col )
	render.DrawBeam( B3, T3, Width, 0, 1, Col )
	render.DrawBeam( B4, T4, Width, 0, 1, Col )
end