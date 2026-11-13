#!/bin/bash

source "src/99-functions.sh"

project="ge-proton-9"
revision=0

mkdir -p build/trixie/${project}/
cd build/trixie/${project}/

download_github_last_tag GloriousEggroll proton-ge-custom '.*\.tar\.gz' 'GE-Proton9-.*'

if [ -z "${LAST_GITHUB_TAG}" ]; then
	echo "Aucune release correspondant au pattern de tag."
	exit 1
fi

version=$(echo "${LAST_GITHUB_TAG}" | sed -E 's/.*-(.+)-(.+)$/\1.\2/')

if [ -f "$project-$version.deb" ]; then
	echo "a jour $version"
	# deja la = OK, pas d'erreur
	exit 0
fi

mkdir ${version}
tar -xzf GE-Proton9-${version}.tar.gz -C ${version}
cd ${version}

mkdir ${project}-${version}
cd ${project}-${version}

exit 0

# a mettre dans /lib/proton/proton-x/
# faire les liens symbolique dans /usr/bin ? a voir car plusieur version de proton


mkdir -p usr/local/bin/
cp ../hyprshot usr/local/bin/

mkdir DEBIAN

echo "Source: ${project}
Section: games
Priority: optional
Maintainer: Shionn<shionn@gmail.com>
Homepage: https://github.com/GloriousEggroll/proton-ge-custom
Package: ${project}
Version: ${version}
Architecture: amd64
Depends: 
Description: This is my build of Proton with the most recent bleeding-edge Proton Experimental Wine.">> DEBIAN/control

echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${project}
Source: https://github.com/GloriousEggroll/proton-ge-custom/tree/GE-Proton9-${version}
Files: *
Copyright: Valve Corporation
Licence: https://github.com/GloriousEggroll/proton-ge-custom/blob/master/LICENSE.proton" >> DEBIAN/copyright

cd .. 
dpkg -b ${project}-${version}

mv ${project}-${version}.deb ../
cd ../
rm -Rf $version