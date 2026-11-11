#!/bin/bash

mkdir -p /var/www/html/conf/

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
" > /var/www/html/conf/distributions

#mkdir -p temp/experimental
#mkdir -p temp/trixie

#mv temp/*~*.deb build/experimental/
#mv temp/*.deb   build/trixie/

reprepro -b /var/www/html includedeb trixie       build/trixie/*/*.deb
reprepro -b /var/www/html includedeb experimental build/experimental/*/*.deb

reprepro -b /var/www/html export trixie
reprepro -b /var/www/html export experimental

#rm build/experimental/*.deb
#rm build/trixie/*.deb