SCRIPTS_DIR := source_directory() + "/scripts"


_default:
    @just --justfile {{ justfile() }} --list ddev

# Backup all ddev databases you have
backup backup_dir:
    @{{ SCRIPTS_DIR }}/ddev-backup.sh {{backup_dir}}
