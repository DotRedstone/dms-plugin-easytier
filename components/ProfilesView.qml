import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../UiText.js" as UiText

// [Profiles & Backend Mode Tab View]
Column {
    id: root

    property string lang: "zh_CN"
    property string backendMode: "managed"
    property string serviceUnit: "easytier.service"
    property var profiles: []
    property string activeProfileId: ""
    property bool busy: false
    property bool connected: false
    property bool managedActive: false

    // Editor state
    property bool editing: false
    property string editId: ""
    property string editName: ""
    property string editConfigMode: "manual"
    property string editConfigServer: ""
    property string editNetworkName: ""
    property string editNetworkSecret: ""
    property bool editDhcp: true
    property string editIpv4: ""
    property string editHostname: ""
    property var editPeers: []
    property var editProxyCidrs: []
    property bool editNoTun: false

    signal backendModeSelected(string mode)
    signal selectProfileRequested(string profileId)
    signal connectProfileRequested(string profileId)
    signal deleteProfileRequested(string profileId)
    signal saveProfileRequested(var profileObj, bool connectImmediately)

    spacing: Theme.spacingS

    function t(key, arg1) {
        return UiText.tr(root.lang, key, arg1);
    }

    function openNewEditor() {
        editId = "";
        editName = "";
        editConfigMode = "manual";
        editConfigServer = "";
        editNetworkName = "";
        editNetworkSecret = "";
        editDhcp = true;
        editIpv4 = "";
        editHostname = "";
        editPeers = [];
        editProxyCidrs = [];
        editNoTun = false;
        peerField.text = "";
        cidrField.text = "";
        editing = true;
    }

    function openEditProfile(prof) {
        if (!prof)
            return;
        editId = prof.id || "";
        editName = prof.name || "";
        editConfigMode = prof.configMode === "uri" ? "uri" : "manual";
        editConfigServer = prof.configServer || "";
        editNetworkName = prof.networkName || "";
        editNetworkSecret = prof.networkSecret || "";
        editDhcp = prof.dhcp !== false;
        editIpv4 = prof.ipv4 || "";
        editHostname = prof.hostname || "";
        editPeers = Array.isArray(prof.peers) ? prof.peers.slice() : [];
        editProxyCidrs = Array.isArray(prof.proxyCidrs) ? prof.proxyCidrs.slice() : [];
        editNoTun = prof.noTun === true;
        peerField.text = "";
        cidrField.text = "";
        editing = true;
    }

    function appendTokens(currentList, rawInput) {
        const tokens = String(rawInput || "")
            .split(/[\s,]+/)
            .map(s => s.trim())
            .filter(s => s.length > 0);
        if (tokens.length === 0)
            return currentList;
        const next = currentList.slice();
        for (let i = 0; i < tokens.length; i++) {
            if (next.indexOf(tokens[i]) < 0)
                next.push(tokens[i]);
        }
        return next;
    }

    function commitPendingPeer() {
        if (peerField.text.trim().length > 0) {
            editPeers = appendTokens(editPeers, peerField.text);
            peerField.text = "";
        }
    }

    function commitPendingCidr() {
        if (cidrField.text.trim().length > 0) {
            editProxyCidrs = appendTokens(editProxyCidrs, cidrField.text);
            cidrField.text = "";
        }
    }

    function buildPayload() {
        commitPendingPeer();
        commitPendingCidr();
        return {
            id: editId,
            name: nameField.text.trim(),
            configMode: editConfigMode,
            configServer: configServerField.text.trim(),
            networkName: networkNameField.text.trim(),
            networkSecret: networkSecretField.text,
            dhcp: editDhcp,
            ipv4: ipv4Field.text.trim(),
            hostname: hostnameField.text.trim(),
            peers: editPeers.slice(),
            proxyCidrs: editProxyCidrs.slice(),
            noTun: editNoTun
        };
    }

    readonly property bool canSaveForm: {
        const hasName = nameField.text.trim().length > 0;
        if (!hasName)
            return false;
        if (editConfigMode === "uri")
            return configServerField.text.trim().length > 0;
        return networkNameField.text.trim().length > 0;
    }

    // [Backend Mode Switcher]
    Rectangle {
        visible: !root.editing
        width: parent.width
        height: modeCol.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadiusM
        color: Theme.ccPillInactiveBg

        Column {
            id: modeCol
            x: Theme.spacingM
            y: Theme.spacingM
            width: parent.width - Theme.spacingM * 2
            spacing: Theme.spacingXS

            StyledText {
                text: root.t("runModeLabel")
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            DFilterChips {
                width: parent.width
                currentIndex: root.backendMode === "systemd" ? 1 : 0
                showCounts: false
                model: [
                    { label: root.t("modeManaged") },
                    { label: root.t("modeSystemd") }
                ]
                onSelectionChanged: index => {
                    root.backendModeSelected(index === 1 ? "systemd" : "managed");
                }
            }
        }
    }

    // [Systemd Mode Hint Banner]
    Rectangle {
        visible: !root.editing && root.backendMode === "systemd"
        width: parent.width
        height: sysHintText.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadiusM
        color: Theme.ccPillInactiveBg

        StyledText {
            id: sysHintText
            x: Theme.spacingM
            y: Theme.spacingM
            width: parent.width - Theme.spacingM * 2
            text: root.t("systemdModeHint", root.serviceUnit)
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
        }
    }

    // [Saved Profiles List Header]
    Item {
        visible: !root.editing && root.backendMode === "managed"
        width: parent.width
        height: 32

        StyledText {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter
            text: root.t("savedProfiles")
            color: Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.Medium
        }

        DButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            buttonHeight: 30
            iconName: "add"
            text: root.t("newProfile")
            enabled: !root.busy
            onClicked: root.openNewEditor()
        }
    }

    // [Empty Profiles State]
    Rectangle {
        visible: !root.editing && root.backendMode === "managed" && root.profiles.length === 0
        width: parent.width
        height: emptyProfText.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadiusM
        color: Theme.ccPillInactiveBg

        StyledText {
            id: emptyProfText
            x: Theme.spacingM
            y: Theme.spacingL
            width: parent.width - Theme.spacingM * 2
            text: root.t("noProfilesYet")
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // [Saved Profiles Cards]
    Column {
        visible: !root.editing && root.backendMode === "managed" && root.profiles.length > 0
        width: parent.width
        spacing: Theme.spacingXS

        Repeater {
            model: root.profiles

            delegate: Rectangle {
                id: profCard
                required property var modelData
                readonly property bool isSelected: modelData.id === root.activeProfileId
                readonly property bool isRunningThis: isSelected && root.managedActive

                width: parent ? parent.width : 378
                height: 62
                radius: Theme.cornerRadiusM
                color: isSelected ? Theme.secondaryContainer : Theme.ccPillInactiveBg
                border.width: isRunningThis ? 1.5 : 0
                border.color: Theme.primary

                StyledButton {
                    id: selectArea
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: actionsRow.left
                    anchors.rightMargin: Theme.spacingXS
                    radius: Theme.cornerRadiusM
                    onClicked: root.selectProfileRequested(profCard.modelData.id)

                    DIcon {
                        id: radioIcon
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        name: profCard.isSelected ? "radio_button_checked" : "radio_button_unchecked"
                        size: 18
                        color: profCard.isSelected ? Theme.primary : Theme.surfaceVariantText
                    }

                    Column {
                        anchors.left: radioIcon.right
                        anchors.leftMargin: Theme.spacingS
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            width: parent.width
                            text: profCard.modelData.name || "Profile"
                            color: profCard.isSelected ? Theme.onSecondaryContainer : Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            width: parent.width
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
                            text: {
                                const tags = [];
                                if (profCard.modelData.configMode === "uri") {
                                    tags.push(root.t("tagUri"));
                                } else {
                                    if (profCard.modelData.networkName)
                                        tags.push(profCard.modelData.networkName);
                                    tags.push(profCard.modelData.dhcp !== false ? root.t("tagDhcp") : (profCard.modelData.ipv4 || "Static"));
                                    const pCount = Array.isArray(profCard.modelData.peers) ? profCard.modelData.peers.length : 0;
                                    if (pCount > 0)
                                        tags.push(root.t("peersCountTag", pCount));
                                }
                                if (profCard.modelData.noTun === true)
                                    tags.push(root.t("tagNoTun"));
                                return tags.join(" • ");
                            }
                        }
                    }

                    StateLayer {
                        control: selectArea
                        stateColor: Theme.primary
                    }
                }

                Row {
                    id: actionsRow
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    DActionButton {
                        buttonSize: 30
                        iconSize: 17
                        iconName: profCard.isRunningThis ? "sync" : "play_arrow"
                        iconColor: Theme.primary
                        backgroundColor: "transparent"
                        enabled: !root.busy
                        tooltipText: profCard.isRunningThis ? root.t("reconnectNow") : root.t("connectNow")
                        onClicked: root.connectProfileRequested(profCard.modelData.id)
                    }

                    DActionButton {
                        buttonSize: 30
                        iconSize: 16
                        iconName: "edit"
                        iconColor: Theme.surfaceText
                        backgroundColor: "transparent"
                        enabled: !root.busy
                        tooltipText: root.t("editProfile")
                        onClicked: root.openEditProfile(profCard.modelData)
                    }

                    DActionButton {
                        buttonSize: 30
                        iconSize: 16
                        iconName: "delete_outline"
                        iconColor: Theme.error
                        backgroundColor: "transparent"
                        enabled: !root.busy
                        tooltipText: root.t("deleteProfile")
                        onClicked: root.deleteProfileRequested(profCard.modelData.id)
                    }
                }
            }
        }
    }

    // [Inline Profile Editor Card]
    Rectangle {
        visible: root.editing
        width: parent.width
        height: editorCol.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadiusL
        color: Theme.ccPillInactiveBg

        Column {
            id: editorCol
            x: Theme.spacingM
            y: Theme.spacingM
            width: parent.width - Theme.spacingM * 2
            spacing: Theme.spacingS

            StyledText {
                text: root.editId.length > 0 ? root.t("editProfile") : root.t("newProfile")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
            }

            // Profile Name
            StyledText {
                text: root.t("profileName")
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
            }
            DTextField {
                id: nameField
                width: parent.width
                text: root.editName
                placeholderText: root.t("profileNamePlaceholder")
                showClearButton: true
            }

            // Config Mode Chips
            DFilterChips {
                width: parent.width
                currentIndex: root.editConfigMode === "uri" ? 1 : 0
                showCounts: false
                model: [
                    { label: root.t("authModePassword") },
                    { label: root.t("authModeUri") }
                ]
                onSelectionChanged: index => {
                    root.editConfigMode = index === 1 ? "uri" : "manual";
                }
            }

            // URI Mode Field
            Column {
                visible: root.editConfigMode === "uri"
                width: parent.width
                spacing: Theme.spacingXS

                StyledText {
                    text: root.t("configServerUri")
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                }
                DTextField {
                    id: configServerField
                    width: parent.width
                    text: root.editConfigServer
                    placeholderText: root.t("configServerPlaceholder")
                    showClearButton: true
                }
            }

            // Standard Mode Fields
            Column {
                visible: root.editConfigMode === "manual"
                width: parent.width
                spacing: Theme.spacingS

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: root.t("networkName")
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    DTextField {
                        id: networkNameField
                        width: parent.width
                        text: root.editNetworkName
                        placeholderText: root.t("networkNamePlaceholder")
                        showClearButton: true
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: root.t("networkSecret")
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    DTextField {
                        id: networkSecretField
                        width: parent.width
                        text: root.editNetworkSecret
                        placeholderText: root.t("networkSecretPlaceholder")
                        echoMode: TextInput.Password
                        showPasswordToggle: true
                    }
                }

                // DHCP Toggle
                DToggle {
                    width: parent.width
                    text: root.t("dhcpAuto")
                    description: root.t("dhcpAutoDesc")
                    checked: root.editDhcp
                    onToggled: checked => {
                        root.editDhcp = checked;
                    }
                }

                // Static IPv4
                Column {
                    visible: !root.editDhcp
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: root.t("staticIpv4")
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    DTextField {
                        id: ipv4Field
                        width: parent.width
                        text: root.editIpv4
                        placeholderText: root.t("staticIpv4Placeholder")
                        showClearButton: true
                    }
                }

                // Initial Peers Builder
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: root.t("initialPeers")
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        DTextField {
                            id: peerField
                            width: parent.width - addPeerBtn.width - Theme.spacingXS
                            placeholderText: root.t("peerInputPlaceholder")
                            onAccepted: root.commitPendingPeer()
                        }

                        DActionButton {
                            id: addPeerBtn
                            buttonSize: 36
                            iconSize: 18
                            iconName: "add"
                            iconColor: Theme.onPrimary
                            backgroundColor: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: root.commitPendingPeer()
                        }
                    }

                    Flow {
                        visible: root.editPeers.length > 0
                        width: parent.width
                        spacing: Theme.spacingXS

                        Repeater {
                            model: root.editPeers

                            delegate: Rectangle {
                                required property var modelData
                                height: 24
                                width: Math.min(editorCol.width, chipPeerRow.implicitWidth + 12)
                                radius: 12
                                color: Theme.secondaryContainer

                                Row {
                                    id: chipPeerRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    StyledText {
                                        text: modelData
                                        color: Theme.onSecondaryContainer
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        elide: Text.ElideMiddle
                                        width: Math.min(implicitWidth, editorCol.width - 36)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    DActionButton {
                                        buttonSize: 18
                                        iconSize: 12
                                        iconName: "close"
                                        iconColor: Theme.onSecondaryContainer
                                        backgroundColor: "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        onClicked: {
                                            root.editPeers = root.editPeers.filter(item => item !== modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Subnet Proxy CIDRs Builder
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: root.t("subnetProxies")
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingXS

                        DTextField {
                            id: cidrField
                            width: parent.width - addCidrBtn.width - Theme.spacingXS
                            placeholderText: root.t("cidrInputPlaceholder")
                            onAccepted: root.commitPendingCidr()
                        }

                        DActionButton {
                            id: addCidrBtn
                            buttonSize: 36
                            iconSize: 18
                            iconName: "add"
                            iconColor: Theme.primary
                            backgroundColor: Theme.secondaryContainer
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: root.commitPendingCidr()
                        }
                    }

                    Flow {
                        visible: root.editProxyCidrs.length > 0
                        width: parent.width
                        spacing: Theme.spacingXS

                        Repeater {
                            model: root.editProxyCidrs

                            delegate: Rectangle {
                                required property var modelData
                                height: 24
                                width: chipCidrRow.implicitWidth + 12
                                radius: 12
                                color: Theme.secondaryContainer

                                Row {
                                    id: chipCidrRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    StyledText {
                                        text: modelData
                                        color: Theme.onSecondaryContainer
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    DActionButton {
                                        buttonSize: 18
                                        iconSize: 12
                                        iconName: "close"
                                        iconColor: Theme.onSecondaryContainer
                                        backgroundColor: "transparent"
                                        anchors.verticalCenter: parent.verticalCenter
                                        onClicked: {
                                            root.editProxyCidrs = root.editProxyCidrs.filter(item => item !== modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Custom Hostname
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: root.t("customHostname")
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    DTextField {
                        id: hostnameField
                        width: parent.width
                        text: root.editHostname
                        placeholderText: root.t("customHostnamePlaceholder")
                        showClearButton: true
                    }
                }
            }

            // No-TUN Toggle (applies to both Standard and URI modes)
            DToggle {
                width: parent.width
                text: root.t("noTunMode")
                description: root.t("noTunModeDesc")
                checked: root.editNoTun
                onToggled: checked => {
                    root.editNoTun = checked;
                }
            }

            // Form Action Buttons
            Row {
                width: parent.width
                spacing: Theme.spacingXS
                layoutDirection: Qt.RightToLeft

                DButton {
                    buttonHeight: 34
                    iconName: "bolt"
                    text: root.t("saveAndConnect")
                    enabled: root.canSaveForm && !root.busy
                    onClicked: {
                        const payload = root.buildPayload();
                        root.editing = false;
                        root.saveProfileRequested(payload, true);
                    }
                }

                DButton {
                    buttonHeight: 34
                    text: root.t("save")
                    backgroundColor: Theme.secondaryContainer
                    textColor: Theme.onSecondaryContainer
                    enabled: root.canSaveForm && !root.busy
                    onClicked: {
                        const payload = root.buildPayload();
                        root.editing = false;
                        root.saveProfileRequested(payload, false);
                    }
                }

                DButton {
                    buttonHeight: 34
                    text: root.t("cancel")
                    backgroundColor: "transparent"
                    textColor: Theme.surfaceVariantText
                    onClicked: root.editing = false
                }
            }
        }
    }
}
