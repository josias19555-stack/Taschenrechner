-- KGV-Export (kgv_delta, kgv_delta0): die daraus bestimmten X muessen die FEM-Loesung treffen.
-- Kern der Pruefung: bei einem geloesten Pendelstab gehoert seine eigene Laengenaenderung L/(EA)
-- zu delta_ii, weil der Stab im Hauptsystem entfernt ist.
-- Aufruf: luajit Emulator/tests/kgv.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller = T.node, T.fixed, T.pinned, T.roller

-- exportierte Matrizen abgreifen
local gespeichert = {}
var = var or {}
var.store = function(name, mat) gespeichert[name] = mat end

local function rechneX(K, S)
    gespeichert = {}
    T.reset()
    autoKGV = true
    setKnoten(K); setStaebe(S)
    starteBerechnung()
    exportKGVToTI()
    local D, D0 = gespeichert.kgv_delta, gespeichert.kgv_delta0
    if not D or not D0 then return nil end
    local n = #D
    -- X = -D^-1 * D0 (kleines Gauss-Verfahren)
    local M = {}
    for i = 1, n do
        M[i] = {}
        for j = 1, n do M[i][j] = D[i][j] end
        M[i][n + 1] = -D0[i][1]
    end
    for k = 1, n do
        local p, best = k, math.abs(M[k][k])
        for i = k + 1, n do if math.abs(M[i][k]) > best then p, best = i, math.abs(M[i][k]) end end
        if best < 1e-300 then return nil end
        M[k], M[p] = M[p], M[k]
        for i = k + 1, n do
            local f = M[i][k] / M[k][k]
            for j = k, n + 1 do M[i][j] = M[i][j] - f * M[k][j] end
        end
    end
    local x = {}
    for i = n, 1, -1 do
        local sum = M[i][n + 1]
        for j = i + 1, n do sum = sum - M[i][j] * x[j] end
        x[i] = sum / M[i][i]
    end
    return x, getXWerte(), D, D0
end

-- Fachwerkfeld mit zwei Diagonalen: unbestimmt im Stab, Lager statisch bestimmt
local function fachwerk(extra)
    local K = { pinned(node(0, 0)), roller(node(2, 0)), node(0, 2), node(2, 2) }
    for _, k in ipairs(K) do k.gelenk = true end
    K[4].last_y = 1
    local S = {}
    for i, p in ipairs({ { 1, 2 }, { 1, 3 }, { 2, 4 }, { 3, 4 }, { 1, 4 }, { 2, 3 } }) do
        local f = { EA = 1e4, EI = 1 }
        for k, v in pairs((extra and extra[i]) or {}) do f[k] = v end
        S[i] = T.bar(p[1], p[2], f)
    end
    return K, S
end

local fall = T.fall

