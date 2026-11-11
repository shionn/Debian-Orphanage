#!/bin/bash

# download_github : telecharge les assets d'une release d'un repo GitHub.
#
#   download_github <author> <repo> [pattern] [release|pre-release]
#
#   pattern    : regex ERE sur le nom de fichier. Seuls les fichiers qui
#            correspondent sont telecharges (le reste est ignore).
#   release    : ne garde que la release stable (defaut).
#   pre-release: inclut les prereleases (via ?pre=1 sur l'API GitHub).
#
# Récupère la release la plus recente, filtre par regex, puis telecharge
# dans le dossier courant.
# dependances : curl, jq
download_github() {
	local author="$1"
	local repo="$2"
	local pattern="${3:-'.*\.deb'}"
	local prerelease="${4:-release}"
	
	API_URL="https://api.github.com/repos/${author}/${repo}/releases/latest"
	if [ "$prerelease" = "pre-release" ] || [ "$prerelease" = "prerelease" ]; then
		API_URL="https://api.github.com/repos/${author}/${repo}/releases?per_page=1"
	fi

	#echo ${API_URL}
	RELEASE_INFO=$(curl -s ${API_URL})
	#echo ${RELEASE_INFO}
	if [ $? -ne 0 ]; then
		echo "Erreur lors de la recuperation des informations de la release."
		exit 1
	fi
	# .tarball_url
	DOWNLOAD_URLS=$(echo "${RELEASE_INFO}" | jq -r 'if type=="array" then .[] else . end | .assets[] | .browser_download_url')

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

github_get_last_release_tag() {
	local author="$1"
	local repo="$2"
	
	API_URL="https://api.github.com/repos/${author}/${repo}/releases/latest"
	RELEASE_INFO=$(curl -s ${API_URL})

	if [ $? -ne 0 ]; then
		echo "Erreur lors de la recuperation des informations de la release."
		return 1
	fi
	TAG_NAME=$(echo "${RELEASE_INFO}" | jq -r '.tag_name')
	echo ${TAG_NAME}
	return 0
}

