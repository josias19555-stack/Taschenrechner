-- Perfektionierter Mohrscher Spannungskreis für TI-Nspire
-- Inkl. 3 Modi: Standard, 2-Punkte, 1-Punkt + Winkel zu Tau_max
-- Mit invertierter Tau-Achse, Merksätzen & einheitlichen Tabellen

local state = 0
local mode = 1
local inputStr = ""

-- Variablen für Modus 1
local sx, sy, txy, alpha = 0, 0, 0, 0
local s_xi, s_eta, t_xiet = 0, 0, 0

-- Variablen für Modus 2 & 3
local sa, ta, sb, tb, alpha_tmax = 0, 0, 0, 0, 0

-- Gemeinsame Ergebnis-Variablen
local sigm, r, sig1, sig2, phi = 0, 0, 0, 0, 0
local show_table = false

local W = platform.window:width() or 318
local H = platform.window:height() or 212

function on.resize()
    W = platform.window:width()
    H = platform.window:height()
end

function drawInputBox(gc, title, varName, hint)
    local boxW, boxH = 260, 110
    local boxX, boxY = (W - boxW) / 2, (H - boxH) / 2
    
    gc:setColorRGB(180, 180, 180)
    gc:fillRect(boxX + 4, boxY + 4, boxW, boxH)
    
    gc:setColorRGB(245, 245, 245)
    gc:fillRect(boxX, boxY, boxW, boxH)
    gc:setColorRGB(0, 0, 0)
    gc:setPen("thin", "smooth")
    gc:drawRect(boxX, boxY, boxW, boxH)
    
    gc:setFont("sansserif", "b", 11)
    gc:drawString(title, boxX + 10, boxY + 10)
    
    if hint then
        gc:setFont("sansserif", "i", 9)
        gc:setColorRGB(120, 120, 120)
        gc:drawString(hint, boxX + 10, boxY + 26)
    end
    
    gc:setFont("sansserif", "b", 14)
    gc:setColorRGB(0, 50, 150)
    local displayStr = varName .. " = " .. inputStr .. "_"
    if (state == 14 or state == 33) and inputStr == "" then
        displayStr = varName .. " = _ (Leer = 0°)"
    end
    gc:drawString(displayStr, boxX + 10, boxY + 45)
    
    gc:setColorRGB(100, 100, 100)
    gc:setFont("sansserif", "i", 9)
    gc:drawString("[Enter] Weiter  |  [Esc] Zurueck", boxX + 10, boxY + 75)
    gc:drawString("[Ctrl+Clear] Neustart", boxX + 10, boxY + 90)
end

function drawLabel(gc, text, x, y)
    gc:setFont("sansserif", "b", 9)
    gc:setColorRGB(0, 0, 0)
    gc:drawString(text, x, y)
end

function on.paint(gc)
    if state == 0 then
        gc:setFont("sansserif", "b", 13)
        local t1 = "Mohrscher Spannungskreis"
        local t1_w = gc:getStringWidth(t1)
        gc:drawString(t1, (W - t1_w)/2, 10)
        
        gc:setFont("sansserif", "r", 10)
        gc:drawString("Wähle den Eingabemodus:", 15, 45)
        
        gc:setFont("sansserif", "b", 11)
        gc:setColorRGB(0, 50, 150)
        gc:drawString("[ 1 ] Standard (σx, σy, τxy, α)", 25, 75)
        
        gc:setColorRGB(200, 50, 0)
        gc:drawString("[ 2 ] 2 Punkte (σa, τa, σb, τb)", 25, 100)
        
        gc:setColorRGB(0, 150, 0)
        gc:drawString("[ 3 ] Punkt + Winkel zu τ_max", 25, 125)
        
        gc:setColorRGB(100, 100, 100)
        gc:setFont("sansserif", "i", 9)
        gc:drawString("Taste 1, 2 oder 3 drücken zum Starten", 25, 155)
        
    -- Modus 1
    elseif state == 11 then drawInputBox(gc, "1. Normalspannung (x)", "σ_x", "Merksatz: Druck \"-\"")
    elseif state == 12 then drawInputBox(gc, "2. Normalspannung (y)", "σ_y", "Merksatz: Druck \"-\"")
    elseif state == 13 then drawInputBox(gc, "3. Schubspannung", "τ_xy", "Merksatz: gegen Uhrzeigersinn \"+\"")
    elseif state == 14 then drawInputBox(gc, "4. Drehwinkel in Grad", "α")
    
    -- Modus 2
    elseif state == 21 then drawInputBox(gc, "1. Punkt: Normalspannung", "σ_a", "Merksatz: Druck \"-\"")
    elseif state == 22 then drawInputBox(gc, "1. Punkt: Schubspannung", "τ_a", "Merksatz: gegen Uhrzeigersinn \"+\"")
    elseif state == 23 then drawInputBox(gc, "2. Punkt: Normalspannung", "σ_b", "Merksatz: Druck \"-\"")
    elseif state == 24 then drawInputBox(gc, "2. Punkt: Schubspannung", "τ_b", "Merksatz: gegen Uhrzeigersinn \"+\"")
    
    -- Modus 3
    elseif state == 31 then drawInputBox(gc, "Gegebene Normalspannung", "σ_a", "Merksatz: Druck \"-\"")
    elseif state == 32 then drawInputBox(gc, "Gegebene Schubspannung", "τ_a", "Merksatz: gegen Uhrzeigersinn \"+\"")
    elseif state == 33 then drawInputBox(gc, "Winkel zu τ_max (Grad)", "α", "Richtung zur Fläche mit max. Schubspannung")
    
    elseif state == 5 then
        if show_table then drawTable(gc) else drawGraph(gc) end
    end
