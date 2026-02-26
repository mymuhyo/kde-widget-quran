#include "mprisplugin.h"
#include "mprisadaptor.h"
#include <QtQml>

void MprisPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_UNUSED(engine)
    Q_UNUSED(uri)
}

void MprisPlugin::registerTypes(const char *uri)
{
    qmlRegisterType<MprisManager>(uri, 1, 0, "MprisManager");
}
