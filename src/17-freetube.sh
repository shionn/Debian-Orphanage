#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/trixie/freetube/
cd build/trixie/freetube/

download_github FreeTubeApp FreeTube ".*amd64.deb"

