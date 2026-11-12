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
| `build/` | Dossier racine du travail (déposé par les scripts packageurs, lu par `90-update-repo.sh` à 2 niveaux : `build/trixie-*/*/*.deb` + `build/experimental/*/*.deb`) |
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
./src/01-keyring-local.sh <URI>      # fingerprint auto (clé secrète GPG), URI obligatoire
./src/01-keyring-github.sh         # idem
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
### Obtenir le fingerprint GPG
Le fingerprint est récupéré **automatiquement** depuis la clé secrète GPG — plus besoin de le passer en paramètre :
```bash
sign=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')
```
→ `--with-colons` (format colon) + `awk -F: '/^fpr:/' {print $10; exit}` prend le **premier** `fpr:` = empreinte hexa de la clé principale (~40 caractères). Si vide → erreur + `exit 1`.

```bash
sign=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')
```
→ `--with-colons` (format colon) + `awk -F: '/^fpr:/' {print $10; exit}` prend le **premier** `fpr:` = empreinte hexa de la clé principale (~40 caractères). Si vide → erreur + `exit 1`.

### Rôle de chaque script (état actuel)
- **`00-init.sh`** :
  - Installe `reprepro` et `lighttpd` (serveur web du dépôt).
- **`01-keyring-local.sh`** (et `01-keyring-github.sh`, mêmes mécanismes, version `1.0.4`) :
  - Le **fingerprint** GPG est récupéré **automatiquement** depuis la clé secrète (`gpg --list-secret-keys --with-colons | awk ...`) — plus de paramètre requis ; sinon erreur + `exit 1`.
  - **`01-keyring-local.sh`** : l'URI est un **paramètre obligatoire** (`$1`) qui définit le dépôt vers lequel pointer le keyring ; sinon erreur + usage + `exit 1`.
  - **`01-keyring-github.sh`** : l'URI reste **en dur** (`https://shionn.github.io/Debian-Orphanage`) — aucun paramètre.
  - Construit le paquet `orphanage-keyring` (version `1.0.4`).
  - `DEBIAN/control` : `misc / optional / all`.
  - Installe la clé sous `/usr/share/keyrings/orphanage.<project>.pgp` (via `gpg --export-options export-minimal`).
  - Crée l'entry apt au **format `.sources`** : `etc/apt/sources.list.d/orphanage.<project>.sources` (`Types: deb`, `URIs:`, `Suites: trixie`, `Components: main`, `Signed-By:`).
  - Sortie : le `.deb` est déposé dans **`build/trixie-local/keyring/`** (local) ou **`build/trixie-github/keyring/`** (GitHub).
- **`90-update-repo.sh`** :
  - Écrit `conf/distributions` à `/var/www/html/conf/distributions` (Origin/Label `orphanage.shionn.org`, Codenames `trixie` + `experimental`, Composant `main`, Arch `amd64`, `SignWith: yes`).
  - `includedeb` à 2 niveaux : `reprepro -b /var/www/html includedeb trixie build/trixie-local/*/*.deb` puis `build/trixie/*/*.deb` (récupère les packages ET le keyring-local), et `includedeb experimental build/experimental/*/*.deb`.
  - `reprepro -b /var/www/html export trixie` / `export experimental` → exporte le pool vers `/var/www/html/pool/` (servi par lighttpd/webroot).
  - Doit être exécuté depuis la **racine du projet** (`/root/Orphanage`) pour que `build/trixie/*/*.deb` se résolve.
  - Les anciennes lignes `mv temp/*`/`build/trixie/` sont **commentées** — ne pas les activer sans raison.
- **`91-update-repo-github.sh`** :
  - Régénère `docs/conf/distributions` (Origin/Label `shionn.github.io/Debian-Orphanage`, codenames `trixie` + `experimental`).
  - `reprepro -b docs includedeb trixie build/trixie-github/*/*.deb` (keyring GitHub) puis export trixie/experimental.
