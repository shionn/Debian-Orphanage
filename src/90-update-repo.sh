#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage : $0 <origin-url> <config-root>"
    exit 1
fi

ORIGIN=$1
CONFIG_ROOT=$2

mkdir -p "${CONFIG_ROOT}/conf/"

echo "Origin: ${ORIGIN}
Label: ${ORIGIN}
Codename: trixie
Architectures: amd64
Components: main
Description: Orphanage repository by shionn
SignWith: yes

Origin: ${ORIGIN}
Label: ${ORIGIN}
Codename: experimental
Architectures: amd64
Components: main
Description: Orphanage repository by shionn
SignWith: yes
" > "${CONFIG_ROOT}/conf/distributions"

reprepro -b "${CONFIG_ROOT}" includedeb trixie       build/trixie/*/*.deb
reprepro -b "${CONFIG_ROOT}" includedeb experimental build/experimental/*/*.deb

reprepro -b "${CONFIG_ROOT}" export trixie
reprepro -b "${CONFIG_ROOT}" export experimental