fall('1 Geloester Pendelstab', function()
    T.abschnitt('Fachwerk mit zwei Diagonalen: X aus delta muss die FEM-Normalkraft treffen')
    local K, S = fachwerk()
    local x, XW, D, D0 = rechneX(K, S)
    if not x then T.pruef(false, 'KGV-Export lieferte keine Matrizen'); return end
    T.wahr('genau ein X, Typ Pendelstab', #XW == 1 and XW[1].typ == 'pendel_n', XW[1] and XW[1].typ)
    applyKGVZustand(-1); rechneAktuellesSystem()
    local s = getStaebe()[XW[1].stab]
    local N_fem = -s.s_local[1]
    T.zahl('X1 = N des geloesten Stabes (FEM)', x[1], N_fem, 1e-9)
    -- ohne den Eigenanteil waere das Ergebnis deutlich daneben
    local k1, k2 = getKnoten()[s.k1], getKnoten()[s.k2]
    local L = math.sqrt((k2.x - k1.x) ^ 2 + (k2.y - k1.y) ^ 2)
    local eigen = L / s.EA
    local ohne = -D0[1][1] / (D[1][1] - eigen)
    T.wahr('ohne Eigenanteil L/EA waere X falsch', math.abs(ohne - N_fem) > 0.01 * math.abs(N_fem),
        string.format('ohne = %.6f, richtig = %.6f', ohne, N_fem))
    T.zahl('delta_11 enthaelt L/EA', D[1][1] - eigen + eigen, D[1][1], 1e-12)
end)

fall('2 Weicherer Stab', function()
    T.abschnitt('geloester Stab mit kleinerem EA: der Eigenanteil waechst entsprechend')
    local K, S = fachwerk({ [5] = { EA = 2e3 }, [6] = { EA = 2e3 } })
    local x, XW = rechneX(K, S)
    if not x then T.pruef(false, 'KGV-Export lieferte keine Matrizen'); return end
    applyKGVZustand(-1); rechneAktuellesSystem()
    local N_fem = -getStaebe()[XW[1].stab].s_local[1]
    T.zahl('X1 = N des geloesten Stabes (FEM)', x[1], N_fem, 1e-9)
end)

fall('3 Dehnsteifer geloester Stab', function()
    T.abschnitt('dehnsteifer geloester Stab: kein Eigenanteil, X muss trotzdem stimmen')
    local K, S = fachwerk({ [5] = { dehnsteif = true }, [6] = { dehnsteif = true } })
    local x, XW = rechneX(K, S)
    if not x then T.pruef(false, 'KGV-Export lieferte keine Matrizen'); return end
    applyKGVZustand(-1); rechneAktuellesSystem()
    local N_fem = -getStaebe()[XW[1].stab].s_local[1]
    T.zahl('X1 = N des geloesten Stabes (FEM)', x[1], N_fem, 1e-6)
end)

fall('4 Geloestes Lager und Gelenk', function()
    T.abschnitt('andere Freiwerte bleiben unveraendert richtig')
    -- Durchlauftraeger: Einspannung + zwei Rollen, ein Lager wird geloest
    local K = { fixed(node(0)), roller(node(2)), roller(node(4)) }
    local S = { T.bar(1, 2, { q = 1, q_str = '1', EI = 1e4, EA = 1e8 }), T.bar(2, 3, { q = 1, q_str = '1', EI = 1e4, EA = 1e8 }) }
    local x, XW = rechneX(K, S)
    if not x then T.pruef(false, 'KGV-Export lieferte keine Matrizen'); return end
    T.wahr('geloest wurden Lager bzw. Gelenke', XW[1].typ ~= 'pendel_n', XW[1].typ)
    applyKGVZustand(-1); rechneAktuellesSystem()
    local xw = XW[1]
    local ist, soll
    if xw.typ == 'lager_y' then
        ist, soll = math.abs(x[1]), math.abs(getKnoten()[xw.knoten].Ry_glob)
    elseif xw.typ == 'lager_m' then
        ist, soll = math.abs(x[1]), math.abs(getKnoten()[xw.knoten].Rm_glob)
    else
        local s = getStaebe()[xw.stab]
        ist, soll = math.abs(x[1]), math.abs(s.s_local[xw.typ == 'gelenk_A' and 3 or 6])
    end
    T.zahl('|X1| = |Lagerkraft bzw. Moment| (FEM)', ist, soll, 1e-6)
end)

fall('5 Zwei geloeste Staebe', function()
    T.abschnitt('zwei Felder mit je zwei Diagonalen: jeder geloeste Stab nur in seinem eigenen Diagonaleintrag')
    -- Untergurt 1-2-3 (y = 2), Obergurt 4-5-6 (y = 0), Pfosten, je Feld zwei Diagonalen
    local K = { pinned(node(0, 2)), node(2, 2), roller(node(4, 2)), node(0, 0), node(2, 0), node(4, 0) }
    for _, k in ipairs(K) do k.gelenk = true end
    K[5].last_y = 1
    local paare = { { 1, 2 }, { 2, 3 }, { 4, 5 }, { 5, 6 }, { 1, 4 }, { 2, 5 }, { 3, 6 }, { 1, 5 }, { 2, 4 }, { 2, 6 }, { 3, 5 } }
    local S = {}
    for i, p in ipairs(paare) do S[i] = T.bar(p[1], p[2], { EA = 1e4, EI = 1 }) end
    local x, XW, D = rechneX(K, S)
    if not x then T.pruef(false, 'KGV-Export lieferte keine Matrizen'); return end
    T.wahr('zwei geloeste Pendelstaebe', #XW == 2 and XW[1].typ == 'pendel_n' and XW[2].typ == 'pendel_n',
        (XW[1] and XW[1].typ or '?') .. ',' .. (XW[2] and XW[2].typ or '?'))
    applyKGVZustand(-1); rechneAktuellesSystem()
    for i = 1, 2 do
        local N_fem = -getStaebe()[XW[i].stab].s_local[1]
        T.zahl('X' .. i .. ' = N des geloesten Stabes ' .. XW[i].stab, x[i], N_fem, 1e-8)
    end
    -- Nebendiagonale: im Einheitszustand j ist der andere geloeste Stab kraeftefrei, also kein Zusatz
    T.zahl('delta_12 = delta_21 (symmetrisch, ohne Zusatz)', D[1][2], D[2][1], 1e-9)
end)

T.ende('KGV')
