-- UI API
-- by Justa

-- Start to initialize the UI api here
-- I do it this way so it's just nicely organised.
UI = {}
UI.ActiveNumberedUIPanel = false

-- LocalPlayer
local lp = LocalPlayer

--[[-------------------------------------------------------------------------

	Numbered UI Panel
	This is the panel with numbers (1-7) to chose through.

	Usage:
		Defining:
 			panel_obj = UI:NumberedUIPanel(String title, Table options)

	 		options (example):
	 			Argument 1 (table):
	 				"name": "Name that will be displayed"
	 				"function": function()
	 								print("Foo bar")
	 							end
	 				"bool": true (default value)
	 				"customBool": {"Yay", "Nah"} (true/false of bool set above ^)

	Sub Functions
		NumberedUIPanel:UpdateTitle(String title) -> Updates the title of any given panel.
		NumberedUIPanel:UpdateOption(Int id, String name=nil, Color color=nil, Function func=nil) -> Updates an option, set value to nil to keep a part of an option the same.
		NumberedUIPanel:OnThink() -> Called when ever 'Think' is called, overwrite to use.
		NumberedUIPanel:SelectOption(Int optionId) -> Selects the option just as if a player was to.
		NumberedUIPanel:UpdateOptionBool(Int optionId) -> Reverses the state of the bool set to the optionId (true to false, false to true)
		NumberedUIPanel:SetCustomDelay(Float delay) -> Sets a custom key delay in seconds. (default = 0.25 seconds)
		NumberedUIPanel:Exit() -> Exits the numbered ui panel.
		NumberedUIPanel:ForceNextPrevious() -> Forces UI Panel to have a next and previous button without the need of 7 options.
		NumberedUIPanel:UpdateLongestOption() -> Updates panel width to the longest options width, always call this when updating options.
		NumberedUIPanel:OnNext() -> Called when the 'next' button is called, overwrite to use.

---------------------------------------------------------------------------]]

