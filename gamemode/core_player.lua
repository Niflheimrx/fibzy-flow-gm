DEFINE_BASECLASS("player_default")

local PLAYER = {}
PLAYER.DisplayName				= "Player"
PLAYER.WalkSpeed 				= 250
PLAYER.RunSpeed				= 250
PLAYER.CrouchedWalkSpeed 	= 0.6
PLAYER.DuckSpeed				= 0.4
PLAYER.UnDuckSpeed			= 0.2
PLAYER.JumpPower				= _C["Player"].JumpPower
PLAYER.AvoidPlayers				= false
PLAYER.Model = "models/player/group01/male_01.mdl"
PLAYER.BotModel = "models/player/kleiner.mdl"

function PLAYER:Loadout()
	self.Player:StripWeapons()
	
	if self.Player.ReceiveWeapons then
		self.Player:Give( "weapon_glock" )
		self.Player:Give( "weapon_usp" )
		self.Player:Give( "weapon_knife" )
		
		self.Player:SetAmmo( 999, "pistol" ) 
		self.Player:SetAmmo( 999, "smg1" )
		self.Player:SetAmmo( 999, "buckshot" )
	end
end

function PLAYER:SetModel()
	self.Player:SetModel(self.Player:IsBot() and PLAYER.BotModel or PLAYER.Model)
end

player_manager.RegisterClass( "player_bhop", PLAYER, "player_default" )