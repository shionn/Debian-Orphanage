#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/trixie/bc-250/
cd build/trixie/bc-250/

download_github movacx bc250-control-center ".*.deb"
