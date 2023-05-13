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
    [2] = "HELLO",
    [3] = "FUNCTION",
    [4] = "PERIODIC" -- Inter indoor unit update? some other type of update? happens every 30 sec. unless a write changes certain things...
}

local address = {
    [0] = "INDOOR UNIT SRC",
    [1] = "INDOOR UNIT DST", -- this is weird, possibly reading address fields incorrectly. Need a single remote with multi indoor units connected to compare with.
    [32] = "PRIMARY REMOTE",
    [33] = "SECONDARY REMOTE",
    [34] = "TERTIARY REMOTE" -- not confirmed
}

local f_duplicate = ProtoField.bool     ("fujitsuair.duplicate"       , "Duplicate"       , base.NONE)
local f_dup_frame = ProtoField.framenum ("fujitsuair.duplicate_frame" , "Duplicate Frame" , base.NONE)

-- byte 0
local f_bcast     = ProtoField.bool  ("fujitsuair.broadcast" , "Broadcast"    ,        8, nil        , 0x80) -- ALL -- not confirmed
local f_src       = ProtoField.uint8 ("fujitsuair.src"       , "Source"       , base.DEC, address    , 0x7F) -- ALL -- maybe 0x0F is address and 0xF0 flags, 0x20 remote/indoor unit flag?
-- byte 1
local f_unk1      = ProtoField.bool  ("fujitsuair.unknown1"  , "Unknown"      ,        8, nil        , 0x80) -- ALL
local f_dst       = ProtoField.uint8 ("fujitsuair.dst"       , "Destination"  , base.DEC, address    , 0x7F) -- ALL
-- byte 2
local f_unk2      = ProtoField.uint8 ("fujitsuair.unknown2"  , "Unknown"      , base.DEC, nil        , 0x80) -- ALL
local f_type      = ProtoField.uint8 ("fujitsuair.type"      , "Type"         , base.DEC, packettype , 0x70) -- ALL -- maybe 4 bits? 0xF0?
local f_write     = ProtoField.bool  ("fujitsuair.write"     , "Write"        ,        8, nil        , 0x08) -- ALL -- from indoor unit might mean turn on defrost symbol on remote
local f_unk3      = ProtoField.uint8 ("fujitsuair.unknown3"  , "Unknown"      , base.DEC, nil        , 0x07) -- ALL
-- byte 3
local f_unk4      = ProtoField.uint8 ("fujitsuair.unknown4"  , "Unknown"      , base.DEC, nil        , 0xFF) -- ERROR, HELLO
local f_error     = ProtoField.bool  ("fujitsuair.error"     , "Error"        ,        8, nil        , 0x80) -- STATUS
local f_fan       = ProtoField.uint8 ("fujitsuair.fan"       , "Fan"          , base.DEC, fanlevel   , 0x70) -- STATUS
local f_mode      = ProtoField.uint8 ("fujitsuair.mode"      , "Mode"         , base.DEC, opmode     , 0x0E) -- STATUS
local f_enabled   = ProtoField.bool  ("fujitsuair.enabled"   , "Enabled"      ,        8, nil        , 0x01) -- STATUS
local f_unk13     = ProtoField.uint8 ("fujitsuair.unknown13" , "Unknown"      , base.DEC, nil        , 0xFF) -- FUNCTION
-- byte 4
local f_unk5      = ProtoField.uint8 ("fujitsuair.unknown5"  , "Unknown"      , base.DEC, nil        , 0xFF) -- HELLO
local f_errcode   = ProtoField.uint8 ("fujitsuair.errcode"   , "Error Code"   , base.HEX)                    -- ERROR
local f_eco       = ProtoField.bool  ("fujitsuair.eco"       , "Economy Mode" ,        8, nil        , 0x80) -- STATUS
local f_testrun   = ProtoField.bool  ("fujitsuair.testrun"   , "Test Run"     ,        8, nil        , 0x40) -- STATUS -- check this with eco mode on to ensure this is not a 2 or 3 bit state
local f_unk6      = ProtoField.bool  ("fujitsuair.unknown6"  , "Unknown"      ,        8, nil        , 0x20) -- STATUS
local f_temp      = ProtoField.uint8 ("fujitsuair.temp"      , "Temperature"  , base.DEC, nil        , 0x1F) -- STATUS -- needs another bit from unk6?
local f_function  = ProtoField.uint8 ("fujitsuair.function"  , "Function"     , base.DEC, nil        , 0xFF) -- FUNCTION -- maybe 7 bits? function #99 (0x63) appears to be maximum
-- byte 5
local f_unk7      = ProtoField.uint8 ("fujitsuair.unknown7"       , "Unknown"        , base.DEC, nil , 0xFF) -- ERROR, HELLO
local f_unk8      = ProtoField.uint8 ("fujitsuair.unknown8"       , "Unknown"        , base.DEC, nil , 0xF8) -- STATUS
local f_swing     = ProtoField.bool  ("fujitsuair.swing"          , "Swing"          ,        8, nil , 0x04) -- STATUS -- not confirmed (enable/disable)
local f_sstep     = ProtoField.bool  ("fujitsuair.swingstep"      , "Swing Step"     ,        8, nil , 0x02) -- STATUS -- not confirmed (change to next position (position not reported, always 0 from indoor unit))
local f_unk9      = ProtoField.bool  ("fujitsuair.unknown9"       , "Unknown"        ,        8, nil , 0x01) -- STATUS
local f_funcval   = ProtoField.uint8 ("fujitsuair.function_value" , "Function Value" , base.DEC, nil , 0xFF) -- FUNCTION
-- byte 6
local f_unk10            = ProtoField.uint8 ("fujitsuair.unknown10"        , "Unknown"            , base.DEC, nil, 0xFF) -- HELLO
local f_unk11            = ProtoField.uint8 ("fujitsuair.unknown11"        , "Unknown"            , base.DEC, nil, 0xC0) -- STATUS
local f_remote_temp      = ProtoField.uint8 ("fujitsuair.remote_temp"      , "Remote Temperature" , base.DEC, nil, 0x3E) -- STATUS
local f_remote_connected = ProtoField.bool  ("fujitsuair.remote_connected" , "Remote Connected"   ,        8, nil, 0x01) -- STATUS
local f_unk14            = ProtoField.uint8 ("fujitsuair.unknown14"        , "Unknown"            , base.DEC, nil, 0xFF) -- FUNCTION
-- byte 7
local f_unk12      = ProtoField.uint8 ("fujitsuair.unknown12"  , "Unknown"     , base.DEC, nil, 0xFF) -- STATUS, HELLO
local f_unk15      = ProtoField.uint8 ("fujitsuair.unknown15"  , "Unknown"     , base.DEC, nil, 0xF0) -- FUNCTION
local f_indoorunit = ProtoField.uint8 ("fujitsuair.indoorunit" , "Indoor Unit" , base.DEC, nil, 0x0F) -- FUNCTION -- maybe all?

