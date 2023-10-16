SQL = {}
SQL.Use = true -- Set this to false if you don't want MySQL, if you want MySQL (for multiple servers, or better management / performance), set it to true

if SQL.Use then
	-- Make sure you have libmysql in your root directory as well as the mysqloo module in your lua/bin folder
	require( "mysqloo" )
end


Core = Core or {}
Core.Protocol = "SecureTransfer"
Core.Protocol2 = "BinaryTransfer"

Core.Locked = false
Core.Try = 0

util.AddNetworkString( Core.Protocol )
util.AddNetworkString( Core.Protocol2 )


function Core:Boot()
	Command:Init()
	RTV:Init()

	Core:LoadZones()
	Timer:LoadRecords()
	Player:LoadRanks()
	Player:LoadTop()

	Timer:AddPlays()
end

function Core:Unload( bForce )
	Bot:Save( bForce )
end


function Core:LoadZones()
	local zones = sql.Query( "SELECT nType, vPos1, vPos2 FROM game_zones WHERE szMap = '" .. game.GetMap() .. "'" )
	if not zones then return end

	Zones.Cache = {}
	for _,data in pairs( zones ) do
		table.insert( Zones.Cache, {
			Type = tonumber( data[ "nType" ] ),
			P1 = util.StringToType( tostring( data[ "vPos1" ] ), "Vector" ),
			P2 = util.StringToType( tostring( data[ "vPos2" ] ), "Vector" )
		} )
	end
end


function Core:AwaitLoad( bRetry )
	if not bRetry then
		Zones:SetupMap()
		Bot:Setup()
		Radio:Setup()
		Core:Optimize()

		if SQL.Use then
			if timer.Exists( "SQLCheck" ) then
				timer.Destroy( "SQLCheck" )
			end

			timer.Simple( 0, function() Core:StartSQL() end )
			timer.Create( "SQLCheck", 10, 0, Core.SQLCheck )
		else
			SQL:LoadNoMySQL()
		end
	end

	if #Zones.Cache > 0 then
		Zones:Setup()
		Core.Try = 0
	else
		if Core.Try < 100 then
			Core.Try = Core.Try + 1
			Core:LoadZones()

			if #Zones.Cache == 0 then
				print( "Couldn't load data. Retrying (Try " .. Core.Try .. ")" )
			end

			timer.Simple( 5, function() Core:AwaitLoad( true ) end )
		else
			Core:Lock( "Server failed to load zone data from the database (No zones set in time!)" )
		end
	end
end

function Core:StartSQL()
	if not SQL.Use then return end

	local function OnComplete()
		Admin:LoadAdmins()
		Admin:LoadNotifications()

		Core.SQLChecking = nil
	end

	SQL:CreateObject( OnComplete )
	timer.Simple( 5, function()
		Core.SQLChecking = nil
	end )
end

function Core.SQLCheck()
	if not SQL.Use then return end

	if (not Admin.Loaded or SQL.Error) and not Core.SQLChecking then
		SQL.Error = nil
		Core.SQLChecking = true
		Core:StartSQL()
	end
end

local FirstLock
function Core:Lock( szMessage )
	if not FirstLock then
		FirstLock = szMessage
	end

	Core.Locked = true

	for k,v in pairs( player.GetAll() ) do
		v:Kick( Lang:Get( "AdminDataFailure", { FirstLock } ) )
	end

	for i = 1, 3 do
		print( "[LOCKING MECHANISM]", "Your server has been locked for this reason:", FirstLock )
	end

	print( "[LOCKING MECHANISM]", "Player has been locked out:", szMessage )
end

function Core:Assert( varType, szType )
	if varType and type( varType ) == "table" and varType[ 1 ] and type( varType[ 1 ] ) == "table" and varType[ 1 ][ szType ] then
		return true
	end

	return false
end

function Core:Null( varInput, varAlternate )
	if varInput and type( varInput ) == "string" and varInput != "NULL" then
		return varInput
	end

	return varAlternate or nil
end

function Core:Print( szPrefix, szText )
	print( "[" .. (szPrefix or "Core") .. "]", szText )
