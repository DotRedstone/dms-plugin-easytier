import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../UiText.js" as UiText
import "../AssistantConfig.js" as AssistantConfig

// [EasyTier Official Assistant-Style Profile Editor]
Rectangle {
    id: root

    property string lang: "zh_CN"
    property bool busy: false
    property var draft: AssistantConfig.createDefaultProfile()
    property int currentSection: 0
    property bool showTomlSecret: false

    signal cancelled()
    signal saveRequested(var profileObj, bool connectImmediately)
    signal copyTomlRequested(string tomlText)

    height: editorCol.implicitHeight + Theme.spacingM * 2
    radius: Theme.cornerRadiusL
    color: Theme.ccPillInactiveBg

    function t(key, arg1) {
        return UiText.tr(root.lang, key, arg1);
    }

    function loadNew() {
        root.draft = AssistantConfig.createDefaultProfile();
        root.currentSection = 0;
        root.showTomlSecret = false;
    }

    function loadProfile(prof) {
        root.draft = AssistantConfig.normalizeProfile(prof);
        root.currentSection = 0;
        root.showTomlSecret = false;
    }

    function updateDraft(patch) {
        const next = Object.assign({}, root.draft, patch);
        root.draft = next;
    }

    function updateFlag(key, value) {
        const nextFlags = Object.assign({}, root.draft.flags || {});
        nextFlags[key] = value;
        const patch = { flags: nextFlags };
        if (key === "noTun")
            patch.noTun = value === true;
        updateDraft(patch);
    }

    function flushAllPending() {
        peersEditor.commitPending();
        listenersEditor.commitPending();
        mappedListenersEditor.commitPending();
        proxyEditor.commitPending();
        routesEditor.commitPending();
        exitNodesEditor.commitPending();
    }

    readonly property bool isUriMode: root.draft.configMode === "uri"

    readonly property bool canSave: {
        const hasName = String(root.draft.name || "").trim().length > 0;
        if (!hasName)
            return false;
        if (root.isUriMode)
            return String(root.draft.configServer || "").trim().length > 0;
        if (String(root.draft.networkName || "").trim().length === 0)
            return false;
        if (!root.draft.dhcp && !root.draft.flags.noTun && String(root.draft.ipv4 || "").trim().length === 0)
            return false;
        return true;
    }

    readonly property var sectionTabs: [
        { icon: "badge", labelKey: "secIdentityIp", allowInUri: true },
        { icon: "cable", labelKey: "secConnections", allowInUri: false },
        { icon: "alt_route", labelKey: "secProxyRoutes", allowInUri: false },
        { icon: "swap_horiz", labelKey: "secVpnForward", allowInUri: false },
        { icon: "tune", labelKey: "secAdvanced", allowInUri: false },
        { icon: "code", labelKey: "secLogToml", allowInUri: true }
    ]

    Column {
        id: editorCol
        x: Theme.spacingM
        y: Theme.spacingM
        width: parent.width - Theme.spacingM * 2
        spacing: Theme.spacingS

        // [Editor Header]
        Item {
            width: parent.width
            height: 30

            StyledText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: String(root.draft.id || "").length > 0 ? root.t("editProfile") : root.t("newProfile")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                DActionButton {
                    buttonSize: 28
                    iconSize: 16
                    iconName: "restart_alt"
                    iconColor: Theme.surfaceVariantText
                    backgroundColor: "transparent"
                    tooltipText: root.t("resetDefaults")
                    onClicked: {
                        const keepId = root.draft.id || "";
                        const keepName = root.draft.name || "";
                        const fresh = AssistantConfig.createDefaultProfile();
                        fresh.id = keepId;
                        fresh.name = keepName;
                        root.draft = fresh;
                    }
                }

                DActionButton {
                    buttonSize: 28
                    iconSize: 16
                    iconName: "close"
                    iconColor: Theme.surfaceVariantText
                    backgroundColor: "transparent"
                    tooltipText: root.t("cancel")
                    onClicked: root.cancelled()
                }
            }
        }

        // [Profile Name]
        Column {
            width: parent.width
            spacing: 4

            StyledText {
                text: root.t("profileName")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            SyncedTextField {
                width: parent.width
                value: root.draft.name || ""
                placeholderText: root.t("profileNamePlaceholder")
                showClearButton: true
                onValueEdited: newText => root.updateDraft({ name: newText })
            }
        }

        // [3x2 Assistant Section Navigation Grid]
        Grid {
            width: parent.width
            columns: 3
            spacing: 6

            Repeater {
                model: root.sectionTabs

                delegate: StyledButton {
                    id: secTabBtn
                    required property var modelData
                    required property int index
                    readonly property bool active: root.currentSection === index
                    readonly property bool tabAllowed: modelData.allowInUri || !root.isUriMode

                    width: Math.floor((editorCol.width - 12) / 3)
                    height: 32
                    radius: Theme.cornerRadiusM
                    color: active ? Theme.primary : Theme.ccIconBoxInactiveBg
                    opacity: tabAllowed ? 1.0 : 0.4
                    enabled: tabAllowed
                    onClicked: {
                        root.flushAllPending();
                        root.currentSection = index;
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        DIcon {
                            name: modelData.icon
                            size: 14
                            color: secTabBtn.active ? Theme.onPrimary : Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.t(modelData.labelKey)
                            color: secTabBtn.active ? Theme.onPrimary : Theme.surfaceText
                            font.pixelSize: Theme.fontSizeXSmall
                            font.weight: secTabBtn.active ? Font.Medium : Font.Normal
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
            opacity: 0.35
        }

        // =========================================================
        // [Section 0: Network Identity & IP Settings]
        // =========================================================
        Column {
            visible: root.currentSection === 0
            width: parent.width
            spacing: Theme.spacingS

            OptionChipsField {
                width: parent.width
                label: root.t("configSourceLabel")
                currentValue: root.isUriMode ? "uri" : "assistant"
                options: [
                    { value: "assistant", label: root.t("sourceAssistant") },
                    { value: "uri", label: root.t("sourceConfigServer") }
                ]
                onValueSelected: val => {
                    if (val === "uri")
                        root.updateDraft({ configMode: "uri" });
                    else if (root.draft.configMode === "uri")
                        root.updateDraft({ configMode: "manual" });
                }
            }

            // Web Config Server (-w) Fields
            Column {
                visible: root.isUriMode
                width: parent.width
                spacing: Theme.spacingS

                Column {
                    width: parent.width
                    spacing: 4

                    StyledText {
                        text: root.t("configServerUri")
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    SyncedTextField {
                        width: parent.width
                        value: root.draft.configServer || ""
                        placeholderText: root.t("configServerPlaceholder")
                        showClearButton: true
                        onValueEdited: newText => root.updateDraft({ configServer: newText.trim() })
                    }
                }

                Column {
                    width: parent.width
                    spacing: 4

                    StyledText {
                        text: root.t("machineIdLabel")
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    SyncedTextField {
                        width: parent.width
                        value: root.draft.machineId || ""
                        placeholderText: root.t("machineIdPlaceholder")
                        showClearButton: true
                        onValueEdited: newText => root.updateDraft({ machineId: newText.trim() })
                    }
                }

                CompactSwitchRow {
                    width: parent.width
                    label: root.t("swDisableTun")
                    checked: root.draft.flags ? root.draft.flags.noTun === true : false
                    onToggled: isChecked => root.updateFlag("noTun", isChecked)
                }
            }

            // Local Assistant Identity & IP Fields
            Column {
                visible: !root.isUriMode
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: root.t("networkIdentityHeader")
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                // Network Name + Shuffle
                Column {
                    width: parent.width
                    spacing: 4

                    StyledText {
                        text: root.t("networkNameLabel")
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        SyncedTextField {
                            width: parent.width - randNetBtn.width - Theme.spacingXS
                            value: root.draft.networkName || ""
                            placeholderText: root.t("networkNamePlaceholder")
                            anchors.verticalCenter: parent.verticalCenter
                            onValueEdited: newText => root.updateDraft({ networkName: newText.trim() })
                        }

                        DActionButton {
                            id: randNetBtn
                            buttonSize: 36
                            iconSize: 18
                            iconName: "shuffle"
                            iconColor: Theme.primary
                            backgroundColor: Theme.ccIconBoxInactiveBg
                            tooltipText: root.t("randomGenerate")
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: root.updateDraft({ networkName: AssistantConfig.randomNetworkName() })
                        }
                    }
                }

                // Network Secret + Show/Hide + Shuffle
                Column {
                    width: parent.width
                    spacing: 4

                    StyledText {
                        text: root.t("networkSecretLabel")
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        SyncedTextField {
                            width: parent.width - randSecBtn.width - Theme.spacingXS
                            value: root.draft.networkSecret || ""
                            placeholderText: root.t("networkSecretPlaceholder")
                            echoMode: TextInput.Password
                            showPasswordToggle: true
                            anchors.verticalCenter: parent.verticalCenter
                            onValueEdited: newText => root.updateDraft({ networkSecret: newText })
                        }

                        DActionButton {
                            id: randSecBtn
                            buttonSize: 36
                            iconSize: 18
                            iconName: "shuffle"
                            iconColor: Theme.primary
                            backgroundColor: Theme.ccIconBoxInactiveBg
                            tooltipText: root.t("randomGenerate")
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: root.updateDraft({ networkSecret: AssistantConfig.randomSecret(16) })
                        }
                    }
                }

                // Instance Name + Hostname (2-column)
                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    Column {
                        width: Math.floor((parent.width - Theme.spacingS) / 2)
                        spacing: 4

                        StyledText {
                            text: root.t("instanceNameLabel")
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        Row {
                            width: parent.width
                            spacing: 4

                            SyncedTextField {
                                width: parent.width - randInstBtn.width - 4
                                value: root.draft.instanceName || ""
                                placeholderText: root.t("instanceNamePlaceholder")
                                anchors.verticalCenter: parent.verticalCenter
                                onValueEdited: newText => root.updateDraft({ instanceName: newText.trim() })
                            }

                            DActionButton {
                                id: randInstBtn
                                buttonSize: 34
                                iconSize: 16
                                iconName: "shuffle"
                                iconColor: Theme.primary
                                backgroundColor: Theme.ccIconBoxInactiveBg
                                tooltipText: root.t("randomGenerate")
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: root.updateDraft({ instanceName: AssistantConfig.randomInstanceName() })
                            }
                        }
                    }

                    Column {
                        width: Math.floor((parent.width - Theme.spacingS) / 2)
                        spacing: 4

                        StyledText {
                            text: root.t("hostnameLabel")
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }

                        SyncedTextField {
                            width: parent.width
                            value: root.draft.hostname || ""
                            placeholderText: root.t("hostnamePlaceholder")
                            onValueEdited: newText => root.updateDraft({ hostname: newText.trim() })
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.25
                }

                // IP Settings
                StyledText {
                    text: root.t("ipSettingsHeader")
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                CompactSwitchRow {
                    width: parent.width
                    label: root.t("enableDhcp")
                    subtitle: root.t("enableDhcpDesc")
                    checked: root.draft.dhcp !== false
                    onToggled: isChecked => root.updateDraft({ dhcp: isChecked })
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    Column {
                        width: Math.floor((parent.width - Theme.spacingS) / 2)
                        spacing: 4
                        opacity: root.draft.dhcp ? 0.48 : 1.0

                        StyledText {
                            width: parent.width
                            text: root.t("ipv4Address")
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        SyncedTextField {
                            width: parent.width
                            enabled: !root.draft.dhcp
                            value: root.draft.ipv4 || ""
                            placeholderText: root.t("ipv4Placeholder")
                            onValueEdited: newText => root.updateDraft({ ipv4: newText.trim() })
                        }
                    }

                    Column {
                        width: Math.floor((parent.width - Theme.spacingS) / 2)
                        spacing: 4

                        StyledText {
                            width: parent.width
                            text: root.t("ipv6Address")
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        SyncedTextField {
                            width: parent.width
                            value: root.draft.ipv6 || ""
                            placeholderText: root.t("ipv6Placeholder")
                            onValueEdited: newText => root.updateDraft({ ipv6: newText.trim() })
                        }
                    }
                }

                CompactSwitchRow {
                    width: parent.width
                    label: root.t("ipv6Provider")
                    checked: root.draft.ipv6PublicProvider === true
                    onToggled: isChecked => root.updateDraft({ ipv6PublicProvider: isChecked })
                }

                CompactSwitchRow {
                    width: parent.width
                    label: root.t("ipv6Auto")
                    checked: root.draft.ipv6PublicAuto === true
                    onToggled: isChecked => root.updateDraft({ ipv6PublicAuto: isChecked })
                }

                CompactSwitchRow {
                    width: parent.width
                    label: root.t("swDisableTun")
                    checked: root.draft.flags ? root.draft.flags.noTun === true : false
                    onToggled: isChecked => root.updateFlag("noTun", isChecked)
                }
            }
        }

        // =========================================================
        // [Section 1: Connections & Listeners]
        // =========================================================
        Column {
            visible: root.currentSection === 1
            width: parent.width
            spacing: Theme.spacingS

            OptionChipsField {
                width: parent.width
                label: root.t("networkingMethod")
                currentValue: root.draft.configMode === "standalone" ? "standalone" : "manual"
                options: [
                    { value: "manual", label: root.t("manualConfigPeers") },
                    { value: "standalone", label: root.t("standaloneMode") }
                ]
                onValueSelected: val => root.updateDraft({ configMode: val })
            }

            // Empty Peers Warning (matches easytier.cn/assistant)
            Rectangle {
                visible: root.draft.configMode === "manual" && (!root.draft.peers || root.draft.peers.length === 0)
                width: parent.width
                height: warnPeersText.implicitHeight + Theme.spacingS * 2
                radius: Theme.cornerRadiusM
                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

                StyledText {
                    id: warnPeersText
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    text: root.t("noPeersWarning")
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall - 1
                    wrapMode: Text.WordWrap
                }
            }

            RepeatableListEditor {
                id: peersEditor
                visible: root.draft.configMode === "manual"
                width: parent.width
                label: root.t("peersLabel")
                description: root.t("peersDesc")
                placeholder: "tcp://198.51.100.1:11010"
                values: root.draft.peers || []
                presetLabel: root.t("presetPublicPeer")
                presetValues: [AssistantConfig.PUBLIC_PEER_PRESET]
                onValuesUpdated: nextValues => root.updateDraft({ peers: nextValues })
            }

            CompactSwitchRow {
                width: parent.width
                label: root.t("noListenerSwitch")
                subtitle: root.t("noListenerSwitchDesc")
                checked: root.draft.noListener === true
                onToggled: isChecked => root.updateDraft({ noListener: isChecked })
            }

            RepeatableListEditor {
                id: listenersEditor
                width: parent.width
                fieldEnabled: root.draft.noListener !== true
                label: root.t("listenersLabel")
                description: root.t("listenersDesc")
                placeholder: "tcp://0.0.0.0:11010"
                values: root.draft.listeners || []
                presetLabel: root.t("presetDefaultListeners")
                presetValues: AssistantConfig.DEFAULT_LISTENERS_PRESET
                onValuesUpdated: nextValues => root.updateDraft({ listeners: nextValues })
            }

            RepeatableListEditor {
                id: mappedListenersEditor
                width: parent.width
                fieldEnabled: root.draft.noListener !== true
                label: root.t("mappedListenersLabel")
                description: root.t("mappedListenersDesc")
                placeholder: "tcp://198.51.100.10:11010"
                values: root.draft.mappedListeners || []
                onValuesUpdated: nextValues => root.updateDraft({ mappedListeners: nextValues })
            }
        }

        // =========================================================
        // [Section 2: Proxy Networks, Routes, Exit Nodes & SOCKS5]
        // =========================================================
        Column {
            visible: root.currentSection === 2
            width: parent.width
            spacing: Theme.spacingS

            RepeatableListEditor {
                id: proxyEditor
                width: parent.width
                label: root.t("proxyNetworksLabel")
                description: root.t("proxyNetworksDesc")
                placeholder: "192.168.1.0/24"
                values: root.draft.proxyCidrs || []
                onValuesUpdated: nextValues => root.updateDraft({ proxyCidrs: nextValues })
            }

            RepeatableListEditor {
                id: routesEditor
                width: parent.width
                label: root.t("manualRoutesLabel")
                description: root.t("manualRoutesDesc")
                placeholder: "10.0.0.0/8"
                values: root.draft.manualRoutes || []
                onValuesUpdated: nextValues => root.updateDraft({ manualRoutes: nextValues })
            }

            RepeatableListEditor {
                id: exitNodesEditor
                width: parent.width
                label: root.t("exitNodesLabel")
                description: root.t("exitNodesDesc")
                placeholder: "10.144.144.1"
                values: root.draft.exitNodes || []
                onValuesUpdated: nextValues => root.updateDraft({ exitNodes: nextValues })
            }

            Column {
                width: parent.width
                spacing: 4

                StyledText {
                    text: root.t("socks5Label")
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                SyncedTextField {
                    width: parent.width
                    value: root.draft.socks5 || ""
                    placeholderText: root.t("socks5Placeholder")
                    showClearButton: true
                    onValueEdited: newText => root.updateDraft({ socks5: newText.trim() })
                }
            }
        }

        // =========================================================
        // [Section 3: WireGuard VPN Portal & Port Forwarding]
        // =========================================================
        Column {
            visible: root.currentSection === 3
            width: parent.width
            spacing: Theme.spacingS

            StyledText {
                text: root.t("vpnPortalHeader")
                color: Theme.primary
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            CompactSwitchRow {
                width: parent.width
                label: root.t("enableVpnPortal")
                subtitle: root.t("enableVpnPortalDesc")
                checked: root.draft.vpnPortalEnabled === true
                onToggled: isChecked => root.updateDraft({ vpnPortalEnabled: isChecked })
            }

            Row {
                visible: root.draft.vpnPortalEnabled === true
                width: parent.width
                spacing: Theme.spacingS

                Column {
                    width: Math.floor((parent.width - Theme.spacingS) / 2)
                    spacing: 4

                    StyledText {
                        text: root.t("vpnClientCidr")
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    SyncedTextField {
                        width: parent.width
                        value: root.draft.vpnClientCidr || "10.144.145.0/24"
                        placeholderText: "10.144.145.0/24"
                        onValueEdited: newText => root.updateDraft({ vpnClientCidr: newText.trim() })
                    }
                }

                Column {
                    width: Math.floor((parent.width - Theme.spacingS) / 2)
                    spacing: 4

                    StyledText {
                        text: root.t("vpnListenAddr")
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    SyncedTextField {
                        width: parent.width
                        value: root.draft.vpnWireguardListen || "0.0.0.0:11011"
                        placeholderText: "0.0.0.0:11011"
                        onValueEdited: newText => root.updateDraft({ vpnWireguardListen: newText.trim() })
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.outlineVariant
                opacity: 0.25
            }

            // Port Forwarding Rules
            StyledText {
                text: root.t("portForwardHeader")
                color: Theme.primary
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            StyledText {
                width: parent.width
                text: root.t("portForwardDesc")
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall - 1
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: Array.isArray(root.draft.portForwards) ? root.draft.portForwards : []

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: editorCol.width
                    height: fwInner.implicitHeight + Theme.spacingS * 2
                    radius: Theme.cornerRadiusM
                    color: Theme.ccIconBoxInactiveBg

                    Column {
                        id: fwInner
                        x: Theme.spacingS
                        y: Theme.spacingS
                        width: parent.width - Theme.spacingS * 2
                        spacing: 6

                        Row {
                            width: parent.width
                            spacing: 6

                            StyledButton {
                                width: 46
                                height: 24
                                radius: 12
                                color: modelData.proto === "udp" ? Theme.secondaryContainer : Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    const list = (root.draft.portForwards || []).slice();
                                    list[index] = Object.assign({}, list[index], {
                                        proto: modelData.proto === "udp" ? "tcp" : "udp"
                                    });
                                    root.updateDraft({ portForwards: list });
                                }

                                StyledText {
                                    anchors.centerIn: parent
                                    text: String(modelData.proto || "tcp").toUpperCase()
                                    color: modelData.proto === "udp" ? Theme.onSecondaryContainer : Theme.onPrimary
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    font.weight: Font.Bold
                                }
                            }

                            Item {
                                width: parent.width - 46 - 24 - 12
                                height: 1
                            }

                            DActionButton {
                                buttonSize: 24
                                iconSize: 15
                                iconName: "delete"
                                iconColor: Theme.error
                                backgroundColor: "transparent"
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    const list = (root.draft.portForwards || []).filter((_, idx) => idx !== index);
                                    root.updateDraft({ portForwards: list });
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 6

                            Column {
                                width: Math.floor((parent.width - 6) / 2)
                                spacing: 2

                                StyledText {
                                    text: root.t("localBind")
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                }

                                SyncedTextField {
                                    width: parent.width
                                    value: modelData.bindAddr || ""
                                    placeholderText: "0.0.0.0:11012"
                                    onValueEdited: newText => {
                                        const list = (root.draft.portForwards || []).slice();
                                        list[index] = Object.assign({}, list[index], { bindAddr: newText.trim() });
                                        root.updateDraft({ portForwards: list });
                                    }
                                }
                            }

                            Column {
                                width: Math.floor((parent.width - 6) / 2)
                                spacing: 2

                                StyledText {
                                    text: root.t("dstAddress")
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                }

                                SyncedTextField {
                                    width: parent.width
                                    value: modelData.dstAddr || ""
                                    placeholderText: "10.144.144.2:80"
                                    onValueEdited: newText => {
                                        const list = (root.draft.portForwards || []).slice();
                                        list[index] = Object.assign({}, list[index], { dstAddr: newText.trim() });
                                        root.updateDraft({ portForwards: list });
                                    }
                                }
                            }
                        }
                    }
                }
            }

            DButton {
                width: parent.width
                buttonHeight: 32
                iconName: "add"
                text: root.t("addPortForwardRule")
                backgroundColor: Theme.secondaryContainer
                textColor: Theme.onSecondaryContainer
                onClicked: {
                    const list = (root.draft.portForwards || []).slice();
                    list.push({ proto: "tcp", bindAddr: "0.0.0.0:11012", dstAddr: "10.144.144.2:80" });
                    root.updateDraft({ portForwards: list });
                }
            }
        }

        // =========================================================
        // [Section 4: Advanced Options]
        // =========================================================
        AssistantAdvancedSection {
            visible: root.currentSection === 4
            width: parent.width
            lang: root.lang
            flags: root.draft.flags || ({})
            onFlagChanged: (key, val) => root.updateFlag(key, val)
        }

        // =========================================================
        // [Section 5: Logging & Live TOML Preview]
        // =========================================================
        Column {
            visible: root.currentSection === 5
            width: parent.width
            spacing: Theme.spacingS

            Column {
                visible: !root.isUriMode
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: root.t("loggingHeader")
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                OptionChipsField {
                    width: parent.width
                    label: root.t("consoleLogLevel")
                    currentValue: root.draft.consoleLogLevel || "warn"
                    options: [
                        { value: "off", label: root.t("logOff") },
                        { value: "error", label: "Error" },
                        { value: "warn", label: "Warn" },
                        { value: "info", label: "Info" },
                        { value: "debug", label: "Debug" },
                        { value: "trace", label: "Trace" }
                    ]
                    onValueSelected: val => root.updateDraft({ consoleLogLevel: val })
                }

                OptionChipsField {
                    width: parent.width
                    label: root.t("fileLogLevel")
                    currentValue: root.draft.fileLogLevel || ""
                    options: [
                        { value: "", label: root.t("logOff") },
                        { value: "error", label: "Error" },
                        { value: "warn", label: "Warn" },
                        { value: "info", label: "Info" },
                        { value: "debug", label: "Debug" },
                        { value: "trace", label: "Trace" }
                    ]
                    onValueSelected: val => root.updateDraft({ fileLogLevel: val })
                }

                Row {
                    visible: String(root.draft.fileLogLevel || "").length > 0
                    width: parent.width
                    spacing: Theme.spacingS

                    Column {
                        width: Math.floor((parent.width - Theme.spacingS) / 2)
                        spacing: 4

                        StyledText {
                            text: root.t("logDirLabel")
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        SyncedTextField {
                            width: parent.width
                            value: root.draft.fileLogDir || ""
                            placeholderText: "/tmp/easytier"
                            onValueEdited: newText => root.updateDraft({ fileLogDir: newText.trim() })
                        }
                    }

                    Column {
                        width: Math.floor((parent.width - Theme.spacingS) / 2)
                        spacing: 4

                        StyledText {
                            text: root.t("logFileNameLabel")
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        SyncedTextField {
                            width: parent.width
                            value: root.draft.fileLogName || ""
                            placeholderText: "easytier"
                            onValueEdited: newText => root.updateDraft({ fileLogName: newText.trim() })
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.25
                }
            }

            // Live TOML Preview Header + Actions
            Item {
                width: parent.width
                height: 28

                StyledText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.t("tomlPreviewHeader")
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    DActionButton {
                        buttonSize: 26
                        iconSize: 15
                        iconName: root.showTomlSecret ? "visibility_off" : "visibility"
                        iconColor: Theme.surfaceVariantText
                        backgroundColor: Theme.ccIconBoxInactiveBg
                        tooltipText: root.showTomlSecret ? root.t("hideSecretInToml") : root.t("showSecretInToml")
                        onClicked: root.showTomlSecret = !root.showTomlSecret
                    }

                    DButton {
                        buttonHeight: 26
                        iconName: "content_copy"
                        text: root.t("copyToml")
                        backgroundColor: Theme.secondaryContainer
                        textColor: Theme.onSecondaryContainer
                        onClicked: {
                            root.flushAllPending();
                            const fullToml = AssistantConfig.generateToml(root.draft, false);
                            root.copyTomlRequested(fullToml);
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: tomlTextItem.implicitHeight + Theme.spacingM * 2
                radius: Theme.cornerRadiusM
                color: Theme.ccIconBoxInactiveBg

                StyledText {
                    id: tomlTextItem
                    x: Theme.spacingM
                    y: Theme.spacingM
                    width: parent.width - Theme.spacingM * 2
                    text: AssistantConfig.generateToml(root.draft, !root.showTomlSecret)
                    color: Theme.surfaceText
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall - 1
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outlineVariant
            opacity: 0.35
        }

        // [Bottom Save / Connect Bar]
        Row {
            width: parent.width
            spacing: Theme.spacingXS
            layoutDirection: Qt.RightToLeft

            DButton {
                buttonHeight: 34
                iconName: "bolt"
                text: root.t("saveAndConnect")
                enabled: root.canSave && !root.busy
                onClicked: {
                    root.flushAllPending();
                    root.saveRequested(root.draft, true);
                }
            }

            DButton {
                buttonHeight: 34
                text: root.t("save")
                backgroundColor: Theme.secondaryContainer
                textColor: Theme.onSecondaryContainer
                enabled: root.canSave && !root.busy
                onClicked: {
                    root.flushAllPending();
                    root.saveRequested(root.draft, false);
                }
            }

            DButton {
                buttonHeight: 34
                text: root.t("cancel")
                backgroundColor: "transparent"
                textColor: Theme.surfaceVariantText
                onClicked: root.cancelled()
            }
        }
    }
}
