#!/bin/bash

project=orphanage
version=1.0.0

cd build

rm -Rf ${project}-keyring
mkdir -p ${project}-keyring
cd ${project}-keyring

mkdir -p ${project}-keyring-${version}
cd ${project}-keyring-${version}

mkdir -p DEBIAN
echo "Package: ${project}-keyring
Version: ${version}
Section: misc
Priority: optional
Architecture: all
Maintainer: Shionn <shionn@gmail.com>
Description: OpenPGP archive certificates of ${project}" > DEBIAN/control

mkdir -p usr/share/keyrings
gpg --export-options export-minimal --export $1 > usr/share/keyrings/${project}.pgp

mkdir -p etc/apt/sources.list.d
echo "deb [signed-by=/usr/share/keyrings/${project}.pgp] orphanage.shionn.org/ trixie main" > etc/apt/sources.list.d/${project}.list

cd ..

dpkg -b ${project}-keyring-${version}

mv ${project}-keyring-${version}.deb ../