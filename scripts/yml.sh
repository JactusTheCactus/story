#!/usr/bin/env bash
set -euo pipefail
YML="tmp/$1"
cat data/config.yml data/$1.yml > "$YML"
yq "$YML" -o=json \
	| jq -c "del(._) | .$1" \
	> "data/$1.json"
