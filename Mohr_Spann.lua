-- Perfektionierter Mohrscher Spannungskreis für TI-Nspire
-- Inkl. 4 Modi: Standard, 2-Punkte, 1-Punkt + Winkel, FORMEL-SOLVER
-- Solver berechnet nun auch Winkel rückwärts aus gegebenen Schnittspannungen!

local state = 0
local mode = 1
local inputStr = ""

-- Variablen für Modus 1-3
local sx, sy, txy, alpha = 0, 0, 0, 0
local s_xi, s_eta, t_xiet = 0, 0, 0
local sa, ta, sb, tb, alpha_tmax = 0, 0, 0, 0, 0
local sigm, r, sig1, sig2, phi = 0, 0, 0, 0, 0

-- Variablen für Modus 4 (Solver)
local sv = {}
local sv_given = {}
local solver_idx = 1
local solver_prompts = {
    {"Normalspg. (x)", "σ_x", "Merksatz: Druck \"-\""},
    {"Normalspg. (y)", "σ_y", "Merksatz: Druck \"-\""},
    {"Schubspannung", "τ_xy", "Merksatz: gegen Uhrz. \"+\""},
    {"Drehwinkel 1", "α_1", "Merksatz: gegen Uhrz. \"+\""},
    {"Gedrehtes σ_ξ 1", "σ_ξ1", "Merksatz: Druck \"-\""},
    {"Gedrehtes τ_ξη 1", "τ_ξ1η1", "Merksatz: gegen Uhrz. \"+\""},
    {"Drehwinkel 2", "α_2", "Merksatz: gegen Uhrz. \"+\""},
    {"Gedrehtes σ_ξ 2", "σ_ξ2", "Merksatz: Druck \"-\""},
    {"Gedrehtes τ_ξη 2", "τ_ξ2η2", "Merksatz: gegen Uhrz. \"+\""},
    {"Hauptspannung 1", "σ_1", "Meist die größere Spannung"},
    {"Hauptspannung 2", "σ_2", "Meist die kleinere Spannung"},
    {"Max Schubspg.", "τ_max", "Radius des Kreises"},
    {"Winkel zu τ_max", "α_tmax", "Merksatz: gegen Uhrz. \"+\""}
}
local solver_keys = {"sx", "sy", "txy", "a1", "s_xi1", "t_xiet1", "a2", "s_xi2", "t_xiet2", "s1", "s2", "tmax", "a_tmax"}

local show_table = false
local W = platform.window:width() or 318
local H = platform.window:height() or 212

function on.resize()
    W = platform.window:width()
    H = platform.window:height()
end

