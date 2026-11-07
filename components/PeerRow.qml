import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../UiText.js" as UiText

// [Peer List Row]
Rectangle {
    id: root

    required property var modelData
    property string lang: "zh_CN"
    property string copyField: "ip"
    property bool expanded: false

    signal toggleExpand
    signal copyRequested(string value, string label)

    readonly property bool isP2p: modelData.mode === "p2p"
    readonly property bool isRelay: modelData.mode === "relay"
    readonly property color modeColor: isP2p ? Theme.success : (isRelay ? Theme.warning : Theme.primary)
    readonly property string modeLabel: isP2p ? "P2P" : (isRelay ? "Relay" : (modelData.cost || "Mesh"))
    readonly property string latencyDisplay: UiText.formatLatency(modelData.latencyMs, modelData.latencyText)
    readonly property color latencyColor: {
        const ms = Number(modelData.latencyMs);
        if (!isFinite(ms) || ms < 0)
            return Theme.surfaceVariantText;
        if (ms <= 50)
            return Theme.success;
        if (ms <= 150)
            return Theme.warning;
        return Theme.error;
    }
    readonly property string copyTargetValue: copyField === "hostname"
        ? (modelData.hostname || modelData.ipv4 || "")
        : (modelData.ipv4 || modelData.hostname || "")
    readonly property string copyTooltipText: copyField === "hostname"
        ? UiText.tr(lang, "copyHostname")
        : UiText.tr(lang, "copyIp")

    readonly property int baseHeight: Theme.buttonHeightM
    readonly property int detailHeight: Theme.buttonHeightS + Theme.spacingXS

    width: parent ? parent.width : 360
    height: baseHeight + (expanded ? detailHeight : 0)
    radius: Theme.cornerRadiusM
    color: Theme.ccPillInactiveBg
    clip: true

    StyledButton {
        id: rowButton
        width: parent.width
        height: root.baseHeight
        radius: Theme.cornerRadiusM
        onClicked: root.toggleExpand()

        // Contained rounded status bar
        Rectangle {
            id: modeIndicator
            width: Theme.spacingXS
            height: Theme.buttonHeightXXS
            radius: Theme.cornerRadiusXXS
            color: root.modeColor
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: modeIndicator.right
            anchors.leftMargin: Theme.spacingS
            anchors.right: rightCluster.left
            anchors.rightMargin: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXXS

            Row {
                width: parent.width
                spacing: Theme.spacingXS

                StyledText {
                    text: root.modelData.hostname || root.modelData.ipv4 || "peer"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, Math.max(80, parent.width - badgeRect.width - Theme.spacingS))
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    id: badgeRect
                    height: badgeLabel.implicitHeight + Theme.spacingXS
                    width: badgeLabel.implicitWidth + Theme.spacingS
                    radius: Theme.cornerRadiusFull
                    color: Qt.rgba(root.modeColor.r, root.modeColor.g, root.modeColor.b, 0.16)
                    anchors.verticalCenter: parent.verticalCenter

                    StyledText {
                        id: badgeLabel
                        anchors.centerIn: parent
                        text: root.modeLabel
                        color: root.modeColor
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
                    const parts = [];
                    if (root.modelData.ipv4)
                        parts.push(root.modelData.ipv4);
                    if (root.modelData.proto && root.modelData.proto !== "-")
                        parts.push(String(root.modelData.proto).toUpperCase());
                    if (root.modelData.rxText && root.modelData.rxText !== "-")
                        parts.push("↓" + root.modelData.rxText + " ↑" + (root.modelData.txText || "-"));
                    return parts.join(" • ");
                }
            }
        }

        Row {
            id: rightCluster
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS

            StyledText {
                text: root.latencyDisplay
                color: root.latencyColor
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }

            DActionButton {
                buttonSize: Theme.buttonHeightXXS
                iconSize: Theme.iconSizeSmall
                iconName: "content_copy"
                iconColor: Theme.surfaceText
                backgroundColor: "transparent"
                enabled: root.copyTargetValue.length > 0
                tooltipText: root.copyTooltipText
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.copyRequested(root.copyTargetValue, root.copyTargetValue)
            }
        }

        StateLayer {
            control: rowButton
            stateColor: Theme.primary
        }
        FocusRing {
            visible: rowButton.visualFocus
        }
    }

    Rectangle {
        visible: root.expanded
        x: Theme.spacingM
        y: root.baseHeight
        width: parent.width - Theme.spacingM * 2
        height: 1
        color: Theme.outlineVariant
        opacity: 0.35
    }

    Column {
        visible: root.expanded
        x: Theme.spacingM
        y: root.baseHeight + Theme.spacingXS
        width: parent.width - Theme.spacingM * 2
        spacing: Theme.spacingXXS

        StyledText {
            width: parent.width
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
            text: "NAT: " + (root.modelData.natType || "Unknown")
                + "  •  Loss: " + (root.modelData.lossText || "-")
                + "  •  Cost: " + (root.modelData.cost || "-")
        }

        StyledText {
            width: parent.width
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
            text: "ID: " + (root.modelData.id || "-")
                + (root.modelData.version ? ("  •  v" + root.modelData.version) : "")
        }
    }
}
