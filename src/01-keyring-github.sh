#!/bin/bash

if [ -z "$1" ]; then
    echo "Erreur : le fingerprint GPG n'a pas été fourni en paramètre."
    echo "Usage : $0 <fingerprint>"
    echo "Faire un 'gpg --list-secret-key' pour trouver la valeur hexa d'environ 40 caractere"
    exit 1
fi


project=orphanage
version=1.0.3

mkdir -p build/trixie-github/keyring/
cd build/trixie-github/keyring/

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
echo "# Orphan package by shionn
Types: deb
Architectures: amd64
URIs: http://orphanage.shionn.org
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/${project}.pgp
" > etc/apt/sources.list.d/${project}.sources

cd ..

dpkg -b ${project}-keyring-${version}

