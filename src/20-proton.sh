#!/bin/bash

source "src/99-functions.sh"

project="proton-9"
revision=0

mkdir -p build/trixie/${project}/
cd build/trixie/${project}/

download_github_last_tag GloriousEggroll proton-ge-custom '.*\.tar\.gz' 'GE-Proton9-.*'

if [ -z "${LAST_GITHUB_TAG}" ]; then
	echo "Aucune release correspondant au pattern de tag."
	exit 1
fi

version=$(echo "${LAST_GITHUB_TAG}" | sed -E 's/.*-(.+)-(.+)$/\1.\2/')

echo "Version : ${version}"

exit 0

if [ -f "$project-$version-$revision.deb" ]; then
	echo "a jour $version"
	# deja la = OK, pas d'erreur
	exit 0
fi

git clone -b $version git@github.com:Gustash/Hyprshot.git ${version}
cd "${version}/"

mkdir ${project}-${version}
cd ${project}-${version}

# a mettre dans /lib/proton/proton-x/
# faire les liens symbolique dans /usr/bin ? a voir car plusieur version de proton


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