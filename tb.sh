#! /bin/bash

ghdl -a project_reti_logiche.vhd project_tb.vhd
ghdl -e project_tb
ghdl -r project_tb --vcd=wave.vcd