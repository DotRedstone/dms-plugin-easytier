import QtQuick
import qs.Common
import qs.DCommon.Widgets

// [Inline Option Chip Selector]
Column {
    id: root

    property string label: ""
    property var options: []
    property string currentValue: ""
    property bool fieldEnabled: true

    signal valueSelected(string value)

    spacing: 4
    opacity: fieldEnabled ? 1.0 : 0.48

    StyledText {
        visible: root.label.length > 0
        width: parent.width
        text: root.label
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
    }

    Flow {
        width: parent.width
        spacing: 6

        Repeater {
            model: Array.isArray(root.options) ? root.options : []

            delegate: StyledButton {
                readonly property bool selected: String(modelData.value) === root.currentValue
                height: 28
                width: optText.implicitWidth + 18
                radius: 14
                color: selected ? Theme.primary : Theme.ccIconBoxInactiveBg
                enabled: root.fieldEnabled
                onClicked: {
                    if (!selected)
                        root.valueSelected(String(modelData.value));
                }

                StyledText {
                    id: optText
                    anchors.centerIn: parent
                    text: String(modelData.label || modelData.value || "")
                    color: parent.selected ? Theme.onPrimary : Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.weight: parent.selected ? Font.Medium : Font.Normal
                }
            }
        }
    }
}
