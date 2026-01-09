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
exec &> logs/main.log
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
} || echo "'$yml' not found" >&2
[[ -f $html ]] && {
	$html h1 Characters
	while IFS= read -r c; do
		$html h2 "$(jq -r '.name' <<< "$c")"
		$html ul "$(
			m=`jq -r '.monikers | length != 0' <<< "$c"`
			r=`jq -r '.relationships | length != 0' <<< "$c"`
			if [[ $m = true ]] || [[ $r = true ]]; then
				if [[ $m = true ]]; then
					$html li "$(
						$html b Monikers:
						$html ul "$(
							while IFS= read -r i; do
								$html li "$i"
							done < <(jq -r '.monikers[]' <<< "$c")
						)"
					)"
				fi
				if [[ $r = true ]]; then
					$html li "$(
						$html b Relationships:
						$html ul "$(
							while IFS= read -r i; do
								$html li "$i"
							done < <(jq -r '.relationships[]' <<< "$c")
						)"
					)"
				fi
			fi
		)"
	done < <(jq -c '.[]' data/characters.json)
	$html h1 Story
	while IFS= read -r l; do
		k=`jq -r '.key' <<< "$l"`
		v=`jq -r '.value' <<< "$l"`
		$html p "$(
			$html b "$k:"
			printf " $v"
		)"
	done < <(jq -c '.[] | to_entries[]' data/script.json)
} > README.md || echo "'$html' not found" >&2
