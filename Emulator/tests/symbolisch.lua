-- Symbolischer Modus: Rand-LGS (wneu/uneu) gegen geschlossene Handformeln.
-- Staebe haben standardmaessig EI_str = 'EI', EA_str = 'EA'; ohne Symbol in der Geometrie
-- gilt ein Rasterabstand (rasterMass = 1) als l.
-- Aufruf: luajit Emulator/tests/symbolisch.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller = T.node, T.fixed, T.pinned, T.roller
local function bar(a, b, f) return T.bar(a, b, f, { EI = 1, EA = 1, EI_str = 'EI', EA_str = 'EA' }) end

local function str(e) return tostring(T.evs(e)) end
local function num(e) return T.ev(e) end

-- symbolischer Vergleich: expand(ist - soll) muss 0 sein
local function check(label, expr, soll)
    local diff = num('expand((' .. expr .. ')-(' .. soll .. '))')
    local ok = type(diff) == 'number' and math.abs(diff) < 1e-9
    T.pruef(ok, string.format('%-34s ist=%s  soll=%s', label, str(expr), soll))
end

-- numerische Kontrolle: Symbole mit Zahlen belegen, vergleichen, wieder loeschen
local function checkNum(label, expr, soll, subs)
    local names = {}
    for k, v in pairs(subs) do math.eval(k .. ':=' .. tostring(v)); names[#names + 1] = k end
    local a, b = num(expr), num(soll)
    math.eval('DelVar ' .. table.concat(names, ','))
    local ok = type(a) == 'number' and type(b) == 'number' and math.abs(a - b) < 1e-6 * math.max(1, math.abs(b))
    T.pruef(ok, string.format('%-34s ist=%s  soll=%s', label, tostring(a), tostring(b)))
end

local function setup(title, K, S, opts)
    T.abschnitt(title)
    if not T.rechne(K, S, opts) then return false end
    if symbolFehler then T.pruef(false, 'unerwarteter symbolFehler: ' .. symbolFehler); return false end
    if not T.randLGS() then return false end
    for i = 1, #S do T.info('   wneu' .. i .. '(x) = ' .. str('wneu' .. i .. '(x)')) end
    return true
end

-- erwarteter Abbruch mit Meldung
local function abbruch(title, K, S, muster)
    T.abschnitt(title)
    T.rechne(K, S)
    T.pruef(symbolFehler ~= nil and symbolFehler:find(muster, 1, true) ~= nil,
        'symbolFehler enthaelt "' .. muster .. '": ' .. tostring(symbolFehler))
    local ok, res = pcall(exportBiegelinienNeuToTI)
    T.pruef(ok and res == false, 'Rand-LGS bricht ab')
end

local fall = T.fall

fall('1 Einfeld q', function()
    if setup('Einfeldtraeger L=2l, q', { pinned(node(0)), roller(node(2)) }, { bar(1, 2, { q = 1, q_str = 'q' }) }) then
        check('wneu1(l) = 5/24 q l^4', 'wneu1(l)', '5/24*q*l^4')
        check('wneu1(x) Formel', 'wneu1(x)', 'q*x*((2*l)^3-2*(2*l)*x^2+x^3)/24')
        check('uneu1(x) = 0', 'uneu1(x)', '0')
    end
end)

fall('2 Kragarm F', function()
    local K = { fixed(node(0)), node(1) }
    K[2].last_y, K[2].last_y_str = 1, 'F'
    if setup('Kragarm L=l, F an der Spitze', K, { bar(1, 2) }) then
        check('wneu1(l) = F l^3/3', 'wneu1(l)', 'F*l^3/3')
        check('wneu1(x) = F x^2(3l-x)/6', 'wneu1(x)', 'F*x^2*(3*l-x)/6')
    end
end)

fall('3 Eingespannt q', function()
    if setup('Beidseitig eingespannt L=2l, q', { fixed(node(0)), fixed(node(2)) }, { bar(1, 2, { q = 1, q_str = 'q' }) }) then
        check('wneu1(l) = q(2l)^4/384', 'wneu1(l)', 'q*(2*l)^4/384')
        check('wneu1(x) = q x^2 (L-x)^2/24', 'wneu1(x)', 'q*x^2*(2*l-x)^2/24')
    end
end)

fall('4 Gerber F', function()
    -- Einspannung 0, Gelenk bei l, F bei 3l/2, Rollenlager bei 2l
    local K = { fixed(node(0)), node(1), node(1.5, 0, '3/2', '0'), roller(node(2)) }
    K[2].gelenk = true
    K[3].last_y, K[3].last_y_str = 1, 'F'
    if setup('Gerbertraeger: Einsp. 0, Gelenk l, F bei 3l/2, Rolle 2l', K, { bar(1, 2), bar(2, 3), bar(3, 4) }) then
        check('wneu1(l) = F l^3/6', 'wneu1(l)', 'F*l^3/6')
        check('wneu2(l/2) = 5/48 F l^3', 'wneu2(l/2)', '5/48*F*l^3')
        check('wneu3(0) = 5/48 F l^3', 'wneu3(0)', '5/48*F*l^3')
        check('wneu3(l/2) = 0', 'wneu3(l/2)', '0')
        check('wneu1(x) = F x^2(3l-x)/12', 'wneu1(x)', 'F*x^2*(3*l-x)/12')
    end
end)

fall('5 Drehfeder', function()
    local K = { pinned(node(0)), roller(node(1)) }
    K[1].cm, K[1].cm_str = 1, 'EI/l'
    if setup('Einfeldtraeger l, Drehfeder cm=EI/l links, q', K, { bar(1, 2, { q = 1, q_str = 'q' }) }) then
        -- M_A = q l^2/32, w(l/2) = 5ql^4/384 - ql^4/512 = 17/1536 q l^4
        check('wneu1(l/2) = 17/1536 q l^4', 'wneu1(l/2)', '17/1536*q*l^4')
        check('wneu1(x) Formel', 'wneu1(x)', 'q*x*(l^3-2*l*x^2+x^3)/24 - q*l^2/32*x*(l-x)*(2*l-x)/(6*l)')
    end
    local K2 = { pinned(node(0)), roller(node(1)) }
    K2[1].cm, K2[1].cm_str = 1, 'c'
    if setup('Einfeldtraeger l, Drehfeder cm=c links, q', K2, { bar(1, 2, { q = 1, q_str = 'q' }) }) then
        -- M_A = c q l^3/(8 (3EI + c l)); w(l/2) = 5ql^4/384 - M_A l^2/16
        checkNum('wneu1(l/2) (c=2,EI=3,l=5,q=7)', 'wneu1(l/2)', '5/384*q*l^4 - (c*q*l^3/(8*(3*EI+c*l)))*l^2/16', { c = 2, ei = 3, l = 5, q = 7 })
        checkNum('wneu1(l/4)', 'wneu1(l/4)', 'q*l/4*(l^3-2*l*(l/4)^2+(l/4)^3)/24 - (c*q*l^3/(8*(3*EI+c*l)))*(l/4)*(l-l/4)*(2*l-l/4)/(6*l)', { c = 2, ei = 3, l = 5, q = 7 })
    end
end)

fall('6 Rahmen H', function()
    -- Portal h = L = l, Fusspunkte bei y = l (Bildschirm unten)
    local function frame(EAsym)
        local K = { pinned(node(0, 1)), node(0, 0), node(1, 0), pinned(node(1, 1)) }
        K[2].last_x, K[2].last_x_str = 1, 'H'
        local S = { bar(1, 2), bar(2, 3), bar(3, 4) }
        if not EAsym then for _, s in ipairs(S) do s.EA_str = nil; s.EA = 1e9 end end
        return K, S
    end
    local K, S = frame(true)
    if setup('Zweigelenkrahmen h=L=l, H an Ecke, EA symbolisch', K, S) then
        -- dehnstarr (EA sehr gross): EI*Delta = H l^3/4
        checkNum('wneu1(l)|EA=1e15 = H l^3/4', 'wneu1(l)', 'H*l^3/4', { ea = 1e15, ei = 2, l = 3, h = 5 })
        checkNum('wneu3(0)|EA=1e15 = -H l^3/4', 'wneu3(0)', '-H*l^3/4', { ea = 1e15, ei = 2, l = 3, h = 5 })
        checkNum('wneu2(0)|EA=1e15 = 0', 'wneu2(0)', '0', { ea = 1e15, ei = 2, l = 3, h = 5 })
        checkNum('wneu2(l/2)|EA=1e15 = 0 (antimetrisch)', 'wneu2(l/2)', '0', { ea = 1e15, ei = 2, l = 3, h = 5 })
        checkNum('uneu1(l) = H l (Stuetze 1 Zug)', 'uneu1(l)', 'H*l', { ea = 7, ei = 2, l = 3, h = 5 })
    end
    local K2, S2 = frame(false)
    if setup('Zweigelenkrahmen, EA=1e9 numerisch', K2, S2) then
        checkNum('wneu1(l) ~ H l^3/4', 'wneu1(l)', 'H*l^3/4', { ei = 2, l = 3, h = 5 })
        checkNum('wneu3(0) ~ -H l^3/4', 'wneu3(0)', '-H*l^3/4', { ei = 2, l = 3, h = 5 })
    end
end)

fall('7 EI numerisch', function()
    local K = { fixed(node(0)), node(1) }
    K[2].last_y, K[2].last_y_str = 1, 'F'
    local S = { bar(1, 2, { EI = 1e8, EA = 1e10 }) }
    S[1].EI_str, S[1].EA_str = nil, nil
    if setup('Kragarm l, F symbolisch, EI=1e8 numerisch', K, S) then
        check('wneu1(l) = F l^3/3', 'wneu1(l)', 'F*l^3/3')
    end
    local S2 = { bar(1, 2, { q = 1, q_str = 'q', EI = 1e8, EA = 1e10 }) }
    S2[1].EI_str, S2[1].EA_str = nil, nil
    if setup('Einspannung-Rolle 2l, q symbolisch, EI numerisch', { fixed(node(0)), roller(node(2)) }, S2) then
        check('wneu1(x) = q x^2 (L-x)(3L-2x)/48', 'wneu1(x)', 'q*x^2*(2*l-x)*(3*2*l-2*x)/48')
    end
end)

fall('8 Grenzen', function()
    local K = { fixed(node(0)), node(1) }
    K[2].last_y, K[2].last_y_str = 1, 'F'
    abbruch('Temperatur als Funktion von x', K, { bar(1, 2, { To = 1, To_str = 'dt*x', Tu = 100, h = 0.2, alpha = 1e-5 }) }, 'Temperatur')
    abbruch('Lastfunktion q*x', { pinned(node(0)), roller(node(2)) }, { bar(1, 2, { q = 1, q_str = 'q*x' }) }, 'Lastfunktion')
    abbruch('Streckenmoment m(x)=x', { pinned(node(0)), roller(node(2)) }, { bar(1, 2, { q = 1, q_str = 'q', m_str = 'x' }) }, 'Lastfunktion')
    abbruch('Symbol t', { pinned(node(0)), roller(node(2)) }, { bar(1, 2, { q = 1, q_str = 't' }) }, 'reserviert')
    local K2 = { fixed(node(0)), node(1) }
    K2[2].cy, K2[2].cy_str, K2[2].last_y, K2[2].last_y_str = 1, 'EI/l^3', 1, 'F'
    local S2 = { bar(1, 2) }; S2[1].EI_str = nil
    abbruch('Feder EI/l^3 ohne symbolisches EI am Stab', K2, S2, 'EI')
    local K3 = { pinned(node(0)), node(1, 0, 'a', '0'), roller(node(2, 0, 'a+2', '0')) }
    K3[2].last_y, K3[2].last_y_str = 1, 'F'
    abbruch('Koordinate a+2', K3, { bar(1, 2), bar(2, 3) }, 'Vielfaches')
end)

fall('9 Koordinaten l', function()
    local K = { pinned(node(0, 0, '0', '0')), node(1, 0, 'l', '0'), roller(node(2, 0, '2*l', '0')) }
    K[2].last_y, K[2].last_y_str = 1, 'F'
    if setup('Einfeldtraeger 2l (x_str l, 2*l), F mittig', K, { bar(1, 2), bar(2, 3) }) then
        check('wneu1(l) = F (2l)^3/48', 'wneu1(l)', 'F*(2*l)^3/48')
        check('wneu1(x) = F x (3L^2-4x^2)/48', 'wneu1(x)', 'F*x*(3*(2*l)^2-4*x^2)/48')
    end
    local K2 = { fixed(node(0, 0, '0', '0')), node(3, 0, 'a', '0') }
    K2[2].last_y, K2[2].last_y_str = 1, 'F'
    if setup('Kragarm Laenge a, F', K2, { bar(1, 2) }) then
        check('wneu1(a) = F a^3/3', 'wneu1(a)', 'F*a^3/3')
    end
    -- Raster 0,5: ein Rasterabstand = l, Stab 2 m = 4 l
    local K3 = { fixed(node(0)), node(2) }
    K3[2].last_y, K3[2].last_y_str = 1, 'F'
    if setup('Kragarm 2 m bei Raster 0,5 -> L = 4l', K3, { bar(1, 2) }, { raster = 0.5 }) then
        check('wneu1(4l) = F (4l)^3/3', 'wneu1(4*l)', 'F*(4*l)^3/3')
    end
    -- schraeger Stab, Zahlenformat 2: Laenge sqrt(2)*l
    local K4 = { fixed(node(0, 0)), node(1, 1) }
    K4[2].last_y, K4[2].last_y_str = 1, 'F'
    if setup('Schraeger Kragarm (0,0)-(1,1), zahlenFormat 2', K4, { bar(1, 2) }, { zahlenFormat = 2 }) then
        -- Querkomponente F/sqrt(2): EI*w(L) = F/sqrt(2) * (sqrt(2) l)^3/3 = 2/3 F l^3
        check('wneu1(sqrt(2) l) = 2/3 F l^3', 'wneu1(sqrt(2)*l)', '2/3*F*l^3')
    end
end)

fall('10 Weitere Lasten', function()
    if setup('Einfeldtraeger l, Dreieckslast 0 -> q', { pinned(node(0)), roller(node(1)) },
        { bar(1, 2, { q_A = 0, q_B = 1, q_A_str = '0', q_B_str = 'q' }) }) then
        check('wneu1(x) Dreieck', 'wneu1(x)', 'q*x*(7*l^4-10*l^2*x^2+3*x^4)/(360*l)')
    end
    if setup('Stab l mit n symbolisch, links eingespannt', { fixed(node(0)), node(1) }, { bar(1, 2, { n = 1, n_str = 'n' }) }) then
        check('uneu1(l) = n l^2/2', 'uneu1(l)', 'n*l^2/2')
    end
    local K3 = { pinned(node(0)), roller(node(1)) }
    K3[2].last_m, K3[2].last_m_str = 1, 'M0'
    if setup('Einfeldtraeger l, Knotenmoment M0 rechts', K3, { bar(1, 2) }) then
        check('wneu1(l/2) = M0 l^2/16', 'wneu1(l/2)', 'M0*l^2/16')
    end
    local K4 = { fixed(node(0)), node(1) }
    K4[2].cy, K4[2].cy_str = 1, 'c'
    K4[2].last_y, K4[2].last_y_str = 1, 'F'
    if setup('Kragarm l, Feder cy=c am Ende, F', K4, { bar(1, 2) }) then
        checkNum('wneu1(l) = F EI l^3/(c l^3+3EI)', 'wneu1(l)', 'F*EI*l^3/(c*l^3+3*EI)', { c = 2, ei = 3, l = 5, f = 7 })
    end
    local K5 = { fixed(node(0)), node(2) }
    K5[2].cy, K5[2].cy_str = 1, 'EI/l^3'
    K5[2].last_y, K5[2].last_y_str = 1, 'F'
    if setup('Kragarm 2l, Feder EI/l^3 am Ende, F', K5, { bar(1, 2) }) then
        check('wneu1(2l) = 8/11 F l^3', 'wneu1(2*l)', '8/11*F*l^3')
    end
    local K6 = { pinned(node(0)), roller(node(4)) }
    if setup('Einfeldtraeger 4l, Eigengewicht gy = g', K6, { bar(1, 2, { gy = 1, gy_str = 'g' }) }) then
        check('wneu1(2l) = 5 g (4l)^4/384', 'wneu1(2*l)', '5*g*(4*l)^4/384')
    end
end)

T.ende('Symbolischer Modus')
