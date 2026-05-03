#!/usr/bin/env bash

set -e

ACME_DIR="$(cd "$(dirname "$0")" && pwd)"
ACME_BIN="$ACME_DIR/bin/acme"
LOCAL_BIN="$HOME/.local/bin"

green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red() { printf "\033[31m%s\033[0m\n" "$*"; }

detect_rc() {
    case "${SHELL##*/}" in
        zsh)  echo "$HOME/.zshrc" ;;
        bash) [ -f "$HOME/.bash_profile" ] && echo "$HOME/.bash_profile" || echo "$HOME/.bashrc" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.profile" ;;
    esac
}

add_to_path_in_rc() {
    local dir="$1"
    local rc
    rc=$(detect_rc)
    local export_line

    if [[ "${SHELL##*/}" == "fish" ]]; then
        export_line="fish_add_path $dir"
    else
        export_line="export PATH=\"$dir:\$PATH\""
    fi

    if grep -qF "$dir" "$rc" 2>/dev/null; then
        yellow "  PATH entry already present in $rc — skipping"
        return
    fi

    printf "\n# acme CLI\n%s\n" "$export_line" >> "$rc"
    green "  Added to $rc"
    yellow "  Run: source $rc   (or open a new terminal)"
}

printf "\nInstalling acme CLI\n\n"

if [ ! -f "$ACME_BIN" ]; then
    red "Error: $ACME_BIN not found. Run this script from the .acme directory."
    exit 1
fi

chmod +x "$ACME_BIN"

if mkdir -p "$LOCAL_BIN" 2>/dev/null; then
    ln -sf "$ACME_BIN" "$LOCAL_BIN/acme"
    green "  Symlinked acme -> $LOCAL_BIN/acme"
    if echo "$PATH" | tr ':' '\n' | grep -qx "$LOCAL_BIN"; then
        green "\nDone. 'acme' is ready to use."
    else
        add_to_path_in_rc "$LOCAL_BIN"
        green "\nDone."
    fi
else
    yellow "  Could not use $LOCAL_BIN — adding $ACME_DIR/bin to PATH instead"
    add_to_path_in_rc "$ACME_DIR/bin"
    green "\nDone."
fi
