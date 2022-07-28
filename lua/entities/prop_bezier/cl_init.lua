include('shared.lua')
print("prop_bezier/cl_init.lua")

include('entities/bezier_drag.lua')

include('experiments/fastslice.lua')
include('experiments/vertexlinker.lua')

local function transformToBone(vec, bones, weights, binds) -- special thanks to derpius for helping me fix the dreaded root bone rotated models
    local final = Vector()
    for _, v in pairs(weights) do
        if not bones[v.bone] or not binds[v.bone] then continue end
        final = final + bones[v.bone] * binds[v.bone].matrix * vec * v.weight
    end
    return final
end

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

	local maxs, mins, box = getBB(tris)
	local axis, axisLen = getLongestAxis(box)

	local COUNT = 64
	local STEP  = 1/COUNT

	local tris_all = {}

	for i=0, COUNT-1 do
		local t = i/COUNT

		local tris_right = fastMeshSlice(tris, 
            mins + axis*axisLen*(t), axis,
            mins + axis*axisLen*(t+STEP), -axis,
        i) 
			
		table.Add(tris_all,tris_right)
	end

    VERTEXLINKER.Reset()
	VERTEXLINKER.Link(tris_all)
    print( VERTEXLINKER.countUnique() )

	local verts_processed = {}

	for k, v in ipairs(tris_all) do
		if not verts_processed[v.pos] then
			verts_processed[v.pos] = true
			tris_all[k].pos:Sub( axis*axisLen*(v.slice)*STEP )
		end
	end

    -- print(table.Count(caching))

	return tris_all

end

function ENT:GetBoneMatricies()
    if self.bones then return self.bones end
    self:SetupBones()
    local bones = {}
    for i = 0, self:GetBoneCount() - 1 do
        bones[i] = self:GetBoneMatrix(i)
    end
    self.bones = bones
    return bones
end

function ENT:vert_unfuck(vismesh, bindposes) 
    local objectTransform = Matrix()
    objectTransform:SetTranslation(self:GetPos())
    objectTransform:SetAngles(self:GetAngles())

    -- Transform the world coordinates using the object transform as an inverted transformation matrix
    
    local bones = self:GetBoneMatricies()

    for _, vert in pairs(vismesh.triangles) do
        if not vert.weights then continue end
        vert.pos = self:WorldToLocal( transformToBone(vert.pos, bones, vert.weights, bindposes) )
        vert.weights = nil
    end
end

local function DestroyMeshes(meshes)
    for k, submesh in ipairs(meshes or {}) do
        submesh:Destroy()
    end 
end

function ENT:BuildMeshes()
    DestroyMeshes( self.Meshes )

    self.Meshes = {}
    self.Materials = {}
    self.DebugMeshes = {}

    local vismeshes, bindposes = util.GetModelMeshes( self:GetModel() )
    local clipped_vismeshes = {}
    if ( !vismeshes ) then return end

    for k, vismesh in ipairs(vismeshes) do
           
        self:vert_unfuck(vismesh,bindposes) -- certain models are fucked and need to be unfucked
        vismesh.triangles = mesh_preproc(vismesh.triangles)

        if( #vismesh.triangles > 0 ) then
            self.Meshes[#self.Meshes+1] = Mesh( self.Materials[k] )  -- USERDATAS ARE STUPID!!!
            self.Materials[#self.Materials+1] = Material(vismesh.material)
            self.Meshes[#self.Meshes]:BuildFromTriangles( vismesh.triangles )
        end

    end
end

local wireframe = Material("models/wireframe")

function ENT:Initialize()
    self.IsBezier = true -- if you change this after creation you are gay
    self:BuildMeshes()
end

function ENT:OnRemove()
    local meshes = self.Meshes
    timer.Simple( 0, function()
		if not IsValid( self ) then -- definiely gone
			DestroyMeshes(meshes) -- avoid leaking memory
        end
	end)
end

function ENT:Draw()
    self:SetModelScale(0)
    self:DrawModel() -- lighting bug fix

    if ( self.Meshes ) then
        local meshes = self.Meshes
        local materials = self.Materials

        local transform = Matrix()
        transform:Translate( self:GetPos() )
        transform:Rotate( self:GetAngles() )

        render.SetMaterial(wireframe)
        local color = self:GetColor()
        local alpha = color.a / 255
        color = Vector(color.r/255,color.g/255,color.b/255)

        local flashlight = LocalPlayer():FlashlightIsOn()
        
        cam.PushModelMatrix( transform )
            for k, submesh in ipairs(meshes) do
                -- these are fucking stupid but they work
                materials[k]:SetVector("$color",color)
                materials[k]:SetFloat("$alpha",alpha)
                render.SetMaterial( materials[k] )
                if flashlight then -- TODO: why is our model transparent???
                    -- render.PushFlashlightMode(true)
                    submesh:Draw()
                    -- render.PopFlashlightMode()
                else
                    submesh:Draw()
                end
            end
        cam.PopModelMatrix()
    end
end