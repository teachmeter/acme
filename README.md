# acme

Personal command runner built on [just](https://just.systems).

## Requirements

- [just](https://just.systems) 1.24.0+
- bash
- dig (for DNS recipes)

## Install

```sh
bash install.sh
```

This symlinks the `acme` command into `~/.local/bin` (creating it if needed) and adds it to your `PATH` in your shell rc file. No `sudo` required.

Open a new terminal or run `source ~/.zshrc` (or the relevant rc file shown) to activate.

## Usage

```sh
acme                   # list all available commands
acme devops            # list devops commands
acme devops::dns::watch example.com
acme devops::dns::watch example.com -r 10
```