- **`92-update-repo-github-keyring.sh`** :
  - Régénère `docs/conf/distributions`, puis `includedeb trixie build/trixie/*/*.deb` + export, suivi d'un `git push` vers le dépôt GitHub.

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
### Fonction réutilisable : `download_github` (`99-functions.sh`)
Télécharge les assets d'une **release** d'un repo GitHub.
```bash
download_github <author> <repo> [pattern] [release|pre-release]   # pattern : regex ERE, défaut : .*\.deb
```
- Récupère la release la plus récente via `https://api.github.com/repos/<author>/<repo>/releases/latest`.
- **`pattern`** : regex ERE (`[[ =~ ]]`) — seuls les noms de fichier correspondants sont téléchargés.
- **4e argument** : `release` (défaut, stable) ou `pre-release` → ajoute `?pre=1` à l'API pour inclure les prereleases.
- **`--exclude` supprimé** (le regex positif exprime directement ce qu'on garde).
- Télécharge dans le **dossier courant** sous le nom du fichier (`basename` de l'URL).
- Dépendances : `curl`, `jq`.

Exemple validé par shionn (umu : garde le `.deb` amd64, exclut implicitement `debian-12`/`arm64`/`ubuntu`/`.rpm`/`.tar`) :
```bash
download_github umu umu-core "^umu-.*_[0-9][^_]*_amd64\.deb$"
Exemple avec prereleases :
```bash
download_github author repo ".*\.deb" pre-release
```

### Fonction réutilisable : `github_get_last_release_tag` (`99-functions.sh`)
Récupère le **tag_name** de la dernière release (pour cloner/git).
```bash
TAG=$(github_get_last_release_tag <author> <repo>)   # retourne le tag, 0=OK / 1=erreur
```
- Utilise `releases/latest`, `jq -r '.tag_name'`.
- **`return 1` / `return 0`** (correct — ne tue pas le script appelant).
- Exemple : `18-hyprshot.sh` fait `version=$(github_get_last_release_tag Gustash Hyprshot)`.

### Fonction réutilisable : `download_github_last_tag` (`99-functions.sh`)
Télécharge les assets d'une release dont le **tag_name** correspond à un pattern (pour cloner/git sur un tag précis).
```bash
download_github_last_tag <author> <repo> <pattern-fichier> <pattern-tag>
```
- Récupère `releases?per_page=50`, parcourt les `tag_name` (plus récents d'abord) et prend le **premier** correspondant au `pattern-tag` (regex ERE).
- Télécharge les assets de cette release dont le nom correspond au `pattern-fichier` (regex ERE, comme `download_github`).
- Expose le tag retenu via la variable globale **`LAST_GITHUB_TAG`** (à lire dans le script appelant — ex. `20-proton.sh`).
- **`return 1` / `return 0`** (ne tue pas le script appelant) ; message « Aucune release ... » si aucun tag ne correspond.
- Exemple : `download_github_last_tag GloriousEggroll proton-ge-custom '.*\.tar\.gz' 'GE-Proton9-.*'` puis `version="${LAST_GITHUB_TAG}"`.


> ⚠️ **`download_github`** utilise encore `exit 1` sur erreur (ligne 31) — ça marche via `update.sh` (`if ! bash "$script"`), mais devrait être `return 1` pour être portable.
Exemple avec prereleases :
```bash
download_github author repo ".*\.deb" pre-release
```
|---|---|---|---|
| `10-umu.sh` | umu-launcher | GitHub `Open-Wine-Components/umu-launcher` | `.*(amd64\|all)_debian-13.deb` (amd64 + all) |
| `11-openrgb.sh` | openrgb | GitHub `CalcProgrammer1/OpenRGB` | `.*amd64_trixie_.*.deb` |
| `16-recomp-launcher.sh` | recomp-launcher | **curl direct** `recomplauncher.com/api/launcher-beta.php?a=download&os=deb` | — (hors `download_github`, `99-functions.sh` commenté) |
| `17-freetube.sh` | freetube | à confirmer | — |
| `18-hyprshot.sh` | hyprshot | `git clone -b $tag` GitHub + `dpkg -b` (build complet d'un DEB) | utilise `github_get_last_release_tag` |
| `13-hydra-launcher.sh` | hydra | GitHub `hydralauncher/hydra` | `.*.deb` (tout) |
| `14-heroic-games-launcher.sh` | heroic-games-launcher | GitHub `Heroic-Games-Launcher/HeroicGamesLauncher` | `.*amd64.deb` |
| `15-faugus-launcher.sh` | faugus-launcher | GitHub `Faugus/faugus-launcher` | `.*.deb` (tout) |
| `16-recomp-launcher.sh` | recomp-launcher | **curl direct** `recomplauncher.com/api/launcher-beta.php?a=download&os=deb` | — (hors `download_github`, `99-functions.sh` commenté) |

> **`16-recomp-launcher.sh`** ne suit pas le modèle : pas de `download_github`, source externe (`recomplauncher.com`). À aligner si possible, ou documenter comme exception.
- **`update.sh`** (racine) exécute les scripts `10-*` à `89-*` dans l'ordre :
  - Extraction du préfixe corrigée : `basename="${script##*/}"` puis `prefix="${basename%%[!0-9]*}"` (sinon `src/` donne une chaîne vide → aucun script traité).
  - Gestion d'erreur robuste : `if ! bash "$script"` → un échec de package ne tue pas la boucle (avertissement en stderr).
  - À la fin : `bash "src/90-update-repo.sh"` (publication du repo).
  - `set -e` présent — un échec direct (hors `if !`) arrête tout.
## 5. Flux d'un nouveau paquet
1. Récupérer/construire le paquet orphelin → produire un `.deb`, ex. via `download_github`.
2. Faire traiter le paquet par son script dédié (`NN-pkg.sh`, 10–89), qui dépose le `.deb` dans `build/trixie/<pkg>/`.
3. Rebuild du dépôt : `./src/90-update-repo.sh`.
4. Le paquet apparaît dans `www/` (trixie ou experimental selon le nom).

## 6. Orchestration
- `update.sh` (racine) exécute les scripts `10-*` à `89-*` dans l'ordre, avec `set -e` (arrêt à la première erreur).
- Lancement automatique global : **crontab ou script racine** à préciser (cadence, dépendances, gestion des échecs, idempotence).
- **`.github/workflows/packages.yml`** (workflow GitHub Actions, iter 1) :
  - **`on: push`** sur `main`/`master` (déclenchement auto, plus qu'`workflow_dispatch`).
  - `runs-on: ubuntu-latest` (GitHub-hosted suffit — **pas de self-hosted debian-13**).
  - `permissions` : `contents: read`, `pages: write`, `id-token: write` ; `environment: github-pages`.
  - Étapes : checkout → `apt-get install jq reprepro` → boucle `10-*` à `89-*` (chacun `source`e `99-functions.sh`, **fix prefix : `basename="${script##*/}"` puis `prefix="${basename%%[!0-9]*}"` sinon le glob `src/*.sh` ne matche rien → 0s) → step `Importer la clé GPG` → `src/91-update-repo-github.sh` (`continue-on-error: true`) → `actions/deploy-pages@v4` déploie `./docs` (via API Pages, **AUCUN push git**).
  - `91` ne pousse PAS : son `git push` (anciennement L40-45) est commenté.
  - `build/` est dans `.gitignore` → le workflow ne committe que `docs/`.
  - **Bloc `env:`** dans le step import : `KEY: ${{ secrets.GPG_PRIVATE_KEY }}` → `echo "$KEY" | tr -d '[:space:]' | base64 -d | gpg --import`.
  - ⚠️ Sans le secret `GPG_PRIVATE_KEY`, `91` échoue à signer (SignWith: yes) → `continue-on-error` → `docs/` déployé mais **sans keyring GitHub** → repo GitHub a des `.deb` signés mais **pas installable via apt** (le keyring GitHub = `01-keyring-github.sh` → `92-update-repo-github-keyring.sh` n'est PAS dans ce workflow).

## 7. Signature GPG (export)
- **Une seule clé** : ta clé GPG personnelle (actuellement ed25519, `sec` + sous-clé `ssb` cv25519).
- **reprepro** signe les `.deb` + `Release` avec **ta clé secrète**.
- **`download_github`** : `exit 1` sur erreur (ligne 31) — fonctionnel via `update.sh` (`if !`), mais devrait être `return 1`.
- **`00-init.sh`** : `apt instal` (typo) à corriger en `apt install`.
- **`18-hyprshot.sh`** : `exit 1` sur vraie erreur (ligne 12) — OK (vrai échec), mais `exit 0` sur « a jour » (ligne 18).
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).
- La clé privée vit dans `~/.gnupg` (locale, **hors git**) ; les scripts ne contiennent qu'un identifiant (`SignKey:`).
- **Clé de signature sans mot de passe** : l'export automatisé ne peut pas demander de passphrase (erreur `GPGME:54: Unusable secret key`). Utilise une clé dédiée sans passphrase.
- **Secret GitHub** : la clé privée est un **repository secret** `GPG_PRIVATE_KEY` dans le repo `Debian-Orphanage` (Settings → Secrets and variables → **Secrets**, valeur = base64 `base64 -w0` de l'export secret-key). Le workflow la lit via `${{ secrets.GPG_PRIVATE_KEY }}`. `longueur=${#GPG_PRIVATE_KEY}` = 0 → le secret n'est pas lu (nom, section, ou valeur vide).

## 8. Outils utilisés
- `reprepro` — construction/export du dépôt Debian.
- `lighttpd` — serveur web du dépôt (`www/`).
| Package keyring | `orphanage-keyring` v`1.0.4` |
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
| Package keyring | `orphanage-keyring` v`1.0.4` |
| Chemin d'installation | `/root/Orphanage` (container Debian) |

## 10. Questions ouvertes / TODO
- **`16-recomp-launcher.sh`** : hors modèle (`curl` direct, source externe) — aligner ou documenter comme exception.
- **`99-functions.sh`** : convention « ordre d'exécution » vs « librairie à `source` » — à clarifier.
- **`00-init.sh`** : `apt instal` (typo) à corriger en `apt install`.
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).
- **Keyring GitHub** : le workflow ne contient PAS `01-keyring-github.sh`/`92` → le repo GitHub a des `.deb` signés mais **sans keyring** = pas installable via apt. Ajouter le keyring GitHub pour rendre le repo installable.
- **Config root / webroot :** reprepro utilise `-b /var/www/html` et écrit `conf/distributions` à `/var/www/html/conf/`. Le pool exporté est servi depuis `/var/www/html/pool/`. Vérifier que lighttpd/webroot sert bien `/var/www/html/` et que l'URI apt (`orphanage.shionn.org/`) pointe vers ce pool.
- **Experimental :** `includedeb experimental build/experimental/*/*.deb` ne matche rien tant qu'aucun package n'est déposé dans `build/experimental/`. Décider si un package peut aller en experimental (et comment).
- **`16-recomp-launcher.sh`** : hors modèle (`curl` direct, source externe) — aligner ou documenter comme exception.
- **`99-functions.sh`** : convention « ordre d'exécution » vs « librairie à `source` » — à clarifier.
- **`00-init.sh`** : `apt instal` (typo) à corriger en `apt install`.
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).

- **Orchestration :** crontab vs script racine — à choisir et documenter.
- **`16-recomp-launcher.sh`** : hors modèle (`curl` direct, source externe) — aligner ou documenter comme exception.
- **`99-functions.sh`** : convention « ordre d'exécution » vs « librairie à `source` » — à clarifier.
- **`00-init.sh`** : `apt instal` (typo) à corriger en `apt install`.
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).
