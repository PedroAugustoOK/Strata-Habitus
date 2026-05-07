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
import "webapps"
import "screenshot"
import "frame"

ShellRoot {
  property bool integratedFrameEnabled: false
  property bool screenFrameVisible: false
  property bool launcherPanelEnabled: false
  property bool themePickerPanelEnabled: false
  property bool wallPickrPanelEnabled: false
  property bool powerMenuPanelEnabled: false
  property bool clipboardPanelEnabled: false
  property bool settingsCenterPanelEnabled: false
  property bool updateCenterPanelEnabled: false
  property bool appCenterPanelEnabled: false
  property bool frameEdgesEnabled: false
  property bool strataDrawersEnabled: false

  function closeFramePanels(except) {
    if (except !== "launcher") launcherPanel.close()
    if (except !== "themepicker") themePickerPanel.close()
    if (except !== "wallpickr") wallPickrPanel.close()
    if (except !== "powermenu") powerMenuPanel.close()
    if (except !== "clipboard") clipboardPanel.close()
    if (except !== "settingscenter") settingsCenterPanel.close()
    if (except !== "updatecenter") updateCenterPanel.close()
    if (except !== "appcenter") appCenterPanel.close()
    if (except !== "webapps") webApps.close()
    if (except !== "controlcenter" && controlCenter.visible) controlCenter.close()
  }

  function toggleThemePicker() {
    if (integratedFrameEnabled) shellFrame.toggleThemePicker()
    else if (themePickerPanelEnabled) {
      closeFramePanels("themepicker")
      themePickerPanel.toggle()
    } else {
      themePicker.toggle()
    }
  }

  function toggleWallPickr() {
    if (integratedFrameEnabled) shellFrame.toggleWallPickr()
    else if (wallPickrPanelEnabled) {
      closeFramePanels("wallpickr")
      wallPickrPanel.toggle()
    } else {
      wallPickr.toggle()
    }
  }

  function togglePowerMenu() {
    if (integratedFrameEnabled) shellFrame.togglePowerMenu()
    else if (powerMenuPanelEnabled) {
      closeFramePanels("powermenu")
      powerMenuPanel.toggle()
    } else {
      powerMenu.toggle()
    }
  }

  function toggleClipboard() {
    if (integratedFrameEnabled) shellFrame.toggleClipboard()
    else if (clipboardPanelEnabled) {
      closeFramePanels("clipboard")
      clipboardPanel.toggle()
    } else {
      clipboard.toggle()
    }
  }

  function toggleSettingsCenter() {
    if (integratedFrameEnabled) shellFrame.toggleSettingsCenter()
    else if (settingsCenterPanelEnabled) {
      closeFramePanels("settingscenter")
      settingsCenterPanel.toggle()
    } else {
      settingsCenter.toggle()
    }
  }

  function toggleUpdateCenter() {
    if (integratedFrameEnabled) shellFrame.toggleUpdateCenter()
    else if (updateCenterPanelEnabled) {
      closeFramePanels("updatecenter")
      updateCenterPanel.toggle()
    } else {
      updateCenter.toggle()
    }
  }

  function toggleAppCenter() {
    if (integratedFrameEnabled) shellFrame.toggleAppCenter()
    else if (appCenterPanelEnabled) {
      closeFramePanels("appcenter")
      appCenterPanel.toggle()
    } else {
      appCenter.toggle()
    }
  }

  function toggleWebApps() {
    closeFramePanels("webapps")
    webApps.toggle()
  }

  function toggleControlCenter() {
    if (integratedFrameEnabled) shellFrame.closeDrawers("")
    closeFramePanels("controlcenter")
    controlCenter.toggle()
  }

  Loader {
    active: strataDrawersEnabled
    source: strataDrawersEnabled ? Qt.resolvedUrl("frame/StrataDrawers.qml") : ""
    onLoaded: item.active = Qt.binding(function() { return strataDrawersEnabled })
  }
  FrameSharedSurface {}
  Bar {}
  ShellFrame {
    id: shellFrame
    active: integratedFrameEnabled
    onOpenControlCenter: toggleControlCenter()
    onCloseControlCenter: if (controlCenter.visible) controlCenter.close()
    onOpenThemePicker: toggleThemePicker()
    onOpenWallPickr: toggleWallPickr()
    onOpenAppCenter: toggleAppCenter()
    onOpenUpdateCenter: toggleUpdateCenter()
  }
  DynamicIslandCard {}
  TrayMenu {}
  CalendarMenu {}
  FrameEdges { visible: frameEdgesEnabled }
  LauncherPanel { id: launcherPanel }
  ThemePickerPanel { id: themePickerPanel }
  WallPickrPanel { id: wallPickrPanel }
  PowerMenuPanel { id: powerMenuPanel }
  ClipboardPanel { id: clipboardPanel }
  SettingsCenterPanel {
    id: settingsCenterPanel
    onOpenControlCenter: toggleControlCenter()
    onOpenThemePicker: toggleThemePicker()
    onOpenWallPickr: toggleWallPickr()
    onOpenAppCenter: toggleAppCenter()
    onOpenWebApps: toggleWebApps()
    onOpenUpdateCenter: toggleUpdateCenter()
  }
  UpdateCenterPanel { id: updateCenterPanel }
  AppCenterPanel { id: appCenterPanel }
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
  WebApps { id: webApps }
  UpdateCenter { id: updateCenter }
  ScreenshotSelector { id: screenshotSelector }
  SettingsCenter {
    id: settingsCenter
    onOpenControlCenter: toggleControlCenter()
    onOpenThemePicker: toggleThemePicker()
    onOpenWallPickr: toggleWallPickr()
    onOpenAppCenter: toggleAppCenter()
    onOpenWebApps: toggleWebApps()
    onOpenUpdateCenter: toggleUpdateCenter()
  }

  readonly property string clipboardDaemonScript: Qt.resolvedUrl("./scripts/clipboard-daemon.sh").toString().replace("file://", "")
  readonly property string notificationIconDaemonScript: Qt.resolvedUrl("./scripts/notification-icon-daemon.sh").toString().replace("file://", "")
  readonly property string spotifyNotifyScript: Qt.resolvedUrl("./scripts/spotify-notify.sh").toString().replace("file://", "")

  FileView {
    id: shellFrameFlag
    path: Paths.state + "/shell-frame-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      integratedFrameEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  FileView {
    id: launcherPanelFlag
    path: Paths.state + "/launcher-panel-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      launcherPanelEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  FileView {
    id: themePickerPanelFlag
    path: Paths.state + "/theme-picker-panel-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      themePickerPanelEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  FileView {
    id: wallPickrPanelFlag
    path: Paths.state + "/wallpickr-panel-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      wallPickrPanelEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  FileView {
    id: powerMenuPanelFlag
    path: Paths.state + "/powermenu-panel-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      powerMenuPanelEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  FileView {
    id: clipboardPanelFlag
    path: Paths.state + "/clipboard-panel-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      clipboardPanelEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  FileView {
    id: settingsCenterPanelFlag
    path: Paths.state + "/settingscenter-panel-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      settingsCenterPanelEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  FileView {
    id: updateCenterPanelFlag
    path: Paths.state + "/updatecenter-panel-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      updateCenterPanelEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  FileView {
    id: appCenterPanelFlag
    path: Paths.state + "/appcenter-panel-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      appCenterPanelEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  FileView {
    id: frameEdgesFlag
    path: Paths.state + "/frame-edges-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      frameEdgesEnabled = value !== "0" && value !== "false" && value !== "no" && value !== "off"
    }
  }

  FileView {
    id: strataDrawersFlag
    path: Paths.state + "/strata-drawers-enabled"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const value = text().trim().toLowerCase()
      strataDrawersEnabled = value === "1" || value === "true" || value === "yes" || value === "on"
    }
  }

  Component.onCompleted: {
    makoBackend.command = ["/run/current-system/sw/bin/bash", "-lc", "busctl --user --quiet status org.freedesktop.Notifications >/dev/null 2>&1 || systemctl --user start mako 2>/dev/null || exec /run/current-system/sw/bin/mako --config /home/ankh/dotfiles/generated/mako/config"]
    makoBackend.running = true
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
    id: makoBackend
    command: []
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
    visible: screenFrameVisible
  }

  // Arco superior esquerdo
  PanelWindow {
    anchors { top: true; left: true }
    implicitWidth: brd + r
    implicitHeight: barH + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: screenFrameVisible
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
    visible: screenFrameVisible
  }

  // Arco superior direito
  PanelWindow {
    anchors { top: true; right: true }
    implicitWidth: brd + r
    implicitHeight: barH + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: screenFrameVisible
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
    visible: screenFrameVisible
  }

  // Canto inferior esquerdo
  PanelWindow {
    anchors { left: true; bottom: true }
    implicitWidth: brd + r
    implicitHeight: brd + r
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: screenFrameVisible
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
    visible: screenFrameVisible
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
    function toggle(): void {
      if (integratedFrameEnabled) shellFrame.toggleLauncher()
      else if (launcherPanelEnabled) {
        closeFramePanels("launcher")
        launcherPanel.toggle()
      }
      else launcher.toggle()
    }
  }
  IpcHandler {
    target: "controlcenter"
    function toggle(): void { toggleControlCenter() }
  }
  IpcHandler {
    target: "powermenu"
    function toggle(): void { togglePowerMenu() }
  }
  IpcHandler {
    target: "wallPickr"
    function toggle(): void { toggleWallPickr() }
  }
  IpcHandler {
    target: "clipboard"
    function toggle(): void { toggleClipboard() }
  }
  IpcHandler {
    target: "themepicker"
    function toggle(): void { toggleThemePicker() }
  }
  IpcHandler {
    target: "appcenter"
    function toggle(): void { toggleAppCenter() }
  }
  IpcHandler {
    target: "webapps"
    function toggle(): void { toggleWebApps() }
  }
  IpcHandler {
    target: "updatecenter"
    function toggle(): void { toggleUpdateCenter() }
  }
  IpcHandler {
    target: "settingscenter"
    function toggle(): void { toggleSettingsCenter() }
  }
  IpcHandler {
    target: "screenshot"
    function select(requestId: string): void { screenshotSelector.select(requestId) }
    function cancel(): void { screenshotSelector.cancel() }
  }

  Process {
    id: clipboardDaemon
    command: []
  }
}
