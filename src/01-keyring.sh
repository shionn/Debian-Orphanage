#!/bin/bash

# Récupération automatique du fingerprint depuis la clé secrète GPG
sign=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')

if [ -z "$sign" ]; then
    echo "Erreur : aucune clé secrète GPG trouvée. Vérifiez ~/.gnupg (ou le keyring d'importation)."
    exit 1
fi

# L'URI est obligatoire : elle définit le dépôt vers lequel pointer le keyring
if [ -z "$1" ]; then
    echo "Erreur : l'URI n'a pas été fournie en paramètre."
    echo "Usage : $0 <uri>"
    exit 1
fi
url=$1


project=orphanage
version=1.0.4

mkdir -p build/trixie/keyring/
cd build/trixie/keyring/

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
URIs: ${url}
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/${project}.pgp
" > etc/apt/sources.list.d/${project}.sources

cd ..

dpkg -b ${project}-keyring-${version}
