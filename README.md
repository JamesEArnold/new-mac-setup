# new-mac-setup

Automated scripts to take a fresh Mac to a fully configured development environment. Each step is idempotent and safe to re-run; existing tools and configs are detected and preserved.

## Quick start

```bash
git clone <this-repo> ~/Development/new-mac-setup
cd ~/Development/new-mac-setup
./run_all.sh
```

`run_all.sh` walks through each script in order and lets you skip any of them. You can also run scripts individually.

## Layout

```
new-mac-setup/
├── run_all.sh                 # Orchestrator — confirms each step
├── configs/
│   └── gwt.zsh                # Git worktree shell helpers (sourced from ~/.zshrc)
└── scripts/
    ├── mac_defaults.sh        # macOS system preferences (Finder, Dock, screenshots, etc.)
    ├── apps.sh                # Homebrew, casks, brew formulae, Dock pinning
    ├── cli_tools.sh           # Non-brew CLI tools: uv, AWS CLI v2, gcloud
    ├── terminal_defaults.sh   # zsh, Oh My Zsh, Starship, Nerd Font, plugins, gwt
    ├── nvm.sh                 # nvm + latest Node.js LTS
    ├── vs_code.sh             # VS Code CLI + extensions + settings
    └── github.sh              # Generates an ed25519 SSH key for GitHub
```

## What gets installed

### `apps.sh` — desktop apps & brew formulae
Casks (skipped if already installed):
- iTerm, Visual Studio Code, Google Chrome, Firefox, Slack, Postman
- 1Password, ChatGPT, Claude Desktop, Codex, DBeaver, Obsidian, OpenCode
- noTunes, Stats, Claude Code (CLI), GitHub CLI, Hack Nerd Font (optional)

Formulae:
- `coreutils`, `tree`, `terminal-notifier`, `pulumi/tap/pulumi`, `anomalyco/tap/opencode`

Pinned to Dock: every installed cask that has an `.app` bundle, plus Docker Desktop if present.

> Docker Desktop is **not** installed via brew here — install it manually from https://docker.com (brew cask installs have caused issues). The script will pin it to the Dock if it's already in `/Applications`.

### `cli_tools.sh` — outside Homebrew
- `uv` (Astral Python package manager) via the official installer
- AWS CLI v2 via the official `.pkg` (Homebrew lags releases)
- Google Cloud SDK via `brew install --cask google-cloud-sdk`

### `terminal_defaults.sh` — zsh environment
- Oh My Zsh + Starship prompt + Meslo Nerd Font
- Plugins: `git`, `zsh-syntax-highlighting`, `zsh-autosuggestions`
- `~/.zshrc` additions:
  - `$HOME/.local/bin` on PATH
  - `/Library/Frameworks/Python.framework/Versions/3.12/bin` on PATH
  - `ecr-login` alias for AWS SSO + ECR Docker login
  - Sources `~/.config/zsh/gwt.zsh` (copied from `configs/gwt.zsh`)

### `mac_defaults.sh` — system preferences
Finder (show hidden files, path bar, list view), Dock (size 36, autohide, scale effect), screenshots → `~/Pictures/Screenshots` as PNG, fast key repeat, no natural scrolling, Activity Monitor defaults, TextEdit plain-text + UTF-8.

### `nvm.sh` — Node
Installs nvm v0.40.0 and the latest stable Node, sets it as default.

### `vs_code.sh` — VS Code
Categories prompted individually: Core (Prettier, ESLint, TS), Git (GitLens), Themes (Dracula, Material Icons), React (snippets, Tailwind, Headwind), Dev Tools (Docker, Python, debugpy, Playwright, Prisma, SonarLint, CSV/Office viewers), AI (Claude Code, ChatGPT). Also writes a few opinionated `settings.json` keys.

### `github.sh` — SSH key
Generates `~/.ssh/id_ed25519`, adds to keychain, prints the public key, and links to GitHub's docs for adding it.

## Git worktree helpers (`configs/gwt.zsh`)

Once `terminal_defaults.sh` has run, these functions are available in every shell:

- `gwt-create <branch> [base]` — create a worktree at `../<repo>-worktrees/<branch>`, run `yarn install/prepare/build`
- `gwt-create-fast <branch> [base]` — same as above, but applies the personal `~/.physna-fast-tests/` overlay first
- `gwt-checkout <remote-branch>` — fetch and check out a tracking worktree
- `gwt-cleanup` — remove the worktree you're currently in
- `gwt-list`, `gwt-remove <path>`, `gwt-repair`, `gwt-status` — utilities

## Re-running

Everything is designed to be re-runnable. Already-installed apps/extensions/plugins are detected and skipped; `~/.zshrc` and `settings.json` are appended to or merged, never overwritten.

## Manual / out-of-scope

Things deliberately not automated:
- Cursor (managed manually)
- Docker Desktop (download from docker.com)
- Work-managed apps (Falcon, Self Service, AWS VPN Client, DisplayLink)
- GitHub authentication step — `github.sh` prints the public key and a link to add it to your account
