
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
- [Fluxer](https://fluxer.com/)
- [FreeTube](https://freetubeapp.io/)
- [Heroic Game Launcher](https://heroicgameslauncher.com/)
- [GE-Proton 9/10/11](https://github.com/GloriousEggroll/proton-ge-custom)
- [Godot4](https://godotengine.org/fr/)
- [Hydra Launcher](https://hydralauncher.gg/)
- [Hyprshot](https://github.com/Gustash/Hyprshot)
- [Lib Hidapi Hotplug](https://codeberg.org/OpenRGB/hidapi-hotplug) dépendance de OpenRGB
- [OpenRGB](https://openrgb.org/)
- [Recomp Launcher](https://recomplauncher.com/)
- [umu](https://github.com/Open-Wine-Components/umu-launcher)

## Contenu futur

- Echoes of the forgotten deep
- GameLauncher
- eclipse
- fluxer

# Construction

Si vous voulez construire votre propre serveur.

## Sur votre propre serveur

Exécuter une première fois `src/00-init`. 
Cela installera les dépendances nécessaires du projet et générera la clef de signature nécessaire. 
La clef doit être **sans mot de passe** pour que les scripts s'exécutent tous seuls.

Éditer le fichier `update.sh` en changeant `host` et `dest`:

~~~
host=orphanage.shionn.org
dest=/var/www/html
~~~

Exécuter `update.sh`

## sur github

Faire un fork ou copier ce projet à votre guise.
Sur votre ordinateur, générez votre propre clef de signature avec `gpg --generate-key`.
La clef doit être **sans mot de passe** pour que les scripts s'exécutent tous seuls.
Puis importer votre clef GPG comme secret du repo GitHub `Debian-Orphanage` :

    gpg --export-secret-keys --armor TA_CLE@exemple.com | base64 -w0

    Settings → Secrets and variables → Secrets → New repository secret
    Nom : GPG_PRIVATE_KEY
    Valeur : le résultat de la commande ci-dessus

Le workflow GitHub la lit via `${{ secrets.GPG_PRIVATE_KEY }}` pour signer les paquets.

Modifier l'URL de déploiement dans `.github/workflows/packages.yml` (serveur GitHub).
