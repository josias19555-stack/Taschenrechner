-- Rand-LGS (wneu_i, uneu_i) gegen die FEM-Loesung desselben Systems.
-- Viele Systemtypen: Lager, Gelenke, Federn, gedrehte Lager, Lastarten, Temperatur, Rahmen.
-- Stabenden: gegen die exakten FEM-Knotenwerte v_local (Toleranz 1e-8 relativ).
-- Stabinneres: gegen den Referenzexport v_EI_stab. Dieser wandelt grosse Brueche absichtlich in
-- Zahlen mit 6 gueltigen Stellen um (eval_cas_string), daher dort Toleranz 1e-4.
-- Aufruf: luajit Emulator/tests/randlgs_fem.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller, ev = T.node, T.fixed, T.pinned, T.roller, T.ev
local function bar(a, b, f) return T.bar(a, b, f) end   -- EI = 1, EA = 100

local TOL_KNOTEN, TOL_INNEN = 1e-8, 1e-4

local function vergleich(label, ist, soll, tol)
    local ok = type(ist) == 'number' and type(soll) == 'number' and math.abs(ist - soll) < tol * math.max(1, math.abs(soll))
    T.pruef(ok, string.format('%-24s FEM=%-18s Rand-LGS=%s', label, tostring(soll), tostring(ist)))
end

local function run(title, K, S, opts)
    opts = opts or {}
    T.abschnitt(title)
    if not T.rechne(K, S, opts) then return end
    exportBiegelinienToTI()
    if not T.randLGS() then return end
    for i, s in ipairs(getStaebe()) do
        local k1, k2 = getKnoten()[s.k1], getKnoten()[s.k2]
        local L = math.sqrt((k2.x - k1.x) ^ 2 + (k2.y - k1.y) ^ 2)
        -- Stabenden: exakte FEM-Knotenwerte (w, EA*u)
        vergleich(string.format('Stab %d EI*w(0)', i), ev('wneu' .. i .. '(0)'), (s.v_local[2] or 0) * s.EI, TOL_KNOTEN)
        vergleich(string.format('Stab %d EI*w(L)', i), ev('wneu' .. i .. '(' .. L .. ')'), (s.v_local[5] or 0) * s.EI, TOL_KNOTEN)
        vergleich(string.format('Stab %d EA*u(0)', i), ev('uneu' .. i .. '(0)'), (s.v_local[1] or 0) * s.EA, TOL_KNOTEN)
        vergleich(string.format('Stab %d EA*u(L)', i), ev('uneu' .. i .. '(' .. L .. ')'), (s.v_local[4] or 0) * s.EA, TOL_KNOTEN)
        -- Stabinneres: Referenzexport
        for _, t in ipairs({ 1 / 3, 2 / 3 }) do
            local x = t * L
            vergleich(string.format('Stab %d EI*w(%.3f)', i, x), ev('wneu' .. i .. '(' .. x .. ')'), ev('v_EI_stab' .. i .. '(' .. x .. ')'), TOL_INNEN)
        end
    end
end

local fall = T.fall

