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
- **Sources des paquets :** releases d'un repo GitHub (via l'API GitHub), ou Codeberg/Gitea (via `download_codeberg`, **sans auth OAuth**), sauf exceptions (ex. `16-recomp-launcher` / `19-discord` via curl direct).

## 2. Environnement d'exécution
- Un **container Debian** Proxmox nommé **`Orphanage`**.
- Le projet + son **repo git** sont clonés dans **`/root/Orphanage`** (dans ce container).
- Tous les scripts `src/` s'exécutent depuis ce dossier, successivement.

| Chemin | Rôle |
|---|---|
| `src/` | Scripts ordonnés par préfixe numérique |
| `build/trixie/<pkg>/` | `.deb` téléchargés par chaque script packageur (sous-dossier par package) |
| `build/trixie/keyring/` | **keyring unifié** `orphanage-keyring` (posé par `01-keyring.sh`) |
| `build/` | Dossier racine du travail (scripts packageurs y déposent `trixie/<pkg>/`) |
| `/var/www/html/` | **Config root + webroot de reprepro** (`-b /var/www/html`, `conf/distributions`, `pool/` servi) |
| `/var/www/html/pool/` | Pool exporté, servi par lighttpd/webroot |
| `www/` | Ancienne zone tampon (créée par `00-init.sh`) |
| `agent/reference.md` | Ce fichier |
| `update.sh` | Exécute les scripts de packages (10–89) dans l'ordre |
| `README.md` | Notice courte |

### Convention de noms de scripts (ordre d'exécution par index)
| Plage | Rôle | Fréquence |
|---|---|---|
| `00-` à `09-` | Initialisation / setup / infra | une fois, ou très rarement |
| `10-` à `89-` | Récupération ou construction d'un paquet (**un script par package**) | à la demande |
| `90-` | Mise à jour du repo (`reprepro`) | après chaque nouveau paquet |
| `99-functions.sh` | **Bibliothèque de fonctions** réutilisables — **`source`**e, pas exécutée dans l'ordre | toujours avant usage |
| `update.sh` (racine) | Lance les scripts `10-*` à `89-*` dans l'ordre | après ajout d'un nouveau package |

> ⚠️ **`99-functions.sh`** porte un préfixe numérique mais est une **librairie à `source`**, pas un script ordonné. Les scripts qui l'utilisent doivent faire `source "src/99-functions.sh"` (idéalement en tête de fichier).

## 4. Workflow de reconstruction
Exécuter les scripts `src/` dans l'ordre croissant de leur index :

```
./src/00-init.sh            # setup (une fois)
source ./src/99-functions.sh
./src/01-keyring.sh "http://orphanage.shionn.org"   # keyring unifié (fingerprint auto + URI obligatoire)
./src/NN-pkg.sh             # un par package (10–89)
./src/90-update-repo.sh "orphanage.shionn.org" "/var/www/html"   # rebuild du dépôt local
```

Ou, pour tout le lot de packages, depuis la racine :
```bash
bash update.sh              # exécute src/10-* à src/89-* dans l'ordre (set -e : arrêt à la 1ère erreur)
```
- `update.sh` appelle en tête `bash "src/01-keyring.sh" "http://orphanage.shionn.org"`, puis, à la fin, `bash "src/90-update-repo.sh" "orphanage.shionn.org" "/var/www/html"`.
- **`90-update-repo.sh`** :
  - **2 paramètres obligatoires** : `$1` = origin/URL (`orphanage.shionn.org`), `$2` = config root / destination (`/var/www/html`). Sinon → `Usage : $0 <origin-url> <config-root>` + `exit 1`.
  - Écrit `conf/distributions` à `${CONFIG_ROOT}/conf/distributions` (Origin/Label = `$1`, Codenames `trixie` + `experimental`, Composant `main`, Arch `amd64`, `SignWith: yes`).
  - `includedeb` à 2 niveaux : `reprepro -b "${CONFIG_ROOT}" includedeb trixie build/trixie/*/*.deb` (récupère les packages ET le keyring unifié dans `build/trixie/keyring/`), et `includedeb experimental build/experimental/*/*.deb`.
  - `reprepro -b "${CONFIG_ROOT}" export trixie` / `export experimental` → exporte le pool vers `${CONFIG_ROOT}/pool/`.
  - Doit être exécuté depuis la **racine du projet** pour que `build/trixie/*/*.deb` se résolve.
