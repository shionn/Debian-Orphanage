#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/trixie/umu/
cd build/trixie/umu/

download_github Open-Wine-Components umu-launcher ".*(amd64|all)_debian-13.deb"
