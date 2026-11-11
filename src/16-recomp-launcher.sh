#!/bin/bash

#source "src/99-functions.sh"

mkdir -p build/trixie/recomp-launcher/
cd build/trixie/recomp-launcher/

curl -LJO "https://recomplauncher.com/api/launcher-beta.php?a=download&os=deb"

