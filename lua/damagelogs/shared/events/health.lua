if SERVER then
    Damagelog:EventHook("TTTPlayerUsedHealthStation")
    Damagelog:EventHook("TTTEndRound")
else
    Damagelog:AddFilter("filter_show_healthstation", DAMAGELOG_FILTER_BOOL, false)
    Damagelog:AddColor("color_heal", Color(0, 255, 128))
end

local usages = {}
local event = {}
event.Type = "HEAL"

function event:TTTPlayerUsedHealthStation(ply, ent, healed)
    if (ply.IsGhost and ply:IsGhost()) or not ply:IsPlayer() then return end

    if usages[ply:SteamID()] ~= nil then
        usages[ply:SteamID()] = usages[ply:SteamID()] + healed
        return
    end

    local healthStationOwner = (ent.GetPlacer and ent:GetPlacer()) -- Vanilla TTT
        or (ent.GetOriginator and ent:GetOriginator()) -- TTT2
        or nil

    local timername = "HealTimer_" .. tostring(ply:SteamID())

    timer.Create(timername, 5, 0, function()
        if not IsValid(ply) then
            timer.Remove(timername)
        elseif usages[ply:SteamID()] > 0 then
            self:Store(ply, healthStationOwner, usages[ply:SteamID()])
            usages[ply:SteamID()] = 0
        else
            usages[ply:SteamID()] = nil
            self:RemoveTimer(ply:SteamID())
        end
    end)

    self:Store(ply, healthStationOwner, healed)
    usages[ply:SteamID()] = 0
end

function event:Store(ply, healthStationOwner, healed)
    local isOwnerValid = IsValid(healthStationOwner)
    local tbl = {
        [1] = ply:GetDamagelogID(),
        [2] = healed,
        [3] = isOwnerValid,
        [4] = isOwnerValid and healthStationOwner:GetDamagelogID() or nil
    }

    self.CallEvent(tbl)
end

function event:RemoveTimer(id)
    local timername = "HealTimer_" .. tostring(id)

    if timer.Exists(timername) then
        timer.Remove(timername)
    end
end

function event:TTTEndRound()
    for k in pairs(usages) do
        self:RemoveTimer(k)
    end
end

function event:ToString(tbl, roles)
    local ply = Damagelog:InfoFromID(roles, tbl[1])
    local healerNick

    if tbl[3] then
        local healer = Damagelog:InfoFromID(roles, tbl[4])
        healerNick = healer.nick .. " [" .. Damagelog:StrRole(healer.role) .. "]"
    else
        healerNick = TTTLogTranslate(GetDMGLogLang, "healerNick")
    end

    return string.format(TTTLogTranslate(GetDMGLogLang, "HealthStationHeal"), ply.nick, Damagelog:StrRole(ply.role), tbl[2], healerNick)
end

function event:IsAllowed(tbl)
    return Damagelog.filter_settings["filter_show_healthstation"]
end

function event:Highlight(line, tbl, text)
    if table.HasValue(Damagelog.Highlighted, tbl[1]) or table.HasValue(Damagelog.Highlighted, tbl[2]) then
        return true
    end

    return false
end

function event:GetColor(tbl)
    return Damagelog:GetColor("color_heal")
end

function event:RightClick(line, tbl, roles, text)
    line:ShowTooLong(true)
    local ply = Damagelog:InfoFromID(roles, tbl[1])

    if tbl[3] then
        local healer = Damagelog:InfoFromID(roles, tbl[4])
        line:ShowCopy(true, {ply.nick, util.SteamIDFrom64(ply.steamid64)}, {healer.nick, util.SteamIDFrom64(healer.steamid64)})
    else
        line:ShowCopy(true, {ply.nick, util.SteamIDFrom64(ply.steamid64)})
    end
end

Damagelog:AddEvent(event)