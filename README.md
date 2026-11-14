
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
- GODOT

# Construction

## Sur votre propre serveur

Executer une premiere fois `src/00-init`. Cela installera les dependance necessaire du projet et générera la clef de siganture nécéssaire. La clef doit etre **sans mot de passe** pour que les script s'éxécute tous seul.

Editer le fichier `update.sh` en changeant `host` et `dest`:

~~~
host=orphanage.shionn.org
dest=/var/www/html
~~~

Executer `update.sh`

## sur github

Forker ou copier ce projet à votre guise.
Sur votre ordinateur généré votre propre clef de signature avec `gpg --generate-key`.
La clef doit etre **sans mot de passe** pour que les script s'éxécute tous seul.
 
Puis importer votre clef GPG comme secret du repo GitHub `Debian-Orphanage` :

    gpg --export-secret-keys | base64 -w0

    Settings → Secrets and variables → Secrets → New repository secret
    Nom : GPG_PRIVATE_KEY
    Valeur : le resultat de la commande ci-dessus

Le workflow GitHub la lit via `${{ secrets.GPG_PRIVATE_KEY }}` pour signer les paquets.

Modifier l'URL de deploiement dans `.github/workflows/packages.yml` (serveur GitHub).
