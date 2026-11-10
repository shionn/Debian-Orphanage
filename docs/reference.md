# Orphanage — Référence du projet

> Fichier de référence durable pour reconstruire et maintenir le projet.
> À relire et mettre à jour par toute session de travail.

## 1. Contexte & but
- **Nom du projet :** Orphanage
- **Mainteneur :** Shionn <shionn@gmail.com> (pseudo : `shionn`)
- **Hôte du dépôt :** `orphanage.shionn.org`
- **Signature GPG :** oui — les `.deb` sont signés (`SignWith: yes`)
- **Objectif :** rassembler les paquets Debian tiers **orphelins** (aucun repo, aucun extrepo) + des projets packagés personnellement par shionn.

## 2. Structure du dépôt
| Chemin | Rôle |
|---|---|
| `src/00-keyring.sh` | Génère le paquet `orphanage-keyring` (clé GPG + entry `apt` sources.list.d) |
| `src/90-update-repo.sh` | Construit le dépôt avec `reprepro` (composantes `trixie` + `experimental`) |
| `build/` | Dossier de travail : `.deb` reçus + sortie intermédiaire |
| `www/` | Export du dépôt `reprepro`, servi via `http://orphanage.shionn.org/` |
| `docs/reference.md` | Ce fichier |
| `README.md` | Notice courte |

### Convention de noms de scripts
Un **préfixe numérique** = ordre d'exécution : `00-`, `10-`, …, `90-`.
Tout nouveau script suit ce schéma.

## 3. Workflow de reconstruction
Exécuter les scripts `src/` dans l'ordre croissant de leur index :

```
./src/00-keyring.sh <FINGERPRINT>
... autres scripts intermédiaires ...
./src/90-update-repo.sh
```

### Obtenir le fingerprint GPG
```
gpg --list-secret-key
```
→ récupérer l'empreinte dans la section `pub` (passée en `$1` à `00-keyring.sh`).

### Rôle de chaque script
- **`00-keyring.sh`** `<fingerprint>` :
  - Construit le paquet `orphanage-keyring` (version `1.0.0`).
  - `DEBIAN/control` : `misc / optional / all`.
  - Installe la clé sous `/usr/share/keyrings/orphanage.shionn.org.gpg` (via `gpg --export-options export-minimal`).
  - Crée l'entry apt : `deb [signed-by=...] orphanage.shionn.org/ trixie main`.
  - Sortie : le `.deb` est déplacé **dans le root du dépôt** (`mv ... ../`).
- **`90-update-repo.sh`** :
  - Écrit `www/conf/distributions` (Origin/Label `orphanage.shionn.org`, Codenames `trixie` + `experimental`, Composant `main`, Arch `amd64`).
  - Sépare les `.deb` : trixie = stable (`build/*.deb`), experimental = le reste (`build/*~*.deb`).
  - `reprepro -b www/` : build → export des deux composants.

## 4. Flux d'un nouveau paquet
1. Packager le paquet orphelin → produire un `.deb` (signé par la clé shionn).
2. Placer le `.deb` dans `build/` (attendu par `90-update-repo.sh`).
3. Rebuild du dépôt : `./src/90-update-repo.sh`.
4. Le paquet apparaît dans `www/` (trixie ou experimental selon le nom).

## 5. Outils utilisés
- `reprepro` — construction/export du dépôt Debian.
- `dpkg -b` — assemblage des paquets.
- `gpg` — export de la clé de signature.

## 6. Valeurs clés / constantes
| Élément | Valeur |
|---|---|
| Origin / Label | `orphanage.shionn.org` |
| Codenames | `trixie` (stable), `experimental` |
| Composant | `main` |
| Architecture | `amd64` |
| Maintainer (control) | `Shionn <shionn@gmail.com>` |
| Package keyring | `orphanage-keyring` v`1.0.0` |

## 7. Questions ouvertes / TODO
- **Incohérence de chemins :** `00-keyring.sh` déplace son `.deb` dans le **root** (`mv ... ../`), mais `90-update-repo.sh` lit les `.deb` dans **`build/`**.
  → Où/ comment les `.deb` finissent-ils dans `build/` ? À clarifier (script intermédiaire ? copie manuelle ?).
- **Scripts intermédiaires :** seul `00-` et `90-` existent. Le gap entre eux (vérification des `.deb`, placement dans `build/`, nettoyage) n'est pas couvert.
- **README.md** : très court, à enrichir (installation, contribution).
