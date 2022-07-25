include("shared.lua")
print("bezier_control/cl_init.lua")
-- TODO

function ENT:Initialize()

    local parent = self -- prevents confusion
    self.Drag = ents.CreateClientside("bezier_drag")
    self.Drag:SetPos( self:GetPos() + self:GetForward() * 10 )
    self.Drag:SetParent(self)

    function parent.Drag:Drag()
        local trace = LocalPlayer():GetEyeTrace()
        local eye = trace.StartPos
        local fwd = trace.HitPos - trace.StartPos

        local arrowdir = parent:GetAngles():Forward()
        local planepos = self:GetPos()
        local planenrm = (eye-planepos):GetNormal()


        local trace = LocalPlayer():GetEyeTrace()
        local eye = trace.StartPos
        local fwd = trace.HitPos - trace.StartPos
        local hitpos = util.IntersectRayWithPlane( eye, fwd, planepos, planenrm )
        if ( !hitpos ) then return end
        local fdist, vpos, falong = util.DistanceToLine( parent:GetPos(), parent:GetPos() + parent:GetForward() * 1024, hitpos )
        -- Get nearest point along the arrow where we touched it
        self:SetPos(vpos)
    end

    self.Drag:Spawn()
end

function ENT:OnRemove()
    self.Drag:Remove()
end

local linecolor = Color(255,255,0)
function ENT:Draw()
    self:DrawModel()
    self.Drag:Draw() -- should probably draw on top
    render.DrawLine( self:GetPos(), self.Drag:GetPos(), linecolor)
end