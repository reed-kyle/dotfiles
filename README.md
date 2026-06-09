# Dotfiles (chezmoi)

## Purpose

Personal macOS dotfiles managed with chezmoi.

## Bootstrap

```sh
xcode-select --install
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --source ~/dotfiles https://github.com/reed-kyle/dotfiles.git
```

On first apply, chezmoi scripts will:

- install Homebrew (if missing)
- run `brew bundle` (installs tmux, Rectangle, Karabiner-Elements, etc.)
- apply macOS keyboard defaults
- write Rectangle window-snap bindings

TPM bootstraps itself on first tmux launch (see `dot_config/tmux/tmux.conf`):
opening tmux for the first time clones TPM and installs plugins automatically.

Mission Control / Space shortcuts are set manually in **System Settings →
Keyboard → Keyboard Shortcuts → Mission Control** — chezmoi doesn't manage
them. See the binding table below for the target chords.

## Keyboard layers

Four layers, each owned by exactly one modifier. See `dot_config/private_karabiner/karabiner.json`.

| Layer                            | Modifier         | Source           |
| -------------------------------- | ---------------- | ---------------- |
| Terminal / editor (tmux, Neovim) | `Ctrl`           | Caps Lock (hold) |
| OS-spatial (Spaces, Rectangle)   | `Hyper` = `⌃⌥⌘⇧` | Tab (hold)       |
| App (in-app tabs/windows)        | `Cmd`            | Cmd              |
| Summon (Spotlight, Contexts)     | `Opt` / `Cmd`    | Opt / Cmd        |

Caps tap = Esc; Tab tap = Tab.

### Verb grammar

The same three verbs in every layer, on the same keys:

| Verb                   | Keys    | `Ctrl` (nvim / tmux)      | `Cmd` (apps)       | `Hyper` (OS-spatial)      |
| ---------------------- | ------- | ------------------------- | ------------------ | ------------------------- |
| Go to adjacent sibling | `hjkl`  | split / pane nav          | —                  | space prev/next (`h`/`l`) |
| Go to slot N           | numbers | tmux window: `prefix + #` | app tab: `Cmd + #` | space: `Hyper + #`        |
| Reshape current region | arrows  | resize split              | —                  | place window (Rectangle)  |

Dimensionality matches layout:

- Panes/splits are 2-D → all four `hjkl` directions are live
- Spaces are 1-D → only `h`/`l` move; `j`/`k` are idle at the space level and
  Rectangle's native corner cluster `Hyper+u/i/j/k` claims them for quarters

### Bindings

| Action                      | Chord                                           |
| --------------------------- | ----------------------------------------------- |
| nvim window nav             | `Ctrl+hjkl` (tmux-aware via vim-tmux-navigator) |
| nvim split resize           | `Ctrl+arrows`                                   |
| nvim buffers                | `Shift+h/l`                                     |
| tmux prefix                 | `Ctrl+a`                                        |
| tmux window switch          | `prefix` + `1–9`                                |
| Space prev / next           | `Hyper+h` / `Hyper+l`                           |
| Jump to Space N             | `Hyper+1–4`                                     |
| Window halves (Rectangle)   | `Hyper+arrows`                                  |
| Window quarters (Rectangle) | `Hyper+u/i/j/k`                                 |
| Maximize (Rectangle)        | `Hyper+Enter`                                   |
| Jump to tab N               | `Cmd+1–N`                                       |
| Spotlight                   | `Opt+Space`                                     |
| App switcher (Contexts)     | `Cmd+Tab`, `Cmd+Space`                          |

Rule of thumb: tmux owns multiplexing; Ghostty runs as a single window.

## Local overrides

Machine-specific secrets/aliases go in:

```sh
~/.zshrc.local
```

This file is sourced by `~/.zshrc` if present.

## Notes

- Keyboard repeat settings may require logout/login to take effect.
- First tmux launch will pause briefly while TPM clones itself and installs
  plugins; subsequent launches are instant.
