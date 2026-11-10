# AGENTS.md — Orphanage

Règles pour maintenir ce projet. Pour les faits durables transversaux, voir la mémoire.

## Ce que c'est
Dépôt Debian personnalisé (`orphanage.shionn.org`) hébergeant les paquets tiers **orphelins** de Debian + projets packagés par shionn. Signé en GPG.

## Conventions
- **Scripts `src/`** : préfixe numérique = ordre d'exécution (`00-`, `90-`). Ajouter un nouveau script avec ce schéma.
- **Reconstruction** : exécuter les scripts `src/` dans l'ordre croissant de leur index.
- **Nouveaux paquets** : produire un `.deb` signé, le placer dans `build/`, puis rebuild via `90-update-repo.sh`.
- **Fichier référence** : `docs/reference.md` — le relire/mettre à jour avant toute modification.
- **Signature** : les `.deb` doivent être signés par la clé shionn (`SignWith: yes`).

## À ne pas faire
- Ne pas déplacer de fichiers hors de leur rôle (ex. ne pas briser le flux `build/` ↔ `www/`).
- Ne pas modifier les valeurs clés (Origin, codenames, maintainer) sans raison.

## Incohérence connue
`00-keyring.sh` sort le `.deb` dans le root, mais `90-update-repo.sh` lit `build/`. À clarifier.
