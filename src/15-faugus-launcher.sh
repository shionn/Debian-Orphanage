#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/trixie/faugus-launcher/
cd build/trixie/faugus-launcher/

download_github Faugus faugus-launcher ".*.deb"

