import QtQuick

// Material 3 Expressive shape dot — faithful port of the M3 Expressive
// shape catalog, with rounded corners for all angular shapes.
//
// shape: "circle" | "cookie" | "sunny" | "burst" | "star"
//      | "clover" | "flower" | "pentagon" | "hexagon" | "square"
//      | "oval" | "pill" | "pill_diag" | "blob"
//
// roundness: 0 → sharp polygon, 1 → near circle
// morph:     0 → plain circle, 1 → fully shaped (entry animation)
Canvas {
    id: dot

    property real   dotSize: 14
    property color  dotColor: M3.primary
    property string shape: "circle"
    property real   roundness: 0.75      // ← generous default for soft corners
    property real   spin: -Math.PI / 2
    property real   morph: 1.0

    width: dotSize
    height: dotSize
    antialiasing: true
    renderStrategy: Canvas.Immediate

    onDotSizeChanged:   requestPaint()
    onDotColorChanged:  requestPaint()
    onShapeChanged:     requestPaint()
    onRoundnessChanged: requestPaint()
    onSpinChanged:      requestPaint()
    onMorphChanged:     requestPaint()
    Component.onCompleted: requestPaint()

    // -------- rounded path through a list of vertices --------
    // Each vertex is cut and replaced with a quadratic Bézier.
    // fracs[i] ∈ (0, 0.5): fraction of edge length to round at vertex i.
    function roundedPath(ctx, pts, fracs) {
        var n = pts.length
        ctx.beginPath()
        var prev = pts[n - 1]
        for (var i = 0; i < n; i++) {
            var cur = pts[i]
            var nxt = pts[(i + 1) % n]

            var d1x = prev.x - cur.x, d1y = prev.y - cur.y
            var d2x = nxt.x  - cur.x, d2y = nxt.y  - cur.y
            var l1  = Math.sqrt(d1x * d1x + d1y * d1y) || 1
            var l2  = Math.sqrt(d2x * d2x + d2y * d2y) || 1

            var f  = (fracs && fracs[i] !== undefined) ? fracs[i] : 0.3
            var t  = Math.min(f, 0.49)

            var p1x = cur.x + d1x * t, p1y = cur.y + d1y * t
            var p2x = cur.x + d2x * t, p2y = cur.y + d2y * t

            if (i === 0) ctx.moveTo(p1x, p1y)
            else         ctx.lineTo(p1x, p1y)
            ctx.quadraticCurveTo(cur.x, cur.y, p2x, p2y)

            prev = cur
        }
        ctx.closePath()
    }

    function polygonPts(cx, cy, R, n, rot) {
        var pts = []
        for (var i = 0; i < n; i++) {
            var a = rot + i * 2 * Math.PI / n
            pts.push({ x: cx + R * Math.cos(a), y: cy + R * Math.sin(a) })
        }
        return pts
    }

    function starPts(cx, cy, R, n, innerRatio, rot) {
        var pts = []
        for (var i = 0; i < n * 2; i++) {
            var a = rot + i * Math.PI / n
            var r = (i % 2 === 0) ? R : R * innerRatio
            pts.push({ x: cx + r * Math.cos(a), y: cy + r * Math.sin(a) })
        }
        return pts
    }

    // Smooth n-lobe scallop: r(θ) = 1 + amp * cos(nθ + spin)
    function scallopR(theta, n, amp) {
        return 1 + amp * Math.cos(n * theta + spin)
    }

    function blobR(theta) {
        return 1
            + 0.10 * Math.sin(3 * theta + spin)
            + 0.05 * Math.sin(5 * theta - spin * 0.7)
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)
        ctx.fillStyle = dotColor

        var cx = width / 2
        var cy = height / 2
        var R  = width / 2 * 0.92

        // --- elongated shapes: transform context, then draw ---
        var sx = 1, sy = 1, rot = 0
        if (shape === "pill")       { sx = 1.55; sy = 0.82 }
        if (shape === "pill_diag")  { sx = 1.55; sy = 0.82; rot = Math.PI / 4 }
        if (shape === "oval")       { sx = 1.28; sy = 0.92 }

        ctx.save()
        ctx.translate(cx, cy)
        if (rot) ctx.rotate(rot)
        ctx.scale(sx, sy)

        if (shape === "oval") {
            ctx.beginPath()
            ctx.arc(0, 0, R, 0, Math.PI * 2)
            ctx.fill()
            ctx.restore()
            return
        }
        if (shape === "pill" || shape === "pill_diag") {
            var rr = R * 0.95
            ctx.beginPath()
            ctx.moveTo(-R + rr, -R)
            ctx.lineTo( R - rr, -R)
            ctx.quadraticCurveTo( R, -R,  R, -R + rr)
            ctx.lineTo( R,  R - rr)
            ctx.quadraticCurveTo( R,  R,  R - rr,  R)
            ctx.lineTo(-R + rr,  R)
            ctx.quadraticCurveTo(-R,  R, -R,  R - rr)
            ctx.lineTo(-R, -R + rr)
            ctx.quadraticCurveTo(-R, -R, -R + rr, -R)
            ctx.closePath()
            ctx.fill()
            ctx.restore()
            return
        }

        // --- polygons with TRUE rounded corners ---
        if (shape === "pentagon" || shape === "hexagon" || shape === "square") {
            var n     = shape === "pentagon" ? 5
                      : shape === "hexagon"  ? 6
                      :                        4
            // "square" wants flat-on-top, not a diamond → extra 45°
            var sSpn  = (shape === "square") ? spin + Math.PI / 4 : spin
            var pts   = polygonPts(0, 0, R, n, sSpn)

            // roundness → corner fraction (0 → sharp, 1 → nearly circular)
            var frac  = 0.02 + roundness * 0.43
            var frs   = []
            for (var k = 0; k < n; k++) frs.push(frac)

            roundedPath(ctx, pts, frs)
            ctx.fill()
            ctx.restore()
            return
        }

        // --- star with rounded peaks AND valleys ---
        if (shape === "star") {
            var sp   = starPts(0, 0, R, 6, 0.55, spin)
            var frs2 = []
            for (var k = 0; k < sp.length; k++) {
                frs2.push((k % 2 === 0)
                          ? 0.12 + roundness * 0.30   // outer peak
                          : 0.08 + roundness * 0.22)  // inner valley
            }
            roundedPath(ctx, sp, frs2)
            ctx.fill()
            ctx.restore()
            return
        }

        // --- scalloped / smooth radial shapes (already C∞ smooth) ---
        var steps = 260
        ctx.beginPath()
        for (var i = 0; i <= steps; i++) {
            var t = i / steps
            var a = t * 2 * Math.PI - Math.PI / 2
            var r = 1

            switch (shape) {
            case "cookie": r = scallopR(a, 12, 0.07); break
            case "sunny":  r = scallopR(a, 12, 0.12); break
            case "burst":  r = scallopR(a, 8,  0.17); break
            case "clover": r = scallopR(a, 4,  0.20); break
            case "flower": r = scallopR(a, 6,  0.15); break
            case "blob":   r = blobR(a); break
            default:       r = 1
            }

            if (morph < 1 && shape !== "circle") {
                r = 1 + (r - 1) * morph
            }

            var x = R * r * Math.cos(a)
            var y = R * r * Math.sin(a)
            if (i === 0) ctx.moveTo(x, y)
            else         ctx.lineTo(x, y)
        }
        ctx.closePath()
        ctx.fill()
        ctx.restore()
    }
}
