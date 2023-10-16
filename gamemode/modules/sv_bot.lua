-- Rewritten by Niflheimr, base code by Gravious --
-- Description: Make this bot code great! Yay! --
-- Documentation: Available (on new code) --

-- I am going this route because I want to convert the old structure easily without doing funky stuff --
include( "sv_json.lua" )

Bot = {}
Bot.RecordAll = true
Bot.AlwaysDisplayFirst = true
Bot.Maximum = Bot.RecordAll and 64 or 9
Bot.MinimumTime = 90

local BotPlayer = {}
local BotFrame = {}
local BotFrames = {}
local BotData = {}
local BotInfo = {}

local Players = {}
local Recording = {}

local Frame = {}
local StartedFrame = {}
local EndedFrame = {}
local RecordingFinished = {}

local ct = CurTime

-- Initialization and control
function Bot:Setup()
	BotPlayer = {}
	BotFrame = {}
	BotFrames = {}
	BotInfo = {}
	BotData = {}

	if not file.Exists( _C.GameType .. "/bots/revisions", "DATA" ) then
		file.CreateDir( _C.GameType .. "/bots/revisions" )
	end

	Bot.PerStyle = {}
	Bot:LoadData()
end

-- Our new functions! --
local function OldBotToNewStructure( style, tab )
	-- Do we even have a table? --
	if not tab then return end
	MsgC( Color( 0, 255, 255 ), "Found old bot structure, converting to the new structure, may take a few seconds...\n" )

	-- Get the frames from the table like the older structure did/setup a temporary table --
	local tabFrames = #tab[1]
	local newTab = {}

	-- Because grav's stupid index method, we have to look all frames to convert to the more efficient one --
	for i = 1, tabFrames do
		newTab[i] = { tab[1][i], tab[2][i], tab[3][i], tab[4][i], tab[5][i], tab[6][i] }
	end

	-- Re-set the bot data with the correct information --
	BotData[ style ] = newTab
	BotFrame[ style ] = 1
	BotFrames[ style ] = #BotData[ style ]
end

function Bot:StartRecording( ply )
	-- If we were recording our last run, we should end that recording first! --
	self:CheckEndFrames( ply )

	-- Recording/Frame reset --
	Recording[ ply ] = {}
	Frame[ ply ] = 1
end

function Bot:StopRecording( ply, nTime, nRecord )
	-- Validity checks, blah blah blah --
  if not IsValid( ply ) then return end
  if not nTime then return end
  if nRecord != 0 and nRecord < nTime then return end
  if #Recording[ ply ] == 0 then Core:Send( ply, "Print", { "Notification", "Failed to build run for your record, please contact the developers for this." } ) return end

	-- Declare this variable to decrease runtime --
  local tempStyle = ply.Style
  local botInfo = BotInfo[ tempStyle ] and BotInfo[ tempStyle ].Time

	-- No record? No run for you haha --
  if botInfo and botInfo < nTime then return end

	-- Set a pointer for this player so we can check the frames after --
  RecordingFinished[ ply ] = tempStyle
  EndedFrame[ ply ] = Frame[ ply ]

  BotInfo[ tempStyle ] = { Name = ply:Name(), Time = nTime, Style = ply.Style, SteamID = ply:SteamID(), Date = os.date( "%Y-%m-%d %H:%M:%S", os.time() ), Saved = false, Start = ct(), Frame = { StartedFrame[ ply ], EndedFrame[ ply ] } }

	timer.Simple(1, function()
		if ply:IsValid() then
			umsg.Start("DispatchChatWR")
				umsg.String(ply:GetName())
				umsg.String("2")
				umsg.String(ply:SteamID())
			umsg.End()
		end
	end)

  timer.Simple( 1.5, function()
    self:CheckEndFrames( ply )
  end )
end

