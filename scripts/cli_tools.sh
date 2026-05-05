#!/usr/bin/env bash
# scripts/cli_tools.sh
# Installs CLI tools that are not distributed (or not preferred) via Homebrew.
# Idempotent and interactive.

set -euo pipefail

prompt_yes() {
  local prompt="${1:-Proceed?} [Y/n] "
  local ans=""
  printf "%s" "$prompt"
  read -r ans || true
  case "${ans:-Y}" in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *)     return 0 ;;
  esac
}

have() { command -v "$1" >/dev/null 2>&1; }

# --- uv (fast Python package & project manager) -------------------------------
if have uv; then
  echo "✓ uv already installed at $(command -v uv)"
else
  if prompt_yes "Install uv (Astral's Python package manager)?"; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "uv installed. Restart shell or 'source ~/.local/bin/env' to pick it up."
  fi
fi

# --- AWS CLI v2 (official installer; Homebrew lags releases) ------------------
if have aws; then
  echo "✓ aws CLI already installed at $(command -v aws) ($(aws --version 2>&1))"
else
  if prompt_yes "Install AWS CLI v2 (official installer)?"; then
    TMP_PKG="$(mktemp -d)/AWSCLIV2.pkg"
    curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "$TMP_PKG"
    sudo installer -pkg "$TMP_PKG" -target /
    rm -f "$TMP_PKG"
  fi
fi

# --- Google Cloud SDK ---------------------------------------------------------
if have gcloud; then
  echo "✓ gcloud already installed at $(command -v gcloud)"
else
  if prompt_yes "Install Google Cloud SDK (via Homebrew cask)?"; then
    brew install --cask google-cloud-sdk
    echo "gcloud installed. Run 'gcloud init' to authenticate."
  fi
fi

echo "cli_tools.sh completed."
