#!/bin/bash
# update.sh : execute les scripts de packages (10-* a 89-*) dans src/, par ordre.
# Exclut automatiquement 00-09 (init/setup) et 90+ (update-repo / fonctions).

set -e

git pull

host=orphanage.shionn.org
dest=/var/www/html

bash "src/01-keyring.sh" "http://${host}"

src_dir="src"
for script in "$src_dir"/*.sh; do
	[ -e "$script" ] || continue
	basename="${script##*/}"          # ne garde que "10-umu.sh" (sans src/)
	prefix="${basename%%[!0-9]*}"     # ne garde que "10"
	if [[ "$prefix" =~ ^[0-9]+$ ]] && [ "$prefix" -ge 10 ] && [ "$prefix" -le 89 ]; then
		echo "== $script =="
		if ! bash "$script"; then
			echo "!! echec dans $script" >&2
		fi
	fi
done

echo "== publication =="
bash "src/90-update-repo.sh" $host $dest