end


function Core:AddResources()
	resource.AddFile( "materials/" .. _C.MaterialID .. "/timer.png" )

	for i = 1, 10 do
		resource.AddFile( "materials/" .. _C.MaterialID .. "/icon_rank" .. i .. ".png" )
	end

	for i = 1, 3 do
		resource.AddFile( "materials/" .. _C.MaterialID .. "/icon_special" .. i .. ".png" )
	end
end

function Core:Send( ply, szAction, varArgs )
	net.Start( Core.Protocol )
	net.WriteString( szAction )

	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end

	net.Send( ply )
end

function Core:Broadcast( szAction, varArgs, varExclude )
	net.Start( Core.Protocol )
	net.WriteString( szAction )

	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end

	if varExclude and (type( varExlude ) == "table" or (IsValid( varExclude ) and varExclude:IsPlayer())) then
		net.SendOmit( varExclude )
	else
		net.Broadcast()
	end
end


local function CoreHandle( ply, szAction, varArgs )
	if szAction == "Admin" then
		Admin:HandleClient( ply, varArgs )
	elseif szAction == "Speed" then
		Timer:AddSpeedData( ply, varArgs )
	elseif szAction == "WRList" then
		Timer:SendWRList( ply, varArgs[ 1 ], varArgs[ 2 ], varArgs[ 3 ] )
	elseif szAction == "MapList" then
		RTV:GetMapList( ply, varArgs[ 1 ] )
	elseif szAction == "Vote" then
		RTV:ReceiveVote( ply, varArgs[ 1 ], varArgs[ 2 ] )
	elseif szAction == "TopList" then
		Player:SendTopList( ply, varArgs[ 1 ], varArgs[ 2 ] )
	elseif szAction == "Checkpoints" then
		Timer:CPHandleCallback( ply, varArgs[ 1 ], varArgs[ 2 ], varArgs[ 3 ] )
	elseif szAction == "Radio" then
		Radio:HandleClient( ply, varArgs )
	elseif szAction == 'abc' then
		JAC:RegisterDetection(ply, 'no_startcommand')
	end
end

local function CoreReceive( _, ply )
	local szAction = net.ReadString()
	local bTable = net.ReadBit() == 1
	local varArgs = {}

	if bTable then
		varArgs = net.ReadTable()
	end

	if IsValid( ply ) and ply:IsPlayer() then
		CoreHandle( ply, szAction, varArgs )
	end
end
net.Receive( Core.Protocol, CoreReceive )

local function BinaryReceive( l, ply )
	local length = net.ReadUInt( 32 )
	local data = net.ReadData( length )

	if IsValid( ply ) then
		local target = Admin.Screenshot[ ply ]
		if IsValid( target ) then
			net.Start( Core.Protocol2 )
			net.WriteString( "Data" )
			net.WriteUInt( length, 32 )
			net.WriteData( data, length )
			net.Send( target )

			Admin.Screenshot[ ply ] = nil
		end
	end
end
net.Receive( Core.Protocol2, BinaryReceive )


--- SQL ---
-- ignore this and go down to line 508
SQL.Available = true

local SQLObject
local SQLDetails = {
	Host = "kawaii.site.nfoservers.com", Port = 3306 ,
	User = "kawaii", Pass = "9Mv8K2kmDn", -- This is default for a lot of servers, but you'll probably have to change this
	Database = "kawaii_flow"
}

local function SQL_Print( szMsg, varArg )
	print( szMsg, varArg or "" )
end

local function SQL_ConnectSuccess( fCallback )
	SQL.Available = true
	SQL.Busy = false

	SQL_Print( "[SQL Connect] Connected to " .. string.upper( SQLDetails.Host ) .. " successfully (User: " .. string.upper( SQLDetails.User ) .. ")" )

	fCallback()
end

local function SQL_ConnectFailure( obj, szError )
	SQL.Available = false
	SQL.Busy = false

	SQL_Print( "[SQL Connect] Failed to connect: ", szError )
end

