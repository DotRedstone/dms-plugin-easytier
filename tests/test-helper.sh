#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT_DIR/easytier-dms"

TMP_DIR="$(mktemp -d)"
export EASYTIER_DMS_CONFIG_DIR="$TMP_DIR/config"
export EASYTIER_DMS_RUNTIME_DIR="$TMP_DIR/runtime"
trap 'rm -rf "$TMP_DIR"' EXIT

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1" >&2; exit 1; }

# [Test 1: Argument Validation]
if "$HELPER" status "-bad-flag" >/dev/null 2>&1; then
    fail "Expected leading-dash RPC portal to fail"
fi
if "$HELPER" status "127.0.0.1:15888" "bad;unit" >/dev/null 2>&1; then
    fail "Expected invalid unit name to fail"
fi
if "$HELPER" status "127.0.0.1:15888" "easytier.service" "invalid_scope" >/dev/null 2>&1; then
    fail "Expected invalid scope to fail"
fi
if "$HELPER" connector-add "not-a-url" >/dev/null 2>&1; then
    fail "Expected malformed connector URL to fail"
fi
pass "Argument validation rejects malformed inputs"

# [Test 2: Missing CLI State]
OUT_MISSING="$(EASYTIER_CLI_BIN="$TMP_DIR/nonexistent-cli" "$HELPER" status "127.0.0.1:15888" "easytier" "user")"
[[ "$(jq -r '.ok' <<<"$OUT_MISSING")" == "true" ]] || fail "Missing CLI should return ok=true"
[[ "$(jq -r '.cliAvailable' <<<"$OUT_MISSING")" == "false" ]] || fail "cliAvailable should be false"
[[ "$(jq -r '.serviceUnit' <<<"$OUT_MISSING")" == "easytier.service" ]] || fail "Short unit name should normalize to .service"
pass "Missing CLI state handled cleanly"

# [Test 3: Profile CRUD via stdin, 0600 Permissions & Status Sanitization]
SAVE_OUT="$(printf '%s' '{
  "name": "Lab Mesh",
  "configMode": "manual",
  "networkName": "example-net",
  "networkSecret": "PROFILE_SECRET_NEVER_IN_STATUS",
  "dhcp": false,
  "ipv4": "10.144.144.9/24",
  "hostname": "lab-node",
  "peers": ["tcp://198.51.100.10:11010"],
  "proxyCidrs": ["192.168.50.0/24"],
  "noTun": true
}' | "$HELPER" profile-save -)"
PROF_ID="$(jq -r '.id' <<<"$SAVE_OUT")"
[[ -n "$PROF_ID" && "$PROF_ID" != "null" ]] || fail "Expected generated profile ID"
[[ "$(stat -c '%a' "$EASYTIER_DMS_CONFIG_DIR/profiles.json")" == "600" ]] || fail "profiles.json must be mode 0600"

STATUS_WITH_PROF="$(EASYTIER_CLI_BIN="$TMP_DIR/nonexistent-cli" "$HELPER" status "127.0.0.1:15888" "easytier.service" "user")"
if grep -q "PROFILE_SECRET_NEVER_IN_STATUS" <<<"$STATUS_WITH_PROF"; then
    fail "Profile secret leaked into status JSON!"
fi
[[ "$(jq -r '.activeProfileId' <<<"$STATUS_WITH_PROF")" == "$PROF_ID" ]] || fail "Expected activeProfileId in status"
[[ "$(jq -r '.profileSummaries[0].name' <<<"$STATUS_WITH_PROF")" == "Lab Mesh" ]] || fail "Expected profile summary name"
pass "Profile CRUD via stdin, 0600 permissions, and status sanitization verified"

# [Test 4: Mocked Topology, Connectors & Secret Sanitization]
MOCK_CLI="$TMP_DIR/mock-easytier-cli"
MOCK_SYSCTL="$TMP_DIR/mock-systemctl"
STATE_FILE="$TMP_DIR/svc_state"
printf 'active\n' >"$STATE_FILE"

