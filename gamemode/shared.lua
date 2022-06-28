DeriveGamemode("base")

GM.Name = "Lite Network Community Half-Life 2 Deathmatch"
GM.Author = "Riggs Mackay"

lnhl2dm = lnhl2dm or {}
lnhl2dm.config = {
    lsd = false,
}

--[[ Factions ]]--

FACTION_REBELS = 1
FACTION_COMBINES = 2

lnhl2dm.teams = {
    [FACTION_REBELS] = {
        index = 1,
        name = "Resistance",
        color = Color(200, 150, 50),
        weapons = {"weapon_crowbar", "weapon_pistol", "weapon_smg1"},
        models = {
            "models/humans/group03/male_01.mdl",
            "models/humans/group03/male_01.mdl",
            "models/humans/group03/male_02.mdl",
            "models/humans/group03/male_03.mdl",
            "models/humans/group03/male_04.mdl",
            "models/humans/group03/male_05.mdl",
            "models/humans/group03/male_07.mdl",
            "models/humans/group03/male_08.mdl",
            "models/humans/group03/male_09.mdl",
        },
    },
    [FACTION_COMBINES] = {
        index = 2,
        name = "Universal Union",
        color = Color(50, 150, 200),
        weapons = {"weapon_stunstick", "weapon_pistol", "weapon_smg1"},
        models = {
            "models/police.mdl",
            "models/combine_soldier.mdl",
            "models/combine_super_soldier.mdl",
        },
    },
}

function GM:CreateTeams()
    team.SetUp(lnhl2dm.teams[FACTION_REBELS].index, lnhl2dm.teams[FACTION_REBELS].name, lnhl2dm.teams[FACTION_REBELS].color, true)
    team.SetUp(lnhl2dm.teams[FACTION_COMBINES].index, lnhl2dm.teams[FACTION_COMBINES].name, lnhl2dm.teams[FACTION_COMBINES].color, true)
	
	team.SetSpawnPoint(lnhl2dm.teams[FACTION_REBELS].index, {"info_player_rebel", "info_player_deathmatch"})
	team.SetSpawnPoint(lnhl2dm.teams[FACTION_COMBINES].index, {"info_player_combine", "info_player_deathmatch"})
end

local PLAYER = FindMetaTable("Player")
local PM = include("pmove.lua")

JUMP_RELEASED = 0
JUMP_HELD = 1

function PLAYER:SetJumpState(value)
    self:SetNWInt("JumpState", value)
end

function PLAYER:GetJumpState()
    return self:GetNWInt("JumpState")
end

local function IsFlagSet(var, flag)
    return bit.band(var, flag)
end

local function RemoveFlag(var, flag)
    return bit.band(var, bit.bnot(flag))
end

local function AddFlag(var, flag)
    return bit.bor(var, flag)
end

local function GetCurrentGravity()
    return 800
end

local function VectorMA(start, scale, direction)
    local dest = Vector()
	dest.x=start.x+direction.x*scale
	dest.y=start.y+direction.y*scale
    dest.z=start.z+direction.z*scale
    return dest
end

local function StartGravity(ply, vec)
    local ent_gravity
    if ply:GetGravity() > 0 then
        ent_gravity = ply:GetGravity()
    else
        ent_gravity = 1.0
    end
    local vel = Vector(vec)
    vel.z = vel.z - (ent_gravity * GetCurrentGravity() * 0.5 * FrameTime())
    vel.z = vel.z + (ply:GetBaseVelocity().z * FrameTime())
    return vel
end

local function FinishGravity(ply, vec)
    local ent_gravity
    if ply:GetGravity() > 0 then
        ent_gravity = ply:GetGravity()
    else
        ent_gravity = 1.0
    end
    local vel = Vector(vec)
    vel.z = vel.z - (ent_gravity * GetCurrentGravity() * FrameTime() * 0.5)
    return vel
end
--[[
local function AddJumpPower(ply, vel)
    local vel = Vector(vel)
    vel.z = vel.z + ply:GetJumpPower()
    return vel
end
-- Estimates if they jumped 
local function DidPlayerJump(ply, mv)
    local v = ply:GetVelocity()
    local v = StartGravity(ply, v)
    -- dont need to add jump power, it seems to be not needed
    -- local v = AddJumpPower(ply, v)
    local v = FinishGravity(ply, v)
    return v.z == mv:GetVelocity().z
end
]]

