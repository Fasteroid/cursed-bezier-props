// Thanks to Mee for this code (I tried once and was too lazy to make further attempts)

local util_IntersectRayWithPlane = util.IntersectRayWithPlane

local GetShared = VERTEXLINKER.GetShared

local function mix(a,b,fac)
    return a*(1-fac) + b*fac
end 

local function rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
    local p3 = util_IntersectRayWithPlane(v1.pos, v2.pos - v1.pos, plane_pos, plane_dir)
    if p3 then
        local vert = {}
        vert.pos = GetShared(p3)
        local dist = v1.pos:Distance(v2.pos)
        local fac = p3:Distance(v1.pos) / dist
        vert.u = mix(v1.u,v2.u,fac)
        vert.v = mix(v1.v,v2.v,fac)
        vert.normal = mix(v1.normal,v2.normal,fac)
        vert.tangent = mix(v1.tangent,v2.tangent,fac)
        vert.userdata = {}
        for i=1, 4 do
            vert.userdata[i] = mix(v1.userdata[i],v2.userdata[i],fac)
        end
        return vert
    end
end

// tris in are in the format {{pos = value}, {pos = value2}}
function meeMeshSplit(tris, plane_pos, plane_dir, vertex_share_cache, slice)

    PrintTable(tris)

    local TRIS_A = {}
    local A_TRIS_INDEX = 0

    local VERTS_A = {}
    local A_INDEX = 0

    local TRIS_B = {}
    local B_TRIS_INDEX = 0

    // loop through all triangles in the mesh
    for i = 1, #tris, 3 do

        local v1 = tris[i    ]
        local v2 = tris[i + 1]
        local v3 = tris[i + 2]

        v1.pos = GetShared(v1.pos)
        v2.pos = GetShared(v2.pos)
        v3.pos = GetShared(v3.pos)

        local p1 = v1.pos
        local p2 = v2.pos
        local p3 = v3.pos

        assert( (v1.slice or 0 == v2.slice or 0) and (v2.slice or 0 == v3.slice or 0), "slice consistency failed" )

        // get points that are valid sides of the plane

        local p1_valid = (p1 - plane_pos):Dot(plane_dir) > 0
        local p2_valid = (p2 - plane_pos):Dot(plane_dir) > 0
        local p3_valid = (p3 - plane_pos):Dot(plane_dir) > 0
        
        // if all points should be kept, add triangle
        if p1_valid and p2_valid and p3_valid then -- half A
            TRIS_A[A_TRIS_INDEX + 1] = v1
            TRIS_A[A_TRIS_INDEX + 2] = v2
            TRIS_A[A_TRIS_INDEX + 3] = v3
            A_TRIS_INDEX = A_TRIS_INDEX + 3
            continue
        end
        
        // if none of the points should be kept, skip triangle
        if !p1_valid and !p2_valid and !p3_valid then -- half B
            -- TRIS_B[B_TRIS_INDEX + 1] = v1
            -- TRIS_B[B_TRIS_INDEX + 2] = v2
            -- TRIS_B[B_TRIS_INDEX + 3] = v3
            -- B_TRIS_INDEX = B_TRIS_INDEX + 3
            continue
        end
        
        // all possible states of the intersected triangle
        // extremely fast since a max of 4 if statments are required
        local point1
        local point2

        if p1_valid then
            if p2_valid then      //p1 = valid, p2 = valid, p3 = invalid
                point1 = rayPlaneIntersect(v1, v3, plane_pos, plane_dir)
                point2 = rayPlaneIntersect(v2, v3, plane_pos, plane_dir)
                if !point1 then point1 = v3 end
                if !point2 then point2 = v3 end

                TRIS_A[A_TRIS_INDEX + 1] = v1     -- forwards, half A
                TRIS_A[A_TRIS_INDEX + 2] = v2
                TRIS_A[A_TRIS_INDEX + 3] = point1

                TRIS_A[A_TRIS_INDEX + 6] = v2     -- backwards, half A
                TRIS_A[A_TRIS_INDEX + 5] = point1
                TRIS_A[A_TRIS_INDEX + 4] = point2
                
                A_TRIS_INDEX = A_TRIS_INDEX + 6
            elseif p3_valid then  // p1 = valid, p2 = invalid, p3 = valid
                point1 = rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
                point2 = rayPlaneIntersect(v3, v2, plane_pos, plane_dir)
                if !point1 then point1 = v2 end
                if !point2 then point2 = v2 end
                
                TRIS_A[A_TRIS_INDEX + 3] = v1     -- backwards, half A
                TRIS_A[A_TRIS_INDEX + 2] = v3
                TRIS_A[A_TRIS_INDEX + 1] = point1

                TRIS_A[A_TRIS_INDEX + 4] = v3     -- forwards, half A
                TRIS_A[A_TRIS_INDEX + 5] = point1
                TRIS_A[A_TRIS_INDEX + 6] = point2

                A_TRIS_INDEX = A_TRIS_INDEX + 6

                VERTS_A[A_INDEX + 1] = v1
                VERTS_A[A_INDEX + 2] = v3
                VERTS_A[A_INDEX + 3] = point1
                if point2 ~= point1 then
                    VERTS_A[A_INDEX + 4] = point2
                    A_INDEX = A_INDEX + 4
                else
                    A_INDEX = A_INDEX + 3
                end

            else                    // p1 = valid, p2 = invalid, p3 = invalid
                point1 = rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
                point2 = rayPlaneIntersect(v1, v3, plane_pos, plane_dir)
                if !point1 then point1 = v2 end
                if !point2 then point2 = v3 end

                TRIS_A[A_TRIS_INDEX + 1] = v1     -- forwards, half A
                TRIS_A[A_TRIS_INDEX + 2] = point1
                TRIS_A[A_TRIS_INDEX + 3] = point2
                
                A_TRIS_INDEX = A_TRIS_INDEX + 3
            end
        elseif p2_valid then
            if p3_valid then      // p1 = invalid, p2 = valid, p3 = valid
                point1 = rayPlaneIntersect(v2, v1, plane_pos, plane_dir)
                point2 = rayPlaneIntersect(v3, v1, plane_pos, plane_dir)
                if !point1 then point1 = v1 end
                if !point2 then point2 = v1 end

                TRIS_A[A_TRIS_INDEX + 1] = v2     -- forwards, half A
                TRIS_A[A_TRIS_INDEX + 2] = v3
                TRIS_A[A_TRIS_INDEX + 3] = point1
                
                TRIS_A[A_TRIS_INDEX + 6] = v3     -- backwards, half A
                TRIS_A[A_TRIS_INDEX + 5] = point1
                TRIS_A[A_TRIS_INDEX + 4] = point2
                
                A_TRIS_INDEX = A_TRIS_INDEX + 6
            else                    // p1 = invalid, p2 = valid, p3 = invalid
                point1 = rayPlaneIntersect(v2, v1, plane_pos, plane_dir)
                point2 = rayPlaneIntersect(v2, v3, plane_pos, plane_dir)
                if !point1 then point1 = v1 end
                if !point2 then point2 = v3 end

                TRIS_A[A_TRIS_INDEX + 3] = v2     -- backwards, half A
                TRIS_A[A_TRIS_INDEX + 2] = point1
                TRIS_A[A_TRIS_INDEX + 1] = point2
                
                A_TRIS_INDEX = A_TRIS_INDEX + 3
            end
        else                       // p1 = invalid, p2 = invalid, p3 = valid
        
            point1 = rayPlaneIntersect(v3, v1, plane_pos, plane_dir)
            point2 = rayPlaneIntersect(v3, v2, plane_pos, plane_dir)
            if !point1 then point1 = v1 end
            if !point2 then point2 = v2 end

            TRIS_A[A_TRIS_INDEX + 1] = v3    -- forwards, half A
            TRIS_A[A_TRIS_INDEX + 2] = point1
            TRIS_A[A_TRIS_INDEX + 3] = point2
            
            A_TRIS_INDEX = A_TRIS_INDEX + 3
        end

    end

    for k, v in ipairs(TRIS_A) do
        v.slice = math.max(v.slice or 0, slice)
    end
    
    for i = 1, #TRIS_A, 3 do
        local v1 = TRIS_A[i    ]
        local v2 = TRIS_A[i + 1]
        local v3 = TRIS_A[i + 2]

        assert( (v1.slice or 0 == v2.slice or 0) and (v2.slice or 0 == v3.slice or 0), "slice consistency failed" )
    end

    return TRIS_A

end