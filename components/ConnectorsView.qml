import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../UiText.js" as UiText

// [Dynamic Connectors Tab View]
Column {
    id: root

    property string lang: "zh_CN"
    property bool connected: false
    property bool busy: false
    property var connectors: []

    signal addConnectorRequested(string url)
    signal removeConnectorRequested(string url)
    signal copyRequested(string value)

    spacing: Theme.spacingS

    function t(key, arg1) {
        return UiText.tr(root.lang, key, arg1);
    }

    function submitConnector() {
        const raw = urlField.text.trim();
        if (!raw || raw.indexOf("://") < 0)
            return;
        urlField.text = "";
        root.addConnectorRequested(raw);
    }

    // [Offline State]
    Rectangle {
        visible: !root.connected
        width: parent.width
        height: offlineLabel.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadiusM
        color: Theme.ccPillInactiveBg

        StyledText {
            id: offlineLabel
            x: Theme.spacingM
            y: Theme.spacingL
            width: parent.width - Theme.spacingM * 2
            text: root.t("connectorsOfflineHint")
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // [Add Connector Bar]
    Row {
        visible: root.connected
        width: parent.width
        spacing: Theme.spacingXS

        DTextField {
            id: urlField
            width: parent.width - addBtn.width - Theme.spacingXS
            placeholderText: root.t("connectorAddPlaceholder")
            showClearButton: true
            enabled: !root.busy
            onAccepted: root.submitConnector()
        }

        DActionButton {
            id: addBtn
            buttonSize: Theme.buttonHeightXS + Theme.spacingXS
            iconSize: Theme.iconSizeMedium
            iconName: "add"
            iconColor: Theme.onPrimary
            backgroundColor: Theme.primary
            enabled: !root.busy && urlField.text.trim().indexOf("://") > 0
            tooltipText: root.t("connectorAddBtn")
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.submitConnector()
        }
    }

    // [Empty Connectors State]
    Rectangle {
        visible: root.connected && root.connectors.length === 0
        width: parent.width
        height: Theme.buttonHeightS + Theme.spacingXS
        radius: Theme.cornerRadiusM
        color: Theme.ccPillInactiveBg

        StyledText {
            anchors.centerIn: parent
            text: root.t("noConnectors")
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    // [Connectors List]
    Column {
        visible: root.connected && root.connectors.length > 0
        width: parent.width
        spacing: Theme.spacingXS

        Repeater {
            model: root.connectors

            delegate: Rectangle {
                id: connRow
                required property var modelData

                readonly property color stateColor: {
                    if (modelData.state === "connected")
                        return Theme.success;
                    if (modelData.state === "connecting")
                        return Theme.warning;
                    return Theme.surfaceVariantText;
                }
                readonly property string stateText: {
                    if (modelData.state === "connected")
                        return root.t("connConnected");
                    if (modelData.state === "connecting")
                        return root.t("connConnecting");
                    return root.t("connDisconnected");
                }

                width: parent ? parent.width : 378
                height: Theme.buttonHeightM - Theme.spacingXS
                radius: Theme.cornerRadiusM
                color: Theme.ccPillInactiveBg

                Rectangle {
                    id: dot
                    width: Theme.spacingS
                    height: Theme.spacingS
                    radius: Theme.cornerRadiusFull
                    color: connRow.stateColor
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.left: dot.right
                    anchors.leftMargin: Theme.spacingS
                    anchors.right: connActions.left
                    anchors.rightMargin: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingXXS

                    StyledText {
                        width: parent.width
                        text: connRow.modelData.url || ""
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        width: parent.width
                        color: connRow.stateColor
                        font.pixelSize: Theme.fontSizeSmall - 1
                        text: (connRow.modelData.proto ? String(connRow.modelData.proto).toUpperCase() + " • " : "") + connRow.stateText
                    }
                }

                Row {
                    id: connActions
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingXXS

                    DActionButton {
                        buttonSize: Theme.buttonHeightXXS
                        iconSize: Theme.iconSizeSmall
                        iconName: "content_copy"
                        iconColor: Theme.surfaceText
                        backgroundColor: "transparent"
                        tooltipText: root.t("copyUrl")
                        onClicked: root.copyRequested(connRow.modelData.url || "")
                    }

                    DActionButton {
                        buttonSize: Theme.buttonHeightXXS
                        iconSize: Theme.iconSizeSmall
                        iconName: "delete_outline"
                        iconColor: Theme.error
                        backgroundColor: "transparent"
                        enabled: !root.busy
                        tooltipText: root.t("connectorRemoveBtn")
                        onClicked: root.removeConnectorRequested(connRow.modelData.url || "")
                    }
                }
            }
        }
    }
}
