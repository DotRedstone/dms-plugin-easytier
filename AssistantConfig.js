.pragma library

// [EasyTier Assistant Schema & TOML Generator]
var WORDS_ADJ = [
    "amber", "arctic", "azure", "brisk", "calm", "cedar", "cobalt", "coral",
    "crisp", "dawn", "delta", "ember", "frost", "jade", "lunar", "misty",
    "noble", "nova", "onyx", "polar", "rapid", "solar", "sonic", "swift"
];

var WORDS_NOUN = [
    "atlas", "beacon", "bridge", "canyon", "comet", "crest", "falcon", "fjord",
    "harbor", "haven", "lynx", "matrix", "mesh", "nexus", "orbit", "otter",
    "peak", "pine", "prism", "pulse", "quartz", "ridge", "river", "spark"
];

var DEFAULT_FLAGS = {
    defaultProtocol: "tcp",
    encryptionAlgorithm: "aes-gcm",
    compression: "none",
    mtu: 1380,
    multiThread: true,
    multiThreadCount: 2,
    devName: "",
    relayNetworkWhitelist: "*",
    tldDnsZone: "et.net.",
    foreignRelayBpsLimit: "",
    instanceRecvBpsLimit: "",
    enableEncryption: true,
    enableIpv6: true,
    latencyFirst: false,
    enableExitNode: false,
    noTun: false,
    useSmoltcp: false,
    bindDevice: true,
    proxyForwardBySystem: false,
    enableP2p: true,
    p2pOnly: false,
    lazyP2p: false,
    needP2p: false,
    disableTcpHolePunching: false,
    disableUdpHolePunching: false,
    disableSymHolePunching: false,
    enableUpnp: true,
    enableKcpProxy: false,
    disableKcpInput: false,
    enableQuicProxy: false,
    disableQuicInput: false,
    relayAllPeerRpc: false,
    disableRelayData: false,
    disableRelayKcp: false,
    disableRelayQuic: false,
    enableRelayForeignKcp: false,
    enableRelayForeignQuic: false,
    acceptDns: false,
    privateMode: false,
    enableUdpBroadcastRelay: false
};

var DEFAULT_LISTENERS_PRESET = [
    "tcp://0.0.0.0:11010",
    "udp://0.0.0.0:11010",
    "wg://0.0.0.0:11011",
    "ws://0.0.0.0:11011/",
    "wss://0.0.0.0:11012/"
];

var PUBLIC_PEER_PRESET = "tcp://public.easytier.cn:11010";

function _pick(arr) {
    return arr[Math.floor(Math.random() * arr.length)];
}

function randomNetworkName() {
    var suffix = String(Math.floor(100 + Math.random() * 900));
    return _pick(WORDS_ADJ) + "-" + _pick(WORDS_NOUN) + "-" + suffix;
}

function randomInstanceName() {
    return "node-" + _pick(WORDS_NOUN) + "-" + String(Math.floor(10 + Math.random() * 90));
}

