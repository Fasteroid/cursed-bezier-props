local ControlPoints = {}
local ENT = scripted_ents.Get("base_anim")

ENT.Type            = "anim"
ENT.Base            = "base_anim"

ENT.Dragging = false

function ENT:Initialize()
    ControlPoints[self] = true
    self:SetModel("models/pac/default.mdl")
end

function ENT:StartDrag()
    self.Dragging = true
    chat.AddText("ENT:StartDrag()")
end

function ENT:EndDrag()
    self.Dragging = false
    chat.AddText("ENT:EndDrag()")
end

function ENT:OnRemove()
    ControlPoints[self] = nil
end

function ENT:IsHovered() -- TODO: consider caching results every frame
    local trace = LocalPlayer():GetEyeTrace()
    PrintTable(trace)
    local pos, norm, frac = util.IntersectRayWithOBB(trace.StartPos, (trace.HitPos - trace.StartPos)*999, self:GetPos(), self:GetAngles(), self:OBBMins(), self:OBBMaxs())
    return frac
end

function ENT:Thinkk() -- TODO: why does think not run every frame like it should?
    if self.Dragging then
        self:SetPos( LocalPlayer():GetEyeTrace().HitPos )
    end
end
hook.Add("Think","Bezier.ControlPoints.ThinkFix",function()
    for ent, _ in pairs(ControlPoints) do
        ent:Thinkk()
    end
end)

scripted_ents.Register(ENT, "bezier_control")

-- god I hate everything, this code is so horrible

local function blockServerClicks(cmd)
	cmd:RemoveKey(IN_ATTACK)
	cmd:RemoveKey(IN_ATTACK2)
end

local isClick        = false
local isWorldClicker = false
local clickedControl = nil

hook.Add("CreateMove", "Bezier.ControlPoints.OnClick", function(cmd)

    local attack1 = cmd:KeyDown(IN_ATTACK) or input.IsMouseDown(MOUSE_FIRST)
    
    if attack1 ~= isClick and attack1 then
        isClick = true
        for ent, _ in pairs(ControlPoints) do
            if ent:IsHovered()  then
                clickedControl = ent
                clickedControl:StartDrag()
                break
            end
        end
    elseif not attack1 then
        isClick = false
        if clickedControl then clickedControl:EndDrag() end
        clickedControl = nil
    end

    if not isWorldClicker and isClick and clickedControl then blockServerClicks(cmd) return true end
    isWorldClicker = false

end)

hook.Add( "PreventScreenClicks", "Bezier.ControlPoints.OnWorldClicker", function()
    isWorldClicker = true
	return not not clickedControl
end )