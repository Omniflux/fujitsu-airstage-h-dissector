local p_fujitsuair = Proto("fujitsuair", "Fujitsu AirStage BUS");

local frame_len = 8
local tzsp_encap_type = 255

local opmode = {
    [1] = "FAN",
    [2] = "DRY",
    [3] = "COOL",
    [4] = "HEAT",
    [5] = "AUTO"
}

local fanlevel = {
    [0] = "AUTO",
    [1] = "QUIET",
    [2] = "LOW",
    [3] = "MEDIUM",
    [4] = "HIGH"
}

local packettype = {
    [0] = "STATUS",
    [1] = "ERROR",
    [2] = "FEATURES",
    [3] = "FUNCTION",
    [4] = "PERIODIC" -- Inter indoor unit update? some other type of update? happens every 30 sec. unless a write changes certain things...
}

local addrtype = {
    [0] = "INDOOR UNIT",
    [1] = "CONTROLLER"
}

local f_duplicate = ProtoField.bool     ("fujitsuair.duplicate"       , "Duplicate"       , base.NONE)
local f_dup_frame = ProtoField.framenum ("fujitsuair.duplicate_frame" , "Duplicate Frame" , base.NONE)

-- byte 0
local f_unk0                 = ProtoField.uint8 ("fujitsuair.unknown0"  , "Unknown"     , base.DEC, nil            , 0xC0) -- ALL
local f_srctype              = ProtoField.uint8 ("fujitsuair.srctype"   , "Source Type" , base.DEC, addrtype       , 0x20) -- ALL
local f_unk16                = ProtoField.uint8 ("fujitsuair.unknown16" , "Unknown"     , base.DEC, nil            , 0x10) -- ALL
local f_src                  = ProtoField.uint8 ("fujitsuair.src"       , "Source"      , base.DEC, nil            , 0x0F) -- ALL
-- byte 1
local f_unk1                 = ProtoField.uint8 ("fujitsuair.unknown1"  , "Unknown"     , base.DEC, nil            , 0xC0) -- ALL
local f_dsttype              = ProtoField.uint8 ("fujitsuair.dsttype"   , "Dest Type"   , base.DEC, addrtype       , 0x20) -- ALL
local f_unk18                = ProtoField.uint8 ("fujitsuair.unknown17" , "Unknown"     , base.DEC, nil            , 0x10) -- ALL
local f_dst                  = ProtoField.uint8 ("fujitsuair.dst"       , "Destination" , base.DEC, nil            , 0x0F) -- ALL
-- byte 2
local f_unk2                 = ProtoField.uint8 ("fujitsuair.unknown2"  , "Unknown"     , base.DEC, nil            , 0x80) -- ALL
local f_type                 = ProtoField.uint8 ("fujitsuair.type"      , "Type"        , base.DEC, packettype     , 0x70) -- ALL -- maybe 4 bits? 0xF0?
local f_write                = ProtoField.bool  ("fujitsuair.write"     , "Write"       ,        8, nil            , 0x08) -- ALL -- from indoor unit might mean turn on defrost/standby symbol on controller
local f_unk3                 = ProtoField.uint8 ("fujitsuair.unknown3"  , "Unknown"     , base.DEC, nil            , 0x07) -- ALL
-- byte 3
local f_unk21                = ProtoField.uint8 ("fujitsuair.unknown21"                 , "Unknown"                , base.DEC, nil , 0xE0) -- IU FEATURES
local f_f_mode_auto          = ProtoField.bool  ("fujitsuair.feature.mode_auto"         , "Mode Auto"              ,        8, nil , 0x10) -- IU FEATURES
local f_f_mode_heat          = ProtoField.bool  ("fujitsuair.feature.mode_heat"         , "Mode Heat"              ,        8, nil , 0x08) -- IU FEATURES
local f_f_mode_fan           = ProtoField.bool  ("fujitsuair.feature.mode_fan"          , "Mode Fan"               ,        8, nil , 0x04) -- IU FEATURES
local f_f_mode_dry           = ProtoField.bool  ("fujitsuair.feature.mode_dry"          , "Mode Dry"               ,        8, nil , 0x02) -- IU FEATURES
local f_f_mode_cool          = ProtoField.bool  ("fujitsuair.feature.mode_cool"         , "Mode Cool"              ,        8, nil , 0x01) -- IU FEATURES

