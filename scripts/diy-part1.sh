#!/bin/bash
#========================================================================================================================
# Description: Build ImmortalWrt x86_64 bypass router
# Function: Diy script before updating feeds, for adding/removing feed sources.
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: openwrt-25.12
#========================================================================================================================

# Add a feed source
# sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
grep -q "src-git istore" feeds.conf.default || echo "src-git istore https://github.com/linkease/istore;main" >> feeds.conf.default

# other
# rm -rf package/emortal/{autosamba,ipv6-helper}
