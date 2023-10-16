-- Code for segmented style
-- by justa

-- module 
Segment = {}

-- Setup waypoints
function Segment:WaypointSetup(client)
	if (not client.waypoints) then 
		client.waypoints = {}
		client.lastWaypoint = 0
		client.lastTele = 0
	end
end

-- Reset
function Segment:Reset(client)
	client.waypoints = nil
end

-- Set a waypoint
function Segment:SetWaypoint(client)
	-- Set up waypoints
	self:WaypointSetup(client)

	-- Too fast
	if (client.lastWaypoint > CurTime()) then 
		return
	end

	-- Checks
	if (not client.Style == _C.Style.Segment) or (not client.Tn) then 
		return end 

	-- Set waypoint
	table.insert(client.waypoints, {
		frame = Bot:GetFrame(client),
		pos = client:GetPos(),
		angles = client:EyeAngles(),
		vel = client:GetVelocity(),
		time = CurTime() - client.Tn
	})

	-- Lil' inform 
	Core:Send(client, "Print", {"Timer", "New waypoint set."})

	-- Last waypoint
	client.lastWaypoint = CurTime() + 0.5
end

-- Goto waypoint
function Segment:GotoWaypoint(client)
	-- Set up waypoints
	self:WaypointSetup(client)

	-- Checks
	if (not client.Style == _C.Style.Segment) then 
		return end

	-- Do we even have a waypoint
	if (#client.waypoints < 1) then 
		Core:Send(client, "Print", {"Timer", "Set a waypoint first."})
		return
	end

	-- Too fast
	if (client.lastTele > CurTime()) then 
		return
	end


	-- Get waypoint
	local waypoint = client.waypoints[#client.waypoints]

	-- Set player values
	client:SetPos(waypoint.pos)
	client:SetLocalVelocity(waypoint.vel)
	client:SetEyeAngles(waypoint.angles)
	client.Tn = CurTime() - waypoint.time 

	-- Network time (THIS IS SUPER DUMB I NEED TO REDO NETWORKING ASAP)
	Core:Send(player.GetAll(), "Scoreboard", {"normal", client, client.Tn})
	Core:Send(client, "Timer", {"Start", client.Tn})
	Spectator:PlayerRestart(client)

	-- Strip bot frames 
	Bot:StripFromFrame(client, waypoint.frame)

	-- Last tele
	client.lastTele = CurTime() + 0.5
end

-- Goto waypoint
function Segment:RemoveWaypoint(client)
	-- Set up waypoints
	self:WaypointSetup(client)

	-- Checks
	if (not client.Style == _C.Style.Segment) then 
		return end

	-- Do we even have a waypoint
	if (#client.waypoints < 1) then 
		Core:Send(client, "Print", {"Timer", "Set a waypoint first."})
		return
	end

	-- Remove waypoint
	client.waypoints[#client.waypoints] = nil 

	-- Message
	Core:Send(client, "Print", {"Timer", "Waypoint removed."})

	-- Goto 
	self:GotoWaypoint(client)
end

-- Exit
function Segment:Exit(client)
	UI:SendToClient(client, "segment", true)
end

-- UI 
UI:AddListener("segment", function(client, data)
	local id = data[1]

	if (id == "set") then 
		Segment:SetWaypoint(client)
	elseif (id == "goto") then
		Segment:GotoWaypoint(client)
	elseif (id == "remove") then 
		Segment:RemoveWaypoint(client)
	elseif (id == "reset") then
		client.hasWarning = client.hasWarning or false

		if (client.hasWarning) then 
			client:ConCommand("reset")
			client.hasWarning = false
		else 
			client.hasWarning = true 
			Core:Send(client, "Print", {"Timer", "Are you sure you wish to reset your waypoints? Press again to confirm."})

			timer.Simple(3, function()
				client.hasWarning = false
			end)
		end 
	end
end)

-- Register segmented command
Command:Register({"segment", "segmented", "tas", "seg"}, function(client)
	if (client.Style ~= _C.Style.Segment) then
		Command:RemoveLimit(client)
		Command.Style(client, nil, {_C.Style.Segment})
		Core:Send(client, "Print", {"Timer", "To reopen the segment menu at any time, use this command again."})
	end

	UI:SendToClient(client, "segment")
end)