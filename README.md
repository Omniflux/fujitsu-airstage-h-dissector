# Wireshark dissector plugin for Fujitsu AirStage-H (Halcyon) serial protocol

An incomplete Lua dissector for Wireshark used in conjunction with [esphome-tzspserial](https://github.com/Omniflux/esphome-tzspserial).

To use, setup Wireshark with for UDP capture on port `37008` using payload type `tzsp`. Add the dissector to your local Wireshark plugins directory.

`esphome_log_parser.py` can be used to parse ESPHome log entries into a .pcapng file.