- **`91-update-repo-github.sh`** :
  - Régénère `docs/conf/distributions` (Origin/Label `shionn.github.io/Debian-Orphanage`, codenames `trixie` + `experimental`).
  - `reprepro -b docs includedeb trixie build/trixie/*/*.deb` (inclut **aussi** le keyring unifié) puis export trixie/experimental.
  - Exécuté manuellement sur le serveur (pas dans le workflow).
- **`92-update-repo-github-keyring.sh`** : **OBSOLÈTE** — référence l'ancien chemin `build/trixie-github/*/*.deb` (supprimé par l'unification). Ne plus utiliser.
- **`01-keyring-local.sh`** / **`01-keyring-github.sh`** : **OBSOLÈTES** — remplacés par `01-keyring.sh` (plus appelés par `update.sh`). Garder ou supprimer à la discrétion.

### Obtenir le fingerprint GPG
Le fingerprint est récupéré **automatiquement** depuis la clé secrète GPG — plus besoin de le passer en paramètre :
```bash
sign=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')
```
→ `--with-colons` (format colon) + `awk -F: '/^fpr:/' {print $10; exit}` prend le **premier** `fpr:` = empreinte hexa de la clé principale (~40 caractères). Si vide → erreur + `exit 1`.

### Rôle de chaque script (état actuel)
- **`00-init.sh`** :
  - Installe `reprepro`, `lighttpd`, `curl`, `jq` (`apt install ...` — typo déjà corrigée).
  - `mkdir -p www` ; génère la clé GPG une fois (`gpg --generate-key`).
- **`01-keyring.sh`** (keyring **unifié**, version `1.0.4`) :
  - Fingerprint GPG récupéré **automatiquement** depuis la clé secrète (`gpg --list-secret-keys --with-colons | awk ...`) — plus de paramètre requis ; sinon erreur + `exit 1`.
  - **URI obligatoire** en paramètre `$1` : définit le dépôt vers lequel pointer le keyring ; sinon erreur + usage + `exit 1`.
  - Construit le paquet `orphanage-keyring` (version `1.0.4`).
  - `DEBIAN/control` : `misc / optional / all`.
  - Exporte la clé publique minimale (`gpg --export-options export-minimal`) sous `usr/share/keyrings/orphanage.pgp`.
  - Crée l'entry apt au **format `.sources`** : `etc/apt/sources.list.d/orphanage.sources` (`Types: deb`, `URIs: $1`, `Suites: trixie`, `Components: main`, `Signed-By: /usr/share/keyrings/orphanage.pgp`).
  - **Sortie :** le `.deb` est déposé dans **`build/trixie/keyring/`** (lieu unique, servi par `90` ET `91`).
- **`01-keyring-local.sh`** / **`01-keyring-github.sh`** : **OBSOLÈTES** — remplacés par `01-keyring.sh`.
- **`90-update-repo.sh`** :
  - 2 paramètres obligatoires (`$1` origin, `$2` config root) ; usage + `exit 1` sinon.
  - `includedeb` à 2 niveaux (packages + keyring unifié) + export → pool servi par `/var/www/html/pool/`.
  - Doit être exécuté depuis la **racine du projet**.
- **`91-update-repo-github.sh`** :
  - Régénère `docs/conf/distributions` (Origin/Label `shionn.github.io/Debian-Orphanage`, codenames `trixie` + `experimental`).
  - `includedeb trixie build/trixie/*/*.deb` (inclut **aussi** le keyring unifié) + export.
  - Exécuté manuellement sur le serveur (pas dans le workflow).
