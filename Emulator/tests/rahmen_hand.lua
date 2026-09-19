-- Rand-LGS (vne_i = EI*w_i, uneu_i = EA*u_i) gegen Handrechnung: Rahmen (1)-(9).
-- Weltkoordinaten: x nach rechts, y nach UNTEN. Lokal: x von k1 nach k2, n = (-dy, dx)/L,
-- phi = -w', M = -EI w'', Q = M', N = EA u'.
-- Aufruf: luajit Emulator/tests/rahmen_hand.lua [Filter, z. B. "2 Zweigelenk"]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, ev = T.node, T.fixed, T.pinned, T.ev
local function bar(a, b, f) return T.bar(a, b, f) end

local TOL = 1e-6

-- Gauss-Elimination (kleines LGS)
local function solve(A, y)
    local n = #y
    for i = 1, n do
        local p = i
        for r = i + 1, n do if math.abs(A[r][i]) > math.abs(A[p][i]) then p = r end end
        A[i], A[p] = A[p], A[i]; y[i], y[p] = y[p], y[i]
        for r = i + 1, n do
            local f = A[r][i] / A[i][i]
            for c = i, n do A[r][c] = A[r][c] - f * A[i][c] end
            y[r] = y[r] - f * y[i]
        end
    end
    local x = {}
    for i = n, 1, -1 do
        local s = y[i]
        for c = i + 1, n do s = s - A[i][c] * x[c] end
        x[i] = s / A[i][i]
    end
    return x
end

-- Polynomkoeffizienten (Grad n) der CAS-Funktion name auf [0, L] durch Interpolation
local function fitPoly(name, L, n)
    local A, y = {}, {}
    for k = 0, n do
        local x = L * k / n
        local v = ev(name .. '(' .. string.format('%.17g', x) .. ')')
        if type(v) ~= 'number' then return nil, v end
        A[k + 1] = {}
        for j = 0, n do A[k + 1][j + 1] = x ^ j end
        y[k + 1] = v
    end
    return solve(A, y)
end

local function polyval(c, x) local s = 0; for j = #c, 1, -1 do s = s * x + (c[j] or 0) end; return s end
local function d1(c, x) local s = 0; for j = #c, 2, -1 do s = s * x + (j - 1) * c[j] end; return s end
local function d2(c, x) local s = 0; for j = #c, 3, -1 do s = s * x + (j - 1) * (j - 2) * c[j] end; return s end
local function d3(c, x) local s = 0; for j = #c, 4, -1 do s = s * x + (j - 1) * (j - 2) * (j - 3) * c[j] end; return s end

