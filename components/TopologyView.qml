import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../UiText.js" as UiText

// [Topology Tab View]
Column {
    id: root

    property string lang: "zh_CN"
    property string backendMode: "managed"
    property string serviceUnit: "easytier.service"
    property string activeProfileName: ""
    property int profileCount: 0
    property bool cliAvailable: true
    property bool busy: false
    property bool connected: false
    property bool backendActive: false
    property bool noInstance: false
    property var selfNode: null
    property var peers: []
    property var routes: []
    property var traffic: ({ rxBytes: 0, txBytes: 0, forwardedBytes: 0 })
    property var counts: ({ total: 0, p2p: 0, relay: 0 })
    property string copyField: "ip"
    property bool showRoutes: true

    property string searchQuery: ""
    property int filterIndex: 0
    property string expandedPeerKey: ""

    signal copyRequested(string value)
    signal openProfilesTab(bool createNew)

    spacing: Theme.spacingS

    function t(key, arg1) {
        return UiText.tr(root.lang, key, arg1);
    }

    readonly property string modeBadgeText: {
        if (backendMode === "systemd")
            return root.t("modeBadgeSystemd", serviceUnit);
        if (activeProfileName.length > 0)
            return root.t("modeBadgeManaged", activeProfileName);
        return root.t("modeBadgeManagedEmpty");
    }

    readonly property var filteredPeers: {
        const all = Array.isArray(root.peers) ? root.peers : [];
        let base = all;
        if (filterIndex === 1)
            base = all.filter(p => p.mode === "p2p");
        else if (filterIndex === 2)
            base = all.filter(p => p.mode === "relay");

        const q = searchQuery.trim().toLowerCase();
        if (!q)
            return base;
        return base.filter(p =>
            String(p.hostname || "").toLowerCase().indexOf(q) >= 0
            || String(p.ipv4 || "").toLowerCase().indexOf(q) >= 0
            || String(p.proto || "").toLowerCase().indexOf(q) >= 0
            || String(p.cost || "").toLowerCase().indexOf(q) >= 0
        );
    }

    // [Self Node Hero Card]
    Rectangle {
        width: parent.width
        height: heroColumn.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadiusL
        color: Theme.ccPillInactiveBg

        Column {
            id: heroColumn
            x: Theme.spacingM
            y: Theme.spacingM
            width: parent.width - Theme.spacingM * 2
            spacing: Theme.spacingS

            Row {
                width: parent.width
                spacing: Theme.spacingM

                Rectangle {
                    id: heroIconBox
                    width: 42
                    height: 42
                    radius: Theme.cornerRadiusM
                    color: root.connected ? Theme.primary : Theme.ccIconBoxInactiveBg
                    anchors.verticalCenter: parent.verticalCenter

                    EasyTierLogo {
                        anchors.centerIn: parent
                        size: 22
                        color: root.connected ? Theme.onPrimary : Theme.primary
                    }
                }

                Column {
                    width: parent.width - heroIconBox.width - (copySelfBtn.visible ? copySelfBtn.width + Theme.spacingS : 0) - Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Row {
                        spacing: Theme.spacingXS

                        StyledText {
                            text: root.connected && root.selfNode && root.selfNode.hostname
                                ? root.selfNode.hostname
                                : root.t("title")
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            visible: root.connected
                            height: 18
                            width: selfBadgeLabel.implicitWidth + 10
                            radius: 9
                            color: Theme.secondaryContainer
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                id: selfBadgeLabel
                                anchors.centerIn: parent
                                text: root.t("thisDevice")
                                color: Theme.onSecondaryContainer
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.weight: Font.Medium
                            }
                        }
                    }

                    StyledText {
                        width: parent.width
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        elide: Text.ElideRight
                        text: {
                            if (root.busy)
                                return root.t("starting");
                            if (!root.cliAvailable)
                                return root.t("cliMissing");
                            if (!root.connected) {
                                if (root.noInstance)
                                    return root.t("noInstanceHint");
                                if (root.backendActive)
                                    return root.t("rpcUnreachable");
                                return root.backendMode === "managed" ? root.t("managedStopped") : root.t("serviceStopped");
                            }
                            const parts = [];
                            if (root.selfNode && root.selfNode.ipv4)
                                parts.push(root.selfNode.ipv4);
                            if (root.selfNode && root.selfNode.networkName)
                                parts.push(root.selfNode.networkName);
                            return parts.join(" • ");
                        }
                    }
                }

                DActionButton {
                    id: copySelfBtn
                    visible: root.connected && root.selfNode !== null && String(root.selfNode.ipv4 || "").length > 0
                    buttonSize: 30
                    iconSize: 16
                    iconName: "content_copy"
                    iconColor: Theme.surfaceText
                    backgroundColor: "transparent"
                    tooltipText: root.t("copyIp")
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.copyRequested(root.selfNode ? root.selfNode.ipv4 : "")
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.outlineVariant
                opacity: 0.35
            }

            // Mode badge + metrics bar
            Row {
                width: parent.width
                spacing: Theme.spacingS

                StyledButton {
                    id: modeChip
                    height: 22
                    width: modeChipRow.implicitWidth + 14
                    radius: 11
                    color: Theme.secondaryContainer
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.openProfilesTab(false)

                    Row {
                        id: modeChipRow
                        anchors.centerIn: parent
                        spacing: 4

                        DIcon {
                            name: root.backendMode === "managed" ? "tune" : "dns"
                            size: 13
                            color: Theme.onSecondaryContainer
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.modeBadgeText
                            color: Theme.onSecondaryContainer
                            font.pixelSize: Theme.fontSizeSmall - 1
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                StyledText {
                    visible: root.connected
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    width: Math.max(60, parent.width - modeChip.width - Theme.spacingS)
                    text: root.t("natType") + ": " + ((root.selfNode && root.selfNode.natType) ? root.selfNode.natType : "Unknown")
                        + "  •  ↓" + UiText.formatBytes(root.traffic.rxBytes) + " ↑" + UiText.formatBytes(root.traffic.txBytes)
                }
            }

            // Quick CTA when Managed Mode has no profile yet
            DButton {
                visible: !root.connected && root.backendMode === "managed" && root.profileCount === 0
                width: parent.width
                iconName: "add"
                text: root.t("createFirstProfile")
                onClicked: root.openProfilesTab(true)
            }
        }
    }

    // [Peer Search & Filter]
    DSearchField {
        visible: root.connected && root.peers.length > 0
        width: parent.width
        placeholderText: root.t("searchPlaceholder")
        text: root.searchQuery
        onTextEdited: root.searchQuery = text
    }

    DFilterChips {
        visible: root.connected && root.peers.length > 0
        width: parent.width
        currentIndex: root.filterIndex
        showCounts: true
        model: [
            { label: root.t("allPeers"), count: root.counts.total || 0 },
            { label: root.t("p2pPeers"), count: root.counts.p2p || 0 },
            { label: root.t("relayPeers"), count: root.counts.relay || 0 }
        ]
        onSelectionChanged: index => root.filterIndex = index
    }

    // [Empty Peer State]
    Rectangle {
        visible: root.connected && root.filteredPeers.length === 0
        width: parent.width
        height: 46
        radius: Theme.cornerRadiusM
        color: Theme.ccPillInactiveBg

        StyledText {
            anchors.centerIn: parent
            text: root.searchQuery.length > 0 ? root.t("noMatchingPeers") : root.t("noPeers")
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    // [Peer List]
    Column {
        visible: root.connected && root.filteredPeers.length > 0
        width: parent.width
        spacing: Theme.spacingXS

        Repeater {
            model: root.filteredPeers

            delegate: PeerRow {
                width: parent ? parent.width : 378
                lang: root.lang
                copyField: root.copyField
                expanded: root.expandedPeerKey === (modelData.id || modelData.ipv4 || modelData.hostname)
                onToggleExpand: {
                    const key = modelData.id || modelData.ipv4 || modelData.hostname;
                    root.expandedPeerKey = root.expandedPeerKey === key ? "" : key;
                }
                onCopyRequested: (value, label) => root.copyRequested(value)
            }
        }
    }

    // [Subnet Proxy Routes]
    Column {
        visible: root.connected && root.showRoutes && root.routes.length > 0
        width: parent.width
        spacing: Theme.spacingXS

        StyledText {
            leftPadding: Theme.spacingXS
            text: root.t("routes")
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
        }

        Repeater {
            model: root.routes

            delegate: Rectangle {
                required property var modelData
                width: parent ? parent.width : 378
                height: routeCol.implicitHeight + Theme.spacingS * 2
                radius: Theme.cornerRadiusM
                color: Theme.ccPillInactiveBg

                Column {
                    id: routeCol
                    x: Theme.spacingM
                    y: Theme.spacingS
                    width: parent.width - Theme.spacingM * 2
                    spacing: 2

                    StyledText {
                        width: parent.width
                        text: (modelData.proxyCidrs || []).join(", ")
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        width: parent.width
                        text: root.t("viaHop", modelData.hostname || modelData.nextHopHostname || modelData.ipv4 || "-")
                            + (modelData.pathLen > 0 ? (" • " + root.t("hopsCount", modelData.pathLen)) : "")
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
