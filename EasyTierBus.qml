pragma Singleton
import QtQuick

// [Shared State Bus]
QtObject {
    property var primaryInstance: null
    property var instances: []
    property var snapshot: null
    property var profiles: []
    property string activeProfileId: ""
    property bool busy: false
    property bool popupOpen: false
    property string lastError: ""
}
