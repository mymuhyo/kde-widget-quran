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

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

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
            display: AbstractButton.IconOnly
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Refresh reciters")
            
            // Adding a subtle background to make it look more like a button
            background: Rectangle {
                color: parent.down ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.2) :
                       (parent.hovered ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.1) : "transparent")
                radius: 4
                
                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }
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

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        
        Label {
            text: qsTr("Surah")
            color: Models.PlaybackManager.colorTextPrimary
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }
        
        Item { Layout.fillWidth: true }
        
        // Quick search/filter button
        ToolButton {
            icon.name: "search"
            display: AbstractButton.IconOnly
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Search Surah")
            onClicked: {
                searchField.visible = !searchField.visible
                if (searchField.visible) {
                    searchField.forceActiveFocus()
                }
            }
            
            background: Rectangle {
                color: parent.down ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.2) :
                       (parent.hovered ? Qt.rgba(Models.PlaybackManager.colorTextPrimary.r, Models.PlaybackManager.colorTextPrimary.g, Models.PlaybackManager.colorTextPrimary.b, 0.1) : "transparent")
                radius: 4
            }
        }
    }

    TextField {
        id: searchField
        Layout.fillWidth: true
        placeholderText: qsTr("Search surah by name or number...")
        visible: false
        
        // Make sure it takes up space when visible
        Layout.preferredHeight: visible ? implicitHeight : 0
        opacity: visible ? 1.0 : 0.0
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
        
        onTextChanged: {
            var query = text.toLowerCase()
            if (query.length === 0) return
            
            // Try to match by number first
            var num = parseInt(query)
            if (!isNaN(num) && num >= 1 && num <= 114) {
                Models.PlaybackManager.setSurah(num)
                return
            }
            
            // Then by name
            for (var i = 0; i < Models.PlaybackManager.surahs.length; i++) {
                var s = Models.PlaybackManager.surahs[i]
                if (s.nameEn.toLowerCase().indexOf(query) !== -1 ||
                    s.nameAr.toLowerCase().indexOf(query) !== -1 ||
                    s.nameEnTranslated.toLowerCase().indexOf(query) !== -1) {
                    Models.PlaybackManager.setSurah(i + 1)
                    break
                }
            }
        }
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

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 12
        rowSpacing: 8
        visible: !root.fullSurahMode
        
        Label {
            text: qsTr("From ayah")
            color: Models.PlaybackManager.colorTextPrimary
            font.bold: true
            Layout.fillWidth: true
        }
        
        Label {
            text: qsTr("To ayah")
            color: Models.PlaybackManager.colorTextPrimary
            font.bold: true
            Layout.fillWidth: true
        }
        
        SpinBox {
            Layout.fillWidth: true
            from: 1
            to: Models.PlaybackManager.maxAyahForSurah
            value: Models.PlaybackManager.startAyah
            enabled: !Models.PlaybackManager.isQueueLoading
            onValueChanged: {
                if (Models.PlaybackManager.startAyah !== value) {
                    Models.PlaybackManager.startAyah = value
                }
            }
        }
        
        SpinBox {
            Layout.fillWidth: true
            from: 1
            to: Models.PlaybackManager.maxAyahForSurah
            value: Models.PlaybackManager.endAyah
            enabled: !Models.PlaybackManager.isQueueLoading
            onValueChanged: {
                if (Models.PlaybackManager.endAyah !== value) {
                    Models.PlaybackManager.endAyah = value
                }
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

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Layout.topMargin: 4

        Button {
            text: Models.PlaybackManager.isQueueLoading
                ? qsTr("Building...")
                : (root.fullSurahMode ? qsTr("Prepare Surah") : qsTr("Build Queue"))
            icon.name: "list-add"
            Layout.fillWidth: true
            enabled: !Models.PlaybackManager.isQueueLoading
            onClicked: Models.PlaybackManager.buildQueue(false)
        }

        Button {
            text: root.fullSurahMode ? qsTr("Play Surah") : qsTr("Play Now")
            icon.name: "media-playback-start"
            Layout.fillWidth: true
            enabled: !Models.PlaybackManager.isQueueLoading
            onClicked: Models.PlaybackManager.buildQueue(true)
            
            // Highlight the primary action button
            background: Rectangle {
                radius: 4
                color: parent.down ? Qt.darker(Models.PlaybackManager.colorAccent, 1.2) :
                       (parent.hovered ? Qt.lighter(Models.PlaybackManager.colorAccent, 1.1) : Models.PlaybackManager.colorAccent)
                
                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }
            contentItem: Row {
                spacing: 6
                anchors.centerIn: parent
                Image {
                    source: parent.parent.icon.name ? "image://icon/" + parent.parent.icon.name : ""
                    width: 16
                    height: 16
                    visible: source != ""
                    anchors.verticalCenter: parent.verticalCenter
                    layer.enabled: true
                    layer.effect: ShaderEffect {
                        fragmentShader: "
                            varying highp vec2 qt_TexCoord0;
                            uniform highp sampler2D source;
                            void main() {
                                gl_FragColor = texture2D(source, qt_TexCoord0).a * vec4(1.0, 1.0, 1.0, 1.0); // White icon
                            }
                        "
                    }
                }
                Text {
                    text: parent.parent.text
                    color: "#ffffff" // White text for contrast on accent color
                    font: parent.parent.font
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
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
            color: Models.PlaybackManager.hasErrorStatus
                ? Models.PlaybackManager.colorNegative
                : Models.PlaybackManager.colorTextSecondary
            wrapMode: Text.WordWrap
            font.pixelSize: 11
        }

        Label {
            visible: Models.PlaybackManager.isQueueLoading
            text: Models.PlaybackManager.queueBuildProgress + "%"
            color: Models.PlaybackManager.colorTextSecondary
            font.pixelSize: 11
        }

        Button {
            visible: Models.PlaybackManager.hasErrorStatus && !Models.PlaybackManager.isQueueLoading
            text: qsTr("Retry")
            onClicked: Models.PlaybackManager.requestRetryLastAction()
        }
    }
}
