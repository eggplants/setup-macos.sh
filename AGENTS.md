# AGENTS.md

## What this repo is

The global [mise](https://mise.jdx.dev) config for a macOS (Apple Silicon) machine. It is cloned as `~/.config/mise`, and `mise bootstrap` sets the machine up from it: Homebrew formulae/casks and Mac App Store apps (installed by mise itself), CLI tools, dotfiles, the colima LaunchAgent, and a few imperative steps.

## Apply the config

```bash
mise bootstrap --dry-run   # preview
mise bootstrap             # apply (zsh alias: mb)
```

## Architecture

| File | Purpose |
|------|---------|
| `config.toml` | `[tools]`, `[bootstrap.packages]` (`brew:` / `brew-cask:` / `mas:`), `[bootstrap.repos]` (zsh plugins, nano syntax), `[dotfiles]`, shell activation, login shell, colima user service, `bootstrap` task |
| `dotfiles/` | `[dotfiles]` sources (symlinked unless the entry says otherwise) |
| `tasks/setup/` | File tasks run by the `bootstrap` task: `macos`, `gpg`, `git`, `docker`, `vscode`, `claude` |
| `scripts/stop-brew-colima.sh` | `post-tools` hook: unloads the old `brew services` colima agent |
| `bootstrap.sh` | Installs Xcode CLT and mise (`~/.local/bin`), clones this repo, runs `mise bootstrap` |

### Key design decisions

- **Repo = global config** — relative `source` paths in `[dotfiles]` resolve from `~/.config/mise`. Tools in `[tools]` are global.
- **Declarative first, tasks for the rest** — use `[bootstrap.*]` / `[dotfiles]` when mise can check the state. Hooks and the `bootstrap` task run on every `mise bootstrap`, so they must be idempotent (guard every step).
- **mise tools vs brew** — CLIs and runtimes come from `[tools]` whenever the mise registry has a macOS build (`pipx:` tools need `uv`). `brew:` keeps libraries, GNU tools, and CLIs without a macOS build in the registry (e.g. `ttyd`, `nkf`, `docker`). mise installs `brew:` / `brew-cask:` itself; Homebrew is optional. Removing an entry does not uninstall it — use `mise bootstrap packages prune`.
- **Docker** — colima and lima come from `[tools]` and run as the `dev.mise.colima` LaunchAgent (`[bootstrap.services.colima]`, via `~/.local/bin/mise exec`). The docker CLI, buildx, compose, and the credential helper stay in `brew:` so `cliPluginsExtraDirs` can point at the stable `/opt/homebrew/lib/docker/cli-plugins`. `setup:docker` writes that and selects the `colima` context.
- **mise itself** — installed by mise.run into `~/.local/bin` (not Homebrew), because the colima service runs that path.
- **Git config** — `dotfiles/gitconfig` is static; `user.email` / `user.signingkey` are derived from the GPG keyring and written to `~/.gitconfig.local` by `setup:git`.
- **Shell** — `~/.zshrc` / `~/.zshenv` are whole-file dotfiles, so `~/.zshrc` activates mise itself; `[bootstrap.mise_shell_activate]` writes only shims into `~/.zprofile` (and bash files). `~/.zshrc` re-prepends `~/.local/bin` and `/opt/homebrew/bin` because `/etc/zprofile`'s `path_helper` reorders `PATH`.
- **Mac App Store** — `mas` comes from `[tools]`, which installs after packages, so a brand-new Mac needs a second `mise bootstrap` to install `mas:` entries.
