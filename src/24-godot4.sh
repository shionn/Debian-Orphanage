#!/bin/bash

source "src/99-functions.sh"

project="godot4"

mkdir -p build/trixie/${project}/
cd build/trixie/${project}/

download_github godotengine godot ".*-stable_linux.x86_64.zip"

# version extraite du nom : Godot_v4.7.2-stable_linux.x86_64.zip -> 4.7.2
version=$(echo "${DL_FILENAME}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed -E 's/^v//')
if [ -z "${version}" ]; then
	echo "Impossible de determiner la version depuis ${DL_FILENAME}"
	exit 1
fi
if [[ ! "${version}" =~ ^4\. ]]; then
	echo "Limité à. Refus: ${version}"
	exit 1
fi
source="${DL_FILENAME%.zip}"
echo "Version detectee: ${version}. Source: ${source}."

if [ -f "$project-$version.deb" ]; then
	echo "Package debian à jour $version.$revision"
	exit 0
fi

rm -rf ${project}-${version}
mkdir -p ${project}-${version}
unzip -o $DL_FILENAME
 
cd ${project}-${version}
mkdir -p usr/bin
mkdir -p usr/share/${project}
mkdir -p usr/share/applications
mkdir DEBIAN
mv ../${source} usr/share/${project}/
ln -s usr/share/${project}/${source} usr/bin/${project}
curl -o usr/share/${project}/icon.svg https://godotengine.org/assets/press/icon_color.svg

echo "Source: ${project}
Section: devel
Priority: optional
Maintainer: Shionn<shionn@gmail.com>
Homepage: https://godotengine.org/fr/
Package: ${project}
Version: ${version}
Architecture: amd64
Depends: 
Description: Développez vos jeux en 2D et 3D, des projets cross-plateformes ou même des applications XR !" >> DEBIAN/control

echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${project}
Source: https://github.com/godotengine/godot/tree/${version}-stable
Files: *
Copyright: 2014-present Godot Engine contributors
Licence: MIT License" >> DEBIAN/copyright

echo "[Desktop Entry]
Name=Godot4
Comment=Godot
GenericName=Godot
X-GNOME-FullName=Godot
Exec=/usr/bin/${project}
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=/usr/share/${project}/icon.svg
Categories=Development;
StartupWMClass=Godot
StartupNotify=true" >> usr/share/applications/Godot4.desktop

cd .. 

dpkg -b ${project}-${version}
rm -rf ${project}-${version}