local f_unk4                 = ProtoField.uint8 ("fujitsuair.unknown4"                  , "Unknown"                , base.DEC, nil      , 0xFF) -- ERROR, IU FEATURES
local f_error                = ProtoField.bool  ("fujitsuair.error"                     , "Error"                  ,        8, nil      , 0x80) -- STATUS
local f_fan                  = ProtoField.uint8 ("fujitsuair.fan"                       , "Fan"                    , base.DEC, fanlevel , 0x70) -- STATUS
local f_mode                 = ProtoField.uint8 ("fujitsuair.mode"                      , "Mode"                   , base.DEC, opmode   , 0x0E) -- STATUS
local f_enabled              = ProtoField.bool  ("fujitsuair.enabled"                   , "Enabled"                ,        8, nil      , 0x01) -- STATUS
local f_unk13                = ProtoField.uint8 ("fujitsuair.unknown13"                 , "Unknown"                , base.DEC, nil      , 0xFF) -- FUNCTION
-- byte 4
local f_unk5                 = ProtoField.uint8 ("fujitsuair.unknown5"                  , "Unknown"                , base.DEC, nil , 0xE0) -- IU FEATURES
local f_f_fan_quiet          = ProtoField.bool  ("fujitsuair.feature.fan_quiet"         , "Fan Quiet"              ,        8, nil , 0x10) -- IU FEATURES
local f_f_fan_low            = ProtoField.bool  ("fujitsuair.feature.fan_low"           , "Fan Low"                ,        8, nil , 0x08) -- IU FEATURES
local f_f_fan_medium         = ProtoField.bool  ("fujitsuair.feature.fan_medium"        , "Fan Medium"             ,        8, nil , 0x04) -- IU FEATURES
local f_f_fan_high           = ProtoField.bool  ("fujitsuair.feature.fan_high"          , "Fan High"               ,        8, nil , 0x02) -- IU FEATURES
local f_f_fan_auto           = ProtoField.bool  ("fujitsuair.feature.fan_auto"          , "Fan Auto"               ,        8, nil , 0x01) -- IU FEATURES

local f_errcode              = ProtoField.uint8 ("fujitsuair.errcode"                   , "Error Code"             , base.HEX)             -- ERROR
local f_eco                  = ProtoField.bool  ("fujitsuair.eco"                       , "Economy Mode"           ,        8, nil , 0x80) -- STATUS
local f_testrun              = ProtoField.bool  ("fujitsuair.testrun"                   , "Test Run"               ,        8, nil , 0x40) -- STATUS
local f_unk6                 = ProtoField.uint8 ("fujitsuair.unknown6"                  , "Unknown"                , base.DEC, nil , 0x20) -- STATUS -- another bit for temperature? sign bit?
local f_temp                 = ProtoField.uint8 ("fujitsuair.temperature_setpoint"      , "Temperature Setpoint"   , base.DEC, nil , 0x1F) -- STATUS -- celcius 16C (0x10) - 30C (0x1E) valid?
local f_function             = ProtoField.uint8 ("fujitsuair.function"                  , "Function"               , base.DEC, nil , 0xFF) -- FUNCTION -- maybe 7 bits? function #99 (0x63) appears to be maximum
-- byte 5
local f_f_filter_reset       = ProtoField.bool  ("fujitsuair.feature.filter_reset"      , "Filter Reset"           ,        8, nil , 0x80) -- IU FEATURES
local f_f_sensor_switching   = ProtoField.bool  ("fujitsuair.feature.sensor_switching"  , "Sensor Switching"       ,        8, nil , 0x40) -- IU FEATURES
local f_unk17                = ProtoField.uint8 ("fujitsuair.unknown17"                 , "Unknown"                , base.DEC, nil , 0x30) -- IU FEATURES
local f_f_maintenance_button = ProtoField.bool  ("fujitsuair.feature.maintenance_button", "Maintenance Button"     ,        8, nil , 0x08) -- IU FEATURES
local f_f_economy_mode       = ProtoField.bool  ("fujitsuair.feature.economy_mode"      , "Economy Mode"           ,        8, nil , 0x04) -- IU FEATURES
local f_f_swing_horizontal   = ProtoField.bool  ("fujitsuair.feature.swint_horizontal"  , "Swing Horizontal"       ,        8, nil , 0x02) -- IU FEATURES
local f_f_swing_vertical     = ProtoField.bool  ("fujitsuair.feature.swing_vertical"    , "Swing Vertical"         ,        8, nil , 0x01) -- IU FEATURES

