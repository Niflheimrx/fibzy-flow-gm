-- Scoreboard by justa

-- Fonts
surface.CreateFont("hud.title", {font = "coolvetica", size = 20, weight = 100, antialias = true})
surface.CreateFont("hud.credits", {font = "Tahoma", size = 12, weight = 100, antialias = true})
surface.CreateFont("hud.infotext", {font = "Tahoma", size = 13, weight = 800, antialias = true})
surface.CreateFont("hud.subinfo", {font = "Tahoma", size = 12, weight = 300, antialias = true})
surface.CreateFont("hud.subinfo2", {font = "Tahoma", size = 9, weight = 300, antialias = true})
surface.CreateFont("hud.subtitle", {font = "Tahoma", size = 16, weight = 1000, antialias = true, italic = false})

-- Colours
local SCORE_ONE = Settings:GetValue("PrimaryCol")
local SCORE_TWO = Settings:GetValue("SecondaryCol")
local SCORE_THREE = Settings:GetValue("TertiaryCol")
local SCORE_ACCENT = Settings:GetValue("AccentCol")

-- Outlines?
local outlines = Color( 45, 45, 45 )

-- Text
local text_colour = Settings:GetValue("TextCol")
local text_colour2 = Settings:GetValue("TextCol2")

-- Size
local SCORE_HEIGHT = ScrH() - 118
local SCORE_WIDTH = (ScrW() / 2) + 150

-- Text
local SCORE_TITLE = "justa's cool server"
local SCORE_PLAYERS = "Players: %s/%s"
local SCORE_CREDITS = ""

-- Funcs
local abs = math.abs
local sin = math.sin
local con = Timer:GetConvert()

-- Ranks
-- These need to be changed when new admin system is developed 
local ranks = {"VIP", "VIP+", "Moderator", "Admin", "Zone Admin", "Super Admin", "Developer", "Manager", "Founder", "Owner"}

-- Add Message
-- This scoreboard was ripped from my gamemode, so function is missing :V
local function AddMessage(prefix, message)
	chat.AddText(color_white, "[", Color(0, 200, 200), "Server", color_white, "] ", message)
end

