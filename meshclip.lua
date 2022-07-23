MESHCLIP = MESHCLIP or {}
include("meeclip.lua")


local function mesh_preproc(tris)

	local parent = MESHCLIP.parent
	local share_cache = {}

	local maxs = Vector(0,0,0)
	local mins = Vector(0,0,0)
	
	for k, v in ipairs(tris) do
		local pos = v.pos
		for n=1, 3 do
			maxs[n] = math.max(maxs[n],pos[n])
			mins[n] = math.min(mins[n],pos[n])
		end
	end

	maxs = maxs*1.01
	mins = mins*1.01

	local box = maxs-mins

	local longest = math.max(box[1],box[2],box[3])
	if(longest == box[1]) then longest = 1 
	elseif(longest == box[2]) then longest = 2
	else longest = 3 end

	local axis = Vector(0,0,0)
	axis[longest] = 1

	print( axis )
	print(maxs, mins)

	local slices = {}

	local COUNT = 4
	local STEP  = 1/COUNT

	local tris_all = {}
	local caching = {}

	for i=0, COUNT do
		local t = i/COUNT

		local tris_right = meeMeshSplit(tris, mins + axis*box[longest]*(t), axis, share_cache, i) 
		tris_right = meeMeshSplit(tris_right, mins + axis*box[longest]*(t+STEP), -axis, share_cache, i) 

		slices[i] = tris_right
		for k, v in ipairs(tris_right) do
			if not caching[v.pos] then
				v.pos = v.pos + Vector(0,0,v.slice * 10)
				caching[v.pos] = true
			end
		end
			
		table.Add(tris_all,tris_right)
	end

	PrintTable(tris_all)

	return tris_all

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
			vismesh.triangles = mesh_preproc(vismesh.triangles)
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
				 	--render.SetMaterial( materials[k] )
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

MESHCLIP.spawn("models/hunter/blocks/cube1x1x1.mdl")

hook.Remove( "KeyPress", "MeshClip.Use" )