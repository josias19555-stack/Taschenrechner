-- Smoke-Test fuer den K-Modus in Querschnitt.lua (ausserhalb des Taschenrechners)
local calls = {invalidate = 0}
on = {}
platform = {
    window = {
        width = function() return 318 end,
        height = function() return 212 end,
        invalidate = function() calls.invalidate = calls.invalidate + 1 end,
    }
}

local gc_stub = setmetatable({}, {__index = function(_, k)
    if k == "clipRect" or k == "setColorRGB" or k == "setPen" or k == "setFont"
       or k == "drawLine" or k == "drawString" or k == "fillRect" or k == "drawRect"
       or k == "fillArc" or k == "drawArc" or k == "fillPolygon" or k == "drawPolyLine" then
        return function(...) end
    end
    return function(...) return nil end
end})

dofile("Querschnitt.lua")

-- Rechteck 4x6 zeichnen: Menue M -> Enter (Rechteck) -> zwei Klicks
on.charIn("m")
on.enterKey() -- mode = "rect"
on.mouseUp(160 - 2*24, 106 - 3*24) -- (-2, -3) in Welt (toScreen: ox+u*scale, oy-v*scale)
on.mouseUp(160 + 2*24, 106 + 3*24) -- (2, 3)

-- K-Modus durchschalten und jede Seite zeichnen
on.charIn("k") -- Seite 1: Umhüllende
on.paint(gc_stub)
on.mouseMove(160, 106 + 3*24 + 2) -- nahe untere Kante -> Hover auf Gerade
on.paint(gc_stub)
on.charIn("k") -- Seite 2: Kernfläche
on.paint(gc_stub)
on.mouseMove(160, 106) -- nahe Schwerpunkt
on.paint(gc_stub)
on.charIn("k") -- zurueck zu normal
on.paint(gc_stub)

-- Zweiter Test: Kreis
on.clearKey()
on.charIn("m")
menuRow = 2 -- geht nicht von aussen... stattdessen Pfeiltaste
on.arrowKey("down")
on.enterKey() -- mode = "circle"
on.mouseUp(160, 106)     -- Mittelpunkt (0,0)
on.mouseUp(160 + 2*24, 106) -- Radius 2
on.charIn("k")
on.paint(gc_stub)
on.charIn("k")
on.paint(gc_stub)

print("Test OK, invalidates:", calls.invalidate)
