-- Oberflaeche des Tragwerksskripts: Warnhinweise mit ESC schliessen, Obermenue-Werte fuer neue Staebe.
-- on.paint wird mit einer Zeichen-Attrappe aufgerufen, die alle Texte sammelt.
-- Aufruf: luajit Emulator/tests/oberflaeche.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller = T.node, T.fixed, T.pinned, T.roller
local STANDARD_DEHNSTARR = randDehnstarr   -- Wert ab Werk (vor jedem T.reset)
local STANDARD_DIREKT = randStarrDirekt

-- Zeichen-Attrappe: Texte sammeln, Textbreite 6 px je Zeichen
local texte = {}
local gc = setmetatable({}, { __index = function(_, k)
    if k == 'drawString' then return function(_, text, x, y) texte[#texte + 1] = { t = tostring(text), x = x, y = y } end end
    if k == 'getStringWidth' then return function(_, text) return #tostring(text) * 6 end end
    if k == 'getStringHeight' then return function() return 12 end end
    return function() end
end })
local function zeichne()
    texte = {}
    local ok, err = pcall(on.paint, gc)
    if not ok then T.pruef(false, 'on.paint Absturz: ' .. tostring(err):gsub('\n.*', '')) end
    return texte
end
local function sichtbar(muster)
    for _, e in ipairs(zeichne()) do if e.t:find(muster, 1, true) then return true end end
    return false
end
local function sichtbarGenau(text)
    for _, e in ipairs(zeichne()) do if e.t == text then return true end end
    return false
end

-- Obermenue Seite 1 wie auf dem Rechner: Zeile waehlen, Enter, Text, Enter
local function obermenue(zeile, text)
    menuOffen, menuTyp, menuSeite, menuZeile, eingabeModus = true, 'obermenue', 1, zeile, false
    on.enterKey(); eingabeText = text; on.enterKey()
    menuOffen = false
end
local function stabZeichnen(a, b, q)
    local S = getStaebe(); S[#S + 1] = erstelleStab(a, b)
    if q then S[#S].q, S[#S].q_str = 1, q end
    setStaebe(S)
end
local function leer(K)
    T.reset()
    defEA, defEI, defEA_str, defEI_str = 1e10, 1e8, nil, nil
    menuOffen, eingabeModus = false, false
    uiZustand({ auswahl = false, warnungKinematisch = false, warnungStarrBestimmt = false, pvvPrompt = false, pvvModus = false, in_pvv_release = false })
    ansichtsModus = 'System'
    hinweisQuittiert = nil
    setKnoten(K); setStaebe({})
end
local function hinweisMit(muster)
    for _, h in ipairs(hinweisListe) do if h:find(muster, 1, true) then return true end end
    return false
end

local fall = T.fall

fall('1 Obermenue vor dem Zeichnen', function()
    T.abschnitt('EA/EI im Obermenue setzen, danach Staebe zeichnen')
    leer({ pinned(node(0)), node(2), roller(node(4)) })
    obermenue(2, 'EA'); obermenue(3, 'EI')
    stabZeichnen(1, 2, 'q'); stabZeichnen(2, 3, 'q')
    local S = getStaebe()
    for i = 1, 2 do
        T.wahr('Stab ' .. i .. ': EA_str = EA', S[i].EA_str == 'EA', S[i].EA_str)
        T.wahr('Stab ' .. i .. ': EI_str = EI', S[i].EI_str == 'EI', S[i].EI_str)
    end
    pcall(starteBerechnung)
    T.wahr('kein symbolFehler', symbolFehler == nil, symbolFehler)
end)

fall('2 Obermenue zwischendurch', function()
    T.abschnitt('Stab zeichnen, EA setzen, weiteren Stab zeichnen (fuehrte zur Warnung)')
    leer({ pinned(node(0)), node(2), roller(node(4)) })
    stabZeichnen(1, 2, 'q'); obermenue(2, 'EA'); stabZeichnen(2, 3, 'q')
    pcall(starteBerechnung)
    T.wahr('Stab 2 uebernimmt EA', getStaebe()[2].EA_str == 'EA', getStaebe()[2].EA_str)
    T.wahr('kein symbolFehler', symbolFehler == nil, symbolFehler)
end)

fall('3 Fehlerbox symbolischer Modus', function()
    T.abschnitt('Fehlerbox: umbrechen, mit ESC schliessen, Sperre bleibt')
    leer({ pinned(node(0)), roller(node(2)) })
    stabZeichnen(1, 2, 'q*x')
    pcall(starteBerechnung)
    T.wahr('symbolFehler gesetzt', symbolFehler ~= nil, symbolFehler)
    T.wahr('Box offen', symbolFehlerOffen == true)
    T.wahr('Box gezeichnet', sichtbar('Symbolischer Modus nicht moeglich'))
    on.escapeKey()
    T.wahr('ESC: Box geschlossen', symbolFehlerOffen == false and not sichtbar('Symbolischer Modus nicht moeglich'))
    T.wahr('ESC: Fehler bleibt gespeichert', symbolFehler ~= nil)
    local ok, res = pcall(exportBiegelinienNeuToTI)
    T.wahr('Rand-LGS bleibt gesperrt', ok and res == false)
    pcall(starteBerechnung)
    T.wahr('neue Berechnung zeigt die Box wieder', sichtbar('Symbolischer Modus nicht moeglich'))
    -- lange Meldung wird umgebrochen und bleibt in der Box
    symbolFehler = 'Symbol EA kommt vor, aber Stab 12 hat EA als Zahl. EA fuer alle Staebe symbolisch setzen.'
    symbolFehlerOffen = true
    local b = platform.window:width()
    local boxW = math.min(b - 20, 300); local boxX = math.floor((b - boxW) / 2)
    local zeilen, drin = 0, true
    for _, e in ipairs(zeichne()) do
        if e.t ~= '[Esc]' and e.x == boxX + 8 and e.t ~= 'Symbolischer Modus nicht moeglich:' then
            zeilen = zeilen + 1
            if e.x + #e.t * 6 > boxX + boxW then drin = false end
        end
    end
    T.wahr('lange Meldung auf mehrere Zeilen umgebrochen', zeilen >= 2, zeilen)
    T.wahr('alle Zeilen innerhalb der Box', drin)
    on.escapeKey()
end)

fall('4 Kinematisch und Starrmodus', function()
    T.abschnitt('Warnungen kinematisch / Starrmodus: ESC schliesst, Auswahl bleibt')
    leer({ roller(node(0)), roller(node(2)) })
    stabZeichnen(1, 2)
    getKnoten()[2].last_x = 1
    pcall(starteBerechnung)
    T.wahr('System als kinematisch erkannt', uiZustand().warnungKinematisch == true)
    T.wahr('Warnung gezeichnet', sichtbar('System ist kinematisch!'))
    uiZustand({ auswahl = 1 })
    on.escapeKey()
    T.wahr('ESC: Warnung weg', uiZustand().warnungKinematisch == false and not sichtbar('System ist kinematisch!'))
    T.wahr('ESC schliesst nur die Warnung (Auswahl bleibt)', uiZustand().auswahl == 1)
    on.escapeKey()
    T.wahr('zweites ESC hebt die Auswahl auf', uiZustand().auswahl == nil)
    uiZustand({ warnungStarrBestimmt = true })
    T.wahr('Starrmodus-Warnung gezeichnet', sichtbar('Starrmodus & statisch unbestimmt!'))
    on.escapeKey()
    T.wahr('ESC: Starrmodus-Warnung weg', uiZustand().warnungStarrBestimmt == false and not sichtbar('Starrmodus'))
end)

fall('5 Menue ueber Warnung', function()
    T.abschnitt('Menue offen und Warnung: erst Menue, dann Warnung')
    leer({ pinned(node(0)), roller(node(2)) })
    stabZeichnen(1, 2)
    uiZustand({ warnungKinematisch = true }); menuOffen, menuTyp, menuSeite, menuZeile = true, 'obermenue', 1, 1
    on.escapeKey()
    T.wahr('1. ESC schliesst das Menue', menuOffen == false and uiZustand().warnungKinematisch == true)
    on.escapeKey()
    T.wahr('2. ESC schliesst die Warnung', uiZustand().warnungKinematisch == false)
end)

fall('6 Stabmenue starr', function()
    T.abschnitt('Stabmenue: biegesteif/dehnsteif schalten, EI/EA gesperrt, eigenes EA')
    T.wahr('Standard-EA dehnstarr ist ab Werk aus', STANDARD_DEHNSTARR == false)
    leer({ pinned(node(0)), roller(node(2)) })
    stabZeichnen(1, 2)
    local s = getStaebe()[1]
    local function stabmenue(zeile) menuOffen, menuTyp, menuIndex, menuSeite, menuZeile, eingabeModus = true, 'stab', 1, 1, zeile, false end
    stabmenue(2); on.enterKey()
    T.wahr('Zeile 2 schaltet biegesteif ein', s.biegesteif == true and eingabeModus == false)
    T.wahr('Menue: EI zeigt "starr"', sichtbarGenau('starr'))
    stabmenue(1); on.enterKey()
    T.wahr('EI-Eingabe gesperrt', eingabeModus == false)
    stabmenue(4); on.enterKey()
    T.wahr('Zeile 4 schaltet dehnsteif ein', s.dehnsteif == true)
    stabmenue(3); on.enterKey()
    T.wahr('EA-Eingabe gesperrt', eingabeModus == false)
    stabmenue(4); on.enterKey(); stabmenue(2); on.enterKey()
    T.wahr('beide wieder aus', not s.biegesteif and not s.dehnsteif)
    T.wahr('Menue: EI wieder als Wert', not sichtbarGenau('starr'))
    stabmenue(3); on.enterKey(); eingabeText = '5e9'; on.enterKey()
    T.wahr('eigenes EA gesetzt und als manuell markiert', s.EA == 5e9 and s.EA_manuell == true, tostring(s.EA))
    stabmenue(5); on.enterKey(); eingabeText = '2'; on.enterKey()
    T.wahr('Zeile 5 = Last q', s.q_str == '2', s.q_str)
    stabmenue(6); on.enterKey(); eingabeText = '3'; on.enterKey()
    T.wahr('Zeile 6 = Last n', s.n_str == '3', s.n_str)
    stabmenue(7); on.enterKey(); eingabeText = '4'; on.enterKey()
    T.wahr('Zeile 7 = Momentenlast m', s.m_str == '4', s.m_str)
    -- Standard-EA dehnstarr: eigener Wert ausgenommen; "Alle EA setzen" macht ihn wieder zum Standard
    randDehnstarr = true
    T.wahr('Stab mit eigenem EA nicht dehnsteif', stabDehnsteif(s) == false)
    stabmenue(4)
    T.wahr('Menue: dehnsteif "Nein"', sichtbarGenau('Nein'))
    obermenue(2, '1e10')
    T.wahr('Alle EA setzen: wieder Standard und dehnsteif', s.EA_manuell == nil and stabDehnsteif(s) == true)
    stabmenue(4)
    T.wahr('Menue: dehnsteif "Ja (Std.)"', sichtbarGenau('Ja (Std.)'))
    randDehnstarr = false
    menuOffen = false
end)

fall('7 Temperatur im Stabmenue', function()
    T.abschnitt('Stabmenue Seite 3: Temperatur als Text eingeben und anzeigen')
    leer({ pinned(node(0)), roller(node(2)) })
    stabZeichnen(1, 2)
    local s = getStaebe()[1]
    local function eingabe(zeile, text)
        menuOffen, menuTyp, menuIndex, menuSeite, menuZeile, eingabeModus = true, 'stab', 1, 3, zeile, false
        on.enterKey(); eingabeText = text; on.enterKey()
    end
    eingabe(5, 'dt'); eingabe(6, 'dt'); eingabe(7, 'a'); eingabe(8, 'h')
    T.wahr('Texte gespeichert', s.To_str == 'dt' and s.Tu_str == 'dt' and s.alpha_str == 'a' and s.h_str == 'h',
        tostring(s.To_str) .. ',' .. tostring(s.Tu_str) .. ',' .. tostring(s.alpha_str) .. ',' .. tostring(s.h_str))
    menuOffen, menuSeite = true, 3
    T.wahr('Menue zeigt "dt" statt 1', sichtbarGenau('dt'))
    T.wahr('Menue zeigt "a" und "h"', sichtbarGenau('a') and sichtbarGenau('h'))
    menuOffen = false
    pcall(starteBerechnung)
    T.wahr('symbolischer Modus ohne Fehler', symbolischer_modus == true and symbolFehler == nil, symbolFehler)
    T.wahr('Temperatur-Hinweis gezeichnet', sichtbar('Temperatur symbolisch'))
    on.escapeKey()
    T.wahr('ESC schliesst den Temperatur-Hinweis', not sichtbar('Temperatur symbolisch'))
end)

fall('8 Hinweise', function()
    T.abschnitt('Hinweisbox: Zahl-EI/EA neben symbolischen Steifigkeiten, h = 0, ESC')
    -- Klausur Aufgabe 4 ohne Gelenke: EI der senkrechten Staebe ist eine Zahl
    local function klausur4(gelenke)
        leer({ node(0, 0), node(2, 0), pinned(node(4, 0)), node(6, 0), pinned(node(6, -1)), pinned(node(6, 4)), node(10, 0) })
        local K = getKnoten()
        K[1].cm, K[1].cm_str = 3, '3*EA*l'
        K[2].last_y, K[2].last_y_str = 1, 'F'
        K[7].last_y, K[7].last_y_str = -1, '-F'
        if gelenke then K[5].gelenk, K[6].gelenk = true, true end
        local S = {}
        for i, p in ipairs({ { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 7 } }) do
            S[i] = erstelleStab(p[1], p[2]); S[i].biegesteif, S[i].dehnsteif = true, true
        end
        S[5] = erstelleStab(5, 4); S[5].EA, S[5].EA_str = 1, 'EA'
        S[6] = erstelleStab(4, 6); S[6].EA, S[6].EA_str = 2, '2*EA'
        if gelenke then S[5].gelenk_A, S[5].gelenk_B, S[6].gelenk_A, S[6].gelenk_B = true, true, true, true end
        setStaebe(S)
        pcall(starteBerechnung)
    end
    klausur4(false)
    T.wahr('ohne Gelenke: Hinweis EI Zahl fuer Stab 5, 6', hinweisMit('Stab 5, 6: EI ist eine Zahl'), table.concat(hinweisListe, ' | '))
    T.wahr('Hinweisbox gezeichnet', sichtbarGenau('Hinweis:'))
    on.escapeKey()
    T.wahr('ESC schliesst die Hinweisbox', hinweisOffen == false and not sichtbarGenau('Hinweis:'))
    pcall(starteBerechnung)
    T.wahr('gleiche Eingaben: Box bleibt zu', hinweisOffen == false)
    klausur4(true)
    T.wahr('mit Gelenken: kein EI-Hinweis', not hinweisMit('EI ist eine Zahl'), table.concat(hinweisListe, ' | '))
    -- Zweigelenkrahmen mit EI symbolisch, EA Zahl: Hinweis EA, mit Standard-EA dehnstarr keiner
    local function portal(dehnstarr)
        leer({ pinned(node(0, 1)), node(0, 0), node(1, 0), pinned(node(1, 1)) })
        randDehnstarr = dehnstarr or false
        local K = getKnoten(); K[2].last_x, K[2].last_x_str = 1, 'H'
        local S = {}
        for i = 1, 3 do S[i] = erstelleStab(i, i + 1); S[i].EI, S[i].EI_str = 1, 'EI' end
        setStaebe(S)
        pcall(starteBerechnung)
    end
    portal()
    T.wahr('Rahmen: Hinweis EA Zahl', hinweisMit('EA ist eine Zahl'), table.concat(hinweisListe, ' | '))
    portal(true)
    T.wahr('Rahmen mit Standard-EA dehnstarr: kein Hinweis', #hinweisListe == 0, table.concat(hinweisListe, ' | '))
    randDehnstarr = false
    -- Einfeldtraeger mit q und EI symbolisch: N = 0, EA spielt keine Rolle -> kein Hinweis
    leer({ pinned(node(0)), roller(node(2)) })
    stabZeichnen(1, 2, 'q'); getStaebe()[1].EI_str = 'EI'
    pcall(starteBerechnung)
    T.wahr('Einfeldtraeger: kein Hinweis', #hinweisListe == 0 and not hinweisOffen, table.concat(hinweisListe, ' | '))
    -- Temperatur oben 10, unten 0, h = 0: nur mittlere Erwaermung
    leer({ pinned(node(0)), roller(node(2)) })
    stabZeichnen(1, 2)
    local s = getStaebe()[1]; s.To, s.Tu, s.h = 10, 0, 0
    pcall(starteBerechnung)
    T.wahr('h = 0 und To ~= Tu: Hinweis', hinweisMit('aber h = 0'), table.concat(hinweisListe, ' | '))
    s.Tu = 10
    pcall(starteBerechnung)
    T.wahr('To = Tu: kein Hinweis', not hinweisMit('aber h = 0'))
end)

fall('9 Schalter Methode', function()
    T.abschnitt('Obermenue Seite 4: Methode fuer starre Staebe')
    T.wahr('ab Werk: direkt', STANDARD_DIREKT == true)
    leer({ pinned(node(0)), roller(node(2)) })
    randStarrDirekt = true
    menuOffen, menuTyp, menuSeite, menuZeile, eingabeModus = true, 'obermenue', 4, 4, false
    T.wahr('Menue zeigt "direkt"', sichtbarGenau('direkt'))
    on.enterKey()
    T.wahr('Enter schaltet auf Grenzwert', randStarrDirekt == false and sichtbarGenau('Grenzwert'))
    on.enterKey()
    T.wahr('nochmal Enter: wieder direkt', randStarrDirekt == true)
    menuOffen = false
end)

T.ende('Oberflaeche Tragwerk')
