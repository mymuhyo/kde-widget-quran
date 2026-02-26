import QtQuick
import org.kde.kirigami as Kirigami
import "../models" as Models

Rectangle {
    id: root

    color: Models.PlaybackManager.colorCard
    border.color: Models.PlaybackManager.colorBorder
    border.width: 1
    radius: 12
}