local f_unk7                 = ProtoField.uint8 ("fujitsuair.unknown7"                  , "Unknown"                , base.DEC, nil , 0xFF) -- IU STATUS
local f_controller_sensor    = ProtoField.bool  ("fujitsuair.controller_sensor"         , "Use Controller Sensor"  ,        8, nil , 0x80) -- RC STATUS
local f_unk8                 = ProtoField.uint8 ("fujitsuair.unknown8"                  , "Unknown"                , base.DEC, nil , 0x60) -- RC STATUS
local f_swing_horizontal     = ProtoField.bool  ("fujitsuair.swing_horizontal"          , "Swing Horizontal"       ,        8, nil , 0x10) -- RC STATUS -- missing IU STATUS - find with emulator?
local f_set_horizontal_louver= ProtoField.bool  ("fujitsuair.set_horizontal_louver"     , "Set Horizontal Louver"  ,        8, nil , 0x08) -- RC STATUS -- missing IU STATUS - find with emulator?
local f_swing_vertical       = ProtoField.bool  ("fujitsuair.swing_vertical"            , "Swing Vertical"         ,        8, nil , 0x04) -- RC STATUS -- missing IU STATUS - find with emulator?
local f_set_vertical_louver  = ProtoField.bool  ("fujitsuair.set_vertical_louver"       , "Set Vertical Louver"    ,        8, nil , 0x02) -- RC STATUS -- missing IU STATUS - find with emulator?
local f_unk9                 = ProtoField.uint8 ("fujitsuair.unknown9"                  , "Unknown"                , base.DEC, nil , 0x01) -- RC STATUS
local f_funcval              = ProtoField.uint8 ("fujitsuair.function_value"            , "Function Value"         , base.DEC, nil , 0xFF) -- FUNCTION
-- byte 6
local f_unk10                = ProtoField.uint8 ("fujitsuair.unknown10"                 , "Unknown"                , base.DEC, nil , 0xFF) -- IU FEATURES
local f_unk19                = ProtoField.uint8 ("fujitsuair.unknown19"                 , "Unknown"                , base.DEC, nil , 0xFC) -- IU STATUS
local f_seen_secondary_rc    = ProtoField.bool  ("fujitsuair.seen_secondary_rc"         , "Seen Secondary RC"      ,        8, nil , 0x02) -- IU STATUS
local f_seen_primary_rc      = ProtoField.bool  ("fujitsuair.seen_primary_rc"           , "Seen Primary RC"        ,        8, nil , 0x01) -- IU STATUS
local f_unk11                = ProtoField.uint8 ("fujitsuair.unknown11"                 , "Unknown"                , base.DEC, nil , 0x80) -- RC STATUS -- probably sign bit; need to decrease controller temp below 0 to check
local f_controller_temp      = ProtoField.uint8 ("fujitsuair.controller_temp"           , "Controller Temperature" , base.DEC, nil , 0x7E) -- RC STATUS -- max temperature reported by controller is 60C
local f_unk20                = ProtoField.uint8 ("fujitsuair.unknown20"                 , "Unknown"                , base.DEC, nil , 0x01) -- RC STATUS -- 0.5 degrees C?
local f_unk14                = ProtoField.uint8 ("fujitsuair.unknown14"                 , "Unknown"                , base.DEC, nil , 0xFF) -- FUNCTION
-- byte 7
local f_unk12                = ProtoField.uint8 ("fujitsuair.unknown12"                 , "Unknown"                , base.DEC, nil , 0xFF) -- IU STATUS, IU FEATURES
local f_unk22                = ProtoField.uint8 ("fujitsuair.unknown22"                 , "Unknown"                , base.DEC, nil , 0x80) -- RC STATUS
local f_filter_reset         = ProtoField.bool  ("fujitsuair.filter_reset"              , "Filter Reset"           ,        8, nil , 0x40) -- RC STATUS -- Remote writes this bit, then writes this bit clear in next packet -- missing IU STATUS - find with emulator?
local f_maintenance          = ProtoField.bool  ("fujitsuair.maintenance"               , "Maintenance"            ,        8, nil , 0x20) -- RC STATUS -- Remote writes this bit, then writes this bit clear in next packet
local f_unk23                = ProtoField.uint8 ("fujitsuair.unknown23"                 , "Unknown"                , base.DEC, nil , 0x1F) -- RC STATUS
local f_unk15                = ProtoField.uint8 ("fujitsuair.unknown15"                 , "Unknown"                , base.DEC, nil , 0xF0) -- FUNCTION
local f_indoorunit           = ProtoField.uint8 ("fujitsuair.indoorunit"                , "Indoor Unit"            , base.DEC, nil , 0x0F) -- FUNCTION -- maybe ALL?

-- maybe missing powerful, min heat, power diffuser, sleep, coil dry, but may not be available over this protocol, only over built in IR controllers...

