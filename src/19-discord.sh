#!/bin/bash

#source "src/99-functions.sh"

mkdir -p build/trixie/discord/
cd build/trixie/discord/

curl -LJO "https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=linux&arch=x64&format=deb"

