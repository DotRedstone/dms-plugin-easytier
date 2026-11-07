# dms-plugin-easytier

面向 **DMS 2 (DankMaterialShell / Dux Modular Shell)** 的 **EasyTier** 网格组网监控、官方风格可视化配置助手与动态连接器管理插件。

## 功能特性

- **内置官方风格配置助手（对齐 `easytier.cn/assistant/`）**：
  - 在弹窗 **组网方案 (`Profiles`)** 标签页内置 `3 × 2` 六分区编辑器，无需手写配置文件即可新建、编辑、保存并一键连接多套组网方案：
    1. **身份与 IP**：支持本地配置助手与 Web 配置中心 (`-w` + `--machine-id`) 切换；网络名称、网络密钥（显隐切换与随机生成）、实例名、主机名；DHCP 自动分配、静态 IPv4/IPv6 与公网 IPv6 提供/自动获取。
    2. **连接与监听**：支持手动配置节点与独立服务端（仅监听）模式；一键填入官方公共共享节点 (`tcp://public.easytier.cn:11010`)；本地监听地址（一键填充默认 `11010/11011/11012` 端口）、公网映射监听地址 (`mapped_listeners`) 与 `--no-listener` 纯出站开关。
    3. **代理与路由**：子网代理 (`[[proxy_network]]`)、手动路由覆盖 (`routes`)、出口节点 (`exit_nodes`) 以及 SOCKS5 入站代理 (`socks5_proxy`)。
    4. **VPN 与转发**：WireGuard VPN Portal (`[vpn_portal_config]`) 客户端网段与监听端口；可视化 TCP/UDP 端口转发规则卡片 (`[[port_forward]]`)。
    5. **高级选项**：默认传输协议、加密算法 (`aes-gcm` / `aes-256-gcm` / `chacha20` / `xor`)、Zstd 数据压缩 (`data_compress_algo`)、TUN MTU、多线程数、网卡名、Magic DNS 域名、中继网络白名单、外部中继与实例接收限速，以及全部 29 项高级布尔开关（低延迟优先、免 TUN / `smoltcp`、P2P 打洞控制、KCP / QUIC 代理与转发控制、私有模式、全局 UDP 广播中继等）。
    6. **日志与 TOML 实时预览**：控制台与文件日志级别配置；实时渲染 `easytier-core` 原生兼容的 TOML 配置（默认遮罩密钥，支持一键复制完整 `TOML`）。
  - **凭据隔离与预检**：方案保存在权限为 `0600` 的 `~/.config/easytier-dms/profiles.json`；托管启动时渲染 `0600` 运行时 `managed.toml`，先执行 `easytier-core --check-config` 校验，再通过 `-c` 加载，避免命令行暴露密钥。
- **双运行模式无缝切换**：
  - **托管方案 (`Managed Profile`)**：由插件管理 `dms-easytier-managed.service`（默认隔离在 `127.0.0.1:15889` RPC，开启 TUN 时通过 `pkexec` 最小权限授予 `CAP_NET_ADMIN` / `CAP_NET_RAW` / `CAP_NET_BIND_SERVICE`；勾选免 TUN 时纯用户态无感运行）。
  - **系统服务 (`Systemd Service`)**：直接启停现有的系统级或用户级 `easytier.service`（默认 `127.0.0.1:15888` RPC）。
- **动态连接器热管理 (`Connectors`)**：运行期间无需中断现有组网，直接在弹窗内查看出站连接器状态并动态添加/移除 `tcp://`、`udp://`、`ws://`、`wss://`、`wg://`、`quic://` 远端节点。
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

在 **DMS Settings -> Plugins** 中启用 **EasyTier**，并在 **Bar -> Widgets** 或 **Control Center** 中添加组件。修改子组件 QML 或 JS 模块后可执行 `systemctl --user restart dms.service` 刷新组件缓存。

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
