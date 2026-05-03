mod dns 'dns.just'

_default:
    @just --justfile {{ justfile() }} --list devops
