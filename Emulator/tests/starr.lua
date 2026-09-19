-- Starre Staebe je Stab (Stabmenue): biegesteif (EI -> unendlich), dehnsteif (EA -> unendlich).
-- Rand-LGS exakt gegen Handrechnung; FEM (exakte Zwangsbedingungen) ueber Verschiebungen und Stabendkraefte
-- (Betraege, Vorzeichen der FEM-Endkraefte sind Stabend-Konvention).
-- Aufruf: luajit Emulator/tests/starr.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller = T.node, T.fixed, T.pinned, T.roller

local function str(e) return tostring(T.evs(e)) end
local function num(e) return T.ev(e) end
local function check(label, expr, soll)
    local diff = num('expand((' .. expr .. ')-(' .. soll .. '))')
    local ok = type(diff) == 'number' and math.abs(diff) < 1e-12
    T.pruef(ok, string.format('%-44s ist=%s  soll=%s', label, str(expr), soll))
end
local function enthaelt(label, expr, muster, soll)
    local s = str(expr)
    local hat = s:find(muster, 1, true) ~= nil
    T.pruef(hat == (soll ~= false), string.format('%-44s %s "%s": %s', label, soll == false and 'ohne' or 'mit', muster, s))
end
-- FEM-Wert (Naeherung) mit absoluter Toleranz
local function fem(label, ist, soll, tol)
    local ok = type(ist) == 'number' and math.abs(ist - soll) <= (tol or 1e-9)
    T.pruef(ok, string.format('%-44s soll %-12.6g ist %s', label, soll, tostring(ist)))
end
local function bar(a, b, f) return T.bar(a, b, f, { EI = 1e8, EA = 1e10 }) end
local function setup(title, K, S)
    T.abschnitt(title)
    if not T.rechne(K, S) then return false end
    if symbolFehler then T.pruef(false, 'unerwarteter symbolFehler: ' .. symbolFehler); return false end
    if not T.randLGS() then return false end
    T.info('   randinfo = ' .. str('randinfo'))
    for i = 1, #S do T.info('   wneu' .. i .. '(x) = ' .. str('wneu' .. i .. '(x)') .. '   uneu' .. i .. '(x) = ' .. str('uneu' .. i .. '(x)')) end
    return true
end
local function feder(k, c) k.cy = c; return k end

local fall = T.fall

fall('1 Kragarm biegesteif', function()
    -- statisch bestimmt: EI*w haengt nicht von EI ab und bleibt endlich, w selbst ist 0
    local K = { fixed(node(0)), node(2) }
    K[2].last_y = 1
    local S = { bar(1, 2, { biegesteif = true }) }
    if setup('Kragarm L = 2, F = 1 am Ende, biegesteif', K, S) then
        check('wneu1(x) = EI*w = F (L x^2/2 - x^3/6)', 'wneu1(x)', 'x^2-x^3/6')
        enthaelt('randinfo', 'randinfo', 'biegesteif (EI->unendlich): Stab 1')
        enthaelt('randinfo: wneu1 bleibt EI*w', 'randinfo', 'wneu1(x)=w1(x)', false)
        fem('FEM: Durchbiegung am Ende = 0', getStaebe()[1].v_local[5], 0)
        fem('FEM: |M Einspannung| = F L = 2', math.abs(getStaebe()[1].s_local[3]), 2)
        fem('FEM: |Q| = F = 1', math.abs(getStaebe()[1].s_local[2]), 1)
    end
end)

