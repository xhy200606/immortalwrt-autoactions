#!/bin/bash
#========================================================================================================================
# Description: Build ImmortalWrt x86_64 bypass router
# Function: Diy script after installing feeds, for LAN, password, and package customization.
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: openwrt-25.12
#========================================================================================================================

# ------------------------------- Main source started -------------------------------
#
# Set root password to: root
sed -i 's|^root:[^:]*:|root:$1$fShxqZPK$GIpLusJDY9SqOOD0k8IEL.:|' package/base-files/files/etc/shadow

# Set etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release

# Add Turbo ACC patches and packages for OpenWrt 25.12.
rm -rf package/turboacc package/turboacc-source
git clone --depth 1 https://github.com/mufeng05/turboacc.git package/turboacc-source
bash package/turboacc-source/add_turboacc.sh
rm -rf package/turboacc-source

# Add custom packages.
rm -rf package/luci-app-openclash package/easytier package/luci-theme-material3 package/luci-theme-design package/luci-theme-aurora package/luci-theme-argon package/luci-app-argon-config package/luci-app-gecoosac
git clone --depth 1 https://github.com/vernesong/OpenClash.git package/luci-app-openclash
git clone --depth 1 https://github.com/EasyTier/luci-app-easytier.git package/easytier
git clone --depth 1 https://github.com/KawaiiHachimi/luci-theme-material3.git package/luci-theme-material3
git clone --depth 1 https://github.com/0x676e67/luci-theme-design.git package/luci-theme-design
git clone --depth 1 https://github.com/eamonxg/luci-theme-aurora.git package/luci-theme-aurora
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config
git clone --depth 1 https://github.com/laipeng668/luci-app-gecoosac.git package/luci-app-gecoosac

# Set bypass router LAN IP.
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# Bypass router defaults: static LAN, gateway/DNS to main router, DHCP disabled.
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-bypass-router <<'EOF'
#!/bin/sh
uci -q batch <<'UCI'
set network.lan.ipaddr='192.168.1.2'
set network.lan.netmask='255.255.255.0'
set network.lan.gateway='192.168.1.1'
set network.lan.dns='192.168.1.1'
set dhcp.lan.ignore='1'
commit network
commit dhcp
UCI
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-bypass-router
#
# ------------------------------- Main source ends -------------------------------