local function SQL_Query( szQuery, fCallback, varArgs )
	if not SQLObject or not SQL.Available then
		return SQL_Print( "No valid SQLObject to execute query: ", szQuery )
	elseif not szQuery or szQuery == "" then
		return SQL_Print( "No valid SQLQuery to execute" )
	end

	local query = SQLObject:query( szQuery )
	local function fSuccess( obj, varData )
		if fCallback then
			fCallback( varData, varArgs )
		end
	end

	local function fError( obj, szError, szSQL )
		if fCallback then
			fCallback( nil, nil, szError or "" )
		end

		SQL_Print( "[SQL Error] " .. szError, "(On query: " .. szSQL .. ")" )

		if string.find( string.lower( szError ), "lost connection", 1, true ) or string.find( string.lower( szError ), "gone away", 1, true ) then
			SQL.Error = true
			return false
		end
	end

	query.onSuccess = fSuccess
	query.onError = fError
	query:start()
end

local function SQL_Execute( szQuery, fCallback, varArg )
	SQL_Query( szQuery, function( varData, varArgs, szError )
		fCallback( varData, varArgs, szError )
	end, varArg )
end

function SQL:CreateObject( SQL_ConnectCallback )
	local function SQL_SelectCallback()
		SQL_ConnectSuccess( SQL_ConnectCallback )
	end

	SQL.Busy = true

	SQLObject = mysqloo.connect( SQLDetails.Host, SQLDetails.User, SQLDetails.Pass, SQLDetails.Database, SQLDetails.Port )
	SQLObject.onConnected = SQL_SelectCallback
	SQLObject.onConnectionFailed = SQL_ConnectFailure
	SQLObject:connect()
end

function SQL:Prepare( szQuery, varArgs, bNoQuote )
	if not SQL.Use then
		return SQL:LocalPrepare( szQuery, varArgs, bNoQuote )
	end

	if not SQLObject or not SQL.Available then
		SQL_Print( "No valid SQLObject to prepare query: " .. szQuery )
		return { Execute = function() end }
	end

	if varArgs and #varArgs > 0 then
		for i = 1, #varArgs do
			local sort = type( varArgs[ i ] )
			local num = tonumber( varArgs[ i ] )
			local arg = ""

			if sort == "string" and not num then
				arg = SQLObject:escape( varArgs[ i ] )
				if not bNoQuote then
					arg = "'" .. arg .. "'"
				end
			elseif (sort == "string" and num) or (sort == "number") then
				arg = varArgs[ i ]
			else
				arg = tostring( varArgs[ i ] ) or ""
				SQL_Print( "Parameter of type " .. sort .. " was parsed to a default value on query: " .. szQuery )
			end

			szQuery = string.gsub( szQuery, "{" .. i - 1 .. "}", arg )
		end
	end

	return { Query = szQuery, Execute = function( self, fCallback, varArg ) SQL_Execute( self.Query, fCallback, varArg ) end }
end


-- No MySQL Custom Part

function SQL:LoadNoMySQL()
	SQL.Use = true

	if not sql.TableExists( "gmod_admins" ) or not sql.TableExists( "gmod_bans" ) then
		Core:Lock( "Missing SQLite tables (gmod_admins and gmod_bans) on No MySQL setup! (Use the correct sv.db or SQL queries)" )

		for i = 0, 3 do
			print( "[LOCKING ERROR]", "You aren't using the right SQLite tables. Be sure to use the correct files from the /Database folder in the release! Or use the preset sv.db" )
		end

		return false
	end

	SQL.LoadedSQLite = true
	SQL.Available = true
	SQL.Busy = false

	SQL_Print( "[SQL Connect] Connected to local SQLite server successfully" )

	local OperatorID = "STEAM_0:1:123285371" -- If you want to start adding admins and don't know how to edit the 'sv.db' manually, enter your Steam ID here! It'll force you to admin.
	Admin:LoadAdmins( OperatorID )
	Admin:LoadNotifications()
end

