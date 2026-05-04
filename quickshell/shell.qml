import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "bar"
import "launcher"
import "notifications"
import "osd"
import "osd_bright"
import "themepicker"
import "controlcenter"
import "powermenu"
import "clipboard"
import "wallpickr"
import "appcenter"
import "updatecenter"
import "settingscenter"
import "screenshot"

ShellRoot {
  Bar {}
  TrayMenu {}
  CalendarMenu {}
  Launcher { id: launcher }
  // Notifications {}
  OSD {}
  OsdbRight {}
  ControlCenter { id: controlCenter }
  PowerMenu { id: powerMenu }
  ThemePicker { id: themePicker }
  WallPickr { id: wallPickr }
  Clipboard { id: clipboard }
  AppCenter { id: appCenter }
  UpdateCenter { id: updateCenter }
  ScreenshotSelector { id: screenshotSelector }
  SettingsCenter {
    id: settingsCenter
    onOpenControlCenter: controlCenter.toggle()
    onOpenThemePicker: themePicker.toggle()
    onOpenWallPickr: wallPickr.toggle()
    onOpenAppCenter: appCenter.toggle()
    onOpenUpdateCenter: updateCenter.toggle()
  }

  readonly property string clipboardDaemonScript: Qt.resolvedUrl("./scripts/clipboard-daemon.sh").toString().replace("file://", "")
  readonly property string notificationIconDaemonScript: Qt.resolvedUrl("./scripts/notification-icon-daemon.sh").toString().replace("file://", "")
  readonly property string spotifyNotifyScript: Qt.resolvedUrl("./scripts/spotify-notify.sh").toString().replace("file://", "")

  Component.onCompleted: {
    clipboardDaemon.command = ["/run/current-system/sw/bin/bash", clipboardDaemonScript, "start"]
    clipboardDaemon.running = true
    notificationIconDaemon.command = ["/run/current-system/sw/bin/bash", notificationIconDaemonScript, "start"]
    notificationIconDaemon.running = true
    spotifyNotify.command = ["/run/current-system/sw/bin/bash", spotifyNotifyScript, "start"]
    spotifyNotify.running = true
  }

  readonly property int barH: 34
  readonly property int brd: 10
  readonly property int r: 12

  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    visible: powerMenu.visible
    mask: Region {}
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) powerMenu.close()
    }
    MouseArea {
      anchors.fill: parent
      onClicked: powerMenu.close()
    }
  }

  Process {
    id: spotifyNotify
    command: []
  }
  Process {
    id: notificationIconDaemon
    command: []
  }

  // Borda esquerda — começa abaixo da bar
  PanelWindow {
    anchors { left: true; bottom: true }
    implicitWidth: brd
    implicitHeight: Screen.height - barH
    color: Colors.bg1
    exclusionMode: ExclusionMode.Ignore
  }

  // Arco superior esquerdo
  PanelWindow {
    anchors { top: true; left: true }
    implicitWidth: brd + r
    implicitHeight: barH + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: cv1arc }
    Canvas {
      id: cv1
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const bh = barH, b = brd, rv = r
        ctx.clearRect(0, 0, width, height)
        ctx.fillStyle = Colors.bg1.toString()
        ctx.fillRect(0, 0, b, bh)
        ctx.beginPath()
        ctx.moveTo(b, bh); ctx.lineTo(b, bh + rv)
        ctx.arc(b + rv, bh + rv, rv, Math.PI, -Math.PI / 2, false)
        ctx.lineTo(b, bh); ctx.closePath(); ctx.fill()
      }
      Connections {
        target: Colors
        function onBg1Changed() { cv1.requestPaint() }
      }
    }
    Item {
      id: cv1arc
      x: 0; y: barH
      width: brd
      height: r
    }
  }

  // Borda direita — começa abaixo da bar
  PanelWindow {
    anchors { right: true; bottom: true }
    implicitWidth: brd
    implicitHeight: Screen.height - barH
    color: Colors.bg1
    exclusionMode: ExclusionMode.Ignore
  }

  // Arco superior direito
  PanelWindow {
    anchors { top: true; right: true }
    implicitWidth: brd + r
    implicitHeight: barH + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: cv2arc }
    Canvas {
      id: cv2
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const bh = barH, b = brd, rv = r, w = width
        ctx.clearRect(0, 0, w, height)
        ctx.fillStyle = Colors.bg1.toString()
        ctx.fillRect(rv, 0, b, bh)
        ctx.beginPath()
        ctx.moveTo(rv, bh); ctx.lineTo(rv, bh + rv)
        ctx.arc(0, bh + rv, rv, 0, -Math.PI / 2, true)
        ctx.lineTo(rv, bh); ctx.closePath(); ctx.fill()
      }
      Connections {
        target: Colors
        function onBg1Changed() { cv2.requestPaint() }
      }
    }
    Item {
      id: cv2arc
      x: r; y: barH
      width: brd
      height: r
    }
  }

  // Borda inferior
  PanelWindow {
    anchors { left: true; right: true; bottom: true }
    implicitHeight: brd
    color: Colors.bg1
    exclusionMode: ExclusionMode.Ignore
  }

  // Canto inferior esquerdo
  PanelWindow {
    anchors { left: true; bottom: true }
    implicitWidth: brd + r
    implicitHeight: brd + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Canvas {
      id: cv3
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const b = brd, rv = r, h = height
        ctx.clearRect(0, 0, width, h)
        ctx.fillStyle = Colors.bg1.toString()
        ctx.fillRect(0, 0, b, h - b)
        ctx.fillRect(b, h - b, rv, b)
        ctx.beginPath()
        ctx.moveTo(b, h - b)
        ctx.arc(b + rv, h - b - rv, rv, Math.PI / 2, Math.PI, false)
        ctx.closePath(); ctx.fill()
      }
      Connections {
        target: Colors
        function onBg1Changed() { cv3.requestPaint() }
      }
    }
  }

  // Canto inferior direito
  PanelWindow {
    anchors { right: true; bottom: true }
    implicitWidth: brd + r
    implicitHeight: brd + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    Canvas {
      id: cv4
      anchors.fill: parent
      Component.onCompleted: requestPaint()
      onPaint: {
        const ctx = getContext("2d")
        const b = brd, rv = r, w = width, h = height
        ctx.clearRect(0, 0, w, h)
        ctx.fillStyle = Colors.bg1.toString()
        ctx.fillRect(rv, 0, b, h - b)
        ctx.fillRect(0, h - b, rv, b)
        ctx.beginPath()
        ctx.moveTo(rv, h - b)
        ctx.arc(0, h - b - rv, rv, Math.PI / 2, 0, true)
        ctx.closePath(); ctx.fill()
      }
      Connections {
        target: Colors
        function onBg1Changed() { cv4.requestPaint() }
      }
    }
  }

  IpcHandler {
    target: "launcher"
    function toggle(): void { launcher.toggle() }
  }
  IpcHandler {
    target: "controlcenter"
    function toggle(): void { controlCenter.toggle() }
  }
  IpcHandler {
    target: "powermenu"
    function toggle(): void { powerMenu.toggle() }
  }
  IpcHandler {
    target: "wallPickr"
    function toggle(): void { wallPickr.toggle() }
  }
  IpcHandler {
    target: "clipboard"
    function toggle(): void { clipboard.toggle() }
  }
  IpcHandler {
    target: "themepicker"
    function toggle(): void { themePicker.toggle() }
  }
  IpcHandler {
    target: "appcenter"
    function toggle(): void { appCenter.toggle() }
  }
  IpcHandler {
    target: "updatecenter"
    function toggle(): void { updateCenter.toggle() }
  }
  IpcHandler {
    target: "settingscenter"
    function toggle(): void { settingsCenter.toggle() }
  }
  IpcHandler {
    target: "screenshot"
    function select(requestId: string): void { screenshotSelector.select(requestId) }
  }

  Process {
    id: clipboardDaemon
    command: []
  }
}