function randomSecret(len) {
    var n = len || 16;
    var chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    var out = "";
    for (var i = 0; i < n; i++) {
        out += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return out;
}

function normalizeSocks5(raw) {
    var s = String(raw || "").trim();
    if (!s)
        return "";
    if (s.indexOf("socks5://") === 0)
        return s;
    if (/^\d+$/.test(s))
        return "socks5://0.0.0.0:" + s;
    if (s.indexOf("://") < 0)
        return "socks5://" + s;
    return s;
}

function _cleanStringArray(arr) {
    if (!Array.isArray(arr))
        return [];
    var out = [];
    for (var i = 0; i < arr.length; i++) {
        var v = String(arr[i] || "").trim();
        if (v && out.indexOf(v) < 0)
            out.push(v);
    }
    return out;
}

function _boolOr(val, fallback) {
    if (val === true || val === false)
        return val;
    return fallback;
}

function normalizeFlags(rawFlags, legacyNoTun) {
    var src = (rawFlags && typeof rawFlags === "object") ? rawFlags : {};
    var mtuVal = parseInt(src.mtu, 10);
    var threadsVal = parseInt(src.multiThreadCount, 10);
    return {
        defaultProtocol: String(src.defaultProtocol || DEFAULT_FLAGS.defaultProtocol).trim() || "tcp",
        encryptionAlgorithm: String(src.encryptionAlgorithm || DEFAULT_FLAGS.encryptionAlgorithm).trim() || "aes-gcm",
        compression: src.compression === "zstd" ? "zstd" : "none",
        mtu: (!isNaN(mtuVal) && mtuVal >= 576 && mtuVal <= 65535) ? mtuVal : DEFAULT_FLAGS.mtu,
        multiThread: _boolOr(src.multiThread, DEFAULT_FLAGS.multiThread),
        multiThreadCount: (!isNaN(threadsVal) && threadsVal >= 2 && threadsVal <= 128) ? threadsVal : DEFAULT_FLAGS.multiThreadCount,
        devName: String(src.devName || "").trim(),
        relayNetworkWhitelist: src.relayNetworkWhitelist !== undefined ? String(src.relayNetworkWhitelist).trim() : DEFAULT_FLAGS.relayNetworkWhitelist,
        tldDnsZone: String(src.tldDnsZone !== undefined ? src.tldDnsZone : DEFAULT_FLAGS.tldDnsZone).trim() || "et.net.",
        foreignRelayBpsLimit: /^\d+$/.test(String(src.foreignRelayBpsLimit || "").trim()) ? String(src.foreignRelayBpsLimit).trim() : "",
        instanceRecvBpsLimit: /^\d+$/.test(String(src.instanceRecvBpsLimit || "").trim()) ? String(src.instanceRecvBpsLimit).trim() : "",
        enableEncryption: _boolOr(src.enableEncryption, DEFAULT_FLAGS.enableEncryption),
        enableIpv6: _boolOr(src.enableIpv6, DEFAULT_FLAGS.enableIpv6),
        latencyFirst: _boolOr(src.latencyFirst, DEFAULT_FLAGS.latencyFirst),
        enableExitNode: _boolOr(src.enableExitNode, DEFAULT_FLAGS.enableExitNode),
        noTun: _boolOr(src.noTun, _boolOr(legacyNoTun, DEFAULT_FLAGS.noTun)),
        useSmoltcp: _boolOr(src.useSmoltcp, DEFAULT_FLAGS.useSmoltcp),
        bindDevice: _boolOr(src.bindDevice, DEFAULT_FLAGS.bindDevice),
        proxyForwardBySystem: _boolOr(src.proxyForwardBySystem, DEFAULT_FLAGS.proxyForwardBySystem),
        enableP2p: _boolOr(src.enableP2p, DEFAULT_FLAGS.enableP2p),
        p2pOnly: _boolOr(src.p2pOnly, DEFAULT_FLAGS.p2pOnly),
        lazyP2p: _boolOr(src.lazyP2p, DEFAULT_FLAGS.lazyP2p),
        needP2p: _boolOr(src.needP2p, DEFAULT_FLAGS.needP2p),
        disableTcpHolePunching: _boolOr(src.disableTcpHolePunching, DEFAULT_FLAGS.disableTcpHolePunching),
        disableUdpHolePunching: _boolOr(src.disableUdpHolePunching, DEFAULT_FLAGS.disableUdpHolePunching),
        disableSymHolePunching: _boolOr(src.disableSymHolePunching, DEFAULT_FLAGS.disableSymHolePunching),
        enableUpnp: _boolOr(src.enableUpnp, DEFAULT_FLAGS.enableUpnp),
        enableKcpProxy: _boolOr(src.enableKcpProxy, DEFAULT_FLAGS.enableKcpProxy),
        disableKcpInput: _boolOr(src.disableKcpInput, DEFAULT_FLAGS.disableKcpInput),
        enableQuicProxy: _boolOr(src.enableQuicProxy, DEFAULT_FLAGS.enableQuicProxy),
        disableQuicInput: _boolOr(src.disableQuicInput, DEFAULT_FLAGS.disableQuicInput),
        relayAllPeerRpc: _boolOr(src.relayAllPeerRpc, DEFAULT_FLAGS.relayAllPeerRpc),
        disableRelayData: _boolOr(src.disableRelayData, DEFAULT_FLAGS.disableRelayData),
        disableRelayKcp: _boolOr(src.disableRelayKcp, DEFAULT_FLAGS.disableRelayKcp),
        disableRelayQuic: _boolOr(src.disableRelayQuic, DEFAULT_FLAGS.disableRelayQuic),
        enableRelayForeignKcp: _boolOr(src.enableRelayForeignKcp, DEFAULT_FLAGS.enableRelayForeignKcp),
        enableRelayForeignQuic: _boolOr(src.enableRelayForeignQuic, DEFAULT_FLAGS.enableRelayForeignQuic),
        acceptDns: _boolOr(src.acceptDns, DEFAULT_FLAGS.acceptDns),
        privateMode: _boolOr(src.privateMode, DEFAULT_FLAGS.privateMode),
        enableUdpBroadcastRelay: _boolOr(src.enableUdpBroadcastRelay, DEFAULT_FLAGS.enableUdpBroadcastRelay)
    };
}

function normalizePortForwards(arr) {
    if (!Array.isArray(arr))
        return [];
    var out = [];
    for (var i = 0; i < arr.length; i++) {
        var item = arr[i];
        if (!item || typeof item !== "object")
            continue;
        var bindAddr = String(item.bindAddr || item.bind_addr || "").trim();
        var dstAddr = String(item.dstAddr || item.dst_addr || "").trim();
        var proto = String(item.proto || "tcp").toLowerCase() === "udp" ? "udp" : "tcp";
        if (bindAddr && dstAddr) {
            out.push({ proto: proto, bindAddr: bindAddr, dstAddr: dstAddr });
        }
    }
    return out;
}

function createDefaultProfile() {
    var flags = normalizeFlags({}, false);
    return {
        id: "",
        name: "",
        configMode: "manual",
        configServer: "",
        machineId: "",
        instanceName: "",
        hostname: "",
        networkName: randomNetworkName(),
        networkSecret: randomSecret(16),
        dhcp: true,
        ipv4: "",
        ipv6: "",
        ipv6PublicProvider: false,
        ipv6PublicAuto: false,
        peers: [],
        listeners: [],
        mappedListeners: [],
        noListener: false,
        proxyCidrs: [],
        manualRoutes: [],
        exitNodes: [],
        socks5: "",
        vpnPortalEnabled: false,
        vpnClientCidr: "10.144.145.0/24",
        vpnWireguardListen: "0.0.0.0:11011",
        portForwards: [],
        flags: flags,
        noTun: flags.noTun,
        consoleLogLevel: "warn",
        fileLogLevel: "",
        fileLogDir: "",
        fileLogName: ""
    };
}

function normalizeProfile(raw) {
    if (!raw || typeof raw !== "object")
        return createDefaultProfile();
    var mode = String(raw.configMode || "manual");
    if (mode !== "manual" && mode !== "standalone" && mode !== "uri")
        mode = "manual";
    var flags = normalizeFlags(raw.flags, raw.noTun);
    return {
        id: String(raw.id || "").trim(),
        name: String(raw.name || "").trim(),
        configMode: mode,
        configServer: String(raw.configServer || "").trim(),
        machineId: String(raw.machineId || "").trim(),
        instanceName: String(raw.instanceName || "").trim(),
        hostname: String(raw.hostname || "").trim(),
        networkName: String(raw.networkName || "").trim(),
        networkSecret: String(raw.networkSecret || ""),
        dhcp: raw.dhcp !== false,
        ipv4: String(raw.ipv4 || "").trim(),
        ipv6: String(raw.ipv6 || "").trim(),
        ipv6PublicProvider: raw.ipv6PublicProvider === true,
        ipv6PublicAuto: raw.ipv6PublicAuto === true,
        peers: _cleanStringArray(raw.peers),
        listeners: _cleanStringArray(raw.listeners),
        mappedListeners: _cleanStringArray(raw.mappedListeners),
        noListener: raw.noListener === true,
        proxyCidrs: _cleanStringArray(raw.proxyCidrs),
        manualRoutes: _cleanStringArray(raw.manualRoutes),
        exitNodes: _cleanStringArray(raw.exitNodes),
        socks5: String(raw.socks5 || "").trim(),
        vpnPortalEnabled: raw.vpnPortalEnabled === true,
        vpnClientCidr: String(raw.vpnClientCidr || "10.144.145.0/24").trim() || "10.144.145.0/24",
        vpnWireguardListen: String(raw.vpnWireguardListen || "0.0.0.0:11011").trim() || "0.0.0.0:11011",
        portForwards: normalizePortForwards(raw.portForwards),
        flags: flags,
        noTun: flags.noTun,
        consoleLogLevel: String(raw.consoleLogLevel || "warn").trim(),
        fileLogLevel: String(raw.fileLogLevel || "").trim(),
        fileLogDir: String(raw.fileLogDir || "").trim(),
        fileLogName: String(raw.fileLogName || "").trim()
    };
}

function _q(str) {
    return JSON.stringify(String(str));
}

function _qArr(arr) {
    var items = [];
    for (var i = 0; i < arr.length; i++)
        items.push(_q(arr[i]));
    return "[" + items.join(", ") + "]";
}

function generateToml(rawProfile, maskSecret) {
    var p = normalizeProfile(rawProfile);
    var lines = [];

    if (p.configMode === "uri") {
        lines.push("# Web Config Server Mode (-w)");
        var shownUri = maskSecret && p.configServer ? p.configServer.replace(/:\/\/([^/]+)/, "://***") : p.configServer;
        lines.push("# easytier-core -w " + _q(shownUri || "udp://config-server:22020/user"));
        if (p.machineId)
            lines.push("# --machine-id " + _q(p.machineId));
        if (p.flags.noTun)
            lines.push("# --no-tun");
        return lines.join("\n");
    }

    if (p.instanceName && p.instanceName !== "default")
        lines.push("instance_name = " + _q(p.instanceName));
    if (p.hostname)
        lines.push("hostname = " + _q(p.hostname));
    if (p.dhcp) {
        lines.push("dhcp = true");
    } else if (p.ipv4) {
        lines.push("ipv4 = " + _q(p.ipv4));
    }
    if (p.ipv6)
        lines.push("ipv6 = " + _q(p.ipv6));
    if (p.ipv6PublicProvider)
        lines.push("ipv6_public_addr_provider = true");
    if (p.ipv6PublicAuto)
        lines.push("ipv6_public_addr_auto = true");

    if (p.noListener) {
        lines.push("listeners = []");
    } else if (p.listeners.length > 0) {
        lines.push("listeners = " + _qArr(p.listeners));
    }
    if (p.mappedListeners.length > 0)
        lines.push("mapped_listeners = " + _qArr(p.mappedListeners));
    if (p.exitNodes.length > 0)
        lines.push("exit_nodes = " + _qArr(p.exitNodes));
    if (p.manualRoutes.length > 0)
        lines.push("routes = " + _qArr(p.manualRoutes));

    var socksUrl = normalizeSocks5(p.socks5);
    if (socksUrl)
        lines.push("socks5_proxy = " + _q(socksUrl));

    if (lines.length > 0)
        lines.push("");

    lines.push("[network_identity]");
    lines.push("network_name = " + _q(p.networkName || "default"));
    if (p.networkSecret) {
        lines.push("network_secret = " + _q(maskSecret ? "••••••••" : p.networkSecret));
    }

    if (p.configMode === "manual" && p.peers.length > 0) {
        for (var i = 0; i < p.peers.length; i++) {
            lines.push("");
            lines.push("[[peer]]");
            lines.push("uri = " + _q(p.peers[i]));
        }
    }

    for (var j = 0; j < p.proxyCidrs.length; j++) {
        lines.push("");
        lines.push("[[proxy_network]]");
        lines.push("cidr = " + _q(p.proxyCidrs[j]));
    }

    if (p.vpnPortalEnabled && p.vpnClientCidr && p.vpnWireguardListen) {
        lines.push("");
        lines.push("[vpn_portal_config]");
        lines.push("client_cidr = " + _q(p.vpnClientCidr));
        lines.push("wireguard_listen = " + _q(p.vpnWireguardListen));
    }

    for (var k = 0; k < p.portForwards.length; k++) {
        var fw = p.portForwards[k];
        lines.push("");
        lines.push("[[port_forward]]");
        lines.push("bind_addr = " + _q(fw.bindAddr));
        lines.push("dst_addr = " + _q(fw.dstAddr));
        lines.push("proto = " + _q(fw.proto));
    }

    var f = p.flags;
    var flagLines = [];
    if (f.defaultProtocol !== DEFAULT_FLAGS.defaultProtocol)
        flagLines.push("default_protocol = " + _q(f.defaultProtocol));
    if (f.devName)
        flagLines.push("dev_name = " + _q(f.devName));
    if (f.enableEncryption !== DEFAULT_FLAGS.enableEncryption)
        flagLines.push("enable_encryption = " + String(f.enableEncryption));
    if (f.encryptionAlgorithm !== DEFAULT_FLAGS.encryptionAlgorithm)
        flagLines.push("encryption_algorithm = " + _q(f.encryptionAlgorithm));
    if (f.enableIpv6 !== DEFAULT_FLAGS.enableIpv6)
        flagLines.push("enable_ipv6 = " + String(f.enableIpv6));
    if (f.mtu !== DEFAULT_FLAGS.mtu)
        flagLines.push("mtu = " + String(f.mtu));
    if (f.latencyFirst)
        flagLines.push("latency_first = true");
    if (f.enableExitNode)
        flagLines.push("enable_exit_node = true");
    if (f.proxyForwardBySystem)
        flagLines.push("proxy_forward_by_system = true");
    if (f.noTun)
        flagLines.push("no_tun = true");
    if (f.useSmoltcp)
        flagLines.push("use_smoltcp = true");
    if (f.relayNetworkWhitelist !== DEFAULT_FLAGS.relayNetworkWhitelist)
        flagLines.push("relay_network_whitelist = " + _q(f.relayNetworkWhitelist));
    if (!f.enableP2p)
        flagLines.push("disable_p2p = true");
    if (f.p2pOnly)
        flagLines.push("p2p_only = true");
    if (f.lazyP2p)
        flagLines.push("lazy_p2p = true");
    if (f.needP2p)
        flagLines.push("need_p2p = true");
    if (f.relayAllPeerRpc)
        flagLines.push("relay_all_peer_rpc = true");
    if (f.disableTcpHolePunching)
        flagLines.push("disable_tcp_hole_punching = true");
    if (f.disableUdpHolePunching)
        flagLines.push("disable_udp_hole_punching = true");
    if (f.disableSymHolePunching)
        flagLines.push("disable_sym_hole_punching = true");
    if (!f.enableUpnp)
        flagLines.push("disable_upnp = true");
    if (f.multiThread !== DEFAULT_FLAGS.multiThread)
        flagLines.push("multi_thread = " + String(f.multiThread));
    if (f.multiThreadCount !== DEFAULT_FLAGS.multiThreadCount)
        flagLines.push("multi_thread_count = " + String(f.multiThreadCount));
    if (f.compression === "zstd")
        flagLines.push("data_compress_algo = 2");
    if (f.bindDevice !== DEFAULT_FLAGS.bindDevice)
        flagLines.push("bind_device = " + String(f.bindDevice));
    if (f.enableKcpProxy)
        flagLines.push("enable_kcp_proxy = true");
    if (f.disableKcpInput)
        flagLines.push("disable_kcp_input = true");
    if (f.enableQuicProxy)
        flagLines.push("enable_quic_proxy = true");
    if (f.disableQuicInput)
        flagLines.push("disable_quic_input = true");
    if (f.disableRelayData)
        flagLines.push("disable_relay_data = true");
    if (f.disableRelayKcp)
        flagLines.push("disable_relay_kcp = true");
    if (f.disableRelayQuic)
        flagLines.push("disable_relay_quic = true");
    if (f.enableRelayForeignKcp)
        flagLines.push("enable_relay_foreign_network_kcp = true");
    if (f.enableRelayForeignQuic)
        flagLines.push("enable_relay_foreign_network_quic = true");
    if (f.acceptDns)
        flagLines.push("accept_dns = true");
    if (f.tldDnsZone !== DEFAULT_FLAGS.tldDnsZone)
        flagLines.push("tld_dns_zone = " + _q(f.tldDnsZone));
    if (f.privateMode)
        flagLines.push("private_mode = true");
    if (f.enableUdpBroadcastRelay)
        flagLines.push("enable_udp_broadcast_relay = true");
    if (f.foreignRelayBpsLimit)
        flagLines.push("foreign_relay_bps_limit = " + f.foreignRelayBpsLimit);
    if (f.instanceRecvBpsLimit)
        flagLines.push("instance_recv_bps_limit = " + f.instanceRecvBpsLimit);

    if (flagLines.length > 0) {
        lines.push("");
        lines.push("[flags]");
        for (var m = 0; m < flagLines.length; m++)
            lines.push(flagLines[m]);
    }

    if (p.consoleLogLevel && p.consoleLogLevel !== "warn") {
        lines.push("");
        lines.push("[console_logger]");
        lines.push("level = " + _q(p.consoleLogLevel));
    }

    if (p.fileLogLevel) {
        lines.push("");
        lines.push("[file_logger]");
        lines.push("level = " + _q(p.fileLogLevel));
        if (p.fileLogDir)
            lines.push("dir = " + _q(p.fileLogDir));
        if (p.fileLogName)
            lines.push("file = " + _q(p.fileLogName));
    }

    return lines.join("\n");
}
