# Dotfiles

Personal macOS dotfiles, managed with [chezmoi](https://chezmoi.io).
Ghostty + tmux + LazyVim + starship, Tokyo Night throughout.

## Bootstrap

```sh
xcode-select --install
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --source ~/dotfiles https://github.com/reed-kyle/dotfiles.git
```

First apply installs Homebrew, the Brewfile packages, node + pi, and macOS
defaults. tmux plugins install themselves on first launch.

Set manually: Mission Control / Spaces shortcuts in **System Settings →
Keyboard → Keyboard Shortcuts → Mission Control** (chords in the table below).

## Keyboard layers

Four layers, each owned by one modifier (`dot_config/private_karabiner/karabiner.json`).
Caps tap = Esc; Tab tap = Tab.

| Layer                            | Modifier         | Source           |
| -------------------------------- | ---------------- | ---------------- |
| Terminal / editor (tmux, Neovim) | `Ctrl`           | Caps Lock (hold) |
| OS-spatial (Spaces, Rectangle)   | `Hyper` = `⌃⌥⌘⇧` | Tab (hold)       |
| App (in-app tabs/windows)        | `Cmd`            | Cmd              |
| Summon (Spotlight, Contexts)     | `Opt` / `Cmd`    | Opt / Cmd        |

| Action                      | Chord                  |
| --------------------------- | ---------------------- |
| nvim window nav             | `Ctrl+hjkl`            |
| nvim split resize           | `Ctrl+arrows`          |
| nvim buffers                | `Shift+h/l`            |
| tmux prefix                 | `Ctrl+a`               |
| tmux window switch          | `prefix` + `1–9`       |
| Space prev / next           | `Hyper+h` / `Hyper+l`  |
| Jump to Space N             | `Hyper+1–4`            |
| Window halves (Rectangle)   | `Hyper+arrows`         |
| Window quarters (Rectangle) | `Hyper+u/i/j/k`        |
| Maximize (Rectangle)        | `Hyper+Enter`          |
| Jump to tab N               | `Cmd+1–N`              |
| Spotlight                   | `Opt+Space`            |
| App switcher (Contexts)     | `Cmd+Tab`, `Cmd+Space` |

## Local overrides

Machine-specific secrets and aliases live in `~/.zshrc.local`, sourced by
`~/.zshrc`.
