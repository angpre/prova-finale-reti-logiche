#! /bin/bash

mkdir -p build
cd build
ghdl -a ../project_reti_logiche.vhd

for tb in ../tests/*
do
    ghdl -a "$tb"
    name="${tb##*/}"
    name="${name%.vhd}"
    echo "------ TEST: $name -------"
    ghdl -e "$name"
    ghdl -r "$name"
    echo "--------------------------------------"
done