local p_fujitsuair_dmmum = Proto("fujitsuair-dmmum", "Fujitsu AirStage BUS DMMUM");

local frame_len = 8
local tzsp_encap_type = 254

local opmode = {
    [0] = "NO CHANGE",
    [1] = "COOL",
    [2] = "DRY",
    [3] = "HEAT",
    [4] = "FAN",
    [5] = "AUTO"
}

local fanlevel = {
    [0] = "NO CHANGE",
    [1] = "AUTO",
    [2] = "HIGH",
    [3] = "MEDIUM",
    [4] = "LOW",
    [5] = "QUIET"
}

local packettype = {
    [0] = "CONFIG"
}

local addrtype = {
    [1] = "OUTDOOR UNIT",
    [2] = "CONTROLLER",
    [3] = "BRANCH BOX"
}

local tristate = {
    [0] = "NO CHANGE",
    [1] = "False",
    [2] = "True"
}

local f_duplicate = ProtoField.bool     ("fujitsuair-dmmum.duplicate"       , "Duplicate"       , base.NONE)
local f_dup_frame = ProtoField.framenum ("fujitsuair-dmmum.duplicate_frame" , "Duplicate Frame" , base.NONE)

-- byte 0
local f_unk0            = ProtoField.uint8 ("fujitsuair-dmmum.unknown0"             , "Unknown"               , base.DEC, nil     , 0xC0)
local f_src_type        = ProtoField.uint8 ("fujitsuair-dmmum.src_type"             , "Source Type"           , base.DEC, addrtype, 0x30)
local f_unk2            = ProtoField.uint8 ("fujitsuair-dmmum.unknown2"             , "Unknown"               , base.DEC, nil     , 0x0C)
local f_src             = ProtoField.uint8 ("fujitsuair-dmmum.src"                  , "Source"                , base.DEC, nil     , 0x03)
-- byte 1
local f_unk1            = ProtoField.uint8 ("fujitsuair-dmmum.unknown1"             , "Unknown"               , base.DEC, nil     , 0xC0)
local f_token_dst_type  = ProtoField.uint8 ("fujitsuair-dmmum.token_dst_type"       , "Token Destination Type", base.DEC, addrtype, 0x30)
local f_unk3            = ProtoField.uint8 ("fujitsuair-dmmum.unknown3"             , "Unknown"               , base.DEC, nil     , 0x0C)
local f_token_dst       = ProtoField.uint8 ("fujitsuair-dmmum.token_dst"            , "Token Destination"     , base.DEC, nil     , 0x03)
-- byte 2
local f_unk6            = ProtoField.uint8 ("fujitsuair-dmmum.unknown6"             , "Unknown"               , base.DEC, nil , 0xFF)
-- byte 3
local f_ou_unit_exists  = ProtoField.uint8 ("fujitsuair-dmmum.unit_exists"          , "Existing Indoor Units" , base.HEX, nil , 0xFC)
local f_ou_unit_exists6 = ProtoField.bool  ("fujitsuair-dmmum.unit_exists.6"        , "Indoor Unit 6"         ,        8, nil , 0x80)
local f_ou_unit_exists5 = ProtoField.bool  ("fujitsuair-dmmum.unit_exists.5"        , "Indoor Unit 5"         ,        8, nil , 0x40)
local f_ou_unit_exists4 = ProtoField.bool  ("fujitsuair-dmmum.unit_exists.4"        , "Indoor Unit 4"         ,        8, nil , 0x20)
local f_ou_unit_exists3 = ProtoField.bool  ("fujitsuair-dmmum.unit_exists.3"        , "Indoor Unit 3"         ,        8, nil , 0x10)
local f_ou_unit_exists2 = ProtoField.bool  ("fujitsuair-dmmum.unit_exists.2"        , "Indoor Unit 2"         ,        8, nil , 0x08)
local f_ou_unit_exists1 = ProtoField.bool  ("fujitsuair-dmmum.unit_exists.1"        , "Indoor Unit 1"         ,        8, nil , 0x04)
local f_ou_unk8         = ProtoField.uint8 ("fujitsuair-dmmum.unknown8"             , "Unknown"               , base.DEC, nil , 0x03)

