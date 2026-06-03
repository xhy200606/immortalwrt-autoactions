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

- Web 管理地址：`192.168.1.2`
- 登录账号：`root`
- 登录密码：`root`
- LAN 网关/DNS：`192.168.1.1`
- LAN DHCP：默认关闭，避免和主路由冲突

默认集成插件：

- OpenClash：`vernesong/OpenClash`
- EasyTier：`EasyTier/luci-app-easytier`，包含 `luci-app-easytier` 和 `easytier`
- Material 3 主题：`KawaiiHachimi/luci-theme-material3`
- ttyd：`luci-app-ttyd` 和 `ttyd`
- Turbo ACC：`luci-app-turboacc`
- iStore：`linkease/istore`，包名 `luci-app-store`
- Tailscale：`luci-app-tailscale-community` 和 `tailscale`
- Docker：`luci-app-dockerman`、`docker`、`dockerd` 和 `docker-compose`
- 集客 AC：`laipeng668/luci-app-gecoosac`
- UPnP：`luci-app-upnp` 和 `miniupnpd`

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
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
```

添加软件包：编辑对应的 `.config`，例如：

```text
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-passwall=y
```

这些包是否能编译通过取决于对应 feeds 是否存在、是否兼容 `openwrt-25.12`。
