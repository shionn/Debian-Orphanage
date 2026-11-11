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
- **Un seul dépôt** : `reprepro/` → `orphanage.shionn.org` (local). Plus de double repo.
- **Référence** : `agent/reference.md` — le relire/mettre à jour avant toute modification.
- **Signature** : les `.deb` doivent être signés par la clé shionn (`SignWith: yes`).

## À ne pas faire
- Ne pas déplacer de fichiers hors de leur rôle (ex. ne pas briser le flux `temp/` → `build/` → `www/`).
- Ne pas modifier les valeurs clés (Origin, codenames, maintainer) sans raison.

## Incohérence connue
`01-keyring.sh` sort le `.deb` dans `temp/`, mais `90-update-repo.sh` lit `build/`. À clarifier.