- **`92-update-repo-github-keyring.sh`** : **OBSOLÈTE** — ancien chemin `build/trixie-github/*/*.deb`.
- **`update.sh`** (racine) exécute les scripts `10-*` à `89-*` dans l'ordre :
  - Extraction du préfixe corrigée : `basename="${script##*/}"` puis `prefix="${basename%%[!0-9]*}"` (sinon `src/` donne une chaîne vide → aucun script traité).
  - Gestion d'erreur robuste : `if ! bash "$script"` → un échec de package ne tue pas la boucle (avertissement en stderr).
  - Appel en tête du keyring unifié +, à la fin, publication du repo local (`90`).

### Fonction réutilisable : `download_github` (`99-functions.sh`)
Télécharge les assets d'une **release** d'un repo GitHub.
```bash
download_github <author> <repo> [pattern] [release|pre-release]   # pattern : regex ERE, défaut : .*\.deb
```
- Récupère la release la plus récente via `https://api.github.com/repos/<author>/<repo>/releases/latest`.
- Lit les `browser_download_url` des assets (nécessite **`jq`**).
- **`pattern`** est une regex ERE (`[[ =~ ]]`) — seuls les noms de fichier correspondants sont téléchargés.
- Télécharge dans le **dossier courant** sous le nom du fichier.
- Dépendances : `curl`, `jq`.
- ⚠️ Utilise encore `exit 1` sur erreur (fonctionnel via `update.sh` (`if !`), mais devrait être `return 1`).

### Fonction réutilisable : `download_codeberg` (`99-functions.sh`)
Télécharge les assets d'une **dernière release stable** d'un repo **Codeberg** (Gitea) **sans aucune authentification OAuth**.
```bash
download_codeberg <owner> <repo> [pattern]   # pattern : regex ERE sur le nom de fichier (partie asset), défaut : .*\.deb
```
- Codeberg tourne sur Gitea : l'API Gitea exige un token OAuth (**évité**). On scrape la page des releases `https://codeberg.org/<owner>/<repo>/releases` et on utilise le URL de téléchargement direct des assets `.../releases/download/<tag>/<asset>` (`curl -L` suit le redirect).
- **Isolation de la dernière release** : chaque release = un bloc `<details class="download">` (en ordre croissant) ; on isole du 1er bloc jusqu'à l'ouverture du 2e (ou EOF). CSS cible : `#release-list > li:first-child details ul a`.
- **On lit l'`href`** (pas le texte) : chaque `<a>` contient un **SVG enfant** dont le markup brut serait inclus dans le texte brut. Le fichier est téléchargé sous le **`basename` de l'`href`** (= partie asset, dernière composante après `/releases/download/`).
- **`pattern`** est une regex ERE (`[[ =~ ]]`, **pattern variable non cité** — sinon traité comme littéral). Seuls les noms de fichier correspondants sont téléchargés.
- Télécharge dans le **dossier courant** sous le nom du fichier.
- **`return 1`** sur erreur (échec récupération page / aucun asset correspondant / échec curl) — ne tue pas le script appelant (contrairement à `download_github` qui fait `exit 1`).
- Idempotence : « a jour » si le fichier existe déjà ; aucun re-téléchargement.
- Dépendances : `curl`, `grep`, `sed`.
- Exemple : `21-libhidapi-hotplug.sh` → `download_codeberg OpenRGB hidapi-hotplug ".*trixie_amd64.deb"`.


### Fonction réutilisable : `github_get_last_release_tag` (`99-functions.sh`)
Récupère le **tag_name** de la dernière release (pour cloner/git sur un tag précis).
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

