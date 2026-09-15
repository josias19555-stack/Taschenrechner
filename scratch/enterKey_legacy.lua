-- Auskommentierte alte Enter-Verarbeitung aus Querschnitt.lua.
-- Diese Datei dient nur als Sicherung und wird nicht automatisch geladen.

function on.enterKey()
    if mode == "duenn_linie" and not menuOpen then
        finish_thin_line()
        return
    end

    if sigma_input_step > 0 then
        local val = evaluate_input(inputText)
        if not val then
            status = "Ungueltige σx-Eingabe."
            inputText = ""
            platform.window:invalidate()
            return
        end
        if sigma_input_step == 1 then
            sigma_N = val
            sigma_input_step = 2
            inputText = ""
            status = "My in Nm eingeben, dann Enter."
        elseif sigma_input_step == 2 then
            sigma_My = val
            inputText = ""
            if sigma_oblique then
                sigma_input_step = 3
                status = "Mz in Nm eingeben, dann Enter."
            else
                sigma_input_step = 0
                if finishSigmaCalculation(0) then
                    status = "Normale σx-Minimum und -Maximum berechnet."
                else
                    status = "σx nicht berechenbar: Nenner ist 0."
                end
            end
        else
            sigma_Mz = val
            sigma_input_step = 0
            inputText = ""
            if finishSigmaCalculation(sigma_Mz) then
                status = "Schiefe σx-Minimum und -Maximum berechnet."
            else
                status = "σx nicht berechenbar: Nenner ist 0."
            end
        end
        platform.window:invalidate()
        return
    end

    if not menuOpen and mode == "idle" and selected_idx then
        menuOpen = true
        menuPage = 3
        menuRow = 1
        showResults = false
        platform.window:invalidate()
        return
    end
    if not menuOpen then return end

    if inputMode then
        local val = evaluate_input(inputText)
        if val then
            if menuPage == 4 and menuRow == 1 then
                local old_raster = raster
                raster = math.max(1e-5, val)
                scale = scale * (old_raster / raster)
                status = "Raster gesetzt auf " .. raster
            elseif menuPage == 4 and menuRow == 2 then
                default_t = math.max(0.01, val)
                status = "Dicke t gesetzt auf " .. default_t
            elseif menuPage == 4 and menuRow == 5 then
                kos_size = math.max(1e-5, val)
                kos_pixel_length = kos_size
                status = "KOS Groesse gesetzt auf " .. kos_size
            elseif menuPage == 3 then
                local elem = (selected_type == "massiv") and massiv_elemente[selected_idx] or (selected_type == "duenn" and duenn_elemente[selected_idx] or kraefte[selected_idx])
                if selected_type == "kraft" then
                    if menuRow == 2 then elem.u = val
                    elseif menuRow == 3 then elem.v = val
                    elseif menuRow == 4 then elem.fa = val
                    elseif menuRow == 5 then elem.fb = val
                    elseif menuRow == 6 then elem.fc = val
                    end
                elseif selected_type == "duenn" and menuRow == (#elem.points * 2 + 2) then
                    elem.t = math.max(0.01, val)
                elseif selected_type == "massiv" and elem.has_t and menuRow == (#elem.points * 2 + 3) then
                    elem.t = math.max(0.01, val)
                else
                    local row_idx = menuRow - 1
                    local pt_idx = math.floor((row_idx + 1) / 2)
                    local is_y = (row_idx % 2 == 0)
                    if is_y then elem.points[pt_idx].v = val else elem.points[pt_idx].u = val end
                end
                berechneSystem()
            end
        else
            status = "Ungueltige Eingabe."
        end
        inputMode, inputText = false, ""
        platform.window:invalidate()
        return
    end

    if menuPage == 5 then
        if menuRow == 1 then
            showResults, showTable, menuOpen = true, false, false
        elseif menuRow == 2 then
            showTable, showResults, menuOpen = true, false, false
        elseif menuRow == 3 then
            menuPage, menuRow = 7, 1
        elseif menuRow == 4 then
            menuPage, menuRow = 6, 1
        elseif menuRow == 5 then
            showResults, showTable, menuOpen = true, false, false
        elseif menuRow == 6 then
            menuOpen = false
        end
    elseif menuPage == 6 then
        if menuRow == 1 or menuRow == 2 then
            kernMode = menuRow
            if kern_build then kern_build() end
            menuOpen = false
        elseif menuRow == 3 then
            kernMode, menuOpen = 0, false
        elseif menuRow == 4 then
            menuPage, menuRow = 5, 4
        end
    elseif menuPage == 7 then
        if menuRow == 1 then openSigmaInput(false)
        elseif menuRow == 2 then openSigmaInput(true)
        else menuPage, menuRow = 5, 3 end
    elseif menuPage == 1 then
        local modes = {"rect", "circle", "triangle", "trapezoid", "sector", "segment", "massiv_linie"}
        if modes[menuRow] then
            mode, pending, menuOpen = modes[menuRow], {}, false
        elseif menuRow == 8 then
            menuPage, menuRow = 2, 1
        end
    elseif menuPage == 2 then
        local modes = {"duenn_linie", "duenn_kreis", "duenn_kreis_bogen"}
        if modes[menuRow] then
            mode, pending, menuOpen = modes[menuRow], {}, false
        elseif menuRow == 5 then
            menuPage, menuRow = 1, 1
        end
    elseif menuPage == 4 then
        if menuRow == 1 or menuRow == 2 or menuRow == 5 then
            inputMode, inputText = true, ""
        elseif menuRow == 3 then
            plane, swapped = plane % 3 + 1, false
        elseif menuRow == 4 then
            rotation = (rotation + 90) % 360
        elseif menuRow == 6 then
            menuOpen = false
        end
    elseif menuPage == 3 then
        local elem = (selected_type == "massiv") and massiv_elemente[selected_idx] or (selected_type == "duenn" and duenn_elemente[selected_idx] or kraefte[selected_idx])
        if selected_type == "kraft" then
            if menuRow > 1 and menuRow <= 6 then
                inputMode, inputText = true, ""
            elseif menuRow == 7 then
                table.remove(kraefte, selected_idx)
                menuOpen = false
                selected_type, selected_idx = nil, nil
            end
        elseif menuRow > 1 and menuRow <= (#elem.points * 2 + 1) then
            inputMode, inputText = true, ""
        elseif selected_type == "massiv" and menuRow == (#elem.points * 2 + 2) then
            elem.is_hole = not elem.is_hole
            berechneSystem()
        elseif selected_type == "duenn" and menuRow == (#elem.points * 2 + 2) then
            inputMode, inputText = true, ""
        elseif selected_type == "massiv" and elem.has_t and menuRow == (#elem.points * 2 + 3) then
            inputMode, inputText = true, ""
        elseif elem.has_swap and menuRow == (#elem.points * 2 + 3) then
            elem.points[2], elem.points[3] = elem.points[3], elem.points[2]
            berechneSystem()
        elseif menuRow == (#elem.points * 2 + (elem.has_swap and 4 or (elem.has_t and 4 or 3))) then
            if selected_type == "massiv" then table.remove(massiv_elemente, selected_idx)
            else table.remove(duenn_elemente, selected_idx) end
            selected_idx, selected_type, menuOpen = nil, nil, false
            berechneSystem()
        elseif menuRow == (#elem.points * 2 + (elem.has_swap and 5 or (elem.has_t and 5 or 4))) then
            menuOpen = false
        end
    end
    platform.window:invalidate()
end
