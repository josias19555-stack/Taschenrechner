-- Rand-LGS (vne_i = EI*w_i, uneu_i = EA*u_i) gegen Lehrbuchformeln: Balkensysteme S1-S12.
-- Geprueft werden w, phi, M, Q, EA*u und N an mehreren Stellen je Stab.
-- Ableitungen: der SymPy-Emulator kennt kein d(); die Polynome werden daher exakt interpoliert
-- (simult mit 7 bzw. 4 Stuetzstellen) und die Koeffizienten exakt abgeleitet.
-- Aufruf: luajit Emulator/tests/balken_hand.lua [S1..S12]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller, ev, evs = T.node, T.fixed, T.pinned, T.roller, T.ev, T.evs
local function bar(a, b, f) return T.bar(a, b, f) end   -- EI = 1, EA = 100

local function fracStr(v)
    for d = 1, 1000 do
        local n = v * d
        if math.abs(n - math.floor(n + 0.5)) < 1e-9 then
            return (string.format('%d/%d', math.floor(n + 0.5), d):gsub('/1$', ''))
        end
    end
    return string.format('%.12g', v)
end
local function xnum(x) if type(x) == 'number' then return x end return assert(loadstring('return ' .. x))() end
local function xstr(x) if type(x) == 'number' then return fracStr(x) end return x end

