#!/usr/bin/env bash
set -euo pipefail
case $1 in
	br|hr)
		printf '<%s>' "$1"
	;;
	*)
		tag="$1"
		shift
		printf '<%s>%s</%s>' "$tag" "$@" "$tag"
	;;
esac

