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
			DL_FILENAME=$FILENAME
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
# download_codeberg : telecharge les assets d'une release d'un repo Codeberg
# (Gitea) SANS aucune authentification OAuth.
#
#   download_codeberg <owner> <repo> [pattern]
#
#   pattern    : regex ERE sur le nom de fichier (partie asset). Seuls les
#            fichiers correspondants sont telecharges (le reste est ignore).
#   release    : la derniere release stable (defaut, isolation native).
#
# Codeberg tourne sur Gitea : l'API Gitea exige un token OAuth (evite). On
# utilise le URL de telechargement direct des assets de release et on scrape
# la page des releases pour decouvrir la derniere release + ses assets.
#
# CSS cible : #release-list > li:first-child details ul a  (1ere release =
# li:first-child, isolation native ; Gitea liste par ordre decreissant).
#
# Récupère la page des releases, isole la derniere release, filtre ses assets
# par regex, puis telecharge dans le dossier courant.
# dependances : curl, grep, sed
download_codeberg() {
	local owner="$1"
	local repo="$2"
	local pattern="${3:-'.*\.deb'}"

	PAGES_URL="https://codeberg.org/${owner}/${repo}/releases"
	PAGE_HTML=$(curl -s --connect-timeout 10 --max-time 120 "${PAGES_URL}")
	if [ $? -ne 0 ]; then
		echo "Erreur lors de la recuperation de la page des releases."
		return 1
	fi

	# Isolation de la derniere (1ere) release : chaque release = un bloc
	# <details class="download">, en ordre croissant. On isole du 1er bloc
	# jusqu'a l'ouverture du 2e (ou EOF), puis on lit les href des <a> de
	# telechargement. On lit l'href (pas le texte) : le <a> contient un SVG
	# enfant dont le markup brut serait inclus dans le texte brut.
	OPENINGS=$(echo "${PAGE_HTML}" | grep -n 'details class="download"' | cut -d: -f1)
	FIRST=$(echo "${OPENINGS}" | head -1)
	if [ -z "${FIRST}" ]; then
		echo "Aucun asset correspondant"
		return 1
	fi
	NEXT=$(echo "${OPENINGS}" | sed -n '2p')
	if [ -z "${NEXT}" ]; then
		RANGE=$(echo "${PAGE_HTML}" | sed -n "${FIRST},\$p")
	else
		RANGE=$(echo "${PAGE_HTML}" | sed -n "${FIRST},$((NEXT-1))p")
	fi

	# Extraction des href des assets de telechargement (lire l'href, pas le texte)
	DOWNLOAD_URLS=$(echo "${RANGE}" | grep -oE 'href="[^"]*releases/download/[^"]+"' | sed -E 's/href="//; s/"$//')

	# Suivi : un asset a-t-il correspondu au pattern (telecharge ou deja present) ?
	MATCHED=0
	while IFS= read -r URL; do
		if [ -z "${URL}" ]; then
			continue
		fi
		FILENAME=$(basename "${URL}")

		# Filtre regex (ERE) : ne garde que les fichiers correspondants.
		if [[ "$FILENAME" =~ $pattern ]]; then
			MATCHED=1
			if [ -f "$FILENAME" ]; then
				echo "a jour $FILENAME"
			else
				echo "Telechargement de ${FILENAME}"
				curl -L --connect-timeout 10 --max-time 120 -o "${FILENAME}" "${URL}"
				if [ $? -ne 0 ]; then
					echo "Erreur lors du telechargement de ${FILENAME}."
				fi
			fi
		else
			echo "Ignoré : $FILENAME"
		fi
	done <<< "${DOWNLOAD_URLS}"
	if [ "${MATCHED}" -eq 0 ]; then
		echo "Aucun asset correspondant"
		return 1
	fi
	return 0
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

# download_github_last_tag : telecharge les assets d'une release dont le tag_name
# correspond a un pattern.
#
#   download_github_last_tag <author> <repo> <pattern-fichier> <pattern-tag>
#
#   pattern-fichier : regex ERE sur le nom de fichier. Seuls les fichiers qui
#            correspondent sont telecharges (le reste est ignore).
#   pattern-tag     : regex ERE sur le tag_name. Les releases sont triees plus
#            recentes en premier ; on prend le premier dont le tag_name correspond.
#
# Récupère la release la plus récente dont le tag correspond au pattern, filtre
# ses assets par regex, puis telecharge dans le dossier courant.
# dependances : curl, jq
download_github_last_tag() {
	local author="$1"
	local repo="$2"
	local pattern="${3:-'.*\.deb'}"
	local tag_pattern="${4:-.*}"

	API_URL="https://api.github.com/repos/${author}/${repo}/releases?per_page=50"
	RELEASE_INFO=$(curl -s ${API_URL})
	if [ $? -ne 0 ]; then
		echo "Erreur lors de la recuperation des informations de la release."
		return 1
	fi

	# Parcourt les releases (triees plus recentes en premier) et garde le premier
	# dont le tag_name correspond au pattern.
	local TAG_NAME=""
	while IFS= read -r TAG_NAME; do
		if [ -z "${TAG_NAME}" ]; then
			continue
		fi
		if [[ "${TAG_NAME}" =~ ${tag_pattern} ]]; then
			break
		fi
	done <<< "$(echo "${RELEASE_INFO}" | jq -r '.[] | .tag_name')"

	if [ -z "${TAG_NAME}" ]; then
		echo "Aucune release dont le tag_name correspond au pattern '${tag_pattern}'."
		LAST_GITHUB_TAG="${TAG_NAME}"
		return 1
	fi

	# Telecharge les assets de cette release correspondant au pattern de fichier.
	URLS=$(echo "${RELEASE_INFO}" | jq -r --arg tag "${TAG_NAME}" '.[] | select(.tag_name==$tag) | .assets[] | .browser_download_url')

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
	done <<< "${URLS}"
	LAST_GITHUB_TAG="${TAG_NAME}"
	return 0
}