p_fujitsuair.fields = {
    f_duplicate, f_dup_frame,
    f_unk0, f_srctype, f_unk16, f_src,                                        -- byte 0
    f_unk1, f_dsttype, f_unk18, f_dst,                                        -- byte 1
    f_unk2, f_type, f_write, f_unk3,                                          -- byte 2
    f_f_mode_auto, f_f_mode_heat, f_f_mode_fan, f_f_mode_dry, f_f_mode_cool,  -- byte 3
    f_unk21, f_unk4, f_error, f_fan, f_mode, f_enabled, f_unk13,              -- byte 3
    f_f_fan_quiet, f_f_fan_low, f_f_fan_medium, f_f_fan_high, f_f_fan_auto,   -- byte 4
    f_unk5, f_unk6, f_errcode, f_eco, f_testrun, f_temp, f_function,          -- byte 4
    f_f_filter_reset, f_f_sensor_switching, f_unk17, f_f_maintenance_button,  -- byte 5
    f_f_economy_mode, f_f_swing_horizontal, f_f_swing_vertical, f_unk7,       -- byte 5
    f_controller_sensor, f_unk8, f_swing_horizontal, f_set_horizontal_louver, -- byte 5
    f_swing_vertical, f_set_vertical_louver, f_unk9, f_funcval,               -- byte 5
    f_unk10, f_unk11, f_controller_temp, f_unk20, f_unk14,                    -- byte 6
    f_unk19, f_seen_secondary_rc, f_seen_primary_rc,                          -- byte 6
    f_unk12, f_unk22, f_filter_reset, f_maintenance, f_unk23,                 -- byte 7
    f_unk15, f_indoorunit                                                     -- byte 7
}

local frame_number = Field.new("frame.number")
local tzsp_encap_f = Field.new("tzsp.encap")
local data_f       = Field.new("data.data")

local track_unique = {}
local track_unique_list = {}
function p_fujitsuair.init()
    track_unique = {}
    track_unique_list = {}
end

