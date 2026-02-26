#include "mprisplayeradaptor.h"

MediaPlayer2Adaptor::MediaPlayer2Adaptor(MprisManager *parent)
    : QDBusAbstractAdaptor(parent)
{
}

MediaPlayer2PlayerAdaptor::MediaPlayer2PlayerAdaptor(MprisManager *parent)
    : QDBusAbstractAdaptor(parent), m_manager(parent)
{
}

QString MediaPlayer2PlayerAdaptor::PlaybackStatus() const
{
    return m_manager->playbackStatus();
}

QVariantMap MediaPlayer2PlayerAdaptor::Metadata() const
{
    return m_manager->metadata();
}

void MediaPlayer2PlayerAdaptor::Next()
{
    emit m_manager->nextRequested();
}

void MediaPlayer2PlayerAdaptor::Previous()
{
    emit m_manager->previousRequested();
}

void MediaPlayer2PlayerAdaptor::Pause()
{
    emit m_manager->pauseRequested();
}

void MediaPlayer2PlayerAdaptor::PlayPause()
{
    emit m_manager->playPauseRequested();
}

void MediaPlayer2PlayerAdaptor::Stop()
{
    emit m_manager->stopRequested();
}

void MediaPlayer2PlayerAdaptor::Play()
{
    emit m_manager->playRequested();
}
