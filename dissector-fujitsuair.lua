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
    [0] = "CONFIG",
    [1] = "ERROR",
    [2] = "FEATURES",
    [3] = "FUNCTION",
    [4] = "STATUS",
    [5] = "ZONE CONFIG",
    [6] = "ZONE FUNCTION"
}

local addrtype = {
    [0] = "INDOOR UNIT",
    [1] = "CONTROLLER"
}

local zonegroup = {
    [0] = "NONE",
    [1] = "DAY",
    [2] = "NIGHT",
    [3] = "ALL",
}

local f_duplicate = ProtoField.bool     ("fujitsuair.duplicate"       , "Duplicate"       , base.NONE)
local f_dup_frame = ProtoField.framenum ("fujitsuair.duplicate_frame" , "Duplicate Frame" , base.NONE)

-- byte 0
local f_unk0                 = ProtoField.uint8 ("fujitsuair.unknown0"                  , "Unknown"                , base.DEC, nil        , 0xC0) -- ALL
local f_src_type             = ProtoField.uint8 ("fujitsuair.src_type"                  , "Source Type"            , base.DEC, addrtype   , 0x20) -- ALL
local f_unk16                = ProtoField.uint8 ("fujitsuair.unknown16"                 , "Unknown"                , base.DEC, nil        , 0x10) -- ALL
local f_src                  = ProtoField.uint8 ("fujitsuair.src"                       , "Source"                 , base.DEC, nil        , 0x0F) -- ALL

-- byte 1
local f_unk1                 = ProtoField.uint8 ("fujitsuair.unknown1"                  , "Unknown"                , base.DEC, nil        , 0xC0) -- ALL
local f_token_dst_type       = ProtoField.uint8 ("fujitsuair.token_dst_type"            , "Token Destination Type" , base.DEC, addrtype   , 0x20) -- ALL
local f_unk18                = ProtoField.uint8 ("fujitsuair.unknown17"                 , "Unknown"                , base.DEC, nil        , 0x10) -- ALL
local f_token_dst            = ProtoField.uint8 ("fujitsuair.token_dst"                 , "Token Destination"      , base.DEC, nil        , 0x0F) -- ALL

-- byte 2
local f_unk2                 = ProtoField.uint8 ("fujitsuair.unknown2"                  , "Unknown"                , base.DEC, nil        , 0x80) -- ALL -- not part of type field
local f_type                 = ProtoField.uint8 ("fujitsuair.type"                      , "Type"                   , base.DEC, packettype , 0x70) -- ALL
local f_standby              = ProtoField.bool  ("fujitsuair.standby"                   , "Standby"                ,        8, nil        , 0x08) -- IU CONFIG
local f_write                = ProtoField.bool  ("fujitsuair.write"                     , "Write"                  ,        8, nil        , 0x08) -- RC CONFIG, RC FUNCTION, RC ZONE CONFIG
local f_unk3                 = ProtoField.uint8 ("fujitsuair.unknown3"                  , "Unknown"                , base.DEC, nil        , 0x07) -- CONFIG, RC FUNCTION -- RC does not consume CONFIG packets if 0x01 or 0x02 are set
local f_unk26                = ProtoField.uint8 ("fujitsuair.unknown26"                 , "Unknown"                , base.DEC, nil        , 0x0F) -- IU STATUS, RC FEATURES, RC ERROR
local f_unk20                = ProtoField.uint8 ("fujitsuair.unknown20"                 , "Unknown"                , base.DEC, nil        , 0x07) -- IU ZONE FUNCTION
local f_zone_common          = ProtoField.bool  ("fujitsuair.zone_common"               , "Zone Common"            ,        8, nil        , 0x08) -- IU ZONE FUNCTION

-- byte 3
local f_unk21                = ProtoField.uint8 ("fujitsuair.unknown21"                 , "Unknown"                , base.DEC, nil        , 0xE0) -- IU FEATURES
local f_f_mode_auto          = ProtoField.bool  ("fujitsuair.feature.mode_auto"         , "Mode Auto"              ,        8, nil        , 0x10) -- IU FEATURES
local f_f_mode_heat          = ProtoField.bool  ("fujitsuair.feature.mode_heat"         , "Mode Heat"              ,        8, nil        , 0x08) -- IU FEATURES
local f_f_mode_fan           = ProtoField.bool  ("fujitsuair.feature.mode_fan"          , "Mode Fan"               ,        8, nil        , 0x04) -- IU FEATURES
local f_f_mode_dry           = ProtoField.bool  ("fujitsuair.feature.mode_dry"          , "Mode Dry"               ,        8, nil        , 0x02) -- IU FEATURES
local f_f_mode_cool          = ProtoField.bool  ("fujitsuair.feature.mode_cool"         , "Mode Cool"              ,        8, nil        , 0x01) -- IU FEATURES

