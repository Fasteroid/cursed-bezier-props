VERTEXLINKER = VERTEXLINKER or {}
local cache = {}

local function v2s(v)
    return "" .. math.Round(v[1],3) .. "," .. math.Round(v[2],3) .. "," .. math.Round(v[3],3)
end

function VERTEXLINKER.Reset()
    cache = {}
end

function VERTEXLINKER.GetShared(vec)
    local id = v2s(vec)
    if not cache[id] then cache[id] = vec end
    return cache[id]
end

local GetShared = VERTEXLINKER.GetShared

function VERTEXLINKER.Link(verts)
    for k, v in ipairs(verts) do
        verts[k].pos = GetShared(v.pos) -- this SHOULD link everything
    end
end

function VERTEXLINKER.countUnique()
    return table.Count(cache)
end