end

function getNiceStep(span)
    if span <= 0 then return 1 end
    local raw_step = span / 5 
    local p = math.floor(math.log10(raw_step))
    local factor = 10^p
    local norm = raw_step / factor
    
    local nice = 1
    if norm > 5 then nice = 10
    elseif norm > 2 then nice = 5
    elseif norm > 1 then nice = 2
    end
    return nice * factor
end

function drawGraph(gc)
    local topBarH = 20
    gc:setColorRGB(230, 230, 230)
    gc:fillRect(0, 0, W, topBarH)
    gc:setColorRGB(0, 0, 0)
    gc:drawLine(0, topBarH, W, topBarH)
    
    gc:setFont("sansserif", "r", 9)
    local infoStr = "[T] Tab  |  [Esc] Zurueck  |  [Ctrl+Clear] Neu"
    local infoW = gc:getStringWidth(infoStr)
    gc:drawString(infoStr, (W - infoW)/2, 4)

    local graphH = H - topBarH
    local pad = 30
    
    local min_s, max_s, min_t, max_t
    if mode == 1 then
        min_s = math.min(sigm - r, 0, sx, sy, s_xi, s_eta)
        max_s = math.max(sigm + r, 0, sx, sy, s_xi, s_eta)
        min_t = math.min(-r, 0, -txy, -t_xiet)
        max_t = math.max(r, 0, txy, t_xiet)
    elseif mode == 2 then
        min_s = math.min(sigm - r, 0, sa, sb, 2*sigm - sa, 2*sigm - sb)
        max_s = math.max(sigm + r, 0, sa, sb, 2*sigm - sa, 2*sigm - sb)
        min_t = math.min(-r, 0, ta, tb, -ta, -tb)
        max_t = math.max(r, 0, ta, tb, -ta, -tb)
    elseif mode == 3 then
        min_s = math.min(sigm - r, 0, sa, 2*sigm - sa)
        max_s = math.max(sigm + r, 0, sa, 2*sigm - sa)
        min_t = math.min(-r, 0, ta, -ta)
        max_t = math.max(r, 0, ta, -ta)
    end
    
    local span_s = max_s - min_s
    local span_t = max_t - min_t
    if span_s == 0 then span_s = 10 end
    if span_t == 0 then span_t = 10 end
    
    local scale = math.min((W - 2*pad) / span_s, (graphH - 2*pad) / span_t)
    local ox = pad - min_s * scale
    local oy = topBarH + pad + max_t * scale
    
    -- Achsen zeichnen
    gc:setColorRGB(150, 150, 150)
    gc:setPen("thin", "smooth")
    gc:drawLine(0, oy, W, oy) 
    gc:drawLine(ox, topBarH, ox, H)
    
    gc:setFont("sansserif", "i", 10)
    gc:drawString("σ", W - 15, oy - 15)
    gc:drawString("τ", ox + 5, topBarH + 5) 
    
    local step = getNiceStep(math.max(span_s, span_t))
    
    for v = math.floor(min_s/step)*step, max_s, step do
        local px = ox + v * scale
        if px > 0 and px < W then
            gc:drawLine(px, oy - 2, px, oy + 2)
            if v ~= 0 then gc:drawString(tostring(v), px - 5, oy + 4) end
        end
    end
    for v = math.floor(min_t/step)*step, max_t, step do
        local py = oy - v * scale
        if py > topBarH and py < H then
            gc:drawLine(ox - 2, py, ox + 2, py)
            if v ~= 0 then gc:drawString(tostring(v), ox + 5, py - 6) end
        end
    end
    
    local cx = ox + sigm * scale
    local cy = oy
    local radius_px = r * scale
    
    -- Kreis zeichnen
    gc:setColorRGB(0, 0, 200)
    gc:setPen("medium", "smooth")
    gc:drawArc(cx - radius_px, cy - radius_px, radius_px * 2, radius_px * 2, 0, 360)
    gc:fillArc(cx - 2, cy - 2, 4, 4, 0, 360)
    drawLabel(gc, "σ_m", cx - 8, cy + 4)
    
    gc:fillArc(ox + sig1*scale - 2, cy - 2, 4, 4, 0, 360)
    gc:fillArc(ox + sig2*scale - 2, cy - 2, 4, 4, 0, 360)
    drawLabel(gc, "σ_1", ox + sig1*scale + 2, cy - 15)
    drawLabel(gc, "σ_2", ox + sig2*scale - 18, cy - 15)
    
    if mode == 1 then
        local px1 = ox + sx * scale
        local py1 = oy - txy * scale
        local px2 = ox + sy * scale
        local py2 = oy + txy * scale
        
        gc:setColorRGB(200, 0, 0)
        gc:drawLine(px1, py1, px2, py2)
        gc:fillArc(px1 - 2, py1 - 2, 4, 4, 0, 360)
        gc:fillArc(px2 - 2, py2 - 2, 4, 4, 0, 360)
        drawLabel(gc, "σ_x", px1 + 4, py1 - 8)
        drawLabel(gc, "σ_y", px2 + 4, py2 - 8)
        
        if alpha ~= 0 then
            local px3 = ox + s_xi * scale
            local py3 = oy - t_xiet * scale
            local px4 = ox + s_eta * scale
            local py4 = oy + t_xiet * scale
            gc:setColorRGB(0, 150, 0)
            gc:drawLine(px3, py3, px4, py4)
            gc:fillArc(px3 - 2, py3 - 2, 4, 4, 0, 360)
            gc:fillArc(px4 - 2, py4 - 2, 4, 4, 0, 360)
            drawLabel(gc, "σ_ξ", px3 + 4, py3 - 8)
            drawLabel(gc, "σ_η", px4 + 4, py4 - 8)
        end
        
    elseif mode == 2 then
        local px1 = ox + sa * scale
        local py1 = oy - ta * scale
        local px1_opp = ox + (2*sigm - sa) * scale
        local py1_opp = oy + ta * scale
        
        local px2 = ox + sb * scale
        local py2 = oy - tb * scale
        local px2_opp = ox + (2*sigm - sb) * scale
        local py2_opp = oy + tb * scale
        
        gc:setColorRGB(200, 0, 0)
        gc:drawLine(px1, py1, px1_opp, py1_opp)
        gc:fillArc(px1 - 2, py1 - 2, 4, 4, 0, 360)
        gc:fillArc(px1_opp - 2, py1_opp - 2, 4, 4, 0, 360)
        drawLabel(gc, "P_a", px1 + 4, py1 - 8)
        
        gc:setColorRGB(0, 150, 0)
        gc:drawLine(px2, py2, px2_opp, py2_opp)
        gc:fillArc(px2 - 2, py2 - 2, 4, 4, 0, 360)
        gc:fillArc(px2_opp - 2, py2_opp - 2, 4, 4, 0, 360)
        drawLabel(gc, "P_b", px2 + 4, py2 - 8)
        
    elseif mode == 3 then
        local px1 = ox + sa * scale
        local py1 = oy - ta * scale
        local px1_opp = ox + (2*sigm - sa) * scale
        local py1_opp = oy + ta * scale
        
        gc:setColorRGB(200, 0, 0)
        gc:drawLine(px1, py1, px1_opp, py1_opp)
        gc:fillArc(px1 - 2, py1 - 2, 4, 4, 0, 360)
        gc:fillArc(px1_opp - 2, py1_opp - 2, 4, 4, 0, 360)
        drawLabel(gc, "P_a", px1 + 4, py1 - 8)
        
        -- Tau Max Achse (Senkrecht zum Sigma)
        local px_t = cx
        local py_t = oy - r * scale -- top
        local px_b = cx
        local py_b = oy + r * scale -- bottom
        
        gc:setColorRGB(0, 150, 0)
        gc:drawLine(px_t, py_t, px_b, py_b)
        gc:fillArc(px_t - 2, py_t - 2, 4, 4, 0, 360)
        gc:fillArc(px_b - 2, py_b - 2, 4, 4, 0, 360)
        drawLabel(gc, "τ_max", px_t + 4, py_t - 5)
        drawLabel(gc, "τ_min", px_b + 4, py_b + 12)
    end
