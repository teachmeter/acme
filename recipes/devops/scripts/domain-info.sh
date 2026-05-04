#!/usr/bin/env bash

DOMAIN="${1:-}"
if [ -z "$DOMAIN" ]; then
    printf "Usage: domain-info.sh <domain>\n" >&2
    exit 1
fi

# ── terminal helpers ──────────────────────────────────────────────────────────
bold=$(tput bold)
reset=$(tput sgr0)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
cyan=$(tput setaf 6)

header() { printf "\n%s%s%s\n" "$bold$cyan" "$1" "$reset"; }
row()    { printf "  %-18s %s\n" "$1" "$2"; }
ok()     { printf "%s%s%s" "$green" "$1" "$reset"; }
warn()   { printf "%s%s%s" "$yellow" "$1" "$reset"; }
err()    { printf "%s%s%s" "$red" "$1" "$reset"; }

# ── NS provider detection ─────────────────────────────────────────────────────
detect_ns_provider() {
    local ns="$1"
    case "$ns" in
        *.cloudflare.com)           echo "Cloudflare" ;;
        *.awsdns-*)                 echo "AWS Route 53" ;;
        *ns-cloud-*.googledomains.com|*.googledomains.com) echo "Google Cloud DNS" ;;
        *.google.com)               echo "Google" ;;
        *.digitalocean.com)         echo "DigitalOcean" ;;
        *.domaincontrol.com)        echo "GoDaddy" ;;
        *.registrar-servers.com)    echo "Namecheap" ;;
        *.hetzner.com)              echo "Hetzner" ;;
        *.azure-dns.*)              echo "Azure DNS" ;;
        *.nsone.net)                echo "NS1" ;;
        *.dnsimple.com)             echo "DNSimple" ;;
        *)
            # fallback: extract second-level domain of NS as provider hint
            echo "$ns" | awk -F. '{if(NF>=2) print $(NF-1)"."$NF; else print $0}'
            ;;
    esac
}

# ── IP org lookup via whois ───────────────────────────────────────────────────
ip_org() {
    local ip="$1"
    if ! command -v whois &>/dev/null; then
        warn "whois not available"
        return
    fi
    local org
    org=$(whois "$ip" 2>/dev/null | grep -iE '^(OrgName|org-name|netname|descr):' | head -1 | sed 's/^[^:]*:[[:space:]]*//')
    if [ -n "$org" ]; then
        ok "$org"
    else
        warn "unknown"
    fi
}

# ── main ──────────────────────────────────────────────────────────────────────
printf "%sDomain info: %s%s\n" "$bold" "$DOMAIN" "$reset"

# Nameservers
header "Nameservers"
ns_list=$(dig +noall +answer NS "$DOMAIN" 2>/dev/null | awk '$4 == "NS" {print $5}')
if [ -z "$ns_list" ]; then
    row "NS" "$(err 'none found')"
else
    first=true
    provider=""
    while IFS= read -r ns; do
        [ -z "$ns" ] && continue
        p=$(detect_ns_provider "${ns%.}")
        [ -z "$provider" ] && provider="$p"
        if $first; then
            row "NS" "$(ok "${ns%.)}")"
            first=false
        else
            row "" "$(ok "${ns%.)}")"
        fi
    done <<< "$ns_list"
    row "Provider" "$(warn "$provider")"
fi

# SOA
header "SOA"
soa=$(dig +short SOA "$DOMAIN" 2>/dev/null)
if [ -n "$soa" ]; then
    soa_ns=$(echo "$soa" | awk '{print $1}')
    soa_serial=$(echo "$soa" | awk '{print $3}')
    row "Primary NS" "$(ok "${soa_ns%.)}")"
    row "Serial" "$soa_serial"
else
    row "SOA" "$(err 'none found')"
fi

# A records / hosting
header "Hosting (A)"
a_list=$(dig +short A "$DOMAIN" 2>/dev/null)
if [ -z "$a_list" ]; then
    row "A" "$(err 'none found')"
else
    while IFS= read -r ip; do
        [ -z "$ip" ] && continue
        rdns=$(dig +short -x "$ip" 2>/dev/null | head -1)
        rdns="${rdns:-(no rDNS)}"
        org=$(ip_org "$ip")
        row "A" "$(ok "$ip")"
        row "  rDNS" "${rdns%.}"
        row "  Org" "$org"
    done <<< "$a_list"
fi

# AAAA records / hosting
header "Hosting (AAAA)"
aaaa_list=$(dig +short AAAA "$DOMAIN" 2>/dev/null)
if [ -z "$aaaa_list" ]; then
    row "AAAA" "$(warn 'none')"
else
    while IFS= read -r ip; do
        [ -z "$ip" ] && continue
        rdns=$(dig +short -x "$ip" 2>/dev/null | head -1)
        rdns="${rdns:-(no rDNS)}"
        org=$(ip_org "$ip")
        row "AAAA" "$(ok "$ip")"
        row "  rDNS" "${rdns%.}"
        row "  Org" "$org"
    done <<< "$aaaa_list"
fi

# MX
header "Mail (MX)"
mx_list=$(dig +short MX "$DOMAIN" 2>/dev/null)
if [ -z "$mx_list" ]; then
    row "MX" "$(warn 'none')"
else
    while IFS= read -r mx; do
        [ -z "$mx" ] && continue
        prio=$(echo "$mx" | awk '{print $1}')
        host=$(echo "$mx" | awk '{print $2}')
        row "MX $prio" "$(ok "${host%.)}")"
    done <<< "$mx_list"
fi

# TXT records
header "TXT"
txt_list=$(dig +short TXT "$DOMAIN" 2>/dev/null)
if [ -z "$txt_list" ]; then
    row "TXT" "$(warn 'none')"
else
    first=true
    while IFS= read -r txt; do
        [ -z "$txt" ] && continue
        if $first; then
            row "TXT" "$(ok "$txt")"
            first=false
        else
            row "" "$(ok "$txt")"
        fi
    done <<< "$txt_list"
fi

printf "\n"
