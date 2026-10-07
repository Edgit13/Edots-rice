/****************************************************************************
** Meta object code from reading C++ file 'browser_window.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/browser_window.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'browser_window.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN13BrowserWindowE_t {};
} // unnamed namespace

template <> constexpr inline auto BrowserWindow::qt_create_metaobjectdata<qt_meta_tag_ZN13BrowserWindowE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "BrowserWindow",
        "currentUrlChanged",
        "",
        "currentHostChanged",
        "currentTitleChanged",
        "permissionChanged",
        "loadProgressChanged",
        "loadingChanged",
        "tabsChanged",
        "sectionChanged",
        "navStateChanged",
        "bookmarkedChanged",
        "zoomChanged",
        "permissionsListChanged",
        "filtersChanged",
        "focusAddressRequested",
        "navigate",
        "text",
        "back",
        "forward",
        "reload",
        "hardReload",
        "stop",
        "goHome",
        "focusWeb",
        "openUrl",
        "url",
        "newTab",
        "activateTab",
        "index",
        "closeTab",
        "showSection",
        "name",
        "showSettings",
        "toggleBookmark",
        "setPermission",
        "mode",
        "setSitePermission",
        "host",
        "removeSitePermission",
        "zoomBy",
        "delta",
        "updateFilters",
        "clearData",
        "kind",
        "openPopup",
        "x",
        "y",
        "closePopup",
        "showTip",
        "area",
        "hideTip",
        "notify",
        "currentUrl",
        "currentHost",
        "currentTitle",
        "permission",
        "loadProgress",
        "loading",
        "tabs",
        "QVariantList",
        "section",
        "canGoBack",
        "canGoForward",
        "bookmarked",
        "zoomPercent",
        "trustedSites",
        "blockedSites",
        "filterLists",
        "filtersBusy",
        "versionInfo",
        "dataFolder"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'currentUrlChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentHostChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentTitleChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'permissionChanged'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'loadProgressChanged'
        QtMocHelpers::SignalData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'loadingChanged'
        QtMocHelpers::SignalData<void()>(7, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'tabsChanged'
        QtMocHelpers::SignalData<void()>(8, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'sectionChanged'
        QtMocHelpers::SignalData<void()>(9, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'navStateChanged'
        QtMocHelpers::SignalData<void()>(10, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'bookmarkedChanged'
        QtMocHelpers::SignalData<void()>(11, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'zoomChanged'
        QtMocHelpers::SignalData<void()>(12, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'permissionsListChanged'
        QtMocHelpers::SignalData<void()>(13, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'filtersChanged'
        QtMocHelpers::SignalData<void()>(14, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'focusAddressRequested'
        QtMocHelpers::SignalData<void()>(15, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'navigate'
        QtMocHelpers::MethodData<void(const QString &)>(16, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 17 },
        }}),
        // Method 'back'
        QtMocHelpers::MethodData<void()>(18, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'forward'
        QtMocHelpers::MethodData<void()>(19, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'reload'
        QtMocHelpers::MethodData<void()>(20, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'hardReload'
        QtMocHelpers::MethodData<void()>(21, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'stop'
        QtMocHelpers::MethodData<void()>(22, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'goHome'
        QtMocHelpers::MethodData<void()>(23, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'focusWeb'
        QtMocHelpers::MethodData<void()>(24, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'openUrl'
        QtMocHelpers::MethodData<void(const QString &)>(25, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 26 },
        }}),
        // Method 'newTab'
        QtMocHelpers::MethodData<void()>(27, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'activateTab'
        QtMocHelpers::MethodData<void(int)>(28, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 29 },
        }}),
        // Method 'closeTab'
        QtMocHelpers::MethodData<void(int)>(30, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 29 },
        }}),
        // Method 'showSection'
        QtMocHelpers::MethodData<void(const QString &)>(31, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 32 },
        }}),
        // Method 'showSettings'
        QtMocHelpers::MethodData<void()>(33, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'toggleBookmark'
        QtMocHelpers::MethodData<void()>(34, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'setPermission'
        QtMocHelpers::MethodData<void(const QString &)>(35, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 36 },
        }}),
        // Method 'setSitePermission'
        QtMocHelpers::MethodData<void(const QString &, const QString &)>(37, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 38 }, { QMetaType::QString, 36 },
        }}),
        // Method 'removeSitePermission'
        QtMocHelpers::MethodData<void(const QString &)>(39, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 38 },
        }}),
        // Method 'zoomBy'
        QtMocHelpers::MethodData<void(int)>(40, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 41 },
        }}),
        // Method 'updateFilters'
        QtMocHelpers::MethodData<void()>(42, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'clearData'
        QtMocHelpers::MethodData<void(const QString &)>(43, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 44 },
        }}),
        // Method 'openPopup'
        QtMocHelpers::MethodData<void(const QString &, int, int)>(45, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 44 }, { QMetaType::Int, 46 }, { QMetaType::Int, 47 },
        }}),
        // Method 'closePopup'
        QtMocHelpers::MethodData<void()>(48, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'showTip'
        QtMocHelpers::MethodData<void(const QString &, const QString &, int, int)>(49, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 50 }, { QMetaType::QString, 17 }, { QMetaType::Int, 46 }, { QMetaType::Int, 47 },
        }}),
        // Method 'hideTip'
        QtMocHelpers::MethodData<void()>(51, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'notify'
        QtMocHelpers::MethodData<void(const QString &)>(52, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 17 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'currentUrl'
        QtMocHelpers::PropertyData<QString>(53, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'currentHost'
        QtMocHelpers::PropertyData<QString>(54, QMetaType::QString, QMC::DefaultPropertyFlags, 1),
        // property 'currentTitle'
        QtMocHelpers::PropertyData<QString>(55, QMetaType::QString, QMC::DefaultPropertyFlags, 2),
        // property 'permission'
        QtMocHelpers::PropertyData<QString>(56, QMetaType::QString, QMC::DefaultPropertyFlags, 3),
        // property 'loadProgress'
        QtMocHelpers::PropertyData<int>(57, QMetaType::Int, QMC::DefaultPropertyFlags, 4),
        // property 'loading'
        QtMocHelpers::PropertyData<bool>(58, QMetaType::Bool, QMC::DefaultPropertyFlags, 5),
        // property 'tabs'
        QtMocHelpers::PropertyData<QVariantList>(59, 0x80000000 | 60, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 6),
        // property 'section'
        QtMocHelpers::PropertyData<QString>(61, QMetaType::QString, QMC::DefaultPropertyFlags, 7),
        // property 'canGoBack'
        QtMocHelpers::PropertyData<bool>(62, QMetaType::Bool, QMC::DefaultPropertyFlags, 8),
        // property 'canGoForward'
        QtMocHelpers::PropertyData<bool>(63, QMetaType::Bool, QMC::DefaultPropertyFlags, 8),
        // property 'bookmarked'
        QtMocHelpers::PropertyData<bool>(64, QMetaType::Bool, QMC::DefaultPropertyFlags, 9),
        // property 'zoomPercent'
        QtMocHelpers::PropertyData<int>(65, QMetaType::Int, QMC::DefaultPropertyFlags, 10),
        // property 'trustedSites'
        QtMocHelpers::PropertyData<QStringList>(66, QMetaType::QStringList, QMC::DefaultPropertyFlags, 11),
        // property 'blockedSites'
        QtMocHelpers::PropertyData<QStringList>(67, QMetaType::QStringList, QMC::DefaultPropertyFlags, 11),
        // property 'filterLists'
        QtMocHelpers::PropertyData<int>(68, QMetaType::Int, QMC::DefaultPropertyFlags, 12),
        // property 'filtersBusy'
        QtMocHelpers::PropertyData<bool>(69, QMetaType::Bool, QMC::DefaultPropertyFlags, 12),
        // property 'versionInfo'
        QtMocHelpers::PropertyData<QString>(70, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Constant),
        // property 'dataFolder'
        QtMocHelpers::PropertyData<QString>(71, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Constant),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<BrowserWindow, qt_meta_tag_ZN13BrowserWindowE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject BrowserWindow::staticMetaObject = { {
    QMetaObject::SuperData::link<QMainWindow::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN13BrowserWindowE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN13BrowserWindowE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN13BrowserWindowE_t>.metaTypes,
    nullptr
} };

void BrowserWindow::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<BrowserWindow *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->currentUrlChanged(); break;
        case 1: _t->currentHostChanged(); break;
        case 2: _t->currentTitleChanged(); break;
        case 3: _t->permissionChanged(); break;
        case 4: _t->loadProgressChanged(); break;
        case 5: _t->loadingChanged(); break;
        case 6: _t->tabsChanged(); break;
        case 7: _t->sectionChanged(); break;
        case 8: _t->navStateChanged(); break;
        case 9: _t->bookmarkedChanged(); break;
        case 10: _t->zoomChanged(); break;
        case 11: _t->permissionsListChanged(); break;
        case 12: _t->filtersChanged(); break;
        case 13: _t->focusAddressRequested(); break;
        case 14: _t->navigate((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 15: _t->back(); break;
        case 16: _t->forward(); break;
        case 17: _t->reload(); break;
        case 18: _t->hardReload(); break;
        case 19: _t->stop(); break;
        case 20: _t->goHome(); break;
        case 21: _t->focusWeb(); break;
        case 22: _t->openUrl((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 23: _t->newTab(); break;
        case 24: _t->activateTab((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 25: _t->closeTab((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 26: _t->showSection((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 27: _t->showSettings(); break;
        case 28: _t->toggleBookmark(); break;
        case 29: _t->setPermission((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 30: _t->setSitePermission((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2]))); break;
        case 31: _t->removeSitePermission((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 32: _t->zoomBy((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 33: _t->updateFilters(); break;
        case 34: _t->clearData((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 35: _t->openPopup((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3]))); break;
        case 36: _t->closePopup(); break;
        case 37: _t->showTip((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 38: _t->hideTip(); break;
        case 39: _t->notify((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::currentUrlChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::currentHostChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::currentTitleChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::permissionChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::loadProgressChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::loadingChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::tabsChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::sectionChanged, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::navStateChanged, 8))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::bookmarkedChanged, 9))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::zoomChanged, 10))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::permissionsListChanged, 11))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::filtersChanged, 12))
            return;
        if (QtMocHelpers::indexOfMethod<void (BrowserWindow::*)()>(_a, &BrowserWindow::focusAddressRequested, 13))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QString*>(_v) = _t->currentUrl(); break;
        case 1: *reinterpret_cast<QString*>(_v) = _t->currentHost(); break;
        case 2: *reinterpret_cast<QString*>(_v) = _t->currentTitle(); break;
        case 3: *reinterpret_cast<QString*>(_v) = _t->permission(); break;
        case 4: *reinterpret_cast<int*>(_v) = _t->loadProgress(); break;
        case 5: *reinterpret_cast<bool*>(_v) = _t->loading(); break;
        case 6: *reinterpret_cast<QVariantList*>(_v) = _t->tabs(); break;
        case 7: *reinterpret_cast<QString*>(_v) = _t->section(); break;
        case 8: *reinterpret_cast<bool*>(_v) = _t->canGoBack(); break;
        case 9: *reinterpret_cast<bool*>(_v) = _t->canGoForward(); break;
        case 10: *reinterpret_cast<bool*>(_v) = _t->bookmarked(); break;
        case 11: *reinterpret_cast<int*>(_v) = _t->zoomPercent(); break;
        case 12: *reinterpret_cast<QStringList*>(_v) = _t->trustedSites(); break;
        case 13: *reinterpret_cast<QStringList*>(_v) = _t->blockedSites(); break;
        case 14: *reinterpret_cast<int*>(_v) = _t->filterLists(); break;
        case 15: *reinterpret_cast<bool*>(_v) = _t->filtersBusy(); break;
        case 16: *reinterpret_cast<QString*>(_v) = _t->versionInfo(); break;
        case 17: *reinterpret_cast<QString*>(_v) = _t->dataFolder(); break;
        default: break;
        }
    }
}

const QMetaObject *BrowserWindow::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *BrowserWindow::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN13BrowserWindowE_t>.strings))
        return static_cast<void*>(this);
    return QMainWindow::qt_metacast(_clname);
}

int BrowserWindow::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QMainWindow::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 40)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 40;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 40)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 40;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 18;
    }
    return _id;
}

// SIGNAL 0
void BrowserWindow::currentUrlChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void BrowserWindow::currentHostChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void BrowserWindow::currentTitleChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void BrowserWindow::permissionChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void BrowserWindow::loadProgressChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void BrowserWindow::loadingChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void BrowserWindow::tabsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void BrowserWindow::sectionChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 7, nullptr);
}

// SIGNAL 8
void BrowserWindow::navStateChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 8, nullptr);
}

// SIGNAL 9
void BrowserWindow::bookmarkedChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 9, nullptr);
}

// SIGNAL 10
void BrowserWindow::zoomChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 10, nullptr);
}

// SIGNAL 11
void BrowserWindow::permissionsListChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 11, nullptr);
}

// SIGNAL 12
void BrowserWindow::filtersChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 12, nullptr);
}

// SIGNAL 13
void BrowserWindow::focusAddressRequested()
{
    QMetaObject::activate(this, &staticMetaObject, 13, nullptr);
}
QT_WARNING_POP
