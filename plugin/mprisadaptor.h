#pragma once

#include <QObject>
#include <QDBusContext>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class MprisManager : public QObject, protected QDBusContext
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString playbackStatus READ playbackStatus WRITE setPlaybackStatus NOTIFY playbackStatusChanged)
    Q_PROPERTY(QVariantMap metadata READ metadata WRITE setMetadata NOTIFY metadataChanged)

public:
    explicit MprisManager(QObject *parent = nullptr);
    ~MprisManager();

    QString playbackStatus() const;
    void setPlaybackStatus(const QString &status);

    QVariantMap metadata() const;
    void setMetadata(const QVariantMap &meta);

signals:
    void playbackStatusChanged();
    void metadataChanged();

    // From DBus (Remote -> QML)
    void playRequested();
    void pauseRequested();
    void playPauseRequested();
    void nextRequested();
    void previousRequested();
    void stopRequested();

private:
    QString m_playbackStatus = "Stopped";
    QVariantMap m_metadata;
    QString m_serviceName;
    
    void updateProperties(const QString &interface, const QVariantMap &properties);
};
