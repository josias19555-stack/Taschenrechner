-- Querschnitt.lua: eigenstaendiger Querschnittseditor fuer TI-Nspire CX II CAS
-- Version 2: Massiv-Querschnitte (alle Standardformen) und Duennwandige Profile
-- Mit automatischer Loch-Erkennung, Steiner-Satz, und Hauptachsen-Darstellung.

local massiv_elemente = {}
local duenn_elemente = {}
local kraefte = {}
local pending = {}
local mode = "idle" -- Easteregg1
local selected_idx = nil
local selected_type = nil -- "massiv" oder "duenn"
local hover_type, hover_idx = nil, nil

local scale, ox, oy, raster = 24, 160, 106, 1
local kos_size = 48
local kos_pixel_length = kos_size
local plane, swapped, rotation = 2, false, 180
local menuOpen, menuRow, menuPage = false, 1, 1

local default_t = 1 -- Standarddicke fuer duennwandige Profile
torsion_xi = 1 -- Profilbeiwert fuer offene Duennwandprofile
local zahlenFormat = 3 -- 1: Brueche/Wurzelbrueche, 2: Brueche, 3: Dezimal
local casToleranz = 5

local function evaluate_input(expr)
    -- Wertet zuerst den TI-Nspire-Ausdruck und danach eine einfache Lua-Formel aus.
    local ok, val = false, nil
    if math.eval then
        ok, val = pcall(function() return tonumber(math.eval("approx(" .. expr .. ")")) end)
    end
    if not ok or not val then
        ok, val = pcall(function() return load("return " .. expr)() end)
    end
    if ok and type(val) == "number" then return val end
    return nil
end

local function floatToFrac_lua(value, tolerance, max_denominator)
    if math.abs(value) < 1e-10 then return "0" end
    local sign = value < 0 and "-" or ""
    value = math.abs(value)
    max_denominator = max_denominator or 10000
    local h1, h2, k1, k2 = 1, 0, 0, 1
    local rest = value
    for _ = 1, 30 do
        local a = math.floor(rest)
        local h, k = a * h1 + h2, a * k1 + k2
        h2, h1, k2, k1 = h1, h, k1, k
        if k > max_denominator then break end
        if math.abs(value - h / k) <= tolerance + 1e-10 then
            if k == 1 then return sign .. tostring(h) end
            return sign .. tostring(h) .. "/" .. tostring(k)
        end
        if math.abs(rest - a) < 1e-10 then break end
        rest = 1 / (rest - a)
    end
    return nil
end

local function smartToFracStr(value, tolerance)
    if math.abs(value) < 1e-10 then return "0" end
    if math.abs(value - 1) < 1e-10 then return "1" end
    if math.abs(value + 1) < 1e-10 then return "-1" end
    if zahlenFormat ~= 3 then
        local strict = floatToFrac_lua(value, 1e-5, 50)
        if strict then return strict end
        if zahlenFormat == 1 and value * value <= 10000 then
            local square_fraction = floatToFrac_lua(value * value, 1e-4, 2000)
            if square_fraction then
                local numerator, denominator = square_fraction:match("^(%d+)/(%d+)$")
                local num, den = tonumber(numerator) or tonumber(square_fraction), tonumber(denominator) or 1
                local function extract_square(number)
                    for factor = math.floor(math.sqrt(number)), 2, -1 do
                        if number % (factor * factor) == 0 then return factor, number / (factor * factor) end
                    end
                    return 1, number
                end
                local coeff_num, rest_num = extract_square(num)
                local coeff_den, rest_den = extract_square(den)
                local final_coeff, final_rest = extract_square(rest_num * rest_den)
                local total_coeff = coeff_num * final_coeff
                local function gcd(a, b) while b ~= 0 do a, b = b, a % b end return a end
                local divisor = gcd(total_coeff, coeff_den * rest_den)
                total_coeff = total_coeff / divisor
                local final_den = coeff_den * rest_den / divisor
                local prefix = value < 0 and "-" or ""
                if final_rest == 1 then return prefix .. (final_den == 1 and tostring(total_coeff) or string.format("%d/%d", total_coeff, final_den)) end
                local root = "sqrt(" .. final_rest .. ")"
                if total_coeff == 1 and final_den == 1 then return prefix .. root end
                if final_den == 1 then return prefix .. total_coeff .. "*" .. root end
                if total_coeff == 1 then return prefix .. root .. "/" .. final_den end
                return prefix .. total_coeff .. "*" .. root .. "/" .. final_den
            end
        end
        local loose = floatToFrac_lua(value, tolerance, 10000)
        if loose then return loose end
    end
    return string.format("%.4f", value)
end

local function formatLabel(value)
    if type(value) ~= "number" then return "0" end
    return smartToFracStr(value, 10^(-casToleranz))
end

local function point_to_line_dist(px, py, x1, y1, x2, y2)
    local l2 = (x1-x2)^2 + (y1-y2)^2
    if l2 == 0 then return math.sqrt((px-x1)^2 + (py-y1)^2) end
    local t = ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / l2
    t = math.max(0, math.min(1, t))
    local proj_x, proj_y = x1 + t * (x2 - x1), y1 + t * (y2 - y1)
    return math.sqrt((px - proj_x)^2 + (py - proj_y)^2)
end
local showResults = false
local showTable = false
local table_scroll_x = 0
local table_scroll_y = 0
local results_scroll_y = 0
local overlap_pending_elem = nil
local is_numeric_system = false
local inputMode, inputText = false, ""
local status = "Massiv | Duennwand | Ergebnisse"
local escape_clear_pending = false
local sigma_input_step = 0
local sigma_N, sigma_My, sigma_Mz = nil, nil, nil
local sigma_oblique = false
local sigma_results = nil
local sigma_scroll_y, sigma_table_scroll_y = 0, 0
local shear_results = nil
local shear_input_step = 0
local shear_Qa, shear_Qb = nil, nil
local shear_N, shear_M = 0, 0
local shear_profile_visible = false
local shear_hover_index = nil
local shear_view_mode = 0
local shear_selector_open = false
local shear_external_input = false
local show_shear_center = false
local show_shear_moment_table = false
local shear_moment_table = nil
local force_unit, length_unit, moment_unit = "N", "mm", "Nm"
local force_units = {N = 1, kN = 1000}
local length_units = {m = 1000, dm = 100, cm = 10, mm = 1}
local moment_units = {Nm = 1000, Ncm = 10, Nmm = 1, kNm = 1000000, kNcm = 10000, kNmm = 1000}

local function unit_factor(unit)
    return force_units[unit] or length_units[unit] or moment_units[unit] or 1
end

local function input_to_internal(value, unit)
    return value * unit_factor(unit)
end