fall('2 Starrer Balken auf Federn', function()
    -- drei gleiche Federn c = 1, q = 1 auf 2 m: starrer Balken senkt sich gleichmaessig um qL/(3c) = 2/3
    local K = { feder(node(0), 1), feder(node(1), 1), feder(node(2), 1) }
    K[1].lager_x = true
    local S = { bar(1, 2, { q = 1, q_str = '1', biegesteif = true }), bar(2, 3, { q = 1, q_str = '1', biegesteif = true }) }
    if setup('starrer Balken auf drei Federn, q = 1', K, S) then
        check('wneu1(x) = w1 = 2/3', 'wneu1(x)', '2/3')
        check('wneu2(x) = w2 = 2/3', 'wneu2(x)', '2/3')
        enthaelt('randinfo', 'randinfo', 'wneu1(x)=w1(x), da EI*w unendlich')
        local S1, S2 = getStaebe()[1], getStaebe()[2]
        fem('FEM: w Knoten 1', S1.v_local[2], 2 / 3)
        fem('FEM: w Knoten 2', S1.v_local[5], 2 / 3)
        fem('FEM: w Knoten 3', S2.v_local[5], 2 / 3)
        fem('FEM: |M Mitte| = 2/3*1 - 1/2 = 1/6', math.abs(S1.s_local[6]), 1 / 6)
        fem('FEM: |Q links| = Federkraft 2/3', math.abs(S1.s_local[2]), 2 / 3)
    end
    -- Gegenprobe: ohne Schalter und mit weichem Balken (EI = 1) ist die Mitte tiefer als die Enden
    local K2 = { feder(node(0), 1), feder(node(1), 1), feder(node(2), 1) }
    K2[1].lager_x = true
    local S2 = { bar(1, 2, { q = 1, q_str = '1', EI = 1 }), bar(2, 3, { q = 1, q_str = '1', EI = 1 }) }
    if setup('Gegenprobe: weicher Balken EI = 1', K2, S2) then
        T.wahr('w(Mitte) > w(Rand)', num('wneu2(0)') > num('wneu1(0)') + 1e-6, str('wneu2(0)') .. ' / ' .. str('wneu1(0)'))
        enthaelt('randinfo', 'randinfo', 'keine starren Staebe')
    end
end)

fall('3 Rahmenecke Stuetze starr', function()
    -- Stuetze biege- und dehnsteif, eingespannt: Ecke unverschieblich und unverdreht,
    -- Riegel wirkt wie Einspannung-Rolle: w = q x^2 (L-x)(3L-2x)/(48 EI), Eckmoment qL^2/8
    local K = { fixed(node(0, 0)), node(0, -2), roller(node(2, -2)) }
    local S = { bar(1, 2, { biegesteif = true, dehnsteif = true }), bar(2, 3, { q = 1, q_str = '1' }) }
    if setup('Rahmenecke, Stuetze biege- und dehnsteif', K, S) then
        check('wneu2(x) = x^2 (2-x)(6-2x)/48', 'wneu2(x)', 'x^2*(2-x)*(6-2*x)/48')
        check('wneu2(1) = 1/12', 'wneu2(1)', '1/12')
        check('wneu1(x) = EI*w = M x^2/2 = x^2/4', 'wneu1(x)', 'x^2/4')
        check('uneu1(x) = N1 x = -5x/4', 'uneu1(x)', '-5*x/4')
        check('uneu2(x) = 0', 'uneu2(x)', '0')
        enthaelt('randinfo', 'randinfo', 'dehnsteif (EA->unendlich): Stab 1')
        enthaelt('randinfo', 'randinfo', 'biegesteif (EI->unendlich): Stab 1')
        local S2 = getStaebe()[2]
        fem('FEM: Ecke w = 0', S2.v_local[2], 0)
        fem('FEM: Ecke phi = 0', S2.v_local[3], 0)
        fem('FEM: |M Ecke Riegel| = qL^2/8 = 1/2', math.abs(S2.s_local[3]), 1 / 2)
        fem('FEM: |M Stuetze oben| = 1/2', math.abs(getStaebe()[1].s_local[6]), 1 / 2)
        fem('FEM: |M Stuetze unten| = 1/2', math.abs(getStaebe()[1].s_local[3]), 1 / 2)
        fem('FEM: |N Stuetze| = 5/4', math.abs(getStaebe()[1].s_local[1]), 5 / 4)
        fem('FEM: |Rolle| = 3qL/8 = 3/4', math.abs(getKnoten()[3].Ry_glob), 3 / 4)
    end
end)

