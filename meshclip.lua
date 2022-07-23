MESHCLIP = MESHCLIP or {}
include("meeclip.lua")

local function mesh_preproc(tris)

	if not (MESHCLIP.plane) then return tris end	
	
	local tris_out = {}
	local tris_grouped = { {} }

	local parent = MESHCLIP.parent
	local plane = MESHCLIP.plane

	--first we need to find where the plane is in prop local space
	local origin, ang = WorldToLocal( plane:GetPos(), plane:GetAngles(), parent:GetPos(), parent:GetAngles() )

	-- now we precompute some values
	local plane_up = ang:Right()

	meeMeshSplit(tris, origin, plane_up, tris_out, tris_grouped)
	-- PrintTable(tris_out)

	return tris_out

end

local function MeshClip()

	local MeshClip = ents.CreateClientside("starfall_hologram")
	MESHCLIP.testmesh = MeshClip

	function MeshClip:Finalize()
		self:Activate()
		self:BuildMeshes()
	end

	function MeshClip:UseModel(path)
		self.Model = path
		self:SetModel(path)
		self:ManipulateBoneScale( 0, Vector(0,0,0) ) -- so we can fix the stupid lighting bug
	end

	function MeshClip:BuildMeshes()

		for k, submesh in ipairs(self.Meshes or {}) do
			submesh:Destroy()
		end 

		self.Meshes = {}
		self.Materials = {}
		self.DebugMeshes = {}

		local vismeshes = util.GetModelMeshes( self.Model )
		local clipped_vismeshes = {}
		if ( !vismeshes ) then return end

		for k, vismesh in ipairs(vismeshes) do
			local set1, set2, set3
			vismesh.triangles, set1, set2, set3 = mesh_preproc(vismesh.triangles)
			if( #vismesh.triangles > 0 ) then

				self.Meshes[#self.Meshes+1] = Mesh( self.Materials[k] )  -- USERDATAS ARE STUPID!!!
				self.Materials[#self.Materials+1] = Material(vismesh.material)
				self.Meshes[#self.Meshes]:BuildFromTriangles( vismesh.triangles )

			end
		end

	end

	local wire = Material("models/wireframe")

	function MeshClip:Draw()

		self:DrawModel() -- lighting bug fix
		local parent = MESHCLIP.parent

		if ( self.Meshes ) then
			local meshes = self.Meshes
			local materials = self.Materials

			local transform = Matrix()
			transform:Translate( parent:GetPos() )
			transform:Rotate( parent:GetAngles() )
			render.SetMaterial(wire)
			cam.PushModelMatrix( transform )
				for k, submesh in ipairs(meshes) do
				 	render.SetMaterial( materials[k] )
				 	submesh:Draw()
				end
			cam.PopModelMatrix()
		end

	end

	return MeshClip

end



//

local testmesh

---- Testing Stuff ----
function MESHCLIP.spawn(mdl)

	if MESHCLIP.testmesh and IsValid(MESHCLIP.testmesh) then
		chat.AddText("Removing old meshes")
		MESHCLIP.testmesh:Remove()
	end

	testmesh = MeshClip()
	MESHCLIP.testmesh = testmesh
	testmesh:SetPos( MESHCLIP.parent:GetPos() )
	testmesh:SetParent( MESHCLIP.parent )
	testmesh:UseModel(mdl)
	testmesh:Finalize()

end

function MESHCLIP.setParent()
	MESHCLIP.parent = LocalPlayer():GetEyeTrace().Entity
end

function MESHCLIP.setPlane()
	MESHCLIP.plane = LocalPlayer():GetEyeTrace().Entity
end

function MESHCLIP.rebuild()
	testmesh:BuildMeshes()
end

function MESHCLIP.unfuckmatricies()
	for i=1, 8192 do
		cam.PopModelMatrix()
	end
end

MESHCLIP.spawn("models/props_vehicles/truck001a.mdl")

hook.Remove( "KeyPress", "MeshClip.Use" )