-- Inspired by 4chan, obviously. Feel free to change it.

local varFilter = {
	["This is an example to show the format of this shit"] = "nigga",
	["heres another example showing that you need a comma after all the shit"] = "nigga",
}

local _sub, _find, _low, _up, _gs = string.sub, string.find, string.lower, string.upper, string.gsub
local function _rep( s, pat, repl, n )
    pat = _gs( pat, '(%a)', function( v ) return '[' .. _up( v ) .. _low( v ) .. ']' end )
    if n then return _gs( s, pat, repl, n ) else return _gs( s, pat, repl ) end
end

local HelpData, HelpLength, HelpSetter

function GM:PlayerSay( ply, text, team )
	local Prefix = _sub( text, 0, 1 )
	local szCommand = "invalid"

	if Prefix != "!" and Prefix != "/" then
		local szFilter = self:FilterText( ply, text )
		if not team then
			return szFilter
		else
			return Admin:HandleTeamChat( ply, szFilter, text )
		end
	else
		szCommand = _low( _sub( text, 2 ) )
	end

	local szReply = Command:Trigger( ply, szCommand, text )
	if not szReply or not type( szReply ) == "string" then
		return ""
	else
		return szReply
	end
end

function GM:FilterText( ply, text )
	if Radio.Prepared then
		local low = _low( text )
		if _find( low, "jiggy", 1, true ) then
			Core:Send( ply, "Radio", { "Single", nil, Radio.Misc.jiggy } )
		elseif _find( low, "waitin' for a mate", 1, true ) then
			Core:Send( ply, "Radio", { "Single", nil, Radio.Misc.mate } )
		elseif _find( low, "i'm a rude boy", 1, true ) then
			Core:Send( ply, "Radio", { "Single", nil, Radio.Misc.rude } )
		elseif _find( low, "a problem", 1, true ) then
			HelpSetter = ply:Name()
		elseif HelpSetter and table.HasValue( Radio.Misc.target, ply:SteamID() ) then
			Core:Broadcast( "Radio", { "Single", nil, Radio.Misc.problem, ply:Name() .. ": " .. (string.len( text ) > 8 and text or "No, " .. HelpSetter .. ", not really..." ) } )
			HelpSetter = nil
			return ""
		elseif HelpSetter then
			HelpSetter = nil
		end
	end

	for input,output in pairs( varFilter ) do
		text = _rep( text, input, output )
	end

	return text
end

function GM:ShowTeam( ply )
	Core:Send( ply, "GUI_Open", { "Spectate" } )
end


Command = {}
Command.Functions = {}
Command.TimeLimit = 0.8
Command.Limiter = {}

local HelpData, HelpLength


