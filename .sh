#!/usr/bin/env bash
set -euo pipefail
yml="./scripts/yml.sh"
html="./scripts/html.sh"
flag() {
	for f in "$@"
		do [[ -e ".flags/$f" ]] || return 1
	done
}
DIRS=(tmp logs)
mkdir -p "${DIRS[@]}"
trap "rm -rf tmp" EXIT
flag local && exec &> logs/main.log
[[ -f $yml ]] && {
	while read -r f
		do
			f="${f#data/}"
			f="${f%.yml}"
			$yml "$f"
	done < <(find data \
		-name \*.yml \
		! -name config.yml \
		| sort
	)
} || {
	echo "'$yml' not found" >&2
	exit 1
}
declare -A toggles
toggles[details]=true
toggles[plot]=true
[[ -f $html ]] && {
	$html style 'body{font:20pt"Noto Sans"}'
	"${toggles[details]}" && $html div "$(
		while IFS= read -r c; do
			$html h1 "$(jq -r '.name' <<< "$c")"
			$html dl "$(
				m=`jq -r '.monikers | length != 0' <<< "$c"`
				r=`jq -r '.relationships | length != 0' <<< "$c"`
				if [[ $m = true ]] || [[ $r = true ]]; then
					if [[ $m = true ]]; then
						$html dt "$($html b Monikers:)"
						while IFS= read -r i; do
							$html dd "$($html q "$i")"
						done < <(jq -r '.monikers[]' <<< "$c")
					fi
					if [[ $r = true ]]; then
						$html dt "$($html b Relationships:)"
						while IFS= read -r i; do
							$html dd "$i"
						done < <(jq -r '.relationships[]' <<< "$c")
					fi
				fi
			)"
		done < <(jq -c '.[]' data/characters.json)
	)"
	"${toggles[details]}" && "${toggles[plot]}" && $html hr
	"${toggles[plot]}" && $html dl "$(
		while IFS= read -r l; do
			$html dt "$($html b "$(jq -r '.key' <<< "$l"):")"
			$html dd "$(jq -r '.value' <<< "$l")"
		done < <(jq -c '.[] | to_entries[]' data/script.json)
	)"
} > README.md || {
	echo "'$html' not found" >&2
	exit 1
}
cp README.md index.html
find . -path "*/data/*" -name "*.json" -o -empty -delete
