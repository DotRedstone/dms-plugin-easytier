.pragma library

// [Localization]
var STRINGS = {
    zh_CN: {
        title: "EasyTier",
        tabTopology: "拓扑",
        tabProfiles: "组网方案",
        tabConnectors: "连接器",
        connected: "已连接",
        disconnected: "未连接",
        starting: "正在切换…",
        cliMissing: "未检测到 easytier-cli",
        serviceStopped: "服务未运行",
        managedStopped: "组网未启动",
        rpcUnreachable: "已启动，等待 RPC 就绪…",
        noInstanceHint: "RPC 已就绪，暂无组网实例（配置中心超时或未下发）",
        off: "OFF",
        on: "ON",
        thisDevice: "本机",
        modeManaged: "托管方案",
        modeSystemd: "系统服务",
        modeBadgeManaged: "方案: %1",
        modeBadgeManagedEmpty: "方案: 未配置",
        modeBadgeSystemd: "服务: %1",
        network: "网络",
        virtualIp: "虚拟 IP",
        natType: "NAT",
        traffic: "流量",
        peers: "节点",
        routes: "子网路由",
        allPeers: "全部",
        p2pPeers: "直连 P2P",
        relayPeers: "中转 Relay",
        searchPlaceholder: "搜索主机名、虚拟 IP 或协议…",
        noPeers: "暂无远端节点",
        noMatchingPeers: "无匹配节点",
        noRoutes: "暂无子网代理路由",
        copyIp: "复制虚拟 IP",
        copyHostname: "复制主机名",
        copyUrl: "复制连接地址",
        copied: "已复制到剪贴板",
        refresh: "刷新状态",
        restart: "重启连接",
        enableService: "启动 EasyTier",
        disableService: "停止 EasyTier",
        serviceStarted: "EasyTier 已启动",
        serviceStoppedToast: "EasyTier 已停止",
        serviceRestarted: "EasyTier 已重启",
        controlFailed: "操作失败",
        onlineCount: "%1 在线",
        viaHop: "下一跳 %1",
        hopsCount: "%1 跳",

        // Profiles UI
        runModeLabel: "运行方式",
        savedProfiles: "已保存方案",
        newProfile: "新建方案",
        editProfile: "编辑方案",
        noProfilesYet: "尚未创建组网方案，点击右上角「新建方案」直接配置网络名与密钥。",
        createFirstProfile: "立即新建组网方案",
        profileName: "方案名称",
        profileNamePlaceholder: "例如：家里组网 / 异地联机",
        authModePassword: "密码组网",
        authModeUri: "配置中心 (-w)",
        configServerUri: "配置服务器地址 (-w)",
        configServerPlaceholder: "udp://198.51.100.10:22020/admin 或用户名",
        networkName: "网络名称 (--network-name)",
        networkNamePlaceholder: "例如：example-net",
        networkSecret: "网络密钥 (--network-secret)",
        networkSecretPlaceholder: "输入组网密钥",
        dhcpAuto: "自动分配虚拟 IP (DHCP)",
        dhcpAutoDesc: "由网格内节点自动协商 10.x.x.x 地址",
        staticIpv4: "静态虚拟 IPv4 (-i)",
        staticIpv4Placeholder: "例如：10.144.144.2/24",
        initialPeers: "初始对等节点 (--peers)",
        peerInputPlaceholder: "tcp://198.51.100.1:11010（回车或点 + 添加）",
        subnetProxies: "子网代理 CIDR (-n，可选)",
        cidrInputPlaceholder: "例如：192.168.50.0/24（回车或点 + 添加）",
        customHostname: "自定义主机名（可选）",
        customHostnamePlaceholder: "留空默认使用系统主机名",
        noTunMode: "免虚拟网卡模式 (--no-tun)",
        noTunModeDesc: "不创建 TUN 网卡，无需管理员授权即可在用户态运行",
        cancel: "取消",
        save: "保存",
        saveAndConnect: "保存并连接",
        connectNow: "连接此方案",
        reconnectNow: "应用重连",
        deleteProfile: "删除方案",
        profileSaved: "组网方案已保存",
        profileDeleted: "组网方案已删除",
        systemdModeHint: "当前使用外部 Systemd 服务（%1），参数由系统服务配置管理；你可随时切回「托管方案」在弹窗内直接配置多套网络。",
        tagUri: "URI 配置",
        tagDhcp: "DHCP",
        tagNoTun: "免网卡",
        peersCountTag: "%1 节点地址",

        // Connectors UI
        connectorsOfflineHint: "请先启动 EasyTier 连接，随后即可在此动态添加或移除远端节点地址（无需重启服务）。",
        connectorAddPlaceholder: "tcp://198.51.100.1:11010 或 udp://…",
        connectorAddBtn: "添加连接器",
        connectorRemoveBtn: "移除连接器",
        connectorAdded: "已添加连接器",
        connectorRemoved: "已移除连接器",
        noConnectors: "当前实例暂无配置的出站连接器",
        connConnected: "已连接",
        connConnecting: "连接中",
        connDisconnected: "未连接",

        // Settings page
        settingSectionDisplay: "外观与交互",
        settingBackendMode: "默认运行模式",
        settingBackendModeDesc: "选择由插件托管组网方案直接拉起 easytier-core，或控制外部 Systemd 服务。",
        settingLanguage: "界面语言",
        settingLanguageDesc: "自动跟随系统区域设置或手动指定语言。",
        langAuto: "自动 (Auto)",
        langZh: "简体中文",
        langEn: "English",
        settingPillMode: "顶栏胶囊显示内容",
        settingPillModeDesc: "连接成功后在 DankBar 胶囊上展示的主要文本。",
        pillPeers: "在线节点数",
        pillIp: "本机虚拟 IPv4",
        pillNetwork: "网络名称",
        pillIcon: "仅显示图标",
        settingCopyField: "点击节点默认复制",
        settingCopyFieldDesc: "在节点列表中点击复制按钮时写入剪贴板的字段。",
        copyFieldIp: "虚拟 IPv4 地址",
        copyFieldHost: "节点主机名",
        settingRightClickToggle: "右键顶栏胶囊快速开关",
        settingRightClickToggleDesc: "在 DankBar 上右键点击插件图标时直接启动或停止连接。",
        settingShowRoutes: "显示子网代理路由",
        settingShowRoutesDesc: "当网格网络中存在子网代理 (Proxy CIDRs) 时在弹窗底部展示路由条目。",
        settingSectionBackend: "外部服务与 RPC 连接",
        settingPollInterval: "轮询刷新间隔",
        settingPollIntervalDesc: "后台调用 easytier-cli 拉取节点拓扑的时间间隔。",
        settingServiceScope: "外部 Systemd 单元作用域",
        settingServiceScopeDesc: "在「系统服务」模式下生效：系统级服务通过 pkexec / sudo 控制；用户级通过 systemctl --user 控制。",
        scopeSystem: "系统级 (system)",
        scopeUser: "用户级 (user)",
        settingServiceUnit: "外部 Systemd 服务单元名",
        settingServiceUnitDesc: "在「系统服务」模式下用于启停的单元名称（例如 easytier.service）。",
        settingRpcPortal: "EasyTier RPC 地址",
        settingRpcPortalDesc: "easytier-core 监听的本地管理 RPC 端点（默认 127.0.0.1:15888）。"
    },
    en: {
        title: "EasyTier",
        tabTopology: "Topology",
        tabProfiles: "Profiles",
        tabConnectors: "Connectors",
        connected: "Connected",
        disconnected: "Disconnected",
        starting: "Switching…",
        cliMissing: "easytier-cli not found",
        serviceStopped: "Service is stopped",
        managedStopped: "Profile is stopped",
        rpcUnreachable: "Started, waiting for RPC…",
        noInstanceHint: "RPC reachable, no active network instance (config server timeout)",
        off: "OFF",
        on: "ON",
        thisDevice: "This device",
        modeManaged: "Managed Profile",
        modeSystemd: "Systemd Service",
        modeBadgeManaged: "Profile: %1",
        modeBadgeManagedEmpty: "Profile: Unset",
        modeBadgeSystemd: "Service: %1",
        network: "Network",
        virtualIp: "Virtual IP",
        natType: "NAT",
        traffic: "Traffic",
        peers: "Peers",
        routes: "Subnet Routes",
        allPeers: "All",
        p2pPeers: "P2P",
        relayPeers: "Relay",
        searchPlaceholder: "Search hostname, virtual IP, or protocol…",
        noPeers: "No remote peers connected",
        noMatchingPeers: "No matching peers",
        noRoutes: "No subnet proxy routes",
        copyIp: "Copy virtual IP",
        copyHostname: "Copy hostname",
        copyUrl: "Copy connector URL",
        copied: "Copied to clipboard",
        refresh: "Refresh status",
        restart: "Restart connection",
        enableService: "Start EasyTier",
        disableService: "Stop EasyTier",
        serviceStarted: "EasyTier started",
        serviceStoppedToast: "EasyTier stopped",
        serviceRestarted: "EasyTier restarted",
        controlFailed: "Operation failed",
        onlineCount: "%1 online",
        viaHop: "via %1",
        hopsCount: "%1 hop(s)",

        // Profiles UI
        runModeLabel: "Backend Mode",
        savedProfiles: "Saved Profiles",
        newProfile: "New Profile",
        editProfile: "Edit Profile",
        noProfilesYet: "No network profiles yet. Click 'New Profile' to configure network name, secret, and peers.",
        createFirstProfile: "Create Network Profile",
        profileName: "Profile Name",
        profileNamePlaceholder: "e.g. Home Mesh / Lab Net",
        authModePassword: "Standard",
        authModeUri: "Config URI (-w)",
        configServerUri: "Config Server URI (-w)",
        configServerPlaceholder: "udp://198.51.100.10:22020/admin or username",
        networkName: "Network Name (--network-name)",
        networkNamePlaceholder: "e.g. example-net",
        networkSecret: "Network Secret (--network-secret)",
        networkSecretPlaceholder: "Enter network secret",
        dhcpAuto: "Automatic Virtual IP (DHCP)",
        dhcpAutoDesc: "Automatically negotiate a 10.x.x.x address from peers",
        staticIpv4: "Static Virtual IPv4 (-i)",
        staticIpv4Placeholder: "e.g. 10.144.144.2/24",
        initialPeers: "Initial Peers (--peers)",
        peerInputPlaceholder: "tcp://198.51.100.1:11010 (Enter or + to add)",
        subnetProxies: "Subnet Proxy CIDRs (-n, optional)",
        cidrInputPlaceholder: "e.g. 192.168.50.0/24 (Enter or + to add)",
        customHostname: "Custom Hostname (optional)",
        customHostnamePlaceholder: "Leave blank to use system hostname",
        noTunMode: "Userspace No-TUN Mode (--no-tun)",
        noTunModeDesc: "Run without creating a TUN device (no root authentication needed)",
        cancel: "Cancel",
        save: "Save",
        saveAndConnect: "Save & Connect",
        connectNow: "Connect",
        reconnectNow: "Reconnect",
        deleteProfile: "Delete",
        profileSaved: "Profile saved",
        profileDeleted: "Profile deleted",
        systemdModeHint: "Controlling external systemd unit (%1). Switch to 'Managed Profile' anytime to configure networks directly in this panel.",
        tagUri: "Config URI",
        tagDhcp: "DHCP",
        tagNoTun: "No-TUN",
        peersCountTag: "%1 peer(s)",

        // Connectors UI
        connectorsOfflineHint: "Start EasyTier first to dynamically add or remove outbound peer connectors without restarting.",
        connectorAddPlaceholder: "tcp://198.51.100.1:11010 or udp://…",
        connectorAddBtn: "Add connector",
        connectorRemoveBtn: "Remove connector",
        connectorAdded: "Connector added",
        connectorRemoved: "Connector removed",
        noConnectors: "No outbound connectors configured",
        connConnected: "Connected",
        connConnecting: "Connecting",
        connDisconnected: "Disconnected",

        // Settings page
        settingSectionDisplay: "Appearance & Behavior",
        settingBackendMode: "Default Backend Mode",
        settingBackendModeDesc: "Run profiles managed directly by the plugin or control an external systemd service.",
        settingLanguage: "Language",
        settingLanguageDesc: "Follow the system locale automatically or pick a fixed UI language.",
        langAuto: "Auto",
        langZh: "简体中文",
        langEn: "English",
        settingPillMode: "Bar Pill Display",
        settingPillModeDesc: "Primary text shown next to the icon in the DankBar pill when connected.",
        pillPeers: "Online peer count",
        pillIp: "Virtual IPv4",
        pillNetwork: "Network name",
        pillIcon: "Icon only",
        settingCopyField: "Default Copy Field",
        settingCopyFieldDesc: "Value copied when clicking a peer copy action.",
        copyFieldIp: "Virtual IPv4",
        copyFieldHost: "Hostname",
        settingRightClickToggle: "Right-Click Bar Pill to Toggle",
        settingRightClickToggleDesc: "Start or stop EasyTier when right-clicking the bar widget.",
        settingShowRoutes: "Show Subnet Routes",
        settingShowRoutesDesc: "Display advertised proxy CIDR routes at the bottom of the popout.",
        settingSectionBackend: "External Service & RPC Backend",
        settingPollInterval: "Poll Interval",
        settingPollIntervalDesc: "Background refresh interval for querying easytier-cli.",
        settingServiceScope: "External Systemd Scope",
        settingServiceScopeDesc: "Used in Systemd Service mode: system units use pkexec / sudo; user units use systemctl --user.",
        scopeSystem: "System (system)",
        scopeUser: "User (user)",
        settingServiceUnit: "External Systemd Unit",
        settingServiceUnitDesc: "Unit name controlled in Systemd Service mode (e.g. easytier.service).",
        settingRpcPortal: "EasyTier RPC Portal",
        settingRpcPortalDesc: "Local management RPC endpoint of easytier-core (default 127.0.0.1:15888)."
    }
};