function Command:Init()
	self:Register({"theme", "themeeditor", "themes"}, function(pl)
		pl:ConCommand("kawaii_thememanager")
	end)

	self:Register({"menu", "mainmneu", "options"}, function(pl)
		pl:ConCommand("kawaii_mainmenu")
	end)

	-- General timer commands
	self:Register( { "restart", "r", "respawn", "kill" }, function( ply )
		-- Let's make a nice feature that blocks this command if we're above 5 minutes, unless we confirm.
		if (ply.Tn or ply.Tb) and (not ply:GetNWInt("inPractice", false)) and (not ply.TnF) and (not ply.TbF) then 
			local time = ply.Tn and (CurTime() - ply.Tn or 0) or (ply.Tb and CurTime() - ply.Tb or 0) or 0 
			if (time > 300) and (not ply.informedReset) then 
				-- Inform
				Core:Send(ply, "Print", {"Timer", "Due to your long play time, could you please confirm you want to reset by doing this command again."})
				ply.informedReset = true

				timer.Simple(4, function()
					ply.informedReset = false
				end)

				return
			end
		end

		ply.informedReset = false

		Command:RemoveLimit( ply )
		Command.Restart( ply )
	end )

	self:Register( { "spectate", "spec", "watch", "view" }, function( ply, args )
		Command:RemoveLimit( ply )
		if #args > 0 then
			if type( args[ 1 ] ) == "string" then
				local ar, target, tname = Spectator:GetAlive(), nil, nil
				for id, p in pairs( ar ) do
					if string.find( string.lower( p:Name() ), string.lower( args[1] ), 1, true ) then
						target = p:SteamID()
						tname = p:Name()
						break
					end
				end
				if target then
					if ply.Spectating then
						return Spectator:NewById( ply, target, true, tname )
					else
						args[ 1 ] = target
					end
				end
			end

			Command.Spectate( ply, nil, args )
		else
			Command.Spectate( ply )
		end
	end )

	self:Register( { "noclip", "freeroam", "clip", "wallhack" }, function( ply )
		Command.NoClip( ply )
	end )

	-- Noclip speed
	self:Register({"noclipspeed", "nspeed", "ncspeed"}, function(pl, args)

		--- REMOVED
		if (true) then 
			Core:Send(pl, "Print", {"Notification", "This command has been removed due to a bug, it will be added back soon!"})
			return
		end

		local ty = args[1] or false 
		local spd = args[2] or false 

		-- Not enough arguments
		if (not ty) or (not spd) then 
			Core:Send(pl, "Print", {"Notification", "Not enough arguments specified. (!noclipspeed <walk/shift/duck> <speed>)"})
			return
		end

		-- Invalid type
		if not table.HasValue({"walk", "shift", "duck"}, string.lower(ty)) then 
			Core:Send(pl, "Print", {"Notification", "Incorrect type. (Types: walk/shift/duck)"})
			return
		end

		-- Incorrect speed
		local speed = tonumber(spd)
		if (not speed) or (speed < 0) or (speed > 3500) then 
			Core:Send(pl, "Print", {"Notification", "Incorrect speed, enter a value from 0-3500."})
			return
		end

		-- Set
		pl:SetNWInt("noclip" .. string.lower(ty), speed) 

		-- Inform 
		Core:Send(pl, "Print", {"Notification", ("Noclip type " .. ty .. " speed changed to " .. speed)})
	end)

	self:Register( { "lj", "ljstats", "wj", "longjump", "stats" }, function( ply )
		Stats:ToggleStatus( ply )
	end )

	self:Register( { "ilovejustasomuch" }, function( ply )
		StrafeTrainer_CMD(ply)
	end )

	self:Register( { "tp", "tpto", "goto", "teleport", "tele" }, function( ply, args )
		if not ply:GetNWInt("inPractice", false) then
			return Core:Send( ply, "Print", { "Notification", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport." } )
		end

		if #args > 0 then
			local target
			for _,p in pairs( player.GetAll() ) do
				if string.find( string.lower( p:Name() ), string.lower( args[ 1 ] ), 1, true ) then
					target = p
					break
				end
			end
			if IsValid( target ) then
				if ply.Spectating then
					return Core:Send( ply, "Print", { "Notification", "Your target player is in spectator mode." } )
				end

				ply:SetPos( target:GetPos() )
				ply:SetEyeAngles( target:EyeAngles() )
				ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
				Core:Send( ply, "Print", { "Notification", "You have been teleported to " .. target:Name() } )
			else
				return Core:Send( ply, "Print", { "Notification", "Couldn't find a valid player with search terms: " .. args[ 1 ] } )
			end
		else
			Core:Send( ply, "Print", { "Notification", "No player name enterede. Usage: !tp PlayerName" } )
		end
	end )

	-- RTV commands
	self:Register( { "rtv", "vote", "votemap" }, function( ply, args )
		if #args > 0 then
			if args[ 1 ] == "who" or args[ 1 ] == "list" then
				RTV:Who( ply )
			elseif args[ 1 ] == "check" or args[ 1 ] == "left" then
				RTV:Check( ply )
			elseif args[ 1 ] == "revoke" then
				RTV:Revoke( ply )
			elseif args[ 1 ] == "extend" then
				Admin.VIPProcess( ply, { "extend" } )
			else
				Core:Send( ply, "Print", { "Notification", args[ 1 ] .. " is an invalid subcommand of the rtv command. Valid: who, list, check, left, revoke, extend" } )
			end
		else
			RTV:Vote( ply )
		end
	end )

	self:Register({"revote", "openrtv"}, function(ply, args)
		if (not RTV.VotePossible) then 
			Core:Send(ply, "Print", {"Notification", "There is no vote currently active."})
		else 
			local RTVSend = {}

			for _,map in pairs( RTV.Selections ) do
				table.insert( RTVSend, RTV:GetMapData( map ) )
			end

			UI:SendToClient(false, "rtv", "Revote", RTVSend)
			UI:SendToClient(false, "rtv", "VoteList", RTV.MapVoteList)
		end
	end)

	self:Register( { "revoke", "retreat", "revokertv" }, function( ply )
		RTV:Revoke( ply )
	end )

	self:Register( { "checkvotes", "votecount" }, function( ply )
		RTV:Check( ply )
	end )

	self:Register( { "votelist", "listrtv" }, function( ply )
		RTV:Who( ply )
	end )

	self:Register( { "timeleft", "time", "remaining" }, function( ply )
		Core:Send( ply, "Print", { "Notification", Lang:Get( "TimeLeft", { Timer:Convert( RTV.MapEnd - CurTime() ) } ) } )
	end )

	-- GUI Functionality
	self:Register( { "edithud", "hudedit", "sethud", "movehud" }, function( ply )
		Core:Send( ply, "Client", { "HUDEditToggle" } )
	end )

	self:Register( { "restorehud", "hudrestore", "huddefault" }, function( ply )
		Core:Send( ply, "Client", { "HUDEditRestore", { 20, 115 } } )
	end )

	self:Register( { "opacity", "hudopacity", "visibility", "hudvisibility" }, function( ply, args )
		if not tonumber( args[ 1 ] ) then
			return Core:Send( ply, "Print", { "Notification", Lang:Get( "MissingArgument", { "an extra numeric" } ) } )
		end

		Core:Send( ply, "Client", { "HUDOpacity", math.Clamp( tonumber( args[ 1 ] ), 0, 255 ) } )
	end )

	self:Register( { "showgui", "showhud", "hidegui", "hidehud", "togglegui", "togglehud" }, function( ply, args )
		if string.sub( args.Key, 1, 4 ) == "show" or string.sub( args.Key, 1, 4 ) == "hide" then
			Core:Send( ply, "Client", { "GUIVisibility", string.sub( args.Key, 1, 4 ) == "hide" and 0 or 1 } )
		else
			Core:Send( ply, "Client", { "GUIVisibility", -1 } )
		end
	end )

	self:Register( { "sync", "showsync", "sink", "strafe", "monitor" }, function( ply )
		SMgrAPI:ToggleSyncState( ply )
	end )

	-- Windows
	self:Register( { "style", "mode", "bhop", "styles", "modes" }, function( ply )
		Command:RemoveLimit( ply )
		Core:Send( ply, "GUI_Open", { "Style" } )
	end )

	self:Register( { "nominate", "rtvmap", "playmap", "addmap", "maps" }, function( ply, args )
		if #args > 0 then
			Command:RemoveLimit( ply )
			Command.Nominate( ply, nil, args )
		else
			Core:Send( ply, "GUI_Open", { "Nominate", { RTV.MapListVersion } } )
		end
	end )

	self:Register( { "wr", "wrlist", "records" }, function( ply, args )
		local nStyle, nPage = ply.Style, 1
		if #args > 0 then
			Player:SendRemoteWRList( ply, args[ 1 ], nStyle, nPage )
		else
			UI:SendToClient(ply, "wr", Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ))
			--Core:Send( ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ) } } )
		end
	end )

	self:Register( { "rank", "ranks", "ranklist" }, function( ply )
		local bAngled = Player:GetRankType( ply.Style )
		Core:Send( ply, "GUI_Open", { "Ranks", { ply.Rank or 1, ply.RankSum or 0, bAngled, (bAngled and Player.AngledScalar or Player.NormalScalar) or 0.0001 } } )
	end )

	self:Register( { "top", "toplist", "top100", "bestplayers" }, function( ply )
		local nPage = 1
		Core:Send( ply, "GUI_Open", { "Top", { 2, Player:GetTopPage( nPage, ply.Style ), nPage, Player:GetTopCount( ply.Style ), Player:GetRankType( ply.Style, true ) } } )
	end )

	self:Register( { "mapsbeat", "beatlist", "listbeat", "mapsdone", "mapscompleted", "beat", "done", "completed", "howgoodami" }, function( ply )
		--Core:Send( ply, "GUI_Open", { "Maps", { "Completed", Player:GetMapsBeat( ply ) } } )
		Player:GetMapsBeat( ply, 'Completed' )
	end )

	self:Register( { "mapsleft", "left", "leftlist", "listleft", "notbeat", "howbadami" }, function( ply )
		--Core:Send( ply, "GUI_Open", { "Maps", { "Left", Player:GetMapsBeat( ply ) } } )
		Player:GetMapsBeat( ply, 'Left' )
	end )

	self:Register( { "mywr", "mywrs", "wr1", "wr#1", "wrcount", "wrcounter", "countwr", "wramount" }, function( ply )
		MySQL:Start( "SELECT t2.* FROM game_times AS t2 INNER JOIN (SELECT szUID, nStyle, szPlayer, MIN(nTime) AS nMin, szMap FROM game_times GROUP BY szMap, nStyle) AS t1 ON t2.szUID = t1.szUID AND t2.nTime = t1.nMin WHERE t2.szUID = '" .. ply:SteamID() .. "'", function(Query)
			if not Query then
				Core:Send( ply, "Print", { "Notification", "You have no #1 times." } )
			else
				local tab = {}
				for _,d in pairs( Query ) do
					table.insert( tab, { d["szMap"], tonumber( d["nTime"] ), tonumber( d["nStyle"] ), { d["szDate"], d["vData"], tonumber( d["nPoints"] ), d["szPlayer"] } } )
				end
				Core:Send( ply, "GUI_Open", { "Maps", { "WR", tab } } )
			end
		end)
	end )

	-- Weapon functionality
	self:Register( { "crosshair", "cross", "togglecrosshair", "togglecross", "setcross" }, function( ply, args )
		if #args > 0 then
			local szType = args[ 1 ]
			if szType == "color" then
				if not #args == 4 or not tonumber( args[ 2 ] ) or not tonumber( args[ 3 ] ) or not tonumber( args[ 4 ] ) then
					return Core:Send( ply, "Print", { "Notification", "You need to supply 4 parameters: !crosshair color r g b - Where r, g and b are numbers [0-255]" } )
				end

				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_color_r"] = args[ 2 ], ["sl_cross_color_g"] = args[ 3 ], ["sl_cross_color_b"] = args[ 4 ] } } )
			elseif szType == "length" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core:Send( ply, "Print", { "Notification", "You need to supply 2 parameters: !crosshair length number" } )
				end

				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_length"] = args[ 2 ] } } )
			elseif szType == "gap" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core:Send( ply, "Print", { "Notification", "You need to supply 2 parameters: !crosshair gap number" } )
				end

				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_gap"] = args[ 2 ] } } )
			elseif szType == "thick" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core:Send( ply, "Print", { "Notification", "You need to supply 2 parameters: !crosshair thick number" } )
				end

				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_thick"] = args[ 2 ] } } )
			elseif szType == "opacity" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core:Send( ply, "Print", { "Notification", "You need to supply 2 parameters: !crosshair opacity number - Where number is [0-255]" } )
				end

				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_opacity"] = args[ 2 ] } } )
			elseif szType == "default" then
				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_color_r"] = 0, ["sl_cross_color_g"] = 255, ["sl_cross_color_b"] = 0, ["sl_cross_length"] = 1, ["sl_cross_gap"] = 1, ["sl_cross_thick"] = 0, ["sl_cross_opacity"] = 255 } } )
			elseif szType == "random" then
				Core:Send( ply, "Client", { "Crosshair", { ["sl_cross_color_r"] = math.random( 0, 255 ), ["sl_cross_color_g"] = math.random( 0, 255 ), ["sl_cross_color_b"] = math.random( 0, 255 ), ["sl_cross_length"] = math.random( 1, 50 ), ["sl_cross_gap"] = math.random( 1, 35 ), ["sl_cross_thick"] = math.random( 0, 10 ), ["sl_cross_opacity"] = math.random( 70, 255 ) } } )
			else
				Core:Send( ply, "Print", { "Notification", "Available commands: color [red green blue], length [scalar], gap [scalar], thick [scalar], opacity [alpha], default, random" } )
			end
		else
			Core:Send( ply, "Client", { "Crosshair" } )
		end
	end )

	self:Register( { "glock", "usp", "knife", "p90", "mp5", "crowbar", "deagle", "fiveseven", "m4a1", "ump45", "scout" }, function( ply, args )
		if ply.Spectating or ply:Team() == TEAM_SPECTATOR then
			return Core:Send( ply, "Print", { "Notification", Lang:Get( "SpectateWeapon" ) } )
		else
			-- Edited: justa
			-- This will be done via a UI Config in the future
			local maps_disallowed = {"bhop_sandtrap", "bhop_sandtrap2", "bhop_sandtrap3", "bhop_classicrainbowaux_fix", "kz_bhop_yonkoma"}

			if table.HasValue(maps_disallowed, game.GetMap()) then
				return Core:Send(ply, "Print", {"Notification", "Sorry, weapons are disabled on this map."})
			end

			local bFound = false
			for _,ent in pairs( ply:GetWeapons() ) do
				if ent:GetClass() == "weapon_" .. args.Key then
					bFound = true
					break
				end
			end
			if not bFound then
				ply.WeaponPickup = true
				ply:Give( "weapon_" .. args.Key )
				ply:SelectWeapon( "weapon_" .. args.Key )
				ply.WeaponPickup = nil
				Core:Send( ply, "Print", { "Notification", Lang:Get( "PlayerGunObtain", { args.Key } ) } )
			else
				Core:Send( ply, "Print", { "Notification", Lang:Get( "PlayerGunFound", { args.Key } ) } )
			end
		end
	end )

	-- Edited: justa
	-- Concommand, as if we did this serverside it would do it for everyone nifl!! <3

	self:Register({"trigger", "triggers", "showtrigger", "showtriggers", "toggletriggers"}, function(pl)
		pl:ConCommand("bhop_toggletriggers")

		Core:Send(pl, "Print", {"Notification", "This command is NOT currently disabled, sorry!"})
	end)

	self:Register({"acs", "anticheats", "showanticheats", "toggleanticheats", "toggleacs"}, function(pl)
		pl:ConCommand("_toggleanticheats")

		Core:Send(pl, "Print", {"Notification", "You have toggled anti-cheat zone visibility."})
	end)

	self:Register({"gunsounds", "shotsounds", "weaponsounds"}, function(pl)
		pl:ConCommand("_togglegunsounds")

		Core:Send(pl, "Print", {"Notification", "You have toggled gunsounds."})
	end)

	self:Register( { "remove", "strip", "stripweapons" }, function( ply )
		if not ply.Spectating and not ply:IsBot() then
			ply:StripWeapons()
		else
			return Core:Send( ply, "Print", { "Notification", Lang:Get( "SpectateWeapon" ) } )
		end
	end )

	self:Register( { "flip", "leftweapon", "leftwep", "lefty", "flipwep", "flipweapon" }, function( ply )
		ply.WeaponsFlipped = not ply.WeaponsFlipped
		Core:Send( ply, "Client", { "WeaponFlip" } )
	end )

	-- Client functionality
	self:Register( { "show", "hide", "showplayers", "hideplayers", "toggleplayers", "seeplayers", "noplayers" }, function( ply, args )
		if string.sub( args.Key, 1, 4 ) == "show" or string.sub( args.Key, 1, 4 ) == "hide" then
			Core:Send( ply, "Client", { "PlayerVisibility", string.sub( args.Key, 1, 4 ) == "hide" and 0 or 1 } )
		else
			Core:Send( ply, "Client", { "PlayerVisibility", -1 } )
		end
	end )

	self:Register( { "showspec", "hidespec", "togglespec" }, function( ply, args )
		local key = string.sub( args.Key, 1, 1 )
		if key == "s" then Core:Send( ply, "Client", { "SpecVisibility", 1 } )
		elseif key == "h" then Core:Send( ply, "Client", { "SpecVisibility", 0 } )
		elseif key == "t" then Core:Send( ply, "Client", { "SpecVisibility", nil } )
		end
	end )

	self:Register( { "chat", "togglechat", "hidechat", "showchat" }, function( ply )
		Core:Send( ply, "Client", { "Chat" } )
	end )

	self:Register( { "muteall", "muteplayers", "unmuteall", "unmuteplayers" }, function( ply, args )
		Core:Send( ply, "Client", { "Mute", string.sub( args.Key, 1, 2 ) == "mu" and true or nil } )
	end )

	self:Register( { "playernames", "playername", "player", "playertag", "targetids", "targetid", "labels" }, function( ply )
		Core:Send( ply, "Client", { "TargetIDs" } )
	end )

	self:Register( { "water", "fixwater", "reflection", "refraction" }, function( ply )
		Core:Send( ply, "Client", { "Water" } )
	end )

	self:Register( { "sky", "disablesky", "blacksky" }, function( ply )
		Core:Send( ply, "Client", { "Sky" } )
	end )

	self:Register( { "fog", "disablefog", "nofog", "removefog" }, function( ply )
		Core:Send( ply, "Client", { "Fog" } )
	end )

	self:Register( { "simple", "simpletextures" }, function( ply )
		Core:Send( ply, "Client", { "Simple" } )
	end )

	self:Register( { "decals", "blood", "shots", "removedecals" }, function( ply )
		Core:Send( ply, "Client", { "Decals" } )
	end )

	self:Register( { "vipnames", "disguise", "disguises", "reveal" }, function( ply )
		Core:Send( ply, "Client", { "Reveal" } )
	end )

	self:Register( { "space", "spacetoggle", "holdtoggle", "auto" }, function( ply )
		ply.SpaceToggle = not ply.SpaceToggle
		Core:Send( ply, "Print", { "Notification", "Holding space will now" .. (not ply.SpaceToggle and " no longer" or "") .. " toggle" } )
		Core:Send( ply, "Client", { "Space", true } )
	end )

	self:Register( { "gravityboosterfix", "boosterfix2" }, function( ply, args )
	local pBFix = ply.Boosterfix
	pBFix.Enabled = not pBFix.Enabled
		Core:Send( ply, "Print", { "Notification", "You have " .. (pBFix.Enabled and "Enabled" or "Disabled") .. " Gravity Boosterfix." } )
	end )

	-- Bot commands
	self:Register( { "bot" }, function( ply, args )
		Core:Send( ply, "Print", { "Notification", "This command has been renamed, please do !runs" } )
	end )

	self:Register( { "setbot", "setrun", "runs", "botset" }, function( ply, args )
		if not args[ 1 ] then
			local list = Bot:GetMultiBots()
			if #list > 0 then
				return Core:Send( ply, "Print", { "Notification", "Runs on these styles are recorded and playable: " .. string.Implode( ", ", list ) .. " (Use !setbot Style to start playback.)" } )
			else
				return Core:Send( ply, "Print", { "Notification", "There are no other bots available for playback." } )
			end
		end

		local nStyle = tonumber( args[ 1 ] )
		if not nStyle then
			--table.remove( args.Upper, 1 )
			local szStyle = string.Implode( " ", args.Upper )

			local a = Core:GetStyleID( szStyle )
			if not Core:IsValidStyle( a ) then
				return Core:Send( ply, "Print", { "Notification", "You have entered an invalid style name. Use the exact name shown on !styles or use their respective ID." } )
			else
				nStyle = a
			end
		end

		local Change = Bot:ChangeMultiBot( nStyle )
		if string.len( Change ) > 10 then
			Core:Send( ply, "Print", { "Notification", Change } )
		else
			Core:Send( ply, "Print", { "Notification", Lang:Get( "BotMulti" .. Change ) } )
		end
	end )

	-- Info commands
	self:Register( { "help", "commands", "command" }, function( ply, args )
		Command:GetHelp()

		if #args > 0 then
			local mainArg, th = "", table.HasValue
			for main,data in pairs( Command.Functions ) do
				if th( data[ 1 ], string.lower( args[ 1 ] ) ) then
					mainArg = main
					break
				end
			end

			if mainArg != "" then
				local data = Lang.Commands[ mainArg ]
				if data then
					if string.sub( data, 1, 7 ) == "A quick" or string.sub( data, 1, 7 ) == "For VIP" then
						Core:Send( ply, "Print", { "Notification", "The !" .. mainArg .. " command is " .. data:gsub("%a", string.lower, 1) } )
					else
						Core:Send( ply, "Print", { "Notification", "The !" .. mainArg .. " command " .. data:gsub("%a", string.lower, 1) } )
					end
				else
					Core:Send( ply, "Print", { "Notification", "The command '" .. mainArg .. "' has no documentation" } )
				end
			else
				Core:Send( ply, "Print", { "Notification", "The command '" .. mainArg .. "' isn't available or has no documentation" } )
			end
		else
			net.Start( Core.Protocol2 )
			net.WriteString( "Help" )

			if ply.HelpReceived then
				net.WriteUInt( 0, 32 )
			else
				net.WriteUInt( HelpLength, 32 )
				net.WriteData( HelpData, HelpLength )
				ply.HelpReceived = true
			end

			net.Send( ply )
		end
	end )

	self:Register( { "map", "points", "mapdata", "mapinfo", "difficulty", "tier" }, function( ply, args )
		if #args > 0 then
			if not args[ 1 ] then return end
			if RTV:MapExists( args[ 1 ] ) then
				local data = RTV:GetMapData( args[ 1 ] )
				Core:Send( ply, "Print", { "Notification", Lang:Get( "MapInfo", { data[ 1 ], data[ 2 ] or 1, "No more details available", "" } ) } )
			else
				Core:Send( ply, "Print", { "Notification", Lang:Get( "MapInavailable", { args[ 1 ] } ) } )
			end
		else
			local nMult, bMult = Timer.Multiplier or 1, Timer.BonusMultiplier or 1
			local szBonus = Zones.BonusPoint and " (Bonus has a multiplier of " .. bMult .. ")" or ""
			local nPoints = Timer:GetPointsForMap( ply.Record, ply.Style )
			local szPoints = "Obtained " .. math.floor( nPoints ) .. " / " .. nMult .. " pts"

			Core:Send( ply, "Print", { "Notification", Lang:Get( "MapInfo", { game.GetMap(), Timer.Multiplier or 1, szPoints, szBonus } ) } )
		end
	end )

	self:Register( { "plays", "playcount", "timesplayed", "howoften", "overplayed" }, function( ply )
		Core:Send( ply, "Print", { "Notification", Lang:Get( "MapPlayed", { Timer.PlayCount or 1 } ) } )
	end )

	self:Register( { "end", "goend", "gotoend", "tpend" }, function( ply )
		if ply:GetNWInt("inPractice", false) then
			local vPoint = Zones:GetCenterPoint( Zones.Type["Normal End"] )
			if vPoint then
				ply:SetPos( vPoint )
				Core:Send( ply, "Print", { "Timer", Lang:Get( "PlayerTeleport", { "the normal end zone!" } ) } )
			else
				Core:Send( ply, "Print", { "Timer", Lang:Get( "MiscZoneNotFound", { "normal end" } ) } )
			end
		else
			Core:Send( ply, "Print", { "Timer", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport." } )
		end
	end )

	self:Register( { "endbonus", "endb", "bend", "gotobonus", "tpbonus" }, function( ply )
		if ply:GetNWInt("inPractice", false) then
			local vPoint = Zones:GetCenterPoint( Zones.Type["Bonus End"] )
			if vPoint then
				ply:SetPos( vPoint )
				Core:Send( ply, "Print", { "Timer", Lang:Get( "PlayerTeleport", { "the bonus end zone!" } ) } )
			else
				Core:Send( ply, "Print", { "Timer", Lang:Get( "MiscZoneNotFound", { "bonus end" } ) } )
			end
		else
			Core:Send( ply, "Print", { "Timer", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport." } )
		end
	end )

	self:Register( { "hop", "switch", "server" }, function( ply, args )
		if #args > 0 then
			local data = Lang.Servers[ args[ 1 ] ]
			if data then
				ply.DCReason = "Player hopped to " .. data[ 2 ]
				Core:Send( ply, "Client", { "Server", data } )
				timer.Simple( 10, function()
					if IsValid( ply ) then
						ply.DCReason = nil
					end
				end )
			else
				Core:Send( ply, "Print", { "Notification", "The server '" .. args[ 1 ] .. "' is not a valid server." } )
			end
		else
			local servers = "None"
			local tab = {}

			for server,data in pairs( Lang.Servers ) do
				table.insert( tab, server )
			end

			if #tab > 0 then
				servers = string.Implode( ", ", tab )
			end

			Core:Send( ply, "Print", { "Notification", "Usage: !hop [server id]\nAvailable servers to !hop to: " .. servers } )
		end
	end )

	self:Register( { "about", "info", "credits", "author", "owner" }, function( ply )
		Core:Send( ply, "Print", { "Notification", Lang:Get( "MiscAbout" ) } )
	end )

	self:Register( { "tutorial", "tut", "howto", "helppls", "plshelp" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.TutorialLink } )
	end )

	self:Register( { "website", "flow", "surfline", "fl", "flweb", "web" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.WebsiteLink } )
	end )

	self:Register( { "youtube", "speedruns", "videos", "video" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.ChannelLink } )
	end )

	self:Register( { "forum", "forums", "community" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.ForumLink } )
	end )

	self:Register( { "donate", "donation", "sendmoney", "givemoney", "gibepls" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.DonateLink .. "&steam=" .. ply:SteamID() } )
	end )

	self:Register( { "version", "lastchange" }, function( ply )
		Core:Send( ply, "Client", { "Tutorial", Lang.ChangeLink } )
	end )

	-- Easy access commands
	self:Register( { "normal", "default", "standard", "n" }, function( ply )
		Command:RemoveLimit( ply )
		Command.Style( ply, nil, { _C.Style.Normal } )
	end )

	self:Register( { "sideways", "sw" }, function( ply )
		Command:RemoveLimit( ply )
		Command.Style( ply, nil, { _C.Style.SW } )
	end )

	self:Register( { "halfsideways", "halfsw", "hsw", "h" }, function( ply )
		Command:RemoveLimit( ply )
		Command.Style( ply, nil, { _C.Style.HSW } )
	end )

	self:Register( { "wonly", "w" }, function( ply )
		Command:RemoveLimit( ply )
		Command.Style( ply, nil, { _C.Style["W-Only"] } )
	end )

	self:Register( { "aonly", "a" }, function( ply )
		Command:RemoveLimit( ply )
		Command.Style( ply, nil, { _C.Style["A-Only"] } )
	end )

	self:Register( { "legit", "l" }, function( ply )
		Command:RemoveLimit( ply )
		Command.Style( ply, nil, { _C.Style.Legit } )
	end )

	self:Register( { "scroll", "s", "easy", "easyscroll", "e", "ez" }, function( ply )
		Command:RemoveLimit( ply )
		Command.Style( ply, nil, { _C.Style["Easy Scroll"] } )
	end )

	self:Register( { "bonus", "extra", "b" }, function( ply )
		Command:RemoveLimit( ply )
		Command.Style( ply, nil, { _C.Style.Bonus } )
	end )

	self:Register( { "practice", "try", "free", "p" }, function( ply )
		Core:Send(ply, "Print", {"Timer", "This feature has been removed, using checkpoint or noclip will now disable your timer instead."})
	end )

	self:Register( { "wrn", "wrnormal", "nwr" }, function( ply, args )
		local nStyle, nPage = _C.Style.Normal, 1
		if #args > 0 then
			Player:SendRemoteWRList( ply, args[ 1 ], nStyle, nPage )
		else
			UI:SendToClient(ply, "wr", Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ))
		end
	end )

	self:Register( { "wrsw", "wrsideways", "swwr" }, function( ply, args )
		local nStyle, nPage = _C.Style.SW, 1
		if #args > 0 then
			Player:SendRemoteWRList( ply, args[ 1 ], nStyle, nPage )
		else
			UI:SendToClient(ply, "wr", Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ))
		end
	end )

	self:Register( { "wrhsw", "wrhalf", "wrhalfsw", "wrhalfsideways", "hswwr" }, function( ply, args )
		local nStyle, nPage = _C.Style.HSW, 1
		if #args > 0 then
			Player:SendRemoteWRList( ply, args[ 1 ], nStyle, nPage )
		else
			UI:SendToClient(ply, "wr", Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ))
		end
	end )

	self:Register( { "wrw", "wrwonly", "wwr", "wonlywr" }, function( ply, args )
		local nStyle, nPage = _C.Style["W-Only"], 1
		if #args > 0 then
			Player:SendRemoteWRList( ply, args[ 1 ], nStyle, nPage )
		else
			UI:SendToClient(ply, "wr", Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ))
		end
	end )

	self:Register( { "wra", "wraonly", "awr", "aonlywr" }, function( ply, args )
		local nStyle, nPage = _C.Style["A-Only"], 1
		if #args > 0 then
			Player:SendRemoteWRList( ply, args[ 1 ], nStyle, nPage )
		else
			UI:SendToClient(ply, "wr", Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ))
		end
	end )

	self:Register( { "wrl", "wrlegit", "lwr" }, function( ply, args )
		local nStyle, nPage = _C.Style.Legit, 1
		if #args > 0 then
			Player:SendRemoteWRList( ply, args[ 1 ], nStyle, nPage )
		else
			UI:SendToClient(ply, "wr", Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ))
		end
	end )

	self:Register( { "wrs", "wrscroll", "swr", "scrollwr", "wre", "ewr" }, function( ply, args )
		local nStyle, nPage = _C.Style["Easy Scroll"], 1
		if #args > 0 then
			Player:SendRemoteWRList( ply, args[ 1 ], nStyle, nPage )
		else
			UI:SendToClient(ply, "wr", Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ))
		end
	end )

	self:Register( { "wrb", "wrbonus", "bwr" }, function( ply, args )
		local nStyle, nPage = _C.Style.Bonus, 1
		if #args > 0 then
			Player:SendRemoteWRList( ply, args[ 1 ], nStyle, nPage )
		else
			UI:SendToClient(ply, "wr", Timer:GetRecordList( nStyle, nPage ), nStyle, nPage, Timer:GetRecordCount( nStyle ))
		end
	end )

	self:Register( { "swtop", "hswtop", "wtop", "atop" }, function( ply )
		local nPage = 1
		Core:Send( ply, "GUI_Open", { "Top", { 2, Player:GetTopPage( nPage, _C.Style.SW ), nPage, Player:GetTopCount( _C.Style.SW ), Player:GetRankType( _C.Style.SW, true ) } } )
	end )

	-- VIP only commands
	self:Register( "extend", function( ply )
		Admin.VIPProcess( ply, { "extend" } )
	end )

	self:Register( { "emote", "me", "say" }, function( ply, args )
		Admin.VIPProcess( ply, { "me", args.Upper }, true )
	end )

	-- Different handler functions
	self:Register( "admin", Admin.CommandProcess )
	self:Register( "vip", Admin.VIPProcess )
	--self:Register( { "cp", "cpmenu", "cpsave", "cpload" }, Timer.CPProcess )
	self:Register( { "radio", "groove", "gs", "yt", "song", "play" }, Radio.CommandProcess )

	-- Default functions
	self:Register( "invalid", function( ply, args )
		Core:Send( ply, "Print", { "Notification", Lang:Get( "InvalidCommand", { args.Key } ) } )
	end )