local f_rc_units        = ProtoField.uint8 ("fujitsuair-dmmum.unit"                 , "Indoor Units"          , base.HEX, nil , 0xFF)
local f_rc_unit8        = ProtoField.bool  ("fujitsuair-dmmum.unit.8"               , "Indoor Unit 8"         ,        8, nil , 0x80)
local f_rc_unit7        = ProtoField.bool  ("fujitsuair-dmmum.unit.7"               , "Indoor Unit 7"         ,        8, nil , 0x40)
local f_rc_unit6        = ProtoField.bool  ("fujitsuair-dmmum.unit.6"               , "Indoor Unit 6"         ,        8, nil , 0x20)
local f_rc_unit5        = ProtoField.bool  ("fujitsuair-dmmum.unit.5"               , "Indoor Unit 5"         ,        8, nil , 0x10)
local f_rc_unit4        = ProtoField.bool  ("fujitsuair-dmmum.unit.4"               , "Indoor Unit 4"         ,        8, nil , 0x08)
local f_rc_unit3        = ProtoField.bool  ("fujitsuair-dmmum.unit.3"               , "Indoor Unit 3"         ,        8, nil , 0x04)
local f_rc_unit2        = ProtoField.bool  ("fujitsuair-dmmum.unit.2"               , "Indoor Unit 2"         ,        8, nil , 0x02)
local f_rc_unit1        = ProtoField.bool  ("fujitsuair-dmmum.unit.1"               , "Indoor Unit 1"         ,        8, nil , 0x01)
-- byte 4
local f_ou_unk10        = ProtoField.uint8 ("fujitsuair-dmmum.unknown10"            , "Unknown"               , base.DEC, nil     , 0x80)
local f_ou_unit         = ProtoField.uint8 ("fujitsuair-dmmum.unit"                 , "Indoor Unit"           , base.DEC, nil     , 0x70)
local f_ou_unk11        = ProtoField.uint8 ("fujitsuair-dmmum.unknown11"            , "Unknown"               , base.DEC, nil     , 0x0F)

local f_rc_mode         = ProtoField.uint8 ("fujitsuair-dmmum.mode"                 , "Mode"                  , base.DEC, opmode  , 0xE0)
local f_rc_enabled      = ProtoField.uint8 ("fujitsuair-dmmum.enabled"              , "Enabled"               , base.DEC, tristate, 0x18)
local f_rc_unk9         = ProtoField.uint8 ("fujitsuair-dmmum.unknown9"             , "Unknown"               , base.DEC, nil     , 0x07)
-- byte 5
local f_ou_fan          = ProtoField.uint8 ("fujitsuair-dmmum.fan"                  , "Fan"                   , base.DEC, fanlevel, 0xE0)
local f_ou_mode         = ProtoField.uint8 ("fujitsuair-dmmum.mode"                 , "Mode"                  , base.DEC, opmode  , 0x1C)
local f_ou_enabled      = ProtoField.bool  ("fujitsuair-dmmum.enabled"              , "Enabled"               ,        8, nil     , 0x02)
local f_ou_unk13        = ProtoField.uint8 ("fujitsuair-dmmum.unknown13"            , "Unknown"               , base.DEC, nil     , 0x01)

local f_rc_temp         = ProtoField.uint8 ("fujitsuair-dmmum.temperature_setpoint" , "Temperature Setpoint"  , base.DEC, nil     , 0xF8)
local f_rc_fan          = ProtoField.uint8 ("fujitsuair-dmmum.fan"                  , "Fan"                   , base.DEC, fanlevel, 0x07)
-- byte 6
local f_ou_min_heat     = ProtoField.bool  ("fujitsuair-dmmum.minimum_heat"         , "Minimum Heat"          ,        8, nil     , 0x80)
local f_ou_low_noise    = ProtoField.bool  ("fujitsuair-dmmum.low_noise"            , "Low Noise"             ,        8, nil     , 0x40)
local f_ou_eco          = ProtoField.bool  ("fujitsuair-dmmum.eco"                  , "Economy Mode"          ,        8, nil     , 0x20)
local f_ou_temp         = ProtoField.uint8 ("fujitsuair-dmmum.temperature_setpoint" , "Temperature Setpoint"  , base.DEC, nil     , 0x1F)

local f_rc_rc_prohibit  = ProtoField.uint8 ("fujitsuair-dmmum.rc_prohibit"          , "RC Prohibit"           , base.DEC, tristate, 0xC0)
local f_rc_min_heat     = ProtoField.uint8 ("fujitsuair-dmmum.minimum_heat"         , "Minimum Heat"          , base.DEC, tristate, 0x30)
local f_rc_low_noise    = ProtoField.uint8 ("fujitsuair-dmmum.low_noise"            , "Low Noise"             , base.DEC, tristate, 0x0C)
local f_rc_eco          = ProtoField.uint8 ("fujitsuair-dmmum.eco"                  , "Economy Mode"          , base.DEC, tristate, 0x03)
-- byte 7
local f_ou_unk15        = ProtoField.uint8 ("fujitsuair-dmmum.unknown15"            , "Unknown"               , base.DEC, nil , 0xE0)
local f_ou_restricted   = ProtoField.bool  ("fujitsuair-dmmum.restricted"           , "Operation Restricted"  ,        8, nil , 0x10)
local f_ou_error        = ProtoField.bool  ("fujitsuair-dmmum.error"                , "Error"                 ,        8, nil , 0x08)
local f_ou_standby      = ProtoField.bool  ("fujitsuair-dmmum.standby"              , "Standby"               ,        8, nil , 0x04)
local f_ou_testrun      = ProtoField.bool  ("fujitsuair-dmmum.testrun"              , "Test Run"              ,        8, nil , 0x02)
local f_ou_rc_prohibit  = ProtoField.bool  ("fujitsuair-dmmum.rc_prohibit"          , "RC Prohibit"           ,        8, nil , 0x01)

