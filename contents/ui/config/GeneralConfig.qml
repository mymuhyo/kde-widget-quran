import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root
    width: childrenRect.width
    height: childrenRect.height

    property alias cfg_playbackMode: playbackModeCombo.currentIndex
    property alias cfg_repeatMode: repeatModeCombo.currentIndex
    property alias cfg_ayahRepeatTarget: ayahRepeatSpinBox.value
    property double cfg_speed
    property double cfg_uiScale

    onCfg_speedChanged: {
        var val = Math.round(cfg_speed * 100)
        if (speedSpinBox.value !== val) {
            speedSpinBox.value = val
        }
    }

    onCfg_uiScaleChanged: {
        var val = Math.round(cfg_uiScale * 100)
        if (uiScaleSpinBox.value !== val) {
            uiScaleSpinBox.value = val
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        
        Kirigami.FormLayout {
            Layout.fillWidth: true

            ComboBox {
                id: playbackModeCombo
                Kirigami.FormData.label: i18n("Default Playback Mode:")
                model: [i18n("Ayah Range"), i18n("Full Surah")]
            }

            ComboBox {
                id: repeatModeCombo
                Kirigami.FormData.label: i18n("Default Repeat Mode:")
                model: [i18n("None"), i18n("Track"), i18n("Queue")]
            }

            SpinBox {
                id: ayahRepeatSpinBox
                Kirigami.FormData.label: i18n("Default Ayah Repeats:")
                from: 1
                to: 20
            }

            SpinBox {
                id: speedSpinBox
                Kirigami.FormData.label: i18n("Default Speed:")
                from: 50
                to: 200
                stepSize: 5
                textFromValue: function(value, locale) {
                    return (value / 100).toFixed(2) + "x"
                }
                valueFromText: function(text, locale) {
                    return Number.fromLocaleString(locale, text.replace("x", "")) * 100
                }
                onValueChanged: {
                    root.cfg_speed = value / 100.0
                }
            }

            SpinBox {
                id: uiScaleSpinBox
                Kirigami.FormData.label: i18n("UI Scale:")
                from: 90
                to: 115
                stepSize: 5
                textFromValue: function(value, locale) {
                    return value + "%"
                }
                valueFromText: function(text, locale) {
                    return Number.fromLocaleString(locale, text.replace("%", ""))
                }
                onValueChanged: {
                    root.cfg_uiScale = value / 100.0
                }
            }

            Item {
                Kirigami.FormData.isSection: true
            }

            Label {
                text: i18n("Note: Some settings are also adjustable directly within the widget interface.")
                font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }
}