local f_unk4                 = ProtoField.uint8 ("fujitsuair.unknown4"                  , "Unknown"                , base.DEC, nil      , 0xFF) -- ERROR
local f_error                = ProtoField.bool  ("fujitsuair.error"                     , "Error"                  ,        8, nil      , 0x80) -- CONFIG
local f_fan                  = ProtoField.uint8 ("fujitsuair.fan"                       , "Fan"                    , base.DEC, fanlevel , 0x70) -- CONFIG
local f_mode                 = ProtoField.uint8 ("fujitsuair.mode"                      , "Mode"                   , base.DEC, opmode   , 0x0E) -- CONFIG
local f_enabled              = ProtoField.bool  ("fujitsuair.enabled"                   , "Enabled"                ,        8, nil      , 0x01) -- CONFIG
local f_unk13                = ProtoField.uint8 ("fujitsuair.unknown13"                 , "Unknown"                , base.DEC, nil      , 0xFF) -- FUNCTION
local f_unk27                = ProtoField.bool  ("fujitsuair.unknown27"                 , "Unknown"                ,        8, nil      , 0x80) -- IU STATUS -- false in first after power on, true thereafter
local f_unk28                = ProtoField.uint8 ("fujitsuair.unknown28"                 , "Unknown"                , base.DEC, nil      , 0x7F) -- IU STATUS
local f_zones                = ProtoField.uint8 ("fujitsuair.zones"                     , "Active Zones"           , base.HEX, nil      , 0xFF) -- ZONE CONFIG / IU ZONE FUNCTION
local f_zone8                = ProtoField.bool  ("fujitsuair.zones.8"                   , "Zone 8"                 ,        8, nil      , 0x80) -- ZONE CONFIG / IU ZONE FUNCTION
local f_zone7                = ProtoField.bool  ("fujitsuair.zones.7"                   , "Zone 7"                 ,        8, nil      , 0x40) -- ZONE CONFIG / IU ZONE FUNCTION
local f_zone6                = ProtoField.bool  ("fujitsuair.zones.6"                   , "Zone 6"                 ,        8, nil      , 0x20) -- ZONE CONFIG / IU ZONE FUNCTION
local f_zone5                = ProtoField.bool  ("fujitsuair.zones.5"                   , "Zone 5"                 ,        8, nil      , 0x10) -- ZONE CONFIG / IU ZONE FUNCTION
local f_zone4                = ProtoField.bool  ("fujitsuair.zones.4"                   , "Zone 4"                 ,        8, nil      , 0x08) -- ZONE CONFIG / IU ZONE FUNCTION
local f_zone3                = ProtoField.bool  ("fujitsuair.zones.3"                   , "Zone 3"                 ,        8, nil      , 0x04) -- ZONE CONFIG / IU ZONE FUNCTION
local f_zone2                = ProtoField.bool  ("fujitsuair.zones.2"                   , "Zone 2"                 ,        8, nil      , 0x02) -- ZONE CONFIG / IU ZONE FUNCTION
local f_zone1                = ProtoField.bool  ("fujitsuair.zones.1"                   , "Zone 1"                 ,        8, nil      , 0x01) -- ZONE CONFIG / IU ZONE FUNCTION
local f_unk36                = ProtoField.uint8 ("fujitsuair.unknown36"                 , "Unknown"                , base.HEX, nil      , 0xFF) -- ZONE FEATURE

-- byte 4
local f_unk5                 = ProtoField.uint8 ("fujitsuair.unknown5"                  , "Unknown"                , base.DEC, nil , 0xE0) -- IU FEATURES
local f_f_fan_quiet          = ProtoField.bool  ("fujitsuair.feature.fan_quiet"         , "Fan Quiet"              ,        8, nil , 0x10) -- IU FEATURES
local f_f_fan_low            = ProtoField.bool  ("fujitsuair.feature.fan_low"           , "Fan Low"                ,        8, nil , 0x08) -- IU FEATURES
local f_f_fan_medium         = ProtoField.bool  ("fujitsuair.feature.fan_medium"        , "Fan Medium"             ,        8, nil , 0x04) -- IU FEATURES
local f_f_fan_high           = ProtoField.bool  ("fujitsuair.feature.fan_high"          , "Fan High"               ,        8, nil , 0x02) -- IU FEATURES
local f_f_fan_auto           = ProtoField.bool  ("fujitsuair.feature.fan_auto"          , "Fan Auto"               ,        8, nil , 0x01) -- IU FEATURES

