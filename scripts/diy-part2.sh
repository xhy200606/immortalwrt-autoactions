#!/usr/bin/env bash
set -euo pipefail

# Run in the ImmortalWrt source directory after feeds are installed and before defconfig.
# Example:
# sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
