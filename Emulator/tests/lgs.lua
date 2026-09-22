-- LGS-Export (ggw_a, ggw_b, ggw_x): das exportierte Gleichungssystem wird geloest und mit der
-- FEM-Loesung verglichen. Damit ist sichergestellt, dass die Unbekannten dieselben Zahlen liefern,
-- die der E-Modus anzeigt -- auch die Gelenkgroessen:
--   Momentengelenk : Gx_i, Gy_i   (globale Komponenten)
--   N-Gelenk       : Gq_i, Gm_i   (lokal quer und Moment; die Normalkraft ist geloest)
--   Q-Gelenk       : Gn_i, Gm_i   (lokal laengs und Moment; die Querkraft ist geloest)
-- Aufruf: luajit Emulator/tests/lgs.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'common.lua')
local node, fixed, pinned, roller = T.node, T.fixed, T.pinned, T.roller

-- exportiertes LGS aus dem CAS holen und numerisch loesen
local function loeseLGS()
    local xs = tostring(T.evs('ggw_x'))
    local namen = {}
    for n in xs:gmatch('%[([%w_]+)%]') do namen[#namen + 1] = n end
    local n = #namen
    if n == 0 then return nil, namen end
    local A, b = {}, {}
    for r = 1, n do
        A[r] = {}
        for c = 1, n do A[r][c] = tonumber(T.ev(('ggw_a[%d,%d]'):format(r, c))) or 0 end
        b[r] = tonumber(T.ev(('ggw_b[%d,1]'):format(r))) or 0
    end
    for k = 1, n do
        local p, best = k, math.abs(A[k][k])
        for i = k + 1, n do if math.abs(A[i][k]) > best then p, best = i, math.abs(A[i][k]) end end
        if best < 1e-12 then return nil, namen end
        A[k], A[p] = A[p], A[k]; b[k], b[p] = b[p], b[k]
        for i = k + 1, n do
            local f = A[i][k] / A[k][k]
            for j = k, n do A[i][j] = A[i][j] - f * A[k][j] end
            b[i] = b[i] - f * b[k]
        end
    end
    local x = {}
    for i = n, 1, -1 do
        local sum = b[i]
        for j = i + 1, n do sum = sum - A[i][j] * x[j] end
        x[i] = sum / A[i][i]
    end
    local werte = {}
    for i = 1, n do werte[namen[i]] = x[i] end
    return werte, namen
end

local function rechneUndLoese(K, S)
    T.reset()
    setKnoten(K); setStaebe(S)
    starteBerechnung()
    exportLGSMatrixToTI()
    return loeseLGS()
end

-- Stabendgroessen der FEM (wie im E-Modus angezeigt)
local function endA(s) return -(s.s_local[1] or 0), -(s.s_local[2] or 0), -(s.s_local[3] or 0) end
local function endB(s) return s.s_local[4] or 0, s.s_local[5] or 0, s.s_local[6] or 0 end

local fall = T.fall

fall('1 Q-Gelenk', function()
    T.abschnitt('Querkraftgelenk: uebertragen werden N (Gn) und M (Gm), nicht Gx/Gy')
    local K = { fixed(node(0, 0)), node(2, 0), roller(node(4, 0)) }
    local S = { T.bar(1, 2), T.bar(2, 3, { q = 1, q_str = '1' }) }
    S[2].q_gelenk_A = true
    local x, namen = rechneUndLoese(K, S)
    if not x then T.pruef(false, 'LGS nicht loesbar: ' .. table.concat(namen, ',')); return end
    T.wahr('Unbekannte Gn_1 vorhanden', x.gn_1 ~= nil, table.concat(namen, ','))
    T.wahr('Unbekannte Gm_1 vorhanden', x.gm_1 ~= nil, table.concat(namen, ','))
    T.wahr('kein Gx_1/Gy_1 mehr', x.gx_1 == nil and x.gy_1 == nil, table.concat(namen, ','))
    local s2 = getStaebe()[2]
    local N_a, _, M_a = endA(s2)
    T.zahl('Gn_1 = N am Gelenk (FEM)', x.gn_1, N_a, 1e-6)
    T.zahl('Gm_1 = M am Gelenk (FEM)', x.gm_1, M_a, 1e-6)
    local k1, k3 = getKnoten()[1], getKnoten()[3]
    T.zahl('M_A = Einspannmoment (FEM)', x.m_a, k1.Rm_glob or 0, 1e-6)
    T.zahl('B_v = Auflagerkraft (FEM)', x.b_v, -(k3.Ry_glob or 0), 1e-6)
end)

fall('2 N-Gelenk', function()
    T.abschnitt('Normalkraftgelenk: uebertragen werden Q (Gq) und M (Gm)')
    local K = { pinned(node(0, 0)), node(0, 2), pinned(node(3, 2)) }
    local S = { T.bar(1, 2), T.bar(2, 3, { q = 1, q_str = '1' }) }
    S[1].n_gelenk_B = true
    local x, namen = rechneUndLoese(K, S)
    if not x then T.pruef(false, 'LGS nicht loesbar: ' .. table.concat(namen, ',')); return end
    T.wahr('Unbekannte Gq_1 vorhanden', x.gq_1 ~= nil, table.concat(namen, ','))
    T.wahr('Unbekannte Gm_1 vorhanden', x.gm_1 ~= nil, table.concat(namen, ','))
    local s1 = getStaebe()[1]
    local _, Q_b, M_b = endB(s1)
    T.zahl('Gq_1 = Q am Gelenk (FEM)', x.gq_1, Q_b, 1e-6)
    T.zahl('Gm_1 = M am Gelenk (FEM)', x.gm_1, M_b, 1e-6)
    local k1, k3 = getKnoten()[1], getKnoten()[3]
    T.zahl('A_h = Auflagerkraft (FEM)', x.a_h, k1.Rx_glob or 0, 1e-6)
    T.zahl('B_v = Auflagerkraft (FEM)', x.b_v, -(k3.Ry_glob or 0), 1e-6)
end)

fall('3 Momentengelenk', function()
    T.abschnitt('Vollgelenk: globale Komponenten Gx, Gy wie bisher')
    local K = { fixed(node(0, 0)), node(2, 0), roller(node(4, 0)) }
    local S = { T.bar(1, 2, { q = 1, q_str = '1' }), T.bar(2, 3, { q = 1, q_str = '1' }) }
    K[2].gelenk = true
    local x, namen = rechneUndLoese(K, S)
    if not x then T.pruef(false, 'LGS nicht loesbar: ' .. table.concat(namen, ',')); return end
    T.wahr('Unbekannte Gx_1, Gy_1 vorhanden', x.gx_1 ~= nil and x.gy_1 ~= nil, table.concat(namen, ','))
    T.wahr('kein Gm_1 (Gelenk uebertraegt kein Moment)', x.gm_1 == nil, table.concat(namen, ','))
    -- waagerechter Balken: global x = Normalkraft, global y = Querkraft am Gelenk
    local s2 = getStaebe()[2]
    local N_a, Q_a = endA(s2)
    T.zahl('Gx_1 = N am Gelenk', math.abs(x.gx_1), math.abs(N_a), 1e-6)
    T.zahl('Gy_1 = Q am Gelenk', math.abs(x.gy_1), math.abs(Q_a), 1e-6)
    local k1, k3 = getKnoten()[1], getKnoten()[3]
    T.zahl('M_A = Einspannmoment (FEM)', x.m_a, k1.Rm_glob or 0, 1e-6)
    T.zahl('B_v = Auflagerkraft (FEM)', x.b_v, -(k3.Ry_glob or 0), 1e-6)
end)

fall('4 Rahmen mit schraegem Stab', function()
    T.abschnitt('Dreigelenkrahmen mit schraegem Riegel: Auflagerkraefte aus dem LGS gegen die FEM')
    local K = { pinned(node(0, 0)), node(0, 2), node(2, 3), node(4, 2), pinned(node(4, 0)) }
    K[3].gelenk = true
    K[3].last_x = 1
    local S = { T.bar(1, 2), T.bar(2, 3), T.bar(3, 4), T.bar(4, 5) }
    local x, namen = rechneUndLoese(K, S)
    if not x then T.pruef(false, 'LGS nicht loesbar: ' .. table.concat(namen, ',')); return end
    local k1, k5 = getKnoten()[1], getKnoten()[5]
    T.zahl('A_h (FEM)', x.a_h, k1.Rx_glob or 0, 1e-6)
    T.zahl('A_v (FEM)', x.a_v, -(k1.Ry_glob or 0), 1e-6)
    T.zahl('B_h (FEM)', x.b_h, k5.Rx_glob or 0, 1e-6)
    T.zahl('B_v (FEM)', x.b_v, -(k5.Ry_glob or 0), 1e-6)
end)

T.ende('LGS-Export gegen FEM')