fall('4 Dehnsteif je Stab', function()
    local K = { pinned(node(0)), node(1), pinned(node(2)) }
    K[2].last_x = 1
    local S = { bar(1, 2, { dehnsteif = true }), bar(2, 3, { EA = 1 }) }
    if setup('Festlager-Festlager, Stab 1 dehnsteif, Stab 2 EA = 1', K, S) then
        check('uneu1(x) = N1 x = x', 'uneu1(x)', 'x')
        check('uneu2(x) = 0', 'uneu2(x)', '0')
        fem('FEM: u Mitte = 0', getStaebe()[1].v_local[4], 0)
        fem('FEM: |N1| = 1', math.abs(getStaebe()[1].s_local[1]), 1)
        fem('FEM: N2 = 0', getStaebe()[2].s_local[1], 0)
    end
end)

fall('5 Symbolisch', function()
    -- Kragarm 2l, q; Stab 1 mit EI symbolisch, Stab 2 biegesteif (ohne EI): kein symbolFehler
    local K = { fixed(node(0)), node(1), node(2) }
    local S = { T.bar(1, 2, { EI = 1, EI_str = 'EI', EA = 1e10, q = 1, q_str = 'q' }),
                T.bar(2, 3, { EI = 1e8, EA = 1e10, q = 1, q_str = 'q', biegesteif = true }) }
    if setup('Kragarm 2l, q, zweite Haelfte biegesteif', K, S) then
        check('wneu1(l) = 17/24 q l^4', 'wneu1(l)', '17/24*q*l^4')
        check('wneu1(x) Formel', 'wneu1(x)', 'q*(2*l-x)^4/24+4/3*q*l^3*x-2/3*q*l^4')
        check('wneu2(x) = w2 = q l^3 (17 l/24 + 7 x/6)/EI', 'wneu2(x)', 'q*l^3*(17*l/24+7*x/6)/ei')
        enthaelt('randinfo', 'randinfo', 'wneu2(x)=w2(x)')
    end
end)

fall('6 Temperatur', function()
    -- freie Temperaturdehnung bzw. -kruemmung eines starren Einfeldtraegers: keine Schnittgroessen
    local K = { pinned(node(0)), roller(node(2)) }
    local S = { bar(1, 2, { dehnsteif = true, To = 10, Tu = 10, alpha = 1e-5, h = 0.2 }) }
    if setup('Einfeldtraeger dehnsteif, epsT = 1e-4', K, S) then
        check('uneu1(x) = u1 = epsT x', 'uneu1(x)', 'x/10000')
        fem('FEM: Laengenaenderung = epsT L', getStaebe()[1].v_local[4] - getStaebe()[1].v_local[1], 2e-4, 1e-15)
        fem('FEM: N = 0', getStaebe()[1].s_local[1], 0)
    end
    local S2 = { bar(1, 2, { biegesteif = true, To = 0, Tu = 20, alpha = 1e-5, h = 0.2 }) }
    if setup('Einfeldtraeger biegesteif, kappaT = 1e-3', { pinned(node(0)), roller(node(2)) }, S2) then
        -- w = -kappaT x^2/2 + kappaT L/2 x
        check('wneu1(x) = w1 = kappaT (x - x^2/2)', 'wneu1(x)', '(x-x^2/2)/1000')
        enthaelt('randinfo', 'randinfo', 'wneu1(x)=w1(x)')
        fem('FEM: |phi_A| = kappaT L/2', math.abs(getStaebe()[1].v_local[3]), 1e-3, 1e-15)
        fem('FEM: M_A = 0', getStaebe()[1].s_local[3], 0)
        fem('FEM: M_B = 0', getStaebe()[1].s_local[6], 0)
    end
end)

T.ende('Starre Staebe')
