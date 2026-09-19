-- Temperatur im Rand-LGS, auch symbolisch (To, Tu, alpha, h als Text). Die Exporte wv_i/uv_i sind die
-- Verschiebungen selbst, damit Klausurfragen wie "dT so, dass u = 0" per solve(uv1(l)=0,dt) gehen.
-- Aufruf: luajit Emulator/tests/temperatur.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller = T.node, T.fixed, T.pinned, T.roller

local function str(e) return tostring(T.evs(e)) end
local function num(e) return T.ev(e) end
local function check(label, expr, soll)
    local diff = num('expand((' .. expr .. ')-(' .. soll .. '))')
    local ok = type(diff) == 'number' and math.abs(diff) < 1e-12
    T.pruef(ok, string.format('%-46s ist=%s  soll=%s', label, str(expr), soll))
end
local function fem(label, ist, soll, tol)
    local ok = type(ist) == 'number' and math.abs(ist - soll) <= (tol or 1e-9) * math.max(1, math.abs(soll))
    T.pruef(ok, string.format('%-46s soll %-12.6g ist %s', label, soll, tostring(ist)))
end
local function bar(a, b, f) return T.bar(a, b, f, { EI = 1e8, EA = 1e10 }) end
-- Temperaturfelder: Zahl (Platzhalter 1) plus Text wie im Stabmenue
local function temp(f, To, Tu, al, h)
    f.To, f.To_str, f.Tu, f.Tu_str = 1, To, 1, Tu
    if al then f.alpha, f.alpha_str = 1, al end
    if h then f.h, f.h_str = 1, h end
    return f
end
local function setup(title, K, S)
    T.abschnitt(title)
    if not T.rechne(K, S) then return false end
    if symbolFehler then T.pruef(false, 'unerwarteter symbolFehler: ' .. symbolFehler); return false end
    if not T.randLGS() then return false end
    T.info('   randinfo = ' .. str('randinfo'))
    for i = 1, #S do T.info('   wv' .. i .. '(x) = ' .. str('wv' .. i .. '(x)') .. '   uv' .. i .. '(x) = ' .. str('uv' .. i .. '(x)')) end
    return true