end

function Command:Register( varCommand, varFunc )
	local MainCommand, CommandList = "undefined", { "undefined" }
	if type( varCommand ) == "table" then
		MainCommand = varCommand[ 1 ]
		CommandList = varCommand
	elseif type( varCommand ) == "string" then
		MainCommand = varCommand
		CommandList = { varCommand }
	end

	Command.Functions[ MainCommand ] = { CommandList, varFunc }
end

function Command:Trigger( ply, szCommand, szText )
	if not Command:Possible( ply ) then return nil end

	local szFunc = nil
	local mainCommand, commandArgs = szCommand, {}

	if string.find( szCommand, " ", 1, true ) then
		local splitData = string.Explode( " ", szCommand )
		mainCommand = splitData[ 1 ]

		local splitDataUpper = string.Explode( " ", szText )
		commandArgs.Upper = {}

		for i = 2, #splitData do
			table.insert( commandArgs, splitData[ i ] )
			table.insert( commandArgs.Upper, splitDataUpper[ i ] )
		end
	end

	for _, data in pairs( Command.Functions ) do
		for __, alias in pairs( data[ 1 ] ) do
			if mainCommand == alias then
				szFunc = data[ 1 ][ 1 ]
				break
			end
		end
	end

	if not szFunc then szFunc = "invalid" end
	commandArgs.Key = mainCommand

	local varFunc = Command.Functions[ szFunc ]
	if varFunc then
		varFunc = varFunc[ 2 ]
		return varFunc( ply, commandArgs )
	end

	return nil
