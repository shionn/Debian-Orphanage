#!/bin/bash

source "src/99-functions.sh"

project="ge-proton9"
revision=0

mkdir -p build/trixie/${project}/
cd build/trixie/${project}/

download_github_last_tag GloriousEggroll proton-ge-custom '.*\.tar\.gz' 'GE-Proton9-.*'

if [ -z "${LAST_GITHUB_TAG}" ]; then
	echo "Aucune release correspondant au pattern de tag."
	exit 1
fi

version=$(echo "${LAST_GITHUB_TAG}" | sed -E 's/.*-([0-9]+)$/\1/')
#version=$(echo "GE-Proton9-27" | sed -E 's/.*-([0-9]+)$/\1/')

if [ -f "$project-$version.deb" ]; then
	echo "Proton GE à jour $version"
	exit 0
fi

mkdir -p ${project}-${version}
tar -xzf GE-Proton9-${version}.tar.gz 
cd ${project}-${version}

# préparation du package
# faire les liens symbolique dans /usr/bin ? a voir car plusieur version de proton

mkdir -p lib/proton/GE-Proton-9/
mv ../GE-Proton9-${version}/* lib/proton/GE-Proton-9/

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

rm -Rf GE-Proton9-${version} ${project}-${version}