end
-- Symbole belegen, Ausdruck auswerten, Symbole wieder loeschen
local function mit(werte, expr)
    local namen = {}
    for k, v in pairs(werte) do math.eval(k .. ':=' .. v); namen[#namen + 1] = k end
    local r = num(expr)
    math.eval('DelVar ' .. table.concat(namen, ','))
    return r
end

local fall = T.fall

fall('1 Gleichmaessig symbolisch', function()
    local S = { bar(1, 2, temp({}, 'dt', 'dt', 'a')) }
    if setup('Einfeldtraeger 2l, gleichmaessig dT, alpha symbolisch', { pinned(node(0)), roller(node(2)) }, S) then
        check('uv1(x) = a dT x', 'uv1(x)', 'a*dt*x')
        check('uv1(2l) = 2 a dT l', 'uv1(2*l)', '2*a*dt*l')
        check('wv1(x) = 0', 'wv1(x)', '0')
        check('uneu1(x) = EA u = 10^10 a dT x', 'uneu1(x)', '10^10*a*dt*x')
        T.wahr('Hinweis zu den Diagrammen offen', hinweisOffen == true)
        on.escapeKey()
        T.wahr('ESC schliesst den Hinweis', hinweisOffen == false)
        pcall(starteBerechnung)
        T.wahr('gleiche Eingaben: Hinweis bleibt zu', hinweisOffen == false)
        getStaebe()[1].To_str = 'dt2'
        pcall(starteBerechnung)
        T.wahr('geaenderte Temperatur: Hinweis wieder offen', hinweisOffen == true)
    end
end)

fall('2 Klausurtyp dT fuer u = 0', function()
    -- Stab 1 (erwaermt) und Stab 2 zwischen zwei Festlagern, F am Mittelknoten:
    -- u = (F + EA a dT) l/(2 EA)  ->  u = 0 fuer dT = -F/(EA a)
    local K = { pinned(node(0)), node(1), pinned(node(2)) }
    K[2].last_x, K[2].last_x_str = 1, 'F'
    local S = { bar(1, 2, temp({ EA = 1, EA_str = 'EA' }, 'dt', 'dt', 'a')), bar(2, 3, { EA = 1, EA_str = 'EA' }) }
    if setup('zwei Staebe zwischen Festlagern, Stab 1 erwaermt', K, S) then
        check('uv1(l) = (F + EA a dT) l/(2 EA)', 'uv1(l)', '(f+ea*a*dt)*l/(2*ea)')
        check('uv2(0) = uv1(l) (Knoten)', 'uv2(0)-uv1(l)', '0')
        T.wahr('solve-Probe: dT = -F/(EA a) -> uv1(l) = 0', math.abs(mit({ dt = '-f/(ea*a)' }, 'expand(uv1(l))') or 1) < 1e-12)
    end
end)

fall('3 Gradient symbolisch', function()
    local S = { bar(1, 2, temp({}, 't1', 't2', 'a', 'h')) }
    if setup('Kragarm 2l, To = t1, Tu = t2, alpha = a, h = h', { fixed(node(0)), node(2) }, S) then
        check('wv1(x) = -a (t2 - t1) x^2/(2 h)', 'wv1(x)', '-a*(t2-t1)*x^2/(2*h)')
        check('uv1(x) = a (t1 + t2) x/2', 'uv1(x)', 'a*(t1+t2)*x/2')
        check('wneu1(x) = EI w', 'wneu1(x)-10^8*wv1(x)', '0')
    end
end)

fall('4 Symbolisch gegen numerisch', function()
    -- statisch unbestimmter Rahmen: Stuetzen eingespannt, Riegel mit Gradient und Erwaermung
    local function rahmen(riegel)
        local K = { fixed(node(0, 1)), node(0, 0), node(1, 0), fixed(node(1, 1)) }
        return K, { bar(1, 2), bar(2, 3, riegel), bar(3, 4) }
    end
    local punkte = { 'wv1(1/2)', 'wv2(1/3)', 'uv2(0)', 'uv1(1)', 'wneu2(1/2)', 'uneu3(1/2)' }
    local K, S = rahmen({ To = 10, Tu = 30, alpha = 1e-5, h = 0.2 })
    local ref = {}
    if setup('Rahmen numerisch: To = 10, Tu = 30', K, S) then
        for _, p in ipairs(punkte) do ref[p] = num(p) end
    end
    local K2, S2 = rahmen(temp({}, 't1', 't2', 'a', 'h'))
    if setup('derselbe Rahmen symbolisch: To = t1, Tu = t2, alpha = a, h = h', K2, S2) then
        local werte = { t1 = '10', t2 = '30', a = '1/100000', h = '1/5', l = '1' }
        for _, p in ipairs(punkte) do
            local ps = p:gsub('%(([%d/]+)%)', '((%1)*l)')   -- Stelle x in Vielfachen von l
            fem('symbolisch = numerisch: ' .. p, mit(werte, ps), ref[p] or 0/0, 1e-9)
        end
    end
end)

fall('5 Starre Scheibe', function()
    -- Stab 1 (EA, erwaermt) und Stab 2 (2EA) gelenkig an eine starre Scheibe (Knoten 3-5-4),
    -- F in Scheibenmitte, Rolle an Knoten 3: N1 = N2 = F/2 (statisch bestimmt)
    -- Querschnitt A (Knoten 3) verschiebt sich nicht fuer dT = -F/(2 EA a)
    local K = { pinned(node(0, 0)), pinned(node(0, -2)), roller(node(1, 0)), node(1, -2), node(1, -1) }
    K[1].gelenk, K[2].gelenk = true, true   -- Lagergelenke (sonst ist die Knotenverdrehung in der FEM frei)
    K[5].last_x, K[5].last_x_str = 1, 'F'
    local S = {
        bar(1, 3, temp({ EA = 1, EA_str = 'EA', gelenk_B = true }, 'dt', 'dt', 'a')),
        bar(2, 4, { EA = 2, EA_str = '2*EA', gelenk_B = true }),
        bar(3, 5, { biegesteif = true, dehnsteif = true }),
        bar(5, 4, { biegesteif = true, dehnsteif = true }),
    }
    if setup('zwei Staebe an starrer Scheibe, Stab 1 erwaermt', K, S) then
        check('uv1(l) = F l/(2 EA) + a dT l', 'uv1(l)', 'f*l/(2*ea)+a*dt*l')
        check('uv2(l) = F l/(4 EA)', 'uv2(l)', 'f*l/(4*ea)')
        T.wahr('solve-Probe: dT = -F/(2 EA a) -> uv1(l) = 0', math.abs(mit({ dt = '-f/(2*ea*a)' }, 'expand(uv1(l))') or 1) < 1e-12)
        T.wahr('FEM nicht kinematisch', uiZustand().warnungKinematisch == false)
        fem('FEM: |N1| = F/2', math.abs(getStaebe()[1].s_local[1]), 0.5)
        fem('FEM: |N2| = F/2', math.abs(getStaebe()[2].s_local[1]), 0.5)
    end
end)

fall('6 Ohne Hoehe h', function()
    -- gleichmaessige Erwaermung braucht keine Hoehe: h = 0 heisst nur "kein Gradient"
    local S = { bar(1, 2, { To = 10, Tu = 10, alpha = 1e-5, h = 0 }) }
    if setup('Festlager-Festlager, dT = 10, h = 0', { pinned(node(0)), pinned(node(2)) }, S) then
        check('uv1(x) = 0', 'uv1(x)', '0')
        fem('FEM: |N| = EA alpha dT = 10^6', math.abs(getStaebe()[1].s_local[1]), 1e6)
    end
end)

T.ende('Temperatur')
