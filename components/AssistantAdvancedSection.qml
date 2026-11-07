import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../UiText.js" as UiText

// [Assistant Section 5: Advanced Options]
Column {
    id: root

    property string lang: "zh_CN"
    property var flags: ({})

    signal flagChanged(string key, var value)

    spacing: Theme.spacingS

    function t(key, arg1) {
        return UiText.tr(root.lang, key, arg1);
    }

    function flagBool(key, fallback) {
        if (root.flags && (root.flags[key] === true || root.flags[key] === false))
            return root.flags[key];
        return fallback;
    }

    readonly property var switchGroups: [
        {
            titleKey: "advGroupTransport",
            items: [
                { key: "enableEncryption", labelKey: "swEnableEncryption", defVal: true },
                { key: "enableIpv6", labelKey: "swEnableIpv6", defVal: true },
                { key: "latencyFirst", labelKey: "swLatencyFirst", defVal: false },
                { key: "enableExitNode", labelKey: "swEnableExitNode", defVal: false },
                { key: "noTun", labelKey: "swDisableTun", defVal: false },
                { key: "useSmoltcp", labelKey: "swUseSmoltcp", defVal: false },
                { key: "bindDevice", labelKey: "swBindDevice", defVal: true },
                { key: "proxyForwardBySystem", labelKey: "swProxyForwardSystem", defVal: false },
                { key: "multiThread", labelKey: "swMultiThread", defVal: true }
            ]
        },
        {
            titleKey: "advGroupP2p",
            items: [
                { key: "enableP2p", labelKey: "swEnableP2p", defVal: true },
                { key: "p2pOnly", labelKey: "swP2pOnly", defVal: false },
                { key: "lazyP2p", labelKey: "swLazyP2p", defVal: false },
                { key: "needP2p", labelKey: "swNeedP2p", defVal: false },
                { key: "disableTcpHolePunching", labelKey: "swDisableTcpHole", defVal: false },
                { key: "disableUdpHolePunching", labelKey: "swDisableUdpHole", defVal: false },
                { key: "disableSymHolePunching", labelKey: "swDisableSymHole", defVal: false },
                { key: "enableUpnp", labelKey: "swEnableUpnp", defVal: true }
            ]
        },
        {
            titleKey: "advGroupRelay",
            items: [
                { key: "enableKcpProxy", labelKey: "swKcpProxy", defVal: false },
                { key: "disableKcpInput", labelKey: "swDisableKcpInput", defVal: false },
                { key: "enableQuicProxy", labelKey: "swQuicProxy", defVal: false },
                { key: "disableQuicInput", labelKey: "swDisableQuicInput", defVal: false },
                { key: "relayAllPeerRpc", labelKey: "swRelayAllRpc", defVal: false },
                { key: "disableRelayData", labelKey: "swDisableRelayData", defVal: false },
                { key: "disableRelayKcp", labelKey: "swDisableRelayKcp", defVal: false },
                { key: "disableRelayQuic", labelKey: "swDisableRelayQuic", defVal: false },
                { key: "enableRelayForeignKcp", labelKey: "swRelayForeignKcp", defVal: false },
                { key: "enableRelayForeignQuic", labelKey: "swRelayForeignQuic", defVal: false }
            ]
        },
        {
            titleKey: "advGroupDnsMisc",
            items: [
                { key: "acceptDns", labelKey: "swMagicDns", defVal: false },
                { key: "privateMode", labelKey: "swPrivateMode", defVal: false },
                { key: "enableUdpBroadcastRelay", labelKey: "swUdpBroadcast", defVal: false }
            ]
        }
    ]

    StyledText {
        text: root.t("advParamsHeader")
        color: Theme.primary
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
    }

    OptionChipsField {
        width: parent.width
        label: root.t("defaultProtocol")
        currentValue: (root.flags && root.flags.defaultProtocol) ? root.flags.defaultProtocol : "tcp"
        options: [
            { value: "tcp", label: "TCP" },
            { value: "udp", label: "UDP" },
            { value: "ws", label: "WS" },
            { value: "wss", label: "WSS" },
            { value: "quic", label: "QUIC" },
            { value: "wg", label: "WG" }
        ]
        onValueSelected: val => root.flagChanged("defaultProtocol", val)
    }

    OptionChipsField {
        width: parent.width
        label: root.t("encryptionAlgorithm")
        currentValue: (root.flags && root.flags.encryptionAlgorithm) ? root.flags.encryptionAlgorithm : "aes-gcm"
        options: [
            { value: "aes-gcm", label: "AES-GCM" },
            { value: "aes-256-gcm", label: "AES-256-GCM" },
            { value: "chacha20", label: "ChaCha20" },
            { value: "xor", label: "XOR" }
        ]
        onValueSelected: val => root.flagChanged("encryptionAlgorithm", val)
    }

    OptionChipsField {
        width: parent.width
        label: root.t("compressionAlgo")
        currentValue: (root.flags && root.flags.compression) ? root.flags.compression : "none"
        options: [
            { value: "none", label: root.t("compNone") },
            { value: "zstd", label: "Zstd" }
        ]
        onValueSelected: val => root.flagChanged("compression", val)
    }

    // MTU + Thread Count
    Row {
        width: parent.width
        spacing: Theme.spacingS

        Column {
            width: Math.floor((parent.width - Theme.spacingS) / 2)
            spacing: 4

            StyledText {
                text: root.t("mtuLabel")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            SyncedTextField {
                width: parent.width
                value: String((root.flags && root.flags.mtu) ? root.flags.mtu : 1380)
                placeholderText: "1380"
                onValueEdited: newText => {
                    const n = parseInt(newText, 10);
                    if (!isNaN(n) && n >= 576 && n <= 65535)
                        root.flagChanged("mtu", n);
                }
            }
        }

        Column {
            width: Math.floor((parent.width - Theme.spacingS) / 2)
            spacing: 4

            StyledText {
                text: root.t("threadCountLabel")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            SyncedTextField {
                width: parent.width
                value: String((root.flags && root.flags.multiThreadCount) ? root.flags.multiThreadCount : 2)
                placeholderText: "2"
                onValueEdited: newText => {
                    const n = parseInt(newText, 10);
                    if (!isNaN(n) && n >= 2 && n <= 128)
                        root.flagChanged("multiThreadCount", n);
                }
            }
        }
    }

    // TUN Device Name + Magic DNS Zone
    Row {
        width: parent.width
        spacing: Theme.spacingS

        Column {
            width: Math.floor((parent.width - Theme.spacingS) / 2)
            spacing: 4

            StyledText {
                text: root.t("tunDeviceName")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            SyncedTextField {
                width: parent.width
                value: (root.flags && root.flags.devName) ? root.flags.devName : ""
                placeholderText: root.t("leaveEmptyDefault")
                onValueEdited: newText => root.flagChanged("devName", newText.trim())
            }
        }

        Column {
            width: Math.floor((parent.width - Theme.spacingS) / 2)
            spacing: 4

            StyledText {
                text: root.t("tldDnsZone")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            SyncedTextField {
                width: parent.width
                value: (root.flags && root.flags.tldDnsZone !== undefined) ? root.flags.tldDnsZone : "et.net."
                placeholderText: "et.net."
                onValueEdited: newText => root.flagChanged("tldDnsZone", newText.trim() || "et.net.")
            }
        }
    }

    // Relay Network Whitelist
    Column {
        width: parent.width
        spacing: 4

        StyledText {
            text: root.t("relayWhitelist")
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
        }

        StyledText {
            width: parent.width
            text: root.t("relayWhitelistDesc")
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall - 1
            wrapMode: Text.WordWrap
        }

        SyncedTextField {
            width: parent.width
            value: (root.flags && root.flags.relayNetworkWhitelist !== undefined) ? root.flags.relayNetworkWhitelist : "*"
            placeholderText: "*"
            onValueEdited: newText => root.flagChanged("relayNetworkWhitelist", newText.trim())
        }
    }

    // Bandwidth Limits
    Row {
        width: parent.width
        spacing: Theme.spacingS

        Column {
            width: Math.floor((parent.width - Theme.spacingS) / 2)
            spacing: 4

            StyledText {
                width: parent.width
                text: root.t("foreignBpsLimit")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            SyncedTextField {
                width: parent.width
                value: (root.flags && root.flags.foreignRelayBpsLimit) ? root.flags.foreignRelayBpsLimit : ""
                placeholderText: root.t("unlimitedPlaceholder")
                onValueEdited: newText => root.flagChanged("foreignRelayBpsLimit", newText.replace(/\D+/g, ""))
            }
        }

        Column {
            width: Math.floor((parent.width - Theme.spacingS) / 2)
            spacing: 4

            StyledText {
                width: parent.width
                text: root.t("instanceBpsLimit")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            SyncedTextField {
                width: parent.width
                value: (root.flags && root.flags.instanceRecvBpsLimit) ? root.flags.instanceRecvBpsLimit : ""
                placeholderText: root.t("unlimitedPlaceholder")
                onValueEdited: newText => root.flagChanged("instanceRecvBpsLimit", newText.replace(/\D+/g, ""))
            }
        }
    }

    // Grouped Boolean Switches
    Repeater {
        model: root.switchGroups

        delegate: Column {
            required property var modelData
            width: root.width
            spacing: 6

            Item {
                width: 1
                height: 2
            }

            StyledText {
                text: root.t(modelData.titleKey)
                color: Theme.primary
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            Repeater {
                model: modelData.items

                delegate: CompactSwitchRow {
                    required property var modelData
                    width: root.width
                    label: root.t(modelData.labelKey)
                    checked: root.flagBool(modelData.key, modelData.defVal)
                    onToggled: isChecked => root.flagChanged(modelData.key, isChecked)
                }
            }
        }
    }
}
