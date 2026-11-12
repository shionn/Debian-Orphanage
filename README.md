
# Repository debian pour package orphelin

L'idée c'est de faire unr epository qui contient tous les paquets debian (que je trouve utile) qui n'ont pas de repo officiel en un seul repo. 

## Installation

~~~
wget https://shionn.github.io/Debian-Orphanage/pool/main/o/orphanage-keyring/orphanage-keyring_1.0.3_all.deb
sudo apt install ./orphanage-keyring_1.0.3_all.deb
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



# Construction

WIP

Pour reconstruire votre repo vous devez executer les scripts present dans src un par un mais certain script necessiterons d'etre adapter à vos target. 
