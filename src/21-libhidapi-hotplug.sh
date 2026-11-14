#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/trixie/lib-hidapi-hotplug/
cd build/trixie/lib-hidapi-hotplug/

download_codeberg OpenRGB hidapi-hotplug ".*trixie_amd64.deb"

