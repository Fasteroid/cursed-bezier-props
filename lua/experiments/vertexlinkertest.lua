include('vertexlinker.lua')

local verts = {}
print("======================================")
print("============ VERTEXLINKER ============")
print("======================================")
for n=0, 4 do
    table.insert(verts,{
        pos = Vector(n,0,0),
        slice = 1
    })
    table.insert(verts,{
        pos = Vector(0,n,0),
        slice = 2
    })
    table.insert(verts,{
        pos = Vector(0,0,n),
        slice = 3
    })
end

PrintTable(verts)

local struct = VERTEXLINKER.BuildAccelStruct(verts)

for addr, point in ipairs(struct.points) do
    point[1]:Add( Vector(0,point[2],0) )
end

verts = VERTEXLINKER.ParseAccelStruct(struct)
PrintTable(verts)