local function ClipVelocity(in_, normal, out, overbounce)
    local out = Vector(out)
    local angle = normal.z
    local blocked = 0x00
    if angle > 0 then
        blocked = bit.bor(blocked, 0x01)
    end
    if angle == 0 then
        blocked = bit.bor(blocked, 0x02)
    end

    local backoff = in_:Dot(normal) * overbounce

    local change
    for i=1,3 do
        change = normal[i] * backoff
        out[i] = in_[i] - change
    end

    local adjust = out:Dot(normal)
    if adjust < 0 then
        out = out - (normal * adjust)
    end
    return out
end

local function TryPlayerMove(ent, origin_, velocity)
    local origin = Vector(origin_)
    local velocity = Vector(velocity)
    local original_velocity = Vector(velocity)
    local primal_velocity = Vector(velocity)
    local time_left = FrameTime()
    local numbumps = 4
    local blocked = 0
    local numplanes = 0
    local allFraction = 0
    local MAX_CLIP_PLANES = 5
    local planes = {}

    for bumpcount=0,numbumps-1,1 do
        if velocity:Length() == 0 then
            break
        end

        local endpos = VectorMA(origin, time_left, velocity)

        local pm = util.TraceEntity({start = origin, endpos = endpos, filter = ent}, ent)

        allFraction = allFraction + pm.Fraction

        if pm.AllSolid then
            return Vector(0, 0, 0), origin
        end

        if pm.Fraction > 0 then
            if numbumps > 0 and pm.Fraction == 1 then
                local stuck = util.TraceEntity({start = pm.HitPos, endpos = pm.HitPos, filter = ent}, ent)
                if stuck.StartSolid or stuck.Fraction ~= 1.0 then
                    velocity = Vector(0, 0, 0)
                    break
                end
            end

            origin = Vector(pm.HitPos)
            if origin == nil then
                print("ORIGIN IS NIL")
            end
            original_velocity = Vector(velocity)
            numplanes = 0
        end

        if pm.Fraction == 1 then
            break
        end

        if pm.HitNormal.z > 0.7 then
            blocked = bit.bor(blocked, 1)
        end

        if pm.HitNormal.z == 0 then
            blocked = bit.bor(blocked, 2)
        end

        time_left = time_left - (time_left * pm.Fraction)

        if numplanes >= 5 then
            velocity = Vector(0, 0, 0)
            break
        end

        planes[numplanes] = Vector(pm.HitNormal)
        numplanes = numplanes + 1

        if numplanes == 1 and ent:GetMoveType() == MOVETYPE_WALK and ent:GetGroundEntity() == NULL then
            for i=0,numplanes-1,1 do
                if planes[i].z > 0.7 then
                    new_velocity = ClipVelocity(original_velocity, planes[i], new_velocity, 1)
                    original_velocity = new_velocity
                else
                    new_velocity = ClipVelocity(original_velocity, planes[i], new_velocity, 1.0)
                end
            end

            velocity = new_velocity
            original_velocity = new_velocity
        else
            for i=0,numplanes-1,1 do
                velocity = ClipVelocity(original_velocity, planes[i], velocity, 1)

                for j=0,numplanes-1,1 do
                    if j ~= i then
                        if velocity:Dot(planes[j]) < 0 then
                            break
                        end
                    end
                    if j == numplanes then
                        break
                    end
                end

                if i ~= numplanes then
                    -- ...
                else
                    if numplanes ~= 2 then
                        velocity = Vector(0, 0, 0)
                        break
                    end
                    local dir = planes[0]:Cross(planes[1]):GetNormalized()
                    local d = dir.Dot(velocity)
                    velocity = dir:Mul(d)
                end

                local d = velocity:Dot(primal_velocity)
                if d <= 0 then
                    velocity = Vector(0, 0, 0)
                    break
                end
            end
        end
    end

    if allFraction == 0 then
        velocity = Vector(0, 0, 0)
    end

    return velocity, origin
end

local function VQ3_CmdScale(cmd, playerSpeed)
    local abs = math.abs
    local sqrt = math.sqrt
    local max = abs(cmd:GetForwardMove())
    if abs(cmd:GetSideMove()) > max then
        max = abs(cmd:GetSideMove())
    end
    if abs(cmd:GetUpMove()) > max then
        max = abs(cmd:GetUpMove())
    end
    if not max or max == 0 then
        return 0
    end
    local total = sqrt(cmd:GetForwardMove() * cmd:GetForwardMove() + cmd:GetSideMove() * cmd:GetSideMove() + cmd:GetUpMove() * cmd:GetUpMove())
    local scale = playerSpeed * max / (127 * total)
    return scale
