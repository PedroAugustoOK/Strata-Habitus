import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".."

PanelWindow {
  id: root
  anchors { top: true; left: true; right: true; bottom: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  focusable: true
  visible: CalendarMenuState.visible

  readonly property real panelWidth: 318
  readonly property real panelX: Math.max(12, Math.min(width - panelWidth - 12, CalendarMenuState.anchorX - panelWidth / 2))
  readonly property real panelY: Math.max(44, CalendarMenuState.anchorY)
  readonly property int dayCellWidth: 36
  readonly property int cellSpacing: 6
  property bool opening: false

  readonly property var weekdayShort: ["D", "S", "T", "Q", "Q", "S", "S"]
  readonly property var monthNames: ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]

  readonly property date baseDate: {
    const now = new Date()
    return new Date(now.getFullYear(), now.getMonth() + CalendarMenuState.monthOffset, 1)
  }
  readonly property int daysInMonth: new Date(baseDate.getFullYear(), baseDate.getMonth() + 1, 0).getDate()
  readonly property int firstWeekday: baseDate.getDay()
  readonly property int totalCells: Math.ceil((firstWeekday + daysInMonth) / 7) * 7
  readonly property int totalRows: Math.ceil(totalCells / 7)

  function close() {
    CalendarMenuState.close()
  }

  function isToday(dayNumber) {
    const now = new Date()
    return dayNumber > 0
      && now.getFullYear() === baseDate.getFullYear()
      && now.getMonth() === baseDate.getMonth()
      && now.getDate() === dayNumber
  }

  Item {
    id: keyGrabber
    focus: root.visible
    Keys.onPressed: function(e) {
      if (e.key === Qt.Key_Escape) {
        root.close()
        e.accepted = true
      } else if (e.key === Qt.Key_Left) {
        CalendarMenuState.monthOffset--
        e.accepted = true
      } else if (e.key === Qt.Key_Right) {
        CalendarMenuState.monthOffset++
        e.accepted = true
      } else if (e.key === Qt.Key_Home || e.key === Qt.Key_T) {
        CalendarMenuState.monthOffset = 0
        e.accepted = true
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      opening = true
      keyGrabber.forceActiveFocus()
      openAnim.restart()
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: panel
    x: root.panelX
    y: root.panelY
    width: root.panelWidth
    height: content.implicitHeight + 20
    radius: 18
    color: Colors.bg1
    border.width: 1
    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
    opacity: root.opening ? 0 : 1
    scale: root.opening ? 0.97 : 1
    transformOrigin: Item.Top

    ParallelAnimation {
      id: openAnim
      NumberAnimation { target: panel; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
      NumberAnimation { target: panel; property: "scale"; from: 0.97; to: 1; duration: 220; easing.type: Easing.OutCubic }
      onFinished: root.opening = false
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius - 1
      color: "transparent"
      border.width: 1
      border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.07 : 0.10)
    }

    Column {
      id: content
      anchors.fill: parent
      anchors.margins: 10
      spacing: 10

      Row {
        width: parent.width
        spacing: 8

        Rectangle {
          width: 32
          height: 32
          radius: 16
          color: prevMouse.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14) : "transparent"

          Text {
            anchors.centerIn: parent
            text: "‹"
            color: Colors.text1
            font { family: "JetBrains Mono"; pixelSize: 18 }
          }

          MouseArea {
            id: prevMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: CalendarMenuState.monthOffset--
          }
        }

        Column {
          width: parent.width - 80
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            width: parent.width
            text: root.monthNames[root.baseDate.getMonth()] + " " + root.baseDate.getFullYear()
            color: Colors.text1
            horizontalAlignment: Text.AlignHCenter
            font { family: "Roboto"; pixelSize: 15; weight: Font.Bold }
          }

          Text {
            width: parent.width
            text: CalendarMenuState.monthOffset === 0
              ? Qt.formatDateTime(new Date(), "dddd, d 'de' MMMM")
              : "←/→ muda o mês  •  Home volta para hoje"
            color: Colors.text3
            horizontalAlignment: Text.AlignHCenter
            font { family: "Roboto"; pixelSize: 10 }
          }
        }

        Rectangle {
          width: 32
          height: 32
          radius: 16
          color: nextMouse.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14) : "transparent"

          Text {
            anchors.centerIn: parent
            text: "›"
            color: Colors.text1
            font { family: "JetBrains Mono"; pixelSize: 18 }
          }

          MouseArea {
            id: nextMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: CalendarMenuState.monthOffset++
          }
        }
      }

      Column {
        width: parent.width
        spacing: 6

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: root.cellSpacing

          Repeater {
            model: 7
            delegate: Text {
              required property int index
              width: root.dayCellWidth
              height: 18
              horizontalAlignment: Text.AlignHCenter
              text: root.weekdayShort[index]
              color: Colors.text3
              font { family: "JetBrains Mono"; pixelSize: 10; weight: Font.DemiBold }
            }
          }
        }

        Repeater {
          model: root.totalRows
          delegate: Row {
            id: weekRow
            required property int index            
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.cellSpacing

            Repeater {
              model: 7
              delegate: Rectangle {
                required property int index
                readonly property int cellIndex: (weekRow.index * 7) + index
                readonly property int dayNumber: {
                  const d = cellIndex - root.firstWeekday + 1
                  return d >= 1 && d <= root.daysInMonth ? d : 0
                }
                readonly property bool today: root.isToday(dayNumber)
                readonly property bool weekend: (index === 0) || (index === 6)

                width: root.dayCellWidth
                height: 36
                radius: 14
                color: today
                  ? Colors.accent
                  : weekend && dayNumber > 0
                    ? Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.03 : 0.05)
                    : "transparent"
                border.width: dayNumber > 0 && !today ? 1 : 0
                border.color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.06 : 0.10)
                opacity: dayNumber > 0 ? 1 : 0

                Text {
                  anchors.centerIn: parent
                  text: parent.dayNumber > 0 ? parent.dayNumber.toString() : ""
                  color: parent.today ? Colors.bg0 : Colors.text1
                  font { family: "Roboto"; pixelSize: 12; weight: parent.today ? Font.Bold : Font.Medium }
                }
              }
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.08 : 0.12)
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: "Use ← → para navegar entre os meses"
        color: Colors.text3
        font { family: "JetBrains Mono"; pixelSize: 9 }
      }

      Rectangle {
        width: parent.width
        height: 42
        radius: 14
        color: Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.03 : 0.05)

        Row {
          anchors.fill: parent
          anchors.margins: 12
          spacing: 10

          Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.accent

            Text {
              anchors.centerIn: parent
              text: new Date().getDate().toString()
              color: Colors.bg0
              font { family: "Roboto"; pixelSize: 9; weight: Font.Bold }
            }
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
              text: "Hoje"
              color: Colors.text1
              font { family: "Roboto"; pixelSize: 11; weight: Font.Bold }
            }

            Text {
              text: Qt.formatDateTime(new Date(), "dddd, d 'de' MMMM")
              color: Colors.text3
              font { family: "Roboto"; pixelSize: 10 }
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 38
        radius: 14
        color: todayMouse.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14) : Qt.rgba(Colors.text1.r, Colors.text1.g, Colors.text1.b, Colors.darkMode ? 0.03 : 0.05)

        Text {
          anchors.centerIn: parent
          text: "Voltar para hoje"
          color: Colors.text1
          font { family: "JetBrains Mono"; pixelSize: 11 }
        }

        MouseArea {
          id: todayMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: CalendarMenuState.monthOffset = 0
        }
      }
    }
  }
}
