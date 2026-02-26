import QtQuick
import "../models" as Models
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

        readonly property bool narrow: width < 380
    readonly property bool fullSurahMode: Models.PlaybackManager.playbackMode === 1
    readonly property bool showStatus: true
        && (Models.PlaybackManager.isQueueLoading || (Models.PlaybackManager.statusText && Models.PlaybackManager.statusText.length > 0 && Models.PlaybackManager.statusText !== qsTr("Ready")))

    spacing: 8

    Label {
        text: qsTr("Reciter")
        color: Models.PlaybackManager.colorTextPrimary
        font.bold: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.narrow ? 1 : 2
        columnSpacing: 8
        rowSpacing: 6

        ReadableComboBox {
            Layout.fillWidth: true
            model: Models.PlaybackManager.reciters
            textRole: "name"
            currentIndex: Models.PlaybackManager.selectedReciterIndex
            enabled: !Models.PlaybackManager.isQueueLoading
            onActivated: function(index) {
                Models.PlaybackManager.selectedReciterIndex = index
            }
        }

        ToolButton {
            icon.name: "view-refresh"
            onClicked: Models.PlaybackManager.refreshReciters()
            enabled: !Models.PlaybackManager.isQueueLoading
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
        text: Models.PlaybackManager.providerStatus
        color: Models.PlaybackManager.colorTextSecondary
        font.pixelSize: 11
        wrapMode: Text.WordWrap
        visible: text.length > 0
    }

    Label {
        text: qsTr("Surah")
        color: Models.PlaybackManager.colorTextPrimary
        font.bold: true
    }

    ReadableComboBox {
        id: surahCombo
        Layout.fillWidth: true
        // controller removed
        model: Models.PlaybackManager.surahs
        textRole: Models.PlaybackManager.uiLocale.toLowerCase().indexOf("ar") === 0 ? "nameAr" : "nameEn"
        currentIndex: Models.PlaybackManager.selectedSurah - 1
        enabled: !Models.PlaybackManager.isQueueLoading
        onActivated: function(index) {
            Models.PlaybackManager.setSurah(index + 1)
        }
        displayText: {
            if (currentIndex < 0 || currentIndex >= Models.PlaybackManager.surahs.length) {
                return ""
            }
            var item = Models.PlaybackManager.surahs[currentIndex]
            var name = Models.PlaybackManager.uiLocale.toLowerCase().indexOf("ar") === 0 ? item.nameAr : item.nameEn
            return item.number + ". " + name
        }
    }

    Label {
        text: qsTr("Playback mode")
        color: Models.PlaybackManager.colorTextPrimary
        font.bold: true
    }

    ReadableComboBox {
        Layout.fillWidth: true
        model: [qsTr("Ayah range"), qsTr("Full surah")]
        currentIndex: Models.PlaybackManager.playbackMode
        enabled: !Models.PlaybackManager.isQueueLoading
        onActivated: function(index) {
            Models.PlaybackManager.playbackMode = index
        }
    }

    Label {
        text: qsTr("From ayah")
        color: Models.PlaybackManager.colorTextPrimary
        font.bold: true
        visible: !root.fullSurahMode
    }

    SpinBox {
        Layout.fillWidth: true
        from: 1
        to: Models.PlaybackManager.maxAyahForSurah
        value: Models.PlaybackManager.startAyah
        enabled: !Models.PlaybackManager.isQueueLoading
        visible: !root.fullSurahMode
        onValueChanged: {
            if (Models.PlaybackManager.startAyah !== value) {
                Models.PlaybackManager.startAyah = value
            }
        }
    }

    Label {
        text: qsTr("To ayah")
        color: Models.PlaybackManager.colorTextPrimary
        font.bold: true
        visible: !root.fullSurahMode
    }

    SpinBox {
        Layout.fillWidth: true
        from: 1
        to: Models.PlaybackManager.maxAyahForSurah
        value: Models.PlaybackManager.endAyah
        enabled: !Models.PlaybackManager.isQueueLoading
        visible: !root.fullSurahMode
        onValueChanged: {
            if (Models.PlaybackManager.endAyah !== value) {
                Models.PlaybackManager.endAyah = value
            }
        }
    }

    Label {
        Layout.fillWidth: true
        text: qsTr("Full surah uses a single audio stream when available to reduce gaps.")
        color: Models.PlaybackManager.colorTextSecondary
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
            text: Models.PlaybackManager.isQueueLoading
                ? qsTr("Building...")
                : (root.fullSurahMode ? qsTr("Prepare Surah") : qsTr("Build Queue"))
            Layout.fillWidth: true
            enabled: !Models.PlaybackManager.isQueueLoading
            onClicked: Models.PlaybackManager.buildQueue(false)
        }

        Button {
            text: root.fullSurahMode ? qsTr("Play Surah") : qsTr("Play Now")
            Layout.fillWidth: true
            enabled: !Models.PlaybackManager.isQueueLoading
            onClicked: Models.PlaybackManager.buildQueue(true)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: root.showStatus

        BusyIndicator {
            running: Models.PlaybackManager.isQueueLoading
            visible: running
            implicitWidth: 16
            implicitHeight: 16
        }

        Label {
            Layout.fillWidth: true
            text: Models.PlaybackManager.statusText
            color: Models.PlaybackManager.colorTextSecondary
            wrapMode: Text.WordWrap
            font.pixelSize: 11
        }
    }
}