local f_rc_unk7         = ProtoField.uint8 ("fujitsuair-dmmum.unknown7"             , "Unknown"               , base.DEC, nil , 0xFF)

p_fujitsuair_dmmum.fields = {
    f_duplicate, f_dup_frame,
    f_unk0, f_src_type, f_unk2, f_src,                         -- byte 0
    f_unk1, f_token_dst_type, f_unk3, f_token_dst,             -- byte 1
    f_unk6,                                                    -- byte 2
    f_ou_unit_exists, f_ou_unit_exists6, f_ou_unit_exists5,    -- byte 3
    f_ou_unit_exists4, f_ou_unit_exists3, f_ou_unit_exists2,   -- byte 3
    f_ou_unit_exists1, f_ou_unk8, f_rc_units,                  -- byte 3
    f_rc_unit8, f_rc_unit7, f_rc_unit6, f_rc_unit5,            -- byte 3
    f_rc_unit4, f_rc_unit3, f_rc_unit2, f_rc_unit1,            -- byte 3
    f_rc_mode, f_rc_enabled, f_rc_unk9,                        -- byte 4
    f_ou_unit, f_ou_unk10, f_ou_unk11,                         -- byte 4
    f_ou_fan, f_ou_mode, f_ou_enabled, f_ou_unk13,             -- byte 5
    f_rc_temp, f_rc_fan,                                       -- byte 5
    f_ou_min_heat, f_ou_low_noise, f_ou_eco, f_ou_temp,        -- byte 6
    f_rc_rc_prohibit, f_rc_min_heat, f_rc_low_noise, f_rc_eco, -- byte 6
    f_ou_unk15, f_ou_restricted, f_ou_error, f_ou_standby,     -- byte 7
    f_ou_testrun, f_ou_rc_prohibit, f_rc_unk7                  -- byte 7
}

local frame_number = Field.new("frame.number")
local tzsp_encap_f = Field.new("tzsp.encap")
local data_f       = Field.new("data.data")

local track_unique = {}
local track_unique_list = {}
function p_fujitsuair_dmmum.init()
    track_unique = {}
    track_unique_list = {}
end

