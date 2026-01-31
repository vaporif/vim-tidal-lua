# List available recipes
default:
    @just --list

# Run all checks
check: lint-lua lint-toml lint-actions check-typos

lint-lua:
    selene lua/ plugin/ ftplugin/ ftdetect/
    stylua --check .

fmt-lua:
    stylua .

lint-toml:
    taplo check

fmt-toml:
    taplo fmt

lint-actions:
    actionlint

check-typos:
    typos

fmt: fmt-lua fmt-toml

setup-hooks:
    git config core.hooksPath .githooks

