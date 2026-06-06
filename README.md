# ImmortalWrt 25.12 GitHub Actions 云编译模板

这个模板参考 `jxjxcw/build_openwrt` 一类项目的组织方式：GitHub Actions 负责云端编译，`configs/` 保存设备配置，`scripts/diy-part1.sh` 和 `scripts/diy-part2.sh` 负责自定义 feeds 与源码修改。

源码默认使用：

- 仓库：`https://github.com/immortalwrt/immortalwrt`
- 分支：`openwrt-25.12`

> 说明：模板默认按 OpenWrt/ImmortalWrt 常见分支命名使用 `openwrt-25.12`。如果你在 GitHub 上确认实际分支名就是 `25.12`，手动运行 workflow 时把 `source_branch` 改成 `25.12` 即可。

## 使用方法

1. 新建一个 GitHub 仓库。
2. 把本目录所有文件推送到仓库。
3. 打开仓库的 `Actions` 页面。
4. 选择 `Build ImmortalWrt`。
5. 点击 `Run workflow`。
6. 默认配置会编译 `x86_64.config`。
7. 编译成功后，在 workflow run 的 `Artifacts` 中下载固件。

## 目录说明

```text
.github/workflows/build-immortalwrt.yml  GitHub Actions 编译流程
configs/x86_64.config                    x86_64 旁路由配置
scripts/diy-part1.sh                     feeds 更新前执行
scripts/diy-part2.sh                     feeds 安装后、defconfig 前执行
```

默认配置用于 x86_64 设备旁路由：

- Web 管理地址：`192.168.1.5`
- 登录账号：`root`
- 登录密码：`root`
- LAN 网关/DNS：`192.168.1.1`
- LAN DHCP：默认关闭，避免和主路由冲突
- IPv6：默认关闭 DHCPv6/RA/NDP，并禁用 `odhcpd`
- x86_64 根分区大小：`4096 MB`
- `/root/login.sh`：服务器本地存在 `/home/xhy200606/Openwrt/login.sh` 时，编译会自动复制到固件的 `/root/login.sh`，权限为 `700`

默认集成插件：

- OpenClash：`vernesong/OpenClash`
- 软件包管理：`luci-app-package-manager`
- EasyTier：`EasyTier/luci-app-easytier`，包含 `luci-app-easytier` 和 `easytier`
- Material 3 主题：`KawaiiHachimi/luci-theme-material3`
- Design 主题：`0x676e67/luci-theme-design`
- Aurora 主题：`eamonxg/luci-theme-aurora`
- Argon 主题：`jerrykuku/luci-theme-argon`
- Argon 配置：`jerrykuku/luci-app-argon-config`
- ttyd：`luci-app-ttyd` 和 `ttyd`
- Turbo ACC：`mufeng05/turboacc`，适配 OpenWrt `24.10/25.12/snapshot`
- iStore：`linkease/istore`，包名 `luci-app-store`
- Tailscale：`luci-app-tailscale-community` 和 `tailscale`
- SmartDNS：`luci-app-smartdns` 和 `smartdns`
- 集客 AC：`laipeng668/luci-app-gecoosac`
- Diskman：`luci-app-diskman`
- 文件管理器：`luci-app-filemanager`
- MosDNS：`sbwml/luci-app-mosdns`，包含 `luci-app-mosdns` 和 `mosdns`
- PassWall：`luci-app-passwall`，启用 `Xray`、`SingBox` 和 `V2ray Geodata`
- UPnP：`luci-app-upnp` 和 `miniupnpd-nftables`
- Watchcat：`luci-app-watchcat`
- vnStat：`luci-app-vnstat2`、`vnstat2` 和 `vnstati2`
- QEMU Guest Agent：`qemu-ga`

> Turbo ACC 使用 `mufeng05/turboacc` 的 `add_turboacc.sh` 接入，会按内核版本复制补丁和包。`firewall4` 环境下建议使用 Flow Offloading；Full Cone NAT 选择兼容模式，不建议在 `firewall4` 下启用高性能 Broadcom 模式。

默认 DNS 链路：

- `dnsmasq-full` 监听局域网 DNS `:53`
- `dnsmasq-full` 转发到 SmartDNS `127.0.0.1:6053`
- SmartDNS 默认启用缓存、预取、过期应答和双栈优选
- OpenClash 不自动启用，导入订阅或配置文件后再手动开启

## 编译其他设备

先在本地 ImmortalWrt 源码中生成对应设备的 `.config`：

```bash
git clone --depth 1 --branch openwrt-25.12 https://github.com/immortalwrt/immortalwrt openwrt
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig
make defconfig
cp .config ../configs/your-device.config
```

然后提交 `configs/your-device.config`，手动运行 workflow 时把 `config` 输入改为：

```text
your-device.config
```

## 常见自定义

添加第三方 feeds：编辑 `scripts/diy-part1.sh`。

```bash
echo "src-git helloworld https://github.com/fw876/helloworld" >> feeds.conf.default
```

修改默认 IP：编辑 `scripts/diy-part2.sh`。

```bash
LAN_IP="${LAN_IP:-192.168.1.5}"
sed -i "s/192.168.1.1/${LAN_IP}/g" package/base-files/files/bin/config_generate
```

添加软件包：编辑对应的 `.config`，例如：

```text
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-passwall=y
```

这些包是否能编译通过取决于对应 feeds 是否存在、是否兼容 `openwrt-25.12`。
