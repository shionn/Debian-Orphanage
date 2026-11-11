#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/trixie/openrgb/
cd build/trixie/openrgb/

download_github CalcProgrammer1 OpenRGB ".*amd64_trixie_.*.deb"
