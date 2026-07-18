import re
import sys

from pathlib import Path
from scapy.contrib.tzsp import TZSP, TZSPTagEnd, TZSP_PORT_DEFAULT
from scapy.layers.inet import IP, UDP
from scapy.layers.l2 import Ether
from scapy.packet import Raw
from scapy.utils import wrpcapng

line_re = r'[RT]X:((?: [0-9a-fA-F]{2}){8})$'

if len(sys.argv) != 3:
    print (f'{sys.argv[0]}: <source file> <destination file>')
    exit()

log_file = Path(sys.argv[1])
try:
    with open(log_file, 'r', encoding='utf-8') as file:
        log_lines = re.findall(line_re, file.read(), re.MULTILINE)
        if log_lines:
            packets = [Ether() / IP() / UDP(dport=TZSP_PORT_DEFAULT, sport=0) / TZSP(type=1, encapsulated_protocol=255) / TZSPTagEnd() / Raw(bytes.fromhex(packet)) for packet in log_lines]
            wrpcapng(sys.argv[2], packets)
except FileNotFoundError:
    print(f"Error: The file '{log_file}' does not exist.")
except PermissionError:
    print(f"Error: The file '{log_file}' exists but is not readable (permission denied).")
except OSError as e:
    print(f"OS error occurred: {e}")
