-- Regressionstests fuer Biegelinieneu.lua mit Handrechen-Sollwerten.
-- Aufruf:  luajit Emulator/test_regression.lua
--          (anderes Skript testen: Umgebungsvariable BIEGELINIE=<pfad>)
-- Pruefungen mit bekannt = true sind dokumentierte, noch offene Fehler: sie werden
-- als "BEKANNT" gemeldet und lassen den Lauf nicht scheitern. Sobald ein solcher
-- Fall stimmt, meldet der Test "BEHOBEN" -> dann das true entfernen.

io.stdout:setvbuf('no')
local runner_dir = (debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\")
local cas = dofile(runner_dir .. 'cas_bridge.lua')
cas.start()
local write = io.write
write('Teste ' .. cas.loadBiegelinie(nil, '_G.neuCasText = neuCasText; _G.neuZahl = neuZahl') .. '\n')
print = function() end -- Statusausgaben des Skripts unterdruecken

local results = { ok = 0, fail = 0, known = 0, fixed = 0 }

local function check(name, actual, expected, known, tol)
    tol = tol or 1e-6
    local good = type(actual) == 'number' and math.abs(actual - expected) <= tol * math.max(1, math.abs(expected))
    local status
    if good and known then status = 'BEHOBEN'; results.fixed = results.fixed + 1
    elseif good then status = 'OK'; results.ok = results.ok + 1
    elseif known then status = 'BEKANNT'; results.known = results.known + 1
    else status = 'FEHLER'; results.fail = results.fail + 1 end
    write(string.format('  %-8s %-58s ist %-12s soll %.6g\n', status, name, tostring(actual), expected))
end

-- Jeder Fall laeuft einzeln: ein Absturz zaehlt als FEHLER, die anderen Faelle laufen weiter
local function case(title, fn)
    write('\n' .. title .. '\n')
    local ok, err = pcall(fn)
    if not ok then
        results.fail = results.fail + 1
        write('  FEHLER   Absturz: ' .. (tostring(err):gsub('\n.*', '')) .. '\n')
    end
end

local function ev(expression)
    local ok, value = pcall(math.eval, 'approx(' .. expression .. ')')
    return ok and value or ('Fehler: ' .. tostring(value))
end

local function node(x, y)
    local k = erstelleKnoten(x, y or 0)
    k.x_str, k.y_str = tostring(x), tostring(y or 0)
    return k
end

local function bar(a, b, fields)
    local s = erstelleStab(a, b)
    s.EI, s.EA = 1, 1e8
    for key, value in pairs(fields or {}) do s[key] = value end
    return s
end

local function solve(nodes, bars)
    cas.reset()
    autoKGV, zeigeN, sym_vars, symbolischer_modus = false, false, {}, false
    randDehnstarr = false   -- Rand-LGS mit endlichem EA (Vergleich mit FEM)
    setKnoten(nodes); setStaebe(bars)
    starteBerechnung()
    return getKnoten(), getStaebe()
end

local function fixed(k) k.lager_x, k.lager_y, k.lager_m = true, true, true; return k end
local function pinned(k) k.lager_x, k.lager_y = true, true; return k end
local function roller(k) k.lager_y = true; return k end

-- Q und M wie in on.paint (Diagrammformel) am Stuetzpunkt j auswerten
local function diagram(s, j, L)
    local x = j / ptsBiegelinie * L
    local Q0, M0 = -s.s_local[2], -s.s_local[3]
    local qA, qB = s.q + s.q_A, s.q + s.q_B
    if s.q_in_cas then qA, qB = 0, 0 end
    local Q = Q0 - (qA * x + (qB - qA) * x ^ 2 / (2 * L)) - ((s.Q_cas_pts and s.Q_cas_pts[j + 1]) or 0)
    local M = M0 + Q0 * x - s.m * x - (qA * x ^ 2 / 2 + (qB - qA) * x ^ 3 / (6 * L)) - ((s.M_cas_pts and s.M_cas_pts[j + 1]) or 0)
    return Q, M
end

case('[A] Kragarm L=2, q=1, EI=1: EI*w(Ende) = qL^4/8 = 2   (Fehler 1: Vorzeichen Z. 846)', function()
    solve({ fixed(node(0)), node(2) }, { bar(1, 2, { q = 1, q_str = '1' }) })
    exportBiegelinienToTI()
    check('Stab Einspannung->Ende: v_EI_stab1(2)', ev('v_EI_stab1(2)'), 2)
    solve({ node(0), fixed(node(2)) }, { bar(1, 2, { q = 1, q_str = '1' }) })
    exportBiegelinienToTI()
    check('Stab Ende->Einspannung: v_EI_stab1(0)', ev('v_EI_stab1(0)'), 2)
end)

case('[B] Gerbertraeger Einsp. x=0, Gelenk x=2, Rolle x=4, q=1   (Fehler 2: Gelenk-Zweig Z. 849)', function()
    local k = { fixed(node(0)), node(2), roller(node(4)) }
    k[2].gelenk = true
    solve(k, { bar(1, 2, { q = 1, q_str = '1' }), bar(2, 3, { q = 1, q_str = '1' }) })
    exportBiegelinienToTI()
    check('v_EI_stab1(2) am Gelenk = qL^4/8 + F L^3/3', ev('v_EI_stab1(2)'), 2 + 8 / 3)
    check('v_EI_stab2(0) am Gelenk', ev('v_EI_stab2(0)'), 2 + 8 / 3)
    check('v_EI_stab2(2) am Rollenlager', ev('v_EI_stab2(2)'), 0)
end)

case('[C] Einfeldtraeger L=4, Trapezlast q_A=q_B=1 aus dem Menue   (Fehler 3: Diagramme)', function()
    local _, s = solve({ pinned(node(0)), roller(node(4)) },
        { bar(1, 2, { q_A = 1, q_A_str = '1', q_B = 1, q_B_str = '1' }) })
    local _, M_mid = diagram(s[1], ptsBiegelinie / 2, 4)
    local Q_end = diagram(s[1], ptsBiegelinie, 4)
    check('Diagramm M(2) = qL^2/8', M_mid, 2)
    check('Diagramm Q(4) = -qL/2', Q_end, -2)
end)

case('[D] Einfeldtraeger L=4, q(x)=x plus Trapez q_A=q_B=1   (Fehler 3 Rechenkern, Fehler 6)', function()
    local k = solve({ pinned(node(0)), roller(node(4)) },
        { bar(1, 2, { q_str = 'x', q = 0, q_A = 1, q_A_str = '1', q_B = 1, q_B_str = '1' }) })
    check('Auflager A = 8/3 + 2', math.abs(k[1].R_eta), 8 / 3 + 2)
    check('Auflager B = 16/3 + 2', math.abs(k[2].R_eta), 16 / 3 + 2)
end)

case('[E] Einfeldtraeger L=4, q(x)=exp(x/4)   (Fehler 5: x-Ersetzung)', function()
    local k = solve({ pinned(node(0)), roller(node(4)) }, { bar(1, 2, { q_str = 'exp(x/4)', q = 0 }) })
    check('Auflager B = (1/4)*int(x*e^(x/4),0,4) = 4', math.abs(k[2].R_eta), 4)
    check('Auflager A = 4(e-1) - 4', math.abs(k[1].R_eta), 4 * (math.exp(1) - 1) - 4)
end)

-- Symbolischer Modus: Koeffizient eines symb_start-Ausdrucks (alle Symbole = 1 gesetzt)
local function symbWert(expr)
    local numeric = tostring(expr or '0'):gsub('%f[%a_][%a_][%w_]*', '(1)')
    return ev(numeric)
end

local function solveSymb(nodes, bars, raster)
    rasterMass, rasterMass_str = raster or 1, nil
    local ok, err = pcall(solve, nodes, bars)
    rasterMass = 1
    if not ok then error(err, 0) end
    return getKnoten(), getStaebe()
end

case('[F] Symbolisch: Einfeldtraeger 4 m, F am Mittelknoten, Raster 0,5 m -> l = 0,5 m', function()
    local k = { pinned(node(0)), node(2), roller(node(4)) }
    k[2].last_y, k[2].last_y_str = 1, 'F'
    local _, s = solveSymb(k, { bar(1, 2), bar(2, 3) }, 0.5)
    check('kein Fehler im symbolischen Modus', symbolFehler == nil and 1 or 0, 1)
    check('Referenzlaenge symbLDummy = Raster', symbLDummy, 0.5)
    write('           Stablaenge 2 m -> ' .. symbLaenge(2) .. ', M(Mitte) = ' .. tostring(s[2].symb_start.M) .. '\n')
    check('Stablaenge 2 m = 4*l', symbLaenge(2) == '(4*l)' and 1 or 0, 1)
    check('|M(Mitte)| = F*L/4 = F*1 m = 2*F*l -> Koeffizient 2', math.abs(symbWert(s[2].symb_start.M)), 2)
end)

case('[G] Symbolisch: Eigengewicht gy = g auf Einfeldtraeger 4 m (Raster 1)', function()
    local _, s = solveSymb({ pinned(node(0)), roller(node(4)) }, { bar(1, 2, { gy = 1, gy_str = 'g' }) })
    check('kein Fehler im symbolischen Modus', symbolFehler == nil and 1 or 0, 1)
    write('           V(A) = ' .. tostring(s[1].symb_start.V) .. '\n')
    check('|V(A)| = g*L/2 = 2*g*l (war vorher 0)', math.abs(symbWert(s[1].symb_start.V)), 2)
end)

case('[H] Symbolisch: nicht abbildbare Eingaben muessen einen Fehler melden', function()
    solveSymb({ pinned(node(0)), roller(node(4)) }, { bar(1, 2, { q = 1, q_str = 'q', To = 10, Tu = 20, h = 0.5 }) })
    write('           Meldung: ' .. tostring(symbolFehler) .. '\n')
    -- Temperatur ist im symbolischen Modus inzwischen erlaubt (Export symbolisch, Hinweis zu den Diagrammen)
    check('Temperatur -> kein Fehler, Hinweis offen', (symbolFehler == nil and hinweisOffen) and 1 or 0, 1)
    solveSymb({ pinned(node(0)), roller(node(4)) }, { bar(1, 2, { q = 1, q_str = 'q', To = 1, To_str = 'dt*x', Tu = 20, h = 0.5 }) })
    write('           Meldung: ' .. tostring(symbolFehler) .. '\n')
    check('Temperatur f(x) -> Fehler', symbolFehler and symbolFehler:find('Temperatur') and 1 or 0, 1)
    solveSymb({ pinned(node(0)), roller(node(4)) }, { bar(1, 2, { q_str = 'q*x', q = 0 }) })
    write('           Meldung: ' .. tostring(symbolFehler) .. '\n')
    check('Lastfunktion q*x -> Fehler', symbolFehler and symbolFehler:find('Lastfunktion') and 1 or 0, 1)
    local k = { pinned(node(0)), node(2), roller(node(4)) }
    k[2].x_str = 'a'; k[3].x_str = 'a+2'; k[2].last_y, k[2].last_y_str = 1, 'F'
    solveSymb(k, { bar(1, 2), bar(2, 3) })
    write('           Meldung: ' .. tostring(symbolFehler) .. '\n')
    check('Koordinate a+2 -> Fehler', symbolFehler and symbolFehler:find('Vielfaches') and 1 or 0, 1)
    solveSymb({ pinned(node(0)), roller(node(4)) }, { bar(1, 2, { q = 1, q_str = 'q' }) })
    check('reine Streckenlast q -> kein Fehler', symbolFehler == nil and 1 or 0, 1)
end)

-- Vergleich Rand-LGS (wneu/uneu) gegen den FEM-Referenzexport (v_EI_stab, v_local) an Stabenden und Drittelspunkten
local function rlVergleich(name, nodes, bars)
    casToleranz = 9   -- Referenzexport rundet auf casToleranz Stellen
    local K, S = solve(nodes, bars)
    exportBiegelinienToTI()
    local ok = exportBiegelinienNeuToTI()
    casToleranz = 5
    check(name .. ': Rand-LGS loesbar', ok and 1 or 0, 1)
    if not ok then return end
    for i, s in ipairs(S) do
        local k1, k2 = K[s.k1], K[s.k2]
        local L = math.sqrt((k2.x - k1.x) ^ 2 + (k2.y - k1.y) ^ 2)
        for _, t in ipairs({ 1 / 3, 1 }) do
            local x = t * L
            check(string.format('%s: wneu%d(%.3g) = v_EI_stab%d', name, i, x, i), ev('wneu' .. i .. '(' .. x .. ')-v_EI_stab' .. i .. '(' .. x .. ')'), 0, nil, 1e-5)
        end
        check(string.format('%s: uneu%d(L) = EA*u_b', name, i), ev('uneu' .. i .. '(' .. L .. ')') - (s.v_local[4] or 0) * s.EA, 0, nil, 1e-5)
    end
end

case('[I] FEM-Modellfehler: konstantes Streckenmoment, gedrehtes Lager, gedrehte Feder', function()
    -- Kragarm L=2, m=1, EI=1: exakt EI*w(L) = -m*L^3/3 (vorher -2 durch Endmomente -mL/2 statt Kraeften -+m)
    solve({ fixed(node(0)), node(2) }, { bar(1, 2, { m = 1, m_str = '1' }) })
    exportBiegelinienToTI()
    check('Kragarm m=1: v_EI_stab1(2) = -8/3', ev('v_EI_stab1(2)'), -8 / 3)
    -- Rollenlager um 30 Grad gedreht: Knoten gleitet entlang (cos30, -sin30) (Zeichnung); Last Fy=-1 hat Anteil +0.5 darauf
    local k = { fixed(node(0)), node(4) }; k[2].lager_y = true; k[2].winkel = 30; k[2].last_y = -1
    local _, s = solve(k, { bar(1, 2) })
    check('Rollenlager 30 Grad: u_b > 0 (Lastanteil +0.5 in Gleitrichtung)', s[1].v_local[4] > 0 and 1 or 0, 1)
    check('Rollenlager 30 Grad: v_b = -tan(30)*u_b (Gleitrichtung)', s[1].v_local[5] + math.tan(math.rad(30)) * s[1].v_local[4], 0, nil, 1e-9)
    -- Feder cx um 90 Grad gedreht wirkt vertikal: gleiche Loesung wie cy ohne Drehung
    local ka = { fixed(node(0)), node(4) }; ka[2].cx = 3; ka[2].f_winkel = 90; ka[2].last_y = -1
    local _, sa = solve(ka, { bar(1, 2) }); local va = sa[1].v_local[5]
    local kb = { fixed(node(0)), node(4) }; kb[2].cy = 3; kb[2].last_y = -1
    local _, sb = solve(kb, { bar(1, 2) })
    check('Feder cx/f_winkel=90 == Feder cy', va - sb[1].v_local[5], 0, nil, 1e-9)
end)

case('[J] Rand-LGS gegen FEM-Referenz (numerisch)', function()
    rlVergleich('Kragarm q', { fixed(node(0)), node(2) }, { bar(1, 2, { q = 1, q_str = '1' }) })
    local kg = { fixed(node(0)), node(2), roller(node(4)) }; kg[2].gelenk = true
    rlVergleich('Gerber', kg, { bar(1, 2, { q = 1, q_str = '1' }), bar(2, 3, { q = 1, q_str = '1' }) })
    local ke = { fixed(node(0, 0)), node(0, 2), roller(node(2, 2)) }
    rlVergleich('Rahmenecke', ke, { bar(1, 2, { EA = 100 }), bar(2, 3, { q = 1, q_str = '1', EA = 100 }) })
    local kf = { fixed(node(0)), node(4) }; kf[2].cx = 3; kf[2].f_winkel = 30; kf[2].last_y = -1
    rlVergleich('Feder 30 Grad', kf, { bar(1, 2, { EA = 100 }) })
    local kl = { fixed(node(0)), node(4) }; kl[2].lager_y = true; kl[2].winkel = 30; kl[2].last_y = -1
    rlVergleich('Rollenlager 30 Grad', kl, { bar(1, 2, { EA = 100 }) })
    rlVergleich('Temperatur', { fixed(node(0)), node(2) }, { bar(1, 2, { To = 0, Tu = 100, h = 0.2, alpha = 1e-5 }) })
    rlVergleich('m(x)=x', { fixed(node(0)), node(2) }, { bar(1, 2, { m = 0, m_str = 'x' }) })
    local kq = { fixed(node(0)), node(2), fixed(node(4)) }
    rlVergleich('Q-Gelenk', kq, { bar(1, 2, { q = 1, q_str = '1' }), bar(2, 3, { q = 1, q_str = '1', q_gelenk_A = true }) })
end)

case('[K] Rand-LGS symbolisch und Fehlerfaelle', function()
    solveSymb({ pinned(node(0)), roller(node(4)) }, { bar(1, 2, { q = 1, q_str = 'q', EI_str = 'EI', EA_str = 'EA' }) })
    check('symbolisch: Rand-LGS loesbar', exportBiegelinienNeuToTI() and 1 or 0, 1)
    check('symbolisch: wneu1(2l) = 5*q*(4l)^4/384 = 10/3*q*l^4', ev('expand(wneu1(2*l) - 10/3*q*l^4)'), 0)
    write('           randbed = ' .. tostring(math.eval('string(randbed)')) .. '\n')
    -- Mechanismus: Balken nur mit Gelenklager links -> singulaer, keine Ausnahme
    solve({ pinned(node(0)), node(2) }, { bar(1, 2, { q = 1, q_str = '1' }) })
    local ok, res = pcall(exportBiegelinienNeuToTI)
    check('Mechanismus: kein Absturz, Rueckgabe false', (ok and res == false) and 1 or 0, 1)
end)

case('[L] Befunde der Rand-LGS-Verifikation', function()
    -- H1 FEM: N-Gelenk am Ende B mit Laengslast: N = n(L-x), EA*u(L) = n*L^2/2 = +2
    local K, S = solve({ fixed(node(0)), pinned(node(2)) }, { bar(1, 2, { n = 1, n_str = '1', n_gelenk_B = true, EA = 100 }) })
    check('FEM N-Gelenk B: EA*u_b = +2', S[1].v_local[4] * S[1].EA, 2)
    exportBiegelinienNeuToTI()
    check('Rand-LGS N-Gelenk B: uneu1(2) = +2', ev('uneu1(2)'), 2)
    -- M2 kleine Werte: eT = 1e-5 -> EA*u(2) = EA*eT*L = 0.002 (war 0 durch sqrt(0))
    solve({ fixed(node(0)), node(2) }, { bar(1, 2, { To = 1, Tu = 1, h = 0.2, alpha = 1e-5, EA = 100 }) })
    exportBiegelinienNeuToTI()
    check('Temperatur eT=1e-5: uneu1(2) = 0.002', ev('uneu1(2)'), 0.002)
    check('neuZahl(1e-5) ohne e/sqrt', (neuZahl(1e-5):find('[e]') or neuZahl(1e-5):find('sqrt')) and 0 or 1, 1)
    write('           neuZahl(1e-5) = ' .. neuZahl(1e-5) .. ', neuZahl(5e-5) = ' .. neuZahl(5e-5) .. ', neuZahl(1e15) = ' .. neuZahl(1e15) .. '\n')
    -- M3/M4 Eingabetexte
    check("neuCasText('1,5*x') = '1.5*x'", neuCasText('1,5*x') == '1.5*x' and 1 or 0, 1)
    check("neuCasText('max(1,2)') unveraendert", neuCasText('max(1,2)') == 'max(1,2)' and 1 or 0, 1)
    check("neuCasText('1e8') = '1*10^(8)'", neuCasText('1e8') == '1*10^(8)' and 1 or 0, 1)
    solve({ fixed(node(0)), node(2) }, { bar(1, 2, { q = 1.5, q_str = '1,5' }) })
    check("Dezimalkomma q='1,5': Rand-LGS loesbar", exportBiegelinienNeuToTI() and 1 or 0, 1)
    check("Dezimalkomma q='1,5': wneu1(2) = qL^4/8 = 3", ev('wneu1(2)'), 3)
    -- M6 randbed: Stab 2 rueckwaerts gezeichnet -> M2(B) = -M1(B)
    local kz = { pinned(node(0)), roller(node(2)), roller(node(4)) }
    solve(kz, { bar(1, 2, { q = 1, q_str = '1' }), bar(3, 2, { q = 1, q_str = '1' }) })
    exportBiegelinienNeuToTI()
    local rb = tostring(math.eval('string(randbed)'))
    write('           randbed = ' .. rb .. '\n')
    check("randbed: EIw2''(x2=2)=-EIw1''(x1=2)", (rb:find("EIw2''(x2=2)=-EIw1''(x1=2)", 1, true) or rb:find("EIw1''(x1=2)=-EIw2''(x2=2)", 1, true)) and 1 or 0, 1)
    check('randbed ist Spaltenvektor ["...";"..."]', (rb:sub(1, 2) == '["' and rb:find('";"', 1, true)) and 1 or 0, 1)
    -- N2: Knoten nur mit Q-Gelenk-Enden, ohne Last
    local kq = { fixed(node(0)), node(2), fixed(node(4)) }
    -- (die FEM meldet hier "kinematisch"; Sollwerte aus dem beidseitig eingespannten Traeger L=4,
    --  wegen Symmetrie ist Q in der Mitte ohnehin 0: EI*w = q*x^2*(L-x)^2/24)
    solve(kq, { bar(1, 2, { q = 1, q_str = '1', q_gelenk_B = true }), bar(2, 3, { q = 1, q_str = '1', q_gelenk_A = true }) })
    check('Q-Gelenke am Mittelknoten: Rand-LGS loesbar', exportBiegelinienNeuToTI() and 1 or 0, 1)
    check('  wneu1(2/3) = q x^2 (L-x)^2/24 = 0.20576', ev('wneu1(2/3)'), (2/3)^2 * (10/3)^2 / 24)
    check('  wneu1(2) = qL^4/384 = 2/3', ev('wneu1(2)'), 2 / 3)
    check('  wneu2(0) = 2/3', ev('wneu2(0)'), 2 / 3)
    -- N1: nach Abbruch keine veralteten Funktionen
    solve({ pinned(node(0)), node(2) }, { bar(1, 2, { q = 1, q_str = '1' }) })
    exportBiegelinienNeuToTI()
    local rbf = tostring(math.eval('string(randbed)'))
    check('Abbruch: randbed enthaelt Fehlermeldung', rbf:find('Fehler', 1, true) and 1 or 0, 1)
    check('Abbruch: wneu1 geloescht', type(ev('wneu1(1)')) == 'number' and 0 or 1, 1)
    write('           randbed = ' .. rbf .. '\n')
end)

case('[M] Symbolischer Modus: reservierte/inkonsistente Symbole', function()
    solveSymb({ pinned(node(0)), roller(node(4)) }, { bar(1, 2, { q_str = 't', q = 1 }) })
    check('q = t -> Fehler (reserviert)', symbolFehler and symbolFehler:find('reserviert') and 1 or 0, 1)
    local k = { fixed(node(0)), node(2) }; k[2].cy_str = 'EI/l^3'; k[2].cy = 1; k[2].last_y_str = 'F'; k[2].last_y = 1
    solveSymb(k, { bar(1, 2) })
    write('           Meldung: ' .. tostring(symbolFehler) .. '\n')
    -- Mischung Zahl/Symbol ist kein Abbruch mehr: es wird gerechnet und gewarnt
    write('           Hinweis: ' .. table.concat(hinweisListe, ' | ') .. '\n')
    check('Feder EI/l^3 ohne symbolisches EI am Stab -> kein Abbruch', symbolFehler == nil and 1 or 0, 1)
    check('Feder EI/l^3 ohne symbolisches EI am Stab -> Hinweis', table.concat(hinweisListe, ' | '):find('EI ist dort eine Zahl', 1, true) and 1 or 0, 1)
    local k2 = { fixed(node(0)), node(2) }; k2[2].cy_str = 'EI/l^3'; k2[2].cy = 1; k2[2].last_y_str = 'F'; k2[2].last_y = 1
    solveSymb(k2, { bar(1, 2, { EI_str = 'EI' }) })
    check('Feder EI/l^3 mit EI am Stab -> ok', symbolFehler == nil and 1 or 0, 1)
    check('  Rand-LGS loesbar', exportBiegelinienNeuToTI() and 1 or 0, 1)
    -- Kragarm 2l, Feder c = EI/l^3 am Ende: EI*w = F*L^3/3 / (1 + c*L^3/(3EI)) mit L=2l -> 8/3 F l^3 / (1+8/3) = 8/11 F l^3
    check('  wneu1(2l) = 8/11*F*l^3', ev('expand(wneu1(2*l) - 8/11*f*l^3)'), 0)
    -- schraeger Stab symbolisch bei zahlenFormat 2: Laenge sqrt(2)*l
    zahlenFormat = 2
    local ks = { fixed(node(0, 0)), node(1, 1) }; ks[2].last_y_str = 'F'; ks[2].last_y = 1
    solveSymb(ks, { bar(1, 2, { EI_str = 'EI', EA_str = 'EA' }) })
    write('           Stablaenge: ' .. symbLaenge(math.sqrt(2)) .. '\n')
    check('zahlenFormat 2: Laenge = (sqrt(2)*l)', symbLaenge(math.sqrt(2)) == '(sqrt(2)*l)' and 1 or 0, 1)
    zahlenFormat = 1
end)

cas.stop()
write(string.format('\nErgebnis: %d OK, %d FEHLER, %d BEKANNT (offen), %d BEHOBEN   [%d CAS-Anfragen]\n',
    results.ok, results.fail, results.known, results.fixed, cas.stats.requests))
os.exit(results.fail == 0 and 0 or 1)