### Packages actuels (10–21)
| `NN-script.sh` | Package | Source | Pattern / remarque |
|---|---|---|---|
| `10-umu.sh` | umu-launcher | GitHub `Open-Wine-Components/umu-launcher` | `.*(amd64\|all)_debian-13.deb` (amd64 + all) |
| `11-openrgb.sh` | openrgb | GitHub `CalcProgrammer1/OpenRGB` | `.*amd64_trixie_.*.deb` |
| `12-bc250.sh` | bc250-control-center | GitHub `movacx/bc250-control-center` | `.*.deb` (tout) |
| `13-hydra-launcher.sh` | hydra | GitHub `hydralauncher/hydra` | `.*.deb` (tout) |
| `14-heroic-games-launcher.sh` | heroic-games-launcher | GitHub `Heroic-Games-Launcher/HeroicGamesLauncher` | `.*amd64.deb` |
| `15-faugus-launcher.sh` | faugus-launcher | GitHub `Faugus/faugus-launcher` | `.*.deb` (tout) |
| `16-recomp-launcher.sh` | recomp-launcher | **curl direct** `recomplauncher.com/api/launcher-beta.php?a=download&os=deb` | hors `download_github` (exception) |
| `17-freetube.sh` | freetube | GitHub `FreeTubeApp/FreeTube` | `.*amd64.deb` **prerelease** |
| `18-hyprshot.sh` | hyprshot | `git clone -b $tag` GitHub + `dpkg -b` | `github_get_last_release_tag` |
| `19-discord.sh` | discord | **curl direct** `discord.com/api/downloads/.../installers/latest?...&format=deb` | hors `download_github` (exception) |
| `20-proton.sh` | proton (GE) | **copier-coller cassé de `18-hyprshot.sh`** | télécharge `proton-ge-custom` mais `git clone Gustash/Hyprshot` (à corriger) |
| `21-libhidapi-hotplug.sh` | libhidapi-hotplug | **Codeberg** `OpenRGB/hidapi-hotplug` (Gitea, **sans auth**) | `download_codeberg` `.*trixie_amd64.deb` (dernière release stable) |

- Les scripts simples (10–17) : `source "src/99-functions.sh"` → `mkdir -p build/trixie/<pkg>/` → `cd` → `download_github <author> <repo> "<pattern>"`.
- `18-hyprshot.sh` / `20-proton.sh` : build complet d'un `.deb` (`git clone` + `dpkg -b`) ; `exit 0` sur « a jour », `exit 1` sur vraie erreur.
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
  - `91` ne pousse PAS : son `git push` est commenté.
  - `build/` est dans `.gitignore` → le workflow ne committe que `docs/`.
  - **Bloc `env:`** dans le step import : `KEY: ${{ secrets.GPG_PRIVATE_KEY }}` → `echo "$KEY" | tr -d '[:space:]' | base64 -d | gpg --import`.
  - ⚠️ Sans le secret `GPG_PRIVATE_KEY`, `91` échoue à signer (SignWith: yes) → `continue-on-error` → `docs/` déployé mais **sans keyring GitHub** → repo GitHub a des `.deb` signés mais **pas installable via apt**. Le keyring unifié (`01-keyring.sh`) est partagé par `90` ET `91` (inclus via `build/trixie/*/*.deb`) ; l'ajouter dans le workflow rendrait le repo GitHub installable.

