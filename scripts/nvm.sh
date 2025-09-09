# scripts/nvm.sh
#!/usr/bin/env bash
set -euo pipefail

echo "Installing nvm..."
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
else
  echo "nvm already installed at ~/.nvm"
fi

# Decide which profile to update (prefer current shell)
PROFILE_FILE="${PROFILE_FILE:-}"
if [[ -z "${PROFILE_FILE}" ]]; then
  case "${SHELL##*/}" in
    zsh) PROFILE_FILE="$HOME/.zshrc" ;;
    bash) PROFILE_FILE="$HOME/.bashrc" ;;
    *) PROFILE_FILE="$HOME/.profile" ;;
  esac
fi

touch "$PROFILE_FILE"

# Idempotent additions
grep -q 'export NVM_DIR=' "$PROFILE_FILE" || echo 'export NVM_DIR="$HOME/.nvm"' >> "$PROFILE_FILE"
grep -q 'nvm.sh' "$PROFILE_FILE" || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$PROFILE_FILE"
grep -q 'bash_completion' "$PROFILE_FILE" || echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$PROFILE_FILE"

# Load nvm in current shell
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1090
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

echo "Installing latest Node.js LTS..."
# Prefer latest stable (node alias). You can switch to 'lts/*' if desired.
nvm install node
nvm alias default node
nvm use default

echo "Node installed: $(node -v) (npm $(npm -v))"
