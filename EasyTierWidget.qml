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
    property var _activePopupItem: null

    // [Settings Bindings]
    readonly property string lang: UiText.resolveLang(
        pluginData.language || "auto",
        Qt.locale().name
    )
    readonly property string backendMode: pluginData.backendMode === "systemd" ? "systemd" : "managed"
    readonly property string pillMode: pluginData.pillMode || "peers"
    readonly property string copyField: pluginData.copyField || "ip"
    readonly property bool rightClickToggle: pluginData.rightClickToggle !== false && pluginData.rightClickToggle !== "false"
    readonly property bool showRoutes: pluginData.showRoutes !== false && pluginData.showRoutes !== "false"
    readonly property int pollIntervalMs: Math.max(5, Math.min(60, Number(pluginData.pollInterval) || 5)) * 1000
    readonly property int effectivePollMs: {
        if (EasyTierBus.popupOpen)
            return pollIntervalMs;
        if (connected || backendActive)
            return Math.max(pollIntervalMs, 15000);
        return Math.max(pollIntervalMs, 30000);
    }
    readonly property string serviceScope: pluginData.serviceScope === "user" ? "user" : "system"
    readonly property string serviceUnit: {
        const raw = String(pluginData.serviceUnit || "").trim();
        return raw.length > 0 ? raw : "easytier.service";
    }
    readonly property string rpcPortal: {
        const raw = String(pluginData.rpcPortal || "").trim();
        return raw.length > 0 ? raw : "127.0.0.1:15888";
    }
    readonly property string managedRpcPortal: rpcPortal === "127.0.0.1:15888" ? "127.0.0.1:15889" : rpcPortal
    readonly property string effectiveRpcPortal: backendMode === "managed" ? managedRpcPortal : rpcPortal

    // [Reactive State]
    readonly property var snap: EasyTierBus.snapshot
    readonly property var profiles: EasyTierBus.profiles
    readonly property string activeProfileId: EasyTierBus.activeProfileId || (snap && snap.activeProfileId ? snap.activeProfileId : "")
    readonly property string activeProfileName: {
        for (let i = 0; i < profiles.length; i++) {
            if (profiles[i].id === activeProfileId)
                return profiles[i].name || "";
        }
        const summaries = snap && Array.isArray(snap.profileSummaries) ? snap.profileSummaries : [];
        for (let j = 0; j < summaries.length; j++) {
            if (summaries[j].id === activeProfileId)
                return summaries[j].name || "";
        }
        return "";
    }
    readonly property bool busy: EasyTierBus.busy
    readonly property string lastError: EasyTierBus.lastError
    readonly property bool cliAvailable: snap ? snap.cliAvailable === true : true
    readonly property bool serviceActive: snap ? snap.serviceActive === true : false
    readonly property bool managedActive: snap ? snap.managedActive === true : false
    readonly property bool backendActive: backendMode === "managed" ? managedActive : serviceActive
    readonly property bool connected: snap ? snap.rpcConnected === true : false
    readonly property bool noInstance: snap ? snap.noInstance === true : false
    readonly property var selfNode: snap && snap.self ? snap.self : null
    readonly property var peers: snap && Array.isArray(snap.peers) ? snap.peers : []
    readonly property var routes: snap && Array.isArray(snap.routes) ? snap.routes : []
    readonly property var connectors: snap && Array.isArray(snap.connectors) ? snap.connectors : []
    readonly property var traffic: snap && snap.traffic ? snap.traffic : ({ rxBytes: 0, txBytes: 0, forwardedBytes: 0 })
    readonly property var counts: snap && snap.counts ? snap.counts : ({ total: 0, p2p: 0, relay: 0 })
    readonly property bool hasError: !cliAvailable || lastError.length > 0

    readonly property string pillText: {
        if (!cliAvailable)
            return "ERR";
        if (!connected)
            return backendActive ? "…" : UiText.tr(lang, "off");
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

    function setBackendMode(nextMode) {
        if (!pluginService || !pluginId)
            return;
        const clean = nextMode === "systemd" ? "systemd" : "managed";
        if (pluginService.savePluginData) {
            pluginService.savePluginData(pluginId, "backendMode", clean);
            loadPluginData();
        }
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

    function syncPopupOpen() {
        EasyTierBus.popupOpen = EasyTierBus.instances.some(item => item && item.interactionActive);
    }

    function unregisterInstance() {
        const list = EasyTierBus.instances.filter(item => item !== root);
        EasyTierBus.instances = list;
        if (EasyTierBus.primaryInstance === root) {
            EasyTierBus.primaryInstance = list.length > 0 ? list[0] : null;
        }
        syncPopupOpen();
    }

    onInteractionActiveChanged: {
        syncPopupOpen();
        if (interactionActive)
            refresh();
    }

    onIsLiveInstanceChanged: {
        if (isLiveInstance) {
            registerInstance();
            if (EasyTierBus.snapshot === null) {
                loadProfiles();
                refresh();
            }
        }
    }

    Component.onCompleted: {
        if (isLiveInstance) {
            registerInstance();
            if (isPrimaryInstance || EasyTierBus.profiles.length === 0)
                loadProfiles();
            refresh();
        }
    }

    Component.onDestruction: {
        unregisterInstance();
    }

    onBackendModeChanged: if (isPrimaryInstance) refresh()
    onEffectiveRpcPortalChanged: if (isPrimaryInstance) refresh()
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

    function copyToml(tomlText) {
        const text = String(tomlText || "").trim();
        if (!text)
            return;
        Quickshell.execDetached(["dms", "cl", "copy", text]);
        if (typeof ToastService !== "undefined")
            ToastService.showInfo(root.t("title"), root.t("tomlCopied"));
    }

    function showToast(title, msg, isErr) {
        if (typeof ToastService === "undefined")
            return;
        if (isErr)
            ToastService.showError(title, msg);
        else
            ToastService.showInfo(title, msg);
    }

    // [Backend Queries & Controls]
    function refresh() {
        if (!isLiveInstance || EasyTierBus.busy)
            return;
        const seq = ++_refreshSeq;
        Proc.runCommand(
            "easytier.status",
            [helper, "status", effectiveRpcPortal, serviceUnit, serviceScope],
            (output, exitCode) => {
                if (seq !== _refreshSeq && EasyTierBus.busy)
                    return;
                if (exitCode !== 0)
                    return;
                try {
                    const parsed = JSON.parse(output);
                    if (parsed && parsed.ok === true) {
                        EasyTierBus.snapshot = parsed;
                        if (!EasyTierBus.activeProfileId && parsed.activeProfileId)
                            EasyTierBus.activeProfileId = parsed.activeProfileId;
                    }
                } catch (e) {}
            },
            0,
            8000
        );
    }

    function loadProfiles() {
        if (!isLiveInstance)
            return;
        Proc.runCommand(
            "easytier.profiles",
            [helper, "profile-list"],
            (output, exitCode) => {
                if (exitCode !== 0)
                    return;
                try {
                    const parsed = JSON.parse(output);
                    if (parsed && parsed.ok === true) {
                        EasyTierBus.profiles = Array.isArray(parsed.profiles) ? parsed.profiles : [];
                        EasyTierBus.activeProfileId = parsed.activeProfileId || "";
                    }
                } catch (e) {}
            },
            0,
            5000
        );
    }

    function runControlCommand(args, onDone) {
        if (EasyTierBus.busy)
            return;
        EasyTierBus.busy = true;
        EasyTierBus.lastError = "";
        ++_refreshSeq;

        Proc.runCommand(
            "easytier.control",
            args,
            (output, exitCode) => {
                EasyTierBus.busy = false;
                let parsed = null;
                try {
                    parsed = JSON.parse(output);
                } catch (e) {}

                if (exitCode === 0 && parsed && parsed.ok === true) {
                    if ("rpcConnected" in parsed)
                        EasyTierBus.snapshot = parsed;
                    EasyTierBus.lastError = "";
                    if (onDone)
                        onDone(parsed);
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
        if (backendMode === "managed") {
            if (!managedActive && !connected && profiles.length === 0) {
                triggerPopout();
                Qt.callLater(() => {
                    if (root._activePopupItem)
                        root._activePopupItem.jumpToProfiles(true);
                });
                return;
            }
            runControlCommand(
                [helper, "managed-toggle", activeProfileId, managedRpcPortal, serviceUnit, serviceScope],
                parsed => {
                    showToast(
                        root.t("title"),
                        parsed.action === "stop" ? root.t("serviceStoppedToast") : root.t("serviceStarted"),
                        false
                    );
                }
            );
            return;
        }

        runControlCommand(
            [helper, "toggle", serviceUnit, serviceScope, rpcPortal],
            parsed => {
                showToast(
                    root.t("title"),
                    parsed.action === "stop" ? root.t("serviceStoppedToast") : root.t("serviceStarted"),
                    false
                );
            }
        );
    }

    function restartService() {
        const args = backendMode === "managed"
            ? [helper, "managed-restart", activeProfileId, managedRpcPortal, serviceUnit, serviceScope]
            : [helper, "restart", serviceUnit, serviceScope, rpcPortal];
        runControlCommand(args, () => {
            showToast(root.t("title"), root.t("serviceRestarted"), false);
        });
    }

    function connectProfile(profileId) {
        setBackendMode("managed");
        EasyTierBus.activeProfileId = profileId;
        runControlCommand(
            [helper, "managed-start", profileId, managedRpcPortal, serviceUnit, serviceScope],
            () => {
                showToast(root.t("title"), root.t("serviceStarted"), false);
                if (root._activePopupItem)
                    root._activePopupItem.currentTab = 0;
            }
        );
    }

    function selectProfile(profileId) {
        Proc.runCommand(
            "easytier.profileSelect",
            [helper, "profile-select", profileId],
            (output, exitCode) => {
                if (exitCode !== 0)
                    return;
                try {
                    const parsed = JSON.parse(output);
                    if (parsed && parsed.ok === true) {
                        EasyTierBus.activeProfileId = parsed.activeProfileId || profileId;
                        EasyTierBus.profiles = Array.isArray(parsed.profiles) ? parsed.profiles : EasyTierBus.profiles;
                    }
                } catch (e) {}
            },
            0,
            5000
        );
    }

    function saveProfile(profileObj, connectImmediately) {
        if (profileSaveProcess.running)
            return;
        profileSaveProcess.pendingPayload = JSON.stringify(profileObj);
        profileSaveProcess.connectImmediately = connectImmediately === true;
        profileSaveProcess.stdinEnabled = true;
        profileSaveProcess.running = true;
    }

    function deleteProfile(profileId) {
        Proc.runCommand(
            "easytier.profileDelete",
            [helper, "profile-delete", profileId],
            (output, exitCode) => {
                let parsed = null;
                try {
                    parsed = JSON.parse(output);
                } catch (e) {}
                if (exitCode === 0 && parsed && parsed.ok === true) {
                    EasyTierBus.profiles = Array.isArray(parsed.profiles) ? parsed.profiles : [];
                    EasyTierBus.activeProfileId = parsed.activeProfileId || "";
                    showToast(root.t("title"), root.t("profileDeleted"), false);
                    refresh();
                }
            },
            0,
            5000
        );
    }

    function addConnector(url) {
        runControlCommand(
            [helper, "connector-add", url, effectiveRpcPortal, serviceUnit, serviceScope],
            () => showToast(root.t("title"), root.t("connectorAdded") + ": " + url, false)
        );
    }

    function removeConnector(url) {
        runControlCommand(
            [helper, "connector-remove", url, effectiveRpcPortal, serviceUnit, serviceScope],
            () => showToast(root.t("title"), root.t("connectorRemoved") + ": " + url, false)
        );
    }

    Process {
        id: profileSaveProcess
        property string pendingPayload: ""
        property bool connectImmediately: false
        command: [root.helper, "profile-save", "-"]
        stdinEnabled: true

        onStarted: {
            write(pendingPayload);
            stdinEnabled = false;
        }

        stdout: StdioCollector {
            id: profileSaveStdout
        }

        onExited: (exitCode, exitStatus) => {
            let parsed = null;
            try {
                parsed = JSON.parse(profileSaveStdout.text);
            } catch (e) {}
            if (exitCode === 0 && parsed && parsed.ok === true) {
                EasyTierBus.profiles = Array.isArray(parsed.profiles) ? parsed.profiles : [];
                EasyTierBus.activeProfileId = parsed.id || parsed.activeProfileId || "";
                root.showToast(root.t("title"), root.t("profileSaved"), false);
                if (connectImmediately && parsed.id) {
                    root.connectProfile(parsed.id);
                } else {
                    root.refresh();
                }
            } else {
                const errMsg = (parsed && parsed.error) ? String(parsed.error) : root.t("controlFailed");
                root.showToast(root.t("title"), errMsg, true);
            }
        }
    }

    // [Timers]
    Timer {
        interval: 0
        running: root.isLiveInstance && !root._ipcReady
        onTriggered: root._ipcReady = true
    }

    Timer {
        id: pollTimer
        interval: root.effectivePollMs
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
                backendMode: root.backendMode,
                rpcPortal: root.effectiveRpcPortal,
                connected: root.connected,
                noInstance: root.noInstance,
                serviceActive: root.serviceActive,
                managedActive: root.managedActive,
                activeProfileId: root.activeProfileId,
                ipv4: root.selfNode ? root.selfNode.ipv4 : "",
                networkName: root.selfNode ? root.selfNode.networkName : "",
                peers: root.counts.total || 0,
                p2p: root.counts.p2p || 0,
                relay: root.counts.relay || 0,
                connectors: root.connectors.length
            });
        }

        function toggle(): string {
            root.toggleService();
            return "TOGGLE_REQUESTED";
        }

        function start(): string {
            if (root.backendMode === "managed")
                root.runControlCommand([root.helper, "managed-start", root.activeProfileId, root.managedRpcPortal, root.serviceUnit, root.serviceScope], null);
            else
                root.runControlCommand([root.helper, "start", root.serviceUnit, root.serviceScope, root.rpcPortal], null);
            return "START_REQUESTED";
        }

        function stop(): string {
            if (root.backendMode === "managed")
                root.runControlCommand([root.helper, "managed-stop", "", root.managedRpcPortal, root.serviceUnit, root.serviceScope], null);
            else
                root.runControlCommand([root.helper, "stop", root.serviceUnit, root.serviceScope, root.rpcPortal], null);
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
        if (!root.connected) {
            if (root.noInstance && root.backendActive)
                return root.t("noInstanceHint");
            return root.backendActive ? root.t("rpcUnreachable") : root.t("disconnected");
        }
        return root.t("onlineCount", root.counts.total || 0);
    }
    ccWidgetIsActive: root.connected || root.backendActive
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
    popoutWidth: 456

    popoutContent: Component {
        PopoutComponent {
            id: popup

            property int currentTab: 0

            headerText: root.t("title")
            detailsText: ""

            function jumpToProfiles(createNew) {
                currentTab = 1;
                if (createNew)
                    profilesTab.openNewEditor();
            }

            readonly property int maxViewportHeight: {
                const screenH = root.parentScreen && root.parentScreen.height > 0 ? root.parentScreen.height : 1080;
                const reserve = Math.max(root.barThickness + root.barSpacing, 56) + 140;
                return Math.max(280, Math.min(640, Math.floor(screenH - reserve)));
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

            Component.onCompleted: {
                root._activePopupItem = popup;
                if (EasyTierBus.profiles.length === 0)
                    root.loadProfiles();
            }

            Component.onDestruction: {
                if (root._activePopupItem === popup)
                    root._activePopupItem = null;
            }

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
                        checked: root.connected || root.backendActive
                        toggling: root.busy
                        enabled: root.cliAvailable && !root.busy
                        Accessible.name: (root.connected || root.backendActive) ? root.t("disableService") : root.t("enableService")
                        onToggled: root.toggleService()
                    }

                    Item {
                        width: Theme.spacingXS
                        height: 1
                    }

                    DActionButton {
                        buttonSize: Theme.buttonHeightXS
                        iconSize: Theme.iconSizeSmall
                        iconName: "restart_alt"
                        iconColor: Theme.primary
                        backgroundColor: Theme.ccPillInactiveBg
                        enabled: (root.connected || root.backendActive) && !root.busy
                        tooltipText: root.t("restart")
                        onClicked: root.restartService()
                    }

                    DActionButton {
                        buttonSize: Theme.buttonHeightXS
                        iconSize: Theme.iconSizeSmall
                        iconName: "refresh"
                        iconColor: Theme.primary
                        backgroundColor: Theme.ccPillInactiveBg
                        enabled: !root.busy
                        tooltipText: root.t("refresh")
                        onClicked: {
                            root.loadProfiles();
                            root.refresh();
                        }
                    }
                }
            }

            DTabBar {
                width: parent.width
                currentIndex: popup.currentTab
                tabHeight: Theme.buttonHeightS
                spacing: Theme.spacingXS
                model: [
                    { icon: "hub", text: root.t("tabTopology") },
                    { icon: "tune", text: root.t("tabProfiles") },
                    { icon: "cable", text: root.t("tabConnectors") }
                ]
                onTabClicked: index => {
                    popup.currentTab = index;
                }
            }

            Item {
                width: parent.width
                height: Theme.spacingXS
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

                    TopologyView {
                        visible: popup.currentTab === 0
                        width: parent.width
                        lang: root.lang
                        backendMode: root.backendMode
                        serviceUnit: root.serviceUnit
                        activeProfileName: root.activeProfileName
                        profileCount: root.profiles.length
                        cliAvailable: root.cliAvailable
                        busy: root.busy
                        connected: root.connected
                        backendActive: root.backendActive
                        noInstance: root.noInstance && root.backendActive
                        selfNode: root.selfNode
                        peers: root.peers
                        routes: root.routes
                        traffic: root.traffic
                        counts: root.counts
                        copyField: root.copyField
                        showRoutes: root.showRoutes
                        onCopyRequested: value => root.copyText(value)
                        onOpenProfilesTab: createNew => popup.jumpToProfiles(createNew)
                    }

                    ProfilesView {
                        id: profilesTab
                        visible: popup.currentTab === 1
                        width: parent.width
                        lang: root.lang
                        backendMode: root.backendMode
                        serviceUnit: root.serviceUnit
                        profiles: root.profiles
                        activeProfileId: root.activeProfileId
                        busy: root.busy
                        connected: root.connected
                        managedActive: root.managedActive
                        onBackendModeSelected: mode => root.setBackendMode(mode)
                        onSelectProfileRequested: id => root.selectProfile(id)
                        onConnectProfileRequested: id => root.connectProfile(id)
                        onDeleteProfileRequested: id => root.deleteProfile(id)
                        onSaveProfileRequested: (profileObj, connectNow) => root.saveProfile(profileObj, connectNow)
                        onCopyTomlRequested: tomlText => root.copyToml(tomlText)
                    }

                    ConnectorsView {
                        visible: popup.currentTab === 2
                        width: parent.width
                        lang: root.lang
                        connected: root.connected
                        busy: root.busy
                        connectors: root.connectors
                        onAddConnectorRequested: url => root.addConnector(url)
                        onRemoveConnectorRequested: url => root.removeConnector(url)
                        onCopyRequested: value => root.copyText(value)
                    }
                }
            }
        }
    }
}
