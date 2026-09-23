-- Spannungskreis.lua: Rechnung, Tabelle (Eingabe = Ausgabe) und Ansichten.
-- Geprueft wird gegen die Transformationsformeln des ebenen Spannungszustands:
--   sigma(a) = (sx+sy)/2 + (sx-sy)/2*cos(2a) + txy*sin(2a)
--   tau(a)   =          - (sx-sy)/2*sin(2a) + txy*cos(2a)
-- Aufruf: luajit Emulator/tests/spannung.lua [Filter]
local M = {}
io.stdout:setvbuf('no')
local dir = (debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\")
M.verbose = os.getenv('TEST_VERBOSE') ~= nil
M.filter = arg and arg[1]
M.total, M.fails = 0, 0

on = {}
platform = { window = { width = function() return 318 end, height = function() return 212 end,
    invalidate = function() end } }

-- Zeichenstub: merkt sich Texte (mit Breite zur eingestellten Schrift) und Rechtecke.
-- Die Breite je Zeichen ist bewusst etwas grosszuegiger als auf dem Rechner, damit ein
-- Layout, das hier passt, auch dort nicht ueber den Rand laeuft.
local texte, rechtecke, linien, boegen = {}, {}, {}, {}
local schrift = { stil = 'r', groesse = 10 }
local function utf8len(s)
    local n = 0
    for _ in tostring(s):gmatch('[^\128-\191]') do n = n + 1 end
    return n
end
local function breite(t)
    local f = (schrift.stil == 'b') and 0.70 or 0.66
    return utf8len(t) * schrift.groesse * f
end
local gc = setmetatable({}, { __index = function(_, k)
    if k == 'drawString' then
        return function(_, t, x, y)
            texte[#texte + 1] = { t = tostring(t), x = x, y = y, w = breite(t),
                h = schrift.groesse + 3, g = schrift.groesse }
        end
    end
    if k == 'setFont' then return function(_, _, stil, groesse)
        schrift.stil, schrift.groesse = stil or 'r', groesse or 10
    end end
    if k == 'fillRect' then return function(_, x, y, w, h)
        rechtecke[#rechtecke + 1] = { x = x, y = y, w = w, h = h }
    end end
    if k == 'drawLine' then return function(_, x1, y1, x2, y2)
        linien[#linien + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
    end end
    if k == 'drawArc' then return function(_, x, y, w, h)
        boegen[#boegen + 1] = { x = x, y = y, w = w, h = h }
    end end
    if k == 'getStringWidth' then return function(_, t) return breite(t) end end
    if k == 'getStringHeight' then return function() return schrift.groesse + 3 end end
    return function() end
end })

local pfad = dir .. '..\\..\\Spannungskreis\\Spannungskreis.lua'
local f = assert(io.open(pfad, 'rb'), 'Spannungskreis.lua nicht gefunden: ' .. pfad)
local code = f:read('*a'); f:close()
if code:sub(1, 3) == string.char(239, 187, 191) then code = code:sub(4) end
local export = [[

_G.__S = {
  schnitte = function() return schnitte end,
  setSchnitte = function(t) schnitte = t end,
  loesung = function() return loesung end,
  rang = function() return rang end,
  widerspruch = function() return widerspruch end,
  bereit = function() return bereit() end,
  modus = function() return modus end,
  setModus = function(m) modus = m end,
  rechne = function() return rechne() end,
  spannungen = function(a, L) return spannungen(a, L) end,
  neu = function() allesLoeschen() end,
  loeschFrage = function() return loeschFrage end,
  cursor = function() return spalte, zeile, editiere, text end,
  polygon = function(r) return scheibenPolygon(r) end,
  meldung = function() return meldung end,
  kreisWinkel = function() return kreisWinkel end,
  mehrdeutig = function() return mehrdeutig end,
  pfeile = function() return scheibenPfeile end,
}
]]
assert(loadstring(code .. export, '=' .. pfad))()
local S = _G.__S

local function write(s) io.write(s) end
local function pruef(ok, text)
    M.total = M.total + 1
    if not ok then M.fails = M.fails + 1 end
    if not ok or M.verbose then write('   ' .. (ok and 'ok ' or 'XX ') .. text .. '\n') end
end
local function zahl(label, ist, soll, tol)
    tol = tol or 1e-9
    local ok = type(ist) == 'number' and math.abs(ist - soll) <= tol * math.max(1, math.abs(soll))
    pruef(ok, string.format('%-46s soll %-12.6g ist %s', label, soll,
        type(ist) == 'number' and string.format('%.6g', ist) or tostring(ist)))
end
local function wahr(label, bed, info) pruef(bed and true or false, label .. (info and ('  [' .. tostring(info) .. ']') or '')) end
local function abschnitt(t) write('\n== ' .. t .. '\n') end
local function fall(name, fn)
    if M.filter and not name:find(M.filter, 1, true) then return end
    S.neu()
    local ok, err = pcall(fn)
    if not ok then pruef(false, 'Absturz in ' .. name .. ': ' .. tostring(err):gsub('\n.*', '')) end
end

local function refSigma(sx, sy, txy, a)
    local z = 2 * a * math.pi / 180
    return (sx + sy) / 2 + (sx - sy) / 2 * math.cos(z) + txy * math.sin(z)
end
local function refTau(sx, sy, txy, a)
    local z = 2 * a * math.pi / 180
    return -(sx - sy) / 2 * math.sin(z) + txy * math.cos(z)
end

local function setze(liste)
    local t = {}
    for i, e in ipairs(liste) do
        t[i] = { a = e[1], s = e[2], t = e[3], a_in = e[1] ~= nil, s_in = e[2] ~= nil, t_in = e[3] ~= nil }
    end
    S.setSchnitte(t)
end

-- eine Zelle wie auf dem Rechner tippen
local function tippeZelle(s)
    if s then
        for i = 1, #s do on.charIn(s:sub(i, i)) end
    else
        on.enterKey()            -- Zelle oeffnen ...
    end
    on.enterKey()                -- ... und uebernehmen
end

local function male(m)
    S.setModus(m); texte, rechtecke, linien, boegen = {}, {}, {}, {}
    local ok, err = pcall(on.paint, gc)
    pruef(ok, 'on.paint (' .. m .. ')' .. (ok and '' or (': ' .. tostring(err))))
    local alle = {}
    for _, e in ipairs(texte) do alle[#alle + 1] = e.t end
    return table.concat(alle, ' | ')
end

-- ======================================================================

fall('1 Standardzustand', function()
    abschnitt('σx = 20, σy = -5, τxy = 10 ueber zwei Schnitte')
    setze({ { 0, 20, 10 }, { 90, -5, nil } })
    wahr('rechnet', S.rechne())
    local L = S.loesung()
    wahr('eindeutig bestimmt', S.rang() == 3 and S.bereit(), S.rang())
    zahl('σx', L.sx, 20); zahl('σy', L.sy, -5); zahl('τxy', L.txy, 10)
    zahl('σm', L.sig_m, 7.5)
    zahl('R = τmax', L.r, math.sqrt(12.5 ^ 2 + 10 ^ 2))
    zahl('σ1', L.sig1, 7.5 + math.sqrt(12.5 ^ 2 + 10 ^ 2))
    zahl('σ2', L.sig2, 7.5 - math.sqrt(12.5 ^ 2 + 10 ^ 2))
    zahl('Hauptrichtung', L.a1, 0.5 * math.deg(math.atan2(10, 12.5)))
    zahl('τ im 90-Grad-Schnitt ergaenzt', S.schnitte()[2].t, -10)
    wahr('als berechnet markiert', S.schnitte()[2].t_in == false)
end)

fall('2 Dritter Schnitt wird ergaenzt', function()
    abschnitt('Schnitt unter 30 Grad gegen die Transformationsformeln')
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { 30, nil, nil } })
    S.rechne()
    local s3 = S.schnitte()[3]
    zahl('σ(30°)', s3.s, refSigma(20, -5, 10, 30))
    zahl('τ(30°)', s3.t, refTau(20, -5, 10, 30))
end)

fall('3 Drei beliebige Schnitte', function()
    abschnitt('drei schiefe Schnitte mit je einer Angabe')
    local sx, sy, txy = -12, 30, -8
    setze({ { 20, refSigma(sx, sy, txy, 20), nil },
            { 55, refSigma(sx, sy, txy, 55), nil },
            { 130, nil, refTau(sx, sy, txy, 130) } })
    wahr('rechnet', S.rechne())
    local L = S.loesung()
    zahl('σx', L.sx, sx, 1e-7); zahl('σy', L.sy, sy, 1e-7); zahl('τxy', L.txy, txy, 1e-7)
    zahl('fehlendes τ im ersten Schnitt', S.schnitte()[1].t, refTau(sx, sy, txy, 20), 1e-7)
end)

fall('4 Unbekannter Winkel', function()
    abschnitt('Schnitt ohne Winkel: er folgt geschlossen')
    local sx, sy, txy, a = 40, 10, 15, 63
    setze({ { 0, sx, txy }, { 90, sy, nil },
            { nil, refSigma(sx, sy, txy, a), refTau(sx, sy, txy, a) } })
    S.rechne()
    zahl('Winkel berechnet', S.schnitte()[3].a, a, 1e-7)
    wahr('als berechnet markiert', S.schnitte()[3].a_in == false)
    setze({ { 0, sx, txy }, { 90, sy, nil }, { nil, refSigma(sx, sy, txy, a), nil } })
    S.rechne()
    local s3, L = S.schnitte()[3], S.loesung()
    zahl('erste Loesung liefert σ', S.spannungen(s3.a, L), refSigma(sx, sy, txy, a), 1e-7)
    wahr('zweite Loesung angegeben', s3.a2 ~= nil, tostring(s3.a2))
    if s3.a2 then zahl('zweite Loesung liefert dasselbe σ', S.spannungen(s3.a2, L), refSigma(sx, sy, txy, a), 1e-7) end
end)

fall('5 Bestimmtheit', function()
    abschnitt('Rang zaehlen; ohne Rang 3 keine Loesung und keine Ansichten')
    setze({ { 0, 20, nil } }); S.rechne()
    wahr('eine Angabe: Rang 1', S.rang() == 1, S.rang())
    wahr('nicht bereit', S.bereit() == false)
    setze({ { 0, 20, 10 } }); S.rechne()
    wahr('zwei Angaben: Rang 2', S.rang() == 2, S.rang())
    setze({ { 0, 20, 10 }, { 90, -5, nil } }); S.rechne()
    wahr('drei Angaben: Rang 3', S.rang() == 3, S.rang())
    setze({ { 0, 20, nil }, { 180, 20, nil }, { 0, 20, nil } }); S.rechne()
    wahr('parallele Schnitte erhoehen den Rang nicht', S.rang() == 1, S.rang())
end)

fall('6 Widerspruch', function()
    abschnitt('zu viele Angaben, die nicht zusammenpassen')
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { 45, 999, nil } }); S.rechne()
    wahr('Widerspruch erkannt', S.widerspruch() == true)
    wahr('Ansichten gesperrt', S.bereit() == false)
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { 45, refSigma(20, -5, 10, 45), nil } }); S.rechne()
    wahr('passende Zusatzangabe ist kein Widerspruch', S.widerspruch() == false)
    wahr('Ansichten frei', S.bereit() == true)
