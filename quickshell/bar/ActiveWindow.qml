import Quickshell.Hyprland
import QtQuick

Text {
  property string title: {
    if (Hyprland.focusedClient === null) return ""
    var t = Hyprland.focusedClient.title || ""
    return t.length > 50 ? t.substring(0, 47) + "…" : t
  }

  text: title
  color: title === "" ? "transparent" : "#888888"
  font { pixelSize: 11; family: "JetBrainsMono Nerd Font" }
  elide: Text.ElideRight
}
