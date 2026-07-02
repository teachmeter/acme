# justfile — run `just` to list available recipes

mod devops 'recipes/devops/mod.just'
mod ddev 'recipes/ddev/mod.just'

_default:
    @just --list
