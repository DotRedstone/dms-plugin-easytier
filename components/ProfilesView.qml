import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../UiText.js" as UiText
import "../AssistantConfig.js" as AssistantConfig

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
    property bool editing: false

    signal backendModeSelected(string mode)
    signal selectProfileRequested(string profileId)
    signal connectProfileRequested(string profileId)
    signal deleteProfileRequested(string profileId)
    signal saveProfileRequested(var profileObj, bool connectImmediately)
    signal copyTomlRequested(string tomlText)

    spacing: Theme.spacingS

    function t(key, arg1) {
        return UiText.tr(root.lang, key, arg1);
    }

    function openNewEditor() {
        profileEditor.loadNew();
        editing = true;
    }

    function openEditProfile(prof) {
        if (!prof)
            return;
        profileEditor.loadProfile(prof);
        editing = true;
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
        height: Theme.buttonHeightXS

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
            buttonHeight: Theme.buttonHeightXXS
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

                width: parent ? parent.width : 412
                height: Theme.buttonHeightM + Theme.spacingXS
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
                        size: Theme.iconSizeSmall
                        color: profCard.isSelected ? Theme.primary : Theme.surfaceVariantText
                    }

                    Column {
                        anchors.left: radioIcon.right
                        anchors.leftMargin: Theme.spacingS
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXXS

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
                                const mode = profCard.modelData.configMode || "manual";
                                const flags = profCard.modelData.flags || {};
                                const isNoTun = flags.noTun === true || profCard.modelData.noTun === true;
                                if (mode === "uri") {
                                    tags.push(root.t("tagUri"));
                                } else {
                                    if (mode === "standalone")
                                        tags.push(root.t("tagStandalone"));
                                    if (profCard.modelData.networkName)
                                        tags.push(profCard.modelData.networkName);
                                    if (!isNoTun)
                                        tags.push(profCard.modelData.dhcp !== false ? root.t("tagDhcp") : (profCard.modelData.ipv4 || "Static"));
                                    const pCount = Array.isArray(profCard.modelData.peers) ? profCard.modelData.peers.length : 0;
                                    if (mode === "manual" && pCount > 0)
                                        tags.push(root.t("peersCountTag", pCount));
                                    const cCount = Array.isArray(profCard.modelData.proxyCidrs) ? profCard.modelData.proxyCidrs.length : 0;
                                    if (cCount > 0)
                                        tags.push(root.t("proxyCountTag", cCount));
                                    const pfCount = Array.isArray(profCard.modelData.portForwards) ? profCard.modelData.portForwards.length : 0;
                                    if (pfCount > 0)
                                        tags.push(root.t("pfCountTag", pfCount));
                                    if (profCard.modelData.vpnPortalEnabled === true)
                                        tags.push(root.t("tagVpn"));
                                }
                                if (isNoTun)
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
                    spacing: Theme.spacingXXS

                    DActionButton {
                        buttonSize: Theme.buttonHeightXXS
                        iconSize: Theme.iconSizeSmall
                        iconName: profCard.isRunningThis ? "sync" : "play_arrow"
                        iconColor: Theme.primary
                        backgroundColor: "transparent"
                        enabled: !root.busy
                        tooltipText: profCard.isRunningThis ? root.t("reconnectNow") : root.t("connectNow")
                        onClicked: root.connectProfileRequested(profCard.modelData.id)
                    }

                    DActionButton {
                        buttonSize: Theme.buttonHeightXXS
                        iconSize: Theme.iconSizeSmall
                        iconName: "code"
                        iconColor: Theme.surfaceVariantText
                        backgroundColor: "transparent"
                        tooltipText: root.t("copyToml")
                        onClicked: root.copyTomlRequested(AssistantConfig.generateToml(profCard.modelData, false))
                    }

                    DActionButton {
                        buttonSize: Theme.buttonHeightXXS
                        iconSize: Theme.iconSizeSmall
                        iconName: "edit"
                        iconColor: Theme.surfaceText
                        backgroundColor: "transparent"
                        enabled: !root.busy
                        tooltipText: root.t("editProfile")
                        onClicked: root.openEditProfile(profCard.modelData)
                    }

                    DActionButton {
                        buttonSize: Theme.buttonHeightXXS
                        iconSize: Theme.iconSizeSmall
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

    // [Official Assistant-Style Profile Editor]
    ProfileEditor {
        id: profileEditor
        visible: root.editing
        width: parent.width
        lang: root.lang
        busy: root.busy
        onCancelled: root.editing = false
        onCopyTomlRequested: tomlText => root.copyTomlRequested(tomlText)
        onSaveRequested: (profileObj, connectNow) => {
            root.editing = false;
            root.saveProfileRequested(profileObj, connectNow);
        }
    }
}