end

function drawTable(gc)
    gc:setColorRGB(255, 255, 255)
    gc:fillRect(0, 0, W, H)
    
    gc:setColorRGB(0, 50, 150)
    gc:fillRect(0, 0, W, 25)
    gc:setColorRGB(255, 255, 255)
    gc:setFont("sansserif", "b", 11)
    gc:drawString("Ergebnistabelle (Schliessen mit 'T')", 5, 5)
    
    gc:setColorRGB(0, 0, 0)
    
    local data = {}
    if mode == 1 then
        data = {
            {"Eingabe: σ_x", string.format("%.2f", sx), "Eingabe: α", string.format("%.2f °", alpha)},
            {"Eingabe: σ_y", string.format("%.2f", sy), "Gedreht: σ_ξ", string.format("%.2f", s_xi)},
            {"Eingabe: τ_xy", string.format("%.2f", txy), "Gedreht: σ_η", string.format("%.2f", s_eta)},
            {"", "", "Gedreht: τ_ξη", string.format("%.2f", t_xiet)},
            {"Mittelpunkt σ_m", string.format("%.2f", sigm), "Winkel zu σ_1", string.format("%.2f °", phi)},
            {"Radius τ_max", string.format("%.2f", r), "", ""},
            {"Hauptspg. σ_1", string.format("%.2f", sig1), "", ""},
            {"Hauptspg. σ_2", string.format("%.2f", sig2), "", ""}
        }
    elseif mode == 2 then
        data = {
            {"Punkt A: σ_a", string.format("%.2f", sa), "Punkt B: σ_b", string.format("%.2f", sb)},
            {"Punkt A: τ_a", string.format("%.2f", ta), "Punkt B: τ_b", string.format("%.2f", tb)},
            {"Gegenst. A': σ", string.format("%.2f", 2*sigm - sa), "Gegenst. B': σ", string.format("%.2f", 2*sigm - sb)},
            {"Gegenst. A': τ", string.format("%.2f", -ta), "Gegenst. B': τ", string.format("%.2f", -tb)},
            {"Mittelpunkt σ_m", string.format("%.2f", sigm), "Radius τ_max", string.format("%.2f", r)},
            {"Hauptspg. σ_1", string.format("%.2f", sig1), "Hauptspg. σ_2", string.format("%.2f", sig2)}
        }
    elseif mode == 3 then
        -- Einheitliche Struktur wie in Modus 2 (6 Zeilen)
        data = {
            {"Punkt A: σ_a", string.format("%.2f", sa), "Winkel zu τ_max", string.format("%.2f °", alpha_tmax)},
            {"Punkt A: τ_a", string.format("%.2f", ta), "Mittelpunkt σ_m", string.format("%.2f", sigm)},
            {"Gegenst. A': σ", string.format("%.2f", 2*sigm - sa), "Radius τ_max", string.format("%.2f", r)},
            {"Gegenst. A': τ", string.format("%.2f", -ta), "Winkel zu σ_1", string.format("%.2f °", phi)},
            {"Max Punkt: σ", string.format("%.2f", sigm), "Max Punkt: τ", string.format("%.2f", r)},
            {"Hauptspg. σ_1", string.format("%.2f", sig1), "Hauptspg. σ_2", string.format("%.2f", sig2)}
        }
    end
    
    local y_start = 30
    local row_h = 18
    local col1 = 5
    local col2 = 105
    local col3 = 165
    local col4 = 255
    
    for i, row in ipairs(data) do
        local y = y_start + (i-1) * row_h
        if i % 2 == 0 then
            gc:setColorRGB(240, 240, 240)
            gc:fillRect(0, y, W, row_h)
            gc:setColorRGB(0, 0, 0)
        end
        gc:setFont("sansserif", "b", 9)
        gc:drawString(row[1], col1, y + 2)
        gc:drawString(row[3], col3, y + 2)
        gc:setFont("sansserif", "r", 9)
        gc:drawString(row[2], col2, y + 2)
        gc:drawString(row[4], col4, y + 2)
    end
