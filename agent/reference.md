# Orphanage — Référence du projet (agent/)

> Fichier de référence durable pour reconstruire et maintenir le projet.
> À relire et mettre à jour par toute session de travail.
> ⚠️ Les scripts évoluent sans toujours avertir : vérifier l'état réel avant de s'appuyer sur cette doc.

## 1. Contexte & but
- **Nom du projet :** Orphanage
- **Mainteneur :** Shionn <shionn@gmail.com> (pseudo : `shionn`)
- **Hôte du dépôt :** `orphanage.shionn.org` (repo **local**, seul dépôt concerné)
- **Signature GPG :** oui — les `.deb` sont signés (`SignWith: yes`)
- **Objectif :** rassembler les paquets Debian tiers **orphelins** (aucun repo, aucun extrepo) + des projets packagés personnellement par shionn.
- **Sources des paquets :** releases d'un repo GitHub (via l'API GitHub), sauf exceptions (ex. `16-recomp-launcher` via curl direct).

## 2. Environnement d'exécution
- Un **container Debian** Proxmox nommé **`Orphanage`**.
- Le projet + son **repo git** sont clonés dans **`/root/Orphanage`** (dans ce container).
- Tous les scripts `src/` s'exécutent depuis ce dossier, successivement.

| Chemin | Rôle |
|---|---|
| `src/` | Scripts ordonnés par préfixe numérique |
| `build/trixie/<pkg>/` | `.deb` téléchargés par chaque script packageur (sous-dossier par package) |
| `build/` | Dossier racine du travail (scripts packageurs y déposent `trixie/<pkg>/`) |
| `/var/www/html/` | **Config root + webroot de reprepro** (`-b /var/www/html`, `conf/distributions`, `pool/` servi) |
| `/var/www/html/pool/` | Pool exporté, servi par lighttpd/webroot |
| `temp/` | Ancienne zone tampon du keyring (plus utilisée) |
| `agent/reference.md` | Ce fichier |
| `update.sh` | Exécute tous les scripts de packages (10–89) dans l'ordre |
| `README.md` | Notice courte |
| Chemin | Rôle |
|---|---|
| `src/` | Scripts ordonnés par préfixe numérique |
| `reprepro/` | Config + pool du dépôt local (`orphanage.shionn.org`) |
| `build/trixie/<pkg>/` | `.deb` téléchargés par chaque script packageur (sous-dossier par package) |
| `build/` | Dossier racine du travail (attendu par `90-update-repo.sh`, cf. incohérence §10) |
| `build/experimental/` | `.deb` expérimentaux (cf. `90-update-repo.sh`) |
| `temp/` | Ancienne zone tampon du keyring (plus utilisée) |
| `www/` | Export du dépôt `reprepro`, servi via `http://orphanage.shionn.org/` |
| `agent/reference.md` | Ce fichier |
| `update.sh` | Exécute tous les scripts de packages (10–89) dans l'ordre |
| `README.md` | Notice courte |

### Convention de noms de scripts (ordre d'exécution par index)
| Plage | Rôle | Fréquence |
|---|---|---|
| `00-` à `09-` | Initialisation / setup / infra | une fois, ou très rarement |
| `10-` à `89-` | Récupération ou construction d'un paquet (**un script par package**) | à la demande |
| `90-` | Mise à jour du repo (`reprepro`) | après chaque nouveau paquet |
| `99-functions.sh` | **Bibliothèque de fonctions** réutilisables — **`source`**e, pas exécutée dans l'ordre | toujours avant usage |
| `update.sh` (racine) | Lance les scripts `10-*` à `89-*` dans l'ordre | après ajout d'un nouveau package |

> ⚠️ **Tension de convention :** `99-functions.sh` porte un préfixe numérique mais est une **librairie à `source`**, pas un script ordonné. Les scripts qui l'utilisent doivent faire `source "src/99-functions.sh"` (idéalement en tête de fichier).

## 4. Workflow de reconstruction
Exécuter les scripts `src/` dans l'ordre croissant de leur index :

```
./src/00-init.sh            # setup (une fois)
source ./src/99-functions.sh
./src/01-keyring.sh <FINGERPRINT>
./src/NN-pkg.sh             # un par package (10–89)
./src/90-update-repo.sh     # rebuild du dépôt
```