end

local function VQ3_Accelerate(playerVel, wishdir, wishspeed, accel)
    local currentspeed = playerVel:Dot(wishdir)
    local addspeed = wishspeed - currentspeed

    if addspeed <= 0 then
        return playerVel
    end

    local accelspeed = accel * wishspeed * FrameTime()

    if accelspeed > addspeed then
        accelspeed = addspeed
    end

    local x = playerVel.x + (accelspeed * wishdir.x)
    local y = playerVel.y + (accelspeed * wishdir.y)
    local z = playerVel.z + (accelspeed * wishdir.z)
    return Vector(x, y, z)
end

local function VQ3_AirMove(scale, playerVel, mv)
    local angles = mv:GetMoveAngles()
    local forward = angles:Forward()
    local up = angles:Up()
    local right = angles:Right()

    local fmove = mv:GetForwardSpeed()
    local smove = mv:GetSideSpeed()
    --[[
    local angles = cmd:GetViewAngles()
    print(angles)
    local forward = angles:Forward()
    local right = angles:Right()
    local up = angles:Up()
    local fmove = cmd:GetForwardMove()
    local smove = cmd:GetSideMove()
    ]]

    forward.z = 0
    right.z = 0
    forward:Normalize()
    right:Normalize()

    local wishvel = Vector()
    wishvel.x = forward.x * fmove + right.x * smove
    wishvel.y = forward.y * fmove + right.y * smove
    wishvel.z = 0

    local wishdir = Vector(wishvel)
    wishdir:Normalize()
    local wishspeed = wishdir:LengthSqr()
    wishspeed = wishspeed * scale

    local accel = 1
    return VQ3_Accelerate(playerVel, wishdir, wishspeed, accel)
end

hook.Add("PlayerTick", "Bhop", function (ply, mv)
    if not mv:KeyDown(IN_JUMP) then
        ply:SetJumpState(JUMP_RELEASED)
    end
end)



shared_cmdScale = -1

hook.Add("SetupMove", "Bhop", function (ply, mv, cmd)
    ply.oldOnGround = ply:OnGround()
    ply.oldOrigin = mv:GetOrigin()
    ply.cmd = cmd
    ply.cmdScale = VQ3_CmdScale(cmd, ply:GetMaxSpeed())
    shared_cmdScale = ply.cmdScale
    if ply:GetJumpState() == JUMP_HELD then
        -- disable jump
        mv:SetOldButtons(AddFlag(mv:GetOldButtons(), IN_JUMP))
    elseif ply:GetJumpState() == JUMP_RELEASED then
        -- allow jump
        mv:SetOldButtons(RemoveFlag(mv:GetOldButtons(), IN_JUMP))
    end
end)

hook.Add("Move", "Bhop", function (ply, mv)
    if not ply:OnGround() and not PM.HitGround(ply, mv) then
        local v = mv:GetVelocity()
        local v = StartGravity(ply, v)
        local v = VQ3_AirMove(ply.cmdScale, v, mv)
        local v = FinishGravity(ply, v)
        local v, origin = TryPlayerMove(ply, mv:GetOrigin(), v)
        mv:SetVelocity(v)
        mv:SetOrigin(origin)
        return true
    end
end)

hook.Add("FinishMove", "Bhop", function (ply, mv)
    local jumped = false
    if mv:KeyDown(IN_JUMP) and mv:KeyWasDown(IN_JUMP) and ply.oldOnGround and not ply:OnGround() then
        ply:SetJumpState(JUMP_HELD)
        jumped = true
    end
end)

lnhl2dm.anims = lnhl2dm.anims or {}
lnhl2dm.anims.citizen_male = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_RANGE_ATTACK_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_ATTACK_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	ar2 = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_RANGE_ATTACK_THROW
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING
	},
	glide = ACT_GLIDE,
	vehicle = {
		["prop_vehicle_prisoner_pod"] = {"podpose", Vector(-3, 0, 0)},
		["prop_vehicle_jeep"] = {ACT_BUSY_SIT_CHAIR, Vector(14, 0, -14)},
		["prop_vehicle_airboat"] = {ACT_BUSY_SIT_CHAIR, Vector(8, 0, -20)},
		chair = {ACT_BUSY_SIT_CHAIR, Vector(1, 0, -23)}
	},
}

