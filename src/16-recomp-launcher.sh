#!/bin/bash

#source "src/99-functions.sh"

rm -Rf build/trixie/recomp-launcher/
mkdir -p build/trixie/recomp-launcher/
cd build/trixie/recomp-launcher/

project="recomp-launcher"

curl -LJO "https://recomplauncher.com/api/launcher-beta.php?a=download&os=deb"
#   RecompLauncher_0.90.0-beta.41_amd64.deb  ->  version=0.90.0, revision=beta.41
debname="$(basename *.deb)"   # RecompLauncher_0.90.0-beta.43_amd64.deb
debname="${debname%.deb}"     # RecompLauncher_0.90.0-beta.41_amd64
name="${debname%%_*}"         # RecompLauncher
rest="${debname#*_}"          # 0.90.0-beta.41_amd64
arch="${rest##*_}"            # amd64
verrev="${rest%_*}"           # 0.90.0-beta.41
version="${verrev%%-*}"       # 0.90.0
revision="${verrev#*-}"       # beta.41

dpkg-deb -R ${debname}.deb ${project}-${version}
rm ${debname}.deb
cd ${project}-${version}
rm DEBIAN/*

echo "Source: ${project}
Section: games
Priority: optional
Maintainer: Ripalda
Homepage: https://recomplauncher.com
Package: ${project}
Version: ${version}-${revision}
Architecture: amd64
Depends: libwebkit2gtk-4.1-0, libgtk-3-0, libayatana-appindicator3-1
Description: Recompiled and decompiled PC games
 RecompLauncher finds, installs, updates and starts recompiled and decompiled PC games, straight from each developer's own GitHub. No game files are included: every game needs your own copy." >> DEBIAN/control

echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${name}
Source: https://github.com/elripalda/RecompLauncher/tree/v${version}-${revision}
Files: *
Copyright: 
Licence: GNU GPL V3" >> DEBIAN/copyright

cd ..
dpkg -b ${project}-${version}
