#!/bin/bash

# Récupération automatique du fingerprint depuis la clé secrète GPG
sign=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')

if [ -z "$sign" ]; then
    echo "Erreur : aucune clé secrète GPG trouvée. Vérifiez ~/.gnupg (ou le keyring d'importation)."
    exit 1
fi


project=orphanage
version=1.0.4

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
gpg --export-options export-minimal --export $sign > usr/share/keyrings/${project}.pgp

mkdir -p etc/apt/sources.list.d
echo "# Orphan package by shionn
Types: deb
Architectures: amd64
URIs: https://shionn.github.io/Debian-Orphanage
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/${project}.pgp
" > etc/apt/sources.list.d/${project}.sources

cd ..

dpkg -b ${project}-keyring-${version}
