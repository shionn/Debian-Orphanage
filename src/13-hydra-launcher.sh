#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/trixie/hydra-launcher/
cd build/trixie/hydra-launcher/

download_github hydralauncher hydra ".*.deb"