end

function calcMohrStandard()
    sigm = (sx + sy) / 2
    r = math.sqrt(((sx - sy) / 2)^2 + txy^2)
    sig1 = sigm + r
    sig2 = sigm - r
    phi = 0.5 * math.deg(math.atan2(2 * txy, sx - sy))
    
    local rad = math.rad(alpha)
    s_xi = sigm + ((sx - sy)/2) * math.cos(2*rad) + txy * math.sin(2*rad)
    s_eta = sigm - ((sx - sy)/2) * math.cos(2*rad) - txy * math.sin(2*rad)
    t_xiet = -((sx - sy)/2) * math.sin(2*rad) + txy * math.cos(2*rad)
end

function calcMohr2Points()
    if sb == sa then sb = sb + 0.0001 end
    sigm = (sb^2 - sa^2 + tb^2 - ta^2) / (2 * (sb - sa))
    r = math.sqrt((sa - sigm)^2 + ta^2)
    sig1 = sigm + r
    sig2 = sigm - r
    phi = 0.5 * math.deg(math.atan2(2 * ta, sa - sigm))
end

function calcMohrMode3()
    local rad2 = math.rad(2 * alpha_tmax)
    -- Division durch 0 verhindern (falls Alpha = 45 Grad)
    if math.abs(math.cos(rad2)) < 1e-7 then rad2 = rad2 + 0.0001 end
    
    -- Mittelpunkt und Radius über Winkelfunktionen berechnen
    sigm = sa - ta * math.tan(rad2)
    r = math.abs(ta / math.cos(rad2))
    
    sig1 = sigm + r
    sig2 = sigm - r
    phi = 0.5 * math.deg(math.atan2(2 * ta, sa - sigm))