-- exakte Polynomkoeffizienten von fname auf [0,L] (Grad deg) ueber Vandermonde-LGS im CAS
local function polyCoef(fname, Ls, deg)
    local rows, rhs = {}, {}
    for k = 0, deg do
        local xs = '(' .. k .. '*(' .. Ls .. '))/' .. deg
        local ents = {}
        for j = 0, deg do ents[j + 1] = (j == 0) and '1' or ('(' .. xs .. ')^' .. j) end
        rows[k + 1] = table.concat(ents, ',')
        rhs[k + 1] = fname .. '(' .. xs .. ')'
    end
    local res = evs('simult([[' .. table.concat(rows, '][') .. ']],[[' .. table.concat(rhs, '][') .. ']])')
    if type(res) ~= 'string' or res:sub(1, 2) ~= '[[' then return nil, res end
    local coef = {}
    for v in (res:sub(3, -3) .. ']['):gmatch('(.-)%]%[') do coef[#coef + 1] = v end
    return coef
end

-- k-te Ableitung des Polynoms an der Stelle xs (exakt im CAS, Ergebnis approx)
local function polyD(coef, k, xs)
    local terms = {}
    for j = k, #coef - 1 do
        local f = 1
        for m = 0, k - 1 do f = f * (j - m) end
        terms[#terms + 1] = f .. '*(' .. coef[j + 1] .. ')' .. ((j - k) > 0 and ('*(' .. xs .. ')^' .. (j - k)) or '')
    end
    if #terms == 0 then return 0 end
    return ev(table.concat(terms, '+'))
end
local function neg(v) if type(v) == 'number' then return -v end return v end
local function div(v, d) if type(v) == 'number' then return v / d end return v end

local function check(label, got, exp)
    local ok = type(got) == 'number' and math.abs(got - exp) <= 1e-6 * math.abs(exp) + 1e-9
    T.pruef(ok, string.format('%-26s soll=%-16s ist=%s', label, string.format('%.10g', exp),
        type(got) == 'number' and string.format('%.10g', got) or tostring(got)))
end

local function run(title, K, S, body)
    T.abschnitt(title)
    if not T.rechne(K, S) or not T.randLGS() then return end
    for i = 1, #S do
        T.info('   vne' .. i .. '(x)  = ' .. tostring(evs('vne' .. i .. '(x)')))
        T.info('   uneu' .. i .. '(x) = ' .. tostring(evs('uneu' .. i .. '(x)')))
    end
    local coefW, coefU = {}, {}
    local function Ls(i) local k1, k2 = K[S[i].k1], K[S[i].k2]; return fracStr(math.sqrt((k2.x - k1.x) ^ 2 + (k2.y - k1.y) ^ 2)) end
    local function cw(i)
        if not coefW[i] then local c, err = polyCoef('vne' .. i, Ls(i), 6); coefW[i] = c or {}; if not c then T.pruef(false, 'Interpolation vne' .. i .. ': ' .. tostring(err)) end end
        return coefW[i]
    end
    local function cu(i)
        if not coefU[i] then local c, err = polyCoef('uneu' .. i, Ls(i), 3); coefU[i] = c or {}; if not c then T.pruef(false, 'Interpolation uneu' .. i .. ': ' .. tostring(err)) end end
        return coefU[i]
    end
    local H = {}
    function H.w(i, x, exp) check(string.format('EI*w%d(%s)', i, xstr(x)), ev('vne' .. i .. '(' .. xstr(x) .. ')'), exp) end
    function H.phi(i, x, exp) check(string.format('phi%d(%s)', i, xstr(x)), div(neg(polyD(cw(i), 1, xstr(x))), S[i].EI), exp) end
    function H.M(i, x, exp) check(string.format('M%d(%s)', i, xstr(x)), neg(polyD(cw(i), 2, xstr(x))), exp) end
    function H.Q(i, x, exp) check(string.format('Q%d(%s)', i, xstr(x)), neg(polyD(cw(i), 3, xstr(x))), exp) end
    function H.u(i, x, exp) check(string.format('EA*u%d(%s)', i, xstr(x)), ev('uneu' .. i .. '(' .. xstr(x) .. ')'), exp) end
    function H.N(i, x, exp) check(string.format('N%d(%s)', i, xstr(x)), polyD(cu(i), 1, xstr(x)), exp) end
    function H.all(i, pts, fw, fphi, fM, fQ, fu, fN)
        for _, x in ipairs(pts) do
            local xv = xnum(x)
            if fw then H.w(i, x, fw(xv)) end
            if fphi then H.phi(i, x, fphi(xv)) end
            if fM then H.M(i, x, fM(xv)) end
            if fQ then H.Q(i, x, fQ(xv)) end
            if fu then H.u(i, x, fu(xv)) end
            if fN then H.N(i, x, fN(xv)) end
        end
    end
    body(H)
end

local zero = function() return 0 end
local fall = T.fall

fall('S1', function()
    -- Einfeldtraeger L=4, Dreieckslast q(x)=q*x/L: A=qL/6, B=qL/3, EIw=qx^5/(120L)-qLx^3/36+7qL^3x/360
    local q, L = 1, 4
    run('S1 Einfeldtraeger L=4, Dreieckslast q_A=0, q_B=1', { pinned(node(0)), roller(node(4)) },
        { bar(1, 2, { q_A = 0, q_B = 1, q_A_str = '0', q_B_str = '1' }) }, function(H)
        H.all(1, { 0, 1, 2, '5/2', 3, 4 },
            function(x) return q * x ^ 5 / (120 * L) - q * L * x ^ 3 / 36 + 7 * q * L ^ 3 * x / 360 end,
            function(x) return -(q * x ^ 4 / (24 * L) - q * L * x ^ 2 / 12 + 7 * q * L ^ 3 / 360) end,
            function(x) return q * L * x / 6 - q * x ^ 3 / (6 * L) end,
            function(x) return q * L / 6 - q * x ^ 2 / (2 * L) end,
            zero, zero)
    end)
end)

fall('S2', function()
    local F, L = 1, 3
    run('S2a Kragarm L=3, Einspannung links, F=1 (last_y) am Ende', (function() local K = { fixed(node(0)), node(3) }; K[2].last_y = F; return K end)(),
        { bar(1, 2) }, function(H)
        H.all(1, { 0, 1, '3/2', 2, 3 },
            function(x) return F * x ^ 2 * (3 * L - x) / 6 end,
            function(x) return -F * (L * x - x ^ 2 / 2) end,
            function(x) return -F * (L - x) end,
            function(x) return F end,
            zero, zero)
    end)
    run('S2b Kragarm L=3, Stab vom freien Ende (F=1) zur Einspannung', (function() local K = { node(0), fixed(node(3)) }; K[1].last_y = F; return K end)(),
        { bar(1, 2) }, function(H)
        H.all(1, { 0, 1, '3/2', 2, 3 },
            function(x) return F * (L - x) ^ 2 * (2 * L + x) / 6 end,
            function(x) return F * (L ^ 2 - x ^ 2) / 2 end,
            function(x) return -F * x end,
            function(x) return -F end,
            zero, zero)
    end)
    -- Stab von rechts nach links: lokal n = (0,-1), Last nach unten = -n
    run('S2c Kragarm L=4 von rechts (eingespannt) nach links (frei), F=1 nach unten', (function() local K = { fixed(node(4)), node(0) }; K[2].last_y = F; return K end)(),
        { bar(1, 2) }, function(H)
        local L4 = 4
        H.all(1, { 0, 1, 2, 3, 4 },
            function(x) return -F * x ^ 2 * (3 * L4 - x) / 6 end,
            function(x) return F * (L4 * x - x ^ 2 / 2) end,
            function(x) return F * (L4 - x) end,
            function(x) return -F end,
            zero, zero)
    end)
end)

fall('S3', function()
    -- beidseitig eingespannt L=4, q=1: EIw = q x^2 (L-x)^2 / 24
    local q, L = 1, 4
    run('S3 Beidseitig eingespannter Traeger L=4, q=1', { fixed(node(0)), fixed(node(4)) },
        { bar(1, 2, { q = 1, q_str = '1' }) }, function(H)
        H.all(1, { 0, 1, 2, 3, 4 },
            function(x) return q * x ^ 2 * (L - x) ^ 2 / 24 end,
            function(x) return -q * x * (L - x) * (L - 2 * x) / 12 end,
            function(x) return -q * (L ^ 2 - 6 * L * x + 6 * x ^ 2) / 12 end,
            function(x) return q * (L / 2 - x) end,
            zero, zero)
    end)
end)

fall('S4', function()
    -- Gerbertraeger: Einspannung 0 - Gelenk 4 - F=1 bei 6 - Rollenlager 8; Gelenkkraft F/2
    local F = 1
    run('S4 Gerbertraeger: Einspannung x=0, Gelenk x=4, F=1 bei x=6, Rollenlager x=8',
        (function() local K = { fixed(node(0)), node(4), node(6), roller(node(8)) }; K[2].gelenk = true; K[3].last_y = F; return K end)(),
        { bar(1, 2), bar(2, 3), bar(3, 4) }, function(H)
        H.all(1, { 0, 2, 4 },
            function(x) return 0.5 * F * x ^ 2 * (12 - x) / 6 end,
            function(x) return -0.5 * F * (4 * x - x ^ 2 / 2) end,
            function(x) return -0.5 * F * (4 - x) end,
            function(x) return 0.5 * F end,
            zero, zero)
        H.all(2, { 0, 1, 2 },
            function(x) return 32 / 3 - 5 * x / 3 - x ^ 3 / 12 end,
            function(x) return 5 / 3 + x ^ 2 / 4 end,
            function(x) return x / 2 end,
            function(x) return 0.5 end,
            zero, zero)
        H.all(3, { 0, 1, 2 },
            function(x) return 22 / 3 - 11 * x / 3 - (2 - x) ^ 3 / 12 end,
            function(x) return 11 / 3 - (2 - x) ^ 2 / 4 end,
            function(x) return (2 - x) / 2 end,
            function(x) return -0.5 end,
            zero, zero)
    end)
end)

fall('S5', function()
    -- Zweifeldtraeger 2 x 4, q=1: M_B = -qL^2/8, A = 3qL/8
    local L = 4
    run('S5 Zweifeldtraeger 4+4, q=1', { pinned(node(0)), roller(node(4)), roller(node(8)) },
        { bar(1, 2, { q = 1, q_str = '1' }), bar(2, 3, { q = 1, q_str = '1' }) }, function(H)
        local function w1(x) return x ^ 4 / 24 - x ^ 3 / 4 + 4 * x / 3 end
        local function phi1(x) return -(x ^ 3 / 6 - 3 * x ^ 2 / 4 + 4 / 3) end
        local function M1(x) return 1.5 * x - x ^ 2 / 2 end
        local function Q1(x) return 1.5 - x end
        H.all(1, { 0, 1, 2, 3, 4 }, w1, phi1, M1, Q1, zero, zero)
        H.all(2, { 0, 1, 2, 3, 4 }, function(x) return w1(L - x) end, function(x) return -phi1(L - x) end,
            function(x) return M1(L - x) end, function(x) return -Q1(L - x) end, zero, zero)
    end)
end)

fall('S6', function()
    -- 6a: Gelenklager + Drehfeder cm=2 links, Rollenlager rechts, L=4, q=1: M_A = -16/11
    run('S6a Balken L=4, links Gelenklager + Drehfeder cm=2, rechts Rollenlager, q=1',
        (function() local K = { pinned(node(0)), roller(node(4)) }; K[1].cm = 2; return K end)(),
        { bar(1, 2, { q = 1, q_str = '1' }) }, function(H)
        local c1, c2, c3 = -26 / 11, 16 / 11, 8 / 11
        H.all(1, { 0, 1, 2, 3, 4 },
            function(x) return x ^ 4 / 24 + c1 * x ^ 3 / 6 + c2 * x ^ 2 / 2 + c3 * x end,
            function(x) return -(x ^ 3 / 6 + c1 * x ^ 2 / 2 + c2 * x + c3) end,
            function(x) return -(x ^ 2 / 2 + c1 * x + c2) end,
            function(x) return -c1 - x end,
            zero, zero)
    end)
    -- 6b: Kragarm L=4, EI=2, q=1, Dehnfeder cy=3: w(L) = 16/33
    run('S6b Kragarm L=4, EI=2, q=1, Dehnfeder cy=3 am freien Ende',
        (function() local K = { fixed(node(0)), node(4) }; K[2].cy = 3; return K end)(),
        { bar(1, 2, { q = 1, q_str = '1', EI = 2 }) }, function(H)
        local c1, c2 = -28 / 11, 24 / 11
        H.all(1, { 0, 1, 2, 3, 4 },
            function(x) return x ^ 4 / 24 + c1 * x ^ 3 / 6 + c2 * x ^ 2 / 2 end,
            function(x) return -(x ^ 3 / 6 + c1 * x ^ 2 / 2 + c2 * x) / 2 end,
            function(x) return -(x ^ 2 / 2 + c1 * x + c2) end,
            function(x) return -c1 - x end,
            zero, zero)
    end)
    -- 6c: Gelenklager + cm=2 links, nur Dehnfeder cy=3 rechts: w(L) = 48/89
    run('S6c Balken L=4, links Gelenklager + cm=2, rechts nur Dehnfeder cy=3, q=1',
        (function() local K = { pinned(node(0)), node(4) }; K[1].cm = 2; K[2].cy = 3; return K end)(),
        { bar(1, 2, { q = 1, q_str = '1' }) }, function(H)
        local c1, c2, c3 = -212 / 89, 136 / 89, 68 / 89
        H.all(1, { 0, 1, 2, 3, 4 },
            function(x) return x ^ 4 / 24 + c1 * x ^ 3 / 6 + c2 * x ^ 2 / 2 + c3 * x end,
            function(x) return -(x ^ 3 / 6 + c1 * x ^ 2 / 2 + c2 * x + c3) end,
            function(x) return -(x ^ 2 / 2 + c1 * x + c2) end,
            function(x) return -c1 - x end,
            zero, zero)
    end)
end)

fall('S7', function()
    -- Rollenlager um 90 Grad gedreht (haelt horizontal), n=1, EA=2, F=1 quer
    run('S7a Kragarm L=4, rechts Rollenlager winkel=90, n=1 (EA=2), last_y=1',
        (function() local K = { fixed(node(0)), node(4) }; K[2].lager_y = true; K[2].winkel = 90; K[2].last_y = 1; return K end)(),
        { bar(1, 2, { n = 1, n_str = '1', EA = 2 }) }, function(H)
        H.all(1, { 0, 1, 2, 3, 4 },
            function(x) return x ^ 2 * (12 - x) / 6 end,
            function(x) return -(4 * x - x ^ 2 / 2) end,
            function(x) return -(4 - x) end,
            function(x) return 1 end,
            function(x) return (4 * x - x ^ 2) / 2 end,
            function(x) return 2 - x end)
    end)
    run('S7b Kragarm L=4, rechts Rollenlager winkel=90, last_x=1 (Last geht ins Lager)',
        (function() local K = { fixed(node(0)), node(4) }; K[2].lager_y = true; K[2].winkel = 90; K[2].last_x = 1; return K end)(),
        { bar(1, 2) }, function(H)
        H.all(1, { 0, 2, 4 }, zero, zero, zero, zero, zero, zero)
    end)
    run('S7c Kragarm L=4, rechts Rollenlager winkel=0, last_x=1',
        (function() local K = { fixed(node(0)), node(4) }; K[2].lager_y = true; K[2].last_x = 1; return K end)(),
        { bar(1, 2) }, function(H)
        H.all(1, { 0, 2, 4 }, zero, zero, zero, zero, function(x) return x end, function(x) return 1 end)
    end)
end)

fall('S8', function()
    -- Knotenmoment M0=1 am rechten Auflager: EIw = M0 x (L^2-x^2)/(6L)
    run('S8 Einfeldtraeger L=4, Knotenmoment last_m=1 am rechten Lager',
        (function() local K = { pinned(node(0)), roller(node(4)) }; K[2].last_m = 1; return K end)(),
        { bar(1, 2) }, function(H)
        H.all(1, { 0, 1, 2, 3, 4 },
            function(x) return x * (16 - x ^ 2) / 24 end,
            function(x) return -(16 - 3 * x ^ 2) / 24 end,
            function(x) return x / 4 end,
            function(x) return 0.25 end,
            zero, zero)
    end)
end)

fall('S9', function()
    -- Gleichlast + Dreieckslast ueberlagert (Superposition S1 + Gleichlast)
    local q, L = 1, 4
    run('S9 Einfeldtraeger L=4, q=1 plus Dreieckslast q_A=0, q_B=1', { pinned(node(0)), roller(node(4)) },
        { bar(1, 2, { q = 1, q_str = '1', q_A = 0, q_B = 1, q_A_str = '0', q_B_str = '1' }) }, function(H)
        H.all(1, { 0, 1, 2, 3, 4 },
            function(x) return q * x ^ 5 / (120 * L) - q * L * x ^ 3 / 36 + 7 * q * L ^ 3 * x / 360 + q * x * (L ^ 3 - 2 * L * x ^ 2 + x ^ 3) / 24 end,
            function(x) return -(q * x ^ 4 / (24 * L) - q * L * x ^ 2 / 12 + 7 * q * L ^ 3 / 360) - q * (L ^ 3 - 6 * L * x ^ 2 + 4 * x ^ 3) / 24 end,
            function(x) return q * L * x / 6 - q * x ^ 3 / (6 * L) + q * x * (L - x) / 2 end,
            function(x) return q * L / 6 - q * x ^ 2 / (2 * L) + q * (L / 2 - x) end,
            zero, zero)
    end)
end)

fall('S10', function()
    -- Knotenlast gedreht: last_x=1, last_w=90 -> F = (0,-1), nach oben
    run('S10 Kragarm L=3, last_x=1 mit last_w=90 (Kraft nach oben)',
        (function() local K = { fixed(node(0)), node(3) }; K[2].last_x = 1; K[2].last_w = 90; return K end)(),
        { bar(1, 2) }, function(H)
        H.all(1, { 0, 1, 2, 3 },
            function(x) return -x ^ 2 * (9 - x) / 6 end,
            function(x) return (3 * x - x ^ 2 / 2) end,
            function(x) return (3 - x) end,
            function(x) return -1 end,
            zero, zero)
    end)
end)

fall('S11', function()
    -- Feder cx=3 mit f_winkel=90 wirkt vertikal; Kragarm L=4, q=1: w(L) = 32/65
    run('S11 Kragarm L=4, q=1, Feder cx=3 mit f_winkel=90 am freien Ende',
        (function() local K = { fixed(node(0)), node(4) }; K[2].cx = 3; K[2].f_winkel = 90; return K end)(),
        { bar(1, 2, { q = 1, q_str = '1' }) }, function(H)
        local c1, c2 = -164 / 65, 136 / 65
        H.all(1, { 0, 1, 2, 3, 4 },
            function(x) return x ^ 4 / 24 + c1 * x ^ 3 / 6 + c2 * x ^ 2 / 2 end,
            function(x) return -(x ^ 3 / 6 + c1 * x ^ 2 / 2 + c2 * x) end,
            function(x) return -(x ^ 2 / 2 + c1 * x + c2) end,
            function(x) return -c1 - x end,
            zero, zero)
    end)
end)

fall('S12', function()
    -- Schraeger Kragarm (0,0)->(3,4), L=5, EA=2, last_y=1: F_t = 0.8, F_n = 0.6
    run('S12 Schraeger Kragarm (0,0)->(3,4), L=5, EA=2, last_y=1 am Ende',
        (function() local K = { fixed(node(0, 0)), node(3, 4) }; K[2].last_y = 1; return K end)(),
        { bar(1, 2, { EA = 2 }) }, function(H)
        H.all(1, { 0, 1, '5/2', 4, 5 },
            function(x) return 0.6 * x ^ 2 * (15 - x) / 6 end,
            function(x) return -0.6 * (5 * x - x ^ 2 / 2) end,
            function(x) return -0.6 * (5 - x) end,
            function(x) return 0.6 end,
            function(x) return 0.8 * x end,
            function(x) return 0.8 end)
    end)
end)

T.ende('Balken (Handrechnung)')
