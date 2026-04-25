import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
  property var selectedItem: null

  color: "transparent"

  RowLayout {
    anchors.fill: parent
    spacing: 16

    Text {
      text: "Enter abrir"
      color: Colors.text3
      font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
    }

    Text {
      text: "Ctrl+K fixar"
      color: Colors.text3
      font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
    }

    Text {
      text: "Ctrl+R reindexar"
      color: Colors.text3
      font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
    }

    Text {
      text: "Tab acoes"
      color: Colors.text3
      font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
    }

    Text {
      text: "PgUp/PgDn navegar"
      color: Colors.text3
      font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
    }

    Item { Layout.fillWidth: true }

    Text {
      text: selectedItem
        ? ((selectedItem.pinned ? "Fixado" : "") +
           (selectedItem.actionCount > 0 ? (selectedItem.pinned ? " · " : "") + selectedItem.actionCount + " acoes" : "") +
           ((selectedItem.pinned || selectedItem.actionCount > 0) ? " · " : "") +
           (selectedItem.source === "flatpak" ? "Flatpak" : selectedItem.source === "user" ? "Local" : "Sistema"))
        : "Esc fechar"
      color: Colors.text3
      font { pixelSize: 10; family: "JetBrainsMono Nerd Font" }
    }
  }
}