function SQL:LocalPrepare( szQuery, varArgs, bNoQuote )
	if not SQL.LoadedSQLite then
		SQL_Print( "No valid SQLite tables to prepare query: " .. szQuery )
		return { Execute = function() end }
	end

	if varArgs and #varArgs > 0 then
		for i = 1, #varArgs do
			local sort = type( varArgs[ i ] )
			local num = tonumber( varArgs[ i ] )
			local arg = ""

			if sort == "string" and not num then
				arg = sql.SQLStr( varArgs[ i ] )
				if bNoQuote then
					arg = string.sub( arg, 2, string.len( arg ) - 1 )
				end
			elseif (sort == "string" and num) or (sort == "number") then
				arg = varArgs[ i ]
			else
				arg = tostring( varArgs[ i ] ) or ""
				SQL_Print( "Parameter of type " .. sort .. " was parsed to a default value on query: " .. szQuery )
			end

			szQuery = string.gsub( szQuery, "{" .. i - 1 .. "}", arg )
		end
	end

	local varData, szError
	local data = sql.Query( szQuery )

	if data then
		-- This is required because I don't want to update all SQL:Prepare statements to check for SQLite.
		-- Screw you Garry! Why haven't you added type parsing to the default SQLite library... :(

		for id,item in pairs( data ) do
			for key,value in pairs( item ) do
				if tonumber( value ) then
					data[ id ][ key ] = tonumber( value )
				end
			end
		end

		varData = data
	else
		local statement = string.sub( szQuery, 1, 6 )
		if statement == "SELECT" then
			szError = sql.LastError() or "Unknown error"
		else
			varData = true
		end
	end

	return { Query = szQuery, Execute = function( self, fCallback, varArg ) fCallback( varData, varArg, szError ) end }
end

-- Edited: justa
-- UI networking
util.AddNetworkString('userinterface.network')

UI = {}
function UI:SendToClient(client, uiId, ...)
	-- What we need to send
	local net_contents = {...}

	-- Send it
	net.Start("userinterface.network")
	net.WriteString(uiId)
	net.WriteTable(net_contents)

	-- Target
	if (not client) then
		net.Broadcast()
	else
		net.Send(client)
	end
end

-- This is dumb I have it twice I know, I gotta redo all the networking stuff in this file because it's really messy
-- Eventually it'll just be Core:Send(client, id, contents) and Core:Receive(client, id, contents) with some compression options
-- ty o/
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

--[[Add MySQL information here and ignore the one above]] --
MySQL = MySQL or {}

require("mysqloo")

local database = {
	ip = "localhost",
	port = 3306,
	username = "root",
	password = "",
	schema = "kawaii_flow"
}

MySQL.queries = {}

function MySQL:Notify(p, m)
	MsgC(Color(10, 65, 157), "[", p, "] ", color_white, m, "\n")
end

local db = db or false

function Connect()
	if (db) then return end

	db = mysqloo.connect(database.ip, database.username, database.password, database.schema, database.port)

	-- We connected successfully
	function db:onConnected()
		MySQL:Notify("MySQL", "Connected successfully to database.")

		-- Enable queries
		db.successful = true

		-- Run StartUp Queries
		MySQL:StartUp()

		-- Anymore?
		for k, v in pairs(MySQL.queries) do
			MySQL:Start(v[1], v[2])
		end
	end

	-- We didn't connect successfully
	function db:onConnectionFailed(err)
		MySQL:Notify("MySQL", "Failed to connect to database. ("..err..")")
		MySQL:Notify("MySQL", "Retrying in 10 seconds...")
		timer.Simple(10, Connect)
	end

	db:connect()
end

-- Startup Queries
function MySQL:StartUp()
end

function MySQL:Start(query, callback)
	-- Hold up there buddy
	if (not db.successful) then
		self:Notify("MySQL", "Tried to run query ("..query..") without successful connection, storing...")
		table.insert(self.queries, {query, callback})
		return
	end

	-- Try it
	local q = db:query(query)

	-- Successful!
	function q:onSuccess(data)
		if (callback) then
			callback(data)
		end
	end

	-- Awh
	function q:onError(err)
		MySQL:Notify("MySQL", "Query ("..query..") encounted error: "..err)
	end

	-- Do et
	q:start()
end

function MySQL:Escape(str)
	return sql.SQLStr(str)
end

Connect()
