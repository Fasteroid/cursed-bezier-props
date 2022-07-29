local function reload()

    --include("experiments/meshclip.lua")
    --include("experiments/vertexlinkertest.lua")
    include("autorun/fastslice.lua")
    include("autorun/vertexlinker.lua")
    include("autorun/properties/beziercreate.lua")
    print("init.lua")

end

reload()

if CLIENT then
    hook.Add("CreateMove","Bezier.F5",function(cmd)
        if input.WasKeyPressed(KEY_F5) then
            reload()
            net.Start("Bezier.F5")
            net.SendToServer()
        end
    end)
    hook.Add("CreateMove","Bezier.F6",function(cmd)
        if input.WasKeyPressed(KEY_F6) then
            for i=1, 8192 do
                cam.PopModelMatrix()
            end
        end
    end)
end

if SERVER then
    util.AddNetworkString("Bezier.F5")
    net.Receive("Bezier.F5", reload)
end


