import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property int   currentUser:    userModel.lastIndex
    property int   currentSession: sessionModel.lastIndex
    property color accentColor:    "#8aad91"
    property bool  locked:         true
    property bool  acceptInput:    false

    width:  Screen.width
    height: Screen.height
    color:  "#0d0d0f"

    // lê accent do tema atual
    Timer {
        interval: 100; running: true; repeat: false
        onTriggered: {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///var/lib/strata/theme.conf", false)
            xhr.send()
            var lines = xhr.responseText.split("\n")
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].indexOf("accent=") === 0) {
                    root.accentColor = lines[i].replace("accent=", "").trim()
                    break
                }
            }
        }
    }

    Image {
        anchors.fill: parent
        source: "/var/lib/strata/background.jpg"
        cache: false
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#30000000" }
            GradientStop { position: 0.4; color: "#10000000" }
            GradientStop { position: 1.0; color: "#80000000" }
        }
    }

    // ── Top Bar ─────────────────────────────────────────────
    Text {
        id: dateLabel
        anchors { top: parent.top; left: parent.left; margins: 40 }
        color: "#ccffffff"
        font { pixelSize: 15; family: "Roboto"; weight: Font.Medium }
        text: formatDatePtBr()
        Timer {
            interval: 30000; running: true; repeat: true
            onTriggered: dateLabel.text = formatDatePtBr()
        }
    }

    Row {
        anchors { top: parent.top; right: parent.right; margins: 40 }
        spacing: 16
        IconBtn { icon: "⏾"; onClicked: sddm.suspend()  }
        IconBtn { icon: "⟳"; onClicked: sddm.reboot()   }
        IconBtn { icon: "⏻"; onClicked: sddm.powerOff() }
    }

    Timer {
        id: startupGuard
        interval: 800; running: true
        onTriggered: acceptInput = true
    }

    // ════════════════════════════════════════════════════════
    //  TELA 1 — BLOQUEIO
    // ════════════════════════════════════════════════════════
    Item {
        id: lockScreen
        anchors.fill: parent
        opacity: locked ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

        Column {
            anchors.centerIn: parent
            spacing: -20

            Text {
                id: clockHours
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#e8ffffff"
                font { pixelSize: 160; family: "Roboto"; weight: Font.Bold; letterSpacing: -4 }
                text: "00"
            }

            Text {
                id: clockMinutes
                anchors.horizontalCenter: parent.horizontalCenter
                color: accentColor
                font { pixelSize: 160; family: "Roboto"; weight: Font.Bold; letterSpacing: -4 }
                text: "00"
                opacity: 0.85
            }

            Item { width: 1; height: 16 }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: formatDatePtBr()
                color: "#66ffffff"
                font { pixelSize: 14; family: "Roboto"; weight: Font.Medium; letterSpacing: 1 }
            }
        }

        Text {
            anchors { bottom: parent.bottom; bottomMargin: 60; horizontalCenter: parent.horizontalCenter }
            text: "Pressione qualquer tecla para desbloquear"
            color: "#44ffffff"
            font { pixelSize: 12; family: "Roboto"; letterSpacing: 1 }
        }

        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                var now = new Date()
                clockHours.text   = ("0" + now.getHours()).slice(-2)
                clockMinutes.text = ("0" + now.getMinutes()).slice(-2)
            }
        }

        MouseArea {
            anchors.fill: parent
            z: 100
            enabled: locked
            onClicked: { if (acceptInput) unlock() }
        }
    }

    // ════════════════════════════════════════════════════════
    //  TELA 2 — LOGIN
    // ════════════════════════════════════════════════════════
    Item {
        id: loginScreen
        anchors.fill: parent
        opacity: locked ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InQuad } }

        Column {
            anchors.centerIn: parent
            spacing: 0
            width: 320

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: userModel.data(userModel.index(currentUser, 0), Qt.UserRole + 1) || "Usuário"
                color: "#eeffffff"
                font { pixelSize: 24; family: "Roboto"; weight: Font.DemiBold; letterSpacing: 0.5 }
            }

            Item { width: 1; height: 10 }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: sessionText.implicitWidth + 24
                height: 26; radius: 6
                color: "#18ffffff"

                Text {
                    id: sessionText
                    anchors.centerIn: parent
                    color: "#aaffffff"
                    font { pixelSize: 11; family: "Roboto"; weight: Font.Medium }
                    text: getSessionName(currentSession)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        currentSession = (currentSession + 1) % sessionModel.rowCount()
                        sessionText.text = getSessionName(currentSession)
                    }
                }
            }

            Item { width: 1; height: 30 }

            Rectangle {
                id: passContainer
                anchors.horizontalCenter: parent.horizontalCenter
                width: 280; height: 44; radius: 22
                color: "#15ffffff"
                border.color: passwordField.activeFocus ? accentColor : "#25ffffff"
                border.width: 1
                transform: Translate { id: shakeTranslate; x: 0 }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                TextField {
                    id: passwordField
                    anchors { fill: parent; leftMargin: 20; rightMargin: 50 }
                    verticalAlignment: Text.AlignVCenter
                    echoMode: TextInput.Password
                    placeholderText: "Senha"
                    color: "#e0ffffff"
                    placeholderTextColor: "#55ffffff"
                    font { pixelSize: 13; family: "Roboto" }
                    background: Item {}
                    onAccepted: doLogin()
                    Keys.onPressed: function(event) { errorMsg.visible = false }
                }

                Rectangle {
                    anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    width: 36; height: 36; radius: 18
                    color: passwordField.text.length > 0 ? accentColor : "#20ffffff"
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        color: passwordField.text.length > 0 ? "#0d0d0f" : "#55ffffff"
                        font { pixelSize: 16; weight: Font.Bold }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: doLogin()
                    }
                }
            }

            Item { width: 1; height: 14 }

            Text {
                id: errorMsg
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Senha incorreta"
                color: "#ff6b6b"
                font { pixelSize: 12; family: "Roboto" }
                visible: false
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeTranslate; property: "x"; to: -10; duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: 10;  duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: -5;  duration: 50 }
        NumberAnimation { target: shakeTranslate; property: "x"; to: 0;   duration: 50 }
    }

    function getSessionName(idx) {
        var raw = sessionModel.data(sessionModel.index(idx, 0), Qt.DisplayRole) || ""
        if (raw === "") raw = sessionModel.data(sessionModel.index(idx, 0), Qt.UserRole + 2) || ""
        if (raw === "") raw = sessionModel.data(sessionModel.index(idx, 0), Qt.UserRole + 1) || ""
        if (raw.indexOf("/nix/store/") !== -1) {
            var parts = raw.split("/")
            for (var i = parts.length - 1; i >= 0; i--) {
                if (parts[i].indexOf(".desktop") !== -1) return parts[i].replace(".desktop", "")
                if (parts[i] === "wayland-sessions" || parts[i] === "xsessions") continue
                if (parts[i] === "share") continue
                if (parts[i].length > 0) return parts[i]
            }
        }
        return raw || "Sessão"
    }

    function unlock() {
        locked = false
        passwordField.forceActiveFocus()
    }

    function doLogin() {
        var username = userModel.data(userModel.index(currentUser, 0), Qt.UserRole + 1)
        sddm.login(username, passwordField.text, currentSession)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordField.text = ""
            errorMsg.visible = true
            shakeAnim.start()
        }
        function onLoginSucceeded() {}
    }

    focus: true
    Keys.onPressed: function(event) {
        if (locked && acceptInput) {
            unlock()
            event.accepted = true
        }
    }

    Component.onCompleted: root.forceActiveFocus()

    component IconBtn: Rectangle {
        property string icon
        signal clicked()
        width: 32; height: 32; radius: 16
        color: ma.containsMouse ? "#20ffffff" : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent
            text: parent.icon
            color: "#88ffffff"
            font.pixelSize: 15
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    function formatDatePtBr() {
        var dias  = ["Domingo","Segunda-feira","Terça-feira","Quarta-feira","Quinta-feira","Sexta-feira","Sábado"]
        var meses = ["Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]
        var d = new Date()
        return dias[d.getDay()] + ", " + d.getDate() + " de " + meses[d.getMonth()]
    }
}