end

function Command:GetHelp()
	if not HelpData or not HelpLength then
		local tab = {}

		for command,data in pairs( Command.Functions ) do
			if not Lang.Commands[ command ] then continue end
			table.insert( tab, { Lang.Commands[ command ], data[ 1 ] } )
		end

		HelpData = util.Compress( util.TableToJSON( tab ) )
		HelpLength = #HelpData
	end
end


function Command:Possible( ply )
	if not Command.Limiter[ ply ] then
		Command.Limiter[ ply ] = CurTime()
	else
		if CurTime() - Command.Limiter[ ply ] < Command.TimeLimit then
			Core:Send( ply, "Print", { "Notification", Lang:Get( "CommandLimiter", { Lang.MiscCommandLimit[ math.random( 1, #Lang.MiscCommandLimit ) ], math.ceil( Command.TimeLimit - (CurTime() - Command.Limiter[ ply ]) ) } ) } )
			Command.Limiter[ ply ] = Command.Limiter[ ply ] + 0.5
			return false
		end

		Command.Limiter[ ply ] = CurTime()
	end

	return true
end

function Command:RemoveLimit( ply )
	Command.Limiter[ ply ] = nil
end


function Command.Restart( ply )
	if not Command:Possible( ply ) then return end
	if ply:Team() != _C.Team.Spectator then
		local szWeapon = nil
		if IsValid( ply:GetActiveWeapon() ) then
			szWeapon = ply:GetActiveWeapon():GetClass() or _C.Player.DefaultWeapon
		end

		ply.ReceiveWeapons = not not szWeapon
		ply:KillSilent()
		ply:Spawn()
		ply:ResetTimer()
		ply.ReceiveWeapons = nil

		if szWeapon and ply:HasWeapon( szWeapon ) then
			ply:SelectWeapon( szWeapon )
		end

		if ply.WeaponsFlipped then
			Core:Send( ply, "Client", { "WeaponFlip", true } )
		end
	else
		Core:Send( ply, "Print", { "Timer", Lang:Get( "SpectateRestart" ) } )
	end
end

function Command.Style( ply, _, varArgs )
	if not Command:Possible( ply ) then return end
	if not varArgs[ 1 ] or not tonumber( varArgs[ 1 ] ) then return end

	-- edited: justa
	if (ply.Style == _C.Style.Segment) and (tonumber(varArgs[1]) ~= _C.Style.Segment) then 
		Segment:Reset(ply)
		Segment:Exit(ply)
	end

	if tonumber( varArgs[ 1 ] ) == ply.Style then
		if ply.Style == _C.Style.Bonus then
			Command:RemoveLimit( ply )
			return Command.Restart( ply )
		else
			return Core:Send( ply, "Print", { "Timer", Lang:Get( "StyleEqual", { Core:StyleName( ply.Style ) } ) } )
		end
	end

	local nStyle = tonumber( varArgs[ 1 ] ) or _C.Style.Normal
	if nStyle == _C.Style.Bonus and not Zones.BonusPoint then
		return Core:Send( ply, "Print", { "Timer", Lang:Get( "StyleBonusNone" ) } )
	elseif nStyle == _C.Style.Bonus then
		ply:ResetTimer()
	elseif ply.Style == _C.Style.Bonus then
		ply:BonusReset()
	elseif ply:GetNWInt("inPractice", false) then
		ply.Tn = nil
		Core:Send( ply, "Timer", { "Start", ply.Tn } )
	end

	Player:LoadStyle( ply, nStyle )
end

function Command.Spectate( ply, _, varArgs )
	if not Command:Possible( ply ) then return end

	if ply.Spectating and varArgs and varArgs[ 1 ] then
		return Spectator:NewById( ply, varArgs[ 1 ], true, varArgs[ 2 ] )
	elseif ply.Spectating then
		local target = ply:GetObserverTarget()
		ply:SetTeam( _C.Team.Players )
		Command:RemoveLimit( ply )
		Command.Restart( ply )
		ply.Spectating = false
		ply:SetNWInt( "Spectating", 0 )
		Core:Send( ply, "Spectate", { "Clear" } )
		Core:Send( ply, "Client", { "Display" } )
		Spectator:End( ply, target )

		if Admin:CanAccess( ply, Admin.Level.Admin ) then
			SMgrAPI:SendSyncData( ply, {} )
		end
	else
		ply:SetNWInt( "Spectating", 1 )
		Core:Send( ply, "Spectate", { "Clear" } )
		ply.Spectating = true
		ply:KillSilent()
		ply:ResetTimer()
		GAMEMODE:PlayerSpawnAsSpectator( ply )
		ply:SetTeam( TEAM_SPECTATOR )

		if varArgs and varArgs[ 1 ] then
			return Spectator:NewById( ply, varArgs[ 1 ], nil, varArgs[ 2 ] )
		end

		Spectator:New( ply )
	end
end

function Command.Nominate( ply, _, varArgs )
	if not Command:Possible( ply ) then return end
	if not varArgs[ 1 ] then return end
	if not RTV:MapExists( varArgs[ 1 ] ) then return Core:Send( ply, "Print", { "Notification", Lang:Get( "MapInavailable", { varArgs[ 1 ] } ) } ) end
	if varArgs[ 1 ] == game.GetMap() then return Core:Send( ply, "Print", { "Notification", Lang:Get( "NominateOnMap" ) } ) end
	if not RTV:IsAvailable( varArgs[ 1 ] ) then return Core:Send( ply, "Print", { "Notification", "Sorry, this map isn't available on the server itself. Please contact an admin!" } ) end

	RTV:Nominate( ply, varArgs[ 1 ] )
end

function Command.NoClip( ply, _, varArgs )
	if (not ply:GetNWInt("inPractice")) and (ply.Tn) or (ply.Tb) then 
		Core:Send(ply, "Print", {"Timer", "Your timer has been stopped due to the use of noclip."})
		ply:StopAnyTimer()
		ply:SetNWInt("inPractice", true)
		ply:ConCommand("noclip")
	elseif (not ply:GetNWInt("inPractice")) then
		Core:Send(ply, "Print", {"Timer", "You cannot use noclip in the start zone."})
		return
	end

	ply:ConCommand("noclip")
end


function Command.ServerCommand( ply, szCmd, varArgs )
	local bConsole = false
	if not IsValid( ply ) and not ply.Name and not ply.Team then
		bConsole = true
	end
	if not bConsole then return end

	if szCmd == "gg" then
		Core:Unload( true )
		RunConsoleCommand( "changelevel", game.GetMap() )
	elseif szCmd == "botsave" or szCmd == "savebot" then
		Bot:Save()
	elseif szCmd == "stop" then
		RunConsoleCommand( "exit" )
	elseif szCmd == "dodebug" then
		if CommandIncomplete then
			PrintTable( CommandIncomplete )
		end
	end
end

concommand.Add( "reset", Command.Restart )
concommand.Add( "spectate", Command.Spectate )
concommand.Add( "style", Command.Style )
concommand.Add( "nominate", Command.Nominate )
concommand.Add( "pnoclip", Command.NoClip )
concommand.Add( "cpload", Command.Checkpoint )
concommand.Add( "cpsave", Command.Checkpoint )

concommand.Add( "gg", Command.ServerCommand )
concommand.Add( "botsave", Command.ServerCommand )
concommand.Add( "stop", Command.ServerCommand )
concommand.Add( "dodebug", Command.ServerCommand )
