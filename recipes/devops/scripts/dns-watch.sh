#!/usr/bin/env bash

REFRESH=5

while [ $# -gt 0 ]; do
    case "$1" in
        -r|--refresh-rate) REFRESH="$2"; shift 2 ;;
        -*) printf "Unknown option: %s\nUsage: dns-watch.sh <domain> [-r|--refresh-rate <seconds>]\n" "$1" >&2; exit 1 ;;
        *) DOMAIN="$1"; shift ;;
    esac
done

if [ -z "$DOMAIN" ]; then
    printf "Usage: dns-watch.sh <domain> [-r|--refresh-rate <seconds>]\n" >&2
    exit 1
fi

cleanup() {
    tput smam
    tput cnorm
    tput rmcup
}
trap cleanup EXIT
trap 'exit' INT TERM

tput smcup
tput civis
tput rmam  # disable line wrapping — clip at terminal edge instead

draw() {
    local rows max_records tmp_a tmp_aaaa count=0
    rows=$(tput lines)
    max_records=$(( rows - 5 ))

    tput cup 0 0
    tput ed

    printf "Domain: %-30s  Refresh: %ss  Updated: %s\n\n" \
        "$DOMAIN" "$REFRESH" "$(date '+%H:%M:%S')"
    printf "%-6s  %-36s  %-6s  %s\n" "TYPE" "NAME" "TTL" "VALUE"
    printf "%-6s  %-36s  %-6s  %s\n" "------" "------------------------------------" "------" "-----"

    tmp_a=$(mktemp)
    tmp_aaaa=$(mktemp)
    dig +noall +answer "$DOMAIN" A    > "$tmp_a"    &
    dig +noall +answer "$DOMAIN" AAAA > "$tmp_aaaa" &
    wait

    for tmp in "$tmp_a" "$tmp_aaaa"; do
        while read -r name ttl _class type value && (( count < max_records )); do
            printf "%-6s  %-36s  %-6s  %s\n" "$type" "$name" "$ttl" "$value"
            (( count++ ))
        done < "$tmp"
        rm -f "$tmp"
    done

    tput cup $(( rows - 1 )) 0
    printf "[q] quit"
}

while true; do
    draw
    if read -r -s -n 1 -t "$REFRESH" key && [ "$key" = "q" ]; then
        break
    fi
done
