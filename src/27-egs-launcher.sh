#!/bin/bash

project="egs-launcher"

mkdir -p build/trixie/${project}/
cd build/trixie/${project}/

curl -LJO "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncher-x86_64.deb"

