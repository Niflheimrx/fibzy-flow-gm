-- justa's ssj

-- Neat
local SSJ = {}
util.AddNetworkString("kawaii.secret")

-- Load
local function LoadPlayer(pl)
	-- Just a timer
	timer.Simple(1, function()
		local ssj = pl:GetPData("SSJ_Settings", false)

		pl.SSJ = {}
		pl.SSJ["Jumps"] = {}
		pl.SSJ["Settings"] = ssj and util.JSONToTable(ssj) or {false, true, false, false, true, false}
		pl.rawgain = 0
		pl.tick = 0
	end)
end
hook.Add("PlayerInitialSpawn", "SSJ.LoadPlayer", LoadPlayer)

-- The "!ssj" command
local function AddCommand()
	Command:Register({"ssj", "s6j", "sj", "ssjmenu", "justascool"}, function(pl)
		SSJ:OpenMenuForPlayer(pl, pl.SSJ["Settings"])
	end )
end
hook.Add("Initialize", "SSJ.AddCommand", AddCommand)

-- Adding ssj jumps
local function OnPlayerHitGround(pl)
	if pl.SSJ then
		-- No first?
		if (not pl.SSJ["Jumps"][1]) then
			pl.SSJ["Jumps"][1] = {0, 0}
		end

		table.insert(pl.SSJ["Jumps"], SSJ:RetrieveData(pl))
		SSJ:Display(pl)

		-- Raw gain 
		pl.rawgain = 0
		pl.tick = 0
	end
end
hook.Add("OnPlayerHitGround", "SSJ.OnPlayerHitGround", OnPlayerHitGround)

-- Key Press 
-- Work out first jump data
local function KeyPress(pl, key)
	if (key == IN_JUMP) then 
		pl.SSJ["InSpace"] = true 
	end
	if (key == IN_JUMP) and pl:IsOnGround() and pl:Alive() then
		-- In Space
		pl.tick = 0 
		pl.rawgain = 0
		pl.maxgain = 0

		-- Add statistic
		pl.SSJ["Jumps"] = {}
		pl.SSJ["Jumps"][1] = SSJ:RetrieveData(pl)

		-- A
		if (PlayerJumps) and (PlayerJumps[pl]) and (PlayerJumps[pl] <= 1) then 
			local observers = {pl}

			for k, v in pairs(player.GetHumans()) do 
				if IsValid(v:GetObserverTarget()) and (v:GetObserverTarget() == pl) then 
					table.insert(observers, v)
				end
			end

			Core:Send(observers, "jump_update", {pl, 1})
			PlayerJumps[pl] = 1
		end

		-- Display to players
		SSJ:Display(pl)
	end
end

-- Key Release
local function KeyRelease(pl, key)
	if (key == IN_JUMP) and pl.SSJ["InSpace"] then
		pl.SSJ["InSpace"] = false 
	end
end

-- Hooks
hook.Add("KeyPress", "SSJ.KeyPress", KeyPress)
hook.Add("KeyRelease", "SSJ.KeyRelease", KeyRelease)

-- Open menu for player
function SSJ:OpenMenuForPlayer(pl, data)
	UI:SendToClient(pl, "ssj", data)
end

-- Retrieve Data
function SSJ:RetrieveData(pl)
	local velocity = pl:GetVelocity():Length2D()
	local pos = pl:GetPos().z

	return {velocity, pos}
end

-- Interface Response
local function InterfaceResponse(pl, data)
	-- The key
	local k = data[1]

	-- The setting
	pl.SSJ["Settings"][k] = (not pl.SSJ["Settings"][k])
	pl:SetPData("SSJ_Settings", util.TableToJSON(pl.SSJ["Settings"]))

	-- Callback
	SSJ:OpenMenuForPlayer(pl, k)
end
UI:AddListener("ssj", InterfaceResponse)