-- Koeffizientenvergleich: Abweichung |dc_k| L^k relativ zur Skala max_k |c_k| L^k
local function compare(title, name, L, hand, n)
    local fit, err = fitPoly(name, L, n)
    if not fit then T.pruef(false, title .. ' ' .. name .. ': CAS-Fehler ' .. tostring(err)); return nil end
    local scale, maxdev = 0, 0
    for k = 0, n do scale = math.max(scale, math.abs(hand[k + 1] or 0) * L ^ k) end
    if scale == 0 then scale = 1 end
    local parts = {}
    for k = 0, n do
        maxdev = math.max(maxdev, math.abs((fit[k + 1] or 0) - (hand[k + 1] or 0)) * L ^ k / scale)
        parts[#parts + 1] = string.format('x^%d: %.8g (Hand %.8g)', k, fit[k + 1], hand[k + 1] or 0)
    end
    T.pruef(maxdev <= TOL, string.format('%-24s %-6s relAbw=%.1e | %s', title, name, maxdev, table.concat(parts, '; ')))
    return fit
end

local function check(title, expected, actual)
    local dev = math.abs(expected - actual) / math.max(1e-12, math.abs(expected), 1)
    T.pruef(dev <= TOL, string.format('%-48s soll %-14.10g ist %-14.10g relAbw=%.1e', title, expected, actual, dev))
end

local function run(title, K, S)
    T.abschnitt(title)
    return T.rechne(K, S) and T.randLGS()
end

-- Handloesung L-Rahmen: F = Querkraft am Riegelende (nach unten), Hk = Horizontalkraft am Riegelende,
-- Hc = Horizontalkraft an der Ecke (nur Stuetze)
local function lhand(F, Hk, Hc, EA, EIc, EIb, h, L)
    local H = Hk + Hc
    local v1 = { 0, 0, F * L / 2 + H * h / 2, -H / 6, 0 }
    local u1 = { 0, -F, 0 }
    local w1h = polyval(v1, h) / EIc
    local phi1h = -d1(v1, h) / EIc
    local u1h = -F * h / EA
    local v2 = { EIb * (-u1h), -EIb * phi1h, F * L / 2, -F / 6, 0 }
    local u2 = { EA * w1h, Hk, 0 }
    return v1, u1, v2, u2
end

local function lcheck(F, Hk, Hc, EA, EIc, EIb, h, L)
    local v1, u1, v2, u2 = lhand(F, Hk, Hc, EA, EIc, EIb, h, L)
    local H = Hk + Hc
    local c1 = compare('Stuetze EI*w', 'vne1', h, v1, 4)
    local cu1 = compare('Stuetze EA*u', 'uneu1', h, u1, 2)
    local c2 = compare('Riegel EI*w', 'vne2', L, v2, 4)
    local cu2 = compare('Riegel EA*u', 'uneu2', L, u2, 2)
    if c1 and c2 and cu1 and cu2 then
        check('w_Riegelende', F * L ^ 3 / (3 * EIb) + F * L ^ 2 * h / EIc + H * h ^ 2 * L / (2 * EIc) + F * h / EA, polyval(c2, L) / EIb)
        check('u_Riegelende (Hk L/EA + w1(h))', Hk * L / EA + polyval(v1, h) / EIc, polyval(cu2, L) / EA)
        check('M_Stuetzenfuss = -F L - H h', -F * L - H * h, -d2(c1, 0))
        check('M_Ecke Stuetze = M_Ecke Riegel', -d2(c1, h), -d2(c2, 0))
        check('phi Ecke Stuetze = phi Riegel', -d1(c1, h) / EIc, -d1(c2, 0) / EIb)
    end
    return c1, cu1, c2, cu2
end

local function lrahmen(F, H, EA, EIc, EIb, h, L, title)
    local K = { fixed(node(0, h)), node(0, 0), node(L, 0) }
    K[3].last_y, K[3].last_x = F, H
    local S = { bar(1, 2, { EI = EIc, EA = EA }), bar(2, 3, { EI = EIb, EA = EA }) }
    if run(title, K, S) then lcheck(F, H, 0, EA, EIc, EIb, h, L) end
end

local fall = T.fall

fall('1a L-Rahmen F', function() lrahmen(1, 0, 1e9, 2, 1, 3, 2, '(1a) L-Kragrahmen h=3 L=2 EIc=2 EIb=1 EA=1e9, F=1 am Riegelende') end)
fall('1b L-Rahmen H', function() lrahmen(0, 1, 1e9, 2, 1, 3, 2, '(1b) L-Kragrahmen, H=1 (nach rechts) am Riegelende') end)
fall('1c L-Rahmen EA', function() lrahmen(1, 0.5, 50, 2, 1, 3, 2, '(1c) L-Kragrahmen, F=1 und H=0.5, EA=50 (Laengsverformung exakt)') end)

fall('2 Zweigelenk', function()
    local h, L, H, EI, EA = 3, 4, 1, 1, 1e9
    local K = { pinned(node(0, h)), node(0, 0), node(L, 0), pinned(node(L, h)) }
    K[2].last_x = H
    local S = { bar(1, 2, { EI = EI, EA = EA }), bar(2, 3, { EI = EI, EA = EA }), bar(3, 4, { EI = EI, EA = EA }) }
    if not run('(2) Zweigelenkrahmen h=3 L=4 EI=1 EA=1e9, H=1 an linker Ecke', K, S) then return end
    local delta = H * h ^ 2 * (2 * h + L) / (12 * EI)
    local c1 = compare('linke Stuetze EI*w', 'vne1', h, { 0, H * h * (3 * h + L) / 12, 0, -H / 12, 0 }, 4)
    compare('linke Stuetze EA*u', 'uneu1', h, { 0, H * h / L, 0 }, 2)
    local c2 = compare('Riegel EI*w', 'vne2', L, { 0, H * h * L / 12, -H * h / 4, H * h / (6 * L), 0 }, 4)
    compare('Riegel EA*u', 'uneu2', L, { EA * delta, -H / 2, 0 }, 2)
    local c3 = compare('rechte Stuetze EI*w', 'vne3', h, { -H * h ^ 2 * (2 * h + L) / 12, H * h * L / 12, H * h / 4, -H / 12, 0 }, 4)
    compare('rechte Stuetze EA*u', 'uneu3', h, { H * h ^ 2 / L, -H * h / L, 0 }, 2)
    if c1 and c2 and c3 then
        check('Eckverschiebung delta = H h^2 (2h+L)/(12 EI)', delta, polyval(c1, h) / EI)
        check('Eckverschiebung rechts (-w3(0))', delta, -polyval(c3, 0) / EI)
        check('M Ecke links = H h/2', H * h / 2, -d2(c1, h))
        check('M Ecke rechts = -H h/2', -H * h / 2, -d2(c3, 0))
        check('Q linke Stuetze = H/2', H / 2, -d3(c1, 0))
        check('M Fuss links = 0', 0, -d2(c1, 0))
        check('M Fuss rechts = 0', 0, -d2(c3, h))
    end
end)

fall('3 Dreigelenk', function()
    local h, L, q, EI, EA = 3, 6, 1, 1, 1e9
    local K = { pinned(node(0, h)), node(0, 0), node(L / 2, 0), node(L, 0), pinned(node(L, h)) }
    K[3].gelenk = true
    local S = { bar(1, 2, { EI = EI, EA = EA }), bar(2, 3, { EI = EI, EA = EA, q = q, q_str = tostring(q) }),
                bar(3, 4, { EI = EI, EA = EA, q = q, q_str = tostring(q) }), bar(4, 5, { EI = EI, EA = EA }) }
    if not run('(3) Dreigelenkrahmen h=3 L=6, q=1 auf Riegel, Gelenk in Riegelmitte', K, S) then return end
    local d0 = EI * q * L * h / (2 * EA)
    local c1 = compare('linke Stuetze EI*w', 'vne1', h, { 0, -q * L ^ 2 * h / 48, 0, q * L ^ 2 / (48 * h), 0 }, 4)
    compare('linke Stuetze EA*u', 'uneu1', h, { 0, -q * L / 2, 0 }, 2)
    local c2 = compare('Riegel links EI*w', 'vne2', L / 2, { d0, q * L ^ 2 * h / 24, q * L ^ 2 / 16, -q * L / 12, q / 24 }, 4)
    local cu2 = compare('Riegel links EA*u', 'uneu2', L / 2, { q * L ^ 3 / (16 * h), -q * L ^ 2 / (8 * h), 0 }, 2)
    local c3 = compare('Riegel rechts EI*w', 'vne3', L / 2, { q * L ^ 4 / 128 + q * L ^ 3 * h / 48 + d0, -(q * L ^ 3 / 48 + q * L ^ 2 * h / 24), 0, 0, q / 24 }, 4)
    compare('Riegel rechts EA*u', 'uneu3', L / 2, { 0, -q * L ^ 2 / (8 * h), 0 }, 2)
    local c4 = compare('rechte Stuetze EI*w', 'vne4', h, { 0, -q * L ^ 2 * h / 24, q * L ^ 2 / 16, -q * L ^ 2 / (48 * h), 0 }, 4)
    compare('rechte Stuetze EA*u', 'uneu4', h, { q * L * h / 2, -q * L / 2, 0 }, 2)
    if c1 and c2 and c3 and c4 and cu2 then
        check('Eckmoment links = -q L^2/8', -q * L ^ 2 / 8, -d2(c1, h))
        check('Eckmoment Riegel links x=0', -q * L ^ 2 / 8, -d2(c2, 0))
        check('Gelenkmoment M2(L/2) = 0', 0, -d2(c2, L / 2))
        check('Gelenkmoment M3(0) = 0', 0, -d2(c3, 0))
        check('Eckmoment rechts = -q L^2/8', -q * L ^ 2 / 8, -d2(c4, 0))
        check('Gelenkdurchbiegung q L^4/128 + q L^3 h/48', q * L ^ 4 / 128 + q * L ^ 3 * h / 48 + d0, polyval(c2, L / 2))
        check('Eckverdrehung links = -q L^2 h/(24 EI)', -q * L ^ 2 * h / (24 * EI), -d1(c1, h) / EI)
        check('Horizontalschub N2 = -q L^2/(8h)', -q * L ^ 2 / (8 * h), d1(cu2, 0))
        check('Q Stuetze links = -q L^2/(8h)', -q * L ^ 2 / (8 * h), -d3(c1, 0))
        check('Gelenk: Q2(L/2) = 0', 0, -d3(c2, L / 2))
    end
end)

fall('4 Schraeg', function()
    -- K1(0,0) eingespannt -> K2(a,-a) (45 Grad nach rechts oben) -> K3(a+b,-a); F nach unten, H nach rechts an K3
    local a, b, F, H, EI1, EI2, EA = 2, 3, 1, 0.5, 2, 1, 100
    local r2 = math.sqrt(2)
    local L1 = a * r2
    local K = { fixed(node(0, 0)), node(a, -a), node(a + b, -a) }
    K[3].last_y, K[3].last_x = F, H
    local S = { bar(1, 2, { EI = EI1, EA = EA }), bar(2, 3, { EI = EI2, EA = EA }) }
    if not run('(4) Kragrahmen mit 45-Grad-Stab a=2 b=3, F=1 nach unten, H=0.5 nach rechts', K, S) then return end
    local N1, Q1 = (H - F) / r2, (H + F) / r2
    local v1 = { 0, 0, F * b / 2 + Q1 * L1 / 2, -Q1 / 6, 0 }
    local w1L = polyval(v1, L1) / EI1
    local phi1L = -d1(v1, L1) / EI1
    local u1L = N1 * L1 / EA
    local Ux, Uy = u1L / r2 + w1L / r2, -u1L / r2 + w1L / r2
    local v2 = { EI2 * Uy, -EI2 * phi1L, F * b / 2, -F / 6, 0 }
    local c1 = compare('Schraegstab EI*w', 'vne1', L1, v1, 4)
    local cu1 = compare('Schraegstab EA*u', 'uneu1', L1, { 0, N1, 0 }, 2)
    local c2 = compare('Riegel EI*w', 'vne2', b, v2, 4)
    local cu2 = compare('Riegel EA*u', 'uneu2', b, { EA * Ux, H, 0 }, 2)
    if c1 and c2 and cu1 and cu2 then
        local ux1 = (polyval(cu1, L1) / EA) / r2 + (polyval(c1, L1) / EI1) / r2
        local uy1 = -(polyval(cu1, L1) / EA) / r2 + (polyval(c1, L1) / EI1) / r2
        local ux2, uy2 = polyval(cu2, 0) / EA, polyval(c2, 0) / EI2
        check('Ecke Ux aus Stab 1 = aus Stab 2', ux1, ux2)
        check('Ecke Uy aus Stab 1 = aus Stab 2', uy1, uy2)
        check('Ecke Ux Hand', Ux, ux2)
        check('Ecke Uy Hand', Uy, uy2)
        local N0, Q0, M0 = d1(cu1, 0), -d3(c1, 0), -d2(c1, 0)
        check('Auflager Rx = -H', -H, -(N0 / r2 + Q0 / r2))
        check('Auflager Ry = -F', -F, -(-N0 / r2 + Q0 / r2))
        check('M Fuss = -F(a+b) - H a', -F * (a + b) - H * a, M0)
        check('M Ecke = -F b', -F * b, -d2(c1, L1))
        check('phi Ecke Stab 1 = Stab 2', -d1(c1, L1) / EI1, -d1(c2, 0) / EI2)
    end
end)

fall('5 T-Knoten', function()
    -- K1(-a,0), K3(b,0), K4(0,c) eingespannt, K2(0,0) mit Knotenmoment M0
    local a, b, c, EI1, EI2, EI3, EA, M0 = 2, 3, 2, 1, 2, 1, 1e9, 1
    local K = { fixed(node(-a, 0)), node(0, 0), fixed(node(b, 0)), fixed(node(0, c)) }
    K[2].last_m = M0
    local S = { bar(1, 2, { EI = EI1, EA = EA }), bar(2, 3, { EI = EI2, EA = EA }), bar(2, 4, { EI = EI3, EA = EA }) }
    if not run('(5) T-Anschluss, Knotenmoment M0=1', K, S) then return end
    local th = M0 / (4 * (EI1 / a + EI2 / b + EI3 / c))
    local Q1, Q2, Q3 = 6 * EI1 * th / a ^ 2, 6 * EI2 * th / b ^ 2, 6 * EI3 * th / c ^ 2
    local N1, N2, N3 = -Q3 * b / (a + b), Q3 * a / (a + b), Q1 - Q2
    local ux, uy = N1 * a / EA, -N3 * c / EA
    local c1 = compare('Stab links EI*w', 'vne1', a, { 0, 0, EI1 * th / a, -EI1 * th / a ^ 2, 0 }, 4)
    compare('Stab links EA*u', 'uneu1', a, { 0, N1, 0 }, 2)
    local c2 = compare('Stab rechts EI*w', 'vne2', b, { 0, -EI2 * th, 2 * EI2 * th / b, -EI2 * th / b ^ 2, 0 }, 4)
    compare('Stab rechts EA*u', 'uneu2', b, { EA * ux, N2, 0 }, 2)
    local c3 = compare('Stab unten EI*w', 'vne3', c, { 0, -EI3 * th, 2 * EI3 * th / c, -EI3 * th / c ^ 2, 0 }, 4)
    compare('Stab unten EA*u', 'uneu3', c, { EA * uy, N3, 0 }, 2)
    if c1 and c2 and c3 then
        check('theta = M0/(4 sum EI/L)', th, -d1(c2, 0) / EI2)
        check('theta aus Stab 1', th, -d1(c1, a) / EI1)
        check('theta aus Stab 3', th, -d1(c3, 0) / EI3)
        check('M1(a) = 4 EI1 th/a', 4 * EI1 * th / a, -d2(c1, a))
        check('M2(0) = -4 EI2 th/b', -4 * EI2 * th / b, -d2(c2, 0))
        check('M3(0) = -4 EI3 th/c', -4 * EI3 * th / c, -d2(c3, 0))
        check('Momentengleichgewicht am Knoten', 0, -d2(c2, 0) - d2(c3, 0) + d2(c1, a) + M0)
        check('Fernmoment M1(0) = -2 EI1 th/a', -2 * EI1 * th / a, -d2(c1, 0))
        check('Fernmoment M2(b) = 2 EI2 th/b', 2 * EI2 * th / b, -d2(c2, b))
    end
end)

fall('6 Eckgelenk', function()
    -- Zweigelenkrahmen mit Vollgelenk an der rechten Ecke: rechte Stuetze ist Pendelstab
    local h, L, H, EI, EA = 3, 4, 1, 1, 1e9
    local K = { pinned(node(0, h)), node(0, 0), node(L, 0), pinned(node(L, h)) }
    K[2].last_x = H; K[3].gelenk = true
    local S = { bar(1, 2, { EI = EI, EA = EA }), bar(2, 3, { EI = EI, EA = EA }), bar(3, 4, { EI = EI, EA = EA }) }
    if not run('(6) Zweigelenkrahmen mit Vollgelenk an rechter Ecke, H=1', K, S) then return end
    local delta = H * h ^ 2 * (h + L) / (3 * EI)
    local c1 = compare('linke Stuetze EI*w', 'vne1', h, { 0, H * h ^ 2 / 2 + H * h * L / 3, 0, -H / 6, 0 }, 4)
    compare('linke Stuetze EA*u', 'uneu1', h, { 0, H * h / L, 0 }, 2)
    local c2 = compare('Riegel EI*w', 'vne2', L, { 0, H * h * L / 3, -H * h / 2, H * h / (6 * L), 0 }, 4)
    compare('Riegel EA*u', 'uneu2', L, { EA * delta, 0, 0 }, 2)
    local c3 = compare('Pendelstuetze EI*w', 'vne3', h, { -EI * delta, EI * delta / h, 0, 0, 0 }, 4)
    compare('Pendelstuetze EA*u', 'uneu3', h, { H * h ^ 2 / L, -H * h / L, 0 }, 2)
    if c1 and c2 and c3 then
        check('delta = H h^2 (h+L)/(3 EI)', delta, polyval(c1, h) / EI)
        check('M Ecke links = H h', H * h, -d2(c1, h))
        check('M Eckgelenk rechts = 0', 0, -d2(c2, L))
        check('M Pendelstuetze oben = 0', 0, -d2(c3, 0))
        check('Q linke Stuetze = H', H, -d3(c1, 0))
        check('Q Pendelstuetze = 0', 0, -d3(c3, 0))
    end
end)

fall('7 Rolle', function()
    -- L-Rahmen mit Rollenlager am Riegelende, H an der Ecke: 1x statisch unbestimmt (Kraftgroessenverfahren)
    local h, L, EIc, EIb, EA, Hc = 3, 2, 2, 1, 1e9, 1
    local K = { fixed(node(0, h)), node(0, 0), node(L, 0) }
    K[2].last_x = Hc; K[3].lager_y = true
    local S = { bar(1, 2, { EI = EIc, EA = EA }), bar(2, 3, { EI = EIb, EA = EA }) }
    if not run('(7) L-Rahmen, Rollenlager am Riegelende, H=1 an der Ecke', K, S) then return end
    local d10 = Hc * h ^ 2 * L / (2 * EIc)
    local d11 = L ^ 3 / (3 * EIb) + L ^ 2 * h / EIc + h / EA
    local _, _, c2 = lcheck(-d10 / d11, 0, Hc, EA, EIc, EIb, h, L)
    if c2 then check('w Riegelende = 0 (Rollenlager)', 0, polyval(c2, L)) end
end)

fall('8 Feder', function()
    -- wie (7), aber Feder cy statt Rollenlager
    local h, L, EIc, EIb, EA, Hc, cy = 3, 2, 2, 1, 1e9, 1, 0.5
    local K = { fixed(node(0, h)), node(0, 0), node(L, 0) }
    K[2].last_x = Hc; K[3].cy = cy
    local S = { bar(1, 2, { EI = EIc, EA = EA }), bar(2, 3, { EI = EIb, EA = EA }) }
    if not run('(8) L-Rahmen, Feder cy=0.5 am Riegelende, H=1 an der Ecke', K, S) then return end
    local d10 = Hc * h ^ 2 * L / (2 * EIc)
    local d11 = L ^ 3 / (3 * EIb) + L ^ 2 * h / EIc + h / EA
    local _, _, c2 = lcheck(-cy * d10 / (1 + cy * d11), 0, Hc, EA, EIc, EIb, h, L)
    if c2 then check('Feder: Q2(L) = -cy w2(L)', -cy * polyval(c2, L) / EIb, -d3(c2, L)) end
end)

fall('9 Gedreht', function()
    -- L-Rahmen, um 90 Grad gedrehtes Rollenlager am Riegelende (haelt x fest), F nach unten
    local h, L, EIc, EIb, EA, F0 = 3, 2, 2, 1, 1e9, 1
    local K = { fixed(node(0, h)), node(0, 0), node(L, 0) }
    K[3].last_y = F0; K[3].lager_y = true; K[3].winkel = 90
    local S = { bar(1, 2, { EI = EIc, EA = EA }), bar(2, 3, { EI = EIb, EA = EA }) }
    if not run('(9) L-Rahmen, Rollenlager winkel=90 am Riegelende, F=1 nach unten', K, S) then return end
    local Hk = -(F0 * L * h ^ 2 / (2 * EIc)) / (h ^ 3 / (3 * EIc) + L / EA)
    local _, _, _, cu2 = lcheck(F0, Hk, 0, EA, EIc, EIb, h, L)
    if cu2 then check('u Riegelende = 0 (gedrehtes Lager)', 0, polyval(cu2, L) / EA) end
end)

T.ende('Rahmen (Handrechnung)')
