#!/bin/bash

source "src/99-functions.sh"

project="ge-proton9"
version=9

mkdir -p build/trixie/${project}/
cd build/trixie/${project}/

download_github_last_tag GloriousEggroll proton-ge-custom '.*\.tar\.gz' "GE-Proton${version}-.*"

if [ -z "${LAST_GITHUB_TAG}" ]; then
	echo "Aucune release correspondant au pattern de tag."
	exit 1
fi

revision=$(echo "${LAST_GITHUB_TAG}" | sed -E 's/.*-([0-9]+)$/\1/')
echo "Downloaded Revision ${revision}"

if [ -f "$project-$version.$revision.deb" ]; then
	echo "Proton GE à jour $version.$revision"
	exit 0
fi

mkdir -p ${project}-${version}.${revision}
tar -xzf GE-Proton${version}-${revision}.tar.gz 
cd ${project}-${version}.${revision}

# préparation du package
# faire les liens symbolique dans /usr/bin ? a voir car plusieur version de proton

mkdir -p lib/proton/GE-Proton-${version}/
mv ../GE-Proton${version}-${revision}/* lib/proton/GE-Proton-${version}/

mkdir DEBIAN

echo "Source: ${project}
Section: games
Priority: optional
Maintainer: Shionn<shionn@gmail.com>
Homepage: https://github.com/GloriousEggroll/proton-ge-custom
Package: ${project}
Version: ${version}.${revision}
Architecture: amd64
Depends: 
Description: This is my build of Proton with the most recent bleeding-edge Proton Experimental Wine.">> DEBIAN/control

echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${project}
Source: https://github.com/GloriousEggroll/proton-ge-custom/tree/GE-Proton${version}-${revision}
Files: *
Copyright: Valve Corporation
Licence: https://github.com/GloriousEggroll/proton-ge-custom/blob/master/LICENSE.proton" >> DEBIAN/copyright

cd .. 
dpkg -b ${project}-${version}.${revision}

rm -Rf GE-Proton${version}-${revision} ${project}-${version}.${revision}
