AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

print("bezier_control/init.lua")

function ENT:Initialize()
    self:SetModel("models/maxofs2d/hover_classic.mdl")
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
end

function ENT:Think()

    if not self:IsPlayerHolding() then
        local phys = self:GetPhysicsObject()
        if phys:IsMotionEnabled() then
            phys:EnableMotion(false)
        end
        phys:EnableGravity(false)
    end

    self:NextThink(CurTime())
    return true

end