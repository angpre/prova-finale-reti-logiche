#! /bin/bash

mkdir -p build
cd build
ghdl -a ../project_reti_logiche.vhd

tests_dir=./tests

for tb in "$tests_dir"/*
do
    ghdl -a "$tb"
    name=$(basename "$tb_file" .vhd)
    ghdl -e "$name"
    ghdl -r "$name"
done