-- Querschnitt.lua gegen Handrechnung: Querschnittswerte, Anzeige, sigma, Schub, Torsion.
-- Interne Koordinaten: u nach rechts, v nach oben. Standardanzeige (rotation 180): y = -u, z = -v.
-- Aufruf: luajit Emulator/tests/querschnitt.lua [Filter]
local T = dofile((debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])") or ".\\") .. 'qs_common.lua')
local Q, P = T.Q, T.P
local fall, zahl, wahr = T.fall, T.zahl, T.wahr

-- Traegheitsmoment um eine Schwerachse mit Richtung theta (intern, gegen den Uhrzeigersinn ab u)
local function I_achse(r, theta)
    return r.IyS * math.cos(theta) ^ 2 + r.IzS * math.sin(theta) ^ 2 + r.IyzS * math.sin(2 * theta)
end

-- ============================================================ Querschnittswerte
fall('1 Kreisabschnitt', function()
    T.abschnitt('Befund 1: Kreisabschnitt (Segment) R=1, 120 Grad, symmetrisch zur senkrechten Achse')
    local R, a1, a2 = 1, math.rad(30), math.rad(150)
    T.massiv({ type = 'segment', points = { P(0, 0), P(R * math.cos(a1), R * math.sin(a1)), P(R * math.cos(a2), R * math.sin(a2)) } })
    local r = T.rechne()
    -- Referenz: Streifenintegration ueber v von R*cos(60) bis R
    local n, v0 = 200000, R * math.cos(math.rad(60))
    local A, Sv, Ivv, Iuu = 0, 0, 0, 0
    local dv = (R - v0) / n
    for i = 0, n - 1 do
        local v = v0 + (i + 0.5) * dv
        local b = 2 * math.sqrt(R ^ 2 - v ^ 2)
        A, Sv, Ivv, Iuu = A + b * dv, Sv + v * b * dv, Ivv + v ^ 2 * b * dv, Iuu + b ^ 3 / 12 * dv
    end
    local vs = Sv / A
    zahl('A', r.A, A, 1e-6)
    zahl('z-Schwerpunkt (intern v_s)', r.zs, vs, 1e-6)
    zahl('I um waagerechte Schwerachse (IyS)', r.IyS, Ivv - A * vs ^ 2, 1e-5)
    zahl('I um senkrechte Schwerachse (IzS)', r.IzS, Iuu, 1e-5)
    T.reset()
    T.massiv({ type = 'segment', points = { P(0, 0), P(4, 0), P(0, 4) } })
    r = T.rechne()
    zahl('Viertelkreis-Abschnitt R=4: I_1,S = 7.599', r.I1, 7.599, 2e-4)
    zahl('Viertelkreis-Abschnitt R=4: I_2,S = 0.4326', r.I2, 0.4326, 2e-4)
end)

fall('2 Numerische Teilflaechen', function()
    T.abschnitt('Befund 2: numerisch addierte Ueberlappung, 6x2-Rechteck aus zwei Rechtecken')
    T.massiv({ type = 'rect', points = { P(0, 0), P(4, 2) } })
    T.massiv({ type = 'rect', points = { P(2, 0), P(6, 2) }, is_numeric = true })
    local r = T.rechne()
    zahl('A = 12', r.A, 12, 5e-3)
    zahl('IyS = 6*2^3/12 = 4', r.IyS, 4, 1e-2)
    zahl('IzS = 2*6^3/12 = 36', r.IzS, 36, 1e-2)
    zahl('I_1,S = 36', r.I1, 36, 1e-2)
    zahl('I_2,S = 4', r.I2, 4, 1e-2)
end)

fall('3 Halbkreis an Rechteck', function()
    T.abschnitt('Ueberlappungserkennung: Rechteck 4x4 + Halbkreis r=2 an der Kante (Beispiel mit Screenshot)')
    T.massiv({ type = 'rect', points = { P(0, 0), P(4, 4) } })
    local halb = { type = 'sector', points = { P(4, 2), P(4, 0), P(4, 4) } }
    wahr('Kantenberuehrung ist keine Ueberlappung', Q.overlap(halb) == 'none', Q.overlap(halb))
    T.massiv(halb)
    local r = T.rechne()
    zahl('A = 16 + 2 pi', r.A, 16 + 2 * math.pi, 1e-9)
    zahl('u_s = 2.80328', r.ys, 2.803279, 1e-5)
    zahl('IyS = 27.6165', r.IyS, 27.61652, 1e-5)
    zahl('IzS = 59.7041', r.IzS, 59.70407, 1e-5)
    -- echte Ueberlappungen muessen weiter erkannt werden
    wahr('schmaler Streifen (3.3..8) ueberlappt', Q.overlap({ type = 'rect', points = { P(3.3, 0), P(8, 4) } }) == 'partial')
    wahr('Halbkreis 1 mm hineingeschoben ueberlappt', Q.overlap({ type = 'sector', points = { P(3, 2), P(3, 0), P(3, 4) } }) == 'partial')
    wahr('Kreis ganz innen -> Loch', Q.overlap({ type = 'circle', points = { P(2, 2), P(3, 2) } }) == 'inside')
    wahr('Rechteck links daneben -> keine Ueberlappung', Q.overlap({ type = 'rect', points = { P(-4, 0), P(0, 4) } }) == 'none')
end)

fall('10 Widerstandsmoment Halbkreis', function()
    T.abschnitt('Befund 10: Widerstandsmoment Halbkreis R=3 (oben)')
    T.massiv({ type = 'sector', points = { P(0, 0), P(3, 0), P(-3, 0) } })
    local r = T.rechne()
    local R = 3
    local e = R - 4 * R / (3 * math.pi)
    local Iy = (math.pi / 8 - 8 / (9 * math.pi)) * R ^ 4
    zahl('IyS = (pi/8 - 8/(9 pi)) R^4', r.IyS, Iy, 1e-9)
    zahl('W_y = IyS / (R - 4R/(3pi)) = 5.149', r.Wu, Iy / e, 1e-6)
    zahl('W_z = (pi R^4/8)/R', r.Wv, math.pi * R ^ 4 / 8 / R, 1e-6)
end)

fall('12 Hauptachsenwinkel', function()
    T.abschnitt('Befund 12: gleichschenkliges L (I_y = I_z), Hauptachse 1 muss I_1 liefern')
    for _, spiegel in ipairs({ 1, -1 }) do
        T.reset()
        T.massiv({ type = 'rect', points = { P(0, 0), P(spiegel * 1, 10) } })
        T.massiv({ type = 'rect', points = { P(spiegel * 1, 0), P(spiegel * 10, 1) } })
        local r = T.rechne()
        zahl(string.format('Spiegel %d: I um Achse alpha = I_1', spiegel), I_achse(r, r.alpha), r.I1, 1e-9)
        zahl(string.format('Spiegel %d: |alpha| = 45 Grad', spiegel), math.abs(math.deg(r.alpha)), 45, 1e-9)
    end
end)

-- ============================================================ Anzeige / KOS-Drehung
fall('3 KOS-Drehung', function()
    T.abschnitt('Befund 3: Rechteck 40x60 (Anzeige 0..40, 0..60 bei 180 Grad), Ergebnisfeld bei 180/90/270 Grad')
    T.massiv({ type = 'rect', points = { P(0, 0), P(-40, -60) } })
    T.rechne()
    local soll = {
        [180] = { ys = 20, zs = 30, Iy = 2.88e6, Iz = 1.28e6, Iyz = -1.44e6, alpha = 0 },
        [90] = { ys = -30, zs = 20, Iy = 1.28e6, Iz = 2.88e6, Iyz = 1.44e6, alpha = 90 },
        [270] = { ys = 30, zs = -20, Iy = 1.28e6, Iz = 2.88e6, Iyz = 1.44e6, alpha = 90 },
    }
    -- die Zahlen oben gelten fuer den Bezug KOS-Ursprung (Obermenue: FTM-Bezug)
    Q.ftmBezug('kos')
    for _, rot in ipairs({ 180, 90, 270 }) do
        Q.setRotation(rot)
        local t = T.ergebnisfeld()
        local s = soll[rot]
        zahl(rot .. ' Grad: y_s', T.zeileWert(t, 'y_s'), s.ys, 1e-3)
        zahl(rot .. ' Grad: z_s', T.zeileWert(t, 'z_s'), s.zs, 1e-3)
        zahl(rot .. ' Grad: I_y (KOS)', T.zeileWert(t, 'I_y (KOS)'), s.Iy, 1e-3)
        zahl(rot .. ' Grad: I_z (KOS)', T.zeileWert(t, 'I_z (KOS)'), s.Iz, 1e-3)
        zahl(rot .. ' Grad: I_yz (KOS)', T.zeileWert(t, 'I_yz (KOS)'), s.Iyz, 1e-3)
        zahl(rot .. ' Grad: |alpha|', math.abs(T.zeileWert(t, 'alpha') or 999), s.alpha, 1e-3)
    end
    -- Standard ist der Schwerpunkt: I_y,S = 40*60^3/12, I_z,S = 60*40^3/12, I_yz,S = 0
    Q.ftmBezug('schwerpunkt')
    Q.setRotation(180)
    local ts = T.ergebnisfeld()
    zahl('Schwerpunkt: I_y,S', T.zeileWert(ts, 'I_y,S'), 40 * 60 ^ 3 / 12, 1e-6)
    zahl('Schwerpunkt: I_z,S', T.zeileWert(ts, 'I_z,S'), 60 * 40 ^ 3 / 12, 1e-6)
    zahl('Schwerpunkt: I_yz,S', T.zeileWert(ts, 'I_yz,S'), 0, 1e-6)
end)

