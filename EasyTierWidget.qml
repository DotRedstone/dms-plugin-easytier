import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "components"
import "UiText.js" as UiText

// [Main Plugin Widget]
PluginComponent {
    id: root

    readonly property string helper: Paths.strip(Qt.resolvedUrl("easytier-dms"))
    readonly property bool isLiveInstance: pluginService !== null && pluginId !== ""
    readonly property bool isPrimaryInstance: isLiveInstance && EasyTierBus.primaryInstance === root
    property bool _ipcReady: false
    property int _refreshSeq: 0

    // [Settings Bindings]
    readonly property string lang: UiText.resolveLang(
        pluginData.language || "auto",
        Qt.locale().name
    )
    readonly property string pillMode: pluginData.pillMode || "peers"
    readonly property string copyField: pluginData.copyField || "ip"
    readonly property bool rightClickToggle: pluginData.rightClickToggle !== false && pluginData.rightClickToggle !== "false"
    readonly property bool showRoutes: pluginData.showRoutes !== false && pluginData.showRoutes !== "false"
    readonly property int pollIntervalMs: Math.max(2, Math.min(60, Number(pluginData.pollInterval) || 5)) * 1000
    readonly property string serviceScope: pluginData.serviceScope === "user" ? "user" : "system"
    readonly property string serviceUnit: {
        const raw = String(pluginData.serviceUnit || "").trim();
        return raw.length > 0 ? raw : "easytier.service";
    }
    readonly property string rpcPortal: {
        const raw = String(pluginData.rpcPortal || "").trim();
        return raw.length > 0 ? raw : "127.0.0.1:15888";
    }

    // [Reactive State]
    readonly property var snap: EasyTierBus.snapshot
    readonly property bool busy: EasyTierBus.busy
    readonly property string lastError: EasyTierBus.lastError
    readonly property bool cliAvailable: snap ? snap.cliAvailable === true : true
    readonly property bool serviceActive: snap ? snap.serviceActive === true : false
    readonly property bool connected: snap ? snap.rpcConnected === true : false
    readonly property var selfNode: snap && snap.self ? snap.self : null
    readonly property var peers: snap && Array.isArray(snap.peers) ? snap.peers : []
    readonly property var routes: snap && Array.isArray(snap.routes) ? snap.routes : []
    readonly property var traffic: snap && snap.traffic ? snap.traffic : ({ rxBytes: 0, txBytes: 0, forwardedBytes: 0 })
    readonly property var counts: snap && snap.counts ? snap.counts : ({ total: 0, p2p: 0, relay: 0 })
    readonly property bool hasError: !cliAvailable || lastError.length > 0

    readonly property string pillText: {
        if (!cliAvailable)
            return "ERR";
        if (!connected)
            return serviceActive ? "…" : UiText.tr(lang, "off");
        if (pillMode === "icon")
            return "";
        if (pillMode === "ip")
            return (selfNode && selfNode.ipv4) ? selfNode.ipv4 : UiText.tr(lang, "on");
        if (pillMode === "network")
            return (selfNode && selfNode.networkName) ? selfNode.networkName : UiText.tr(lang, "on");
        return String(counts.total || 0);
    }

    function t(key, arg1) {
        return UiText.tr(root.lang, key, arg1);
    }

    // [Instance Lifecycle]
    function registerInstance() {
        if (!isLiveInstance)
            return;
        const list = EasyTierBus.instances.slice();
        if (list.indexOf(root) < 0) {
            list.push(root);
            EasyTierBus.instances = list;
        }
        if (EasyTierBus.primaryInstance === null) {
            EasyTierBus.primaryInstance = root;
        }
    }

    function unregisterInstance() {
        const list = EasyTierBus.instances.filter(item => item !== root);
        EasyTierBus.instances = list;
        if (EasyTierBus.primaryInstance === root) {
            EasyTierBus.primaryInstance = list.length > 0 ? list[0] : null;
        }
    }

    onIsLiveInstanceChanged: {
        if (isLiveInstance) {
            registerInstance();
            if (EasyTierBus.snapshot === null)
                refresh();
        }
    }

    Component.onCompleted: {
        if (isLiveInstance) {
            registerInstance();
            refresh();
        }
    }

    Component.onDestruction: {
        unregisterInstance();
    }

    onRpcPortalChanged: if (isPrimaryInstance) refresh()
    onServiceUnitChanged: if (isPrimaryInstance) refresh()
    onServiceScopeChanged: if (isPrimaryInstance) refresh()

    // [Clipboard & Notifications]
    function copyText(value) {
        const text = String(value || "").trim();
        if (!text)
            return;
        Quickshell.execDetached(["dms", "cl", "copy", text]);
        if (typeof ToastService !== "undefined")
            ToastService.showInfo(root.t("title"), root.t("copied") + ": " + text);
    }

    function showToast(title, msg, isErr) {
        if (typeof ToastService === "undefined")
            return;
        if (isErr)
            ToastService.showError(title, msg);
        else
            ToastService.showInfo(title, msg);
    }

    // [Backend Actions]
    function refresh() {
        if (!isLiveInstance || EasyTierBus.busy)
            return;
        const seq = ++_refreshSeq;
        Proc.runCommand(
            "easytier.status",
            [helper, "status", rpcPortal, serviceUnit, serviceScope],
            (output, exitCode) => {
                if (seq !== _refreshSeq && EasyTierBus.busy)
                    return;
                if (exitCode !== 0) {
                    return;
                }
                try {
                    const parsed = JSON.parse(output);
                    if (parsed && parsed.ok === true) {
                        EasyTierBus.snapshot = parsed;
                    }
                } catch (e) {}
            },
            0,
            8000
        );
    }

    function controlService(action) {
        if (!cliAvailable && action !== "stop")
            return;
        if (EasyTierBus.busy)
            return;

        EasyTierBus.busy = true;
        EasyTierBus.lastError = "";
        ++_refreshSeq;

        Proc.runCommand(
            "easytier.control",
            [helper, action, serviceUnit, serviceScope, rpcPortal],
            (output, exitCode) => {
                EasyTierBus.busy = false;
                let parsed = null;
                try {
                    parsed = JSON.parse(output);
                } catch (e) {}

                if (exitCode === 0 && parsed && parsed.ok === true) {
                    EasyTierBus.snapshot = parsed;
                    EasyTierBus.lastError = "";
                    const effective = parsed.action || action;
                    if (effective === "stop")
                        showToast(root.t("title"), root.t("serviceStoppedToast"), false);
                    else if (effective === "restart")
                        showToast(root.t("title"), root.t("serviceRestarted"), false);
                    else
                        showToast(root.t("title"), root.t("serviceStarted"), false);
                    postActionRefreshTimer.restart();
                } else {
                    const errMsg = (parsed && parsed.error) ? String(parsed.error) : root.t("controlFailed");
                    EasyTierBus.lastError = errMsg;
                    showToast(root.t("title"), errMsg, true);
                    refresh();
                }
            },
            0,
            35000
        );
    }

    function toggleService() {
        controlService("toggle");
    }

    function restartService() {
        controlService("restart");
    }

    // [Timers]
    Timer {
        interval: 0
        running: root.isLiveInstance && !root._ipcReady
        onTriggered: root._ipcReady = true
    }

    Timer {
        id: pollTimer
        interval: root.pollIntervalMs
        repeat: true
        running: root.isPrimaryInstance && !root.busy
        onTriggered: root.refresh()
    }

    Timer {
        id: postActionRefreshTimer
        interval: 1200
        repeat: false
        onTriggered: root.refresh()
    }

    // [IPC]
    IpcHandler {
        id: ipcHandler
        target: "easytier"
        enabled: root._ipcReady && root.isPrimaryInstance

        function status(): string {
            return JSON.stringify({
                connected: root.connected,
                serviceActive: root.serviceActive,
                ipv4: root.selfNode ? root.selfNode.ipv4 : "",
                networkName: root.selfNode ? root.selfNode.networkName : "",
                peers: root.counts.total || 0,
                p2p: root.counts.p2p || 0,
                relay: root.counts.relay || 0
            });
        }

        function toggle(): string {
            root.toggleService();
            return "TOGGLE_REQUESTED";
        }

        function start(): string {
            root.controlService("start");
            return "START_REQUESTED";
        }

        function stop(): string {
            root.controlService("stop");
            return "STOP_REQUESTED";
        }

        function restart(): string {
            root.restartService();
            return "RESTART_REQUESTED";
        }

        function refresh(): string {
            root.refresh();
            return "REFRESH_REQUESTED";
        }

        function popout(): string {
            root.triggerPopout();
            return "POPOUT_TOGGLED";
        }
    }

    // [Control Center Tile]
    ccWidgetIcon: "hub"
    ccWidgetPrimaryText: root.t("title")
    ccWidgetSecondaryText: {
        if (root.busy)
            return root.t("starting");
        if (!root.cliAvailable)
            return root.t("cliMissing");
        if (!root.connected)
            return root.serviceActive ? root.t("rpcUnreachable") : root.t("disconnected");
        return root.t("onlineCount", root.counts.total || 0);
    }
    ccWidgetIsActive: root.connected || root.serviceActive
    onCcWidgetToggled: root.toggleService()
    onCcWidgetExpanded: root.refresh()

    // [Bar Pills]
    pillRightClickAction: root.rightClickToggle ? (() => root.toggleService()) : null

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            EasyTierLogo {
                size: Math.max(15, root.iconSize - 2)
                color: root.hasError
                    ? Theme.error
                    : (root.connected ? Theme.primary : Theme.surfaceVariantText)
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.pillText.length > 0
                text: root.pillText
                color: root.connected ? Theme.surfaceText : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: root.connected ? Font.Medium : Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            EasyTierLogo {
                size: Math.max(15, root.iconSize - 2)
                color: root.hasError
                    ? Theme.error
                    : (root.connected ? Theme.primary : Theme.surfaceVariantText)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.pillMode !== "icon"
                text: root.connected ? String(root.counts.total || 0) : root.t("off")
                color: root.connected ? Theme.surfaceText : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // [Popout Panel]
    popoutWidth: 410

    popoutContent: Component {
        PopoutComponent {
            id: popup

            property string searchQuery: ""
            property int filterIndex: 0
            property string expandedPeerKey: ""

            headerText: root.t("title")
            detailsText: ""
            showCloseButton: false

            readonly property var filteredPeers: {
                const all = root.peers;
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

            readonly property int maxViewportHeight: {
                const screenH = root.parentScreen && root.parentScreen.height > 0 ? root.parentScreen.height : 1080;
                const reserve = Math.max(root.barThickness + root.barSpacing, 56) + 96;
                return Math.max(260, Math.min(620, Math.floor(screenH - reserve)));
            }

            function commitGeometry() {
                if (!parentPopout || !parentPopout.shouldBeVisible)
                    return;
                Qt.callLater(() => {
                    if (parentPopout && parentPopout.shouldBeVisible)
                        parentPopout.updateSurfacePosition();
                });
            }

            onImplicitHeightChanged: commitGeometry()

            onParentPopoutChanged: {
                if (parentPopout) {
                    parentPopout.animationDuration = 0;
                    parentPopout.suspendShadowWhileResizing = true;
                }
            }

            headerActions: Component {
                Row {
                    spacing: Theme.spacingXS

                    DToggle {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.connected || root.serviceActive
                        toggling: root.busy
                        enabled: root.cliAvailable && !root.busy
                        Accessible.name: (root.connected || root.serviceActive) ? root.t("disableService") : root.t("enableService")
                        onToggled: root.toggleService()
                    }

                    Item {
                        width: Theme.spacingXS
                        height: 1
                    }

                    DActionButton {
                        buttonSize: 32
                        iconSize: 18
                        iconName: "restart_alt"
                        iconColor: Theme.primary
                        backgroundColor: Theme.ccPillInactiveBg
                        enabled: (root.connected || root.serviceActive) && !root.busy
                        tooltipText: root.t("restart")
                        onClicked: root.restartService()
                    }

                    DActionButton {
                        buttonSize: 32
                        iconSize: 18
                        iconName: "refresh"
                        iconColor: Theme.primary
                        backgroundColor: Theme.ccPillInactiveBg
                        enabled: !root.busy
                        tooltipText: root.t("refresh")
                        onClicked: root.refresh()
                    }
                }
            }

            DFlickable {
                id: bodyViewport
                width: parent.width
                height: Math.min(bodyColumn.implicitHeight, popup.maxViewportHeight)
                contentWidth: width
                contentHeight: bodyColumn.implicitHeight
                interactive: contentHeight > height
                clip: true

                Column {
                    id: bodyColumn
                    width: bodyViewport.width
                    spacing: Theme.spacingS

                    // Error banner
                    Rectangle {
                        visible: root.lastError.length > 0 || !root.cliAvailable
                        width: parent.width
                        height: errText.implicitHeight + Theme.spacingM
                        radius: Theme.cornerRadiusM
                        color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.14)

                        StyledText {
                            id: errText
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            text: !root.cliAvailable ? root.t("cliMissing") : root.lastError
                            color: Theme.error
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Self Node Hero Card
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
                                    spacing: 2

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
                                            if (!root.connected)
                                                return root.serviceActive ? root.t("rpcUnreachable") : root.t("serviceStopped");
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
                                    onClicked: root.copyText(root.selfNode ? root.selfNode.ipv4 : "")
                                }
                            }

                            // Metrics footer inside Hero Card when connected
                            Rectangle {
                                visible: root.connected
                                width: parent.width
                                height: 1
                                color: Theme.outlineVariant
                                opacity: 0.35
                            }

                            Row {
                                visible: root.connected
                                width: parent.width
                                spacing: Theme.spacingM

                                StyledText {
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    text: root.t("natType") + ": " + ((root.selfNode && root.selfNode.natType) ? root.selfNode.natType : "Unknown")
                                }

                                StyledText {
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    text: "↓ " + UiText.formatBytes(root.traffic.rxBytes) + "  ↑ " + UiText.formatBytes(root.traffic.txBytes)
                                }

                                StyledText {
                                    visible: root.selfNode && root.selfNode.version
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    text: root.selfNode && root.selfNode.version ? ("v" + root.selfNode.version) : ""
                                }
                            }
                        }
                    }

                    // Search & Filter Controls
                    DSearchField {
                        visible: root.connected && root.peers.length > 0
                        width: parent.width
                        placeholderText: root.t("searchPlaceholder")
                        text: popup.searchQuery
                        onTextEdited: popup.searchQuery = text
                    }

                    DFilterChips {
                        visible: root.connected && root.peers.length > 0
                        width: parent.width
                        currentIndex: popup.filterIndex
                        showCounts: true
                        model: [
                            { label: root.t("allPeers"), count: root.counts.total || 0 },
                            { label: root.t("p2pPeers"), count: root.counts.p2p || 0 },
                            { label: root.t("relayPeers"), count: root.counts.relay || 0 }
                        ]
                        onSelectionChanged: index => popup.filterIndex = index
                    }

                    // Empty Peer State
                    Rectangle {
                        visible: root.connected && popup.filteredPeers.length === 0
                        width: parent.width
                        height: 48
                        radius: Theme.cornerRadiusM
                        color: Theme.ccPillInactiveBg

                        StyledText {
                            anchors.centerIn: parent
                            text: popup.searchQuery.length > 0 ? root.t("noMatchingPeers") : root.t("noPeers")
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    // Peer List
                    Column {
                        visible: root.connected && popup.filteredPeers.length > 0
                        width: parent.width
                        spacing: Theme.spacingXS

                        Repeater {
                            model: popup.filteredPeers

                            delegate: PeerRow {
                                width: parent ? parent.width : 378
                                lang: root.lang
                                copyField: root.copyField
                                expanded: popup.expandedPeerKey === (modelData.id || modelData.ipv4 || modelData.hostname)
                                onToggleExpand: {
                                    const key = modelData.id || modelData.ipv4 || modelData.hostname;
                                    popup.expandedPeerKey = popup.expandedPeerKey === key ? "" : key;
                                }
                                onCopyRequested: (value, label) => root.copyText(value)
                            }
                        }
                    }

                    // Subnet Proxy Routes Section
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
            }
        }
    }
}
