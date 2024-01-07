AddCSLuaFile('shared.lua')
include('shared.lua')
AddCSLuaFile('cl_init.lua')

print("prop_bezier/init.lua")

local CONTROL_POINT_COUNT = 4

function ENT:Initialize()
    self.IsBezier = true -- if you change this after creation you are gay
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self.ControlPoints = {}
    for i=1, CONTROL_POINT_COUNT do
        local control = ents.Create("bezier_control")
        control:SetPos( self:GetPos() + Vector(0,0,i*10) )
        control:Spawn()
        self.ControlPoints[i] = control
    end
end

function ENT:SetModel(path)
    BaseClass.SetModel(self, path)
    self:Activate()
end

function ENT:OnRemove()
    for _, ent in ipairs(self.ControlPoints) do
        ent:Remove()
    end
end

function ENT:Think()
    for i=1, CONTROL_POINT_COUNT do
        if not IsValid( self.ControlPoints[i] ) then
            local control = ents.Create("bezier_control")
            control:SetPos( self:GetPos() + Vector(0,0,i*10) )
            control:Spawn()
            self.ControlPoints[i] = control
        end
    end
end