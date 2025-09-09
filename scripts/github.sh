# scripts/github.sh
#!/usr/bin/env bash
set -euo pipefail

echo "Requesting administrator password..."
sudo -v || { echo "Failed to obtain administrator privileges."; exit 1; }

read -rp "Enter your GitHub account email for the SSH key: " EMAIL
EMAIL=${EMAIL:-}

if [[ -z "$EMAIL" ]]; then
  echo "No email provided. Exiting."
  exit 1
fi

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

KEY_PATH="$SSH_DIR/id_ed25519"

if [[ -f "$KEY_PATH" ]]; then
  echo "SSH key already exists at $KEY_PATH (leaving it in place)."
else
  echo "Generating new SSH key (ed25519)..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
fi

# Start/ensure ssh-agent
if ! pgrep -x "ssh-agent" >/dev/null; then
  eval "$(ssh-agent -s)"
fi

# macOS keychain integration
if [[ -f "$HOME/Library/LaunchAgents/org.openbsd.ssh-agent.plist" ]]; then
  launchctl load -w "$HOME/Library/LaunchAgents/org.openbsd.ssh-agent.plist" || true
fi

# Add key to agent with macOS keychain helpers
if [[ -x /usr/bin/ssh-add ]]; then
  /usr/bin/ssh-add --apple-use-keychain "$KEY_PATH" || ssh-add "$KEY_PATH" || true
fi

# Configure to use keychain & GitHub host
SSH_CONFIG="$SSH_DIR/config"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"
if ! grep -q "Host github.com" "$SSH_CONFIG"; then
  cat >> "$SSH_CONFIG" <<'EOF'

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
fi


echo
echo "Public key (add this to GitHub -> Settings -> SSH and GPG keys):"
echo "----------------------------------------------------------------"
cat "$KEY_PATH.pub"
echo "----------------------------------------------------------------"
echo ""
echo "Follow this link to add your SSH key to your GitHub account:"
echo "https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account"
echo "You can test with: ssh -T git@github.com"
