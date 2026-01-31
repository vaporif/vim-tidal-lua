# List available recipes
default:
    @just --list

# Run all checks
check: lint-lua lint-toml lint-actions check-typos

# Lint nvim lua with selene
lint-lua:
    selene lua/ plugin/ ftplugin/ ftdetect/
    stylua --check .

# Format lua files
fmt-lua:
    stylua .

# Lint TOML files
lint-toml:
    taplo check

# Format TOML files
fmt-toml:
    taplo fmt

# Lint GitHub Actions
lint-actions:
    actionlint

# Check for typos
check-typos:
    typos

# Format all
fmt: fmt-lua fmt-toml

# Set up git hooks
setup-hooks:
    git config core.hooksPath .githooks

