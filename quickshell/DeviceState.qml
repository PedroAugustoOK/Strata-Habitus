pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
  id: root

  property string hostname: "unknown"
  property string profile:  "desktop"

  property bool hasBattery:       false
  property bool hasBrightness:    false
  property bool hasWifi:          false
  property bool hasBluetooth:     false
  property bool hasEthernet:      false
  property bool hasPowerProfiles: false

  readonly property bool isLaptop: profile === "laptop"
  readonly property bool isDesktop: profile === "desktop"

  function refresh() {
    detectProc.running = true
  }

  function applyCapabilities(data) {
    root.hasBattery       = !!data.hasBattery
    root.hasBrightness    = !!data.hasBrightness
    root.hasWifi          = !!data.hasWifi
    root.hasBluetooth     = !!data.hasBluetooth
    root.hasEthernet      = !!data.hasEthernet
    root.hasPowerProfiles = !!data.hasPowerProfiles
  }

  property var _profileFile: FileView {
    path: Paths.state + "/device-profile.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        var data = JSON.parse(text())
        root.hostname = data.hostname || "unknown"
        root.profile = data.profile || "desktop"
      } catch (e) {
        console.log("DeviceState profile parse error:", e.message)
      }
    }
  }

  property var _detectProc: Process {
    id: detectProc
    command: ["/run/current-system/sw/bin/bash", Paths.scripts + "/device-capabilities.sh"]
    stdout: SplitParser {
      onRead: data => {
        try {
          root.applyCapabilities(JSON.parse(data.trim()))
        } catch (e) {
          console.log("DeviceState capability parse error:", e.message)
        }
      }
    }
  }

  Component.onCompleted: refresh()
}