fall('4 Sigma', function()
    T.abschnitt('Befund 4: Rechteck 40x60 um den Ursprung, My = 1000 Nm (nach Gross: Zug bei z = +30)')
    T.massiv({ type = 'rect', points = { P(-20, -30), P(20, 30) } })
    T.rechne()
    -- bei 180 Grad: z ueber die Hoehe 60 (I_y = 40*60^3/12); bei 90/270 Grad liegt z ueber der Breite 40
    local soll = { [180] = { I = 40 * 60 ^ 3 / 12, e = 30 }, [90] = { I = 60 * 40 ^ 3 / 12, e = 20 }, [270] = { I = 60 * 40 ^ 3 / 12, e = 20 } }
    for _, rot in ipairs({ 180, 90, 270 }) do
        Q.setRotation(rot)
        local s = Q.sigma(0, 1e6, 0)
        wahr(rot .. ' Grad: sigma berechnet', s ~= nil)
        if s then
            local _, zmax = Q.cfd(s.max_y, s.max_z)
            zahl(rot .. ' Grad: sigma_max = My/I_y * z_max', s.sigma_max, 1e6 / soll[rot].I * soll[rot].e, 1e-6)
            zahl(rot .. ' Grad: sigma_max bei z = +z_max (Anzeige)', zmax, soll[rot].e, 1e-9)
        end
    end
    Q.setRotation(180)
    local s = Q.sigma(0, 0, 1e6)
    local ymax = Q.cfd(s.max_y, s.max_z)
    -- Gross: sigma = -Mz/Iz * y  -> Zug bei y = -20
    zahl('Mz = 1000 Nm: sigma_max bei y = -20 (Anzeige)', ymax, -20, 1e-9)
end)

-- ============================================================ Duennwandig: Schub
local function kasten(t_flansch, t_steg, start)
    -- Kasten 10 x 6, Mittellinie
    local pkte = { P(-5, 3), P(5, 3), P(5, -3), P(-5, -3) }
    local dick = { t_flansch, t_steg, t_flansch, t_steg }
    for i = 0, 3 do
        local k = (i + (start or 0)) % 4 + 1
        T.duenn(pkte[k], pkte[k % 4 + 1], dick[k])
    end
end

-- Resultierende des Schubflusses (Kraft und Moment um den Ursprung) aus den Stuetzstellen
local function resultierende(samples)
    local Fu, Fv, Mo = 0, 0, 0
    for _, s in ipairs(samples or {}) do
        local w = (s.parameter and (s.parameter <= 1e-9 or s.parameter >= 1 - 1e-9)) and 0.5 or 1
        local f = (s.tau_a + s.tau_b) * s.thickness * s.ds * w
        Fu, Fv = Fu + f * s.tangent_u, Fv + f * s.tangent_v
        Mo = Mo + (s.u * s.tangent_v - s.v * s.tangent_u) * f
    end
    return Fu, Fv, Mo
end

-- Vertraeglichkeit der Zelle: Umlaufintegral tau/t ds (im Umlaufsinn) muss null sein
local function umlaufTauDurchT(samples)
    local summe, laenge = 0, 0
    for _, s in ipairs(samples or {}) do
        if s.in_cell then
            local w = (s.parameter <= 1e-9 or s.parameter >= 1 - 1e-9) and 0.5 or 1
            summe = summe + s.tau * (s.cell_sign or 1) * s.ds * w / s.thickness
            laenge = laenge + s.ds * w / s.thickness
        end
    end
    return summe, laenge
end

fall('5 Kasten doppeltsymmetrisch', function()
    T.abschnitt('Befund 5: Kasten 10x6, t=1, doppeltsymmetrisch, einzellig')
    for _, start in ipairs({ 0, 1 }) do
        T.reset(); kasten(1, 1, start); T.rechne()
        local ra = Q.schub(1, 0)
        wahr('Start ' .. start .. ': Q_a berechnet', ra ~= nil, Q.status())
        if ra then zahl('Start ' .. start .. ': Q_a=1: tau_max = 27.5/466.67 = 0.05893', ra.max_tau, 27.5 / (2 * 6 * 25 + 2 * 1000 / 12), 1e-3) end
        local rb = Q.schub(0, 1)
        if rb then zahl('Start ' .. start .. ': Q_b=1: tau_max = 19.5/216 = 0.09028', rb.max_tau, 19.5 / 216, 1e-3) end
        local _, samples = Q.duennSchub(1, 0)
        local Fu, Fv = resultierende(samples)
        zahl('Start ' .. start .. ': Resultierende Q_a: |F_u| = 1', math.abs(Fu), 1, 1e-3)
        zahl('Start ' .. start .. ': Resultierende Q_a: F_v = 0', Fv, 0, 1e-3)
        local m = Q.smp()
        wahr('Start ' .. start .. ': Schubmittelpunkt bekannt', m and m.known)
        if m and m.known then
            zahl('Start ' .. start .. ': Schubmittelpunkt u = 0', m.u, 0, 1e-3)
            zahl('Start ' .. start .. ': Schubmittelpunkt v = 0', m.v, 0, 1e-3)
        end
    end
end)

fall('5b Trapezkasten einfachsymmetrisch', function()
    T.abschnitt('Einzellig, nur zur senkrechten Achse symmetrisch: Q parallel zur Achse per Symmetrie, quer dazu per Vertraeglichkeit')
    T.zug({ -6, 3, 6, 3, 4, -3, -4, -3, -6, 3 }, 1); T.rechne()
    local rb = Q.schub(0, 1)
    wahr('Q_b (parallel zur Symmetrieachse) berechnet', rb ~= nil, Q.status())
    if rb then
        local _, samples = Q.duennSchub(0, 1)
        local Fu, Fv, Mo = resultierende(samples)
        zahl('Resultierende |F_v| = 1', math.abs(Fv), 1, 1e-3)
        zahl('Resultierende F_u = 0', Fu, 0, 1e-3)
        zahl('Resultierende liegt auf der Symmetrieachse (M um u=0 ist 0)', Mo, 0, 1e-3)
    end
    local ra = Q.schub(1, 0)
    wahr('Q_a (quer zur einzigen Symmetrieachse) wird jetzt berechnet', ra ~= nil, Q.status())
    if ra then
        wahr('  q0 kam fuer diese Richtung aus der Vertraeglichkeit',
            ra.zelle_korrigiert and ra.zelle_korrigiert.vertraeglich and ra.zelle_korrigiert.vertraeglich.a == true)
        local _, samples = Q.duennSchub(1, 0)
        local summe, laenge = umlaufTauDurchT(samples)
        zahl('  Umlaufintegral tau/t ds = 0', summe / laenge, 0, 1e-6)
        local Fu, Fv = resultierende(samples)
        zahl('  Resultierende |F_u| = 1', math.abs(Fu), 1, 1e-3)
        zahl('  Resultierende F_v = 0', Fv, 0, 1e-3)
        local m = Q.meldung()
        wahr('  Warnung nennt die fehlende Achse und "trotzdem richtig"', m ~= nil
            and tostring(m.text):find('fehlt die Symmetrieachse', 1, true) ~= nil
            and tostring(m.text):find('trotzdem richtig', 1, true) ~= nil, m and m.text)
    end
end)

fall('6 Offene Profile', function()
    T.abschnitt('Befund 6: unsymmetrische offene Profile mit I_yz-Kopplung')
    -- L-Profil, Schenkel 100, t=2: Schubmittelpunkt in der Ecke
    T.duenn(P(0, 0), P(0, 100), 2); T.duenn(P(0, 0), P(100, 0), 2); T.rechne()
    for _, q in ipairs({ { 1, 0 }, { 0, 1 } }) do
        local _, samples = Q.duennSchub(q[1], q[2])
        local Fu, Fv, Mo = resultierende(samples)
        zahl(string.format('L, Q=(%d,%d): |F| parallel zu Q', q[1], q[2]), math.abs(q[1] == 1 and Fu or Fv), 1, 1e-3)
        zahl(string.format('L, Q=(%d,%d): Querkomponente = 0', q[1], q[2]), q[1] == 1 and Fv or Fu, 0, 1e-3)
        zahl(string.format('L, Q=(%d,%d): Moment um die Ecke = 0', q[1], q[2]), Mo, 0, 1e-2)
    end
    local m = Q.smp()
    wahr('L: Schubmittelpunkt bekannt', m and m.known)
    if m then zahl('L: Schubmittelpunkt u = 0', m.u, 0, 1e-3); zahl('L: Schubmittelpunkt v = 0', m.v, 0, 1e-3) end
    -- Z-Profil (punktsymmetrisch): Schubmittelpunkt = Schwerpunkt
    T.reset()
    T.zug({ -5, 5, 0, 5, 0, -5, 5, -5 }, 1); local r = T.rechne()
    m = Q.smp()
    if m then zahl('Z: Schubmittelpunkt u = u_s', m.u, r.ys, 1e-3); zahl('Z: Schubmittelpunkt v = v_s', m.v, r.zs, 1e-3) end
    local _, samples = Q.duennSchub(1, 0)
    local Fu, Fv = resultierende(samples)
    zahl('Z, Q_a=1: Querkomponente = 0', Fv, 0, 1e-3)
end)

