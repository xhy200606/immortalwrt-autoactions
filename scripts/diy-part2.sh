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

# Install optional local login script into firmware root home.
# Keep the script outside Git because it may contain private account data.
LOGIN_SH="${LOGIN_SH:-/home/xhy200606/Openwrt/login.sh}"
if [ ! -f "$LOGIN_SH" ] && [ -f "/Users/chananyah/Documents/Shell/login.sh" ]; then
    LOGIN_SH="/Users/chananyah/Documents/Shell/login.sh"
fi
if [ ! -f "$LOGIN_SH" ] && [ -f "../login.sh" ]; then
    LOGIN_SH="../login.sh"
fi
if [ -f "$LOGIN_SH" ]; then
    mkdir -p package/base-files/files/root
    cp "$LOGIN_SH" package/base-files/files/root/login.sh
    chmod 700 package/base-files/files/root/login.sh
    echo "Installed login script to /root/login.sh"
else
    echo "WARNING: login.sh not found, skipped installing /root/login.sh"
fi

# Add Turbo ACC patches and packages for OpenWrt 25.12.
rm -rf package/turboacc package/turboacc-source
git clone --depth 1 https://github.com/mufeng05/turboacc.git package/turboacc-source
bash package/turboacc-source/add_turboacc.sh
rm -rf package/turboacc-source

# Add MosDNS LuCI app and matching data packages.
find feeds package -path "*/mosdns/Makefile" -delete 2>/dev/null || true
find feeds package -path "*/v2ray-geodata/Makefile" -delete 2>/dev/null || true
rm -rf package/mosdns package/v2ray-geodata
git clone --depth 1 -b v5 https://github.com/sbwml/luci-app-mosdns.git package/mosdns
git clone --depth 1 https://github.com/sbwml/v2ray-geodata.git package/v2ray-geodata

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

# Fix iStore version format for OpenWrt 25.12 APK packaging.
ISTORE_MAKEFILE="feeds/istore/luci/luci-app-store/Makefile"
if [ -f "$ISTORE_MAKEFILE" ]; then
    sed -i "s/^PKG_VERSION:=0\\.1\\.32-1$/PKG_VERSION:=0.1.32/" "$ISTORE_MAKEFILE"
    sed -i "s/^PKG_RELEASE:=$/PKG_RELEASE:=1/" "$ISTORE_MAKEFILE"
fi

# Set bypass router LAN IP.
LAN_IP="${LAN_IP:-192.168.1.5}"
LAN_GATEWAY="${LAN_GATEWAY:-192.168.1.1}"
sed -i "s/192.168.1.1/${LAN_IP}/g" package/base-files/files/bin/config_generate

# Bypass router defaults: static LAN, gateway/DNS to main router, DHCP and IPv6 disabled.
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-bypass-router <<EOF
#!/bin/sh
uci -q batch <<'UCI'
set network.lan.ipaddr='${LAN_IP}'
set network.lan.netmask='255.255.255.0'
set network.lan.gateway='${LAN_GATEWAY}'
set network.lan.dns='${LAN_GATEWAY}'
set network.lan.delegate='0'
delete network.globals.ula_prefix
delete network.lan.ip6assign
delete network.lan.ip6hint
delete network.lan.ip6ifaceid
set dhcp.lan.ignore='1'
set dhcp.lan.dynamicdhcp='0'
delete dhcp.lan.start
delete dhcp.lan.limit
delete dhcp.lan.leasetime
set dhcp.lan.dhcpv6='disabled'
set dhcp.lan.ra='disabled'
set dhcp.lan.ndp='disabled'
set dhcp.odhcpd.maindhcp='0'
set dhcp.odhcpd.disabled='1'
commit network
commit dhcp
UCI
/etc/init.d/odhcpd disable >/dev/null 2>&1 || true
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-bypass-router

# SmartDNS defaults: dnsmasq listens on LAN and forwards queries to local SmartDNS.
cat > package/base-files/files/etc/uci-defaults/98-smartdns-defaults <<'EOF'
#!/bin/sh
uci -q show smartdns.@smartdns[0] >/dev/null 2>&1 || uci add smartdns smartdns >/dev/null
uci -q batch <<'UCI'
set smartdns.@smartdns[0].enabled='1'
set smartdns.@smartdns[0].port='6053'
set smartdns.@smartdns[0].bind='127.0.0.1'
set smartdns.@smartdns[0].cache_size='32768'
set smartdns.@smartdns[0].prefetch_domain='1'
set smartdns.@smartdns[0].serve_expired='1'
set smartdns.@smartdns[0].dualstack_ip_selection='1'
set smartdns.@smartdns[0].ipv6_server='0'
delete dhcp.@dnsmasq[0].server
set dhcp.@dnsmasq[0].noresolv='1'
add_list dhcp.@dnsmasq[0].server='127.0.0.1#6053'
commit smartdns
commit dhcp
UCI
/etc/init.d/smartdns enable
/etc/init.d/dnsmasq enable
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/98-smartdns-defaults
#
# ------------------------------- Main source ends -------------------------------
