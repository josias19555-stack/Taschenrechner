-- Spannungskreis.lua: ebener Spannungszustand ueber Schnitte
--
-- Eingabe und Ergebnis stehen in derselben Tabelle: Spalten sind die Schnitte, Zeilen sind
--   α  Winkel der Schnittnormalen gegen die x-Achse, mathematisch positiv (gegen den Uhrzeigersinn)
--   σ  Normalspannung in diesem Schnitt
--   τ  Schubspannung in diesem Schnitt (Tangente = Normale um +90 Grad gedreht)
-- Leere Felder sind unbekannt und werden berechnet; jeder Wert laesst sich jederzeit aendern.
--
-- Rechenweg (ohne CAS, alles geschlossen):
--   Mit σm = (σx+σy)/2, Rc = (σx-σy)/2, Rs = τxy gilt
--      σ(α) = σm + Rc*cos(2α) + Rs*sin(2α)
--      τ(α) =    - Rc*sin(2α) + Rs*cos(2α)
--   Beide Gleichungen sind in (σm, Rc, Rs) linear, solange der Winkel bekannt ist: drei
--   unabhaengige Angaben bestimmen den Zustand (Gauss mit Rangkontrolle). Fehlende Winkel folgen
--   geschlossen aus σ = σm + R*cos(2α-φ), τ = -R*sin(2α-φ) mit R = |(Rc,Rs)|, φ = atan2(Rs,Rc).
--
-- Tasten: [b] rechnen  [s] Spannungsscheibe  [k] Mohrscher Kreis  [t] Tabelle
--         Pfeile: Zelle waehlen   Enter: Zelle aendern   Backspace: Zelle leeren
--         [del] alles neu (mit Rueckfrage)

local W = (platform and platform.window and platform.window:width()) or 318
local H = (platform and platform.window and platform.window:height()) or 212

local schnitte = {}          -- { {a=, s=, t=, a_in=, s_in=, t_in=} }
local modus = "tabelle"      -- tabelle | scheibe | kreis
local spalte, zeile = 1, 1   -- Cursor in der Tabelle (zeile 1 = α, 2 = σ, 3 = τ)
local editiere = false
local text = ""
local scroll = 0             -- erste sichtbare Spalte
local meldung = nil
local loeschFrage = false
local loesung = nil
local rang = 0
local widerspruch = false

local FARBE_EIN = { 0, 0, 0 }
local FARBE_BER = { 0, 130, 0 }
local FARBE_KOPF = { 0, 50, 150 }
local FARBE_SIGMA = { 200, 0, 0 }
local FARBE_TAU = { 0, 100, 200 }

local ZEILENNAME = { "α [°]", "σ", "τ" }

-- ===================== Hilfen =====================

local function grad(x) return x * 180 / math.pi end
local function bogen(x) return x * math.pi / 180 end
local function setFarbe(gc, f) gc:setColorRGB(f[1], f[2], f[3]) end

local function wertVon(s)
    s = tostring(s or ""):gsub(",", ".")
    if s:match("^%s*$") then return nil, true end
    if math.eval then
        local ok, v = pcall(function() return tonumber(math.eval("approx(" .. s .. ")")) end)
        if ok and type(v) == "number" then return v, true end
    end
    local chunk = (loadstring or load)("return " .. s)
    if chunk then
        if setfenv then setfenv(chunk, setmetatable({ math = math }, { __index = math })) end
        local ok, v = pcall(chunk)
        if ok and type(v) == "number" and v == v then return v, true end
    end
    return nil, false
end

local function fmt(x, stellen)
    if x == nil then return "" end
    if math.abs(x) < 5e-11 then x = 0 end
    return string.format("%." .. (stellen or 2) .. "f", x)
end

local function neuerSchnitt() return { a = nil, s = nil, t = nil, a_in = false, s_in = false, t_in = false } end

-- Wert und Eingabemarke einer Zelle
local function zelle(sch, z)
    if z == 1 then return sch.a, sch.a_in elseif z == 2 then return sch.s, sch.s_in else return sch.t, sch.t_in end