local f_errcode              = ProtoField.uint8 ("fujitsuair.errcode"                   , "Error Code"             , base.HEX)             -- IU ERROR
local f_eco                  = ProtoField.bool  ("fujitsuair.eco"                       , "Economy Mode"           ,        8, nil , 0x80) -- CONFIG
local f_testrun              = ProtoField.bool  ("fujitsuair.testrun"                   , "Test Run"               ,        8, nil , 0x40) -- CONFIG
local f_unk6                 = ProtoField.uint8 ("fujitsuair.unknown6"                  , "Unknown"                , base.DEC, nil , 0x20) -- CONFIG -- another bit for temperature? sign bit?
local f_temp                 = ProtoField.uint8 ("fujitsuair.temperature_setpoint"      , "Temperature Setpoint"   , bit.bor(base.DEC, base.UNIT_STRING), {"°C"}, 0x1F) -- CONFIG -- celcius 16C (0x10) - 30C (0x1E) valid?
local f_function             = ProtoField.uint8 ("fujitsuair.function"                  , "Function"               , base.DEC, nil , 0xFF) -- FUNCTION -- maybe 7 bits? function #99 (0x63) appears to be maximum
local f_unk29                = ProtoField.uint8 ("fujitsuair.unknown29"                 , "Unknown"                , base.DEC, nil , 0xFF) -- IU STATUS -- seen values 0,1,2,3, 6,7,8,9
local f_unk33                = ProtoField.bool  ("fujitsuair.unknown33"                 , "Unknown"                ,        8, nil , 0x80) -- ZONE CONFIG -- seen bit set when source is indoor unit, otherwise 0
local f_unk32                = ProtoField.uint8 ("fujitsuair.unknown32"                 , "Unknown"                , base.DEC, nil , 0x60) -- ZONE CONFIG
local f_unk37                = ProtoField.uint8 ("fujitsuair.unknown37"                 , "Unknown"                , base.DEC, nil , 0x07) -- ZONE CONFIG
local f_zone_groups          = ProtoField.uint8 ("fujitsuair.zone_groups"               , "Active Zone Groups"     , base.DEC, zonegroup , 0x18) -- ZONE CONFIG -- Group 'all' enables both night + day
local f_zone_group_night     = ProtoField.bool  ("fujitsuair.zone_groups.night"         , "Zone Group - Night"     ,        8, nil , 0x10) -- ZONE CONFIG
local f_zone_group_day       = ProtoField.bool  ("fujitsuair.zone_groups.day"           , "Zone Group - Day"       ,        8, nil , 0x08) -- ZONE CONFIG
local f_unk34                = ProtoField.uint8 ("fujitsuair.unknown34"                 , "Unknown"                , base.HEX, nil , 0xFF) -- ZONE FEATURE


-- byte 5
local f_f_filter_timer       = ProtoField.bool  ("fujitsuair.feature.filter_timer"      , "Filter Timer"           ,        8, nil , 0x80) -- IU FEATURES
local f_f_sensor_switching   = ProtoField.bool  ("fujitsuair.feature.sensor_switching"  , "Sensor Switching"       ,        8, nil , 0x40) -- IU FEATURES
local f_unk17                = ProtoField.uint8 ("fujitsuair.unknown17"                 , "Unknown"                , base.DEC, nil , 0x30) -- IU FEATURES
local f_f_maintenance_button = ProtoField.bool  ("fujitsuair.feature.maintenance_button", "Maintenance Button"     ,        8, nil , 0x08) -- IU FEATURES
local f_f_economy_mode       = ProtoField.bool  ("fujitsuair.feature.economy_mode"      , "Economy Mode"           ,        8, nil , 0x04) -- IU FEATURES
local f_f_swing_horizontal   = ProtoField.bool  ("fujitsuair.feature.horizontal_louvers", "Horizontal Louvers"     ,        8, nil , 0x02) -- IU FEATURES
local f_f_swing_vertical     = ProtoField.bool  ("fujitsuair.feature.vertical_louvers"  , "Vertical Louvers"       ,        8, nil , 0x01) -- IU FEATURES

local f_unk7                 = ProtoField.uint8 ("fujitsuair.unknown7"                  , "Unknown"                , base.DEC, nil , 0xE0) -- IU CONFIG
local f_controller_sensor    = ProtoField.bool  ("fujitsuair.controller_sensor"         , "Use Controller Sensor"  ,        8, nil , 0x80) -- RC CONFIG
local f_unk8                 = ProtoField.uint8 ("fujitsuair.unknown8"                  , "Unknown"                , base.DEC, nil , 0x60) -- RC CONFIG
local f_swing_horizontal     = ProtoField.bool  ("fujitsuair.swing_horizontal"          , "Swing Horizontal"       ,        8, nil , 0x10) -- CONFIG
local f_unk24                = ProtoField.uint8 ("fujitsuair.unknown24"                 , "Unknown"                , base.DEC, nil , 0x08) -- IU CONFIG
local f_set_horizontal_louver= ProtoField.bool  ("fujitsuair.set_horizontal_louver"     , "Set Horizontal Louver"  ,        8, nil , 0x08) -- RC CONFIG
local f_swing_vertical       = ProtoField.bool  ("fujitsuair.swing_vertical"            , "Swing Vertical"         ,        8, nil , 0x04) -- CONFIG
local f_unk25                = ProtoField.uint8 ("fujitsuair.unknown25"                 , "Unknown"                , base.DEC, nil , 0x03) -- IU CONFIG
local f_set_vertical_louver  = ProtoField.bool  ("fujitsuair.set_vertical_louver"       , "Set Vertical Louver"    ,        8, nil , 0x02) -- RC CONFIG
local f_unk9                 = ProtoField.uint8 ("fujitsuair.unknown9"                  , "Unknown"                , base.DEC, nil , 0x01) -- RC CONFIG
local f_funcval              = ProtoField.uint8 ("fujitsuair.function_value"            , "Function Value"         , base.DEC, nil , 0xFF) -- FUNCTION
local f_unk30                = ProtoField.uint8 ("fujitsuair.unknown30"                 , "Unknown"                , base.DEC, nil , 0xFF) -- IU STATUS -- seen values 0x00, 0x16