fall('1 Kragarm q', function()
    run('Kragarm L=2, q=1, Einspannung links', { fixed(node(0)), node(2) }, { bar(1, 2, { q = 1, q_str = '1' }) })
    run('Kragarm umgedreht', { node(0), fixed(node(2)) }, { bar(1, 2, { q = 1, q_str = '1' }) })
end)
fall('2 Einfeld F', function()
    local k = { pinned(node(0)), node(2), roller(node(4)) }; k[2].last_y = -1
    run('Einfeldtraeger, F=-1 am Mittelknoten', k, { bar(1, 2), bar(2, 3) })
end)
fall('3 Zweifeld', function()
    run('Zweifeldtraeger 2+3, q=1 und q=2', { pinned(node(0)), roller(node(2)), roller(node(5)) },
        { bar(1, 2, { q = 1, q_str = '1' }), bar(2, 3, { q = 2, q_str = '2' }) })
end)
fall('4 Gerber', function()
    local k = { fixed(node(0)), node(2), roller(node(4)) }; k[2].gelenk = true
    run('Gerbertraeger', k, { bar(1, 2, { q = 1, q_str = '1' }), bar(2, 3, { q = 1, q_str = '1' }) })
end)
fall('5 Rahmenecke', function()
    run('Rahmenecke, q=1 auf Riegel', { fixed(node(0, 0)), node(0, 2), roller(node(2, 2)) },
        { bar(1, 2), bar(2, 3, { q = 1, q_str = '1' }) })
end)
fall('6 Portal', function()
    local k = { pinned(node(0, 0)), node(0, 3), node(4, 3), pinned(node(4, 0)) }; k[2].last_x = 1
    run('Zweigelenkrahmen, H=1 an Ecke, q auf Riegel', k, { bar(1, 2), bar(2, 3, { q = 1, q_str = '1' }), bar(3, 4) })
end)
fall('7 Schraeg', function()
    run('Schraeger Stab 45 Grad beidseitig gelenkig, q=1', { pinned(node(0, 0)), pinned(node(3, 3)) }, { bar(1, 2, { q = 1, q_str = '1' }) })
    local k2 = { fixed(node(0, 0)), node(3, 3) }; k2[2].last_y = -1; k2[2].last_x = 0.5
    run('Schraeger Kragarm mit Fx, Fy', k2, { bar(1, 2) })
end)
fall('8 Federn', function()
    local k = { pinned(node(0)), node(4) }; k[1].cm = 2; k[2].cy = 3
    run('Balken: Drehfeder cm=2 links, Feder cy=3 rechts, q=1', k, { bar(1, 2, { q = 1, q_str = '1' }) })
    local k2 = { fixed(node(0)), node(4) }; k2[2].cx = 3; k2[2].f_winkel = 90; k2[2].last_y = -1
    run('Kragarm, Feder cx=3 um 90 Grad gedreht, Fy=-1', k2, { bar(1, 2) })
    local k3 = { fixed(node(0)), node(4) }; k3[2].cx = 3; k3[2].f_winkel = 30; k3[2].last_y = -1
    run('Kragarm, Feder cx=3 um 30 Grad gedreht, Fy=-1', k3, { bar(1, 2) })
end)
fall('9 Gedrehtes Lager', function()
    local k = { fixed(node(0)), node(4) }; k[2].lager_y = true; k[2].winkel = 45; k[2].last_x = 1
    run('Rollenlager 45 Grad gedreht, Fx=1', k, { bar(1, 2) })
    local k2 = { fixed(node(0)), node(4) }; k2[2].lager_y = true; k2[2].winkel = 30; k2[2].last_y = -1
    run('Rollenlager 30 Grad gedreht, Fy=-1', k2, { bar(1, 2) })
end)
fall('10 Streckenmoment', function()
    run('Kragarm, Streckenmoment m=1', { fixed(node(0)), node(2) }, { bar(1, 2, { m = 1, m_str = '1' }) })
    run('Kragarm, m(x)=x', { fixed(node(0)), node(2) }, { bar(1, 2, { m = 0, m_str = 'x' }) })
    run('Einfeldtraeger 4 m, m(x)=x', { pinned(node(0)), roller(node(4)) }, { bar(1, 2, { m = 0, m_str = 'x' }) })
end)
fall('11 Temperatur', function()
    run('Kragarm Temperatur To=0, Tu=100', { fixed(node(0)), node(2) }, { bar(1, 2, { To = 0, Tu = 100, h = 0.2, alpha = 1e-5 }) })
    run('Kragarm Temperatur gleichmaessig To=Tu=100', { fixed(node(0)), node(2) }, { bar(1, 2, { To = 100, Tu = 100, h = 0.2, alpha = 1e-5 }) })
    run('Kragarm Temperatur To=Tu=1 (kleine Dehnung 1e-5)', { fixed(node(0)), node(2) }, { bar(1, 2, { To = 1, Tu = 1, h = 0.2, alpha = 1e-5 }) })
end)
fall('12 Laengslast', function()
    run('Stab mit n=1, links eingespannt, rechts frei', { fixed(node(0)), node(2) }, { bar(1, 2, { n = 1, n_str = '1' }) })
    run('Stab mit n=1 beidseitig festgehalten', { pinned(node(0)), pinned(node(2)) }, { bar(1, 2, { n = 1, n_str = '1' }) })
    run('Stab mit n=1, N-Gelenk am Ende B', { fixed(node(0)), pinned(node(2)) }, { bar(1, 2, { n = 1, n_str = '1', n_gelenk_B = true }) })
end)
fall('13 Gelenke', function()
    run('Beidseitig eingespannt, N-Gelenk in Stab 2 links, q=1', { fixed(node(0)), node(2), fixed(node(4)) },
        { bar(1, 2, { q = 1, q_str = '1' }), bar(2, 3, { q = 1, q_str = '1', n_gelenk_A = true }) })
    run('Beidseitig eingespannt, Q-Gelenk in Stab 2 links, q=1', { fixed(node(0)), node(2), fixed(node(4)) },
        { bar(1, 2, { q = 1, q_str = '1' }), bar(2, 3, { q = 1, q_str = '1', q_gelenk_A = true }) })
end)
fall('14 Knotenmoment', function()
    local k = { pinned(node(0)), node(2), roller(node(4)) }; k[2].last_m = 1
    run('Einfeldtraeger, Moment M=1 am Mittelknoten', k, { bar(1, 2), bar(2, 3) })
end)
fall('15 Eigengewicht', function()
    run('Schraeger Kragarm, gy=1 projiziert', { fixed(node(0, 0)), node(3, 4) }, { bar(1, 2, { gy = 1, gy_str = '1', gy_proj = true }) })
end)
fall('16 Trapez', function()
    run('Einfeldtraeger, Trapez q_A=1, q_B=3', { pinned(node(0)), roller(node(4)) },
        { bar(1, 2, { q_A = 1, q_B = 3, q_A_str = '1', q_B_str = '3' }) })
    run('Kragarm, q(x) = exp(x/4)', { fixed(node(0)), node(4) }, { bar(1, 2, { q = 0, q_str = 'exp(x/4)' }) })
    run('Kragarm, Dezimalkomma q = 1,5', { fixed(node(0)), node(2) }, { bar(1, 2, { q = 1.5, q_str = '1,5' }) })
end)

T.ende('Rand-LGS gegen FEM')
