SCRIPTS_DIR := source_directory() + "/scripts"


_default:
    @just --justfile {{ justfile() }} --list devops::dns
# Show hosting provider and nameserver management for a domain
info domain:
    @{{ SCRIPTS_DIR }}/domain-info.sh {{ domain }}

# Watch A and AAAA DNS records for a domain
watch domain refresh="5":
    @{{ SCRIPTS_DIR }}/dns-watch.sh {{ domain }} --refresh-rate {{ refresh }}
