import QtQuick
import qs.Common

// [Mesh Logo Canvas]
Item {
    id: root

    property color color: Theme.surfaceText
    property int size: 18

    width: size
    height: size
    implicitWidth: size
    implicitHeight: size

    onColorChanged: canvas.requestPaint()
    onSizeChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            ctx.reset();
            if (w <= 0 || h <= 0)
                return;

            const topX = w * 0.50;
            const topY = h * 0.20;
            const leftX = w * 0.21;
            const leftY = h * 0.74;
            const rightX = w * 0.79;
            const rightY = h * 0.74;
            const centerX = w * 0.50;
            const centerY = h * 0.54;

            const strokeW = Math.max(1.35, w * 0.095);
            const outerR = Math.max(1.8, w * 0.125);
            const innerR = Math.max(1.4, w * 0.09);

            ctx.strokeStyle = root.color;
            ctx.fillStyle = root.color;
            ctx.lineWidth = strokeW;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            // Outer mesh triangle + hub spokes
            ctx.beginPath();
            ctx.moveTo(topX, topY);
            ctx.lineTo(leftX, leftY);
            ctx.lineTo(rightX, rightY);
            ctx.closePath();
            ctx.moveTo(topX, topY);
            ctx.lineTo(centerX, centerY);
            ctx.moveTo(leftX, leftY);
            ctx.lineTo(centerX, centerY);
            ctx.moveTo(rightX, rightY);
            ctx.lineTo(centerX, centerY);
            ctx.stroke();

            // Nodes
            const nodes = [
                [topX, topY, outerR],
                [leftX, leftY, outerR],
                [rightX, rightY, outerR],
                [centerX, centerY, innerR]
            ];
            for (let i = 0; i < nodes.length; i++) {
                ctx.beginPath();
                ctx.arc(nodes[i][0], nodes[i][1], nodes[i][2], 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }
}
