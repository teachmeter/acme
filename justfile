# justfile — run `just` to list available recipes

mod devops 'recipes/devops/mod.just'

_default:
    @just --list
