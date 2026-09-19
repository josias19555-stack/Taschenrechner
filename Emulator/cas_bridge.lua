-- SymPy-Bruecke fuer math.eval ausserhalb des TI-Nspire (LuaJIT / Lua 5.1).
--
-- Verwendung:
--   local cas = dofile(<pfad>/cas_bridge.lua)
--   cas.start()            -- Python-Server starten, math.eval installieren
--   cas.loadBiegelinie()   -- Biegelinieneu.lua laden, lokale Funktionen in _G spiegeln
--   ...                    -- Tests
--   cas.stop()
--
-- Der Server (python_cas_server.py) laeuft dauerhaft, Anfragen gehen ueber
-- nummerierte Dateien in %TEMP% (nicht im OneDrive-Ordner). Schreiben erfolgt
-- atomar (.tmp -> rename), damit nie halbe Dateien gelesen werden.

local M = {}

local function scriptDir()
    local source = debug.getinfo(1, "S").source:gsub("^@", "")
    return (source:match("^(.*[/\\])") or ".\\")
end

M.dir = scriptDir()
M.timeout = tonumber(os.getenv("CAS_TIMEOUT") or "") or 120 -- Sekunden pro Anfrage
M.verbose = os.getenv("CAS_VERBOSE") ~= nil -- jede Anfrage auf stderr protokollieren
M.stats = { requests = 0, started = nil }

cas_vars = cas_vars or {}
cas_funcs = cas_funcs or {}

