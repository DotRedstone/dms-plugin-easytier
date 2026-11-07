import QtQuick
import qs.DCommon.Widgets

// [Two-Way Synced DTextField]
DTextField {
    id: field

    property string value: ""
    property bool _ready: false
    property bool _editingTick: false

    signal valueEdited(string newText)

    Component.onCompleted: {
        field._ready = true;
        if (field.text !== field.value)
            field.text = field.value;
    }

    onValueChanged: {
        if (field._ready && !field._editingTick && field.text !== field.value)
            field.text = field.value;
    }

    onTextEdited: {
        field._editingTick = true;
        field.valueEdited(field.text);
        field._editingTick = false;
    }
}
