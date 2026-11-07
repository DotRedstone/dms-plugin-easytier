#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT_DIR/easytier-dms"

TMP_DIR="$(mktemp -d)"
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
pass "Argument validation rejects malformed inputs"

# [Test 2: Missing CLI State]
OUT_MISSING="$(EASYTIER_CLI_BIN="$TMP_DIR/nonexistent-cli" "$HELPER" status "127.0.0.1:15888" "easytier" "user")"
[[ "$(jq -r '.ok' <<<"$OUT_MISSING")" == "true" ]] || fail "Missing CLI should return ok=true"
[[ "$(jq -r '.cliAvailable' <<<"$OUT_MISSING")" == "false" ]] || fail "cliAvailable should be false"
[[ "$(jq -r '.serviceUnit' <<<"$OUT_MISSING")" == "easytier.service" ]] || fail "Short unit name should normalize to .service"
pass "Missing CLI state handled cleanly"

# [Test 3: Mocked Topology & Secret Sanitization]
MOCK_CLI="$TMP_DIR/mock-easytier-cli"
MOCK_SYSCTL="$TMP_DIR/mock-systemctl"
STATE_FILE="$TMP_DIR/svc_state"
printf 'active\n' >"$STATE_FILE"

cat >"$MOCK_SYSCTL" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ "\${1:-}" == "--user" ]]; then shift; fi
case "\${1:-}" in
    is-active) cat "$STATE_FILE" ;;
    start) printf 'active\n' >"$STATE_FILE" ;;
    stop) printf 'inactive\n' >"$STATE_FILE" ;;
    restart) printf 'active\n' >"$STATE_FILE" ;;
    *) exit 1 ;;
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
  },
  {
    "name": "traffic_bytes_forwarded",
    "value": 4096,
    "labels": { "network_name": "example-net" }
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
[[ "$(jq -r '.self.ipv4' <<<"$OUT_MOCK")" == "10.144.144.1" ]] || fail "Expected self ipv4 10.144.144.1"
[[ "$(jq -r '.self.networkName' <<<"$OUT_MOCK")" == "example-net" ]] || fail "Expected networkName example-net"
[[ "$(jq -r '.self.natType' <<<"$OUT_MOCK")" == "FullCone" ]] || fail "Expected Local peer NAT FullCone"
[[ "$(jq -r '.counts.total' <<<"$OUT_MOCK")" == "2" ]] || fail "Expected 2 remote peers (Local excluded)"
[[ "$(jq -r '.counts.p2p' <<<"$OUT_MOCK")" == "1" ]] || fail "Expected 1 p2p peer"
[[ "$(jq -r '.counts.relay' <<<"$OUT_MOCK")" == "1" ]] || fail "Expected 1 relay peer"
[[ "$(jq -r '.peers[0].hostname' <<<"$OUT_MOCK")" == "peer-alpha" ]] || fail "Expected p2p peer sorted first"
[[ "$(jq -r '.routes | length' <<<"$OUT_MOCK")" == "1" ]] || fail "Expected 1 subnet proxy route"
[[ "$(jq -r '.routes[0].proxyCidrs | length' <<<"$OUT_MOCK")" == "2" ]] || fail "Expected 2 parsed proxy CIDRs"
[[ "$(jq -r '.traffic.rxBytes' <<<"$OUT_MOCK")" == "2097152" ]] || fail "Expected rxBytes=2097152"
pass "Mocked topology normalization and secret stripping verified"

# [Test 4: Service Toggle]
OUT_TOGGLE="$(EASYTIER_CLI_BIN="$TMP_DIR/nonexistent-cli" SYSTEMCTL_BIN="$MOCK_SYSCTL" "$HELPER" toggle "easytier.service" "user" "127.0.0.1:15888")"
[[ "$(jq -r '.action' <<<"$OUT_TOGGLE")" == "stop" ]] || fail "Active service should toggle to stop"
[[ "$(cat "$STATE_FILE")" == "inactive" ]] || fail "Service state file should now be inactive"
pass "User-scope service toggle verified"

# [Test 5: Live Unprivileged Sandbox (Optional if easytier-core is installed)]
if command -v easytier-core >/dev/null 2>&1 && command -v easytier-cli >/dev/null 2>&1; then
    easytier-core --no-tun --hostname sandbox-a -i 10.144.144.1 --network-name example-net --network-secret synthetic-secret -l tcp://127.0.0.1:29910 -r 127.0.0.1:29888 >/dev/null 2>&1 &
    ET_PID=$!
    trap 'kill "$ET_PID" 2>/dev/null || true; rm -rf "$TMP_DIR"' EXIT
    sleep 1.5
    OUT_LIVE="$(SYSTEMCTL_BIN="$MOCK_SYSCTL" "$HELPER" status "127.0.0.1:29888" "easytier.service" "user")"
    kill "$ET_PID" 2>/dev/null || true
    wait "$ET_PID" 2>/dev/null || true
    if grep -q "synthetic-secret" <<<"$OUT_LIVE"; then
        fail "Live sandbox leaked network_secret!"
    fi
    [[ "$(jq -r '.rpcConnected' <<<"$OUT_LIVE")" == "true" ]] || fail "Live sandbox should report rpcConnected=true"
    [[ "$(jq -r '.self.ipv4' <<<"$OUT_LIVE")" == "10.144.144.1" ]] || fail "Live sandbox self ipv4 mismatch"
    pass "Live easytier-core --no-tun loopback RPC verified"
fi

printf 'All tests passed.\n'