## 7. Signature GPG (export)
- **Une seule clé** : ta clé GPG personnelle (actuellement ed25519, `sec` + sous-clé `ssb` cv25519).
- **reprepro** signe les `.deb` + `Release` avec **ta clé secrète**.
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).
- La clé privée vit dans `~/.gnupg` (locale, **hors git**) ; les scripts ne contiennent qu'un identifiant (`SignKey:`).
- **Clé de signature sans mot de passe** : l'export automatisé ne peut pas demander de passphrase (erreur `GPGME:54: Unusable secret key`). Utilise une clé dédiée sans passphrase.
- **Secret GitHub** : la clé privée est un **repository secret** `GPG_PRIVATE_KEY` dans le repo `Debian-Orphanage` (Settings → Secrets and variables → **Secrets**, valeur = base64 `base64 -w0` de l'export secret-key). Le workflow la lit via `${{ secrets.GPG_PRIVATE_KEY }}`. `longueur=${#GPG_PRIVATE_KEY}` = 0 → le secret n'est pas lu (nom, section, ou valeur vide).

## 8. Outils utilisés
- `reprepro` — construction/export du dépôt Debian.
- `lighttpd` — serveur web du dépôt (`www/`).
- `gpg` — export de la clé de signature.
- `curl`, `jq`, `grep`, `sed` — téléchargement des paquets depuis GitHub (via `download_github`) ou Codeberg/Gitea (via `download_codeberg`, scraping sans API).

## 9. Valeurs clés / constantes
| Élément | Valeur |
|---|---|
| Origin / Label (local) | `orphanage.shionn.org` |
| Origin / Label (GitHub) | `shionn.github.io/Debian-Orphanage` |
| Codenames | `trixie` (stable), `experimental` |
| Composant | `main` |
| Architecture | `amd64` |
| Maintainer (control) | `Shionn <shionn@gmail.com>` |
| Package keyring | `orphanage-keyring` v`1.0.4` |
| Chemin d'installation | `/root/Orphanage` (container Debian) |

## 10. Questions ouvertes / TODO
- **`20-proton.sh`** : copier-coller cassé de `18-hyprshot.sh` (télécharge `proton-ge-custom` mais `git clone Gustash/Hyprshot`) — à réparer ou supprimer.
- **`92-update-repo-github-keyring.sh`** : obsolète (ancien chemin `build/trixie-github/*/*.deb`) — supprimer ou réutiliser.
- **`01-keyring-local.sh` / `01-keyring-github.sh`** : obsolètes (remplacés par `01-keyring.sh`) — supprimer pour éviter la confusion.
- **`16-recomp-launcher.sh` / `19-discord.sh`** : hors modèle (`curl` direct, source externe) — aligner ou documenter comme exception.
- **`99-functions.sh`** : convention « ordre d'exécution » vs « librairie à `source` » — à clarifier.
- **`download_github`** : `exit 1` sur erreur (ligne 31) — devrait être `return 1` pour être portable.
- **`download_codeberg`** : l'isolation de la dernière release repose sur la présence d'un `<details class="download">` par release (1ʳᵉ = plus récente) + extraction regex de l'`href` (lecture href, pas le texte SVG). La page releases Gitea peut changer de structure HTML : si le sélecteur / l'extraction grep ne cible plus la 1ʳᵉ release, le script échoue silencieusement (aucun lien trouvé). Surveiller ; adapter l'extraction si nécessaire (ex. cibler `details.download` open, ou un pattern plus large sur `releases/download/` tout en restant limité à la 1ʳᵉ release). Timeout `--connect-timeout 10 --max-time 120` sur les `curl` pour éviter un blocage.
- **`00-init.sh`** : `mkdir -p www` (zone tampon obsolète) — à supprimer si plus utilisée.
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).
- **Keyring GitHub** : le workflow ne contient PAS `01-keyring.sh`/`91` → le repo GitHub a des `.deb` signés mais **sans keyring** = pas installable via apt. Ajouter le keyring unifié dans le workflow pour rendre le repo installable.
- **Config root / webroot :** reprepro utilise `-b /var/www/html` et écrit `conf/distributions` à `/var/www/html/conf/`. Le pool exporté est servi depuis `/var/www/html/pool/`. Vérifier que lighttpd/webroot sert bien `/var/www/html/` et que l'URI apt (`orphanage.shionn.org/`) pointe vers ce pool.
- **Experimental :** `includedeb experimental build/experimental/*/*.deb` ne matche rien tant qu'aucun package n'est déposé dans `build/experimental/`. Décider si un package peut aller en experimental (et comment).
- **Orchestration :** crontab vs script racine — à choisir et documenter.
