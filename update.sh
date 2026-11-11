#!/bin/bash
# update.sh : execute les scripts de packages (10-* a 89-*) dans src/, par ordre.
# Exclut automatiquement 00-09 (init/setup) et 90+ (update-repo / fonctions).

set -e

src_dir="src"

for script in "$src_dir"/*.sh; do
	[ -e "$script" ] || continue
	prefix="${script%%[!0-9]*}"		  # part numerique avant le premier tiret
	if [[ "$prefix" =~ ^[0-9]+$ ]] && [ "$prefix" -ge 10 ] && [ "$prefix" -le 89 ]; then
		echo "== $script =="
		bash "$script"
	fi
done
bash "src/90-update-repo.sh"
