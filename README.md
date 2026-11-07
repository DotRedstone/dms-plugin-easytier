# dms-plugin-easytier

面向 **DMS 2 (DankMaterialShell / Dux Modular Shell)** 的 **EasyTier** 网格组网状态监控、可视化组网方案管理与动态连接器控制插件。

## 功能特性

- **双运行模式无缝切换**：
  - **托管方案模式 (`Managed Profile`)**：无需手写配置文件或环境变量，直接在顶栏弹窗内新建、编辑、保存并切换多套组网方案（支持密码组网 `--network-name` / `--network-secret` 与配置中心 `-w` URI、自动 DHCP 或静态虚拟 IPv4、初始节点列表、子网代理 CIDR、自定义主机名以及免授权 `--no-tun` 用户态模式）。方案凭据独立保存在权限为 `0600` 的 `~/.config/easytier-dms/profiles.json` 中，启动时通过临时 `0600` `EnvironmentFile` 注入，避免命令行参数暴露密钥。
  - **系统服务模式 (`Systemd Service`)**：直接控制现有的系统级或用户级 `easytier.service`。
- **动态连接器热管理 (`Connectors`)**：运行期间无需中断现有组网，直接在弹窗内查看出站连接器状态并动态添加/移除 `tcp://`、`udp://`、`ws://`、`wg://`、`quic://` 远端节点。
- **拓扑详情与检索 (`Topology`)**：
  - 本机节点卡片：主机名、虚拟 IPv4（一键复制）、组网名称、当前运行模式徽标、NAT 类型与累计收发流量。
  - 远端节点列表：自动过滤 `Local` 回环项，展示 **P2P 直连** / **Relay 中转**徽标、协议、延迟着色、收发字节统计，支持关键字搜索与直连/中转过滤。
  - 子网代理路由：自动展示网格内广播的 `Proxy CIDRs` 与下一跳信息。
- **DankBar 胶囊 & Control Center 磁贴 & IPC 接口**：支持顶栏显示节点数/虚拟 IP/网络名/仅图标，右键快速开关，控制中心磁贴联动与窗口管理器快捷键绑定。

## 依赖项

- DMS `>= 2.0.0`（Quickshell）
- `easytier-core` 与 `easytier-cli`（EasyTier `>= 2.0`）
- `jq`、`systemctl`、`systemd-run`

## 安装方式

```bash
mkdir -p ~/.config/dms/plugins
ln -s /path/to/dms-plugin-easytier ~/.config/dms/plugins/easytier
dms ipc call plugin-scan scan
```

在 **DMS Settings -> Plugins** 中启用 **EasyTier**，并在 **Bar -> Widgets** 或 **Control Center** 中添加组件。

## IPC 命令

```bash
dms ipc call easytier status
dms ipc call easytier popout
dms ipc call easytier toggle
dms ipc call easytier start
dms ipc call easytier stop
dms ipc call easytier restart
dms ipc call easytier refresh
```

## 验证与测试

```bash
chmod +x easytier-dms tests/test-helper.sh
shellcheck easytier-dms tests/test-helper.sh
./tests/test-helper.sh
jq -e . plugin.json
```
