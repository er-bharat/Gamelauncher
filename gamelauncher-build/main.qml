import QtQuick           6.4
import QtQuick.Controls  6.4
import QtQuick.Layouts   6.4

ApplicationWindow {
    width: 1100
    height: 700
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint
    title: "Game Launcher"

    /*----------------------------Background--------------------------------*/

    //Background color
    Item {
        anchors.fill: parent
        z: -1

        Rectangle {
            anchors.fill: parent
            radius: 10  // Rounded corners
            color: Qt.rgba(0, 0, 1, 0.2)
        }
    }

    //Game editor
    Button {
        text: "Games " + totalItems
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 20
        // width: 120
        height: 40
        font.pixelSize: 25
        font.family: "URW Gothic"
        background: Rectangle {
            color: Qt.rgba(0, 0, 1, 0.08)
            radius: 4
        }
        onClicked: backend.edit_ini()
        z:10
    }

    //Close button
    Button {
        text: "✕"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 30
        height: 30
        font.pixelSize: 18
        z: 100
        background: Rectangle {
            color: Qt.rgba(0, 0, 1, 0.08)
            radius: 4
        }
        onClicked: Qt.quit()
    }



    /* ---------------------------- configuration --------------------------- */
    property int cardWidth   : Math.max(width * 0.2, 250)
    property int cardHeight  : cardWidth * 1.3
    property real cardSpacing: width * 0.3
    property int currentIndex: 0
    readonly property int totalItems: gameList.length                    // from Python



    /*----------------------------- Search games -----------------------------*/
    property string searchText: ""
    property var filteredIndexes: []
    property int filteredIndex: 0

    TextField {
        id: searchField
        placeholderText: "Search games..."
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // anchors.left: parent.left
        // anchors.right: parent.right
        anchors.margins: 20
        width: parent.width * 0.6
        height: 40
        font.pixelSize: 18
        focus: false
        horizontalAlignment: Text.AlignHCenter
        color: "black"
        z: 10

        background: Rectangle {
            color: Qt.rgba(0, 0, 1, 0.2)
            radius: 40
            border.color: Qt.rgba(0.6, 0.6, 01, 0.6)
            border.width: 2
        }

        Keys.onReturnPressed: {
            searchField.focus = false
            focusRoot.focus = true
        }

        onTextChanged: {
            searchText = text.toLowerCase()
            filteredIndexes = []

            for (let i = 0; i < gameList.length; ++i) {
                if (gameList[i].title.toLowerCase().includes(searchText)) {
                    filteredIndexes.push(i)
                }
            }

            if (filteredIndexes.length > 0) {
                filteredIndex = 0
                currentIndex = filteredIndexes[filteredIndex]
                scroll()
            }
        }
    }

    MouseArea {
        id: backgroundClickArea
        anchors.fill: parent
        z: 0  // Behind all controls
        acceptedButtons: Qt.LeftButton
        onClicked: {
            searchField.focus = false
            focusRoot.focus = true
        }
    }


    /* --------------------------- key navigation --------------------------- */
    FocusScope {
        id: focusRoot
        anchors.fill: parent
        focus: true                               // receive keyboard

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Left && currentIndex > 0) {
                currentIndex--
                scroll()
                event.accepted = true
            } else if (event.key === Qt.Key_Right && currentIndex < totalItems - 1) {
                currentIndex++
                scroll()
                event.accepted = true
            } else if (event.key === Qt.Key_Tab && filteredIndexes.length > 0) {
                filteredIndex = (filteredIndex + 1) % filteredIndexes.length
                currentIndex = filteredIndexes[filteredIndex]
                scroll()
                event.accepted = true
            } else if (event.key === Qt.Key_Backtab && filteredIndexes.length > 0) {
                filteredIndex = (filteredIndex - 1 + filteredIndexes.length) % filteredIndexes.length
                currentIndex = filteredIndexes[filteredIndex]
                scroll()
                event.accepted = true
            } else if (event.key === Qt.Key_Return && currentIndex >= 0 && currentIndex < gameList.length) {
                backend.launch(gameList[currentIndex].exec)
                event.accepted = true
            }
            if (event.key === Qt.Key_F && event.modifiers & Qt.ControlModifier) {
                if (searchField.focus) {
                    searchField.focus = false
                    focusRoot.focus = true  // move focus back to main UI
                } else {
                    searchField.focus = true
                }
                event.accepted = true
            }
        }

        Keys.onReturnPressed: {
            if (currentIndex >= 0 && currentIndex < totalItems) {
                backend.launch(gameList[currentIndex].exec)
            }
        }

        //Mouse buttons
        WheelHandler {
            id: wheelHandler
            target: flick
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            orientation: Qt.Vertical

            onWheel: (event) => {
                const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y * 1.17

                if (Math.abs(delta) < 20)
                    return  // Ignore small/noise deltas

                    if (delta > 0 && currentIndex > 0) {
                        currentIndex--        // ⬇ scroll down = move left
                        scroll()
                    } else if (delta < 0 && currentIndex < totalItems - 1) {
                        currentIndex++        // ⬆ scroll up = move right
                        scroll()
                    }

                    event.accepted = true
            }
        }


        /* ------------------------ flickable carousel ----------------------- */
        Flickable {
            id: flick
            anchors.fill: parent
            interactive: false                     // only arrows / programmatic
            // orientation: Flickable.HorizontalFlick
            contentWidth: row.width

            Behavior on contentX {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }

            Row {
                id: row
                spacing: cardSpacing
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin : (flick.width - cardWidth) / 2
                anchors.rightMargin: (flick.width - cardWidth) / 2

                Repeater {
                    model: gameList               // provided by main.py
                    delegate: Rectangle {
                        id: card
                        width: cardWidth
                        height: cardHeight
                        radius: 16
                        color: Qt.rgba(0, 0, 1, 0.2)
                        border.color: Qt.rgba(0.6, 0.6, 01, 0.6)
                        border.width: 7
                        antialiasing: true
                        transformOrigin: Item.Center

                        // SCALE TRANSFORM
                        transform: Scale {
                            id: scaleTransform
                            origin.x: card.width / 2
                            origin.y: card.height / 2
                            xScale: index === currentIndex ? 1.5 : 1.0
                            yScale: index === currentIndex ? 1.5 : 1.0

                            NumberAnimation on xScale {
                                duration: 400
                                easing.type: Easing.OutBack
                            }
                            NumberAnimation on yScale {
                                duration: 400
                                easing.type: Easing.OutBack
                            }
                        }

                        // Game Cover art
                        Image {
                            anchors.centerIn: parent
                            anchors.topMargin: 0
                            width: parent.width * 0.98
                            height: parent.height * 0.95
                            fillMode: Image.PreserveAspectFit
                            source: modelData.image
                        }

                        //Game Title
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: - 50
                            color: "black"          // background color
                            radius: 12             // roundness of corners
                            // anchors.horizontalCenter: parent.horizontalCenter
                            width: cardWidth * 0.8   // some horizontal padding
                            height: 30 // some vertical padding

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 5
                                width: parent.width * 0.9
                                wrapMode: Text.WordWrap
                                font.pixelSize: 18
                                font.family: "URW Gothic"
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.title
                            }
                        }



                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.launch(modelData.exec)
                            onEntered: parent.color = Qt.rgba(0, 0, 1, 0.9)
                            onExited: parent.color = Qt.rgba(0, 0, 1, 0.2)
                        }
                    }

                }
            }
        }
    }

    /* ---------------------------- helpers --------------------------------- */
    function scroll() {
        const offset = (flick.width - cardWidth) / 2
        flick.contentX = currentIndex * (cardWidth + cardSpacing) - offset
    }

    Component.onCompleted: scroll()                // centre first card at startup



}
