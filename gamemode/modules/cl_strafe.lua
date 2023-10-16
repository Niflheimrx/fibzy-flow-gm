-- HUD module used for my tutorials
-- Edited: justa 
-- Made my own "HUD" module piggy back off this code

local StrafeAxis = 0 -- Saves the last eye angle yaw for checking mouse movement
local StrafeButtons = nil -- Saves the buttons from SetupMove for displaying
local StrafeCounter = 0 -- Holds the amount of strafes
local StrafeLast = nil -- Your last strafe key for counting strafes
local StrafeDirection = nil -- The direction of your strafes used for displaying
local StrafeStill = 0 -- Counter to reset mouse movement

local fb, ik, lp, ts = bit.band, input.IsKeyDown, LocalPlayer, _C.Team.Spectator -- This function is used frequently so to reduce lag...
local function norm( i ) if i > 180 then i = i - 360 elseif i < -180 then i = i + 360 end return i end -- Custom function to normalize eye angles

local StrafeData -- Your Sync value is stored here
local KeyADown, KeyDDown -- For displaying on the HUD
local MouseLeft, MouseRight --- For displaying on the HUD

local ViewGUI = CreateClientConVar( "kawaii_keys", "1", true, false ) -- GUI visibility
surface.CreateFont( "HUDFont2", { size = 20, weight = 800, font = "Tahoma" } )

function ResetStrafes() StrafeCounter = 0 end -- Resets your stafes (global)
function SetSyncData( data ) StrafeData = data end -- Sets your sync data (global)

-- Monitors the buttons and angles
local function MonitorInput( ply, data )
	StrafeButtons = data:GetButtons()
	
	local ang = data:GetAngles().y
	local difference = norm( ang - StrafeAxis )
	
	if difference > 0 then
		StrafeDirection = -1
		StrafeStill = 0
	elseif difference < 0 then
		StrafeDirection = 1
		StrafeStill = 0
	else
		if StrafeStill > 20 then
			StrafeDirection = nil
		end
		
		StrafeStill = StrafeStill + 1
	end
	
	StrafeAxis = ang
end
hook.Add( "SetupMove", "MonitorInput", MonitorInput )

-- Monitors your key presses for strafe counting
local function StrafeKeyPress( ply, key )
	if ply:IsOnGround() then return end
	
	local SetLast = true
	if key == IN_MOVELEFT or key == IN_MOVERIGHT then
		if StrafeLast != key then
			StrafeCounter = StrafeCounter + 1
		end
	else
		SetLast = false
	end
	
	if SetLast then
		StrafeLast = key
	end
end
hook.Add( "KeyPress", "StrafeKeys", StrafeKeyPress )

-- Paints the actual HUD
local function HUDPaintB()
	if not ViewGUI:GetBool() then return end
	if not IsValid( lp() ) or lp():Team() == ts then return end

	local data = {pos = {20, 20}, strafe = true, r = (MouseRight != nil), l = (MouseLeft != nil)}

	-- Setting the key colors
	if StrafeButtons then
		if fb( StrafeButtons, IN_MOVELEFT ) > 0 then 
			data.a = true 
		end

		if fb( StrafeButtons, IN_MOVERIGHT ) > 0 then
			data.d = true 
	 	end
	end
	
	-- Getting the direction for the mouse
	if StrafeDirection then
		if StrafeDirection > 0 then
			MouseLeft, MouseRight = nil, Color( 142, 42, 42, 255 )
		elseif StrafeDirection < 0 then
			MouseLeft, MouseRight = Color( 142, 42, 42, 255 ), nil
		else
			MouseLeft, MouseRight = nil, nil
		end
	else
		MouseLeft, MouseRight = nil, nil
	end
	
	-- If we have buttons, display them
	if StrafeButtons then
		if fb( StrafeButtons, IN_FORWARD ) > 0 then
			data.w = true 
		end
		if fb( StrafeButtons, IN_BACK ) > 0 then
			data.s = true
		end
		if ik( KEY_SPACE ) or fb( StrafeButtons, IN_JUMP ) > 0 then
			data.jump = true 
		end
		if fb( StrafeButtons, IN_DUCK ) > 0 then
			data.duck = true
		end
	end
	
	-- Display the amount of strafes
	if StrafeCounter then
		data.strafes = StrafeCounter
	end
	
	-- If we have sync, display the sync
	if StrafeData then
		data.sync = StrafeData
	end
	
	HUD:Draw(2, lp(), data)
end
hook.Add( "HUDPaint", "PaintB", HUDPaintB )

-- strafe trainer
-- justa 	
surface.CreateFont( "HUDcsstop", { size = 32, weight = 800, antialias = true, bold = true, font = "DermaDefaultBold" } )
surface.CreateFont( "HUDcss", { size = 21, weight = 800, bold = false, font = "DermaDefaultBold" } )

local function GetColour(percent)
	local offset = math.abs(1 - percent)

	if offset < 0.05 then 
		return Color(0, 255, 0, 255)
	elseif (0.05 <= offset) and (offset < 0.1) then 
		return Color(128, 255, 0, 255)
	elseif (0.1 <= offset) and (offset < 0.25) then 
		return Color(255, 255, 0, 255) 
	elseif (0.15 <= offset) and (offset < 0.3) then 
		return Color(255, 128, 0, 255)
	elseif (0.25 <= offset) and (offset < 0.5) then 
		return Color(0, 160, 200, 255)
	else 
		return Color(255, 0, 0, 255)
	end
end

local value = 0 
net.Receive("train_update", function(_, _)
	value = net.ReadFloat()
end)	

local lp = LocalPlayer
local function Display()
	if not lp():GetNWBool("strafetrainer") then return end
	if IsValid(lp():GetObserverTarget()) and lp():GetObserverTarget():IsBot() then return end
	if LocalPlayer():IsOnGround() then return end
	if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP then return end

	local c = GetColour(value)
	local x = ScrW() / 2 
	local y = (ScrH() / 2) + 100
	local w = 240
	local size = 4
	local msize = size / 2
	local h = 14
	local movething = 22
	local spacing = 6
	local endingval = math.floor(value * 100)

	surface.SetDrawColor(c)

	if endingval >= 0 and endingval <= 200 then 
		local move = w * (value/2)
		surface.DrawRect(x - (w / 2) + move, y - (movething/2) + (size / 2), size, movething)
	else
		draw.SimpleText("Invalid", "HUDcsstop", x, y + (size / 2), c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	y = y + 32
	surface.DrawRect(x - (w / 2) + (size / 2), y, w - size, size)
	surface.DrawRect(x - (w / 2), y - h, size, h + size)
	surface.DrawRect(x + (w / 2) - size, y - h, size, h + size)
	surface.DrawRect(x - (msize / 2), y + size, msize, h)
	draw.SimpleText("100", "HUDcss", x, y + size + spacing + h, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	y = y - (32 * 2)
	surface.DrawRect(x - (w / 2) + (size / 2), y, w - size, size)
	surface.DrawRect(x - (w / 2), y, size, h + size)
	surface.DrawRect(x + (w / 2) - size, y, size, h + size)
	surface.DrawRect(x - (msize / 2), y - h, msize, h)


	draw.SimpleText(endingval, "HUDcss", x, y - h - spacing, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end 
hook.Add("HUDPaint", "StrafeTrainer", Display)--]]
