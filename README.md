# dms-plugin-easytier

面向 **DMS 2 (DankMaterialShell / Dux Modular Shell)** 的 **EasyTier** 网格组网状态监控与服务控制插件。

## 功能特性

- **DankBar 顶栏/侧栏胶囊**：展示自定义网格拓扑图标与连接状态，支持切换显示**在线节点数**、**本机虚拟 IPv4**、**网络名称**或**仅图标**模式，支持右键快速启停服务。
- **Control Center 快捷磁贴**：集成至 DMS 2 控制中心，支持一键开关与连接状态速览。
- **拓扑详情弹窗 (Popout)**：
  - 本机节点卡片：显示主机名、虚拟 IPv4（一键复制）、组网名称、NAT 类型、累计收发流量及内核版本。
  - 远端节点列表：自动过滤 `Local` 回环项，区分 **P2P 直连**与 **Relay 中转**徽标、传输协议、实时延迟着色及收发字节统计；支持关键字搜索、直连/中转筛选及展开查看丢包率与节点 ID。
  - 子网代理路由：自动解析并展示网格内广播的 `Proxy CIDRs` 与下一跳信息。
- **安全脱敏边界**：后端辅助脚本 `easytier-dms` 在解析 `easytier-cli -o json node` 时立即剥离 `.config` 原始配置段，绝不输出 `network_secret` 等敏感凭据。
- **IPC 快捷键接入**：内置 `easytier` IPC 目标，便于绑定窗口管理器快捷键。

## 依赖项

- DMS `>= 2.0.0`（Quickshell）
- `easytier-cli`（EasyTier `>= 2.0`）
- `jq`
- `systemctl`（系统级单元控制依赖 `pkexec` / Polkit 认证代理或免密 `sudo`）

## 安装方式

将插件仓库软链接或复制到 `~/.config/dms/plugins/easytier`：

```bash
mkdir -p ~/.config/dms/plugins
ln -s /path/to/dms-plugin-easytier ~/.config/dms/plugins/easytier
dms ipc call plugin-scan scan
```

随后在 **DMS Settings -> Plugins** 中启用 **EasyTier**，并在 **Bar -> Widgets** 或 **Control Center** 中添加组件。

## IPC 命令

启用插件后可通过 `dms ipc` 调用：

```bash
dms ipc call easytier status
dms ipc call easytier popout
dms ipc call easytier toggle
dms ipc call easytier start
dms ipc call easytier stop
dms ipc call easytier restart
dms ipc call easytier refresh
```

## 系统级服务免密开关（可选）

若使用系统级 `easytier.service`，默认点击开关会通过 `pkexec` 唤起桌面 Polkit 图形授权框。如需无感切换，可在系统中为所属用户组放行对应单元（示例以 NixOS Polkit 规则为例）：

```nix
security.polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "easytier.service" &&
        subject.isInGroup("wheel")) {
      return polkit.Result.YES;
    }
  });
'';
```

## 验证与测试

```bash
chmod +x easytier-dms tests/test-helper.sh
./tests/test-helper.sh
jq -e . plugin.json
```
