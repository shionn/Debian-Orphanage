#!/bin/bash

# ce bash est executé sur le serveur perso pour generer le keyring

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

reprepro -b docs includedeb trixie       build/trixie-github/*/*.deb

if [[ `git status --porcelain` ]]
then
	git add --all
	git commit -am "Auto Build"
	git push
fi