function UI:NumberedUIPanel(title, ...)
	-- Options
	local options = {...}

	-- Let's create our panel
	local pan = vgui.Create("DPanel")

	-- Page options
	pan.hasPages = #options > 7 and true or false
	pan.page = 1

	-- Positioning and Sizing
	local width = 200
	local height = 75 + ((pan.hasPages and 9 or #options) * 20)
	local xPos, yPos = 20, (ScrH() / 2) - (height / 2)

	-- Set up
	pan:SetSize(width, height)
	pan:SetPos(xPos, yPos)
	pan.title = title
	pan.options = options

	-- Remove other numbered panel if open
	if (self.ActiveNumberedUIPanel) then
		self.ActiveNumberedUIPanel:Exit()
	end

	-- Check if there's a toggleable boolean in the options, and if there is set a prefix.
	-- Also lets get the largest option by name length here as well.
	local largest = ""
	for index, option in pairs(pan.options) do
		if (option.bool ~= nil) then
			local o1 = option.customBool and option.customBool[1] or "ON"
			local o2 = option.customBool and option.customBool[2] or "OFF"
			option.defname = option.name
			option.name = "[" .. (option.bool and o1 or o2) .. "] " .. option.name
		end

		largest = (#option.name > #largest) and option.name or largest
	end

	-- Get width of largest option
	surface.SetFont("HUDLabelMed")
	local width_largest = select(1, surface.GetTextSize(largest)) + 20

	-- Set the panels width larger than default if the text width goes beyond it.
	if (width_largest > 180) then
		pan:SetWide((width_largest * 1.1) + 44)
	end

	-- Paint the panel
	-- Todo: Themes, the style should be changeable
	pan.Paint = function(self, width, height)
		local primary = Color(43, 43, 43)
		local outline = Color(0, 0, 0, 0)
		local text = Settings:GetValue("TextCol")

		-- Box
		surface.SetDrawColor(primary)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(outline)
		surface.DrawOutlinedRect(0, 0, width, height)

		-- Title
		draw.SimpleText(self.title, "hud.title", 10, 15, text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		-- Print options
		local i = 1
		for index = 1 + ((self.page - 1) * 7), ((self.page - 1) * 7) + 7 do
			-- No option
			if (not self.options[index]) then break end

			local option = self.options[index]
			draw.SimpleText(i .. ". " .. option.name, "HUDLabelMed", 10, 25 + (i * 20), option.col and option.col or text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			i = i + 1
		end

		-- Index
		local index = self.hasPages and 7 or #self.options

		-- Exit
		draw.SimpleText("0. Exit", "HUDLabelMed", 10, 35 + ((index + (self.hasPages and 3 or 1)) * 20), text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		-- Pages?
		if (self.hasPages) then
			draw.SimpleText("8. Previous", "HUDLabelMed", 10, 35 + ((index + 1) * 20), text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("9. Next", "HUDLabelMed", 10, 35 + ((index + 2) * 20), text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	-- Think
	pan.keylimit = false
	pan.Think = function(self)
		local key = -1

		-- Get current key down
		for id = 1, 10 do
			if input.IsKeyDown(id) then
				key = id - 1
				break
			end
		end

		-- Check if player is typing
		if lp and IsValid(lp()) and lp():IsTyping() then
			key = -1
		end

		-- Call custom function set by the option
		if (key > 0) and (key <= 9) and (not self.keylimit) then
			if (key == 8) and (self.hasPages) then
				self.page = (self.page == 1 and 1 or self.page - 1)
			elseif (key == 9) and (self.hasPages) then
				local max = math.ceil(#self.options / 7)
				self.page = self.page == max and self.page or self.page + 1
				self:OnNext(self.page == max)
			else
				local pageAddition = (self.page - 1) * 7
				if (not self.options[key + pageAddition]) or (not self.options[key + pageAddition]["function"]) then
					return end

				self.options[key + pageAddition]["function"]()
			end

			-- Reset delay
			self.keylimit = true
			timer.Simple(self.keydelay or 0.25, function()
				-- Bug fix
				if not IsValid(self) then return end
				self.keylimit = false
			end)
		elseif (key == 0) then
			self:OnExit()
			self:Exit()
		end

		-- Call an extra think function if one is set
		self:OnThink()
	end

	-- Update Title
	function pan:UpdateTitle(title)
		self.title = title
	end

	-- Update option
	function pan:UpdateOption(optionId, title, colour, f)
		if (not self.options[optionId]) then
			return end

		if (title) then
			self.options[optionId]["name"] = title
		end

		if (colour) then
			self.options[optionId]["col"] = colour
		end

		if (f) then
			self.options[optionId]["function"] = f
		end
	end

	-- Update option bool
	function pan:UpdateOptionBool(optionId)
		if (not self.options[optionId]) or (self.options[optionId].bool == nil) then
			return end

		self.options[optionId].bool = (not self.options[optionId].bool)

		-- Name
		local o1 = self.options[optionId].customBool and self.options[optionId].customBool[1] or "ON"
		local o2 = self.options[optionId].customBool and self.options[optionId].customBool[2] or "OFF"
		self.options[optionId].name = "[" .. (self.options[optionId].bool and o1 or o2) .. "] " .. self.options[optionId].defname
	end

	-- On Think
	-- This should just be overwritten if you need to use it.
	function pan:OnThink()
	end

	-- Exit
	function pan:Exit()
		UI.ActiveNumberedUIPanel = false
		self:Remove()
		pan = nil
	end

	-- On Exit
	function pan:OnExit()
	end

	-- Select option
	function pan:SelectOption(id)
		self.options[id]["function"]()
	end

	-- Set custom delay
	function pan:SetCustomDelay(delay)
		self.keydelay = delay
	end

	-- Force next/previous
	function pan:ForceNextPrevious(bool)
		self.hasPages = true
		self:SetTall(75 + 180)

		local posx, posy = self:GetPos()
		self:SetPos(posx, ScrH() / 2 - ((75 + 180) / 2))
	end

	-- Update longest option
	function pan:UpdateLongestOption()
		local largest = ""
		for index, option in pairs(self.options) do
			largest = (#option.name > #largest) and option.name or largest
		end

		-- Get width of largest option
		surface.SetFont("HUDLabelMed")
		local width_largest = select(1, surface.GetTextSize(largest)) + 20

		-- Set the panels width larger than default if the text width goes beyond it.
		if (width_largest > 180) then
			self:SetWide((width_largest * 1.1) + 44)
		end
	end

	-- On Next
	-- This should be overwritten if you need to use it
	function pan:OnNext()
	end

	-- Set Active Numbered UI Panel
	-- This is important, as if another numbered UI panel was opened, there would be overlap.
	self.ActiveNumberedUIPanel = pan

	-- Return
	return pan
end


--[[-------------------------------------------------------------------------
	SendCallback
	This function allows easy communication from client to server when interacting
	with a ui

	Usage: UI:SendCallback(handle, data)

 	Note: I'm making a new network string here, I know. But, I cannot be bothered with Core:Send anymore :V
---------------------------------------------------------------------------]]

function UI:SendCallback(handle, data)
	net.Start("userinterface.network")
		net.WriteString(handle)
		net.WriteTable(data)
	net.SendToServer()
end

--[[-------------------------------------------------------------------------
	AddListener
	This function is when the server sends the client a message to open a UI interface.
	Or when the server sends the client a message to update an already existing UI.
	'network_data' (seen in the net.Receive func) is what the server has sent the client, usually updated variables.
	See my example in /modules/sv_checkpoint.lua to see how it works.

	Usage: UI:AddListener(listenerId, dataReceieved)
---------------------------------------------------------------------------]]

local DATA = {}
function UI:AddListener(id, func)
	DATA[id] = func
end

net.Receive("userinterface.network", function(_, cl)
	-- Get the data
	local network_id = net.ReadString()
	local network_data = net.ReadTable()


	-- If this ever happens, I'm retarded
	if (not DATA[network_id]) then return end

	-- Call the function
	DATA[network_id](cl, network_data)
end)

--[[-------------------------------------------------------------------------
	Checkpoints
]]---------------------------------------------------------------------------]]
local function CP_Callback(id)
	return function() UI:SendCallback("checkpoints", {id}) end
end

-- Listener
UI:AddListener("checkpoints", function(_, data)
	local update = data[1] or false

	-- Update?
	if update and (UI.checkpoints) then
		if (update == "angles") then
			UI.checkpoints:UpdateOptionBool(7)
			return
		end

		local current = data[2]
		local all = data[3] or nil

		-- no current?
		if (not current) then
			UI.checkpoints:UpdateTitle("Checkpoints")
			return
		end

		UI.checkpoints:UpdateTitle("Checkpoint: " .. current .. " / " .. all)
	elseif (not UI.checkpoints) or (not UI.checkpoints.title) then
		UI.checkpoints = UI:NumberedUIPanel("Checkpoints",
			{["name"] = "Save checkpoint", ["function"] = CP_Callback("save")},
			{["name"] = "Teleport to checkpoint", ["function"] = CP_Callback("tp")},
			{["name"] = "Next checkpoint", ["function"] = CP_Callback("next")},
			{["name"] = "Previous checkpoint", ["function"] = CP_Callback("prev")},
			{["name"] = "Delete checkpoint", ["function"] = CP_Callback("del")},
			{["name"] = "Reset checkpoints", ["function"] = CP_Callback("reset")},
			{["name"] = "Use Angles", ["function"] = CP_Callback("angles"), ["bool"] = true}
		)
	end
end)

--[[-------------------------------------------------------------------------
	SSJ
---------------------------------------------------------------------------]]
local function SSJ_Callback(key)
	return function() UI:SendCallback("ssj", {key}) end
end

UI:AddListener("ssj", function(_, data)
	local data = data[1] or false

	if tonumber(data) and UI.ssj then
		UI.ssj:UpdateOptionBool(tonumber(data))
	elseif (not UI.ssj) or (not UI.ssj.title) and (not tonumber(data)) then
		UI.ssj = UI:NumberedUIPanel("SSJ Menu",
			{["name"] = "Toggle", ["function"] = SSJ_Callback(1), ["bool"] = data[1]},
			{["name"] = "Mode", ["function"] = SSJ_Callback(2), ["bool"] = data[2], ["customBool"] = {"All", "6th"}},
			{["name"] = "Speed Difference", ["function"] = SSJ_Callback(3), ["bool"] = data[3]},
			{["name"] = "Height Difference", ["function"] = SSJ_Callback(4), ["bool"] = data[4]},
			{["name"] = "Observers Stats", ["function"] = SSJ_Callback(5), ["bool"] = data[5]},
			{["name"] = "Gain Percentage", ["function"] = SSJ_Callback(6), ["bool"] = data[6]}
		)
	end
end)

--[[-------------------------------------------------------------------------
	RTV
---------------------------------------------------------------------------]]
RTVStart = false
RTVSelected = false

local function RTV_Callback(id)
	return function()
		local accent = Color(244, 80, 66)
		local text = Settings:GetValue("TextCol")
		local old = false

		-- Same option
		if (UI.rtv.options[id].col) and (UI.rtv.options[id].col == accent) then
			return end

		RTVSelected = id
		UI.rtv:UpdateOption(id, false, accent, false)
		for k, v in pairs(UI.rtv.options) do
			if (k ~= id) then
				if (v.col) and (v.col == accent) then
					old = k
				end

				UI.rtv:UpdateOption(k, false, text, false)
			end
		end

		UI:SendCallback("rtv", {id, old})
	end
end

UI:AddListener("rtv", function(_, data, isRevote)
	local id = data[1]
	local info = data[2]

	-- GetList
	if (id == "GetList") then
		local ui_options = {}

		-- Convert options to readable by UI API
		for k, v in pairs(info) do
			local name = "[0] " .. v[1] .. " (" .. v[2] .. " points, " .. v[3] .. " plays)"
			table.insert(ui_options, {["name"] = name, ["function"] = RTV_Callback(k)})
		end
		table.insert(ui_options, {["name"] = "[0] Extend current map", ["function"] = RTV_Callback(6)})
		table.insert(ui_options, {["name"] = "[0] Goto random map", ["function"] = RTV_Callback(7)})

		-- Initialize
		UI.rtv = UI:NumberedUIPanel("", unpack(ui_options))
		if (isRevote) then
			RTVStart = RTVStart and RTVStart or CurTime() + 30
		else
			RTVStart = CurTime() + 30
		end

		-- On think
		function UI.rtv:OnThink()
			local s = math.Round(RTVStart - CurTime())

			if (s <= 0) then
				self:Exit()
				RTVStart = false
				RTVSelected = false
				return
			end

			self.title = "Rock The Vote (" .. s .. "s)"
		end

		-- On exit
		function UI.rtv:OnExit()
			Link:Print("General", "You can reopen this menu with !revote")
		end

		UI.rtv:SetCustomDelay(3)
	elseif (id == "VoteList") then
		if (not UI.rtv) or (not UI.rtv.title) then
			return end

		for k, v in pairs(info) do
			local name = UI.rtv.options[k].name
			name = "[" .. v .. "] " .. (v <= 10 and name:Right(#name - 4) or name:Right(#name - 5))
			UI.rtv:UpdateOption(k, name, false, false)
		end
	elseif (id == "InstantVote") then
		UI.rtv:SelectOption(info)
	elseif (id == "Revote") then 
		if (not UI.rtv) or (not UI.rtv.title) then 
			-- This is cheeky
			DATA["rtv"](_, {"GetList", info}, true)

			if (RTVSelected) then 
				UI.rtv:UpdateOption(RTVSelected, false, Color(244, 80, 66), false)
			end
		end
	end
end)

--[[-------------------------------------------------------------------------
	Segmented Style
---------------------------------------------------------------------------]]
local function SEGMENT_Callback(id)
	return function() UI:SendCallback("segment", {id}) end
end

UI:AddListener("segment", function(_, data)
	if (data) and (data[1]) and (UI.segment) and (UI.segment.title) then
		UI.segment:Exit()
		return
	end

	if (data and data[1]) then return end

	UI.segment = UI:NumberedUIPanel("Segment Menu",
		{["name"] = "Set waypoint", ["function"] = SEGMENT_Callback("set")},
		{["name"] = "Goto waypoint", ["function"] = SEGMENT_Callback("goto")},
		{["name"] = "Remove waypoint", ["function"] = SEGMENT_Callback("remove")},
		{["name"] = "Reset waypoints", ["function"] = SEGMENT_Callback("reset")}
	)
end)

-- Silly changelog
hook.Add("Think", "Changelog", function()
	if IsValid(LocalPlayer()) then
		local lastchange = LocalPlayer():GetPData("changelog", false)

		if (not lastchange) or (tonumber(lastchange) != 100) then
			UI:NumberedUIPanel("Change Log",
				{["name"] = "[+] Added !revote command as requested."},
				{["name"] = "[+] Confirmation is now needed when resetting waypoints."},
				{["name"] = "[*] Reset confirmation will now ask again if you haven't used reset in a while."},
				{["name"] = "[*] Segmented style will now reset normally as long as no waypoints are set."}
			)

			LocalPlayer():SetPData("changelog", 100)
		end

		hook.Remove("Think", "Changelog")
	end
end)

--[[-------------------------------------------------------------------------
	World Records
	1. [#1] jsTr (00:14.199, 19 jumps)
---------------------------------------------------------------------------]]
local function WR_OnPress(Index, szMap, nStyle, Item, Speed)
	return function()
		if Admin.EditType and Admin.EditType == 17 and (game.GetMap() == szMap) then
			Admin:ReqAction(Admin.EditType, {nStyle, Index, Item[1], Item[2]})
			return 
		end

		if Speed then
			local place = Index
			local time = Timer:Convert(Item[3] or 0)
			local pl = Item[2] or "????"
			local id = Item[1] or "????"
			local date = Item[4] or "????"
			local style = Core:StyleName(nStyle) or "????"
			local jumps = Speed[3] or "????"
			local topvel = Speed[1] or "????"
			local avgvel = Speed[2] or "????"
			local sync = (Speed[4] or "????") .. "%"
			local str = string.format("Player %s (%s) achieved #%s on %s on %s style (at: %s) with a time of %s. (Average Vel: %s u/s, Top Vel: %s u/s, Jumps: %s, Sync: %s)",
				pl, id, place, szMap, style, date, time, avgvel, topvel, jumps, sync)

			Link:Print( "Timer", str )
		end
	end
end

UI:AddListener("wr", function(_, data)
	local wrList = data[1]
	local recordStyle = data[2]
	local page = data[3]
	local recordsTotal = data[4]
	local map = data[5] or game.GetMap()

	-- New Page?
	if (page ~= 1) and (UI.WR) and (UI.WR.title) then
		for k, v in pairs(wrList) do
			local data
			if (not v[5] or #v[5] < 4) then 
				data = {}
			else
				data = Core.Util:StringToTab(v[5])
			end
			local jumps = data[3] or 0
			UI.WR.options[k] = {["name"] = ("[#" .. k .. "] " .. v[2] .. " (" .. Timer:Convert(v[3]) .. ", " .. jumps .. " jumps)"), ["function"] = WR_OnPress(k, map, recordStyle, v, data)}
		end

		UI.WR.page = UI.WR.page + 1
		UI.WR:UpdateLongestOption()

		return
	end

	-- Convert options to readable by module
	local options = {}
	for k, v in pairs(wrList) do
		local data
		if (not v[5] or #v[5] < 4) then 
			data = {}
		else
			data = Core.Util:StringToTab(v[5])
		end
		local jumps = data[3] or 0
		options[k] = {["name"] = ("[#" .. k .. "] " .. v[2] .. " (" .. Timer:Convert(v[3]) .. ", " .. jumps .. " jumps)"), ["function"] = WR_OnPress(k, map, recordStyle, v, data)}
	end

	-- Set up UI
	UI.WR = UI:NumberedUIPanel(Core:StyleName(recordStyle) .. " Records (#" .. recordsTotal .. ")", unpack(options))
	UI.WR:ForceNextPrevious(true)
	UI.WR.recordCount = recordsTotal
	UI.WR.style = recordStyle
	UI.WR.map = map or game.GetMap()

	-- When 'next' button is pressed
	function UI.WR:OnNext(hitMax)
		if (hitMax) and ((self.page * 7) < self.recordCount) then
			Link:Send("WRList", {self.page + 1, self.style, self.map})
		end
	end
end)
