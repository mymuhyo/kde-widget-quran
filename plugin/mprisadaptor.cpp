#include "mprisadaptor.h"
#include "mprisplayeradaptor.h"
#include <QDBusConnection>
#include <QDBusMessage>
#include <QCoreApplication>
#include <QProcess>
#include <QDebug>

MprisManager::MprisManager(QObject *parent) : QObject(parent)
{
    m_serviceName = QStringLiteral("org.mpris.MediaPlayer2.quranplayer_") + QString::number(QCoreApplication::applicationPid());
    
    new MediaPlayer2Adaptor(this);
    new MediaPlayer2PlayerAdaptor(this);
    
    QDBusConnection::sessionBus().registerObject(QStringLiteral("/org/mpris/MediaPlayer2"), this);
    QDBusConnection::sessionBus().registerService(m_serviceName);
}

MprisManager::~MprisManager()
{
    QDBusConnection::sessionBus().unregisterService(m_serviceName);
    QDBusConnection::sessionBus().unregisterObject(QStringLiteral("/org/mpris/MediaPlayer2"));
}

QString MprisManager::playbackStatus() const
{
    return m_playbackStatus;
}

void MprisManager::setPlaybackStatus(const QString &status)
{
    if (m_playbackStatus == status) return;
    m_playbackStatus = status;
    emit playbackStatusChanged();
    
    QVariantMap props;
    props.insert("PlaybackStatus", status);
    updateProperties("org.mpris.MediaPlayer2.Player", props);
}

QVariantMap MprisManager::metadata() const
{
    return m_metadata;
}

void MprisManager::setMetadata(const QVariantMap &meta)
{
    m_metadata = meta;
    emit metadataChanged();
    
    QVariantMap props;
    props.insert("Metadata", meta);
    updateProperties("org.mpris.MediaPlayer2.Player", props);
}

void MprisManager::updateProperties(const QString &interface, const QVariantMap &properties)
{
    QDBusMessage signal = QDBusMessage::createSignal(
        QStringLiteral("/org/mpris/MediaPlayer2"),
        QStringLiteral("org.freedesktop.DBus.Properties"),
        QStringLiteral("PropertiesChanged")
    );
    signal << interface;
    signal << properties;
    signal << QStringList();
    QDBusConnection::sessionBus().send(signal);
}