cat >"$MOCK_SYSCTL" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ "\${1:-}" == "--user" ]]; then shift; fi
case "\${1:-}" in
    is-active)
        if [[ "\${2:-}" == "dms-easytier-managed.service" ]]; then
            printf 'inactive\n'
        else
            cat "$STATE_FILE"
        fi
        ;;
    start) printf 'active\n' >"$STATE_FILE" ;;
    stop) printf 'inactive\n' >"$STATE_FILE" ;;
    restart) printf 'active\n' >"$STATE_FILE" ;;
    *) exit 0 ;;
esac
EOF
chmod +x "$MOCK_SYSCTL"

cat >"$MOCK_CLI" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sub="${5:-}"
case "$sub" in
    node)
        cat <<'JSON'
{
  "peer_id": 100001,
  "ipv4_addr": "10.144.144.1/24",
  "proxy_cidrs": ["172.16.0.0/24"],
  "hostname": "host-local",
  "inst_id": "00000000-0000-0000-0000-000000000001",
  "listeners": ["ring://00000000-0000-0000-0000-000000000001", "tcp://0.0.0.0:11010"],
  "config": "hostname = \"host-local\"\n[network_identity]\nnetwork_name = \"example-net\"\nnetwork_secret = \"SUPER_SENSITIVE_TEST_SECRET_DO_NOT_LEAK\"\n",
  "version": "2.6.4"
}
JSON
        ;;
    peer)
        cat <<'JSON'
[
  {
    "cidr": "10.144.144.1/24",
    "ipv4": "10.144.144.1",
    "hostname": "host-local",
    "cost": "Local",
    "lat_ms": "-",
    "loss_rate": "-",
    "rx_bytes": "-",
    "tx_bytes": "-",
    "tunnel_proto": "-",
    "nat_type": "FullCone",
    "id": "100001",
    "version": "2.6.4"
  },
  {
    "cidr": "10.144.144.3/24",
    "ipv4": "10.144.144.3",
    "hostname": "peer-relay",
    "cost": "relay(1)",
    "lat_ms": "48.5",
    "loss_rate": "0.0%",
    "rx_bytes": "4.20 MB",
    "tx_bytes": "1.10 MB",
    "tunnel_proto": "tcp",
    "nat_type": "Symmetric",
    "id": "100003",
    "version": "2.6.4"
  },
  {
    "cidr": "10.144.144.2/24",
    "ipv4": "10.144.144.2",
    "hostname": "peer-alpha",
    "cost": "p2p",
    "lat_ms": "6.2",
    "loss_rate": "0.0%",
    "rx_bytes": "128.5 MB",
    "tx_bytes": "64.0 MB",
    "tunnel_proto": "udp",
    "nat_type": "PortRestricted",
    "id": "100002",
    "version": "2.6.4"
  }
]
JSON
        ;;
    route)
        cat <<'JSON'
[
  {
    "ipv4": "10.144.144.1/24",
    "hostname": "host-local",
    "proxy_cidrs": "",
    "next_hop_ipv4": "-",
    "next_hop_hostname": "Local",
    "path_len": 0,
    "path_latency": 0
  },
  {
    "ipv4": "10.144.144.2/24",
    "hostname": "peer-alpha",
    "proxy_cidrs": "192.168.50.0/24, 192.168.60.0/24",
    "next_hop_ipv4": "10.144.144.2",
    "next_hop_hostname": "peer-alpha",
    "path_len": 1,
    "path_latency": 6
  }
]
JSON
        ;;
    stats)
        cat <<'JSON'
[
  {
    "name": "traffic_bytes_rx",
    "value": 2097152,
    "labels": { "network_name": "example-net" }
  },
  {
    "name": "traffic_bytes_tx",
    "value": 1048576,
    "labels": { "network_name": "example-net" }
  }
]
JSON
        ;;
    connector)
        cat <<'JSON'
