pragma Singleton
import QtQuick
import ".."

QtObject {
  readonly property int barHeight: 34
  readonly property int screenVerticalMargin: 56
  readonly property int bottomInset: 22
  readonly property int bottomWindowPad: 96
  readonly property int rightWindowPad: 18
  readonly property int rightPanelGutter: 10
  readonly property int rightPanelSlideOffset: 28
  readonly property int controlCenterWindowPad: 28
  readonly property int contentHeightPad: 28
  readonly property int controlCenterTopOffset: 44

  readonly property int launcherWidth: 720
  readonly property int themePickerWindowWidth: 1136
  readonly property int themePickerWindowHeight: 472
  readonly property int themePickerContentWidth: 1040
  readonly property int themePickerContentHeight: 430
  readonly property int wallPickrMaxWidth: 820
  readonly property int wallPickrMaxHeight: 500
  readonly property int wallPickrMinHeight: 300
  readonly property int powerMenuHeight: 58
  readonly property int clipboardWidth: 920
  readonly property int clipboardHeight: 620
  readonly property int settingsCenterWidth: 620
  readonly property int updateCenterWidth: 720
  readonly property int appCenterWidth: 920
  readonly property int webAppsWidth: 1040
  readonly property int webAppsHeight: 648
  readonly property int webAppsContentHeight: 628
  readonly property int webAppsRadius: Math.round(32 * Colors.radiusScale)
  readonly property int controlCenterDesktopWidth: 344
  readonly property int controlCenterLaptopWidth: 316

  readonly property int bottomDrawerDuration: 320
  readonly property int rightDrawerDuration: 260
  readonly property int panelOpenDuration: 170
  readonly property int panelOpenOpacityDuration: 130
  readonly property int panelCloseDuration: 110
  readonly property int panelCloseOpacityDuration: 90
  readonly property int controlCenterOpenDuration: 260
  readonly property int controlCenterOpenOpacityDuration: 120
  readonly property int controlCenterCloseDuration: 150
  readonly property int controlCenterCloseOpacityDuration: 110

  readonly property int surfaceRadius: Math.round(18 * Colors.radiusScale)
  readonly property int compactSurfaceRadius: Math.round(16 * Colors.radiusScale)
  readonly property int frameBlend: 12
  readonly property int activeFrameExpansion: 6
  readonly property int activeBottomExpansion: 22
  readonly property int sharedSurfaceShoulder: 28
  readonly property int attachedEdgeDepth: compactSurfaceRadius + 4
  readonly property int attachedEdgeStrokeOffset: compactSurfaceRadius + 3
  readonly property real bottomDrawerClosedScale: 0.035
  readonly property real rightDrawerClosedScale: 0.025
  readonly property real panelOpenScale: 0.988
  readonly property real panelCloseScale: 0.992
  readonly property real controlCenterClosedXScale: 0.965
  readonly property real controlCenterClosedYScale: 0.985

  readonly property var zephyrCurve: [0.23, 1, 0.61, 1, 1, 1]

  function rightPanelHeight(screenHeight) {
    return Math.max(1, screenHeight - screenVerticalMargin)
  }
}
