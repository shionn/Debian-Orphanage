#!/bin/bash

# download_github : telecharge les assets d'une release d'un repo GitHub.
#
#   download_github <author> <repo> [pattern]
#
#   pattern : regex ERE sur le nom de fichier. Seuls les fichiers qui
#            correspondent sont telecharges (le reste est ignore).
#
# Récupère la release la plus recente, filtre par regex, puis telecharge
# dans le dossier courant.
# dependances : curl, jq
download_github() {
	local author="$1"
	local repo="$2"
	local pattern="${3:-}"
	if [ -z "$pattern" ]; then
		pattern=".*\.deb"
	fi

	RELEASE_INFO=$(curl -s "https://api.github.com/repos/${author}/${repo}/releases/latest")
	if [ $? -ne 0 ]; then
		echo "Erreur lors de la recuperation des informations de la release."
		exit 1
	fi
	# .tarball_url
	DOWNLOAD_URLS=$(echo "${RELEASE_INFO}" | jq -r '.assets[] | .browser_download_url')

	while IFS= read -r URL; do
		if [ -z "${URL}" ]; then
			continue
		fi
		FILENAME=$(basename "${URL}")

		# Filtre regex (ERE) : ne garde que les fichiers correspondants.
		if [[ "$FILENAME" =~ $pattern ]]; then
			if [ -f "$FILENAME" ]; then
				echo "a jour $FILENAME"
			else
				echo "Telechargement de ${FILENAME}"
				curl -L -o "${FILENAME}" "${URL}"
				if [ $? -ne 0 ]; then
					echo "Erreur lors du telechargement de ${FILENAME}."
				fi
			fi
		else
			echo "Ignoré : $FILENAME"
		fi
	done <<< "${DOWNLOAD_URLS}"
}
