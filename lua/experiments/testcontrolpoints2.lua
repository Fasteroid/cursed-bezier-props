if SERVER then
    CONTROLPOINTS = CONTROLPOINTS or {}

    if CONTROLPOINTS.test and IsValid(CONTROLPOINTS.test) then
        CONTROLPOINTS.test:Remove()
    end

    local eyetrace = Entity(1):GetEyeTrace()

    CONTROLPOINTS.test = ents.Create("bezier_control")
    local test = CONTROLPOINTS.test

    test:SetPos( eyetrace.HitPos )
    test:Spawn()
end