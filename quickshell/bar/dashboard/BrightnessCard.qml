import "root:/theme"
import QtQuick

// BrightnessCard — окрема картка з одним повзунком для всіх дисплеїв.
DashCard {
    id: root
    title: "Яскравість"

    BrightnessManager {
        width: parent.width
    }
}
