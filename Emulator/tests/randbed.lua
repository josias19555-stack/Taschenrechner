-- Lesbarkeit der exportierten Randbedingungen:
--   * bereits bekannte Groessen (meist 0) stehen als Wert in der Bedingung, nicht als fremder Name
--   * randbed wird nach Biegelinie (w) und Laengslinie (u) gruppiert, wenn das moeglich ist
--   * die Ergebnisse muessen dabei unveraendert richtig bleiben (Vergleich mit der FEM)
-- Aufruf: luajit Emulator/tests/randbed.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller, ev = T.node, T.fixed, T.pinned, T.roller, T.ev

-- randbed als Liste von Strings
local function bedingungen()
    local rb = tostring(T.evs('randbed'))
    local liste = {}
    for t in rb:gmatch('"([^"]*)"') do liste[#liste + 1] = t end
    return liste
end

local function enthaelt(liste, muster)
    for _, t in ipairs(liste) do if t:find(muster, 1, true) then return true end end
    return false
end

local function zeige(liste)
    for i, t in ipairs(liste) do T.info(string.format('   %2d  %s', i, t)) end
end

-- Stabenden gegen die FEM: der lesbare Export muss dieselbe Loesung liefern
local function pruefeGegenFEM(tol)
    for i, s in ipairs(getStaebe()) do
        local k1, k2 = getKnoten()[s.k1], getKnoten()[s.k2]
        local L = math.sqrt((k2.x - k1.x) ^ 2 + (k2.y - k1.y) ^ 2)
        T.zahl('Stab ' .. i .. ' w(0)', ev('wv' .. i .. '(0)'), s.v_local[2] or 0, tol or 1e-8)
        T.zahl('Stab ' .. i .. ' w(L)', ev('wv' .. i .. '(' .. L .. ')'), s.v_local[5] or 0, tol or 1e-8)
        T.zahl('Stab ' .. i .. ' u(0)', ev('uv' .. i .. '(0)'), s.v_local[1] or 0, tol or 1e-8)
        T.zahl('Stab ' .. i .. ' u(L)', ev('uv' .. i .. '(' .. L .. ')'), s.v_local[4] or 0, tol or 1e-8)
    end
end

local fall = T.fall

fall('1 Bekannte Groessen eingesetzt', function()
    T.abschnitt('Rahmenecke: Stab 2 dehnstarr und gehalten, also u2 = 0 -> "w1(x1=2)=0" statt "=u2(...)"')
    local K = { node(0, 0), node(2, 0), fixed(node(2, 2)) }
    K[1].last_y = 1
    local S = { T.bar(1, 2, { EI = 10, EA = 100 }), T.bar(2, 3, { EI = 10, EA = 100, dehnsteif = true }) }
    if not T.rechne(K, S, { starrDirekt = true }) then return end
    if not T.randLGS() then return end
    local rb = bedingungen()
    zeige(rb)
    T.wahr('w1 am Knoten 2 steht mit Wert 0 da', enthaelt(rb, 'w1(x1=2)=0'), table.concat(rb, ' | '))
    T.wahr('kein Verweis auf u2 in dieser Bedingung', not enthaelt(rb, 'w1(x1=2)=u2'), table.concat(rb, ' | '))
    T.wahr('Biegelinie allein loesbar gemeldet',
        tostring(T.evs('randinfo')):find('Biegelinie w ohne Laengslinie', 1, true) ~= nil, tostring(T.evs('randinfo')))
    T.wahr('Gruppenueberschrift vorhanden', enthaelt(rb, 'Biegelinie w: diese genuegen'), table.concat(rb, ' | '))
    -- Handrechnung: phi(Ecke) = F*L*L/EI = 2*2/10 = 0.4; w(Spitze) = F*L^3/(3EI) + phi*L
    T.zahl('w1(0) = F L^3/(3EI) + phi L', ev('wv1(0)'), 8 / 30 + 0.4 * 2, 1e-9)
    pruefeGegenFEM()
end)

fall('2 Biege- und Laengslinie unabhaengig', function()
    T.abschnitt('gerader Balken mit q und n: w und u haengen nicht zusammen')
    local K = { fixed(node(0, 0)), node(2, 0), roller(node(4, 0)) }
    local S = { T.bar(1, 2, { q = 1, q_str = '1', n = 1, n_str = '1' }), T.bar(2, 3, { q = 1, q_str = '1' }) }
    if not T.rechne(K, S) then return end
    if not T.randLGS() then return end
    local rb = bedingungen()
    zeige(rb)
    T.wahr('Gruppe Biegelinie', enthaelt(rb, 'nur Biegelinie w'), table.concat(rb, ' | '))
    T.wahr('Gruppe Laengslinie', enthaelt(rb, 'nur Laengslinie u'), table.concat(rb, ' | '))
    T.wahr('randinfo meldet die Unabhaengigkeit',
        tostring(T.evs('randinfo')):find('unabhaengig', 1, true) ~= nil, tostring(T.evs('randinfo')))
    -- in der w-Gruppe darf keine u-Groesse mit Namen stehen und umgekehrt
    local gruppe = nil
    for _, t in ipairs(rb) do
        if t:find('nur Biegelinie', 1, true) then gruppe = 'w'
        elseif t:find('nur Laengslinie', 1, true) then gruppe = 'u'
        elseif gruppe == 'w' then
            T.wahr('w-Gruppe ohne u-Groesse: ' .. t, not t:find('u%d'), t)
        elseif gruppe == 'u' then
            T.wahr('u-Gruppe ohne w-Ableitung: ' .. t, not t:find("EIw"), t)
        end
    end
    pruefeGegenFEM()
end)

fall('3 Gekoppeltes System bleibt ungeteilt', function()
    T.abschnitt('Zweigelenkrahmen ohne starre Staebe: Normalkraft und Biegung haengen zusammen')
    local K = { pinned(node(0, 2)), node(0, 0), node(2, 0), pinned(node(2, 2)) }
    K[2].last_x = 1
    local S = {}
    for i = 1, 3 do S[i] = T.bar(i, i + 1, { EI = 10, EA = 100 }) end
    if not T.rechne(K, S) then return end
    if not T.randLGS() then return end
    local rb = bedingungen()
    T.wahr('keine Gruppenueberschrift', not enthaelt(rb, '---'), table.concat(rb, ' | '))
    T.wahr('randinfo ohne Trennungshinweis',
        tostring(T.evs('randinfo')):find('Laengslinie u', 1, true) == nil, tostring(T.evs('randinfo')))
    pruefeGegenFEM()
end)

fall('4 Klausursystem mit starrem Balken', function()
    T.abschnitt('starrer Balken auf Pendelstaeben: Bedingungen bleiben richtig, Werte eingesetzt')
    local K = { node(0, 0), node(2, 0), pinned(node(4, 0)), node(6, 0), pinned(node(6, -1)), pinned(node(6, 4)), node(10, 0) }
    K[1].cm = 3
    K[2].last_y = 1
    K[7].last_y = -1
    K[5].gelenk, K[6].gelenk = true, true
    local function starr() return { biegesteif = true, dehnsteif = true, EI = 1e8, EA = 1e10 } end
    local S = { T.bar(1, 2, starr()), T.bar(2, 3, starr()), T.bar(3, 4, starr()), T.bar(4, 7, starr()),
        T.bar(5, 4, { EA = 1, EI = 1e8, gelenk_A = true, gelenk_B = true }),
        T.bar(4, 6, { EA = 2, EI = 1e8, gelenk_A = true, gelenk_B = true }) }
    if not T.rechne(K, S, { starrDirekt = true }) then return end
    if not T.randLGS() then return end
    local rb = bedingungen()
    zeige(rb)
    T.wahr('Laengsverschiebung des starren Balkens steht als 0 da', enthaelt(rb, 'u1(x1=2)=0'), table.concat(rb, ' | '))
    pruefeGegenFEM(1e-6)
end)

T.ende('Randbedingungen lesbar')