local f_zone_grouping_1_4    = ProtoField.uint8 ("fujitsuair.zone_grouping_1_4"         , "Zone Group Assoc 1-4"   , base.HEX,       nil , 0xFF) -- ZONE CONFIG
local f_zone4_groups         = ProtoField.uint8 ("fujitsuair.zone_grouping_1_4.4"       , "Zone 4 Groups"          , base.DEC, zonegroup , 0xC0) -- ZONE CONFIG
local f_zone4_night          = ProtoField.bool  ("fujitsuair.zone_grouping_1_4.4.night" , "Zone 4 - Night"         ,        8,       nil , 0x80) -- ZONE CONFIG
local f_zone4_day            = ProtoField.bool  ("fujitsuair.zone_grouping_1_4.4.day"   , "Zone 4 - Day"           ,        8,       nil , 0x40) -- ZONE CONFIG
local f_zone3_groups         = ProtoField.uint8 ("fujitsuair.zone_grouping_1_4.3"       , "Zone 3 Groups"          , base.DEC, zonegroup , 0x30) -- ZONE CONFIG
local f_zone3_night          = ProtoField.bool  ("fujitsuair.zone_grouping_1_4.3.night" , "Zone 3 - Night"         ,        8,       nil , 0x20) -- ZONE CONFIG
local f_zone3_day            = ProtoField.bool  ("fujitsuair.zone_grouping_1_4.3.day"   , "Zone 3 - Day"           ,        8,       nil , 0x10) -- ZONE CONFIG
local f_zone2_groups         = ProtoField.uint8 ("fujitsuair.zone_grouping_1_4.2"       , "Zone 2 Groups"          , base.DEC, zonegroup , 0x0C) -- ZONE CONFIG
local f_zone2_night          = ProtoField.bool  ("fujitsuair.zone_grouping_1_4.2.night" , "Zone 2 - Night"         ,        8,       nil , 0x08) -- ZONE CONFIG
local f_zone2_day            = ProtoField.bool  ("fujitsuair.zone_grouping_1_4.2.day"   , "Zone 2 - Day"           ,        8,       nil , 0x04) -- ZONE CONFIG
local f_zone1_groups         = ProtoField.uint8 ("fujitsuair.zone_grouping_1_4.1"       , "Zone 1 Groups"          , base.DEC, zonegroup , 0x03) -- ZONE CONFIG
local f_zone1_night          = ProtoField.bool  ("fujitsuair.zone_grouping_1_4.1.night" , "Zone 1 - Night"         ,        8,       nil , 0x02) -- ZONE CONFIG
local f_zone1_day            = ProtoField.bool  ("fujitsuair.zone_grouping_1_4.1.day"   , "Zone 1 - Day"           ,        8,       nil , 0x01) -- ZONE CONFIG

local f_zone_func_write      = ProtoField.bool  ("fujitsuair.zone_func_write"           , "Zone Function Write"    ,        8, nil , 0x80) -- ZONE FUNCTION
local f_unk38                = ProtoField.uint8 ("fujitsuair.unknown38"                 , "Unknown"                , base.DEC, nil , 0x7F) -- ZONE FUNCTION


-- byte 6
local f_unk10                = ProtoField.uint8 ("fujitsuair.unknown10"                 , "Unknown"                , base.DEC, nil , 0xFF) -- IU FEATURES
local f_lock_filter_reset    = ProtoField.bool  ("fujitsuair.lock.filter_reset"         , "Lock Filter Reset"      ,        8, nil , 0x80) -- IU CONFIG
local f_lock_on_off          = ProtoField.bool  ("fujitsuair.lock.on_off"               , "Lock On/Off"            ,        8, nil , 0x40) -- IU CONFIG
local f_lock_mode            = ProtoField.bool  ("fujitsuair.lock.mode"                 , "Lock Mode"              ,        8, nil , 0x20) -- IU CONFIG
local f_lock_unknown         = ProtoField.bool  ("fujitsuair.lock.unknown"              , "Lock Unknown"           ,        8, nil , 0x10) -- IU CONFIG
local f_lock_timer           = ProtoField.bool  ("fujitsuair.lock.timer"                , "Lock Timer"             ,        8, nil , 0x08) -- IU CONFIG
local f_lock_all             = ProtoField.bool  ("fujitsuair.lock.all"                  , "Lock All"               ,        8, nil , 0x04) -- IU CONFIG
local f_seen_secondary_rc    = ProtoField.bool  ("fujitsuair.seen_secondary_rc"         , "Seen Secondary RC"      ,        8, nil , 0x02) -- IU CONFIG
local f_seen_primary_rc      = ProtoField.bool  ("fujitsuair.seen_primary_rc"           , "Seen Primary RC"        ,        8, nil , 0x01) -- IU CONFIG

