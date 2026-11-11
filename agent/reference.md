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
- **Sources des paquets :** releases d'un repo GitHub (via l'API GitHub), puis téléchargement des `.deb`.

## 2. Environnement d'exécution
- Un **container Debian** Proxmox nommé **`Orphanage`**.
- Le projet + son **repo git** sont clonés dans **`/root/Orphanage`** (dans ce container).
- Tous les scripts `src/` s'exécutent depuis ce dossier, successivement.

## 3. Structure du dépôt
| Chemin | Rôle |
|---|---|
| `src/` | Scripts ordonnés par préfixe numérique |
| `reprepro/` | Config + pool du dépôt local (`orphanage.shionn.org`) |
| `build/` | Dossier de travail : `.deb` reçus + sortie intermédiaire |
| `temp/` | Zone tampon (actuellement : sortie du keyring) |
| `www/` | Export du dépôt `reprepro`, servi via `http://orphanage.shionn.org/` |
| `agent/reference.md` | Ce fichier |
| `README.md` | Notice courte |

### Convention de noms de scripts (ordre d'exécution par index)
| Plage | Rôle | Fréquence |
|---|---|---|
| `00-` à `09-` | Initialisation / setup / infra | une fois, ou très rarement |
| `10-` à `89-` | Récupération ou construction d'un paquet (**idéalement un script par package**) | à la demande |
| `90-` | Mise à jour du repo (`reprepro`) | après chaque nouveau paquet |
| `99-functions.sh` | **Bibliothèque de fonctions** réutilisables — **`source`**e, pas exécutée dans l'ordre | toujours avant usage |

> ⚠️ **Tension de convention :** `99-functions.sh` porte un préfixe numérique mais est une **librairie à `source`**, pas un script ordonné. Les scripts qui l'utilisent doivent faire `source ./src/99-functions.sh` (idéalement en tête de fichier).

## 4. Workflow de reconstruction
Exécuter les scripts `src/` dans l'ordre croissant de leur index :

```
./src/00-init.sh            # setup (une fois)
source ./src/99-functions.sh
./src/01-keyring.sh <FINGERPRINT>
./src/NN-pkg.sh             # un par package (10–89)
./src/90-update-repo.sh     # rebuild du dépôt
```

### Obtenir le fingerprint GPG
```
gpg --list-secret-key
```
→ récupérer l'empreinte dans la section `pub` (passée en `$1`).

### Rôle de chaque script (état actuel)
- **`00-init.sh`** :
  - Installe `reprepro` et `lighttpd` (serveur web du dépôt).
  - ⚠️ Contient une faute de frappe : `apt instal` (manque un `l`). À corriger.
- **`01-keyring.sh`** :
  - Construit le paquet `orphanage-keyring` (version `1.0.0`).
  - `DEBIAN/control` : `misc / optional / all`.
  - Installe la clé sous `/usr/share/keyrings/orphanage.shionn.org.gpg` (via `gpg --export-options export-minimal`).
  - Crée l'entry apt : `deb [signed-by=...] orphanage.shionn.org/ trixie main`.
  - Sortie : le `.deb` est déplacé dans **`temp/`** (`mv ... ../temp`).
- **`90-update-repo.sh`** :
  - Écrit `www/conf/distributions` (Origin/Label `orphanage.shionn.org`, Codenames `trixie` + `experimental`, Composant `main`, Arch `amd64`).
  - Sépare les `.deb` : trixie = stable (`build/*.deb`), experimental = le reste (`build/*~*.deb`).
  - `reprepro -b www/` : build → export des deux composants.

