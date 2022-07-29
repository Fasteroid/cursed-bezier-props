VERTEXLINKER = VERTEXLINKER or {}
local addr_lookup = {}
local points = {}
local addr_ptr = 0

local function v2s(v)
    return "" .. math.Round(v[1],3) .. "," .. math.Round(v[2],3) .. "," .. math.Round(v[3],3)
end

local function point_copy(point_list)
    local copy = {}
    for addr, point in ipairs(point_list) do
        local pos = point[1]
        copy[addr] = { Vector(pos[1],pos[2],pos[3]), point[2] }
    end
    return copy
end

local function reset()
    addr_cache = {}
    points = {}
    addr_ptr = 0
end

local function alloc_ptr(pos, slice)
    local id = v2s(pos)
    if not addr_lookup[id] then 
        addr_ptr = addr_ptr + 1
        addr_lookup[id] = addr_ptr
        points[addr_ptr] = {pos, slice}
    end
    return addr_lookup[id]
end

function VERTEXLINKER.BuildAccelStruct(verts)
    reset()

    local struct = {}
    struct.verts = {}
    struct.points = {}

    local struct_verts = struct.verts

    for vid, vert in ipairs(verts) do
        vert.pos = alloc_ptr(vert.pos, vert.slice)
        struct_verts[vid] = vert
    end

    struct.points = point_copy(points)

    return struct -- has same verticies as [verts], but all positions are now replaced with "memory addresses" that are "pointers" to vectors in [struct.positions]
end

function VERTEXLINKER.CopyAccelStruct(struct)
    local struct_copy = {}

    struct_copy.verts = struct.verts
    struct_copy.points = point_copy( struct.points )

    return struct_copy -- same struct but with a copy of [struct.points] so you can modify it without messing up the master copy
end

function VERTEXLINKER.FlashAccelStruct(master, recipient) -- Like doing [recipient = VERTEXLINKER.CopyAccelStruct(master)] but with less garbage production!
    for pid, mpoint in ipairs(master.points) do
        local rpoint = recipient[pid][1]
        rpoint[1] = mpoint[1]
        rpoint[2] = mpoint[2]
        rpoint[3] = mpoint[3]
    end
end

function VERTEXLINKER.ParseAccelStruct(struct)
    local verts = {}

    local struct_verts = struct.verts
    local struct_points = struct.points

    for vid, vert in ipairs(struct_verts) do
        vert.pos = struct_points[ vert.pos ][1]
        verts[vid] = vert
    end

    return verts -- gets back [verts] from a vertexlinker struct
end