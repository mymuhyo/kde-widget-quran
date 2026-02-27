import QtQuick
import "../models" as Models
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

        readonly property bool narrow: width < 380

    spacing: 10

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 12
        rowSpacing: 8
        
        Label {
            text: qsTr("Repeat mode")
            color: Models.PlaybackManager.colorTextPrimary
            font.bold: true
            Layout.fillWidth: true
        }

        Label {
            text: qsTr("Ayah repeats")
            color: Models.PlaybackManager.colorTextPrimary
            font.bold: true
            Layout.fillWidth: true
        }

        ReadableComboBox {
            Layout.fillWidth: true
            model: [qsTr("None"), qsTr("Track"), qsTr("Queue")]
            currentIndex: Models.PlaybackManager.repeatMode
            onActivated: function(index) {
                Models.PlaybackManager.repeatMode = index
            }
        }

        SpinBox {
            Layout.fillWidth: true
            from: 1
            to: 20
            value: Models.PlaybackManager.ayahRepeatTarget
            onValueChanged: {
                if (Models.PlaybackManager.ayahRepeatTarget !== value) {
                    Models.PlaybackManager.ayahRepeatTarget = value
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: abLoopLayout.implicitHeight + 16
        radius: 8
        color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.10)
        border.width: 1
        border.color: Qt.rgba(Models.PlaybackManager.colorAccent.r, Models.PlaybackManager.colorAccent.g, Models.PlaybackManager.colorAccent.b, 0.30)

        ColumnLayout {
            id: abLoopLayout
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            CheckBox {
                text: qsTr("Enable A-B loop")
                checked: Models.PlaybackManager.abLoopEnabled
                palette.windowText: Models.PlaybackManager.colorTextPrimary
                onToggled: {
                    Models.PlaybackManager.abLoopEnabled = checked
                    if (!checked) {
                        Models.PlaybackManager.clearABLoop()
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.narrow ? 2 : 3
                columnSpacing: 6
                rowSpacing: 6

                Button {
                    text: qsTr("Set A")
                    enabled: Models.PlaybackManager.currentTrack
                    onClicked: Models.PlaybackManager.setABStart()
                    Layout.fillWidth: true
                }

                Button {
                    text: qsTr("Set B")
                    enabled: Models.PlaybackManager.currentTrack
                    onClicked: Models.PlaybackManager.setABEnd()
                    Layout.fillWidth: true
                }

                Button {
                    text: qsTr("Clear")
                    onClicked: Models.PlaybackManager.clearABLoop()
                    Layout.fillWidth: true
                }
            }

            Label {
                Layout.fillWidth: true
                text: Models.PlaybackManager.timeLabel(Models.PlaybackManager.abStartMs) + " - " + Models.PlaybackManager.timeLabel(Models.PlaybackManager.abEndMs)
                elide: Text.ElideRight
                color: Models.PlaybackManager.colorTextSecondary
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 12
        rowSpacing: 8

        Label {
            text: qsTr("Speed")
            color: Models.PlaybackManager.colorTextPrimary
            font.bold: true
            Layout.fillWidth: true
        }

        Label {
            text: qsTr("Volume")
            color: Models.PlaybackManager.colorTextPrimary
            font.bold: true
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Slider {
                Layout.fillWidth: true
                from: 0.5
                to: 2.0
                stepSize: 0.05
                value: Models.PlaybackManager.speed
                onMoved: Models.PlaybackManager.setSpeed(value)
            }

            Label {
                text: Number(Models.PlaybackManager.speed).toFixed(2) + "x"
                color: Models.PlaybackManager.colorTextPrimary
                Layout.preferredWidth: 35
                horizontalAlignment: Text.AlignRight
                font.bold: true
                font.pixelSize: 11
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Slider {
                Layout.fillWidth: true
                from: 0
                to: 1
                stepSize: 0.01
                value: Models.PlaybackManager.volume
                onMoved: Models.PlaybackManager.setVolume(value)
            }

            Label {
                text: Math.round(Models.PlaybackManager.volume * 100) + "%"
                color: Models.PlaybackManager.colorTextPrimary
                Layout.preferredWidth: 35
                horizontalAlignment: Text.AlignRight
                font.bold: true
                font.pixelSize: 11
            }
        }
    }

    Label {
        text: qsTr("Sleep timer")
        color: Models.PlaybackManager.colorTextPrimary
        font.bold: true
    }

    ReadableComboBox {
        Layout.fillWidth: true
        model: [qsTr("Off"), qsTr("15 min"), qsTr("30 min"), qsTr("45 min"), qsTr("60 min")]
        currentIndex: {
            var remaining = Models.PlaybackManager.sleepRemainingMinutes
            if (remaining <= 0) return 0
            if (remaining <= 15) return 1
            if (remaining <= 30) return 2
            if (remaining <= 45) return 3
            return 4
        }
        onActivated: function(index) {
            var options = [0, 15, 30, 45, 60]
            Models.PlaybackManager.setSleepTimer(options[index])
        }
    }

    Label {
        Layout.fillWidth: true
        text: Models.PlaybackManager.sleepRemainingMinutes > 0 ? Models.PlaybackManager.sleepRemainingMinutes + qsTr(" min left") : qsTr("Off")
        color: Models.PlaybackManager.colorTextSecondary
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
    }
}
