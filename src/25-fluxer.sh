#!/bin/bash

#source "src/99-functions.sh"

project="fluxer"

exit 0

mkdir -p build/trixie/${project}/
cd build/trixie/${project}/


curl -LJO "https://pkgs.fluxer.com/desktop/stable/linux/x64/latest/deb"