[
  {
    "url": { "url": "tcp://198.51.100.10:11010" },
    "status": 0
  },
  {
    "url": { "url": "udp://198.51.100.11:11010" },
    "status": 2
  }
]
JSON
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod +x "$MOCK_CLI"

OUT_MOCK="$(EASYTIER_CLI_BIN="$MOCK_CLI" SYSTEMCTL_BIN="$MOCK_SYSCTL" "$HELPER" status "127.0.0.1:15888" "easytier.service" "user")"

if grep -q "SUPER_SENSITIVE_TEST_SECRET_DO_NOT_LEAK\|network_secret" <<<"$OUT_MOCK"; then
    fail "Secret leaked in status output!"
fi
[[ "$(jq -r '.rpcConnected' <<<"$OUT_MOCK")" == "true" ]] || fail "Expected rpcConnected=true"
[[ "$(jq -r '.counts.total' <<<"$OUT_MOCK")" == "2" ]] || fail "Expected 2 remote peers"
[[ "$(jq -r '.connectors | length' <<<"$OUT_MOCK")" == "2" ]] || fail "Expected 2 normalized connectors"
[[ "$(jq -r '.connectors[0].state' <<<"$OUT_MOCK")" == "connected" ]] || fail "Expected connector 0 connected"
[[ "$(jq -r '.connectors[1].state' <<<"$OUT_MOCK")" == "connecting" ]] || fail "Expected connector 1 connecting"
pass "Mocked topology, connectors, and secret stripping verified"

