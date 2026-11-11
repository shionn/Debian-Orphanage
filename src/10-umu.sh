#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/umu/trixie/
cd build/umu/trixie/

download_github Open-Wine-Components umu-launcher ".*(amd64|all)_debian-13.deb"
