import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "UiText.js" as UiText

// [Plugin Settings]
PluginSettings {
    id: root
    pluginId: "easytier"

    readonly property string currentLang: UiText.resolveLang(
        langSetting.value || "auto",
        Qt.locale().name
    )

    function t(key) {
        return UiText.tr(root.currentLang, key);
    }

    // [Appearance & Behavior]
    StyledText {
        width: parent.width
        text: root.t("settingSectionDisplay")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    SelectionSetting {
        settingKey: "backendMode"
        label: root.t("settingBackendMode")
        description: root.t("settingBackendModeDesc")
        defaultValue: "managed"
        options: [
            { label: root.t("modeManaged"), value: "managed" },
            { label: root.t("modeSystemd"), value: "systemd" }
        ]
    }

    SelectionSetting {
        id: langSetting
        settingKey: "language"
        label: root.t("settingLanguage")
        description: root.t("settingLanguageDesc")
        defaultValue: "auto"
        options: [
            { label: root.t("langAuto"), value: "auto" },
            { label: root.t("langZh"), value: "zh_CN" },
            { label: root.t("langEn"), value: "en" }
        ]
    }

    SelectionSetting {
        settingKey: "pillMode"
        label: root.t("settingPillMode")
        description: root.t("settingPillModeDesc")
        defaultValue: "peers"
        options: [
            { label: root.t("pillPeers"), value: "peers" },
            { label: root.t("pillIp"), value: "ip" },
            { label: root.t("pillNetwork"), value: "network" },
            { label: root.t("pillIcon"), value: "icon" }
        ]
    }

    SelectionSetting {
        settingKey: "copyField"
        label: root.t("settingCopyField")
        description: root.t("settingCopyFieldDesc")
        defaultValue: "ip"
        options: [
            { label: root.t("copyFieldIp"), value: "ip" },
            { label: root.t("copyFieldHost"), value: "hostname" }
        ]
    }

    ToggleSetting {
        settingKey: "rightClickToggle"
        label: root.t("settingRightClickToggle")
        description: root.t("settingRightClickToggleDesc")
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "showRoutes"
        label: root.t("settingShowRoutes")
        description: root.t("settingShowRoutesDesc")
        defaultValue: true
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outlineVariant
        opacity: 0.35
    }

    // [Backend & Service]
    StyledText {
        width: parent.width
        text: root.t("settingSectionBackend")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    SliderSetting {
        settingKey: "pollInterval"
        label: root.t("settingPollInterval")
        description: root.t("settingPollIntervalDesc")
        defaultValue: 5
        minimum: 5
        maximum: 60
        unit: "s"
    }

    SelectionSetting {
        settingKey: "serviceScope"
        label: root.t("settingServiceScope")
        description: root.t("settingServiceScopeDesc")
        defaultValue: "system"
        options: [
            { label: root.t("scopeSystem"), value: "system" },
            { label: root.t("scopeUser"), value: "user" }
        ]
    }

    StringSetting {
        settingKey: "serviceUnit"
        label: root.t("settingServiceUnit")
        description: root.t("settingServiceUnitDesc")
        placeholder: "easytier.service"
        defaultValue: "easytier.service"
    }

    StringSetting {
        settingKey: "rpcPortal"
        label: root.t("settingRpcPortal")
        description: root.t("settingRpcPortalDesc")
        placeholder: "127.0.0.1:15888"
        defaultValue: "127.0.0.1:15888"
    }
}
