.pragma library

// [Localization]
var STRINGS = {
    zh_CN: {
        title: "EasyTier",
        connected: "已连接",
        disconnected: "未连接",
        starting: "正在切换…",
        cliMissing: "未检测到 easytier-cli",
        serviceStopped: "EasyTier 服务未运行",
        rpcUnreachable: "服务运行中，等待 RPC 就绪…",
        off: "OFF",
        on: "ON",
        thisDevice: "本机",
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
        copied: "已复制到剪贴板",
        refresh: "刷新状态",
        restart: "重启服务",
        enableService: "启动 EasyTier",
        disableService: "停止 EasyTier",
        serviceStarted: "EasyTier 已启动",
        serviceStoppedToast: "EasyTier 已停止",
        serviceRestarted: "EasyTier 已重启",
        controlFailed: "服务控制失败",
        onlineCount: "%1 在线",
        viaHop: "下一跳 %1",
        hopsCount: "%1 跳",
        settingSectionDisplay: "外观与交互",
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
        settingRightClickToggleDesc: "在 DankBar 上右键点击插件图标时直接启动或停止 EasyTier 服务。",
        settingShowRoutes: "显示子网代理路由",
        settingShowRoutesDesc: "当网格网络中存在子网代理 (Proxy CIDRs) 时在弹窗底部展示路由条目。",
        settingSectionBackend: "服务与 RPC 连接",
        settingPollInterval: "轮询刷新间隔",
        settingPollIntervalDesc: "后台调用 easytier-cli 拉取节点拓扑的时间间隔。",
        settingServiceScope: "Systemd 单元作用域",
        settingServiceScopeDesc: "系统级服务通过 pkexec / sudo 控制；用户级服务通过 systemctl --user 控制。",
        scopeSystem: "系统级 (system)",
        scopeUser: "用户级 (user)",
        settingServiceUnit: "Systemd 服务单元名",
        settingServiceUnitDesc: "用于启动、停止与重启的单元名称（例如 easytier.service）。",
        settingRpcPortal: "EasyTier RPC 地址",
        settingRpcPortalDesc: "easytier-core 监听的本地管理 RPC 端点（默认 127.0.0.1:15888）。"
    },
    en: {
        title: "EasyTier",
        connected: "Connected",
        disconnected: "Disconnected",
        starting: "Switching…",
        cliMissing: "easytier-cli not found",
        serviceStopped: "EasyTier service is stopped",
        rpcUnreachable: "Service active, waiting for RPC…",
        off: "OFF",
        on: "ON",
        thisDevice: "This device",
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
        copied: "Copied to clipboard",
        refresh: "Refresh status",
        restart: "Restart service",
        enableService: "Start EasyTier",
        disableService: "Stop EasyTier",
        serviceStarted: "EasyTier started",
        serviceStoppedToast: "EasyTier stopped",
        serviceRestarted: "EasyTier restarted",
        controlFailed: "Service control failed",
        onlineCount: "%1 online",
        viaHop: "via %1",
        hopsCount: "%1 hop(s)",
        settingSectionDisplay: "Appearance & Behavior",
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
        settingRightClickToggleDesc: "Start or stop the EasyTier service when right-clicking the bar widget.",
        settingShowRoutes: "Show Subnet Routes",
        settingShowRoutesDesc: "Display advertised proxy CIDR routes at the bottom of the popout.",
        settingSectionBackend: "Service & RPC Backend",
        settingPollInterval: "Poll Interval",
        settingPollIntervalDesc: "Background refresh interval for querying easytier-cli.",
        settingServiceScope: "Systemd Scope",
        settingServiceScopeDesc: "System units use pkexec / sudo; user units use systemctl --user.",
        scopeSystem: "System (system)",
        scopeUser: "User (user)",
        settingServiceUnit: "Systemd Service Unit",
        settingServiceUnitDesc: "Unit name controlled on start, stop, and restart (e.g. easytier.service).",
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