end
local function setzeZelle(sch, z, v)
    if z == 1 then sch.a, sch.a_in = v, (v ~= nil)
    elseif z == 2 then sch.s, sch.s_in = v, (v ~= nil)
    else sch.t, sch.t_in = v, (v ~= nil) end
end
local function leererSchnitt(sch)
    return not sch.a_in and not sch.s_in and not sch.t_in
end

-- ===================== Rechnung =====================

local function gleichungen()
    local A, b = {}, {}
    for _, sch in ipairs(schnitte) do
        if sch.a_in and sch.a then
            local z = 2 * bogen(sch.a)
            if sch.s_in and sch.s then A[#A + 1] = { 1, math.cos(z), math.sin(z) }; b[#b + 1] = sch.s end
            if sch.t_in and sch.t then A[#A + 1] = { 0, -math.sin(z), math.cos(z) }; b[#b + 1] = sch.t end
        end
    end
    return A, b
end

local function loeseLGS(A, b)
    local n = #A
    if n == 0 then return nil, 0, false end
    local M, skala = {}, 1e-9
    for r = 1, n do
        M[r] = { A[r][1], A[r][2], A[r][3], b[r] }
        for c = 1, 4 do skala = math.max(skala, math.abs(M[r][c])) end
    end
    local zn, pivot = 1, {}
    for sp = 1, 3 do
        local best, bi = 1e-9 * skala, nil
        for r = zn, n do if math.abs(M[r][sp]) > best then best, bi = math.abs(M[r][sp]), r end end
        if bi then
            M[zn], M[bi] = M[bi], M[zn]
            for r = 1, n do
                if r ~= zn and M[r][sp] ~= 0 then
                    local f = M[r][sp] / M[zn][sp]
                    for c = sp, 4 do M[r][c] = M[r][c] - f * M[zn][c] end
                end
            end
            pivot[sp] = zn
            zn = zn + 1
        end
    end
    local r_ang = zn - 1
    local wider = false
    for r = r_ang + 1, n do if math.abs(M[r][4]) > 1e-6 * skala then wider = true end end
    if r_ang < 3 then return nil, r_ang, wider end
    local x = {}
    for sp = 1, 3 do local z = pivot[sp]; x[sp] = M[z][4] / M[z][sp] end
    return x, 3, wider
end

local function spannungen(a_grad, L)
    local z = 2 * bogen(a_grad)
    return L.sig_m + L.rc * math.cos(z) + L.rs * math.sin(z),
           -L.rc * math.sin(z) + L.rs * math.cos(z)
end

local function winkelAus(sch, L)
    local R, phi = L.r, L.phi
    if R < 1e-9 then return nil, nil, "Kreis hat Radius 0" end
    local function norm(a)
        while a < 0 do a = a + 180 end
        while a >= 180 do a = a - 180 end
        return a
    end
    if sch.s_in and sch.t_in and sch.s and sch.t then
        return norm(grad((phi + math.atan2(-sch.t, sch.s - L.sig_m)) / 2))
    elseif sch.s_in and sch.s then
        local c = (sch.s - L.sig_m) / R
        if c > 1 + 1e-9 or c < -1 - 1e-9 then return nil, nil, "σ liegt nicht auf dem Kreis" end
        local d = math.acos(math.max(-1, math.min(1, c)))
        return norm(grad((phi + d) / 2)), norm(grad((phi - d) / 2))
    elseif sch.t_in and sch.t then
        local sn = -sch.t / R
        if sn > 1 + 1e-9 or sn < -1 - 1e-9 then return nil, nil, "τ liegt nicht auf dem Kreis" end
        local d = math.asin(math.max(-1, math.min(1, sn)))
        return norm(grad((phi + d) / 2)), norm(grad((phi + math.pi - d) / 2))
    end
    return nil, nil, "keine Angabe"
end

local function rechne()
    loesung, widerspruch = nil, false
    for _, sch in ipairs(schnitte) do
        sch.hinweis, sch.a2 = nil, nil
        if not sch.a_in then sch.a = nil end
        if not sch.s_in then sch.s = nil end
        if not sch.t_in then sch.t = nil end
    end
    local A, b = gleichungen()
    local x, r, wider = loeseLGS(A, b)
    rang, widerspruch = r or 0, wider and true or false
    if not x then return false end
    local L = { sig_m = x[1], rc = x[2], rs = x[3] }
    L.r = math.sqrt(L.rc * L.rc + L.rs * L.rs)
    L.phi = math.atan2(L.rs, L.rc)
    L.sig1, L.sig2, L.tau_max = L.sig_m + L.r, L.sig_m - L.r, L.r
    L.a1 = grad(L.phi / 2)
    while L.a1 < 0 do L.a1 = L.a1 + 180 end
    while L.a1 >= 180 do L.a1 = L.a1 - 180 end
    L.sx, L.sy, L.txy = L.sig_m + L.rc, L.sig_m - L.rc, L.rs
    loesung = L
    for _, sch in ipairs(schnitte) do
        if sch.a_in and sch.a then
            local s, t = spannungen(sch.a, L)
            if not sch.s_in then sch.s = s end
            if not sch.t_in then sch.t = t end
        elseif not leererSchnitt(sch) then
            local a, a2, warum = winkelAus(sch, L)
            if a then
                sch.a, sch.a2 = a, a2
                local s, t = spannungen(a, L)
                if not sch.s_in then sch.s = s end
                if not sch.t_in then sch.t = t end
            else
                sch.hinweis = warum
            end
        end
    end
    return true
end

local function bereit() return loesung ~= nil and not widerspruch end

local function allesLoeschen()
    schnitte = { neuerSchnitt() }
    modus, spalte, zeile, editiere, text = "tabelle", 1, 1, false, ""
    loesung, rang, widerspruch, scroll, meldung = nil, 0, false, 0, nil
    loeschFrage = false
end

-- ===================== Zeichenhilfen =====================

local function pfeil(gc, x1, y1, x2, y2)
    gc:drawLine(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local L = math.sqrt(dx * dx + dy * dy)
    if L < 1e-6 then return end
    local ux, uy = dx / L, dy / L
    local nx, ny = -uy, ux
    local hl, hw = 6, 2.5
    local bx, by = x2 - hl * ux, y2 - hl * uy
    gc:fillPolygon({ x2, y2, bx + hw * nx, by + hw * ny, bx - hw * nx, by - hw * ny })
end

local function zentriert(gc, s, x, y) gc:drawString(s, x - gc:getStringWidth(s) / 2, y) end

local function kopf(gc, titel, rechts)
    gc:setColorRGB(255, 255, 255); gc:fillRect(0, 0, W, H)
    setFarbe(gc, FARBE_KOPF); gc:fillRect(0, 0, W, 18)
    gc:setColorRGB(255, 255, 255); gc:setFont("sansserif", "b", 10)
    gc:drawString(titel, 4, 1)
    if rechts then gc:drawString(rechts, W - gc:getStringWidth(rechts) - 4, 1) end
end

-- ===================== Tabelle (Eingabe und Ergebnis) =====================

local SP_BREIT, SP_X0 = 50, 40

local function sichtbareSpalten()
    return math.max(1, math.floor((W - SP_X0 - 4) / SP_BREIT))
end

local function haltePosition()
    local sicht = sichtbareSpalten()
    if spalte < scroll + 1 then scroll = spalte - 1 end
    if spalte > scroll + sicht then scroll = spalte - sicht end
    if scroll < 0 then scroll = 0 end
end

local function zeichneTabelle(gc)
    kopf(gc, "Spannungszustand über Schnitte", "[b] rechnen")
    gc:setColorRGB(60, 60, 60); gc:setFont("sansserif", "r", 7)
    gc:drawString("α: Winkel der Schnittnormalen zur x-Achse, mathematisch positiv (gegen den Uhrzeigersinn)", 4, 19)

    haltePosition()
    local y0, zh = 32, 14
    local sicht = sichtbareSpalten()
    -- Kopfzeile
    gc:setFont("sansserif", "b", 9); gc:setColorRGB(0, 0, 0)
    gc:drawString("Schnitt", 4, y0)
    for i = scroll + 1, math.min(#schnitte + 1, scroll + sicht) do
        local x = SP_X0 + (i - scroll - 1) * SP_BREIT
        if i <= #schnitte then gc:drawString("S" .. i, x, y0)
        else gc:setColorRGB(150, 150, 150); gc:drawString("neu", x, y0); gc:setColorRGB(0, 0, 0) end
    end
    -- Zeilen
    gc:setFont("sansserif", "r", 9)
    for z = 1, 3 do
        local y = y0 + z * zh
        gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "b", 9)
        gc:drawString(ZEILENNAME[z], 4, y)
        gc:setFont("sansserif", "r", 9)
        for i = scroll + 1, math.min(#schnitte + 1, scroll + sicht) do
            local x = SP_X0 + (i - scroll - 1) * SP_BREIT
            local sch = schnitte[i]
            local aktiv = (i == spalte and z == zeile)
            if aktiv then
                gc:setColorRGB(200, 220, 255); gc:fillRect(x - 3, y - 1, SP_BREIT - 4, zh - 1)
            end
            if aktiv and editiere then
                gc:setColorRGB(0, 0, 0); gc:drawString(text .. "_", x, y)
            elseif sch then
                local v, gesetzt = zelle(sch, z)
                if gesetzt then setFarbe(gc, FARBE_EIN) else setFarbe(gc, FARBE_BER) end
                local s = fmt(v)
                if s == "" then gc:setColorRGB(170, 170, 170); s = "-" end
                gc:drawString(s, x, y)
                if z == 1 and sch.a2 then
                    gc:setColorRGB(180, 100, 0); gc:setFont("sansserif", "r", 6)
                    gc:drawString("|" .. fmt(sch.a2, 1), x + 26, y + 2)
                    gc:setFont("sansserif", "r", 9)
                end
            end
        end
    end
    gc:setColorRGB(170, 170, 170)
    gc:drawLine(0, y0 + 3 * zh + 12, W, y0 + 3 * zh + 12)

    -- Legende und Status
    local y = y0 + 3 * zh + 14
    gc:setFont("sansserif", "r", 7)
    setFarbe(gc, FARBE_EIN); gc:drawString("schwarz: eingegeben", 4, y)
    setFarbe(gc, FARBE_BER); gc:drawString("grün: berechnet", 100, y)
    gc:setColorRGB(120, 120, 120); gc:drawString("Pfeile: Zelle   Enter: ändern", 180, y)

    y = y + 12
    gc:setFont("sansserif", "b", 9)
    if widerspruch then
        gc:setColorRGB(200, 0, 0); gc:drawString("Eingaben widersprechen sich — [s] und [k] gesperrt", 4, y)
    elseif loesung then
        setFarbe(gc, FARBE_BER); gc:drawString("eindeutig bestimmt — [s] Scheibe   [k] Kreis", 4, y)
    else
        gc:setColorRGB(180, 100, 0)
        gc:drawString("noch " .. (3 - rang) .. " unabhängige Angabe(n) nötig — [s] und [k] gesperrt", 4, y)
    end

    -- Ergebnisse, weiter unten mit mehr Luft
    y = y + 20
    if loesung then
        local L = loesung
        gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "b", 10)
        gc:drawString("Spannungszustand", 4, y)
        gc:setFont("sansserif", "r", 10)
        local zeilen = {
            "σ₁ = " .. fmt(L.sig1) .. "      σ₂ = " .. fmt(L.sig2),
            "σm = " .. fmt(L.sig_m) .. "      R = τmax = " .. fmt(L.r),
            "Hauptrichtung α₁ = " .. fmt(L.a1) .. "°      τmax bei " .. fmt(L.a1 + 45) .. "°",
            "σx = " .. fmt(L.sx) .. "      σy = " .. fmt(L.sy) .. "      τxy = " .. fmt(L.txy),
        }
        local dy = math.max(14, math.min(18, (H - 14 - (y + 16)) / #zeilen))
        for i, z in ipairs(zeilen) do gc:drawString(z, 6, y + 4 + i * dy) end
    end
    for _, sch in ipairs(schnitte) do
        if sch.hinweis then
            gc:setColorRGB(180, 100, 0); gc:setFont("sansserif", "r", 7)
            gc:drawString(sch.hinweis, 4, H - 22)
            break
        end
    end
    if meldung then
        gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "r", 8)
        gc:drawString(meldung, 4, H - 12)
    end
end

-- ===================== Spannungsscheibe =====================

-- Haelfte abschneiden: behalte n.x <= d
local function schneide(poly, nx, ny, d)
    local out, n = {}, #poly
    for i = 1, n do
        local p, q = poly[i], poly[(i % n) + 1]
        local dp = nx * p[1] + ny * p[2] - d
        local dq = nx * q[1] + ny * q[2] - d
        if dp <= 1e-9 then out[#out + 1] = p end
        if (dp > 1e-9 and dq < -1e-9) or (dp < -1e-9 and dq > 1e-9) then
            local tt = dp / (dp - dq)
            out[#out + 1] = { p[1] + tt * (q[1] - p[1]), p[2] + tt * (q[2] - p[2]) }
        end
    end
    return out
end

-- Vieleck, dessen Kanten die Schnitte sind: Schnitt aller Halbebenen n_i.x <= r.
-- Decken die Normalen nicht den ganzen Kreis ab, kommen die Gegenseiten dazu, damit die
-- Scheibe geschlossen ist (zwei senkrechte Schnitte ergeben so das uebliche Rechteck).
local function scheibenPolygon(r)
    local ebenen = {}
    for i, sch in ipairs(schnitte) do
        if sch.a and not leererSchnitt(sch) then
            local a = bogen(sch.a)
            ebenen[#ebenen + 1] = { nx = math.cos(a), ny = math.sin(a), i = i, seite = 1 }
        end
    end
    if #ebenen == 0 then return nil, nil end
    local function baue(liste)
        local poly = { { -6 * r, -6 * r }, { 6 * r, -6 * r }, { 6 * r, 6 * r }, { -6 * r, 6 * r } }
        for _, e in ipairs(liste) do poly = schneide(poly, e.nx, e.ny, r) end
        return poly
    end
    local liste = {}
    for _, e in ipairs(ebenen) do liste[#liste + 1] = e end
    local poly = baue(liste)
    local weit = false
    for _, p in ipairs(poly) do
        if math.sqrt(p[1] ^ 2 + p[2] ^ 2) > 2.5 * r then weit = true end
    end
    if weit then
        for _, e in ipairs(ebenen) do
            liste[#liste + 1] = { nx = -e.nx, ny = -e.ny, i = e.i, seite = -1 }
        end
        poly = baue(liste)
    end
    return poly, liste
end

local function zeichneScheibe(gc)
    kopf(gc, "Spannungsscheibe", "[t] Tabelle  [k] Kreis")
    if not bereit() then
        gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "b", 10)
        gc:drawString("Spannungszustand nicht eindeutig bestimmt", 10, 40)
        return
    end
    local cx, cy = W / 2, (H + 18) / 2 + 4
    local r = math.min(W, H - 18) * 0.17
    local poly, ebenen = scheibenPolygon(r)
    if not poly or #poly < 3 then
        gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "r", 9)
        gc:drawString("Zu wenige Schnitte fuer eine Scheibe", 10, 40)
        return
    end
    local function sx(p) return cx + p[1] end
    local function sy(p) return cy - p[2] end

    -- Skalierung der Pfeile
    local gross = 0
    for _, sch in ipairs(schnitte) do
        gross = math.max(gross, math.abs(sch.s or 0), math.abs(sch.t or 0))
    end
    if gross < 1e-9 then gross = 1 end
    local pmax = r * 0.85

    -- Flaeche
    local pts = {}
    for _, p in ipairs(poly) do pts[#pts + 1] = sx(p); pts[#pts + 1] = sy(p) end
    gc:setColorRGB(235, 235, 235); gc:fillPolygon(pts)
    gc:setColorRGB(0, 0, 0); gc:setPen("thin", "smooth")
    for i = 1, #poly do
        local p, q = poly[i], poly[(i % #poly) + 1]
        gc:drawLine(sx(p), sy(p), sx(q), sy(q))
    end
    -- Achsenkreuz
    gc:setColorRGB(0, 150, 0)
    gc:drawLine(cx, cy, cx + 22, cy); gc:drawLine(cx, cy, cx, cy - 22)
    gc:setFont("sansserif", "r", 8)
    gc:drawString("x", cx + 24, cy - 6); gc:drawString("y", cx - 4, cy - 36)

    -- je Kante die Spannungen
    gc:setFont("sansserif", "r", 7)
    for i = 1, #poly do
        local p, q = poly[i], poly[(i % #poly) + 1]
        local mx, my = (p[1] + q[1]) / 2, (p[2] + q[2]) / 2
        local zu = nil
        for _, e in ipairs(ebenen or {}) do
            if math.abs(e.nx * mx + e.ny * my - r) < 1e-6 * math.max(1, r) then zu = e; break end
        end
        if zu then
            local sch = schnitte[zu.i]
            local nx, ny = zu.nx, zu.ny                    -- aeussere Normale der Kante
            local tx, ty = -ny, nx                          -- Tangente (Normale um +90 Grad)
            local vz = zu.seite                             -- Rueckseite: Spannungen zeigen anders
            local px, py = sx({ mx, my }), sy({ mx, my })
            -- Normalspannung laengs der Normalen (Zug nach aussen, Druck auf die Kante zu)
            local ls = (sch.s or 0) / gross * pmax * vz
            if math.abs(ls) < 8 then ls = (ls >= 0 and 8 or -8) end
            setFarbe(gc, FARBE_SIGMA)
            if (sch.s or 0) * vz >= 0 then
                pfeil(gc, px, py, px + nx * ls, py - ny * ls)
            else
                pfeil(gc, px - nx * ls, py + ny * ls, px, py)
            end
            -- Schubspannung laengs der Kante
            local lt = (sch.t or 0) / gross * pmax * 0.8 * vz
            if math.abs(lt) < 8 and math.abs(sch.t or 0) > 1e-9 then lt = (lt >= 0 and 8 or -8) end
            setFarbe(gc, FARBE_TAU)
            if math.abs(sch.t or 0) > 1e-9 then
                pfeil(gc, px, py, px + tx * lt, py - ty * lt)
            end
            -- Beschriftung nach aussen
            local bx, by = px + nx * (pmax * 0.55 + 16), py - ny * (pmax * 0.55 + 16)
            bx = math.max(24, math.min(W - 24, bx))
            by = math.max(26, math.min(H - 18, by))
            gc:setFont("sansserif", "b", 7); gc:setColorRGB(0, 0, 0)
            zentriert(gc, "S" .. zu.i .. " (" .. fmt(sch.a, 1) .. "°)" .. (vz < 0 and " R" or ""), bx, by - 16)
            gc:setFont("sansserif", "r", 7)
            setFarbe(gc, FARBE_SIGMA); zentriert(gc, "σ=" .. fmt(sch.s, 1), bx, by - 7)
            setFarbe(gc, FARBE_TAU); zentriert(gc, "τ=" .. fmt(sch.t, 1), bx, by + 2)
        end
    end
    gc:setFont("sansserif", "r", 7); gc:setColorRGB(60, 60, 60)
    gc:drawString("rot: σ   blau: τ   R = Rückseite desselben Schnitts", 4, H - 10)
end

-- ===================== Mohrscher Kreis =====================

local function zeichneKreis(gc)
    kopf(gc, "Mohrscher Spannungskreis", "[t] Tabelle  [s] Scheibe")
    if not bereit() then
        gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "b", 10)
        gc:drawString("Spannungszustand nicht eindeutig bestimmt", 10, 40)
        return
    end
    local L = loesung
    local cy = (H + 18) / 2
    local rand = 28
    local spanne = math.max(L.r * 1.3, 1e-6)
    local sk = math.min((W - 2 * rand) / (2 * spanne), (H - 18 - 2 * rand) / (2 * spanne))
    local function px(sig) return W / 2 + (sig - L.sig_m) * sk end
    local function py(tau) return cy - tau * sk end

    gc:setColorRGB(150, 150, 150); gc:setPen("thin", "smooth")
    gc:drawLine(8, cy, W - 8, cy)
    gc:drawLine(px(L.sig_m), 22, px(L.sig_m), H - 6)
    gc:setFont("sansserif", "r", 8); gc:setColorRGB(120, 120, 120)
    gc:drawString("σ", W - 14, cy - 12)
    gc:drawString("τ", px(L.sig_m) + 4, 22)

    local rp = L.r * sk
    gc:setColorRGB(0, 0, 0); gc:setPen("medium", "smooth")
    gc:drawArc(px(L.sig_m) - rp, cy - rp, 2 * rp, 2 * rp, 0, 360)
    gc:setPen("thin", "smooth")

    setFarbe(gc, FARBE_SIGMA)
    gc:setFont("sansserif", "b", 8)
    for _, p in ipairs({ { L.sig1, "σ₁" }, { L.sig2, "σ₂" } }) do
        local x = px(p[1])
        gc:fillArc(x - 3, cy - 3, 6, 6, 0, 360)
        gc:drawString(p[2] .. "=" .. fmt(p[1], 1), x - 18, cy + 6)
    end
    gc:setColorRGB(120, 120, 120); gc:setFont("sansserif", "r", 8)
    gc:drawString("M=" .. fmt(L.sig_m, 1), px(L.sig_m) + 4, cy + 6)

    for i, sch in ipairs(schnitte) do
        if sch.s and sch.t and not leererSchnitt(sch) then
            local x, y = px(sch.s), py(sch.t)
            setFarbe(gc, FARBE_TAU)
            gc:drawLine(px(L.sig_m), cy, x, y)
            gc:fillArc(x - 3, y - 3, 6, 6, 0, 360)
            gc:setFont("sansserif", "b", 8); gc:setColorRGB(0, 0, 0)
            gc:drawString("S" .. i, x + ((x >= px(L.sig_m)) and 6 or -26), y + ((y <= cy) and -12 or 4))
        end
    end
    gc:setFont("sansserif", "r", 7); gc:setColorRGB(60, 60, 60)
    gc:drawString("Drehung im Kreis: 2α (bei wachsendem α im Uhrzeigersinn)", 4, H - 10)
end

-- ===================== Zeichnen =====================

function on.paint(gc)
    W = platform.window:width(); H = platform.window:height()
    if modus == "scheibe" then zeichneScheibe(gc)
    elseif modus == "kreis" then zeichneKreis(gc)
    else zeichneTabelle(gc) end

    if loeschFrage then
        local bw, bh = math.min(W - 20, 250), 46
        local bx, by = math.floor((W - bw) / 2), math.floor((H - bh) / 2)
        gc:setColorRGB(255, 165, 0); gc:fillRect(bx, by, bw, bh)
        gc:setColorRGB(0, 0, 0); gc:setPen("thin", "smooth"); gc:drawRect(bx, by, bw, bh)
        gc:setFont("sansserif", "b", 10); gc:drawString("Wirklich neu anfangen?", bx + 8, by + 6)
        gc:setFont("sansserif", "r", 9); gc:drawString("[Enter] alles löschen   [Esc] abbrechen", bx + 8, by + 26)
    end
end

-- ===================== Bedienung =====================

local function sorgeFuerSpalte()
    while #schnitte < spalte do schnitte[#schnitte + 1] = neuerSchnitt() end
end

local function beendeEingabe(uebernehmen)
    if not editiere then return true end
    if uebernehmen then
        local v, ok = wertVon(text)
        if not ok then meldung = "nicht auswertbar: " .. text; return false end
        meldung = nil
        sorgeFuerSpalte()
        setzeZelle(schnitte[spalte], zeile, v)
        rechne()
    end
    editiere, text = false, ""
    return true
end

local function starteEingabe(vorbelegt)
    sorgeFuerSpalte()
    local v = select(1, zelle(schnitte[spalte], zeile))
    editiere = true
    text = vorbelegt or ((v ~= nil) and fmt(v) or "")
end

local function gehe(dx, dy)
    if not beendeEingabe(true) then return end
    spalte = math.max(1, math.min(#schnitte + 1, spalte + dx))
    zeile = math.max(1, math.min(3, zeile + dy))
    haltePosition()
end

function on.charIn(c)
    if loeschFrage then return end
    if editiere then
        text = text .. c
        platform.window:invalidate()
        return
    end
    if c == "b" or c == "B" then
        rechne()
        if #schnitte > 1 and leererSchnitt(schnitte[#schnitte]) then
            table.remove(schnitte)
            if spalte > #schnitte + 1 then spalte = #schnitte + 1 end
            rechne()
        end
        modus = "tabelle"
        meldung = nil
    elseif c == "t" or c == "T" or c == "e" or c == "E" then
        modus = "tabelle"
    elseif c == "s" or c == "S" then
        if bereit() then modus = "scheibe" else meldung = "Scheibe erst, wenn der Zustand eindeutig ist" end
    elseif c == "k" or c == "K" then
        if bereit() then modus = "kreis" else meldung = "Kreis erst, wenn der Zustand eindeutig ist" end
    elseif modus == "tabelle" and c:match("^[%d%.%,%-%+%(]$") then
        starteEingabe(c)
    end
    platform.window:invalidate()
end

function on.enterKey()
    if loeschFrage then allesLoeschen(); platform.window:invalidate(); return end
    if modus ~= "tabelle" then modus = "tabelle"; platform.window:invalidate(); return end
    if editiere then
        if beendeEingabe(true) then
            -- weiter zur naechsten Zelle: α -> σ -> τ -> naechster Schnitt
            if zeile < 3 then zeile = zeile + 1
            else zeile = 1; spalte = math.min(#schnitte + 1, spalte + 1) end
            haltePosition()
        end
    else
        starteEingabe(nil)
    end
    platform.window:invalidate()
end

function on.backspaceKey()
    if loeschFrage then return end
    if editiere then
        text = text:sub(1, -2)
    elseif modus == "tabelle" and schnitte[spalte] then
        setzeZelle(schnitte[spalte], zeile, nil)
        rechne()
    end
    platform.window:invalidate()
end

function on.arrowKey(k)
    if loeschFrage then return end
    if modus ~= "tabelle" then
        if k == "left" or k == "right" then modus = "tabelle" end
        platform.window:invalidate(); return
    end
    if k == "left" then gehe(-1, 0)
    elseif k == "right" then gehe(1, 0)
    elseif k == "up" then gehe(0, -1)
    elseif k == "down" then gehe(0, 1) end
    platform.window:invalidate()
end

function on.deleteKey()
    if loeschFrage then return end
    if editiere then text = ""; platform.window:invalidate(); return end
    loeschFrage = true
    platform.window:invalidate()
end

function on.clearKey() on.deleteKey() end

function on.escapeKey()
    if loeschFrage then loeschFrage = false
    elseif editiere then editiere, text = false, ""
    elseif modus ~= "tabelle" then modus = "tabelle"
    else meldung = nil end
    platform.window:invalidate()
end

allesLoeschen()