fall('6b C-Profil', function()
    T.abschnitt('C-Profil Steg h=10, Flansche b=5, t=1: e = b^2 h^2 t/(4 I) = 1.875 hinter dem Steg')
    T.duenn(P(5, 0), P(0, 0), 1); T.duenn(P(0, 0), P(0, 10), 1); T.duenn(P(0, 10), P(5, 10), 1); T.rechne()
    local m = Q.smp()
    wahr('Schubmittelpunkt bekannt', m and m.known)
    if m then zahl('Schubmittelpunkt u = -1.875', m.u, -1.875, 1e-3); zahl('Schubmittelpunkt v = 5', m.v, 5, 1e-3) end
end)

fall('6c Geschlossen unsymmetrisch', function()
    T.abschnitt('Unsymmetrische Zelle ueber die Vertraeglichkeit, mehrzellig bleibt abgelehnt')
    T.zug({ 0, 0, 100, 0, 0, 60, 0, 0 }, 2); T.rechne()
    local rd = Q.schub(0, 1000)
    wahr('Dreieck geschlossen: Schub ueber die Vertraeglichkeit berechnet', rd ~= nil, Q.status())
    local m = Q.smp()
    wahr('Dreieck geschlossen: Schubmittelpunkt jetzt bestimmt', m and m.known, m and m.u)
    if rd and m and m.known then
        for _, q in ipairs({ { 1, 0 }, { 0, 1 } }) do
            local _, samples = Q.duennSchub(q[1], q[2])
            local summe, laenge = umlaufTauDurchT(samples)
            zahl(string.format('Dreieck Q=(%d,%d): Umlaufintegral tau/t ds = 0', q[1], q[2]), summe / laenge, 0, 1e-6)
            local Fu, Fv, Mo = resultierende(samples)
            zahl(string.format('Dreieck Q=(%d,%d): |F| = 1', q[1], q[2]), math.sqrt(Fu ^ 2 + Fv ^ 2), 1, 1e-3)
            zahl(string.format('Dreieck Q=(%d,%d): Moment um den Schubmittelpunkt = 0', q[1], q[2]),
                Mo - (m.u * Fv - m.v * Fu), 0, 1e-2)
        end
    end
    T.reset()
    T.zug({ -6, 3, 6, 3, 6, -3, -6, -3, -6, 3 }, 1); T.duenn(P(0, 3), P(0, -3), 1); T.rechne()
    wahr('Zweizeller: Schub abgelehnt', Q.schub(0, 1) == nil, Q.status())
    local It = Q.zellen()
    wahr('Zweizeller: keine Bredt-Torsion', Q.torsion(1000) == nil or not Q.torsion(1000).closed, It)
end)

fall('11 Massiv Schub', function()
    T.abschnitt('Befund 11: Rechteck 4x4 mit aufgesetztem Halbkreis r=2, Q=1000 senkrecht')
    T.massiv({ type = 'sector', points = { P(0, 2), P(2, 2), P(-2, 2) } })
    T.massiv({ type = 'rect', points = { P(-2, -2), P(2, 2) } })
    local r = T.rechne()
    local res = Q.schub(0, 1000)
    wahr('berechnet', res ~= nil, Q.status())
    if res then
        zahl('tau_max = 65.81 (Handrechnung)', res.max_tau, 65.81, 2e-3)
        zahl('tau_max im Schwerpunkt (Schnittweite 6/160)', res.max_v, r.zs, 0.04)
    end
    T.reset()
    T.massiv({ type = 'massiv_linie', points = { P(-20, 0), P(20, 0) }, t = 10 })
    r = T.rechne()
    res = Q.schub(0, 1000)
    if res then zahl('Dicke Linie 40x10: tau_max = 1.5 Q/A = 3.75', res.max_tau, 1.5 * 1000 / 400, 2e-3) end
    T.reset()
    T.massiv({ type = 'rect', points = { P(0, 0), P(1, 10) } }); T.massiv({ type = 'rect', points = { P(1, 0), P(10, 1) } })
    T.rechne()
    wahr('massives unsymmetrisches L (I_yz != 0): Schub abgelehnt', Q.schub(0, 1000) == nil, Q.status())
    T.reset()
    T.massiv({ type = 'rect', points = { P(-2, -2), P(2, 2) } }); T.duenn(P(-2, 3), P(2, 3), 1); T.rechne()
    wahr('massiv + duennwandig gemischt: Schub abgelehnt', Q.schub(0, 1000) == nil, Q.status())
end)

-- Vertraeglichkeit der Zelle: Integral tau ds ueber den Umlauf (im Umlaufsinn) muss 0 sein
local function umlaufintegral(samples)
    local summe, laenge = 0, 0
    for _, s in ipairs(samples or {}) do
        if s.in_cell then
            local w = (s.parameter <= 1e-9 or s.parameter >= 1 - 1e-9) and 0.5 or 1
            summe = summe + s.tau * (s.cell_sign or 1) * s.ds * w
            laenge = laenge + s.ds * w
        end
    end
    return summe, laenge
end

fall('5c Vertraeglichkeit', function()
    T.abschnitt('Zelle: Symmetrie-Loesung erfuellt die Vertraeglichkeit (Umlaufintegral tau ds = 0)')
    local faelle = {
        { 'Kasten, Q_a', function() kasten(1, 1) end, 1, 0 },
        { 'Kasten, Q_b', function() kasten(1, 1) end, 0, 1 },
        { 'Kasten Gurte t=2, Stege t=1, Q_b', function() kasten(2, 1) end, 0, 1 },
        { 'Trapezkasten, Q_b', function() T.zug({ -6, 3, 6, 3, 4, -3, -4, -3, -6, 3 }, 1) end, 0, 1 },
        { 'Kasten mit ueberstehendem Obergurt (Mischprofil), Q_b', function()
            T.duenn(P(-8, 3), P(8, 3), 1); T.zug({ -5, 3, -5, -3, 5, -3, 5, 3 }, 1) end, 0, 1 },
        { 'Hutprofil geschlossen mit Flanschen unten, Q_b', function()
            T.zug({ -8, -3, -5, -3, -5, 3, 5, 3, 5, -3, 8, -3 }, 1); T.duenn(P(-5, -3), P(5, -3), 1) end, 0, 1 },
    }
    for _, f in ipairs(faelle) do
        T.reset(); f[2](); T.rechne()
        local maximum, samples, _, fehler = Q.duennSchub(f[3], f[4])
        wahr(f[1] .. ': berechnet', maximum ~= nil, fehler)
        if maximum then
            local summe, laenge = umlaufintegral(samples)
            zahl(f[1] .. ': Umlaufintegral tau ds / Umfang = 0', summe / laenge, 0, 1e-4)
            local Fu, Fv, Mo = resultierende(samples)
            zahl(f[1] .. ': |Resultierende| = 1', math.sqrt(Fu ^ 2 + Fv ^ 2), 1, 1e-3)
            zahl(f[1] .. ': Resultierende parallel zu Q', f[3] == 1 and Fv or Fu, 0, 1e-3)
        end
    end
end)

fall('6d I-Profil', function()
    T.abschnitt('I-Profil h=10, b=6, t=1 (offen, doppeltsymmetrisch): tau_max = Q S/(I t) = 42.5/383.3')
    T.duenn(P(-3, 5), P(3, 5), 1); T.duenn(P(-3, -5), P(3, -5), 1); T.duenn(P(0, 5), P(0, -5), 1); T.rechne()
    local res = Q.schub(0, 1)
    if res then zahl('Q_z = 1: tau_max im Steg', res.max_tau, 42.5 / (1000 / 12 + 2 * 6 * 25), 1e-3) end
    local m = Q.smp()
    if m then zahl('Schubmittelpunkt u = 0', m.u, 0, 1e-6); zahl('Schubmittelpunkt v = 0', m.v, 0, 1e-6) end
end)

fall('7b Torsion einfachsymmetrisch', function()
    T.abschnitt('Trapezkasten (Symmetrie nur senkrecht): Kraft auf der Achse ohne Torsion, waagerechte Kraft jetzt bestimmbar')
    T.zug({ -6, 3, 6, 3, 4, -3, -4, -3, -6, 3 }, 1)
    table.insert(Q.K(), { u = 0, v = 1, fa = 0, fb = 1000, fc = 0 })
    T.rechne()
    local m = Q.smp()
    wahr('Schubmittelpunkt: beide Koordinaten bestimmt (v ueber die Vertraeglichkeit)', m and m.known)
    local t = Q.kraftTorsion()
    wahr('senkrechte Kraft auf der Symmetrieachse: keine Torsion', t == nil or math.abs(t.M) < 0.2, t and t.M)
    Q.K()[1].fa, Q.K()[1].fb = 1000, 0
    T.rechne()
    local t2 = Q.kraftTorsion()
    wahr('waagerechte Kraft: Torsion um den Schubmittelpunkt jetzt bestimmbar', t2 ~= nil and t2.closed == true, Q.status())
end)