local f_unk11                = ProtoField.uint8 ("fujitsuair.unknown11"                 , "Unknown"                , base.DEC, nil , 0x80) -- RC CONFIG -- sign bit? not used by controllers I have...
local f_controller_temp      = ProtoField.float ("fujitsuair.controller_temp"           , "Controller Temperature" ,           {"°C"}    ) -- RC CONFIG -- temperature range reported by controller is 0C - 60C in 0.5 degree increments
local f_unk14                = ProtoField.uint8 ("fujitsuair.unknown14"                 , "Unknown"                , base.DEC, nil , 0xFF) -- FUNCTION
local f_unk31                = ProtoField.uint8 ("fujitsuair.unknown31"                 , "Unknown"                , base.DEC, nil , 0xFF) -- IU STATUS -- seen values 0x00, 0x01 -- 0x01 heat running?

local f_zone_grouping_5_8    = ProtoField.uint8 ("fujitsuair.zone_grouping_5_8"         , "Zone Group Assoc 5-8"   , base.HEX,       nil , 0xFF) -- ZONE CONFIG
local f_zone8_groups         = ProtoField.uint8 ("fujitsuair.zone_grouping_5_8.8"       , "Zone 8 Groups"          , base.DEC, zonegroup , 0xC0) -- ZONE CONFIG
local f_zone8_night          = ProtoField.bool  ("fujitsuair.zone_grouping_5_8.8.night" , "Zone 8 - Night"         ,        8,       nil , 0x80) -- ZONE CONFIG
local f_zone8_day            = ProtoField.bool  ("fujitsuair.zone_grouping_5_8.8.day"   , "Zone 8 - Day"           ,        8,       nil , 0x40) -- ZONE CONFIG
local f_zone7_groups         = ProtoField.uint8 ("fujitsuair.zone_grouping_5_8.7"       , "Zone 7 Groups"          , base.DEC, zonegroup , 0x30) -- ZONE CONFIG
local f_zone7_night          = ProtoField.bool  ("fujitsuair.zone_grouping_5_8.7.night" , "Zone 7 - Night"         ,        8,       nil , 0x20) -- ZONE CONFIG
local f_zone7_day            = ProtoField.bool  ("fujitsuair.zone_grouping_5_8.7.day"   , "Zone 7 - Day"           ,        8,       nil , 0x10) -- ZONE CONFIG
local f_zone6_groups         = ProtoField.uint8 ("fujitsuair.zone_grouping_5_8.6"       , "Zone 6 Groups"          , base.DEC, zonegroup , 0x0C) -- ZONE CONFIG
local f_zone6_night          = ProtoField.bool  ("fujitsuair.zone_grouping_5_8.6.night" , "Zone 6 - Night"         ,        8,       nil , 0x08) -- ZONE CONFIG
local f_zone6_day            = ProtoField.bool  ("fujitsuair.zone_grouping_5_8.6.day"   , "Zone 6 - Day"           ,        8,       nil , 0x04) -- ZONE CONFIG
local f_zone5_groups         = ProtoField.uint8 ("fujitsuair.zone_grouping_5_8.5"       , "Zone 5 Groups"          , base.DEC, zonegroup , 0x03) -- ZONE CONFIG
local f_zone5_night          = ProtoField.bool  ("fujitsuair.zone_grouping_5_8.5.night" , "Zone 5 - Night"         ,        8,       nil , 0x02) -- ZONE CONFIG
local f_zone5_day            = ProtoField.bool  ("fujitsuair.zone_grouping_5_8.5.day"   , "Zone 5 - Day"           ,        8,       nil , 0x01) -- ZONE CONFIG

local f_zone_func_location   = ProtoField.uint8 ("fujitsuair.zone_func_location"        , "Zone Function Location" , base.HEX, nil , 0xFF) -- ZONE FUNCTION -- 0x0B thru 0x13 show the outlet count for zones 1-8 + common

-- byte 7
local f_unk12                = ProtoField.uint8 ("fujitsuair.unknown12"                 , "Unknown"                , base.DEC, nil , 0xFF) -- IU FEATURES
local f_unk22                = ProtoField.uint8 ("fujitsuair.unknown22"                 , "Unknown"                , base.DEC, nil , 0x80) -- CONFIG
local f_filter_timer         = ProtoField.bool  ("fujitsuair.filter_timer"              , "Filter Timer"           ,        8, nil , 0x40) -- IU CONFIG
local f_reset_filter_timer   = ProtoField.bool  ("fujitsuair.reset_filter_timer"        , "Reset Filter Timer"     ,        8, nil , 0x40) -- RC CONFIG -- Remote writes this bit, then writes this bit clear in next packet
local f_maintenance          = ProtoField.bool  ("fujitsuair.maintenance"               , "Maintenance"            ,        8, nil , 0x20) -- RC CONFIG -- Remote writes this bit, then writes this bit clear in next packet
local f_unk19                = ProtoField.uint8 ("fujitsuair.unknown19"                 , "Unknown"                , base.DEC, nil , 0x3F) -- IU CONFIG
local f_unk23                = ProtoField.uint8 ("fujitsuair.unknown23"                 , "Unknown"                , base.DEC, nil , 0x1F) -- RC CONFIG
local f_unk15                = ProtoField.uint8 ("fujitsuair.unknown15"                 , "Unknown"                , base.DEC, nil , 0xF0) -- FUNCTION
local f_indoorunit           = ProtoField.uint8 ("fujitsuair.indoorunit"                , "Indoor Unit"            , base.DEC, nil , 0x0F) -- FUNCTION -- maybe ALL?
local f_unk35                = ProtoField.uint8 ("fujitsuair.unknown35"                 , "Unknown"                , base.DEC, nil , 0xFF) -- RC ZONE CONFIG
local f_zone_func_value      = ProtoField.uint8 ("fujitsuair.zone_func_value"           , "Zone Function Value"    , base.HEX, nil , 0xFF) -- ZONE FUNCTION

