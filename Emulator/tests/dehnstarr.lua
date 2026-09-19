-- Rand-LGS dehnstarr (randDehnstarr): Grenzwert EA -> unendlich fuer Staebe mit Standard-EA
-- (Zahl, nicht im Stabmenue eingegeben).
-- Sollwerte aus Handrechnung mit dehnstarren Staeben (wie in TM2 ueblich).
-- Aufruf: luajit Emulator/tests/dehnstarr.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller = T.node, T.fixed, T.pinned, T.roller
local STARR = { dehnstarr = true }

local function str(e) return tostring(T.evs(e)) end
local function num(e) return T.ev(e) end

-- exakter Vergleich: expand(ist - soll) muss 0 sein
local function check(label, expr, soll)
    local diff = num('expand((' .. expr .. ')-(' .. soll .. '))')
    local ok = type(diff) == 'number' and math.abs(diff) < 1e-12
    T.pruef(ok, string.format('%-40s ist=%s  soll=%s', label, str(expr), soll))
end
local function enthaelt(label, expr, muster, soll)
    local s = str(expr)
    local hat = s:find(muster, 1, true) ~= nil
    T.pruef(hat == (soll ~= false), string.format('%-40s %s "%s": %s', label, soll == false and 'ohne' or 'mit', muster, s))
end
-- keine "winzigen Brueche": keine Zahl mit 7 oder mehr Stellen
local function sauber(label, expr)
    local s = str(expr)
    T.pruef(not s:find('%d%d%d%d%d%d%d'), string.format('%-40s %s', label, s))
end

local function setup(title, K, S, opts)
    T.abschnitt(title)
    if not T.rechne(K, S, opts or STARR) then return false end
    if symbolFehler then T.pruef(false, 'unerwarteter symbolFehler: ' .. symbolFehler); return false end
    if not T.randLGS() then return false end
    T.info('   randinfo = ' .. str('randinfo'))
    for i = 1, #S do
        T.info('   wneu' .. i .. '(x) = ' .. str('wneu' .. i .. '(x)'))
        T.info('   uneu' .. i .. '(x) = ' .. str('uneu' .. i .. '(x)'))
    end
    return true
end

-- Zweigelenkrahmen h = L = l, H an der linken Ecke; Fusspunkte bei y = l (y nach unten)
local function portal(EAsym)
    local K = { pinned(node(0, 1)), node(0, 0), node(1, 0), pinned(node(1, 1)) }
    K[2].last_x, K[2].last_x_str = 1, 'H'
    local S = {}
    for i = 1, 3 do
        S[i] = T.bar(i, i + 1, { EI = 1, EI_str = 'EI', EA = EAsym and 1 or 1e10, EA_str = EAsym and 'EA' or nil })
    end
    return K, S
end

-- Rahmenecke: Stuetze 2 hoch (eingespannt), Riegel 2 lang mit q, Rolle am Riegelende
local function ecke(qs)
    local K = { fixed(node(0, 0)), node(0, -2), roller(node(2, -2)) }
    local S = { T.bar(1, 2, { EI = 1e8, EA = 1e10 }), T.bar(2, 3, { EI = 1e8, EA = 1e10, q = 1, q_str = qs }) }
    return K, S
end

local fall = T.fall

fall('1 Portal symbolisch', function()
    local K, S = portal(false)
    if setup('Zweigelenkrahmen, H und EI symbolisch, EA = 1e10 -> dehnstarr', K, S) then
        check('wneu1(x) = H l^2 x/3 - H x^3/12', 'wneu1(x)', 'h*l^2*x/3-h*x^3/12')
        check('wneu1(l) = H l^3/4', 'wneu1(l)', 'h*l^3/4')
        check('wneu2(0) = 0 (Stuetzen dehnstarr)', 'wneu2(0)', '0')
        check('wneu2(l/2) = 0 (antimetrisch)', 'wneu2(l/2)', '0')
        check('wneu3(0) = -H l^3/4', 'wneu3(0)', '-h*l^3/4')
        check('uneu1(x) = EA*u1 = H x', 'uneu1(x)', 'h*x')
        check('uneu3(x) = H (l - x)', 'uneu3(x)', 'h*(l-x)')
        check('uneu2(x) = u2 = H l^3/(4 EI)', 'uneu2(x)', 'h*l^3/(4*ei)')
        for i = 1, 3 do sauber('wneu' .. i .. '(x) ohne winzige Brueche', 'wneu' .. i .. '(x)') end
        enthaelt('randinfo', 'randinfo', 'dehnsteif (EA->unendlich): Stab 1,2,3')
        enthaelt('randinfo', 'randinfo', 'uneu2(x)=u2(x)')
        enthaelt('randinfo', 'randinfo', 'uneu1(x)=u1(x)', false)
    end
end)

fall('2 Rahmenecke numerisch', function()
    local K, S = ecke('1')
    if setup('Rahmenecke, q = 1, EI = 1e8, EA = 1e10 -> dehnstarr', K, S) then
        -- Handrechnung: Rollenkraft B = 15/16, Eckmoment 1/8, Stuetzen-N = -17/16
        check('wneu1(x) = x^2/16', 'wneu1(x)', 'x^2/16')
        check('wneu2(0) = 0', 'wneu2(0)', '0')
        check('wneu2(1) = 17/96', 'wneu2(1)', '17/96')
        check('wneu2(2) = 0 (Rolle)', 'wneu2(2)', '0')
        check('wneu2(x) Formel', 'wneu2(x)', '(2-x)^4/24-15/16*(2-x)^3/6-7/24*x+7/12')
        check('uneu1(x) = N1 x = -17 x/16', 'uneu1(x)', '-17*x/16')
        check('uneu2(x) = u2 = 1/(4 EI)', 'uneu2(x)', '1/400000000')
    end
end)

