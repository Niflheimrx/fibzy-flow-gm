-- shit lag
__HOOK[ "InitPostEntity" ] = function()

	for _,ent in pairs( ents.FindByClass( "env_fire" ) ) do
		ent:Remove()
	end
end