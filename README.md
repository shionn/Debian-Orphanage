
# Repository debian pour package orphelin

L'idée c'est de faire unr epository qui contient tous les paquets debian (que je trouve utile) qui n'ont pas de repo officiel en un seul repo. 

## Installation

~~~
wget https://shionn.github.io/Debian-Orphanage/pool/main/o/orphanage-keyring/orphanage-keyring_1.0.3_all.deb
sudo apt install ./orphanage-keyring_1.0.3_all.deb
sudo apt update
~~~

## Contenu

- bc-250-control-center
- discord
- faugus-launcher
- freetube
- heroic-game-launcher
- hydra-launcher
- hyprshot
- openrgb
- recomp-launcher
- umu-launcher



# Construction

WIP

Pour reconstruire votre repo vous devez executer les scripte present dans src un par un mais certain script necessiterons d'etre adapter à vos target. 
