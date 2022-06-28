DeriveGamemode("base")

GM.Name = "Half-Life 2 Deathmatch"
GM.Author = "Riggs.mackay"

hl2deathmach = hl2deathmach or {}

--[[ Teams ]]--

FACTION_REBELS = 1
FACTION_COMBINES = 2

hl2deathmach.teams = {
    [FACTION_REBELS] = {
        index = 1,
        name = "Resistance",
        color = Color(200, 50, 0),
    },
    [FACTION_COMBINES] = {
        index = 2,
        name = "Universal Union",
        color = Color(0, 50, 200),
    },
}

hl2deathmach.classes = {
    [FACTION_REBELS] = {
        {
            index = 1,
            name = "Partisan",
            models = {
                "models/player/group01/male_01.mdl",
                "models/player/group01/male_01.mdl",
                "models/player/group01/male_02.mdl",
                "models/player/group01/male_03.mdl",
                "models/player/group01/male_04.mdl",
                "models/player/group01/male_05.mdl",
                "models/player/group01/male_07.mdl",
                "models/player/group01/male_08.mdl",
                "models/player/group01/male_09.mdl",
            },
            onBecome = function(ply)
                ply:Give("weapon_crowbar")
                ply:Give("weapon_pistol")
                ply:GiveAmmo(150, "pistol")

                ply:SetJumpPower(200)
                ply:SetRunSpeed(140)
                ply:SetWalkSpeed(250)
            end,
        },
        {
            index = 2,
            name = "Rebel Soldier",
            models = {
                "models/player/group03/male_01.mdl",
                "models/player/group03/male_01.mdl",
                "models/player/group03/male_02.mdl",
                "models/player/group03/male_03.mdl",
                "models/player/group03/male_04.mdl",
                "models/player/group03/male_05.mdl",
                "models/player/group03/male_07.mdl",
                "models/player/group03/male_08.mdl",
                "models/player/group03/male_09.mdl",
            },
            onBecome = function(ply)
                ply:Give("weapon_frag")
                ply:Give("weapon_smg1")
                ply:GiveAmmo(500, "smg1")

                ply:SetJumpPower(200)
                ply:SetRunSpeed(140)
                ply:SetWalkSpeed(250)

                ply:SetArmor(100)
            end,
        },
        {
            index = 3,
            name = "Rebel Shotgunner",
            models = {
                "models/player/group03/male_01.mdl",
                "models/player/group03/male_01.mdl",
                "models/player/group03/male_02.mdl",
                "models/player/group03/male_03.mdl",
                "models/player/group03/male_04.mdl",
                "models/player/group03/male_05.mdl",
                "models/player/group03/male_07.mdl",
                "models/player/group03/male_08.mdl",
                "models/player/group03/male_09.mdl",
            },
            onBecome = function(ply)
                ply:Give("weapon_frag")
                ply:Give("weapon_shotgun")
                ply:GiveAmmo(50, "buckshot")

                ply:SetJumpPower(175)
                ply:SetRunSpeed(110)
                ply:SetWalkSpeed(220)

                ply:SetArmor(200)
            end,
        },
        {
            index = 4,
            name = "Rebel Medic",
            models = {
                "models/player/group03m/male_01.mdl",
                "models/player/group03m/male_01.mdl",
                "models/player/group03m/male_02.mdl",
                "models/player/group03m/male_03.mdl",
                "models/player/group03m/male_04.mdl",
                "models/player/group03m/male_05.mdl",
                "models/player/group03m/male_07.mdl",
                "models/player/group03m/male_08.mdl",
                "models/player/group03m/male_09.mdl",
            },
            onBecome = function(ply)
                ply:Give("weapon_stunstick")
                ply:Give("weapon_medkit")
                ply:Give("weapon_pistol")
                ply:GiveAmmo(150, "pistol")

                ply:SetJumpPower(200)
                ply:SetRunSpeed(140)
                ply:SetWalkSpeed(250)
    
                ply:SetHealth(80)
                ply:SetMaxHealth(80)
                ply:SetArmor(0)
                ply:SetMaxArmor(0)
            end,
        },
    },
    [FACTION_COMBINES] = {
        {
            index = 1,
            name = "Metrocop",
            models = {
                "models/player/police.mdl",
            },
            onBecome = function(ply)
                ply:Give("weapon_stunstick")
                ply:Give("weapon_pistol")
                ply:GiveAmmo(150, "pistol")

                ply:SetJumpPower(200)
                ply:SetRunSpeed(140)
                ply:SetWalkSpeed(250)
            end,
        },
        {
            index = 2,
            name = "Overwatch Soldier",
            models = {
                "models/player/combine_soldier.mdl",
            },
            onBecome = function(ply)
                ply:Give("weapon_frag")
                ply:Give("weapon_smg1")
                ply:GiveAmmo(500, "smg1")

                ply:SetJumpPower(200)
                ply:SetRunSpeed(140)
                ply:SetWalkSpeed(250)

                ply:SetArmor(100)
            end,
        },
        {
            index = 3,
            name = "Overwatch Shotgunner",
            models = {
                "models/player/combine_soldier.mdl",
            },
            skin = 1,
            onBecome = function(ply)
                ply:Give("weapon_frag")
                ply:Give("weapon_shotgun")
                ply:GiveAmmo(50, "buckshot")

                ply:SetJumpPower(175)
                ply:SetRunSpeed(110)
                ply:SetWalkSpeed(220)

                ply:SetArmor(200)

                ply:SetSkin(1)
            end,
        },
        {
            index = 4,
            name = "Metrocop Medic",
            models = {
                "models/player/combine_super_soldier.mdl",
            },
            onBecome = function(ply)
                ply:Give("weapon_stunstick")
                ply:Give("weapon_medkit")
                ply:Give("weapon_pistol")
                ply:GiveAmmo(150, "pistol")

                ply:SetJumpPower(200)
                ply:SetRunSpeed(140)
                ply:SetWalkSpeed(250)
    
                ply:SetHealth(80)
                ply:SetMaxHealth(80)
                ply:SetArmor(0)
                ply:SetMaxArmor(0)
            end,
        },
    },
}

