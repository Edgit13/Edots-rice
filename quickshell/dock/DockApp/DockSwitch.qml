import QtQuick
import QtQuick.Controls
import qs.DockApp

// M3 on/off switch for the dock settings dialog.
//
// It shows `value` and reports clicks through toggledTo() instead of owning its
// state: a Switch sets `checked` itself on click, which would break a plain
// `checked: <setting>` binding and stop the switch following changes made
// elsewhere (IPC, the config file). The binding is restored after every click.
Switch {
    id: control

    property bool value: false

    signal toggledTo(bool on)

    checked: control.value
    onToggled: {
        control.toggledTo(control.checked)
        control.checked = Qt.binding(() => control.value)
    }

    implicitWidth: 52
    implicitHeight: 32

    // M3 switch: 52×32 track with 16dp-thumb geometry, rounded fully.
    indicator: Rectangle {
        implicitWidth: 52
        implicitHeight: 32
        radius: 16
        color: control.checked ? DockTheme.primary
                               : DockTheme.surface_container_high
        border.color: control.checked ? DockTheme.primary
                                      : DockTheme.outline_variant
        border.width: 2

        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.OutQuint }
        }

        Rectangle {
            x: control.checked ? parent.width - width - 4 : 4
            y: (parent.height - height) / 2
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: control.checked ? DockTheme.on_primary
                                   : DockTheme.on_surface_variant

            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuint }
            }
            Behavior on color {
                ColorAnimation { duration: 150; easing.type: Easing.OutQuint }
            }
        }
    }
}