-- oil recovery, defrost MAY be different flags from standby although controller displays same symbol for all.
-- maybe missing powerful, min heat, power diffuser, sleep, coil dry, but may not be available over this protocol, only over built in IR controllers...

-- IU0 -> C0 unknown7 switches from 101 to 010 on eco on/off, then back to 101 on next packet
-- IU0 -> C0 unknown7 switches from 101 to 000 on min heat on/off, then back to 101 on next packet

p_fujitsuair.fields = {
    f_duplicate, f_dup_frame,

    f_unk0, f_src_type, f_unk16, f_src,                                       -- byte 0

    f_unk1, f_token_dst_type, f_unk18, f_token_dst,                           -- byte 1

    f_unk2, f_type, f_standby, f_write, f_unk3, f_unk26,                      -- byte 2
    f_zone_common, f_unk20,                                                   -- byte 2

    f_f_mode_auto, f_f_mode_heat, f_f_mode_fan, f_f_mode_dry, f_f_mode_cool,  -- byte 3
    f_unk21, f_unk4, f_error, f_fan, f_mode, f_enabled, f_unk13,              -- byte 3
    f_unk27, f_unk28, f_unk36, f_zones,                                       -- byte 3
    f_zone8, f_zone7, f_zone6, f_zone5, f_zone4, f_zone3, f_zone2, f_zone1,   -- byte 3

    f_f_fan_quiet, f_f_fan_low, f_f_fan_medium, f_f_fan_high, f_f_fan_auto,   -- byte 4
    f_unk5, f_unk6, f_errcode, f_eco, f_testrun, f_temp, f_function, f_unk29, -- byte 4
    f_unk33, f_unk32, f_zone_groups, f_zone_group_night, f_zone_group_day,    -- byte 4
    f_unk34, f_unk37,                                                         -- byte 4

    f_f_filter_timer, f_f_sensor_switching, f_unk17, f_f_maintenance_button,  -- byte 5
    f_f_economy_mode, f_f_swing_horizontal, f_f_swing_vertical,               -- byte 5
    f_unk7, f_unk24, f_unk25,                                                 -- byte 5
    f_controller_sensor, f_unk8, f_swing_horizontal, f_set_horizontal_louver, -- byte 5
    f_swing_vertical, f_set_vertical_louver, f_unk9, f_funcval, f_unk30,      -- byte 5
    f_zone_grouping_1_4, f_zone_func_write, f_unk38,                          -- byte 5
    f_zone4_groups, f_zone4_night, f_zone4_day,                               -- byte 5
    f_zone3_groups, f_zone3_night, f_zone3_day,                               -- byte 5
    f_zone2_groups, f_zone2_night, f_zone2_day,                               -- byte 5
    f_zone1_groups, f_zone1_night, f_zone1_day,                               -- byte 5

    f_unk10, f_lock_filter_reset, f_lock_on_off, f_lock_mode, f_lock_unknown, -- byte 6
    f_lock_timer, f_lock_all, f_seen_secondary_rc, f_seen_primary_rc,         -- byte 6
    f_unk11, f_controller_temp, f_unk14, f_unk31,                             -- byte 6
    f_zone_grouping_5_8, f_zone_func_location,                                -- byte 6
    f_zone8_groups, f_zone8_night, f_zone8_day,                               -- byte 6
    f_zone7_groups, f_zone7_night, f_zone7_day,                               -- byte 6
    f_zone6_groups, f_zone6_night, f_zone6_day,                               -- byte 6
    f_zone5_groups, f_zone5_night, f_zone5_day,                               -- byte 6

    f_unk12, f_unk22, f_filter_timer, f_reset_filter_timer, f_maintenance,    -- byte 7
    f_unk19, f_unk23, f_unk15, f_indoorunit, f_unk35, f_zone_func_value       -- byte 7
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
    subtree:add(f_src_type, buf(0,1))
    subtree:add(f_unk16   , buf(0,1))
    subtree:add(f_src     , buf(0,1))
    -- byte 1
    subtree:add(f_unk1          , buf(1,1))
    subtree:add(f_token_dst_type, buf(1,1))
    subtree:add(f_unk18         , buf(1,1))
    subtree:add(f_token_dst     , buf(1,1))
    -- byte 2
    subtree:add(f_unk2    , buf(2,1))
    subtree:add(f_type    , buf(2,1))
    if srctype == 0 then -- INDOOR UNIT
        if ptype == 0 then -- CONFIG
            subtree:add(f_standby , buf(2,1))
            subtree:add(f_unk3    , buf(2,1))
        elseif ptype == 6 then -- ZONE FUNCTION
            subtree:add(f_unk20   , buf(2,1))
        else
            subtree:add(f_unk26   , buf(2,1))
        end
    else -- REMOTE
        if ptype == 0 or ptype == 3 or ptype == 5 then -- CONFIG, FUNCTION, ZONE CONFIG
            subtree:add(f_write , buf(2,1))
            subtree:add(f_unk3  , buf(2,1))
        else
            subtree:add(f_unk26 , buf(2,1))
        end
    end

    local used = 3

    if ptype == 0 then -- CONFIG
        local CONFIGtree = subtree:add("", "CONFIG")

        -- byte 3
        CONFIGtree:add(f_error   , buf(3,1))
        CONFIGtree:add(f_fan     , buf(3,1))
        CONFIGtree:add(f_mode    , buf(3,1))
        CONFIGtree:add(f_enabled , buf(3,1))
        -- byte 4
        CONFIGtree:add(f_eco     , buf(4,1))
        CONFIGtree:add(f_testrun , buf(4,1))
        CONFIGtree:add(f_unk6    , buf(4,1))
        CONFIGtree:add(f_temp    , buf(4,1))

        if srctype == 0 then -- INDOOR UNIT
            -- byte 5
            CONFIGtree:add(f_unk7              , buf(5,1))
            CONFIGtree:add(f_swing_horizontal  , buf(5,1))
            CONFIGtree:add(f_unk24             , buf(5,1))
            CONFIGtree:add(f_swing_vertical    , buf(5,1))
            CONFIGtree:add(f_unk25             , buf(5,1))
            -- byte 6
            CONFIGtree:add(f_lock_filter_reset , buf(6,1))
            CONFIGtree:add(f_lock_on_off       , buf(6,1))
            CONFIGtree:add(f_lock_mode         , buf(6,1))
            CONFIGtree:add(f_lock_unknown      , buf(6,1))
            CONFIGtree:add(f_lock_timer        , buf(6,1))
            CONFIGtree:add(f_lock_all          , buf(6,1))
            CONFIGtree:add(f_seen_secondary_rc , buf(6,1))
            CONFIGtree:add(f_seen_primary_rc   , buf(6,1))
            -- byte 7
            CONFIGtree:add(f_unk22             , buf(7,1))
            CONFIGtree:add(f_filter_timer      , buf(7,1))
            CONFIGtree:add(f_unk19             , buf(7,1))
        else -- REMOTE
            -- byte 5
            CONFIGtree:add(f_controller_sensor     , buf(5,1))
            CONFIGtree:add(f_unk8                  , buf(5,1))
            CONFIGtree:add(f_swing_horizontal      , buf(5,1))
            CONFIGtree:add(f_set_horizontal_louver , buf(5,1))
            CONFIGtree:add(f_swing_vertical        , buf(5,1))
            CONFIGtree:add(f_set_vertical_louver   , buf(5,1))
            CONFIGtree:add(f_unk9                  , buf(5,1))
            -- byte 6
            CONFIGtree:add(f_unk11                 , buf(6,1))
            CONFIGtree:add(f_controller_temp       , buf(6,1), buf(6,1):bitfield(1,7) / 2) -- No bit field displayed for floats, unfortunately
            -- byte 7
            CONFIGtree:add(f_unk22                 , buf(7,1))
            CONFIGtree:add(f_reset_filter_timer    , buf(7,1))
            CONFIGtree:add(f_maintenance           , buf(7,1))
            CONFIGtree:add(f_unk23                 , buf(7,1))
        end

        used = used + 5
    elseif ptype == 1 and srctype == 0 then -- INDOOR UNIT ERROR
        -- byte 3
        subtree:add(f_unk4    , buf(3,1))
        -- byte 4
        subtree:add(f_errcode , buf(4,1))

        used = used + 2
    elseif ptype == 2 and srctype == 0 then -- INDOOR UNIT FEATURES
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
        featuretree:add(f_f_filter_timer       , buf(5,1))
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
    elseif ptype == 4 and srctype == 0 then -- STATUS
        -- byte 3
        subtree:add(f_unk27 , buf(3,1))
        subtree:add(f_unk28 , buf(3,1))
        -- byte 4
        subtree:add(f_unk29 , buf(4,1))
        -- byte 5
        subtree:add(f_unk30 , buf(5,1))
        -- byte 6
        subtree:add(f_unk31 , buf(6,1))

        used = used + 4
    elseif ptype == 5 then -- ZONE CONFIG
        local CONFIGtree = subtree:add("", "ZONE CONFIG")
        -- byte 3
        local ZONEtree = CONFIGtree:add(f_zones , buf(3,1))
        ZONEtree:add(f_zone8 , buf(3,1))
        ZONEtree:add(f_zone7 , buf(3,1))
        ZONEtree:add(f_zone6 , buf(3,1))
        ZONEtree:add(f_zone5 , buf(3,1))
        ZONEtree:add(f_zone4 , buf(3,1))
        ZONEtree:add(f_zone3 , buf(3,1))
        ZONEtree:add(f_zone2 , buf(3,1))
        ZONEtree:add(f_zone1 , buf(3,1))
        -- byte 4
        CONFIGtree:add(f_unk33 , buf(4,1))
        CONFIGtree:add(f_unk32 , buf(4,1))
        local ZONEGROUPStree = CONFIGtree:add(f_zone_groups , buf(4,1))
        ZONEGROUPStree:add(f_zone_group_night , buf(4,1))
        ZONEGROUPStree:add(f_zone_group_day   , buf(4,1))
        CONFIGtree:add(f_unk37 , buf(4,1))
        -- byte 5
        local ZONEGROUP14tree = CONFIGtree:add(f_zone_grouping_1_4 , buf(5,1))
        local ZONEGROUP4tree = ZONEGROUP14tree:add(f_zone4_groups , buf(5,1))
        ZONEGROUP4tree:add(f_zone4_night , buf(5,1))
        ZONEGROUP4tree:add(f_zone4_day   , buf(5,1))
        local ZONEGROUP3tree = ZONEGROUP14tree:add(f_zone3_groups , buf(5,1))
        ZONEGROUP3tree:add(f_zone3_night , buf(5,1))
        ZONEGROUP3tree:add(f_zone3_day   , buf(5,1))
        local ZONEGROUP2tree = ZONEGROUP14tree:add(f_zone2_groups , buf(5,1))
        ZONEGROUP2tree:add(f_zone2_night , buf(5,1))
        ZONEGROUP2tree:add(f_zone2_day   , buf(5,1))
        local ZONEGROUP1tree = ZONEGROUP14tree:add(f_zone1_groups , buf(5,1))
        ZONEGROUP1tree:add(f_zone1_night , buf(5,1))
        ZONEGROUP1tree:add(f_zone1_day   , buf(5,1))
        -- byte 6
        local ZONEGROUP58tree = CONFIGtree:add(f_zone_grouping_5_8 , buf(6,1))
        local ZONEGROUP8tree = ZONEGROUP58tree:add(f_zone8_groups , buf(6,1))
        ZONEGROUP8tree:add(f_zone8_night , buf(6,1))
        ZONEGROUP8tree:add(f_zone8_day   , buf(6,1))
        local ZONEGROUP7tree = ZONEGROUP58tree:add(f_zone7_groups , buf(6,1))
        ZONEGROUP7tree:add(f_zone7_night , buf(6,1))
        ZONEGROUP7tree:add(f_zone7_day   , buf(6,1))
        local ZONEGROUP6tree = ZONEGROUP58tree:add(f_zone6_groups , buf(6,1))
        ZONEGROUP6tree:add(f_zone6_night , buf(6,1))
        ZONEGROUP6tree:add(f_zone6_day   , buf(6,1))
        local ZONEGROUP5tree = ZONEGROUP58tree:add(f_zone5_groups , buf(6,1))
        ZONEGROUP5tree:add(f_zone5_night , buf(6,1))
        ZONEGROUP5tree:add(f_zone5_day   , buf(6,1))
        -- byte 7
        CONFIGtree:add(f_unk35 , buf(7,1))

        used = used + 5
    elseif ptype == 6 then -- ZONE FUNCTION (IU ACKs)
        local CONFIGtree = subtree:add("", "ZONE FUNCTION")
        if srctype == 0 then -- INDOOR UNIT
            -- byte 2
            CONFIGtree:add(f_zone_common , buf(2,1))
            -- byte 3
            local ZONEtree = CONFIGtree:add(f_zones , buf(3,1))
            ZONEtree:add(f_zone8 , buf(3,1))
            ZONEtree:add(f_zone7 , buf(3,1))
            ZONEtree:add(f_zone6 , buf(3,1))
            ZONEtree:add(f_zone5 , buf(3,1))
            ZONEtree:add(f_zone4 , buf(3,1))
            ZONEtree:add(f_zone3 , buf(3,1))
            ZONEtree:add(f_zone2 , buf(3,1))
            ZONEtree:add(f_zone1 , buf(3,1))
        else -- REMOTE
            CONFIGtree:add(f_unk36 , buf(3,1))
        end
        -- byte 4
        CONFIGtree:add(f_unk34              , buf(4,1))
        -- byte 5
        CONFIGtree:add(f_zone_func_write    , buf(5,1))
        CONFIGtree:add(f_unk38              , buf(5,1))
        -- byte 6
        CONFIGtree:add(f_zone_func_location , buf(6,1))
        -- byte 7
        CONFIGtree:add(f_zone_func_value    , buf(7,1))

        used = used + 5
    end

    if (used < frame_len) then
        Dissector.get("data"):call(buf(used):tvb(), pinfo, tree)
    end
end

local tzsp_encap_d = DissectorTable.get("tzsp.encap")
tzsp_encap_d:add(tzsp_encap_type, p_fujitsuair)