function GM:CreateTeams()
    team.SetUp(hl2deathmach.teams[FACTION_REBELS].index, hl2deathmach.teams[FACTION_REBELS].name, hl2deathmach.teams[FACTION_REBELS].color, true)
    team.SetUp(hl2deathmach.teams[FACTION_COMBINES].index, hl2deathmach.teams[FACTION_COMBINES].name, hl2deathmach.teams[FACTION_COMBINES].color, true)
	
	team.SetSpawnPoint(hl2deathmach.teams[FACTION_REBELS].index, {"info_player_rebel", "info_player_deathmatch"})
	team.SetSpawnPoint(hl2deathmach.teams[FACTION_COMBINES].index, {"info_player_combine", "info_player_deathmatch"})
end

--[[ Hooks ]]--

function GM:PlayerFootstep(ply, pos, foot, sound, volume)
    local pitch = math.random(90.0, 110.0)
    if ( ply:GetModel():find("police") ) then
        sound = "npc/metropolice/gear"..math.random(1,6)..".wav"
    elseif ( ply:GetModel():find("combine") ) then
        sound = "npc/combine_soldier/gear"..math.random(1,6)..".wav"
    elseif ( ply:GetModel():find("group0") ) then
        sound = table.Random({
            "npc/footsteps/hardboot_generic1.wav",
            "npc/footsteps/hardboot_generic2.wav",
            "npc/footsteps/hardboot_generic3.wav",
            "npc/footsteps/hardboot_generic4.wav",
            "npc/footsteps/hardboot_generic5.wav",
            "npc/footsteps/hardboot_generic6.wav",
            "npc/footsteps/hardboot_generic8.wav",
        })
    end

    if ( SERVER ) then
        ply:EmitSound(sound, 70, pitch, volume / 2)
    end

    return true
end