#!/bin/bash

mkdir -p www/conf

echo "Origin: orphanage.shionn.org
Label: orphanage.shionn.org
Codename: trixie
Architectures: amd64
Components: main
Description: Orphanage repository by shionn
SignWith: yes

Origin: orphanage.shionn.org
Label: orphanage.shionn.org
Codename: experimental
Architectures: amd64
Components: main
Description: Orphanage repository by shionn
SignWith: yes
" > www/conf/distributions

mkdir -p temp/experimental
mkdir -p temp/trixie

mv temp/*~*.deb build/experimental/
mv temp/*.deb   build/trixie/

reprepro -b www/ includedeb trixie       build/trixie/*.deb
reprepro -b www/ includedeb experimental build/experimental/*.deb

reprepro -b www/ export trixie
reprepro -b www/ export experimental

rm build/experimental/*.deb
rm build/trixie/*.deb