# [Test 5: Live Managed Profile + Dynamic Connector Add/Remove]
if command -v easytier-core >/dev/null 2>&1 && command -v easytier-cli >/dev/null 2>&1 && command -v systemd-run >/dev/null 2>&1; then
    LIVE_SAVE="$("$HELPER" profile-save '{
      "name": "Sandbox Profile",
      "configMode": "manual",
      "networkName": "sandbox-net",
      "networkSecret": "synthetic-managed-secret",
      "dhcp": false,
      "ipv4": "10.144.144.99/24",
      "hostname": "sandbox-managed",
      "peers": [],
      "proxyCidrs": [],
      "noTun": true
    }')"
    LIVE_ID="$(jq -r '.id' <<<"$LIVE_SAVE")"

    trap '"$HELPER" managed-stop "" "127.0.0.1:29895" >/dev/null 2>&1 || true; rm -rf "$TMP_DIR"' EXIT

    OUT_MGD_START="$("$HELPER" managed-start "$LIVE_ID" "127.0.0.1:29895" "easytier.service" "user")"
    [[ "$(jq -r '.rpcConnected' <<<"$OUT_MGD_START")" == "true" ]] || fail "Managed start should connect RPC"
    [[ "$(jq -r '.managedActive' <<<"$OUT_MGD_START")" == "true" ]] || fail "managedActive should be true"
    [[ "$(jq -r '.self.ipv4' <<<"$OUT_MGD_START")" == "10.144.144.99" ]] || fail "Managed IPv4 mismatch"

    OUT_CONN_ADD="$("$HELPER" connector-add "tcp://127.0.0.1:29997" "127.0.0.1:29895" "easytier.service" "user")"
    [[ "$(jq -r '[.connectors[].url] | index("tcp://127.0.0.1:29997") != null' <<<"$OUT_CONN_ADD")" == "true" ]] || fail "Dynamic connector-add not reflected"

    OUT_CONN_RM="$("$HELPER" connector-remove "tcp://127.0.0.1:29997" "127.0.0.1:29895" "easytier.service" "user")"
    [[ "$(jq -r '[.connectors[].url] | index("tcp://127.0.0.1:29997") == null' <<<"$OUT_CONN_RM")" == "true" ]] || fail "Dynamic connector-remove not reflected"

    OUT_MGD_STOP="$("$HELPER" managed-stop "" "127.0.0.1:29895" "easytier.service" "user")"
    [[ "$(jq -r '.managedActive' <<<"$OUT_MGD_STOP")" == "false" ]] || fail "managedActive should be false after stop"

    "$HELPER" profile-delete "$LIVE_ID" >/dev/null
    pass "Live managed profile start/stop and dynamic connector add/remove verified"

    # [Test 6: Assistant v2 Full Advanced TOML Profile & Live Startup]
    ADV_SAVE="$("$HELPER" profile-save '{
      "name": "Assistant Expert Profile",
      "configMode": "standalone",
      "instanceName": "expert-inst",
      "hostname": "expert-node",
      "networkName": "expert-net",
      "networkSecret": "EXPERT_SECRET_DO_NOT_LEAK",
      "dhcp": false,
      "ipv4": "10.144.144.88/24",
      "ipv6": "fd00:144::88/64",
      "listeners": ["tcp://127.0.0.1:29897"],
      "mappedListeners": ["tcp://198.51.100.88:29897"],
      "proxyCidrs": ["192.168.88.0/24"],
      "manualRoutes": ["10.200.0.0/16"],
      "exitNodes": ["10.144.144.1"],
      "socks5": "127.0.0.1:29898",
      "vpnPortalEnabled": true,
      "vpnClientCidr": "10.144.145.0/24",
      "vpnWireguardListen": "127.0.0.1:29900",
      "portForwards": [
        { "proto": "tcp", "bindAddr": "127.0.0.1:29899", "dstAddr": "10.144.144.2:8080" }
      ],
      "flags": {
        "defaultProtocol": "udp",
        "encryptionAlgorithm": "aes-256-gcm",
        "compression": "zstd",
        "mtu": 1360,
        "multiThread": true,
        "multiThreadCount": 2,
        "noTun": true,
        "useSmoltcp": true,
        "latencyFirst": true,
        "enableKcpProxy": true,
        "privateMode": true,
        "foreignRelayBpsLimit": "1048576"
      },
      "consoleLogLevel": "info"
    }')"
    ADV_ID="$(jq -r '.id' <<<"$ADV_SAVE")"
    [[ -n "$ADV_ID" && "$ADV_ID" != "null" ]] || fail "Expected generated ID for advanced profile"

    OUT_ADV_START="$("$HELPER" managed-start "$ADV_ID" "127.0.0.1:29895" "easytier.service" "user")"
    [[ "$(jq -r '.rpcConnected' <<<"$OUT_ADV_START")" == "true" ]] || fail "Advanced TOML profile should start and connect RPC"
    [[ "$(jq -r '.self.hostname' <<<"$OUT_ADV_START")" == "expert-node" ]] || fail "Expected expert-node hostname"
    [[ "$(stat -c '%a' "$EASYTIER_DMS_RUNTIME_DIR/managed.toml")" == "600" ]] || fail "managed.toml must be mode 0600"
    grep -q 'data_compress_algo = 2' "$EASYTIER_DMS_RUNTIME_DIR/managed.toml" || fail "Expected integer enum data_compress_algo = 2"
    grep -q 'socks5_proxy = "socks5://127.0.0.1:29898"' "$EASYTIER_DMS_RUNTIME_DIR/managed.toml" || fail "Expected normalized socks5_proxy"
    if grep -q "EXPERT_SECRET_DO_NOT_LEAK" <<<"$OUT_ADV_START"; then
        fail "Expert profile secret leaked into managed-start JSON!"
    fi

    "$HELPER" managed-stop "" "127.0.0.1:29895" "easytier.service" "user" >/dev/null
    "$HELPER" profile-delete "$ADV_ID" >/dev/null
    pass "Assistant v2 advanced TOML rendering, 0600 permissions, and live startup verified"
fi

printf 'All tests passed.\n'