### Fonction réutilisable : `download_github` (`99-functions.sh`)
Télécharge les assets d'une **release** d'un repo GitHub.
```bash
download_github <author> <repo> [pattern]   # pattern par défaut : *.deb
```
- Récupère la release la plus récente via `https://api.github.com/repos/<author>/<repo>/releases/latest`.
- Lit les `browser_download_url` des assets (nécessite **`jq`**).
- Filtre par nom de fichier (glob non échappé) et télécharge ceux correspondant au pattern.
- Télécharge dans le **dossier courant** sous le nom du fichier (`basename` de l'URL).
- Dépendances : `curl`, `jq`.

### Script packageur : `10-umu.sh`
- **Placeholder vide** pour le premier package : **`umu`**.
- À remplir plus tard : `source 99-functions.sh`, appeler `download_github`, puis placer le `.deb` dans `build/`.
- Ne pas exécuter avant d'y avoir ajouté la logique de récupération.

## 5. Flux d'un nouveau paquet
1. Récupérer/construire le paquet orphelin → produire un `.deb` (signé par la clé shionn), ex. via `download_github`.
2. Faire traiter le paquet par son script dédié (`NN-pkg.sh`, 10–89).
3. Rebuild du dépôt : `./src/90-update-repo.sh`.
4. Le paquet apparaît dans `www/` (trixie ou experimental selon le nom).

## 6. Orchestration (à décider)
Tous les scripts sont censés être lancés automatiquement, soit via la **crontab**, soit via **un script à la racine**. Le mode n'est pas encore fixé.
- À préciser : cadence, dépendances entre scripts, gestion des échecs, idempotence.

## 7. Outils utilisés
- `reprepro` — construction/export du dépôt Debian.
- `lighttpd` — serveur web du dépôt (`www/`).
- `dpkg -b` — assemblage des paquets.
- `gpg` — export de la clé de signature.
- `curl`, `jq` — téléchargement des paquets depuis GitHub (fonction `download_github`).

## 8. Valeurs clés / constantes
| Élément | Valeur |
|---|---|
| Origin / Label | `orphanage.shionn.org` |
| Codenames | `trixie` (stable), `experimental` |
| Composant | `main` |
| Architecture | `amd64` |
| Maintainer (control) | `Shionn <shionn@gmail.com>` |
| Package keyring | `orphanage-keyring` v`1.0.0` |
| Chemin d'installation | `/root/Orphanage` (container Debian) |

## 9. Questions ouvertes / TODO
- **Zone tampon :** `01-keyring.sh` sort le `.deb` dans `temp/`, mais `90-update-repo.sh` lit `build/`.
  → Comment les `.deb` passent de `temp/` à `build/` ? (script intermédiaire ? copie ?)
- **Orchestration :** crontab vs script racine — à choisir et documenter.
- **`10-umu.sh`** : placeholder vide — définir la logique de récupération de `umu` (repo GitHub, pattern).
- **`99-functions.sh`** : convention « ordre d'exécution » vs « librairie à `source` » — à clarifier.
- **`00-init.sh`** : `apt instal` (typo) à corriger en `apt install`.
- **Gestion d'erreurs / idempotence :** les scripts ne gèrent pas les échecs ni la re-exécution.
- **README.md** : très court, à enrichir (installation, contribution).
### Fonction réutilisable : `download_github` (`99-functions.sh`)
Télécharge les assets d'une **release** d'un repo GitHub.
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

Exemple (umu : garder uniquement le `.deb` amd64 réel, exclure implicitement `debian_12`/`arm64`) :
```bash
download_github umu umu-core "^umu-.*_[0-9][^_]*_amd64\.deb$"
```
download_github <author> <repo> [pattern] [--exclude pattern]...   # pattern par défaut : *.deb
```
- Récupère la release la plus récente via `https://api.github.com/repos/<author>/<repo>/releases/latest`.
- Lit les `browser_download_url` des assets (nécessite **`jq`**).
- Filtre par nom de fichier (glob non échappé) ; supporte **plusieurs `--exclude "pattern"`** (un suffit pour exclure).
- Télécharge dans le **dossier courant** sous le nom du fichier (`basename` de l'URL).
- Dépendances : `curl`, `jq`.

Exemple (umu : garder les `.deb` amd64, exclure le packaging Debian 12 et arm64) :
```bash
download_github umu umu-core "*.deb" \
  --exclude "*debian_12*" \
  --exclude "*arm64*"
```