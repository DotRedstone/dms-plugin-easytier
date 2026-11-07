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

    spacing: Theme.spacingXS
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
            buttonSize: Theme.buttonHeightXS + Theme.spacingXS
            iconSize: Theme.iconSizeSmall
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
        height: Theme.buttonHeightXXS - Theme.spacingXS
        width: presetText.implicitWidth + Theme.spacingL
        radius: Theme.cornerRadiusFull
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
        spacing: Theme.spacingXS

        Repeater {
            model: Array.isArray(root.values) ? root.values : []

            delegate: Rectangle {
                height: Theme.buttonHeightXXS
                width: Math.min(root.width, chipRow.implicitWidth + Theme.spacingM)
                radius: Theme.cornerRadiusFull
                color: Theme.secondaryContainer

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingXS

                    StyledText {
                        text: String(modelData)
                        width: Math.min(implicitWidth, root.width - Theme.buttonHeightS)
                        elide: Text.ElideMiddle
                        color: Theme.onSecondaryContainer
                        font.pixelSize: Theme.fontSizeSmall - 1
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DActionButton {
                        buttonSize: Theme.buttonHeightXXS - Theme.spacingXS
                        iconSize: Theme.iconSizeSmall
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
