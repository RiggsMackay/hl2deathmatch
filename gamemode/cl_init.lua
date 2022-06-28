--[[ Include Files ]]--

include("shared.lua")

for value = 8, 128 do
	surface.CreateFont("LiteNetworkFont"..tostring(value), {
		font = "Segoe Ui",
		size = tonumber(value),
		weight = 400,
		antialias = true,
		shadow = false,
	})

	surface.CreateFont("LiteNetworkFont"..tostring(value).."-Light", {
		font = "Segoe Ui Light",
		size = tonumber(value),
		weight = 100,
		antialias = true,
		shadow = false,
	})
end

hook.Add("HUDShouldDraw", "dontDrawIt", function(name)
	for k, v in pairs ({"CHudHealth", "CHudBattery"}) do 
		if name == v then
			return false
		end
	end
end)

local colorModify = {
	["$pp_colour_addr"] = 0,
	["$pp_colour_addg"] = 0,
	["$pp_colour_addb"] = 0,
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 10,
	["$pp_colour_mulr"] = 0,
	["$pp_colour_mulg"] = 0,
	["$pp_colour_mulb"] = 0
}

function GM:RenderScreenspaceEffects()
    if ( lnhl2dm.config.lsd == true ) then
	    DrawColorModify(colorModify)
    end
end

function GM:HUDPaint()
    local ply = LocalPlayer()
    local teamName = team.GetName(ply:Team())

    if ( ply:Alive() ) then
        draw.RoundedBox(100, 10, ScrH() - 110, 500, 100, ColorAlpha(team.GetColor(ply:Team()), 100))

        draw.DrawText("Your Health: "..ply:Health(), "LiteNetworkFont50", 50, ScrH() - 110, color_black)
        draw.DrawText("Your Armor: "..ply:Armor(), "LiteNetworkFont50", 50, ScrH() - 65, color_black)
    end

	local currentTime = os.time()
	local currentDate = os.date("%H:%M:%S - %d/%m/%Y", currentTime)
	
	draw.DrawText(currentDate, "DermaLarge", ScrW() / 2, 50, Color(50, 150, 250), TEXT_ALIGN_CENTER)
end

CreateClientConVar("lnhl2dm_thirdperson", "0", true, false)

local lerpOrigin
local lerpAngles
function GM:CalcView(ply, origin, angles, fov)
    if not ( lerpOrigin ) then
        lerpOrigin = origin
    end

    if not ( lerpAngles ) then
        lerpAngles = angles
    end

    if ((GetConVar("lnhl2dm_thirdperson")) and (GetConVar("lnhl2dm_thirdperson"):GetInt() == 1)) then
        local head = ply:LookupAttachment("eyes")
        head = ply:GetAttachment(head)

        if not (head) then
            lerpOrigin = origin
            lerpAngles = LerpAngle(FrameTime() * 20, lerpAngles, angles)
        
            return {
                origin = lerpOrigin,
                angles = lerpAngles,
                fov = fov + 20,
                drawviewer = false,
            }
        end

        local neworigin = head.Pos - (angles:Forward() * 80) + (angles:Right() * 10) + (angles:Up() * 2)

        lerpOrigin = LerpVector(FrameTime() * 20, lerpOrigin, neworigin)
        lerpAngles = LerpAngle(FrameTime() * 20, lerpAngles, angles)
    
        return {
            origin = lerpOrigin,
            angles = lerpAngles,
            fov = fov + 20,
            drawviewer = true,
        }
    end

    lerpOrigin = origin
    lerpAngles = LerpAngle(FrameTime() * 20, lerpAngles, angles)

    return {
        origin = lerpOrigin,
        angles = lerpAngles,
        fov = fov + 20,
        drawviewer = false,
    }
end

local lerpOrigin
local lerpAngles
function GM:CalcViewModelView(wep, vm, oldPos, oldAng, pos, ang)
    if not ( lerpOrigin ) then
        lerpOrigin = pos
    end

    if not ( lerpAngles ) then
        lerpAngles = ang
    end

    lerpOrigin = pos
    lerpAngles = LerpAngle(FrameTime() * 10, lerpAngles, ang)

    return lerpOrigin, lerpAngles
end