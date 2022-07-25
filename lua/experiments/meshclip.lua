MESHCLIP = MESHCLIP or {}

include("vertexlinker.lua")
include("meeclip.lua")
include("fastslice.lua")

local function getBB(tris)
	local maxs = Vector(0,0,0)
	local mins = Vector(0,0,0)
	
	for k, v in ipairs(tris) do
		local pos = v.pos
		for n=1, 3 do
			maxs[n] = math.max(maxs[n],pos[n])
			mins[n] = math.min(mins[n],pos[n])
		end
	end

	-- scale these up a tiny bit so we don't trim tris flush with the BB edge
	maxs = maxs*1.01
	mins = mins*1.01

	return maxs, mins, maxs-mins
end

local function getLongestAxis(box)
	local longest = math.max(box[1],box[2],box[3])
	if(longest == box[1]) then longest = 1 
	elseif(longest == box[2]) then longest = 2
	else longest = 3 end

	local axis = Vector(0,0,0)
	axis[longest] = 1
	return axis, box[longest]
end

local function mesh_preproc(tris)

	local parent = MESHCLIP.parent
	local share_cache = {}

	local maxs, mins, box = getBB(tris)
	local axis, axisLen = getLongestAxis(box)

	local slices = {}

	local COUNT = 8
	local STEP  = 1/COUNT

	local tris_all = {}
	local caching = {}

	VERTEXLINKER.Reset()
	VERTEXLINKER.Link(tris)

	for i=0, COUNT do
		local t = i/COUNT

		local tris_right = meeMeshSplit(tris, mins + axis*axisLen*(t), axis, share_cache, i) 
		tris_right = meeMeshSplit(tris_right, mins + axis*axisLen*(t+STEP), -axis, share_cache, i) 

		slices[i] = tris_right
			
		table.Add(tris_all,tris_right)
	end

	for k, v in ipairs(tris_all) do
		if not caching[v.pos] then
			caching[v.pos] = true
			tris_all[k].pos:Add( Vector(0,0,v.slice * 10) )
		end
	end

	print( VERTEXLINKER.countUnique() )

	-- local tri_slice = 
	-- 	fastMeshSlice(tris, 
	-- 		mins + axis*axisLen*(0.25), axis, 
	-- 		mins + axis*axisLen*(0.75), -axis
	-- ) 


	return tris_all

end

MESHCLIP.meshes = MESHCLIP.meshes or {}

local function MeshClip(parent)

	if not parent or not IsValid(parent) then error("no parent ent") end

	local MeshClip = ents.CreateClientside("starfall_hologram")
	MESHCLIP.meshes[parent] = MeshClip
	MeshClip:SetParent(parent)
	MeshClip.parent = parent

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
		local parent = self.parent

		if ( self.Meshes ) then
			local meshes = self.Meshes
			local materials = self.Materials

			local transform = Matrix()
			transform:Translate( parent:GetPos() )
			transform:Rotate( parent:GetAngles() )

			render.SetMaterial(wire)
			local color = parent:GetColor()
			local alpha = color.a / 255
			color = Vector(color.r/255,color.g/255,color.b/255)

			local flashlight = LocalPlayer():FlashlightIsOn()
			

			cam.PushModelMatrix( transform )
				for k, submesh in ipairs(meshes) do
					-- these are fucking stupid but they work
					materials[k]:SetVector("$color",color)
					materials[k]:SetFloat("$alpha",alpha)
					render.SetMaterial( materials[k] )
				 	if flashlight then
						render.PushFlashlightMode(true)
						submesh:Draw()
						render.PopFlashlightMode()
					else
						submesh:Draw()
					end
				end
			cam.PopModelMatrix()
		end
	end

	return MeshClip

end



//


---- Testing Stuff ----
local testmesh

function MESHCLIP.spawn(mdl)

	for k, msh in pairs(MESHCLIP.meshes) do
		if msh and IsValid(msh) then
			chat.AddText("Removing old mesh")
			msh:Remove()
		end
	end

	testmesh = MeshClip( MESHCLIP.parent )
	testmesh:SetPos( MESHCLIP.parent:GetPos() )
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

MESHCLIP.spawn("models/props_c17/FurnitureBathtub001a.mdl")
