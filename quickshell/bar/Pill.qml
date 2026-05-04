import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
  id: pill
  default property alias content: inner.data
  property int paddingH: 12
  property int paddingV: 5

  height: 24
  width: inner.implicitWidth + paddingH * 2
  radius: height / 2
  color: Colors.barPill

  Item {
    id: inner
    anchors {
      left: parent.left; right: parent.right
      verticalCenter: parent.verticalCenter
      leftMargin: pill.paddingH; rightMargin: pill.paddingH
    }
    implicitWidth: {
      var w = 0
      for (var i = 0; i < children.length; i++)
        w += children[i].implicitWidth || children[i].width || 0
      return w
    }
    implicitHeight: 24
  }
}
