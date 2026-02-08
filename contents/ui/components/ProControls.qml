import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var controller
    readonly property bool narrow: width < 380

    spacing: 10

    Label {
        text: qsTr("Repeat mode")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
    }

    ReadableComboBox {
        Layout.fillWidth: true
        controller: root.controller
        model: [qsTr("None"), qsTr("Track"), qsTr("Queue")]
        currentIndex: controller ? controller.repeatMode : 0
        onActivated: function(index) {
            controller.repeatMode = index
        }
    }

    Label {
        text: qsTr("Ayah repeats")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
    }

    SpinBox {
        Layout.fillWidth: true
        from: 1
        to: 20
        value: controller ? controller.ayahRepeatTarget : 1
        onValueChanged: {
            if (controller && controller.ayahRepeatTarget !== value) {
                controller.ayahRepeatTarget = value
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: abLoopLayout.implicitHeight + 16
        radius: 8
        color: controller ? Qt.rgba(controller.colorAccent.r, controller.colorAccent.g, controller.colorAccent.b, 0.10) : "#EEF4FA"
        border.width: 1
        border.color: controller ? Qt.rgba(controller.colorAccent.r, controller.colorAccent.g, controller.colorAccent.b, 0.30) : "#C5D9EE"

        ColumnLayout {
            id: abLoopLayout
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            CheckBox {
                text: qsTr("Enable A-B loop")
                checked: controller ? controller.abLoopEnabled : false
                palette.windowText: controller ? controller.colorTextPrimary : "#1A222C"
                onToggled: {
                    if (!controller) {
                        return
                    }
                    controller.abLoopEnabled = checked
                    if (!checked) {
                        controller.clearABLoop()
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
                    enabled: controller && controller.currentTrack
                    onClicked: controller.setABStart()
                    Layout.fillWidth: true
                }

                Button {
                    text: qsTr("Set B")
                    enabled: controller && controller.currentTrack
                    onClicked: controller.setABEnd()
                    Layout.fillWidth: true
                }

                Button {
                    text: qsTr("Clear")
                    onClicked: controller.clearABLoop()
                    Layout.fillWidth: true
                }
            }

            Label {
                Layout.fillWidth: true
                text: controller ? controller.timeLabel(controller.abStartMs) + " - " + controller.timeLabel(controller.abEndMs) : ""
                elide: Text.ElideRight
                color: controller ? controller.colorTextSecondary : "#5B6675"
            }
        }
    }

    Label {
        text: qsTr("Speed")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Slider {
            Layout.fillWidth: true
            from: 0.5
            to: 2.0
            stepSize: 0.05
            value: controller ? controller.speed : 1.0
            onMoved: {
                if (controller) {
                    controller.setSpeed(value)
                }
            }
        }

        Label {
            text: controller ? Number(controller.speed).toFixed(2) + "x" : "1.00x"
            color: controller ? controller.colorTextPrimary : "#1A222C"
            Layout.preferredWidth: root.narrow ? 48 : 58
            horizontalAlignment: Text.AlignRight
            font.bold: true
        }
    }

    Label {
        text: qsTr("Volume")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Slider {
            Layout.fillWidth: true
            from: 0
            to: 1
            stepSize: 0.01
            value: controller ? controller.volume : 1.0
            onMoved: {
                if (controller) {
                    controller.setVolume(value)
                }
            }
        }

        Label {
            text: controller ? Math.round(controller.volume * 100) + "%" : "100%"
            color: controller ? controller.colorTextPrimary : "#1A222C"
            Layout.preferredWidth: root.narrow ? 48 : 58
            horizontalAlignment: Text.AlignRight
            font.bold: true
        }
    }

    Label {
        text: qsTr("Sleep timer")
        color: controller ? controller.colorTextPrimary : "#1A222C"
        font.bold: true
    }

    ReadableComboBox {
        Layout.fillWidth: true
        controller: root.controller
        model: [qsTr("Off"), qsTr("15 min"), qsTr("30 min"), qsTr("45 min"), qsTr("60 min")]
        currentIndex: {
            if (!controller) {
                return 0
            }
            var remaining = controller.sleepRemainingMinutes
            if (remaining <= 0) {
                return 0
            }
            if (remaining <= 15) {
                return 1
            }
            if (remaining <= 30) {
                return 2
            }
            if (remaining <= 45) {
                return 3
            }
            return 4
        }
        onActivated: function(index) {
            if (!controller) {
                return
            }

            var options = [0, 15, 30, 45, 60]
            controller.setSleepTimer(options[index])
        }
    }

    Label {
        Layout.fillWidth: true
        text: controller && controller.sleepRemainingMinutes > 0 ? controller.sleepRemainingMinutes + qsTr(" min left") : qsTr("Off")
        color: controller ? controller.colorTextSecondary : "#5B6675"
        horizontalAlignment: Text.AlignLeft
        elide: Text.ElideRight
    }
}