fall('3 Rahmenecke symbolisch', function()
    local K, S = ecke('q')
    if setup('Rahmenecke, q symbolisch, EI/EA numerisch -> dehnstarr', K, S) then
        check('wneu1(x) = q l^2 x^2/16', 'wneu1(x)', 'q*l^2*x^2/16')
        check('wneu2(l) = 17/96 q l^4', 'wneu2(l)', '17/96*q*l^4')
        check('wneu2(0) = 0', 'wneu2(0)', '0')
        check('wneu2(2l) = 0', 'wneu2(2*l)', '0')
        check('uneu1(x) = -17/16 q l x', 'uneu1(x)', '-17*q*l*x/16')
        sauber('wneu2(x) ohne winzige Brueche', 'wneu2(x)')
    end
end)

fall('4 Festlager-Festlager', function()
    -- Horizontallast zwischen zwei Festlagern, beide Staebe gleich starr: N teilt sich 1:1. Mit
    -- 1/EA = 0 waere das LGS singulaer; der Grenzwert liefert die Aufteilung.
    local K = { pinned(node(0)), node(1), pinned(node(2)) }
    K[2].last_x = 1
    local S = { T.bar(1, 2, { EI = 1e8, EA = 1e10 }), T.bar(2, 3, { EI = 1e8, EA = 1e10 }) }
    if setup('Festlager-Festlager, F = 1 in der Mitte, beide dehnstarr', K, S) then
        check('uneu1(x) = N1 x = x/2', 'uneu1(x)', 'x/2')
        check('uneu2(x) = 1/2 (1 - x)', 'uneu2(x)', '1/2*(1-x)')
        check('wneu1(x) = 0', 'wneu1(x)', '0')
        enthaelt('randinfo ohne u-Hinweis', 'randinfo', 'da EA*u unendlich', false)
    end
    -- Stab 2 mit eigenem EA (im Stabmenue eingegeben): bleibt dehnbar, Stab 1 nimmt alles auf
    local K2 = { pinned(node(0)), node(1), pinned(node(2)) }
    K2[2].last_x = 1
    local S2 = { T.bar(1, 2, { EI = 1e8, EA = 1e10 }), T.bar(2, 3, { EI = 1e8, EA = 1e10, EA_manuell = true }) }
    if setup('dasselbe, Stab 2 mit eigenem EA -> nur Stab 1 dehnstarr', K2, S2) then
        enthaelt('randinfo', 'randinfo', 'dehnsteif (EA->unendlich): Stab 1"')
        check('uneu1(x) = N1 x = x (N1 = F)', 'uneu1(x)', 'x')
        check('uneu2(x) = 0 (N2 = 0, u = 0)', 'uneu2(x)', '0')
    end
end)

fall('5 Temperatur frei', function()
    local K = { pinned(node(0)), roller(node(2)) }
    local S = { T.bar(1, 2, { EI = 1e8, EA = 1e10, To = 10, Tu = 10, alpha = 1e-5, h = 0.2 }) }
    if setup('Einfeldtraeger, gleichmaessige Erwaermung (epsT = 1e-4)', K, S) then
        check('uneu1(x) = u1 = epsT x', 'uneu1(x)', 'x/10000')
        check('wneu1(x) = 0', 'wneu1(x)', '0')
        enthaelt('randinfo', 'randinfo', 'uneu1(x)=u1(x)')
    end
end)

fall('6 Temperatur gehalten', function()
    T.abschnitt('Festlager-Festlager mit Erwaermung: Zwangskraft unendlich -> Abbruch')
    local K = { pinned(node(0)), pinned(node(2)) }
    local S = { T.bar(1, 2, { EI = 1e8, EA = 1e10, To = 10, Tu = 10, alpha = 1e-5, h = 0.2 }) }
    if not T.rechne(K, S, STARR) then return end
    local ok, res = pcall(exportBiegelinienNeuToTI)
    T.pruef(ok and res == false, 'Rand-LGS bricht ab (' .. tostring(res) .. ')')
    enthaelt('randbed mit Meldung', 'randbed', 'unendliche Zwangskraft')
    T.pruef(type(num('wneu1(1)')) ~= 'number', 'wneu1 nicht definiert')
    -- ausgeschaltet: N = -EA epsT = -10^6
    T.abschnitt('dasselbe System, dehnstarr aus')
    if T.rechne(K, S) and T.randLGS() then
        check('uneu1(x) = 0 (u = 0, N = -1e6 konstant)', 'uneu1(x)', '0')
        check('N = uneu1\'(x) - EA epsT', 'uneu1(1)-uneu1(0)-10^10/10000', '-1000000')
    end
end)

fall('7 Schalter aus', function()
    local K, S = portal(false)
    if setup('Zweigelenkrahmen, dehnstarr aus (EA = 1e10 endlich)', K, S, {}) then
        enthaelt('randinfo', 'randinfo', 'keine starren Staebe')
        enthaelt('wneu2(x) mit EA-Anteil', 'wneu2(x)', '10000000000')
        check('uneu1(x) = H x (EA*u)', 'uneu1(x)', 'h*x')
    end
end)

fall('8 EA symbolisch bleibt dehnbar', function()
    local K, S = portal(true)
    if setup('Zweigelenkrahmen, EA symbolisch -> nicht dehnstarr', K, S) then
        enthaelt('randinfo', 'randinfo', 'keine starren Staebe')
        enthaelt('wneu1(x) enthaelt ea', 'wneu1(x)', 'ea')
    end
end)

T.ende('Dehnstarr')
