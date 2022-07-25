local function reload()

    include("experiments/testcontrolpoints2.lua")
    include("entities/bezier_drag.lua")
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
end

if SERVER then
    util.AddNetworkString("Bezier.F5")
    net.Receive("Bezier.F5", reload)
end