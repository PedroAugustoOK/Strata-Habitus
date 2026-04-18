pragma Singleton
import QtQuick
import Quickshell

QtObject {
  readonly property string home: Quickshell.env("HOME")
  readonly property string config: home + "/.config/quickshell"
  readonly property string scripts: config + "/scripts"
  readonly property string themes: config + "/themes"
  readonly property string dotfiles: home + "/dotfiles"
  readonly property string wallpapers: dotfiles + "/wallpapers"
}
