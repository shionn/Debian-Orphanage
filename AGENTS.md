# AGENTS.md — Orphanage

Règles pour maintenir ce projet. Pour les faits durables transversaux, voir la mémoire.
⚠️ Les scripts évoluent sans toujours avertir : **relire l'état réel** avant de s'appuyer sur cette doc ou `agent/reference.md`.

## Ce que c'est
Dépôt Debian personnalisé (`orphanage.shionn.org`) hébergeant les paquets tiers **orphelins** de Debian + projets packagés par shionn. Signé en GPG.

## Environnement
Cloné dans un **container Debian Proxmox** `Orphanage`, au chemin **`/root/Orphanage`**. Tous les scripts s'exécutent depuis ce dossier.

## Conventions
- **Scripts `src/`** : préfixe numérique = ordre d'exécution.
  - `00-` à `09-` : init/setup (une fois, ou très rarement).
  - `10-` à `89-` : un script par package (récupération/construction).
  - `90-` : mise à jour du repo (`reprepro`).
  - `99-functions.sh` : **librairie à `source`** (pas exécutée dans l'ordre).
- **Un seul dépôt** : `reprepro/` → `orphanage.shionn.org` (local).
- **`update.sh`** (racine) exécute les scripts `10-*` à `89-*` dans l'ordre (set -e).
- **Référence** : `agent/reference.md` — le relire/mettre à jour avant toute modification.
- **Signature** : les `.deb` doivent être signés par la clé shionn (`SignWith: yes`).

## Sécurité
- **La clé privée GPG reste locale** (`~/.gnupg`), **hors git**. Les scripts ne contiennent qu'un identifiant (`SignKey:`).
## Flux actuel (cohérent)
Scripts 10-16 déposent les `.deb` dans `build/trixie/<pkg>/<fichier>.deb`. `90-update-repo.sh` inclut via `build/trixie/*/*.deb` (2 niveaux) et exporte le pool vers `/var/www/html/pool/` (config root `-b /var/www/html`). À exécuter depuis la racine du projet.
`90-update-repo.sh` inclut les `.deb` à 2 niveaux : `build/trixie-local/*/*.deb` (keyring-local), `build/trixie/*/*.deb` (packages) et `build/experimental/*/*.deb`, puis exporte le pool vers `/var/www/html/pool/` (config root `-b /var/www/html`). Flux cohérent : les packages déposés dans `build/trixie/<pkg>/` sont bien retrouvés.

## À ne pas faire
- Ne pas déplacer de fichiers hors de leur rôle (ex. ne pas briser le flux `build/` → `www/`).
- Ne pas modifier les valeurs clés (Origin, codenames, maintainer) sans raison.

## Scripts keyring (2 dépôts)
Deux scripts, version `1.0.4`, produisent le paquet `orphanage-keyring` (même clé GPG, deux serveurs distincts) :
- `01-keyring-local.sh` : dépose dans `build/trixie-local/keyring/`, URI `http://orphanage.shionn.org` (dépôt local). Inclus par `90-update-repo.sh` (L28).
- `01-keyring-github.sh` : dépose dans `build/trixie-github/keyring/`, URI `https://shionn.github.io/Debian-Orphanage` (dépôt GitHub). Inclus par `91-update-repo-github.sh`.
- `92-update-repo-github-keyring.sh` : régénère `docs/conf/distributions`, puis `includedeb` depuis `build/trixie/*/*.deb` + `git push` (serveur GitHub).
