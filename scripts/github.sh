#!/bin/bash

# Ask for the administrator password upfront.
echo "Requesting administrator password..."
sudo -v
if [ $? -eq 0 ]; then
    echo "Administrator password accepted."
else
    echo "Failed to obtain administrator privileges."
    exit 1
fi

# Prompt the user for their email
read -p "Enter your github account email for the SSH key: " EMAIL

# Check if the email is empty
if [ -z "$EMAIL" ]; then
  echo "Email is required. Exiting."
  exit 1
fi

# Generate SSH key
ssh-keygen -t ed25519 -C "$EMAIL" -f ~/.ssh/id_ed25519

# Start the ssh-agent
eval "$(ssh-agent -s)"

# Create or modify the SSH config file
if [ ! -f ~/.ssh/config ]; then
  touch ~/.ssh/config
fi

# Add configuration to ssh config file
cat <<EOT >> ~/.ssh/config

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOT

# Add the SSH key to the ssh-agent and store the passphrase in the keychain
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Print the public key to the console
echo "SSH key generated successfully. The public key is:"
cat ~/.ssh/id_ed25519.pub

# Provide the GitHub documentation link
echo ""
echo "Follow this link to add your SSH key to your GitHub account:"
echo "https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account"
