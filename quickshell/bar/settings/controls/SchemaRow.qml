pragma ComponentBehavior: Bound
import ".."
import QtQuick

// SchemaRow — вибирає тип контрола за field.type.
Loader {
    id: root
    required property string cat
    required property string key
    required property var field

    sourceComponent: {
        switch (root.field.type) {
        case "bool":  return boolComp
        case "num":   return numComp
        case "enum":  return enumComp
        case "color": return colorComp
        case "str":   return strComp
        case "pos":   return posComp
        }
        return null
    }

    Component { id: boolComp
        RowSwitch { cat: root.cat; key: root.key; field: root.field }
    }
    Component { id: numComp
        RowSlider { cat: root.cat; key: root.key; field: root.field }
    }
    Component { id: enumComp
        RowDropdown { cat: root.cat; key: root.key; field: root.field }
    }
    Component { id: colorComp
        RowColor { cat: root.cat; key: root.key; field: root.field }
    }
    Component { id: posComp
        RowPosition { cat: root.cat; key: root.key; field: root.field }
    }
    Component { id: strComp
        RowText { cat: root.cat; key: root.key; field: root.field }
    }
}
