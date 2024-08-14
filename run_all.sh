#!/bin/bash

# Find all .sh files and make them executable
find . -type f -name "*.sh" -exec chmod +x {} \;

# Execute the scripts in the specified order
./scripts/mac_defaults.sh
./scripts/apps.sh
./scripts/terminal_defaults.sh
./scripts/nvm.sh
./scripts/vs_code.sh