local function cycle_unit(current, units)
    for index, unit in ipairs(units) do
        if unit == current then return units[index % #units + 1] end
    end
    return units[1]
end

local function unit_label(power)
    if power == 1 then return length_unit end
    return length_unit .. "^" .. power
end

local function display_length(value) return value / unit_factor(length_unit) end
local function display_area(value) return value / unit_factor(length_unit)^2 end
local function display_volume(value) return value / unit_factor(length_unit)^3 end
local function display_inertia(value) return value / unit_factor(length_unit)^4 end
local function display_moment(value) return value / unit_factor(moment_unit) end
local function display_force(value) return value / unit_factor(force_unit) end
local torsion_input_step, torsion_M, torsion_results = 0, nil, nil
local berechneSchubspannungsResultate
local system_results = nil
kernMode = 0
local kern_lines, kern_pts, kern_vertices = {}, {}, {}
local kern_hover_line, kern_hover_pt = nil, nil
local kern_build = nil
local kern_collect_points
local find_closed_cells
local coordinatesForDisplay

local function current_axes()
    local p = {{"x", "y"}, {"y", "z"}, {"x", "z"}}
    local a, b = p[plane][1], p[plane][2]
    if swapped then return b, a end
    return a, b
end

local function openSigmaInput(oblique)
    sigma_oblique = oblique == true
    sigma_input_step, inputText = 1, ""
    sigma_results, sigma_scroll_y, sigma_table_scroll_y = nil, 0, 0
    showResults, showTable, menuOpen = true, false, false
    local a, b = current_axes()
    status = "N in Newton eingeben, dann Enter."
    if sigma_oblique then status = "N, M" .. a .. " und M" .. b .. " eingeben." end
end

local function openShearInput()
    shear_input_step, inputText = 1, ""
    shear_N, shear_M = 0, 0
    shear_results = nil
    shear_view_mode, shear_selector_open = 0, false
    showResults, showTable, menuOpen = false, false, false
    local a, b = current_axes()
        status = "Q" .. a .. " und Q" .. b .. " eingeben, dann Enter." 
end

local function openShearFromForces()
    shear_input_step, shear_Qa, shear_Qb = 0, 0, 0
    shear_results = berechneSchubspannungsResultate(0, 0)
    shear_view_mode, shear_selector_open = 0, false
    showResults, showTable, menuOpen = false, false, false
    if shear_results then
        shear_selector_open = true
        status = "Eingetragene Kräfte ausgewertet. V: Verlauf wählen."
    else
        status = "Schubspannung nicht berechenbar."
    end
    platform.window:invalidate()
end

local function openTorsionInput()
    torsion_input_step, inputText = 1, ""
    torsion_results = nil
    showResults, showTable, menuOpen = true, false, false
    status = "Torsionsmoment MT in Nm eingeben."
end

local function berechneTorsionsResultat(moment)
    local r = system_results
    if not r then return nil end
    local torsion_constant, area = find_closed_cells()
    local closed = torsion_constant > 1e-9 and area > 1e-9
    local inertia = closed and torsion_constant or (r.It or 0)
    local thickness = default_t
    for _, elem in ipairs(duenn_elemente) do thickness = math.max(thickness, elem.t or default_t) end
    local tau
    if closed then
        tau = math.abs(moment / math.max(2 * area * thickness, 1e-12))
    else
        tau = math.abs(moment / math.max(inertia, 1e-12) * thickness)
    end
    return {M = moment, It = inertia, Am = area, tau = tau, closed = closed}
end

local function aktualisiereTorsionsverlauf(result)
    if not result or not shear_results or not shear_results.samples then return end
    local q_t = result.closed and result.M / math.max(2 * result.Am, 1e-12) or result.M / math.max(result.It, 1e-12)
    local max_total = 0
    for _, sample in ipairs(shear_results.samples) do
        local direction = result.closed and (sample.torsion_sign or 1) or (sample.direction or 1)
        sample.tau_t = direction * q_t / math.max(sample.thickness or default_t, 1e-12)
        if result.closed then
            sample.tau_total = (sample.tau or 0) + sample.tau_t
        else
            sample.tau_total = math.abs(sample.tau or 0) + math.abs(sample.tau_t)
        end
        max_total = math.max(max_total, math.abs(sample.tau_total))
    end
    shear_results.max_tau_total = max_total
end

local function torsionTauAtSample(sample)
    if not torsion_results then return sample.tau_t or 0 end
    local q_t = torsion_results.closed
        and torsion_results.M / math.max(2 * torsion_results.Am, 1e-12)
        or torsion_results.M / math.max(torsion_results.It, 1e-12)
    local direction = torsion_results.closed and (sample.torsion_sign or 1) or (sample.direction or 1)
    return direction * q_t / math.max(sample.thickness or default_t, 1e-12)
end

local function combinedTauAtSample(sample)
    local shear_tau = sample.tau or 0
    local torsion_tau = torsionTauAtSample(sample)
    if (torsion_results and torsion_results.closed) or (shear_results and shear_results.thin_closed) then
        return shear_tau + torsion_tau
    end
    return math.abs(shear_tau) + math.abs(torsion_tau)
end

local function displayedMomentDensity(sample)
    local r = system_results
    if not r then return 0, 0 end
    local display_u, display_v = coordinatesForDisplay(sample.u - r.ys, sample.v - r.zs)
    local thickness = sample.thickness or default_t
    return display_u * thickness, display_v * thickness
end

local function displayedVector(u, v)
    return coordinatesForDisplay(u, v)
end

local function enterTorsionInput()
    local value = evaluate_input(inputText)
    if not value then status = "Ungueltige Torsionseingabe."; inputText = ""; return true end
    value = input_to_internal(value, moment_unit)
    torsion_M, torsion_input_step, inputText = value, 0, ""
    torsion_results = berechneTorsionsResultat(value)
    aktualisiereTorsionsverlauf(torsion_results)
    local torsion_constant, area = find_closed_cells()
    status = "Torsionsspannung berechnet."
    showResults = true
    return true
end

local function berechneKraftTorsion()
    if not system_results or #duenn_elemente == 0 then return nil end
    local moment = 0
    for _, kraft in ipairs(kraefte) do
        local kraft_u, kraft_v = displayedVector(kraft.u, kraft.v)
        local center_u, center_v = displayedVector(system_results.ys, system_results.zs)
        local force_a, force_b = displayedVector(tonumber(kraft.fa) or 0, tonumber(kraft.fb) or 0)
        moment = moment + (kraft_u - center_u) * force_b - (kraft_v - center_v) * force_a
    end
    if math.abs(moment) < 1e-12 then return nil end
    return berechneTorsionsResultat(moment)
end

local function enterShearInput()
    local val = evaluate_input(inputText)
    if not val then
        status = "Ungueltige Schubkraft-Eingabe."
        inputText = ""
        platform.window:invalidate()
        return true
    end
    if shear_input_step == 1 then
        shear_Qa, shear_input_step, inputText = input_to_internal(val, force_unit), 2, ""
        local _, b = current_axes()
            status = "Q" .. b .. " in " .. force_unit .. " eingeben, dann Enter." 
    elseif shear_input_step == 2 then
        shear_Qb, inputText = input_to_internal(val, force_unit), ""
        if shear_external_input then
            shear_input_step = 3
            status = "N in " .. force_unit .. " eingeben, dann Enter."
        else
            shear_input_step = 0
            shear_results = berechneSchubspannungsResultate(shear_Qa, shear_Qb)
            shear_selector_open = shear_results ~= nil
            status = shear_results and "Schubkräfte ausgewertet. V: Verlauf waehlen." or "Schubspannung nicht berechenbar."
        end
    elseif shear_input_step == 3 then
        shear_N, shear_input_step, inputText = input_to_internal(val, force_unit), 4, ""
        status = "MT in " .. moment_unit .. " eingeben, dann Enter."
    else
        shear_M, shear_input_step, inputText = input_to_internal(val, moment_unit), 0, ""
        shear_results = berechneSchubspannungsResultate(shear_Qa or 0, shear_Qb or 0)
        torsion_M = shear_M
        torsion_results = berechneTorsionsResultat(shear_M)
        aktualisiereTorsionsverlauf(torsion_results)
        shear_external_input = false
        shear_selector_open = shear_results ~= nil
        showResults = true
        status = shear_results and "Belastungen ausgewertet. V: Verlauf waehlen." or "Schubspannung nicht berechenbar."
    end
    platform.window:invalidate()
    return true
end

local function toggleCalculationMenu()
    if sigma_input_step ~= 0 or inputMode then return end
    if shear_results and shear_input_step == 0 then
        if menuOpen and menuPage == 8 then
            menuOpen = false
            return
        end
        menuOpen, menuPage, menuRow = true, 8, 1
        showResults, showTable = false, false
        return
    end
    if menuOpen and menuPage == 5 then
        menuOpen = false
        return
    end
    if not system_results then status = "Kein Querschnitt vorhanden." end
    menuOpen, menuPage, menuRow = true, 5, 1
    showResults, showTable = false, false
end

local function axes()
    return current_axes()
end

local function toScreen(u, v) return ox + u * scale, oy - v * scale end
local function toScreenKOS(u, v)
    local x, y
    if rotation == 0 then x, y = u, -v
    elseif rotation == 90 then x, y = -v, -u
    elseif rotation == 180 then x, y = -u, v
    else x, y = v, u end
    return ox + x * scale, oy + y * scale
end
local function fromScreen(x, y) return (x - ox) / scale, (oy - y) / scale end
local function snap(x)
    local q = x / raster
    if q >= 0 then return math.floor(q + .5) * raster end
    return math.ceil(q - .5) * raster
end

coordinatesForDisplay = function(u, v)
    if rotation == 90 then return -v, u end
    if rotation == 180 then return -u, -v end
    if rotation == 270 then return v, -u end
    return u, v
end

local function coordinatesFromDisplay(u, v)
    if rotation == 90 then return v, -u end
    if rotation == 180 then return -u, -v end
    if rotation == 270 then return -v, u end
    return u, v
end

local function forceComponentsForDisplay(fu, fv)
    return coordinatesForDisplay(fu, fv)
end

local function forceComponentsFromDisplay(fu, fv)
    return coordinatesFromDisplay(fu, fv)
end

local function setDisplayedPointCoordinate(point, coordinate, value)
    local display_u, display_v = coordinatesForDisplay(point.u, point.v)
    if coordinate == "u" then display_u = value else display_v = value end
    point.u, point.v = coordinatesFromDisplay(display_u, display_v)
end

local function poly_props(pts)
    local A, sy, sz, Iy, Iz, Iyz = 0, 0, 0, 0, 0, 0
    for i = 1, #pts do
        local p1, p2 = pts[i], pts[i % #pts + 1]
        local c = p1.u * p2.v - p2.u * p1.v
        A = A + c
        sy = sy + (p1.u + p2.u) * c
        sz = sz + (p1.v + p2.v) * c
        Iy = Iy + (p1.v^2 + p1.v*p2.v + p2.v^2) * c
        Iz = Iz + (p1.u^2 + p1.u*p2.u + p2.u^2) * c
        Iyz = Iyz + (p1.u*p2.v + 2*p1.u*p1.v + 2*p2.u*p2.v + p2.u*p1.v) * c
    end
    A = A / 2
    if math.abs(A) < 1e-9 then return 0, 0, 0, 0, 0, 0 end
    if A < 0 then A, sy, sz, Iy, Iz, Iyz = -A, -sy, -sz, -Iy, -Iz, -Iyz end
    local ys, zs = sy / (6 * A), sz / (6 * A)
    return A, ys, zs, Iy / 12 - A * zs^2, Iz / 12 - A * ys^2, -(Iyz / 24 - A * ys * zs)
end

local function sector_props(p1, p2, p3, is_segment)
    local R = math.sqrt((p2.u-p1.u)^2 + (p2.v-p1.v)^2)
    if R < 1e-5 then return 0, 0, 0, 0, 0, 0 end
    local a1 = math.atan2(p2.v-p1.v, p2.u-p1.u)
    local diff = math.atan2(p3.v-p1.v, p3.u-p1.u) - a1
    if diff <= 0 then diff = diff + 2 * math.pi end
    local alpha = diff / 2
    local A, d
    if is_segment then
        A = R^2 / 2 * (2 * alpha - math.sin(2 * alpha))
        d = 4 * R * math.sin(alpha)^3 / (3 * (2 * alpha - math.sin(2 * alpha)))
    else
        A, d = alpha * R^2, 2 * R * math.sin(alpha) / (3 * alpha)
    end
    local phi = a1 + alpha
    local ys, zs = p1.u + d * math.cos(phi), p1.v + d * math.sin(phi)
    local Iu = R^4 / 4 * (alpha - math.sin(alpha) * math.cos(alpha))
    local Iv = R^4 / 4 * (alpha + math.sin(alpha) * math.cos(alpha)) - A * d^2
    local c, s = math.cos(phi), math.sin(phi)
    return A, ys, zs, Iu*c^2 + Iv*s^2, Iu*s^2 + Iv*c^2, (Iu-Iv)*s*c
end

local function thin_line_props(p1, p2, t)
    local du, dv = p2.u-p1.u, p2.v-p1.v
    local L = math.sqrt(du^2 + dv^2)
    local A, ys, zs = L*t, (p1.u+p2.u)/2, (p1.v+p2.v)/2
    if L < 1e-9 then return 0, ys, zs, 0, 0, 0, 0 end
    local Iy = t*L/12*dv^2
    local Iz = t*L/12*du^2
    local Iyz = -(t*L/12)*du*dv
    return A, ys, zs, Iy, Iz, Iyz, L
end

local function berechneLokaleWerte(elem)
    local A, ys, zs, Iy, Iz, Iyz = 0,0,0,0,0,0
    local p = elem.points
    if elem.type == "massiv_linie" then
        local p1, p2 = elem.points[1], elem.points[2]
        local du, dv = p2.u - p1.u, p2.v - p1.v
        local L = math.sqrt(du^2 + dv^2)
        local nx, ny = 0, 0
        if L > 1e-9 then nx, ny = (-dv/L) * (elem.t/2), (du/L) * (elem.t/2) end
        local pts = {
            {u = p1.u + nx, v = p1.v + ny},
            {u = p2.u + nx, v = p2.v + ny},
            {u = p2.u - nx, v = p2.v - ny},
            {u = p1.u - nx, v = p1.v - ny}
        }
        A, ys, zs, Iy, Iz, Iyz = poly_props(pts)
    end
    
    if elem.type == "rect" then
        local pts = {
            {u=p[1].u, v=p[1].v}, {u=p[2].u, v=p[1].v},
            {u=p[2].u, v=p[2].v}, {u=p[1].u, v=p[2].v}
        }
        A, ys, zs, Iy, Iz, Iyz = poly_props(pts)
    elseif elem.type == "circle" or elem.type == "duenn_kreis" then
        local R = math.sqrt((p[2].u-p[1].u)^2 + (p[2].v-p[1].v)^2)
        A = math.pi * R^2
        ys, zs = p[1].u, p[1].v
        Iy, Iz = math.pi * R^4 / 4, math.pi * R^4 / 4
        Iyz = 0
    elseif elem.type == "triangle" or elem.type == "trapezoid" then
        A, ys, zs, Iy, Iz, Iyz = poly_props(p)
    elseif elem.type == "sector" then
        A, ys, zs, Iy, Iz, Iyz = sector_props(p[1], p[2], p[3], false)
    elseif elem.type == "segment" then
        A, ys, zs, Iy, Iz, Iyz = sector_props(p[1], p[2], p[3], true)
    end
    
    if elem.is_hole then A, Iy, Iz, Iyz = -A, -Iy, -Iz, -Iyz end
    return A, ys, zs, Iy, Iz, Iyz
end

-- === GRAPH & TORSION ===
find_closed_cells = function()
    local nodes = {}
    local function get_node(u, v)
        for i, n in ipairs(nodes) do
            if math.abs(n.u - u) < 1e-4 and math.abs(n.v - v) < 1e-4 then return i end
        end
        table.insert(nodes, {u=u, v=v, adj={}})
        return #nodes
    end
    
    for i, elem in ipairs(duenn_elemente) do
        local n1 = get_node(elem.points[1].u, elem.points[1].v)
        local n2 = get_node(elem.points[2].u, elem.points[2].v)
        table.insert(nodes[n1].adj, {to=n2, edge_idx=i})
        table.insert(nodes[n2].adj, {to=n1, edge_idx=i})
    end
    
    local changed = true
    local active_nodes = {}
    local active_edges = {}
    for i=1, #nodes do active_nodes[i] = true end
    for i=1, #duenn_elemente do active_edges[i] = true end
    
    while changed do
        changed = false
        for i=1, #nodes do
            if active_nodes[i] then
                local deg = 0
                local last_edge = nil
                for _, edge in ipairs(nodes[i].adj) do
                    if active_edges[edge.edge_idx] then deg = deg + 1; last_edge = edge.edge_idx end
                end
                if deg <= 1 then
                    active_nodes[i] = false
                    if last_edge then active_edges[last_edge] = false end
                    changed = true
                end
            end
        end
    end

    local cycle_edges = {}
    for i, active in ipairs(active_edges) do
        if active then table.insert(cycle_edges, i) end
    end
    
    if #cycle_edges == 0 then return 0, 0 end
    
    local start_node
    for i=1, #nodes do if active_nodes[i] then start_node = i; break end end
    
    local path = {start_node}
    local curr = start_node
    local visited_edges = {}
    
    while true do
        local next_node = nil
        for _, edge in ipairs(nodes[curr].adj) do
            if active_edges[edge.edge_idx] and not visited_edges[edge.edge_idx] then
                visited_edges[edge.edge_idx] = true
                next_node = edge.to
                break
            end
        end
        if not next_node or next_node == start_node then break end
        table.insert(path, next_node)
        curr = next_node
    end
    
    local Am = 0
    for i=1, #path do
        local p1 = nodes[path[i]]
        local p2 = nodes[path[(i%#path)+1]]
        Am = Am + (p1.u * p2.v - p2.u * p1.v)
    end
    Am = math.abs(Am / 2)
    
    local sum_lt = 0
    for _, edge_idx in ipairs(cycle_edges) do
        local elem = duenn_elemente[edge_idx]
        local dx = elem.points[2].u - elem.points[1].u
        local dy = elem.points[2].v - elem.points[1].v
        local L = math.sqrt(dx^2 + dy^2)
        sum_lt = sum_lt + (L / elem.t)
    end
    
    if sum_lt > 1e-9 then
        return (4 * Am^2) / sum_lt, Am
    end
    return 0, 0
end

-- === SYSTEM BERECHNUNG ===
-- === KOLLISION UND LOECHER ===
local function is_point_inside(elem, u, v)
    if elem.type == "massiv_linie" then
        local p1, p2 = elem.points[1], elem.points[2]
        local du, dv = p2.u - p1.u, p2.v - p1.v
        local L2 = du^2 + dv^2
        if L2 < 1e-9 then return false end
        local dot = (u - p1.u)*du + (v - p1.v)*dv
        local proj = dot / L2
        if proj < 0 or proj > 1 then return false end
        local px = p1.u + proj * du
        local py = p1.v + proj * dv
        local dist2 = (u - px)^2 + (v - py)^2
        return dist2 <= (elem.t/2)^2
    end
    
    if elem.type == "rect" then
        local p = elem.points
        local min_u, max_u = math.min(p[1].u, p[2].u), math.max(p[1].u, p[2].u)
        local min_v, max_v = math.min(p[1].v, p[2].v), math.max(p[1].v, p[2].v)
        return u >= min_u and u <= max_u and v >= min_v and v <= max_v
    elseif elem.type == "circle" or elem.type == "duenn_kreis" then
        local R = math.sqrt((elem.points[2].u - elem.points[1].u)^2 + (elem.points[2].v - elem.points[1].v)^2)
        return (u - elem.points[1].u)^2 + (v - elem.points[1].v)^2 <= R^2
    elseif elem.type == "triangle" or elem.type == "trapezoid" then
        -- Ray casting for polygon
        local pts = elem.points
        local inside = false
        local j = #pts
        for i=1,#pts do
            if ((pts[i].v > v) ~= (pts[j].v > v)) and (u < (pts[j].u - pts[i].u) * (v - pts[i].v) / (pts[j].v - pts[i].v) + pts[i].u) then
                inside = not inside
            end
            j = i
        end
        return inside
    elseif elem.type == "massiv_linie" then
        local p1, p2 = elem.points[1], elem.points[2]
        local du, dv = p2.u - p1.u, p2.v - p1.v
        local L = math.sqrt(du^2 + dv^2)
        local nx, ny = 0, 0
        if L > 1e-9 then nx, ny = (-dv/L) * (elem.t/2), (du/L) * (elem.t/2) end
        local pts = {
            {u = p1.u + nx, v = p1.v + ny},
            {u = p2.u + nx, v = p2.v + ny},
            {u = p2.u - nx, v = p2.v - ny},
            {u = p1.u - nx, v = p1.v - ny}
        }
        local q = {}
        for _, p in ipairs(pts) do
            local x, y = toScreen(p.u, p.v)
            table.insert(q, x)
            table.insert(q, y)
        end
        gc:fillPolygon(q)
        table.insert(q, q[1])
        table.insert(q, q[2])
        gc:drawPolyLine(q)
    elseif elem.type == "sector" or elem.type == "segment" or elem.type == "duenn_kreis_bogen" then
        local C = elem.points[1]
        local R = math.sqrt((elem.points[2].u - C.u)^2 + (elem.points[2].v - C.v)^2)
        local dist2 = (u - C.u)^2 + (v - C.v)^2
        if dist2 > R^2 then return false end
        -- Check angle
        local a1 = math.atan2(elem.points[2].v - C.v, elem.points[2].u - C.u)
        local a2 = math.atan2(elem.points[3].v - C.v, elem.points[3].u - C.u)
        local aP = math.atan2(v - C.v, u - C.u)
        
        local function norm(a) if a < 0 then return a + 2*math.pi end return a end
        local a2_n = norm(a2 - a1)
        local aP_n = norm(aP - a1)
        
        if elem.type == "sector" then
            return aP_n <= a2_n
        else
            -- For segment, must also be on the correct side of the chord
            if aP_n > a2_n then return false end
            local line_a = (elem.points[2].v - elem.points[3].v)
            local line_b = (elem.points[3].u - elem.points[2].u)
            local line_c = elem.points[2].u * elem.points[3].v - elem.points[3].u * elem.points[2].v
            -- Check if center and point are on opposite sides
            local valC = line_a * C.u + line_b * C.v + line_c
            local valP = line_a * u + line_b * v + line_c
            return (valC * valP) <= 0
        end
    end
    return false
end

local function getBoundingBox(elem)
    local min_u, max_u, min_v, max_v
    
    if elem.type == "rect" then
        min_u = math.min(elem.points[1].u, elem.points[2].u)
        max_u = math.max(elem.points[1].u, elem.points[2].u)
        min_v = math.min(elem.points[1].v, elem.points[2].v)
        max_v = math.max(elem.points[1].v, elem.points[2].v)
    elseif elem.type == "circle" or elem.type == "duenn_kreis" then
        local C = elem.points[1]
        local R = math.sqrt((elem.points[2].u - C.u)^2 + (elem.points[2].v - C.v)^2)
        min_u, max_u = C.u - R, C.u + R
        min_v, max_v = C.v - R, C.v + R
    elseif elem.type == "massiv_linie" then
        local p1, p2 = elem.points[1], elem.points[2]
        local du, dv = p2.u - p1.u, p2.v - p1.v
        local L = math.sqrt(du^2 + dv^2)
        local nx, ny = 0, 0
        if L > 1e-9 then nx, ny = (-dv/L) * (elem.t/2), (du/L) * (elem.t/2) end
        local pts = {
            {u = p1.u + nx, v = p1.v + ny},
            {u = p2.u + nx, v = p2.v + ny},
            {u = p2.u - nx, v = p2.v - ny},
            {u = p1.u - nx, v = p1.v - ny}
        }
        min_u, max_u, min_v, max_v = math.huge, -math.huge, math.huge, -math.huge
        for _, p in ipairs(pts) do
            min_u = math.min(min_u, p.u)
            max_u = math.max(max_u, p.u)
            min_v = math.min(min_v, p.v)
            max_v = math.max(max_v, p.v)
        end
    else
        if elem.type == "sector" or elem.type == "segment" or elem.type == "duenn_kreis_bogen" then
            local C = elem.points[1]
            local R = math.sqrt((elem.points[2].u - C.u)^2 + (elem.points[2].v - C.v)^2)
            min_u, max_u = C.u - R, C.u + R
            min_v, max_v = C.v - R, C.v + R
        else
            min_u, max_u, min_v, max_v = math.huge, -math.huge, math.huge, -math.huge
            for _, p in ipairs(elem.points) do
                min_u = math.min(min_u, p.u)
                max_u = math.max(max_u, p.u)
                min_v = math.min(min_v, p.v)
                max_v = math.max(max_v, p.v)
            end
        end
    end
    return min_u, max_u, min_v, max_v
end

local function berechneNumerisch(elem, index_of_elem)
    -- Naehert die Kennwerte rasterbasiert an, wenn keine geschlossene Formel genutzt wird.
    local min_u, max_u, min_v, max_v = getBoundingBox(elem)
    local A, sum_yu, sum_zu, sum_y2, sum_z2, sum_yz = 0,0,0,0,0,0
    
    local steps = 40
    local du = (max_u - min_u) / steps
    local dv = (max_v - min_v) / steps
    local dA = du * dv
    
    for i=0, steps-1 do
        for j=0, steps-1 do
            local u = min_u + (i + 0.5)*du
            local v = min_v + (j + 0.5)*dv
            
            if is_point_inside(elem, u, v) then
                if elem.is_hole then
                    local is_positive = false
                    for k=1, index_of_elem-1 do
                        local other = massiv_elemente[k]
                        if not other.is_hole and is_point_inside(other, u, v) then
                            is_positive = true
                            break
                        end
                    end
                    if is_positive then
                        A = A - dA
                        sum_yu = sum_yu - u * dA
                        sum_zu = sum_zu - v * dA
                        sum_y2 = sum_y2 - (v^2) * dA
                        sum_z2 = sum_z2 - (u^2) * dA
                        sum_yz = sum_yz - (u * v) * dA
                    end
                else
                    local overlap = false
                    for k=1, index_of_elem-1 do
                        if is_point_inside(massiv_elemente[k], u, v) then overlap = true break end
                    end
                    if not overlap then
                        A = A + dA
                        sum_yu = sum_yu + u * dA
                        sum_zu = sum_zu + v * dA
                        sum_y2 = sum_y2 + (v^2) * dA
                        sum_z2 = sum_z2 + (u^2) * dA
                        sum_yz = sum_yz + (u * v) * dA
                    end
                end
            end
        end
    end
    
    if math.abs(A) < 1e-9 then return 0,0,0,0,0,0 end
    
    local ys = sum_yu / A
    local zs = sum_zu / A
    
    local Iys = sum_z2 - A * zs^2
    local Izs = sum_y2 - A * ys^2
    local Iyzs = -(sum_yz - A * ys * zs)
    
    return A, ys, zs, Iys, Izs, Iyzs
end

local function checkOverlapStatus(new_elem)
    local min_u, max_u, min_v, max_v = getBoundingBox(new_elem)
    local test_pts = {}
    -- Nur innere Punkte pruefen: Eine gemeinsame Randlinie ist keine Flaechenueberlappung.
    for i=1, 5 do
        for j=1, 5 do
            local u = min_u + (max_u - min_u) * (i/6)
            local v = min_v + (max_v - min_v) * (j/6)
            if is_point_inside(new_elem, u, v) then
                table.insert(test_pts, {u=u, v=v})
            end
        end
    end
    
    local is_partial = false
    local completely_inside = false
    
    for _, other in ipairs(massiv_elemente) do
        if not other.is_hole and other ~= new_elem then
            local count_in = 0
            for _, pt in ipairs(test_pts) do
                if is_point_inside(other, pt.u, pt.v) then count_in = count_in + 1 end
            end
            if count_in == #test_pts then
                completely_inside = true
            elseif count_in > 0 then
                is_partial = true
            end
        end
    end
    
    if is_partial then return "partial" end
    if completely_inside then return "inside" end
    return "none"
end

-- === GUI & ZEICHNEN ===


local function get_thin_props(elem)
    if elem.type == "duenn_kreis" or elem.type == "duenn_kreis_bogen" then
        local C = elem.points[1]
        local P2 = elem.points[2]
        local is_full = (elem.type == "duenn_kreis")
        local R = math.sqrt((P2.u - C.u)^2 + (P2.v - C.v)^2)
        local a1, diff = 0, 2*math.pi
        if not is_full then
            a1 = math.atan2(P2.v - C.v, P2.u - C.u)
            local P3 = elem.points[3]
            local a2 = math.atan2(P3.v - C.v, P3.u - C.u)
            diff = a2 - a1
            if diff <= 0 then diff = diff + 2*math.pi end
        end
        local t = elem.t
        local L = R * diff
        local A = L * t
        local ys, zs = C.u, C.v
        if not is_full then
            local chord = 2 * R * math.sin(diff / 2)
            local cg_dist = (R * chord) / L
            local bisector = a1 + diff / 2
            ys = C.u + cg_dist * math.cos(bisector)
            zs = C.v + cg_dist * math.sin(bisector)
        end
        local i_sin2 = (a1+diff)/2 - math.sin(2*(a1+diff))/4 - (a1/2 - math.sin(2*a1)/4)
        local i_cos2 = (a1+diff)/2 + math.sin(2*(a1+diff))/4 - (a1/2 + math.sin(2*a1)/4)
        local i_sincos = -math.cos(2*(a1+diff))/4 - (-math.cos(2*a1)/4)
        local Iu_c = R^3 * t * i_sin2
        local Iv_c = R^3 * t * i_cos2
        local Iuv_c = -(R^3 * t * i_sincos)
        local dy = ys - C.u
        local dz = zs - C.v
        return A, ys, zs, Iu_c - A * dz^2, Iv_c - A * dy^2, Iuv_c + A * dy * dz, L
    else
        return thin_line_props(elem.points[1], elem.points[2], elem.t)
    end
end

local function autoZoom()
    -- Waehlt einen Massstab, der alle vorhandenen Elemente im Zeichenbereich zeigt.
    if not system_results then return end
    local r = system_results
    if r.A == nil or r.A == 0 then return end
    
    local min_u, max_u, min_v, max_v = math.huge, -math.huge, math.huge, -math.huge
    for _, elem in ipairs(massiv_elemente) do
        local u1, u2, v1, v2 = getBoundingBox(elem)
        min_u, max_u = math.min(min_u, u1), math.max(max_u, u2)
        min_v, max_v = math.min(min_v, v1), math.max(max_v, v2)
    end
    for _, elem in ipairs(duenn_elemente) do
        local u1, u2, v1, v2 = getBoundingBox(elem)
        min_u, max_u = math.min(min_u, u1), math.max(max_u, u2)
        min_v, max_v = math.min(min_v, v1), math.max(max_v, v2)
    end
    
    if min_u == math.huge then return end
    
    local w = max_u - min_u
    local h = max_v - min_v
    if w < 1e-9 then w = 1 end
    if h < 1e-9 then h = 1 end
    
    local sw = platform.window:width()
    local sh = platform.window:height()
    scale = math.min((sw - 60) / w, (sh - 60) / h)
    
    local cx = (max_u + min_u) / 2
    local cy = (max_v + min_v) / 2
    
    ox = sw/2 - cx * scale
    oy = sh/2 + cy * scale
    platform.window:invalidate()
end

function on.clearKey()
    escape_clear_pending = false
    massiv_elemente, duenn_elemente, kraefte, pending = {}, {}, {}, {}
    overlap_pending_elem = nil
    system_results = nil
    showResults, showTable = false, false
    table_scroll_x, table_scroll_y = 0, 0
    results_scroll_y = 0
    sigma_input_step, sigma_N, sigma_My, sigma_Mz, sigma_results = 0, nil, nil, nil, nil
    shear_input_step, shear_Qa, shear_Qb, shear_results = 0, nil, nil, nil
    torsion_input_step, torsion_M, torsion_results = 0, nil, nil
    shear_profile_visible, shear_hover_index, shear_view_mode, shear_selector_open = false, nil, 0, false
    shear_external_input = false
    show_shear_center, show_shear_moment_table, shear_moment_table = false, false, nil
    shear_profile_visible = false
    shear_hover_index = nil
    sigma_scroll_y = 0
    sigma_table_scroll_y = 0
    sigma_oblique = false
    kernMode = 0
    kern_lines, kern_pts, kern_vertices = {}, {}, {}
    kern_hover_line, kern_hover_pt = nil, nil
    selected_idx, selected_type = nil, nil
    hover_type, hover_idx = nil, nil
    menuOpen, inputMode = false, false
    mode = "idle"
    kos_size, kos_pixel_length = 48, 48
    plane, swapped, rotation = 2, false, 180
    status = "Massiv | Duennwand | Ergebnisse"
    platform.window:invalidate()
end

function on.backspaceKey()
    on.clearKey()
end

local function berechneSystem()
    sigma_results = nil
    local sumA, sumSyu, sumSzu = 0, 0, 0
    is_numeric_system = false
    
    for i, elem in ipairs(massiv_elemente) do
        local A, ys, zs = 0,0,0
        if elem.is_numeric then
            is_numeric_system = true
            A, ys, zs = berechneNumerisch(elem, i)
        else
            A, ys, zs = berechneLokaleWerte(elem)
        end
        elem.ys = ys
        elem.zs = zs
        sumA = sumA + A
        sumSyu = sumSyu + A * ys
        sumSzu = sumSzu + A * zs
    end
    
    local It_open = 0
    for _, elem in ipairs(duenn_elemente) do
        local A, ys, zs, Iy, Iz, Iyz, L = get_thin_props(elem)
        elem.ys = ys
        elem.zs = zs
        sumA = sumA + A
        sumSyu = sumSyu + A * ys
        sumSzu = sumSzu + A * zs
        It_open = It_open + (torsion_xi / 3) * L * (elem.t^3)
    end
    
    if math.abs(sumA) < 1e-9 then system_results = nil; return end
    
    local global_ys = sumSyu / sumA
    local global_zs = sumSzu / sumA
    
    local sys_Iy, sys_Iz, sys_Iyz = 0, 0, 0
    
    for i, elem in ipairs(massiv_elemente) do
        local A, ys, zs, Iy, Iz, Iyz = 0,0,0,0,0,0
        if elem.is_numeric then
            A, ys, zs, Iy, Iz, Iyz = berechneNumerisch(elem, i)
        else
            A, ys, zs, Iy, Iz, Iyz = berechneLokaleWerte(elem)
        end
        elem.A, elem.Iy, elem.Iz, elem.Iyz = A, Iy, Iz, Iyz
        local I_avg = (Iy + Iz) / 2
        local R = math.sqrt(((Iy - Iz)/2)^2 + Iyz^2)
        elem.I_eta = I_avg + R
        elem.I_zeta = I_avg - R
        elem.I_etazeta = 0
        elem.display_name = "M" .. i
        elem.alpha = 0
        if R > 1e-9 then
            elem.alpha = math.atan2(2 * Iyz, Iy - Iz) / 2
        end
        local dy = ys - global_ys
        local dz = zs - global_zs
        sys_Iy = sys_Iy + Iy + A * dz^2
        sys_Iz = sys_Iz + Iz + A * dy^2
        sys_Iyz = sys_Iyz + Iyz - A * dy * dz
    end
    
    for _, elem in ipairs(duenn_elemente) do
        local A, ys, zs, Iy, Iz, Iyz = get_thin_props(elem)
        elem.A, elem.Iy, elem.Iz, elem.Iyz = A, Iy, Iz, Iyz
        local I_avg = (Iy + Iz) / 2
        local R = math.sqrt(((Iy - Iz)/2)^2 + Iyz^2)
        elem.I_eta = I_avg + R
        elem.I_zeta = I_avg - R
        elem.I_etazeta = 0
        elem.display_name = "D" .. _
        elem.alpha = 0
        if R > 1e-9 then
            elem.alpha = math.atan2(2 * Iyz, Iy - Iz) / 2
        end
        local dy = ys - global_ys
        local dz = zs - global_zs
        sys_Iy = sys_Iy + Iy + A * dz^2
        sys_Iz = sys_Iz + Iz + A * dy^2
        sys_Iyz = sys_Iyz + Iyz - A * dy * dz
    end
    
    -- Haupttraegheitsmomente & Drehwinkel
    local IyS, IzS, IyzS = sys_Iy, sys_Iz, sys_Iyz
    local m = (IyS + IzS) / 2
    local d = math.sqrt(((IyS - IzS)/2)^2 + IyzS^2)
    local I1 = m + d
    local I2 = m - d
    -- Vorsicht: Der Winkel im Mohrschen Kreis tan(2a) = 2 Iyz / (Iy - Iz)
    -- Da y,z hier als Koordinaten sind (y horizontal, z vertikal):
    local alpha_star = 0
    if math.abs(sys_Iy - sys_Iz) > 1e-9 then
        alpha_star = 0.5 * math.atan2(2 * sys_Iyz, sys_Iy - sys_Iz)
    elseif math.abs(sys_Iyz) > 1e-9 then
        alpha_star = math.pi / 4
    end
    
    local It_closed, Am = find_closed_cells()
    
    local sys_min_u, sys_max_u = 1e9, -1e9
    local sys_min_v, sys_max_v = 1e9, -1e9
    local function update_sys_bounds(elem)
        if elem.is_hole then return end
        local min_u, max_u, min_v, max_v = getBoundingBox(elem)
        if min_u < sys_min_u then sys_min_u = min_u end
        if max_u > sys_max_u then sys_max_u = max_u end
        if min_v < sys_min_v then sys_min_v = min_v end
        if max_v > sys_max_v then sys_max_v = max_v end
    end
    for _, elem in ipairs(massiv_elemente) do update_sys_bounds(elem) end
    for _, elem in ipairs(duenn_elemente) do update_sys_bounds(elem) end
    
    local e_u = math.max(math.abs(sys_max_u - global_ys), math.abs(sys_min_u - global_ys))
    local e_v = math.max(math.abs(sys_max_v - global_zs), math.abs(sys_min_v - global_zs))
    local Wu = (e_v > 1e-9) and (sys_Iy / e_v) or 0
    local Wv = (e_u > 1e-9) and (sys_Iz / e_u) or 0
    
    system_results = {
        A = sumA, ys = global_ys, zs = global_zs,
        Iy = IyS, Iz = IzS, Iyz = IyzS,
        IyS = IyS, IzS = IzS, IyzS = IyzS,
        Wu = Wu, Wv = Wv,
        I1 = I1, I2 = I2, alpha = alpha_star,
        It = It_open, It_closed = It_closed, Am = Am
    }
    local force_torsion = berechneKraftTorsion()
    if force_torsion then
        torsion_results = force_torsion
    elseif torsion_M == nil then
        torsion_results = nil
    end
    if kernMode > 0 and kern_build then kern_build() end
end

local function verschiebeKOSZumSchwerpunkt()
    if not system_results then
        status = "Kein Querschnitt vorhanden."
        return
    end
    local shift_u, shift_v = system_results.ys, system_results.zs
    local shifted_points = {}
    for _, elem in ipairs(massiv_elemente) do
        for _, point in ipairs(elem.points) do
            if not shifted_points[point] then
                point.u, point.v = point.u - shift_u, point.v - shift_v
                shifted_points[point] = true
            end
        end
    end
    for _, elem in ipairs(duenn_elemente) do
        for _, point in ipairs(elem.points) do
            if not shifted_points[point] then
                point.u, point.v = point.u - shift_u, point.v - shift_v
                shifted_points[point] = true
            end
        end
    end
    for _, kraft in ipairs(kraefte) do
        kraft.u, kraft.v = kraft.u - shift_u, kraft.v - shift_v
    end
    berechneSystem()
    status = "KOS in den Schwerpunkt verschoben."
end

local function berechneMaxSchubspannung(Vz)
    local r = system_results
    if not r or math.abs(Vz) < 1e-12 or math.abs(r.Iy) < 1e-12 then
        return r and r.zs or 0, 0
    end

    local min_u, max_u, min_v, max_v = math.huge, -math.huge, math.huge, -math.huge
    for _, elem in ipairs(massiv_elemente) do
        if not elem.is_hole then
            local u1, u2, v1, v2 = getBoundingBox(elem)
            min_u, max_u = math.min(min_u, u1), math.max(max_u, u2)
            min_v, max_v = math.min(min_v, v1), math.max(max_v, v2)
        end
    end
    if min_u == math.huge then return r.zs, 0 end

    local rows, columns = 100, 140
    local du = math.max((max_u - min_u) / columns, 1e-9)
    local dv = math.max((max_v - min_v) / rows, 1e-9)
    local row_area, row_moment, row_width = {}, {}, {}

    local function occupied(u, v)
        local positive = false
        for _, elem in ipairs(massiv_elemente) do
            if is_point_inside(elem, u, v) then
                if elem.is_hole then return false end
                positive = true
            end
        end
        for _, elem in ipairs(duenn_elemente) do
            local p1, p2 = elem.points[1], elem.points[2]
            local distance
            if elem.type == "duenn_kreis" or elem.type == "duenn_kreis_bogen" then
                local radius = math.sqrt((p2.u - p1.u)^2 + (p2.v - p1.v)^2)
                distance = math.abs(math.sqrt((u - p1.u)^2 + (v - p1.v)^2) - radius)
                if elem.type == "duenn_kreis_bogen" then
                    local a1 = math.atan2(p2.v - p1.v, p2.u - p1.u)
                    local a2 = math.atan2(elem.points[3].v - p1.v, elem.points[3].u - p1.u)
                    local ap = math.atan2(v - p1.v, u - p1.u)
                    local sweep = a2 - a1
                    if sweep <= 0 then sweep = sweep + 2 * math.pi end
                    local relative = ap - a1
                    if relative < 0 then relative = relative + 2 * math.pi end
                    if relative > sweep then distance = math.huge end
                end
            else
                distance = point_to_line_dist(u, v, p1.u, p1.v, p2.u, p2.v)
            end
            if distance <= elem.t / 2 then positive = true end
        end
        return positive
    end

    for row = 1, rows do
        local v = min_v + (row - 0.5) * dv
        local area, width = 0, 0
        for column = 1, columns do
            local u = min_u + (column - 0.5) * du
            if occupied(u, v) then
                area = area + du * dv
                width = width + du
            end
        end
        row_area[row] = area
        row_moment[row] = (v - r.zs) * area
        row_width[row] = width
    end

    local q_above = 0
    local best_z, best_tau = r.zs, 0
    for row = rows, 1, -1 do
        local b = row_width[row]
        if b > du * 0.5 then
            local tau = math.abs(Vz * q_above / (r.Iy * b))
            if tau > best_tau then
                best_tau = tau
                best_z = min_v + (row - 0.5) * dv
            end
        end
        q_above = q_above + row_moment[row]
    end
    return best_z, best_tau
end

local function berechneDuenneSchubspannung(Qa, Qb)
    if not system_results or #duenn_elemente == 0 then return nil end
    local r = system_results
    local samples = {}
    local paths = {}
    local nodes, edges = {}, {}
    local node_tolerance = 1e-6

    local function node_for(u, v)
        for index, node in ipairs(nodes) do
            if math.abs(node.u - u) <= node_tolerance and math.abs(node.v - v) <= node_tolerance then
                return index
            end
        end
        table.insert(nodes, {u = u, v = v, edges = {}, arrivals = {}})
        return #nodes
    end

    local function cross(au, av, bu, bv)
        return au * bv - av * bu
    end

    local function add_parameter(parameters, value)
        if value < -node_tolerance or value > 1 + node_tolerance then return end
        value = math.max(0, math.min(1, value))
        for _, existing in ipairs(parameters) do
            if math.abs(existing - value) <= node_tolerance then return end
        end
        table.insert(parameters, value)
    end

    local straight = {}
    local split_parameters = {}
    local symmetric_profile = math.abs(r.Iyz) < 1e-5
    local preferred_symmetry_points = {}
    local fallback_symmetry_points = {}
    for index, elem in ipairs(duenn_elemente) do
        straight[index] = not elem.type or elem.type == "duenn_linie"
        if straight[index] then split_parameters[index] = {0, 1} end
    end

    local function add_axis_parameter(index, parameter, preferred)
        if not symmetric_profile then return end
        add_parameter(split_parameters[index], parameter)
        table.insert(fallback_symmetry_points, {index = index, parameter = parameter})
        if preferred then table.insert(preferred_symmetry_points, {index = index, parameter = parameter}) end
    end

    -- Schnittparameter aller geraden Mittellinien bestimmen. Damit werden
    -- auch Endpunkt-auf-Linie-Kontakte und T-Knoten erkannt.
    for first = 1, #duenn_elemente do
        if straight[first] then
            local p, p2 = duenn_elemente[first].points[1], duenn_elemente[first].points[2]
            local rx, rv = p2.u - p.u, p2.v - p.v
            for second = first + 1, #duenn_elemente do
                if straight[second] then
                    local q, q2 = duenn_elemente[second].points[1], duenn_elemente[second].points[2]
                    local sx, sv = q2.u - q.u, q2.v - q.v
                    local qpx, qpv = q.u - p.u, q.v - p.v
                    local denominator = cross(rx, rv, sx, sv)
                    if math.abs(denominator) > node_tolerance then
                        local first_parameter = cross(qpx, qpv, sx, sv) / denominator
                        local second_parameter = cross(qpx, qpv, rx, rv) / denominator
                        add_parameter(split_parameters[first], first_parameter)
                        add_parameter(split_parameters[second], second_parameter)
                    elseif math.abs(cross(qpx, qpv, rx, rv)) <= node_tolerance then
                        -- Kollineare Linien: auch reine Endpunktberuehrungen
                        -- und ueberlappende Teilstrecken in Knoten zerlegen.
                        local first_length = rx^2 + rv^2
                        local second_length = sx^2 + sv^2
                        if first_length > node_tolerance then
                            add_parameter(split_parameters[first], ((q.u - p.u) * rx + (q.v - p.v) * rv) / first_length)
                            add_parameter(split_parameters[first], ((q2.u - p.u) * rx + (q2.v - p.v) * rv) / first_length)
                        end
                        if second_length > node_tolerance then
                            add_parameter(split_parameters[second], ((p.u - q.u) * sx + (p.v - q.v) * sv) / second_length)
                            add_parameter(split_parameters[second], ((p2.u - q.u) * sx + (p2.v - q.v) * sv) / second_length)
                        end
                    end
                end
            end
        end
    end

    -- Symmetrieachsen als zusaetzliche Knoten eintragen. Ein bevorzugter
    -- Punkt liegt auf einem Element, das die Achse senkrecht schneidet.
    if symmetric_profile then
        for index, elem in ipairs(duenn_elemente) do
            if straight[index] then
                local p1, p2 = elem.points[1], elem.points[2]
                local du, dv = p2.u - p1.u, p2.v - p1.v
                local length2 = du^2 + dv^2
                if length2 > node_tolerance then
                    if math.abs(dv) <= node_tolerance and (p1.u - r.ys) * (p2.u - r.ys) <= node_tolerance then
                        add_axis_parameter(index, (r.ys - p1.u) / du, true)
                    elseif math.abs(du) <= node_tolerance and (p1.v - r.zs) * (p2.v - r.zs) <= node_tolerance then
                        add_axis_parameter(index, (r.zs - p1.v) / dv, true)
                    end
                    if math.abs(du) > node_tolerance then
                        local parameter = (r.ys - p1.u) / du
                        if parameter >= -node_tolerance and parameter <= 1 + node_tolerance then
                            add_axis_parameter(index, parameter, false)
                        end
                    end
                    if math.abs(dv) > node_tolerance then
                        local parameter = (r.zs - p1.v) / dv
                        if parameter >= -node_tolerance and parameter <= 1 + node_tolerance then
                            add_axis_parameter(index, parameter, false)
                        end
                    end
                end
            end
        end
    end

    local function parameter_sort(left, right) return left < right end
    for index, elem in ipairs(duenn_elemente) do
        local parameters = split_parameters[index]
        if parameters then
            table.sort(parameters, parameter_sort)
            local p1, p2 = elem.points[1], elem.points[2]
            for part = 1, #parameters - 1 do
                local first_parameter, second_parameter = parameters[part], parameters[part + 1]
                local first_point = {
                    u = p1.u + first_parameter * (p2.u - p1.u),
                    v = p1.v + first_parameter * (p2.v - p1.v)
                }
                local second_point = {
                    u = p1.u + second_parameter * (p2.u - p1.u),
                    v = p1.v + second_parameter * (p2.v - p1.v)
                }
                local n1, n2 = node_for(first_point.u, first_point.v), node_for(second_point.u, second_point.v)
                if n1 ~= n2 then
                    table.insert(edges, {index = index, p1 = first_point, p2 = second_point, n1 = n1, n2 = n2, used = false})
                    table.insert(nodes[n1].edges, #edges)
                    table.insert(nodes[n2].edges, #edges)
                end
            end
        else
            local p1, p2 = elem.points[1], elem.points[2]
            local n1, n2 = node_for(p1.u, p1.v), node_for(p2.u, p2.v)
            if n1 ~= n2 then
                table.insert(edges, {index = index, p1 = p1, p2 = p2, n1 = n1, n2 = n2, used = false})
                table.insert(nodes[n1].edges, #edges)
                table.insert(nodes[n2].edges, #edges)
            end
        end
    end

    local function other_node(edge, node_index)
        return edge.n1 == node_index and edge.n2 or edge.n1
    end

    local function unused_edges(node_index)
        local result = {}
        for _, edge_index in ipairs(nodes[node_index].edges) do
            if not edges[edge_index].used then table.insert(result, edge_index) end
        end
        return result
    end

    local function integrate_edge(path, item, first_moment_a, first_moment_b, path_s)
        local edge, reverse = item.edge, item.reverse
        local segment_index, elem = edge.index, duenn_elemente[edge.index]
        local p1, p2 = edge.p1, edge.p2
        if reverse then p1, p2 = p2, p1 end
        local du, dv = p2.u - p1.u, p2.v - p1.v
        local length = math.sqrt(du^2 + dv^2)
        if length <= 1e-9 then return first_moment_a, first_moment_b, path_s end
        local original_p1, original_p2 = elem.points[1], elem.points[2]
        if original_p2.u < original_p1.u or (math.abs(original_p2.u - original_p1.u) <= 1e-9 and original_p2.v < original_p1.v) then
            original_p1, original_p2 = original_p2, original_p1
        end
        local original_du = original_p2.u - original_p1.u
        local original_dv = original_p2.v - original_p1.v
        local original_length = math.sqrt(original_du^2 + original_dv^2)
        local display_normal_u = original_length > 1e-9 and -original_dv / original_length or 0
        local display_normal_v = original_length > 1e-9 and original_du / original_length or 0
        -- Die Integration darf nicht von der Bildschirmzoomstufe abhaengen.
        -- Mindestens 32 Teilintervalle pro atomarer Kante verbessern die
        -- Restmoment- und Schubmittelpunktgenauigkeit deutlich.
        local integration_step = math.max(raster / 4, 0.05)
        local sample_count = math.max(32, math.ceil(length / integration_step))
        for sample = 0, sample_count do
            local f = sample / sample_count
            local u = p1.u + f * du
            local v = p1.v + f * dv
            local ds = length / sample_count
            local area = elem.t * ds
            local tau_a = Qa * first_moment_a / math.max(math.abs(r.Iz * elem.t), 1e-12)
            local tau_b = Qb * first_moment_b / math.max(math.abs(r.Iy * elem.t), 1e-12)
            local tau_total = tau_a + tau_b
            table.insert(samples, {u = u, v = v, tau_a = tau_a, tau_b = tau_b, tau = tau_total, Sy = first_moment_b, Sz = first_moment_a, moment_y_density = (v - r.zs) * elem.t, moment_z_density = (u - r.ys) * elem.t, thickness = elem.t, ds = ds, tangent_u = du / length, tangent_v = dv / length, display_normal_u = display_normal_u, display_normal_v = display_normal_v, segment = segment_index, path_id = path.id, parameter = f, s = path_s + f * length, direction = reverse and -1 or 1})
            if sample < sample_count then
                local midpoint = (sample + 0.5) / sample_count
                first_moment_a = first_moment_a + (p1.u + midpoint * du - r.ys) * area
                first_moment_b = first_moment_b + (p1.v + midpoint * dv - r.zs) * area
            end
        end
        item.p1, item.p2 = p1, p2
        return first_moment_a, first_moment_b, path_s + length
    end

    local function make_path(start_node, first_edge, initial_moment_a, initial_moment_b, start_kind)
        local path = {id = #paths + 1, items = {}, start_kind = start_kind, start_moment_a = initial_moment_a or 0, start_moment_b = initial_moment_b or 0}
        local current_node, edge_index = start_node, first_edge
        local first_moment_a, first_moment_b = initial_moment_a or 0, initial_moment_b or 0
        local path_s = 0
        while edge_index do
            local edge = edges[edge_index]
            if edge.used then break end
            edge.used = true
            local reverse = edge.n2 == current_node
            local next_node = other_node(edge, current_node)
            local item = {edge = edge, reverse = reverse}
            table.insert(path.items, item)
            first_moment_a, first_moment_b, path_s = integrate_edge(path, item, first_moment_a, first_moment_b, path_s)
            current_node = next_node
            table.insert(nodes[current_node].arrivals, {a = first_moment_a, b = first_moment_b})
            local candidates = unused_edges(current_node)
            -- An einem Knoten wird nur bei genau zwei inzidenten Aesten
            -- direkt weiterintegriert. Verzweigungen warten, bis feststeht,
            -- ob ein letzter unbekannter Ast mit einer Summe starten kann.
            if #nodes[current_node].edges ~= 2 then break end
            edge_index = candidates[1]
        end
        if #path.items > 0 then
            local signed_area = 0
            for _, item in ipairs(path.items) do
                if item.p1 and item.p2 then
                    signed_area = signed_area + item.p1.u * item.p2.v - item.p2.u * item.p1.v
                end
            end
            path.torsion_sign = signed_area >= 0 and 1 or -1
            for _, sample in ipairs(samples) do
                if sample.path_id == path.id then sample.torsion_sign = path.torsion_sign end
            end
            table.insert(paths, path)
        end
    end

    local function node_at(u, v)
        for index, node in ipairs(nodes) do
            if math.abs(node.u - u) <= node_tolerance and math.abs(node.v - v) <= node_tolerance then
                return index
            end
        end
        return nil
    end

    local function start_at_symmetry_point(candidates)
        for _, candidate in ipairs(candidates) do
            local elem = duenn_elemente[candidate.index]
            local p1, p2 = elem.points[1], elem.points[2]
            local point_u = p1.u + candidate.parameter * (p2.u - p1.u)
            local point_v = p1.v + candidate.parameter * (p2.v - p1.v)
            local node_index = node_at(point_u, point_v)
            if node_index then
                for _, edge_index in ipairs(nodes[node_index].edges) do
                    if not edges[edge_index].used then
                        make_path(node_index, edge_index, nil, nil, "symmetry")
                        return true
                    end
                end
            end
        end
        return false
    end

    -- Zuerst von jedem freien Ende aus laufen.
    for node_index, node in ipairs(nodes) do
        if #node.edges == 1 and not edges[node.edges[1]].used then
            make_path(node_index, node.edges[1], nil, nil, "free")
        end
    end

    -- Wenn an einer Verzweigung nur noch ein Ast unbekannt ist, startet dieser
    -- mit der Summe aller bereits am Knoten angekommenen statischen Momente.
    -- Wird nach jedem Symmetriestart erneut aufgerufen, damit ein an einer
    -- geschlossenen Zelle haengender freier Ast korrekt eingerechnet wird.
    local function resolve_branch_nodes()
        local changed = true
        while changed do
            changed = false
            for node_index, node in ipairs(nodes) do
                local candidates = unused_edges(node_index)
                if #node.edges >= 3 and #candidates == 1 and #node.arrivals > 0 then
                    local start_a, start_b = 0, 0
                    for _, arrival in ipairs(node.arrivals) do
                        start_a, start_b = start_a + arrival.a, start_b + arrival.b
                    end
                    make_path(node_index, candidates[1], start_a, start_b)
                    changed = true
                end
            end
        end
    end
    resolve_branch_nodes()

    local function has_unused_edges()
        for _, edge in ipairs(edges) do
            if not edge.used then return true end
        end
        return false
    end

    -- Mischprofile: eine geschlossene Zelle kann trotz noch vorhandener
    -- freier Aeste bestehen bleiben. Deren statisches Moment ist an den
    -- Verzweigungsknoten oben bereits als Ankunft hinterlegt; der
    -- Symmetriestart darf deshalb nicht mehr durch freie Enden anderswo im
    -- Profil blockiert werden. Nach jedem Symmetriestart wird erneut
    -- aufgeloest, damit der zweite Schenkel der Zelle die Summe aus
    -- Astmoment und Schleifenanteil uebernimmt.
    if symmetric_profile then
        local safety = #edges + 1
        while has_unused_edges() and safety > 0 do
            safety = safety - 1
            local started = start_at_symmetry_point(preferred_symmetry_points)
            if not started then started = start_at_symmetry_point(fallback_symmetry_points) end
            if not started then break end
            resolve_branch_nodes()
        end
    end

    if has_unused_edges() then
        if symmetric_profile then
            status = "Warnung: Geschlossenes Profil schneidet keine Symmetrieachse."
        end
        -- Restliche geschlossene Komponenten ohne Symmetrieachse werden
        -- deterministisch mit einem Startwert null orientiert.
        for edge_index, edge in ipairs(edges) do
            if not edge.used then make_path(edge.n1, edge_index) end
        end
    end
    local maximum = {tau = 0, abs_tau = 0, u = r.ys, v = r.zs}
    for _, sample in ipairs(samples) do
        if math.abs(sample.tau) > maximum.abs_tau then
            maximum = {tau = sample.tau, abs_tau = math.abs(sample.tau), u = sample.u, v = sample.v}
        end
    end
    return maximum, samples, paths
end

local function berechneOffenenSchubmittelpunkt()
    if not system_results or #duenn_elemente == 0 then return nil end
    local closed_constant = find_closed_cells()
    local is_closed = closed_constant > 1e-9
    local symmetric_profile = math.abs(system_results.Iyz) < 1e-5
    -- Ohne Symmetrieachse fehlt die Vertraeglichkeitsgleichung fuer den
    -- statisch unbestimmten Schubfluss q0, daher bleibt fuer unsymmetrische
    -- geschlossene Zellen der Schwerpunkt-Fallback bestehen.
    if is_closed and not symmetric_profile then
        return {u = system_results.ys, v = system_results.zs, known = true, closed = true}
    end
    local function shear_torque(Qa, Qb)
        local _, samples = berechneDuenneSchubspannung(Qa, Qb)
        local moment = 0
        for _, sample in ipairs(samples or {}) do
            local tau = sample.tau_a + sample.tau_b
            local sample_u, sample_v = coordinatesForDisplay(sample.u, sample.v)
            local center_u, center_v = coordinatesForDisplay(system_results.ys, system_results.zs)
            local tu, tv = displayedVector(sample.tangent_u, sample.tangent_v)
            local endpoint_weight = (sample.parameter and (sample.parameter <= 1e-9 or sample.parameter >= 1 - 1e-9)) and 0.5 or 1
            local force = tau * sample.thickness * sample.ds * endpoint_weight
            moment = moment - ((sample_u - center_u) * tv - (sample_v - center_v) * tu) * force
        end
        return moment
    end
    local moment_a = shear_torque(1, 0)
    local moment_b = shear_torque(0, 1)
    return {
        u = system_results.ys - moment_b,
        v = system_results.zs + moment_a,
        known = true,
        closed = is_closed,
        moment_a = moment_a,
        moment_b = moment_b
    }
end

local function berechneSchubmittelpunkt()
    if not system_results or #duenn_elemente == 0 then return nil end
    local probe_center = berechneOffenenSchubmittelpunkt()
    if probe_center and probe_center.closed then return probe_center end
    if probe_center and probe_center.known then return probe_center end
    local base_u, base_v, dir_u, dir_v
    for _, elem in ipairs(duenn_elemente) do
        local p1, p2 = elem.points[1], elem.points[2]
        local du, dv = p2.u - p1.u, p2.v - p1.v
        local length = math.sqrt(du^2 + dv^2)
        if length > 1e-9 then
            if not dir_u then
                base_u, base_v = p1.u, p1.v
                dir_u, dir_v = du / length, dv / length
            else
                local cross = dir_u * dv - dir_v * du
                if math.abs(cross) > 1e-9 then
                    local delta_u, delta_v = p1.u - base_u, p1.v - base_v
                    local t = (delta_u * dv - delta_v * du) / cross
                    local intersection_u = base_u + t * dir_u
                    local intersection_v = base_v + t * dir_v
                    local valid = true
                    for _, other in ipairs(duenn_elemente) do
                        local q1, q2 = other.points[1], other.points[2]
                        local eu, ev = q2.u - q1.u, q2.v - q1.v
                        local denominator = intersection_u * 0 + dir_u * ev - dir_v * eu
                        if math.abs(denominator) > 1e-9 then
                            local distance = math.abs((intersection_u - q1.u) * ev - (intersection_v - q1.v) * eu) / math.abs(denominator)
                            if distance > 1e-6 then valid = false; break end
                        end
                    end
                    if valid then return {u = intersection_u, v = intersection_v, known = true, closed = false} end
                end
            end
        end
    end
    return {u = system_results.ys, v = system_results.zs, known = false, closed = false}
end

local function berechneSchubMomentTabelle()
    if not system_results or #duenn_elemente == 0 then return nil end
    local function contributions(Qa, Qb)
        local _, samples = berechneDuenneSchubspannung(Qa, Qb)
        local result = {}
        local moments = {}
        for index = 1, #duenn_elemente do result[index] = 0 end
        for index = 1, #duenn_elemente do moments[index] = 0 end
        for _, sample in ipairs(samples or {}) do
            local endpoint_weight = (sample.parameter and (sample.parameter <= 1e-9 or sample.parameter >= 1 - 1e-9)) and 0.5 or 1
            local force = (Qa ~= 0 and sample.tau_a or sample.tau_b)
                * (sample.thickness or 0) * (sample.ds or 0) * endpoint_weight
            if sample.segment then
                result[sample.segment] = result[sample.segment] + math.abs(force)
                local sample_u, sample_v = displayedVector(sample.u, sample.v)
                local center_u, center_v = displayedVector(system_results.ys, system_results.zs)
                local tangent_u, tangent_v = displayedVector(sample.tangent_u, sample.tangent_v)
                moments[sample.segment] = moments[sample.segment]
                    - ((sample_u - center_u) * tangent_v - (sample_v - center_v) * tangent_u) * force
            end
        end
        return result, moments
    end
    local first, first_moment = contributions(1, 0)
    local second, second_moment = contributions(0, 1)
    local rows = {}
    local total_first, total_second = 0, 0
    for index = 1, #duenn_elemente do
        total_first, total_second = total_first + first_moment[index], total_second + second_moment[index]
        rows[index] = {name = "D" .. index, first = first[index], second = second[index], moment_first = first_moment[index], moment_second = second_moment[index]}
    end
    return {rows = rows, total_first = total_first, total_second = total_second}
end

local function polygon_width_at_v(points, v)
    local intersections = {}
    for i = 1, #points do
        local p1, p2 = points[i], points[i % #points + 1]
        if (p1.v <= v and p2.v > v) or (p2.v <= v and p1.v > v) then
            local f = (v - p1.v) / (p2.v - p1.v)
            table.insert(intersections, p1.u + f * (p2.u - p1.u))
        end
    end
    table.sort(intersections)
    local width = 0
    for i = 1, #intersections - 1, 2 do
        width = width + math.max(0, intersections[i + 1] - intersections[i])
    end
    return width
end

local function polygon_height_at_u(points, u)
    local intersections = {}
    for i = 1, #points do
        local p1, p2 = points[i], points[i % #points + 1]
        if (p1.u <= u and p2.u > u) or (p2.u <= u and p1.u > u) then
            local f = (u - p1.u) / (p2.u - p1.u)
            table.insert(intersections, p1.v + f * (p2.v - p1.v))
        end
    end
    table.sort(intersections)
    local height = 0
    for i = 1, #intersections - 1, 2 do
        height = height + math.max(0, intersections[i + 1] - intersections[i])
    end
    return height
end

local function massiv_width_at_v(v)
    local width = 0
    for _, elem in ipairs(massiv_elemente) do
        local sign = elem.is_hole and -1 or 1
        if elem.type == "rect" then
            local p = elem.points
            local min_v, max_v = math.min(p[1].v, p[2].v), math.max(p[1].v, p[2].v)
            if v >= min_v and v <= max_v then width = width + sign * math.abs(p[2].u - p[1].u) end
        elseif elem.type == "circle" then
            local c, p = elem.points[1], elem.points[2]
            local radius = math.sqrt((p.u-c.u)^2 + (p.v-c.v)^2)
            local dv = v - c.v
            if math.abs(dv) < radius then width = width + sign * 2 * math.sqrt(radius^2 - dv^2) end
        elseif elem.type == "triangle" or elem.type == "trapezoid" then
            width = width + sign * polygon_width_at_v(elem.points, v)
        end
    end
    return math.max(0, width)
end

local function massiv_height_at_u(u)
    local height = 0
    for _, elem in ipairs(massiv_elemente) do
        local sign = elem.is_hole and -1 or 1
        if elem.type == "rect" then
            local p = elem.points
            local min_u, max_u = math.min(p[1].u, p[2].u), math.max(p[1].u, p[2].u)
            if u >= min_u and u <= max_u then height = height + sign * math.abs(p[2].v - p[1].v) end
        elseif elem.type == "circle" then
            local c, p = elem.points[1], elem.points[2]
            local radius = math.sqrt((p.u-c.u)^2 + (p.v-c.v)^2)
            local du = u - c.u
            if math.abs(du) < radius then height = height + sign * 2 * math.sqrt(radius^2 - du^2) end
        elseif elem.type == "triangle" or elem.type == "trapezoid" then
            height = height + sign * polygon_height_at_u(elem.points, u)
        end
    end
    return math.max(0, height)
end

berechneSchubspannungsResultate = function(input_Qa, input_Qb)
    if not system_results then return nil end
    local r = system_results
    local a, b = axes()
    local force_Qa, force_Qb = 0, 0
    for _, kraft in ipairs(kraefte) do
        force_Qa = force_Qa + (tonumber(kraft.fa) or 0)
        force_Qb = force_Qb + (tonumber(kraft.fb) or 0)
    end
    local Qa, Qb = (input_Qa or 0) + force_Qa, (input_Qb or 0) + force_Qb
    local force_torsion = berechneKraftTorsion()
    if force_torsion then
        torsion_results = force_torsion
        aktualisiereTorsionsverlauf(torsion_results)
    end
    local torsion_constant, enclosed_area = find_closed_cells()
    local thin_closed = #duenn_elemente > 0 and torsion_constant > 1e-9
    local shear_center = berechneSchubmittelpunkt()
    if #massiv_elemente == 0 and #duenn_elemente > 0 then
        local maximum, samples, paths = berechneDuenneSchubspannung(Qa, Qb)
        if not maximum then return nil end
        return {
            Qa = Qa, Qb = Qb, force_Qa = force_Qa, force_Qb = force_Qb,
            max_tau = maximum.abs_tau, max_u = maximum.u, max_v = maximum.v,
            samples = samples, paths = paths, thin_walled = true, axis_a = a, axis_b = b,
            thin_closed = thin_closed, torsion_constant = torsion_constant, enclosed_area = enclosed_area,
            shear_center = shear_center, torsion_open = r.It, torsion_closed = r.It_closed
        }
    end
    local min_u, max_u, min_v, max_v = math.huge, -math.huge, math.huge, -math.huge
    for _, elem in ipairs(massiv_elemente) do
        local u1, u2, v1, v2 = getBoundingBox(elem)
        min_u, max_u = math.min(min_u, u1), math.max(max_u, u2)
        min_v, max_v = math.min(min_v, v1), math.max(max_v, v2)
    end
    if min_u == math.huge then return nil end

    -- TM2-Ansatz: eindimensionale Schnittintegration, keine 2D-Rasterzellen.
    local slices = 160
    local dv = math.max((max_v - min_v) / slices, 1e-9)
    local du = math.max((max_u - min_u) / slices, 1e-9)
    local tau_b, tau_a, samples = {}, {}, {}
    local moment_b, moment_a = 0, 0
    for row = slices, 1, -1 do
        local v = min_v + (row - 0.5) * dv
        local width = massiv_width_at_v(v)
        moment_b = moment_b + (v - r.zs) * width * dv
        tau_b[row] = math.abs(r.Iy) > 1e-12 and math.abs(Qb * moment_b / math.max(math.abs(r.Iy * width), 1e-12)) or 0
    end
    for column = slices, 1, -1 do
        local u = min_u + (column - 0.5) * du
        local height = massiv_height_at_u(u)
        moment_a = moment_a + (u - r.ys) * height * du
        tau_a[column] = math.abs(r.Iz) > 1e-12 and math.abs(Qa * moment_a / math.max(math.abs(r.Iz * height), 1e-12)) or 0
    end
    local max_tau, max_u, max_v = 0, r.ys, r.zs
    for row = 1, slices do
        local v = min_v + (row - 0.5) * dv
        for column = 1, slices do
            local u = min_u + (column - 0.5) * du
            local tau = math.sqrt((tau_a[column] or 0)^2 + (tau_b[row] or 0)^2)
            if tau > 0 then table.insert(samples, {u = u, v = v, tau_a = tau_a[column] or 0, tau_b = tau_b[row] or 0, tau = tau}) end
            if tau > max_tau then max_tau, max_u, max_v = tau, u, v end
        end
    end
    local profile_samples = {}
    for row = 1, slices do
        local v = min_v + (row - 0.5) * dv
        local width = massiv_width_at_v(v)
        if width > 1e-12 then
            table.insert(profile_samples, {u = r.ys, v = v, tau_a = 0, tau_b = tau_b[row] or 0, tau = tau_b[row] or 0, moment_y_density = (v - r.zs) * width, moment_z_density = 0, parameter = row / slices, profile = "massiv_b"})
        end
    end
    for column = 1, slices do
        local u = min_u + (column - 0.5) * du
        local height = massiv_height_at_u(u)
        if height > 1e-12 then
            table.insert(profile_samples, {u = u, v = r.zs, tau_a = tau_a[column] or 0, tau_b = 0, tau = tau_a[column] or 0, moment_y_density = 0, moment_z_density = (u - r.ys) * height, parameter = column / slices, profile = "massiv_a"})
        end
    end
    return {
        Qa = Qa, Qb = Qb, force_Qa = force_Qa, force_Qb = force_Qb,
        max_tau = max_tau, max_u = max_u, max_v = max_v,
        samples = profile_samples, axis_a = a, axis_b = b,
        thin_closed = thin_closed, torsion_constant = torsion_constant, enclosed_area = enclosed_area,
        shear_center = shear_center, torsion_open = r.It, torsion_closed = r.It_closed
    }
end

local function finish_shape(type_name)
    if type_name == "force" then
        local pt = pending[1]
        table.insert(kraefte, {u = pt.u, v = pt.v, fa = 0, fb = 0, fc = 0})
        pending = {}
        mode = "idle"
        status = "Kraft platziert. Hover + Enter zum Bearbeiten."
        platform.window:invalidate()
        return
    end
    local elem = {type = type_name, points = pending, is_hole = false, is_numeric = false}
    if type_name == "massiv_linie" then
        elem.t = default_t
    end
    local status_overlap = checkOverlapStatus(elem)
    
    if status_overlap == "inside" then
        elem.is_hole = true
        table.insert(massiv_elemente, elem)
        pending = {}
        mode = "idle"
        status = "Element als Loch abgezogen."
        berechneSystem()
        platform.window:invalidate()
    elseif status_overlap == "partial" then
        overlap_pending_elem = elem
        mode = "overlap_prompt"
        status = "Ueberlappung! 1: Abziehen 2: Addieren (Numerisch) 3: Verwerfen"
        platform.window:invalidate()
    else
        table.insert(massiv_elemente, elem)
        pending = {}
        mode = "idle"
        status = "Element erstellt."
        berechneSystem()
        platform.window:invalidate()
    end
end

local function finish_thin_line()
    if #pending >= 2 then
        for i=1, #pending-1 do
            table.insert(duenn_elemente, {points = {pending[i], pending[i+1]}, t = default_t})
        end
    end
    pending = {}
    mode = "idle"
    status = "Duennwandiges Profil erstellt."
    berechneSystem()
    platform.window:invalidate()
end

local function drawAxes(gc)
    local a, b = axes()
    local x, y = toScreenKOS(0,0)
    local hx, hy = toScreenKOS(1,0)
    local vx, vy = toScreenKOS(0,1)
    
    local dx1, dy1 = hx - x, hy - y
    local mag1 = math.sqrt(dx1^2 + dy1^2)
    local X, Y = x, y
    if mag1 > 1e-5 then X, Y = x + dx1/mag1 * kos_pixel_length, y + dy1/mag1 * kos_pixel_length end
    
    local dx2, dy2 = vx - x, vy - y
    local mag2 = math.sqrt(dx2^2 + dy2^2)
    local Z, W = x, y
    if mag2 > 1e-5 then Z, W = x + dx2/mag2 * kos_pixel_length, y + dy2/mag2 * kos_pixel_length end
    
    gc:setColorRGB(35, 150, 70)
    gc:setPen("thin", "smooth")
    gc:drawLine(x, y, X, Y)
    gc:drawLine(x, y, Z, W)
    gc:setFont("sansserif", "r", 9)
    gc:drawString(a, X+4, Y-9)
    gc:drawString(b, Z+4, W-9)
    gc:setFont("sansserif", "r", 7)
    gc:drawString("0", x+3, y+2)
    
    if system_results then
        local sx, sy = toScreen(system_results.ys, system_results.zs)
        gc:setColorRGB(255, 0, 0)
        gc:drawLine(sx-5, sy, sx+5, sy)
        gc:drawLine(sx, sy-5, sx, sy+5)
        
        -- Draw Hauptachsen
        local HA_len = 1.0 * scale
        local a_rad = system_results.alpha
        local hx1 = sx + HA_len * math.cos(a_rad)
        local hy1 = sy - HA_len * math.sin(a_rad) -- negative for screen Y
        local hx2 = sx + HA_len * math.cos(a_rad + math.pi/2)
        local hy2 = sy - HA_len * math.sin(a_rad + math.pi/2)
        
        gc:setColorRGB(200, 50, 255)
        gc:setPen("thin", "dashed")
        gc:drawLine(sx, sy, hx1, hy1)
        gc:drawLine(sx, sy, hx2, hy2)
        gc:setFont("sansserif", "r", 8)
        gc:drawString("1", hx1+2, hy1-8)
        gc:drawString("2", hx2+2, hy2-8)
    end
end

local function drawGrid(gc, w, h)
    gc:setColorRGB(180, 180, 180)
    for i = -30, 30 do
        for j = -24, 24 do
            local x, y = toScreen(i * raster, j * raster)
            if x >= 0 and x <= w and y >= 0 and y <= h then
                gc:fillRect(x, y, 1, 1)
            end
        end
    end
end

local function drawShapePath(gc, elem)
    
    if elem.type == "rect" then
        local p = elem.points
        local min_u, max_u = math.min(p[1].u, p[2].u), math.max(p[1].u, p[2].u)
        local min_v, max_v = math.min(p[1].v, p[2].v), math.max(p[1].v, p[2].v)
        local a, b = toScreen(min_u, min_v)
        local c, d = toScreen(max_u, max_v)
        local l, t = math.min(a, c), math.min(b, d)
        local w, h = math.abs(c - a), math.abs(d - b)
        gc:fillRect(l, t, w, h)
        gc:drawRect(l, t, w, h)
    elseif elem.type == "circle" or elem.type == "duenn_kreis" then
        local C = elem.points[1]
        local R = math.sqrt((elem.points[2].u - C.u)^2 + (elem.points[2].v - C.v)^2)
        local a, b = toScreen(C.u - R, C.v - R)
        local c, d = toScreen(C.u + R, C.v + R)
        local l, t = math.min(a, c), math.min(b, d)
        local w, h = math.abs(c - a), math.abs(d - b)
        gc:fillArc(l, t, w, h, 0, 360)
        gc:drawArc(l, t, w, h, 0, 360)
    elseif elem.type == "triangle" or elem.type == "trapezoid" then
        local q = {}
        for _, p in ipairs(elem.points) do
            local x, y = toScreen(p.u, p.v)
            table.insert(q, x)
            table.insert(q, y)
        end
        gc:fillPolygon(q)
        table.insert(q, q[1])
        table.insert(q, q[2])
        gc:drawPolyLine(q)
    elseif elem.type == "massiv_linie" then
        local p1, p2 = elem.points[1], elem.points[2]
        local du, dv = p2.u - p1.u, p2.v - p1.v
        local L = math.sqrt(du^2 + dv^2)
        local nx, ny = 0, 0
        if L > 1e-9 then nx, ny = (-dv/L) * (elem.t/2), (du/L) * (elem.t/2) end
        local pts = {
            {u = p1.u + nx, v = p1.v + ny},
            {u = p2.u + nx, v = p2.v + ny},
            {u = p2.u - nx, v = p2.v - ny},
            {u = p1.u - nx, v = p1.v - ny}
        }
        local q = {}
        for _, p in ipairs(pts) do
            local x, y = toScreen(p.u, p.v)
            table.insert(q, x)
            table.insert(q, y)
        end
        gc:fillPolygon(q)
        table.insert(q, q[1])
        table.insert(q, q[2])
        gc:drawPolyLine(q)
    elseif elem.type == "sector" or elem.type == "segment" or elem.type == "duenn_kreis_bogen" then
        local C = elem.points[1]
        local R = math.sqrt((elem.points[2].u - C.u)^2 + (elem.points[2].v - C.v)^2)
        local a1 = math.atan2(elem.points[2].v - C.v, elem.points[2].u - C.u)
        local a2 = math.atan2(elem.points[3].v - C.v, elem.points[3].u - C.u)
        local diff = a2 - a1
        if diff <= 0 then diff = diff + 2*math.pi end
        
        local start_angle = math.deg(a1)
        local arc_angle = math.deg(diff)
        
        local a, b = toScreen(C.u - R, C.v - R)
        local c, d = toScreen(C.u + R, C.v + R)
        local l, t = math.min(a, c), math.min(b, d)
        local w, h = math.abs(c - a), math.abs(d - b)
        
        -- on screen, angles might be flipped if rotation/swapped
        -- Simplification: draw an approximated polygon
        local q = {}
        if elem.type == "sector" then
            local cx, cy = toScreen(C.u, C.v)
            table.insert(q, cx)
            table.insert(q, cy)
        end
        local steps = math.max(10, math.floor(arc_angle / 5))
        for i=0, steps do
            local ang = a1 + (i/steps)*diff
            local pu = C.u + R * math.cos(ang)
            local pv = C.v + R * math.sin(ang)
            local sx, sy = toScreen(pu, pv)
            table.insert(q, sx)
            table.insert(q, sy)
        end
        gc:fillPolygon(q)
        table.insert(q, q[1])
        table.insert(q, q[2])
        gc:drawPolyLine(q)
    end
end
local function drawLocalAxes(gc, elem)
    if not elem.ys or not elem.zs or not elem.alpha then return end
    local sx, sy = toScreen(elem.ys, elem.zs)
    local len = 30
    local a_rad = elem.alpha
    
    local hx1, hy1 = toScreen(elem.ys + math.cos(a_rad), elem.zs + math.sin(a_rad))
    local dx1, dy1 = hx1 - sx, hy1 - sy
    local mag1 = math.sqrt(dx1^2 + dy1^2)
    if mag1 > 1e-5 then dx1, dy1 = dx1/mag1 * len, dy1/mag1 * len end
    
    local hx2, hy2 = toScreen(elem.ys + math.cos(a_rad + math.pi/2), elem.zs + math.sin(a_rad + math.pi/2))
    local dx2, dy2 = hx2 - sx, hy2 - sy
    local mag2 = math.sqrt(dx2^2 + dy2^2)
    if mag2 > 1e-5 then dx2, dy2 = dx2/mag2 * len, dy2/mag2 * len end
    
    gc:setColorRGB(0, 100, 200)
    gc:setPen("medium", "smooth")
    gc:drawLine(sx, sy, sx + dx1, sy + dy1)
    gc:drawLine(sx, sy, sx + dx2, sy + dy2)
    gc:setFont("sansserif", "i", 9)
    gc:drawString("eta", sx + dx1 + 2, sy + dy1 - 8)
    gc:drawString("zeta", sx + dx2 + 2, sy + dy2 - 8)
end

local function drawSpreadsheet(gc, w, h)
    if not showResults then return end
    local width = 210
    local left = w - width
    local top = -results_scroll_y
    gc:setColorRGB(248, 248, 248)
    gc:fillRect(left, 0, width, h)
    gc:setColorRGB(0, 0, 0)
    gc:drawLine(left, 0, left, h)
    gc:clipRect("set", left, 0, width, h)

    gc:setFont("sansserif", "b", 9)
    gc:drawString("Ergebnisse", left + 5, top + 5)
    gc:setFont("sansserif", "r", 9)

    if system_results then
        local r = system_results
        local a, b = axes()
        local display_ys, display_zs = coordinatesForDisplay(r.ys, r.zs)
        local iy_origin = r.IyS + r.A * r.zs^2
        local iz_origin = r.IzS + r.A * r.ys^2
        local iyz_origin = r.IyzS - r.A * r.ys * r.zs
        local lines = {
            string.format("A = %.4g [%s]", display_area(r.A), unit_label(2)),
            string.format("%s_s = %.4g [%s]", a, display_length(display_ys), unit_label(1)),
            string.format("%s_s = %.4g [%s]", b, display_length(display_zs), unit_label(1)),
            string.format("I_%s = %.4g [%s]", a, display_inertia(iy_origin), unit_label(4)),
            string.format("I_%s = %.4g [%s]", b, display_inertia(iz_origin), unit_label(4)),
            string.format("I_%s%s = %.4g [%s]", a, b, display_inertia(iyz_origin), unit_label(4)),
            string.format("i_%s = %.4g [%s]", a, display_length(math.sqrt(math.abs(r.IyS / r.A))), unit_label(1)),
            string.format("i_%s = %.4g [%s]", b, display_length(math.sqrt(math.abs(r.IzS / r.A))), unit_label(1)),
            string.format("W_%s = %.4g [%s]", a, display_volume(r.Wu), unit_label(3)),
            string.format("W_%s = %.4g [%s]", b, display_volume(r.Wv), unit_label(3)),
            string.format("I_1,S = %.4g [%s]", display_inertia(r.I1), unit_label(4)),
            string.format("I_2,S = %.4g [%s]", display_inertia(r.I2), unit_label(4)),
            string.format("alpha = %.2f [deg]", math.deg(r.alpha)),
        }
        if #duenn_elemente > 0 then
            table.insert(lines, string.format("I_T(offen) = %.4g [%s]", display_inertia(r.It), unit_label(4)))
            if r.It_closed > 1e-9 then
                table.insert(lines, string.format("I_T(geschlossen) = %.4g [%s]", display_inertia(r.It_closed), unit_label(4)))
                table.insert(lines, string.format("A_m = %.4g [%s]", display_area(r.Am), unit_label(2)))
            end
        end
        if shear_results then
            table.insert(lines, "--- Schubspannung ---")
            table.insert(lines, string.format("Q_%s = %.4g [%s]", shear_results.axis_a, display_force(shear_results.Qa), force_unit))
            table.insert(lines, string.format("Q_%s = %.4g [%s]", shear_results.axis_b, display_force(shear_results.Qb), force_unit))
            table.insert(lines, string.format("Q_%s aus Kraeften = %.4g [%s]", shear_results.axis_a, display_force(shear_results.force_Qa), force_unit))
            table.insert(lines, string.format("Q_%s aus Kraeften = %.4g [%s]", shear_results.axis_b, display_force(shear_results.force_Qb), force_unit))
            table.insert(lines, string.format("tau_max = %.4g [MPa]", shear_results.max_tau))
            if shear_results.max_tau_total then
                table.insert(lines, string.format("tau_gesamt,max = %.4g [MPa]", shear_results.max_tau_total))
            end
            table.insert(lines, string.format("bei (%s,%s) = (%.4g,%.4g)", shear_results.axis_a, shear_results.axis_b, shear_results.max_u, shear_results.max_v))
            if shear_results.thin_walled then
                table.insert(lines, shear_results.thin_closed and "duennwandig geschlossen" or "duennwandig offen")
                if shear_results.thin_closed then
                    table.insert(lines, string.format("A_m = %.4g [%s]", display_area(shear_results.enclosed_area or 0), unit_label(2)))
                end
                if shear_results.shear_center then
                    if shear_results.shear_center.known then
                        table.insert(lines, "Schubmittelpunkt = (" .. formatLabel(display_length(coordinatesForDisplay(shear_results.shear_center.u, shear_results.shear_center.v))) .. ", " .. formatLabel(display_length(select(2, coordinatesForDisplay(shear_results.shear_center.u, shear_results.shear_center.v)))) .. ") [" .. length_unit .. "]")
                        if shear_results.shear_center.moment_a then
                            table.insert(lines, string.format("Probe-Ma = %.4g [%s]", display_moment(shear_results.shear_center.moment_a), moment_unit))
                            table.insert(lines, string.format("Probe-Mb = %.4g [%s]", display_moment(shear_results.shear_center.moment_b), moment_unit))
                        end
                    else
                        table.insert(lines, "Schubmittelpunkt: Symmetriepruefung offen")
                    end
                    table.insert(lines, string.format("I_T offen = %.4g [%s]", display_inertia(shear_results.torsion_open or 0), unit_label(4)))
                    if shear_results.thin_closed then
                        table.insert(lines, string.format("I_T geschlossen = %.4g [%s]", display_inertia(shear_results.torsion_closed or 0), unit_label(4)))
                    end
                end
            end
        end
        if torsion_results then
            table.insert(lines, "--- Torsion ---")
            table.insert(lines, string.format("MT = %.4g [%s]", display_moment(torsion_results.M), moment_unit))
            table.insert(lines, string.format("I_T = %.4g [%s]", display_inertia(torsion_results.It), unit_label(4)))
            table.insert(lines, string.format("tau_T,max = %.4g [MPa]", torsion_results.tau))
            table.insert(lines, torsion_results.closed and "geschlossen" or "offen")
        end

        for i, text in ipairs(lines) do
            gc:drawString(text, left + 5, top + 20 + i * 16)
        end

        if math.abs(r.Iyz) < 1e-5 and math.abs(r.A) > 1e-9 then
            gc:setColorRGB(35, 150, 70)
            gc:setFont("sansserif", "b", 9)
            gc:drawString("System ist symmetrisch!", left + 5, top + 20 + (#lines + 2) * 16)
        end
        if is_numeric_system then
            gc:setColorRGB(255, 100, 0)
            gc:setFont("sansserif", "b", 9)
            gc:drawString("Warnung: Numerisch berechnet!", left + 5, top + 20 + (#lines + 4) * 16)
        end
    else
        gc:drawString("Keine Flaechen gezeichnet.", left + 5, top + 25)
    end
    gc:clipRect("reset")
end

local function drawSigmaInput(gc, w, h)
    if sigma_input_step == 0 then return end
    local left, top, width = 12, 28, math.min(260, w - 24)
    local function valueText(value)
        return value == nil and "" or string.format("%.6g", value)
    end

    local field_left = left + 72
    local field_width = width - 84
    local height = sigma_oblique and 170 or 136
    local moment_a, moment_b = axes()

    gc:setColorRGB(248, 248, 248)
    gc:fillRect(left, top, width, height)
    gc:setColorRGB(0, 0, 0)
    gc:drawRect(left, top, width, height)
    gc:setFont("sansserif", "b", 10)
    gc:drawString("σx Eingabe", left + 8, top + 8)
    gc:setFont("sansserif", "r", 9)
    gc:drawString("N [" .. force_unit .. "]", left + 8, top + 36)
    gc:drawString("M" .. moment_a .. " [" .. moment_unit .. "]", left + 8, top + 70)
    gc:drawRect(field_left, top + 28, field_width, 20)
    gc:drawRect(field_left, top + 62, field_width, 20)
    gc:drawString(sigma_input_step == 1 and inputText .. "_" or valueText(sigma_N), field_left + 5, top + 33)
    gc:drawString(sigma_input_step == 2 and inputText .. "_" or valueText(sigma_My), field_left + 5, top + 67)
    if sigma_oblique then
        gc:drawString("M" .. moment_b .. " [" .. moment_unit .. "]", left + 8, top + 104)
        gc:drawRect(field_left, top + 96, field_width, 20)
        gc:drawString(sigma_input_step == 3 and inputText .. "_" or "", field_left + 5, top + 101)
    end
    gc:setFont("sansserif", "r", 8)
    gc:drawString("Enter bestaetigen, Esc abbrechen", left + 8, top + (sigma_oblique and 146 or 112))
end

local function drawShearInput(gc, w, h)
    if shear_input_step == 0 then return end
    local left, top, width = 12, 28, math.min(280, w - 24)
    local a, b = axes()
    local field_left, field_width = left + 72, width - 84
    gc:setColorRGB(248, 248, 248)
    local input_height = shear_external_input and 180 or 112
    gc:fillRect(left, top, width, input_height)
    gc:setColorRGB(0, 0, 0)
    gc:drawRect(left, top, width, input_height)
    gc:setFont("sansserif", "b", 10)
    gc:drawString("Schubkraft-Eingabe", left + 8, top + 8)
    gc:setFont("sansserif", "r", 9)
    gc:drawString("Q" .. a .. " [" .. force_unit .. "]", left + 8, top + 36)
    gc:drawString("Q" .. b .. " [" .. force_unit .. "]", left + 8, top + 70)
    gc:drawRect(field_left, top + 28, field_width, 20)
    gc:drawRect(field_left, top + 62, field_width, 20)
    gc:drawString(shear_input_step == 1 and inputText .. "_" or string.format("%.6g", shear_Qa or 0), field_left + 5, top + 33)
    gc:drawString(shear_input_step == 2 and inputText .. "_" or string.format("%.6g", shear_Qb or 0), field_left + 5, top + 67)
    if shear_external_input then
        gc:drawString("N [" .. force_unit .. "]", left + 8, top + 104)
        gc:drawString("MT [" .. moment_unit .. "]", left + 8, top + 138)
        gc:drawRect(field_left, top + 96, field_width, 20)
        gc:drawRect(field_left, top + 130, field_width, 20)
        gc:drawString(shear_input_step == 3 and inputText .. "_" or string.format("%.6g", shear_N or 0), field_left + 5, top + 101)
        gc:drawString(shear_input_step == 4 and inputText .. "_" or string.format("%.6g", shear_M or 0), field_left + 5, top + 135)
    end
    gc:setFont("sansserif", "r", 8)
    gc:drawString("Enter bestaetigen, Esc abbrechen", left + 8, top + (shear_external_input and 168 or 94))
end

local function drawTorsionInput(gc, w, h)
    if torsion_input_step == 0 then return end
    local left, top, width = 12, 28, 250
    gc:setColorRGB(248, 248, 248); gc:fillRect(left, top, width, 88)
    gc:setColorRGB(0, 0, 0); gc:drawRect(left, top, width, 88)
    gc:setFont("sansserif", "b", 10); gc:drawString("Torsion", left + 8, top + 8)
    gc:setFont("sansserif", "r", 9); gc:drawString("MT [" .. moment_unit .. "]", left + 8, top + 36)
    gc:drawRect(left + 72, top + 28, width - 84, 20)
    gc:drawString(inputText .. "_", left + 77, top + 33)
    gc:setFont("sansserif", "r", 8); gc:drawString("Enter bestaetigen, Esc abbrechen", left + 8, top + 68)
end

local function drawShearProfileLegacy(gc)
    if not shear_profile_visible or not shear_results or not shear_results.samples then return end
    local maximum = math.max(shear_results.max_tau, 1e-9)
    local hovered_segment = hover_type == "duenn" and hover_idx or nil
    local axis_a, axis_b = axes()
    -- Reihenfolge: 1/2 Momentendichten, 3/4 statische Momente, 5/6 Schubspannungsanteile,
    -- 7 Resultierend aus Querkraft, 8 Torsion, 9 Gesamt aus allem, 10 Laufvariable s.
    local profile_name = shear_view_mode == 1 and axis_a .. "*h(" .. axis_a .. ") [" .. unit_label(2) .. "]"
        or shear_view_mode == 2 and axis_b .. "*h(" .. axis_b .. ") [" .. unit_label(2) .. "]"
        or shear_view_mode == 3 and "S" .. axis_a .. " [" .. unit_label(3) .. "]"
        or shear_view_mode == 4 and "S" .. axis_b .. " [" .. unit_label(3) .. "]"
        or shear_view_mode == 5 and "τ_" .. axis_a .. "-Anteil [MPa]"
        or shear_view_mode == 6 and "τ_" .. axis_b .. "-Anteil [MPa]"
        or shear_view_mode == 7 and "Resultierend aus Querkraft: τ_" .. axis_a .. " + τ_" .. axis_b .. " [MPa]"
        or shear_view_mode == 8 and "Torsionsanteil [MPa]"
        or shear_view_mode == 9 and "Gesamtschubspannung [MPa]"
        or shear_view_mode == 10 and "Laufvariable s [" .. unit_label(1) .. "]"
        or "Schubspannungsverlauf"
    gc:setColorRGB(20, 70, 150)
    gc:setFont("sansserif", "b", 10)
    gc:drawString(profile_name, 6, 5)
    gc:setFont("sansserif", "r", 9)
    local function profile_value(sample)
        local display_sz, display_sy = coordinatesForDisplay(sample.Sz or 0, sample.Sy or 0)
        return shear_view_mode == 1 and displayedMomentDensity(sample)
            or shear_view_mode == 2 and select(2, displayedMomentDensity(sample))
            or shear_view_mode == 3 and display_sy
            or shear_view_mode == 4 and display_sz
            or shear_view_mode == 5 and sample.tau_a
            or shear_view_mode == 6 and sample.tau_b
            or shear_view_mode == 8 and torsionTauAtSample(sample)
            or shear_view_mode == 9 and combinedTauAtSample(sample)
            or shear_view_mode == 10 and (sample.s or 0)
            or sample.tau
    end
    local function profile_display_value(sample)
        local value = profile_value(sample)
        if shear_view_mode == 1 or shear_view_mode == 2 then return display_area(value) end
        if shear_view_mode == 3 or shear_view_mode == 4 then return display_volume(value) end
        if shear_view_mode == 10 then return display_length(value) end
        return value
    end
    local sections = {}
    local current_section = nil
    local current_key = nil
    for index, sample in ipairs(shear_results.samples) do
        if not hovered_segment or sample.segment == hovered_segment then
            local section_key = tostring(sample.path_id or 1) .. ":" .. tostring(sample.segment or sample.profile or 1)
            if not current_section or current_key ~= section_key then
                current_section = {}
                table.insert(sections, current_section)
                current_key = section_key
            end
            table.insert(current_section, {index = index, sample = sample})
        end
    end
    local hovered_max_value, hovered_max_sample = -math.huge, nil
    if hovered_segment then
        for _, section in pairs(sections) do
            for _, entry in ipairs(section) do
                local value = profile_value(entry.sample)
                if value > hovered_max_value then
                    hovered_max_value, hovered_max_sample = value, entry.sample
                end
            end
        end
    end
    local shared_section_max = 1e-9
    for _, section in ipairs(sections) do
        for _, entry in ipairs(section) do
            shared_section_max = math.max(shared_section_max, math.abs(profile_value(entry.sample)))
        end
    end
    for _, section in pairs(sections) do
        table.sort(section, function(left, right)
            return (left.sample.s or left.sample.parameter or left.index) < (right.sample.s or right.sample.parameter or right.index)
        end)
        local section_max = shared_section_max
        local first_sample = section[1] and section[1].sample
        local normal_u = first_sample and -(first_sample.tangent_v or 0) or 0
        local normal_v = first_sample and (first_sample.tangent_u or 0) or 0
        local diagram_width = 36 / math.max(scale, 1e-9)
        local previous_x, previous_y = nil, nil
        local min_value, max_value = math.huge, -math.huge
        local min_sample, max_sample
        for _, entry in ipairs(section) do
            local sample = entry.sample
            local value = profile_value(sample)
            if value < min_value then min_value, min_sample = value, sample end
            if value > max_value then max_value, max_sample = value, sample end
            local display_u, display_v = sample.u, sample.v
            if sample.profile == "massiv_b" then
                display_u = sample.u + (value / maximum) * diagram_width
            elseif sample.profile == "massiv_a" then
                display_v = sample.v + (value / maximum) * diagram_width
            elseif sample.display_normal_u and sample.display_normal_v then
                local sample_normal_u = sample.display_normal_u
                local sample_normal_v = sample.display_normal_v
                display_u = sample.u + sample_normal_u * value / section_max * diagram_width
                display_v = sample.v + sample_normal_v * value / section_max * diagram_width
            end
            local x, y = toScreen(display_u, display_v)
            if previous_x then
                gc:setColorRGB(45, 95, 175)
                gc:setPen("thin", "smooth")
                gc:drawLine(previous_x, previous_y, x, y)
            end
            previous_x, previous_y = x, y
        end
        local function draw_value(sample, label, color)
            if not sample then return end
            local value = profile_value(sample)
            local display_u, display_v = sample.u, sample.v
            if sample.profile == "massiv_b" then
                display_u = sample.u + (value / maximum) * diagram_width
            elseif sample.profile == "massiv_a" then
                display_v = sample.v + (value / maximum) * diagram_width
            elseif sample.display_normal_u and sample.display_normal_v then
                local sample_normal_u = sample.display_normal_u
                local sample_normal_v = sample.display_normal_v
                display_u = sample.u + sample_normal_u * value / section_max * diagram_width
                display_v = sample.v + sample_normal_v * value / section_max * diagram_width
            end
            local x, y = toScreen(display_u, display_v)
            gc:setColorRGB(color[1], color[2], color[3])
            gc:fillArc(x - 2, y - 2, 4, 4, 0, 360)
            gc:setFont("sansserif", "r", 8)
            local label_value = profile_display_value(sample)
            local label_prefix = label ~= "" and label .. " " or ""
            gc:drawString(label_prefix .. formatLabel(label_value), x + 4, y - 10)
        end
        local function draw_boundary_connector(sample)
            if not sample or not sample.display_normal_u or not sample.display_normal_v then return end
            local value = profile_value(sample)
            local display_u = sample.u + sample.display_normal_u * value / section_max * diagram_width
            local display_v = sample.v + sample.display_normal_v * value / section_max * diagram_width
            local source_x, source_y = toScreen(sample.u, sample.v)
            local target_x, target_y = toScreen(display_u, display_v)
            gc:setColorRGB(150, 150, 150)
            gc:setPen("thin", "smooth")
            gc:drawLine(source_x, source_y, target_x, target_y)
        end
        draw_boundary_connector(section[1] and section[1].sample)
        draw_boundary_connector(section[#section] and section[#section].sample)
        draw_value(section[1] and section[1].sample, "", {40, 80, 150})
        if section[#section] and section[#section].sample ~= section[1].sample then
            draw_value(section[#section].sample, "", {40, 80, 150})
        end
        if hovered_segment then
            if max_sample == hovered_max_sample and max_sample ~= section[1].sample and max_sample ~= section[#section].sample then
                draw_value(max_sample, "max", {190, 60, 60})
            end
        else
            if min_sample and max_sample and min_sample ~= section[1].sample and min_sample ~= section[#section].sample then draw_value(min_sample, "min", {190, 60, 60}) end
            if max_sample and max_sample ~= section[1].sample and max_sample ~= section[#section].sample then draw_value(max_sample, "max", {190, 60, 60}) end
        end
    end

    -- Die Pfeile zeigen die Orientierung der Laufvariablen, nicht die
    -- Richtung der Spannungskomponente.
    if shear_results.paths then
        gc:setColorRGB(145, 55, 180)
        gc:setPen("thin", "smooth")
        for _, path in ipairs(shear_results.paths) do
            if path.start_kind and path.items[1] and path.items[1].p1 then
                local start_point = path.items[1].p1
                local start_x, start_y = toScreen(start_point.u, start_point.v)
                gc:fillArc(start_x - 3, start_y - 3, 6, 6, 0, 360)
                gc:setFont("sansserif", "b", 9)
                gc:drawString("Start", start_x + 5, start_y - 10)
            end
            for _, item in ipairs(path.items) do
                if item.p1 and item.p2 and (not hovered_segment or item.edge.index == hovered_segment) then
                    local mx = (item.p1.u + item.p2.u) / 2
                    local mv = (item.p1.v + item.p2.v) / 2
                    local dx, dv = item.p2.u - item.p1.u, item.p2.v - item.p1.v
                    local length = math.sqrt(dx^2 + dv^2)
                    if length > 1e-9 then
                        local ux, uv = dx / length, dv / length
                        local tail_u, tail_v = mx - ux * 0.35, mv - uv * 0.35
                        local tip_u, tip_v = mx + ux * 0.35, mv + uv * 0.35
                        local tx, ty = toScreen(tail_u, tail_v)
                        local px, py = toScreen(tip_u, tip_v)
                        gc:drawLine(tx, ty, px, py)
                        local screen_dx, screen_dy = px - tx, py - ty
                        local screen_length = math.sqrt(screen_dx^2 + screen_dy^2)
                        if screen_length > 1e-9 then
                            local ax, ay = screen_dx / screen_length, screen_dy / screen_length
                            local nx, ny = -ay, ax
                            gc:drawLine(px, py, px - ax * 5 + nx * 3, py - ay * 5 + ny * 3)
                            gc:drawLine(px, py, px - ax * 5 - nx * 3, py - ay * 5 - ny * 3)
                        end
                    end
                end
            end
        end
    end
end

local function drawShearProfile(gc)
    if not shear_profile_visible or not shear_results or not shear_results.samples then return end
    drawShearProfileLegacy(gc)
end

local function drawShearSelector(gc, w, h)
    if not shear_selector_open then return end
    local a, b = axes()
    local items = {
        "1: " .. a .. "*h(" .. a .. ")",
        "2: " .. b .. "*h(" .. b .. ")",
        "3: S" .. a,
        "4: S" .. b,
        "5: τ_" .. a .. "-Anteil",
        "6: τ_" .. b .. "-Anteil",
        "7: Gesamt aus Querkraft",
        "8: Torsion",
        "9: Gesamt aus allem",
        "0: Laufvariable s"
    }
    local row_height = 18
    local width, height = 260, 34 + #items * row_height
    local left, top = (w - width) / 2, (h - height) / 2
    gc:setColorRGB(245, 250, 255)
    gc:fillRect(left, top, width, height)
    gc:setColorRGB(30, 80, 150)
    gc:drawRect(left, top, width, height)
    gc:setFont("sansserif", "b", 10)
    gc:drawString("Schubspannungsverlauf", left + 8, top + 8)
    gc:setFont("sansserif", "r", 9)
    for i, text in ipairs(items) do
        gc:drawString(text, left + 8, top + 22 + (i - 1) * row_height)
    end
end

local function drawSigmaResultsTable(gc, w, h)
    if not sigma_results then return end
    local left, top, width = 8, 8 - sigma_scroll_y, math.min(300, w - 16)
    local row_height = 17
    local moment_a, moment_b = axes()
    local max_display_y, max_display_z = coordinatesForDisplay(sigma_results.max_y, sigma_results.max_z)
    local min_display_y, min_display_z = coordinatesForDisplay(sigma_results.min_y, sigma_results.min_z)
    local rows = {
        {"N [" .. force_unit .. "]", string.format("%.6g %s", display_force(sigma_results.N), force_unit)},
        {"N aus Kraeften [" .. force_unit .. "]", string.format("%.6g %s", display_force(sigma_results.force_N or 0), force_unit)},
        {"M" .. moment_a .. " [" .. moment_unit .. "]", string.format("%.6g %s", display_moment(sigma_results.My_Nm), moment_unit)},
        {"M" .. moment_a .. " aus Kraeften [" .. moment_unit .. "]", string.format("%.6g %s", display_moment(sigma_results.force_Ma_Nm or 0), moment_unit)},
        {"M" .. moment_a .. " umgerechnet [Nmm]", string.format("%.6g Nmm", sigma_results.My_Nmm)},
        {"M" .. moment_b .. " [" .. moment_unit .. "]", string.format("%.6g %s", display_moment(sigma_results.Mz_Nm), moment_unit)},
        {"M" .. moment_b .. " aus Kraeften [" .. moment_unit .. "]", string.format("%.6g %s", display_moment(sigma_results.force_Mb_Nm or 0), moment_unit)},
        {"A [" .. unit_label(2) .. "]", string.format("%.6g %s", display_area(sigma_results.A), unit_label(2))},
        {"Iy [" .. unit_label(4) .. "]", string.format("%.6g %s", display_inertia(sigma_results.Iy), unit_label(4))},
        {"Iz [" .. unit_label(4) .. "]", string.format("%.6g %s", display_inertia(sigma_results.Iz), unit_label(4))},
        {"Iyz [" .. unit_label(4) .. "]", string.format("%.6g %s", display_inertia(sigma_results.Iyz), unit_label(4))},
        {"N/A [MPa]", string.format("%.6g MPa", sigma_results.normal)},
        {"σx,max [MPa]", string.format("%.6g MPa", sigma_results.sigma_max)},
        {"bei (y,z) [" .. unit_label(1) .. "]", string.format("(%.6g, %.6g) %s", display_length(max_display_y), display_length(max_display_z), length_unit)},
        {"σx,min [MPa]", string.format("%.6g MPa", sigma_results.sigma_min)},
        {"bei (y,z) [" .. unit_label(1) .. "]", string.format("(%.6g, %.6g) %s", display_length(min_display_y), display_length(min_display_z), length_unit)}
    }
    local height = (2 + #rows) * row_height + 8
    local split = left + math.min(108, width * 0.42)

    local viewport_top, viewport_bottom = 0, math.max(0, h - 24)
    local visible_top = math.max(top, viewport_top)
    local visible_bottom = math.min(top + height, viewport_bottom)
    if visible_bottom <= visible_top then return end

    gc:clipRect("set", 0, viewport_top, w, viewport_bottom - viewport_top)
    gc:setColorRGB(248, 248, 248)
    gc:fillRect(left, visible_top, width, visible_bottom - visible_top)
    gc:setColorRGB(0, 0, 0)
    if top >= viewport_top and top + height <= viewport_bottom then
        gc:drawRect(left, top, width, height)
    end
    gc:setFont("sansserif", "b", 10)
    if top + 4 >= viewport_top and top + 4 <= viewport_bottom then
        gc:drawString("σx Ergebnis", left + 6, top + 4)
    end
    gc:setFont("sansserif", "r", 8)
    local header_bottom = top + row_height + 8
    if header_bottom >= viewport_top and header_bottom <= viewport_bottom then
        gc:drawLine(left, header_bottom, left + width, header_bottom)
    end
    gc:drawLine(split, visible_top, split, visible_bottom)
    for i, row in ipairs(rows) do
        local y = top + row_height + 8 + i * row_height
        if y >= viewport_top and y <= viewport_bottom then
            gc:drawLine(left, y, left + width, y)
        end
        if y - 12 >= viewport_top and y - 12 <= viewport_bottom then
            gc:drawString(row[1], left + 4, y - 12)
            gc:drawString(row[2], split + 4, y - 12)
        end
    end
    gc:clipRect("reset")
end

local function drawSigmaDistribution(gc, w, h)
    if not sigma_results then return end

    local left = 8
    local top = 8 - sigma_scroll_y + (2 + 13) * 17 + 8 + 14
    local width = math.min(360, w - 16)
    local height = 250
    local graph_left, graph_right = left + 42, left + width - 10
    local graph_top, graph_bottom = top + 42, top + height - 24
    local r = sigma_results
    local denominator = r.Iy * r.Iz - r.Iyz^2
    if math.abs(denominator) < 1e-12 then return end

    local z_min = math.min(r.zs, r.max_z, r.min_z)
    local z_max = math.max(r.zs, r.max_z, r.min_z)
    if z_max - z_min < 1e-9 then z_min, z_max = z_min - 1, z_max + 1 end

    local my = r.My_Nmm
    local mz = r.Mz_Nmm
    local function bending(z)
        return ((my * r.Iz - mz * r.Iyz) / denominator) * (z - r.zs)
    end
    local sigma_min = math.min(0, r.normal + bending(z_min), r.normal + bending(z_max), r.normal)
    local sigma_max = math.max(0, r.normal + bending(z_min), r.normal + bending(z_max), r.normal)
    local sigma_range = math.max(1e-9, sigma_max - sigma_min)
    local function sx(z)
        return graph_left + (z - z_min) / (z_max - z_min) * (graph_right - graph_left)
    end
    local function sy(sigma)
        return graph_bottom - (sigma - sigma_min) / sigma_range * (graph_bottom - graph_top)
    end

    gc:clipRect("set", 0, 0, w, h - 24)
    gc:setColorRGB(248, 248, 248)
    gc:fillRect(left, top, width, height)
    gc:setColorRGB(0, 0, 0)
    gc:drawRect(left, top, width, height)
    gc:setFont("sansserif", "b", 10)
    gc:drawString("σx-Verteilung ueber z", left + 6, top + 5)
    gc:setFont("sansserif", "r", 8)
    gc:drawString("blau: My-Anteil   rot: N + My", left + 6, top + 21)

    local zero_y = sy(0)
    local normal_y = sy(r.normal)
    gc:setColorRGB(120, 120, 120)
    gc:setPen("thin", "smooth")
    gc:drawLine(graph_left, zero_y, graph_right, zero_y)
    gc:drawLine(graph_left, graph_top, graph_left, graph_bottom)
    gc:setColorRGB(80, 80, 80)
    gc:drawString("σ [MPa]", left + 4, graph_top - 2)
    gc:drawString(string.format("z = %.3g", z_min), graph_left - 8, graph_bottom + 5)
    gc:drawString(string.format("z = %.3g", z_max), graph_right - 38, graph_bottom + 5)

    local x1, x2 = sx(z_min), sx(z_max)
    local b1, b2 = bending(z_min), bending(z_max)
    local yb1, yb2 = sy(b1), sy(b2)
    local yt1, yt2 = sy(r.normal + b1), sy(r.normal + b2)

    gc:setColorRGB(170, 205, 240)
    gc:fillPolygon({x1, zero_y, x1, yb1, x2, yb2, x2, zero_y})
    gc:setColorRGB(40, 105, 190)
    gc:setPen("medium", "smooth")
    gc:drawLine(x1, zero_y, x2, zero_y)
    gc:drawLine(x1, yb1, x2, yb2)

    gc:setColorRGB(220, 70, 55)
    gc:setPen("thick", "smooth")
    gc:drawLine(x1, yt1, x2, yt2)
    gc:setColorRGB(0, 130, 70)
    gc:setPen("thin", "dashed")
    gc:drawLine(graph_left, normal_y, graph_right, normal_y)
    gc:setFont("sansserif", "r", 8)
    gc:drawString(string.format("N/A = %.3g", r.normal), graph_left + 4, normal_y - 10)
    gc:drawString(string.format("σx(z_min) = %.3g", r.normal + b1), x1 + 4, yt1 - 10)
    gc:drawString(string.format("σx(z_max) = %.3g", r.normal + b2), x2 - 80, yt2 - 10)
    gc:clipRect("reset")
end

local function drawSigmaCrossSection(gc, w, h)
    if not sigma_results then return end

    local r = sigma_results
    local min_u, max_u, min_v, max_v = math.huge, -math.huge, math.huge, -math.huge
    for _, elem in ipairs(massiv_elemente) do
        local u1, u2, v1, v2 = getBoundingBox(elem)
        min_u, max_u = math.min(min_u, u1), math.max(max_u, u2)
        min_v, max_v = math.min(min_v, v1), math.max(max_v, v2)
    end
    for _, elem in ipairs(duenn_elemente) do
        local u1, u2, v1, v2 = getBoundingBox(elem)
        min_u, max_u = math.min(min_u, u1), math.max(max_u, u2)
        min_v, max_v = math.min(min_v, v1), math.max(max_v, v2)
    end
    if min_u == math.huge then return end

    local left, top = 8, 8
    local width, height = math.max(120, w - 16), math.max(180, h - 28)
    local section_panel_width = math.max(120, math.floor(width * 0.56))
    local graph_left = left + section_panel_width + 6
    local graph_width = width - section_panel_width - 6
    local margin = 24
    local draw_left, draw_top = left + margin, top + 28
    local draw_width = section_panel_width - 2 * margin
    local draw_height = height - 48
    local span_u = math.max(max_u - min_u, 1e-9)
    local span_v = math.max(max_v - min_v, 1e-9)
    local factor = math.min(draw_width / span_u, draw_height / span_v)
    local section_width, section_height = span_u * factor, span_v * factor
    local section_left = draw_left + (draw_width - section_width) / 2
    local section_top = draw_top + (draw_height - section_height) / 2
    local columns, rows = 28, 22
    local cell_width, cell_height = section_width / columns, section_height / rows
    local denominator = r.Iy * r.Iz - r.Iyz^2

    local function screen(u, v)
        return section_left + (u - min_u) * factor, section_top + (max_v - v) * factor
    end
    local function stress(u, v)
        return r.normal
            + ((r.My_Nmm * r.Iz - r.Mz_Nmm * r.Iyz) / denominator) * (v - r.zs)
            - ((r.Mz_Nmm * r.Iy - r.My_Nmm * r.Iyz) / denominator) * (u - r.ys)
    end
    local stress_scale = math.max(math.abs(r.sigma_min), math.abs(r.sigma_max), 1e-9)
    local function color(value)
        local ratio = math.min(1, math.abs(value) / stress_scale)
        if value < -1e-9 then
            return 255 - math.floor(45 * ratio), 225 - math.floor(70 * ratio), 225 - math.floor(65 * ratio)
        elseif value > 1e-9 then
            return 220 - math.floor(70 * ratio), 235 - math.floor(55 * ratio), 255
        end
        return 248, 248, 248
    end

    gc:setColorRGB(248, 248, 248)
    gc:fillRect(left, top, width, height)
    gc:setColorRGB(0, 0, 0)
    gc:drawRect(left, top, width, height)
    gc:setFont("sansserif", "b", 10)
    gc:drawString("σx im Querschnitt", left + 8, top + 5)
    gc:setFont("sansserif", "r", 8)
    gc:drawString("Druck", left + 8, top + 19)
    gc:setColorRGB(235, 175, 175)
    gc:fillRect(left + 39, top + 13, 9, 8)
    gc:setColorRGB(0, 0, 0)
    gc:drawString("Zug", left + 56, top + 19)
    gc:setColorRGB(185, 210, 245)
    gc:fillRect(left + 76, top + 13, 9, 8)
    gc:setColorRGB(0, 0, 0)

    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local u = min_u + (column + 0.5) * span_u / columns
            local v = max_v - (row + 0.5) * span_v / rows
            local inside = false
            for _, elem in ipairs(massiv_elemente) do
                if is_point_inside(elem, u, v) then
                    inside = not elem.is_hole
                end
            end
            if inside then
                local sr, sg, sb = color(stress(u, v))
                gc:setColorRGB(sr, sg, sb)
                gc:fillRect(section_left + column * cell_width, section_top + row * cell_height, cell_width + 1, cell_height + 1)
            end
        end
    end

    local slope_u = -((r.Mz_Nmm * r.Iy - r.My_Nmm * r.Iyz) / denominator)
    local slope_v = (r.My_Nmm * r.Iz - r.Mz_Nmm * r.Iyz) / denominator
    local neutral_offset = r.normal
    local neutral_length = math.sqrt(draw_width^2 + draw_height^2) / math.max(factor, 1e-9)
    local neutral_norm = math.sqrt(slope_u^2 + slope_v^2)
    if neutral_norm > 1e-12 then
        local dir_u, dir_v = -slope_v / neutral_norm, slope_u / neutral_norm
        local base_u = r.ys - slope_u * neutral_offset / (neutral_norm^2)
        local base_v = r.zs - slope_v * neutral_offset / (neutral_norm^2)
        local nu1, nv1 = base_u - dir_u * neutral_length, base_v - dir_v * neutral_length
        local nu2, nv2 = base_u + dir_u * neutral_length, base_v + dir_v * neutral_length
        local sx1, sy1 = screen(nu1, nv1)
        local sx2, sy2 = screen(nu2, nv2)
        gc:setColorRGB(25, 25, 25)
        gc:setPen("medium", "dashed")
        gc:drawLine(sx1, sy1, sx2, sy2)
        gc:setFont("sansserif", "r", 8)
        gc:drawString("neutrale Faser", section_left + 4, section_top + 2)

        local function draw_parallel(point_u, point_v, red, green, blue)
            local line_length = neutral_length * 0.28
            local px1, py1 = screen(point_u - dir_u * line_length, point_v - dir_v * line_length)
            local px2, py2 = screen(point_u + dir_u * line_length, point_v + dir_v * line_length)
            gc:setColorRGB(red, green, blue)
            gc:setPen("thin", "smooth")
            gc:drawLine(px1, py1, px2, py2)
        end
        draw_parallel(r.max_y, r.max_z, 190, 60, 60)
        draw_parallel(r.min_y, r.min_z, 55, 105, 190)
    end

    local cx, cy = screen(r.ys, r.zs)
    local axis_length = math.min(draw_width, draw_height) * 0.42
    local function draw_axis(angle, label)
        local dx, dy = math.cos(angle), math.sin(angle)
        local ax1, ay1 = screen(r.ys - dx * axis_length / factor, r.zs - dy * axis_length / factor)
        local ax2, ay2 = screen(r.ys + dx * axis_length / factor, r.zs + dy * axis_length / factor)
        gc:setColorRGB(110, 80, 160)
        gc:setPen("thin", "dashed")
        gc:drawLine(ax1, ay1, ax2, ay2)
        gc:setFont("sansserif", "r", 8)
        gc:drawString(label, ax2 + 3, ay2 - 8)
    end
    draw_axis(r.alpha, "eta")
    draw_axis(r.alpha + math.pi / 2, "zeta")
    gc:setColorRGB(110, 80, 160)
    gc:fillArc(cx - 3, cy - 3, 6, 6, 0, 360)

    gc:setColorRGB(0, 0, 0)
    gc:setPen("thin", "smooth")
    for _, elem in ipairs(duenn_elemente) do
        local x1, y1 = screen(elem.points[1].u, elem.points[1].v)
        local x2, y2 = screen(elem.points[2].u, elem.points[2].v)
        gc:drawLine(x1, y1, x2, y2)
    end
    gc:setFont("sansserif", "r", 8)
    gc:drawString(string.format("min %.3g", r.sigma_min), left + 8, top + height - 18)

    local graph_top = top + 30
    local graph_bottom = top + height - 24
    if graph_width > 70 then
        local plot_left, plot_right = graph_left + 22, left + width - 8
        local plot_top, plot_bottom = graph_top + 22, graph_bottom - 18
        local sigma_low = math.min(0, r.sigma_min)
        local sigma_high = math.max(0, r.sigma_max)
        local sigma_span = math.max(sigma_high - sigma_low, 1e-9)
        local function graph_y(value)
            return plot_bottom - (value - sigma_low) / sigma_span * (plot_bottom - plot_top)
        end
        gc:setColorRGB(0, 0, 0)
        gc:setPen("thin", "smooth")
        gc:drawRect(graph_left, graph_top, graph_width, graph_bottom - graph_top)
        gc:setFont("sansserif", "b", 9)
        gc:drawString("Spannungsverlauf", graph_left + 4, graph_top + 4)
        gc:setFont("sansserif", "r", 7)
        gc:drawString("σ [MPa]", graph_left + 3, plot_top - 8)
        local zero_y = graph_y(0)
        gc:setColorRGB(130, 130, 130)
        gc:drawLine(plot_left, zero_y, plot_right, zero_y)
        gc:setColorRGB(205, 125, 125)
        gc:drawLine(plot_left, graph_y(r.sigma_min), plot_right, graph_y(r.sigma_max))
        gc:setColorRGB(40, 90, 170)
        gc:setPen("medium", "smooth")
        gc:drawLine(plot_left, graph_y(r.sigma_min), plot_right, graph_y(r.sigma_max))
        gc:setColorRGB(0, 0, 0)
        gc:setFont("sansserif", "r", 7)
        gc:drawString(string.format("min %.3g", r.sigma_min), plot_left, plot_bottom + 4)
        gc:drawString(string.format("max %.3g", r.sigma_max), plot_left, plot_top + 2)
        if r.sigma_min <= 0 and r.sigma_max >= 0 then
            gc:setColorRGB(40, 40, 40)
            gc:setPen("thin", "dashed")
            local neutral_x = plot_left + (0 - r.sigma_min) / sigma_span * (plot_right - plot_left)
            gc:drawLine(neutral_x, plot_top, neutral_x, plot_bottom)
        end
    end
end

local function drawSigmaOverlay(gc, w, h)
    if not sigma_results then return end
    local r = sigma_results
    local denominator = r.Iy * r.Iz - r.Iyz^2
    if math.abs(denominator) < 1e-12 then return end

    local min_u, max_u, min_v, max_v = math.huge, -math.huge, math.huge, -math.huge
    for _, elem in ipairs(massiv_elemente) do
        local u1, u2, v1, v2 = getBoundingBox(elem)
        min_u, max_u = math.min(min_u, u1), math.max(max_u, u2)
        min_v, max_v = math.min(min_v, v1), math.max(max_v, v2)
    end
    for _, elem in ipairs(duenn_elemente) do
        local u1, u2, v1, v2 = getBoundingBox(elem)
        min_u, max_u = math.min(min_u, u1), math.max(max_u, u2)
        min_v, max_v = math.min(min_v, v1), math.max(max_v, v2)
    end
    if min_u == math.huge then return end

    local slope_u = -((r.Mz_Nmm * r.Iy - r.My_Nmm * r.Iyz) / denominator)
    local slope_v = (r.My_Nmm * r.Iz - r.Mz_Nmm * r.Iyz) / denominator
    local function stress(u, v)
        return r.normal + slope_u * (u - r.ys) + slope_v * (v - r.zs)
    end
    local stress_scale = math.max(math.abs(r.sigma_min), math.abs(r.sigma_max), 1e-9)
    local function stress_color(value)
        local ratio = math.min(1, math.abs(value) / stress_scale)
        if value < -1e-9 then
            return 255 - math.floor(45 * ratio), 225 - math.floor(70 * ratio), 225 - math.floor(65 * ratio)
        elseif value > 1e-9 then
            return 220 - math.floor(70 * ratio), 235 - math.floor(55 * ratio), 255
        end
        return 248, 248, 248
    end

    local span_u = math.max(max_u - min_u, 1e-9)
    local span_v = math.max(max_v - min_v, 1e-9)
    local columns = math.max(12, math.min(60, math.floor(span_u * scale / 8)))
    local rows = math.max(12, math.min(60, math.floor(span_v * scale / 8)))
    local du, dv = span_u / columns, span_v / rows

    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            local u = min_u + (column + 0.5) * du
            local v = min_v + (row + 0.5) * dv
            local section_state = 0
            for _, elem in ipairs(massiv_elemente) do
                if is_point_inside(elem, u, v) then
                    section_state = elem.is_hole and -1 or 1
                end
            end
            if section_state ~= 0 then
                local x1, y1 = toScreen(min_u + column * du, min_v + row * dv)
                local x2, y2 = toScreen(min_u + (column + 1) * du, min_v + (row + 1) * dv)
                local sr, sg, sb = 255, 255, 255
                if section_state > 0 then sr, sg, sb = stress_color(stress(u, v)) end
                gc:setColorRGB(sr, sg, sb)
                gc:fillRect(math.min(x1, x2), math.min(y1, y2), math.abs(x2 - x1) + 1, math.abs(y2 - y1) + 1)
            end
        end
    end

    gc:setColorRGB(40, 40, 40)
    gc:setPen("thin", "smooth")
    local function point(u, v) return toScreen(u, v) end
    local function line(u1, v1, u2, v2)
        local x1, y1 = point(u1, v1)
        local x2, y2 = point(u2, v2)
        gc:drawLine(x1, y1, x2, y2)
    end
    for _, elem in ipairs(massiv_elemente) do
        local p = elem.points
        if elem.type == "rect" then
            line(p[1].u, p[1].v, p[2].u, p[1].v)
            line(p[2].u, p[1].v, p[2].u, p[2].v)
            line(p[2].u, p[2].v, p[1].u, p[2].v)
            line(p[1].u, p[2].v, p[1].u, p[1].v)
        elseif elem.type == "circle" then
            local cx, cy = point(p[1].u, p[1].v)
            local rpx = math.sqrt((p[2].u - p[1].u)^2 + (p[2].v - p[1].v)^2) * scale
            gc:drawArc(cx - rpx, cy - rpx, 2 * rpx, 2 * rpx, 0, 360)
        elseif elem.type == "triangle" or elem.type == "trapezoid" then
            local q = {}
            for _, pt in ipairs(p) do
                local x, y = point(pt.u, pt.v)
                table.insert(q, x); table.insert(q, y)
            end
            table.insert(q, q[1]); table.insert(q, q[2])
            gc:drawPolyLine(q)
        end
    end
    for _, elem in ipairs(duenn_elemente) do
        line(elem.points[1].u, elem.points[1].v, elem.points[2].u, elem.points[2].v)
    end

    local neutral_norm = math.sqrt(slope_u^2 + slope_v^2)
    if neutral_norm <= 1e-12 then return end
    local dir_u, dir_v = -slope_v / neutral_norm, slope_u / neutral_norm
    local stress_dir_u, stress_dir_v = slope_u / neutral_norm, slope_v / neutral_norm
    local line_length = math.sqrt(span_u^2 + span_v^2) * 1.15
    local base_u = r.ys - slope_u * r.normal / (neutral_norm^2)
    local base_v = r.zs - slope_v * r.normal / (neutral_norm^2)

    local profile_offset = line_length
    local zero_profile_u = base_u + dir_u * profile_offset
    local zero_profile_v = base_v + dir_v * profile_offset

    local function cross2(au, av, bu, bv) return au * bv - av * bu end
    local function intersect_lines(pu, pv, du, dv, qu, qv, eu, ev)
        local denominator_lines = cross2(du, dv, eu, ev)
        if math.abs(denominator_lines) < 1e-12 then return pu, pv end
        local delta_u, delta_v = qu - pu, qv - pv
        local t = cross2(delta_u, delta_v, eu, ev) / denominator_lines
        return pu + t * du, pv + t * dv
    end

    local graph_slope = 0.45
    local graph_dir_u = stress_dir_u + graph_slope * dir_u
    local graph_dir_v = stress_dir_v + graph_slope * dir_v
    local min_graph_u, min_graph_v = intersect_lines(
        r.min_y, r.min_z, dir_u, dir_v,
        zero_profile_u, zero_profile_v, graph_dir_u, graph_dir_v)
    local max_graph_u, max_graph_v = intersect_lines(
        r.max_y, r.max_z, dir_u, dir_v,
        zero_profile_u, zero_profile_v, graph_dir_u, graph_dir_v)
    local min_axis_u, min_axis_v = intersect_lines(
        r.min_y, r.min_z, dir_u, dir_v,
        zero_profile_u, zero_profile_v, stress_dir_u, stress_dir_v)
    local max_axis_u, max_axis_v = intersect_lines(
        r.max_y, r.max_z, dir_u, dir_v,
        zero_profile_u, zero_profile_v, stress_dir_u, stress_dir_v)

    gc:setColorRGB(40, 40, 40)
    gc:setPen("thin", "dashed")
    line(base_u - dir_u * line_length, base_v - dir_v * line_length,
        zero_profile_u, zero_profile_v)

    -- Abszisse und Verlauf enden exakt an den beiden aeusseren Geraden.
    gc:setColorRGB(90, 90, 90)
    gc:setPen("thin", "smooth")
    line(min_axis_u, min_axis_v, max_axis_u, max_axis_v)
    gc:setPen("thin", "dashed")
    line(r.min_y, r.min_z, min_graph_u, min_graph_v)
    line(r.max_y, r.max_z, max_graph_u, max_graph_v)

    gc:setColorRGB(30, 30, 30)
    gc:setPen("medium", "smooth")
    line(min_graph_u, min_graph_v, max_graph_u, max_graph_v)

    local max_x, max_y = point(max_graph_u, max_graph_v)
    local min_x, min_y = point(min_graph_u, min_graph_v)
    local min_red, min_green, min_blue = 55, 105, 190
    if r.sigma_min < 0 then min_red, min_green, min_blue = 190, 70, 70 end
    gc:setColorRGB(min_red, min_green, min_blue)
    gc:fillArc(min_x - 2, min_y - 2, 4, 4, 0, 360)
    local max_red, max_green, max_blue = 55, 105, 190
    if r.sigma_max < 0 then max_red, max_green, max_blue = 190, 70, 70 end
    gc:setColorRGB(max_red, max_green, max_blue)
    gc:fillArc(max_x - 2, max_y - 2, 4, 4, 0, 360)
    gc:setFont("sansserif", "r", 8)
    gc:drawString(string.format("σmin %.3g", r.sigma_min), min_x + 4, min_y + 4)
    gc:drawString(string.format("σmax %.3g", r.sigma_max), max_x + 4, max_y - 10)
end

local function drawSigmaExtrema(gc)
    if not sigma_results then return end
    local extrema = {
        {y = sigma_results.max_y, z = sigma_results.max_z, color = {55, 105, 190}},
        {y = sigma_results.min_y, z = sigma_results.min_z, color = {210, 0, 0}}
    }
    for _, point in ipairs(extrema) do
        local sx, sy = toScreen(point.y, point.z)
        gc:setColorRGB(point.color[1], point.color[2], point.color[3])
        gc:fillArc(sx - 2, sy - 2, 4, 4, 0, 360)
    end
end

local function buildMenuItems()
    if menuPage == 1 then
        return {"1. Rechteck (2 Klicks)", "2. Kreis (2 Klicks)", "3. Dreieck (3 Klicks)", "4. Trapez/Polygon (n Klicks)", "5. Kreisausschnitt (3 Klicks)", "6. Kreisabschnitt (3 Klicks)", "7. Dicke Linie (2 Klicks)", "8. Kraft platzieren (1 Klick)", "9. Naechste Seite >"}
    elseif menuPage == 2 then
        return {"1. Linienzug (n Klicks)", "2. Kreis (2 Klicks)", "3. Kreisbogen (3 Klicks)", "4. Kraft platzieren (1 Klick)", "5. < Vorherige Seite"}
    elseif menuPage == 4 then
        local a, b = axes()
        local format_name = zahlenFormat == 1 and "Wurzel/Bruch" or zahlenFormat == 2 and "Bruch" or "Dezimal"
        return {"1. Raster aendern (Aktuell: "..string.format("%.4g %s", display_length(raster), length_unit)..")", "2. Standarddicke t (Aktuell: "..string.format("%.4g %s", display_length(default_t), length_unit)..")", "3. KOS Ebene ("..a..b..")", "4. KOS drehen", "5. KOS Groesse (Aktuell: "..kos_size..")", "6. Zahlenformat ("..format_name..")", "7. Kraft-Einheit ("..force_unit..")", "8. Laengen-Einheit ("..length_unit..")", "9. Moment-Einheit ("..moment_unit..")", "10. ξ Profilbeiwert (Aktuell: "..string.format("%.4g", torsion_xi)..")"}
    elseif menuPage == 9 then
        return {"1. KOS in Schwerpunkt verschieben", "2. < Zurueck"}
    elseif menuPage == 5 then
        return {"1. Querschnittswerte", "2. Einzelwerte-Tabelle", "3. σx-Berechnung", "4. Kernflaeche", "5. Schubspannung", "6. Schubmittelpunkt", "7. Schliessen"}
    elseif menuPage == 8 then
        return {"1. Äussere Belastungen hinzufügen", "2. Schliessen"}
    elseif menuPage == 6 then
        return {"1. Umhuellende Geraden", "2. Kernflaeche", "3. Ausblenden", "4. Zurueck"}
    elseif menuPage == 7 then
        if #kraefte > 0 then
            return {"1. σx aus Kraeften", "2. Normalspannung (N, My)", "3. Schiefe Spannung (N, My, Mz)", "4. Zurueck"}
        end
        return {"1. Normalspannung (N, My)", "2. Schiefe Spannung (N, My, Mz)", "3. Zurueck"}
    end

    local elem = selected_type == "massiv" and massiv_elemente[selected_idx] or selected_type == "duenn" and duenn_elemente[selected_idx] or kraefte[selected_idx]
    if not elem then return {} end
    local a_lbl, b_lbl = axes()
    local items = {}
    if selected_type == "kraft" then
        local c_lbl = (a_lbl == "x" and b_lbl == "y") and "z" or ((a_lbl == "y" and b_lbl == "z") and "x" or "y")
        local display_u, display_v = coordinatesForDisplay(elem.u, elem.v)
        local force_a, force_b = forceComponentsForDisplay(elem.fa, elem.fb)
        items = {"--- Bearbeite Kraft " .. selected_idx .. " ---", a_lbl .. " [" .. length_unit .. "]: " .. string.format("%.3f", display_length(display_u)), b_lbl .. " [" .. length_unit .. "]: " .. string.format("%.3f", display_length(display_v)), "F_" .. a_lbl .. " [" .. force_unit .. "]: " .. string.format("%.3f", display_force(force_a)), "F_" .. b_lbl .. " [" .. force_unit .. "]: " .. string.format("%.3f", display_force(force_b)), "F_" .. c_lbl .. " [" .. force_unit .. "]: " .. string.format("%.3f", display_force(elem.fc)), "Loeschen"}
        return items
    end
    items[1] = "--- Bearbeite " .. (selected_type == "massiv" and "M" or "D") .. selected_idx .. " ---"
    for i = 1, #elem.points do
        local display_u, display_v = coordinatesForDisplay(elem.points[i].u, elem.points[i].v)
        table.insert(items, "P" .. i .. " " .. a_lbl .. " [" .. length_unit .. "]: " .. string.format("%.3f", display_length(display_u)))
        table.insert(items, "P" .. i .. " " .. b_lbl .. " [" .. length_unit .. "]: " .. string.format("%.3f", display_length(display_v)))
    end
    if selected_type == "massiv" then
        table.insert(items, "Typ: " .. (elem.is_hole and "Loch" or "Positiv"))
        if elem.type == "massiv_linie" then table.insert(items, "Dicke t [" .. length_unit .. "]: " .. string.format("%.3f", display_length(elem.t))); elem.has_t = true end
    else
        table.insert(items, "Dicke t [" .. length_unit .. "]: " .. string.format("%.3f", display_length(elem.t)))
    end
    if elem.type == "sector" or elem.type == "segment" or elem.type == "duenn_kreis_bogen" then
        table.insert(items, "P2 und P3 tauschen"); elem.has_swap = true
    else
        elem.has_swap = false
    end
    table.insert(items, "Element Loeschen")
    table.insert(items, "Schliessen")
    return items
end

local function drawMenu(gc, w, h)
    if not menuOpen then return end
    local width, left = 220, w - 220
    gc:setColorRGB(248, 248, 248); gc:fillRect(left, 5, width, h - 10)
    gc:setColorRGB(0, 0, 0); gc:drawRect(left, 5, width, h - 10)
    gc:setFont("sansserif", "b", 9)
    local title = "Menue (" .. (menuPage == 1 and "Massiv" or menuPage == 2 and "Duennwand" or menuPage == 3 and "Editieren" or menuPage == 5 and "Berechnungen" or menuPage == 6 and "Kernflaeche" or menuPage == 7 and "σx" or menuPage == 8 and "Schubspannung" or menuPage == 9 and "Weitere Optionen" or "Optionen") .. ")"
    gc:drawString(title, left + 5, 10)
    gc:setFont("sansserif", "r", 9)
    for i, row in ipairs(buildMenuItems()) do
        gc:setColorRGB(i == menuRow and 200 or 0, 0, 0)
        local text = row
        if inputMode and i == menuRow then text = row:match("^(.-):") .. ": " .. inputText .. "_" end
        gc:drawString(text, left + 5, 15 + i * 16)
    end
end

local function drawOverlapPrompt(gc, w, h)
    if mode ~= "overlap_prompt" then return end
    local width, height = 270, 92
    local left, top = (w - width) / 2, (h - height) / 2
    gc:setColorRGB(255, 248, 220)
    gc:fillRect(left, top, width, height)
    gc:setColorRGB(180, 90, 0)
    gc:setPen("medium", "smooth")
    gc:drawRect(left, top, width, height)
    gc:setColorRGB(120, 50, 0)
    gc:setFont("sansserif", "b", 11)
    gc:drawString("Ueberlappung erkannt", left + 10, top + 8)
    gc:setFont("sansserif", "r", 9)
    gc:drawString("1: Abziehen   2: Addieren   3: Verwerfen", left + 10, top + 34)
    gc:drawString("Taste 1, 2 oder 3 druecken", left + 10, top + 57)
end

local function drawTable(gc, w, h)
    if not showTable then return end
    
    local a_lbl, b_lbl = axes()
    local rows = {
        "Flaecheninhalt A [" .. unit_label(2) .. "]",
        a_lbl .. " [" .. unit_label(1) .. "]",
        b_lbl .. " [" .. unit_label(1) .. "]",
        "I_eta (Lokal) [" .. unit_label(4) .. "]",
        "I_zeta (Lokal) [" .. unit_label(4) .. "]",
        "I_etazeta (Lokal) [" .. unit_label(4) .. "]",
        "I_" .. a_lbl .. " (Gedreht) [" .. unit_label(4) .. "]",
        "I_" .. b_lbl .. " (Gedreht) [" .. unit_label(4) .. "]",
        "I_" .. a_lbl .. b_lbl .. " (Gedreht) [" .. unit_label(4) .. "]",
        b_lbl .. "^2 * A (Steiner) [" .. unit_label(4) .. "]",
        a_lbl .. "^2 * A (Steiner) [" .. unit_label(4) .. "]",
        a_lbl .. "*" .. b_lbl .. "*A (Steiner) [" .. unit_label(4) .. "]",
        "I_" .. a_lbl .. " (Global) [" .. unit_label(4) .. "]",
        "I_" .. b_lbl .. " (Global) [" .. unit_label(4) .. "]",
        "I_" .. a_lbl .. b_lbl .. " (Global) [" .. unit_label(4) .. "]"
    }
    
    local all_elems = {}
    for _, e in ipairs(massiv_elemente) do table.insert(all_elems, e) end
    for _, e in ipairs(duenn_elemente) do table.insert(all_elems, e) end
    if #all_elems == 0 then return end
    
    local colW = 75
    local rowColW = 140
    local rowH = 20
    
    local totalW = rowColW + #all_elems * colW
    local totalH = (1 + #rows) * rowH
    
    local startX = 10 + table_scroll_x
    local startY = 30 + table_scroll_y
    
    gc:setColorRGB(240, 240, 240)
    gc:fillRect(0, 0, w, h)
    
    gc:setColorRGB(0, 0, 0)
    gc:setFont("sansserif", "b", 9)
    gc:drawString("Tabellarische uebersicht Einzelelemente", 10, 5)
    
    gc:clipRect("set", 10, 25, w - 20, h - 35)
    
    gc:setColorRGB(0, 0, 0)
    for i = 0, #rows + 1 do
        local y = startY + i * rowH
        gc:drawLine(startX, y, startX + totalW, y)
    end
    for j = 0, #all_elems + 1 do
        local x = startX + (j == 0 and 0 or rowColW + (j-1)*colW)
        gc:drawLine(x, startY, x, startY + totalH)
    end
    
    gc:setFont("sansserif", "r", 8)
    for i, label in ipairs(rows) do
        gc:drawString(label, startX + 5, startY + i * rowH + 2)
    end
    
    for i, elem in ipairs(all_elems) do
        local cx = startX + rowColW + (i-1)*colW
        local title = elem.display_name or ("E" .. i)
        local numeric_color = elem.is_numeric and {210, 0, 0} or {0, 0, 0}
        gc:setColorRGB(numeric_color[1], numeric_color[2], numeric_color[3])
        gc:setFont("sansserif", "b", 9)
        if elem.is_numeric then
            gc:setFont("sansserif", "b", 8)
            gc:drawString("numerisch", cx + 2, startY + 1)
            gc:setFont("sansserif", "b", 9)
            gc:drawString(title, cx + 5, startY + 11)
        else
            gc:drawString(title, cx + 5, startY + 2)
        end
        
        gc:setFont("sansserif", "r", 8)
        local A = elem.A or 0
        local y = elem.ys or 0
        local z = elem.zs or 0
        local Iy = elem.Iy or 0
        local Iz = elem.Iz or 0
        local Iyz = elem.Iyz or 0
        local centroid_y = system_results and system_results.ys or 0
        local centroid_z = system_results and system_results.zs or 0
        local delta_y, delta_z = y - centroid_y, z - centroid_z
        
        local vals = {
            display_area(A), display_length(y), display_length(z),
            display_inertia(elem.I_eta or 0), display_inertia(elem.I_zeta or 0), display_inertia(elem.I_etazeta or 0),
            display_inertia(Iy), display_inertia(Iz), display_inertia(Iyz),
            display_inertia(delta_z^2 * A), display_inertia(delta_y^2 * A), display_inertia(-delta_y * delta_z * A),
            display_inertia(Iy + delta_z^2 * A), display_inertia(Iz + delta_y^2 * A), display_inertia(Iyz - delta_y * delta_z * A)
        }
        
        for i, val in ipairs(vals) do
            local str = string.format("%.2f", val)
            gc:drawString(str, cx + 5, startY + i * rowH + 2)
        end
        gc:setColorRGB(0, 0, 0)
    end
    
    gc:clipRect("reset")
end

local function drawShearMomentTable(gc, w, h)
    if not shear_moment_table then return end
    gc:setColorRGB(255, 255, 255)
    gc:fillRect(0, 0, w, h)
    gc:setColorRGB(0, 0, 0)
    gc:setFont("sansserif", "b", 10)
    gc:drawString("Schubmittelpunkt: Resultierende Schubkraefte", 8, 8)
    gc:setFont("sansserif", "r", 9)
    local axis_a, axis_b = axes()
    gc:drawString("Einheitslast " .. axis_a .. " / " .. axis_b .. ", F [" .. force_unit .. "]", 8, 28)
    gc:drawString("Element", 12, 44)
    gc:drawString("X-Last", 70, 44)
    gc:drawString("Y-Last", 155, 44)
    local y = 62
    for _, row in ipairs(shear_moment_table.rows) do
        gc:drawString(row.name, 12, y)
        gc:drawString(formatLabel(row.first / unit_factor(force_unit)), 70, y)
        gc:drawString(formatLabel(row.second / unit_factor(force_unit)), 155, y)
        y = y + 18
    end
    gc:setFont("sansserif", "b", 9)
    gc:drawString("M_ges", 12, y + 4)
    gc:drawString(formatLabel(shear_moment_table.total_first / unit_factor(moment_unit)) .. " " .. moment_unit, 70, y + 4)
    gc:drawString(formatLabel(shear_moment_table.total_second / unit_factor(moment_unit)) .. " " .. moment_unit, 155, y + 4)
end

-- === KERNFLAECHE (K-Modus) ===
local function kern_dual(nu, nv, d)
    -- Dualitaet: neutrale Faser nu*(y-ys) + nv*(z-zs) = d  ->  Kernpunkt (globale Koordinaten)
    local r = system_results
    local A = r.A
    local Iyzp = -r.Iyz -- Integral (y-ys)*(z-zs) dA (Vorzeichenkonvention beachten)
    local al = -nu / (d * A)
    local be = -nv / (d * A)
    local ky = al * r.Iz + be * Iyzp
    local kz = al * Iyzp + be * r.Iy
    return r.ys + ky, r.zs + kz
end

kern_collect_points = function()
    local pts = {}
    local function add(u, v, src, is_arc)
        table.insert(pts, {u = u, v = v, src = src, arc = is_arc})
    end
    local function arc_samples(C, R, a1, a2, src, full)
        local sweep = a2 - a1
        if sweep <= 0 then sweep = sweep + 2 * math.pi end
        local steps = math.max(4, math.ceil(math.deg(sweep) / 10))
        for i = 0, steps do
            local ang = a1 + sweep * (i / steps)
            local is_end = (i == 0 or i == steps)
            add(C.u + R * math.cos(ang), C.v + R * math.sin(ang), src, full or not is_end)
        end
    end
    for _, elem in ipairs(massiv_elemente) do
        if not elem.is_hole then
            local p = elem.points
            if elem.type == "rect" then
                add(p[1].u, p[1].v); add(p[2].u, p[1].v)
                add(p[2].u, p[2].v); add(p[1].u, p[2].v)
            elseif elem.type == "circle" then
                local R = math.sqrt((p[2].u - p[1].u)^2 + (p[2].v - p[1].v)^2)
                arc_samples(p[1], R, 0, 2 * math.pi, elem, true)
            elseif elem.type == "triangle" or elem.type == "trapezoid" then
                for _, pt in ipairs(p) do add(pt.u, pt.v) end
            elseif elem.type == "massiv_linie" then
                local du, dv = p[2].u - p[1].u, p[2].v - p[1].v
                local L = math.sqrt(du^2 + dv^2)
                local nx, ny = 0, 0
                if L > 1e-9 then nx, ny = (-dv / L) * (elem.t / 2), (du / L) * (elem.t / 2) end
                add(p[1].u + nx, p[1].v + ny); add(p[2].u + nx, p[2].v + ny)
                add(p[2].u - nx, p[2].v - ny); add(p[1].u - nx, p[1].v - ny)
            elseif elem.type == "sector" or elem.type == "segment" then
                local C = p[1]
                local R = math.sqrt((p[2].u - C.u)^2 + (p[2].v - C.v)^2)
                local a1 = math.atan2(p[2].v - C.v, p[2].u - C.u)
                local a2 = math.atan2(p[3].v - C.v, p[3].u - C.u)
                if elem.type == "sector" then add(C.u, C.v) end
                arc_samples(C, R, a1, a2, elem, false)
            end
        end
    end
    for _, elem in ipairs(duenn_elemente) do
        local p = elem.points
        if elem.type == "duenn_kreis" then
            local R = math.sqrt((p[2].u - p[1].u)^2 + (p[2].v - p[1].v)^2)
            arc_samples(p[1], R, 0, 2 * math.pi, elem, true)
        elseif elem.type == "duenn_kreis_bogen" then
            local C = p[1]
            local R = math.sqrt((p[2].u - C.u)^2 + (p[2].v - C.v)^2)
            local a1 = math.atan2(p[2].v - C.v, p[2].u - C.u)
            local a2 = math.atan2(p[3].v - C.v, p[3].u - C.u)
            arc_samples(C, R, a1, a2, elem, false)
        else
            add(p[1].u, p[1].v)
            add(p[2].u, p[2].v)
        end
    end
    return pts
end

local function berechneSigmaExtrema(N, My_Nmm, Mz_Nmm)
    local r = system_results
    if not r then return nil end
    local points = kern_collect_points()
    local denominator = r.Iy * r.Iz - r.Iyz^2
    if math.abs(r.A) < 1e-9 or math.abs(denominator) < 1e-12 or #points == 0 then
        return nil
    end

    local My = My_Nmm
    local Mz = Mz_Nmm
    local normal = N / r.A
    local max_sigma, min_sigma = -math.huge, math.huge
    local max_point, min_point

    for _, point in ipairs(points) do
        local sigma = normal
            + ((My * r.Iz - Mz * r.Iyz) / denominator) * (point.v - r.zs)
            - ((Mz * r.Iy - My * r.Iyz) / denominator) * (point.u - r.ys)
        if sigma > max_sigma then
            max_sigma = sigma
            max_point = point
        end
        if sigma < min_sigma then
            min_sigma = sigma
            min_point = point
        end
    end

    return {
        N = N,
        My_Nm = My,
        My_Nmm = My,
        Mz_Nm = Mz,
        Mz_Nmm = Mz,
        A = r.A,
        ys = r.ys,
        zs = r.zs,
        Iy = r.Iy,
        Iz = r.Iz,
        Iyz = r.Iyz,
        alpha = r.alpha,
        normal = normal,
        sigma_max = max_sigma,
        max_y = max_point.u,
        max_z = max_point.v,
        sigma_min = min_sigma,
        min_y = min_point.u,
        min_z = min_point.v
    }
end

local function berechneKraftResultanten()
    if not system_results then return 0, 0, 0 end
    local force_N, moment_a, moment_b = 0, 0, 0
    local orientation = ({1, 1, -1})[plane]
    if swapped then orientation = -orientation end
    for _, kraft in ipairs(kraefte) do
        local normal_force = tonumber(kraft.fc) or 0
        local du = kraft.u - system_results.ys
        local dv = kraft.v - system_results.zs
        force_N = force_N + normal_force
        moment_a = moment_a + orientation * dv * normal_force
        moment_b = moment_b - orientation * du * normal_force
    end
    return force_N, moment_a, moment_b
end

local function finishSigmaCalculation(Mz_Nmm)
    local r = system_results
    local denominator = r.Iy * r.Iz - r.Iyz^2
    if math.abs(denominator) < 1e-12 then
        return false
    end
    local force_N, force_Ma, force_Mb = berechneKraftResultanten()
    local total_N = (sigma_N or 0) + force_N
    local total_Ma_Nmm = (sigma_My or 0) + force_Ma
    local total_Mb_Nmm = (Mz_Nmm or 0) + force_Mb
    sigma_results = berechneSigmaExtrema(total_N, total_Ma_Nmm, total_Mb_Nmm)
    if sigma_results then
        sigma_results.force_N = force_N
        sigma_results.force_Ma_Nm = force_Ma
        sigma_results.force_Mb_Nm = force_Mb
    end
    return sigma_results ~= nil
end

local function openSigmaFromForces()
    sigma_N, sigma_My, sigma_Mz = 0, 0, 0
    sigma_oblique = true
    sigma_input_step, inputText = 0, ""
    sigma_results, sigma_scroll_y, sigma_table_scroll_y = nil, 0, 0
    local success = finishSigmaCalculation(0)
    showResults, showTable, menuOpen = success, false, false
    status = success and "σx aus den eingetragenen Kraeften berechnet." or "σx nicht berechenbar."
    platform.window:invalidate()
end

kern_build = function()
    kern_lines, kern_pts, kern_vertices = {}, {}, {}
    kern_hover_line, kern_hover_pt = nil, nil
    local r = system_results
    if not r then return end
    local pts = kern_collect_points()
    if #pts < 3 then return end

    -- Konvexe Huelle (Monotone Chain), Ergebnis gegen den Uhrzeigersinn
    table.sort(pts, function(a, b)
        if math.abs(a.u - b.u) > 1e-12 then return a.u < b.u end
        return a.v < b.v
    end)
    local function cross(o, a, b) return (a.u - o.u) * (b.v - o.v) - (a.v - o.v) * (b.u - o.u) end
    local lower, upper = {}, {}
    for _, p in ipairs(pts) do
        while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], p) <= 1e-9 do table.remove(lower) end
        table.insert(lower, p)
    end
    for i = #pts, 1, -1 do
        local p = pts[i]
        while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], p) <= 1e-9 do table.remove(upper) end
        table.insert(upper, p)
    end
    table.remove(lower); table.remove(upper)
    local hull = {}
    for _, p in ipairs(lower) do table.insert(hull, p) end
    for _, p in ipairs(upper) do table.insert(hull, p) end
    local n = #hull
    if n < 3 then return end

    local function arc_edge(H, N, i)
        local p1, p2 = H[i], H[(i % N) + 1]
        return p1.arc and p2.arc and p1.src ~= nil and p1.src == p2.src
    end

    -- Sonderfall: Huelle besteht nur aus einem Vollkreis
    local all_arc = true
    for i = 1, n do
        if not arc_edge(hull, n, i) then all_arc = false break end
    end
    if all_arc then
        local C = hull[1].src.points[1]
        local P0 = hull[1].src.points[2]
        local R = math.sqrt((P0.u - C.u)^2 + (P0.v - C.v)^2)
        for k = 0, 35 do
            local ang = 2 * math.pi * k / 36
            local cu, cv = math.cos(ang), math.sin(ang)
            local d = cu * (C.u + R * cu - r.ys) + cv * (C.v + R * cv - r.zs)
            if d > 1e-9 then
                local ku, kv = kern_dual(cu, cv, d)
                table.insert(kern_pts, {u = ku, v = kv})
            end
        end
        return
    end

    -- Huelle rotieren, so dass die erste Kante keine Bogenkante ist
    local start = 1
    for i = 1, n do
        if not arc_edge(hull, n, i) then start = i break end
    end
    local H = {}
    for i = 0, n - 1 do table.insert(H, hull[((start + i - 1) % n) + 1]) end
    hull = H

    -- Segmente bilden: gerade Kanten einzeln, Bogenläufe als ein Segment
    local segs = {}
    local i = 1
    while i <= n do
        if arc_edge(hull, n, i) then
            local j = i
            while j < n and arc_edge(hull, n, j + 1) do j = j + 1 end
            table.insert(segs, {type = "arc", src = hull[i].src, p1 = hull[i], p2 = hull[(j % n) + 1]})
            i = j + 1
        else
            table.insert(segs, {type = "line", p1 = hull[i], p2 = hull[(i % n) + 1]})
            i = i + 1
        end
    end

    -- Kollineare gerade Kanten verschmelzen (minimale Geradenanzahl)
    local changed = true
    while changed and #segs > 1 do
        changed = false
        for k = 1, #segs do
            local s1, s2 = segs[k], segs[(k % #segs) + 1]
            if s1.type == "line" and s2.type == "line" then
                local d1u, d1v = s1.p2.u - s1.p1.u, s1.p2.v - s1.p1.v
                local d2u, d2v = s2.p2.u - s2.p1.u, s2.p2.v - s2.p1.v
                local cr = math.abs(d1u * d2v - d1v * d2u)
                if cr <= 1e-9 * math.sqrt((d1u^2 + d1v^2) * (d2u^2 + d2v^2)) then
                    s1.p2 = s2.p2
                    table.remove(segs, (k % #segs) + 1)
                    changed = true
                    break
                end
            end
        end
    end

    local function add_line(nu, nv, d)
        if d < 0 then nu, nv, d = -nu, -nv, -d end
        if d <= 1e-9 then return end
        table.insert(kern_lines, {nu = nu, nv = nv, d = d})
        local ku, kv = kern_dual(nu, nv, d)
        table.insert(kern_pts, {u = ku, v = kv})
        table.insert(kern_vertices, {u = ku, v = kv})
    end

    for _, sg in ipairs(segs) do
        if sg.type == "line" then
            local du, dv = sg.p2.u - sg.p1.u, sg.p2.v - sg.p1.v
            local L = math.sqrt(du^2 + dv^2)
            if L > 1e-9 then
                -- Huelle ist CCW, also ist (dv, -du) die Aussennormale
                local nu, nv = dv / L, -du / L
                add_line(nu, nv, nu * (sg.p1.u - r.ys) + nv * (sg.p1.v - r.zs))
            end
        else
            local C = sg.src.points[1]
            local P0 = sg.src.points[2]
            local R = math.sqrt((P0.u - C.u)^2 + (P0.v - C.v)^2)
            -- Tangente am Bogenanfang
            local nu = (sg.p1.u - C.u) / R
            local nv = (sg.p1.v - C.v) / R
            add_line(nu, nv, nu * (sg.p1.u - r.ys) + nv * (sg.p1.v - r.zs))
            -- Kernkurve entlang des Bogens (Stuetzpunkte)
            local a1 = math.atan2(sg.p1.v - C.v, sg.p1.u - C.u)
            local a2 = math.atan2(sg.p2.v - C.v, sg.p2.u - C.u)
            if a2 <= a1 then a2 = a2 + 2 * math.pi end
            local steps = math.max(2, math.ceil(math.deg(a2 - a1) / 5))
            for k = 1, steps - 1 do
                local ang = a1 + (a2 - a1) * (k / steps)
                local cu, cv = math.cos(ang), math.sin(ang)
                local d = cu * (C.u + R * cu - r.ys) + cv * (C.v + R * cv - r.zs)
                if d > 1e-9 then
                    local ku, kv = kern_dual(cu, cv, d)
                    table.insert(kern_pts, {u = ku, v = kv})
                end
            end
            -- Tangente am Bogenende
            nu = (sg.p2.u - C.u) / R
            nv = (sg.p2.v - C.v) / R
            add_line(nu, nv, nu * (sg.p2.u - r.ys) + nv * (sg.p2.v - r.zs))
        end
    end
end

local function drawInfArrow(gc, u0, v0, du, dv, label)
    local x1, y1 = toScreen(u0, v0)
    local x2, y2 = toScreen(u0 + du, v0 + dv)
    local dx, dy = x2 - x1, y2 - y1
    local m = math.sqrt(dx^2 + dy^2)
    if m < 1e-5 then return end
    dx, dy = dx / m * 30, dy / m * 30
    gc:drawLine(x1, y1, x1 + dx, y1 + dy)
    local px, py = -dy, dx
    gc:drawLine(x1 + dx, y1 + dy, x1 + dx * 0.8 + px * 0.15, y1 + dy * 0.8 + py * 0.15)
    gc:drawLine(x1 + dx, y1 + dy, x1 + dx * 0.8 - px * 0.15, y1 + dy * 0.8 - py * 0.15)
    gc:drawString(label, x1 + dx + 4, y1 + dy - 8)
end

local function drawKern(gc, w, h)
    local r = system_results
    if not r then return end
    local a_lbl, b_lbl = axes()
    if kernMode == 1 then
        local L = (w + h) / scale
        for i, ln in ipairs(kern_lines) do
            local bu, bv = r.ys + ln.nu * ln.d, r.zs + ln.nv * ln.d
            local du, dv = -ln.nv, ln.nu
            local x1, y1 = toScreen(bu - du * L, bv - dv * L)
            local x2, y2 = toScreen(bu + du * L, bv + dv * L)
            if kern_hover_line == i then
                gc:setColorRGB(0, 90, 220)
                gc:setPen("medium", "smooth")
            else
                gc:setColorRGB(140, 185, 240)
                gc:setPen("thin", "smooth")
            end
            gc:drawLine(x1, y1, x2, y2)
            local lx, ly = toScreen(bu, bv)
            gc:setFont("sansserif", "r", 8)
            gc:drawString("g" .. i, lx + 4, ly - 10)
        end
        local i = kern_hover_line
        if i then
            local ln = kern_lines[i]
            local bu, bv = r.ys + ln.nu * ln.d, r.zs + ln.nv * ln.d
            gc:setColorRGB(220, 40, 40)
            gc:setFont("sansserif", "r", 9)
            if math.abs(ln.nu) > 1e-9 then
                local iu = r.ys + ln.d / ln.nu
                local sx, sy = toScreen(iu, r.zs)
                gc:fillArc(sx - 3, sy - 3, 6, 6, 0, 360)
                local display_u, display_v = coordinatesForDisplay(iu, r.zs)
                gc:drawString(a_lbl .. "=" .. formatLabel(display_length(display_u)), sx + 6, sy - 12)
            else
                drawInfArrow(gc, bu, bv, 1, 0, "inf")
            end
            if math.abs(ln.nv) > 1e-9 then
                local iv = r.zs + ln.d / ln.nv
                local sx, sy = toScreen(r.ys, iv)
                gc:fillArc(sx - 3, sy - 3, 6, 6, 0, 360)
                local display_u, display_v = coordinatesForDisplay(r.ys, iv)
                gc:drawString(b_lbl .. "=" .. formatLabel(display_length(display_v)), sx + 6, sy - 12)
            else
                drawInfArrow(gc, bu, bv, 0, 1, "inf")
            end
        end
    elseif kernMode == 2 then
        if #kern_pts >= 2 then
            local q = {}
            for _, p in ipairs(kern_pts) do
                local sx, sy = toScreen(p.u, p.v)
                table.insert(q, sx)
                table.insert(q, sy)
            end
            gc:setColorRGB(250, 205, 205)
            gc:fillPolygon(q)
            table.insert(q, q[1])
            table.insert(q, q[2])
            gc:setColorRGB(200, 40, 40)
            gc:setPen("medium", "smooth")
            gc:drawPolyLine(q)
            for k, p in ipairs(kern_vertices) do
                local sx, sy = toScreen(p.u, p.v)
                if kern_hover_pt == k then
                    gc:setColorRGB(255, 0, 0)
                    gc:fillArc(sx - 4, sy - 4, 8, 8, 0, 360)
                    gc:setFont("sansserif", "b", 9)
                    local display_u, display_v = coordinatesForDisplay(p.u, p.v)
                    gc:drawString(a_lbl .. "=" .. formatLabel(display_length(display_u)) .. ", " .. b_lbl .. "=" .. formatLabel(display_length(display_v)), sx + 8, sy - 14)
                else
                    gc:setColorRGB(150, 30, 30)
                    gc:fillArc(sx - 3, sy - 3, 6, 6, 0, 360)
                end
            end
        end
    end
end

function on.paint(gc)
    local w, h = platform.window:width(), platform.window:height()
    
    if showTable then
        if sigma_results then
            gc:setColorRGB(255, 255, 255)
            gc:fillRect(0, 0, w, h)
            drawSigmaResultsTable(gc, w, h)
            drawSigmaDistribution(gc, w, h)
        elseif show_shear_moment_table then
            drawShearMomentTable(gc, w, h)
        else
            drawTable(gc, w, h)
        end
        return
    end
    if sigma_input_step > 0 then
        gc:setColorRGB(255, 255, 255)
        gc:fillRect(0, 0, w, h)
        drawSigmaInput(gc, w, h)
        return
    end
    if shear_input_step > 0 then
        gc:setColorRGB(255, 255, 255)
        gc:fillRect(0, 0, w, h)
        drawShearInput(gc, w, h)
        return
    end
    if torsion_input_step > 0 then
        gc:setColorRGB(255, 255, 255); gc:fillRect(0, 0, w, h)
        drawTorsionInput(gc, w, h)
        return
    end
    gc:setColorRGB(255, 255, 255)
    gc:fillRect(0, 0, w, h)
    
    drawGrid(gc, w, h)
    
    -- Draw Massiv
    for i, elem in ipairs(massiv_elemente) do
        local is_sel = (selected_type == "massiv" and selected_idx == i)
        local is_hov = (hover_type == "massiv" and hover_idx == i)
        
        if elem.is_hole then
            gc:setColorRGB(255, 255, 255)
            gc:setPen((is_sel or is_hov) and "medium" or "thin", "dashed")
            drawShapePath(gc, elem)
        else
            if is_hov and not is_sel then
                gc:setColorRGB(150, 190, 250)
            else
                gc:setColorRGB(180, 210, 250)
            end
            gc:setPen((is_sel or is_hov) and "medium" or "thin", "smooth")
            drawShapePath(gc, elem)
        end
        
        if is_sel or is_hov then
            if not shear_results then drawLocalAxes(gc, elem) end
            gc:setColorRGB(255, 0, 0)
            if not shear_results then for pi, pt in ipairs(elem.points) do
                local sx, sy = toScreen(pt.u, pt.v)
                gc:fillArc(sx-3, sy-3, 6, 6, 0, 360)
                gc:setFont("sansserif", "r", 8)
                gc:drawString("P"..pi, sx + 5, sy - 5)
            end end
        end
        
        if elem.ys and elem.zs and not shear_profile_visible then
            local sx, sy = toScreen(elem.ys, elem.zs)
            gc:setColorRGB(0,0,0)
            gc:setFont("sansserif", "b", 8)
            gc:drawString("M"..i, sx, sy - 10)
        end
    end
    
    -- Draw Duennwand
    gc:setColorRGB(50, 50, 50)
    for i, elem in ipairs(duenn_elemente) do
        local is_sel = (selected_type == "duenn" and selected_idx == i)
        local is_hov = (hover_type == "duenn" and hover_idx == i)
        if shear_profile_visible then
            gc:setPen("thin", "dashed")
        else
            gc:setPen((is_sel or is_hov) and "thick" or "medium", "smooth")
        end
        if is_hov and not is_sel then gc:setColorRGB(100, 100, 100) else gc:setColorRGB(50, 50, 50) end
        
        if elem.type == "duenn_kreis" then
            local C = elem.points[1]
            local R = math.sqrt((elem.points[2].u - C.u)^2 + (elem.points[2].v - C.v)^2)
            local a, b = toScreen(C.u - R, C.v - R)
            local c, d = toScreen(C.u + R, C.v + R)
            local l, t_box = math.min(a, c), math.min(b, d)
            local w_box, h_box = math.abs(c - a), math.abs(d - b)
            gc:drawArc(l, t_box, w_box, h_box, 0, 360)
        elseif elem.type == "duenn_kreis_bogen" then
            local C = elem.points[1]
            local R = math.sqrt((elem.points[2].u - C.u)^2 + (elem.points[2].v - C.v)^2)
            local a1 = math.atan2(elem.points[2].v - C.v, elem.points[2].u - C.u)
            local a2 = math.atan2(elem.points[3].v - C.v, elem.points[3].u - C.u)
            local diff = a2 - a1
            if diff <= 0 then diff = diff + 2*math.pi end
            local a, b = toScreen(C.u - R, C.v - R)
            local c, d = toScreen(C.u + R, C.v + R)
            local l, t_box = math.min(a, c), math.min(b, d)
            local w_box, h_box = math.abs(c - a), math.abs(d - b)
            
            -- We just draw the approximated polygon but without filling it, just lines
            local steps = math.max(10, math.floor(math.deg(diff) / 5))
            local q = {}
            for i=0, steps do
                local ang = a1 + (i/steps)*diff
                local sx, sy = toScreen(C.u + R*math.cos(ang), C.v + R*math.sin(ang))
                table.insert(q, sx)
                table.insert(q, sy)
            end
            gc:drawPolyLine(q)
        else
            local sx1, sy1 = toScreen(elem.points[1].u, elem.points[1].v)
            local sx2, sy2 = toScreen(elem.points[2].u, elem.points[2].v)
            gc:drawLine(sx1, sy1, sx2, sy2)
        end
        
        if is_sel or is_hov then
            if not shear_results then drawLocalAxes(gc, elem) end
            gc:setColorRGB(255, 0, 0)
            if not shear_results then for pi, pt in ipairs(elem.points) do
                local sx, sy = toScreen(pt.u, pt.v)
                gc:fillArc(sx-3, sy-3, 6, 6, 0, 360)
                gc:setFont("sansserif", "r", 8)
                gc:drawString("P"..pi, sx + 5, sy - 5)
            end end
        end
        
        if elem.ys and elem.zs and not shear_profile_visible then
            local sx, sy = toScreen(elem.ys, elem.zs)
            gc:setColorRGB(0,0,0)
            gc:setFont("sansserif", "b", 8)
            gc:drawString("D"..i, sx, sy - 10)
        end
    end

    drawShearProfile(gc)
    drawShearSelector(gc, w, h)

    if show_shear_center and system_results and #duenn_elemente > 0 then
        local center = berechneSchubmittelpunkt()
        if center then
            local center_x, center_y = toScreen(center.u, center.v)
            gc:setColorRGB(220, 40, 40)
            gc:fillArc(center_x - 4, center_y - 4, 8, 8, 0, 360)
            gc:setFont("sansserif", "b", 9)
            local display_u, display_v = coordinatesForDisplay(center.u, center.v)
            gc:drawString("Schubmittelpunkt (" .. formatLabel(display_length(display_u)) .. ", " .. formatLabel(display_length(display_v)) .. ") [" .. length_unit .. "]", center_x + 6, center_y - 10)
        end
    end

    if sigma_results then drawSigmaOverlay(gc, w, h) end
    
    -- Draw Kraefte nur in der normalen Querschnittsansicht.
    if not shear_profile_visible then for i, kraft in ipairs(kraefte) do
        local is_sel = (selected_type == "kraft" and selected_idx == i)
        local is_hov = (hover_type == "kraft" and hover_idx == i)
        gc:setColorRGB(is_sel and 255 or (is_hov and 150 or 0), 0, is_sel and 0 or (is_hov and 250 or 255)) 
        local sx, sy = toScreen(kraft.u, kraft.v)
        
        if math.abs(kraft.fc) > 1e-9 then
            local r = 6
            gc:drawArc(sx - r, sy - r, 2*r, 2*r, 0, 360)
            if kraft.fc < 0 then
                -- into plane (Kreuz)
                local d = r * 0.707
                gc:drawLine(sx - d, sy - d, sx + d, sy + d)
                gc:drawLine(sx - d, sy + d, sx + d, sy - d)
            else
                -- out of plane (Punkt)
                gc:fillArc(sx - 2, sy - 2, 4, 4, 0, 360)
            end
        end
        if math.abs(kraft.fa) > 1e-9 or math.abs(kraft.fb) > 1e-9 then
            local mag = math.sqrt(kraft.fa^2 + kraft.fb^2)
            local dx = (kraft.fa / mag) * 20
            local dy = -(kraft.fb / mag) * 20
            -- Draw line from tail to tip (sx, sy)
            gc:drawLine(sx - dx, sy - dy, sx, sy)
            local head_size = 6
            local angle = math.atan2(dy, dx)
            -- Draw arrowhead at (sx, sy)
            gc:drawLine(sx, sy, sx - head_size * math.cos(angle - 0.4), sy - head_size * math.sin(angle - 0.4))
            gc:drawLine(sx, sy, sx - head_size * math.cos(angle + 0.4), sy - head_size * math.sin(angle + 0.4))
        end
        -- Always draw a small point at the application point so it's clickable and visible
        gc:fillArc(sx - 2, sy - 2, 4, 4, 0, 360)
        if is_sel or is_hov then
            gc:setFont("sansserif", "r", 8)
            gc:drawString("K" .. i, sx + 5, sy - 15)
        end
    end end
    
    -- Draw Pending
    gc:setColorRGB(255, 100, 0)
    for i, p in ipairs(pending) do
        local sx, sy = toScreen(p.u, p.v)
        gc:fillArc(sx-3, sy-3, 6, 6, 0, 360)
        if i > 1 and string.sub(mode, 1, 5) == "duenn" then
            local sx_prev, sy_prev = toScreen(pending[i-1].u, pending[i-1].v)
            gc:drawLine(sx_prev, sy_prev, sx, sy)
        end
    end
    
    if kernMode > 0 then drawKern(gc, w, h) end
    if not shear_results then
        drawAxes(gc)
        drawSigmaExtrema(gc)
    end
    if not sigma_results then drawSpreadsheet(gc, w, h) end
    drawOverlapPrompt(gc, w, h)
    drawMenu(gc, w, h)
    
    if #massiv_elemente == 0 and #duenn_elemente == 0 and mode == "idle" and not menuOpen then
        gc:setColorRGB(0, 0, 0)
        gc:setFont("sansserif", "r", 9)
        gc:drawString("M o. D fuer Querschnitt", 5, h - 15)
    end
end

function on.mouseMove(x, y)
    if menuOpen or mode ~= "idle" then return end
    local u, v = fromScreen(x, y)

    if shear_profile_visible and shear_results and shear_results.samples then
        local nearest, nearest_distance = nil, 10 / math.max(scale, 1e-9)
        for index, sample in ipairs(shear_results.samples) do
            local distance = math.sqrt((u - sample.u)^2 + (v - sample.v)^2)
            if distance < nearest_distance then nearest, nearest_distance = index, distance end
        end
        if nearest ~= shear_hover_index then
            shear_hover_index = nearest
            platform.window:invalidate()
        end
    end
    
    if kernMode > 0 and system_results then
        local r = system_results
        local thresh = 12 / scale
        if kernMode == 1 then
            local best, bd = nil, thresh
            for i, ln in ipairs(kern_lines) do
                local dist = math.abs(ln.nu * (u - r.ys) + ln.nv * (v - r.zs) - ln.d)
                if dist < bd then bd, best = dist, i end
            end
            if best ~= kern_hover_line then
                kern_hover_line = best
                platform.window:invalidate()
            end
        else
            local best, bd = nil, thresh
            for i, p in ipairs(kern_vertices) do
                local dist = math.sqrt((u - p.u)^2 + (v - p.v)^2)
                if dist < bd then bd, best = dist, i end
            end
            if best ~= kern_hover_pt then
                kern_hover_pt = best
                platform.window:invalidate()
            end
        end
        return
    end
    
    local found_type, found_idx = nil, nil
    local force_hover_radius = 14 / math.max(scale, 1e-9)
    local element_hover_radius = 10 / math.max(scale, 1e-9)
    local min_dist = element_hover_radius
    
    -- Check kraefte
    for i, kraft in ipairs(kraefte) do
        local dist = math.sqrt((u - kraft.u)^2 + (v - kraft.v)^2)
        if dist < force_hover_radius and (found_type ~= "kraft" or dist < min_dist) then
            min_dist = dist
            found_type = "kraft"
            found_idx = i
        end
    end
    
    -- Elemente werden nur geprueft, wenn kein Kraftpunkt getroffen wurde.
    if not found_type then
        -- Check duenn
        for i, elem in ipairs(duenn_elemente) do
            local dist = point_to_line_dist(u, v, elem.points[1].u, elem.points[1].v, elem.points[2].u, elem.points[2].v)
            if dist < min_dist then
                min_dist = dist
                found_type = "duenn"
                found_idx = i
            end
        end
        
        -- Check massiv
        -- von hinten nach vorne, um die obersten (zuletzt gezeichneten) zu treffen
        for i = #massiv_elemente, 1, -1 do
            if is_point_inside(massiv_elemente[i], u, v) then
                found_type = "massiv"
                found_idx = i
                break
            end
        end
    end
    
    if found_type ~= hover_type or found_idx ~= hover_idx then
        hover_type, hover_idx = found_type, found_idx
        platform.window:invalidate()
    end
end

function on.mouseUp(x, y)
    if menuOpen then return end
    local u, v = fromScreen(x, y)
    u, v = snap(u), snap(v)
    
    if mode == "idle" then
        if hover_type then
            selected_type = hover_type
            selected_idx = hover_idx
            status = "Element ausgewaehlt. Druecke Enter zum Bearbeiten."
        else
            selected_type, selected_idx = nil, nil
            status = "Menue oeffnen mit 'M' oder 'D'."
        end
        platform.window:invalidate()
        return
    end
    
    table.insert(pending, {u=u, v=v})
    
    if mode == "rect" and #pending == 2 then finish_shape("rect")
    elseif mode == "massiv_linie" and #pending == 2 then finish_shape("massiv_linie")
    elseif mode == "circle" and #pending == 2 then finish_shape("circle")
    elseif mode == "triangle" and #pending == 3 then finish_shape("triangle")
    elseif mode == "trapezoid" and #pending == 4 then finish_shape("trapezoid")
    elseif mode == "sector" and #pending == 3 then finish_shape("sector")
    elseif mode == "segment" and #pending == 3 then finish_shape("segment")
    elseif mode == "duenn_kreis" and #pending == 2 then finish_shape("duenn_kreis")
    elseif mode == "duenn_kreis_bogen" and #pending == 3 then finish_shape("duenn_kreis_bogen")
    elseif mode == "force" and #pending == 1 then finish_shape("force")
    elseif mode == "duenn_linie" then
        status = "Linienzug: Weiter klicken. Enter zum Abschliessen."
    end
    
    platform.window:invalidate()
end

local function zoomCenter(factor)
    local w, h = platform.window:width(), platform.window:height()
    local old_scale = scale
    local new_scale = math.max(1e-4, scale * factor)
    local real_f = new_scale / old_scale
    ox = w/2 - (w/2 - ox) * real_f
    oy = h/2 - (h/2 - oy) * real_f
    scale = new_scale
end

function on.charIn(c)
    if c == "-" or c == "?" or c == string.char(226, 136, 146) or c == string.char(226, 129, 187) or c == string.char(173) or c == string.char(226, 128, 147) or c == "-" or c == "-" then c = "-" end
    c = string.lower(c)
    if sigma_input_step > 0 then
        if c:match("[%w%.,%-%+%*/%(%)]") then inputText = inputText .. c end
        platform.window:invalidate()
        return
    end
    if shear_input_step > 0 or torsion_input_step > 0 then
        if c:match("[%w%.,%-%+%*/%(%)]") then inputText = inputText .. c end
        platform.window:invalidate()
        return
    end
    if inputMode then
        if c:match("[%w%.,%-%+%*/%(%)]") then inputText = inputText .. c end
        platform.window:invalidate()
        return
    end
    
    if mode == "overlap_prompt" then
        if c == "1" then
            overlap_pending_elem.is_hole = true
            overlap_pending_elem.is_numeric = true
            table.insert(massiv_elemente, overlap_pending_elem)
            overlap_pending_elem = nil
            pending = {}
            mode = "idle"
            status = "Element als Loch abgezogen."
            berechneSystem()
        elseif c == "2" then
            overlap_pending_elem.is_numeric = true
            table.insert(massiv_elemente, overlap_pending_elem)
            overlap_pending_elem = nil
            pending = {}
            mode = "idle"
            status = "Numerisch addiert."
            berechneSystem()
        elseif c == "3" then
            overlap_pending_elem = nil
            pending = {}
            mode = "idle"
            status = "Zeichnen verworfen."
        end
        platform.window:invalidate()
        return
    end

    if menuOpen and menuPage ~= 3 then
        local menu_number = tonumber(c)
        local menu_count = menuPage == 1 and 9 or menuPage == 2 and 5 or menuPage == 5 and 7 or menuPage == 6 and 4 or menuPage == 7 and (#kraefte > 0 and 4 or 3) or menuPage == 8 and 2 or menuPage == 9 and 2 or menuPage == 4 and 10 or 6
        if menu_number and menu_number >= 1 and menu_number <= menu_count then
            menuRow = menu_number
            on.enterKey()
            return
        end
    end
    
    if c == "m" then
        menuOpen = true; showResults = false; showTable = false; menuPage = 1; menuRow = 1
    elseif c == "d" then menuOpen = true; showResults = false; showTable = false; menuPage = 2; menuRow = 1
    elseif c == "b" then toggleCalculationMenu()
    elseif c == "e" then
        showResults = not showResults
        if showResults then results_scroll_y = 0 end
        menuOpen = false
        showTable = false
    elseif c == "t" then
        if show_shear_center and system_results and #duenn_elemente > 0 then
            if show_shear_moment_table then
                show_shear_moment_table, showTable = false, false
            else
                shear_moment_table = berechneSchubMomentTabelle()
                show_shear_moment_table = shear_moment_table ~= nil
                showTable = show_shear_moment_table
            end
        else
            showTable = not showTable
        end
        menuOpen = false
        showResults = sigma_results ~= nil and not showTable
    elseif c == "v" then
        if shear_results then
            shear_selector_open = true
            status = "Schubverlauf waehlen: 0 bis 9. Esc schliesst."
        else
            status = "V ist nur im Schubspannungsmodus verfuegbar."
        end
    elseif shear_selector_open and (c == "0" or c == "1" or c == "2" or c == "3" or c == "4" or c == "5" or c == "6" or c == "7" or c == "8" or c == "9") then
        local choice = c == "0" and 10 or tonumber(c)
        shear_selector_open = false
        shear_profile_visible, shear_view_mode = true, choice
        shear_hover_index = nil
        status = "Schubverlauf " .. (c == "0" and "10" or c) .. " angezeigt."
    elseif c == "+" then zoomCenter(1.25)
    elseif c == "-" then zoomCenter(1/1.25)
    elseif c == "c" then on.clearKey()
    elseif c == "h" then autoZoom()
    elseif c == "k" then
        if not system_results then
            status = "Kein Querschnitt vorhanden."
        else
            kernMode = (kernMode + 1) % 3
            hover_type, hover_idx = nil, nil
            if kernMode > 0 then
                if kern_build then kern_build() end
                status = kernMode == 1 and "Kern 1/2: Umhüllende Geraden (K: weiter)" or "Kern 2/2: Kernfläche (K: weiter)"
            else
                status = "Kern-Modus beendet."
            end
        end
    elseif c == "o" then
        menuOpen = true
        showResults = false
        menuPage = 4
        menuRow = 1
        inputMode = false
    end
    platform.window:invalidate()
end

function on.arrowKey(k)
    if showTable then
        if k == "left" then table_scroll_x = table_scroll_x + 20
        elseif k == "right" then table_scroll_x = table_scroll_x - 20
        elseif k == "up" then table_scroll_y = table_scroll_y + 20
        elseif k == "down" then table_scroll_y = table_scroll_y - 20
        end
        platform.window:invalidate()
        return
    end
    if showResults and not sigma_results then
        local max_scroll = math.max(0, 20 + (15 + 4) * 16 - platform.window:height())
        if k == "up" then results_scroll_y = math.max(0, results_scroll_y - 20)
        elseif k == "down" then results_scroll_y = math.min(max_scroll, results_scroll_y + 20)
        end
        platform.window:invalidate()
        return
    end
    if menuOpen and not inputMode then
        if menuPage == 4 or menuPage == 9 then
            if k == "left" or k == "right" then
                menuPage = menuPage == 4 and 9 or 4
                menuRow = 1
                platform.window:invalidate()
                return
            end
        end
        local n = 1
        if menuPage == 1 then n = 9
        elseif menuPage == 2 then n = 5
        elseif menuPage == 5 then n = 7
        elseif menuPage == 6 then n = 4
        elseif menuPage == 7 then n = #kraefte > 0 and 4 or 3
        elseif menuPage == 8 then n = 2
        elseif menuPage == 9 then n = 2
        elseif menuPage == 4 then n = 10
        elseif menuPage == 3 then
            local elem = (selected_type == "massiv") and massiv_elemente[selected_idx] or (selected_type == "duenn" and duenn_elemente[selected_idx] or kraefte[selected_idx])
            if selected_type == "kraft" then
                n = 7
            else
                n = elem and (#elem.points * 2 + (elem.has_swap and 5 or (elem.has_t and 5 or 4))) or 1
            end
        end
        if k == "up" then menuRow = math.max(1, menuRow - 1)
        elseif k == "down" then menuRow = math.min(n, menuRow + 1)
        end
        platform.window:invalidate()
        return
    end
    if k == "left" then ox = ox + 8
        elseif k == "right" then ox = ox - 8
        elseif k == "up" then oy = oy + 8
        elseif k == "down" then oy = oy - 8
        end
    platform.window:invalidate()
end

local function enterSigmaInput()
    local val = evaluate_input(inputText)
    if not val then
        status = "Ungueltige σx-Eingabe."
        inputText = ""
        platform.window:invalidate()
        return true
    end
    if sigma_input_step == 1 then
        sigma_N, sigma_input_step, inputText = input_to_internal(val, force_unit), 2, ""
        local moment_a = axes()
        status = "M" .. moment_a .. " in Nm eingeben, dann Enter."
    elseif sigma_input_step == 2 then
        sigma_My, inputText = input_to_internal(val, moment_unit), ""
        if sigma_oblique then
            sigma_input_step = 3
            local _, moment_b = axes()
            status = "M" .. moment_b .. " in Nm eingeben, dann Enter."
        else
            sigma_input_step = 0
            status = finishSigmaCalculation(0) and "Normale σx-Minimum und -Maximum berechnet." or "σx nicht berechenbar: Nenner ist 0."
        end
    else
        sigma_Mz, sigma_input_step, inputText = input_to_internal(val, moment_unit), 0, ""
        status = finishSigmaCalculation(sigma_Mz) and "Schiefe σx-Minimum und -Maximum berechnet." or "σx nicht berechenbar: Nenner ist 0."
    end
    platform.window:invalidate()
    return true
end

local function enterMenuInput()
    local val = evaluate_input(inputText)
    if val then
        if menuPage == 4 and menuRow == 1 then
            local old_raster = raster
            raster = math.max(1e-5, input_to_internal(val, length_unit))
            scale = scale * old_raster / raster
            status = "Raster gesetzt auf " .. raster
        elseif menuPage == 4 and menuRow == 2 then
            default_t = math.max(0.01, input_to_internal(val, length_unit))
            status = "Dicke t gesetzt auf " .. default_t
        elseif menuPage == 4 and menuRow == 5 then
            kos_size = math.max(1e-5, val)
            kos_pixel_length = kos_size
            status = "KOS Groesse gesetzt auf " .. kos_size
        elseif menuPage == 4 and menuRow == 10 then
            torsion_xi = math.max(0, val)
            berechneSystem()
            status = "ξ gesetzt auf " .. torsion_xi
        elseif menuPage == 3 then
            local elem = selected_type == "massiv" and massiv_elemente[selected_idx] or selected_type == "duenn" and duenn_elemente[selected_idx] or kraefte[selected_idx]
            if selected_type == "kraft" then
                local display_u, display_v = coordinatesForDisplay(elem.u, elem.v)
                local force_a, force_b = forceComponentsForDisplay(elem.fa, elem.fb)
                if menuRow == 2 then display_u = input_to_internal(val, length_unit)
                elseif menuRow == 3 then display_v = input_to_internal(val, length_unit)
                elseif menuRow == 4 then force_a = input_to_internal(val, force_unit)
                elseif menuRow == 5 then force_b = input_to_internal(val, force_unit)
                elseif menuRow == 6 then elem.fc = input_to_internal(val, force_unit) end
                if menuRow == 2 or menuRow == 3 then elem.u, elem.v = coordinatesFromDisplay(display_u, display_v) end
                if menuRow == 4 or menuRow == 5 then elem.fa, elem.fb = forceComponentsFromDisplay(force_a, force_b) end
            elseif selected_type == "massiv" and elem.has_t and menuRow == #elem.points * 2 + 3 then
                elem.t = math.max(0.01, input_to_internal(val, length_unit))
            elseif selected_type == "duenn" and menuRow == #elem.points * 2 + 2 then
                elem.t = math.max(0.01, input_to_internal(val, length_unit))
            else
                local row_idx = menuRow - 1
                local pt_idx = math.floor((row_idx + 1) / 2)
                if row_idx % 2 == 0 then
                    setDisplayedPointCoordinate(elem.points[pt_idx], "v", input_to_internal(val, length_unit))
                else
                    setDisplayedPointCoordinate(elem.points[pt_idx], "u", input_to_internal(val, length_unit))
                end
            end
            berechneSystem()
        end
    else
        status = "Ungueltige Eingabe."
    end
    inputMode, inputText = false, ""
    platform.window:invalidate()
    return true
end

local function enterMenuAction()
    if menuPage == 5 then
        if menuRow == 1 then showResults, showTable, menuOpen = true, false, false
        elseif menuRow == 2 then showTable, showResults, menuOpen = true, false, false
        elseif menuRow == 3 then openSigmaInput(true)
        elseif menuRow == 4 then menuPage, menuRow = 6, 1
        elseif menuRow == 5 then openShearFromForces()
        elseif menuRow == 6 then
            show_shear_center = not show_shear_center
            menuOpen = false
            status = show_shear_center and "Schubmittelpunkt angezeigt. T: Momententabelle." or "Schubmittelpunkt ausgeblendet."
        elseif menuRow == 7 then menuOpen = false end
    elseif menuPage == 8 then
        if menuRow == 1 then
            shear_external_input = true
            menuOpen = false
            openShearInput()
        elseif menuRow == 2 then menuOpen = false end
    elseif menuPage == 6 then
        if menuRow == 1 or menuRow == 2 then kernMode = menuRow; kern_build(); menuOpen = false
        elseif menuRow == 3 then kernMode, menuOpen = 0, false
        elseif menuRow == 4 then menuPage, menuRow = 5, 4 end
    elseif menuPage == 7 then
        if #kraefte > 0 then
            if menuRow == 1 then openSigmaFromForces()
            elseif menuRow == 2 then openSigmaInput(false)
            elseif menuRow == 3 then openSigmaInput(true)
            else menuPage, menuRow = 5, 3 end
        elseif menuRow == 1 then openSigmaInput(false) elseif menuRow == 2 then openSigmaInput(true)
        else menuPage, menuRow = 5, 3 end
    elseif menuPage == 1 then
        local modes = {"rect", "circle", "triangle", "trapezoid", "sector", "segment", "massiv_linie", "force"}
        if modes[menuRow] then mode, pending, menuOpen = modes[menuRow], {}, false
        elseif menuRow == 9 then menuPage, menuRow = 2, 1 end
    elseif menuPage == 2 then
        local modes = {"duenn_linie", "duenn_kreis", "duenn_kreis_bogen", "force"}
        if modes[menuRow] then mode, pending, menuOpen = modes[menuRow], {}, false
        elseif menuRow == 5 then menuPage, menuRow = 1, 1 end
    elseif menuPage == 4 then
        if menuRow == 1 or menuRow == 2 or menuRow == 5 then inputMode, inputText = true, ""
        elseif menuRow == 3 then plane, swapped = plane % 3 + 1, false
        elseif menuRow == 4 then rotation = (rotation + 90) % 360
        elseif menuRow == 6 then zahlenFormat = (zahlenFormat % 3) + 1
        elseif menuRow == 7 then force_unit = cycle_unit(force_unit, {"N", "kN"})
        elseif menuRow == 8 then length_unit = cycle_unit(length_unit, {"m", "dm", "cm", "mm"})
        elseif menuRow == 9 then moment_unit = cycle_unit(moment_unit, {"Nm", "Ncm", "Nmm", "kNm", "kNcm", "kNmm"})
        elseif menuRow == 10 then inputMode, inputText = true, ""
        end
    elseif menuPage == 9 then
        if menuRow == 1 then
            verschiebeKOSZumSchwerpunkt()
            menuOpen = false
        elseif menuRow == 2 then menuPage, menuRow = 4, 1 end
    elseif menuPage == 3 then
        local elem = selected_type == "massiv" and massiv_elemente[selected_idx] or selected_type == "duenn" and duenn_elemente[selected_idx] or kraefte[selected_idx]
        if not elem then
            menuOpen, selected_type, selected_idx = false, nil, nil
            platform.window:invalidate()
            return
        end
        if selected_type == "kraft" then
            if menuRow >= 2 and menuRow <= 6 then inputMode, inputText = true, ""
            elseif menuRow == 7 then table.remove(kraefte, selected_idx); selected_type, selected_idx, menuOpen = nil, nil, false end
        elseif menuRow > 1 and menuRow <= #elem.points * 2 + 1 then inputMode, inputText = true, ""
        elseif selected_type == "massiv" and menuRow == #elem.points * 2 + 2 then elem.is_hole = not elem.is_hole; berechneSystem()
        elseif selected_type == "duenn" and menuRow == #elem.points * 2 + 2 then inputMode, inputText = true, ""
        elseif menuRow == #elem.points * 2 + (elem.has_swap and 3 or (elem.has_t and 3 or 2)) then
            if elem.has_swap then elem.points[2], elem.points[3] = elem.points[3], elem.points[2] else inputMode, inputText = true, "" end
        elseif menuRow >= #elem.points * 2 + 3 then
            if selected_type == "massiv" then table.remove(massiv_elemente, selected_idx) else table.remove(duenn_elemente, selected_idx) end
            selected_type, selected_idx, menuOpen = nil, nil, false
            berechneSystem()
        end
    end
    platform.window:invalidate()
end

function on.enterKey()
    if mode == "duenn_linie" and not menuOpen then finish_thin_line(); return end
    if sigma_input_step > 0 then enterSigmaInput(); return end
    if shear_input_step > 0 then enterShearInput(); return end
    if torsion_input_step > 0 then enterTorsionInput(); platform.window:invalidate(); return end
    if not menuOpen and mode == "idle" and selected_idx then
        menuOpen, menuPage, menuRow, showResults = true, 3, 1, false
        platform.window:invalidate()
        return
    end
    if not menuOpen then return end
    if inputMode then enterMenuInput() else enterMenuAction() end
end

function on.menuKey()
    toggleCalculationMenu()
    platform.window:invalidate()
end

function on.contextMenu()
    toggleCalculationMenu()
    platform.window:invalidate()
end

function on.escapeKey()
    if menuOpen or inputMode or shear_selector_open then
        menuOpen = false
        inputMode, inputText = false, ""
        shear_selector_open = false
        status = "Untermenue geschlossen. Modus bleibt aktiv."
        platform.window:invalidate()
        return
    end
    escape_clear_pending = true
    inputMode, inputText = false, ""
    sigma_input_step, sigma_N, sigma_My, sigma_Mz = 0, nil, nil, nil
    shear_input_step, shear_Qa, shear_Qb, shear_results = 0, nil, nil, nil
    shear_external_input = false
    show_shear_center, show_shear_moment_table, shear_moment_table = false, false, nil
    torsion_input_step, torsion_M, torsion_results = 0, nil, nil
    shear_profile_visible, shear_hover_index, shear_view_mode, shear_selector_open = false, nil, 0, false
    sigma_results = nil
    sigma_oblique = false
    sigma_scroll_y = 0
    kernMode = 0
    menuOpen = false
    showResults = false
    showTable = false
    overlap_pending_elem = nil
    pending = {}
    mode = "idle"
    status = "Abbruch. Modus ist idle."
    platform.window:invalidate()
end

function on.backspaceKey()
    if escape_clear_pending then
        escape_clear_pending = false
        on.clearKey()
        return
    end
    if shear_input_step > 0 or torsion_input_step > 0 then
        inputText = inputText:sub(1, -2)
    elseif inputMode then
        inputText = inputText:sub(1, -2)
    elseif #pending > 0 then
        table.remove(pending)
        status = "Letzten Punkt zurueckgenommen."
    else
        -- Loesche das letzte Element, je nachdem was gezeichnet wurde
        if #duenn_elemente > 0 then
            table.remove(duenn_elemente)
            berechneSystem()
            status = "Letztes duennwandiges Segment geloescht."
        elseif #massiv_elemente > 0 then
            table.remove(massiv_elemente)
            berechneSystem()
            status = "Letztes Massiv-Element geloescht."
        end
    end
    platform.window:invalidate()
end

function on.deleteKey()
    on.backspaceKey()
end

-- Initialize
berechneSystem()
    