function p_fujitsuair.dissector(buf, pinfo, tree)
    -- Unable to attach as chained dissector, process as post dissector
    if Fujitsu_post_dissector then
        local tzsp_encap = { tzsp_encap_f() }
        if (#tzsp_encap == 0 or tzsp_encap[#tzsp_encap].value ~= tzsp_encap_type) then return end

        local data = { data_f() }
        if (#data == 0) then return end
        buf = data[#data].range
    end

    -- Incorrect frame length
    if (buf:len() ~= frame_len) then return end

    -- Extract packet source, dest, and type
    local srctype = bit.rshift(bit.band(buf(0,1):uint(), 0x20), 5)
    local srcaddr = bit.band(buf(0,1):uint(), 0x0F)
    local dsttype = bit.rshift(bit.band(buf(1,1):uint(), 0x20), 5)
    local dstaddr = bit.band(buf(1,1):uint(), 0x0F)
    local ptype   = bit.rshift(bit.band(buf(2,1):uint(), 0x70), 4)

    -- Display information
    pinfo.cols.protocol = p_fujitsuair.name
    pinfo.cols.info = string.format("%s [%s %u → %s %u]", packettype[ptype], addrtype[srctype], srcaddr, addrtype[dsttype], dstaddr)
    local subtree = tree:add(p_fujitsuair, buf(), p_fujitsuair.description)
    subtree:append_text(string.format(", Src: %s %u, Dst: %s %u", addrtype[srctype], srcaddr, addrtype[dsttype], dstaddr))

    -- Track duplicates
    do
        local frame_no = frame_number().value
        local srcdst = buf(0,2):uint()
        local data = buf(2):uint64()

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
    subtree:add(f_srctype , buf(0,1))
    subtree:add(f_unk16   , buf(0,1))
    subtree:add(f_src     , buf(0,1))
    -- byte 1
    subtree:add(f_unk1    , buf(1,1))
    subtree:add(f_dsttype , buf(1,1))
    subtree:add(f_unk18   , buf(1,1))
    subtree:add(f_dst     , buf(1,1))
    -- byte 2
    subtree:add(f_unk2  , buf(2,1))
    subtree:add(f_type  , buf(2,1))
    subtree:add(f_write , buf(2,1))
    subtree:add(f_unk3  , buf(2,1))

    local used = 3

    if ptype == 0 then -- STATUS
        local statustree = subtree:add("", "Status")

        -- byte 3
        statustree:add(f_error   , buf(3,1))
        statustree:add(f_fan     , buf(3,1))
        statustree:add(f_mode    , buf(3,1))
        statustree:add(f_enabled , buf(3,1))
        -- byte 4
        statustree:add(f_eco     , buf(4,1))
        statustree:add(f_testrun , buf(4,1))
        statustree:add(f_unk6    , buf(4,1))
        statustree:add(f_temp    , buf(4,1)):append_text("°C")

        if srctype == 0 then -- INDOOR UNIT
            -- byte 5
            statustree:add(f_unk7              , buf(5,1))
            -- byte 6
            statustree:add(f_unk19             , buf(6,1))
            statustree:add(f_seen_secondary_rc , buf(6,1))
            statustree:add(f_seen_primary_rc   , buf(6,1))
            -- byte 7
            statustree:add(f_unk12             , buf(7,1))
        else -- REMOTE
            -- byte 5
            statustree:add(f_controller_sensor     , buf(5,1))
            statustree:add(f_unk8                  , buf(5,1))
            statustree:add(f_swing_horizontal      , buf(5,1))
            statustree:add(f_set_horizontal_louver , buf(5,1))
            statustree:add(f_swing_vertical        , buf(5,1))
            statustree:add(f_set_vertical_louver   , buf(5,1))
            statustree:add(f_unk9                  , buf(5,1))
            -- byte 6
            statustree:add(f_unk11                 , buf(6,1))
            statustree:add(f_controller_temp       , buf(6,1)):append_text("°C")
            statustree:add(f_unk20                 , buf(6,1))
            -- byte 7
            statustree:add(f_unk22                 , buf(7,1))
            statustree:add(f_filter_reset          , buf(7,1))
            statustree:add(f_maintenance           , buf(7,1))
            statustree:add(f_unk23                 , buf(7,1))
        end

        used = used + 5
    elseif ptype == 1 then -- ERROR
        -- byte 3
        subtree:add(f_unk4    , buf(3,1))
        -- byte 4
        subtree:add(f_errcode , buf(4,1))

        used = used + 2
    elseif ptype == 2 then -- FEATURES
        if srctype == 0 then -- INDOOR UNIT
            local featuretree = subtree:add("", "Supported Features")
            -- byte 3
            featuretree:add(f_unk21                , buf(3,1))
            featuretree:add(f_f_mode_auto          , buf(3,1))
            featuretree:add(f_f_mode_heat          , buf(3,1))
            featuretree:add(f_f_mode_fan           , buf(3,1))
            featuretree:add(f_f_mode_dry           , buf(3,1))
            featuretree:add(f_f_mode_cool          , buf(3,1))
            -- byte 4
            featuretree:add(f_unk5                 , buf(4,1))
            featuretree:add(f_f_fan_quiet          , buf(4,1))
            featuretree:add(f_f_fan_low            , buf(4,1))
            featuretree:add(f_f_fan_medium         , buf(4,1))
            featuretree:add(f_f_fan_high           , buf(4,1))
            featuretree:add(f_f_fan_auto           , buf(4,1))
            -- byte 5
            featuretree:add(f_f_filter_reset       , buf(5,1))
            featuretree:add(f_f_sensor_switching   , buf(5,1))
            featuretree:add(f_unk17                , buf(5,1))
            featuretree:add(f_f_maintenance_button , buf(5,1))
            featuretree:add(f_f_economy_mode       , buf(5,1))
            featuretree:add(f_f_swing_horizontal   , buf(5,1))
            featuretree:add(f_f_swing_vertical     , buf(5,1))
            -- byte 6
            subtree:add(f_unk10  , buf(6,1))
            -- byte 7
            subtree:add(f_unk12  , buf(7,1))
        end
        used = used + 5
    elseif ptype == 3 then -- FUNCTION
        -- byte 3
        subtree:add(f_unk13      , buf(3,1))
        -- byte 4
        subtree:add(f_function   , buf(4,1))
        -- byte 5
        subtree:add(f_funcval    , buf(5,1))
        -- byte 6
        subtree:add(f_unk14      , buf(6,1))
        -- byte 7
        subtree:add(f_unk15      , buf(7,1))
        subtree:add(f_indoorunit , buf(7,1))

        used = used + 5
    elseif ptype == 4 then -- PERIODIC
    end

    if (used < frame_len) then
        Dissector.get("data"):call(buf(used):tvb(), pinfo, tree)
    end
end

local tzsp_encap_d = DissectorTable.get("tzsp.encap")
if tzsp_encap_d then
    tzsp_encap_d:add(tzsp_encap_type, p_fujitsuair)
else
    Fujitsu_post_dissector = true
    register_postdissector(p_fujitsuair)
end