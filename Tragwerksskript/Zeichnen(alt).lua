
function on.paint(gc)

    if ansichtsModus == "L" then
        gc:setFont("sansserif", "r", 7)
        gc:setColorRGB(0, 0, 0)
        gc:drawString("Globales Gleichungssystem (LGS):", 10, 10)
        local y_pos = 30 + (lgs_scroll_y or 0)
        local x_pos = 10 + (lgs_scroll_x or 0)
        local w_h = platform.window:height() - 20
        for i, eq in ipairs(lgs_equations or {}) do
            -- Only draw if visible on screen
            if y_pos > 10 and y_pos < platform.window:height() + 10 then
                gc:drawString(eq, x_pos, y_pos)
            end
            y_pos = y_pos + 12
        end
        return
    end
    
    local function fm(str, keep_sign)
        if type(str) ~= "string" then return "0" end
        str = str:match("^%s*(.-)%s*$")
        
        -- Replace special minus signs with standard minus for processing
        str = str:gsub(string.char(226, 136, 146), "-")
        str = str:gsub("−", "-")
        
        if not keep_sign then
            -- Robustly strip leading minus or leading "(-" to get the absolute value for display
            str = str:gsub("^%s*%-", "")
            str = str:gsub("^%s*%(%s*%-", "(")
        end
        
        return str:gsub("%*", "·"):gsub("%^2", "²"):gsub("%^3", "³")
    end
    local isKinematic = (ansichtsModus == "V")
    local orig_ansichtsModus = ansichtsModus
    -- Für Kinematik und den Prinzip-der-virtuellen-Verschiebungen-Modus (PvV)
    -- greifen wir primär auf die System-Darstellung (als Basis) zurück.
    if isKinematic or in_pvv_release then ansichtsModus = "System" end
    local isPolplan = (orig_ansichtsModus == "P")

    local b, h = platform.window:width(), platform.window:height()
    local drawPxProMeter = pxProMeter

    local stepPx = drawPxProMeter * rasterMass
    local startX = offsetX % stepPx
    local startY = offsetY % stepPx


    gc:setColorRGB(0, 0, 0)
    gc:setFont("sansserif", "b", 12)
    gc:setColorRGB(180, 180, 180)
    for rx = startX, b, stepPx do
        for ry = startY, h, stepPx do gc:fillRect(rx, ry, 1, 1) end
    end
    gc:setColorRGB(200, 200, 255); gc:drawLine(offsetX, 0, offsetX, h); gc:drawLine(0, offsetY, b, offsetY)

    local modusText = isPolplan and "Polplan" or (isKinematic and "Verschiebungszustand" or (ansichtsModus or "System"))
    if (pvvModus or in_pvv_release) and isKinematic then modusText = "PvV" end
    -- Rot wenn Stäbe vorhanden aber noch nicht berechnet
    local needsCalc = (#staebe > 0) and not systemBerechnet
    gc:setFont("sansserif", "b", 12)
    if needsCalc then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 100, 200) end
    gc:drawString("Modus: " .. modusText, 5, 5)
    
    if pvvModus then
        gc:setFont("sansserif", "r", 10); gc:drawString("Wähle Knoten zum Lösen (ESC abbrechen)", 5, 25)
    elseif in_pvv_release then
        gc:setFont("sansserif", "r", 10); gc:setColorRGB(200, 0, 0); gc:drawString("Verschiebungs-Ansicht. [ESC] zum Beenden", 5, 25)
    end

    if autoKGV and KGV_Zustand >= 0 then gc:setColorRGB(200, 0, 200); gc:drawString("Auto-KGV: " .. ((KGV_Zustand == 0) and "Nullsystem" or ("X" .. KGV_Zustand .. " = 1")), 5, 25) end
    -- n=... Anzeige: symb. jetzt als zweite Zeile darunter
    do
        local n_val = getTopologicalN()
        local n_text = "n = " .. n_val
        if zeigeN and kgv_n ~= nil then n_text = n_text .. " (" .. kgv_n .. ")" end
        gc:setFont("sansserif", "b", 12); gc:setColorRGB(0, 100, 200)
        local n_w = gc:getStringWidth(n_text)
        local n_x = b - n_w - 10
        gc:drawString(n_text, n_x, 5)
        
        -- "symb." als zweite Zeile unter n=...
        if symbolischer_modus then
            gc:setFont("sansserif", "r", 9); gc:setColorRGB(0, 100, 200)
            local s_str = "symb."
            gc:drawString(s_str, b - gc:getStringWidth(s_str) - 10, 20)
        end
        
        -- Hover-Tooltip: r+z-3*p Formel (nur bei Hover berechnen)
        local mx = mouseX or -1
        local my = mouseY or -1
        if mx >= n_x - 5 and mx <= b - 5 and my >= 0 and my <= 18 then
            -- r, z, p nur bei Hover ermitteln
            local r_val = 0
            for _, k in ipairs(knoten) do
                if k.lager_x then r_val=r_val+1 end
                if k.lager_y then r_val=r_val+1 end
                if k.lager_m then r_val=r_val+1 end
            end
            local p_val = (glob_num_disks and glob_num_disks > 0) and glob_num_disks or nil
            local z_val = p_val and (n_val + 3*p_val - r_val) or nil
            gc:setFont("sansserif", "r", 9); gc:setColorRGB(60, 60, 60)
            local tip1, tip2
            if p_val and z_val then
                tip1 = string.format("r=%d  z=%d  p=%d", r_val, z_val, p_val)
                tip2 = string.format("n=r+z-3p: %d+%d-%d=%d", r_val, z_val, 3*p_val, n_val)
            else
                tip1 = string.format("r=%d  (B berechnen!)", r_val)
                tip2 = string.format("n=%d", n_val)
            end
            local tw = math.max(gc:getStringWidth(tip1), gc:getStringWidth(tip2))
            gc:drawString(tip1, b - tw - 5, 22)
            gc:drawString(tip2, b - tw - 5, 34)
        end
    end

    local palette = { {220, 20, 60}, {0, 100, 220}, {34, 139, 34}, {255, 140, 0}, {128, 0, 128}, {0, 206, 209}, {139, 69, 19}, {255, 20, 147} }

    local function drawExplosionArrow(gc, x1, y1, x2, y2)
        gc:drawLine(x1, y1, x2, y2)
        local dx, dy = x2 - x1, y2 - y1
        local L = math.sqrt(dx*dx + dy*dy)
        if L > 0 then
            local ux, uy = dx/L, dy/L; local nx, ny = -uy, ux
            local hL, hW = 6, 2
            local bx, by = x2 - hL*ux, y2 - hL*uy
            gc:fillPolygon({x2, y2, bx + hW*nx, by + hW*ny, bx - hW*nx, by - hW*ny})
        end
    end

    local function drawReactionArrow(gc, val, dirX, dirY, cx, cy, labelPrefix, symb_label, custom_val_str, forceDraw)
        if math.abs(val) < 1e-4 and not forceDraw then return end
        local arrowLen = math.max(30, drawPxProMeter * 0.4)
        local sign = val >= 0 and 1 or -1
        if forceDraw then sign = 1 end
        local mag = math.abs(val)

        local tailX = cx - sign * dirX * arrowLen
        local tailY = cy - sign * dirY * arrowLen

        if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(0, 0, 255) end
        gc:setPen("thin", "smooth")
        drawExplosionArrow(gc, tailX, tailY, cx, cy)

        gc:setFont("sansserif", "r", 10)
        if showExplosionLabels ~= false then
            local label
            if explosionPage == 2 then
                if symb_label then label = symb_label else label = labelPrefix:gsub(" = ", "") end
            elseif custom_val_str then
                label = labelPrefix .. custom_val_str
            else
                label = labelPrefix .. formatLabel(mag)
            end
            local tw = gc:getStringWidth(label)

            local ox, oy = -dirY * sign, dirX * sign
            if oy > 0 or (oy == 0 and ox < 0) then ox = -ox; oy = -oy end
            gc:drawString(label, (cx + tailX)/2 - tw/2 + ox*12, (cy + tailY)/2 - 5 + oy*12)
        end
    end

    local function drawFBDArrow(gc, val, dirX, dirY, x, y, labelPrefix, symb_label, custom_val_str, forceDraw, flipMultiplier)
        if math.abs(val) < 1e-4 and not forceDraw then return end
        local arrowLen = math.max(30, drawPxProMeter * 0.45)
        local sign = val >= 0 and 1 or -1
        if forceDraw then sign = 1 end
        if forceDraw and flipMultiplier then sign = sign * flipMultiplier end
        local mag = math.abs(val)

        local tailX = x - sign * dirX * arrowLen
        local tailY = y - sign * dirY * arrowLen

        if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(0, 150, 0) end
        gc:setPen("thin", "smooth")
        drawExplosionArrow(gc, tailX, tailY, x, y)

        gc:setFont("sansserif", "r", 10)
        if showExplosionLabels ~= false then
            local label
            if explosionPage == 2 then
                if symb_label then label = symb_label else label = labelPrefix:gsub(" = ", "") end
            elseif custom_val_str then
                label = labelPrefix .. custom_val_str
            else
                label = labelPrefix .. formatLabel(mag)
            end

            local tw = gc:getStringWidth(label)

            local ox, oy = -dirY * sign, dirX * sign
            if oy > 0 or (oy == 0 and ox < 0) then ox = -ox; oy = -oy end
            gc:drawString(label, (x + tailX)/2 - tw/2 + ox*10, (y + tailY)/2 - 5 + oy*10)
        end
    end

    local function get_u_val(s, x, L_m, j, nA, nB)
        local u_homogen = (s.v_local[1] or 0)*(1-x/L_m) + (s.v_local[4] or 0)*(x/L_m)
        local u_part_class_EA = -(nA*x^2/2 + (nB-nA)*x^3/(6*L_m)) + (x/L_m) * (nA*L_m^2/2 + (nB-nA)*L_m^2/6)
        local u_part_cas_EA = (s.u_cas_pts_EA and s.u_cas_pts_EA[j+1]) or 0
        return u_homogen + (u_part_class_EA + u_part_cas_EA) / s.EA
    end

    local max_val = 0

    if ansichtsModus ~= "System" and ansichtsModus ~= "E" and not isPolplan and not isKinematic and not in_pvv_release then
        for i, s in ipairs(staebe) do
            if not s.is_cut then
                local L_m = math.sqrt((knoten[s.k2].x - knoten[s.k1].x)^2 + (knoten[s.k2].y - knoten[s.k1].y)^2)
                if L_m > 0 then
                    local dx, dy = knoten[s.k2].x - knoten[s.k1].x, knoten[s.k2].y - knoten[s.k1].y; local c_val, s_val = dx/L_m, -dy/L_m
                    local eff_gx = (s.gx or 0) * (s.gx_proj and math.abs(s_val) or 1); local eff_gy = (s.gy or 0) * (s.gy_proj and math.abs(c_val) or 1)
                    local n_add = eff_gx * c_val - eff_gy * s_val; local q_add = eff_gx * s_val + eff_gy * c_val
                    local N0, Q0, M0 = -s.s_local[1], -s.s_local[2], -s.s_local[3]
                    local qA, qB, nA, nB = s.q + s.q_A + q_add, s.q + s.q_B + q_add, s.n + s.n_A + n_add, s.n + s.n_B + n_add

                    for j = 0, ptsBiegelinie do
                        local x = (j/ptsBiegelinie) * L_m; local val = 0
                        local cas_Q_drop = (s.Q_cas_pts and s.Q_cas_pts[j+1]) or 0
                        local cas_M_drop = (s.M_cas_pts and s.M_cas_pts[j+1]) or 0
                        local cas_N_drop = (s.N_cas_pts and s.N_cas_pts[j+1]) or 0

                        if ansichtsModus == "N" then val = N0 - (nA*x + (nB-nA)*(x^2)/(2*L_m)) - cas_N_drop
                        elseif ansichtsModus == "Q" then val = Q0 - (qA*x + (qB-qA)*(x^2)/(2*L_m)) - cas_Q_drop
                        elseif ansichtsModus == "M" then val = M0 + Q0*x - s.m*x - (qA*(x^2)/2 + (qB-qA)*(x^3)/(6*L_m)) - cas_M_drop
                        elseif ansichtsModus == "U" then val = get_u_val(s, x, L_m, j, nA, nB)
                        elseif ansichtsModus == "W" and not skip_diagram then
                            local EI = s.EI
                            local c1 = (s.v_local[2] or 0) * EI
                            local c2 = -(s.v_local[3] or 0) * EI
                            local c3 = (s.v_local[5] or 0) * EI
                            local c4 = -(s.v_local[6] or 0) * EI
                            local xi = x / L_m
                            local val_homogen_EI = c1*(1-3*xi^2+2*xi^3) + c2*(x-2*x^2/L_m+x^3/(L_m^2)) + c3*(3*xi^2-2*xi^3) + c4*(-x^2/L_m+x^3/(L_m^2))
                            local v_part_class_EI = (x^2 * (L_m - x)^2) / (120 * L_m) * ((3*L_m - x)*qA + (2*L_m + x)*qB)
                            local v_part_cas_EI = (s.v_cas_pts_EI and s.v_cas_pts_EI[j+1]) or 0
                            val = (val_homogen_EI + v_part_class_EI + v_part_cas_EI) / EI
                        end
                        if math.abs(val) < 1e-5 then val = 0 end
                        if math.abs(val) > max_val then max_val = math.abs(val) end
                    end
                end
            elseif s.arc_plot_data then
                if ansichtsModus == "W" or ansichtsModus == "U" then
                    for v = 1, #s.arc_plot_data do
                        local pd = s.arc_plot_data[v]
                        local val_disp1 = math.sqrt((pd.disp_x1 or 0)^2 + (pd.disp_y1 or 0)^2)
                        local val_disp2 = math.sqrt((pd.disp_x2 or 0)^2 + (pd.disp_y2 or 0)^2)
                        local val_disp = math.max(val_disp1, val_disp2)
                        if val_disp > max_val then max_val = val_disp end
                    end
                else
                    for _, pd in ipairs(s.arc_plot_data) do
                        local v1, v2 = 0, 0
                        if ansichtsModus == "N" then v1 = pd.N; v2 = pd.N
                        elseif ansichtsModus == "Q" then v1 = pd.Q; v2 = pd.Q
                        elseif ansichtsModus == "M" then v1 = pd.M1; v2 = pd.M2
                        end
                        if math.abs(v1) > max_val then max_val = math.abs(v1) end
                        if math.abs(v2) > max_val then max_val = math.abs(v2) end
                    end
                end
            end
        end
    end
    if max_val < 1e-15 then max_val = 1 end
    local drawScale = (40 / max_val) * (drawPxProMeter / 100) * (verlaufSkalierung or 1)

    local isExplosion = (ansichtsModus == "E")
    glob_resultant_pts = {}
    local hovered_ts = nil
    if isExplosion and explosionPage == 2 and not fachwerkModus then
        if hoverTyp == "stab" and hoverObj and glob_ts_scheibe then
            hovered_ts = glob_ts_scheibe[hoverObj]
        end
    end

    local loadApplied = {}
    local loadApplied = {}

    if isKinematic then
        gc:setPen("thin", "dotted")
        gc:setColorRGB(0, 0, 0)
        for _, s in ipairs(staebe) do
            local opx1 = knoten[s.k1].x * drawPxProMeter + offsetX
            local opy1 = knoten[s.k1].y * drawPxProMeter + offsetY
            local opx2 = knoten[s.k2].x * drawPxProMeter + offsetX
            local opy2 = knoten[s.k2].y * drawPxProMeter + offsetY
            gc:drawLine(opx1, opy1, opx2, opy2)
        end
    end


    for i, s in ipairs(staebe) do
        local px1, py1 = knoten[s.k1].x * drawPxProMeter + offsetX, knoten[s.k1].y * drawPxProMeter + offsetY
        local px2, py2 = knoten[s.k2].x * drawPxProMeter + offsetX, knoten[s.k2].y * drawPxProMeter + offsetY
        if isKinematic then
            local u1x, u1y, u2x, u2y = getKinematicDisp_Stab(i)
            local anim_f = (0.5 * drawPxProMeter) / (kinematic_max_disp and kinematic_max_disp > 1e-6 and kinematic_max_disp or 1)
            px1, py1 = px1 + u1x * anim_f, py1 + u1y * anim_f
            px2, py2 = px2 + u2x * anim_f, py2 + u2y * anim_f
        end
        local orig_px1, orig_py1 = px1, py1
        local orig_px2, orig_py2 = px2, py2
        local dx_orig, dy_orig = px2 - px1, py2 - py1;
        local L_orig = math.sqrt(dx_orig^2 + dy_orig^2)

        local explodeA = knoten[s.k1].gelenk or s.gelenk_A or s.n_gelenk_A or s.q_gelenk_A
        local explodeB = knoten[s.k2].gelenk or s.gelenk_B or s.n_gelenk_B or s.q_gelenk_B
        
        local gapA, gapB = 0, 0
        if s.gelenk_A then gapA = 6 end
        if s.q_gelenk_A then gapA = 10 end
        if s.n_gelenk_A then gapA = 12 end
        if s.gelenk_B then gapB = 6 end
        if s.q_gelenk_B then gapB = 10 end
        if s.n_gelenk_B then gapB = 12 end
        
        if ansichtsModus == "W" or ansichtsModus == "U" then gapA, gapB = 0, 0 end

        local L = L_orig
        if L_orig > gapA + gapB + 10 then
            local ux, uy = dx_orig/L_orig, dy_orig/L_orig
            local expl_gap = isExplosion and math.min(1.5 * drawPxProMeter, L_orig * 0.35) or 0
            if hovered_ts then expl_gap = 0 end
            if explodeA then px1 = px1 + ux * (gapA + expl_gap); py1 = py1 + uy * (gapA + expl_gap) end
            if explodeB then px2 = px2 - ux * (gapB + expl_gap); py2 = py2 - uy * (gapB + expl_gap) end
            L = math.sqrt((px2-px1)^2 + (py2-py1)^2)
        end

        local dx, dy = px2 - px1, py2 - py1
        local ux, uy, nx, ny = 0, 0, 0, 0
        if L > 0 then ux, uy = dx/L, dy/L; nx, ny = -uy, ux end

        local skip_diagram = false
        if hoverTyp == "stab" and hoverObj and hoverObj ~= i then skip_diagram = true end



        if ansichtsModus == "W" then gc:setColorRGB(150, 150, 150)
        elseif isPolplan then
            local d_scheibe = s.scheibe and polplan.display_scheibe[s.scheibe] or s.scheibe
            if d_scheibe == 0 or (d_scheibe and polplan.fixed[d_scheibe]) then
                gc:setColorRGB(100, 100, 100)
            else
                local col = palette[((d_scheibe or 1) % #palette) + 1]
                gc:setColorRGB(col[1], col[2], col[3])
            end
    elseif (menuOffen and menuTyp == "stab" and menuIndex == i) or (not menuOffen and hoverTyp == "stab" and hoverObj == i) then 
                    gc:setColorRGB(0, 100, 255) 
                else 
                    if hovered_ts and glob_ts_scheibe and glob_ts_scheibe[i] ~= hovered_ts then
                        gc:setColorRGB(200, 200, 200)
                    else
                        gc:setColorRGB(0, 0, 0) 
                    end
                end

        local penSize = "thin"
        if isPolplan then penSize = "medium" end
        gc:setPen(penSize, "smooth")


        if ansichtsModus == "W" or ansichtsModus == "U" or s.is_cut then gc:setPen("thin", "dashed") end
        
        local true_L = (L / drawPxProMeter)
        if not (fachwerkModus and isExplosion) then
            if (s.bogen_r or 0) ~= 0 and math.abs(s.bogen_r) >= true_L/2 and true_L > 0 then
                local r_px = math.abs(s.bogen_r) * drawPxProMeter
                local sgn = s.bogen_r > 0 and -1 or 1
                local d_px = math.sqrt(r_px^2 - (L/2)^2)
                local arc_pts = {}
                for j=0, 50 do
                    local t = j/50
                    local x_local = (t - 0.5) * L
                    local y_local = sgn * (math.sqrt(r_px^2 - x_local^2) - d_px)
                    local ax = (px1+px2)/2 + x_local * (dx/L) - y_local * (dy/L)
                    local ay = (py1+py2)/2 + x_local * (dy/L) + y_local * (dx/L)
                    table.insert(arc_pts, ax); table.insert(arc_pts, ay)
                end
                gc:drawPolyLine(arc_pts)
            else
                gc:drawLine(px1, py1, px2, py2)
            end
        end
        gc:setPen("medium", "smooth")



        if isPolplan and L > 0 and not s.is_cut and s.scheibe and s.scheibe ~= 0 then
            gc:setFont("sansserif", "b", 10)
            if polplan.fixed[s.scheibe] then
                gc:setColorRGB(100, 100, 100)
                gc:drawString("S" .. tostring(s.scheibe) .. " (FEST)", (px1+px2)/2 + nx*10, (py1+py2)/2 + ny*10)
            else
                local col = palette[((s.scheibe or 1) % #palette) + 1]
                gc:setColorRGB(col[1], col[2], col[3])
                gc:drawString("S" .. tostring(s.scheibe or 1), (px1+px2)/2 + nx*10, (py1+py2)/2 + ny*10)
            end
        end
        if fachwerkModus and s.is_zero_force and modusText == "System" and not isExplosion then
            gc:setColorRGB(0, 180, 0)
            gc:setPen("medium", "smooth")
            local midX, midY = (px1+px2)/2, (py1+py2)/2
            local cSize = 6
            gc:drawLine(midX - cSize, midY - cSize, midX + cSize, midY + cSize)
            gc:drawLine(midX - cSize, midY + cSize, midX + cSize, midY - cSize)
            gc:setFont("sansserif", "b", 11)
            gc:drawString("0", midX + 8, midY - 12)
        end

        if s.is_cut and L > 0 then
            gc:setColorRGB(0, 0, 0); local midX, midY = (px1+px2)/2, (py1+py2)/2
            gc:drawLine(midX - ux*5 + nx*3, midY - uy*5 + ny*3, midX + ux*5 + nx*3, midY + uy*5 + ny*3)
            gc:drawLine(midX - ux*5 - nx*3, midY - uy*5 - ny*3, midX + ux*5 - nx*3, midY + uy*5 - ny*3)
        end

        if (s.x_nA or 0) ~= 0 and L > 0 then
            gc:setColorRGB(200, 0, 200); gc:setPen("medium", "smooth")
            local midX, midY = (px1+px2)/2, (py1+py2)/2
            drawArrow(gc, midX + ux*5, midY + uy*5, midX + ux*25, midY + uy*25)
            drawArrow(gc, midX - ux*5, midY - uy*5, midX - ux*25, midY - uy*25)
            gc:setFont("sansserif", "b", 9); gc:drawString("1.00", midX + ny*10 - 10, midY - nx*10 - 5)
        end

        if L > 0 and ansichtsModus ~= "W" and ansichtsModus ~= "U" and not isPolplan then
            local uxA, uyA, nxA, nyA = ux, uy, nx, ny
            local uxB, uyB, nxB, nyB = ux, uy, nx, ny
            if (s.bogen_r or 0) ~= 0 and math.abs(s.bogen_r) >= true_L/2 then
                local R = math.abs(s.bogen_r)
                local sgn = s.bogen_r > 0 and -1 or 1
                local function getTang(t)
                    local xl = (t - 0.5) * true_L
                    local denom = math.sqrt(math.max(1e-6, R^2 - xl^2))
                    local tx_l, ty_l = 1, -sgn * (xl / denom)
                    local len = math.sqrt(tx_l^2 + ty_l^2)
                    tx_l, ty_l = tx_l/len, ty_l/len
                    local t_gx = tx_l * (dx/L) - ty_l * (dy/L)
                    local t_gy = tx_l * (dy/L) + ty_l * (dx/L)
                    return t_gx, t_gy, -t_gy, t_gx
                end
                uxA, uyA, nxA, nyA = getTang(0)
                uxB, uyB, nxB, nyB = getTang(1)
            end
            
            local ux_orig, uy_orig = dx_orig/L_orig, dy_orig/L_orig
            local nx_orig, ny_orig = -uy_orig, ux_orig
            local jx1, jy1 = px1 - ux_orig * gapA, py1 - uy_orig * gapA
            local jx2, jy2 = px2 + ux_orig * gapB, py2 + uy_orig * gapB

            if s.q_gelenk_A and not s.is_cut then
                gc:setPen("thin", "smooth"); gc:setColorRGB(0, 0, 0)
                gc:drawLine(jx1, jy1, jx1 + ux_orig*3, jy1 + uy_orig*3)
                gc:drawLine(jx1 + ux_orig*3 + nx_orig*5, jy1 + uy_orig*3 + ny_orig*5, jx1 + ux_orig*3 - nx_orig*5, jy1 + uy_orig*3 - ny_orig*5)
                gc:drawLine(jx1 + ux_orig*7 + nx_orig*5, jy1 + uy_orig*7 + ny_orig*5, jx1 + ux_orig*7 - nx_orig*5, jy1 + uy_orig*7 - ny_orig*5)
                gc:drawLine(jx1 + ux_orig*7, jy1 + uy_orig*7, px1, py1)
            end
            if s.q_gelenk_B and not s.is_cut then
                gc:setPen("thin", "smooth"); gc:setColorRGB(0, 0, 0)
                gc:drawLine(jx2, jy2, jx2 - ux_orig*3, jy2 - uy_orig*3)
                gc:drawLine(jx2 - ux_orig*3 + nx_orig*5, jy2 - uy_orig*3 + ny_orig*5, jx2 - ux_orig*3 - nx_orig*5, jy2 - uy_orig*3 - ny_orig*5)
                gc:drawLine(jx2 - ux_orig*7 + nx_orig*5, jy2 - uy_orig*7 + ny_orig*5, jx2 - ux_orig*7 - nx_orig*5, jy2 - uy_orig*7 - ny_orig*5)
                gc:drawLine(jx2 - ux_orig*7, jy2 - uy_orig*7, px2, py2)
            end

            if s.n_gelenk_A and not s.is_cut then
                gc:setPen("thin", "smooth"); gc:setColorRGB(0, 0, 0)
                gc:drawLine(jx1, jy1, jx1 + ux_orig*3, jy1 + uy_orig*3)
                gc:drawLine(jx1 + ux_orig*3 + nx_orig*4, jy1 + uy_orig*3 + ny_orig*4, jx1 + ux_orig*3 - nx_orig*4, jy1 + uy_orig*3 - ny_orig*4)
                gc:drawLine(jx1 + ux_orig*3 + nx_orig*4, jy1 + uy_orig*3 + ny_orig*4, jx1 + ux_orig*11 + nx_orig*4, jy1 + uy_orig*11 + ny_orig*4)
                gc:drawLine(jx1 + ux_orig*3 - nx_orig*4, jy1 + uy_orig*3 - ny_orig*4, jx1 + ux_orig*11 - nx_orig*4, jy1 + uy_orig*11 - ny_orig*4)
                gc:fillArc(jx1 + ux_orig*9 - 2, jy1 + uy_orig*9 - 2, 4, 4, 0, 360)
                gc:drawLine(jx1 + ux_orig*9, jy1 + uy_orig*9, px1, py1)
            end
            if s.n_gelenk_B and not s.is_cut then
                gc:setPen("thin", "smooth"); gc:setColorRGB(0, 0, 0)
                gc:drawLine(jx2, jy2, jx2 - ux_orig*3, jy2 - uy_orig*3)
                gc:drawLine(jx2 - ux_orig*3 + nx_orig*4, jy2 - uy_orig*3 + ny_orig*4, jx2 - ux_orig*3 - nx_orig*4, jy2 - uy_orig*3 - ny_orig*4)
                gc:drawLine(jx2 - ux_orig*3 + nx_orig*4, jy2 - uy_orig*3 + ny_orig*4, jx2 - ux_orig*11 + nx_orig*4, jy2 - uy_orig*11 + ny_orig*4)
                gc:drawLine(jx2 - ux_orig*3 - nx_orig*4, jy2 - uy_orig*3 - ny_orig*4, jx2 - ux_orig*11 - nx_orig*4, jy2 - uy_orig*11 - ny_orig*4)
                gc:fillArc(jx2 - ux_orig*9 - 2, jy2 - uy_orig*9 - 2, 4, 4, 0, 360)
                gc:drawLine(jx2 - ux_orig*9, jy2 - uy_orig*9, px2, py2)
            end
        end

        if L > 0 then
            if ansichtsModus ~= "W" and ansichtsModus ~= "U" and not (fachwerkModus and isExplosion) then
                gc:setPen("thin", "dashed")
                if (menuOffen and menuTyp == "stab" and menuIndex == i) or (not menuOffen and hoverTyp == "stab" and hoverObj == i) then gc:setColorRGB(100, 150, 255) else gc:setColorRGB(150, 150, 150) end
                if (s.bogen_r or 0) ~= 0 and math.abs(s.bogen_r) >= (L / drawPxProMeter)/2 then
                    local r_px = math.abs(s.bogen_r) * drawPxProMeter
                    local sgn = s.bogen_r > 0 and -1 or 1
                    local d_px = math.sqrt(r_px^2 - (L/2)^2)
                    local dashed_pts = {}
                    for j=0, bogenSegmente do
                        local t = j/bogenSegmente
                        local x_local = (t - 0.5) * L
                        local y_local = sgn * (math.sqrt(r_px^2 - x_local^2) - d_px)
                        local ax = (px1+px2)/2 + x_local * (dx/L) - y_local * (dy/L)
                        local ay = (py1+py2)/2 + x_local * (dy/L) + y_local * (dx/L)
                        local tang_x = dx/L + sgn * (x_local / math.sqrt(r_px^2 - x_local^2)) * (dy/L)
                        local tang_y = dy/L - sgn * (x_local / math.sqrt(r_px^2 - x_local^2)) * (dx/L)
                        local len = math.sqrt(tang_x^2 + tang_y^2)
                        local lnx, lny = -tang_y/len, tang_x/len
                        table.insert(dashed_pts, ax + lnx*3)
                        table.insert(dashed_pts, ay + lny*3)
                    end
                    gc:drawPolyLine(dashed_pts)
                else
                    gc:drawLine(px1 + nx*3, py1 + ny*3, px2 + nx*3, py2 + ny*3)
                end
                gc:setPen("thin", "smooth")
            end
                if in_pvv_release and isKinematic then
                    local L_m = math.sqrt((knoten[s.k2].x - knoten[s.k1].x)^2 + (knoten[s.k2].y - knoten[s.k1].y)^2)
                    if L_m > 0 then
                        local u_phys_xA, u_phys_yA, u_phys_xB, u_phys_yB = getKinematicDisp_Stab(i)
                        local orig_dx_phys = knoten[s.k2].x - knoten[s.k1].x
                        local orig_dy_phys = knoten[s.k2].y - knoten[s.k1].y
                        local L_phys = math.sqrt(orig_dx_phys^2 + orig_dy_phys^2)
                        local cA = L_phys > 0 and orig_dx_phys/L_phys or 1
                        local sA = L_phys > 0 and orig_dy_phys/L_phys or 0
                        
                        local phi_stab = 0
                        if L_phys > 1e-6 then phi_stab = (orig_dx_phys * (u_phys_yB - u_phys_yA) - orig_dy_phys * (u_phys_xB - u_phys_xA)) / (L_phys^2) end
                        local phi_abs = math.abs(phi_stab)
                        local function formatDeltaStab(lbl, val)
                            if phi_abs > 1e-4 then 
                                return string.format("%s = %.2f * φ_0", lbl, math.abs(val)/phi_abs)
                            else 
                                local real_lbl = (s.scheibe and kinematic_disk_states and kinematic_disk_states[s.scheibe] and kinematic_disk_states[s.scheibe].type == "trans") and string.format("δ_%d", s.scheibe) or lbl
                                return string.format("%s = %.2f", real_lbl, math.abs(val)) 
                            end
                        end
                        
                        local anim_f = (0.5 * drawPxProMeter) / (kinematic_max_disp and kinematic_max_disp > 1e-6 and kinematic_max_disp or 1)

                        local qA = s.q + (s.q_A or 0); local qB = s.q + (s.q_B or 0)
                        local Rq = (qA + qB)/2 * L_phys + (s.R_q_cas or 0)
                        local Sq = (L_phys^2)/6 * (qA + 2*qB) + (s.S_q_cas or 0)
                        if math.abs(Rq) > 1e-4 then
                            local xs = Sq / Rq
                            local px = px1 + dx * (xs / L_phys); local py = py1 + dy * (xs / L_phys)
                            gc:setColorRGB(255, 0, 0)
                            local dir = Rq > 0 and -1 or 1; local h = 25 * dir
                            drawArrow(gc, px - sA*h, py + cA*h, px, py)
                            gc:setFont("sansserif", "r", 8)
                            local Rq_lbl_str, _, _ = processDistLoad_PvV(L_phys, L_phys, s.q_str, s.q_A_str, s.q_B_str, s.R_q_cas_str, s.S_q_cas_str, Rq, Sq, "q", true)
                            local lbl = Rq_lbl_str and ("R = " .. Rq_lbl_str) or string.format("R = %.2f", math.abs(Rq))
                            gc:drawString(lbl, px - sA*h + 5, py + cA*h - 10)
                            
                            local uxs = u_phys_xA + (xs / L_phys) * (u_phys_xB - u_phys_xA)
                            local uys = u_phys_yA + (xs / L_phys) * (u_phys_yB - u_phys_yA)
                            local vs = -uxs * sA + uys * cA
                            if math.abs(Rq * vs) > 1e-4 then
                                local disp_px = vs * anim_f
                                local ax1, ay1 = px - (-sA) * disp_px, py - cA * disp_px
                                gc:setColorRGB(200, 0, 200)
                                drawArrow(gc, ax1, ay1, px, py)
                                gc:drawString(formatDeltaStab("δ_q", vs), ax1 + 5, ay1 - 10)
                            end
                        end
                        
                        local nA = s.n + (s.n_A or 0); local nB = s.n + (s.n_B or 0)
                        local Rn = (nA + nB)/2 * L_phys + (s.R_n_cas or 0)
                        local Sn = (L_phys^2)/6 * (nA + 2*nB) + (s.S_n_cas or 0)
                        if math.abs(Rn) > 1e-4 then
                            local xs = Sn / Rn
                            local px = px1 + dx * (xs / L_phys); local py = py1 + dy * (xs / L_phys)
                            gc:setColorRGB(255, 0, 0)
                            local dir = Rn > 0 and 1 or -1; local len = 25
                            drawArrow(gc, px - cA*len*dir, py - sA*len*dir, px, py)
                            gc:setFont("sansserif", "r", 8)
                            local Rn_lbl_str, _, _ = processDistLoad_PvV(L_phys, L_phys, s.n_str, s.n_A_str, s.n_B_str, s.R_n_cas_str, s.S_n_cas_str, Rn, Sn, "q", true)
                            local lbl = Rn_lbl_str and ("R = " .. Rn_lbl_str) or string.format("R = %.2f", math.abs(Rn))
                            gc:drawString(lbl, px - cA*len*dir + 5, py - sA*len*dir - 10)
                            
                            local uxs = u_phys_xA + (xs / L_phys) * (u_phys_xB - u_phys_xA)
                            local uys = u_phys_yA + (xs / L_phys) * (u_phys_yB - u_phys_yA)
                            local us = uxs * cA + uys * sA
                            if math.abs(Rn * us) > 1e-4 then
                                local disp_px = us * anim_f
                                local ax1, ay1 = px - cA * disp_px, py - sA * disp_px
                                gc:setColorRGB(200, 0, 200)
                                drawArrow(gc, ax1, ay1, px, py)
                                gc:drawString(formatDeltaStab("δ_n", us), ax1 + 5, ay1 - 10)
                            end
                        end
                        
                        local Rgy = (s.gy or 0) * (s.gy_proj and math.abs(orig_dx_phys) or L_phys) + (s.R_gy_cas or 0)
                        local Sgy = Rgy * (L_phys/2) + (s.S_gy_cas or 0)
                        if math.abs(Rgy) > 1e-4 then
                            local xs = Sgy / Rgy
                            local px = px1 + dx * (xs / L_phys); local py = py1 + dy * (xs / L_phys)
                            gc:setColorRGB(255, 150, 0)
                            local dir = Rgy > 0 and -1 or 1; local h = 25 * dir
                            drawArrow(gc, px, py + h, px, py)
                            gc:setFont("sansserif", "r", 8)
                            local L_eff_gy = s.gy_proj and math.abs(orig_dx_phys) or L_phys
                            local Rgy_lbl_str, _, _ = processDistLoad_PvV(L_phys, L_eff_gy, s.gy_str, nil, nil, s.R_gy_cas_str, s.S_gy_cas_str, Rgy, Sgy, "g", true)
                            local lbl = Rgy_lbl_str and ("R = " .. Rgy_lbl_str) or string.format("R = %.2f", math.abs(Rgy))
                            gc:drawString(lbl, px + 5, py + h - 10)
                            
                            local uys = u_phys_yA + (xs / L_phys) * (u_phys_yB - u_phys_yA)
                            if math.abs(Rgy * uys) > 1e-4 then
                                local disp_px = uys * anim_f
                                local ax1, ay1 = px, py - disp_px
                                gc:setColorRGB(200, 0, 200)
                                drawArrow(gc, ax1, ay1, px, py)
                                gc:drawString(formatDeltaStab("δ_gy", uys), ax1 + 5, ay1 - 10)
                            end
                        end
                        
                        local Rgx = (s.gx or 0) * (s.gx_proj and math.abs(orig_dy_phys) or L_phys) + (s.R_gx_cas or 0)
                        local Sgx = Rgx * (L_phys/2) + (s.S_gx_cas or 0)
                        if math.abs(Rgx) > 1e-4 then
                            local xs = Sgx / Rgx
                            local px = px1 + dx * (xs / L_phys); local py = py1 + dy * (xs / L_phys)
                            gc:setColorRGB(255, 150, 0)
                            local dir = Rgx > 0 and -1 or 1; local h = 25 * dir
                            drawArrow(gc, px + h, py, px, py)
                            gc:setFont("sansserif", "r", 8)
                            local L_eff_gx = s.gx_proj and math.abs(orig_dy_phys) or L_phys
                            local Rgx_lbl_str, _, _ = processDistLoad_PvV(L_phys, L_eff_gx, s.gx_str, nil, nil, s.R_gx_cas_str, s.S_gx_cas_str, Rgx, Sgx, "g", true)
                            local lbl = Rgx_lbl_str and ("R = " .. Rgx_lbl_str) or string.format("R = %.2f", math.abs(Rgx))
                            gc:drawString(lbl, px + h + 5, py - 10)
                            
                            local uxs = u_phys_xA + (xs / L_phys) * (u_phys_xB - u_phys_xA)
                            if math.abs(Rgx * uxs) > 1e-4 then
                                local disp_px = uxs * anim_f
                                local ax1, ay1 = px - disp_px, py
                                gc:setColorRGB(200, 0, 200)
                                drawArrow(gc, ax1, ay1, px, py)
                                gc:drawString(formatDeltaStab("δ_gx", uxs), ax1 + 5, ay1 - 10)
                            end
                        end
                        
                        local Rm = (s.m or 0) * L_phys
                        if math.abs(Rm) > 1e-4 then
                            local px, py = px1 + dx*0.5, py1 + dy*0.5
                            gc:setColorRGB(255, 150, 0)
                            drawMoment(gc, px, py, 12, Rm < 0)
                            gc:setFont("sansserif", "r", 8)
                            gc:drawString(string.format("M = %.2f", math.abs(Rm)), px + 15, py - 10)
                        end
                    end
                end

            local should_draw_loads = true
            if isExplosion and hovered_ts and glob_ts_scheibe and glob_ts_scheibe[i] ~= hovered_ts then should_draw_loads = false end
            if should_draw_loads and (modusText == "System" or (modusText == "PvV" and not in_pvv_release) or isExplosion) then
                local has_cas_gy = s.gy_str and string.find(s.gy_str, "x")
                local has_classic_gy = (s.gy or 0) ~= 0
                if hovered_ts and glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts and (has_classic_gy or has_cas_gy) then
                    local dx_m, dy_m = knoten[s.k2].x - knoten[s.k1].x, knoten[s.k2].y - knoten[s.k1].y
                    local L_phys = math.sqrt(dx_m^2 + dy_m^2)
                    local Rgy = (s.gy or 0) * (s.gy_proj and math.abs(dx_m) or L_phys) + (s.R_gy_cas or 0)
                    local Sgy = Rgy * (L_phys/2) + (s.S_gy_cas or 0)
                    if math.abs(Rgy) > 1e-4 then
                        local x_res = Sgy / Rgy
                        local px_res = orig_px1 + ux * x_res * drawPxProMeter
                        local py_res = orig_py1 + uy * x_res * drawPxProMeter
                        gc:setColorRGB(255, 150, 0)
                        local dir = Rgy > 0 and 1 or -1
                        drawArrow(gc, px_res, py_res - 40 * dir, px_res, py_res)
                        gc:setFont("sansserif", "b", 8)
                        gc:drawString(formatLabel(math.abs(Rgy)), px_res + 5, py_res - 45 * dir - 10)
                        if not glob_resultant_pts then glob_resultant_pts = {} end
                        table.insert(glob_resultant_pts, {x = knoten[s.k1].x + ux * x_res, y = knoten[s.k1].y + uy * x_res, is_virtual = false})
                    end
                elseif has_classic_gy or has_cas_gy then
                    local steps = 10
                    local max_gy = 0
                    if has_cas_gy and s.gy_pts then
                        for j=1, 11 do if math.abs(s.gy_pts[j]) > max_gy then max_gy = math.abs(s.gy_pts[j]) end end
                else max_gy = math.abs(s.gy) end

                    if max_gy > 0 then
                        gc:setColorRGB(255, 150, 0)
                        local scale_gy = 20 / max_gy
                        if s.gy_proj then
                            local ref_gy = has_cas_gy and (s.gy_pts and s.gy_pts[1] or 0) or s.gy
                            local top_y = math.min(py1, py2) - 25; if ref_gy < 0 then top_y = math.max(py1, py2) + 25 end
                            gc:drawLine(px1, py1, px1, top_y); gc:drawLine(px2, py2, px2, top_y)
                            local env_pts = {}
                            for j = 0, steps do
                                local t = j/steps; local gy_val = has_cas_gy and (s.gy_pts and s.gy_pts[j+1] or 0) or s.gy
                                local dir = gy_val > 0 and -1 or 1
                                local h_curr = math.abs(gy_val) * scale_gy * dir
                                local tailX, tailY = px1 + dx*t, top_y + h_curr
                                table.insert(env_pts, tailX); table.insert(env_pts, tailY)
                                if math.abs(h_curr) > 0.5 then drawArrow(gc, tailX, tailY, px1 + dx*t, top_y) end
                            end
                            gc:setPen("thin", "smooth"); gc:drawPolyLine(env_pts); gc:drawLine(px1, top_y, px2, top_y)
                        else
                            local env_pts = {}
                            for j = 0, steps do
                                local t = j/steps; local gy_val = has_cas_gy and (s.gy_pts and s.gy_pts[j+1] or 0) or s.gy
                                local dir = gy_val > 0 and -1 or 1
                                local h_curr = math.abs(gy_val) * scale_gy * dir
                                local tailX, tailY = px1 + dx*t, py1 + dy*t + h_curr
                                table.insert(env_pts, tailX); table.insert(env_pts, tailY)
                                if math.abs(h_curr) > 0.5 then drawArrow(gc, tailX, tailY, px1 + dx*t, py1 + dy*t) end
                            end
                            gc:setPen("thin", "smooth"); gc:drawPolyLine(env_pts)
                        end
                    end
                end

                local has_cas_gx = s.gx_str and string.find(s.gx_str, "x")
                local has_classic_gx = (s.gx or 0) ~= 0
                if hovered_ts and glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts and (has_classic_gx or has_cas_gx) then
                    local dx_m, dy_m = knoten[s.k2].x - knoten[s.k1].x, knoten[s.k2].y - knoten[s.k1].y
                    local L_phys = math.sqrt(dx_m^2 + dy_m^2)
                    local Rgx = (s.gx or 0) * (s.gx_proj and math.abs(dy_m) or L_phys) + (s.R_gx_cas or 0)
                    local Sgx = Rgx * (L_phys/2) + (s.S_gx_cas or 0)
                    if math.abs(Rgx) > 1e-4 then
                        local x_res = Sgx / Rgx
                        local px_res = orig_px1 + ux * x_res * drawPxProMeter
                        local py_res = orig_py1 + uy * x_res * drawPxProMeter
                        gc:setColorRGB(255, 150, 0)
                        local dir = Rgx > 0 and -1 or 1
                        drawArrow(gc, px_res + 40 * dir, py_res, px_res, py_res)
                        gc:setFont("sansserif", "b", 8)
                        gc:drawString(formatLabel(math.abs(Rgx)), px_res + 45 * dir + 5, py_res - 10)
                        if not glob_resultant_pts then glob_resultant_pts = {} end
                        table.insert(glob_resultant_pts, {x = knoten[s.k1].x + ux * x_res, y = knoten[s.k1].y + uy * x_res, is_virtual = false})
                    end
                elseif has_classic_gx or has_cas_gx then
                    local steps = 10
                    local max_gx = 0
                    if has_cas_gx and s.gx_pts then
                        for j=1, 11 do if math.abs(s.gx_pts[j]) > max_gx then max_gx = math.abs(s.gx_pts[j]) end end
                else max_gx = math.abs(s.gx) end

                    if max_gx > 0 then
                        gc:setColorRGB(255, 150, 0)
                        local scale_gx = 20 / max_gx
                        if s.gx_proj then
                            local ref_gx = has_cas_gx and (s.gx_pts and s.gx_pts[1] or 0) or s.gx
                            local side_x = math.min(px1, px2) - 25; if ref_gx < 0 then side_x = math.max(px1, px2) + 25 end
                            gc:drawLine(px1, py1, side_x, py1); gc:drawLine(px2, py2, side_x, py2)
                            local env_pts = {}
                            for j = 0, steps do
                                local t = j/steps; local gx_val = has_cas_gx and (s.gx_pts and s.gx_pts[j+1] or 0) or s.gx
                                local dir = gx_val > 0 and -1 or 1
                                local h_curr = math.abs(gx_val) * scale_gx * dir
                                local tailX, tailY = side_x + h_curr, py1 + dy*t
                                table.insert(env_pts, tailX); table.insert(env_pts, tailY)
                                if math.abs(h_curr) > 0.5 then drawArrow(gc, tailX, tailY, side_x, py1 + dy*t) end
                            end
                            gc:setPen("thin", "smooth"); gc:drawPolyLine(env_pts); gc:drawLine(side_x, py1, side_x, py2)
                        else
                            local env_pts = {}
                            for j = 0, steps do
                                local t = j/steps; local gx_val = has_cas_gx and (s.gx_pts and s.gx_pts[j+1] or 0) or s.gx
                                local dir = gx_val > 0 and -1 or 1
                                local h_curr = math.abs(gx_val) * scale_gx * dir
                                local tailX, tailY = px1 + dx*t + h_curr, py1 + dy*t
                                table.insert(env_pts, tailX); table.insert(env_pts, tailY)
                                if math.abs(h_curr) > 0.5 then drawArrow(gc, tailX, tailY, px1 + dx*t, py1 + dy*t) end
                            end
                            gc:setPen("thin", "smooth"); gc:drawPolyLine(env_pts)
                        end
                    end
                end

                gc:setColorRGB(255, 50, 50)
                local has_classic_q = (s.q + s.q_A ~= 0) or (s.q + s.q_B ~= 0)
                local has_cas_q = (s.q_pts and #s.q_pts == 11)

                if hovered_ts and glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts and (has_classic_q or has_cas_q) then
                    local dx_m, dy_m = knoten[s.k2].x - knoten[s.k1].x, knoten[s.k2].y - knoten[s.k1].y
                    local L_phys = math.sqrt(dx_m^2 + dy_m^2)
                    local qA = s.q + (s.q_A or 0); local qB = s.q + (s.q_B or 0)
                    local Rq = (qA + qB)/2 * L_phys + (s.R_q_cas or 0)
                    local Sq = (L_phys^2)/6 * (qA + 2*qB) + (s.S_q_cas or 0)
                    if math.abs(Rq) > 1e-4 then
                        local x_res = Sq / Rq
                        local px_res = orig_px1 + ux * x_res * drawPxProMeter
                        local py_res = orig_py1 + uy * x_res * drawPxProMeter
                        drawArrow(gc, px_res - nx * 40 * (Rq > 0 and 1 or -1), py_res - ny * 40 * (Rq > 0 and 1 or -1), px_res, py_res)
                        gc:setFont("sansserif", "b", 8)
                        gc:drawString(formatLabel(math.abs(Rq)), px_res - nx * 45 * (Rq > 0 and 1 or -1) - 10, py_res - ny * 45 * (Rq > 0 and 1 or -1) - 10)
                        -- Let's also add the resultant point to a global so we can dimension it
                        if not glob_resultant_pts then glob_resultant_pts = {} end
                        table.insert(glob_resultant_pts, {x = knoten[s.k1].x + ux * x_res, y = knoten[s.k1].y + uy * x_res, is_virtual = false})
                    end
                elseif has_classic_q or has_cas_q then
                    local combined_q = {}; local max_abs_q = 0
                    for j = 0, 10 do
                        local t = j / 10; local q_class = (s.q + s.q_A)*(1-t) + (s.q + s.q_B)*t
                        local q_tot = has_cas_q and s.q_pts[j+1] or q_class
                        table.insert(combined_q, q_tot)
                        if math.abs(q_tot) > max_abs_q then max_abs_q = math.abs(q_tot) end
                    end

                    if max_abs_q > 0 then
                        local scale_q = 25 / max_abs_q; local pts_env = {}
                        for j = 0, 10 do
                            local t = j / 10; local h_curr = -combined_q[j+1] * scale_q
                            local fx, fy = px1 + dx*t, py1 + dy*t
                            table.insert(pts_env, fx + nx*h_curr); table.insert(pts_env, fy + ny*h_curr)
                            if math.abs(h_curr) > 0.5 then drawArrow(gc, fx + nx*h_curr, fy + ny*h_curr, fx, fy) end
                        end
                        gc:setPen("thin", "smooth"); gc:drawPolyLine(pts_env)
                        gc:drawLine(px1, py1, pts_env[1], pts_env[2]); gc:drawLine(px2, py2, pts_env[#pts_env-1], pts_env[#pts_env])
                        
                    end
                end

                local has_classic_n = (s.n + s.n_A ~= 0) or (s.n + s.n_B ~= 0)
                local has_cas_n = (s.n_pts and #s.n_pts == 11)

                if has_classic_n or has_cas_n then
                    local combined_n = {}; local max_abs_n = 0
                    for j = 0, 10 do
                        local t = j / 10; local n_class = (s.n + s.n_A)*(1-t) + (s.n + s.n_B)*t
                        local n_c = (has_cas_n and s.n_pts[j+1]) or 0
                        local n_tot = n_class + n_c
                        table.insert(combined_n, n_tot)
                        if math.abs(n_tot) > max_abs_n then max_abs_n = math.abs(n_tot) end
                    end

                    if max_abs_n > 0 then
                        local dist = 14; gc:drawLine(px1 + nx*dist, py1 + ny*dist, px2 + nx*dist, py2 + ny*dist)
                        for j = 0, 10, 2 do
                            local t = j/10; local n_curr = combined_n[j+1]; local fx, fy = px1 + dx*t + nx*dist, py1 + dy*t + ny*dist
                            if math.abs(n_curr) > 0.5 then
                                local arr_len = (n_curr/max_abs_n)*12
                                drawArrow(gc, fx - (dx/L)*arr_len, fy - (dy/L)*arr_len, fx + (dx/L)*arr_len, fy + (dy/L)*arr_len)
                            end
                        end
                        
                    end
                end

                local has_classic_m = (s.m ~= 0)
                local has_cas_m = (s.m_pts and #s.m_pts == 11)

                if has_classic_m or has_cas_m then
                    local combined_m = {}; local max_abs_m = 0
                    for j = 0, 10 do
                        local m_class = s.m; local m_c = (has_cas_m and s.m_pts[j+1]) or 0; local m_tot = m_class + m_c
                        table.insert(combined_m, m_tot)
                        if math.abs(m_tot) > max_abs_m then max_abs_m = math.abs(m_tot) end
                    end
                    if max_abs_m > 0 then
                        for j = 1, 9, 2 do
                            local t = j/10; local m_curr = combined_m[j+1]; local fx, fy = px1 + dx*t, py1 + dy*t
                            if math.abs(m_curr) > 0.5 then drawMoment(gc, fx, fy, 8, m_curr < 0) end
                        end
                        
                    end
                end

                if (s.x_mA or 0) ~= 0 then gc:setColorRGB(200, 0, 200); gc:setPen("thin", "smooth"); drawRodMoment(gc, px1, py1, ux, uy, s.x_mA < 0) end
                if (s.x_mB or 0) ~= 0 then gc:setColorRGB(200, 0, 200); gc:setPen("thin", "smooth"); drawRodMoment(gc, px2, py2, -ux, -uy, s.x_mB < 0) end
                
                if (modusText == "System" or (fachwerkModus and ansichtsModus == "N")) and fachwerkModus and s.s_local and L > 0 and not isExplosion then
                    local N_val = -(s.s_local[1] or 0)
                    local is_zero = math.abs(N_val) < 1e-4
                    if not is_zero or symbolischer_modus or not s.is_zero_force or modusText ~= "System" then
                        gc:setFont("sansserif", "r", 8)
                        if N_val > 1e-4 then gc:setColorRGB(0, 0, 200) elseif N_val < -1e-4 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 180, 0) end
                        local n_str = symbolischer_modus and fm(s.symb_N_start or "0", true) or formatLabel(N_val)
                        gc:drawString(n_str, (px1+px2)/2 - gc:getStringWidth(n_str)/2, (py1+py2)/2 - 15)
                        gc:setColorRGB(0, 0, 0)
                    end
                end

            elseif not isExplosion and not s.is_cut and not isPolplan and (s.bogen_r or 0) ~= 0 and s.arc_plot_data and (ansichtsModus == "N" or ansichtsModus == "Q" or ansichtsModus == "M" or ansichtsModus == "W" or ansichtsModus == "U") and not skip_diagram then
                local max_val_ext, best_px, best_py, best_nx, best_ny = 0, 0, 0, 0, 0
                local R = math.abs(s.bogen_r)
                local sgn = s.bogen_r > 0 and -1 or 1
                local r_px = R * drawPxProMeter
                local d_px = math.sqrt(r_px^2 - (L/2)^2)
                
                local poly_pts = render_pts_1; for k_idx=1,#poly_pts do poly_pts[k_idx]=nil end
                local ref_pts = render_pts_2; for k_idx=1,#ref_pts do ref_pts[k_idx]=nil end
                local num_seg = #s.arc_plot_data
                for j = 0, num_seg do
                    local t = j / num_seg
                    
                    local val = 0
                    local px_val, py_val
                    local nx_t, ny_t = 0, 0
                    
                    local xl = (t - 0.5) * true_L
                    local denom = math.sqrt(math.max(1e-6, R^2 - xl^2))
                    local tx_l, ty_l = 1, -sgn * (xl / denom)
                    local len = math.sqrt(tx_l^2 + ty_l^2)
                    tx_l, ty_l = tx_l/len, ty_l/len
                    local t_gx = tx_l * (dx/L) - ty_l * (dy/L)
                    local t_gy = tx_l * (dy/L) + ty_l * (dx/L)
                    local nx_t, ny_t = -t_gy, t_gx
                    
                    if j == 0 then s.arc_nx0, s.arc_ny0 = nx_t, ny_t end
                    if j == num_seg then s.arc_nx1, s.arc_ny1 = nx_t, ny_t end
                    
                    local x_local_px = (t - 0.5) * L
                    local y_local_px = sgn * (math.sqrt(r_px^2 - x_local_px^2) - d_px)
                    local ax = (px1+px2)/2 + x_local_px * (dx/L) - y_local_px * (dy/L)
                    local ay = (py1+py2)/2 + x_local_px * (dy/L) + y_local_px * (dx/L)
                    
                    if ansichtsModus == "W" then
                        local pd_left = j > 0 and s.arc_plot_data[j] or s.arc_plot_data[1]
                        local disp_x = (j == 0) and (pd_left.disp_x1 or 0) or (pd_left.disp_x2 or 0)
                        local disp_y = (j == 0) and (pd_left.disp_y1 or 0) or (pd_left.disp_y2 or 0)
                        val = math.sqrt(disp_x^2 + disp_y^2)
                        px_val = ax + disp_x * drawScale
                        py_val = ay + disp_y * drawScale
                    elseif ansichtsModus == "U" then
                        local pd_left = j > 0 and s.arc_plot_data[j] or s.arc_plot_data[1]
                        local disp_x = (j == 0) and (pd_left.disp_x1 or 0) or (pd_left.disp_x2 or 0)
                        local disp_y = (j == 0) and (pd_left.disp_y1 or 0) or (pd_left.disp_y2 or 0)
                        val = disp_x * t_gx + disp_y * t_gy
                        local dist = val * drawScale
                        px_val = ax + nx_t * dist
                        py_val = ay + ny_t * dist
                    else
                        local pd_left = j > 0 and s.arc_plot_data[j] or s.arc_plot_data[1]
                        local pd_right = j < num_seg and s.arc_plot_data[j+1] or s.arc_plot_data[num_seg]
                        if ansichtsModus == "M" then
                            if j == 0 then val = pd_right.M1
                            elseif j == num_seg then val = pd_left.M2
                            else val = (pd_left.M2 + pd_right.M1) / 2 end
                        elseif ansichtsModus == "N" then val = (pd_left.N + pd_right.N) / 2
                        elseif ansichtsModus == "Q" then val = (pd_left.Q + pd_right.Q) / 2 end
                        local dist = val * drawScale
                        px_val = ax + nx_t * dist
                        py_val = ay + ny_t * dist
                    end
                    
                    table.insert(poly_pts, px_val)
                    table.insert(poly_pts, py_val)
                    table.insert(ref_pts, ax)
                    table.insert(ref_pts, ay)
                    
                    if math.abs(val) >= math.abs(max_val_ext) then max_val_ext = val; best_px = px_val; best_py = py_val; best_nx = nx_t; best_ny = ny_t; best_j = j end
                end
                
                if ansichtsModus == "M" then gc:setColorRGB(200, 50, 50) elseif ansichtsModus == "Q" then gc:setColorRGB(50, 150, 50) elseif ansichtsModus == "N" then gc:setColorRGB(50, 50, 200) elseif ansichtsModus == "W" then gc:setColorRGB(200, 0, 200) elseif ansichtsModus == "U" then gc:setColorRGB(255, 120, 0) end
                gc:setPen("thin", "smooth")
                
                if ansichtsModus == "W" or ansichtsModus == "U" then
                    local smooth_pts = render_pts_3 or {}; render_pts_3 = smooth_pts; for k_idx=1,#smooth_pts do smooth_pts[k_idx]=nil end
                    local n_pts = #poly_pts / 2
                    for i = 1, n_pts - 1 do
                        local p0x = poly_pts[math.max(1, i-1)*2 - 1]
                        local p0y = poly_pts[math.max(1, i-1)*2]
                        local p1x = poly_pts[i*2 - 1]
                        local p1y = poly_pts[i*2]
                        local p2x = poly_pts[(i+1)*2 - 1]
                        local p2y = poly_pts[(i+1)*2]
                        local p3x = poly_pts[math.min(n_pts, i+2)*2 - 1]
                        local p3y = poly_pts[math.min(n_pts, i+2)*2]
                        
                        local steps = 4
                        for j = 0, steps - 1 do
                            local t = j / steps
                            local t2 = t * t
                            local t3 = t2 * t
                            local v0x = (p2x - p0x) * 0.5
                            local v0y = (p2y - p0y) * 0.5
                            local v1x = (p3x - p1x) * 0.5
                            local v1y = (p3y - p1y) * 0.5
                            
                            local px = (2*p1x - 2*p2x + v0x + v1x)*t3 + (-3*p1x + 3*p2x - 2*v0x - v1x)*t2 + v0x*t + p1x
                            local py = (2*p1y - 2*p2y + v0y + v1y)*t3 + (-3*p1y + 3*p2y - 2*v0y - v1y)*t2 + v0y*t + p1y
                            table.insert(smooth_pts, px)
                            table.insert(smooth_pts, py)
                        end
                    end
                    table.insert(smooth_pts, poly_pts[#poly_pts-1])
                    table.insert(smooth_pts, poly_pts[#poly_pts])
                    gc:drawPolyLine(smooth_pts)
                else
                    gc:drawPolyLine(poly_pts)
                end
                
                if ansichtsModus ~= "W" and ansichtsModus ~= "U" then
                    gc:setColorRGB(180, 180, 180); gc:setPen("thin", "smooth")
                    for j=1, num_seg+1 do
                        gc:drawLine(ref_pts[j*2-1], ref_pts[j*2], poly_pts[j*2-1], poly_pts[j*2])
                    end
                end
                
                if ansichtsModus ~= "W" and ansichtsModus ~= "U" then
                    local pd_first = s.arc_plot_data[1]
                    local pd_last = s.arc_plot_data[num_seg]
                    local v_start = (ansichtsModus == "N" and pd_first.N) or (ansichtsModus == "Q" and pd_first.Q) or (pd_first.M1)
                    local v_end = (ansichtsModus == "N" and pd_last.N) or (ansichtsModus == "Q" and pd_last.Q) or (pd_last.M2)
                    
                    gc:setFont("sansserif", "r", 8); gc:setColorRGB(0, 0, 0)
                    if schnittAnzeigeModus ~= "Hover" then
                        gc:drawString(getSymbLabel(s, ansichtsModus, "start", v_start), poly_pts[1] + s.arc_nx0*5, poly_pts[2] + s.arc_ny0*5)
                        gc:drawString(getSymbLabel(s, ansichtsModus, "end", v_end), poly_pts[#poly_pts-1] + s.arc_nx1*5, poly_pts[#poly_pts] + s.arc_ny1*5)
                    end
                end

                if ansichtsModus == "W" or ansichtsModus == "U" then
                    if math.abs(max_val_ext) > 1e-12 then
                        if ansichtsModus == "W" then
                            gc:setColorRGB(200, 0, 200)
                            gc:fillArc(best_px - 1, best_py - 1, 3, 3, 0, 360)
                        else
                            gc:setColorRGB(255, 120, 0)
                            gc:fillArc(best_px - 2, best_py - 2, 5, 5, 0, 360)
                        end
                        gc:setFont("sansserif", "r", 8)
                        if zeigeMaxWerte then gc:drawString(string.format("max: %.3f mm", max_val_ext*1000), best_px + best_nx*6, best_py + best_ny*6) end
                    end
                elseif ansichtsModus == "N" or ansichtsModus == "Q" or ansichtsModus == "M" then
                    if math.abs(max_val_ext) > 1e-12 then
                        if ansichtsModus == "M" then gc:setColorRGB(200, 50, 50) elseif ansichtsModus == "Q" then gc:setColorRGB(50, 150, 50) else gc:setColorRGB(50, 50, 200) end
                        gc:fillArc(best_px - 2, best_py - 2, 5, 5, 0, 360)
                        if zeigeMaxWerte and best_j > 0 and best_j < num_seg then 
                            gc:setFont("sansserif", "r", 8)
                            gc:drawString(getSymbLabel(s, ansichtsModus, "max", max_val_ext), best_px + best_nx*6, best_py + best_ny*6)
                        end
                    end
                end
                
                if (ansichtsModus == "M" or ansichtsModus == "N" or ansichtsModus == "Q") then
                    local function get_arc_val(idx)
                        local pd = s.arc_plot_data[idx]
                        if not pd then return 0 end
                        if ansichtsModus == "N" then return pd.N
                        elseif ansichtsModus == "Q" then return pd.Q
                        elseif ansichtsModus == "M" then return pd.M1 end
                        return 0
                    end
                    
                    if s.messpunkte then
                        for _, t_m in ipairs(s.messpunkte) do
                            local hover_j = math.max(1, math.min(#s.arc_plot_data, math.floor(t_m * #s.arc_plot_data + 0.5)))
                            local h_px = poly_pts[hover_j*2 - 1] or poly_pts[1]
                            local h_py = poly_pts[hover_j*2] or poly_pts[2]
                            local h_val = get_arc_val(hover_j)
                            local h_x = t_m * math.abs(s.bogen_alpha or 1) * math.abs(s.bogen_r or 1)
                            gc:setColorRGB(0, 150, 0)
                            gc:fillArc(h_px - 3, h_py - 3, 7, 7, 0, 360)
                            gc:setColorRGB(255, 255, 220); gc:fillRect(h_px, h_py, 100, 16)
                            gc:setColorRGB(0, 0, 0); gc:drawRect(h_px, h_py, 100, 16)
                            gc:drawString(string.format("s=%.2fm: %.2f", h_x, h_val), h_px + 2, h_py)
                        end
                    end
                    
                    if schnittAnzeigeModus == "Hover" and hoverObj == i and hoverTyp == "stab" then
                        -- Find closest point on arc
                        local min_dist = math.huge
                        local best_idx = 1
                        local n_pts = #poly_pts / 2
                        for j = 1, n_pts do
                            local px = poly_pts[j*2 - 1]
                            local py = poly_pts[j*2]
                            local d = (mouseX - px)^2 + (mouseY - py)^2
                            if d < min_dist then min_dist = d; best_idx = j end
                        end
                        
                        if min_dist < 400 then
                            local h_px = poly_pts[best_idx*2 - 1]
                            local h_py = poly_pts[best_idx*2]
                            local h_val = get_arc_val(best_idx)
                            local t_m = best_idx / n_pts
                            local h_x = t_m * math.abs(s.bogen_alpha or 1) * math.abs(s.bogen_r or 1)
                            gc:setColorRGB(255, 0, 0)
                            gc:fillArc(h_px - 3, h_py - 3, 7, 7, 0, 360)
                            gc:setColorRGB(255, 255, 220); gc:fillRect(h_px, h_py, 100, 16)
                            gc:setColorRGB(0, 0, 0); gc:drawRect(h_px, h_py, 100, 16)
                            gc:drawString(string.format("s=%.2fm: %.2f", h_x, h_val), h_px + 2, h_py)
                        end
                    end
                end
            elseif ansichtsModus ~= "System" and not isExplosion and not s.is_cut and not isPolplan and (s.bogen_r or 0) == 0 and not skip_diagram then
                local L_m = math.sqrt((knoten[s.k2].x - knoten[s.k1].x)^2 + (knoten[s.k2].y - knoten[s.k1].y)^2)
                local c_val, s_val = dx/L, -dy/L
                local eff_gx = (s.gx or 0) * (s.gx_proj and math.abs(s_val) or 1); local eff_gy = (s.gy or 0) * (s.gy_proj and math.abs(c_val) or 1)
                local n_add = eff_gx * c_val - eff_gy * s_val; local q_add = eff_gx * s_val + eff_gy * c_val

                local N0, Q0, M0 = -s.s_local[1], -s.s_local[2], -s.s_local[3]
                local qA, qB = s.q + s.q_A + q_add, s.q + s.q_B + q_add; local nA, nB = s.n + s.n_A + n_add, s.n + s.n_B + n_add
                local pts = render_pts_1; for k_idx=1,#pts do pts[k_idx]=nil end
                local min_val, max_val_ext, best_t, best_px, best_py = 0, 0, 0, px1, py1

                for j = 0, ptsBiegelinie do
                    local t = j / ptsBiegelinie; local x = t * L_m; local val = 0
                    local cas_Q_drop = (s.Q_cas_pts and s.Q_cas_pts[j+1]) or 0
                    local cas_M_drop = (s.M_cas_pts and s.M_cas_pts[j+1]) or 0
                    local cas_N_drop = (s.N_cas_pts and s.N_cas_pts[j+1]) or 0

                    if ansichtsModus == "N" then val = N0 - (nA*x + (nB-nA)*(x^2)/(2*L_m)) - cas_N_drop
                    elseif ansichtsModus == "Q" then val = Q0 - (qA*x + (qB-qA)*(x^2)/(2*L_m)) - cas_Q_drop
                    elseif ansichtsModus == "M" then val = M0 + Q0*x - s.m*x - (qA*(x^2)/2 + (qB-qA)*(x^3)/(6*L_m)) - cas_M_drop
                    elseif ansichtsModus == "U" then val = get_u_val(s, x, L_m, j, nA, nB)
                    elseif ansichtsModus == "W" then
                        local EI = s.EI
                        local c1 = (s.v_local[2] or 0) * EI
                        local c2 = -(s.v_local[3] or 0) * EI
                        local c3 = (s.v_local[5] or 0) * EI
                        local c4 = -(s.v_local[6] or 0) * EI
                        local xi = x / L_m
                        local val_homogen_EI = c1*(1-3*xi^2+2*xi^3) + c2*(x-2*x^2/L_m+x^3/(L_m^2)) + c3*(3*xi^2-2*xi^3) + c4*(-x^2/L_m+x^3/(L_m^2))
                        local v_part_class_EI = (x^2 * (L_m - x)^2) / (120 * L_m) * ((3*L_m - x)*qA + (2*L_m + x)*qB)
                        local v_part_cas_EI = (s.v_cas_pts_EI and s.v_cas_pts_EI[j+1]) or 0
                        val = (val_homogen_EI + v_part_class_EI + v_part_cas_EI) / EI
                    end

                    if math.abs(val) < 1e-5 then val = 0 end
                    local dist = val * drawScale
                    local cur_px = px1 + dx*t + nx*dist
                    local cur_py = py1 + dy*t + ny*dist

                    if ansichtsModus == "W" then
                        local u_val = get_u_val(s, x, L_m, j, nA, nB)
                        cur_px = cur_px + (dx/L)*u_val*drawScale
                        cur_py = cur_py + (dy/L)*u_val*drawScale
                    end

                    if math.abs(val) >= math.abs(max_val_ext) then
                        max_val_ext = val; best_t = t; best_px = cur_px; best_py = cur_py
                    end

                    table.insert(pts, cur_px); table.insert(pts, cur_py)
                    if ansichtsModus ~= "System" and ansichtsModus ~= "E" and ansichtsModus ~= "W" and ansichtsModus ~= "U" and not isPolplan and not isKinematic and not in_pvv_release then gc:setColorRGB(180, 180, 180); gc:drawLine(px1 + dx*t, py1 + dy*t, cur_px, cur_py) end
                end

                if ansichtsModus == "M" then gc:setColorRGB(200, 50, 50) elseif ansichtsModus == "Q" then gc:setColorRGB(50, 150, 50) elseif ansichtsModus == "W" then gc:setColorRGB(200, 0, 200) elseif ansichtsModus == "U" then gc:setColorRGB(255, 120, 0) else gc:setColorRGB(50, 50, 200) end

                if ansichtsModus == "W" or ansichtsModus == "U" then gc:setPen("thin", "smooth") else gc:setPen("thin", "smooth") end
                gc:drawPolyLine(pts); gc:setFont("sansserif", "r", 8); gc:setColorRGB(0, 0, 0)

                local v_start = (ansichtsModus == "N" and N0) or (ansichtsModus == "Q" and Q0) or M0; local v_end = 0
                local cas_Q_end = (s.Q_cas_pts and s.Q_cas_pts[ptsBiegelinie+1]) or 0
                local cas_M_end = (s.M_cas_pts and s.M_cas_pts[ptsBiegelinie+1]) or 0
                local cas_N_end = (s.N_cas_pts and s.N_cas_pts[ptsBiegelinie+1]) or 0

                if ansichtsModus == "N" then v_end = N0 - (nA*L_m + (nB-nA)*(L_m^2)/(2*L_m)) - cas_N_end
                elseif ansichtsModus == "Q" then v_end = Q0 - (qA*L_m + (qB-qA)*(L_m^2)/(2*L_m)) - cas_Q_end
                elseif ansichtsModus == "M" then v_end = M0 + Q0*L_m - s.m*L_m - (qA*(L_m^2)/2 + (qB-qA)*(L_m^3)/(6*L_m)) - cas_M_end
                end

                if ansichtsModus ~= "W" and ansichtsModus ~= "U" then
                if schnittAnzeigeModus ~= "Hover" then
                    gc:drawString(getSymbLabel(s, ansichtsModus, "start", v_start), pts[1] + nx*5, pts[2] + ny*5)
                    gc:drawString(getSymbLabel(s, ansichtsModus, "end", v_end), pts[#pts-1] + nx*5, pts[#pts] + ny*5)
                end
            end

            if ansichtsModus == "W" or ansichtsModus == "U" then
                if math.abs(max_val_ext) > 1e-12 then
                    if ansichtsModus == "W" then
                        gc:setColorRGB(200, 0, 200)
                        gc:fillArc(best_px - 1, best_py - 1, 3, 3, 0, 360)
                    else
                        gc:setColorRGB(255, 120, 0)
                        gc:fillArc(best_px - 2, best_py - 2, 5, 5, 0, 360)
                    end
                    if zeigeMaxWerte then gc:drawString(string.format("max: %.3f mm", max_val_ext*1000), best_px + nx*6, best_py + ny*6) end
                end
            elseif ansichtsModus == "N" or ansichtsModus == "Q" or ansichtsModus == "M" then
                if math.abs(max_val_ext) > 1e-12 then
                    if ansichtsModus == "M" then gc:setColorRGB(200, 50, 50) elseif ansichtsModus == "Q" then gc:setColorRGB(50, 150, 50) else gc:setColorRGB(50, 50, 200) end
                    gc:fillArc(best_px - 2, best_py - 2, 5, 5, 0, 360)
                    if zeigeMaxWerte and best_t > 0.02 and best_t < 0.98 then 
                        gc:setFont("sansserif", "r", 8)
                        gc:drawString(getSymbLabel(s, ansichtsModus, "max", max_val_ext), best_px + nx*6, best_py + ny*6)
                    end
                end
            end
            
            if (ansichtsModus == "M" or ansichtsModus == "N" or ansichtsModus == "Q") then
                local function eval_at_t(t_h)
                    local hover_j = math.floor(t_h * ptsBiegelinie + 0.5)
                    local h_px = pts[hover_j*2 + 1] or pts[1]
                    local h_py = pts[hover_j*2 + 2] or pts[2]
                    local h_x = t_h * L_m
                    local h_val = 0
                    local cas_Q_drop = (s.Q_cas_pts and s.Q_cas_pts[hover_j+1]) or 0
                    local cas_M_drop = (s.M_cas_pts and s.M_cas_pts[hover_j+1]) or 0
                    local cas_N_drop = (s.N_cas_pts and s.N_cas_pts[hover_j+1]) or 0
                    if ansichtsModus == "N" then h_val = N0 - (nA*h_x + (nB-nA)*(h_x^2)/(2*L_m)) - cas_N_drop
                    elseif ansichtsModus == "Q" then h_val = Q0 - (qA*h_x + (qB-qA)*(h_x^2)/(2*L_m)) - cas_Q_drop
                    elseif ansichtsModus == "M" then h_val = M0 + Q0*h_x - s.m*h_x - (qA*(h_x^2)/2 + (qB-qA)*(h_x^3)/(6*L_m)) - cas_M_drop end
                    return h_px, h_py, h_x, h_val
                end
                
                if s.messpunkte then
                    for _, t_m in ipairs(s.messpunkte) do
                        local h_px, h_py, h_x, h_val = eval_at_t(t_m)
                        gc:setColorRGB(0, 150, 0)
                        gc:fillArc(h_px - 3, h_py - 3, 7, 7, 0, 360)
                        gc:setColorRGB(255, 255, 220); gc:fillRect(h_px + nx*10, h_py + ny*10, 100, 16)
                        gc:setColorRGB(0, 0, 0); gc:drawRect(h_px + nx*10, h_py + ny*10, 100, 16)
                        gc:drawString(string.format("X=%.2fm : %.2f", h_x, h_val), h_px + nx*10 + 2, h_py + ny*10)
                    end
                end
                
                if schnittAnzeigeModus == "Hover" and hoverObj == i and hoverTyp == "stab" then
                    local dx_bar, dy_bar = px2 - px1, py2 - py1
                    local L_screen2 = dx_bar*dx_bar + dy_bar*dy_bar
                    if L_screen2 > 0 then
                        local t_h = ((mouseX - px1)*dx_bar + (mouseY - py1)*dy_bar) / L_screen2
                        t_h = math.max(0, math.min(1, t_h))
                        local h_px, h_py, h_x, h_val = eval_at_t(t_h)
                        gc:setColorRGB(255, 0, 0)
                        gc:fillArc(h_px - 3, h_py - 3, 7, 7, 0, 360)
                        gc:setColorRGB(255, 255, 220); gc:fillRect(h_px + nx*10, h_py + ny*10, 100, 16)
                        gc:setColorRGB(0, 0, 0); gc:drawRect(h_px + nx*10, h_py + ny*10, 100, 16)
                        gc:drawString(string.format("X=%.2fm : %.2f", h_x, h_val), h_px + nx*10 + 2, h_py + ny*10)
                    end
                end
            end
            end
        end

        -- ==========================================================
        -- EXPLOSIONSZEICHNUNG: FEINE GELENKKRÄFTE (Anti-Overlap)
        -- ==========================================================
        if isExplosion and s.s_local and L_orig > 0 and not s.is_cut then
            repeat
            if fachwerkModus and isExplosion then
                local ux, uy = dx_orig/L_orig, dy_orig/L_orig
                local startOffset = 5
                local arrowLen = 45
                gc:setColorRGB(0, 150, 0)
                gc:setPen("thin", "smooth")
                
                local val = s.s_local and -s.s_local[1] or 0
                local is_tension = (val >= -1e-7)
                local dir = is_tension and 1 or -1
                if explosionPage == 2 then dir = 1 end
                
                local tailX1 = orig_px1 + ux * startOffset
                local tailY1 = orig_py1 + uy * startOffset  
                local outerX1 = orig_px1 + ux * (startOffset + arrowLen)
                local outerY1 = orig_py1 + uy * (startOffset + arrowLen)
                
                if dir == 1 then drawExplosionArrow(gc, tailX1, tailY1, outerX1, outerY1)
                else drawExplosionArrow(gc, outerX1, outerY1, tailX1, tailY1) end
                
                local lbl
                if explosionPage == 2 then
                    lbl = symbolischer_modus and (s.symb_N_start and fm(s.symb_N_start) or "S"..i) or "S_"..i
                else
                    if symbolischer_modus and s.symb_N_start then
                        local s_str = fm(s.symb_N_start)
                        if dir == -1 and string.sub(s_str, 1, 1) == "-" then
                            s_str = string.sub(s_str, 2)
                        end
                        lbl = s_str
                    else
                        lbl = formatLabel(math.abs(val))
                    end
                end
                gc:setFont("sansserif", "r", 10)
                local tw = gc:getStringWidth(lbl)
                gc:drawString(lbl, outerX1 - tw/2, outerY1 + 5)
                
                local tailX2 = orig_px2 - ux * startOffset
                local tailY2 = orig_py2 - uy * startOffset
                local outerX2 = orig_px2 - ux * (startOffset + arrowLen)
                local outerY2 = orig_py2 - uy * (startOffset + arrowLen)
                
                if dir == 1 then drawExplosionArrow(gc, tailX2, tailY2, outerX2, outerY2)
                else drawExplosionArrow(gc, outerX2, outerY2, tailX2, tailY2) end
                
                gc:drawString(lbl, outerX2 - tw/2, outerY2 + 5)
                
                break
            end
            
            local function isRigidNodeInTS(node_idx, ts)
                if not ts then return true end
                for _idx, st in ipairs(staebe) do
                    if not st.is_cut and (st.k1 == node_idx or st.k2 == node_idx) and glob_ts_scheibe[_idx] == ts then
                        local explA = knoten[st.k1].gelenk or st.gelenk_A or st.n_gelenk_A or st.q_gelenk_A
                        local explB = knoten[st.k2].gelenk or st.gelenk_B or st.n_gelenk_B or st.q_gelenk_B
                        if st.k1 == node_idx and not explA then return true end
                        if st.k2 == node_idx and not explB then return true end
                    end
                end
                return false
            end

            local function getShiftedNodePos(node_idx, ts)
                local orig_x = knoten[node_idx].x * drawPxProMeter + offsetX
                local orig_y = knoten[node_idx].y * drawPxProMeter + offsetY
                if not isExplosion or not ts then return orig_x, orig_y end
                for _idx, st in ipairs(staebe) do
                    if not st.is_cut and (st.k1 == node_idx or st.k2 == node_idx) and glob_ts_scheibe[_idx] == ts then
                        local u1x, u1y, u2x, u2y = getKinematicDisp_Stab(_idx)
                        local anim_f = (0.5 * drawPxProMeter) / (kinematic_max_disp and kinematic_max_disp > 1e-6 and kinematic_max_disp or 1)
                        if st.k1 == node_idx then
                            return orig_x + u1x * anim_f, orig_y + u1y * anim_f
                        else
                            return orig_x + u2x * anim_f, orig_y + u2y * anim_f
                        end
                    end
                end
                return orig_x, orig_y
            end
            
            local ux, uy = dx_orig/L_orig, dy_orig/L_orig
            local nx, ny = -uy, ux

            local Na, Va, Ma = s.s_local[1] or 0, s.s_local[2] or 0, s.s_local[3] or 0
            local Nb, Vb, Mb = s.s_local[4] or 0, s.s_local[5] or 0, s.s_local[6] or 0

            local offsetX_A, offsetY_A, offsetM_A, offsetRx_A, offsetRy_A, offsetRm_A = 0,0,0,0,0,0
            local offsetX_B, offsetY_B, offsetM_B, offsetRx_B, offsetRy_B, offsetRm_B = 0,0,0,0,0,0
            local drawExtA, drawExtB = false, false

            local useLocalA = s.n_gelenk_A or s.q_gelenk_A
            local useLocalB = s.n_gelenk_B or s.q_gelenk_B

            local nodeA_in_ts = (not hovered_ts or (glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts) or isRigidNodeInTS(s.k1, hovered_ts))
            if explodeA and not loadApplied[s.k1] then
                local kn = knoten[s.k1]
                offsetX_A = kn.last_x; offsetY_A = kn.last_y; offsetM_A = kn.last_m
                local isSupp = kn.lager_x or kn.lager_y or kn.lager_m or kn.cx > 0 or kn.cy > 0 or kn.cm > 0
                offsetRx_A = isSupp and kn.Rx_glob or 0; offsetRy_A = isSupp and kn.Ry_glob or 0; offsetRm_A = isSupp and kn.Rm_glob or 0
                if nodeA_in_ts then
                    loadApplied[s.k1] = true; drawExtA = true
                end
            elseif explodeA then
                local kn = knoten[s.k1]
                offsetX_A = kn.last_x; offsetY_A = kn.last_y; offsetM_A = kn.last_m
                local isSupp = kn.lager_x or kn.lager_y or kn.lager_m or kn.cx > 0 or kn.cy > 0 or kn.cm > 0
                offsetRx_A = isSupp and kn.Rx_glob or 0; offsetRy_A = isSupp and kn.Ry_glob or 0; offsetRm_A = isSupp and kn.Rm_glob or 0
            end

            local nodeB_in_ts = (not hovered_ts or (glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts) or isRigidNodeInTS(s.k2, hovered_ts))
            if explodeB and not loadApplied[s.k2] then
                local kn = knoten[s.k2]
                offsetX_B = kn.last_x; offsetY_B = kn.last_y; offsetM_B = kn.last_m
                local isSupp = kn.lager_x or kn.lager_y or kn.lager_m or kn.cx > 0 or kn.cy > 0 or kn.cm > 0
                offsetRx_B = isSupp and kn.Rx_glob or 0; offsetRy_B = isSupp and kn.Ry_glob or 0; offsetRm_B = isSupp and kn.Rm_glob or 0
                if nodeB_in_ts then
                    loadApplied[s.k2] = true; drawExtB = true
                end
            elseif explodeB then
                local kn = knoten[s.k2]
                offsetX_B = kn.last_x; offsetY_B = kn.last_y; offsetM_B = kn.last_m
                local isSupp = kn.lager_x or kn.lager_y or kn.lager_m or kn.cx > 0 or kn.cy > 0 or kn.cm > 0
                offsetRx_B = isSupp and kn.Rx_glob or 0; offsetRy_B = isSupp and kn.Ry_glob or 0; offsetRm_B = isSupp and kn.Rm_glob or 0
            end

            local uxA, uyA = dx_orig/L_orig, dy_orig/L_orig
            local nxA, nyA = -uyA, uxA
            local uxB, uyB = dx_orig/L_orig, dy_orig/L_orig
            local nxB, nyB = -uyB, uxB
            
            if (s.bogen_r or 0) ~= 0 then
                local true_L = (L_orig / drawPxProMeter)
                local R = math.abs(s.bogen_r)
                local sgn = s.bogen_r > 0 and -1 or 1
                local function getTang(t)
                    local xl = (t - 0.5) * true_L
                    local denom = math.sqrt(math.max(1e-6, R^2 - xl^2))
                    local tx_l, ty_l = 1, -sgn * (xl / denom)
                    local len = math.sqrt(tx_l^2 + ty_l^2)
                    tx_l, ty_l = tx_l/len, ty_l/len
                    local t_gx = tx_l * (dx_orig/L_orig) - ty_l * (dy_orig/L_orig)
                    local t_gy = tx_l * (dy_orig/L_orig) + ty_l * (dx_orig/L_orig)
                    return t_gx, t_gy, -t_gy, t_gx
                end
                uxA, uyA, nxA, nyA = getTang(0)
                uxB, uyB, nxB, nyB = getTang(1)
            end

            local Fx_a = Na * uxA + Va * nxA - (offsetX_A + offsetRx_A)
            local Fy_a = Na * uyA + Va * nyA - (offsetY_A + offsetRy_A)
            local Fx_b = Nb * uxB + Vb * nxB - (offsetX_B + offsetRx_B)
            local Fy_b = Nb * uyB + Vb * nyB - (offsetY_B + offsetRy_B)

            local N_a_proj = Fx_a * uxA + Fy_a * uyA; local V_a_proj = Fx_a * nxA + Fy_a * nyA
            local N_b_proj = Fx_b * uxB + Fy_b * uyB; local V_b_proj = Fx_b * nxB + Fy_b * nyB

            local M_a_disp = -(Ma - (offsetM_A + offsetRm_A))
            local M_b_disp = Mb - (offsetM_B + offsetRm_B)

            local s_Fx_a, s_Fy_a, s_Fx_b, s_Fy_b = nil, nil, nil, nil
            if symbolischer_modus then
                s_Fx_a = s.symb_Fx_a or s.symb_N_start
                s_Fy_a = s.symb_Fy_a or s.symb_Q_start
                s_Fx_b = s.symb_Fx_b or s.symb_N_end
                s_Fy_b = s.symb_Fy_b or s.symb_Q_end
            end

            local function getNumTS(node_idx)
                local ang_count, rigid_count = 0, 0
                if knoten[node_idx].gelenk then
                    local count = 0
                    for _, ts in ipairs(staebe) do
                        if not ts.is_cut and (ts.k1 == node_idx or ts.k2 == node_idx) then count = count + 1 end
                    end
                    return count
                else
                    for _, ts in ipairs(staebe) do
                        if not ts.is_cut then
                            if ts.k1 == node_idx then
                                if ts.gelenk_A or ts.n_gelenk_A or ts.q_gelenk_A then ang_count = ang_count + 1 else rigid_count = rigid_count + 1 end
                            elseif ts.k2 == node_idx then
                                if ts.gelenk_B or ts.n_gelenk_B or ts.q_gelenk_B then ang_count = ang_count + 1 else rigid_count = rigid_count + 1 end
                            end
                        end
                    end
                    return ang_count + (rigid_count > 0 and 1 or 0)
                end
            end
            local lblSuffixA = getNumTS(s.k1) > 2 and ("s"..(s.ts_scheibe or i)) or ""
            local lblSuffixB = getNumTS(s.k2) > 2 and ("s"..(s.ts_scheibe or i)) or ""
            local function getFlipMultiplier(node_idx, s_idx)
                if knoten[node_idx].gelenk then
                    return 1
                end

                local r1
                local conn = {}
                for j, ts in ipairs(staebe) do
                    if ts.k1 == node_idx or ts.k2 == node_idx then table.insert(conn, j) end
                end
                
                for _, j in ipairs(conn) do
                    local ts = staebe[j]
                    if (ts.k1 == node_idx and (ts.gelenk_A or ts.n_gelenk_A or ts.q_gelenk_A)) or
                       (ts.k2 == node_idx and (ts.gelenk_B or ts.n_gelenk_B or ts.q_gelenk_B)) then
                        r1 = j
                        break
                    end
                end
                
                if not r1 or s_idx == r1 then
                    return 1
                end
                
                local r1_is_k1 = (staebe[r1].k1 == node_idx)
                local s_is_k1 = (staebe[s_idx].k1 == node_idx)
                
                if r1_is_k1 == s_is_k1 then
                    return -1
                else
                    return 1
                end
            end
            
            local flipA = getFlipMultiplier(s.k1, i)
            local flipB = getFlipMultiplier(s.k2, i)
            local isHingeA = s.n_gelenk_A or s.q_gelenk_A or s.gelenk_A or knoten[s.k1].gelenk
            local prefixN_A = (explosionPage == 2 and isHingeA) and ("Gn_"..getHingeNumber(s.k1)..lblSuffixA.." = ") or "N = "
            local prefixQ_A = (explosionPage == 2 and isHingeA) and ("Gq_"..getHingeNumber(s.k1)..lblSuffixA.." = ") or "Q = "
            local prefixM_A = (explosionPage == 2 and isHingeA) and ("Gm_"..getHingeNumber(s.k1)..lblSuffixA.." = ") or "M = "
            local isMHingeA = knoten[s.k1].gelenk or s.gelenk_A

            if explodeA and (not hovered_ts or (glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts) or isRigidNodeInTS(s.k1, hovered_ts)) then
                local val_N, val_Q, val_h, val_v
                if not hovered_ts or (glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts) then
                    if useLocalA then
                        val_N = -N_a_proj; val_Q = -V_a_proj
                        if not s.n_gelenk_A then drawFBDArrow(gc, val_N, -ux, -uy, px1, py1, prefixN_A, nil, symbolischer_modus and fm(s.symb_N_start) or nil, explosionPage == 2) end
                        if not s.q_gelenk_A then drawFBDArrow(gc, val_Q, -nx, -ny, px1, py1, prefixQ_A, nil, symbolischer_modus and fm(s.symb_Q_start) or nil, explosionPage == 2) end
                    else
                        val_h = -Fx_a; val_v = -Fy_a
                        drawFBDArrow(gc, val_h, -1, 0, px1, py1, "h = ", "Gx_"..getHingeNumber(s.k1)..lblSuffixA, symbolischer_modus and fm(s_Fx_a) or nil, explosionPage == 2, flipA)
                        drawFBDArrow(gc, val_v, 0, -1, px1, py1, "v = ", "Gy_"..getHingeNumber(s.k1)..lblSuffixA, symbolischer_modus and fm(s_Fy_a) or nil, explosionPage == 2, flipA)
                    end

                    if not isMHingeA then
                        if math.abs(M_a_disp) > 1e-4 or explosionPage == 2 then
                            if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(0, 150, 0) end
                            gc:setPen("thin", "smooth"); drawMoment(gc, px1, py1, 16, M_a_disp > 0)
                            gc:setFont("sansserif", "r", 10)
                            local label_m
                            if explosionPage == 2 then
                                label_m = prefixM_A:gsub(" = ", "")
                            else
                                local m_lbl = symbolischer_modus and fm(s.symb_Ma_disp) or formatLabel(math.abs(M_a_disp))
                                label_m = prefixM_A .. m_lbl
                            end
                            gc:drawString(label_m, px1 - ux*45 - 20, py1 - uy*45 - 10)
                        end
                    end
                end

                if drawExtA then
                    if offsetX_A ~= 0 or offsetY_A ~= 0 or offsetM_A ~= 0 then
                        if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(255, 50, 50) end
                        gc:setPen("thin", "smooth")
                        if fachwerkModus and explosionPage == 2 then
                            drawReactionArrow(gc, -N_a_proj, ux, uy, px1, py1, "S" .. i, "S" .. i)
                        else
                            if offsetX_A ~= 0 then local d = offsetX_A > 0 and 1 or -1; drawReactionArrow(gc, offsetX_A, 1, 0, px1, py1, "G"..s.k1.."_h", "G"..s.k1.."_h", symbolischer_modus and fm(knoten[s.k1].x_str) or nil) end
                            if offsetY_A ~= 0 then local d = offsetY_A > 0 and 1 or -1; drawReactionArrow(gc, offsetY_A, 0, 1, px1, py1, "G"..s.k1.."_v", "G"..s.k1.."_v", symbolischer_modus and fm(knoten[s.k1].y_str) or nil) end
                        end
                        if offsetM_A ~= 0 then drawMoment(gc, px1, py1, 24, offsetM_A < 0) end
                    end
                    local isSuppNode_A = knoten[s.k1].lager_x or knoten[s.k1].lager_y or knoten[s.k1].lager_m or (knoten[s.k1].cx and knoten[s.k1].cx > 0) or (knoten[s.k1].cy and knoten[s.k1].cy > 0) or (knoten[s.k1].cm and knoten[s.k1].cm > 0)
                    if math.abs(offsetRx_A) > 1e-4 or math.abs(offsetRy_A) > 1e-4 or math.abs(offsetRm_A) > 1e-4 or (explosionPage == 2 and isSuppNode_A) then
                        local kn = knoten[s.k1]
                        local r = math.rad(kn.winkel or 0)
                        local cw, sw = math.cos(r), math.sin(r)
                        if math.abs(kn.R_xi) > 1e-4 or (explosionPage == 2 and (kn.lager_x or (kn.cx and kn.cx > 0))) then drawReactionArrow(gc, kn.R_xi, cw, -sw, px1, py1, "H = ", string.char(64 + s.k1).."_h", symbolischer_modus and fm(kn.symb_R_xi) or nil, explosionPage == 2) end
                        if math.abs(kn.R_eta) > 1e-4 or (explosionPage == 2 and (kn.lager_y or (kn.cy and kn.cy > 0))) then drawReactionArrow(gc, kn.R_eta, -sw, -cw, px1, py1, "V = ", string.char(64 + s.k1).."_v", symbolischer_modus and fm(kn.symb_R_eta) or nil, explosionPage == 2) end
                        if math.abs(offsetRm_A) > 1e-4 or (explosionPage == 2 and (kn.lager_m or (kn.cm and kn.cm > 0))) then
                            if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(0, 0, 255) end
                            gc:setPen("thin", "smooth"); drawMoment(gc, px1, py1, 28, offsetRm_A < 0)
                            gc:setFont("sansserif", "r", 8); gc:drawString("M = " .. formatLabel(math.abs(offsetRm_A)), px1 + 22, py1 + 22)
                        end
                    end
                end

                local should_draw_A = false
                if not knoten[s.k1].gelenk then
                    if explodeA and not is_only_rod_A then
                        should_draw_A = (not hovered_ts or isRigidNodeInTS(s.k1, hovered_ts))
                    else
                        should_draw_A = (not hovered_ts or (glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts))
                    end
                end
                
                if should_draw_A then
                    local draw_orig_px1, draw_orig_py1 = orig_px1, orig_py1
                    if isExplosion and hovered_ts and isRigidNodeInTS(s.k1, hovered_ts) then
                        draw_orig_px1, draw_orig_py1 = getShiftedNodePos(s.k1, hovered_ts)
                    end

                    if useLocalA then
                        if not s.n_gelenk_A then drawFBDArrow(gc, -(-N_a_proj), -ux, -uy, draw_orig_px1, draw_orig_py1, prefixN_A, nil, symbolischer_modus and fm(s.symb_N_start) or nil, explosionPage == 2, flipA and -flipA or nil) end
                        if not s.q_gelenk_A then drawFBDArrow(gc, -(-V_a_proj), -nx, -ny, draw_orig_px1, draw_orig_py1, prefixQ_A, nil, symbolischer_modus and fm(s.symb_Q_start) or nil, explosionPage == 2, flipA and -flipA or nil) end
                    else
                        drawFBDArrow(gc, -(-Fx_a), -1, 0, draw_orig_px1, draw_orig_py1, "h = ", "Gx_"..getHingeNumber(s.k1)..lblSuffixA, symbolischer_modus and fm(s_Fx_a) or nil, explosionPage == 2, flipA and -flipA or nil)
                        drawFBDArrow(gc, -(-Fy_a), 0, -1, draw_orig_px1, draw_orig_py1, "v = ", "Gy_"..getHingeNumber(s.k1)..lblSuffixA, symbolischer_modus and fm(s_Fy_a) or nil, explosionPage == 2, flipA and -flipA or nil)
                    end

                    if not s.gelenk_A then
                        if math.abs(M_a_disp) > 1e-4 or explosionPage == 2 then
                            if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(0, 150, 0) end
                            gc:setPen("thin", "smooth"); drawMoment(gc, draw_orig_px1, draw_orig_py1, 16, M_a_disp <= 0)
                            gc:setFont("sansserif", "r", 10)
                            local label_m
                            if explosionPage == 2 then
                                label_m = prefixM_A:gsub(" = ", "")
                            else
                                local m_lbl = symbolischer_modus and fm(s.symb_Ma_disp) or formatLabel(math.abs(M_a_disp))
                                label_m = prefixM_A .. m_lbl
                            end
                            gc:drawString(label_m, orig_px1 + ux*30, orig_py1 + uy*30)
                        end
                    end
                end
            end

            local isHingeB = s.n_gelenk_B or s.q_gelenk_B or s.gelenk_B or knoten[s.k2].gelenk
            local prefixN_B = (explosionPage == 2 and isHingeB) and ("Gn_"..getHingeNumber(s.k2)..lblSuffixB.." = ") or "N = "
            local prefixQ_B = (explosionPage == 2 and isHingeB) and ("Gq_"..getHingeNumber(s.k2)..lblSuffixB.." = ") or "Q = "
            local prefixM_B = (explosionPage == 2 and isHingeB) and ("Gm_"..getHingeNumber(s.k2)..lblSuffixB.." = ") or "M = "
            local isMHingeB = knoten[s.k2].gelenk or s.gelenk_B
            if explodeB and (not hovered_ts or (glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts) or isRigidNodeInTS(s.k2, hovered_ts)) then
                local val_N, val_Q, val_h, val_v
                if not hovered_ts or (glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts) then
                    if useLocalB then
                        val_N = N_b_proj; val_Q = V_b_proj
                        if not s.n_gelenk_B then drawFBDArrow(gc, val_N, ux, uy, px2, py2, prefixN_B, nil, symbolischer_modus and fm(s.symb_N_end) or nil, explosionPage == 2) end
                        if not s.q_gelenk_B then drawFBDArrow(gc, val_Q, nx, ny, px2, py2, prefixQ_B, nil, symbolischer_modus and fm(s.symb_Q_end) or nil, explosionPage == 2) end
                    else
                        val_h = Fx_b; val_v = Fy_b
                        drawFBDArrow(gc, val_h, 1, 0, px2, py2, "h = ", "Gx_"..getHingeNumber(s.k2)..lblSuffixB, symbolischer_modus and fm(s_Fx_b) or nil, explosionPage == 2, flipB)
                        drawFBDArrow(gc, val_v, 0, 1, px2, py2, "v = ", "Gy_"..getHingeNumber(s.k2)..lblSuffixB, symbolischer_modus and fm(s_Fy_b) or nil, explosionPage == 2, flipB)
                    end

                    if not isMHingeB then
                        if math.abs(M_b_disp) > 1e-4 or explosionPage == 2 then
                            if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(0, 150, 0) end
                            gc:setPen("thin", "smooth"); drawMoment(gc, px2, py2, 16, M_b_disp < 0)
                            gc:setFont("sansserif", "r", 10)
                            local label_m
                            if explosionPage == 2 then
                                label_m = prefixM_B:gsub(" = ", "")
                            else
                                local m_lbl = symbolischer_modus and fm(s.symb_Ma_disp) or formatLabel(math.abs(M_b_disp))
                                label_m = prefixM_B .. m_lbl
                            end
                            gc:drawString(label_m, px2 + ux*45, py2 + uy*45)
                        end
                    end
                end

                if drawExtB then
                    if offsetX_B ~= 0 or offsetY_B ~= 0 or offsetM_B ~= 0 then
                        if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(255, 50, 50) end
                        gc:setPen("thin", "smooth")
                        if fachwerkModus and explosionPage == 2 then
                            drawReactionArrow(gc, -N_b_proj, ux, uy, px2, py2, "S" .. i, "S" .. i)
                        else
                            if offsetX_B ~= 0 then local d = offsetX_B > 0 and 1 or -1; drawReactionArrow(gc, offsetX_B, 1, 0, px2, py2, "G"..s.k2.."_h", "G"..s.k2.."_h", symbolischer_modus and fm(knoten[s.k2].x_str) or nil) end
                            if offsetY_B ~= 0 then local d = offsetY_B > 0 and 1 or -1; drawReactionArrow(gc, offsetY_B, 0, 1, px2, py2, "G"..s.k2.."_v", "G"..s.k2.."_v", symbolischer_modus and fm(knoten[s.k2].y_str) or nil) end
                        end
                        if offsetM_B ~= 0 then drawMoment(gc, px2, py2, 24, offsetM_B < 0) end
                    end
                    local isSuppNode_B = knoten[s.k2].lager_x or knoten[s.k2].lager_y or knoten[s.k2].lager_m or (knoten[s.k2].cx and knoten[s.k2].cx > 0) or (knoten[s.k2].cy and knoten[s.k2].cy > 0) or (knoten[s.k2].cm and knoten[s.k2].cm > 0)
                    if math.abs(offsetRx_B) > 1e-4 or math.abs(offsetRy_B) > 1e-4 or math.abs(offsetRm_B) > 1e-4 or (explosionPage == 2 and isSuppNode_B) then
                        local kn = knoten[s.k2]
                        local r = math.rad(kn.winkel or 0)
                        local cw, sw = math.cos(r), math.sin(r)
                        if math.abs(kn.R_xi) > 1e-4 or (explosionPage == 2 and (kn.lager_x or (kn.cx and kn.cx > 0))) then drawReactionArrow(gc, kn.R_xi, cw, -sw, px2, py2, "H = ", string.char(64 + s.k2).."_h", symbolischer_modus and fm(kn.symb_R_xi) or nil, explosionPage == 2) end
                        if math.abs(kn.R_eta) > 1e-4 or (explosionPage == 2 and (kn.lager_y or (kn.cy and kn.cy > 0))) then drawReactionArrow(gc, kn.R_eta, -sw, -cw, px2, py2, "V = ", string.char(64 + s.k2).."_v", symbolischer_modus and fm(kn.symb_R_eta) or nil, explosionPage == 2) end
                        if math.abs(offsetRm_B) > 1e-4 or (explosionPage == 2 and (kn.lager_m or (kn.cm and kn.cm > 0))) then
                            if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(0, 0, 255) end
                            gc:setPen("thin", "smooth"); drawMoment(gc, px2, py2, 28, offsetRm_B < 0)
                            gc:setFont("sansserif", "r", 8); gc:drawString("M = " .. formatLabel(math.abs(offsetRm_B)), px2 + 22, py2 + 22)
                        end
                    end
                end

                local should_draw_B = false
                if not knoten[s.k2].gelenk then
                    if explodeB and not is_only_rod_B then
                        should_draw_B = (not hovered_ts or isRigidNodeInTS(s.k2, hovered_ts))
                    else
                        should_draw_B = (not hovered_ts or (glob_ts_scheibe and glob_ts_scheibe[i] == hovered_ts))
                    end
                end
                
                if should_draw_B then
                    local draw_orig_px2, draw_orig_py2 = orig_px2, orig_py2
                    if isExplosion and hovered_ts and isRigidNodeInTS(s.k2, hovered_ts) then
                        draw_orig_px2, draw_orig_py2 = getShiftedNodePos(s.k2, hovered_ts)
                    end

                    if useLocalB then
                        if not s.n_gelenk_B then drawFBDArrow(gc, -(N_b_proj), ux, uy, draw_orig_px2, draw_orig_py2, prefixN_B, nil, symbolischer_modus and fm(s.symb_N_end) or nil, explosionPage == 2, flipB and -flipB or nil) end
                        if not s.q_gelenk_B then drawFBDArrow(gc, -(V_b_proj), nx, ny, draw_orig_px2, draw_orig_py2, prefixQ_B, nil, symbolischer_modus and fm(s.symb_Q_end) or nil, explosionPage == 2, flipB and -flipB or nil) end
                    else
                        drawFBDArrow(gc, -(Fx_b), 1, 0, draw_orig_px2, draw_orig_py2, "h = ", "Gx_"..getHingeNumber(s.k2)..lblSuffixB, symbolischer_modus and fm(s_Fx_b) or nil, explosionPage == 2, flipB and -flipB or nil)
                        drawFBDArrow(gc, -(Fy_b), 0, 1, draw_orig_px2, draw_orig_py2, "v = ", "Gy_"..getHingeNumber(s.k2)..lblSuffixB, symbolischer_modus and fm(s_Fy_b) or nil, explosionPage == 2, flipB and -flipB or nil)
                    end

                    if not s.gelenk_B then
                        if math.abs(M_b_disp) > 1e-4 or explosionPage == 2 then
                            if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(0, 150, 0) end
                            gc:setPen("thin", "smooth"); drawMoment(gc, draw_orig_px2, draw_orig_py2, 16, M_b_disp >= 0)
                            gc:setFont("sansserif", "r", 10)
                            local label_m
                            if explosionPage == 2 then
                                label_m = prefixM_B:gsub(" = ", "")
                            else
                                local m_lbl = symbolischer_modus and fm(s.symb_Mb_disp) or formatLabel(math.abs(M_b_disp))
                                label_m = prefixM_B .. m_lbl
                            end
                            gc:drawString(label_m, orig_px2 - ux*30, orig_py2 - uy*30)
                        end
                    end
                end
            end
            until true
        end
    end

    gc:setPen("thin", "smooth")
    if ansichtsModus ~= "W" then
        for i, k in ipairs(knoten) do
            local node_in_ts = true
            if hovered_ts and glob_ts_scheibe then
                node_in_ts = false
                for _, ns in ipairs(staebe) do
                    if (ns.k1 == i or ns.k2 == i) and glob_ts_scheibe[_] == hovered_ts then
                        node_in_ts = true; break
                    end
                end
            end
            local hide_node = not node_in_ts and ansichtsModus == "E"
            
            if not hide_node then
                local px, py = k.x * drawPxProMeter + offsetX, k.y * drawPxProMeter + offsetY
                if isKinematic then
                    local ux, uy = getKinematicDisp(i)
                    local anim_f = (0.5 * drawPxProMeter) / (kinematic_max_disp and kinematic_max_disp > 1e-6 and kinematic_max_disp or 1)
                    px = px + ux * anim_f
                    py = py + uy * anim_f
                end
                
                if isExplosion then
                    local attach_s = nil
                    local attach_side = 0
                    for _, s in ipairs(staebe) do
                        if s.k1 == i and not s.is_cut then
                            local explodeA = knoten[s.k1].gelenk
                            if explodeA then attach_s = s; attach_side = 1; break end
                        elseif s.k2 == i and not s.is_cut then
                            local explodeB = knoten[s.k2].gelenk
                            if explodeB then attach_s = s; attach_side = 2; break end
                        end
                    end
                    if attach_s and not (fachwerkModus and isExplosion) then
                        local s = attach_s
                        local side = attach_side
                        local px1, py1 = knoten[s.k1].x * drawPxProMeter + offsetX, knoten[s.k1].y * drawPxProMeter + offsetY
                        local px2, py2 = knoten[s.k2].x * drawPxProMeter + offsetX, knoten[s.k2].y * drawPxProMeter + offsetY
                        local dx_orig, dy_orig = px2 - px1, py2 - py1
                        local L_orig = math.sqrt(dx_orig^2 + dy_orig^2)
                        if L_orig > 0 then
                            local ux, uy = dx_orig/L_orig, dy_orig/L_orig
                            local expl_gap = math.min(1.5 * drawPxProMeter, L_orig * 0.35)
                            local gap = 0
                            if side == 1 then
                                if s.gelenk_A then gap = 6 end
                                if s.q_gelenk_A then gap = 10 end
                                if s.n_gelenk_A then gap = 12 end
                                px = px + ux * (gap + expl_gap)
                                py = py + uy * (gap + expl_gap)
                            else
                                if s.gelenk_B then gap = 6 end
                                if s.q_gelenk_B then gap = 10 end
                                if s.n_gelenk_B then gap = 12 end
                                px = px - ux * (gap + expl_gap)
                                py = py - uy * (gap + expl_gap)
                            end
                        end
                    end
                end
        
                if k.gelenk and (not isExplosion or fachwerkModus) then
                    gc:setPen("thin", "smooth")
                    gc:setColorRGB(255, 255, 255); gc:fillArc(px - 4, py - 4, 8, 8, 0, 360)
                    gc:setColorRGB(100, 100, 100); gc:drawArc(px - 4, py - 4, 8, 8, 0, 360)
                elseif ansichtsModus ~= "W" and ansichtsModus ~= "U" and not isPolplan then
                    local all_conn = {}
                    local hinged_conn = {}
                    for _, s in ipairs(staebe) do
                        if s.k1 == i then
                            local dx, dy = knoten[s.k2].x - k.x, knoten[s.k2].y - k.y
                            local ang = math.atan2(-dy, dx)
                            table.insert(all_conn, ang)
                            if s.gelenk_A then table.insert(hinged_conn, ang) end
                        elseif s.k2 == i then
                            local dx, dy = knoten[s.k1].x - k.x, knoten[s.k1].y - k.y
                            local ang = math.atan2(-dy, dx)
                            table.insert(all_conn, ang)
                            if s.gelenk_B then table.insert(hinged_conn, ang) end
                        end
                    end
                    if #hinged_conn > 0 then
                        gc:setPen("thin", "smooth"); gc:setColorRGB(100, 100, 100)
                        for _, A in ipairs(hinged_conn) do
                            local min_pos_delta = math.pi / 2
                            local max_neg_delta = -math.pi / 2
                            
                            local found_pos = false
                            local found_neg = false
                            local best_pos = 2 * math.pi
                            local best_neg = -2 * math.pi
                            
                            for _, B in ipairs(all_conn) do
                                local delta = B - A
                                delta = (delta + math.pi) % (2 * math.pi) - math.pi
                                
                                if delta > 1e-4 then
                                    if delta < best_pos then
                                        best_pos = delta
                                        found_pos = true
                                    end
                                elseif delta < -1e-4 then
                                    if delta > best_neg then
                                        best_neg = delta
                                        found_neg = true
                                    end
                                end
                            end
                            
                            if found_pos then min_pos_delta = best_pos end
                            if found_neg then max_neg_delta = best_neg end
                            
                            local start_ang = A + max_neg_delta
                            local sweep = min_pos_delta - max_neg_delta
                            gc:drawArc(px - 6, py - 6, 12, 12, math.deg(start_ang), math.deg(sweep))
                        end
                    end
                end

                if modusText == "System" or modusText == "PvV" or (isExplosion and not loadApplied[i]) then
                    if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(255, 50, 50) end
                    local lx = k.last_x or 0
                    local ly = k.last_y or 0
                    local fx, fy = 0, 0
                    if lx ~= 0 or ly ~= 0 then
                        local rw = math.rad(-(k.last_w or 0))
                        local cl, sl = math.cos(rw), math.sin(rw)
                        fx = lx * cl - ly * sl
                        fy = lx * sl + ly * cl
                        local res = math.sqrt(fx*fx + fy*fy)
                        if res > 1e-4 then
                            local ux, uy = fx / res, fy / res
                            drawArrow(gc, px - 40*ux, py - 40*uy, px - 10*ux, py - 10*uy)
                            gc:setFont("sansserif", "r", 8)
                            local lbl_x = (symbolischer_modus and k.last_x_str) and fm(k.last_x_str) or formatLabel(math.abs(lx))
                            local lbl_y = (symbolischer_modus and k.last_y_str) and fm(k.last_y_str) or formatLabel(math.abs(ly))
                            local lbl = ""
                            if math.abs(lx) > 1e-4 and math.abs(ly) > 1e-4 then lbl = lbl_x .. ", " .. lbl_y
                            elseif math.abs(lx) > 1e-4 then lbl = lbl_x
                            else lbl = lbl_y end
                            gc:drawString(lbl, px - 45*ux, py - 45*uy - 10)
                        end
                    end
                    if k.last_m ~= 0 then 
                        drawMoment(gc, px, py, 22, k.last_m < 0) 
                        gc:setFont("sansserif", "r", 8)
                        local lbl_m = (symbolischer_modus and k.last_m_str) and fm(k.last_m_str) or formatLabel(math.abs(k.last_m))
                        gc:drawString(lbl_m, px + 25, py - 25)
                    end
                    
                    if modusText == "PvV" then
                        local k_ux, k_uy = getKinematicDisp(i)
                        local anim_f = (0.5 * drawPxProMeter) / (kinematic_max_disp and kinematic_max_disp > 1e-6 and kinematic_max_disp or 1)
                        
                        local k_phi = getKinematicRot and getKinematicRot(i) or 0
                        local k_scheibe = kinematic_states and kinematic_states[i] and kinematic_states[i].scheibe or 1
                        local phi_abs = math.abs(k_phi)
                        local function formatDelta(lbl, val)
                            if phi_abs > 1e-4 then 
                                return string.format("%s = %.2f * φ_0", lbl, math.abs(val)/phi_abs)
                            else 
                                local real_lbl = (k_scheibe and kinematic_disk_states and kinematic_disk_states[k_scheibe] and kinematic_disk_states[k_scheibe].type == "trans") and string.format("δ_%d", k_scheibe) or lbl
                                return string.format("%s = %.2f", real_lbl, math.abs(val)) 
                            end
                        end
                        
                        if math.abs(fx * k_ux) > 1e-4 then
                            gc:setColorRGB(200, 0, 200)
                            local disp_px = k_ux * anim_f
                            drawArrow(gc, px - disp_px, py, px, py)
                            gc:setFont("sansserif", "r", 8)
                            gc:drawString(formatDelta("δ_x", k_ux), px - disp_px, py - 10)
                        end
                        if math.abs(fy * k_uy) > 1e-4 then
                            gc:setColorRGB(200, 0, 200)
                            local disp_py = k_uy * anim_f
                            drawArrow(gc, px, py - disp_py, px, py)
                            gc:setFont("sansserif", "r", 8)
                            gc:drawString(formatDelta("δ_y", k_uy), px + 5, py - disp_py - 10)
                        end
                        local r = math.rad(k.winkel or 0)
                        local cw, sw = math.cos(r), math.sin(r)
                        
                        local is_released_H = pvv_released_binding and pvv_released_binding.node == i and pvv_released_binding.type == "lager_x"
                        if is_released_H or (k.lager_x and math.abs(k.R_xi or 0) > 1e-4) then
                            local u_H = k_ux * cw - k_uy * sw
                            if is_released_H or math.abs(k.R_xi * u_H) > 1e-4 then
                                gc:setColorRGB(200, 0, 200)
                                local disp_H = u_H * anim_f
                                local dx, dy = cw * disp_H, -sw * disp_H
                                drawArrow(gc, px - dx, py - dy, px, py)
                                gc:setFont("sansserif", "r", 8)
                                gc:drawString(formatDelta("δ_H", u_H), px - dx, py - dy - 10)
                            end
                        end
                        
                        local is_released_V = pvv_released_binding and pvv_released_binding.node == i and pvv_released_binding.type == "lager_y"
                        if is_released_V or (k.lager_y and math.abs(k.R_eta or 0) > 1e-4) then
                            local u_V = k_ux * sw + k_uy * cw
                            if is_released_V or math.abs(k.R_eta * u_V) > 1e-4 then
                                gc:setColorRGB(200, 0, 200)
                                local disp_V = u_V * anim_f
                                local dx, dy = sw * disp_V, cw * disp_V
                                drawArrow(gc, px - dx, py - dy, px, py)
                                gc:setFont("sansserif", "r", 8)
                                gc:drawString(formatDelta("δ_V", u_V), px - dx, py - dy - 10)
                            end
                        end
                    end
                end

                if isExplosion and not loadApplied[i] and node_in_ts then
                    local isSupp = k.lager_x or k.lager_y or k.lager_m or k.cx > 0 or k.cy > 0 or k.cm > 0
                    if isSupp then
                        local s_Rx, s_Ry, s_Rm
                        if symbolischer_modus then
                            for _, st in ipairs(staebe) do
                                if st.k1 == i or st.k2 == i then
                                    local dx = knoten[st.k2].x - knoten[st.k1].x
                                    local dy = knoten[st.k2].y - knoten[st.k1].y
                                    local L_len = math.sqrt(dx^2 + dy^2)
                                    if L_len > 0 then
                                        local uX, uY = dx/L_len, dy/L_len
                                        local nX, nY = -uY, uX
                                        if st.k1 == i then
                                            s_Rx = (math.abs(uX) > 0.5) and st.symb_N_start or st.symb_Q_start
                                            s_Ry = (math.abs(nY) > 0.5) and st.symb_Q_start or st.symb_N_start
                                            s_Rm = st.symb_M_start
                                            break
                                        elseif st.k2 == i then
                                            s_Rx = (math.abs(uX) > 0.5) and st.symb_N_end or st.symb_Q_end
                                            s_Ry = (math.abs(nY) > 0.5) and st.symb_Q_end or st.symb_N_end
                                            s_Rm = st.symb_M_end
                                            break
                                        end
                                    end
                                end
                            end
                        end

                        local r = math.rad(k.winkel or 0)
                        local cw, sw = math.cos(r), math.sin(r)
                        if orig_ansichtsModus ~= "N" and orig_ansichtsModus ~= "Q" and orig_ansichtsModus ~= "M" and not ansicht_ausgeblendet then
                            if k.lager_x and (math.abs(k.R_xi or 0) > 1e-4 or explosionPage == 2) then drawReactionArrow(gc, k.R_xi or 0, cw, -sw, px, py, "H = ", getSuppLetter(i).."_h", symbolischer_modus and fm(k.symb_R_xi) or nil, explosionPage == 2) end
                            if k.lager_y and (math.abs(k.R_eta or 0) > 1e-4 or explosionPage == 2) then drawReactionArrow(gc, k.R_eta or 0, -sw, -cw, px, py, "V = ", getSuppLetter(i).."_v", symbolischer_modus and fm(k.symb_R_eta) or nil, explosionPage == 2) end
                            if k.lager_m and (math.abs(k.R_m or 0) > 1e-4 or explosionPage == 2) then
                                if autoKGV and KGV_Zustand > 0 then gc:setColorRGB(200, 0, 200) else gc:setColorRGB(0, 0, 255) end
                                gc:setPen("thin", "smooth")
                                drawMoment(gc, px, py, 28, k.R_m < 0)
                                gc:setFont("sansserif", "r", 9)
                                local m_lbl = ""
                                if explosionPage == 2 then
                                    m_lbl = "M_" .. getSuppLetter(i)
                                else
                                    m_lbl = "M = " .. (symbolischer_modus and fm(k.symb_Rm) or formatLabel(math.abs(k.R_m)))
                                end
                                gc:drawString(m_lbl, px + 22, py + 22)
                            end
                        end
                    end
                end

                if k.cx > 0 or k.cy > 0 or k.cm > 0 then
                    gc:setColorRGB(100, 220, 100); gc:setPen("thin", "smooth")
                    if k.cx > 0 then drawZigZag(gc, px, py, k.f_winkel or 0) end
                    if k.cy > 0 then drawZigZag(gc, px, py, (k.f_winkel or 0) - 90) end
                    if k.cm > 0 then gc:drawArc(px - 14, py - 14, 28, 28, 0, 360); gc:drawArc(px - 10, py - 10, 20, 20, 0, 360) end
                end

                if not isExplosion then
                    gc:setColorRGB(140, 140, 140)
                    gc:setPen("thin", "smooth")
                    drawSupport(gc, k, i, px, py)
                end

                if not isExplosion or not k.gelenk then
                    if k.gelenk then
                        gc:setColorRGB(255, 255, 255); gc:fillArc(px - 4, py - 4, 8, 8, 0, 360)
                        if i == auswahl then gc:setColorRGB(255, 0, 0) elseif (menuOffen and menuTyp == "knoten" and menuIndex == i) or (not menuOffen and hoverTyp == "knoten" and hoverObj == i) then gc:setColorRGB(0, 100, 255) else gc:setColorRGB(0, 0, 0) end
                        gc:setPen("thin", "smooth"); gc:drawArc(px - 4, py - 4, 8, 8, 0, 360)
                    else
                        if i == auswahl then gc:setColorRGB(255, 0, 0) elseif (menuOffen and menuTyp == "knoten" and menuIndex == i) or (not menuOffen and hoverTyp == "knoten" and hoverObj == i) then gc:setColorRGB(0, 100, 255) else gc:setColorRGB(0, 0, 0) end
                        gc:fillArc(px - 3, py - 3, 6, 6, 0, 360)
                    end
                end
                if fachwerkModus and isExplosion and explosionPage == 2 then
                    gc:setFont("sansserif", "b", 10)
                    gc:setColorRGB(0, 0, 0)
                    gc:drawString("K " .. i, px + 6, py - 12)
                    gc:drawString("S = " .. string.char(64 + i), px - 10, py + 10)
                end
            end
        end
    end

    if isPolplan then
        -- 1. Strahlen zeichnen
        local grouped_rays = {}
        for i=0, polplan.num_disks do
            for j=i+1, polplan.num_disks do
                for _, r in ipairs(polplan.rays[i][j]) do
                    local pm = polstrahlModus or 1
                    if pm == 2 or (pm == 1 and r.is_useful) then
                        local lbl = (i==0) and ("HP" .. j) or ("(" .. i .. "," .. j .. ")")
                        local found = false
                        for _, gr in ipairs(grouped_rays) do
                            if math.abs(r.dx*gr.dy - r.dy*gr.dx) < 1e-4 then
                                local cross = (r.px - gr.px)*gr.dy - (r.py - gr.py)*gr.dx
                                if math.abs(cross) < 1e-4 then
                                    gr.labels[lbl] = true
                                    found = true; break
                                end
                            end
                        end
                        if not found then
                            table.insert(grouped_rays, {px=r.px, py=r.py, dx=r.dx, dy=r.dy, labels={[lbl]=true}})
                        end
                    end
                end
            end
        end
            
    for _, gr in ipairs(grouped_rays) do
        local sx = gr.px * drawPxProMeter + offsetX; local sy = gr.py * drawPxProMeter + offsetY
        gc:setPen("thin", "dashed"); gc:setColorRGB(150, 150, 200)

        local ts = {}
        if math.abs(gr.dx) > 1e-5 then
            local tl = (-10 - sx) / gr.dx; local yl = sy + tl * gr.dy; if yl >= -10 and yl <= h + 10 then table.insert(ts, tl) end
            local tr = (b + 10 - sx) / gr.dx; local yr = sy + tr * gr.dy; if yr >= -10 and yr <= h + 10 then table.insert(ts, tr) end
        end
        if math.abs(gr.dy) > 1e-5 then
            local tt = (-10 - sy) / gr.dy; local xt = sx + tt * gr.dx; if xt >= -10 and xt <= b + 10 then table.insert(ts, tt) end
            local tb = (h + 10 - sy) / gr.dy; local xb = sx + tb * gr.dx; if xb >= -10 and xb <= b + 10 then table.insert(ts, tb) end
        end
        table.sort(ts)
        if #ts >= 2 then
            gc:drawLine(sx + ts[1]*gr.dx, sy + ts[1]*gr.dy, sx + ts[#ts]*gr.dx, sy + ts[#ts]*gr.dy)
        else
            gc:drawLine(sx - gr.dx*1000, sy - gr.dy*1000, sx + gr.dx*1000, sy + gr.dy*1000)
        end

        local ex, ey = getScreenEdgeIntersection(sx, sy, gr.dx, gr.dy, b, h)
        local lbl_arr = {}; for l, _ in pairs(gr.labels) do table.insert(lbl_arr, l) end
        table.sort(lbl_arr)
        local full_label = "g(" .. table.concat(lbl_arr, ", ") .. ")"

        gc:setFont("sansserif", "r", 8)
        local tw = gc:getStringWidth(full_label)
        local tx, ty = ex - gr.dx * 5, ey - gr.dy * 5

        if tx > b/2 then tx = tx - tw - 8 else tx = tx + 8 end
        if ty > h/2 then ty = ty - 8 else ty = ty + 12 end
        if tx > b - tw - 5 then tx = b - tw - 5 end; if tx < 5 then tx = 5 end
        if ty > h - 5 then ty = h - 5 end; if ty < 5 then ty = 5 end

        gc:setColorRGB(100, 100, 150)
        gc:drawString(full_label, tx, ty)
    end

    -- 2. Endliche Pole zeichnen
    local grouped_poles = {}
    for i = 0, polplan.num_disks do
        for j = i+1, polplan.num_disks do
            local is_contra = false
            for _, c in ipairs(polplan.contradictions) do
                if (c.A == i and c.B == j) or (c.A == j and c.B == i) then is_contra = true; break end
            end

            for _, p in ipairs(polplan.poles[i][j]) do
                if p.type == "finite" then
                    local sx = p.x * drawPxProMeter + offsetX
                    local sy = p.y * drawPxProMeter + offsetY
                    local lbl = (i == 0) and ("HP" .. j) or ("(" .. i .. "," .. j .. ")")

                    local found = false
                    for _, gp in ipairs(grouped_poles) do
                        if math.abs(gp.x - sx) < 2 and math.abs(gp.y - sy) < 2 then
                            table.insert(gp.labels, lbl)
                            if i == 0 then gp.has_hp = true end
                            if is_contra then gp.is_contra = true end
                            found = true; break
                        end
                    end
                    if not found then
                        table.insert(grouped_poles, {x=sx, y=sy, labels={lbl}, has_hp=(i==0), is_contra=is_contra})
                    end
                end
            end
        end
    end

    for _, gp in ipairs(grouped_poles) do
        if gp.is_contra then gc:setColorRGB(255, 0, 0)
        elseif gp.has_hp then gc:setColorRGB(0, 0, 255)
        else gc:setColorRGB(0, 180, 0) end
        
        gc:fillArc(gp.x-3, gp.y-3, 6, 6, 0, 360)
        
        if gp.is_contra then gc:setColorRGB(255, 0, 0) end
        gc:setFont("sansserif", "b", 8)
        table.sort(gp.labels)
        gc:drawString(table.concat(gp.labels, ", "), gp.x+6, gp.y-14)
    end

    -- 3. Unendliche Pole auflisten (als Text oben rechts)
    local inf_y = 20
    local inf_x = b - 80
    for i = 0, polplan.num_disks do
        for j = i+1, polplan.num_disks do
            local is_contra = false
            for _, c in ipairs(polplan.contradictions) do
                if (c.A == i and c.B == j) or (c.A == j and c.B == i) then is_contra = true; break end
            end

            for _, p in ipairs(polplan.poles[i][j]) do
                if p.type == "infinite" then
                    local lbl = (i == 0) and ("HP" .. j) or ("(" .. i .. "," .. j .. ")")
                    local text = lbl .. " inf"
                    gc:setFont("sansserif", "b", 12)
                    if is_contra then gc:setColorRGB(255, 0, 0) else gc:setColorRGB(0, 100, 200) end
                    gc:drawString(text, inf_x, inf_y)
                    
                    -- Doppel-Pfeil
                    local cx, cy = inf_x - 20, inf_y + 8
                    gc:setPen("thin", "smooth")
                    local l = 10
                    local x1, y1 = cx - p.dx*l, cy - p.dy*l
                    local x2, y2 = cx + p.dx*l, cy + p.dy*l
                    gc:drawLine(x1, y1, x2, y2)
                    
                    local as = 4 -- arrow head size
                    gc:drawLine(x1, y1, x1 + p.dx*as - p.dy*as, y1 + p.dy*as + p.dx*as)
                    gc:drawLine(x1, y1, x1 + p.dx*as + p.dy*as, y1 + p.dy*as - p.dx*as)
                    gc:drawLine(x2, y2, x2 - p.dx*as - p.dy*as, y2 - p.dy*as + p.dx*as)
                    gc:drawLine(x2, y2, x2 - p.dx*as + p.dy*as, y2 - p.dy*as - p.dx*as)
                    inf_y = inf_y + 20
                    if inf_y > h - 30 then
                        inf_y = 20
                        inf_x = inf_x - 70
                    end
                end
            end
        end
    end
    end

    if hovered_ts then
        gc:setFont("sansserif", "b", 10)
        gc:setColorRGB(0, 0, 255)
        gc:drawString("Teilsystem " .. hovered_ts, 10, 25)
        
        local pts = {}
        for j, s in ipairs(staebe) do
            if glob_ts_scheibe and glob_ts_scheibe[j] == hovered_ts then
                pts[#pts+1] = knoten[s.k1]
                pts[#pts+1] = knoten[s.k2]
            end
        end
        if glob_disk_centers and glob_disk_centers[hovered_ts] then
            local c = glob_disk_centers[hovered_ts]
            pts[#pts+1] = {x = c.x, y = c.y, is_virtual = false}
            
            if glob_resultant_pts then
                for _, pt in ipairs(glob_resultant_pts) do
                    pts[#pts+1] = pt
                end
            end
            
            local px = c.x * drawPxProMeter + offsetX
            local py = c.y * drawPxProMeter + offsetY
            gc:setColorRGB(0, 0, 255)
            gc:setPen("medium", "smooth")
            gc:drawLine(px - 3, py - 3, px + 3, py + 3)
            gc:drawLine(px - 3, py + 3, px + 3, py - 3)
            gc:setFont("sansserif", "b", 10)
            gc:drawString("P" .. (c.node_id or hovered_ts), px + 8, py - 15)
        end
        drawBemassung(gc, pts)
    else
        drawBemassung(gc)
    end

    gc:setPen("thin", "smooth")

    if isKinematic and pvv_released_binding then
        gc:setColorRGB(255, 0, 0)
        local bind = pvv_released_binding
        if bind.type == "n_gelenk" or bind.type == "q_gelenk" or bind.type == "m_gelenk" then
            local s = staebe[bind.stab]
            local k1, k2 = knoten[s.k1], knoten[s.k2]
            local px1, py1 = k1.x * drawPxProMeter + offsetX, k1.y * drawPxProMeter + offsetY
            local px2, py2 = k2.x * drawPxProMeter + offsetX, k2.y * drawPxProMeter + offsetY
            local nodeIdx = bind.endA and s.k1 or s.k2
            local n_px = knoten[nodeIdx].x * drawPxProMeter + offsetX
            local n_py = knoten[nodeIdx].y * drawPxProMeter + offsetY
            local ux_n, uy_n = getKinematicDisp(nodeIdx)
            local anim_f = (0.5 * drawPxProMeter) / (kinematic_max_disp and kinematic_max_disp > 1e-6 and kinematic_max_disp or 1)
            local nd_px = n_px + ux_n * anim_f
            local nd_py = n_py + uy_n * anim_f
            
            local u1x, u1y, u2x, u2y = getKinematicDisp_Stab(bind.stab)
            local rd_px = (bind.endA and px1 + u1x * anim_f) or (px2 + u2x * anim_f)
            local rd_py = (bind.endA and py1 + u1y * anim_f) or (py2 + u2y * anim_f)
            
            -- Richtung (dx, dy) des UNVERFORMTEN Systems nutzen, wie vom Benutzer gewünscht.
            local dx, dy = px2 - px1, py2 - py1
            local L = math.sqrt(dx^2 + dy^2)
            
            if bind.type == "n_gelenk" or bind.type == "q_gelenk" then
                if L > 0 then
                    local nx, ny = dx/L, dy/L
                    if bind.type == "q_gelenk" then nx, ny = -ny, nx end
                    local arrowL = 20
                    local dir = bind.endA and -1 or 1
                    local ax, ay = nx * arrowL * dir, ny * arrowL * dir
                    drawArrow(gc, nd_px, nd_py, nd_px - ax, nd_py - ay)
                    drawArrow(gc, rd_px, rd_py, rd_px + ax, rd_py + ay)
                    
                    gc:setFont("sansserif", "b", 10)
                    local text = bind.type == "q_gelenk" and "Q" or "N"
                    gc:drawString(text, nd_px - ax - 8 * nx, nd_py - ay - 8 * ny)
                    gc:drawString(text, rd_px + ax + 8 * nx, rd_py + ay + 8 * ny)
                    
                    -- Displacement drawing (delta_N, delta_Q)
                    local ux_r = bind.endA and u1x or u2x
                    local uy_r = bind.endA and u1y or u2y
                    local delta_val = (ux_r - ux_n) * nx + (uy_r - uy_n) * ny
                    local lbl_disp = bind.type == "q_gelenk" and "δ_Q" or "δ_N"
                    
                    local s_disk = s.scheibe or 1
                    local d_state = kinematic_disk_states and kinematic_disk_states[s_disk]
                    local phi_abs = d_state and math.abs(d_state.phi) or 0
                    local disp_str = ""
                    local abstand = 0
                    local rot_part = 0
                    local trans_part = delta_val
                    
                    if d_state and d_state.type == "rot" and math.abs(phi_abs) > 1e-6 then
                        if bind.type == "n_gelenk" then
                            rot_part = 0
                            abstand = 0
                            trans_part = delta_val
                        else
                            local n_idx = bind.endA and s.k1 or s.k2
                            local kn = knoten[n_idx]
                            
                            local dy_pol = kn.y - d_state.cy
                            local dx_pol = kn.x - d_state.cx
                            
                            local ux_rot = -d_state.phi * dy_pol
                            local uy_rot = d_state.phi * dx_pol
                            
                            rot_part = ux_rot * nx + uy_rot * ny
                            abstand = rot_part / d_state.phi
                            trans_part = delta_val - rot_part
                        end
                    end
                    
                    local sign = delta_val < 0 and -1 or 1
                    local disp_abstand = abstand * sign
                    local disp_trans = trans_part * sign
                    
                    disp_str = lbl_disp .. " = "
                    if math.abs(disp_abstand) > 1e-4 and math.abs(disp_trans) > 1e-4 then
                        disp_str = disp_str .. string.format("%.2f * phi_%d %s %.2f", disp_abstand, s_disk, disp_trans > 0 and "+" or "-", math.abs(disp_trans))
                    elseif math.abs(disp_abstand) > 1e-4 then
                        disp_str = disp_str .. string.format("%.2f * phi_%d", disp_abstand, s_disk)
                    else
                        disp_str = disp_str .. formatLabel(math.abs(disp_trans))
                    end
                    
                    gc:setColorRGB(200, 0, 200)
                    gc:setPen("thin", "smooth")
                    local ox, oy = -ny * 15, nx * 15
                    drawArrow(gc, nd_px + ox, nd_py + oy, rd_px + ox, rd_py + oy)
                    gc:setFont("sansserif", "r", 8)
                    gc:drawString(disp_str, rd_px + ox + 5, rd_py + oy)
                    gc:setColorRGB(255, 0, 0)
                end
            elseif bind.type == "m_gelenk" then
                local angle = 0
                if L > 0 then angle = math.deg(math.atan2(-dy, dx)) end
                if bind.endA then angle = angle + 180 end
                
                -- Funktion zum Zeichnen eines Bogenpfeils für das Moment.
                -- ext < 0 ermöglicht das Zeichnen im Uhrzeigersinn (CW),
                -- da drawArc standardmäßig nur positive Winkel (CCW) unterstützt.
                local function drawPvVArc(cx, cy, sA, ext)
                    gc:drawArc(cx - 15, cy - 15, 30, 30, ext < 0 and sA + ext or sA, math.abs(ext))
                    local eA = math.rad(sA + ext)
                    local tA = math.rad(sA + ext - 15 * (ext > 0 and 1 or -1))
                    drawArrow(gc, cx + 15*math.cos(tA), cy - 15*math.sin(tA), cx + 15*math.cos(eA), cy - 15*math.sin(eA))
                end
                
                -- Vorzeichen entsprechend den positiven Schnittgrößen am Stabende/Stabanfang:
                -- Wenn das Gelenk am Stabanfang (k1) ist, ist das pos. Moment CW (-150).
                -- Wenn es am Stabende (k2) ist, ist es CCW (150).
                local rod_ext = bind.endA and -150 or 150
                local node_ext = -rod_ext
                
                -- Zeichnen des Momentenpaares am Angelenk.
                -- Wir zentrieren die Bögen so, dass sie sich jeweils über den Stab ("Stabseite")
                -- und über den Knoten stülpen.
                -- angle zeigt vom Stab zum Knoten. Die Stabrichtung ist angle + 180.
                
                -- Der Bogen für den Knoten wird über dem Knoten zentriert (angle).
                drawPvVArc(nd_px, nd_py, angle - node_ext / 2, node_ext)
                -- Der Bogen für den Stab wird über dem Stab zentriert (angle + 180).
                drawPvVArc(rd_px, rd_py, angle + 180 - rod_ext / 2, rod_ext)
            end
        elseif bind.type == "lager_x" or bind.type == "lager_y" or bind.type == "lager_m" or bind.type == "knoten_gelenk" then
            local k = knoten[bind.node]
            local n_px = k.x * drawPxProMeter + offsetX
            local n_py = k.y * drawPxProMeter + offsetY
            local ux_n, uy_n = getKinematicDisp(bind.node)
            local anim_f = (0.5 * drawPxProMeter) / (kinematic_max_disp and kinematic_max_disp > 1e-6 and kinematic_max_disp or 1)
            local nd_px = n_px + ux_n * anim_f
            local nd_py = n_py + uy_n * anim_f
            
            if bind.type == "lager_x" then
                drawArrow(gc, nd_px, nd_py, nd_px + 20, nd_py)
                gc:setFont("sansserif", "b", 10)
                gc:drawString("H", nd_px + 25, nd_py - 5)
            elseif bind.type == "lager_y" then
                drawArrow(gc, nd_px, nd_py, nd_px, nd_py + 20)
                gc:setFont("sansserif", "b", 10)
                gc:drawString("V", nd_px + 5, nd_py + 25)
            elseif bind.type == "lager_m" then
                -- positive moment is mathematically CCW. On screen (y down), this visually goes from right (0) to UP (-90).
                -- let's draw a CCW arc of 270 degrees
                local startAng = 90
                local sweep = 270
                gc:drawArc(nd_px - 15, nd_py - 15, 30, 30, startAng, sweep)
                local eA = math.rad(startAng + sweep); local tA = math.rad(startAng + sweep - 15)
                drawArrow(gc, nd_px + 15*math.cos(tA), nd_py - 15*math.sin(tA), nd_px + 15*math.cos(eA), nd_py - 15*math.sin(eA))
                gc:setFont("sansserif", "b", 10)
                gc:drawString("M", nd_px + 20, nd_py - 15)
            elseif bind.type == "knoten_gelenk" then
                local found_rods = {}
                for i, s in ipairs(staebe) do
                    if s.k1 == bind.node or s.k2 == bind.node then
                        table.insert(found_rods, {idx=i, s=s})
                    end
                end
                if #found_rods == 2 then
                    local s1 = found_rods[1].s
                    local s1_is_start = (s1.k1 == bind.node)
                    -- Positives Schnittmoment: Anfang (k1) -> CW (-150), Ende (k2) -> CCW (150)
                    local base_ext = s1_is_start and -150 or 150
                    
                    for i, r_info in ipairs(found_rods) do
                        local s = r_info.s
                        local k1, k2 = knoten[s.k1], knoten[s.k2]
                        local px1, py1 = k1.x * drawPxProMeter + offsetX, k1.y * drawPxProMeter + offsetY
                        local px2, py2 = k2.x * drawPxProMeter + offsetX, k2.y * drawPxProMeter + offsetY
                        
                        if isKinematic then
                            local u1x, u1y, u2x, u2y = getKinematicDisp_Stab(r_info.idx)
                            local anim_f = (0.5 * drawPxProMeter) / (kinematic_max_disp and kinematic_max_disp > 1e-6 and kinematic_max_disp or 1)
                            px1, py1 = px1 + u1x * anim_f, py1 + u1y * anim_f
                            px2, py2 = px2 + u2x * anim_f, py2 + u2y * anim_f
                        end
                        
                        -- Richtung (dx, dy) des (ggf. verformten) Systems nutzen
                        local dx, dy = px2 - px1, py2 - py1
                        
                        local angle = 0
                        if math.sqrt(dx^2 + dy^2) > 0 then angle = math.deg(math.atan2(-dy, dx)) end
                        if s.k1 == bind.node then angle = angle + 180 end
                        
                        -- Erster Stab erhält das Moment, zweiter Stab das exakte Gegenmoment
                        local ext = (i == 1) and base_ext or -base_ext
                        
                        -- Den Mittelpunkt des Bogens etwas entlang des Stabes verschieben
                        local offset = 15
                        local dir_rad = math.rad(angle + 180)
                        local cx = nd_px + offset * math.cos(dir_rad)
                        local cy = nd_py - offset * math.sin(dir_rad)
                        
                        local sA = angle + 180 - ext / 2
                        gc:drawArc(cx - 15, cy - 15, 30, 30, ext < 0 and sA + ext or sA, math.abs(ext))
                        local eA = math.rad(sA + ext); local tA = math.rad(sA + ext - 15 * (ext > 0 and 1 or -1))
                        drawArrow(gc, cx + 15*math.cos(tA), cy - 15*math.sin(tA), cx + 15*math.cos(eA), cy - 15*math.sin(eA))
                    end
                end
            end
        end
    end

    if isKinematic and kinematic_disk_states then
        for i, state in ipairs(kinematic_disk_states) do
            if state.type == "rot" and math.abs(state.phi) > 1e-9 then
                local cx = state.cx * drawPxProMeter + offsetX
                local cy = state.cy * drawPxProMeter + offsetY
                
                local best_s = nil
                local ref_node = nil
                local ref_other = nil
                local needs_hilfslinie = true
                local score = -1
                
                for s_idx, s in ipairs(staebe) do
                    if s.scheibe == i then
                        local ux1, uy1 = getKinematicDisp(s.k1)
                        local ux2, uy2 = getKinematicDisp(s.k2)
                        local is_k1_stat = (math.abs(ux1) < 1e-5 and math.abs(uy1) < 1e-5)
                        local is_k2_stat = (math.abs(ux2) < 1e-5 and math.abs(uy2) < 1e-5)
                        
                        local current_score = 0
                        local c_ref_node, c_ref_other, c_needs_h
                        
                        if is_k1_stat then
                            c_ref_node = s.k1; c_ref_other = s.k2; c_needs_h = false; current_score = 10
                        elseif is_k2_stat then
                            c_ref_node = s.k2; c_ref_other = s.k1; c_needs_h = false; current_score = 10
                        elseif pvv_released_binding and pvv_released_binding.stab == s_idx then
                            local rel_node = pvv_released_binding.endA and s.k1 or s.k2
                            c_ref_node = (rel_node == s.k1) and s.k2 or s.k1
                            c_ref_other = rel_node
                            c_needs_h = true
                            current_score = 5
                        else
                            c_ref_node = s.k1; c_ref_other = s.k2; c_needs_h = true; current_score = 1
                        end
                        
                        if current_score > score then
                            score = current_score; best_s = s; ref_node = c_ref_node; ref_other = c_ref_other; needs_hilfslinie = c_needs_h
                        end
                    end
                end
                
                if ref_node and ref_other then
                    local rx = knoten[ref_node].x * drawPxProMeter + offsetX
                    local ry = knoten[ref_node].y * drawPxProMeter + offsetY
                    local ox = knoten[ref_other].x * drawPxProMeter + offsetX
                    local oy = knoten[ref_other].y * drawPxProMeter + offsetY
                    
                    local dx = ox - rx; local dy = oy - ry
                    local angle_0 = math.deg(math.atan2(-dy, dx))
                    local dist = math.sqrt(dx^2 + dy^2)
                    local r_ref = math.max(25, math.min(50, dist * 0.3)) -- now used as RADIUS
                    
                    local ux, uy = getKinematicDisp(ref_node)
                    local o_ux, o_uy = getKinematicDisp(ref_other)
                    local anim_f = (0.5 * drawPxProMeter) / (kinematic_max_disp and kinematic_max_disp > 1e-6 and kinematic_max_disp or 1)
                    local nd_rx = rx + ux * anim_f; local nd_ry = ry + uy * anim_f
                    local nd_ox = ox + o_ux * anim_f; local nd_oy = oy + o_uy * anim_f
                    
                    local nd_dx = nd_ox - nd_rx; local nd_dy = nd_oy - nd_ry
                    local angle_1 = math.deg(math.atan2(-nd_dy, nd_dx))
                    
                    local v_phi = angle_1 - angle_0
                    while v_phi > 180 do v_phi = v_phi - 360 end
                    while v_phi < -180 do v_phi = v_phi + 360 end
                    local v_phi_dir = v_phi > 0 and 1 or -1
                    
                    gc:setColorRGB(0, 0, 255)
                    
                    if needs_hilfslinie then
                        gc:setPen("thin", "dashed")
                        local hx = nd_rx + r_ref * 1.2 * math.cos(math.rad(angle_0))
                        local hy = nd_ry - r_ref * 1.2 * math.sin(math.rad(angle_0))
                        gc:drawLine(nd_rx, nd_ry, hx, hy)
                    end
                    
                    gc:setPen("thin", "smooth")
                    local start_ang = v_phi > 0 and angle_0 or angle_1
                    gc:drawArc(nd_rx - r_ref, nd_ry - r_ref, 2*r_ref, 2*r_ref, start_ang, math.abs(v_phi))
                    
                    local eA = math.rad(angle_1)
                    local arr_sweep = math.min(15, math.abs(v_phi) * 0.8)
                    local tA = math.rad(angle_1 - arr_sweep * v_phi_dir)
                    drawArrow(gc, nd_rx + r_ref*math.cos(tA), nd_ry - r_ref*math.sin(tA), nd_rx + r_ref*math.cos(eA), nd_ry - r_ref*math.sin(eA))
                    
                    if (not kinematic_seed_info or kinematic_seed_info.disk == i) and (not kinematic_seed_info or not kinematic_seed_info.node_idx) then
                        local cx = state.cx * drawPxProMeter + offsetX
                        local cy = state.cy * drawPxProMeter + offsetY
                        gc:setPen("thin", "dashed"); gc:setColorRGB(180, 180, 180)
                        gc:drawLine(cx, cy, rx, ry); gc:drawLine(cx, cy, nd_rx, nd_ry)
                        gc:setColorRGB(0, 0, 255)
                        gc:fillArc(cx - 3, cy - 3, 6, 6, 0, 360)
                        gc:setFont("sansserif", "r", 9)
                        gc:drawString("Pol", cx + 5, cy + 5)
                    end
                    
                    gc:setFont("sansserif", "r", 10)
                    local txt = (kinematic_seed_info and kinematic_seed_info.disk == i) and "Φ_0 = 1" or string.format("Φ_%d", i)
                    local txt_w = gc:getStringWidth(txt)
                    local midAng = math.rad(angle_0 + v_phi / 2)
                    local r_txt = r_ref + 10
                    gc:drawString(txt, nd_rx + r_txt*math.cos(midAng) - txt_w/2, nd_ry - r_txt*math.sin(midAng) - 6)
                end
            end
        end
    end

    if warnungKinematisch then
        local boxW, boxH = math.min(b - 20, 180), 36; local boxX, boxY = math.floor((b - boxW) / 2), math.floor((h - boxH) / 2)
        gc:setColorRGB(255, 0, 0); gc:fillRect(boxX, boxY, boxW, boxH); gc:setColorRGB(255, 255, 255); gc:drawRect(boxX, boxY, boxW, boxH)
        gc:setFont("sansserif", "b", 10); gc:drawString("System ist kinematisch!", boxX + 8, boxY + 12)
    elseif warnungStarrBestimmt then
        local boxW, boxH = math.min(b - 20, 240), 36; local boxX, boxY = math.floor((b - boxW) / 2), math.floor((h - boxH) / 2)
        gc:setColorRGB(255, 165, 0); gc:fillRect(boxX, boxY, boxW, boxH); gc:setColorRGB(0, 0, 0); gc:drawRect(boxX, boxY, boxW, boxH)
        gc:setFont("sansserif", "b", 10); gc:drawString("Starrmodus & statisch unbestimmt!", boxX + 8, boxY + 12)
    end
    
    if pvvPrompt then
        local boxW, boxH = 320, 40; local boxX, boxY = math.floor((b - boxW) / 2), 20
        gc:setColorRGB(255, 200, 0); gc:fillRect(boxX, boxY, boxW, boxH); gc:setColorRGB(0, 0, 0); gc:drawRect(boxX, boxY, boxW, boxH)
        gc:setFont("sansserif", "b", 11); gc:drawString("System ist starr! [Enter] für PvV-Modus", boxX + 15, boxY + 12)
    end
    if menuOffen then
        local menueHoehe = 150
        if menuTyp == "knoten" then
            if isKinematic then
                local k = knoten[menuIndex]
                local fx_str = (symbolischer_modus and k.last_x_str) and k.last_x_str or formatLabel(k.last_x or 0)
                local fy_str = (symbolischer_modus and k.last_y_str) and k.last_y_str or formatLabel(k.last_y or 0)
                local fm_str = (symbolischer_modus and k.last_m_str) and k.last_m_str or formatLabel(k.last_m or 0)
                local has_m_gelenk = false
                if pvv_released_binding and pvv_released_binding.node == menuIndex then
                    local bind = pvv_released_binding
                    if bind.type == "lager_x" then fx_str = "H" elseif bind.type == "lager_y" then fy_str = "V" elseif bind.type == "lager_m" then fm_str = "M" elseif bind.type == "knoten_gelenk" then has_m_gelenk = true end
                end
                local has_fx = fx_str ~= "0" and fx_str ~= "0.00"; local has_fy = fy_str ~= "0" and fy_str ~= "0.00"; local has_fm = fm_str ~= "0" and fm_str ~= "0.00"
                if has_fx or has_fy or has_fm or has_m_gelenk then
                    local cy = 40
                    if has_fx then cy = cy + 20 end; if has_fy then cy = cy + 20 end; if has_fm then cy = cy + 20 end
                    cy = cy + 10
                    if has_fx then cy = cy + 20 end; if has_fy then cy = cy + 20 end; if has_fm then cy = cy + 20 end
                    if has_m_gelenk then cy = cy + 20 end
                    menueHoehe = cy + 50
                else menueHoehe = 80 end
            else
                if menuSeite == 1 then menueHoehe = 160 elseif menuSeite == 2 then menueHoehe = 140 elseif menuSeite == 3 then menueHoehe = 120 elseif menuSeite == 4 then menueHoehe = 200 elseif menuSeite == 5 then menueHoehe = 160 else menueHoehe = 140 end
            end
        elseif menuTyp == "stab" then
            if isKinematic then
                local s = staebe[menuIndex]
                local cy = 60
                local has_load = (math.abs(s.q) + math.abs(s.q_A or 0) + math.abs(s.q_B or 0) + math.abs(s.n) + math.abs(s.n_A or 0) + math.abs(s.n_B or 0) + math.abs(s.gx or 0) + math.abs(s.gy or 0) + math.abs(s.m or 0)) > 1e-4
                if has_load then cy = cy + 40 end
                if s.q_gelenk_A or s.n_gelenk_A or (pvv_released_binding and pvv_released_binding.stab == menuIndex and pvv_released_binding.endA and (pvv_released_binding.type == "q_gelenk" or pvv_released_binding.type == "n_gelenk" or pvv_released_binding.type == "m_gelenk")) then cy = cy + 40 end
                if s.q_gelenk_B or s.n_gelenk_B or (pvv_released_binding and pvv_released_binding.stab == menuIndex and not pvv_released_binding.endA and (pvv_released_binding.type == "q_gelenk" or pvv_released_binding.type == "n_gelenk" or pvv_released_binding.type == "m_gelenk")) then cy = cy + 40 end
                
                local w_tot, w_str = getKinematicWork_Stab(menuIndex)
                local is_1last_stab = false; local is_1last_node = false
                if pvv_released_binding and (pvv_released_binding.type == "q_gelenk" or pvv_released_binding.type == "n_gelenk" or pvv_released_binding.type == "m_gelenk") then
                    local nodeIdx = nil
                    if pvv_released_binding.stab then local b_stab = staebe[pvv_released_binding.stab]; nodeIdx = pvv_released_binding.endA and b_stab.k1 or b_stab.k2 end
                    if (pvv_released_binding.stab and menuIndex == pvv_released_binding.stab) or (s.k1 == nodeIdx or s.k2 == nodeIdx) then
                        if (pvv_released_binding.stab and menuIndex == pvv_released_binding.stab) then is_1last_stab = true else is_1last_node = true end
                    end
                end
                
                if has_load or is_1last_stab or is_1last_node then
                    cy = cy + 20
                    if type(w_str) == "table" then for _, term in ipairs(w_str) do cy = cy + 15 end end
                    if is_1last_stab then cy = cy + 15 end
                    if is_1last_node then cy = cy + 15 end
                    cy = cy + 20
                end
                menueHoehe = cy + 20
            else
                if menuSeite == 1 then menueHoehe = 160 elseif menuSeite == 2 then menueHoehe = 120 elseif menuSeite == 3 then menueHoehe = 200 elseif menuSeite == 6 then menueHoehe = 160 elseif menuSeite == 7 then menueHoehe = 180 else menueHoehe = 160 end
            end
        elseif menuTyp == "obermenue" then if menuSeite == 1 then menueHoehe = 220 elseif menuSeite == 2 then menueHoehe = 180 elseif menuSeite == 3 then menueHoehe = 240 else menueHoehe = 60 end
        elseif menuTyp == "pvv_knoten" then menueHoehe = 120
        elseif menuTyp == "pvv_stab" then menueHoehe = 160 end

        local mW = (menuTyp == "obermenue") and 210 or 155
        local mX = b - mW - 10
        gc:setColorRGB(240, 240, 240); gc:fillRect(mX, 10, mW, menueHoehe); gc:setColorRGB(0, 0, 0); gc:drawRect(mX, 10, mW, menueHoehe)
        
        if not (isKinematic and (menuTyp == "knoten" or menuTyp == "stab")) then
            gc:setColorRGB(200, 200, 255); gc:fillRect(mX + 2, 20 + (menuZeile * 20), mW - 4, 18)
        end
        gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "b", 9)

        if menuTyp == "knoten" then
            if isKinematic then
                gc:drawString("Knoten " .. menuIndex .. " (PvV-Modus)", b - 160, 15); gc:setFont("sansserif", "r", 9)
        local k_ux, k_uy = getKinematicDisp(menuIndex)
        local k_phi = getKinematicRot and getKinematicRot(menuIndex) or 0
        local k = knoten[menuIndex]
        local fx_str = (symbolischer_modus and k.last_x_str) and k.last_x_str or formatLabel(k.last_x or 0)
        local fy_str = (symbolischer_modus and k.last_y_str) and k.last_y_str or formatLabel(k.last_y or 0)
        local fm_str = (symbolischer_modus and k.last_m_str) and k.last_m_str or formatLabel(k.last_m or 0)

        local is_released_x = false; local is_released_y = false; local is_released_m = false
        local has_m_gelenk = false
        local m_gelenk_phi1, m_gelenk_phi2 = 0, 0

        if pvv_released_binding and pvv_released_binding.node == menuIndex then
            local bind = pvv_released_binding
            if bind.type == "lager_x" then fx_str = "H"; is_released_x = true
            elseif bind.type == "lager_y" then fy_str = "V"; is_released_y = true
            elseif bind.type == "lager_m" then fm_str = "M"; is_released_m = true
            elseif bind.type == "knoten_gelenk" then
                has_m_gelenk = true
                local m_gelenk_s1, m_gelenk_s2 = nil, nil
                for _, s in ipairs(staebe) do
                    if s.k1 == menuIndex or s.k2 == menuIndex then
                        if not m_gelenk_s1 then m_gelenk_s1 = s
                        elseif not m_gelenk_s2 then m_gelenk_s2 = s end
                    end
                end
                if m_gelenk_s1 then m_gelenk_phi1 = -(kinematic_disk_states and kinematic_disk_states[m_gelenk_s1.scheibe] and kinematic_disk_states[m_gelenk_s1.scheibe].type == "rot" and kinematic_disk_states[m_gelenk_s1.scheibe].phi or 0) end
                if m_gelenk_s2 then m_gelenk_phi2 = -(kinematic_disk_states and kinematic_disk_states[m_gelenk_s2.scheibe] and kinematic_disk_states[m_gelenk_s2.scheibe].type == "rot" and kinematic_disk_states[m_gelenk_s2.scheibe].phi or 0) end
            end
        end

        local has_fx = fx_str ~= "0" and fx_str ~= "0.00"
        local has_fy = fy_str ~= "0" and fy_str ~= "0.00"
        local has_fm = fm_str ~= "0" and fm_str ~= "0.00"

        local current_y = 40
        if has_fx or has_fy or has_fm or has_m_gelenk then
            if has_fx then
                gc:setColorRGB(0,0,0); gc:drawString("Starrk. u_x:", b - 160, current_y)
                gc:setColorRGB(0, 120, 0); gc:drawString(string.format("%.4f", k_ux), b - 70, current_y)
                current_y = current_y + 20
            end
            if has_fy then
                gc:setColorRGB(0,0,0); gc:drawString("Starrk. u_y:", b - 160, current_y)
                gc:setColorRGB(0, 120, 0); gc:drawString(string.format("%.4f", k_uy), b - 70, current_y)
                current_y = current_y + 20
            end
            if has_fm then
                gc:setColorRGB(0,0,0); gc:drawString("Starrk. phi:", b - 160, current_y)
                gc:setColorRGB(0, 120, 0); gc:drawString(string.format("%.4f", k_phi), b - 70, current_y)
                current_y = current_y + 20
            end

            local w_str_parts = {}
            local w_val_sum = 0
            if has_fx then
                gc:setColorRGB(0,0,0); gc:drawString("Arbeit W_x:", b - 160, current_y)
                local val = evalInput(fx_str) or 1
                if symbolischer_modus or is_released_x then
                    gc:setColorRGB(200, 50, 50); gc:drawString(string.format("%s * %.2f", fx_str, k_ux), b - 80, current_y)
                else
                    gc:setColorRGB(200, 50, 50); gc:drawString(string.format("%s * %.2f = %.2f", fx_str, k_ux, val * k_ux), b - 80, current_y)
                end
                table.insert(w_str_parts, string.format("%s*%.2f", fx_str, k_ux))
                if not is_released_x then w_val_sum = w_val_sum + val * k_ux end
                current_y = current_y + 20
            end
            if has_fy then
                gc:setColorRGB(0,0,0); gc:drawString("Arbeit W_y:", b - 160, current_y)
                local val = evalInput(fy_str) or 1
                if symbolischer_modus or is_released_y then
                    gc:setColorRGB(200, 50, 50); gc:drawString(string.format("%s * %.2f", fy_str, k_uy), b - 80, current_y)
                else
                    gc:setColorRGB(200, 50, 50); gc:drawString(string.format("%s * %.2f = %.2f", fy_str, k_uy, val * k_uy), b - 80, current_y)
                end
                table.insert(w_str_parts, string.format("%s*%.2f", fy_str, k_uy))
                if not is_released_y then w_val_sum = w_val_sum + val * k_uy end
                current_y = current_y + 20
            end
            if has_fm then
                gc:setColorRGB(0,0,0); gc:drawString("Arbeit W_phi:", b - 160, current_y)
                local val = evalInput(fm_str) or 1
                if symbolischer_modus or is_released_m then
                    gc:setColorRGB(200, 50, 50); gc:drawString(string.format("%s * %.2f", fm_str, k_phi), b - 80, current_y)
                else
                    gc:setColorRGB(200, 50, 50); gc:drawString(string.format("%s * %.2f = %.2f", fm_str, k_phi, val * k_phi), b - 80, current_y)
                end
                table.insert(w_str_parts, string.format("%s*%.2f", fm_str, k_phi))
                if not is_released_m then w_val_sum = w_val_sum + val * k_phi end
                current_y = current_y + 20
            end
            if has_m_gelenk then
                gc:setColorRGB(0,0,0); gc:drawString("Arbeit W_M:", b - 160, current_y)
                local dphi = m_gelenk_phi1 - m_gelenk_phi2
                gc:setColorRGB(200, 50, 50); gc:drawString(string.format("M * %.2f", dphi), b - 80, current_y)
                table.insert(w_str_parts, string.format("M*%.2f", dphi))
                current_y = current_y + 20
            end

            current_y = current_y + 5
            gc:setColorRGB(0,0,0)
            gc:drawLine(b - 160, current_y - 2, b - 10, current_y - 2)
            gc:drawString("Summe W:", b - 160, current_y + 5)
            gc:setFont("sansserif", "r", 8)
            local pvv_sum_str = table.concat(w_str_parts, " + ")
            gc:setColorRGB(200, 50, 50)
            gc:drawString(pvv_sum_str or "", b - 160, current_y + 20)
            gc:setFont("sansserif", "r", 9)

        else
            gc:setColorRGB(150, 150, 150)
            gc:drawString("Keine Lasten vorhanden", b - 160, current_y)
        end
            else
                local menueHoehe = 150
                if menuSeite == 1 then menueHoehe = 160 elseif menuSeite == 2 then menueHoehe = 140 elseif menuSeite == 3 then menueHoehe = 120 elseif menuSeite == 4 then menueHoehe = 200 else menueHoehe = 140 end
                
                gc:drawString("Knoten " .. menuIndex .. " < S." .. menuSeite .. "/4 >", b - 160, 15); gc:setFont("sansserif", "r", 9)
                local k = knoten[menuIndex]
                if menuSeite == 1 then
                    -- URSPRÜNGLICHE REIHENFOLGE WIEDERHERGESTELLT: 
                    -- Zeile 3 ist "Gelenkig", Zeilen 4-6 sind die Lager-Eigenschaften.
                    -- Dies stimmt jetzt wieder 100% mit der Logik in on.enterKey überein!
                    gc:drawString("X Koord:", b - 160, 40); gc:drawString("Y Koord:", b - 160, 60); gc:drawString("Gelenkig:", b - 160, 80); gc:drawString("Lager X:", b - 160, 100); gc:drawString("Lager Y:", b - 160, 120); gc:drawString("Lager M:", b - 160, 140)
                    gc:setColorRGB(0, 0, 255)
                    if menuZeile == 1 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 40) else gc:drawString(tostring(k.x), b - 65, 40) end
                    if menuZeile == 2 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 60) else gc:drawString(tostring(k.y), b - 65, 60) end
                    gc:drawString(k.gelenk and "Ja" or "Nein", b - 65, 80)
                    gc:drawString(k.lager_x and "Ja" or "Nein", b - 65, 100); gc:drawString(k.lager_y and "Ja" or "Nein", b - 65, 120); gc:drawString(k.lager_m and "Ja" or "Nein", b - 65, 140)
                elseif menuSeite == 2 then
                    -- URSPRÜNGLICHE NAMEN WIEDERHERGESTELLT ("Last-Winkel" und "Lager-Winkel")
                    gc:drawString("Last Fx (kN):", b - 160, 40); gc:drawString("Last Fy (kN):", b - 160, 60); gc:drawString("Last M (kNm):", b - 160, 80); gc:drawString("Last-Winkel:", b - 160, 100); gc:drawString("Lager-Winkel:", b - 160, 120)
                    gc:setColorRGB(0, 0, 255)
                    local v_x = (symbolischer_modus and k.last_x_str) and k.last_x_str or tostring(k.last_x or 0)
                    local v_y = (symbolischer_modus and k.last_y_str) and k.last_y_str or tostring(k.last_y or 0)
                    local v_m = (symbolischer_modus and k.last_m_str) and k.last_m_str or tostring(k.last_m or 0)
                    if menuZeile == 1 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 40) else gc:drawString(v_x, b - 65, 40) end
                    if menuZeile == 2 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 60) else gc:drawString(v_y, b - 65, 60) end
                    if menuZeile == 3 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 80) else gc:drawString(v_m, b - 65, 80) end
                    if menuZeile == 4 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 100) else gc:drawString(tostring(k.last_w or 0), b - 65, 100) end
                    if menuZeile == 5 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 120) else gc:drawString(tostring(k.winkel or 0), b - 65, 120) end
                elseif menuSeite == 3 then
                    gc:drawString("Feder cx (kN/m):", b - 160, 40); gc:drawString("Feder cy (kN/m):", b - 160, 60); gc:drawString("Feder cm (kNm/r):", b - 160, 80); gc:drawString("Feder-Winkel:", b - 160, 100)

                    gc:setColorRGB(0, 0, 255)
                    if menuZeile == 1 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 40) else gc:drawString(tostring(k.cx or 0), b - 65, 40) end
                    if menuZeile == 2 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 60) else gc:drawString(tostring(k.cy or 0), b - 65, 60) end
                    if menuZeile == 3 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 80) else gc:drawString(tostring(k.cm or 0), b - 65, 80) end
                    if menuZeile == 4 and eingabeModus then gc:drawString(eingabeText .. "_", b - 65, 100) else gc:drawString(tostring(k.f_winkel or 0), b - 65, 100) end
                elseif menuSeite == 4 then
                    gc:drawString("R_xi (Parallel):", b - 160, 40); gc:drawString("R_eta (Senkr.):", b - 160, 60); gc:drawString("R_m (Moment):", b - 160, 80)
                    gc:drawString("ü_x (WGV):", b - 160, 100); gc:drawString("ü_y (WGV):", b - 160, 120); gc:drawString("ü_ges (WGV):", b - 160, 140); gc:drawString("phi (WGV):", b - 160, 160)
                    gc:drawString("In TI speichern:", b - 160, 180)
                    
                    local ux = (k.eq_x and k.eq_x > 0 and glob_u) and glob_u[k.eq_x] or 0
                    local uy = (k.eq_y and k.eq_y > 0 and glob_u) and glob_u[k.eq_y] or 0
                    local u_ges = math.sqrt(ux^2 + uy^2)
                    local phi = (type(k.eq_m) == "number" and k.eq_m > 0 and glob_u) and glob_u[k.eq_m] or 0
                    
                    gc:setColorRGB(0, 120, 0)
                    
                    local function fm(str)
                        if not str then return "0" end
                        return str:gsub("%*", "·"):gsub("%^2", "²"):gsub("%^3", "³")
                    end

                    if symbolischer_modus then
                        local s_Rx = k.symb_Rx or "0"
                        local s_Ry = k.symb_Ry or "0"
                        local s_Rm = k.symb_Rm or "0"
                        
                        gc:drawString(fm(s_Rx), b - 60, 40)
                        gc:drawString(fm(s_Ry), b - 60, 60)
                        gc:drawString(fm(s_Rm), b - 60, 80)
                    else
                        gc:drawString(formatLabel(k.R_xi or 0), b - 60, 40); gc:drawString(formatLabel(k.R_eta or 0), b - 60, 60); gc:drawString(formatLabel(k.R_m or 0), b - 60, 80)
                    end
                    
                    gc:setColorRGB(255, 120, 0)
                    gc:drawString(string.format("%.4f", ux), b - 60, 100); gc:drawString(string.format("%.4f", uy), b - 60, 120); gc:drawString(string.format("%.4f", u_ges), b - 60, 140); gc:drawString(string.format("%.4f", phi), b - 60, 160)
                    if menuZeile == 8 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 60, 180)
                end
            end

        elseif menuTyp == "stab" then
            local s = staebe[menuIndex]
            if isKinematic then
                gc:drawString("Stab " .. menuIndex .. " (PvV-Modus)", b - 160, 15); gc:setFont("sansserif", "r", 9)
                
                gc:drawString("Verdrehung phi:", b - 160, 40)
                gc:setColorRGB(0, 120, 0)
                local s_phi = kinematic_disk_states and kinematic_disk_states[s.scheibe] and kinematic_disk_states[s.scheibe].type == "rot" and kinematic_disk_states[s.scheibe].phi or 0
                gc:drawString(string.format("%.4f", -s_phi), b - 60, 40)
                
                local w_tot, w_str = getKinematicWork_Stab(menuIndex)
                local current_y = 60
                
                local has_load = (math.abs(s.q) + math.abs(s.q_A or 0) + math.abs(s.q_B or 0) + math.abs(s.n) + math.abs(s.n_A or 0) + math.abs(s.n_B or 0) + math.abs(s.gx or 0) + math.abs(s.gy or 0) + math.abs(s.m or 0)) > 1e-4
                if has_load then
                    gc:setColorRGB(0,0,0)
                    gc:drawString("Lastangriff δ_x:", b - 160, current_y)
                    gc:drawString("Lastangriff δ_y:", b - 160, current_y + 20)
                    local k1, k2 = knoten[s.k1], knoten[s.k2]
                    local dx, dy = k2.x - k1.x, k2.y - k1.y
                    local L = math.sqrt(dx^2 + dy^2)
                    local cosA, sinA = dx/L, dy/L
                    
                    local qA = s.q + (s.q_A or 0); local qB = s.q + (s.q_B or 0)
                    local Rq = (qA + qB)/2 * L + (s.R_q_cas or 0)
                    local Sq = (L^2)/6 * (qA + 2*qB) + (s.S_q_cas or 0)
                    local nA = s.n + (s.n_A or 0); local nB = s.n + (s.n_B or 0)
                    local Rn = (nA + nB)/2 * L + (s.R_n_cas or 0)
                    local Sn = (L^2)/6 * (nA + 2*nB) + (s.S_n_cas or 0)
                    
                    local R_sum = math.abs(Rq) + math.abs(Rn) + math.abs(s.R_gx_cas or 0) + math.abs(s.R_gy_cas or 0)
                    local S_sum = math.abs(Sq) + math.abs(Sn) + math.abs(s.S_gx_cas or 0) + math.abs(s.S_gy_cas or 0)
                    
                    local xs = L/2
                    if R_sum > 1e-6 then xs = S_sum / R_sum end
                    local cx = k1.x + xs * cosA
                    local cy = k1.y + xs * sinA
                    
                    local ux, uy = getKinematicDisp_Point(s.scheibe, cx, cy)
                    gc:setColorRGB(0, 120, 0)
                    gc:drawString(string.format("%.4f", ux), b - 60, current_y)
                    gc:drawString(string.format("%.4f", uy), b - 60, current_y + 20)
                    current_y = current_y + 40
                end
                
                if s.q_gelenk_A or s.n_gelenk_A or (pvv_released_binding and pvv_released_binding.stab == menuIndex and pvv_released_binding.endA and (pvv_released_binding.type == "q_gelenk" or pvv_released_binding.type == "n_gelenk")) then
                    gc:setColorRGB(0,0,0)
                    gc:drawString("Klaffung k1 δ_x:", b - 160, current_y)
                    gc:drawString("Klaffung k1 δ_y:", b - 160, current_y + 20)
                    local u1x, u1y, u2x, u2y = getKinematicDisp_Stab(menuIndex)
                    local n_ux, n_uy = getKinematicDisp(s.k1)
                    gc:setColorRGB(0, 120, 0)
                    gc:drawString(string.format("%.4f", u1x - n_ux), b - 60, current_y)
                    gc:drawString(string.format("%.4f", u1y - n_uy), b - 60, current_y + 20)
                    current_y = current_y + 40
                end
                
                if s.q_gelenk_B or s.n_gelenk_B or (pvv_released_binding and pvv_released_binding.stab == menuIndex and not pvv_released_binding.endA and (pvv_released_binding.type == "q_gelenk" or pvv_released_binding.type == "n_gelenk")) then
                    gc:setColorRGB(0,0,0)
                    gc:drawString("Klaffung k2 δ_x:", b - 160, current_y)
                    gc:drawString("Klaffung k2 δ_y:", b - 160, current_y + 20)
                    local u1x, u1y, u2x, u2y = getKinematicDisp_Stab(menuIndex)
                    local n_ux, n_uy = getKinematicDisp(s.k2)
                    gc:setColorRGB(0, 120, 0)
                    gc:drawString(string.format("%.4f", u2x - n_ux), b - 60, current_y)
                    gc:drawString(string.format("%.4f", u2y - n_uy), b - 60, current_y + 20)
                    current_y = current_y + 40
                end
                
                local is_1last_stab = false
                local is_1last_node = false
                local w_1last_stab = 0
                local w_1last_node = 0
                local proj_1last_stab = 0
                local proj_1last_node = 0
                local force_type = ""
                
                if pvv_released_binding and (pvv_released_binding.type == "q_gelenk" or pvv_released_binding.type == "n_gelenk" or pvv_released_binding.type == "m_gelenk") then
                    local b_stab = staebe[pvv_released_binding.stab]
                    local nodeIdx = pvv_released_binding.endA and b_stab.k1 or b_stab.k2
                    
                    if menuIndex == pvv_released_binding.stab or (s.k1 == nodeIdx or s.k2 == nodeIdx) then
                        if pvv_released_binding.type == "m_gelenk" then
                            if menuIndex == pvv_released_binding.stab then
                                local s_phi = kinematic_disk_states and kinematic_disk_states[s.scheibe] and kinematic_disk_states[s.scheibe].type == "rot" and kinematic_disk_states[s.scheibe].phi or 0
                                proj_1last_stab = -s_phi
                                w_1last_stab = 1.0 * proj_1last_stab
                                is_1last_stab = true
                                force_type = "M"
                            elseif menuIndex ~= pvv_released_binding.stab then
                                local n_phi = getKinematicRot and getKinematicRot(nodeIdx) or 0
                                proj_1last_node = n_phi
                                w_1last_node = -1.0 * proj_1last_node
                                is_1last_node = true
                                force_type = "M"
                            end
                        else
                            local dx, dy = knoten[b_stab.k2].x - knoten[b_stab.k1].x, knoten[b_stab.k2].y - knoten[b_stab.k1].y
                            local L = math.sqrt(dx^2 + dy^2)
                            if L > 0 then
                                local nx, ny = dx/L, dy/L
                                if pvv_released_binding.type == "q_gelenk" then nx, ny = -ny, nx end
                                local dir = pvv_released_binding.endA and -1 or 1
                                local ax, ay = nx * dir, ny * dir
                                
                                if menuIndex == pvv_released_binding.stab then
                                    local u1x, u1y, u2x, u2y = getKinematicDisp_Stab(menuIndex)
                                    local rx = pvv_released_binding.endA and u1x or u2x
                                    local ry = pvv_released_binding.endA and u1y or u2y
                                    proj_1last_stab = ax * rx + ay * ry
                                    w_1last_stab = 1.0 * proj_1last_stab
                                    is_1last_stab = true
                                    force_type = (pvv_released_binding.type == "q_gelenk") and "Q" or "N"
                                elseif menuIndex ~= pvv_released_binding.stab then
                                    local n_ux, n_uy = getKinematicDisp(nodeIdx)
                                    proj_1last_node = ax * n_ux + ay * n_uy
                                    w_1last_node = -1.0 * proj_1last_node
                                    is_1last_node = true
                                    force_type = (pvv_released_binding.type == "q_gelenk") and "Q" or "N"
                                end
                            end
                        end
                    end
                end
                
                if has_load or is_1last_stab or is_1last_node then
                    gc:setColorRGB(0,0,0)
                    gc:drawString("Arbeit W_i:", b - 160, current_y)
                    gc:setColorRGB(200, 50, 50)
                    current_y = current_y + 20
                    local w_ges_parts = {}
                    if type(w_str) == "table" then
                        for _, term in ipairs(w_str) do
                            gc:drawString(term, b - 160, current_y)
                            local eq_part = term:gsub("^[^:]+:%s*", "")
                            table.insert(w_ges_parts, eq_part)
                            current_y = current_y + 15
                        end
                    end
                    if is_1last_stab then
                        gc:drawString(string.format("W_%s: %s * %.2f", force_type, force_type, proj_1last_stab), b - 160, current_y)
                        table.insert(w_ges_parts, string.format("%s*%.2f", force_type, proj_1last_stab))
                        current_y = current_y + 15
                    end
                    if is_1last_node then
                        gc:drawString(string.format("W_%s: %s * %.2f", force_type, force_type, proj_1last_node), b - 160, current_y)
                        table.insert(w_ges_parts, string.format("%s*%.2f", force_type, proj_1last_node))
                        current_y = current_y + 15
                    end
                    current_y = current_y + 5
                    gc:setColorRGB(0, 0, 0)
                    gc:drawLine(b - 160, current_y - 2, b - 10, current_y - 2)
                    gc:drawString("Summe W:", b - 160, current_y + 5)
                    gc:setFont("sansserif", "r", 8)
                    gc:setColorRGB(200, 50, 50)
                    gc:drawString(table.concat(w_ges_parts, " + "), b - 160, current_y + 20)
                    gc:setFont("sansserif", "r", 9)
                end
            else
                gc:drawString("Stab " .. menuIndex .. " < S." .. menuSeite .. "/7 >", b - 160, 15); gc:setFont("sansserif", "r", 9)
                if menuSeite == 1 then
                    gc:drawString("EI (kNm2):", b - 160, 40); gc:drawString("EA (kN):", b - 160, 60); gc:drawString("Last q(x):", b - 160, 80); gc:drawString("Last n(x):", b - 160, 100); gc:drawString("Momentenlast m:", b - 160, 120); gc:drawString("Bogen Radius R:", b - 160, 140)
                    gc:setColorRGB(0, 0, 255)
                    if menuZeile == 1 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 40) else gc:drawString(tostring(s.EI), b - 60, 40) end
                    if menuZeile == 2 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 60) else gc:drawString(tostring(s.EA), b - 60, 60) end
                    if menuZeile == 3 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 80) else gc:drawString(s.q_str or "0", b - 60, 80) end
                    if menuZeile == 4 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 100) else gc:drawString(s.n_str or "0", b - 60, 100) end
                    if menuZeile == 5 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 120) else gc:drawString(s.m_str or tostring(s.m), b - 60, 120) end
                    if menuZeile == 6 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 140) else gc:drawString(tostring(s.bogen_r or 0), b - 60, 140) end
                elseif menuSeite == 2 then
                    gc:drawString("Global pX:", b - 160, 40); gc:drawString("pX projiziert:", b - 160, 60); gc:drawString("Global pY:", b - 160, 80); gc:drawString("pY projiziert:", b - 160, 100)
                    gc:setColorRGB(0, 0, 255)
                    if menuZeile == 1 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 40) else gc:drawString(s.gx_str or tostring(s.gx or 0), b - 60, 40) end
                    gc:drawString((s.gx_proj and "Ja" or "Nein"), b - 60, 60)
                    if menuZeile == 3 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 80) else gc:drawString(s.gy_str or tostring(s.gy or 0), b - 60, 80) end
                    gc:drawString((s.gy_proj and "Ja" or "Nein"), b - 60, 100)
                elseif menuSeite == 3 then
                    gc:drawString("Trapez q Start:", b - 160, 40); gc:drawString("Trapez q Ende:", b - 160, 60); gc:drawString("Trapez n Start:", b - 160, 80); gc:drawString("Trapez n Ende:", b - 160, 100)
                    gc:drawString("Temp. T_oben:", b - 160, 120); gc:drawString("Temp. T_unten:", b - 160, 140); gc:drawString("Alpha_t:", b - 160, 160); gc:drawString("Höhe h (m):", b - 160, 180)
                    gc:setColorRGB(0, 0, 255)
                    if menuZeile == 1 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 40) else gc:drawString(s.q_A_str or tostring(s.q_A or 0), b - 60, 40) end
                    if menuZeile == 2 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 60) else gc:drawString(s.q_B_str or tostring(s.q_B or 0), b - 60, 60) end
                    if menuZeile == 3 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 80) else gc:drawString(s.n_A_str or tostring(s.n_A or 0), b - 60, 80) end
                    if menuZeile == 4 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 100) else gc:drawString(s.n_B_str or tostring(s.n_B or 0), b - 60, 100) end
                    if menuZeile == 5 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 120) else gc:drawString(tostring(s.To), b - 60, 120) end
                    if menuZeile == 6 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 140) else gc:drawString(tostring(s.Tu), b - 60, 140) end
                    if menuZeile == 7 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 160) else gc:drawString(tostring(s.alpha), b - 60, 160) end
                    if menuZeile == 8 and eingabeModus then gc:drawString(eingabeText .. "_", b - 60, 180) else gc:drawString(tostring(s.h), b - 60, 180) end
                elseif menuSeite == 4 then
                    gc:drawString("M-Gelenk Start:", b - 160, 40); gc:drawString("M-Gelenk Ende:", b - 160, 60); gc:drawString("N-Gelenk Start:", b - 160, 80); gc:drawString("N-Gelenk Ende:", b - 160, 100); gc:drawString("Q-Gelenk Start:", b - 160, 120); gc:drawString("Q-Gelenk Ende:", b - 160, 140)
                    gc:setColorRGB(0, 0, 255)
                    gc:drawString(s.gelenk_A and "Ja" or "Nein", b - 60, 40); gc:drawString(s.gelenk_B and "Ja" or "Nein", b - 60, 60)
                    gc:drawString(s.n_gelenk_A and "Ja" or "Nein", b - 60, 80); gc:drawString(s.n_gelenk_B and "Ja" or "Nein", b - 60, 100)
                    gc:drawString(s.q_gelenk_A and "Ja" or "Nein", b - 60, 120); gc:drawString(s.q_gelenk_B and "Ja" or "Nein", b - 60, 140)
                elseif menuSeite == 5 then
                    gc:drawString("Na (Start):", b - 160, 40); gc:drawString("Qa (Start):", b - 160, 60); gc:drawString("Ma (Start):", b - 160, 80); gc:drawString("Nb (Ende):", b - 160, 100); gc:drawString("Qb (Ende):", b - 160, 120); gc:drawString("Mb (Ende):", b - 160, 140)
                    gc:setColorRGB(0, 120, 0)
                    
                    local function fm(str)
                        if not str then return "0" end
                        return str:gsub("%*", "·"):gsub("%^2", "²"):gsub("%^3", "³")
                    end

                    if symbolischer_modus then
                        gc:drawString(fm(s.symb_N_start), b - 60, 40); gc:drawString(fm(s.symb_Q_start), b - 60, 60); gc:drawString(fm(s.symb_M_start), b - 60, 80)
                        gc:drawString(fm(s.symb_N_end), b - 60, 100); gc:drawString(fm(s.symb_Q_end), b - 60, 120); gc:drawString(fm(s.symb_M_end), b - 60, 140)
                    else
                        gc:drawString(formatLabel(-s.s_local[1] or 0), b - 60, 40); gc:drawString(formatLabel(-s.s_local[2] or 0), b - 60, 60); gc:drawString(formatLabel(-s.s_local[3] or 0), b - 60, 80)
                        gc:drawString(formatLabel(s.s_local[4] or 0), b - 60, 100); gc:drawString(formatLabel(s.s_local[5] or 0), b - 60, 120); gc:drawString(formatLabel(s.s_local[6] or 0), b - 60, 140)
                    end
                elseif menuSeite == 6 then
                    gc:drawString("h_a (links+):", b - 160, 40); gc:drawString("v_a (oben+):", b - 160, 60); gc:drawString("M_a (Uhrz.+):", b - 160, 80); gc:drawString("h_b (rechts+):", b - 160, 100); gc:drawString("v_b (unten+):", b - 160, 120); gc:drawString("M_b (Gegen-U.+):", b - 160, 140)
                    gc:setColorRGB(0, 120, 0)
    
                    local k1, k2 = knoten[s.k1], knoten[s.k2]
                    local dx, dy = k2.x - k1.x, k2.y - k1.y
                local L = math.sqrt(dx^2 + dy^2)
                if L > 0 then
                    local c, s_val = dx/L, -dy/L
                    local Na, Va, Ma = s.s_local[1] or 0, s.s_local[2] or 0, s.s_local[3] or 0
                    local Nb, Vb, Mb = s.s_local[4] or 0, s.s_local[5] or 0, s.s_local[6] or 0

                    local loadAppliedMenu = {}
                    local offsetX_A, offsetY_A, offsetM_A = 0, 0, 0
                    local offsetRx_A, offsetRy_A, offsetRm_A = 0, 0, 0
                    local offsetX_B, offsetY_B, offsetM_B = 0, 0, 0
                    local offsetRx_B, offsetRy_B, offsetRm_B = 0, 0, 0

                    for idx, temp_s in ipairs(staebe) do
                        local explA = knoten[temp_s.k1].gelenk or temp_s.gelenk_A or temp_s.n_gelenk_A or temp_s.q_gelenk_A
                        local explB = knoten[temp_s.k2].gelenk or temp_s.gelenk_B or temp_s.n_gelenk_B or temp_s.q_gelenk_B
                        if explA and not loadAppliedMenu[temp_s.k1] then
                            if idx == menuIndex then
                                local kn = knoten[temp_s.k1]
                                offsetX_A = kn.last_x; offsetY_A = kn.last_y; offsetM_A = kn.last_m
                                local isSupp = kn.lager_x or kn.lager_y or kn.lager_m or kn.cx > 0 or kn.cy > 0 or kn.cm > 0
                                offsetRx_A = isSupp and kn.Rx_glob or 0; offsetRy_A = isSupp and kn.Ry_glob or 0; offsetRm_A = isSupp and kn.Rm_glob or 0
                            end
                            loadAppliedMenu[temp_s.k1] = true
                        end
                        if explB and not loadAppliedMenu[temp_s.k2] then
                            if idx == menuIndex then
                                local kn = knoten[temp_s.k2]
                                offsetX_B = kn.last_x; offsetY_B = kn.last_y; offsetM_B = kn.last_m
                                local isSupp = kn.lager_x or kn.lager_y or kn.lager_m or kn.cx > 0 or kn.cy > 0 or kn.cm > 0
                                offsetRx_B = isSupp and kn.Rx_glob or 0; offsetRy_B = isSupp and kn.Ry_glob or 0; offsetRm_B = isSupp and kn.Rm_glob or 0
                            end
                            loadAppliedMenu[temp_s.k2] = true
                        end
                    end

                    local uxA, uyA = dx/L, dy/L
                    local nxA, nyA = -uyA, uxA
                    local uxB, uyB = dx/L, dy/L
                    local nxB, nyB = -uyB, uxB
                    
                    if (s.bogen_r or 0) ~= 0 then
                        local true_L = (L / drawPxProMeter)
                        local R = math.abs(s.bogen_r)
                        local sgn = s.bogen_r > 0 and -1 or 1
                        local function getTang(t)
                            local xl = (t - 0.5) * true_L
                            local denom = math.sqrt(math.max(1e-6, R^2 - xl^2))
                            local tx_l, ty_l = 1, -sgn * (xl / denom)
                            local len = math.sqrt(tx_l^2 + ty_l^2)
                            tx_l, ty_l = tx_l/len, ty_l/len
                            local t_gx = tx_l * (dx/L) - ty_l * (dy/L)
                            local t_gy = tx_l * (dy/L) + ty_l * (dx/L)
                            return t_gx, t_gy, -t_gy, t_gx
                        end
                        uxA, uyA, nxA, nyA = getTang(0)
                        uxB, uyB, nxB, nyB = getTang(1)
                    end

                    local Fx_a = Na * uxA + Va * nxA - (offsetX_A + offsetRx_A)
                    local Fy_a = Na * uyA + Va * nyA - (offsetY_A + offsetRy_A)
                    local Fx_b = Nb * uxB + Vb * nxB - (offsetX_B + offsetRx_B)
                    local Fy_b = Nb * uyB + Vb * nyB - (offsetY_B + offsetRy_B)

                    local M_a_disp = -(Ma - (offsetM_A + offsetRm_A))
                    local M_b_disp = Mb - (offsetM_B + offsetRm_B)

            local s_Fx_a, s_Fy_a, s_Fx_b, s_Fy_b = nil, nil, nil, nil
            if symbolischer_modus then
                s_Fx_a = s.symb_Fx_a or s.symb_N_start
                s_Fy_a = s.symb_Fy_a or s.symb_Q_start
                s_Fx_b = s.symb_Fx_b or s.symb_N_end
                s_Fy_b = s.symb_Fy_b or s.symb_Q_end
            end

                    local function cl(v) return math.abs(v) < 1e-4 and 0 or v end
                    
                    local function fm(str)
                        if not str then return "0" end
                        return str:gsub("%*", "·"):gsub("%^2", "²"):gsub("%^3", "³")
                    end

                    if symbolischer_modus then
                        -- Für Gelenkkräfte ignorieren wir im symbolischen Modus die Auflagerkräfte, da diese numerisch (z.B. 0.5) berechnet wurden.
                        -- Bei geraden Einfeldträgern sind uxA, uyA entweder 1 oder 0, sodass die Projektion trivial ist.
                        local s_Fx_a = s.symb_Fx_a_disp or ("-(" .. (s.symb_N_start or "0") .. ")")
                        local s_Fy_a = s.symb_Fy_a_disp or ("-(" .. (s.symb_Q_start or "0") .. ")")
                        local s_Fx_b = s.symb_Fx_b or s.symb_N_end
                        local s_Fy_b = s.symb_Fy_b or s.symb_Q_end
                        
                        gc:drawString(fm(s_Fx_a), b - 60, 40)
                        gc:drawString(fm(s_Fy_a), b - 60, 60)
                        gc:drawString(fm(s.symb_Ma_disp or "0"), b - 60, 80)
                        gc:drawString(fm(s_Fx_b), b - 60, 100)
                        gc:drawString(fm(s_Fy_b), b - 60, 120)
                        gc:drawString(fm(s.symb_M_end), b - 60, 140)
                    else
                        gc:drawString(string.format("%.2f kN", cl(-Fx_a)), b - 60, 40)
                        gc:drawString(string.format("%.2f kN", cl(-Fy_a)), b - 60, 60)
                        gc:drawString(string.format("%.2f kNm", cl(M_a_disp)), b - 60, 80)
                        gc:drawString(string.format("%.2f kN", cl(Fx_b)), b - 60, 100)
                        gc:drawString(string.format("%.2f kN", cl(Fy_b)), b - 60, 120)
                        gc:drawString(string.format("%.2f kNm", cl(M_b_disp)), b - 60, 140)
                    end
                end
            elseif menuSeite == 7 then
                gc:drawString("ua (m):", b - 160, 40); gc:drawString("va (m):", b - 160, 60); gc:drawString("phi_a (rad):", b - 160, 80); gc:drawString("ub (m):", b - 160, 100); gc:drawString("vb (m):", b - 160, 120); gc:drawString("phi_b (rad):", b - 160, 140)
                gc:setColorRGB(180, 0, 180)
                gc:drawString(string.format("%.3e", s.v_local[1] or 0):gsub("%.", ","), b - 70, 40); gc:drawString(string.format("%.3e", s.v_local[2] or 0):gsub("%.", ","), b - 70, 60); gc:drawString(string.format("%.3e", s.v_local[3] or 0):gsub("%.", ","), b - 70, 80)
                gc:drawString(string.format("%.3e", s.v_local[4] or 0):gsub("%.", ","), b - 70, 100); gc:drawString(string.format("%.3e", s.v_local[5] or 0):gsub("%.", ","), b - 70, 120); gc:drawString(string.format("%.3e", s.v_local[6] or 0):gsub("%.", ","), b - 70, 140)
                gc:setColorRGB(0, 0, 0); gc:drawString("In TI speichern:", b - 160, 160)
                if menuZeile == 7 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 160)
            end
        end

        elseif menuTyp == "pvv_knoten" then
            local k = knoten[menuIndex]
            gc:drawString("PvV-Bindungslösung", b - 160, 15); gc:setFont("sansserif", "r", 9)
            gc:drawString("Lager X entfernen", b - 160, 40)
            gc:drawString("Lager Y entfernen", b - 160, 60)
            gc:drawString("Lager M entfernen", b - 160, 80)
            local rod_count = 0
            for _, s in ipairs(staebe) do if s.k1 == menuIndex or s.k2 == menuIndex then rod_count = rod_count + 1 end end
            
            if rod_count == 2 then
                gc:drawString("Gelenk einfügen", b - 160, 100)
            else
                gc:setColorRGB(150, 150, 150)
                gc:drawString("Gelenk (nur bei 2 Stäben)", b - 160, 100)
            end
            
            gc:setColorRGB(0, 0, 255)
            if menuZeile == 1 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
            if not k.lager_x then gc:setColorRGB(150, 150, 150) end
            gc:drawString(k.lager_x and "Ja" or "Fehlt", b - 60, 40)
            
            if menuZeile == 2 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
            if not k.lager_y then gc:setColorRGB(150, 150, 150) end
            gc:drawString(k.lager_y and "Ja" or "Fehlt", b - 60, 60)
            
            if menuZeile == 3 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
            if not k.lager_m then gc:setColorRGB(150, 150, 150) end
            gc:drawString(k.lager_m and "Ja" or "Fehlt", b - 60, 80)
            
            if rod_count == 2 then
                if menuZeile == 4 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                if k.gelenk then gc:setColorRGB(150, 150, 150) end
                gc:drawString(not k.gelenk and "Einfügen" or "Vorhanden", b - 60, 100)
            end
        elseif menuTyp == "pvv_stab" then
            local s = staebe[menuIndex]
            gc:drawString("PvV-Stablösung", b - 160, 15); gc:setFont("sansserif", "r", 9)
            gc:drawString("M-Gelenk A", b - 160, 40)
            gc:drawString("M-Gelenk B", b - 160, 60)
            gc:drawString("N-Gelenk A", b - 160, 80)
            gc:drawString("N-Gelenk B", b - 160, 100)
            gc:drawString("Q-Gelenk A", b - 160, 120)
            gc:drawString("Q-Gelenk B", b - 160, 140)
            
            if menuZeile == 1 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
            if s.gelenk_A then gc:setColorRGB(150, 150, 150) end
            gc:drawString(not s.gelenk_A and "Einfügen" or "Vorh.", b - 60, 40)
            
            if menuZeile == 2 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
            if s.gelenk_B then gc:setColorRGB(150, 150, 150) end
            gc:drawString(not s.gelenk_B and "Einfügen" or "Vorh.", b - 60, 60)
            
            if menuZeile == 3 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
            if s.n_gelenk_A then gc:setColorRGB(150, 150, 150) end
            gc:drawString(not s.n_gelenk_A and "Einfügen" or "Vorh.", b - 60, 80)
            
            if menuZeile == 4 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
            if s.n_gelenk_B then gc:setColorRGB(150, 150, 150) end
            gc:drawString(not s.n_gelenk_B and "Einfügen" or "Vorh.", b - 60, 100)
            
            if menuZeile == 5 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 120)
                            if menuZeile == 6 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 140)
                            if menuZeile == 7 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
            if s.q_gelenk_A then gc:setColorRGB(150, 150, 150) end
            gc:drawString(not s.q_gelenk_A and "Einfügen" or "Vorh.", b - 60, 120)
            
            if menuZeile == 6 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
            gc:drawString(not s.q_gelenk_B and "Einfügen" or "Vorh.", b - 60, 140)
        elseif menuTyp == "obermenue" then
            gc:drawString("Einstellungen < S." .. menuSeite .. "/4 >", b - 200, 15); gc:setFont("sansserif", "r", 9)
            if menuSeite == 1 then
                gc:drawString("Raster (m):", b - 200, 40)
                gc:drawString("Alle EA setzen:", b - 200, 60)
                gc:drawString("Alle EI setzen:", b - 200, 80)
                gc:drawString("Starr-Modus:", b - 200, 100)
                gc:drawString("Auto-KGV Solver:", b - 200, 120)
                gc:drawString("Anzeige N:", b - 200, 140)
                gc:drawString("Schnittgrößen Modus:", b - 200, 160)
                gc:drawString("Fachwerk-Modus:", b - 200, 180)

                gc:setColorRGB(0, 0, 255)
                if menuZeile == 1 and eingabeModus then gc:drawString(eingabeText .. "_", b - 80, 40) else gc:drawString(rasterMass_str or tostring(rasterMass), b - 80, 40) end
                if menuZeile == 2 and eingabeModus then gc:drawString(eingabeText .. "_", b - 80, 60) else gc:drawString(defEA_str or string.format("%.3e", defEA):gsub("%.", ","), b - 80, 60) end
                if menuZeile == 3 and eingabeModus then gc:drawString(eingabeText .. "_", b - 80, 80) else gc:drawString(defEI_str or string.format("%.3e", defEI):gsub("%.", ","), b - 80, 80) end
                if menuZeile == 4 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                gc:drawString("Aktivieren", b - 80, 100)
                if menuZeile == 5 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                gc:drawString(autoKGV and "An" or "Aus", b - 80, 120)
                if menuZeile == 6 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                gc:drawString(zeigeN and "An" or "Aus", b - 80, 140)
                if menuZeile == 7 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                gc:drawString((schnittAnzeigeModus == "Hover") and "Hover" or "Start&End", b - 80, 160)
                if menuZeile == 8 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                gc:drawString(fachwerkModus and "An" or "Aus", b - 80, 180)

            elseif menuSeite == 2 then
                gc:drawString("Alles Exportieren:", b - 200, 40)
                gc:drawString("Nur Biegelinien exp.:", b - 200, 60)
                gc:drawString("Nur Längslinien exp.:", b - 200, 80)
                gc:drawString("KGV Daten exp.:", b - 200, 100)
                gc:drawString("Arbeitssatz exp.:", b - 200, 120)
                gc:drawString("Nur Schnittgrößen exp.:", b - 200, 140)
                gc:drawString("LGS Matrix exp.:", b - 200, 160)

                gc:setColorRGB(0, 0, 255)
                if menuZeile == 1 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 40)
                
                if menuZeile == 2 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 60)
                
                if menuZeile == 3 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 80)
                
                if menuZeile == 4 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 100)
                
                if menuZeile == 5 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 120)
                
                if menuZeile == 6 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 140)
                
                if menuZeile == 7 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                            gc:drawString("Export", b - 70, 160)
            elseif menuSeite == 3 then
                gc:drawString("CAS Bruch-Tol. (1E-x):", b - 200, 40)
                gc:drawString("Punkte/Stab (Graph):", b - 200, 60)
                gc:drawString("Zoom-Schritt Normal:", b - 200, 80)
                gc:drawString("Zoom-Schritt Expl.:", b - 200, 100)
                gc:drawString("Bemaßung zeigen:", b - 200, 120)
                gc:drawString("Bogen-Segmente:", b - 200, 140)
                gc:drawString("Zahlen-Format:", b - 200, 160)
                gc:drawString("Maximalwerte an/aus:", b - 200, 180)

                gc:setColorRGB(0, 0, 255)
                if menuZeile == 1 and eingabeModus then gc:drawString(eingabeText .. "_", b - 80, 40) else gc:drawString(tostring(casToleranz), b - 80, 40) end
                if menuZeile == 2 and eingabeModus then gc:drawString(eingabeText .. "_", b - 80, 60) else gc:drawString(tostring(ptsBiegelinie), b - 80, 60) end
                if menuZeile == 3 and eingabeModus then gc:drawString(eingabeText .. "_", b - 80, 80) else gc:drawString(tostring(zoomNormal), b - 80, 80) end
                if menuZeile == 4 and eingabeModus then gc:drawString(eingabeText .. "_", b - 80, 100) else gc:drawString(tostring(zoomExplosion), b - 80, 100) end
                
                gc:setColorRGB(0, 0, 255)
                if menuZeile == 5 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                gc:drawString(zeigeBemassung and "An" or "Aus", b - 80, 120)
                
                gc:setColorRGB(0, 0, 255)
                if menuZeile == 6 and eingabeModus then gc:drawString(eingabeText .. "_", b - 80, 140) else gc:drawString(tostring(bogenSegmente), b - 80, 140) end

                gc:setColorRGB(0, 0, 255)
                if menuZeile == 7 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                local fmtStr = "Wurzelbrüche"
                if zahlenFormat == 2 then fmtStr = "Nur Brüche"
                elseif zahlenFormat == 3 then fmtStr = "Dezimal" end
                gc:drawString(fmtStr, b - 80, 160)
                
                gc:setColorRGB(0, 0, 255)
                if menuZeile == 8 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                gc:drawString(zeigeMaxWerte and "An" or "Aus", b - 80, 180)
            elseif menuSeite == 4 then
                gc:drawString("Polstrahle zeichnen:", b - 200, 40)
                gc:setColorRGB(0, 0, 255)
                if menuZeile == 1 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                
                local polStr = "Notwendige"
                local pm = polstrahlModus or 1
                if pm == 0 then polStr = "Keine"
                elseif pm == 2 then polStr = "Alle" end
                
                gc:drawString(polStr, b - 80, 40)
                
                gc:setColorRGB(0, 0, 0)
                gc:drawString("Verlauf-Skalierung:", b - 200, 60)
                gc:setColorRGB(0, 0, 255)
                if menuZeile == 2 and eingabeModus then gc:drawString(eingabeText .. "_", b - 80, 60) else
                    if menuZeile == 2 then gc:setColorRGB(200, 0, 0) else gc:setColorRGB(0, 0, 255) end
                    gc:drawString(string.format("%.2f", verlaufSkalierung or 1), b - 80, 60)
                end
            end
        end
    end
    ansichtsModus = orig_ansichtsModus
end