function resolveLang(overrideValue, localeName) {
    if (overrideValue === "zh_CN" || overrideValue === "en")
        return overrideValue;
    var raw = String(localeName || "").toLowerCase();
    return raw.indexOf("zh") === 0 ? "zh_CN" : "en";
}

function tr(lang, key, arg1) {
    var table = STRINGS[lang] || STRINGS.en;
    var text = table[key] !== undefined ? table[key] : (STRINGS.en[key] || key);
    if (arg1 !== undefined && arg1 !== null)
        text = text.replace("%1", String(arg1));
    return text;
}

// [Formatters]
function stripCidr(value) {
    var s = String(value || "").trim();
    if (!s || s === "-")
        return "";
    var slash = s.indexOf("/");
    return slash >= 0 ? s.slice(0, slash) : s;
}

function formatBytes(bytes) {
    var n = Number(bytes);
    if (!isFinite(n) || n <= 0)
        return "0 B";
    var units = ["B", "KB", "MB", "GB", "TB"];
    var idx = 0;
    while (n >= 1024 && idx < units.length - 1) {
        n /= 1024;
        idx++;
    }
    var digits = idx === 0 ? 0 : (n >= 100 ? 0 : (n >= 10 ? 1 : 2));
    return n.toFixed(digits) + " " + units[idx];
}

function formatLatency(ms, rawText) {
    var n = Number(ms);
    if (isFinite(n) && n >= 0) {
        return (n < 10 ? n.toFixed(1) : String(Math.round(n))) + " ms";
    }
    var raw = String(rawText || "").trim();
    if (!raw || raw === "-")
        return "—";
    return raw.indexOf("ms") >= 0 ? raw : (raw + " ms");
}
