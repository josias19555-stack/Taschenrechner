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
--   Ein Schnitt OHNE Winkel, aber mit σ und τ ist ein Punkt auf dem Kreis:
--      (σ - σm)^2 + τ^2 = Rc^2 + Rs^2          (eine Gleichung, der Winkel ist die zweite Unbekannte)
--   Die Differenz zweier solcher Gleichungen ist linear in σm, es bleibt hoechstens eine
--   quadratische. Hat das lineare System Rang 2, ist sie eine Gleichung zweiten Grades im freien
--   Parameter: eine Loesung (auch wenn der quadratische Anteil wegfaellt) oder zwei. Zwei Loesungen
--   heissen: der Zustand ist nicht eindeutig -- dann wird nichts gezeichnet, beide werden gezeigt.
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
local kreisWinkel = nil      -- Marke im Kreisbild (Winkel in Grad), mit den Pfeilen bewegt
local scheibenPfeile = {}    -- zuletzt gezeichnete Pfeile je Kante (fuer die Pruefung der Richtungen)
local loesung = nil
local rang = 0
local widerspruch = false
local mehrdeutig = nil       -- zwei moegliche Zustaende (Kreispunkt, quadratische Gleichung)

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
    sch.wahl = nil      -- neue Eingabe am Schnitt: gewaehlte Winkelloesung gilt nicht mehr
    if z == 1 then sch.a, sch.a_in = v, (v ~= nil)
    elseif z == 2 then sch.s, sch.s_in = v, (v ~= nil)
    else sch.t, sch.t_in = v, (v ~= nil) end
end
local function leererSchnitt(sch)
    return not sch.a_in and not sch.s_in and not sch.t_in
end

-- ===================== Rechnung =====================

