SCRIPTS_DIR := source_directory() + "/scripts"


_default:
    @just --justfile {{ justfile() }} --list devops::dns
# Watch A and AAAA DNS records for a domain
watch domain refresh="5":
    @{{ SCRIPTS_DIR }}/dns-watch.sh {{ domain }} --refresh-rate {{ refresh }}