function Bot:TrimRecording( ply )
	-- No frames, no thanks! --
	if not Frame[ ply ] then return end

	-- Get the frame the player starts the run, also save variable to prevent mismatched frames --
	local tempFrame = Frame[ ply ]
	StartedFrame[ ply ] = tempFrame

	-- Prevent trimming if we don't have enough frames --
	if tempFrame < 300 then return end

	-- Create a temporary recording to get the frames we need --
	local tempRecording = {}
	local tempCounter = 1

	-- Get 300 indices before the start frame --
	for i = tempFrame - 300, tempFrame do
		-- Grab this frame for cutting runtime --
		local Index = Recording[ ply ][ i ]

		-- No recording frame, skip! --
		if not Index then continue end

		-- Save to the temporary table, increment the counter --
		tempRecording[ tempCounter ] = Index
		tempCounter = tempCounter + 1
	end

	-- Rebuild the Recording session, then get our temporary table and merge it in --
	Recording[ ply ] = {}
	Recording[ ply ] = tempRecording

	-- We trimmed, 3 seconds have happened, 300 frames are set (100 f/s) --
	Frame[ ply ] = 300
	StartedFrame[ ply ] = 300
end

function Bot:CheckEndFrames( ply )
	-- Pointer to style --
	local tempStyle = RecordingFinished[ ply ]

	-- If this run isn't a record run, get it out of here --
	if not tempStyle then return end

	-- Set bot data --
	BotData[ tempStyle ] = Recording[ ply ]
	BotFrame[ tempStyle ] = 1
	BotFrames[ tempStyle ] = #BotData[ tempStyle ]
	self:SetMultiBot( tempStyle )

	-- cungatulasion!!!111, Recording/Frame/State reset --
	Recording[ ply ] = {}
	Frame[ ply ] = 0
	RecordingFinished[ ply ] = nil
end

function Bot:LoadData()
	print("lol")
	local Result = sql.Query( "SELECT * FROM game_bots WHERE szMap = '" .. game.GetMap() .. "' ORDER BY nStyle ASC" )
	if Core:Assert( Result, "nTime" ) then
		print("[BOT DEBUG] Yeah this is working...")
		for _,Info in pairs( Result ) do
			local name = _C.GameType .. "/bots/bot_" .. game.GetMap()
			local style = tonumber( Info["nStyle"] )

			if style != _C.Style.Normal then
				name = name .. "_" .. style .. ".txt"
			else
				name = name .. ".txt"
			end

			local RawData = file.Read( name, "DATA" )
			if not RawData or RawData == "" then continue end
			local RunData = util.Decompress( RawData )
			if not RunData then continue end

			-- Use the json library, haha this is gay --
			BotData[ style ] = util.JSONToTable( RunData )

			if #BotData[ style ] == 6 then
				OldBotToNewStructure( style, BotData[ style ] )
			else
				BotFrame[ style ] = 1
				BotFrames[ style ] = #BotData[ style ]
			end

			local tempFrame = { 0, BotFrames[ style ] }
			if Info["nFrame"] then
				local convFrame = util.JSONToTable( Info["nFrame"] )

				if convFrame then
					tempFrame = { convFrame[1], convFrame[2] }
				end
			end

			BotInfo[ style ] = { Name = Info["szPlayer"], Time = tonumber( Info["nTime"] ), Style = style, SteamID = Info["szSteam"], Date = Info["szDate"], Saved = true, Start = ct(), CompletedRun = true, Frame = tempFrame }
		end
	end
end

function Bot:ClearStyle( nStyle )
	BotFrame[ nStyle ] = nil
	BotFrames[ nStyle ] = nil
	BotData[ nStyle ] = nil
	BotInfo[ nStyle ] = nil
end

function Bot:SetMultiBot( nStyle )
	local target = nil
	for _,bot in pairs( player.GetBots() ) do
		if nStyle == _C.Style.Normal then
			if bot.Style == _C.Style.Normal and not bot.Temporary then
				target = bot
				break
			end
		else
			if bot.Style != _C.Style.Normal and not bot.Temporary then
				target = bot
				break
			end
		end
	end

	if IsValid( target ) then
		target.Style = nStyle
		Bot:SetInfo( target, nStyle, true )
		BotFrame[ nStyle ] = 1
		BotInfo[ nStyle ].CompletedRun = nil
		BotPlayer[ target ] = nStyle
		Bot:NotifyRestart( nStyle )
	end
