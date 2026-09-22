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
    abschnitt('eine Kante je Schnitt; ohne volle Umfassung kommen die Rueckseiten dazu')
    setze({ { 0, 10, 0 }, { 90, 20, 0 }, { 180, 10, 0 }, { 270, 20, 0 } })
    S.rechne()
    local poly, ebenen = S.polygon(40)
    wahr('Polygon entsteht', poly ~= nil and #poly >= 3, poly and #poly)
    wahr('vier Kanten fuer vier Schnitte', #poly == 4, #poly)
    wahr('keine Rueckseiten noetig', #ebenen == 4, #ebenen)
    -- zwei senkrechte Schnitte: Rechteck mit Vorder- und Rueckseite
    setze({ { 0, 20, 10 }, { 90, -5, nil } })
    S.rechne()
    local poly2, ebenen2 = S.polygon(40)
    wahr('Rechteck aus zwei Schnitten', #poly2 == 4, #poly2)
    wahr('Rueckseiten ergaenzt', #ebenen2 == 4, #ebenen2)
    local seiten = 0
    for _, e in ipairs(ebenen2) do if e.seite == -1 then seiten = seiten + 1 end end
    wahr('zwei Rueckseiten', seiten == 2, seiten)
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

write(string.format('\nErgebnis Spannungskreis: %d Pruefungen, %d Fehler\n', M.total, M.fails))
os.exit(M.fails == 0 and 0 or 1)
