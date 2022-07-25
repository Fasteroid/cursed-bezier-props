include("controlpoint.lua")

CONTROLPOINTS = CONTROLPOINTS or {}

if CONTROLPOINTS.test and IsValid(CONTROLPOINTS.test) then
    CONTROLPOINTS.test:Remove()
end

local eyetrace = LocalPlayer():GetEyeTrace()

CONTROLPOINTS.test = ents.CreateClientside("bezier_control")
local test = CONTROLPOINTS.test

function test:Think()


end

test:SetPos( eyetrace.HitPos )
test:Spawn()