function p_fujitsuair_dmmum.dissector(buf, pinfo, tree)
    -- Incorrect frame length
    if (buf:len() ~= frame_len) then return end

    -- Extract packet source and dest
    local srctype = bit.rshift(bit.band(buf(0,1):uint(), 0x30), 4)
    local srcaddr = bit.band(buf(0,1):uint(), 0x03)
    local dsttype = bit.rshift(bit.band(buf(1,1):uint(), 0x30), 4)
    local dstaddr = bit.band(buf(1,1):uint(), 0x03)

    -- Display information
    pinfo.cols.protocol = p_fujitsuair_dmmum.name
    pinfo.cols.info = string.format("%s [%s %u → %s %u]", packettype[0], addrtype[srctype], srcaddr, addrtype[dsttype], dstaddr)
    local subtree = tree:add(p_fujitsuair_dmmum, buf(), p_fujitsuair_dmmum.description)
    subtree:append_text(string.format(", Src: %s %u, Dst: %s %u", addrtype[srctype], srcaddr, addrtype[dsttype], dstaddr))

    -- Track duplicates
    do
        local frame_no = frame_number().value
        local srcdst = bit.lshift(buf(0,2):uint(), 16)
        local unit = bit.band(buf(4,1):uint(), 0x70)
        local data = buf(2):uint64()

        srcdst = bit.bor(srcdst, unit)

        local i = 0
        if not track_unique[srcdst] then
            track_unique[srcdst] = {}
            track_unique_list[srcdst] = {}
        end
        for _, f in ipairs(track_unique_list[srcdst]) do
            if (f >= frame_no) then break end
            i = f
        end
        if (track_unique[srcdst][i] == data) then
            subtree:add(f_duplicate, true):set_generated()
            subtree:add(f_dup_frame, i):set_generated()
        elseif (track_unique[srcdst][frame_no] == nil) then
            track_unique[srcdst][frame_no] = data
            track_unique_list[srcdst][#track_unique_list[srcdst] + 1] = frame_no
        end
    end

    -- Dissect the packet

    -- byte 0
    subtree:add(f_unk0    , buf(0,1))
    subtree:add(f_src_type, buf(0,1))
    subtree:add(f_unk2    , buf(0,1))
    subtree:add(f_src     , buf(0,1))
    -- byte 1
    subtree:add(f_unk1          , buf(1,1))
    subtree:add(f_token_dst_type, buf(1,1))
    subtree:add(f_unk3          , buf(1,1))
    subtree:add(f_token_dst     , buf(1,1))
    -- byte 2
    subtree:add(f_unk6    , buf(2,1))
    -- byte 3
    if srctype == 1 or srctype == 3 then -- OUTDOOR UNIT
        -- Decoded with a UTY-DMMUM which is documented to support up to 5 units,
        -- but appears to support 6. UTY-DMMYM and UTY-DMMGM support up to 8 units,
        -- so this may shift, or last two may be out of order...or previous byte...
        local UNITtree = subtree:add(f_ou_unit_exists, buf(3,1))
        UNITtree:add(f_ou_unit_exists6, buf(3,1))
        UNITtree:add(f_ou_unit_exists5, buf(3,1))
        UNITtree:add(f_ou_unit_exists4, buf(3,1))
        UNITtree:add(f_ou_unit_exists3, buf(3,1))
        UNITtree:add(f_ou_unit_exists2, buf(3,1))
        UNITtree:add(f_ou_unit_exists1, buf(3,1))
        subtree:add(f_ou_unk8         , buf(3,1))
    else -- REMOTE
        local UNITtree = subtree:add(f_rc_units, buf(3,1))
        UNITtree:add(f_rc_unit8, buf(3,1))
        UNITtree:add(f_rc_unit7, buf(3,1))
        UNITtree:add(f_rc_unit6, buf(3,1))
        UNITtree:add(f_rc_unit5, buf(3,1))
        UNITtree:add(f_rc_unit4, buf(3,1))
        UNITtree:add(f_rc_unit3, buf(3,1))
        UNITtree:add(f_rc_unit2, buf(3,1))
        UNITtree:add(f_rc_unit1, buf(3,1))
    end
    -- byte 4
    if srctype == 1 or srctype == 3  then -- OUTDOOR UNIT
        subtree:add(f_ou_unk10, buf(4,1)) -- I have seen a marketing image of a controller with 9 units displayed on screen. Could be this bit...
        subtree:add(f_ou_unit , buf(4,1))
        subtree:add(f_ou_unk11, buf(4,1))
    else -- REMOTE
        subtree:add(f_rc_mode   , buf(4,1))
        subtree:add(f_rc_enabled, buf(4,1))
        subtree:add(f_rc_unk9   , buf(4,1))
    end
    -- byte 5
    if srctype == 1 or srctype == 3  then -- OUTDOOR UNIT
        subtree:add(f_ou_fan    , buf(5,1))
        subtree:add(f_ou_mode   , buf(5,1))
        subtree:add(f_ou_enabled, buf(5,1))
        subtree:add(f_ou_unk13  , buf(5,1))
    else -- REMOTE
        subtree:add(f_rc_temp, buf(5,1)):append_text("°C") -- Need to add 4 to this value?
        subtree:add(f_rc_fan , buf(5,1))
    end
    -- byte 6
    if srctype == 1 or srctype == 3  then -- OUTDOOR UNIT
        subtree:add(f_ou_min_heat , buf(6,1))
        subtree:add(f_ou_low_noise, buf(6,1))
        subtree:add(f_ou_eco      , buf(6,1))
        subtree:add(f_ou_temp     , buf(6,1)):append_text("°C") -- Need to add 4 to this value?
    else -- REMOTE
        subtree:add(f_rc_rc_prohibit, buf(6,1))
        subtree:add(f_rc_min_heat   , buf(6,1))
        subtree:add(f_rc_low_noise  , buf(6,1))
        subtree:add(f_rc_eco        , buf(6,1))
    end
    -- byte 7
    if srctype == 1 or srctype == 3  then -- OUTDOOR UNIT
        subtree:add(f_ou_unk15      , buf(7,1))
        subtree:add(f_ou_restricted , buf(7,1))
        subtree:add(f_ou_error      , buf(7,1))
        subtree:add(f_ou_standby    , buf(7,1))
        subtree:add(f_ou_testrun    , buf(7,1))
        subtree:add(f_ou_rc_prohibit, buf(7,1))
    else -- REMOTE
        subtree:add(f_rc_unk7, buf(7,1))
    end

    local used = 8

    if (used < frame_len) then
        Dissector.get("data"):call(buf(used):tvb(), pinfo, tree)
    end
end

local tzsp_encap_d = DissectorTable.get("tzsp.encap")
tzsp_encap_d:add(tzsp_encap_type, p_fujitsuair_dmmum)