-- ============================================================ Torsion
fall('7 Torsion aus Kraeften', function()
    T.abschnitt('Befund 7: C-Profil, Kraft 1000 N senkrecht am Steg: MT = F * e = 1875 Nmm')
    T.duenn(P(5, 0), P(0, 0), 1); T.duenn(P(0, 0), P(0, 10), 1); T.duenn(P(0, 10), P(5, 10), 1)
    table.insert(Q.K(), { u = 0, v = 5, fa = 0, fb = 1000, fc = 0 })
    T.rechne()
    local t = Q.kraftTorsion()
    wahr('Torsion aus Kraeften berechnet', t ~= nil)
    if t then zahl('|MT| = 1875 Nmm', math.abs(t.M), 1875, 1e-3) end
    Q.K()[1].u = -1.875
    T.rechne()
    t = Q.kraftTorsion()
    wahr('Kraft im Schubmittelpunkt: keine Torsion (|MT| < 1e-4 * F*e)', t == nil or math.abs(t.M) < 0.2, t and t.M)
end)

fall('8 tau_T', function()
    T.abschnitt('Befund 8: Bredt tau = MT/(2 Am t_min), offen tau = MT/I_T * t_max')
    kasten(0.2, 0.2); T.rechne()
    local t = Q.torsion(1000)
    wahr('Kasten t=0.2: geschlossen', t and t.closed)
    if t then zahl('Kasten t=0.2: tau_T = 1000/(2*60*0.2) = 41.67', t.tau, 1000 / (2 * 60 * 0.2), 1e-6) end
    T.reset(); kasten(1, 0.2); T.rechne()
    t = Q.torsion(1000)
    if t then zahl('Kasten Gurte t=1, Stege t=0.2: tau_T = 41.67', t.tau, 1000 / (2 * 60 * 0.2), 1e-6) end
    T.reset()
    T.duenn(P(0, 0), P(0, 100), 2); T.duenn(P(0, 0), P(50, 0), 1); local r = T.rechne()
    t = Q.torsion(1000)
    local It = (100 * 8 + 50 * 1) / 3
    if t then
        zahl('offenes L: I_T = sum h t^3/3', t.It, It, 1e-9)
        zahl('offenes L: tau_T = MT/I_T * t_max', t.tau, 1000 / It * 2, 1e-9)
    end
    T.reset()
    T.massiv({ type = 'rect', points = { P(0, 0), P(4, 2) } }); T.rechne()
    wahr('massiver Querschnitt: keine Torsionsrechnung (keine Prandtl-Loesung)', Q.torsion(1000) == nil, Q.status())
end)

fall('9 Zellen', function()
    T.abschnitt('Befund 9: Kasten mit ueberstehendem Obergurt (T-Knoten) ist einzellig geschlossen')
    T.duenn(P(-6, 2), P(6, 2), 1)
    T.zug({ -4, 2, -4, -2, 4, -2, 4, 2 }, 1)
    local r = T.rechne()
    zahl('A_m = 8*4 = 32', r.Am, 32, 1e-9)
    zahl('I_T = 4 Am^2 / (24/t) = 170.67', r.It_closed, 4 * 32 ^ 2 / 24, 1e-9)
    local t = Q.torsion(1000)
    if t then zahl('tau_T = MT/(2 Am t)', t.tau, 1000 / (2 * 32 * 1), 1e-9) end
end)

