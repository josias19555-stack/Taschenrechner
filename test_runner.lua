-- =========================================================================
-- TI-Nspire Statik & Tragwerk: Standalone Test- und Vorlagen-System
-- =========================================================================
-- Dieses Skript erm�glicht das lokale Ausf�hren und Testen aller
-- Berechnungs- und Export-Funktionen aus AktuellerStand.lua direkt im Terminal,
-- ohne dass die physische TI-Nspire-Software gestartet werden muss.
--
-- Ausf�hrung: lua test_runner.lua
-- =========================================================================

-- 1. TI-Nspire Environment Mocks
platform = { window = { invalidate = function() end } }
on = {}
var = { store = function(name, val) end }
timer = { start = function() end, stop = function() end }

-- 2. SymPy-backed TI-Nspire CAS bridge
cas_vars = {}
cas_funcs = {}
local cas_bridge_dir = 'cas_bridge_' .. tostring({}):gsub('[^%w]', '')
local cas_sequence = 0
local cas_base64_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function cas_base64_encode(value)
    local bits = {}
    for i = 1, #value do
        local byte = string.byte(value, i)
        for bit = 7, 0, -1 do bits[#bits + 1] = math.floor(byte / (2 ^ bit)) % 2 end
    end
    while #bits % 6 ~= 0 do bits[#bits + 1] = 0 end
    local encoded = {}
    for i = 1, #bits, 6 do
        local index = bits[i] * 32 + bits[i+1] * 16 + bits[i+2] * 8 + bits[i+3] * 4 + bits[i+4] * 2 + bits[i+5]
        encoded[#encoded + 1] = cas_base64_chars:sub(index + 1, index + 1)
    end
    while #encoded % 4 ~= 0 do encoded[#encoded + 1] = '=' end
    return table.concat(encoded)
end

local function cas_start_server()
    os.execute('if not exist "' .. cas_bridge_dir .. '" mkdir "' .. cas_bridge_dir .. '"')
    os.execute('start "" /b py -3 python_cas_server.py "' .. cas_bridge_dir .. '"')
end

local function cas_request(cmd)
    cas_sequence = cas_sequence + 1
    local suffix = tostring(cas_sequence) .. '.txt'
    local cas_request_path = cas_bridge_dir .. '/request_' .. suffix
    local cas_response_path = cas_bridge_dir .. '/response_' .. suffix
    local file = assert(io.open(cas_request_path, 'wb'))
    file:write(cas_base64_encode(cmd))
    file:close()
    for _ = 1, 1000000 do
        local response = io.open(cas_response_path, 'rb')
        if response then
            local result = (response:read('*a') or ''):gsub('%s+$', '')
            response:close()
            os.remove(cas_response_path)
            return result
        end
    end
    error('SymPy-CAS-Server antwortet nicht')
end

cas_start_server()

math.eval = function(cmd)
    if not cmd then return nil end
    local result = cas_request(cmd)
    local function_name, argument, body = cmd:match('^([%w_]+)%s*%(([%w_]+)%)%s*:=%s*(.*)$')
    if function_name then
        cas_funcs[function_name] = { arg = argument, body = body }
    else
        local variable_name, variable_body = cmd:match('^([%w_]+)%s*:=%s*(.*)$')
        if variable_name then cas_vars[variable_name] = variable_body end
    end
    if result == '__NIL__' or result == '' then return nil end
    if result:sub(1, 9) == '__ERROR__' then error(result) end
    if result == 'true' then return true end
    if result == 'false' then return false end
    return tonumber(result) or result
end

local function resetCasState()
    cas_request('__RESET__')
    cas_vars = {}
    cas_funcs = {}
end

local function shutdownCasServer()
    pcall(function() cas_request('__EXIT__') end)
    os.execute('del /q "' .. cas_bridge_dir .. '\\*" 2>nul')
    os.execute('rmdir "' .. cas_bridge_dir .. '" 2>nul')
end

-- 3. test.txt laden und lokale Kernfunktionen in _G spiegeln
local f_in = assert(io.open('test.txt', 'rb'))
local code = f_in:read('*a')
f_in:close()
if code:sub(1,3) == string.char(239,187,191) then code = code:sub(4) end

local hook = [[

_G.getKnoten = function() return knoten end
_G.getStaebe = function() return staebe end
_G.setKnoten = function(k) knoten = k end
_G.setStaebe = function(s) staebe = s end
_G.erstelleKnoten = erstelleKnoten
_G.erstelleStab = erstelleStab
_G.starteBerechnung = starteBerechnung
_G.exportBiegelinienToTI = exportBiegelinienToTI
_G.exportSchnittkraefteToTI = exportSchnittkraefteToTI
_G.rechneAktuellesSystem = rechneAktuellesSystem
_G.berechneSystemGleichungen = berechneSystemGleichungen
]]

assert(loadstring(code .. hook))()

print('===================================================================')
print('        TI-NSPIRE STATIK & TRAGWERK TEST-RUNNER BEREIT')
print('===================================================================\n')

-- =========================================================================
-- VORLAGE 1: Zweifeldtr�ger mit Dreieckslast & Einzellast (�bungsaufgabe)
-- =========================================================================
function testZweifeldtraeger()
    print('-------------------------------------------------------------------')
    print(' TESTFALL 1: Festlager, Gelenk bei B, Einspannung, Dreieckslast 0->4 kN/m')
    print('-------------------------------------------------------------------')
    autoKGV = false
    resetCasState()

    -- 3 Knoten
    local k = {
        erstelleKnoten(0, 0),
        erstelleKnoten(1, 0),
        erstelleKnoten(3, 0)
    }
    -- Knoten 1: Festeinspannung (A)
    k[1].lager_x = true; k[1].lager_y = true; k[1].lager_m = false
    k[1].x_str = '0'; k[1].y_str = '0'
    
    -- Knoten 2: inneres Gelenk bei B, keine aeusseren Lager
    k[2].lager_x = false; k[2].lager_y = false; k[2].lager_m = false
    k[2].gelenk = true
    k[2].x_str = '1'; k[2].y_str = '0'
    
    -- Knoten 3: Festeinspannung (C), Feld 2 ist doppelt so lang
    k[3].lager_x = true; k[3].lager_y = true; k[3].lager_m = true
    k[3].x_str = '3'; k[3].y_str = '0'

    setKnoten(k)

    -- 2 St�be
    local s = {
        erstelleStab(1, 2),
        erstelleStab(2, 3)
    }
    -- Stab 1: unbelastetes erstes Feld
    s[1].EA = 1e8; s[1].EI = 1
    
    -- Stab 2: Dreieckslast 0 bis q am rechten Ende
    s[2].q_A = 0; s[2].q_A_str = '0'
    s[2].q_B = 4; s[2].q_B_str = '4'
    s[2].EA = 1e8; s[2].EI = 1

    setStaebe(s)

    sym_vars = {}
    symbolischer_modus = false

    -- Berechnung starten
    starteBerechnung()
    exportBiegelinienToTI()

    local st = getStaebe()
    print('\n[1. Eingaben und lokale Zustandswerte]')
    for i, st_entry in ipairs(st) do
        print(string.format('Stab %d: q_A=%s, q_B=%s, EA=%s, EI=%s', i,
            tostring(st_entry.q_A_str), tostring(st_entry.q_B_str),
            tostring(st_entry.EA), tostring(st_entry.EI)))
        print('   s_local = ' .. table.concat(st_entry.s_local or {}, ', '))
        print('   v_local = ' .. table.concat(st_entry.v_local or {}, ', '))
    end

    print('\n[2. Superpositions-Randwerte (symb_start)]')
    print('Stab 1:')
    for k_name, v in pairs(st[1].symb_start or {}) do
        print(string.format('   %-6s = %s', k_name, tostring(v)))
    end
    print('Stab 2:')
    for k_name, v in pairs(st[2].symb_start or {}) do
        print(string.format('   %-6s = %s', k_name, tostring(v)))
    end

    print('\n[3. Exportierte Biegelinien-Ausdr�cke v_EI_stab(x)]')
    for k_name, v in pairs(cas_funcs) do
        if k_name:find('^v_') then
            print(k_name .. '(' .. v.arg .. ') := ' .. tostring(v.body) .. '\n')
        end
    end

    print('[4. Ausintegrierte Polynome fuer EI*v(x)]')
    print('   Feld 1, 0 <= x1 <= 1 m:')
    print('   EI*v1(x1) = 32/15*x1')
    print('   Feld 2, 0 <= x2 <= 2 m:')
    print('   EI*v2(x2) = x2^5/60 - 4/3*x2 + 32/15')
end

-- =========================================================================
-- VORLAGE 2: Einfeldtr�ger mit Gleichlast q
-- =========================================================================
function testEinfeldtraeger()
    print('-------------------------------------------------------------------')
    print(' TESTFALL 2: Einfeldtraeger (gelagert A-B) mit konstanter Gleichlast q')
    print('-------------------------------------------------------------------')
    autoKGV = false
    cas_vars = {}
    cas_funcs = {}

    local k = {
        erstelleKnoten(0, 0),
        erstelleKnoten(1, 0)
    }
    k[1].lager_x = true; k[1].lager_y = true; k[1].lager_m = false
    k[1].x_str = '0'; k[1].y_str = '0'

    k[2].lager_x = false; k[2].lager_y = true; k[2].lager_m = false
    k[2].x_str = '1*l'; k[2].y_str = '0'

    setKnoten(k)

    local s = {
        erstelleStab(1, 2)
    }
    s[1].q = 1; s[1].q_str = 'q'
    s[1].EA = 1e8; s[1].EI = 1

    setStaebe(s)

    sym_vars = { q = 1, l = 1 }
    symbolischer_modus = true

    starteBerechnung()
    exportBiegelinienToTI()

    local st = getStaebe()
    print('\n[1. Superpositions-Randwerte (symb_start)]')
    for k_name, v in pairs(st[1].symb_start) do
        print(string.format('   %-6s = %s', k_name, tostring(v)))
    end

    print('\n[2. Exportierte Biegelinien-Ausdr�cke]')
    for k_name, v in pairs(cas_funcs) do
        if k_name:find('^v_') then
            print(k_name .. '(' .. v.arg .. ') := ' .. tostring(v.body) .. '\n')
        end
    end
end

function testSymbolischerZweifeldtraeger()
    print('-------------------------------------------------------------------')
    print(' TESTFALL 3: Symbolisch, Dreieckslast q auf Feld 1, F=+q*l bei C')
    print('-------------------------------------------------------------------')
    autoKGV = false
    resetCasState()

    local k = { erstelleKnoten(0, 0), erstelleKnoten(1, 0), erstelleKnoten(2, 0) }
    k[1].lager_x = true; k[1].lager_y = true; k[1].lager_m = true
    k[1].x_str = '0'; k[1].y_str = '0'
    k[2].lager_x = false; k[2].lager_y = true; k[2].lager_m = false
    k[2].x_str = 'l'; k[2].y_str = '0'
    k[3].lager_x = true; k[3].lager_y = false; k[3].lager_m = true
    k[3].x_str = '2*l'; k[3].y_str = '0'
    k[3].last_y = 1; k[3].last_y_str = 'q*l'
    setKnoten(k)

    local s = { erstelleStab(1, 2), erstelleStab(2, 3) }
    s[1].q_A = 0; s[1].q_A_str = '0'; s[1].q_B = 1; s[1].q_B_str = 'q'
    s[1].EA = 1e8; s[1].EI = 1; s[2].EA = 1e8; s[2].EI = 1
    setStaebe(s)

    sym_vars = { q = 1, l = 1 }; symbolischer_modus = true
    starteBerechnung(); exportBiegelinienToTI()

    local st = getStaebe()
    print('\n[1. Dummywerte und lokale Zustandswerte]')
    for i, st_entry in ipairs(st) do
        print(string.format('Stab %d: q_A=%s, q_B=%s, v_local=%s', i,
            tostring(st_entry.q_A_str), tostring(st_entry.q_B_str),
            table.concat(st_entry.v_local or {}, ', ')))
    end
    print('\n[2. Symbolische Randkoeffizienten]')
    for i, st_entry in ipairs(st) do
        print('Stab ' .. i .. ':')
        for name, value in pairs(st_entry.symb_start or {}) do
            print(string.format('   %-6s = %s', name, tostring(value)))
        end
    end
    print('\n[3. Exportierte symbolische Biegelinien]')
    for name, value in pairs(cas_funcs) do
        if name:find('^v_') then
            print(name .. '(' .. value.arg .. ') := ' .. tostring(value.body) .. '\n')
        end
    end
end

-- =========================================================================
-- VORLAGE 4: Rahmen mit symbolischer horizontaler Feder am oberen Ende
-- =========================================================================
function testSymbolischeFederRahmen()
    print('-------------------------------------------------------------------')
    print(' TESTFALL 4: Rahmen A-C-B mit vertikalem Stab, Feder und Gleichlast')
    print('-------------------------------------------------------------------')
    autoKGV = false
    resetCasState()

    -- Geometrie: A=(0,0), C=(l,0), D=(l,2*l), B=(2*l,0).
    local k = {
        erstelleKnoten(0, 0),
        erstelleKnoten(1, 0),
        erstelleKnoten(1, 2),
        erstelleKnoten(2, 0)
    }

    -- A: Lager in y-Richtung; B: Lager in x-Richtung.
    k[1].lager_x = false; k[1].lager_y = true; k[1].lager_m = false
    k[1].x_str = '0'; k[1].y_str = '0'
    k[4].lager_x = true; k[4].lager_y = false; k[4].lager_m = false
    k[4].x_str = '2*l'; k[4].y_str = '0'

    -- C ist ein starrer Rahmeneckknoten; D hat die horizontale Feder c_F=EI/l^3.
    k[2].x_str = 'l'; k[2].y_str = '0'
    k[3].x_str = 'l'; k[3].y_str = '2*l'
    k[3].cx = 0; k[3].cx_str = 'EI/l^3'

    setKnoten(k)

    local s = {
        erstelleStab(1, 2),
        erstelleStab(2, 4),
        erstelleStab(2, 3)
    }

    -- Standardmodell des Taschenrechners: EA ist gegenüber EI sehr groß.
    for i = 1, 3 do s[i].EA = 1e10; s[i].EI = 1 end
    s[2].q = 1; s[2].q_str = 'q'
    s[2].q_A_str = '0'; s[2].q_B_str = '0'
    setStaebe(s)

    sym_vars = { q = 1, l = 1, EI = 1 }
    symbolischer_modus = true

    starteBerechnung()

    local st = getStaebe()
    local kn = getKnoten()
    print('\n[1. Modell und Feder]')
    print('Knoten 3: cx=' .. tostring(kn[3].cx) .. ', cx_str=' .. tostring(kn[3].cx_str))
    print('Last Stab 2: q=' .. tostring(st[2].q) .. ', q_str=' .. tostring(st[2].q_str))
    print('\n[2. Knotenverschiebungen und Reaktionen]')
    for i, node in ipairs(kn) do
        local pv = node.mat_pv or {{0, 0}, {0, 0}, {0, 0}}
        print(string.format('Knoten %d: u=(%s, %s), phi=%s, R=(%s, %s, %s)', i,
            tostring(pv[1][2]), tostring(pv[2][2]), tostring(pv[3][2]),
            tostring(node.Rx_glob), tostring(node.Ry_glob), tostring(node.Rm_glob)))
    end
    print('\n[3. Lokale Stabergebnisse]')
    for i, st_entry in ipairs(st) do
        print(string.format('Stab %d: s_local=%s, v_local=%s', i,
            table.concat(st_entry.s_local or {}, ', '),
            table.concat(st_entry.v_local or {}, ', ')))
    end
    print('\n[4. Symbolische Biegelinien]')
    exportBiegelinienToTI()
    for i = 1, #st do
        local name = 'v_EI_stab' .. i
        local value = cas_funcs[name]
        if value then
            print(name .. '(' .. value.arg .. ') := ' .. tostring(value.body) .. '\n')
        end
        if i == 2 then
            for _, part in ipairs({'c1', 'c2', 'c3', 'c4', 'load'}) do
                local debug_value = cas_funcs['v_EI_dbg_' .. part .. '_' .. i]
                if debug_value then print('dbg_' .. part .. '_stab2 := ' .. tostring(debug_value.body)) end
            end
        end
    end
end

-- Hauptausf�hrung
if arg and arg[1] == 'last' then
    testSymbolischeFederRahmen()
else
    testZweifeldtraeger()
    testSymbolischerZweifeldtraeger()
    testSymbolischeFederRahmen()
end
shutdownCasServer()
