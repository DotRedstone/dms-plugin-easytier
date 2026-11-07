pragma Singleton
import QtQuick

// [Shared State Bus]
QtObject {
    property var primaryInstance: null
    property var instances: []
    property var snapshot: null
    property bool busy: false
    property string lastError: ""
}