Ou, pour tout le lot de packages, depuis la racine :
```bash
bash update.sh              # exécute src/10-* à src/89-* dans l'ordre (set -e : arrêt à la 1ère erreur)
```
- **`90-update-repo.sh`** :
  - Écrit `conf/distributions` à **`/var/www/html/conf/distributions`** (Origin/Label `orphanage.shionn.org`, Codenames `trixie` + `experimental`, Composant `main`, Arch `amd64`, `SignWith: yes`).
  - `reprepro -b /var/www/html includedeb trixie build/trixie/*/*.deb` → inclut tous les `.deb` à deux niveaux (`build/trixie/<pkg>/<fichier>.deb`) — correspond au dépôtage des scripts packageurs.
  - `reprepro -b /var/www/html includedeb experimental build/experimental/*/*.deb` → experimental (matches rien tant qu'aucun package n'y est déposé).
  - `reprepro -b /var/www/html export trixie` / `export experimental` → exporte le pool vers `/var/www/html/pool/` (servi par lighttpd/webroot).
  - Le script doit être exécuté depuis la **racine du projet** (`/root/Orphanage`) pour que `build/trixie/*/*.deb` se résolve.
  - Les anciennes lignes `mv temp/*`/`build/trixie/` sont **commentées** — ne pas les activer sans raison.
### Obtenir le fingerprint GPG
```
gpg --list-secret-key
```
→ récupérer l'empreinte hexa (~40 caractères) sous la ligne `sec` (clé principale).

### Rôle de chaque script (état actuel)
- **`00-init.sh`** :
  - Installe `reprepro` et `lighttpd` (serveur web du dépôt).
  - ⚠️ Contient une faute de frappe : `apt instal` (manque un `l`). À corriger.
- **`01-keyring.sh`** :
  - Vérifie d'abord que le fingerprint est fourni (`$1`) ; sinon erreur + usage + `exit 1`.
  - Construit le paquet `orphanage-keyring` (**version `1.0.2`**).
  - `DEBIAN/control` : `misc / optional / all`.
  - Installe la clé sous `/usr/share/keyrings/orphanage.shionn.org.gpg` (via `gpg --export-options export-minimal`).
  - Crée l'entry apt au **format `.sources`** : `etc/apt/sources.list.d/orphanage.shionn.org.sources` (`Types: deb`, `URIs:`, `Suites: trixie`, `Components: main`, `Signed-By:`).
  - Sortie : le `.deb` est déposé dans **`build/trixie/keyring/`**.
- **`90-update-repo.sh`** :
  - Écrit `www/conf/distributions` (Origin/Label `orphanage.shionn.org`, Codenames `trixie` + `experimental`, Composant `main`, Arch `amd64`).
  - Sépare les `.deb` : trixie = stable (`build/*.deb`), experimental = le reste (`build/*~*.deb`).
  - `reprepro -b www/` : build → export des deux composants.
  - ⚠️ Lit `build/*.deb` (plateforme) alors que les packages sont dans `build/trixie/<pkg>/` → cf. incohérence §10.