end

function Bot:Spawn( bMulti, nStyle, bNone )
	if not bMulti then
		nStyle = _C.Style.Normal
	end

	for _,bot in pairs( player.GetBots() ) do
		if bot.Temporary then
			bot:SetMoveType( MOVETYPE_NONE )
			bot:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
			bot.Style = nStyle
			bot:StripWeapons()
			bot:SetFOV( 90, 0 )
			bot:SetGravity( 0 )
			bot.Temporary = nil
			Bot:SetInfo( bot, nStyle, true )

			return true
		end
	end

	if #player.GetBots() < 2 then
		Bot.Recent = nStyle
		if bMulti and bNone then
			Bot.Recent = nil
		end

		if BotInfo[ nStyle ] then
			if BotInfo[ nStyle ].Style > 3 and BotInfo[ nStyle ].Style < 40 then
				player.CreateNextBot( "Multi-Style Replay" )
			else
				player.CreateNextBot( "Normal Replay" )
			end
		elseif not bMulti then
			player.CreateNextBot( "Normal Replay" )
		else
			player.CreateNextBot( "Multi-Style Replay" )
		end

		timer.Simple( 1, function()
			Bot:Spawn( bMulti, nStyle )
		end )
	end
end

function Bot:CheckStatus()
	if Bot.IsStatusCheck then
		return true
	else
		Bot.IsStatusCheck = true
	end

	local nCount = 0
	local bNormal, bMulti

	for _,bot in pairs( player.GetBots() ) do
		if bot.Style == _C.Style.Normal then
			bNormal = true
		elseif bot.Style != _C.Style.Normal then
			bMulti = true
		end

		nCount = nCount + 1
	end

	if nCount < 2 then
		if not bNormal then
			Bot:Spawn()
		end

		if not bMulti then
			local nStyle, bSet = 0, true
			for style,_ in pairs( BotData ) do
				if style != _C.Style.Normal then
					nStyle = style
					bSet = nil
					break
				end
			end

			Bot.SpawnData = { nStyle, bSet }
			timer.Simple( not bNormal and 2 or 0, function()
				if Bot and Bot.Spawn and Bot.SpawnData then
					Bot:Spawn( true, Bot.SpawnData[ 1 ], Bot.SpawnData[ 2 ] )
				end
			end )
		end
	end

	timer.Simple( 5, function()
		Bot.IsStatusCheck = nil
	end )
end