local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function base64(data)
    return ((data:gsub('.', function(char)
        local byte, bits = char:byte(), ''
        for i = 8, 1, -1 do bits = bits .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and '1' or '0') end
        return bits
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(bits)
        if #bits < 6 then return '' end
        local value = 0
        for i = 1, 6 do value = value + (bits:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b64chars:sub(value + 1, value + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local function fileExists(path)
    local handle = io.open(path, 'rb')
    if handle then handle:close(); return true end
    return false
end

local function waitFor(path, seconds, what)
    local deadline = os.time() + seconds
    while not fileExists(path) do
        if os.time() > deadline then
            local log = M.log and io.open(M.log, 'rb')
            local details = log and log:read('*a') or ''
            if log then log:close() end
            error('CAS-Bruecke: Zeitueberschreitung bei ' .. what .. (details ~= '' and ('\nServer-Log:\n' .. details) or ''), 2)
        end
    end
end

local sequence = 0

function M.request(command)
    sequence = sequence + 1
    local base = M.bridge .. '\\request_' .. sequence
    local handle = assert(io.open(base .. '.tmp', 'wb'))
    handle:write(base64(command))
    handle:close()
    assert(os.rename(base .. '.tmp', base .. '.txt'))
    local response_path = M.bridge .. '\\response_' .. sequence .. '.txt'
    waitFor(response_path, M.timeout, command:sub(1, 80))
    local response = assert(io.open(response_path, 'rb'))
    local result = (response:read('*a') or ''):gsub('%s+$', '')
    response:close()
    os.remove(response_path)
    M.stats.requests = M.stats.requests + 1
    return result
end

-- math.eval-Nachbildung: Zahl, true/false, nil oder TI-String; Fehler -> error()
function M.eval(command)
    if not command then return nil end
    if M.verbose then io.stderr:write('[CAS] ' .. command .. '\n') end
    local result = M.request(command)
    local fname, argument, body = command:match('^%s*([%w_]+)%s*%(([%w_]+)%)%s*:=%s*(.*)$')
    if fname then
        cas_funcs[fname] = { arg = argument, body = body }
    else
        local vname, vbody = command:match('^%s*([%w_]+)%s*:=%s*(.*)$')
        if vname then cas_vars[vname] = vbody end
    end
    if result:sub(1, 7) == '__STR__' then return result:sub(8) end -- string(...) bleibt String
    if result == '__NIL__' or result == '' then return nil end
    if result:sub(1, 9) == '__ERROR__' then error(result, 2) end
    if result == 'true' then return true end
    if result == 'false' then return false end
    return tonumber(result) or result
end

function M.reset()
    M.request('__RESET__')
    cas_vars, cas_funcs = {}, {}
end

function M.start()
    local temp = os.getenv('TEMP') or os.getenv('TMP') or '.'
    M.bridge = temp .. '\\ti_cas_bridge_' .. os.time() .. '_' .. tostring({}):gsub('[^%w]', '')
    os.execute('mkdir "' .. M.bridge .. '" >nul 2>nul')
    local server = M.dir .. 'python_cas_server.py'
    -- Ausgabe in eine Logdatei: sonst erbt der Server stdout und haelt Pipes (luajit | grep) offen
    M.log = M.bridge .. '\\server.log'
    os.execute('start "" /b py -3 "' .. server .. '" "' .. M.bridge .. '" 120 >"' .. M.log .. '" 2>&1')
    waitFor(M.bridge .. '\\server_ready', 60, 'Serverstart (py -3 mit sympy installiert?)')
    M.stats.started = os.clock()
    math.eval = M.eval
    return M
end

function M.stop()
    if not M.bridge then return end
    pcall(M.request, '__EXIT__')
    -- warten, bis der Server beendet ist und seine Logdatei freigibt (max. 5 s)
    local deadline = os.time() + 5
    while not os.remove(M.log) and fileExists(M.log) and os.time() <= deadline do end
    os.execute('del /q "' .. M.bridge .. '\\*" >nul 2>nul')
    os.execute('rmdir "' .. M.bridge .. '" >nul 2>nul')
    M.bridge = nil
end

-- Laedt Biegelinieneu.lua und macht die lokalen Kernfunktionen global erreichbar.
-- extra_hook: zusaetzlicher Lua-Code, der im Skript-Scope laeuft (z. B. '_G.f = lokaleFunktion')
function M.loadBiegelinie(path, extra_hook)
    path = path or os.getenv('BIEGELINIE') or (M.dir .. '..\\Tragwerksskript\\Biegelinieneu.lua')
    if not fileExists(path) then path = 'Biegelinieneu.lua' end
    local handle = assert(io.open(path, 'rb'), 'Biegelinieneu.lua nicht gefunden: ' .. path)
    local code = handle:read('*a')
    handle:close()
    if code:sub(1, 3) == string.char(239, 187, 191) then code = code:sub(4) end
    local hook = [[

_G.getKnoten = function() return knoten end
_G.getStaebe = function() return staebe end
_G.setKnoten = function(k) knoten = k end
_G.setStaebe = function(s) staebe = s end
_G.erstelleKnoten = erstelleKnoten
_G.erstelleStab = erstelleStab
_G.starteBerechnung = starteBerechnung
_G.exportBiegelinienToTI = exportBiegelinienToTI
_G.exportULinienToTI = exportULinienToTI
_G.exportBiegelinienNeuToTI = exportBiegelinienNeuToTI
_G.exportULinienNeuToTI = exportULinienNeuToTI
_G.exportSchnittkraefteToTI = exportSchnittkraefteToTI
_G.rechneAktuellesSystem = rechneAktuellesSystem
_G.berechneSystemGleichungen = berechneSystemGleichungen
-- lokale Oberflaechenzustaende lesen/setzen (auswahl = false setzt nil)
_G.uiZustand = function(t)
    t = t or {}
    if t.auswahl ~= nil then auswahl = t.auswahl or nil end
    if t.warnungKinematisch ~= nil then warnungKinematisch = t.warnungKinematisch end
    if t.warnungStarrBestimmt ~= nil then warnungStarrBestimmt = t.warnungStarrBestimmt end
    if t.pvvPrompt ~= nil then pvvPrompt = t.pvvPrompt end
    if t.pvvModus ~= nil then pvvModus = t.pvvModus end
    if t.in_pvv_release ~= nil then in_pvv_release = t.in_pvv_release end
    return { auswahl = auswahl, warnungKinematisch = warnungKinematisch, warnungStarrBestimmt = warnungStarrBestimmt,
             pvvPrompt = pvvPrompt, pvvModus = pvvModus, in_pvv_release = in_pvv_release }
end
]]
    assert(loadstring(code .. hook .. '\n' .. (extra_hook or ''), '=' .. path))()
    return path
end

-- TI-Umgebung, soweit die Skripte sie ausserhalb von on.paint brauchen
platform = platform or { window = { invalidate = function() end, width = function() return 318 end, height = function() return 212 end } }
on = on or {}
var = var or { store = function() end }
timer = timer or { start = function() end, stop = function() end, getMilliSecCounter = function() return 0 end }

return M