fall('20 Oberflaeche', function()
    T.abschnitt('Oberflaeche: on.paint mit Schub/Torsion in allen Verlaufsansichten (kein Absturz)')
    local profile = {
        { 'Kasten', function() kasten(1, 0.5) end },
        { 'C-Profil', function() T.duenn(P(5, 0), P(0, 0), 1); T.duenn(P(0, 0), P(0, 10), 1); T.duenn(P(0, 10), P(5, 10), 1) end },
        { 'Mischprofil', function() T.duenn(P(-8, 3), P(8, 3), 1); T.zug({ -5, 3, -5, -3, 5, -3, 5, 3 }, 1) end },
        { 'Massiv', function() T.massiv({ type = 'rect', points = { P(-2, -3), P(2, 3) } }) end },
    }
    for _, pr in ipairs(profile) do
        T.reset(); pr[2](); T.rechne()
        local res = Q.schub(0, 1000)
        local tor = Q.torsion(5000)
        Q.setShear(res); Q.setTorsion(tor)
        if res and tor then Q.update(tor) end
        for _, rot in ipairs({ 180, 90 }) do
            Q.setRotation(rot)
            for mode = 0, 9 do
                Q.setView(mode, mode > 0)
                Q.setFlags(true, mode == 3, mode == 4 and #Q.D() > 0)
                local ok, err = pcall(on.paint, T.gc)
                if not ok then T.pruef(false, pr[1] .. ' rot ' .. rot .. ' Ansicht ' .. mode .. ': ' .. tostring(err)) end
            end
        end
        T.pruef(true, pr[1] .. ': alle Ansichten gezeichnet')
        local texte = T.ergebnisfeld()
        local tauzeile = false
        for _, t in ipairs(texte) do if t:find('tau_T,max') then tauzeile = true end end
        wahr(pr[1] .. ': Ergebnisfeld zeigt Torsion (ausser massiv)', tauzeile == (tor ~= nil))
    end
end)

-- ============================================================ Eingabe
fall('13 Eingabe', function()
    T.abschnitt('Befund 13: Eingaben ohne CAS (Lua 5.1)')
    zahl('math.sqrt(2)', Q.evalInput('math.sqrt(2)'), math.sqrt(2), 1e-12)
    zahl('sqrt(2)', Q.evalInput('sqrt(2)'), math.sqrt(2), 1e-12)
    zahl('2,5 (Dezimalkomma)', Q.evalInput('2,5'), 2.5, 1e-12)
    zahl('3*pi', Q.evalInput('3*pi'), 3 * math.pi, 1e-12)
    wahr('os.exit() wird nicht ausgefuehrt', Q.evalInput('os.exit()') == nil)
end)


fall('Hauptachsen gedreht: Meldungen', function()
    T.abschnitt('Schub bei I_yz ~= 0: Hinweis bzw. Begruendung sichtbar, ESC schliesst')
    local function texteMit(muster)
        T.texte = {}
        Q.paint(T.gc)
        for _, t in ipairs(T.texte) do if t:find(muster, 1, true) then return true end end
        return false
    end
    -- massives L: Schub wird abgelehnt, die Begruendung steht in der Box
    T.reset()
    T.massiv({ type = 'rect', points = { P(0, 0), P(60, 10) } })
    T.massiv({ type = 'rect', points = { P(0, 10), P(10, 60) } })
    T.rechne()
    local res = Q.schubEingabe(0, 1000)
    local m = Q.meldung()
    T.wahr('massives L: kein Ergebnis', res == nil)
    T.wahr('massives L: Box "Schub nicht berechnet"', m ~= nil and m.titel == 'Schub nicht berechnet' and m.text:find('I_yz', 1, true) ~= nil, m and m.text)
    T.wahr('massives L: Box gezeichnet', texteMit('Schub nicht berechnet:'))
    on.escapeKey()
    T.wahr('ESC schliesst die Box', Q.meldung() == nil and not texteMit('Schub nicht berechnet:'))
    -- duennwandiges Z: Schub wird mit Kopplung gerechnet, Hinweis auf gedrehte Hauptachsen
    T.reset()
    T.zug({ 40, 50, 0, 50, 0, 0, -40, 0 }, 2)
    local r = T.rechne()
    res = Q.schubEingabe(0, 1000)
    m = Q.meldung()
    T.wahr('Z: Ergebnis vorhanden', res ~= nil and res.iyz_kopplung == true)
    T.wahr('Z: Hinweis Hauptachsen nicht parallel', m ~= nil and m.titel == 'Hinweis' and m.text:find('Hauptachsen nicht parallel', 1, true) ~= nil, m and m.text)
    if T.verbose then T.write('   ' .. (m and m.text or '') .. '\n') end
    T.wahr('Z: Hinweis gezeichnet', texteMit('Hinweis:'))
    on.escapeKey()
    T.wahr('Z: ESC schliesst den Hinweis, Schubauswahl bleibt', Q.meldung() == nil)
    local texte = T.ergebnisfeld()
    local orange = false
    for _, t in ipairs(texte) do if t:find('nicht parallel zu den Achsen', 1, true) then orange = true end end
    T.wahr('Ergebnisfeld: "Hauptachsen nicht parallel zu den Achsen"', orange)
    -- symmetrisches I-Profil: kein Hinweis, Ergebnisfeld gruen
    T.reset()
    T.zug({ -30, 50, 30, 50 }, 2); T.zug({ 0, 50, 0, -50 }, 2); T.zug({ -30, -50, 30, -50 }, 2)
    T.rechne()
    res = Q.schubEingabe(0, 1000)
    T.wahr('I-Profil: Ergebnis ohne Hinweis', res ~= nil and Q.meldung() == nil, Q.meldung() and Q.meldung().text)
    texte = T.ergebnisfeld()
    local gruen = false
    for _, t in ipairs(texte) do if t:find('Hauptachsen parallel zu den Achsen', 1, true) then gruen = true end end
    T.wahr('Ergebnisfeld: "Hauptachsen parallel zu den Achsen"', gruen)
    -- Querschnitt aendern loescht eine alte Meldung
    T.reset()
    T.massiv({ type = 'rect', points = { P(0, 0), P(60, 10) } })
    T.massiv({ type = 'rect', points = { P(0, 10), P(10, 60) } })
    T.rechne()
    Q.schubEingabe(0, 1000)
    T.rechne()
    T.wahr('neue Querschnittsberechnung loescht die Meldung', Q.meldung() == nil)
end)

fall('20 FTM-Bezug im Menue', function()
    T.abschnitt('Obermenue: FTM-Bezug umschalten, Tabelle und Ergebnisfeld folgen')
    -- Rechteck 40x60 mit Ecke im Ursprung: Steiner-Anteil zum KOS ist A*z_s^2 = 2400*30^2
    T.massiv({ type = 'rect', points = { T.P(0, 0), T.P(-40, -60) } })
    T.rechne()
    Q.ftmBezug('schwerpunkt')
    Q.menu(9, 1)
    local eintraege = Q.menuTexte()
    T.wahr('Menueeintrag zeigt den aktuellen Bezug', (eintraege[2] or ''):find('Schwerpunkt', 1, true) ~= nil, eintraege[2])
    T.wahr('Rueckweg ist Zeile 3', (eintraege[3] or ''):find('Zurueck', 1, true) ~= nil, eintraege[3])
    -- Zeile 2 waehlen und mit Enter umschalten
    Q.menu(9, 2)
    on.enterKey()
    T.wahr('Bezug jetzt KOS-Ursprung', Q.ftmBezug() == 'kos', Q.ftmBezug())
    T.wahr('Menuetext folgt', (Q.menuTexte()[2] or ''):find('KOS-Ursprung', 1, true) ~= nil, Q.menuTexte()[2])
    -- Tabelle: Steiner-Anteil bezieht sich jetzt auf den KOS-Ursprung
    T.texte, T.pos = {}, {}
    Q.tabelle(T.gc)
    local hat_kos, hat_wert = false, false
    for _, t in ipairs(T.texte) do
        if t:find('Steiner zu KOS', 1, true) then hat_kos = true end
        if t == string.format('%.2f', 2400 * 30 ^ 2) then hat_wert = true end
    end
    T.wahr('Tabellenkopf nennt den Bezug KOS', hat_kos, table.concat(T.texte, ' | '):sub(1, 120))
    T.wahr('Steiner-Anteil z^2*A = 2400*30^2', hat_wert)
    -- zurueckschalten: Steiner zum Schwerpunkt ist 0
    Q.menu(9, 2); on.enterKey()
    T.wahr('wieder Schwerpunkt', Q.ftmBezug() == 'schwerpunkt', Q.ftmBezug())
    T.texte, T.pos = {}, {}
    Q.tabelle(T.gc)
    local hat_s, null = false, false
    for _, t in ipairs(T.texte) do
        if t:find('Steiner zu S', 1, true) then hat_s = true end
        if t == '0.00' then null = true end
    end
    T.wahr('Tabellenkopf nennt den Schwerpunkt', hat_s)
    T.wahr('Steiner-Anteil ist 0 (ein Element)', null)
    Q.menu(nil)
end)

fall('21 Loeschabfrage', function()
    T.abschnitt('Alles loeschen fragt nach: Esc bricht ab, Enter loescht')
    T.massiv({ type = 'rect', points = { T.P(0, 0), T.P(-40, -60) } })
    T.rechne()
    on.clearKey()
    T.wahr('Frage steht', Q.loeschFrage() == true)
    T.texte, T.pos = {}, {}
    Q.paint(T.gc)
    local gefragt = false
    for _, t in ipairs(T.texte) do if t:find('alles loeschen', 1, true) then gefragt = true end end
    T.wahr('Frage wird gezeichnet', gefragt, table.concat(T.texte, ' | '):sub(1, 100))
    on.escapeKey()
    T.wahr('Esc bricht ab', Q.loeschFrage() == false)
    T.wahr('Querschnitt ist noch da', #Q.M() == 1, #Q.M())
    on.clearKey(); on.enterKey()
    T.wahr('Enter loescht', #Q.M() == 0 and #Q.D() == 0)
    T.wahr('keine Frage mehr offen', Q.loeschFrage() == false)
end)

fall('22 Menues links, Auswahlmenue oben', function()
    T.abschnitt('Menue und Schubauswahl stehen links; die Auswahl liegt ueber den Kraeften')
    T.massiv({ type = 'rect', points = { T.P(0, 0), T.P(-40, -60) } })
    T.rechne()
    Q.menu(4, 1)
    T.texte, T.pos = {}, {}
    Q.paint(T.gc)
    local menue_x
    for _, e in ipairs(T.pos) do if e.t and e.t:find('Menue (', 1, true) then menue_x = e.x end end
    T.wahr('Menuetitel steht links', menue_x ~= nil and menue_x < 100, tostring(menue_x))
    Q.menu(nil)
    -- Schubauswahl: links und nach den Kraeften gezeichnet
    Q.kraft({ u = -20, v = -30, fa = 1, fb = 0, fc = 0 })
    Q.auswahl('kraft', 1)
    Q.selektor(true)
    T.texte, T.pos = {}, {}
    Q.paint(T.gc)
    local sel_i, sel_x, kraft_i
    for i, e in ipairs(T.pos) do
        if e.t == 'Schubspannungsverlauf' then sel_i, sel_x = i, e.x end
        if e.t == 'K1' then kraft_i = i end
    end
    T.wahr('Schubauswahl gezeichnet', sel_i ~= nil)
    T.wahr('Schubauswahl steht links', sel_x ~= nil and sel_x < 100, tostring(sel_x))
    T.wahr('Kraft wird vor der Auswahl gezeichnet', kraft_i ~= nil and sel_i ~= nil and kraft_i < sel_i,
        tostring(kraft_i) .. ' / ' .. tostring(sel_i))
    Q.selektor(false)
    Q.auswahl(nil, nil)
end)

fall('23 Zellsymmetrie trotz anderer Unterteilung', function()
    T.abschnitt('Kasten 40x20: Obergurt in zwei Segmente geteilt, Untergurt in einem')
    -- unten ein Segment, oben zwei, Stege je eins: geometrisch symmetrisch zu beiden Achsen
    T.duenn(T.P(0, 0), T.P(40, 0), 2)
    T.duenn(T.P(40, 0), T.P(40, 20), 2)
    T.duenn(T.P(40, 20), T.P(20, 20), 2)
    T.duenn(T.P(20, 20), T.P(0, 20), 2)
    T.duenn(T.P(0, 20), T.P(0, 0), 2)
    T.rechne()
    local _, _, zellen = Q.zellen()
    T.wahr('eine geschlossene Zelle', zellen == 1, zellen)
    local res = Q.schub(0, 1)
    T.wahr('Schub berechnet', res ~= nil, Q.status())
    if res then
        T.wahr('Symmetrie senkrecht erkannt', res.sym_v == true)
        T.wahr('Symmetrie waagerecht erkannt (Unterteilung egal)', res.sym_h == true)
    end
    local res2 = Q.schub(1, 0)
    T.wahr('auch quer dazu berechenbar', res2 ~= nil, Q.status())
end)

fall('24 Geschlossene Zelle ohne Symmetrie warnt', function()
    T.abschnitt('Dreieckszelle: keine Spiegelsymmetrie, q0 aus der Vertraeglichkeit')
    T.duenn(T.P(0, 0), T.P(40, 0), 2)
    T.duenn(T.P(40, 0), T.P(10, 20), 2)
    T.duenn(T.P(10, 20), T.P(0, 0), 2)
    T.rechne()
    local _, _, zellen = Q.zellen()
    T.wahr('eine geschlossene Zelle', zellen == 1, zellen)
    -- ohne Querkraft laeuft die Rechnung (S-Verlauf), muss aber warnen
    local res = Q.schub(0, 0)
    T.wahr('S-Verlauf berechnet', res ~= nil, Q.status())
    if res then
        T.wahr('keine Symmetrie erkannt', res.sym_v == false and res.sym_h == false)
    end
    local m = Q.meldung()
    T.wahr('Warnung erscheint', m ~= nil and tostring(m.text):find('ohne erkannte Symmetrie', 1, true) ~= nil,
        m and m.text or 'keine Meldung')
    -- mit Querkraft: q0 aus der Vertraeglichkeit, die Warnung bleibt und sagt, dass S und tau stimmen
    local res2 = Q.schub(0, 1)
    T.wahr('Schub ueber die Vertraeglichkeit berechnet', res2 ~= nil, Q.status())
    local m2 = Q.meldung()
    T.wahr('Warnung nennt q0, Symmetrie und "trotzdem richtig"', m2 ~= nil
        and tostring(m2.text):find('Symmetrie', 1, true) ~= nil and tostring(m2.text):find('q0', 1, true) ~= nil
        and tostring(m2.text):find('trotzdem richtig', 1, true) ~= nil, m2 and m2.text)
end)

fall('25 Symmetrische Zelle: S auf den symmetrischen Schnitt bezogen', function()
    T.abschnitt('Kasten 40x20: S muss auf der Symmetrieachse null sein, auch ohne Querkraft')
    T.duenn(T.P(0, 0), T.P(40, 0), 2)
    T.duenn(T.P(40, 0), T.P(40, 20), 2)
    T.duenn(T.P(40, 20), T.P(0, 20), 2)
    T.duenn(T.P(0, 20), T.P(0, 0), 2)
    T.rechne()
    local res = Q.schub(0, 0)
    T.wahr('S-Verlauf berechnet', res ~= nil, Q.status())
    if res then
        -- Schwerpunkt (20,10): auf der senkrechten Achse ist Sy = 0, auf der waagerechten Sz = 0
        local max_sy, max_sz, n_sy, n_sz = 0, 0, 0, 0
        for _, sample in ipairs(res.samples) do
            if sample.in_cell and math.abs(sample.u - 20) < 1e-6 then
                n_sy = n_sy + 1; max_sy = math.max(max_sy, math.abs(sample.Sy))
            end
            if sample.in_cell and math.abs(sample.v - 10) < 1e-6 then
                n_sz = n_sz + 1; max_sz = math.max(max_sz, math.abs(sample.Sz))
            end
        end
        T.wahr('Punkte auf den Symmetrieachsen gefunden', n_sy >= 2 and n_sz >= 2, n_sy .. ' / ' .. n_sz)
        T.zahl('Sy auf der senkrechten Achse = 0', max_sy, 0, 1e-6)
        T.zahl('Sz auf der waagerechten Achse = 0', max_sz, 0, 1e-6)
    end
    local m = Q.meldung()
    T.wahr('keine Warnung bei symmetrischer Zelle', m == nil or tostring(m.text):find('Symmetrie', 1, true) == nil,
        m and m.text or 'keine Meldung')
    -- mit Querkraft laengs der Symmetrieachse: tau bleibt richtig (Probe gegen die Handrechnung folgt
    -- aus den uebrigen Schubtests), hier nur: Rechnung laeuft ohne Warnung
    local res2 = Q.schub(0, 1)
    T.wahr('Schub berechnet', res2 ~= nil, Q.status())
    local m2 = Q.meldung()
    T.wahr('auch mit Querkraft keine Warnung', m2 == nil or tostring(m2.text):find('Symmetrie', 1, true) == nil,
        m2 and m2.text or 'keine Meldung')
end)

fall('26 Startmarken im Schubverlauf', function()
    T.abschnitt('"Start" wo S = 0 ist (freies Ende oder Symmetrieachse), sonst "Schnitt"')
    local function marken()
        T.texte, T.pos = {}, {}
        Q.setView(3, true)
        Q.paint(T.gc)
        Q.setView(0, false)
        local gefunden = {}
        for _, t in ipairs(T.texte) do
            if t:find('Start', 1, true) or t:find('Schnitt', 1, true) then gefunden[#gefunden + 1] = t end
        end
        return table.concat(gefunden, ' | ')
    end
    -- offenes Profil: S beginnt am freien Ende bei null
    T.zug({ 0, 0, 40, 0, 40, 20 }, 2)
    T.rechne()
    Q.schub(0, 1)
    local m = marken()
    T.wahr('offenes Profil: Start', m:find('Start', 1, true) ~= nil and m:find('Schnitt', 1, true) == nil, m)
    -- symmetrischer Kasten mit Ast auf der Symmetrieachse: Start am Ast, Schnitt an der Zelle
    T.reset()
    T.duenn(T.P(0, 0), T.P(40, 0), 2)
    T.duenn(T.P(40, 0), T.P(40, 20), 2)
    T.duenn(T.P(40, 20), T.P(20, 20), 2)
    T.duenn(T.P(20, 20), T.P(0, 20), 2)
    T.duenn(T.P(0, 20), T.P(0, 0), 2)
    T.duenn(T.P(20, 20), T.P(20, 35), 2)
    T.rechne()
    local res = Q.schub(0, 1)
    T.wahr('Schub berechnet', res ~= nil, Q.status())
    if res then
        T.wahr('S der Zelle korrigiert', res.zelle_korrigiert ~= nil and res.zelle_korrigiert.b == true)
        -- alle gespiegelten Punkte der Zelle muessen sich aufheben (S antisymmetrisch)
        local ys = Q.R().ys
        local paare, fehler = 0, 0
        for _, a in ipairs(res.samples) do
            if a.in_cell and a.u < ys - 1e-6 then
                for _, b in ipairs(res.samples) do
                    if b.in_cell and math.abs(b.u - (2 * ys - a.u)) < 1e-9 and math.abs(b.v - a.v) < 1e-9 then
                        paare = paare + 1
                        if math.abs(a.Sy * a.cell_sign + b.Sy * b.cell_sign) > 1e-6 * math.max(1, math.abs(a.Sy)) then
                            fehler = fehler + 1
                        end
                        break
                    end
                end
            end
        end
        T.wahr('gespiegelte Punkte gefunden', paare > 50, paare)
        T.wahr('S in der Zelle antisymmetrisch', fehler == 0, fehler .. ' von ' .. paare)
    end
    local m2 = marken()
    T.wahr('Kasten mit Ast: Start am freien Ende', m2:find('Start |', 1, true) ~= nil or m2:find('| Start', 1, true) ~= nil, m2)
    T.wahr('Zellschnitt liegt auf der Symmetrieachse', m2:find('Start (Symmetrieachse)', 1, true) ~= nil, m2)
    T.wahr('kein "q0 offen" bei erkannter Symmetrie', m2:find('q0 offen', 1, true) == nil, m2)
    -- unsymmetrische Zelle: Schnitt mit Hinweis
    T.reset()
    T.duenn(T.P(0, 0), T.P(40, 0), 2)
    T.duenn(T.P(40, 0), T.P(10, 20), 2)
    T.duenn(T.P(10, 20), T.P(0, 0), 2)
    T.rechne()
    Q.schub(0, 0)
    local m3 = marken()
    T.wahr('unsymmetrische Zelle: Schnitt (q0 aus Vertraeglichkeit)', m3:find('Verträglichkeit', 1, true) ~= nil, m3)
    T.wahr('kein "Start" ohne freies Ende', m3:find('Start', 1, true) == nil, m3)
end)

fall('27 Zellschnitt auf der Symmetrieachse', function()
    T.abschnitt('Kasten 40x20: die Laufvariable beginnt auf der Symmetrieachse, dort ist S = 0')
    T.duenn(T.P(0, 0), T.P(40, 0), 2)
    T.duenn(T.P(40, 0), T.P(40, 20), 2)
    T.duenn(T.P(40, 20), T.P(0, 20), 2)
    T.duenn(T.P(0, 20), T.P(0, 0), 2)
    T.rechne()
    local res = Q.schub(0, 1)
    T.wahr('Schub berechnet', res ~= nil, Q.status())
    if not res then return end
    T.wahr('Schnitt auf der Achse gemeldet', res.schnitt_auf_achse == true, tostring(res.schnitt_auf_achse))
    local start
    for _, pfad in ipairs(res.paths or {}) do
        if pfad.start_kind == 'cut_sym' then start = pfad.items[1] and pfad.items[1].p1 end
    end
    T.wahr('Zellpfad startet als cut_sym', start ~= nil)
    if start then
        T.zahl('Startpunkt liegt auf u = y_s', start.u, Q.R().ys, 1e-9)
        local sy
        for _, sample in ipairs(res.samples) do
            if math.abs(sample.u - start.u) < 1e-9 and math.abs(sample.v - start.v) < 1e-9 then sy = sample.Sy end
        end
        T.zahl('S am Start ist null', sy or 999, 0, 1e-9)
    end
    -- Zelle, die von der senkrechten Schwerpunktachse nicht geschnitten wird: der Schnitt liegt auf der
    -- waagerechten Achse, q0 fuer Q_b kommt aus der Vertraeglichkeit
    T.reset()
    -- kleiner Kasten links, schwerer Gurt rechts zieht den Schwerpunkt aus der Zelle heraus
    T.duenn(T.P(0, 0), T.P(4, 0), 1)
    T.duenn(T.P(4, 0), T.P(4, 4), 1)
    T.duenn(T.P(4, 4), T.P(0, 4), 1)
    T.duenn(T.P(0, 4), T.P(0, 0), 1)
    T.duenn(T.P(4, 2), T.P(60, 2), 20)
    T.rechne()
    local res2 = Q.schub(0, 1)
    T.wahr('Schub berechnet (q0 aus der Vertraeglichkeit)', res2 ~= nil, Q.status())
    if res2 then
        T.wahr('nur waagerechte Symmetrie', res2.sym_h == true and res2.sym_v == false,
            tostring(res2.sym_v) .. '/' .. tostring(res2.sym_h))
        T.wahr('Schnitt liegt auf der waagerechten Achse', res2.schnitt_auf_achse == true, tostring(res2.schnitt_auf_achse))
        local m = Q.meldung()
        T.wahr('Warnung nennt die fehlende Achse und "trotzdem richtig"', m ~= nil
            and tostring(m.text):find('fehlt die Symmetrieachse', 1, true) ~= nil
            and tostring(m.text):find('trotzdem richtig', 1, true) ~= nil, m and m.text or 'keine Meldung')
    end
end)

fall('28 Menue per Hover', function()
    T.abschnitt('Enter oeffnet das Elementmenue schon beim Hovern, ohne vorherigen Klick')
    T.massiv({ type = 'rect', points = { T.P(0, 0), T.P(-40, -60) } })
    T.duenn(T.P(0, 0), T.P(40, 0), 2)
    T.rechne()
    -- nichts ausgewaehlt, nichts unter dem Zeiger: Enter oeffnet kein Elementmenue
    Q.auswahl(nil, nil); Q.hover(nil, nil)
    on.enterKey()
    local offen = Q.menuStatus()
    T.wahr('ohne Hover und Auswahl kein Menue', offen == false, tostring(offen))
    -- nur hovern: Enter oeffnet das Menue des Elements unter dem Zeiger
    Q.hover('massiv', 1)
    on.enterKey()
    local o2, seite, _, typ, idx = Q.menuStatus()
    T.wahr('Hover oeffnet das Menue', o2 == true and seite == 3, tostring(o2) .. '/' .. tostring(seite))
    T.wahr('richtiges Element uebernommen', typ == 'massiv' and idx == 1, tostring(typ) .. ' ' .. tostring(idx))
    on.escapeKey()
    -- Hover gewinnt gegen eine alte Auswahl
    Q.auswahl('massiv', 1); Q.hover('duenn', 1)
    on.enterKey()
    local _, _, _, typ2, idx2 = Q.menuStatus()
    T.wahr('Hover hat Vorrang vor der Auswahl', typ2 == 'duenn' and idx2 == 1, tostring(typ2) .. ' ' .. tostring(idx2))
    on.escapeKey()
    -- ohne Hover bleibt die angeklickte Auswahl
    Q.auswahl('massiv', 1); Q.hover(nil, nil)
    on.enterKey()
    local o3, _, _, typ3 = Q.menuStatus()
    T.wahr('Auswahl ohne Hover oeffnet weiterhin', o3 == true and typ3 == 'massiv', tostring(o3) .. ' ' .. tostring(typ3))
    on.escapeKey()
    Q.auswahl(nil, nil)
end)

fall('29 Warnung bei Verlauf ohne Symmetrieachse', function()
    T.abschnitt('Zelle nur senkrecht symmetrisch: S und tau der anderen Richtung sind unbestimmt')
    -- Kasten mit senkrechtem Ast auf der Achse: sym_v bleibt, sym_h faellt weg
    T.duenn(T.P(0, 0), T.P(40, 0), 2)
    T.duenn(T.P(40, 0), T.P(40, 20), 2)
    T.duenn(T.P(40, 20), T.P(20, 20), 2)
    T.duenn(T.P(20, 20), T.P(0, 20), 2)
    T.duenn(T.P(0, 20), T.P(0, 0), 2)
    T.duenn(T.P(20, 20), T.P(20, 35), 2)
    T.rechne()
    local res = Q.schub(0, 1)
    T.wahr('Schub berechnet', res ~= nil, Q.status())
    if not res then return end
    T.wahr('nur senkrechte Symmetrie', res.sym_v == true and res.sym_h == false,
        tostring(res.sym_v) .. '/' .. tostring(res.sym_h))
    local function ansicht(ziffer)
        Q.meldungWeg()
        Q.selektor(true)
        on.charIn(ziffer)
        local m = Q.meldung()
        return m and tostring(m.text) or ''
    end
    -- 3 = S_a und 6 = tau_b gehoeren zur senkrechten Achse: vorhanden, keine Warnung
    T.wahr('Ansicht 3 ohne Warnung', ansicht('3') == '', ansicht('3'))
    T.wahr('Ansicht 6 ohne Warnung', ansicht('6') == '', ansicht('6'))
    -- 4 = S_b und 5 = tau_a brauchen die waagerechte Achse: Warnung
    local w4 = ansicht('4')
    T.wahr('Ansicht 4 warnt', w4:find('Symmetrie zur', 1, true) ~= nil, w4:sub(1, 60))
    T.wahr('Warnung nennt die Groesse S', w4:sub(1, 2) == 'Sz' or w4:sub(1, 2) == 'Sy', w4:sub(1, 10))
    local w5 = ansicht('5')
    T.wahr('Ansicht 5 warnt', w5:find('Symmetrie zur', 1, true) ~= nil, w5:sub(1, 60))
    T.wahr('Warnung nennt tau', w5:find('tau_', 1, true) ~= nil, w5:sub(1, 10))
    -- vollsymmetrischer Kasten: keine Warnung in beiden Richtungen
    T.reset()
    T.duenn(T.P(0, 0), T.P(40, 0), 2)
    T.duenn(T.P(40, 0), T.P(40, 20), 2)
    T.duenn(T.P(40, 20), T.P(0, 20), 2)
    T.duenn(T.P(0, 20), T.P(0, 0), 2)
    T.rechne()
    Q.schub(0, 1)
    local function ansicht2(ziffer)
        Q.meldungWeg()
        Q.selektor(true)
        on.charIn(ziffer)
        local m = Q.meldung()
        return m and tostring(m.text) or ''
    end
    T.wahr('symmetrischer Kasten: Ansicht 4 ohne Warnung', ansicht2('4') == '', ansicht2('4'))
    T.wahr('symmetrischer Kasten: Ansicht 5 ohne Warnung', ansicht2('5') == '', ansicht2('5'))
    -- offenes Profil: nie eine Warnung
    T.reset()
    T.zug({ 0, 0, 40, 0, 40, 20 }, 2)
    T.rechne()
    Q.schub(0, 1)
    T.wahr('offenes Profil: keine Warnung', ansicht2('4') == '', ansicht2('4'))
end)

fall('30 Vertraeglichkeit gegen Symmetrie', function()
    T.abschnitt('Symmetrischer Kasten: die Vertraeglichkeit liefert dieselben S und tau wie die Spiegelung')
    kasten(2, 1); T.rechne()
    local _, sym = Q.duennSchub(1, 0.5)
    Q.immerVertraeglich(true)
    local _, ver = Q.duennSchub(1, 0.5)
    Q.immerVertraeglich(false)
    wahr('beide Rechnungen liefern Stuetzstellen', sym ~= nil and ver ~= nil and #sym == #ver, sym and #sym)
    if sym and ver and #sym == #ver then
        local dS, dT, skala = 0, 0, 1e-9
        for i = 1, #sym do
            dS = math.max(dS, math.abs(sym[i].Sz - ver[i].Sz), math.abs(sym[i].Sy - ver[i].Sy))
            dT = math.max(dT, math.abs(sym[i].tau - ver[i].tau))
            skala = math.max(skala, math.abs(sym[i].Sz), math.abs(sym[i].Sy))
        end
        zahl('max |Delta S| / max |S| = 0', dS / skala, 0, 1e-9)
        zahl('max |Delta tau| = 0', dT, 0, 1e-9)
    end
end)

fall('31 Verlaufszeichnung', function()
    T.abschnitt('Zeichnen: eine Polylinie je Abschnitt, pixelweise ausgeduennt, Werte aus allen Stuetzstellen')
    T.duenn(P(0, 0), P(40, 0), 2); T.duenn(P(40, 0), P(40, 20), 2)
    T.duenn(P(40, 20), P(0, 20), 2); T.duenn(P(0, 20), P(0, 0), 2)
    T.rechne()
    local res = Q.schub(0, 1)
    wahr('Schub berechnet', res ~= nil, Q.status())
    if not res then return end
    Q.setView(7, true)
    on.charIn('h')          -- einpassen: 40 Einheiten auf ~260 px, Stuetzstellen dichter als 1,5 px
    T.texte, T.pos = {}, {}; T.zaehlerReset()
    Q.paint(T.gc)
    local n = #res.samples
    wahr('viele Stuetzstellen gerechnet', n > 500, n)
    wahr('eine Polylinie je Abschnitt', T.zaehler.polylinien >= 4 and T.zaehler.polylinien <= 12, T.zaehler.polylinien)
    wahr('gezeichnete Punkte deutlich weniger als Stuetzstellen', T.zaehler.polypunkte <= n * 0.6,
        T.zaehler.polypunkte .. ' von ' .. n)
    -- der beschriftete Extremwert kommt aus allen Stuetzstellen
    local v1, v2 = Q.fmt(res.max_tau), Q.fmt(-res.max_tau)
    local gefunden = false
    for _, t in ipairs(T.texte) do
        if t == v1 or t == v2 or t == 'max ' .. v1 or t == 'min ' .. v2 then gefunden = true end
    end
    wahr('tau_max steht als Beschriftung im Bild', gefunden, v1 .. ' / ' .. v2)
    -- Mausbewegung ueber dem Verlauf loest kein Neuzeichnen je Bewegung mehr aus
    local inv, alt = 0, platform.window.invalidate
    platform.window.invalidate = function() inv = inv + 1 end
    for i = 0, 20 do
        local x, y = Q.toScreen(5 + i * 1.5, 0)
        on.mouseMove(x, y)
    end
    platform.window.invalidate = alt
    wahr('Mausbewegung entlang der Wand zeichnet hoechstens einmal neu', inv <= 1, inv)
    Q.setView(0, false)
end)

fall('32 Verwoelbung', function()
    T.abschnitt('Verwoelbung: Quadrat woelbt nicht, Rechteck nach Eckformel, C-Profil nach Lehrbuch')
    local function wertBei(samples, u, v)
        for _, s in ipairs(samples) do
            if math.abs(s.u - u) < 1e-6 and math.abs(s.v - v) < 1e-6 then return s.ux end
        end
    end
    -- Quadratrohr 10x10, t=1: I_T = 4*100^2/40 = 1000, keine Verwoelbung
    T.zug({ -5, 5, 5, 5, 5, -5, -5, -5, -5, 5 }, 1); T.rechne()
    local q, fehler = Q.verwoelbung(1000, 1)
    wahr('Quadrat: berechnet', q ~= nil, fehler)
    if q then
        zahl('Quadrat: I_T = 1000', q.It, 1000, 1e-9)
        zahl('Quadrat: u_x = 0 ueberall', q.max_abs, 0, 1e-9)
        zahl('Quadrat: Umlauf schliesst', q.schluss, 0, 1e-9)
        wahr('Quadrat: geschlossen', q.closed == true)
    end
    -- Rechteckrohr 10x6, t=1: I_T = 4*60^2/32 = 450, Ecke |u| = theta*b*h*|b-h|/(4(b+h)) = 3.75 theta
    T.reset(); kasten(1, 1); T.rechne()
    local rr, f2 = Q.verwoelbung(1000, 1)
    wahr('Rechteck: berechnet', rr ~= nil, f2)
    if rr then
        zahl('Rechteck: I_T = 450', rr.It, 450, 1e-9)
        local theta = 1000 / (1 * 450)
        zahl('Rechteck: theta = MT/(G I_T)', rr.theta, theta, 1e-9)
        local soll = theta * 10 * 6 * 4 / (4 * 16)
        zahl('Rechteck: |u| in der Ecke (5,3)', math.abs(wertBei(rr.samples, 5, 3) or 0), soll, 1e-9)
        zahl('Rechteck: |u| in der Ecke (-5,-3)', math.abs(wertBei(rr.samples, -5, -3) or 0), soll, 1e-9)
        wahr('Rechteck: Nachbarecken mit entgegengesetztem Vorzeichen',
            (wertBei(rr.samples, 5, 3) or 0) * (wertBei(rr.samples, -5, 3) or 0) < 0)
        zahl('Rechteck: u = 0 auf der Symmetrieachse (0,3)', wertBei(rr.samples, 0, 3) or 999, 0, 1e-9)
        zahl('Rechteck: u_max = Eckwert', rr.max_abs, soll, 1e-9)
        zahl('Rechteck: Umlauf schliesst', rr.schluss, 0, 1e-9)
        local summe, laenge = 0, 0
        for _, sm in ipairs(rr.samples) do
            local w = (sm.parameter <= 1e-9 or sm.parameter >= 1 - 1e-9) and 0.5 or 1
            summe = summe + sm.ux * sm.thickness * sm.ds * w; laenge = laenge + sm.thickness * sm.ds * w
        end
        zahl('Rechteck: mittlere Verwoelbung = 0', summe / laenge / soll, 0, 1e-6)
    end
    -- C-Profil (offen): Steg h=10, Flansche b=5, t=1, e = 1.875 -> omega_M = (h/2)(b-e) = 15.625 an der Flanschspitze,
    -- e*h/2 = 9.375 am Stegende, null in Stegmitte (antisymmetrisch)
    T.reset()
    T.duenn(P(5, 0), P(0, 0), 1); T.duenn(P(0, 0), P(0, 10), 1); T.duenn(P(0, 10), P(5, 10), 1)
    local r = T.rechne()
    local cc, f3 = Q.verwoelbung(1000, 1)
    wahr('C-Profil: berechnet (offen)', cc ~= nil and cc.closed == false, f3)
    if cc then
        local theta = 1000 / (1 * r.It)
        zahl('C: I_T offen', cc.It, r.It, 1e-12)
        zahl('C: |u| an der Flanschspitze = theta*15.625', math.abs(wertBei(cc.samples, 5, 0) or 0), theta * 15.625, 1e-6)
        zahl('C: |u| am Stegende = theta*9.375', math.abs(wertBei(cc.samples, 0, 0) or 0), theta * 9.375, 1e-6)
        zahl('C: u = 0 in Stegmitte', wertBei(cc.samples, 0, 5) or 999, 0, 1e-6)
        wahr('C: Flanschspitze und Stegende mit entgegengesetztem Vorzeichen',
            (wertBei(cc.samples, 5, 0) or 0) * (wertBei(cc.samples, 0, 0) or 0) < 0)
        zahl('C: antisymmetrisch (Spitze oben = -Spitze unten)',
            (wertBei(cc.samples, 5, 10) or 0) + (wertBei(cc.samples, 5, 0) or 0), 0, 1e-6)
    end
end)

fall('33 Verwoelbung: Menue, Dialog, Esc', function()
    T.abschnitt('[b] -> 7. Verwoelbung: eigener Modus, MT gilt nur dort, Esc schliesst')
    kasten(1, 1); T.rechne()
    Q.menu(5, 1)
    local items = Q.menuTexte()
    wahr('Menuepunkt 7 heisst Verwoelbung', items[7] ~= nil and items[7]:find('Verw', 1, true) ~= nil, items[7])
    wahr('Menue hat 8 Punkte', #items == 8, #items)
    on.charIn('7')
    wahr('Dialog offen (Schritt 1: MT)', Q.woelb().step == 1, Q.woelb().step)
    on.charIn('1'); on.charIn('2'); on.backspaceKey()
    wahr('Backspace loescht im Dialog ein Zeichen', Q.inputText() == '1', Q.inputText())
    wahr('  ohne Loeschabfrage', Q.loeschFrage() == false)
    on.escapeKey()
    wahr('Esc schliesst den Dialog', Q.woelb().step == 0)
    wahr('vorher keine Torsion', Q.torsionResults() == nil)
    local res = Q.woelbEingabe(1000, 81000)
    wahr('Verwoelbung berechnet', res ~= nil, Q.status())
    if res then
        zahl('MT intern in Nmm (Eingabe 1000 Nm)', res.M, 1000 * 1000, 1e-9)
        zahl('G uebernommen', res.G, 81000, 1e-9)
        wahr('Ansicht sichtbar', Q.woelb().visible == true)
    end
    wahr('MT nicht an die Torsion der Schubspannung uebergeben', Q.torsionResults() == nil)
    T.texte, T.pos = {}, {}; T.zaehlerReset()
    Q.paint(T.gc)
    local mt = false
    for _, t in ipairs(T.texte) do if t:find('MT = ', 1, true) then mt = true end end
    wahr('Momentpfeil beschriftet', mt)
    wahr('Verlauf als Polylinien gezeichnet', T.zaehler.polylinien >= 4, T.zaehler.polylinien)
    local ef = T.ergebnisfeld()
    local hat = false
    for _, t in ipairs(ef) do if t:find('Verwoelbung', 1, true) then hat = true end end
    wahr('Ergebnisfeld hat den Block Verwoelbung', hat)
    on.escapeKey()
    wahr('Esc schliesst die Ansicht', Q.woelb().visible == false and Q.woelb().results == nil)
    T.texte, T.pos = {}, {}
    Q.paint(T.gc)
    mt = false
    for _, t in ipairs(T.texte) do if t:find('MT = ', 1, true) then mt = true end end
    wahr('nach Esc kein Momentpfeil mehr', not mt)
    -- offenes Profil: Warnung statt Fehler
    T.reset()
    T.duenn(P(5, 0), P(0, 0), 1); T.duenn(P(0, 0), P(0, 10), 1); T.duenn(P(0, 10), P(5, 10), 1); T.rechne()
    Q.meldungWeg()
    local ro = Q.woelbEingabe(100, 81000)
    wahr('offen: berechnet', ro ~= nil and ro.closed == false)
    local m = Q.meldung()
    wahr('offen: Warnung "nicht in der Formelsammlung"', m ~= nil
        and tostring(m.text):find('nicht in der Formelsammlung', 1, true) ~= nil, m and m.text)
    on.escapeKey(); on.escapeKey()
    -- massiv: Fehler
    T.reset()
    T.massiv({ type = 'rect', points = { P(-2, -2), P(2, 2) } }); T.rechne()
    Q.meldungWeg()
    local rm = Q.woelbEingabe(100, 81000)
    wahr('massiv: nicht berechnet', rm == nil)
    m = Q.meldung()
    wahr('massiv: Fehlermeldung', m ~= nil and m.fehler == true and tostring(m.text):find('duennwandige', 1, true) ~= nil,
        m and m.text)
end)

T.ende('Querschnitt')
