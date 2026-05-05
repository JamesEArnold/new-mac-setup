# run_all.sh
#!/bin/bash
set -euo pipefail

# Make all .sh files executable
find . -type f -name "*.sh" -exec chmod +x {} \;

confirm() {
  local prompt="${1:-Proceed?}"
  while true; do
    read -r -p "$prompt [Y/n] " yn
    case "${yn:-Y}" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

echo "This setup will make system changes and install developer tools."

confirm "Apply macOS defaults now?" && ./scripts/mac_defaults.sh || echo "Skipped macOS defaults."
confirm "Install apps & brew formulae?" && ./scripts/apps.sh || echo "Skipped apps."
confirm "Install non-brew CLI tools (uv, aws, gcloud)?" && ./scripts/cli_tools.sh || echo "Skipped CLI tools."
confirm "Set up terminal defaults?" && ./scripts/terminal_defaults.sh || echo "Skipped terminal."
confirm "Configure iTerm2 (custom prefs folder + DynamicProfiles)?" && ./scripts/iterm.sh || echo "Skipped iTerm2."
confirm "Install nvm & Node?" && ./scripts/nvm.sh || echo "Skipped nvm."
confirm "Configure VS Code?" && ./scripts/vs_code.sh || echo "Skipped VS Code."
confirm "Generate GitHub SSH key?" && ./scripts/github.sh || echo "Skipped GitHub SSH setup."

echo "All done. You may need to open a new terminal window for PATH changes to take effect."
