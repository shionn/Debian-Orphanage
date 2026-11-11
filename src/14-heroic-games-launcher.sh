#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/trixie/heroic-games-launcher/
cd build/trixie/heroic-games-launcher/

download_github Heroic-Games-Launcher HeroicGamesLauncher ".*amd64.deb"

