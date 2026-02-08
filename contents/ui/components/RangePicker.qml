import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var controller
    readonly property bool narrow: width < 380
    readonly property bool fullSurahMode: controller && controller.playbackMode === 1
    readonly property bool showStatus: controller
        && (controller.isQueueLoading || (controller.statusText && controller.statusText.length > 0 && controller.statusText !== qsTr("Ready")))

    spacing: 8

    Label {
        text: qsTr("Reciter")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.narrow ? 1 : 2
        columnSpacing: 8
        rowSpacing: 6

        ReadableComboBox {
            Layout.fillWidth: true
            controller: root.controller
            model: controller ? controller.reciters : []
            textRole: "name"
            currentIndex: controller ? controller.selectedReciterIndex : -1
            enabled: controller && !controller.isQueueLoading
            onActivated: function(index) {
                controller.selectedReciterIndex = index
            }
        }

        ToolButton {
            icon.name: "view-refresh"
            onClicked: controller.refreshReciters()
            enabled: controller && !controller.isQueueLoading
            display: root.narrow ? AbstractButton.TextBesideIcon : AbstractButton.IconOnly
            text: root.narrow ? qsTr("Refresh") : ""
            Layout.fillWidth: root.narrow
            Layout.alignment: root.narrow ? Qt.AlignLeft : Qt.AlignVCenter
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Refresh reciters")
        }
    }

    Label {
        Layout.fillWidth: true
        text: controller ? controller.providerStatus : ""
        color: controller ? controller.colorTextSecondary : "#5B6675"
        font.pixelSize: 11
        wrapMode: Text.WordWrap
        visible: text.length > 0
    }

    Label {
        text: qsTr("Surah")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
    }

    ReadableComboBox {
        id: surahCombo
        Layout.fillWidth: true
        controller: root.controller
        model: controller ? controller.surahs : []
        textRole: controller && controller.uiLocale.toLowerCase().indexOf("ar") === 0 ? "nameAr" : "nameEn"
        currentIndex: controller ? controller.selectedSurah - 1 : 0
        enabled: controller && !controller.isQueueLoading
        onActivated: function(index) {
            controller.setSurah(index + 1)
        }
        displayText: {
            if (!controller || currentIndex < 0 || currentIndex >= controller.surahs.length) {
                return ""
            }
            var item = controller.surahs[currentIndex]
            var name = controller.uiLocale.toLowerCase().indexOf("ar") === 0 ? item.nameAr : item.nameEn
            return item.number + ". " + name
        }
    }

    Label {
        text: qsTr("Playback mode")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
    }

    ReadableComboBox {
        Layout.fillWidth: true
        controller: root.controller
        model: [qsTr("Ayah range"), qsTr("Full surah")]
        currentIndex: controller ? controller.playbackMode : 0
        enabled: controller && !controller.isQueueLoading
        onActivated: function(index) {
            if (controller) {
                controller.playbackMode = index
            }
        }
    }

    Label {
        text: qsTr("From ayah")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
        visible: !root.fullSurahMode
    }

    SpinBox {
        Layout.fillWidth: true
        from: 1
        to: controller ? controller.maxAyahForSurah : 1
        value: controller ? controller.startAyah : 1
        enabled: controller && !controller.isQueueLoading
        visible: !root.fullSurahMode
        onValueChanged: {
            if (controller && controller.startAyah !== value) {
                controller.startAyah = value
            }
        }
    }

    Label {
        text: qsTr("To ayah")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
        visible: !root.fullSurahMode
    }

    SpinBox {
        Layout.fillWidth: true
        from: 1
        to: controller ? controller.maxAyahForSurah : 1
        value: controller ? controller.endAyah : 1
        enabled: controller && !controller.isQueueLoading
        visible: !root.fullSurahMode
        onValueChanged: {
            if (controller && controller.endAyah !== value) {
                controller.endAyah = value
            }
        }
    }

    Label {
        Layout.fillWidth: true
        text: qsTr("Full surah uses a single audio stream when available to reduce gaps.")
        color: controller ? controller.colorTextSecondary : "#5B6675"
        font.pixelSize: 11
        wrapMode: Text.WordWrap
        visible: root.fullSurahMode
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.narrow ? 1 : 2
        columnSpacing: 8
        rowSpacing: 8

        Button {
            text: controller && controller.isQueueLoading
                ? qsTr("Building...")
                : (root.fullSurahMode ? qsTr("Prepare Surah") : qsTr("Build Queue"))
            Layout.fillWidth: true
            enabled: controller && !controller.isQueueLoading
            onClicked: controller.buildQueue(false)
        }

        Button {
            text: root.fullSurahMode ? qsTr("Play Surah") : qsTr("Play Now")
            Layout.fillWidth: true
            enabled: controller && !controller.isQueueLoading
            onClicked: controller.buildQueue(true)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: root.showStatus

        BusyIndicator {
            running: controller && controller.isQueueLoading
            visible: running
            implicitWidth: 16
            implicitHeight: 16
        }

        Label {
            Layout.fillWidth: true
            text: controller ? controller.statusText : ""
            color: controller ? controller.colorTextSecondary : "#5B6675"
            wrapMode: Text.WordWrap
            font.pixelSize: 11
        }
    }
}
