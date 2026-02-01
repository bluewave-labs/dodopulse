import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    
    // System metrics
    property real cpuUsage: 0
    property real memUsage: 0
    property real memUsedGB: 0
    property real memTotalGB: 0
    property real diskUsage: 0
    property real diskFreeGB: 0
    property real diskTotalGB: 0
    property string diskMountPoint: "/"
    property string diskModel: ""
    property var otherDisks: []  // [{mount, usage, freeGB, totalGB}, ...]
    property real netIn: 0
    property real netOut: 0
    property real netTotalIn: 0
    property real netTotalOut: 0
    property string localIP: "—"
    property string publicIP: "..."
    property int uptime: 0
    property real loadAvg1: 0
    property real loadAvg5: 0
    property real loadAvg15: 0
    property string kernelVersion: ""
    property int cpuCores: 0
    property string cpuModel: ""
    property int processCount: 0
    
    property real gpuUsage: 0
    property real gpuTemp: 0
    property string gpuName: "—"
    
    property bool hasBattery: false
    property real batteryLevel: 0
    property bool batteryCharging: false
    property string batteryStatus: ""
    
    property real cpuTemp: 0

    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []
    property var netHistory: []

    property real prevCpuTotal: 0
    property real prevCpuBusy: 0
    property real prevNetIn: 0
    property real prevNetOut: 0
    property real prevNetTime: 0

    readonly property color cpuColor: "#5B8DEF"
    readonly property color memColor: "#FF7359"
    readonly property color gpuColor: "#F25990"
    readonly property color netColor: "#40E68D"
    readonly property color netUpColor: "#B266FF"
    readonly property color diskColor: "#F2A60F"
    readonly property color battColor: "#4DE680"
    readonly property color tempColor: "#FF9933"
    readonly property color warningColor: "#FFBF33"
    readonly property color dangerColor: "#FF5959"
    readonly property color systemColor: "#9980E6"

    toolTipMainText: "DodoPulse"
    toolTipSubText: "CPU: " + cpuUsage.toFixed(0) + "% | RAM: " + memUsage.toFixed(0) + "%"

    compactRepresentation: MouseArea {
        Layout.minimumWidth: compactRow.implicitWidth + 8
        Layout.preferredWidth: compactRow.implicitWidth + 8
        Layout.minimumHeight: Kirigami.Units.iconSizes.medium
        
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: 4

            Rectangle {
                Layout.preferredWidth: 4; Layout.preferredHeight: 18; radius: 2
                color: Qt.rgba(cpuColor.r, cpuColor.g, cpuColor.b, 0.3)
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                    height: parent.height * Math.min(cpuUsage / 100, 1); radius: 2
                    color: cpuUsage > 90 ? dangerColor : (cpuUsage > 70 ? warningColor : cpuColor)
                }
            }
            PlasmaComponents.Label { text: cpuUsage.toFixed(0) + "%"; font.pixelSize: 11; font.family: "monospace" }

            Rectangle {
                Layout.preferredWidth: 4; Layout.preferredHeight: 18; radius: 2
                color: Qt.rgba(memColor.r, memColor.g, memColor.b, 0.3)
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                    height: parent.height * Math.min(memUsage / 100, 1); radius: 2
                    color: memUsage > 90 ? dangerColor : (memUsage > 75 ? warningColor : memColor)
                }
            }
            PlasmaComponents.Label { text: memUsage.toFixed(0) + "%"; font.pixelSize: 11; font.family: "monospace" }
        }
    }

    onExpandedChanged: {
        if (expanded) {
            // Force repaint all canvases when popup opens
            Qt.callLater(function() {
                if (cpuCanvas) cpuCanvas.requestPaint()
                if (memCanvas) memCanvas.requestPaint()
                if (gpuCanvas) gpuCanvas.requestPaint()
                if (netCanvas) netCanvas.requestPaint()
            })
        }
    }

    fullRepresentation: Rectangle {
        id: popup
        
        readonly property int cardHeight: 68
        readonly property int networkCardHeight: 85
        readonly property int batteryCards: hasBattery ? 1 : 0
        readonly property int extraDiskCards: otherDisks.length
        
        Layout.preferredWidth: 360
        Layout.preferredHeight: 30 + (6 * cardHeight) + networkCardHeight - cardHeight + (batteryCards * 60) + (extraDiskCards * 50) + (7 * 8) + 28 + 10
        Layout.minimumWidth: 350
        Layout.minimumHeight: 400
        Layout.maximumHeight: 800
        
        color: Kirigami.Theme.backgroundColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                PlasmaComponents.Label { text: "DodoPulse"; font.pixelSize: 16; font.bold: true }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label { text: "↑ " + formatUptime(uptime); font.pixelSize: 11; font.bold: true; opacity: 0.8 }
            }

            // CPU
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 68; radius: 10
                color: Qt.rgba(cpuColor.r, cpuColor.g, cpuColor.b, 0.1)
                border.color: Qt.rgba(cpuColor.r, cpuColor.g, cpuColor.b, 0.3); border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10
                    ColumnLayout {
                        spacing: 2
                        RowLayout {
                            spacing: 6
                            PlasmaComponents.Label {
                                text: cpuUsage.toFixed(1) + "%"; font.pixelSize: 22; font.bold: true
                                color: cpuUsage > 90 ? dangerColor : (cpuUsage > 70 ? warningColor : cpuColor)
                            }
                            Rectangle {
                                visible: cpuTemp > 0; width: cpuTempText.implicitWidth + 10; height: 20; radius: 5
                                color: Qt.rgba(tempColor.r, tempColor.g, tempColor.b, 0.15)
                                PlasmaComponents.Label {
                                    id: cpuTempText; anchors.centerIn: parent
                                    text: cpuTemp.toFixed(0) + "°C"; font.pixelSize: 11; font.bold: true
                                    color: cpuTemp > 85 ? dangerColor : (cpuTemp > 70 ? warningColor : tempColor)
                                }
                            }
                        }
                        PlasmaComponents.Label { text: "CPU"; font.pixelSize: 11; font.bold: true; opacity: 0.9 }
                        PlasmaComponents.Label { text: cpuModel || (cpuCores + " cores"); font.pixelSize: 10; font.bold: true; opacity: 0.7; Layout.maximumWidth: 150; elide: Text.ElideRight }
                    }
                    Item { Layout.fillWidth: true }
                    Canvas {
                        id: cpuCanvas
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 48
                        property var historyData: cpuHistory
                        onHistoryDataChanged: requestPaint()
                        onPaint: drawGraph(getContext("2d"), cpuHistory, cpuColor, width, height)
                        Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.requestPaint() }
                    }
                }
            }

            // Memory
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 68; radius: 10
                color: Qt.rgba(memColor.r, memColor.g, memColor.b, 0.1)
                border.color: Qt.rgba(memColor.r, memColor.g, memColor.b, 0.3); border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10
                    ColumnLayout {
                        spacing: 2
                        PlasmaComponents.Label { text: memUsage.toFixed(1) + "%"; font.pixelSize: 22; font.bold: true; color: memUsage > 90 ? dangerColor : (memUsage > 75 ? warningColor : memColor) }
                        PlasmaComponents.Label { text: "Memory"; font.pixelSize: 11; font.bold: true; opacity: 0.9 }
                        PlasmaComponents.Label { text: memUsedGB.toFixed(1) + " / " + memTotalGB.toFixed(0) + " GB"; font.pixelSize: 10; font.bold: true; opacity: 0.7 }
                    }
                    Item { Layout.fillWidth: true }
                    Canvas {
                        id: memCanvas
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 48
                        property var historyData: memHistory
                        onHistoryDataChanged: requestPaint()
                        onPaint: drawGraph(getContext("2d"), memHistory, memColor, width, height)
                        Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.requestPaint() }
                    }
                }
            }

            // GPU
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 68; radius: 10
                color: Qt.rgba(gpuColor.r, gpuColor.g, gpuColor.b, 0.1)
                border.color: Qt.rgba(gpuColor.r, gpuColor.g, gpuColor.b, 0.3); border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10
                    ColumnLayout {
                        spacing: 2
                        RowLayout {
                            spacing: 6
                            PlasmaComponents.Label { text: gpuUsage.toFixed(0) + "%"; font.pixelSize: 22; font.bold: true; color: gpuColor }
                            Rectangle {
                                visible: gpuTemp > 0; width: gpuTempText.implicitWidth + 10; height: 20; radius: 5
                                color: Qt.rgba(tempColor.r, tempColor.g, tempColor.b, 0.15)
                                PlasmaComponents.Label { id: gpuTempText; anchors.centerIn: parent; text: gpuTemp.toFixed(0) + "°C"; font.pixelSize: 11; font.bold: true; color: gpuTemp > 85 ? dangerColor : (gpuTemp > 70 ? warningColor : tempColor) }
                            }
                        }
                        PlasmaComponents.Label { text: "GPU"; font.pixelSize: 11; font.bold: true; opacity: 0.9 }
                        PlasmaComponents.Label { text: gpuName; font.pixelSize: 10; font.bold: true; opacity: 0.7; Layout.maximumWidth: 150; elide: Text.ElideRight }
                    }
                    Item { Layout.fillWidth: true }
                    Canvas {
                        id: gpuCanvas
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 48
                        property var historyData: gpuHistory
                        onHistoryDataChanged: requestPaint()
                        onPaint: drawGraph(getContext("2d"), gpuHistory, gpuColor, width, height)
                        Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.requestPaint() }
                    }
                }
            }

            // Network
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 85; radius: 10
                color: Qt.rgba(netColor.r, netColor.g, netColor.b, 0.1)
                border.color: Qt.rgba(netColor.r, netColor.g, netColor.b, 0.3); border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 8
                    ColumnLayout {
                        spacing: 2
                        PlasmaComponents.Label { text: "Network"; font.pixelSize: 11; font.bold: true; opacity: 0.9 }
                        RowLayout {
                            spacing: 4
                            PlasmaComponents.Label { text: "↓"; font.pixelSize: 14; font.bold: true; color: netColor }
                            PlasmaComponents.Label { text: formatSpeed(netIn); font.pixelSize: 13; font.bold: true; color: netColor }
                        }
                        RowLayout {
                            spacing: 4
                            PlasmaComponents.Label { text: "↑"; font.pixelSize: 14; font.bold: true; color: netUpColor }
                            PlasmaComponents.Label { text: formatSpeed(netOut); font.pixelSize: 13; font.bold: true; color: netUpColor }
                        }
                        PlasmaComponents.Label { text: "Session: ↓" + formatBytes(netTotalIn) + " ↑" + formatBytes(netTotalOut); font.pixelSize: 9; font.bold: true; opacity: 0.7 }
                    }
                    Item { Layout.fillWidth: true }
                    ColumnLayout {
                        spacing: 1
                        PlasmaComponents.Label { text: "Local: " + localIP; font.pixelSize: 9; font.bold: true; opacity: 0.8; Layout.alignment: Qt.AlignRight }
                        PlasmaComponents.Label { text: "Public: " + publicIP; font.pixelSize: 9; font.bold: true; opacity: 0.8; Layout.alignment: Qt.AlignRight }
                        Canvas {
                            id: netCanvas
                            Layout.preferredWidth: 85
                            Layout.preferredHeight: 38
                            property var historyData: netHistory
                            onHistoryDataChanged: requestPaint()
                            onPaint: drawGraph(getContext("2d"), netHistory, netColor, width, height)
                            Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.requestPaint() }
                        }
                    }
                }
            }

            // Disk - Main
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 70; radius: 10
                color: Qt.rgba(diskColor.r, diskColor.g, diskColor.b, 0.1)
                border.color: Qt.rgba(diskColor.r, diskColor.g, diskColor.b, 0.3); border.width: 1
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 4
                    RowLayout {
                        PlasmaComponents.Label { text: diskUsage.toFixed(0) + "%"; font.pixelSize: 20; font.bold: true; color: diskUsage > 90 ? dangerColor : (diskUsage > 75 ? warningColor : diskColor) }
                        ColumnLayout {
                            spacing: 0
                            PlasmaComponents.Label { text: "Disk"; font.pixelSize: 11; font.bold: true; opacity: 0.9 }
                            PlasmaComponents.Label { text: diskFreeGB.toFixed(0) + " GB free of " + diskTotalGB.toFixed(0) + " GB"; font.pixelSize: 10; font.bold: true; opacity: 0.7 }
                        }
                        Item { Layout.fillWidth: true }
                        ColumnLayout {
                            spacing: 0
                            PlasmaComponents.Label { text: diskMountPoint; font.pixelSize: 10; font.bold: true; opacity: 0.9; Layout.alignment: Qt.AlignRight }
                            PlasmaComponents.Label { text: diskModel; font.pixelSize: 9; font.bold: true; opacity: 0.6; Layout.alignment: Qt.AlignRight; visible: diskModel !== "" }
                        }
                    }
                    Rectangle { Layout.fillWidth: true; height: 6; radius: 3; color: Qt.rgba(0.5, 0.5, 0.5, 0.2); Rectangle { width: parent.width * Math.min(diskUsage / 100, 1); height: parent.height; radius: 3; color: diskUsage > 90 ? dangerColor : (diskUsage > 75 ? warningColor : diskColor) } }
                }
            }

            // Other Mount Points
            Repeater {
                model: otherDisks
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 42; radius: 8
                    color: Qt.rgba(diskColor.r, diskColor.g, diskColor.b, 0.05)
                    border.color: Qt.rgba(diskColor.r, diskColor.g, diskColor.b, 0.2); border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 8
                        PlasmaComponents.Label { text: modelData.usage.toFixed(0) + "%"; font.pixelSize: 14; font.bold: true; color: modelData.usage > 90 ? dangerColor : (modelData.usage > 75 ? warningColor : diskColor) }
                        ColumnLayout {
                            spacing: 0
                            PlasmaComponents.Label { text: modelData.mount; font.pixelSize: 10; font.bold: true; opacity: 0.9 }
                            PlasmaComponents.Label { text: modelData.freeGB.toFixed(0) + " GB free of " + modelData.totalGB.toFixed(0) + " GB"; font.pixelSize: 9; opacity: 0.6 }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredWidth: 60; Layout.preferredHeight: 5; radius: 2
                            color: Qt.rgba(0.5, 0.5, 0.5, 0.2)
                            Rectangle { width: parent.width * Math.min(modelData.usage / 100, 1); height: parent.height; radius: 2; color: modelData.usage > 90 ? dangerColor : (modelData.usage > 75 ? warningColor : diskColor) }
                        }
                    }
                }
            }

            // Battery
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 55; radius: 10; visible: hasBattery
                color: Qt.rgba(battColor.r, battColor.g, battColor.b, 0.1)
                border.color: Qt.rgba(battColor.r, battColor.g, battColor.b, 0.3); border.width: 1
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 4
                    RowLayout {
                        PlasmaComponents.Label { text: batteryLevel.toFixed(0) + "%"; font.pixelSize: 20; font.bold: true; color: batteryCharging ? "#60A5FA" : (batteryLevel < 20 ? dangerColor : battColor) }
                        PlasmaComponents.Label { text: batteryCharging ? "Charging" : "Battery"; font.pixelSize: 11; font.bold: true; opacity: 0.9 }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label { text: batteryStatus; font.pixelSize: 10; font.bold: true; opacity: 0.8 }
                    }
                    Rectangle { Layout.fillWidth: true; height: 6; radius: 3; color: Qt.rgba(0.5, 0.5, 0.5, 0.2); Rectangle { width: parent.width * Math.min(batteryLevel / 100, 1); height: parent.height; radius: 3; color: batteryCharging ? "#60A5FA" : (batteryLevel < 20 ? dangerColor : battColor) } }
                }
            }

            // System
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 10
                color: Qt.rgba(systemColor.r, systemColor.g, systemColor.b, 0.1)
                border.color: Qt.rgba(systemColor.r, systemColor.g, systemColor.b, 0.3); border.width: 1
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 8; spacing: 2
                    RowLayout {
                        PlasmaComponents.Label { text: "System"; font.pixelSize: 11; font.bold: true; opacity: 0.9 }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label { text: "Processes: " + processCount; font.pixelSize: 10; font.bold: true; opacity: 0.8 }
                    }
                    RowLayout {
                        PlasmaComponents.Label { text: "Load: " + loadAvg1.toFixed(2) + "  " + loadAvg5.toFixed(2) + "  " + loadAvg15.toFixed(2); font.pixelSize: 11; font.bold: true; color: systemColor }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label { text: "Kernel: " + kernelVersion; font.pixelSize: 10; font.bold: true; opacity: 0.7 }
                    }
                }
            }
        }
    }

    // Single data source for all commands
    Plasma5Support.DataSource {
        id: dataSource
        engine: "executable"
        connectedSources: []
        interval: 0
        
        onNewData: function(source, data) {
            var out = data["stdout"] || ""
            
            if (source === "cpu") parseCpu(out)
            else if (source === "mem") parseMem(out)
            else if (source === "net") parseNet(out)
            else if (source === "disk") parseDisk(out)
            else if (source === "load") parseLoad(out)
            else if (source === "uptime") uptime = parseInt(out.split(' ')[0]) || 0
            else if (source === "gpu") parseGpu(out)
            else if (source === "battery") parseBattery(out)
            else if (source === "temp") parseTemp(out)
            else if (source === "ip") parseIP(out)
            else if (source === "publicip") publicIP = out.trim() || "—"
            else if (source === "cpumodel") parseCpuModel(out)
            else if (source === "gpuname") parseGpuName(out)
            else if (source === "kernel") kernelVersion = out.trim()
            else if (source === "cores") cpuCores = parseInt(out.trim()) || 0
        }
        
        function exec(id, cmd) {
            if (connectedSources.indexOf(cmd) !== -1) {
                disconnectSource(cmd)
            }
            sourceToId[cmd] = id
            connectSource(cmd)
        }
    }
    
    property var sourceToId: ({})
    
    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        
        onNewData: function(source, data) {
            var out = data["stdout"] || ""
            var id = sourceToId[source]
            
            if (id === "cpu") parseCpu(out)
            else if (id === "mem") parseMem(out)
            else if (id === "net") parseNet(out)
            else if (id === "disk") parseDisk(out)
            else if (id === "disks") parseAllDisks(out)
            else if (id === "diskmodel") parseDiskModel(out)
            else if (id === "load") parseLoad(out)
            else if (id === "uptime") uptime = parseInt(out.split(' ')[0]) || 0
            else if (id === "gpu") parseGpu(out)
            else if (id === "battery") parseBattery(out)
            else if (id === "temp") parseTemp(out)
            else if (id === "ip") parseIP(out)
            else if (id === "publicip") publicIP = out.trim() || "—"
            else if (id === "cpumodel") parseCpuModel(out)
            else if (id === "gpuname") parseGpuName(out)
            else if (id === "kernel") kernelVersion = out.trim()
            else if (id === "cores") cpuCores = parseInt(out.trim()) || 0
            
            delete sourceToId[source]
            disconnectSource(source)
        }
        
        function run(id, cmd) {
            // Add timestamp to make each command unique
            var uniqueCmd = cmd + " #" + Date.now() + Math.random()
            sourceToId[uniqueCmd] = id
            connectSource(uniqueCmd)
        }
    }

    Timer {
        id: fastTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            exec.run("cpu", "cat /proc/stat 2>/dev/null")
            exec.run("mem", "cat /proc/meminfo 2>/dev/null")
            exec.run("net", "cat /proc/net/dev 2>/dev/null")
            exec.run("load", "cat /proc/loadavg 2>/dev/null")
            exec.run("uptime", "cat /proc/uptime 2>/dev/null")
            // Force repaint graphs if expanded
            if (root.expanded) {
                if (cpuCanvas) cpuCanvas.requestPaint()
                if (memCanvas) memCanvas.requestPaint()
                if (gpuCanvas) gpuCanvas.requestPaint()
                if (netCanvas) netCanvas.requestPaint()
            }
        }
    }

    Timer {
        id: slowTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            exec.run("disk", "df -B1 / 2>/dev/null | tail -1")
            exec.run("disks", "df -B1 -x tmpfs -x devtmpfs -x squashfs -x overlay -x efivarfs 2>/dev/null | tail -n +2")
            exec.run("gpu", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null || cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null || (ACT=$(cat /sys/class/drm/card*/gt_act_freq_mhz 2>/dev/null | head -1); MAX=$(cat /sys/class/drm/card*/gt_max_freq_mhz 2>/dev/null | head -1); [ -n \"$ACT\" ] && [ -n \"$MAX\" ] && [ \"$MAX\" -gt 0 ] && echo $((ACT * 100 / MAX)) || echo '0')")
            exec.run("battery", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1; echo '---'; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1; echo '---'; cat /sys/class/power_supply/AC*/online 2>/dev/null || cat /sys/class/power_supply/ADP*/online 2>/dev/null || echo '0'")
            exec.run("temp", "cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 || cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null")
            exec.run("ip", "ip -4 addr show 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | cut -d/ -f1")
        }
    }

    Component.onCompleted: {
        for (var i = 0; i < 60; i++) { cpuHistory.push(0); memHistory.push(0); gpuHistory.push(0); netHistory.push(0) }
        
        exec.run("kernel", "uname -r")
        exec.run("cores", "nproc")
        exec.run("cpumodel", "lscpu 2>/dev/null | grep 'Model name' | head -1")
        exec.run("diskmodel", "lsblk -d -n -o MODEL $(findmnt -n -o SOURCE / | sed 's/\\[.*//;s/[0-9]*$//;s/p[0-9]*$//') 2>/dev/null")
        exec.run("gpuname", "glxinfo 2>/dev/null | grep 'OpenGL renderer' | head -1 || lspci 2>/dev/null | grep -i 'vga' | head -1")
        exec.run("publicip", "curl -s --max-time 3 https://api.ipify.org 2>/dev/null || echo '—'")
    }

    function parseCpu(content) {
        if (!content) return
        var lines = content.split('\n')
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("cpu ") === 0) {
                var p = lines[i].split(/\s+/)
                var user = parseInt(p[1]) || 0, nice = parseInt(p[2]) || 0, sys = parseInt(p[3]) || 0
                var idle = parseInt(p[4]) || 0, iow = parseInt(p[5]) || 0, irq = parseInt(p[6]) || 0, sirq = parseInt(p[7]) || 0
                var total = user + nice + sys + idle + iow + irq + sirq
                var busy = user + nice + sys + irq + sirq
                if (prevCpuTotal > 0) {
                    var td = total - prevCpuTotal, bd = busy - prevCpuBusy
                    if (td > 0) cpuUsage = (bd / td) * 100
                }
                prevCpuTotal = total; prevCpuBusy = busy
                cpuHistory = cpuHistory.slice(1).concat([cpuUsage])
                cpuCanvas.requestPaint()
                break
            }
        }
    }

    function parseMem(content) {
        if (!content) return
        var total = 0, avail = 0
        var lines = content.split('\n')
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("MemTotal:") === 0) total = parseInt(lines[i].split(/\s+/)[1]) || 0
            else if (lines[i].indexOf("MemAvailable:") === 0) avail = parseInt(lines[i].split(/\s+/)[1]) || 0
        }
        if (total > 0) {
            var used = total - avail
            memUsage = (used / total) * 100
            memUsedGB = used / (1024 * 1024)
            memTotalGB = total / (1024 * 1024)
            memHistory = memHistory.slice(1).concat([memUsage])
            memCanvas.requestPaint()
        }
    }

    function parseNet(content) {
        if (!content) return
        var tIn = 0, tOut = 0
        var lines = content.split('\n')
        for (var i = 2; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line || line.indexOf("lo:") === 0) continue
            var p = line.split(/\s+/)
            if (p.length >= 10) { tIn += parseInt(p[1]) || 0; tOut += parseInt(p[9]) || 0 }
        }
        var now = Date.now()
        if (prevNetTime > 0) {
            var dt = (now - prevNetTime) / 1000
            if (dt > 0) {
                netIn = Math.max(0, (tIn - prevNetIn) / dt)
                netOut = Math.max(0, (tOut - prevNetOut) / dt)
            }
        }
        netTotalIn = tIn; netTotalOut = tOut
        prevNetIn = tIn; prevNetOut = tOut; prevNetTime = now
        netHistory = netHistory.slice(1).concat([netIn + netOut])
        netCanvas.requestPaint()
    }

    function parseDisk(content) {
        if (!content) return
        var p = content.trim().split(/\s+/)
        if (p.length >= 6) {
            var t = parseInt(p[1]) || 0, u = parseInt(p[2]) || 0, a = parseInt(p[3]) || 0
            var mount = p[5] || "/"
            if (t > 0) { 
                diskUsage = (u / t) * 100
                diskTotalGB = t / 1073741824
                diskFreeGB = a / 1073741824
                diskMountPoint = mount
            }
        }
    }

    function parseAllDisks(content) {
        if (!content) return
        var lines = content.trim().split('\n')
        var disks = []
        for (var i = 0; i < lines.length; i++) {
            var p = lines[i].trim().split(/\s+/)
            if (p.length >= 6) {
                var mount = p[5]
                // Skip system mounts
                if (mount === "/" || mount === "/boot" || mount === "/boot/efi" || 
                    mount === "/home" || mount === "/var" || mount === "/tmp" ||
                    mount === "/root" || mount === "/srv" ||
                    mount.indexOf("/var/") === 0 || mount.indexOf("/snap") === 0 ||
                    mount.indexOf("/sys") === 0 || mount.indexOf("/proc") === 0 ||
                    mount.indexOf("/dev") === 0 || mount === "/run" ||
                    (mount.indexOf("/run/") === 0 && mount.indexOf("/run/media/") !== 0)) continue
                
                var t = parseInt(p[1]) || 0, u = parseInt(p[2]) || 0, a = parseInt(p[3]) || 0
                if (t > 0 && t > 1073741824) { // Only show disks > 1GB
                    // Get short name from mount path
                    var shortName = mount.split('/').pop() || mount
                    disks.push({
                        mount: shortName,
                        fullMount: mount,
                        usage: (u / t) * 100,
                        freeGB: a / 1073741824,
                        totalGB: t / 1073741824
                    })
                }
            }
        }
        otherDisks = disks
    }

    function parseDiskModel(content) {
        if (!content) return
        var model = content.trim()
        if (model && model !== "") {
            diskModel = model.replace(/\s+/g, ' ').substring(0, 25)
        }
    }

    function parseLoad(content) {
        if (!content) return
        var p = content.split(' ')
        loadAvg1 = parseFloat(p[0]) || 0; loadAvg5 = parseFloat(p[1]) || 0; loadAvg15 = parseFloat(p[2]) || 0
        if (p.length >= 4) { var pp = p[3].split('/'); if (pp.length >= 2) processCount = parseInt(pp[1]) || 0 }
    }

    function parseGpu(content) {
        if (!content || content.trim() === '' || content.trim() === '0') {
            gpuHistory = gpuHistory.slice(1).concat([gpuUsage])
            gpuCanvas.requestPaint()
            return
        }
        var p = content.trim().split(',')
        if (p.length >= 1) gpuUsage = parseFloat(p[0].trim()) || 0
        if (p.length >= 2) gpuTemp = parseFloat(p[1].trim()) || 0
        gpuHistory = gpuHistory.slice(1).concat([gpuUsage])
        gpuCanvas.requestPaint()
    }

    function parseBattery(content) {
        if (!content || content.trim() === '') { hasBattery = false; return }
        var p = content.split('---')
        if (p.length >= 1 && p[0].trim() !== '') {
            var cap = parseInt(p[0].trim())
            if (!isNaN(cap)) { hasBattery = true; batteryLevel = cap }
            else { hasBattery = false; return }
        }
        var status = (p.length >= 2) ? p[1].trim() : ""
        var ac = (p.length >= 3) ? p[2].trim() === "1" : false
        
        if (status === "Charging") { batteryCharging = true; batteryStatus = "Charging" }
        else if (status === "Full") { batteryCharging = false; batteryStatus = "Fully charged" }
        else if (status === "Not charging" && ac) { batteryCharging = false; batteryStatus = "Plugged in" }
        else { batteryCharging = false; batteryStatus = ac ? "Plugged in" : "On battery" }
    }

    function parseTemp(content) {
        if (!content) return
        var t = parseInt(content.trim())
        if (!isNaN(t)) { if (t > 1000) t = t / 1000; if (t > 0 && t < 150) cpuTemp = t }
    }

    function parseIP(content) {
        if (content && content.trim()) localIP = content.trim()
    }

    function parseCpuModel(content) {
        if (!content) return
        var m = content.match(/Model name:\s*(.+)/)
        if (m) cpuModel = m[1].trim().replace(/\s+/g, ' ').substring(0, 35)
    }

    function parseGpuName(content) {
        if (!content) return
        var m = content.match(/OpenGL renderer string:\s*(.+)/)
        if (m) { gpuName = m[1].trim().replace(/Mesa\s*/i, '').replace(/\(.*\)/, '').trim().substring(0, 28) }
        else {
            m = content.match(/VGA.*:\s*(.+)/)
            if (m) gpuName = m[1].trim().substring(0, 28)
        }
    }

    function formatSpeed(bps) {
        if (bps < 1024) return bps.toFixed(0) + " B/s"
        if (bps < 1048576) return (bps / 1024).toFixed(1) + " KB/s"
        return (bps / 1048576).toFixed(2) + " MB/s"
    }

    function formatBytes(b) {
        if (b < 1024) return b.toFixed(0) + " B"
        if (b < 1048576) return (b / 1024).toFixed(1) + " KB"
        if (b < 1073741824) return (b / 1048576).toFixed(1) + " MB"
        return (b / 1073741824).toFixed(2) + " GB"
    }

    function formatUptime(s) {
        var d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60)
        if (d > 0) return d + "d " + h + "h " + m + "m"
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    function drawGraph(ctx, vals, col, w, h) {
        if (!ctx || !vals || vals.length < 2) return
        ctx.reset()
        var max = Math.max.apply(null, vals); if (max < 1) max = 100
        ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.1); ctx.fillRect(0, 0, w, h)
        ctx.beginPath(); ctx.moveTo(0, h)
        for (var i = 0; i < vals.length; i++) ctx.lineTo((i / (vals.length - 1)) * w, h - (vals[i] / max) * h * 0.85 - 2)
        ctx.lineTo(w, h); ctx.closePath()
        var g = ctx.createLinearGradient(0, 0, 0, h); g.addColorStop(0, Qt.rgba(col.r, col.g, col.b, 0.4)); g.addColorStop(1, Qt.rgba(col.r, col.g, col.b, 0.05))
        ctx.fillStyle = g; ctx.fill()
        ctx.beginPath(); ctx.strokeStyle = col; ctx.lineWidth = 1.5
        for (var j = 0; j < vals.length; j++) { var x = (j / (vals.length - 1)) * w, y = h - (vals[j] / max) * h * 0.85 - 2; if (j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y) }
        ctx.stroke()
        ctx.beginPath(); ctx.arc(w - 2, h - (vals[vals.length - 1] / max) * h * 0.85 - 2, 2.5, 0, Math.PI * 2); ctx.fillStyle = col; ctx.fill()
    }
}
