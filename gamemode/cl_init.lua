--[[ Include Files ]]--

include("shared.lua")

--[[ Net Messages ]]--

net.Receive("dmChooseTeam", function()
    Derma_Query("dmChooseTeam", "Half-Life 2 Deathmatch", "Rebels", function()
        net.Start("dmBecomeTeam")
            net.WriteUInt(FACTION_REBELS, 4)
        net.SendToServer()
    end, "Combine", function()
        net.Start("dmBecomeTeam")
            net.WriteUInt(FACTION_COMBINES, 4)
        net.SendToServer()
    end)
end)

net.Receive("dmChooseClass", function()
    local teamUInt = net.ReadUInt(4)
    
    if ( teamUInt == FACTION_REBELS ) then
        Derma_Query("dmChooseClass", "Half-Life 2 Deathmatch", "Refugees", function()
            net.Start("dmBecomeClass")
                net.WriteUInt(teamUInt, 4)
                net.WriteUInt(1, 4)
            net.SendToServer()
        end, "Resistance", function()
            Derma_Query("dmChooseClass", "Half-Life 2 Deathmatch", "Rebel Fighter", function()
                net.Start("dmBecomeClass")
                    net.WriteUInt(teamUInt, 4)
                    net.WriteUInt(2, 4)
                net.SendToServer()
            end, "Rebel Shotgunner", function()
                net.Start("dmBecomeClass")
                    net.WriteUInt(teamUInt, 4)
                    net.WriteUInt(3, 4)
                net.SendToServer()
            end, "Rebel Medic", function()
                net.Start("dmBecomeClass")
                    net.WriteUInt(teamUInt, 4)
                    net.WriteUInt(4, 4)
                net.SendToServer()
            end)
        end)
    elseif ( teamUInt == FACTION_COMBINES ) then
        Derma_Query("dmChooseClass", "Half-Life 2 Deathmatch", "Civil Protection Force", function()
            Derma_Query("dmChooseClass", "Half-Life 2 Deathmatch", "Metrocop", function()
                net.Start("dmBecomeClass")
                    net.WriteUInt(teamUInt, 4)
                    net.WriteUInt(1, 4)
                net.SendToServer()
            end, "Metrocop Medic", function()
                net.Start("dmBecomeClass")
                    net.WriteUInt(teamUInt, 4)
                    net.WriteUInt(4, 4)
                net.SendToServer()
            end)
        end, "Overwatch Transhuman Arm", function()
            Derma_Query("dmChooseClass", "Half-Life 2 Deathmatch", "Overwatch Soldier", function()
                net.Start("dmBecomeClass")
                    net.WriteUInt(teamUInt, 4)
                    net.WriteUInt(2, 4)
                net.SendToServer()
            end, "Overwatch Shotgunner", function()
                net.Start("dmBecomeClass")
                    net.WriteUInt(teamUInt, 4)
                    net.WriteUInt(3, 4)
                net.SendToServer()
            end, "Overwatch Medic", function()
                net.Start("dmBecomeClass")
                    net.WriteUInt(teamUInt, 4)
                    net.WriteUInt(4, 4)
                net.SendToServer()
            end)
        end)
    end
end)

--[[ Fonts ]]--

surface.CreateFont("HudFontBig", {
    font = "Verdana",
    size = 60,
})

--[[ Hooks ]]--

local color_green = Color(0, 255, 0, 50)
function GM:PreDrawHalos()
	local teamMates = {}

	for _, ply in ipairs( player.GetAll() ) do
		if ( LocalPlayer():Team() == ply:Team() ) then
			teamMates[#teamMates + 1] = ply
		end
	end

	halo.Add(teamMates, color_green, 2, 2, 5, true, true)
end

--[[ Hud ]]--

hook.Add("HUDShouldDraw", "dontDrawIt", function(name)
	for k, v in pairs ({"CHudHealth", "CHudBattery"}) do 
		if ( name == v ) then
			return false
		end
	end
end)

function GM:HUDPaint()
    local ply = LocalPlayer()
    local teamName = team.GetName(ply:Team())
    local teamColor = team.GetColor(ply:Team())

    if ( ply:Alive() ) then
        draw.RoundedBox(20, 25, ScrH() - 90, 150, 60, ColorAlpha(color_black, 100))
        draw.RoundedBox(20, 225, ScrH() - 90, 150, 60, ColorAlpha(color_black, 100))

        draw.DrawText(ply:Health(), "HudFontBig", 100, ScrH() - 90, teamColor, TEXT_ALIGN_CENTER)
        draw.DrawText(ply:Armor(), "HudFontBig", 300, ScrH() - 90, teamColor, TEXT_ALIGN_CENTER)
    end
end