-- Ripped
local fl, fo = math.floor, string.format
local function ConvertTime( ns )
	if ns <= 60 then
		return fo( "%.2d.%.3d", fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
	elseif ns > 3600 then
		return fo( "%d:%.2d:%.2d.%.3d", fl( ns / 3600 ), fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
	else
		return fo( "%.2d:%.2d.%.3d", fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
	end
end

-- Display 
function SSJ:Display(pl)
	-- No SSJ Table? What.
	if (not pl.SSJ) then return end

	-- They're not holding space.
	if (not pl.SSJ["InSpace"]) then return end

	-- Prevent weird spamming in zone.
	if (#pl.SSJ["Jumps"] > 1) and pl.InZone then return end 

	-- Replay bot
	if pl:IsBot() then return end 

	-- Current Data
	local currentJump = pl.SSJ["Jumps"][#pl.SSJ["Jumps"]]
	local currentVel = currentJump[1]
	local currentHeight = currentJump[2]

	if (currentVel == 0) then
		currentVel = 0
	 else
	if (currentVel <= 33) then
		currentVel = 30
		end 
    end

	-- Build string table
	local dStr = {"Jumps: ", _C["Prefixes"].Timer, tostring(#pl.SSJ["Jumps"]), color_white, " | ", "Speed: ", _C["Prefixes"].Timer, tostring(math.Round(currentVel)), color_white}

	-- Values
	local difference, height

	local gain = (pl.rawgain / pl.tick) * 100
	gain = math.floor(gain * 100 + 0.5) / 100

	if gain == math.huge or gain ~= gain then
		gain = 0
	end

	if (gain > (pl.maxgain or 0)) then 
		pl.maxgain = gain
	end

	-- Previous Jump
	local oldData
	if (#pl.SSJ["Jumps"] ~= 1) then
		oldData = pl.SSJ["Jumps"][#pl.SSJ["Jumps"] - 1]

		-- Check
		if (not oldData) then return end

		local oldVelocity = oldData[1]
		local oldHeight = oldData[2]
		difference = math.Round(currentVel - oldVelocity)
		height = math.Round(currentHeight - oldHeight)
	end
	-- JAC report
	if (#pl.SSJ["Jumps"] == 6) then 
		JAC:ReportStat(pl, "gain", pl.maxgain)
		pl.maxgain = 0
	end

	-- Clients to show
	local clients = {pl}
	for k, v in pairs(player.GetAll()) do
		if (not v.Spectating) or (not v.SSJ["Settings"][5]) then continue end 

		local target = v:GetObserverTarget()
		if target:IsValid() and target == pl then 
			table.insert(clients, v)
		end
	end

	-- Start to show
	for k, v in pairs(clients) do
		local str = table.Copy(dStr)
		net.Start("kawaii.secret")
			net.WriteInt(#pl.SSJ["Jumps"], 16)
	 		net.WriteFloat(gain)
	 		net.WriteInt(currentVel, 18)
		net.Send(v)

		-- SSJ Off
		if (not v.SSJ["Settings"][1]) then continue end

		-- Every jump disabled
		if (not v.SSJ["Settings"][2]) and (#pl.SSJ["Jumps"] ~= 6) then continue end

		-- Height
		if (#pl.SSJ["Jumps"] > 1) and (v.SSJ["Settings"][4]) then
			table.insert(str, " | Height ∆: ")
			table.insert(str, _C["Prefixes"].Timer)
			table.insert(str, tostring(height))
			table.insert(str, color_white)
		end

		-- Speed Difference
		if (#pl.SSJ["Jumps"] > 1) and (v.SSJ["Settings"][3]) then
			table.insert(str, " | Speed ∆: ")
			table.insert(str, _C["Prefixes"].Timer)
			table.insert(str, tostring(difference))
			table.insert(str, color_white)
		end

		
		-- Gain Percent
		if (#pl.SSJ["Jumps"] > 1) and (v.SSJ["Settings"][6]) then
			table.insert(str, " | Gain: ")
			table.insert(str, _C["Prefixes"].Timer)
			table.insert(str, tostring(gain) .. "%")
			table.insert(str, color_white)
		end

		-- Print
		Core:Send(v, "Print", {"Timer", str})
	end
end

-- strafe trainer
-- justa 

util.AddNetworkString("train_update")

-- 30 (MV)
-- Normal Garry's mod this is 32.8
local movementSpeed = 32.8

-- Tick interval 
local interval = (1 / engine.TickInterval()) / 10 

-- Faster performance
local deg, atan = math.deg, math.atan

-- active 
local active = {}

local p = FindMetaTable("Player")
function p:InitStrafeTrainer(client)
	local data = self:GetPData("strafetrainer", 0)

	if tobool(data) then 
		self:SetNWBool("strafetrainer", true)
	end
end

function StrafeTrainer_CMD(client)
	local curr = tobool(client:GetPData("strafetrainer", 0))

	client:SetPData("strafetrainer", curr and 0 or 1)
	client:SetNWBool("strafetrainer", not curr)
end

local function NormalizeAngle(x)
	if (x > 180) then 
		x = x - 360
	elseif (x <= -180) then 
		x = x + 360
	end 

	return x
end

local function GetPerfectAngle(vel)
	return deg(atan(movementSpeed / vel))
end

local function NetworkList(ply)
	local watchers = {}

	for _, p in pairs(player.GetHumans()) do
		if not p.Spectating then continue end

		local ob = p:GetObserverTarget()

		if IsValid(ob) and ob == ply then
			watchers[#watchers + 1] = p
		end
	end

	watchers[#watchers + 1] = ply 

	return watchers
end

local last = {}
local tick = {}
local percentages = {}
local value = {}
local function SetupMove(client, data, cmd)
	if not client:GetNWBool("strafetrainer") then return end
	if not client:Alive() then return end


	if client:GetMoveType() == MOVETYPE_NOCLIP then return end 

	if not percentages[client] then 
		percentages[client] = {}
		last[client] = 0
		tick[client] = 0
		value[client] = 0
	end

	local diff = NormalizeAngle(last[client] - data:GetAngles().y)
	local perfect = GetPerfectAngle(client:GetVelocity():Length2D())
	local perc = math.abs(diff) / perfect 
	local t = tick[client]

	if (t > interval) then 
		local avg = 0 

		for x = 0, interval do 
			avg = avg + percentages[client][x]
			percentages[client][x] = 0
		end

		avg = avg / interval 
		value[client] = avg 
		tick[client] = 0 

		net.Start("train_update")
			net.WriteFloat(avg)
		net.Send(NetworkList(client))
	else
		percentages[client][t] = perc 
		tick[client] = t + 1
	end

	last[client] = data:GetAngles().y
end
hook.Add("SetupMove", "sm_strafetrainer", SetupMove)