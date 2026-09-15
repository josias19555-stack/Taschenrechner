-- Perfektionierter Mohrscher Spannungskreis für TI-Nspire
-- Inkl. präziser Hauptwinkel phi (Winkel zu Sigma 1) per atan2

local state = 0
local inputStr = ""
local sx, sy, txy, alpha = 0, 0, 0, 0
local sigm, r, sig1, sig2, phi = 0, 0, 0, 0, 0
local s_xi, s_eta, t_xiet = 0, 0, 0
local show_table = false

local W = platform.window:width() or 318
local H = platform.window:height() or 212

function on.resize()
    W = platform.window:width()
    H = platform.window:height()
end

function drawInputBox(gc, title, varName)
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
    
    gc:setFont("sansserif", "b", 14)
    gc:setColorRGB(0, 50, 150)
    local displayStr = varName .. " = " .. inputStr .. "_"
    if state == 4 and inputStr == "" then
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
        gc:drawString(t1, (W - t1_w)/2, H/2 - 40)
        
        local btnW, btnH = 160, 30
        gc:setColorRGB(200, 200, 200)
        gc:fillRect((W - btnW)/2, H/2 - 10, btnW, btnH)
        gc:setColorRGB(0, 0, 0)
        gc:drawRect((W - btnW)/2, H/2 - 10, btnW, btnH)
        
        gc:setFont("sansserif", "r", 10)
        local t2 = "Start mit 'Enter'"
        local t2_w = gc:getStringWidth(t2)
        gc:drawString(t2, (W - t2_w)/2, H/2 - 2)
        
    elseif state == 1 then drawInputBox(gc, "1. Normalspannung (x)", "σ_x")
    elseif state == 2 then drawInputBox(gc, "2. Normalspannung (y)", "σ_y")
    elseif state == 3 then drawInputBox(gc, "3. Schubspannung", "τ_xy")
    elseif state == 4 then drawInputBox(gc, "4. Drehwinkel in Grad", "α")
    elseif state == 5 then
        if show_table then
            drawTable(gc)
        else
            drawGraph(gc)
        end
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
    
    local min_s = math.min(sigm - r, 0, sx, sy, s_xi, s_eta)
    local max_s = math.max(sigm + r, 0, sx, sy, s_xi, s_eta)
    local min_t = math.min(-r, 0, -txy, -t_xiet)
    local max_t = math.max(r, 0, txy, t_xiet)
    
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
    gc:drawString("τ", ox + 5, H - 15) 
    
    gc:setFont("sansserif", "r", 8)
    local step = getNiceStep(math.max(span_s, span_t))
    
    for v = math.floor(min_s/step)*step, max_s, step do
        local px = ox + v * scale
        if px > 0 and px < W then
            gc:drawLine(px, oy - 2, px, oy + 2)
            if v ~= 0 then gc:drawString(tostring(v), px - 5, oy + 4) end
        end
    end
    for v = math.floor(min_t/step)*step, max_t, step do
        local py = oy + v * scale
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
    
    local px1 = ox + sx * scale
    local py1 = oy + txy * scale
    local px2 = ox + sy * scale
    local py2 = oy - txy * scale
    
    gc:setColorRGB(200, 0, 0)
    gc:drawLine(px1, py1, px2, py2)
    gc:fillArc(px1 - 2, py1 - 2, 4, 4, 0, 360)
    gc:fillArc(px2 - 2, py2 - 2, 4, 4, 0, 360)
    
    drawLabel(gc, "σ_x", px1 + 4, py1 - 8)
    drawLabel(gc, "σ_y", px2 + 4, py2 - 8)
    
    if alpha ~= 0 then
        local px3 = ox + s_xi * scale
        local py3 = oy + t_xiet * scale
        local px4 = ox + s_eta * scale
        local py4 = oy - t_xiet * scale
        
        gc:setColorRGB(0, 150, 0)
        gc:drawLine(px3, py3, px4, py4)
        gc:fillArc(px3 - 2, py3 - 2, 4, 4, 0, 360)
        gc:fillArc(px4 - 2, py4 - 2, 4, 4, 0, 360)
        
        drawLabel(gc, "σ_ξ", px3 + 4, py3 - 8)
        drawLabel(gc, "σ_η", px4 + 4, py4 - 8)
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
    
    local data = {
        {"Eingabe: σ_x", string.format("%.2f", sx), "Eingabe: α", string.format("%.2f °", alpha)},
        {"Eingabe: σ_y", string.format("%.2f", sy), "Gedreht: σ_ξ", string.format("%.2f", s_xi)},
        {"Eingabe: τ_xy", string.format("%.2f", txy), "Gedreht: σ_η", string.format("%.2f", s_eta)},
        {"", "", "Gedreht: τ_ξη", string.format("%.2f", t_xiet)},
        {"Mittelpunkt σ_m", string.format("%.2f", sigm), "Winkel zu σ_1", string.format("%.2f °", phi)},
        {"Radius τ_max", string.format("%.2f", r), "", ""},
        {"Hauptspg. σ_1", string.format("%.2f", sig1), "", ""},
        {"Hauptspg. σ_2", string.format("%.2f", sig2), "", ""}
    }
    
    local y_start = 30
    local row_h = 18
    local col1 = 5
    local col2 = 95
    local col3 = 160
    local col4 = 240
    
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

function calcMohr()
    sigm = (sx + sy) / 2
    r = math.sqrt(((sx - sy) / 2)^2 + txy^2)
    sig1 = sigm + r
    sig2 = sigm - r
    
    -- Hauptwinkel mit atan2 (Richtet sich immer exakt nach Sigma 1 aus)
    phi = 0.5 * math.deg(math.atan2(2 * txy, sx - sy))
    
    local rad = math.rad(alpha)
    s_xi = sigm + ((sx - sy)/2) * math.cos(2*rad) + txy * math.sin(2*rad)
    s_eta = sigm - ((sx - sy)/2) * math.cos(2*rad) - txy * math.sin(2*rad)
    t_xiet = -((sx - sy)/2) * math.sin(2*rad) + txy * math.cos(2*rad)
end

function on.charIn(char)
    if state >= 1 and state <= 4 then
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
    if state >= 1 and state <= 4 then
        if #inputStr > 0 then
            inputStr = string.sub(inputStr, 1, -2)
            platform.window:invalidate()
        end
    end
end

function on.enterKey()
    if state == 0 then
        state = 1
        inputStr = ""
        platform.window:invalidate()
        return
    end
    
    if state >= 1 and state <= 4 then
        local val = tonumber(inputStr)
        
        if state == 4 and (inputStr == "" or val == nil) then
            val = 0
        end
        
        if val ~= nil then
            if state == 1 then sx = val; state = 2
            elseif state == 2 then sy = val; state = 3
            elseif state == 3 then txy = val; state = 4
            elseif state == 4 then
                alpha = val
                calcMohr()
                state = 5
                show_table = false
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
            state = 4 
            inputStr = tostring(alpha)
        end
        platform.window:invalidate()
    elseif state > 1 then
        state = state - 1
        inputStr = ""
        platform.window:invalidate()
    elseif state == 1 then
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