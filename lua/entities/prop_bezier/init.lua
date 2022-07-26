AddCSLuaFile('shared.lua')
include('shared.lua')
AddCSLuaFile('cl_init.lua')

print("prop_bezier/init.lua")

function ENT:Initialize()
    self.IsBezier = true -- if you change this after creation you are gay
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
end

function ENT:SetModel(path)
    BaseClass.SetModel(self, path)
    self:Activate()
end
