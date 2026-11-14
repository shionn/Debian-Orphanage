
# Repository debian pour package orphelin

L'idée c'est de faire un repository qui contient tous les paquets debian (que je trouve utile) qui n'ont pas de repo officiel en un seul repo. 

## Installation

~~~
wget https://shionn.github.io/Debian-Orphanage/pool/main/o/orphanage-keyring/orphanage-keyring_1.0.4_all.deb
sudo apt install ./orphanage-keyring_1.0.4_all.deb
sudo apt update
~~~

## Contenu

- [BC250 Control Center](https://github.com/movacx/bc250-control-center)
- [Discord](https://discord.com/)
- [Faugus Launcher](https://github.com/Faugus/faugus-launcher)
- [FreeTube](https://freetubeapp.io/)
- [Heroic Game Launcher](https://heroicgameslauncher.com/)
- [Hydra Launcher](https://hydralauncher.gg/)
- [Hyprshot](https://github.com/Gustash/Hyprshot)
- [OpenRGB](https://openrgb.org/)
- [Recomp Launcher](https://recomplauncher.com/)
- [umu](https://github.com/Open-Wine-Components/umu-launcher)

## Contenu futur 

- GE Proton 9/10/11
- Echoes of the forgotten deep
- GameLauncher


# Construction

## Generation d'une clef gpg

TODO expliquer comment generer.

## Sur votre propre serveur

Executer une premiere fois `src/00-init`

Editer le fichier `update.sh` en changeant `host` et `dest`: 

~~~
host=orphanage.shionn.org
dest=/var/www/html
~~~

Executer `update.sh`

## sur github

Forker ou copier ce projet à votre guise. Importer dans les sercrets de voter projet sur github votre clef gpg. 
TODO expliquer comment faire.

Modifier le fichier package.yaml en modifiant l'url de deploiement.

WIP

Pour reconstruire votre repo vous devez executer les scripts present dans src un par un mais certain script necessiterons d'etre adapter à vos target. 
