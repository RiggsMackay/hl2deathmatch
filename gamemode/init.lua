--[[ Include Files ]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua"); include("shared.lua")

util.AddNetworkString("dmChooseTeam")
util.AddNetworkString("dmBecomeTeam")
util.AddNetworkString("dmChooseClass")
util.AddNetworkString("dmBecomeClass")

net.Receive("dmBecomeTeam", function(len, ply)
    local teamUInt = net.ReadUInt(4)

    ply:SetTeam(teamUInt)
    ply:Spawn()

    ply:StripWeapons()
    ply:StripAmmo()

    net.Start("dmChooseClass")
        net.WriteUInt(teamUInt, 4)
    net.Send(ply)
end)

net.Receive("dmBecomeClass", function(len, ply)
    local teamUInt = net.ReadUInt(4)
    local classUInt = net.ReadUInt(4)

    ply:SetNWInt("class", hl2deathmach.classes[teamUInt][classUInt].index)

    hook.Run("PlayerLoadout", ply)
end)

--[[ Serverside Hooks ]]--

function GM:PlayerInitialSpawn(ply)
    net.Start("dmChooseTeam")
    net.Send(ply)
end

function GM:OnDamagedByExplosion()
	return true
end

function GM:PlayerLoadout(ply)
    local randomChance = math.random(1, 10)

    ply:SetJumpPower(175)
    ply:SetRunSpeed(130)
    ply:SetWalkSpeed(230)
    ply:StripWeapons()
    ply:StripAmmo()
    ply:SetSkin(0)
    ply:SetMaxHealth(100)
    ply:SetMaxArmor(100)
    
    ply:SetDSP(1)

    local playerClass = hl2deathmach.classes[ply:Team()][ply:GetNWInt("class", 1)]
    if ( playerClass ) then
        ply:SetModel(table.Random(hl2deathmach.classes[ply:Team()][ply:GetNWInt("class", 1)].models))
        playerClass.onBecome(ply)
    end

    ply:GodEnable()

    timer.Simple(4, function()
        ply:GodDisable()
    end)
end

function GM:PlayerDeath(ply, inflictor, attacker)
    ply:EmitSound("")
    if ( ply:Team() == FACTION_REBELS ) then
        ply:EmitSound("vo/npc/male01/pain0"..math.random(1,9)..".wav", 80)
    elseif ( ply:Team() == FACTION_COMBINES ) then
        ply:EmitSound("npc/combine_soldier/die"..math.random(1,3)..".wav", 80)
    end

    if ( attacker:IsPlayer() ) then
        if ( attacker:Team() == FACTION_REBELS ) then
            attacker:EmitSound("vo/npc/male01/sorry0"..math.random(1,3)..".wav", 80)
        elseif ( attacker:Team() == FACTION_COMBINES ) then
            attacker:EmitSound("npc/metropolice/vo/chuckle.wav", 80)
        end
    end
end

function GM:PlayerHurt(ply)
    if ( ply:Team() == FACTION_REBELS ) then
        ply:EmitSound("vo/npc/male01/pain0"..math.random(1,9)..".wav", 70)
    elseif ( ply:Team() == FACTION_COMBINES ) then
        ply:EmitSound("npc/combine_soldier/pain"..math.random(1,3)..".wav", 70)
    end
end

function GM:PlayerSay(ply, text)
    if ( string.lower(text) == "/teams" ) then
        net.Start("dmChooseTeam")
        net.Send(ply)
        return ""
    elseif ( string.lower(text) == "/classes" ) then
        net.Start("dmChooseClass")
            net.WriteUInt(ply:Team(), 4)
        net.Send(ply)
        return ""
    end
end

function GM:CanPlayerSuicide()
    return false
end

function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if ( attacker:IsPlayer() ) then
        if ( ply:Team() == FACTION_REBELS ) and ( attacker:Team() == FACTION_REBELS ) then
            dmginfo:ScaleDamage(0)
        elseif ( ply:Team() == FACTION_COMBINES ) and ( attacker:Team() == FACTION_COMBINES ) then
            dmginfo:ScaleDamage(0)
        else
            dmginfo:ScaleDamage(1.5)
        end

        if ( attacker:GetActiveWeapon() and attacker:GetActiveWeapon():GetClass() == "weapon_shotgun" ) then
            dmginfo:ScaleDamage(4)
        end

        if ( attacker:GetActiveWeapon() and attacker:GetActiveWeapon():GetClass() == "weapon_ar2" ) then
            dmginfo:ScaleDamage(4)
        end
    end
end

function GM:PlayerNoClip(ply)
    return ply:SteamID() == "STEAM_0:1:1395956"
end

function GM:PlayerSwitchFlashlight()
    return true
end

function GM:PlayerSpray()
    return true
end

function GM:GetGameDescription()
    return "Half-Life 2 Deathmatch"
end

function GM:GetFallDamage(ply, speed)
    return speed / 8
end

concommand.Add("hl2deathmach_changemap", function(ply, cmd, args)
    if ( ply:SteamID() == "STEAM_0:1:1395956" ) then
        if ( args[1] ) then
            for k, v in pairs(player.GetAll()) do
                v:ChatPrint("Server changing level to "..args[1])
                v:ChatPrint("5..")
                timer.Simple(1, function() v:ChatPrint("4..") end)
                timer.Simple(2, function() v:ChatPrint("3..") end)
                timer.Simple(3, function() v:ChatPrint("2..") end)
                timer.Simple(4, function() v:ChatPrint("1..") end)
            end
            timer.Simple(5, function() RunConsoleCommand("changelevel", args[1]) end)
        end
    else
        ply:ChatPrint("You need to be the owner to change maps.")
    end
end)