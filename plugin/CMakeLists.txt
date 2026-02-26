cmake_minimum_required(VERSION 3.16)

project(QuranPlayerMprisPlugin)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core DBus Qml)

qt_add_qml_module(quranmprisplugin
    URI org.kde.quranplayer
    VERSION 1.0
    SOURCES
        mprisadaptor.cpp
        mprisplayeradaptor.cpp
)

target_link_libraries(quranmprisplugin PRIVATE
    Qt6::Core
    Qt6::DBus
    Qt6::Qml
)

install(TARGETS quranmprisplugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/quranplayer)
install(TARGETS quranmprispluginplugin DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/quranplayer)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/org/kde/quranplayer)
