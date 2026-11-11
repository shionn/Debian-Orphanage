#!/bin/bash

source "src/99-functions.sh"

mkdir -p build/trixie/hyprshot/
cd build/trixie/hyprshot/

project="hyprshot"
version=$(github_get_last_release_tag Gustash Hyprshot)
if [ $? -ne 0 ]; then
	echo "Erreur lors de la recuperation de la version"
	exit 1
fi

if [ -f "$project-$version.deb" ]; then
	echo "a jour $version"
	exit 1
fi

git clone -b $version git@github.com:Gustash/Hyprshot.git ${version}
cd "${version}/"

mkdir ${project}-${version}
cd ${project}-${version}

mkdir -p usr/local/bin/
cp ../hyprshot usr/local/bin/

mkdir DEBIAN

echo "Source: ${project}
Section: graphics
Priority: optional
Maintainer: Shionn<shionn@gmail.com>
Homepage: https://github.com/Gustash/Hyprshot
Package: ${project}
Version: ${version}
Architecture: amd64
Depends: hyprland, slurp, grim, libnotify-bin, wl-clipboard, jq
Description: Hyprshot is an utility to easily take screenshot in Hyprland using your mouse.">> DEBIAN/control

echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${project}
Source: https://github.com/Gustash/Hyprshot/tree/${version}
Files: *
Copyright: 
Licence: GNU GPL V3" >> DEBIAN/copyright

cd .. 
dpkg -b ${project}-${version}

mv ${project}-${version}.deb ../
cd ../
rm -Rf $version