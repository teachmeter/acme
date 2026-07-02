#!/usr/bin/env bash
set -euo pipefail

backup_dir="${1:-}"
if [[ -z "$backup_dir" ]]; then
  echo "Usage: ddev-backup.sh <backup_dir>" >&2
  exit 1
fi
mkdir -p "$backup_dir"

# read project names into real array (word-split; names have no spaces)
project_list=($(ddev list -j | jq -r '.raw[].name'))

total=${#project_list[@]}

if (( total == 0 )); then
  echo "No DDEV projects found."
  exit 0
fi

progress_bar() {
  local current=$1 total=$2 label=$3
  local width=30
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local pct=$(( current * 100 / total ))
  local bar_filled='' bar_empty=''
  (( filled > 0 )) && bar_filled=$(printf '#%.0s' $(seq 1 "$filled"))
  (( empty > 0 ))  && bar_empty=$(printf ' %.0s' $(seq 1 "$empty"))
  printf '\r[%s%s] %3d%% (%d/%d) %-30s' \
    "$bar_filled" "$bar_empty" "$pct" "$current" "$total" "$label"
}

snapshot_db() {
  # full ddev start, dump, stop. atomic write.
  local project=$1
  ddev start "$project" || return 1

  local stamp
  stamp=$(date +%Y-%m-%d_%H%M%S)
  local tmp="$backup_dir/$project.$stamp.sql.gz.tmp"
  if ddev export-db "$project" --file="$tmp"; then
    mv "$tmp" "$backup_dir/$project.$stamp.sql.gz"
  else
    rm -f "$tmp"
    ddev stop "$project"
    return 1
  fi
  ddev stop "$project"
}

count=0
for project in "${project_list[@]}"; do
  count=$((count + 1))
  progress_bar "$count" "$total" "$project"
  { snapshot_db "$project"; } >/dev/null 2>&1 || echo "$project: backup failed" >>"$backup_dir/backup-errors.log"
done

progress_bar "$total" "$total" "done"
printf '\n'