function Bot:Save( bSave )

	if not bSave and #player.GetHumans() > 0 then
		timer.Simple( 1, function() Bot:Save( true ) end )
		return Core:Broadcast( "Print", { "Server", Lang:Get( "BotSaving" ) } )
	end

	for style,_ in pairs( BotData ) do
		local info = BotInfo[ style ]
		if not info.Saved then
			if not BotData[ style ] or not BotData[ style ][ 1 ] or #BotData[ style ][ 1 ] == 0 or BotFrames[ style ] == 0 then return end

			local Exist = sql.Query( "SELECT nTime FROM game_bots WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. info.Style )
			if Core:Assert( Exist, "nTime" ) and tonumber( Exist[ 1 ]["nTime"] ) then
				sql.Query( "UPDATE game_bots SET szPlayer = " .. sql.SQLStr( info.Name ) .. ", nTime = " .. info.Time .. ", szSteam = '" .. info.SteamID .. "', szDate = '" .. info.Date .. "', nFrame = '" .. util.TableToJSON( info.Frame ) .. "' WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. info.Style )
			else
				
				local e = sql.Query( "INSERT INTO game_bots VALUES ('" .. game.GetMap() .. "', " .. sql.SQLStr( info.Name ) .. ", " .. info.Time .. ", " .. info.Style .. ", '" .. info.SteamID .. "', '" .. info.Date .. "', '" .. util.TableToJSON( info.Frame ) .. "')" )
				if (e == false) then 
					print(sql.LastError())
				end
			end

			local name = _C.GameType .. "/bots/bot_" .. game.GetMap()
			if style != _C.Style.Normal then
				name = name .. "_" .. style
			end

			if file.Exists( name .. ".txt", "DATA" ) then
				local find = 1
				local fp = string.gsub( name, "bots/", "bots/revisions/" ) .. "_v"

				while file.Exists( fp .. find .. ".txt", "DATA" ) do
					find = find + 1
				end

				local existing = file.Read( name .. ".txt", "DATA" )
				file.Write( fp .. find .. ".txt", util.TableToJSON( info ) .. "\n" )
				file.Append( fp .. find .. ".txt", existing )
			end

			local RunData = util.Compress( util.TableToJSON( BotData[ style ] ) )
			file.Write( name .. ".txt", RunData )

			BotInfo[ style ].Saved = true
		end
	end
end


-- Dynamic player system
function Bot:CountPlayers()
	local count = 0

	for d,b in pairs( Players ) do
		if b and IsValid( d ) and d:IsPlayer() then
			count = count + 1
		else
			Players[ d ] = nil
		end
	end

	return count
end

function Bot:ShowStatus( ply )
	Core:Send( ply, "Print", { "Notification", Lang:Get( "BotStatus", { Bot:IsRecorded( ply ) and "being" or "not being" } ) } )
end

function Bot:GetMultiStyle()
	for _,bot in pairs( player.GetAll() ) do
		if bot:IsBot() and bot.Style != _C.Style.Normal then
			return bot.Style
		end
	end

	return 0
end

function Bot:ChangeMultiBot( nStyle )
	local current = Bot:GetMultiStyle()
	if not Core:IsValidStyle( current ) then return "None" end
	if not Core:IsValidStyle( nStyle ) then return "Invalid" end
	if nStyle == _C.Style.Normal then return "Exclude" end
	if current == nStyle then return "Same" end

	if BotInfo[ nStyle ] and BotData[ nStyle ] then
		if BotInfo[ current ].CompletedRun then
			local ply = Bot:GetPlayer( current )
			ply.Style = nStyle
			Bot:SetInfo( ply, nStyle, true )
			BotFrame[ nStyle ] = 1
			BotInfo[ nStyle ].CompletedRun = nil
			BotPlayer[ ply ] = nStyle
			Bot:NotifyRestart( nStyle )

			return "The bot is now displaying " .. BotInfo[ nStyle ].Name .. "'s " .. Core:StyleName( BotInfo[ nStyle ].Style ) .. " run!"
		else
			return "Wait"
		end
	else
		return "Error"
	end
end

function Bot:GetMultiBots()
	local tabStyles = {}
	for style,data in pairs( BotData ) do
		if style != _C.Style.Normal then
			table.insert( tabStyles, Core:StyleName( style ) )
		end
	end
	return tabStyles
end

function Bot:SaveBot( ply )
	local bSave = false

	for style,data in pairs( BotInfo ) do
		if data.SteamID == ply:SteamID() then
			if not data.Saved then
				bSave = true
				Bot:Save()

				break
			end
		end
	end

	Core:Send( ply, "Print", { "General", bSave and "Your bot will now be saved!" or "All your bots have already been saved or you have no bots." } )
end


-- Access functions

function Bot:Exists( nStyle )
	return BotFrame[ nStyle ] and BotFrames[ nStyle ] and BotInfo[ nStyle ].Start
end

function Bot:NotifyRestart( nStyle )
	local ply = Bot:GetPlayer( nStyle )
	local info = BotInfo[ nStyle ]
	local bEmpty = false

	if IsValid( ply ) and not info then
		bEmpty = true
	elseif not info or not info.Start or not IsValid( ply ) then
		return false
	end

	local tab, Watchers = { "Timer", true, nil, "Waiting bot", nil, ct(), "Save" }, {}
	for _,p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob:IsBot() and ob == ply then
			table.insert( Watchers, p )
		end
	end

	if not bEmpty then
		tab = { "Timer", true, info.Start, info.Name, info.Time, ct(), "Save" }
	end

	Core:Send( Watchers, "Spectate", tab )

end

function Bot:GenerateNotify( nStyle, varList )
	if not BotInfo[ nStyle ] or not BotInfo[ nStyle ].Start then return end
	return { "Timer", true, BotInfo[ nStyle ].Start, BotInfo[ nStyle ].Name, BotInfo[ nStyle ].Time, ct(), varList }
end

function Bot:GetPlayer( nStyle )
	for _,ply in pairs( player.GetBots() ) do
		if ply.Style == nStyle and IsValid( ply ) then
			return ply
		end
	end
end

function Bot:SIDToProfile( sid )
	return util.SteamIDTo64( sid )
end

function Bot:GetInfo( nStyle )
	return BotInfo[ nStyle ]
end

function Bot:SetInfoData( nStyle, varData )
	BotInfo[ nStyle ] = varData
end

function Bot:SetInfo( ply, nStyle, bSet )
	local info = BotInfo[ nStyle ]
	if not info then
		ply:SetNWString( "BotName", "Bot (No Time)" )
		ply:SetNWInt( "Style", 0 )
		return false
	elseif info.Style then
		Bot:SetFramePosition( info.Style, 1 )
	end

	if info.Start then
		ply:SetNWString( "BotName", info.Name )
		ply:SetNWString( "ProfileURI", Bot:SIDToProfile( info.SteamID ) )
		ply:SetNWFloat( "Record", info.Time )
		ply:SetNWInt( "Style", info.Style )
		ply:SetNWInt( "Rank", -2 )

		local pos = Timer:GetRecordID( info.Time, info.Style )
		if pos > 0 then
			ply:SetNWInt( "WRPos", pos )
		else
			ply:SetNWInt( "WRPos", 0 )
		end

		Bot.PerStyle[ info.Style ] = pos
	end

	if bSet then
		BotInfo[ nStyle ].Start = ct()
		Bot.Initialized = true
		BotPlayer[ ply ] = nStyle
	end
end

function Bot:SetWRPosition( nStyle )
	local ply = Bot:GetPlayer( nStyle )
	if not IsValid( ply ) then return end

	local info = BotInfo[ nStyle ]
	if not info then
		ply:SetNWString( "BotName", "Bot (No Time)" )
		ply:SetNWInt( "Style", 0 )
		return false
	end

	if info.Start then
		local pos = Timer:GetRecordID( info.Time, info.Style )
		if pos > 0 then
			ply:SetNWInt( "WRPos", pos )
		else
			ply:SetNWInt( "WRPos", 0 )
		end

		Bot.PerStyle[ info.Style ] = pos
	end
end

function Bot:SetFramePosition( nStyle, nFrame )
	if IsValid( Bot:GetPlayer( nStyle ) ) and BotFrame[ nStyle ] then
		Bot:NotifyRestart( nStyle )

		if nFrame < BotFrames[ nStyle ] then
			BotFrame[ nStyle ] = nFrame
		end
	end
end

function Bot:GetFramePosition( nStyle )
	if IsValid( Bot:GetPlayer( nStyle ) ) and BotFrame[ nStyle ] and BotFrames[ nStyle ] then
		return { BotFrame[ nStyle ], BotFrames[ nStyle ] }
	end

	return { 0, 0 }
end

-- Edited justa
function Bot:StripFromFrame(ply, frame)
	Frame[ply] = frame 

	for i = frame, #Recording[ply] do
		Recording[ply][i] = nil 
	end
end

function Bot:GetFrame(ply)
	return Frame[ply] or 0
end

-- Main control
local function BotRecord( ply, data, keys )
	if not ply:IsBot() and ply:Team() != TEAM_SPECTATOR then
		local origin = data:GetOrigin()
		local eyes = data:GetAngles()
		local button = keys:GetButtons()
		local tempFrame = Frame[ ply ]

		if not tempFrame or tempFrame == 0 then return end

		-- TODO: justa
		Recording[ ply ][ tempFrame ] = { origin.x, origin.y, origin.z, eyes.p, eyes.y, button }
		Frame[ ply ] = tempFrame + 1

	elseif BotPlayer[ ply ] then
		keys:ClearButtons()
		keys:ClearMovement()

		local style = BotPlayer[ ply ]
		local frame = BotFrame[ style ]
		local recording = (BotData and BotData[style] and BotData[style][frame]) and BotData[ style ][ frame ] or false 
		if not recording then return end

		if frame >= BotFrames[ style ] then
			if not BotInfo[ style ].BotCooldown then
				BotInfo[ style ].BotCooldown = ct()
				BotInfo[ style ].Start = ct() + 4

				if BotInfo[ style ].Frame[1] != 0 then
					BotInfo[ style ].Start = ct() + 4 + ( BotInfo[ style ].Frame[1] / 100 )
				end

				Bot:NotifyRestart( style )
			end

			local nDifference = ct() - BotInfo[ style ].BotCooldown
			if BotInfo[ style ].Frame[1] != 0 then
				if nDifference >= 4 then
					BotFrame[ style ] = 1
					BotInfo[ style ].BotCooldown = nil
					BotInfo[ style ].CompletedRun = true
				elseif nDifference >= 2 then
					frame = 1
				elseif nDifference >= 0 then
					frame = BotFrames[ style ]
				end
			else
				if nDifference >= 4 then
					BotFrame[ style ] = 1
					BotInfo[ style ].Start = ct()
					BotInfo[ style ].BotCooldown = nil
					BotInfo[ style ].CompletedRun = true
				elseif nDifference >= 2 then
					frame = 1
				elseif nDifference >= 0 then
					frame = BotFrames[ style ]
				end
			end

			local d = BotData[ style ]
			data:SetOrigin( Vector( d[ frame ][ 1 ], d[ frame ][ 2 ], d[ frame ][ 3 ] ) )
	    ply:SetEyeAngles( Angle( d[ frame ][ 4 ], d[ frame ][ 5 ], 0 ) )

			if d[ frame ][ 6 ] and ply:GetMoveType() == 0 then
				keys:SetButtons( d[ frame ][ 6 ] )
			end
		return end

		if BotInfo[ style ].Frame[1] != 0 then
			if frame == BotInfo[ style ].Frame[1] then
        BotInfo[ style ].Start = ct()
        Bot:NotifyRestart( style )
      end
		end

		local d = BotData[ style ]
		data:SetOrigin( Vector( d[ frame ][ 1 ], d[ frame ][ 2 ], d[ frame ][ 3 ] ) )
		ply:SetEyeAngles( Angle( d[ frame ][ 4 ], d[ frame ][ 5 ], 0 ) )

		if d[ frame ][ 6 ] and ply:GetMoveType() == 0 then
			data:SetButtons( d[ frame ][ 6 ] )
		end

		BotFrame[ style ] = frame + 1
	end
end
hook.Add( "SetupMove", "PositionRecord", BotRecord )

timer.Create( "BotController", .1, 0, function()
	for ply,_ in pairs( BotPlayer ) do
		if IsValid( ply ) then
			if ply:GetMoveType() != 0 then ply:SetMoveType( 0 ) end
			if ply:GetCollisionGroup() != 1 then ply:SetCollisionGroup( 1 ) end
			if ply:GetFOV() != 90 then ply:SetFOV( 90, 0 ) end
		end
	end

	if #player.GetBots() == 0 and #player.GetHumans() > 0 then
		Bot.EmptyTick = (Bot.EmptyTick or 0) + 1

		if Bot.EmptyTick > 5 then
			Bot.EmptyTick = nil
			Bot:CheckStatus()
		end
	end
end )