p_fujitsuair.fields = {
    f_duplicate, f_dup_frame,
    f_bcast, f_src,                                                  -- byte 0
    f_unk1, f_dst,                                                   -- byte 1
    f_unk2, f_type, f_write, f_unk3,                                 -- byte 2
    f_unk4, f_error, f_fan, f_mode, f_enabled, f_unk13,              -- byte 3
    f_unk5, f_unk6, f_errcode, f_eco, f_testrun, f_temp, f_function, -- byte 4
    f_unk7, f_unk8, f_swing, f_sstep, f_unk9, f_funcval,             -- byte 5
    f_unk10, f_unk11, f_remote_temp, f_remote_connected, f_unk14,    -- byte 6
    f_unk12, f_unk15, f_indoorunit                                   -- byte 7
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
    local srcaddr = bit.band(buf(0,1):uint(), 0x7F)
    local dstaddr = bit.band(buf(1,1):uint(), 0x7F)
    local ptype   = bit.rshift(bit.band(buf(2,1):uint(), 0x70), 4)

    -- Display information
    pinfo.cols.protocol = p_fujitsuair.name
    pinfo.cols.info = string.format("%s [%s → %s]", packettype[ptype], address[srcaddr], address[dstaddr])
    local subtree = tree:add(p_fujitsuair, buf(), p_fujitsuair.description)
    subtree:append_text(", Src: " .. srcaddr .. ", Dst: " .. dstaddr)

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
        else
            track_unique[srcdst][frame_no] = data
            track_unique_list[srcdst][#track_unique_list[srcdst] + 1] = frame_no
        end
    end

    -- Dissect the packet

    -- byte 0
    subtree:add(f_bcast , buf(0,1))
    subtree:add(f_src   , buf(0,1))
    -- byte 1
    subtree:add(f_unk1  , buf(1,1))
    subtree:add(f_dst   , buf(1,1))
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
        -- byte 5
        statustree:add(f_unk8    , buf(5,1))
        statustree:add(f_swing   , buf(5,1))
        statustree:add(f_sstep   , buf(5,1))
        statustree:add(f_unk9    , buf(5,1))
        -- byte 6
        statustree:add(f_unk11            , buf(6,1))
        statustree:add(f_remote_temp      , buf(6,1)):append_text("°C")
        statustree:add(f_remote_connected , buf(6,1))
        -- byte 7
        subtree:add(f_unk12      , buf(7,1))

        used = used + 5
    elseif ptype == 1 then -- ERROR
        -- byte 3
        subtree:add(f_unk4    , buf(3,1))
        -- byte 4
        subtree:add(f_errcode , buf(4,1))

        used = used + 2
    elseif ptype == 2 then -- HELLO -- unknown fields are probably indoor unit informing remote what is supported (for example swing mode)
        -- byte 3                   -- need to emulate indoor unit and see how remote reacts to different bits flipped...
        subtree:add(f_unk4    , buf(3,1))
        -- byte 4
        subtree:add(f_unk5    , buf(4,1))
        -- byte 5
        subtree:add(f_unk7    , buf(5,1))
        -- byte 6
        subtree:add(f_unk10    , buf(6,1))
        -- byte 7
        subtree:add(f_unk12    , buf(7,1))

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