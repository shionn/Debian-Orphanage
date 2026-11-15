#!/bin/bash

source "src/99-functions.sh"

project="game-launcher"

mkdir -p build/trixie/${project}/
cd build/trixie/${project}/

download_github shionn GameLauncher '.*jar'

# GameLauncher-1.0.0.jar > 1.0.0
version=$(echo "${DL_FILENAME}" | sed -E 's/.*-([0-9][0-9A-Za-z.-]*)\.jar$/\1/')
echo "Downloaded ${DL_FILENAME} in ${version} version"

if [ -f "$project-$version.deb" ]; then
	echo "${project} à jour"
	exit 0
fi

mkdir -p ${project}-${version}
cd ${project}-${version}

mkdir -p usr/bin
mkdir -p usr/share/java
mkdir -p usr/share/applications
mkdir DEBIAN

cp ../${DL_FILENAME} usr/share/java/

# creation du mode desktop
echo "gamescope -f -- java -jar /usr/share/java/${DL_FILENAME}" >> usr/bin/start-gamelauncher
chmod +x usr/bin/start-gamelauncher

# creation de lapplication entry
# TODO Icon=/usr/share/${project}/icon.svg ? 
echo "[Desktop Entry]
Name=Game Launcher
Comment=Game Launcher
GenericName=Game Launcher
X-GNOME-FullName=Game Launcher
Exec=java -jar /usr/share/java/${DL_FILENAME}
Terminal=false
X-MultipleArgs=false
Type=Application
Categories=Development;
StartupWMClass=Game Launcher
StartupNotify=true" >> usr/share/applications/GameLauncher.desktop

# creation du package
echo "Source: ${project}
Section: games
Priority: optional
Maintainer: Shionn<shionn@gmail.com>
Homepage: https://github.com/shionn/GameLauncher
Package: ${project}
Version: ${version}
Architecture: amd64
Depends: openjdk-21-jre, umu-launcher, ge-proton10, zenity, gamescope, gamemode
Description: Offline simple game launcher.">> DEBIAN/control

echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${project}
Source: https://github.com/github.com/shionn/GameLauncher/tree/${version}
Files: *
Copyright: Shionn
Licence: GNU Affero General Public License v3.0" >> DEBIAN/copyright

cd .. 
dpkg -b ${project}-${version}

rm -Rf ${project}-${version}
