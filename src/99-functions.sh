


download_github() {
	local author="$1"
	local repo="$2"
	local pattern="${3:-*.deb}"
	#mkdir -p "$repo"


	RELEASE_INFO=$(curl -s https://api.github.com/repos/${author}/${repo}/releases/latest)
	if [ $? -ne 0 ]; then
		echo "Erreur lors de la récupération des informations de la release."
		exit 1
	fi
	# .tarball_url
	DOWNLOAD_URLS=$(echo "${RELEASE_INFO}" | jq -r '.assets[] | .browser_download_url')

	while IFS= read -r URL; do
		echo "test ${URL}"
		if [ -z "${URL}" ]; then
			continue
		fi
		FILENAME=$(basename "${URL}")

		# Exclure les fichiers qui ne respect pas le pattern.
		if [[ "$FILENAME" != $pattern ]]; then
			echo "Ignoré : $FILENAME (type de fichier non autorisé)"
			continue
		fi


		if [ -f "$FILENAME" ]; then
			echo "a jour $FILENAME"
		else
			echo "Telechargement de ${FILENAME}"
			curl -L -o "${FILENAME}" "${URL}"
			if [ $? -ne 0 ]; then
				echo "Erreur lors du telechargement de ${FILENAME}."
			fi
		fi
	done <<< "${DOWNLOAD_URLS}"
}