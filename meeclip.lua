// Thanks to Mee for this code (I tried once and was too lazy to make further attempts)

// tris in are in the format {{pos = value}, {pos = value2}}
function meeMeshSplit(tris, plane_pos, plane_dir, VERTS_ALL, VERTS_GROUPED)

    local util_IntersectRayWithPlane = util.IntersectRayWithPlane

    local function mix(a,b,fac)
        return a*(1-fac) + b*fac
    end 

    function rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
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
            return vert
        end
    end

    local VERTS_A = VERTS_GROUPED[#VERTS_GROUPED]
    
    local A_INDEX = #VERTS_A

    VERTS_GROUPED[#VERTS_GROUPED + 1] = {}
    local VERTS_B = VERTS_GROUPED[#VERTS_GROUPED] // becomes VERTS_A next split
    local B_INDEX = 0

    // loop through all triangles in the mesh
    for i = 1, #tris, 3 do
        local v1 = tris[i    ]
        local v2 = tris[i + 1]
        local v3 = tris[i + 2]

        local p1 = tris[i    ].pos
        local p2 = tris[i + 1].pos
        local p3 = tris[i + 2].pos

        // get points that are valid sides of the plane

        local p1_valid = (p1 - plane_pos):Dot(plane_dir) > 0
        local p2_valid = (p2 - plane_pos):Dot(plane_dir) > 0
        local p3_valid = (p3 - plane_pos):Dot(plane_dir) > 0
        
        // if all points should be kept, add triangle
        if p1_valid and p2_valid and p3_valid then -- half A
            VERTS_A[A_INDEX + 1] = v1
            VERTS_A[A_INDEX + 2] = v2
            VERTS_A[A_INDEX + 3] = v3
            A_INDEX = A_INDEX + 3
            continue
        end
        
        // if none of the points should be kept, skip triangle
        if !p1_valid and !p2_valid and !p3_valid then -- half B
            VERTS_B[B_INDEX + 1] = v1
            VERTS_B[B_INDEX + 2] = v2
            VERTS_B[B_INDEX + 3] = v3
            B_INDEX = B_INDEX + 3
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

                VERTS_A[A_INDEX + 1] = v1     -- forwards, half A
                VERTS_A[A_INDEX + 2] = v2
                VERTS_A[A_INDEX + 3] = point1

                VERTS_A[A_INDEX + 6] = v2     -- backwards, half A
                VERTS_A[A_INDEX + 5] = point1
                VERTS_A[A_INDEX + 4] = point2
                
                A_INDEX = A_INDEX + 6

                VERTS_B[B_INDEX + 1] = v3     -- forwards, half B
                VERTS_B[B_INDEX + 2] = point1
                VERTS_B[B_INDEX + 3] = point2

                B_INDEX = B_INDEX + 3
            elseif p3_valid then  // p1 = valid, p2 = invalid, p3 = valid
                point1 = rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
                point2 = rayPlaneIntersect(v3, v2, plane_pos, plane_dir)
                if !point1 then point1 = v2 end
                if !point2 then point2 = v2 end
                
                VERTS_A[A_INDEX + 3] = v1     -- backwards, half A
                VERTS_A[A_INDEX + 2] = v3
                VERTS_A[A_INDEX + 1] = point1

                VERTS_A[A_INDEX + 4] = v3     -- forwards, half A
                VERTS_A[A_INDEX + 5] = point1
                VERTS_A[A_INDEX + 6] = point2

                A_INDEX = A_INDEX + 6

                VERTS_B[B_INDEX + 3] = v2     -- backwards, half B
                VERTS_B[B_INDEX + 2] = point1
                VERTS_B[B_INDEX + 1] = point2

                B_INDEX = B_INDEX + 3
            else                    // p1 = valid, p2 = invalid, p3 = invalid
                point1 = rayPlaneIntersect(v1, v2, plane_pos, plane_dir)
                point2 = rayPlaneIntersect(v1, v3, plane_pos, plane_dir)
                if !point1 then point1 = v2 end
                if !point2 then point2 = v3 end

                VERTS_A[A_INDEX + 1] = v1     -- forwards, half A
                VERTS_A[A_INDEX + 2] = point1
                VERTS_A[A_INDEX + 3] = point2
                
                A_INDEX = A_INDEX + 3

                VERTS_B[B_INDEX + 3] = point1     -- forwards, half B
                VERTS_B[B_INDEX + 2] = point2
                VERTS_B[B_INDEX + 1] = v2

                VERTS_B[B_INDEX + 4] = v2     -- forwards, half B
                VERTS_B[B_INDEX + 5] = v3
                VERTS_B[B_INDEX + 6] = point2
                
                B_INDEX = B_INDEX + 6
            end
        elseif p2_valid then
            if p3_valid then      // p1 = invalid, p2 = valid, p3 = valid
                point1 = rayPlaneIntersect(v2, v1, plane_pos, plane_dir)
                point2 = rayPlaneIntersect(v3, v1, plane_pos, plane_dir)
                if !point1 then point1 = v1 end
                if !point2 then point2 = v1 end

                VERTS_A[A_INDEX + 1] = v2     -- forwards, half A
                VERTS_A[A_INDEX + 2] = v3
                VERTS_A[A_INDEX + 3] = point1
                
                VERTS_A[A_INDEX + 6] = v3     -- backwards, half A
                VERTS_A[A_INDEX + 5] = point1
                VERTS_A[A_INDEX + 4] = point2
                
                A_INDEX = A_INDEX + 6

                VERTS_B[B_INDEX + 1] = v1     -- forwards, half B
                VERTS_B[B_INDEX + 2] = point1
                VERTS_B[B_INDEX + 3] = point2

                B_INDEX = B_INDEX + 3
            else                    // p1 = invalid, p2 = valid, p3 = invalid
                point1 = rayPlaneIntersect(v2, v1, plane_pos, plane_dir)
                point2 = rayPlaneIntersect(v2, v3, plane_pos, plane_dir)
                if !point1 then point1 = v1 end
                if !point2 then point2 = v3 end

                VERTS_A[A_INDEX + 3] = v2     -- backwards, half A
                VERTS_A[A_INDEX + 2] = point1
                VERTS_A[A_INDEX + 1] = point2
                
                A_INDEX = A_INDEX + 3

                VERTS_B[B_INDEX + 1] = v1     -- forwards, half B
                VERTS_B[B_INDEX + 2] = point1
                VERTS_B[B_INDEX + 3] = point2

                VERTS_B[B_INDEX + 4] = v3     -- forwards, half B
                VERTS_B[B_INDEX + 5] = v1
                VERTS_B[B_INDEX + 6] = point2
                
                B_INDEX = B_INDEX + 6
            end
        else                       // p1 = invalid, p2 = invalid, p3 = valid
        
            point1 = rayPlaneIntersect(v3, v1, plane_pos, plane_dir)
            point2 = rayPlaneIntersect(v3, v2, plane_pos, plane_dir)
            if !point1 then point1 = v1 end
            if !point2 then point2 = v2 end

            VERTS_A[A_INDEX + 1] = v3    -- forwards, half A
            VERTS_A[A_INDEX + 2] = point1
            VERTS_A[A_INDEX + 3] = point2
            
            A_INDEX = A_INDEX + 3

            VERTS_B[B_INDEX + 3] = v1     -- backwards, half B
            VERTS_B[B_INDEX + 2] = point1
            VERTS_B[B_INDEX + 1] = point2

            VERTS_B[B_INDEX + 6] = v1     -- backwards, half B
            VERTS_B[B_INDEX + 5] = point2
            VERTS_B[B_INDEX + 4] = v2
                
            B_INDEX = B_INDEX + 6
        end

    end

    for k, group in ipairs(VERTS_GROUPED) do
        table.Add(VERTS_ALL, group)
    end

    PrintTable(VERTS_ALL)

end