lnhl2dm.anims.citizen_female = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	ar2 = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_RANGE_ATTACK_THROW
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING
	},
	glide = ACT_GLIDE,
	vehicle = lnhl2dm.anims.citizen_male.vehicle
}
lnhl2dm.anims.metrocop = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK_PISTOL, ACT_WALK_AIM_PISTOL},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_PISTOL, ACT_RUN_AIM_PISTOL},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_GESTURE_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	ar2 = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_COMBINE_THROW_GRENADE
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING_GESTURE
	},
	glide = ACT_GLIDE,
	vehicle = {
		chair = {ACT_COVER_PISTOL_LOW, Vector(5, 0, -5)},
		["prop_vehicle_airboat"] = {ACT_COVER_PISTOL_LOW, Vector(10, 0, 0)},
		["prop_vehicle_jeep"] = {ACT_COVER_PISTOL_LOW, Vector(18, -2, 4)},
		["prop_vehicle_prisoner_pod"] = {ACT_IDLE, Vector(-4, -0.5, 0)}
	}
}
lnhl2dm.anims.overwatch = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	ar2 = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING_GESTURE
	},
	glide = ACT_GLIDE,
	vehicle = {
		chair = {ACT_CROUCHIDLE, Vector(5, 0, -5)},
		["prop_vehicle_airboat"] = {ACT_CROUCHIDLE, Vector(10, 0, 0)},
		["prop_vehicle_jeep"] = {ACT_CROUCHIDLE, Vector(18, -2, 4)},
		["prop_vehicle_prisoner_pod"] = {"idle_unarmed", Vector(-4, -0.5, 0)}
	}
}
lnhl2dm.anims.vort = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	ar2 = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "sweep_idle"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_WALK] = {ACT_WALK, "walk_all_holdbroom"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, "walk_all_holdbroom"},
		[ACT_MP_RUN] = {ACT_RUN, "walk_all_holdbroom"},
        [ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	glide = ACT_GLIDE
}
lnhl2dm.anims.player = {
	normal = {
		[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE,
		[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
		[ACT_MP_WALK] = ACT_HL2MP_WALK,
		[ACT_MP_RUN] = ACT_HL2MP_RUN
	},
	passive = {
		[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_PASSIVE,
		[ACT_MP_WALK] = ACT_HL2MP_WALK_PASSIVE,
		[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_PASSIVE,
		[ACT_MP_RUN] = ACT_HL2MP_RUN_PASSIVE
	}
}
lnhl2dm.anims.zombie = {
	[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_ZOMBIE,
	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_ZOMBIE_02,
	[ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE
}
lnhl2dm.anims.fastZombie = {
	[ACT_MP_STAND_IDLE] = ACT_HL2MP_WALK_ZOMBIE,
	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_05,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_ZOMBIE_06,
	[ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE_FAST
}

local translations = translations or {}

function lnhl2dm.anims.SetModelClass(model, class)
	if not lnhl2dm.anims[class] then
		error("'"..tostring(class).."' is not a valid animation class!")
	end
	
	translations[model:lower()] = class
end

-- Micro-optimization since the get class function gets called a lot.
local stringLower = string.lower
local stringFind = string.find

function lnhl2dm.anims.GetModelClass(model)
	model = stringLower(model)
	local class = translations[model]

	class = class or "player"
	
	return class
end

lnhl2dm.anims.SetModelClass("models/humans/group03/male_01.mdl", "citizen_male")
lnhl2dm.anims.SetModelClass("models/humans/group03/male_02.mdl", "citizen_male")
lnhl2dm.anims.SetModelClass("models/humans/group03/male_03.mdl", "citizen_male")
lnhl2dm.anims.SetModelClass("models/humans/group03/male_04.mdl", "citizen_male")
lnhl2dm.anims.SetModelClass("models/humans/group03/male_05.mdl", "citizen_male")
lnhl2dm.anims.SetModelClass("models/humans/group03/male_06.mdl", "citizen_male")
lnhl2dm.anims.SetModelClass("models/humans/group03/male_07.mdl", "citizen_male")
lnhl2dm.anims.SetModelClass("models/humans/group03/male_08.mdl", "citizen_male")
lnhl2dm.anims.SetModelClass("models/humans/group03/male_09.mdl", "citizen_male")
lnhl2dm.anims.SetModelClass("models/police.mdl", "metrocop")
lnhl2dm.anims.SetModelClass("models/combine_soldier.mdl", "overwatch")
lnhl2dm.anims.SetModelClass("models/combine_soldier_prisonguard.mdl", "overwatch")
lnhl2dm.anims.SetModelClass("models/combine_super_soldier.mdl", "overwatch")

local ALWAYS_RAISED = {}
ALWAYS_RAISED["weapon_physgun"] = true
ALWAYS_RAISED["gmod_tool"] = true

local meta = FindMetaTable("Player")

do
	function meta:ForceSequence(sequence, callback, time, noFreeze)
		hook.Run("OnPlayerEnterSequence", self, sequence, callback, time, noFreeze)

		if not sequence then
			net.Start("lnhl2dmSeqSet")
                net.WriteEntity(self)
                net.WriteBool(true)
                net.WriteUInt(0, 16)
			net.Broadcast()
		end

		local sequence = self:LookupSequence(sequence)

		if sequence and sequence > 0 then
			time = time or self:SequenceDuration(sequence)

			self.lnhl2dmSeqCallback = callback
			self.lnhl2dmForceSeq = sequence

			if not noFreeze then
				self:SetMoveType(MOVETYPE_NONE)
			end

			if time > 0 then
				timer.Create("lnhl2dmSeq"..self:EntIndex(), time, 1, function()
					if IsValid(self) then
						self:leaveSequence()
					end
				end)
			end

			net.Start("lnhl2dmSeqSet")
                net.WriteEntity(self)
                net.WriteBool(false)
                net.WriteUInt(sequence, 16)
			net.Broadcast()

			return time
		end

		return false
	end

	function meta:leaveSequence()
		hook.Run("OnPlayerLeaveSequence", self)

		net.Start("lnhl2dmSeqSet")
            net.WriteEntity(self)
            net.WriteBool(true)
            net.WriteUInt(0, 16)
		net.Broadcast()

		self:SetMoveType(MOVETYPE_WALK)
		self.lnhl2dmForceSeq = nil

		if ( self.lnhl2dmSeqCallback ) then
			self:lnhl2dmSeqCallback()
		end
	end

	if ( SERVER ) then
		util.AddNetworkString("lnhl2dmSeqSet")
	end

	if ( CLIENT ) then
		net.Receive("lnhl2dmSeqSet", function()
			local ent = net.ReadEntity()
			local reset = net.ReadBool()
			local sequence = net.ReadUInt(16)

			if IsValid(ent) then
				if reset then
					ent.lnhl2dmForceSeq = nil
					return
				end

				ent:SetCycle(0)
				ent:SetPlaybackRate(1)
				ent.lnhl2dmForceSeq = sequence
			end
		end)
	end
end

HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["rpg"] = "shotgun"
HOLDTYPE_TRANSLATOR["slam"] = "normal"
HOLDTYPE_TRANSLATOR["grenade"] = "grenade"
HOLDTYPE_TRANSLATOR["fist"] = "normal"
HOLDTYPE_TRANSLATOR["melee2"] = "melee"
HOLDTYPE_TRANSLATOR["passive"] = "normal"
HOLDTYPE_TRANSLATOR["knife"] = "melee"
HOLDTYPE_TRANSLATOR["duel"] = "pistol"
HOLDTYPE_TRANSLATOR["camera"] = "smg"
HOLDTYPE_TRANSLATOR["magic"] = "normal"
HOLDTYPE_TRANSLATOR["revolver"] = "pistol"

PLAYER_HOLDTYPE_TRANSLATOR = {}
PLAYER_HOLDTYPE_TRANSLATOR[""] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["fist"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["pistol"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["grenade"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["slam"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee2"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["passive"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["knife"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["duel"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["bugbait"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["pistol"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["revolver"] = "normal"

local getModelClass = lnhl2dm.anims.GetModelClass
local IsValid = IsValid
local string  = string
local type = type

local PLAYER_HOLDTYPE_TRANSLATOR = PLAYER_HOLDTYPE_TRANSLATOR
local HOLDTYPE_TRANSLATOR = HOLDTYPE_TRANSLATOR

function GM:TranslateActivity(ply, act)
	local model = string.lower(ply.GetModel(ply))
	local class = getModelClass(model) or "player"
	local weapon = ply.GetActiveWeapon(ply)

	if class == "player" then
		if ( IsValid(weapon) and ply.Alive(ply) and ply.OnGround(ply) ) then
			local holdType = IsValid(weapon) and (weapon.HoldType or weapon.GetHoldType(weapon)) or "normal"
			if ply.Alive(ply) and ply.OnGround(ply) then
				holdType = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or "passive"
			end

			local animTree = lnhl2dm.anims.player[holdType]

			if animTree and animTree[act] then
				if type(animTree[act]) == "string" then
					ply.CalcSeqOverride = ply.LookupSequence(ply, animTree[act])
					return
				else
					return animTree[act]
				end
			end
		end
		return self.BaseClass.TranslateActivity(self.BaseClass, ply, act)
	end

	local animTree = lnhl2dm.anims[class]

	if animTree then
		local subClass = "normal"
		if ply.InVehicle(ply) then
			local vehicle = ply.GetVehicle(ply)
			local class = vehicle:IsChair() and "chair" or vehicle:GetClass()

			if animTree.vehicle and animTree.vehicle[class] then
				local act = animTree.vehicle[class][1]
				local fixvec = animTree.vehicle[class][2]

				if fixvec then
					ply:SetLocalPos(fixvec)
				end

				if type(act) == "string" then
					ply.CalcSeqOverride = ply.LookupSequence(ply, act)

					return
				else
					return act
				end
			else
				act = animTree.normal[ACT_MP_CROUCH_IDLE][1]

				if type(act) == "string" then
					ply.CalcSeqOverride = ply:LookupSequence(act)
				end
				return
			end
		elseif ply.OnGround(ply) then
			ply.ManipulateBonePosition(ply, 0, vector_origin)

			if IsValid(weapon) then
				subClass = weapon.HoldType or weapon.GetHoldType(weapon)
				subClass = HOLDTYPE_TRANSLATOR[subClass] or subClass
			end

			if animTree[subClass] and animTree[subClass][act] then
				local act2 = animTree[subClass][act][ply:Alive() and 2 or 1]

				if type(act2) == "string" then
					ply.CalcSeqOverride = ply.LookupSequence(ply, act2)
					return
				end
				return act2
			end
		elseif animTree.glide then
			return animTree.glide
		end
	end
end

local vectorAngle = FindMetaTable("Vector").Angle
local normalizeAngle = math.NormalizeAngle

function GM:CalcMainActivity(ply, velocity)
	local eyeAngles = ply.EyeAngles(ply)
	local yaw = vectorAngle(velocity)[2]
	local normalized = normalizeAngle(yaw - eyeAngles[2])

	ply.SetPoseParameter(ply, "move_yaw", normalized)

	if ( CLIENT ) then
		ply.SetIK(ply, false)
	end

	local oldSeqOverride = ply.CalcSeqOverride
	local seqIdeal, seqOverride = self.BaseClass.CalcMainActivity(self.BaseClass, ply, velocity)

	return seqIdeal, ply.lnhl2dmForceSeq or oldSeqOverride or ply.CalcSeqOverride
end

function GM:DoAnimationEvent(ply, event, data)
	local model = ply:GetModel():lower()
	local class = lnhl2dm.anims.GetModelClass(model)

	if class == "player" then
		return self.BaseClass:DoAnimationEvent(ply, event, data)
	else
		local weapon = ply:GetActiveWeapon()

		if IsValid(weapon) then
			local holdType = weapon.HoldType or weapon:GetHoldType()
			holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

			local animation = lnhl2dm.anims[class][holdType]

			if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
				ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)
				return ACT_VM_PRIMARYATTACK
			elseif event == PLAYERANIMEVENT_ATTACK_SECONDARY then
				ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)
				return ACT_VM_SECONDARYATTACK
			elseif event == PLAYERANIMEVENT_RELOAD then
				ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.reload or ACT_GESTURE_RELOAD_SMG1, true)
				return ACT_INVALID
			elseif event == PLAYERANIMEVENT_JUMP then
				ply.m_bJumping = true
				ply.m_bFirstJumpFrame = true
				ply.m_flJumpStartTime = CurTime()
				ply:AnimRestartMainSequence()
				return ACT_INVALID
			elseif event == PLAYERANIMEVENT_CANCEL_RELOAD then
				ply:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)
				return ACT_INVALID
			end
		end
	end
	return ACT_INVALID
end