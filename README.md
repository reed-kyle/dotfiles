# Dotfiles (chezmoi)

## Purpose

Personal macOS dotfiles managed with chezmoi.

## Bootstrap

```sh
xcode-select --install
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/reed-kyle/dotfiles.git
```

On first apply, chezmoi scripts will:

- install Homebrew (if missing)
- run `brew bundle`
- apply macOS keyboard defaults

## Local overrides

Machine-specific secrets/aliases go in:

```sh
~/.zshrc.local
```

This file is sourced by `~/.zshrc` if present.

## Notes

Keyboard repeat settings may require logout/login to take effect.
