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

local texte = {}
local gc = setmetatable({}, { __index = function(_, k)
    if k == 'drawString' then return function(_, t, x, y) texte[#texte + 1] = { t = tostring(t), x = x, y = y } end end
    if k == 'getStringWidth' then return function(_, t) return #tostring(t) * 6 end end
    if k == 'getStringHeight' then return function() return 12 end end
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
    S.setModus(m); texte = {}
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

write(string.format('\nErgebnis Spannungskreis: %d Pruefungen, %d Fehler\n', M.total, M.fails))
os.exit(M.fails == 0 and 0 or 1)