end)

fall('7 Tabelle als Eingabe', function()
    abschnitt('Zellen tippen, Enter geht α -> σ -> τ -> naechster Schnitt')
    S.neu()
    tippeZelle('0'); tippeZelle('20'); tippeZelle('10')       -- Schnitt 1
    tippeZelle('90'); tippeZelle('-5'); tippeZelle(nil)       -- Schnitt 2, τ leer
    local sp, ze = S.cursor()
    wahr('Cursor steht im naechsten Schnitt', sp == 3 and ze == 1, sp .. '/' .. ze)
    wahr('zwei Schnitte eingegeben', #S.schnitte() == 2, #S.schnitte())
    wahr('Zustand bestimmt', S.bereit(), S.rang())
    local L = S.loesung()
    zahl('σx aus getippter Eingabe', L.sx, 20)
    zahl('τxy aus getippter Eingabe', L.txy, 10)
    zahl('τ im zweiten Schnitt ergaenzt', S.schnitte()[2].t, -10)
    -- Ausdruecke
    S.neu()
    tippeZelle('45'); tippeZelle('10*2'); tippeZelle('5+5')
    zahl('Ausdruck σ', S.schnitte()[1].s, 20)
    zahl('Ausdruck τ', S.schnitte()[1].t, 10)
end)

fall('8 Werte nachtraeglich aendern', function()
    abschnitt('in der Ergebnistabelle eine Zelle ueberschreiben und leeren')
    setze({ { 0, 20, 10 }, { 90, -5, nil } })
    S.rechne()
    -- Cursor auf Schnitt 1, Zeile σ und neu eingeben
    on.arrowKey('down')                 -- Zeile σ
    tippeZelle('30')
    zahl('σx nach der Aenderung', S.loesung().sx, 30)
    wahr('Wert gilt als eingegeben', S.schnitte()[1].s_in == true)
    -- Zelle leeren (nach Enter steht der Cursor schon eine Zeile tiefer)
    on.arrowKey('up')
    on.backspaceKey()
    wahr('Zelle ist jetzt unbekannt', S.schnitte()[1].s_in == false)
    wahr('damit fehlt eine Angabe', S.bereit() == false, S.rang())
end)

fall('9 Vieleck der Spannungsscheibe', function()
    abschnitt('nur die eingegebenen Schnitte; x-/y-Schnitt nur, wenn die Scheibe sonst offen bliebe')
    local function ergaenzt(ebenen)
        local l = {}
        for _, e in ipairs(ebenen) do if e.achse then l[#l + 1] = string.format('%s%.0f', e.achse, e.beta) end end
        table.sort(l)
        return table.concat(l, ',')
    end
    -- vier Schnitte rundum: vier Kanten, nichts ergaenzt
    setze({ { 0, 10, 0 }, { 90, 20, 0 }, { 180, 10, 0 }, { 270, 20, 0 } }); S.rechne()
    local poly, ebenen = S.polygon(1)
    wahr('vier Schnitte: vier Kanten', #poly == 4, #poly)
    wahr('  nichts ergaenzt', #ebenen == 4 and ergaenzt(ebenen) == '', ergaenzt(ebenen))
    -- Trapez wie in der Aufgabe: Schnitte bei 0, 130, 180, 250 Grad -- geschlossen, keine Rueckseiten
    setze({ { 0, 20, 10 }, { 130, 5, nil }, { 180, nil, nil }, { 250, nil, nil } }); S.rechne()
    poly, ebenen = S.polygon(1)
    wahr('Trapez: vier Kanten', #poly == 4, #poly)
    wahr('  nur die eingegebenen Schnitte', #ebenen == 4 and ergaenzt(ebenen) == '', ergaenzt(ebenen))
    -- zwei senkrechte Schnitte: offen, ergaenzt werden genau die beiden Gegenseiten
    setze({ { 0, 20, 10 }, { 90, -5, nil } }); S.rechne()
    poly, ebenen = S.polygon(1)
    wahr('0/90 Grad: Rechteck', #poly == 4, #poly)
    wahr('  ergaenzt: x-Schnitt bei 180, y-Schnitt bei 270', ergaenzt(ebenen) == 'x180,y270', ergaenzt(ebenen))
    -- zwei schiefe Schnitte: eine Ergaenzung reicht (Dreieck)
    setze({ { 30, 20, 10 }, { 120, -5, nil } }); S.rechne()
    poly, ebenen = S.polygon(1)
    wahr('30/120 Grad: Dreieck', #poly == 3, #poly)
    wahr('  nur der y-Schnitt bei 270 ergaenzt', ergaenzt(ebenen) == 'y270', ergaenzt(ebenen))
    -- ein einzelner Schnitt: Gegenseite und beide y-Seiten
    setze({ { 0, 20, 10 } })
    poly, ebenen = S.polygon(1)
    wahr('ein Schnitt: Rechteck', #poly == 4, #poly)
    wahr('  ergaenzt: x180, y90, y270', ergaenzt(ebenen) == 'x180,y270,y90', ergaenzt(ebenen))
    -- jede Ebene liefert eine Kante (alle beruehren den Inkreis)
    setze({ { 0, 20, 10 }, { 130, 5, nil }, { 180, nil, nil }, { 250, nil, nil } }); S.rechne()
    male('scheibe')
    wahr('Trapez gezeichnet: vier Kanten mit Pfeilen', #S.pfeile() == 4, #S.pfeile())
    local txt = male('scheibe')
    wahr('  keine Ergaenzung in der Legende', txt:find('ergänzt', 1, true) == nil)
    local rand = 0
    for _, e in ipairs(texte) do rand = math.max(rand, e.x + e.w - 318) end
    wahr('  laengliche Scheibe passt auf den Bildschirm', rand <= 0, rand)
    local raus = 0
    for _, l in ipairs(linien) do
        for _, pt in ipairs({ { l.x1, l.y1 }, { l.x2, l.y2 } }) do
            if pt[1] < 0 or pt[1] > 318 or pt[2] < 18 or pt[2] > 212 then raus = raus + 1 end
        end
    end
    wahr('  Kanten und Pfeile liegen ganz im Bild', raus == 0, raus)
end)

fall('10 Ansichten zeichnen', function()
    abschnitt('Tabelle, Scheibe und Kreis: griechische Zeichen, alle Schnitte beschriftet')
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { 30, nil, nil } })
    S.rechne()
    local tab = male('tabelle')
    wahr('Tabelle nennt die Schnitte', tab:find('S1', 1, true) and tab:find('S3', 1, true), tab:sub(1, 70))
    wahr('griechisches σ in der Tabelle', tab:find('σ', 1, true) ~= nil)
    wahr('griechisches τ in der Tabelle', tab:find('τ', 1, true) ~= nil)
    wahr('griechisches α in der Tabelle', tab:find('α', 1, true) ~= nil)
    wahr('Hauptspannungen stehen da', tab:find('σ₁', 1, true) ~= nil, tab:sub(1, 70))
    wahr('Farblegende', tab:find('eingegeben', 1, true) ~= nil)
    -- Ergebnisse sollen den Platz unten nutzen
    S.setModus('tabelle'); texte = {}; pcall(on.paint, gc)
    local unten = 0
    for _, e in ipairs(texte) do if e.t:find('σx = ', 1, true) then unten = e.y end end
    wahr('Ergebnisblock steht weit unten', unten > 150, unten)

    local sch = male('scheibe')
    for i = 1, 3 do
        wahr('Scheibe beschriftet S' .. i, sch:find('S' .. i .. ' (', 1, true) ~= nil, sch:sub(1, 90))
    end
    local anz_s, anz_t = 0, 0
    for _, e in ipairs(texte) do
        if e.t:find('σ=', 1, true) then anz_s = anz_s + 1 end
        if e.t:find('τ=', 1, true) then anz_t = anz_t + 1 end
    end
    wahr('σ an jeder Kante', anz_s >= 3, anz_s)
    wahr('τ an jeder Kante', anz_t >= 3, anz_t)

    local kr = male('kreis')
    wahr('Kreis zeigt die Hauptspannungen', kr:find('σ₁=', 1, true) and kr:find('σ₂=', 1, true), kr:sub(1, 70))
    wahr('Kreis beschriftet die Schnitte', kr:find('S2', 1, true) ~= nil)
end)

fall('11 Ansichten gesperrt', function()
    abschnitt('ohne eindeutigen Zustand fuehren [s] und [k] nicht weiter')
    setze({ { 0, 20, nil } }); S.rechne()
    S.setModus('tabelle')
    on.charIn('s')
    wahr('Scheibe gesperrt', S.modus() == 'tabelle', S.modus())
    wahr('mit Hinweis', (S.meldung() or ''):find('eindeutig', 1, true) ~= nil, S.meldung())
    on.charIn('k')
    wahr('Kreis gesperrt', S.modus() == 'tabelle', S.modus())
    local txt = male('scheibe')
    wahr('Scheibe zeigt den Grund', txt:find('nicht eindeutig', 1, true) ~= nil, txt:sub(1, 60))
    S.setModus('tabelle')
    setze({ { 0, 20, 10 }, { 90, -5, nil } }); S.rechne()
    on.charIn('s'); wahr('jetzt frei', S.modus() == 'scheibe', S.modus())
    on.charIn('k'); wahr('Kreis frei', S.modus() == 'kreis', S.modus())
    on.charIn('t'); wahr('zurueck zur Tabelle', S.modus() == 'tabelle', S.modus())
end)

fall('12 Neu anfangen', function()
    abschnitt('[del] fragt nach, [Esc] bricht ab, [Enter] loescht')
    setze({ { 0, 20, 10 }, { 90, -5, nil } }); S.rechne()
    on.deleteKey()
    wahr('Frage steht', S.loeschFrage() == true)
    texte = {}; pcall(on.paint, gc)
    local gefragt = false
    for _, e in ipairs(texte) do if e.t:find('neu anfangen', 1, true) then gefragt = true end end
    wahr('Frage wird gezeichnet', gefragt)
    on.escapeKey()
    wahr('Esc bricht ab', S.loeschFrage() == false and #S.schnitte() == 2, #S.schnitte())
    on.deleteKey(); on.enterKey()
    wahr('Enter loescht alles', #S.schnitte() == 1 and S.loesung() == nil, #S.schnitte())
    wahr('zurueck in der Tabelle', S.modus() == 'tabelle', S.modus())
end)

fall('13 Layout der Tabelle', function()
    abschnitt('nichts laeuft ueber den Rand, Spalten und Zeilen stehen sauber')
    local W, H = 318, 212

    local function male_tab()
        S.setModus('tabelle'); texte = {}; rechtecke = {}
        local ok, err = pcall(on.paint, gc)
        pruef(ok, 'on.paint (Layout)' .. (ok and '' or (': ' .. tostring(err))))
    end
    local function finde(muster)
        for _, e in ipairs(texte) do if e.t:find(muster, 1, true) then return e end end
    end
    local function genau(t)
        for _, e in ipairs(texte) do if e.t == t then return e end end
    end
    local function randpruefung(wann)
        local schlimmster, ueber = nil, 0
        for _, e in ipairs(texte) do
            local rand = e.x + e.w - W
            if rand > ueber then ueber, schlimmster = rand, e end
        end
        wahr('kein Text ueber den rechten Rand (' .. wann .. ')', ueber <= 0,
            schlimmster and (schlimmster.t .. ' +' .. string.format('%.0f', ueber) .. 'px') or 'ok')
        local tief = nil
        for _, e in ipairs(texte) do
            if e.y + e.h > H and (not tief or e.y > tief.y) then tief = e end
        end
        wahr('kein Text unter den unteren Rand (' .. wann .. ')', tief == nil,
            tief and (tief.t .. ' y=' .. tief.y) or 'ok')
    end

    -- leere Tabelle wie direkt nach dem Start
    S.neu()
    male_tab()
    randpruefung('leer')
    local kopf_s = genau('Schnitt')
    local kopf_1 = genau('neu')
    wahr('Zeilenbeschriftung ueberlappt die Spalte nicht',
        kopf_s and kopf_1 and (kopf_s.x + kopf_s.w <= kopf_1.x - 2),
        kopf_s and kopf_1 and string.format('Ende %.0f, Spalte bei %.0f', kopf_s.x + kopf_s.w, kopf_1.x))

    -- Eingabefeld liegt auf der Zeile, die links beschriftet ist
    local zeile_a = finde('α [°]')
    local feld = rechtecke[#rechtecke]
    wahr('Eingabefeld auf Hoehe der Beschriftung',
        zeile_a and feld and math.abs(feld.y - zeile_a.y) <= 1 and math.abs(feld.h - zeile_a.h) <= 2,
        zeile_a and feld and string.format('Feld y=%.0f h=%.0f, Text y=%.0f h=%.0f',
            feld.y, feld.h, zeile_a.y, zeile_a.h))

    -- gerechneter Zustand: Status, Ergebnisse und Fusszeile
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { 30, nil, nil }, { 123.456, nil, nil } })
    S.rechne()
    male_tab()
    randpruefung('gerechnet')
    local status = finde('eindeutig bestimmt')
    local block = genau('Spannungszustand')
    wahr('Ergebnisblock steht deutlich unter der Statuszeile',
        status and block and (block.y - status.y >= 20),
        status and block and (block.y - status.y))
    local letzte = finde('σx = ')
    wahr('letzte Ergebniszeile nutzt den Platz unten', letzte and letzte.y > 150,
        letzte and letzte.y)

    -- Sonderfaelle der Statuszeile
    setze({ { 0, 20, nil } }); S.rechne(); male_tab()
    randpruefung('unbestimmt')
    wahr('Hinweis auf fehlende Angaben', finde('nötig') ~= nil)
    setze({ { 0, 20, nil }, { 0, 25, nil }, { 90, 0, nil }, { 45, 0, nil } })
    S.rechne(); male_tab()
    randpruefung('widerspruch')
    wahr('Widerspruch wird gemeldet', finde('widersprech') ~= nil)

    -- auch die Zeichnungen bleiben im Bild
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { 30, nil, nil } }); S.rechne()
    for _, m in ipairs({ 'scheibe', 'kreis' }) do
        S.setModus(m); texte, rechtecke, linien, boegen = {}, {}, {}, {}
        pcall(on.paint, gc)
        randpruefung(m)
    end
    S.setModus('tabelle')
end)

fall('14 Kreis im klassischen KOS', function()
    abschnitt('die tau-Achse steht bei sigma = 0, der Kreis bleibt ganz sichtbar')
    local W, H = 318, 212

    local function kreisBild(liste)
        setze(liste); S.rechne()
        S.setModus('kreis'); texte, rechtecke, linien, boegen = {}, {}, {}, {}
        local ok, err = pcall(on.paint, gc)
        pruef(ok, 'on.paint (Kreis)' .. (ok and '' or (': ' .. tostring(err))))
        local kreis                     -- groesster Bogen ist der Spannungskreis
        for _, b in ipairs(boegen) do if not kreis or b.w > kreis.w then kreis = b end end
        local achse                     -- laengste senkrechte Linie ist die tau-Achse
        for _, l in ipairs(linien) do
            if math.abs(l.x1 - l.x2) < 0.5 and math.abs(l.y2 - l.y1) > 100 then
                if not achse or math.abs(l.y2 - l.y1) > math.abs(achse.y2 - achse.y1) then achse = l end
            end
        end
        return kreis, achse
    end
    -- Aus dem gezeichneten Kreis die Abbildung zurueckrechnen: Mitte <-> sigma_m, Radius <-> R
    local function nullBei(kreis, L)
        return (kreis.x + kreis.w / 2) - L.sig_m * (kreis.w / 2) / L.r
    end
    local function imBild(kreis)
        return kreis and kreis.x > 0 and kreis.x + kreis.w < W and kreis.y > 18 and kreis.y + kreis.h < H
    end

    -- Zug und Druck: der Ursprung liegt im Kreis
    local kreis, achse = kreisBild({ { 0, 20, 10 }, { 90, -5, nil } })
    local L = S.loesung()
    wahr('Kreis ganz im Bild', imBild(kreis), kreis and
        string.format('x=%.0f..%.0f y=%.0f..%.0f', kreis.x, kreis.x + kreis.w, kreis.y, kreis.y + kreis.h))
    wahr('Kreis gross genug', kreis and kreis.w / 2 >= 30, kreis and kreis.w / 2)
    wahr('tau-Achse steht bei sigma = 0', achse and kreis and math.abs(achse.x1 - nullBei(kreis, L)) < 1.5,
        achse and kreis and string.format('Achse %.1f, sigma=0 bei %.1f', achse.x1, nullBei(kreis, L)))
    local hatNull = false
    for _, e in ipairs(texte) do if e.t == '0' then hatNull = true end end
    wahr('Nullpunkt mit 0 beschriftet', hatNull)

    -- reiner Zug: der Ursprung liegt links ausserhalb des Kreises, muss aber sichtbar bleiben
    kreis, achse = kreisBild({ { 0, 100, 0 }, { 90, 60, nil } })
    L = S.loesung()
    zahl('sigma_m', L.sig_m, 80, 1e-9)
    wahr('Kreis ganz im Bild (Zug)', imBild(kreis), kreis and
        string.format('x=%.0f..%.0f', kreis.x, kreis.x + kreis.w))
    wahr('tau-Achse links vom Kreis', achse and kreis and achse.x1 < kreis.x, achse and achse.x1)
    wahr('tau-Achse bei sigma = 0 (Zug)', achse and kreis and math.abs(achse.x1 - nullBei(kreis, L)) < 1.5,
        achse and kreis and string.format('Achse %.1f, sigma=0 bei %.1f', achse.x1, nullBei(kreis, L)))

    -- weit weg vom Ursprung: der Kreis hat Vorrang, der Nullpunkt wird am Rand vermerkt
    kreis, achse = kreisBild({ { 0, 1000, 0 }, { 90, 998, nil } })
    wahr('kleiner Kreis bleibt sichtbar', kreis and kreis.w / 2 >= 30 and imBild(kreis),
        kreis and kreis.w / 2)
    local txt = table.concat((function()
        local t = {}
        for _, e in ipairs(texte) do t[#t + 1] = e.t end
        return t
    end)(), ' | ')
    wahr('Hinweis auf den Nullpunkt am Rand', txt:find('σ=0', 1, true) ~= nil, txt:sub(1, 60))

    S.setModus('tabelle')
end)

fall('15 Kreis mit den Pfeiltasten', function()
    abschnitt('links/rechts springt zwischen den Schnitten, hoch/runter dreht 5 Grad')
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { 30, nil, nil } })
    S.rechne()
    S.setModus('tabelle')
    on.charIn('k')
    wahr('Kreis offen', S.modus() == 'kreis', S.modus())
    zahl('Marke startet beim ersten Schnitt', S.kreisWinkel(), 0, 1e-9)

    on.arrowKey('right'); zahl('rechts: naechster Schnitt', S.kreisWinkel(), 30, 1e-9)
    on.arrowKey('right'); zahl('rechts: uebernaechster Schnitt', S.kreisWinkel(), 90, 1e-9)
    on.arrowKey('right'); zahl('rechts laeuft zyklisch weiter', S.kreisWinkel(), 0, 1e-9)
    on.arrowKey('left');  zahl('links geht zurueck', S.kreisWinkel(), 90, 1e-9)
    wahr('Pfeile verlassen den Kreis nicht', S.modus() == 'kreis', S.modus())

    on.arrowKey('up');   zahl('hoch dreht 5 Grad', S.kreisWinkel(), 95, 1e-9)
    on.arrowKey('down'); zahl('runter dreht zurueck', S.kreisWinkel(), 90, 1e-9)
    on.arrowKey('down'); zahl('runter unter den Schnitt', S.kreisWinkel(), 85, 1e-9)

    -- Marke steht mit Winkel und Spannungen im Bild
    on.arrowKey('up')
    local txt = male('kreis')
    wahr('Marke ist beschriftet', txt:find('90.0', 1, true) ~= nil, txt:sub(1, 90))
    wahr('Marke nennt ihren Schnitt', txt:find('S2', 1, true) ~= nil)
    local sg, ta = S.spannungen(90, S.loesung())
    wahr('Marke zeigt sigma des Schnitts', txt:find(string.format('%.2f', sg), 1, true) ~= nil,
        string.format('%.2f', sg))
    wahr('Marke zeigt tau des Schnitts', txt:find(string.format('%.2f', ta), 1, true) ~= nil,
        string.format('%.2f', ta))
    S.setModus('tabelle')
end)

fall('16 Scheibe: x nach unten, y nach rechts', function()
    abschnitt('Koordinatensystem der Spannungsscheibe wie im Querschnitt')
    local W, H = 318, 212
    local cx, cy = W / 2, (H + 18) / 2 + 4
    setze({ { 0, 20, 10 }, { 90, -5, nil } }); S.rechne()
    male('scheibe')

    local ax, ay, s1, s2
    for _, e in ipairs(texte) do
        if e.t == 'x' then ax = e end
        if e.t == 'y' then ay = e end
        if e.t:find('S1 (', 1, true) and not e.t:find('R', 1, true) then s1 = e end
        if e.t:find('S2 (', 1, true) and not e.t:find('R', 1, true) then s2 = e end
    end
    wahr('x-Achse ist nach unten beschriftet', ax and ax.y > cy, ax and ax.y)
    wahr('y-Achse ist nach rechts beschriftet', ay and ay.x > cx and math.abs(ay.y - cy) < 20,
        ay and string.format('%.0f/%.0f', ay.x, ay.y))
    wahr('Schnitt bei 0 Grad liegt unten', s1 and s1.y > cy, s1 and s1.y)
    wahr('Schnitt bei 90 Grad liegt rechts', s2 and s2.x > cx, s2 and s2.x)
end)

fall('17 Schnitt ohne Winkel als Kreispunkt', function()
    abschnitt('Klausur Aufgabe 5: Hauptrichtung x, sigma_y = 10, Schnitt (35, 20) ohne Winkel')
    -- wie auf dem Rechner: S1 alpha=0, tau=0 (Hauptrichtung) | S2 alpha=90, sigma=10 | S3 sigma=35, tau=20
    tippeZelle('0'); tippeZelle(nil); tippeZelle('0')
    tippeZelle('90'); tippeZelle('10'); tippeZelle(nil)
    tippeZelle(nil); tippeZelle('35'); tippeZelle('20')
    local L = S.loesung()
    wahr('eindeutig bestimmt', L ~= nil and S.bereit(), 'rang ' .. tostring(S.rang()))
    if L then
        zahl('sigma_I = 51', L.sig1, 51, 1e-9)
        zahl('sigma_II = 10', L.sig2, 10, 1e-9)
        zahl('sigma_x = 51', L.sx, 51, 1e-9)
        zahl('tau_xy = 0', L.txy, 0, 1e-9)
        local sch = S.schnitte()
        zahl('S1: sigma = sigma_I', sch[1].s, 51, 1e-9)
        -- Winkel des Schnitts: -38.66 Grad, in [0, 180) also 141.34 Grad
        zahl('S3: phi_x-xi = -38.66 (mod 180)', sch[3].a, 180 - 38.659808254, 1e-6)
        local s3, t3 = S.spannungen(sch[3].a, L)
        zahl('S3: sigma im berechneten Winkel = 35', s3, 35, 1e-9)
        zahl('S3: tau im berechneten Winkel = 20', t3, 20, 1e-9)
    end
    local txt = male('tabelle')
    wahr('Status: eindeutig bestimmt', txt:find('eindeutig bestimmt', 1, true) ~= nil)
    on.charIn('k'); wahr('Kreis frei', S.modus() == 'kreis', S.modus())
    S.setModus('tabelle')

    abschnitt('zaehlen: ein Kreispunkt ist eine Angabe, der Winkel bleibt offen')
    S.neu(); setze({ { nil, 35, 20 } }); S.rechne()
    zahl('nur ein Kreispunkt: Rang 1', S.rang(), 1)
    setze({ { nil, 35, 20 }, { nil, 10, 5 } }); S.rechne()
    zahl('zwei Kreispunkte: Rang 2 (Mitte und Radius, keine Richtung)', S.rang(), 2)
    wahr('  noch nicht bestimmt', S.loesung() == nil)

    abschnitt('zwei moegliche Zustaende: sigma_x und sigma_y bekannt, Punkt ohne Winkel')
    -- wahrer Zustand sigma_x = 20, sigma_y = -5, tau_xy = 10; Punkt bei 30 Grad
    local s30 = 7.5 + 12.5 * 0.5 + 10 * math.sqrt(3) / 2
    local t30 = -12.5 * math.sqrt(3) / 2 + 10 * 0.5
    setze({ { 0, 20, nil }, { 90, -5, nil }, { nil, s30, t30 } }); S.rechne()
    local M = S.mehrdeutig()
    wahr('zwei Zustaende erkannt', M ~= nil and #M == 2)
    wahr('  nicht eindeutig: gesperrt', S.loesung() == nil and not S.bereit())
    if M and #M == 2 then
        zahl('  tau_xy der Loesungen: +10 und -10', math.abs(M[1].txy) + math.abs(M[2].txy), 20, 1e-9)
        zahl('  entgegengesetzt', M[1].txy + M[2].txy, 0, 1e-9)
    end
    txt = male('tabelle')
    wahr('Status nennt zwei Zustaende', txt:find('zwei Zustände', 1, true) ~= nil, txt:sub(-120))
    wahr('beide Zustaende stehen im Ergebnisblock', txt:find('1:', 1, true) ~= nil and txt:find('2:', 1, true) ~= nil)
    local rand, unten = 0, 0
    for _, e in ipairs(texte) do
        rand = math.max(rand, e.x + e.w - 318); unten = math.max(unten, e.y + e.h - 212)
    end
    wahr('  nichts ueber den rechten Rand', rand <= 0, rand)
    wahr('  nichts unter den unteren Rand', unten <= 0, unten)
    on.charIn('s'); wahr('Scheibe gesperrt', S.modus() == 'tabelle', S.modus())
    -- eine weitere Angabe mit Winkel entscheidet
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { nil, s30, t30 } }); S.rechne()
    wahr('mit tau_xy eindeutig', S.loesung() ~= nil and S.mehrdeutig() == nil)

    abschnitt('Ungleichung aus einem Schnitt ohne Winkel mit nur sigma schliesst eine Loesung aus')
    -- wahr: sigma_m = 10, Rc = 6, Rs = 0. Angaben tau(0) = 0, sigma(30) = 13, Punkt bei 60 Grad (7, -5.196)
    local p60s, p60t = 10 + 6 * math.cos(math.rad(120)), -6 * math.sin(math.rad(120))
    setze({ { 0, nil, 0 }, { 30, 13, nil }, { nil, p60s, p60t } }); S.rechne()
    M = S.mehrdeutig()
    wahr('ohne weitere Angabe zwei Zustaende', M ~= nil and #M == 2)
    if M and #M == 2 then
        local r1, r2 = math.min(M[1].r, M[2].r), math.max(M[1].r, M[2].r)
        zahl('  Radien 6 und 14', r1 + r2 / 100, 6 + 0.14, 1e-9)
    end
    -- sigma = 5 (ohne Winkel) passt nur in [4, 16], nicht in [6, 34]
    setze({ { 0, nil, 0 }, { 30, 13, nil }, { nil, p60s, p60t }, { nil, 5, nil } }); S.rechne()
    L = S.loesung()
    wahr('sigma = 5 ohne Winkel entscheidet', L ~= nil and S.mehrdeutig() == nil)
    if L then zahl('  sigma_1 = 16', L.sig1, 16, 1e-9); zahl('  sigma_2 = 4', L.sig2, 4, 1e-9) end

    abschnitt('Widerspruch: Punkt ohne Winkel liegt nicht auf dem bestimmten Kreis')
    setze({ { 0, 20, 0 }, { 90, -5, nil }, { nil, 100, 0 } }); S.rechne()
    wahr('Widerspruch erkannt', S.widerspruch() == true)
    wahr('  gesperrt', not S.bereit())
    setze({ { 0, 20, 0 }, { 90, -5, nil }, { nil, 20, 0 } }); S.rechne()
    wahr('passender Punkt: kein Widerspruch', S.widerspruch() == false and S.bereit())
end)

fall('18 Pfeilrichtungen an gegenueberliegenden Kanten', function()
    abschnitt('Zug zeigt immer von der Scheibe weg, tau auf Gegenseiten entgegengesetzt')
    local function richtungen(liste, name)
        setze(liste); S.rechne()
        male('scheibe')
        local P = S.pfeile()
        wahr(name .. ': vier Kanten gezeichnet', #P == 4, #P)
        local function dot(a, b) return a[1] * b[1] + a[2] * b[2] end
        for _, e in ipairs(P) do
            local kante = name .. ': ' .. (e.i and ('S' .. e.i) or (e.achse .. '-Schnitt')) .. string.format(' (%.0f)', e.beta)
            local n = { e.nx, e.ny }
            -- Normalspannung: nach aussen genau dann, wenn Zug
            if math.abs(e.s) > 1e-9 then
                local d = { e.sigma[3] - e.sigma[1], e.sigma[4] - e.sigma[2] }
                wahr(kante .. ': sigma ' .. (e.s > 0 and 'Zug zeigt weg' or 'Druck zeigt auf die Scheibe'),
                    (dot(d, n) > 0) == (e.s > 0), string.format('s=%.2f  d.n=%.1f', e.s, dot(d, n)))
            end
            -- Schubspannung: laengs der eigenen Tangente (Normale um +90 Grad) mit dem Vorzeichen von tau
            if math.abs(e.t) > 1e-9 then
                local d = { e.tau[3] - e.tau[1], e.tau[4] - e.tau[2] }
                local tang = { e.ny, -e.nx }
                wahr(kante .. ': tau laengs der eigenen Tangente', (dot(d, tang) > 0) == (e.t > 0),
                    string.format('t=%.2f  d.t=%.1f', e.t, dot(d, tang)))
            end
        end
        -- Gegenueberliegende Kanten (Normalen um 180 Grad verschieden): sigma und tau entgegengesetzt
        for _, a in ipairs(P) do
            for _, b in ipairs(P) do
                if a.beta < b.beta and math.abs(b.beta - a.beta - 180) < 1e-6 then
                    local da = { a.sigma[3] - a.sigma[1], a.sigma[4] - a.sigma[2] }
                    local db = { b.sigma[3] - b.sigma[1], b.sigma[4] - b.sigma[2] }
                    wahr(name .. string.format(': %.0f und %.0f Grad: sigma-Pfeile entgegengesetzt', a.beta, b.beta), dot(da, db) < 0)
                    if a.tau and b.tau then
                        local ta = { a.tau[3] - a.tau[1], a.tau[4] - a.tau[2] }
                        local tb = { b.tau[3] - b.tau[1], b.tau[4] - b.tau[2] }
                        wahr(name .. string.format(': %.0f und %.0f Grad: tau-Pfeile entgegengesetzt', a.beta, b.beta), dot(ta, tb) < 0)
                    end
                end
            end
        end
        return P
    end

    -- sigma_x = 20 (Zug), sigma_y = -5 (Druck), tau_xy = 10
    local P = richtungen({ { 0, 20, 10 }, { 90, -5, nil } }, 'Zug/Druck')
    -- klassisches Bild bei tau_xy > 0: auf der +x-Flaeche (unten, x zeigt nach unten) zeigt tau nach +y
    -- (rechts), auf der +y-Flaeche (rechts) nach +x (unten) -- beide auf die Ecke unten rechts zu
    for _, e in ipairs(P) do
        if e.i == 1 then
            wahr('+x-Flaeche liegt unten', e.ny > 0.9, e.ny)
            wahr('  tau zeigt nach rechts (+y)', e.tau[3] - e.tau[1] > 0)
        elseif e.i == 2 then
            wahr('+y-Flaeche liegt rechts', e.nx > 0.9, e.nx)
            wahr('  tau zeigt nach unten (+x)', e.tau[4] - e.tau[2] > 0)
        end
    end
    -- beide Normalspannungen Zug, negatives tau
    richtungen({ { 0, 30, -8 }, { 90, 12, nil } }, 'Zug/Zug')
    -- drei Schnitte ohne Rueckseiten: jede Kante nur mit ihren eigenen Werten
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { 225, nil, nil } }); S.rechne()
    male('scheibe')
    local ok = true
    for _, e in ipairs(S.pfeile()) do
        local d = { e.sigma[3] - e.sigma[1], e.sigma[4] - e.sigma[2] }
        if math.abs(e.s) > 1e-9 and ((d[1] * e.nx + d[2] * e.ny) > 0) ~= (e.s > 0) then ok = false end
    end
    wahr('Vieleck mit Ergaenzung: an jeder Kante zeigt Zug weg und Druck hin', ok)
end)

fall('19 Tab wechselt die Winkelloesung', function()
    abschnitt('Winkel mit zwei Loesungen: Tab im Feld α wechselt, σ/τ des Schnitts folgen')
    -- sigma_x = 20, sigma_y = -5, tau_xy = 10; S3 nur mit sigma = sigma(30 Grad), Winkel offen
    local s30 = select(1, (function()
        setze({ { 0, 20, 10 }, { 90, -5, nil } }); S.rechne()
        return S.spannungen(30, S.loesung())
    end)())
    setze({ { 0, 20, 10 }, { 90, -5, nil }, { nil, s30, nil } }); S.rechne()
    local sch = S.schnitte()[3]
    wahr('zwei Loesungen vorhanden', sch.a ~= nil and sch.a2 ~= nil, tostring(sch.a) .. ' / ' .. tostring(sch.a2))
    local a1, a2, t1 = sch.a, sch.a2, sch.t
    -- Cursor auf S3, Zeile α
    on.arrowKey('right'); on.arrowKey('right')
    local sp, ze = S.cursor()
    wahr('Cursor auf S3 / α', sp == 3 and ze == 1, sp .. '/' .. ze)
    local txt = male('tabelle')
    wahr('Legende nennt Tab', txt:find('Tab: andere Lösung', 1, true) ~= nil)
    on.tabKey()
    sch = S.schnitte()[3]
    zahl('Tab: jetzt die andere Loesung vorne', sch.a, a2, 1e-12)
    zahl('  die erste steht klein dahinter', sch.a2, a1, 1e-12)
    local s_neu, t_neu = S.spannungen(sch.a, S.loesung())
    zahl('  sigma bleibt die Eingabe', sch.s, s30, 1e-12)
    zahl('  tau folgt der gewaehlten Loesung', sch.t, t_neu, 1e-12)
    wahr('  tau hat sich geaendert', math.abs(sch.t - t1) > 1e-6, sch.t .. ' / ' .. t1)
    zahl('  sigma der Loesung stimmt', s_neu, s30, 1e-9)
    -- Wahl bleibt beim Neurechnen erhalten
    S.rechne()
    zahl('Wahl bleibt beim Neurechnen', S.schnitte()[3].a, a2, 1e-12)
    -- Scheibe und Kreis nehmen den gewaehlten Winkel
    male('scheibe')
    local ok = false
    for _, e in ipairs(texte) do
        if e.t:find('S3 (' .. string.format('%.1f', a2), 1, true) then ok = true end
    end
    wahr('Scheibe beschriftet S3 mit dem gewaehlten Winkel', ok)
    S.setModus('tabelle')
    -- Shift+Tab bzw. nochmal Tab: zurueck
    on.backtabKey()
    zahl('Shift+Tab: wieder die erste Loesung', S.schnitte()[3].a, a1, 1e-12)
    -- Tab ausserhalb eines solchen Feldes: keine Wirkung
    on.arrowKey('left')
    local vorher = S.schnitte()[3].a
    on.tabKey()
    zahl('Tab auf S2 / α: nichts passiert', S.schnitte()[3].a, vorher, 1e-12)
    -- Eingabe am Schnitt setzt die Wahl zurueck
    on.arrowKey('right'); on.tabKey()
    zahl('  (wieder zweite Loesung gewaehlt)', S.schnitte()[3].a, a2, 1e-12)
    on.arrowKey('down')                    -- Zeile σ von S3
    tippeZelle(string.format('%.10g', s30))
    zahl('neue Eingabe an S3: wieder die erste Loesung', S.schnitte()[3].a, a1, 1e-9)
end)

write(string.format('\nErgebnis Spannungskreis: %d Pruefungen, %d Fehler\n', M.total, M.fails))
os.exit(M.fails == 0 and 0 or 1)
