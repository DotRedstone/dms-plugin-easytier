import QtQuick
import qs.Common
import qs.DCommon.Widgets

// [Repeatable Token & URL List Field]
Column {
    id: root

    property string label: ""
    property string description: ""
    property string placeholder: ""
    property var values: []
    property string presetLabel: ""
    property var presetValues: []
    property bool fieldEnabled: true

    signal valuesUpdated(var nextValues)

    spacing: 4
    opacity: fieldEnabled ? 1.0 : 0.48

    function appendItems(rawList) {
        const current = Array.isArray(root.values) ? root.values.slice() : [];
        let changed = false;
        for (let i = 0; i < rawList.length; i++) {
            const clean = String(rawList[i] || "").trim();
            if (clean.length > 0 && current.indexOf(clean) < 0) {
                current.push(clean);
                changed = true;
            }
        }
        if (changed)
            root.valuesUpdated(current);
    }

    function commitPending() {
        const raw = inputField.text.trim();
        if (!raw)
            return;
        const tokens = raw.split(/[\s,]+/).map(s => s.trim()).filter(s => s.length > 0);
        inputField.text = "";
        appendItems(tokens);
    }

    StyledText {
        visible: root.label.length > 0
        width: parent.width
        text: root.label
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
    }

    StyledText {
        visible: root.description.length > 0
        width: parent.width
        text: root.description
        color: Theme.surfaceVariantText
        font.pixelSize: Theme.fontSizeSmall - 1
        wrapMode: Text.WordWrap
    }

    Row {
        width: parent.width
        spacing: Theme.spacingXS

        DTextField {
            id: inputField
            width: parent.width - addBtn.width - Theme.spacingXS
            enabled: root.fieldEnabled
            placeholderText: root.placeholder
            anchors.verticalCenter: parent.verticalCenter
            onAccepted: root.commitPending()
        }

        DActionButton {
            id: addBtn
            buttonSize: 36
            iconSize: 18
            iconName: "add"
            iconColor: inputField.text.trim().length > 0 ? Theme.onPrimary : Theme.surfaceVariantText
            backgroundColor: inputField.text.trim().length > 0 ? Theme.primary : Theme.ccIconBoxInactiveBg
            enabled: root.fieldEnabled && inputField.text.trim().length > 0
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.commitPending()
        }
    }

    StyledButton {
        visible: root.presetLabel.length > 0 && Array.isArray(root.presetValues) && root.presetValues.length > 0
        height: 24
        width: presetText.implicitWidth + 16
        radius: 12
        color: Theme.secondaryContainer
        enabled: root.fieldEnabled
        onClicked: root.appendItems(root.presetValues)

        StyledText {
            id: presetText
            anchors.centerIn: parent
            text: root.presetLabel
            color: Theme.onSecondaryContainer
            font.pixelSize: Theme.fontSizeSmall - 1
            font.weight: Font.Medium
        }
    }

    Flow {
        visible: Array.isArray(root.values) && root.values.length > 0
        width: parent.width
        spacing: 6

        Repeater {
            model: Array.isArray(root.values) ? root.values : []

            delegate: Rectangle {
                height: 24
                width: Math.min(root.width, chipRow.implicitWidth + 14)
                radius: 12
                color: Theme.secondaryContainer

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 4

                    StyledText {
                        text: String(modelData)
                        width: Math.min(implicitWidth, root.width - 42)
                        elide: Text.ElideMiddle
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
                        enabled: root.fieldEnabled
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            const next = (Array.isArray(root.values) ? root.values : []).filter(item => item !== modelData);
                            root.valuesUpdated(next);
                        }
                    }
                }
            }
        }
    }
}
