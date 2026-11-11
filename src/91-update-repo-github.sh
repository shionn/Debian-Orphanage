#!/bin/bash

mkdir -p docs/conf/

echo "Origin: shionn.github.io/Debian-Orphanage
Label: shionn.github.io/Debian-Orphanage
Codename: trixie
Architectures: amd64
Components: main
Description: Orphanage repository by shionn
SignWith: yes

Origin: shionn.github.io/Debian-Orphanage
Label: shionn.github.io/Debian-Orphanage
Codename: experimental
Architectures: amd64
Components: main
Description: Orphanage repository by shionn
SignWith: yes
" > docs/conf/distributions

#mkdir -p temp/experimental
#mkdir -p temp/trixie

#mv temp/*~*.deb build/experimental/
#mv temp/*.deb   build/trixie/

reprepro -b docs includedeb trixie       build/trixie-github/*/*.deb
reprepro -b docs includedeb trixie       build/trixie/*/*.deb
reprepro -b docs includedeb experimental build/experimental/*/*.deb

reprepro -b docs export trixie
reprepro -b docs export experimental

#rm build/experimental/*.deb
#rm build/trixie/*.deb

if [[ `git status --porcelain` ]]
then
	git add --all
	git commit -am "Auto Build"
	git push
fi