-- Punkte auf dem Kreis: Schnitte ohne Winkel mit σ und τ
local function kreispunkte()
    local P = {}
    for _, sch in ipairs(schnitte) do
        if not (sch.a_in and sch.a) and sch.s_in and sch.t_in and sch.s and sch.t then
            P[#P + 1] = { s = sch.s, t = sch.t }
        end
    end
    return P
end

-- Lineare Gleichungen in (σm, Rc, Rs): Schnitte mit Winkel, dazu die Differenzen der Kreispunkte
-- zum ersten Punkt (die quadratischen Anteile heben sich weg, uebrig bleibt eine Gleichung in σm)
local function gleichungen(P)
    local A, b = {}, {}
    for _, sch in ipairs(schnitte) do
        if sch.a_in and sch.a then
            local z = 2 * bogen(sch.a)
            if sch.s_in and sch.s then A[#A + 1] = { 1, math.cos(z), math.sin(z) }; b[#b + 1] = sch.s end
            if sch.t_in and sch.t then A[#A + 1] = { 0, -math.sin(z), math.cos(z) }; b[#b + 1] = sch.t end
        end
    end
    for k = 2, #(P or {}) do
        local p1, pk = P[1], P[k]
        local f = math.max(1, math.abs(p1.s), math.abs(pk.s), math.abs(p1.t), math.abs(pk.t))
        A[#A + 1] = { 2 * (pk.s - p1.s) / f, 0, 0 }
        b[#b + 1] = (pk.s ^ 2 + pk.t ^ 2 - p1.s ^ 2 - p1.t ^ 2) / f
    end
    return A, b
end

-- Gauss-Jordan mit Rangkontrolle. Rueckgabe: { rang, wider, x (Rang 3) oder x0 + t*d (Rang 2) }
local function loeseLGS(A, b)
    local n = #A
    if n == 0 then return { rang = 0, wider = false } end
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
                    for c = 1, 4 do M[r][c] = M[r][c] - f * M[zn][c] end
                end
            end
            pivot[sp] = zn
            zn = zn + 1
        end
    end
    local r_ang = zn - 1
    local wider = false
    for r = r_ang + 1, n do if math.abs(M[r][4]) > 1e-6 * skala then wider = true end end
    local erg = { rang = r_ang, wider = wider }
    if r_ang == 3 then
        erg.x = {}
        for sp = 1, 3 do local z = pivot[sp]; erg.x[sp] = M[z][4] / M[z][sp] end
    elseif r_ang == 2 then
        -- eine freie Spalte: Loesungsgerade x0 + t*d, d auf Laenge 1 gebracht
        local frei
        for sp = 1, 3 do if not pivot[sp] then frei = sp end end
        local x0, d = { 0, 0, 0 }, { 0, 0, 0 }
        d[frei] = 1
        for sp = 1, 3 do
            local z = pivot[sp]
            if z then
                x0[sp] = M[z][4] / M[z][sp]
                d[sp] = -M[z][frei] / M[z][sp]
            end
        end
        local l = math.sqrt(d[1] ^ 2 + d[2] ^ 2 + d[3] ^ 2)
        for i = 1, 3 do d[i] = d[i] / l end
        erg.x0, erg.d = x0, d
    end
    return erg
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

-- Kennwerte eines Zustands aus (σm, Rc, Rs)
local function baueLoesung(x)
    local L = { sig_m = x[1], rc = x[2], rs = x[3] }
    L.r = math.sqrt(L.rc * L.rc + L.rs * L.rs)
    L.phi = math.atan2(L.rs, L.rc)
    L.sig1, L.sig2, L.tau_max = L.sig_m + L.r, L.sig_m - L.r, L.r
    L.a1 = grad(L.phi / 2)
    while L.a1 < 0 do L.a1 = L.a1 + 180 end
    while L.a1 >= 180 do L.a1 = L.a1 - 180 end
    L.sx, L.sy, L.txy = L.sig_m + L.rc, L.sig_m - L.rc, L.rs
    return L
end

local function rechne()
    loesung, widerspruch, mehrdeutig = nil, false, nil
    for _, sch in ipairs(schnitte) do
        sch.hinweis, sch.a2 = nil, nil
        if not sch.a_in then sch.a = nil end
        if not sch.s_in then sch.s = nil end
        if not sch.t_in then sch.t = nil end
    end
    local P = kreispunkte()
    local A, b = gleichungen(P)
    local lg = loeseLGS(A, b)
    rang, widerspruch = lg.rang, lg.wider and true or false

    -- Groessenordnung der Eingaben fuer die Toleranzen
    local skala = 1
    for _, sch in ipairs(schnitte) do
        skala = math.max(skala, math.abs(sch.s_in and sch.s or 0), math.abs(sch.t_in and sch.t or 0))
    end

    local kandidaten = {}
    if #P == 0 then
        if lg.x then kandidaten = { lg.x } end
    else
        -- verbleibende quadratische Gleichung des ersten Kreispunkts
        local p = P[1]
        local function g(x) return (p.s - x[1]) ^ 2 + p.t ^ 2 - x[2] ^ 2 - x[3] ^ 2 end
        if lg.x then
            rang = 3
            if math.abs(g(lg.x)) > 1e-7 * skala ^ 2 then widerspruch = true end
            kandidaten = { lg.x }
        elseif lg.d then
            -- g(x0 + t d) = qa t^2 + qb t + qc
            local x0, d = lg.x0, lg.d
            local e = p.s - x0[1]
            local qa = d[1] ^ 2 - d[2] ^ 2 - d[3] ^ 2
            local qb = -2 * e * d[1] - 2 * x0[2] * d[2] - 2 * x0[3] * d[3]
            local qc = e ^ 2 + p.t ^ 2 - x0[2] ^ 2 - x0[3] ^ 2
            local function punkt(t) return { x0[1] + t * d[1], x0[2] + t * d[2], x0[3] + t * d[3] } end
            if math.abs(qa) <= 1e-9 then
                -- quadratischer Anteil faellt weg (z. B. Hauptrichtung und ein σ bekannt): eine Loesung
                if math.abs(qb) > 1e-9 * skala then
                    rang = 3
                    kandidaten = { punkt(-qc / qb) }
                elseif math.abs(qc) > 1e-7 * skala ^ 2 then
                    rang, widerspruch = 3, true
                end
            else
                rang = 3
                local disk = qb * qb - 4 * qa * qc
                local tol = 1e-9 * (qb * qb + math.abs(4 * qa * qc)) + 1e-12 * skala ^ 2
                if disk < -tol then
                    widerspruch = true
                elseif disk <= tol then
                    kandidaten = { punkt(-qb / (2 * qa)) }
                else
                    local w = math.sqrt(disk)
                    kandidaten = { punkt((-qb + w) / (2 * qa)), punkt((-qb - w) / (2 * qa)) }
                end
            end
        else
            rang = math.min(2, lg.rang + 1)     -- der Kreispunkt zaehlt als eine Angabe
        end
    end

    -- Schnitte ohne Winkel mit nur σ oder nur τ geben Ungleichungen: der Wert muss auf den Kreis
    -- passen. Damit laesst sich einer von zwei moeglichen Zustaenden ausschliessen.
    if #kandidaten == 2 then
        local passend = {}
        for _, x in ipairs(kandidaten) do
            local R = math.sqrt(x[2] ^ 2 + x[3] ^ 2)
            local ok = true
            for _, sch in ipairs(schnitte) do
                if not (sch.a_in and sch.a) then
                    local tol = 1e-9 * skala
                    if sch.s_in and sch.s and not sch.t_in and math.abs(sch.s - x[1]) > R + tol then ok = false end
                    if sch.t_in and sch.t and not sch.s_in and math.abs(sch.t) > R + tol then ok = false end
                end
            end
            if ok then passend[#passend + 1] = x end
        end
        if #passend == 0 then widerspruch = true end
        kandidaten = passend
        -- praktisch gleiche Loesungen zusammenfassen
        if #kandidaten == 2 then
            local a, c = kandidaten[1], kandidaten[2]
            if math.abs(a[1] - c[1]) + math.abs(a[2] - c[2]) + math.abs(a[3] - c[3]) <= 1e-9 * skala then
                kandidaten = { a }
            end
        end
    end
    if #kandidaten == 2 then
        mehrdeutig = { baueLoesung(kandidaten[1]), baueLoesung(kandidaten[2]) }
        return false
    end
    if #kandidaten == 0 then return false end

    local L = baueLoesung(kandidaten[1])
    loesung = L
    for _, sch in ipairs(schnitte) do
        if sch.a_in and sch.a then
            local s, t = spannungen(sch.a, L)
            if not sch.s_in then sch.s = s end
            if not sch.t_in then sch.t = t end
        elseif not leererSchnitt(sch) then
            local a, a2, warum = winkelAus(sch, L)
            if a then
                -- zwei Loesungen: mit Tab gewaehlte zweite Loesung vorne, die andere klein dahinter
                if a2 and sch.wahl == 2 then a, a2 = a2, a end
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
    loeschFrage, kreisWinkel, mehrdeutig = false, nil, nil
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

local SP_BREIT, SP_X0 = 50, 52

local function sichtbareSpalten()
    return math.max(1, math.floor((W - SP_X0 - 4) / SP_BREIT))
end

local function haltePosition()
    local sicht = sichtbareSpalten()
    if spalte < scroll + 1 then scroll = spalte - 1 end
    if spalte > scroll + sicht then scroll = spalte - sicht end
    if scroll < 0 then scroll = 0 end
end

-- erste Variante, die in die Breite passt (sonst die kuerzeste)
local function passend(gc, kandidaten, breite)
    for _, s in ipairs(kandidaten) do
        if gc:getStringWidth(s) <= breite then return s end
    end
    return kandidaten[#kandidaten]
end

-- groesste gueltige Schriftgroesse, mit der der Text in die Breite passt
local SCHRIFTGROESSEN = { 6, 7, 8, 9, 10, 11, 12 }

local function passendeSchrift(gc, s, breite, stil, groesse)
    local gewaehlt = SCHRIFTGROESSEN[1]
    for _, g in ipairs(SCHRIFTGROESSEN) do
        if g <= groesse then
            gc:setFont("sansserif", stil, g)
            if gc:getStringWidth(s) <= breite then gewaehlt = g end
        end
    end
    gc:setFont("sansserif", stil, gewaehlt)
    return gewaehlt
end

-- Hoehe einer Textzeile; drawString setzt y auf die Oberkante
local function texthoehe(gc)
    local ok, h = pcall(function() return gc:getStringHeight("Ag") end)
    if ok and type(h) == "number" and h > 4 then return h end
    return 13
end

local function zeichneTabelle(gc)
    kopf(gc, "Spannungszustand über Schnitte", "[b] rechnen")
    gc:setColorRGB(60, 60, 60); gc:setFont("sansserif", "r", 7)
    gc:drawString(passend(gc, {
        "α: Winkel der Schnittnormalen zur x-Achse, mathematisch positiv (gegen den Uhrzeigersinn)",
        "α: Winkel der Schnittnormalen zur x-Achse, math. positiv (gegen den Uhrzeigersinn)",
        "α: Winkel der Schnittnormalen zur x-Achse, math. positiv (gegen UZS)",
        "α: Winkel der Schnittnormalen zur x-Achse, math. positiv",
        "α: Schnittnormale zur x-Achse, math. positiv",
    }, W - 8), 4, 20)

    haltePosition()
    local y0, zh = 33, 16
    gc:setFont("sansserif", "r", 9)
    local th = texthoehe(gc)
    local sicht = sichtbareSpalten()
    -- Kopfzeile
    gc:setColorRGB(0, 0, 0)
    passendeSchrift(gc, "Schnitt", SP_X0 - 8, "b", 9)
    gc:drawString("Schnitt", 4, y0)
    gc:setFont("sansserif", "b", 9)
    for i = scroll + 1, math.min(#schnitte + 1, scroll + sicht) do
        local x = SP_X0 + (i - scroll - 1) * SP_BREIT
        if i <= #schnitte then gc:drawString("S" .. i, x, y0)
        else gc:setColorRGB(150, 150, 150); gc:drawString("neu", x, y0); gc:setColorRGB(0, 0, 0) end
    end
    -- Zeilen
    for z = 1, 3 do
        local y = y0 + z * zh
        gc:setColorRGB(0, 0, 0)
        passendeSchrift(gc, ZEILENNAME[z], SP_X0 - 8, "b", 9)
        gc:drawString(ZEILENNAME[z], 4, y)
        gc:setFont("sansserif", "r", 9)
        for i = scroll + 1, math.min(#schnitte + 1, scroll + sicht) do
            local x = SP_X0 + (i - scroll - 1) * SP_BREIT
            local sch = schnitte[i]
            local aktiv = (i == spalte and z == zeile)
            if aktiv then
                gc:setColorRGB(200, 220, 255); gc:fillRect(x - 4, y, SP_BREIT - 4, th)
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
                    gc:drawString("|" .. fmt(sch.a2, 1), x + 26, y + 3)
                    gc:setFont("sansserif", "r", 9)
                end
            end
        end
    end
    local trenn = y0 + 3 * zh + th + 2
    gc:setColorRGB(170, 170, 170)
    gc:drawLine(0, trenn, W, trenn)

    -- Legende und Status
    local y = trenn + 3
    gc:setFont("sansserif", "r", 7)
    local x = 4
    setFarbe(gc, FARBE_EIN); gc:drawString("schwarz: eingegeben", x, y)
    x = x + gc:getStringWidth("schwarz: eingegeben") + 10
    setFarbe(gc, FARBE_BER); gc:drawString("grün: berechnet", x, y)
    x = x + gc:getStringWidth("grün: berechnet") + 10
    local hilfe = "Pfeile: Zelle   Enter: ändern"
    local cur = schnitte[spalte]
    if zeile == 1 and cur and cur.a2 and not cur.a_in then hilfe = "Tab: andere Lösung" end
    if x + gc:getStringWidth(hilfe) > W - 4 then hilfe = "Enter: ändern" end
    if x + gc:getStringWidth(hilfe) <= W - 4 then
        gc:setColorRGB(120, 120, 120); gc:drawString(hilfe, x, y)
    end

    y = y + 14
    gc:setFont("sansserif", "b", 9)
    if widerspruch then
        gc:setColorRGB(200, 0, 0)
        gc:drawString(passend(gc, {
            "Eingaben widersprechen sich — [s] und [k] gesperrt",
            "Eingaben widersprechen sich — [s]/[k] gesperrt",
            "Eingaben widersprechen sich",
        }, W - 8), 4, y)
    elseif mehrdeutig then
        gc:setColorRGB(180, 100, 0)
        gc:drawString(passend(gc, {
            "zwei Zustände möglich — noch 1 Angabe zum Unterscheiden",
            "zwei Zustände möglich — 1 Angabe mehr nötig",
            "zwei Zustände möglich",
        }, W - 8), 4, y)
    elseif loesung then
        setFarbe(gc, FARBE_BER)
        gc:drawString(passend(gc, {
            "eindeutig bestimmt — [s] Scheibe   [k] Kreis",
            "eindeutig bestimmt — [s] Scheibe  [k] Kreis",
            "eindeutig bestimmt — [s] / [k]",
        }, W - 8), 4, y)
    else
        local n = 3 - rang
        gc:setColorRGB(180, 100, 0)
        gc:drawString(passend(gc, {
            "noch " .. n .. " unabhängige Angabe(n) nötig — [s] und [k] gesperrt",
            "noch " .. n .. " unabhängige Angabe(n) nötig — [s]/[k] gesperrt",
            "noch " .. n .. " Angabe(n) nötig — [s]/[k] gesperrt",
            "noch " .. n .. " Angabe(n) nötig",
        }, W - 8), 4, y)
    end

    -- Fusszeilen zuerst festlegen, damit die Ergebnisse den Rest bekommen
    local hinweis = nil
    for _, sch in ipairs(schnitte) do
        if sch.hinweis then hinweis = sch.hinweis break end
    end
    local unten = H - 6
    if hinweis or meldung then unten = unten - 12 end
    if hinweis and meldung then unten = unten - 10 end

    -- Ergebnisse: mit Luft zur Statuszeile, danach gleichmaessig bis unten verteilt
    y = y + 24
    if loesung then
        local L = loesung
        gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "b", 10)
        gc:drawString("Spannungszustand", 4, y)
        gc:setFont("sansserif", "r", 10)
        local zeilen = {
            { "σ₁ = " .. fmt(L.sig1) .. "      σ₂ = " .. fmt(L.sig2),
              "σ₁ = " .. fmt(L.sig1) .. "   σ₂ = " .. fmt(L.sig2) },
            { "σm = " .. fmt(L.sig_m) .. "      R = τmax = " .. fmt(L.r),
              "σm = " .. fmt(L.sig_m) .. "   R = τmax = " .. fmt(L.r) },
            { "Hauptrichtung α₁ = " .. fmt(L.a1) .. "°      τmax bei " .. fmt(L.a1 + 45) .. "°",
              "α₁ = " .. fmt(L.a1) .. "°   τmax bei " .. fmt(L.a1 + 45) .. "°" },
            { "σx = " .. fmt(L.sx) .. "      σy = " .. fmt(L.sy) .. "      τxy = " .. fmt(L.txy),
              "σx = " .. fmt(L.sx) .. "   σy = " .. fmt(L.sy) .. "   τxy = " .. fmt(L.txy) },
        }
        local dy = math.max(13, math.min(18, (unten - (y + th)) / #zeilen))
        for i, z in ipairs(zeilen) do
            gc:setFont("sansserif", "r", 10)
            local s = passend(gc, z, W - 12)
            passendeSchrift(gc, s, W - 12, "r", 10)
            gc:drawString(s, 6, y + 2 + i * dy)
        end
    end
    if mehrdeutig and not loesung then
        gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "b", 10)
        gc:drawString("Zwei mögliche Zustände  ([s]/[k] gesperrt)", 4, y)
        local zeilen = {}
        for i, M in ipairs(mehrdeutig) do
            zeilen[#zeilen + 1] = {
                i .. ":  σ₁ = " .. fmt(M.sig1) .. "   σ₂ = " .. fmt(M.sig2) .. "   α₁ = " .. fmt(M.a1, 1) .. "°",
                i .. ": σ₁=" .. fmt(M.sig1) .. " σ₂=" .. fmt(M.sig2) .. " α₁=" .. fmt(M.a1, 1) .. "°" }
            zeilen[#zeilen + 1] = {
                "    σx = " .. fmt(M.sx) .. "   σy = " .. fmt(M.sy) .. "   τxy = " .. fmt(M.txy),
                "   σx=" .. fmt(M.sx) .. " σy=" .. fmt(M.sy) .. " τxy=" .. fmt(M.txy) }
        end
        local dy = math.max(13, math.min(18, (unten - (y + th)) / #zeilen))
        for i, z in ipairs(zeilen) do
            gc:setFont("sansserif", "r", 10)
            local t = passend(gc, z, W - 12)
            passendeSchrift(gc, t, W - 12, "r", 10)
            gc:drawString(t, 6, y + 2 + i * dy)
        end
    end
    if hinweis then
        gc:setColorRGB(180, 100, 0); gc:setFont("sansserif", "r", 7)
        gc:drawString(hinweis, 4, meldung and (H - 22) or (H - 12))
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

-- Vieleck, dessen Kanten die Schnitte sind: Schnitt aller Halbebenen n_i.x <= r (alle Kanten
-- beruehren den Inkreis mit Radius r). Gezeichnet werden nur die eingegebenen Schnitte. Schliessen
-- sie die Scheibe nicht -- zwei benachbarte Normalen liegen SCHEIBE_LUECKE Grad oder weiter
-- auseinander, die Scheibe waere offen oder eine extrem spitze Nadel --, wird der x- bzw.
-- y-Schnitt ergaenzt, und zwar nur die Seite, deren Normale mitten in der groessten Luecke liegt.
local SCHEIBE_LUECKE = 160

local function scheibenPolygon(r)
    local liste, winkel = {}, {}
    local function vorhanden(b)
        for _, w in ipairs(winkel) do
            if math.abs(((b - w) + 180) % 360 - 180) < 1e-6 then return true end
        end
        return false
    end
    local function dazu(b, eintrag)
        b = b % 360
        if vorhanden(b) then return end
        local a = bogen(b)
        eintrag.nx, eintrag.ny, eintrag.beta = math.cos(a), math.sin(a), b
        liste[#liste + 1] = eintrag
        winkel[#winkel + 1] = b
    end
    for i, sch in ipairs(schnitte) do
        if sch.a and not leererSchnitt(sch) then dazu(sch.a, { i = i }) end
    end
    if #liste == 0 then return nil, nil end
    for _ = 1, 4 do
        local w = {}
        for k, v in ipairs(winkel) do w[k] = v end
        table.sort(w)
        local luecke, von, bis = -1, nil, nil
        for k = 1, #w do
            local a, b = w[k], (k < #w) and w[k + 1] or (w[1] + 360)
            if b - a > luecke then luecke, von, bis = b - a, a, b end
        end
        if luecke < SCHEIBE_LUECKE then break end
        local mitte, beste, wahl = von + luecke / 2, math.huge, nil
        for _, b in ipairs({ 0, 90, 180, 270, 360, 450, 540, 630 }) do
            if b > von + 1e-6 and b < bis - 1e-6 and not vorhanden(b % 360) and math.abs(b - mitte) < beste - 1e-9 then
                beste, wahl = math.abs(b - mitte), b
            end
        end
        if not wahl then break end
        local b = wahl % 360
        dazu(b, { achse = (b == 0 or b == 180) and "x" or "y" })
    end
    local g = 50 * r
    local poly = { { -g, -g }, { g, -g }, { g, g }, { -g, g } }
    for _, e in ipairs(liste) do poly = schneide(poly, e.nx, e.ny, r) end
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
    local r = math.min(W, H - 18) * 0.17          -- Pixel je Einheit bei einer gedrungenen Scheibe
    local poly, ebenen = scheibenPolygon(1)       -- Inkreisradius 1, danach auf den Bildschirm skaliert
    if not poly or #poly < 3 then
        gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "r", 9)
        gc:drawString("Zu wenige Schnitte fuer eine Scheibe", 10, 40)
        return
    end
    -- Koordinatensystem wie im Querschnitt: x zeigt nach unten, y nach rechts. Laengliche Vielecke
    -- werden verkleinert, bis sie zwischen die Beschriftungen passen (Breite W-140, Hoehe 2r), und um
    -- die Mitte ihres umschreibenden Rechtecks zentriert.
    local xmin, xmax, ymin, ymax = math.huge, -math.huge, math.huge, -math.huge
    for _, p in ipairs(poly) do
        xmin, xmax = math.min(xmin, p[1]), math.max(xmax, p[1])
        ymin, ymax = math.min(ymin, p[2]), math.max(ymax, p[2])
    end
    local sk = math.min(r, (W - 140) / math.max(ymax - ymin, 1e-9), 2 * r / math.max(xmax - xmin, 1e-9))
    local cx0, cy0 = cx - sk * (ymin + ymax) / 2, cy - sk * (xmin + xmax) / 2
    local function sx(p) return cx0 + p[2] * sk end
    local function sy(p) return cy0 + p[1] * sk end
    local function ziel(px, py, vx, vy, laenge) return px + vy * laenge, py + vx * laenge end

    -- Spannungen je Ebene: eingegebene Schnitte aus der Tabelle, ergaenzte x-/y-Schnitte aus dem Zustand
    local ergaenzt = false
    for _, e in ipairs(ebenen) do
        if e.i then
            e.sig, e.tau = schnitte[e.i].s or 0, schnitte[e.i].t or 0
        else
            e.sig, e.tau = spannungen(e.beta, loesung)
            ergaenzt = true
        end
    end
    -- Skalierung der Pfeile
    local gross = 0
    for _, e in ipairs(ebenen) do gross = math.max(gross, math.abs(e.sig), math.abs(e.tau)) end
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
    gc:drawLine(cx0, cy0, cx0 + 22, cy0); gc:drawLine(cx0, cy0, cx0, cy0 + 22)
    gc:setFont("sansserif", "r", 8)
    gc:drawString("y", cx0 + 24, cy0 - 6); gc:drawString("x", cx0 - 3, cy0 + 22)

    -- je Kante die Spannungen
    gc:setFont("sansserif", "r", 7)
    scheibenPfeile = {}
    for i = 1, #poly do
        local p, q = poly[i], poly[(i % #poly) + 1]
        local mx, my = (p[1] + q[1]) / 2, (p[2] + q[2]) / 2
        local zu = nil
        for _, e in ipairs(ebenen or {}) do
            if math.abs(e.nx * mx + e.ny * my - 1) < 1e-6 then zu = e; break end
        end
        if zu then
            local sch = { s = zu.sig, t = zu.tau }       -- Werte der Kante (Schnitt oder ergaenzte Achse)
            -- Jede Kante zeichnet mit IHRER aeusseren Normalen n und Tangente t (n um +90 Grad).
            -- Die Rueckseite eines Schnitts hat die Normale -n und damit auch die Tangente -t; der
            -- Spannungsvektor dort ist -(σ n + τ t) = σ (-n) + τ (-t). Bezogen auf die eigene Normale
            -- und Tangente hat sie also dieselben Werte σ und τ: Zug zeigt auf beiden Seiten von der
            -- Scheibe weg, τ auf gegenueberliegenden Kanten in entgegengesetzte Richtungen.
            local nx, ny = zu.nx, zu.ny                    -- aeussere Normale der Kante
            local tx, ty = -ny, nx                          -- Tangente (Normale um +90 Grad)
            local px, py = sx({ mx, my }), sy({ mx, my })
            local eintrag = { i = zu.i, achse = zu.achse, beta = zu.beta, px = px, py = py, s = sch.s or 0, t = sch.t or 0 }
            eintrag.nx, eintrag.ny = ziel(0, 0, nx, ny, 1)  -- aeussere Normale auf dem Bildschirm
            -- Normalspannung laengs der Normalen (Zug nach aussen, Druck auf die Kante zu)
            local ls = (sch.s or 0) / gross * pmax
            if math.abs(ls) < 8 then ls = (ls >= 0 and 8 or -8) end
            setFarbe(gc, FARBE_SIGMA)
            if (sch.s or 0) >= 0 then
                local ex, ey = ziel(px, py, nx, ny, ls)
                pfeil(gc, px, py, ex, ey)
                eintrag.sigma = { px, py, ex, ey }
            else
                local ax, ay = ziel(px, py, nx, ny, -ls)
                pfeil(gc, ax, ay, px, py)
                eintrag.sigma = { ax, ay, px, py }
            end
            -- Schubspannung laengs der Kante
            local lt = (sch.t or 0) / gross * pmax * 0.8
            if math.abs(lt) < 8 and math.abs(sch.t or 0) > 1e-9 then lt = (lt >= 0 and 8 or -8) end
            setFarbe(gc, FARBE_TAU)
            if math.abs(sch.t or 0) > 1e-9 then
                local ex, ey = ziel(px, py, tx, ty, lt)
                pfeil(gc, px, py, ex, ey)
                eintrag.tau = { px, py, ex, ey }
            end
            scheibenPfeile[#scheibenPfeile + 1] = eintrag
            -- Beschriftung nach aussen
            local bx, by = ziel(px, py, nx, ny, pmax * 0.55 + 16)
            bx = math.max(24, math.min(W - 24, bx))
            by = math.max(26, math.min(H - 18, by))
            gc:setFont("sansserif", "b", 7); gc:setColorRGB(0, 0, 0)
            local name = zu.i and ("S" .. zu.i .. " (" .. fmt(schnitte[zu.i].a, 1) .. "°)") or (zu.achse .. "-Schnitt")
            zentriert(gc, name, bx, by - 16)
            gc:setFont("sansserif", "r", 7)
            setFarbe(gc, FARBE_SIGMA); zentriert(gc, "σ=" .. fmt(sch.s, 1), bx, by - 7)
            setFarbe(gc, FARBE_TAU); zentriert(gc, "τ=" .. fmt(sch.t, 1), bx, by + 2)
        end
    end
    gc:setFont("sansserif", "r", 7); gc:setColorRGB(60, 60, 60)
    gc:drawString(ergaenzt and "rot: σ   blau: τ   x-/y-Schnitt: ergänzt zum Schließen"
        or "rot: σ   blau: τ", 4, H - 10)
end

-- ===================== Mohrscher Kreis =====================

-- Winkel auf [0, 180) bringen; sigma(α) und tau(α) haben diese Periode
local function normWinkel(a)
    a = (a or 0) % 180
    if a < 0 then a = a + 180 end
    return a
end

-- naechster (richtung > 0) bzw. vorheriger Schnittwinkel, zyklisch um den Kreis
local function schnittWinkel(richtung)
    local liste = {}
    for _, sch in ipairs(schnitte) do
        if sch.a and not leererSchnitt(sch) then liste[#liste + 1] = normWinkel(sch.a) end
    end
    if #liste == 0 then return nil end
    table.sort(liste)
    local a = normWinkel(kreisWinkel or 0)
    if richtung > 0 then
        for _, w in ipairs(liste) do if w > a + 1e-6 then return w end end
        return liste[1]
    end
    for i = #liste, 1, -1 do if liste[i] < a - 1e-6 then return liste[i] end end
    return liste[#liste]
end

-- Winkel des ersten brauchbaren Schnitts (Startpunkt der Marke)
local function ersterWinkel()
    for _, sch in ipairs(schnitte) do
        if sch.a and not leererSchnitt(sch) then return normWinkel(sch.a) end
    end
end

-- Schnitt, der genau auf diesem Winkel liegt (fuer die Beschriftung der Marke)
local function schnittZuWinkel(a)
    for i, sch in ipairs(schnitte) do
        if sch.a and not leererSchnitt(sch) and math.abs(normWinkel(sch.a) - normWinkel(a)) < 1e-6 then
            return i
        end
    end
end

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
    local breite, hoehe = W - 2 * rand, H - 18 - 2 * rand

    -- Zwei Massstaebe: sk_kreis fuellt den Kreis aus, sk_voll zeigt zusaetzlich den Ursprung.
    -- Genommen wird sk_voll, aber nur so weit, dass der Kreis sichtbar gross bleibt.
    local spanne = math.max(L.r * 1.3, 1e-6)
    local sk_kreis = math.min(breite / (2 * spanne), hoehe / (2 * spanne))
    local links = math.min(0, L.sig_m - L.r)
    local rechts = math.max(0, L.sig_m + L.r)
    local sk_voll = math.min(breite / math.max((rechts - links) * 1.3, 1e-6), hoehe / (2 * spanne))
    local rmin = (L.r > 1e-9) and (35 / L.r) or 0
    local sk = math.min(sk_kreis, math.max(sk_voll, math.min(sk_kreis, rmin)))

    -- Bildmitte: moeglichst mittig zwischen Ursprung und Kreis, der Kreis bleibt aber ganz im Bild
    local mitte = (links + rechts) / 2
    local frei = math.max(breite / 2 / sk - L.r, 0)
    if mitte > L.sig_m + frei then mitte = L.sig_m + frei end
    if mitte < L.sig_m - frei then mitte = L.sig_m - frei end

    local function px(sig) return W / 2 + (sig - mitte) * sk end
    local function py(tau) return cy - tau * sk end

    local x0 = px(0)
    local sichtbar0 = x0 > 12 and x0 < W - 12
    gc:setColorRGB(150, 150, 150); gc:setPen("thin", "smooth")
    gc:drawLine(8, cy, W - 8, cy)
    gc:setFont("sansserif", "r", 8)
    if sichtbar0 then
        gc:drawLine(x0, 22, x0, H - 6)
        gc:setColorRGB(120, 120, 120)
        gc:drawString("σ", W - 14, cy - 12)
        gc:drawString("τ", x0 + 4, 22)
        gc:drawString("0", x0 - 8, cy + 4)
    else
        -- Ursprung liegt zu weit weg; der Kreis hat Vorrang, der Nullpunkt wird am Rand vermerkt
        local xr = (x0 <= 12) and 10 or (W - 10)
        gc:setPen("thin", "dotted")
        gc:drawLine(xr, 22, xr, H - 6)
        gc:setPen("thin", "smooth")
        gc:setColorRGB(120, 120, 120)
        gc:drawString("σ", W - 14, cy - 12)
        gc:drawString((x0 <= 12) and "σ=0 ←" or "σ=0 →", (x0 <= 12) and (xr + 4) or (xr - 40), 22)
    end

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
    -- Marke: mit den Pfeiltasten bewegter Punkt auf dem Kreis
    if kreisWinkel then
        local sg, ta = spannungen(kreisWinkel, L)
        local x, y = px(sg), py(ta)
        gc:setColorRGB(220, 120, 0); gc:setPen("medium", "smooth")
        gc:drawLine(px(L.sig_m), cy, x, y)
        gc:fillArc(x - 4, y - 4, 8, 8, 0, 360)
        gc:setPen("thin", "smooth")
        local nr = schnittZuWinkel(kreisWinkel)
        gc:setFont("sansserif", "b", 8)
        gc:drawString((nr and ("S" .. nr .. "  ") or "") .. "α = " .. fmt(kreisWinkel, 1) ..
            "°   σ = " .. fmt(sg) .. "   τ = " .. fmt(ta), 4, H - 21)
    end

    gc:setFont("sansserif", "r", 7); gc:setColorRGB(60, 60, 60)
    gc:drawString(passend(gc, {
        "Drehung im Kreis: 2α   Pfeile: Schnitt wechseln, hoch/runter dreht 5°",
        "2α im Kreis   Pfeile: Schnitt wechseln, hoch/runter 5°",
        "Pfeile: Schnitt wechseln, hoch/runter 5°",
    }, W - 8), 4, H - 10)
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
        if bereit() then
            modus = "kreis"
            if not kreisWinkel then kreisWinkel = ersterWinkel() end
        else meldung = "Kreis erst, wenn der Zustand eindeutig ist" end
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

-- Tab (und Shift+Tab): steht der Cursor auf einem berechneten Winkel mit zwei Loesungen, wird zur
-- anderen gewechselt. Die berechneten σ bzw. τ des Schnitts, Scheibe und Kreis folgen der Wahl.
function on.tabKey()
    if loeschFrage or editiere or modus ~= "tabelle" then return end
    local sch = schnitte[spalte]
    if zeile == 1 and sch and sch.a2 and not sch.a_in then
        sch.wahl = (sch.wahl == 2) and 1 or 2
        rechne()
        meldung = nil
        platform.window:invalidate()
    end
end
function on.backtabKey() on.tabKey() end

function on.arrowKey(k)
    if loeschFrage then return end
    if modus == "kreis" then
        -- links/rechts springt von Schnitt zu Schnitt, hoch/runter dreht in 5-Grad-Schritten
        if k == "left" or k == "right" then
            kreisWinkel = schnittWinkel((k == "right") and 1 or -1) or kreisWinkel or 0
        elseif k == "up" or k == "down" then
            kreisWinkel = normWinkel((kreisWinkel or 0) + ((k == "up") and 5 or -5))
        end
        platform.window:invalidate(); return
    end
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