end

function on.charIn(char)
    if state == 0 then
        if char == "1" then mode = 1; state = 11; inputStr = ""; platform.window:invalidate()
        elseif char == "2" then mode = 2; state = 21; inputStr = ""; platform.window:invalidate()
        elseif char == "3" then mode = 3; state = 31; inputStr = ""; platform.window:invalidate()
        end
        return
    end

    if (state >= 11 and state <= 14) or (state >= 21 and state <= 24) or (state >= 31 and state <= 33) then
        if char:match("[%d%.%-]") then
            inputStr = inputStr .. char
            platform.window:invalidate()
        end
    end
    if state == 5 and (char == "t" or char == "T") then
        show_table = not show_table
        platform.window:invalidate()
    end
end

function on.backspaceKey()
    if (state >= 11 and state <= 14) or (state >= 21 and state <= 24) or (state >= 31 and state <= 33) then
        if #inputStr > 0 then
            inputStr = string.sub(inputStr, 1, -2)
            platform.window:invalidate()
        end
    end
end

function on.enterKey()
    if state == 0 then return end 
    
    if (state >= 11 and state <= 14) or (state >= 21 and state <= 24) or (state >= 31 and state <= 33) then
        local val = tonumber(inputStr)
        
        if (state == 14 or state == 33) and (inputStr == "" or val == nil) then val = 0 end
        
        if val ~= nil then
            if state == 11 then sx = val; state = 12
            elseif state == 12 then sy = val; state = 13
            elseif state == 13 then txy = val; state = 14
            elseif state == 14 then
                alpha = val; calcMohrStandard(); state = 5; show_table = false
                
            elseif state == 21 then sa = val; state = 22
            elseif state == 22 then ta = val; state = 23
            elseif state == 23 then sb = val; state = 24
            elseif state == 24 then
                tb = val; calcMohr2Points(); state = 5; show_table = false
                
            elseif state == 31 then sa = val; state = 32
            elseif state == 32 then ta = val; state = 33
            elseif state == 33 then
                alpha_tmax = val; calcMohrMode3(); state = 5; show_table = false
            end
            inputStr = ""
            platform.window:invalidate()
        end
    end
end

function on.escapeKey()
    if state == 5 then
        if show_table then
            show_table = false
        else
            if mode == 1 then state = 14; inputStr = tostring(alpha)
            elseif mode == 2 then state = 24; inputStr = tostring(tb)
            elseif mode == 3 then state = 33; inputStr = tostring(alpha_tmax)
            end
        end
        platform.window:invalidate()
    elseif (state > 11 and state < 20) or (state > 21 and state < 30) or (state > 31 and state < 40) then
        state = state - 1
        inputStr = ""
        platform.window:invalidate()
    elseif state == 11 or state == 21 or state == 31 then
        state = 0
        inputStr = ""
        platform.window:invalidate()
    end
end

function on.clearKey()
    state = 0
    inputStr = ""
    show_table = false
    platform.window:invalidate()
end