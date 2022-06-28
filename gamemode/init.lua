--[[ Include Files ]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua"); include("shared.lua")
AddCSLuaFile("pmove.lua")

--[[ Serverside Hooks ]]--

function GM:PlayerInitialSpawn(ply)
    ply:SetTeam(table.Random({FACTION_REBELS, FACTION_COMBINES}))
    if ( ply:Team() == FACTION_REBELS ) then
        ply:ChatPrint("You are now in the Rebel Team!")
    elseif ( ply:Team() == FACTION_COMBINES ) then
        ply:ChatPrint("You are now in the Combine Team!")
    else
        ply:ChatPrint("You did not join any Team!")
    end
end

function GM:OnDamagedByExplosion()
	return true
end

function GM:PlayerLoadout(ply)
    local randomChance = math.random(1, 10)

    ply:SetJumpPower(270)
    ply:SetWalkSpeed(400)
    ply:SetRunSpeed(400)
    
    if ( lnhl2dm.config.lsd == true ) then
        ply:SetDSP(11)
    else
        ply:SetDSP(1)
    end

    local playerTeam = lnhl2dm.teams[ply:Team()]
    if ( playerTeam ) then
        ply:SetModel(table.Random(playerTeam.models))
        ply:SetArmor(table.Random({0, 10, 20, 30, 40, 50, 60, 80, 90, 100}))

        for k, v in pairs(playerTeam.weapons) do
            ply:Give(v)
        end
        ply:SetAmmo(180, "pistol")
        ply:SetAmmo(450, "smg1")
    end

    timer.Simple(0, function() ply:SelectWeapon("weapon_smg1") end)

    if ( randomChance == 5 ) then
        ply:Give("weapon_ar2")
        ply:SetAmmo(2, "ar2altfire")
        ply:SetAmmo(300, "ar2")

        ply:ChatPrint("You got a Pulse-Rifle!")
    elseif ( randomChance == 10 ) then
        ply:Give("weapon_shotgun")
        ply:SetAmmo(80, "buckshot")

        ply:ChatPrint("You got a Shotgun!")
    end

    if ( randomChance == math.random(3, 7) ) then
        ply:Give("weapon_frag")
        ply:SetAmmo(3, "SMG1_Grenade")

        ply:ChatPrint("You got Grenades and SMG Grenades.")
    end

    if ( randomChance == 1 ) then
        ply:StripWeapons()
        ply:Give("weapon_rpg")
        ply:Give("weapon_357")
        ply:SetAmmo(10, "RPG_Round")
        ply:SetAmmo(60, "357")

        ply:ChatPrint("You got a Rocket Launcher and a Revolver!")
    end

    --ply:SetColor(255, 255, 255, 100)
    ply:GodEnable()

    timer.Simple(4, function()
        --ply:SetColor(255, 255, 255, 255)
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
    if ( string.lower(text) == "/rebels" ) then
        ply:Spawn()
        ply:SetTeam(FACTION_REBELS)
        hook.Run("PlayerLoadout", ply)
        PrintMessage(HUD_PRINTCENTER, ply:Nick().." changed to the Rebel Team!")
        return ""
    elseif ( string.lower(text) == "/combines" ) then
        ply:Spawn()
        ply:SetTeam(FACTION_COMBINES)
        hook.Run("PlayerLoadout", ply)
        PrintMessage(HUD_PRINTCENTER, ply:Nick().." changed to the Combine Team!")
        return ""
    end
end

function GM:CanPlayerSuicide()
    return false
end

function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)
    if ( dmginfo:GetAttacker():IsPlayer() ) then
        local attacker = dmginfo:GetAttacker()

        if ( ply:Team() == FACTION_REBELS ) and ( attacker:Team() == FACTION_REBELS ) then
            dmginfo:ScaleDamage(0)
        elseif ( ply:Team() == FACTION_COMBINES ) and ( attacker:Team() == FACTION_COMBINES ) then
            dmginfo:ScaleDamage(0)
        else
            dmginfo:ScaleDamage(3)
        end
    end
end

function GM:PlayerSwitchFlashlight()
    return true
end

function GM:PlayerSpray()
    return true
end

function GM:GetGameDescription()
    return "Lite Network Community"
end

concommand.Add("lnhl2dm_changemap", function(ply, cmd, args)
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