function drawInputBox(gc, title, varName, hint)
    local boxW, boxH = 280, 110
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
    
    gc:setFont("sansserif", "b", 13)
    gc:setColorRGB(0, 50, 150)
    local displayStr = varName .. " = " .. inputStr .. "_"
    if (state == 14 or state == 33 or mode == 4) and inputStr == "" then
        displayStr = varName .. " = _ (Leer = ?)"
    end
    gc:drawString(displayStr, boxX + 10, boxY + 45)
    
    gc:setColorRGB(100, 100, 100)
    gc:setFont("sansserif", "i", 9)
    gc:drawString("[Enter] Weiter  |  [Esc] Zurück", boxX + 10, boxY + 75)
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
        gc:drawString(t1, (W - gc:getStringWidth(t1))/2, 10)
        
        gc:setFont("sansserif", "r", 10)
        gc:drawString("Wähle den Eingabemodus:", 15, 35)
        
        gc:setFont("sansserif", "b", 11)
        gc:setColorRGB(0, 50, 150)
        gc:drawString("[ 1 ] Standard (σx, σy, τxy, α)", 25, 60)
        gc:setColorRGB(200, 50, 0)
        gc:drawString("[ 2 ] 2 Punkte (σa, τa, σb, τb)", 25, 85)
        gc:setColorRGB(0, 150, 0)
        gc:drawString("[ 3 ] Punkt + Winkel zu τ_max", 25, 110)
        gc:setColorRGB(100, 0, 150)
        gc:drawString("[ 4 ] Solver (Finde Unbekannte!)", 25, 135)
        
        gc:setColorRGB(100, 100, 100)
        gc:setFont("sansserif", "i", 9)
        gc:drawString("Taste 1, 2, 3 oder 4 drücken", 25, 160)
        
    -- Modus 1-3
    elseif state == 11 then drawInputBox(gc, "1. Normalspannung (x)", "σ_x", "Merksatz: Druck \"-\"")
    elseif state == 12 then drawInputBox(gc, "2. Normalspannung (y)", "σ_y", "Merksatz: Druck \"-\"")
    elseif state == 13 then drawInputBox(gc, "3. Schubspannung", "τ_xy", "Merksatz: gegen Uhrz. \"+\"")
    elseif state == 14 then drawInputBox(gc, "4. Drehwinkel in Grad", "α", "Merksatz: gegen Uhrz. \"+\"")
    
    elseif state == 21 then drawInputBox(gc, "1. Punkt: Normalspg.", "σ_a", "Merksatz: Druck \"-\"")
    elseif state == 22 then drawInputBox(gc, "1. Punkt: Schubspg.", "τ_a", "Merksatz: gegen Uhrz. \"+\"")
    elseif state == 23 then drawInputBox(gc, "2. Punkt: Normalspg.", "σ_b", "Merksatz: Druck \"-\"")
    elseif state == 24 then drawInputBox(gc, "2. Punkt: Schubspg.", "τ_b", "Merksatz: gegen Uhrz. \"+\"")
    
    elseif state == 31 then drawInputBox(gc, "Gegebene Normalspg.", "σ_a", "Merksatz: Druck \"-\"")
    elseif state == 32 then drawInputBox(gc, "Gegebene Schubspg.", "τ_a", "Merksatz: gegen Uhrz. \"+\"")
    elseif state == 33 then drawInputBox(gc, "Winkel zu τ_max", "α_tmax", "Merksatz: gegen Uhrz. \"+\"")
    
    -- Modus 4
    elseif state == 40 then
        local p = solver_prompts[solver_idx]
        drawInputBox(gc, solver_idx.."/"..#solver_prompts..": "..p[1], p[2], p[3])
        
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
    if norm > 5 then nice = 10 elseif norm > 2 then nice = 5 elseif norm > 1 then nice = 2 end
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
    gc:drawString(infoStr, (W - gc:getStringWidth(infoStr))/2, 4)

    local graphH = H - topBarH
    local pad = 30
    local min_s, max_s, min_t, max_t
    if mode == 1 or mode == 4 then
        min_s = math.min(sigm - r, 0, sx, sy, s_xi, s_eta)
        max_s = math.max(sigm + r, 0, sx, sy, s_xi, s_eta)
        min_t = math.min(-r, 0, -txy, -t_xiet)
        max_t = math.max(r, 0, txy, t_xiet)
        if mode == 4 then
            min_s = math.min(min_s, sv.s_xi2 or min_s, sv.s_eta2 or min_s)
            max_s = math.max(max_s, sv.s_xi2 or max_s, sv.s_eta2 or max_s)
            min_t = math.min(min_t, -(sv.t_xiet2 or 0))
            max_t = math.max(max_t, sv.t_xiet2 or 0)
        end
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
    gc:setColorRGB(0, 0, 200)
    gc:setPen("medium", "smooth")
    gc:drawArc(cx - radius_px, cy - radius_px, radius_px * 2, radius_px * 2, 0, 360)
    gc:fillArc(cx - 2, cy - 2, 4, 4, 0, 360)
    drawLabel(gc, "σ_m", cx - 8, cy + 4)
    gc:fillArc(ox + sig1*scale - 2, cy - 2, 4, 4, 0, 360)
    gc:fillArc(ox + sig2*scale - 2, cy - 2, 4, 4, 0, 360)
    drawLabel(gc, "σ_1", ox + sig1*scale + 2, cy - 15)
    drawLabel(gc, "σ_2", ox + sig2*scale - 18, cy - 15)
    
    if mode == 1 or (mode == 4 and sv.sx and sv.sy) then
        local px1 = ox + sx * scale; local py1 = oy - txy * scale
        local px2 = ox + sy * scale; local py2 = oy + txy * scale
        gc:setColorRGB(200, 0, 0); gc:drawLine(px1, py1, px2, py2)
        gc:fillArc(px1 - 2, py1 - 2, 4, 4, 0, 360); gc:fillArc(px2 - 2, py2 - 2, 4, 4, 0, 360)
        drawLabel(gc, "σ_x", px1 + 4, py1 - 8); drawLabel(gc, "σ_y", px2 + 4, py2 - 8)
        
        -- Grüne Graphen für den Winkel Alpha (Modus 1 & 4)
        if alpha ~= 0 or (mode == 4 and sv.a1 and sv.s_xi1) then
            local px3 = ox + s_xi * scale; local py3 = oy - t_xiet * scale
            local px4 = ox + s_eta * scale; local py4 = oy + t_xiet * scale
            gc:setColorRGB(0, 150, 0); gc:drawLine(px3, py3, px4, py4)
            gc:fillArc(px3 - 2, py3 - 2, 4, 4, 0, 360); gc:fillArc(px4 - 2, py4 - 2, 4, 4, 0, 360)
            drawLabel(gc, "σ_ξ1", px3 + 4, py3 - 8); drawLabel(gc, "σ_η1", px4 + 4, py4 - 8)
        end
        if mode == 4 and sv.a2 and sv.s_xi2 and sv.s_eta2 and sv.t_xiet2 then
            local px5 = ox + sv.s_xi2 * scale; local py5 = oy - sv.t_xiet2 * scale
            local px6 = ox + sv.s_eta2 * scale; local py6 = oy + sv.t_xiet2 * scale
            gc:setColorRGB(220, 120, 0); gc:drawLine(px5, py5, px6, py6)
            gc:fillArc(px5 - 2, py5 - 2, 4, 4, 0, 360); gc:fillArc(px6 - 2, py6 - 2, 4, 4, 0, 360)
            drawLabel(gc, "σ_ξ2", px5 + 4, py5 - 8); drawLabel(gc, "σ_η2", px6 + 4, py6 - 8)
        end
        
    elseif mode == 2 or mode == 3 then
        local px1 = ox + sa * scale; local py1 = oy - ta * scale
        local px1_opp = ox + (2*sigm - sa) * scale; local py1_opp = oy + ta * scale
        gc:setColorRGB(200, 0, 0); gc:drawLine(px1, py1, px1_opp, py1_opp)
        gc:fillArc(px1 - 2, py1 - 2, 4, 4, 0, 360); gc:fillArc(px1_opp - 2, py1_opp - 2, 4, 4, 0, 360)
        drawLabel(gc, "P_a", px1 + 4, py1 - 8)
    end
end

function drawTable(gc)
    gc:setColorRGB(255, 255, 255)
    gc:fillRect(0, 0, W, H)
    gc:setColorRGB(0, 50, 150)
    gc:fillRect(0, 0, W, 25)
    gc:setColorRGB(255, 255, 255)
    gc:setFont("sansserif", "b", 11)
    
    if mode == 4 then
        gc:drawString("Solver Ergebnisse ([Esc] Zurueck)", 5, 5)
    else
        gc:drawString("Ergebnistabelle (Schliessen mit 'T')", 5, 5)
    end
    
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
        data = {
            {"Punkt A: σ_a", string.format("%.2f", sa), "Winkel zu τ_max", string.format("%.2f °", alpha_tmax)},
            {"Punkt A: τ_a", string.format("%.2f", ta), "Mittelpunkt σ_m", string.format("%.2f", sigm)},
            {"Gegenst. A': σ", string.format("%.2f", 2*sigm - sa), "Radius τ_max", string.format("%.2f", r)},
            {"Gegenst. A': τ", string.format("%.2f", -ta), "Winkel zu σ_1", string.format("%.2f °", phi)},
            {"Max Punkt: σ", string.format("%.2f", sigm), "Max Punkt: τ", string.format("%.2f", r)},
            {"Hauptspg. σ_1", string.format("%.2f", sig1), "Hauptspg. σ_2", string.format("%.2f", sig2)}
        }
    elseif mode == 4 then
        local function fmt(val, k)
            if val == nil then return "?" end
            local s = string.format("%.2f", val)
            if sv_given[k] then return s .. " (*)" else return s end
        end
        data = {
            {"σ_x", fmt(sv.sx, "sx"), "α_1", fmt(sv.a1, "a1")},
            {"σ_y", fmt(sv.sy, "sy"), "σ_ξ1", fmt(sv.s_xi1, "s_xi1")},
            {"τ_xy", fmt(sv.txy, "txy"), "σ_η1", fmt(sv.s_eta1, "s_eta1")},
            {"", "", "τ_ξ1η1", fmt(sv.t_xiet1, "t_xiet1")},
            {"α_2", fmt(sv.a2, "a2"), "σ_ξ2", fmt(sv.s_xi2, "s_xi2")},
            {"σ_η2", fmt(sv.s_eta2, "s_eta2"), "τ_ξ2η2", fmt(sv.t_xiet2, "t_xiet2")},
            {"Mitte σ_m", fmt(sv.sm, "sm"), "Winkel σ_1", fmt(sv.phi, "phi")},
            {"Rad. τ_max", fmt(sv.R, "R"), "Winkel α_tmax", fmt(sv.a_tmax, "a_tmax")},
            {"Haupt. σ_1", fmt(sv.s1, "s1"), "(*) = Eingabe", ""},
            {"Haupt. σ_2", fmt(sv.s2, "s2"), "", ""}
        }
    end
    
    local y_start = 30
    local row_h = 18
    local col1, col2, col3, col4 = 5, 105, 165, 255
    if mode == 4 then col1 = 2; col2 = 85; col3 = 155; col4 = 240 end
    
    for i, row in ipairs(data) do
        local y = y_start + (i-1) * row_h
        if i % 2 == 0 then
            gc:setColorRGB(240, 240, 240); gc:fillRect(0, y, W, row_h); gc:setColorRGB(0, 0, 0)
        end
        gc:setFont("sansserif", "b", 9); gc:drawString(row[1], col1, y + 2); gc:drawString(row[3], col3, y + 2)
        if mode == 4 and row[2]:match("%(%*%)") then gc:setColorRGB(0, 100, 0) else gc:setColorRGB(0,0,0) end
        gc:setFont("sansserif", "r", 9); gc:drawString(row[2], col2, y + 2)
        if mode == 4 and row[4]:match("%(%*%)") then gc:setColorRGB(0, 100, 0) else gc:setColorRGB(0,0,0) end
        gc:drawString(row[4], col4, y + 2)
        gc:setColorRGB(0,0,0)
    end
end

-- ================= INFERENCE ENGINE (SOLVER) =================
function solveEquations()
    local changed = true
    local iters = 0
    while changed and iters < 20 do
        changed = false
        local function set(k, val)
            if sv[k] == nil and val ~= nil then
                sv[k] = val; changed = true
            end
        end

        local function normAngle(value)
            while value <= -90 do value = value + 180 end
            while value > 90 do value = value - 180 end
            return value
        end

        -- 1. Mittelpunktspannung und Invarianten
        if sv.sx and sv.sy then set("sm", (sv.sx + sv.sy)/2) end
        if sv.s1 and sv.s2 then set("sm", (sv.s1 + sv.s2)/2) end
        if sv.s_xi1 and sv.s_eta1 then set("sm", (sv.s_xi1 + sv.s_eta1)/2) end
        
        if sv.sm and sv.sx then set("sy", 2*sv.sm - sv.sx) end
        if sv.sm and sv.sy then set("sx", 2*sv.sm - sv.sy) end
        if sv.sm and sv.s1 then set("s2", 2*sv.sm - sv.s1) end
        if sv.sm and sv.s2 then set("s1", 2*sv.sm - sv.s2) end
        if sv.sm and sv.s_xi1 then set("s_eta1", 2*sv.sm - sv.s_xi1) end
        
        -- 2. Winkel zu Hauptspannungen
        if sv.a_tmax then
            set("phi", normAngle(sv.a_tmax + 45))
        end
        if sv.phi then
            set("a_tmax", normAngle(sv.phi - 45))
        end
        
        -- 3. Radius & max Schubspannung
        if sv.tmax then set("R", math.abs(sv.tmax)) end
        if sv.R then set("tmax", sv.R) end
        if sv.s1 and sv.s2 then set("R", math.abs(sv.s1 - sv.s2)/2) end
        if sv.sm and sv.s1 then set("R", math.abs(sv.s1 - sv.sm)) end
        if sv.sx and sv.sy and sv.txy then 
            set("R", math.sqrt(((sv.sx-sv.sy)/2)^2 + sv.txy^2)) 
        end
        
        -- 4. Hauptspannungen aus sm und R
        if sv.sm and sv.R then
            set("s1", sv.sm + sv.R)
            set("s2", sv.sm - sv.R)
        end
        
        -- 5. txy rückwärts und phi
        if sv.R and sv.sx and sv.sy then
            local t2 = sv.R^2 - ((sv.sx - sv.sy)/2)^2
            if t2 >= -1e-7 then set("txy", math.sqrt(math.max(0, t2))) end
        end
        if sv.sx and sv.sy and sv.txy then
            set("phi", normAngle(0.5 * math.deg(math.atan2(2 * sv.txy, sv.sx - sv.sy))))
        end
        
        -- 6. Vorwärts-Rotation (Alpha ist bekannt)
        local function applyRotation(a_key, xi_key, eta_key, t_key)
            if sv[a_key] and sv.sx and sv.sy and sv.txy and sv.sm then
                local rad = math.rad(sv[a_key])
                local D = (sv.sx - sv.sy) / 2
                set(xi_key, sv.sm + D * math.cos(2*rad) + sv.txy * math.sin(2*rad))
                set(eta_key, sv.sm - D * math.cos(2*rad) - sv.txy * math.sin(2*rad))
                set(t_key, -D * math.sin(2*rad) + sv.txy * math.cos(2*rad))
            end
        end
        applyRotation("a1", "s_xi1", "s_eta1", "t_xiet1")
        applyRotation("a2", "s_xi2", "s_eta2", "t_xiet2")
        
        -- 7. RÜCKWÄRTS-Winkel-Berechnung (Alpha ist gesucht)
        local function trySolveAngle(a_key, xi_key, eta_key, t_key)
            if sv[a_key] == nil and sv.sx and sv.sy and sv.sm and sv.R and sv.R > 0 then
                local txy = sv.txy or 0
                local D = (sv.sx - sv.sy) / 2
                local theta_0 = math.atan2(txy, D)
                local C = nil
                
                if sv[xi_key] ~= nil then
                    C = sv[xi_key] - sv.sm
                elseif sv[eta_key] ~= nil then
                    C = -(sv[eta_key] - sv.sm)
                end
                
                if C ~= nil then
                    local d = C / sv.R
                    -- Absicherung gegen Rundungsfehler
                    if d > 1 then d = 1 elseif d < -1 then d = -1 end
                    local ac = math.acos(d)
                    
                    local u
                    if sv[t_key] ~= nil then
                        -- Entscheide Vorzeichen anhand von tau
                        if sv[t_key] < 0 then u = ac else u = -ac end
                    else
                        u = ac -- Nimmt Standardlösung, wenn tau_xi_eta unbekannt
                    end
                    
                    set(a_key, normAngle(math.deg(theta_0 + u) / 2))
                end
            end
        end
        trySolveAngle("a1", "s_xi1", "s_eta1", "t_xiet1")
        trySolveAngle("a2", "s_xi2", "s_eta2", "t_xiet2")
        
        iters = iters + 1
    end
end
-- ==============================================================

function calcMohrStandard()
    sigm = (sx + sy) / 2
    r = math.sqrt(((sx - sy) / 2)^2 + txy^2)
    sig1 = sigm + r; sig2 = sigm - r
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
    sig1 = sigm + r; sig2 = sigm - r
end

function calcMohrMode3()
    local rad2 = math.rad(2 * alpha_tmax)
    if math.abs(math.cos(rad2)) < 1e-7 then rad2 = rad2 + 0.0001 end
    sigm = sa - ta * math.tan(rad2)
    r = math.abs(ta / math.cos(rad2))
    sig1 = sigm + r; sig2 = sigm - r
end

function on.charIn(char)
    if state == 0 then
        if char == "1" then mode = 1; state = 11; inputStr = ""; platform.window:invalidate()
        elseif char == "2" then mode = 2; state = 21; inputStr = ""; platform.window:invalidate()
        elseif char == "3" then mode = 3; state = 31; inputStr = ""; platform.window:invalidate()
        elseif char == "4" then 
            mode = 4; state = 40; inputStr = ""; solver_idx = 1
            sv = {}; sv_given = {}
            platform.window:invalidate()
        end
        return
    end

    if (state >= 11 and state <= 14) or (state >= 21 and state <= 24) or (state >= 31 and state <= 33) or state == 40 then
        if char:match("[%d%.%-]") then
            inputStr = inputStr .. char; platform.window:invalidate()
        end
    end
    if state == 5 and (char == "t" or char == "T") then
        show_table = not show_table; platform.window:invalidate()
    end
end

function on.backspaceKey()
    if (state >= 11 and state <= 14) or (state >= 21 and state <= 24) or (state >= 31 and state <= 33) or state == 40 then
        if #inputStr > 0 then
            inputStr = string.sub(inputStr, 1, -2); platform.window:invalidate()
        end
    end
end

function on.enterKey()
    if state == 0 then return end 
    local val = tonumber(inputStr)
    
    if mode == 4 and state == 40 then
        local key = solver_keys[solver_idx]
        if val ~= nil then 
            sv[key] = val
            sv_given[key] = true
        end
        if solver_idx < #solver_keys then
            solver_idx = solver_idx + 1; inputStr = ""
        else
            solveEquations()
            sigm = sv.sm or 0
            r = sv.R or 0
            sig1 = sv.s1 or (sigm + r)
            sig2 = sv.s2 or (sigm - r)
            sx = sv.sx or 0
            sy = sv.sy or 0
            txy = sv.txy or 0
            alpha = sv.a1 or 0
            s_xi = sv.s_xi1 or 0
            s_eta = sv.s_eta1 or 0
            t_xiet = sv.t_xiet1 or 0
            alpha_tmax = sv.a_tmax or 0
            phi = sv.phi or 0
            
            state = 5
            show_table = true
        end
        platform.window:invalidate()
        return
    end
    
    if (state == 14 or state == 33) and (inputStr == "" or val == nil) then val = 0 end
    if val ~= nil then
        if state == 11 then sx = val; state = 12
        elseif state == 12 then sy = val; state = 13
        elseif state == 13 then txy = val; state = 14
        elseif state == 14 then alpha = val; calcMohrStandard(); state = 5; show_table = false
        elseif state == 21 then sa = val; state = 22
        elseif state == 22 then ta = val; state = 23
        elseif state == 23 then sb = val; state = 24
        elseif state == 24 then tb = val; calcMohr2Points(); state = 5; show_table = false
        elseif state == 31 then sa = val; state = 32
        elseif state == 32 then ta = val; state = 33
        elseif state == 33 then alpha_tmax = val; calcMohrMode3(); state = 5; show_table = false
        end
        inputStr = ""; platform.window:invalidate()
    end
end

function on.escapeKey()
    if state == 5 then
        if mode == 4 then
            solver_idx = #solver_keys; state = 40; inputStr = ""
        else
            if show_table then show_table = false else
                if mode == 1 then state = 14; inputStr = tostring(alpha)
                elseif mode == 2 then state = 24; inputStr = tostring(tb)
                elseif mode == 3 then state = 33; inputStr = tostring(alpha_tmax)
                end
            end
        end
        platform.window:invalidate()
    elseif state == 40 then
        if solver_idx > 1 then
            solver_idx = solver_idx - 1; inputStr = ""
            sv[solver_keys[solver_idx]] = nil
            sv_given[solver_keys[solver_idx]] = nil
        else state = 0 end
        platform.window:invalidate()
    elseif (state > 11 and state < 20) or (state > 21 and state < 30) or (state > 31 and state < 40) then
        state = state - 1; inputStr = ""; platform.window:invalidate()
    elseif state == 11 or state == 21 or state == 31 then
        state = 0; inputStr = ""; platform.window:invalidate()
    end
end

function on.clearKey()
    state = 0; inputStr = ""; show_table = false; platform.window:invalidate()
end