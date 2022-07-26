AddCSLuaFile()

properties.Add( "Bezier.Create", {
	MenuLabel = "Add Bezier Curves",
	Order = 1,
	MenuIcon = "icon16/chart_line.png",

	Filter = function( self, ent, ply )

		if ( !IsValid( ent ) ) then return false end
		if ( !gamemode.Call( "CanProperty", ply, "remover", ent ) ) then return false end
        if( ent.IsBezier ) then return false end
		if ( ent:IsPlayer() ) then return false end

		return true

	end,

	Action = function( self, ent )

		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()

	end,

	Receive = function( self, length, ply )

		if ( !IsValid( ply ) ) then return end -- wtf?
		local ent = net.ReadEntity()
		if ( !self:Filter( ent, ply ) ) then return end

		local prop = ents.Create("prop_bezier")
            prop:SetModel( ent:GetModel() )
            prop:SetPos( ent:GetPos() )
            prop:SetAngles( ent:GetAngles() )
            prop:SetColor( ent:GetColor() )
			prop:Activate()
            -- TODO: materials (which will be evil)
        prop:Spawn()

		if CPPI then prop:CPPISetOwner( ent:CPPIGetOwner() ) end

		undo.Create("Bezier Prop")
			undo.AddEntity(prop)
			undo.SetPlayer(ply)
		undo.Finish()
        
        ent:Remove()

	end

} )