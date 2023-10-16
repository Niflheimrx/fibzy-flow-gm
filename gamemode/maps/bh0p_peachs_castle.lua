-- peachs no doors

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "func_door" ) ) do
		ent:Remove()
	end
	for _,ent in pairs( ents.FindByClass( "func_door_rotating" ) ) do
		ent:Remove()
	end
end