### Fonction réutilisable : `download_github` (`99-functions.sh`)
Télécharge les assets d'une **release** d'un repo GitHub.
```bash
download_github <author> <repo> [pattern]   # pattern : regex ERE, défaut : .*\.deb
```
- Récupère la release la plus récente via `https://api.github.com/repos/<author>/<repo>/releases/latest`.
- Lit les `browser_download_url` des assets (nécessite **`jq`**).
- **`pattern` est une regex ERE** (match `[[ =~ ]]`) : seuls les noms de fichier correspondants sont téléchargés, le reste est ignoré.
- **`--exclude` supprimé** (le regex positif exprime directement ce qu'on garde).
- Télécharge dans le **dossier courant** sous le nom du fichier (`basename` de l'URL).
- Dépendances : `curl`, `jq`.

Exemple validé par shionn (umu : garde le `.deb` amd64, exclut implicitement `debian-12`/`arm64`/`ubuntu`/`.rpm`/`.tar`) :
```bash
download_github umu umu-core "^umu-.*_[0-9][^_]*_amd64\.deb$"
```

### Packages actuels (10–16)
Chaque script fait `mkdir -p build/trixie/<pkg>/` puis `cd` dedans, puis `download_github`.
| Script | Package | Source | Regex |
|---|---|---|---|
| `10-umu.sh` | umu-launcher | GitHub `Open-Wine-Components/umu-launcher` | `.*(amd64\|all)_debian-13.deb` (amd64 + all) |
| `11-openrgb.sh` | openrgb | GitHub `CalcProgrammer1/OpenRGB` | `.*amd64_trixie_.*.deb` |
| `12-bc250.sh` | bc250-control-center | GitHub `movacx/bc250-control-center` | `.*.deb` (tout) |
| `13-hydra-launcher.sh` | hydra | GitHub `hydralauncher/hydra` | `.*.deb` (tout) |
| `14-heroic-games-launcher.sh` | heroic-games-launcher | GitHub `Heroic-Games-Launcher/HeroicGamesLauncher` | `.*amd64.deb` |
| `15-faugus-launcher.sh` | faugus-launcher | GitHub `Faugus/faugus-launcher` | `.*.deb` (tout) |
| `16-recomp-launcher.sh` | recomp-launcher | **curl direct** `recomplauncher.com/api/launcher-beta.php?a=download&os=deb` | — (hors `download_github`, `99-functions.sh` commenté) |

> **`16-recomp-launcher.sh`** ne suit pas le modèle : pas de `download_github`, source externe (`recomplauncher.com`). À aligner si possible, ou documenter comme exception.

## 5. Flux d'un nouveau paquet
1. Récupérer/construire le paquet orphelin → produire un `.deb`, ex. via `download_github`.
2. Faire traiter le paquet par son script dédié (`NN-pkg.sh`, 10–89), qui dépose le `.deb` dans `build/trixie/<pkg>/`.
3. Rebuild du dépôt : `./src/90-update-repo.sh`.
4. Le paquet apparaît dans `www/` (trixie ou experimental selon le nom).

## 6. Orchestration
- `update.sh` (racine) exécute les scripts `10-*` à `89-*` dans l'ordre, avec `set -e` (arrêt à la première erreur).
- Lancement automatique global : **crontab ou script racine** à préciser (cadence, dépendances, gestion des échecs, idempotence).

## 7. Signature GPG (export)
- **Une seule clé** : ta clé GPG personnelle (actuellement ed25519, `sec` + sous-clé `ssb` cv25519).
- **reprepro** signe les `.deb` + `Release` avec **ta clé secrète**.
- **`orphanage-keyring`** (`01-keyring.sh`) exporte ta **clé publique** → vérification côté client.
- La clé privée vit dans `~/.gnupg` (locale, **hors git**) ; les scripts ne contiennent qu'un identifiant (`SignKey:`).
- **Clé de signature sans mot de passe** : l'export automatisé ne peut pas demander de passphrase (erreur `GPGME:54: Unusable secret key`). Utilise une clé dédiée sans passphrase.

## 8. Outils utilisés
- `reprepro` — construction/export du dépôt Debian.
- `lighttpd` — serveur web du dépôt (`www/`).
- `dpkg -b` — assemblage des paquets.
- `gpg` — export de la clé de signature.
- `curl`, `jq` — téléchargement des paquets depuis GitHub (fonction `download_github`).

## 9. Valeurs clés / constantes
| Élément | Valeur |
|---|---|
| Origin / Label | `orphanage.shionn.org` |
| Codenames | `trixie` (stable), `experimental` |
| Composant | `main` |
| Architecture | `amd64` |
| Maintainer (control) | `Shionn <shionn@gmail.com>` |
| Package keyring | `orphanage-keyring` v`1.0.2` |
| Chemin d'installation | `/root/Orphanage` (container Debian) |

## 10. Questions ouvertes / TODO
- **`16-recomp-launcher.sh`** : hors modèle (`curl` direct, source externe) — aligner ou documenter comme exception.
- **`99-functions.sh`** : convention « ordre d'exécution » vs « librairie à `source` » — à clarifier.
- **`00-init.sh`** : `apt instal` (typo) à corriger en `apt install`.
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).
- **Config root / webroot :** reprepro utilise `-b /var/www/html` et écrit `conf/distributions` à `/var/www/html/conf/`. Le pool exporté est servi depuis `/var/www/html/pool/`. Vérifier que lighttpd/webroot sert bien `/var/www/html/` et que l'URI apt (`orphanage.shionn.org/`) pointe vers ce pool.
- **Experimental :** `includedeb experimental build/experimental/*/*.deb` ne matche rien tant qu'aucun package n'est déposé dans `build/experimental/`. Décider si un package peut aller en experimental (et comment).
- **`16-recomp-launcher.sh`** : hors modèle (`curl` direct, source externe) — aligner ou documenter comme exception.
- **`99-functions.sh`** : convention « ordre d'exécution » vs « librairie à `source` » — à clarifier.
- **`00-init.sh`** : `apt instal` (typo) à corriger en `apt install`.
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).
- **⚠️ Incohérence de chemins :** les scripts packageurs déposent les `.deb` dans **`build/trixie/<pkg>/`** (sous-dossier), mais `90-update-repo.sh` fait `mv build/*.deb build/trixie/` et lit `build/trixie/*.deb` (plateforme).
  → Les `.deb` ne sont jamais à la racine de `build/`. `90-update-repo.sh` ne trouvera pas les packages. À corriger (recursion `build/trixie/*/` ? ou scripts qui déposent à `build/` ?).
- **Orchestration :** crontab vs script racine — à choisir et documenter.
- **`16-recomp-launcher.sh`** : hors modèle (`curl` direct, source externe) — aligner ou documenter comme exception.
- **`99-functions.sh`** : convention « ordre d'exécution » vs « librairie à `source` » — à clarifier.
- **`00-init.sh`** : `apt instal` (typo) à corriger en `apt install`.
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).
