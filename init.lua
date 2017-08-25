local lib_char = require("solylib.characters")
local lib_unitxt = require("solylib.unitxt")

local _PlayerArray = 0x00A94254
local _PlayerIndex = 0x00A9C4F4
local _PlayerCount = 0x00AAE168
local _Difficulty = 0x00A9CD68
local _Ultimate
local _targetPointerOffset = 0x18
local _targetOffset = 0x108C
local _EntityCount = 0x00AAE164
local _EntityArray = 0x00AAD720
local _ID = 0x1C
local _MonsterUnitxtID = 0x378

local function GetTargetMonster()
    local difficulty = pso.read_u32(_Difficulty)
    _Ultimate = difficulty == 3

    local pIndex = pso.read_u32(_PlayerIndex)
    local pAddr = pso.read_u32(_PlayerArray + 4 * pIndex)

    -- If we don't have address (maybe warping or something)
    -- return the empty list
    if pAddr == 0 then
        return nil
    end

    local targetID = -1
    local targetPointerOffset = pso.read_u32(pAddr + _targetPointerOffset)
    if targetPointerOffset ~= 0 then
        targetID = pso.read_i16(targetPointerOffset + _targetOffset)
    end

    if targetID == -1 then
        return nil
    end

    local _targetPointerOffset = 0x18
    local _targetOffset = 0x108C

    local playerCount = pso.read_u32(_PlayerCount)
    local entityCount = pso.read_u32(_EntityCount)

    local i = 0
    while i < entityCount do
        local monster = pso.read_u32(_EntityArray + 4 * (i + playerCount))
        -- If we got a pointer, then read from it
        if monster ~= 0 then
            local id = pso.read_i16(monster + _ID)
            if id == targetID then
                return monster
            end
        end
        i = i + 1
    end

    return nil
end

local function get_monster_stats(monster)
	local stat_offset = 0x02bc
	local hp_offset = 0x0334
	local resist_offset = 0x02f6
	local cursor = monster + stat_offset + 0
	local stats = {}
	
	stats.address = string.format("%x", monster)
	
	stats.HP =pso.read_u16(monster + hp_offset)
	stats.maxHP = pso.read_u16(cursor)
	cursor = cursor + 8
	stats.maxATP = pso.read_u16(cursor)
	cursor = cursor + 4
	stats.maxEVP = pso.read_u16(cursor)
	cursor = cursor + 2
	stats.maxDFP = pso.read_u16(cursor)
	cursor = cursor + 2
	stats.ATP = pso.read_u16(cursor)
	cursor = cursor + 4
	stats.EVP = pso.read_u16(cursor)
	cursor = cursor + 2
	stats.DFP = pso.read_u16(cursor)
	cursor = cursor + 2
	stats.ATA = pso.read_u16(cursor)
	cursor = cursor + 2
	stats.LCK = pso.read_u16(cursor)
	
	cursor = monster + resist_offset + 0
	stats.EFR = pso.read_u8(cursor)
	cursor = cursor + 2
	stats.ETH = pso.read_u8(cursor)
	cursor = cursor + 2
	stats.EIC = pso.read_u8(cursor)
	cursor = cursor + 2
	stats.EDK = pso.read_u8(cursor)
	cursor = cursor + 2
	stats.ELT = pso.read_u8(cursor)
	cursor = cursor + 2
	
	stats.ESP1 = pso.read_u8(monster + 0x035f)
	stats.ESP2 = pso.read_u8(monster + 0x0342)
	
	return stats
end

local function linear_scale(a, a_min, a_max, b_min, b_max)
	return ((a - a_min) / (a_max - a_min)) * (b_max - b_min) + b_min
end

local function GetMonsterData(monster)
    monster.id = pso.read_u16(monster.address + _ID)
    monster.unitxtID = pso.read_u32(monster.address + _MonsterUnitxtID)

    -- Other stuff
    monster.name = lib_unitxt.GetMonsterName(monster.unitxtID, _Ultimate)
    monster.color = 0xFFFFFFFF
    monster.display = true

	monster.stats = get_monster_stats(monster.address)
	monster.animation_id = pso.read_u8(monster.address + 0x032e)
	
    return monster
end

local function format_stat(name, cur_val, max_val)
	cur_val = cur_val or 0
	if max_val == nil then
		return name .. ": [" .. cur_val .. "]"
	else
		return name .. ": [" .. cur_val .. "/" .. max_val .. "]"
	end
end

local function present()
	imgui.SetNextWindowSize(300, 300)
	imgui.Begin("Monster stats")
	--local target = lib_char.GetPlayer(0)
	local target = GetTargetMonster()
	if target ~= nil then
		local monster = GetMonsterData({address = target})
		imgui.Text(monster.name .. " (" .. string.format("0x%08x", monster.address) .. ")")
		imgui.Text(format_stat("HP", monster.stats.HP, monster.stats.maxHP))
		imgui.Text(format_stat("ATP", monster.stats.ATP, monster.stats.maxATP))
		imgui.Text(format_stat("DFP", monster.stats.DFP, monster.stats.maxDFP))
		imgui.Text(format_stat("ATA", monster.stats.ATA))
		imgui.Text(format_stat("EVP", monster.stats.EVP, monster.stats.maxEVP))
		imgui.Text(format_stat("LCK", monster.stats.LCK))
		
		imgui.Text(format_stat("EFR", monster.stats.EFR))
		imgui.Text(format_stat("EIC", monster.stats.EIC))
		imgui.Text(format_stat("ETH", monster.stats.ETH))
		imgui.Text(format_stat("EDK", monster.stats.EDK))
		imgui.Text(format_stat("ELT", monster.stats.ELT))
		--imgui.Text(format_stat("ESP1", monster.stats.ESP1))
		--imgui.Text(format_stat("ESP2", monster.stats.ESP2))
	end
	imgui.End()
end

local function init()
    return
    {
        name = "Monster stat viewer",
        version = "0.0.0",
        author = "esc",
        description = "wat",
        present = present
    }
end

return
{
    __addon =
    {
        init = init
    }
}