pragma Singleton
import QtQuick

QtObject {
  property bool launcherOpen: false
  property bool launcherVisible: false
  property real launcherOffsetScale: 1
  property int launcherWidth: 720
  property int launcherHeight: 456

  property bool themePickerOpen: false
  property bool themePickerVisible: false
  property real themePickerOffsetScale: 1
  property int themePickerWidth: 1040
  property int themePickerHeight: 452
}
