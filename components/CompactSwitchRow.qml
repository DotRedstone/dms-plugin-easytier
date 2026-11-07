import QtQuick
import qs.Common
import qs.DCommon.Widgets

// [Compact Toggle Row]
Rectangle {
    id: root

    property string label: ""
    property string subtitle: ""
    property bool checked: false
    property bool rowEnabled: true

    signal toggled(bool checked)

    height: Math.max(38, textCol.implicitHeight + Theme.spacingS * 2)
    radius: Theme.cornerRadiusM
    color: Theme.ccIconBoxInactiveBg
    opacity: rowEnabled ? 1.0 : 0.48

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingS + 2
        anchors.rightMargin: Theme.spacingS
        spacing: Theme.spacingS

        Column {
            id: textCol
            width: parent.width - switchCtrl.width - Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StyledText {
                width: parent.width
                text: root.label
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            StyledText {
                visible: root.subtitle.length > 0
                width: parent.width
                text: root.subtitle
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall - 1
                wrapMode: Text.WordWrap
            }
        }

        DToggle {
            id: switchCtrl
            anchors.verticalCenter: parent.verticalCenter
            checked: root.checked
            enabled: root.rowEnabled
            onToggled: isChecked => root.toggled(isChecked)
        }
    }
}
