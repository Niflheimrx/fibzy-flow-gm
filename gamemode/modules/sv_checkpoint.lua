-- New checkpoints
-- by Justa

-- Modules are neat
Checkpoints = {}

-- SetUp 
function Checkpoints:SetUp(pl)
	if (not pl.checkpoints) then 
		pl.checkpoints = {}
		pl.checkpoint_current = 0
		pl.checkpoint_angles = true
	end

	-- Hah
	local practice = pl:GetNWInt("inPractice", false)

	if (not practice) then 
		Core:Send(pl, "Print", {"Timer", "Your timer has been stopped due to the use of checkpoints."})
		Core:Send(pl, "Print", {"Server", "Feel free to use this for setspawn."})
	end

	-- Timer?
	if (pl.Tn) or (pl.Tb) then 
		pl:SetNWInt("inPractice", true)
		pl:StopAnyTimer()
	end
end

-- Get Current
function Checkpoints:GetCurrent(pl)
	return pl.checkpoint_current
end

-- Set Current
function Checkpoints:SetCurrent(pl, current)
	pl.checkpoint_current = current
end

-- Next
function Checkpoints:Next(pl)
	local current = self:GetCurrent(pl)

	if (not pl.checkpoints[current + 1]) then 
		return end 

	self:SetCurrent(pl, current + 1)

	-- Update UI
	UI:SendToClient(pl, "checkpoints", true, current + 1, #pl.checkpoints)
end

-- Previous
function Checkpoints:Previous(pl)
	local current = self:GetCurrent(pl)

	if (not pl.checkpoints[current - 1]) then 
		return end 

	self:SetCurrent(pl, current - 1)

	-- Update UI
	UI:SendToClient(pl, "checkpoints", true, current - 1, #pl.checkpoints)
end

-- Reorder From
function Checkpoints:ReorderFrom(pl, index, method)
	if (method == "add") then
		for i = #pl.checkpoints, index, -1 do 
			pl.checkpoints[i + 1] = pl.checkpoints[i]
		end
	elseif (method == "del") then
		local newcheckpoints = {}
		local i = 1

		for k, v in pairs(pl.checkpoints) do 
			newcheckpoints[i] = v
			i = i + 1
		end

		pl.checkpoints = newcheckpoints
	end
end

-- Save
function Checkpoints:Save(pl)
	-- Set up if not already
	self:SetUp(pl)

	-- Save
	local d = IsValid(pl:GetObserverTarget()) and pl:GetObserverTarget() or pl
	local vel = d:GetVelocity()
	local pos = d:GetPos()
	local angles = d:EyeAngles()

	local current = self:GetCurrent(pl)

	if (#pl.checkpoints > 29) then 
		Core:Send(pl, "Print", {"Timer", "Sorry, you're only allowed a maximum on 30 checkpoints!"})
		return 
	end

	-- Set
	if (pl.checkpoints[current + 1]) then 
		self:ReorderFrom(pl, current + 1, "add")
	end

	pl.checkpoints[current + 1] = {vel, pos, angles}

	-- Update current
	self:SetCurrent(pl, current + 1)

	-- Update UI
	UI:SendToClient(pl, "checkpoints", true, current + 1, #pl.checkpoints)
end

-- TeleportTo
function Checkpoints:Teleport(pl)
    -- Set up if not already
	self:SetUp(pl)

	local current = self:GetCurrent(pl)
	local data = pl.checkpoints[current]

	pl:SetLocalVelocity(data[1])
	pl:SetPos(data[2])

	if (pl.checkpoint_angles) then 
		pl:SetEyeAngles(data[3])
	end
end

-- Reset 
function Checkpoints:Reset(pl)
	-- Set up if not already
	self:SetUp(pl)

	if (#pl.checkpoints < 1) then 
		return end 

	-- Set current to 0
	self:SetCurrent(pl, 0)

	-- Wipe table 
	pl.checkpoints = {}

	-- UI update
	UI:SendToClient(pl, "checkpoints", true, false)
end

-- Delete
function Checkpoints:Delete(pl)
	-- Set up if not already
	self:SetUp(pl)

	if (#pl.checkpoints < 1) then 
		return end 

	-- Only 1?
	if (#pl.checkpoints == 1) then 
		return self:Reset(pl) end

	-- Current
	local current = self:GetCurrent(pl)

	-- Remove current 
	pl.checkpoints[current] = nil 
	self:ReorderFrom(pl, current, "del")

	-- Set checkpoint to one before or one after 
	if (current ~= 1) and (not pl.checkpoints[current - 1]) then 
		self:SetCurrent(pl, current + 1)
	elseif (current ~= 1) then
		self:SetCurrent(pl, current - 1)
	end

	-- UI 
	UI:SendToClient(pl, "checkpoints", true, self:GetCurrent(pl), #pl.checkpoints)
end

-- Open checkpoint menu 
-- Also why not always add commands in modules? It's cleaner.
local function CheckpointOpen(pl, args)
	UI:SendToClient(pl, "checkpoints")

	if (pl.checkpoints) then 
		UI:SendToClient(pl, "checkpoints", true, Checkpoints:GetCurrent(pl), #pl.checkpoints)
	end

	-- Warning
	if (pl.Tn) or (pl.Tb) or (not pl:GetNWInt("inPractice", false)) then 
		Core:Send(pl, "Print", {"Timer", "Warning: The use of checkpoints will disable your timer."})
	end
end
Command:Register({"cp", "checkpoints", "cps"}, CheckpointOpen)

UI:AddListener("checkpoints", function(client, data)
	local id = data[1]

	if (id == "save") then 
		Checkpoints:Save(client)
	elseif (id == "tp") then
		Checkpoints:Teleport(client)
	elseif (id == "next") then 
		Checkpoints:Next(client)
	elseif (id == "prev") then 
		Checkpoints:Previous(client)
	elseif (id == "del") then 
		Checkpoints:Delete(client)
	elseif (id == "reset") then 
		Checkpoints:Reset(client)
	elseif (id == "angles") then 
		Checkpoints:SetUp(client)
		client.checkpoint_angles = (not client.checkpoint_angles)

		-- UI 
		UI:SendToClient(client, "checkpoints", "angles", client.checkpoint_angles)
	end
end)

-- Console commands
concommand.Add("bhop_checkpoint_save", function(cl) Checkpoints:Save(cl) end)
concommand.Add("bhop_checkpoint_tele", function(cl)	Checkpoints:Teleport(cl) end)
concommand.Add("bhop_checkpoint_next", function(cl)	Checkpoints:Next(cl) end)
concommand.Add("bhop_checkpoint_prev", function(cl)	Checkpoints:Previous(cl) end)
concommand.Add("bhop_checkpoint_del", function(cl) Checkpoints:Delete(cl) end)
concommand.Add("bhop_checkpoint_reset", function(cl) Checkpoints:Reset(cl) end)