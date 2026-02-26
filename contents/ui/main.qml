import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

import "views" as Views
import "models" as Models

PlasmoidItem {
    id: root

    readonly property bool panelLike: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical

    Plasmoid.constraintHints: Plasmoid.CanFillArea
    Layout.minimumWidth: panelLike
        ? (Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 180 : 44)
        : 540
    Layout.preferredWidth: panelLike
        ? (Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 300 : 44)
        : 540
    Layout.minimumHeight: panelLike
        ? (Plasmoid.formFactor === PlasmaCore.Types.Vertical ? 180 : 44)
        : 760
    Layout.preferredHeight: panelLike
        ? (Plasmoid.formFactor === PlasmaCore.Types.Vertical ? 300 : 44)
        : 760

    compactRepresentation: Views.PanelCompact {}

    fullRepresentation: Views.DesktopExpanded {}

    preferredRepresentation: panelLike ? compactRepresentation : fullRepresentation

    Shortcut {
        sequence: "Space"
        context: Qt.ApplicationShortcut
        onActivated: Models.PlaybackManager.togglePlayPause()
    }

    Shortcut {
        sequence: "Ctrl+Right"
        context: Qt.ApplicationShortcut
        onActivated: Models.PlaybackManager.nextTrack()
    }

    Shortcut {
        sequence: "Ctrl+Left"
        context: Qt.ApplicationShortcut
        onActivated: Models.PlaybackManager.previousTrack()
    }

    Shortcut {
        sequence: "Ctrl+Up"
        context: Qt.ApplicationShortcut
        onActivated: Models.PlaybackManager.setSpeed(Models.PlaybackManager.speed + 0.05)
    }

    Shortcut {
        sequence: "Ctrl+Down"
        context: Qt.ApplicationShortcut
        onActivated: Models.PlaybackManager.setSpeed(Models.PlaybackManager.speed - 0.05)
    }

    Shortcut {
        sequence: "Ctrl+B"
        context: Qt.ApplicationShortcut
        onActivated: Models.PlaybackManager.addBookmark()
    }

    Component.onCompleted: {
        Models.PlaybackManager.queueModel = Models.QueueModel
        Models.PlaybackManager.loadSettings()
        Models.PlaybackManager.reloadCollections()
        Models.PlaybackManager.telemetryEnabled = Models.PlaybackManager.telemetryEnabled
        Models.PlaybackManager.refreshReciters()
    }

    // Connect PlaybackManager.expanded <-> PlasmoidItem.expanded
    Connections {
        target: Models.PlaybackManager
        function onExpandedChanged() {
            root.expanded = Models.PlaybackManager.expanded
        }
    }
    onExpandedChanged: Models.PlaybackManager.expanded = root.expanded
}