-- Create Scoreboard
local function CreateScoreboard()
	-- The scoreboard is already open you nigger
	if (scoreboard) then
		if (scoreboard_playerrow) then
			scoreboard_playerrow:Remove()
			scoreboard_playerrow = nil
		end
		scoreboard:Remove()
		scoreboard = nil
		gui.EnableScreenClicker(false)

		return
	end

	gui.EnableScreenClicker(false)

	-- Create the interface.
	scoreboard = vgui.Create("EditablePanel")
		scoreboard:SetSize(SCORE_WIDTH, SCORE_HEIGHT)
		scoreboard:Center()

		-- Paint
		scoreboard.Paint = function(self, width, height)
			-- updates
			SCORE_ONE = Color( 42, 42, 42 )
			SCORE_TWO = Color( 42, 42, 42 )
			SCORE_THREE = Color( 42, 42, 42 )
			SCORE_ACCENT = Color( 0, 100, 255 )

			-- Outlines?
			outlines = Color( 45, 45, 45 )

			-- Text
			text_colour = Settings:GetValue("TextCol")
			text_colour2 = Settings:GetValue("TextCol2")

			-- Main
			surface.SetDrawColor(SCORE_ONE)
			surface.DrawRect(0, 0, width, height)
			surface.SetDrawColor(Color( 35, 35, 35 ))

			if outlines then
				surface.DrawOutlinedRect(0, 0, width, height, 10)
			end

			surface.SetDrawColor(Color( 35, 35, 35 ))
			surface.DrawRect(0, 0, width, 35)

			-- Title
			draw.SimpleText(SCORE_TITLE, "hud.title", width / 2, 12, text_colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			-- Map
			draw.SimpleText(game.GetMap(), "hud.title", 14, 12, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			-- Players online
			local text = string.format(SCORE_PLAYERS, #player.GetHumans(), game.MaxPlayers()-2)
			draw.SimpleText(text, "hud.title", width - 14, 12, text_colour, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

			-- Text
			draw.SimpleText(SCORE_CREDITS, "hud.credits", 14, height - 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			--draw.SimpleText("Click on a player's name for an options panel!", "hud.credits", width - 14, height - 20, text_colour, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end

	-- Create our playerlist base panel
	scoreboard.base = scoreboard:Add("DPanel")
		scoreboard.base:SetSize(SCORE_WIDTH - 28, SCORE_HEIGHT - 150)
		scoreboard.base:SetPos(14, 40)

		-- Paint dat bitch!
		scoreboard.base.Paint = function(self, width, height)
			-- Main
			surface.SetDrawColor(SCORE_TWO)
			surface.DrawRect(0, 0, width, 22)
			surface.SetDrawColor(color_black)

			//if outlines then
				//surface.DrawOutlinedRect(0, 0, width, 21)
			//end

			-- Cool fucking way to calculate distances bro
			local distance = (width / 10)

			-- Rank
			draw.SimpleText("Rank", "hud.infotext", 12, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Player", "hud.infotext", distance * 1.5, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Style", "hud.infotext", distance * 4.5, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Status", "hud.infotext", distance * 5.7, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Personal Best", "hud.infotext", distance * 8.5, 10, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("Ping", "hud.infotext", width - 12, 10, text_colour, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end

	-- Calculate
	local width, height = scoreboard.base:GetSize()

	-- Create player row
	local function CreatePlayerRow(pl, isBot)
		local row = vgui.Create("DButton", isBot and scoreboard.bots or scoreboard.players)

		-- Set values
		row:SetSize(width, 40)
		row:SetText("")

		-- Paint
		row.Paint = function(self, width, height)
			-- They left! :(
			if (not IsValid(pl)) then
				scoreboard.players.AddPlayers()
				return
			end

			surface.SetDrawColor(isBot and SCORE_ACCENT or Color( 35, 35, 35 ))
			surface.DrawRect(0, 0, width, height)
			surface.SetDrawColor(color_black)

			//if outlines then
				//surface.DrawOutlinedRect(0, 0, width, height)
			//end

			-- Cool fucking way to calculate distances bro
			local distance = (width / 10)

			-- Player rank
			local pRank = _C.Ranks[pl:GetNWInt("Rank", -1)]

			-- Edited by Niflheimrx, adding custom titles here, just ctrl+c/v for now until new stuff is added
			local rank, VIPTag, VIPTagColor = pl:GetNWInt( "AccessIcon", 0 ), pl:GetNWString( "VIPTag", "" ), pl:GetNWVector( "VIPTagColor", Vector( -1, 0, 0 ) )
			if rank > 0 and VIPTag != "" and VIPTagColor.x >= 0 then
				pRank = { VIPTag, Core.Util:VectorToColor( VIPTagColor ) }
			end

			draw.SimpleText(isBot and "WR Replay" or pRank[1], "hud.subtitle", 12, 20, isBot and Color(255, 255, 255) or pRank[2], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			-- Player name
			local name = isBot and pl:GetNWString("BotName", "Loading...") or pl:Nick()
			if isBot and (name ~= "Loading..." and name ~= "No replay available") then
				local position = pl:GetNWInt("WRPos", 0)
				name = (position > 0 and ("#" .. position .. " run ") or "Run ") .. "by " .. name
			end

			surface.SetFont("hud.subtitle")
			local namewidth, nameheight = surface.GetTextSize(name)
			rank = rank == 0 and "User" or ranks[rank]

			if (rank != "User") then
				draw.SimpleText(string.upper(rank), "hud.subinfo2", (distance * 1.5) + namewidth + 2, 19 + nameheight/2, pl:GetObserverMode() ~= OBS_MODE_NONE and HSVToColor( RealTime() * 40 % 360, 1, 1 ) or HSVToColor( RealTime() * 40 % 360, 1, 1 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			end

			-- justa's name (this will change to VIP not just me xx, feel free to add yourself)
			if (pl:SteamID() == "STEAM_0:1:48688711") then
				draw.SimpleText(name, "hud.subtitle", distance * 1.5, 20, Color( 0, 220 * abs(sin(CurTime())), 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			else
				draw.SimpleText(name, "hud.subtitle", distance * 1.5, 20, pl:GetObserverMode() ~= OBS_MODE_NONE and Color(150, 150, 150, 255) or text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			-- Player style
			local style = Core:StyleName(pl:GetNWInt("Style", _C.Style.Normal))
			draw.SimpleText(style, "hud.subtitle", distance * 4.5, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			-- Current time
			local status = "Start Zone"
			local curr = style == "Bonus" and (pl.Tb or 0) or (pl.Tn or 0)
			local inPlay = style == "Bonus" and (pl.Tb ~= nil) or (pl.Tn ~= nil)
			local finished = style == "Bonus" and (pl.TbF) or (pl.TnF)

			-- We're finished
			if (pl:IsBot()) then
				status = "Playing Recording (1x)"
			elseif (pl:GetObserverMode() ~= OBS_MODE_NONE) then
				local tgt = pl:GetObserverTarget()

				if tgt and IsValid(tgt) and (tgt:IsPlayer() or tgt:IsBot()) then
					local nm = (tgt:IsBot() and (tgt:GetNWString("BotName", "Loading...") .. "'s Replay") or tgt:Nick())

					if (string.len(nm) > 20) then
						nm = nm:Left(20) .. "..."
					end

					status = "Spectating: " .. nm
				else
					status = "Spectating"
				end

			elseif (pl:GetNWInt('inPractice', false)) then
				status = "Practicing"
			elseif (curr > 0) and (finished ~= nil) then
				status = "Finished: " .. con(finished - curr)
			elseif (curr > 0) then
				status = "Running: " .. con(CurTime() - curr)
			end

			-- Calc
			draw.SimpleText(status, "hud.subtitle", distance * 5.7, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			-- Personal best
			local pb = con(pl:GetNWFloat("Record", 0))

			if not pl:IsBot() then
				surface.SetFont("hud.subtitle")
				local place = pl:GetNWInt("SpecialRank", 0)

				if (place == 0) then
					draw.SimpleText(pb, "hud.subtitle", distance * 8.5, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				else

					local w, h = surface.GetTextSize(place)

					draw.SimpleText(pb, "hud.subtitle", distance * 8.5 + 6 + w, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					draw.SimpleText("#" .. place, "hud.subinfo", distance * 8.5, 20, text_colour2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end
			else
				draw.SimpleText(pb, "hud.subtitle", distance * 8.5, 20, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			-- Ping
	 	   local colour246 = Color(255, 255, 255)
	
	   		 if (pl:Ping() > 0) then
	    			if (pl:Ping() >= 100) then
		 			   	colour246 = Color(255, 0, 0)
	       			 else
	    				if (pl:Ping() >= 60) then
		  	  			colour246 = Color(255, 255, 0)
	      	  		else 
		 	  		 	colour246 = Color(0, 255, 0)
			  		end 
	   			end
			end

			if not pl:IsBot() then
			local latency = pl:Ping()
				draw.SimpleText(latency, "hud.subtitle", width - 12, 20, colour246, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
		end

		row.OnMousePressed = function(self)
			if (not scoreboard.moved) then
				local x, y = scoreboard:GetPos()
				scoreboard.moved = true
				scoreboard:MoveTo(x - 150, y, 0.5, 0, -1, function()
					scoreboard_playerrow = vgui.Create("EditablePanel")
					scoreboard_playerrow:SetPos(x + SCORE_WIDTH - 290/2, y)
					scoreboard_playerrow:SetSize(300, pl:IsBot() and 265 - 93 or 265)
					scoreboard_playerrow.pl = pl
					scoreboard_playerrow.Paint = function(self, width, height)
						surface.SetDrawColor(SCORE_ONE)
						surface.DrawRect(0, 0, width, height)
						surface.SetDrawColor(color_black)

						//if outlines then
							//surface.DrawOutlinedRect(0, 0, width, height)
						//end

						surface.SetFont("hud.title")

						-- Player name
						draw.SimpleText(scoreboard_playerrow.pl:IsBot() and scoreboard_playerrow.pl:GetNWString("BotName", "Loading...") or scoreboard_playerrow.pl:Nick(), "hud.title", 84, 26, text_colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

						-- Rank
						local rank = scoreboard_playerrow.pl:GetNWInt("AccessIcon", 0)
						rank = rank == 0 and "User" or ranks[rank]
						draw.SimpleText(scoreboard_playerrow.pl:IsBot() and "Bot" or rank, "hud.title", 84, 44, text_colour2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

						-- VIP
						draw.SimpleText("", "hud.title", 84, 56, text_colour2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

						-- Sep
						surface.DrawLine(0, 84, width, 84)

						if (not scoreboard_playerrow.pl:IsBot()) then
							-- Combobox outline
							//if outlines then
								//surface.DrawOutlinedRect(width - 110, 94, 100, 20)
							//end

							-- Rank BHOP
							local pRank = _C.Ranks[scoreboard_playerrow.pl:GetNWInt("Rank", -1)]
							draw.SimpleText("Rank: " .. pRank[1], "hud.subtitle", 10, 104, text_colour2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							draw.SimpleText("Points: Feature disabled.", "hud.subtitle", 10, 122, text_colour2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							draw.SimpleText("Place: Feature disabled.", "hud.subtitle", 10, 140, text_colour2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
							draw.SimpleText("Amount of WRs: Feature disabled.", "hud.subtitle", 10, 158, text_colour2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
						end

						-- Sep
						surface.DrawLine(0, 177, width, 177)
					end

					local width, height = 300, 200

					-- Avatar
					scoreboard_playerrow.Avatar = scoreboard_playerrow:Add("AvatarImage")
					scoreboard_playerrow.Avatar:SetPos(10, 10)
					scoreboard_playerrow.Avatar:SetSize(64, 64)

					if (scoreboard_playerrow.pl:IsBot()) then
						scoreboard_playerrow.Avatar:SetSteamID(scoreboard_playerrow.pl:GetNWString("ProfileURI", "None"), 256)
					else
						scoreboard_playerrow.Avatar:SetPlayer(scoreboard_playerrow.pl, 256)
					end

					-- Style combobox
					scoreboard_playerrow.Combo = scoreboard_playerrow:Add("DComboBox")
					scoreboard_playerrow.Combo:SetPos(width - 110, 94)
					scoreboard_playerrow.Combo:SetSize(100, 20)
					scoreboard_playerrow.Styles = {}

					-- Fix bug
					if (scoreboard_playerrow.pl:IsBot()) then
						scoreboard_playerrow.Combo:SetVisible(false)
					end

					-- Add Styles
					/*local i = 1
					for k, v in pairs(_C.Style) do
						scoreboard_playerrow.Styles[v] = v
						scoreboard_playerrow.Combo:AddChoice(k, v)
						i = i + 1
					end*/

					-- Set Curr Style
					scoreboard_playerrow.Combo:AddChoice("Disabled", 1)
					scoreboard_playerrow.Combo:ChooseOptionID(1)
					scoreboard_playerrow.Combo.Paint = function(self, width, height)
					end
					scoreboard_playerrow.Combo:SetTextColor(text_colour2)

					-- Create a simple button
					local amount = 1
					scoreboard_playerrow.butts = {}
					local function NewButton(name, y, func)
						local b = vgui.Create("DButton", scoreboard_playerrow)

						b.oy = y
						b:SetPos(amount % 2 == 0 and 150 or 10, scoreboard_playerrow.pl:IsBot() and y - 93 or y)
						b:SetSize(138, 20)
						b:SetText("")
						b.Paint = function(self, width, height)
							surface.SetDrawColor(SCORE_TWO)
							surface.DrawRect(0, 0, width, height)
							surface.SetDrawColor(color_black)

							//if outlines then
								//surface.DrawOutlinedRect(0, 0, width, height)
							//end

							draw.SimpleText(name, "hud.subtitle", width / 2, height / 2, text_colour2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						end
						b.OnMousePressed = function()
							func()
						end

						amount = amount + 1
						table.insert(scoreboard_playerrow.butts, b)
					end

					NewButton("Spectate", 187, function()
						RunConsoleCommand("spectate", scoreboard_playerrow.pl:SteamID(), scoreboard_playerrow.pl:Name())
					end)

					NewButton("PM", 187, function()
						if (scoreboard_playerrow.pl:IsBot()) then
							AddMessage("Server", "You cannot private message a bot.")
							return
						end

						AddMessage("Server", "This feature has not been added yet.")
					end)

					NewButton("Goto Profile", 211, function()
						gui.OpenURL("http://www.steamcommunity.com/profiles/" .. (scoreboard_playerrow.pl:IsBot() and scoreboard_playerrow.pl:GetNWString("ProfileURI", "None") or scoreboard_playerrow.pl:SteamID64()))
					end)

					NewButton("Copy SteamID", 211, function()
						if (scoreboard_playerrow.pl:IsBot()) then
							SetClipboardText(util.SteamIDFrom64(scoreboard_playerrow.pl:GetNWString("ProfileURI", "None")))
						else
							SetClipboardText(scoreboard_playerrow.pl:SteamID())
						end

						AddMessage("Server", "Player " .. (scoreboard_playerrow.pl:IsBot() and scoreboard_playerrow.pl:GetNWString("BotName", "Loading...") or scoreboard_playerrow.pl:Nick()) .. "'s SteamID has been copied to your clipboard.")
					end)

					NewButton("Gag Player", 235, function()
						local pl = scoreboard_playerrow.pl

						-- No
						if (pl == LocalPlayer()) then
							AddMessage("Server", "You can not gag yourself.")
							return
						end

						-- Bot
						if (pl:IsBot()) then
							AddMessage("Server", "You can not perform this action on a bot.")
							return
						end

						AddMessage("Server", "Player " .. pl:Nick() .. " has been " .. (not pl:IsMuted() and "gagged." or "ungagged."))
						pl:SetMuted(not pl:IsMuted())
					end)

					NewButton("Mute Player", 235, function()
						local pl = scoreboard_playerrow.pl

						-- No
						if (pl == LocalPlayer()) then
							AddMessage("Server", "You can not mute yourself.")
							return
						end

						if (pl:IsBot()) then
							AddMessage("Server", "You can not perform this action on a bot.")
							return
						end

						pl.ChatMuted = not pl.ChatMuted
						AddMessage("Server", "Player " .. pl:Name() .. " has been" .. (pl.ChatMuted and " muted." or " unmuted."))
					end)
				end)
			elseif (scoreboard.moved) and (scoreboard_playerrow) then
				scoreboard_playerrow.pl = pl
				scoreboard_playerrow.Avatar:SetPlayer(pl, 256)

				if (pl:IsBot()) then
					scoreboard_playerrow.Combo:SetVisible(false)
					scoreboard_playerrow:SetTall(265-93)
					scoreboard_playerrow.Avatar:SetSteamID(pl:GetNWString("ProfileURI", "None"), 256)

					for k, v in pairs(scoreboard_playerrow.butts) do
						local x, y = v:GetPos()
						v:SetPos(x, v.oy - 93)
					end
				else
					scoreboard_playerrow.Combo:SetVisible(true)
					scoreboard_playerrow:SetTall(265)

					for k, v in pairs(scoreboard_playerrow.butts) do
						local x, y = v:GetPos()
						v:SetPos(x, v.oy)
					end
				end
			end
		end

		return row
	end

	-- DScrollPanel
	scoreboard.players = scoreboard.base:Add("DScrollPanel")
		scoreboard.players:SetSize(width, height - 30)
		scoreboard.players:SetPos(0, 20)
		scoreboard.players.list = {}
		scoreboard.players.VBar:SetSize(0,0)

		-- Add Players
		scoreboard.players.AddPlayers = function()
			-- Already players?
			for k, v in pairs(scoreboard.players.list) do
				v:Remove()
				scoreboard.players.list[k] = nil
			end

			local players = player.GetHumans()
			table.sort(players, function(a, b)
				if not a or not b then return false end
				local ra, rb = a:GetNWInt("Rank", 1), b:GetNWInt("Rank", 1)
				if ra == rb then
					return a:GetNWInt("SpecialRank", 0) > b:GetNWInt("SpecialRank", 0)
				else
					return ra > rb
				end
			end)

			for k, v in pairs(players) do
				local row = CreatePlayerRow(v)
				row:SetPos(0, #scoreboard.players.list == 0 and 0 or #scoreboard.players.list * 39)

				table.insert(scoreboard.players.list, row)
			end

			local height = 600 + (#player.GetHumans() * 39)

			if (height > SCORE_HEIGHT) then
				height = SCORE_HEIGHT
			end

			scoreboard:SetTall(height)
			scoreboard:Center()

			if (scoreboard.bots) then
				scoreboard.bots:SetPos(14, scoreboard:GetTall() - 125)
			end
		end

		-- Adding players
		scoreboard.players.AddPlayers()

		-- Painting the black line around the players
		scoreboard.players.PaintOver = function(self, width, height)
			surface.SetDrawColor(color_black)

			local th = (#scoreboard.players.list * 40)-20

			if (th > height) then
				//if outlines then
					//surface.DrawOutlinedRect(0, 0, width, height)
				//end
			end
		end

	-- Bots at the bottom
	scoreboard.bots = scoreboard:Add("DPanel")
		scoreboard.bots:SetSize(width, 79)
		scoreboard.bots:SetPos(14, scoreboard:GetTall() - 105)
		scoreboard.bots.Paint = function(s,width,height)
		end
		scoreboard.bots.list = {}

		-- Add the bots!
		for k, v in pairs(player.GetBots()) do
			local bot = CreatePlayerRow(v, true)
			bot:SetPos(0, #scoreboard.bots.list == 0 and 0 or #scoreboard.bots.list * 39)
			table.insert(scoreboard.bots.list, bot)
		end
end

function GM:ScoreboardShow()
	CreateScoreboard()
end

function GM:ScoreboardHide()
	CreateScoreboard()
end

function GM:HUDDrawScoreBoard() end

local CanCall = true

hook.Add( "PlayerButtonDown", "SCOREBOARD::ButtonDown", function( ply, key )
	if IsValid( menu ) and key == MOUSE_RIGHT and CanCall then
		Pressed = !Pressed
		CanCall = false
		
		gui.EnableScreenClicker( Pressed )
	end
end )

hook.Add( "PlayerButtonUp", "SCOREBOARD::ButtonUp", function( ply, key )
	if key == MOUSE_RIGHT then
		CanCall = true
	end
end )