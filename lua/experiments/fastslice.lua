local util_IntersectRayWithPlane = util.IntersectRayWithPlane

local function mix(a,b,fac)
    return a*(1-fac) + b*fac
end 

local function rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
    local p3 = util_IntersectRayWithPlane(v1.pos, v2.pos - v1.pos, plane_pos, plane_dir)
    if p3 then
        local vert = {}
        vert.pos = p3
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
        return vert, true
    end
    return v2, false -- mee's code always does this
end

-- optimized version of mee's code, with numerous fixes

local function slice(tris, plane_pos, plane_dir, slice)

    local TRIS = {}
    local TRIS_N = 0

    local function pushtri(v1, v2, v3)
        TRIS[TRIS_N + 1] = v1
        TRIS[TRIS_N + 2] = v2
        TRIS[TRIS_N + 3] = v3
        TRIS_N = TRIS_N + 3
    end

    local function pushquad(v1, v2, v3, v4)

        TRIS[TRIS_N + 1] = v1
        TRIS[TRIS_N + 2] = v2
        TRIS[TRIS_N + 3] = v4

        TRIS[TRIS_N + 4] = v2
        TRIS[TRIS_N + 5] = v3
        TRIS[TRIS_N + 6] = v4

        TRIS_N = TRIS_N + 6
    end

    // loop through all triangles in the mesh
    for i = 1, #tris, 3 do

        local v1 = tris[i    ]
        local v2 = tris[i + 1]
        local v3 = tris[i + 2]

        -- assert( (v1.slice or 0 == v2.slice or 0) and (v2.slice or 0 == v3.slice or 0), "slice consistency failed" )

        local p1 = v1.pos
        local p2 = v2.pos
        local p3 = v3.pos

        -- v1.pos = Vector(p1.x,p1.y,p1.z)
        -- v2.pos = Vector(p2.x,p2.y,p2.z)
        -- v3.pos = Vector(p3.x,p3.y,p3.z)

        // get points that are valid sides of the plane

        local p1_valid = (p1 - plane_pos):Dot(plane_dir) > 0
        local p2_valid = (p2 - plane_pos):Dot(plane_dir) > 0
        local p3_valid = (p3 - plane_pos):Dot(plane_dir) > 0
        
        // if all points should be kept, add triangle
        if p1_valid and p2_valid and p3_valid then -- half A
            pushtri(v1,v2,v3)
            continue
        end
        
        // if none of the points should be kept, skip triangle
        if !p1_valid and !p2_valid and !p3_valid then -- half B
            continue
        end
        
        local vA
        local vB

        local succA
        local succB

        -- god help this is horrible
        if p1_valid then
        
            if p2_valid then  //p1 = valid, p2 = valid, p3 = invalid

                vA, succA = rayPlaneIntersect(v1, v3, plane_pos, plane_dir)
                vB, succB = rayPlaneIntersect(v2, v3, plane_pos, plane_dir)

                if succA then
                    if succB then
                        pushtri(v1, v2, vA) -- v1 v2 vA
                        pushtri(vB, vA, v2) -- v3 vA v2
                    else
                        pushtri(v1, v2, vA) -- v1 v2 vA
                        pushtri(vB, vA, v2) -- v3 vA v2
                    end
                else
                    pushtri(v1, v2, vA) -- v1 v2 vA
                    -- pushtri(vB, vA, v2) [degenerate]
                end

            elseif p3_valid then  // p1 = valid, p2 = invalid, p3 = valid

                vA, succA = rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
                vB, succB = rayPlaneIntersect(v3, v2, plane_pos, plane_dir)
                
                if succA then
                    if succB then
                        pushtri(vA, v3, v1) -- vA v3 v1
                        pushtri(v3, vA, vB) -- v3 vA v2
                    else
                        pushtri(vA, v3, v1) -- vA v3 v1
                        pushtri(v3, vA, vB) -- v3 vA v2
                    end
                else
                    pushtri(vA, v3, v1) -- v2 v3 v1
                    -- pushtri(v3, vA, vB) [degenerate]
                end

            else  // p1 = valid, p2 = invalid, p3 = invalid

                vA, succA = rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
                vB, succB = rayPlaneIntersect(v1, v3, plane_pos, plane_dir)

                if succA and succB then
                    pushtri(v1, vA, vB)
                end -- else [degenerate]

            end

        elseif p2_valid then

            if p3_valid then  // p1 = invalid, p2 = valid, p3 = valid

                vA, succA = rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
                vB, succB = rayPlaneIntersect(v3, v1, plane_pos, plane_dir)
                
                if succA then
                    if succB then
                        pushtri(v2, v3, vA) -- v2 v3 vA
                        pushtri(vB, vA, v3) -- v1 vA v3
                    else
                        pushtri(v2, v3, vA) -- v2 v3 vA
                        pushtri(vB, vA, v3) -- v1 vA v3
                    end
                else
                    -- pushtri(v2, v3, vA) [degenerate]
                    pushtri(vB, vA, v3)
                end

            else  // p1 = invalid, p2 = valid, p3 = invalid

                vA, succA = rayPlaneIntersect(v2, v1, plane_pos, plane_dir)
                vB, succB = rayPlaneIntersect(v2, v3, plane_pos, plane_dir)

                if succA and succB then
                    pushtri(vB, vA, v2)
                end -- else [degenerate]

            end
        else  // p1 = invalid, p2 = invalid, p3 = valid
        
            vA, succA = rayPlaneIntersect(v3, v1, plane_pos, plane_dir)
            vB, succB = rayPlaneIntersect(v3, v2, plane_pos, plane_dir)

            if succA and succB then
                pushtri(v3, vA, vB)
            end -- else [degenerate]

        end

    end

    for k, v in ipairs(TRIS) do
        v.slice = math.max(v.slice or 0, slice)
    end

    return TRIS
end





function fastMeshSlice(tris, plane_pos_1, plane_dir_1, plane_pos_2, plane_dir_2, slice_num)
    local tris = slice(tris, plane_pos_1, plane_dir_1, slice_num)
    tris = slice(tris, plane_pos_2, plane_dir_2, slice_num)

    return tris
end