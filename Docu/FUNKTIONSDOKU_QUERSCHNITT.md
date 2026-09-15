# Funktionsdokumentation Querschnitt.lua

Diese Datei wird automatisch von der KI-Assistenz gepflegt (siehe `.github/copilot-instructions.md`). Sie gehoert zum Querschnittsmodul `Querschnitt.lua`.
Sie beschreibt zu jeder Funktion: **Zweck**, **Moeglichkeiten** und **Grenzen/bekannte Einschraenkungen**.

---

## 1. Eingabe, Formatierung & Einheiten

### `evaluate_input(expr)`
- **Zweck:** Wertet einen vom Nutzer eingegebenen Ausdruck numerisch aus.
- **Moeglichkeiten:** Nutzt zuerst den TI-Nspire-CAS (`math.eval("approx(...)")`), faellt sonst auf einfache Lua-Ausdruecke zurueck.
- **Grenzen:** Nur Ausdruecke, die entweder das CAS oder `load()` versteht; kein Fehlertext bei ungueltiger Eingabe (gibt nur `nil` zurueck).

### `floatToFrac_lua(value, tolerance, max_denominator)`
- **Zweck:** Nach Kettenbruch-Algorithmus die kuerzeste Bruchdarstellung einer Dezimalzahl finden.
- **Moeglichkeiten:** Liefert `"h/k"` oder ganze Zahl als String, begrenzt durch `max_denominator`.
- **Grenzen:** Irrationale/komplizierte Werte liefern `nil`, wenn keine Naeherung innerhalb der Toleranz gefunden wird.

### `smartToFracStr(value, tolerance)`
- **Zweck:** Zahl je nach `zahlenFormat` als Dezimalwert, Bruch oder Wurzel-Bruch darstellen.
- **Moeglichkeiten:** Erkennt einfache Wurzelausdruecke (`sqrt(n)`) durch Quadratzahl-Extraktion aus `value^2`.
- **Grenzen:** Wurzel-Erkennung nur fuer `zahlenFormat == 1` und `value^2 <= 10000`; sonst Dezimaldarstellung mit 4 Nachkommastellen.

### `formatLabel(value)`
- **Zweck:** Kurzform von `smartToFracStr` fuer Anzeige-Strings (z. B. Koordinatenbeschriftungen).
- **Moeglichkeiten:** Nutzt feste Toleranz `10^-casToleranz`.
- **Grenzen:** Nicht-numerische Werte liefern `"0"`.

### `point_to_line_dist(px, py, x1, y1, x2, y2)`
- **Zweck:** Kuerzester Abstand eines Punkts zu einer begrenzten Strecke (nicht zur unendlichen Geraden).
- **Moeglichkeiten:** Wird fuer Hover-Erkennung und Belegungspruefung (`occupied`) genutzt.
- **Grenzen:** Keine, robuste Standardformel inkl. Clamping auf `[0,1]`.

### `unit_factor(unit)`
- **Zweck:** Umrechnungsfaktor einer Einheit (Kraft/Laenge/Moment) auf die internen Basiseinheiten (N, mm, Nmm).
- **Grenzen:** Unbekannte Einheit liefert `1` (keine Fehlermeldung).

### `input_to_internal(value, unit)`
- **Zweck:** Nutzereingabe in interne Basiseinheit umrechnen (Multiplikation mit `unit_factor`).

### `cycle_unit(current, units)`
- **Zweck:** Naechste Einheit aus einer Liste zyklisch weiterschalten (fuer Menüoptionen wie Kraft-/Laengen-/Momenteinheit).

### `unit_label(power)`
- **Zweck:** Beschriftung fuer Laengen-Einheit hoch `power` (z. B. `mm^4`).
- **Grenzen:** Nur fuer Laengen-Einheiten gedacht (nicht fuer Kraft/Moment).

### `display_length/area/volume/inertia/moment/force(value)`
- **Zweck:** Interne SI-nahe Werte (mm, mm², mm³, mm⁴, Nmm, N) in die aktuell gewaehlte Anzeige-Einheit umrechnen.
- **Grenzen:** Reine Skalierung; keine Rundung, keine Format-Entscheidung (siehe `formatLabel`/`string.format` an den Aufrufstellen).

---

## 2. KOS, Anzeige-Transformation & Achsen

### `current_axes()` / `axes()`
- **Zweck:** Liefert die aktuellen Achsbezeichner (z. B. `"y","z"`) abhaengig von `plane` und `swapped`.
- **Grenzen:** Nur 3 Ebenen vorgesehen (`xy`, `yz`, `xz`); dritte Achse wird an anderen Stellen separat berechnet (`c_lbl` in `buildMenuItems`).

### `toScreen(u, v)` / `toScreenKOS(u, v)` / `fromScreen(x, y)`
- **Zweck:** Umrechnung zwischen internen Modellkoordinaten und Bildschirmpixeln, inkl. Rotation des angezeigten KOS (`rotation` 0/90/180/270°) fuer `toScreenKOS` (nur zum Zeichnen der Achsenpfeile, nicht fuer Elemente).
- **Grenzen:** `rotation` nur in 90°-Schritten unterstuetzt.

### `snap(x)`
- **Zweck:** Rundet eine Koordinate auf das aktuelle Raster (`raster`).
- **Grenzen:** Symmetrisches Runden um 0; kein adaptives Raster.

### `coordinatesForDisplay(u, v)` / `coordinatesFromDisplay(u, v)`
- **Zweck:** Zentrale Vorzeichen-/Achsentransformation zwischen internen (u,v) und angezeigten Koordinaten je nach `rotation`.
- **Moeglichkeiten:** Wird fuer alle Anzeige-Texte, Kraftkomponenten, Momentendichten und den Schubmittelpunkt konsistent verwendet.
- **Grenzen:** Muss als lokale Vorwaertsreferenz deklariert sein (`local coordinatesForDisplay` vor der Definition), da mehrere fruehere Funktionen (`displayedVector`) sie referenzieren, bevor sie definiert wird. Nur 4 Rotationsstufen abgedeckt.

### `forceComponentsForDisplay/FromDisplay(fu, fv)`
- **Zweck:** Wrapper um `coordinatesForDisplay/FromDisplay` speziell fuer Kraftkomponenten.

### `setDisplayedPointCoordinate(point, coordinate, value)`
- **Zweck:** Einzelne angezeigte Koordinate (u oder v) eines Punkts setzen, unter Beruecksichtigung der Rotation.
- **Grenzen:** Setzt immer beide internen Koordinaten neu (Rundtrip ueber Display-Koordinaten), auch wenn nur eine geaendert wird.

### `displayedCoordinateSigns()`
- **Zweck:** Liefert die Vorzeichen (+1/-1) fuer u/v-Achsen bei der aktuellen Rotation (Kurzform von `coordinatesForDisplay(1,1)`-Logik).
- **Grenzen:** Wird separat von `coordinatesForDisplay` gepflegt; muss bei neuen Rotationsstufen synchron gehalten werden.

### `displayedVector(u, v)`
- **Zweck:** Kurz-Alias fuer `coordinatesForDisplay`, genutzt in Momenten-/Schubmittelpunktberechnungen.

### `displayedMomentDensity(sample)`
- **Zweck:** Momentendichten (`moment_z_density`, `moment_y_density`) eines Schubfluss-Samples in Anzeigerichtung transformieren.
- **Grenzen:** Nutzt eigene Vorzeichentabelle statt `coordinatesForDisplay` direkt (Wartung an zwei Stellen noetig).

---

## 3. Geometrie-Grundformen (Flaeche, Schwerpunkt, Traegheitsmomente)

### `poly_props(pts)`
- **Zweck:** Flaeche, Schwerpunkt und Traegheitsmomente eines beliebigen (auch nicht konvexen) Polygons per Shoelace-Formel.
- **Moeglichkeiten:** Basis fuer Rechteck, Dreieck, Trapez/Polygon und dicke Linien (`massiv_linie`).
- **Grenzen:** Keine Selbstueberschneidungspruefung; bei entarteten Polygonen (`A ≈ 0`) werden Nullwerte zurueckgegeben.

### `sector_props(p1, p2, p3, is_segment)`
- **Zweck:** Flaeche/Schwerpunkt/Traegheitsmomente eines Kreisausschnitts (`is_segment=false`) oder Kreisabschnitts (`is_segment=true`).
- **Grenzen:** `p1` = Mittelpunkt, `p2`/`p3` definieren Start-/Endradius bzw. Sehne; Winkel wird immer im mathematisch positiven Sinn ab `p2` bestimmt.

### `thin_line_props(p1, p2, t)`
- **Zweck:** Flaeche/Schwerpunkt/Traegheitsmomente eines geraden duennwandigen Linienelements der Dicke `t`.
- **Grenzen:** Vernachlaessigt das lokale `t^3/12`-Eigentraegheitsmoment (duennwandige Naeherung).

### `berechneLokaleWerte(elem)`
- **Zweck:** Dispatcher: berechnet A/ys/zs/Iy/Iz/Iyz eines Massiv-Elements je nach `elem.type` (rect, circle, triangle, trapezoid, sector, segment, massiv_linie).
- **Grenzen:** Loch-Elemente (`elem.is_hole`) liefern negierte Werte; unbekannter Typ liefert Nullwerte.

### `get_thin_props(elem)`
- **Zweck:** Dispatcher fuer duennwandige Elemente (`duenn_kreis`, `duenn_kreis_bogen` oder gerade Linie via `thin_line_props`).
- **Grenzen:** Kreisbogen-Traegheitsmomente ueber trigonometrische Integrale, keine geschlossene Fallback-Naeherung bei extrem kleinem Radius (`R < 1e-5` -> Nullwerte).

### `berechneNumerisch(elem, index_of_elem)`
- **Zweck:** Rasterbasierte numerische Naeherung von A/ys/zs/Iy/Iz/Iyz fuer Elemente ohne geschlossene Formel (z. B. nach "Addieren (Numerisch)" bei Ueberlappung).
- **Moeglichkeiten:** Beruecksichtigt bereits vorhandene ueberlappende/vorherige Elemente (Loch- und Additions-Logik).
- **Grenzen:** Feste Rasterung `40x40`; Genauigkeit sinkt bei sehr duennen/kleinen Elementen; markiert System als `is_numeric_system = true` (Warnhinweis in der UI).

---

## 4. Kollision, Loecher & Ueberlappung

### `is_point_inside(elem, u, v)`
- **Zweck:** Punkt-in-Element-Test fuer alle Massiv-/Duennwand-Typen (inkl. `massiv_linie`-Bandbereich, Kreisbogen-Winkeltest).
- **Grenzen:** Fuer `sector`/`segment`/`duenn_kreis_bogen` wird der Winkeltest ueber `atan2`-Differenzen gemacht; bei extrem kleinen Radien numerisch instabil.

### `getBoundingBox(elem)`
- **Zweck:** Achsparallele Bounding-Box eines Elements (fuer Zoom, numerische Integration, Kernflaechen-Punktesammlung).
- **Grenzen:** Fuer Kreisboegen wird der volle Kreis als Box angenaehert (keine exakte Bogen-Box).

### `checkOverlapStatus(new_elem)`
- **Zweck:** Prueft, ob ein neues Massiv-Element ein bestehendes vollstaendig ueberdeckt (`"inside"`), teilweise ueberlappt (`"partial"`) oder frei steht (`"none"`).
- **Moeglichkeiten:** Steuert die Lochabzugs-/Additions-Abfrage (`mode = "overlap_prompt"`).
- **Grenzen:** Stichprobenbasiert (5x5 innere Punkte); sehr duenne Ueberlappungsbereiche koennen uebersehen werden.

---

## 5. Duennwand-Graph, Schubfluss & Torsion (Kernstueck)

### `find_closed_cells()`
- **Zweck:** Baut einen Knoten/Kanten-Graph aus allen `duenn_elemente`, entfernt iterativ freie Enden (Grad ≤ 1) und ermittelt die verbleibende geschlossene Zelle: torsionswirksame Flaeche `Am` und `I_T,geschlossen = 4*Am^2 / Σ(L/t)` (Bredt'sche Formel).
- **Grenzen:** Unterstuetzt nur **eine** zusammenhaengende geschlossene Zelle sauber; bei mehrzelligen Profilen wird nur ein Umlauf (erster gefundener Pfad) ausgewertet, kein Mehrzellen-Gleichungssystem.

### `berechneMaxSchubspannung(Vz)`
- **Zweck:** Rasterbasierte Ermittlung der maximalen Schubspannung eines **massiven** Querschnitts unter vertikaler Querkraft (klassische `τ = V*S/(I*b)`-Methode ueber Zeilenintegration).
- **Grenzen:** Nur fuer Massiv-Querschnitte (keine Duennwand-Kombination); 100x140-Raster, Genauigkeit rasterabhaengig. Aktuell nicht mehr im aktiven Berechnungspfad referenziert (Altfunktion, siehe `berechneSchubspannungsResultate` fuer den TM2-Streifenansatz).

### `berechneDuenneSchubspannung(Qa, Qb)`
- **Zweck:** Kernfunktion der duennwandigen Schubspannungsberechnung. Zerlegt alle `duenn_elemente` in atomare Kanten (inkl. Schnittpunkte/T-Knoten/Symmetrieachsen-Schnitte), baut einen Graphen und integriert den Schubfluss entlang aller Pfade.
- **Moeglichkeiten:**
  - Erkennt automatisch Verzweigungsknoten, freie Enden und T-Stoesse.
  - Reihenfolge der Integration: (1) freie Enden zuerst, (2) `resolve_branch_nodes()` fasst an Verzweigungen ankommende Teilmomente zusammen, sobald nur noch ein Ast offen ist, (3) bei **symmetrischen** Profilen (`|Iyz| < 1e-5`) wird zusaetzlich an einem Symmetrieachsen-Schnittpunkt gestartet (fixiert den unbestimmten Schubfluss `q0` einer geschlossenen Zelle), danach erneut `resolve_branch_nodes()` – das behandelt auch **Mischprofile** (geschlossene Zelle mit angehaengten freien Aesten) korrekt.
  - Liefert `samples` (mit `tau_a`, `tau_b`, `tau`, `Sy`, `Sz`, `moment_*_density`, `torsion_sign`, `s`, ...) und `paths` (fuer die Pfeil-/Start-Markierungen im Schubverlaufsbild); jeder Pfad kennzeichnet den fachlichen Starttyp (`free` oder `symmetry`), sofern er an einem freien Rand bzw. an der Symmetrieachse beginnt.
  - Statische Momente und Momentendichten werden intern in der geometrischen KOS gespeichert und erst bei der Verlaufsdarstellung mit derselben Rotationsabbildung wie die gezeichnete KOS orientiert. Freie Integrationsanfaenge starten mit statischem Moment null.
- **Grenzen:**
  - Fuer **unsymmetrische geschlossene Zellen** wird `q0` nicht ueber die allgemeine Vertraeglichkeitsgleichung (`∮ dq/t = 0`) bestimmt – der Restschnitt wird deterministisch mit Startwert 0 orientiert, das Ergebnis ist dann **nicht exakt**.
  - Mehrzellige geschlossene Profile werden nicht als gekoppeltes Gleichungssystem geloest.
  - Integrationsschrittweite ist an `raster` gekoppelt (mind. 32 Stuetzstellen pro atomarer Kante), nicht an die Bildschirmzoomstufe.

### `berechneOffenenSchubmittelpunkt()`
- **Zweck:** Schubmittelpunkt ueber Momentengleichgewicht der tatsaechlichen Schubspannungsverteilung (Einheitslasten `Qa=1`/`Qb=1`).
- **Moeglichkeiten:** Funktioniert fuer offene Profile immer exakt (statisch bestimmt). Seit der Erweiterung auch fuer **symmetrische geschlossene/gemischte** Profile (nutzt dieselben, dort korrekt mit `q0` fixierten Samples).
- **Grenzen:** Bei **unsymmetrischen geschlossenen** Profilen (`is_closed and not symmetric_profile`) wird weiterhin nur der Schwerpunkt als Naeherung zurueckgegeben (`closed = true`, keine echte Momentenberechnung), da die q0-Vertraeglichkeitsgleichung fehlt.

### `berechneSchubmittelpunkt()`
- **Zweck:** Wrapper um `berechneOffenenSchubmittelpunkt()`; faellt bei unbekanntem Ergebnis auf eine geometrische Schnittpunkt-Heuristik zweier nicht-paralleler duennwandiger Elemente zurueck.
- **Grenzen:** Die Fallback-Heuristik ist nur fuer einfache, aus zwei geraden Segmenten bestehende offene Profile sinnvoll; bei komplexeren Formen ohne eindeutigen Schnittpunkt wird `known = false` zurueckgegeben (Anzeige: "Symmetriepruefung offen").

### `berechneSchubMomentTabelle()`
- **Zweck:** Pro Element aufgeschluesselte Tabelle der resultierenden Schubkraefte (`X-Last`, `Y-Last`) und deren Momentbeitrag um den Schwerpunkt, fuer Einheitslasten `Qa=1` und `Qb=1`.
- **Grenzen:** Nutzt dieselbe Sample-Basis wie `berechneDuenneSchubspannung`; bei unsymmetrischen geschlossenen Zellen daher mit denselben Einschraenkungen behaftet (q0 nicht exakt bestimmt).

### `berechneTorsionsResultat(moment)`
- **Zweck:** Aus einem St. Venant'schen Torsionsmoment `moment` die maximale Torsionsspannung berechnen, getrennt fuer geschlossene (`τ = M/(2*Am*t)`) und offene (`τ = M*t/I_T`) Profile.
- **Grenzen:** Nutzt `default_t`/`max(elem.t)` als Bezugsdicke fuer offene Profile, nicht die tatsaechliche lokale Dicke jeder Stelle.

### `aktualisiereTorsionsverlauf(result)`
- **Zweck:** Ergaenzt bereits vorhandene Schubfluss-Samples (`shear_results.samples`) um den Torsionsanteil `tau_t` und das kombinierte `tau_total` (offen: Betragssumme, geschlossen: vorzeichenrichtige Summe).

### `torsionTauAtSample(sample)` / `combinedTauAtSample(sample)`
- **Zweck:** Torsionsspannung bzw. kombinierte Schub+Torsionsspannung an einer einzelnen Stichprobe fuer die Profildarstellung.
- **Grenzen:** Vorzeichenlogik unterscheidet offen (`sample.direction`) vs. geschlossen (`sample.torsion_sign`); bei Mischprofilen wird das ueber `shear_results.thin_closed` bzw. `torsion_results.closed` gesteuert.

### `berechneKraftTorsion()`
- **Zweck:** Torsionsmoment aus allen platzierten Kraeften um den Schwerpunkt berechnen (Kreuzprodukt aus Hebelarm und Kraftkomponenten in Anzeige-Koordinaten) und darauf `berechneTorsionsResultat` anwenden.
- **Grenzen:** Nur Kraftkomponenten in der Querschnittsebene (`fa`,`fb`); Kraft senkrecht zur Ebene (`fc`) erzeugt keine Torsion (das ist physikalisch korrekt fuer eine zentrische Normalkraft, aber es gibt keine Exzentrizitaets-Kopplung mit `fc`).

---

## 6. Systemberechnung, KOS-Verschiebung & Schnittgroessen aus Kraeften

### `berechneSystem()`
- **Zweck:** Zentrale Funktion, die nach jeder Geometrieaenderung aufgerufen wird: aggregiert alle Massiv- und Duennwand-Elemente zu `system_results` (Gesamtflaeche, Schwerpunkt `ys/zs`, `Iy/Iz/Iyz` bezogen auf den Schwerpunkt, Haupttraegheitsmomente `I1/I2` + Winkel, Widerstandsmomente `Wu/Wv`, offene/geschlossene Torsionskonstante).
- **Moeglichkeiten:** Speichert je Element zusaetzlich lokale Hauptachsen (`I_eta/I_zeta/alpha`) fuer die Einzelwerte-Tabelle. Ruft am Ende automatisch `berechneKraftTorsion()` und `kern_build()` (falls Kernflaechen-Modus aktiv) auf.
- **Grenzen:** `Iy/Iz/Iyz` in `system_results` sind **immer schwerpunktbezogen** (`IyS/IzS/IyzS`); die am aktuellen KOS-Ursprung dargestellten Werte in der Ergebnisspalte werden erst in `drawSpreadsheet` per Steiner-Rueckrechnung gebildet. Bei Flaeche `≈ 0` wird `system_results = nil` gesetzt (keine Teilergebnisse).

### `verschiebeKOSZumSchwerpunkt()`
- **Zweck:** Verschiebt alle Punkte, Kraefte und damit den Koordinatenursprung in den aktuellen Schwerpunkt.
- **Moeglichkeiten:** Verschiebt jeden gemeinsamen Knotenpunkt (z. B. bei verbundenen Duennwand-Elementen) nur **einmal** (`shifted_points`-Tabelle), damit topologisch verbundene Elemente zusammenhaengend bleiben.
- **Grenzen:** Reine Verschiebung, keine Rotation; muss nach Aufruf `berechneSystem()` erneut ausfuehren (macht die Funktion selbst).

### `berechneKraftResultanten()`
- **Zweck:** Resultierende Normalkraft `N` sowie Momente `Ma`/`Mb` aus allen platzierten Kraeften (nur `fc`-Komponente, senkrecht zur Querschnittsflaeche) um den Schwerpunkt.
- **Grenzen:** Vorzeichenkonvention haengt von `plane`/`swapped` ab (`orientation`-Tabelle); nur fuer die Sigma-x-Berechnung gedacht, nicht fuer Schubspannungen.

---

## 7. Sigma-x (Normal-/Schiefe Biegung) & Kernflaeche

### `berechneSigmaExtrema(N, My_Nm, Mz_Nm)`
 **Möglichkeiten:** Verarbeitet Momente intern einheitlich in `Nmm`; die Eingabemaske rechnet ein eingegebenes `Nm` genau einmal in `Nmm` um. Die Ergebnisanzeige rechnet den internen Wert anschließend abhängig von der gewählten Momenteneinheit zurück.

### `finishSigmaCalculation(Mz_Nm)`
 **Möglichkeiten:** Addiert manuelle und aus Kräften berechnete Momente direkt in `Nmm`, ohne eine bereits umgerechnete Eingabe nochmals zu skalieren.

### `openSigmaFromForces()`
- **Zweck:** Direkte σx-Auswertung ausschliesslich aus den bereits platzierten Kraeften, ohne manuelle Eingabemaske (analog zur Schubspannungs-Kraftauswertung).
- **Grenzen:** Setzt `sigma_N/My/Mz` auf 0 und nutzt ausschliesslich die Kraft-Resultierenden; wird nur angeboten, wenn `#kraefte > 0`.

### `openSigmaInput(oblique)` / `enterSigmaInput()`
- **Zweck:** Mehrstufige manuelle Eingabemaske fuer `N`, `My` (und bei `oblique=true` zusaetzlich `Mz`).
- **Grenzen:** Reine Texteingabe ueber `evaluate_input`; keine Bereichspruefung der eingegebenen Werte.

### `kern_dual(nu, nv, d)`
- **Zweck:** Dualitaetsbeziehung: wandelt eine neutrale Faser (Gerade `nu*(y-ys)+nv*(z-zs)=d`) in den zugehoerigen Kernpunkt um (Basis der Kernflaechen-Konstruktion).
- **Grenzen:** Setzt `system_results` mit gueltigem `A, Iy, Iz, Iyz` voraus; keine Pruefung auf `d ≈ 0` (Aufrufer filtern das).

### `kern_collect_points()`
- **Zweck:** Sammelt alle relevanten Randpunkte (inkl. Kreis-/Bogen-Stuetzstellen) aller **nicht-Loch**-Massiv- und aller Duennwand-Elemente fuer Kernflaechen- und Sigma-Extremwertberechnung.
- **Grenzen:** Bogen-Abtastung mit fester Schrittweite (~10° pro Stuetzpunkt); bei sehr kleinen Radien evtl. zu grob.

### `kern_build()`
- **Zweck:** Baut aus der konvexen Huelle der Randpunkte (Monotone-Chain-Algorithmus) die Kernflaechen-Geometrie: umhuellende Geraden (`kern_lines`) und Kernflaechen-Polygon (`kern_pts`/`kern_vertices`), inkl. Sonderfall Vollkreis und Bogenkanten.
- **Grenzen:** Basiert auf der konvexen Huelle der Randpunkte – bei stark konkaven Querschnitten (z. B. L-Profile) ist das nur eine Naeherung der wahren Kernflaeche, keine exakte Loesung fuer beliebige nicht-konvexe Raender.

---

## 8. Zeichnen / GUI (Canvas-Ausgabe)

### `drawAxes(gc)`
- **Zweck:** Zeichnet das grüne KOS-Kreuz (mit aktueller Rotation), den Schwerpunkt (rotes Kreuz) und die violett gestrichelten Hauptachsen 1/2.

### `drawGrid(gc, w, h)`
- **Zweck:** Zeichnet das Punktraster im sichtbaren Bereich.
- **Grenzen:** Feste Rasteranzahl (61x49 Punkte um den Ursprung), nicht dynamisch an Zoom/Fenstergroesse angepasst.

### `drawShapePath(gc, elem)`
- **Zweck:** Zeichnet die Grundflaeche eines Massiv-/Duennwand-Elements (fuer alle unterstuetzten Typen) inkl. Fuellung.

### `drawLocalAxes(gc, elem)`
- **Zweck:** Zeichnet die lokalen Hauptachsen (`eta`/`zeta`) eines einzelnen Elements bei Auswahl/Hover.

### `drawSpreadsheet(gc, w, h)`
- **Zweck:** Zeichnet die rechte Ergebnisspalte (Flaeche, Schwerpunktkoordinaten, `Iy/Iz/Iyz` am aktuellen KOS-Ursprung, Traegheitsradien, Widerstandsmomente, `I1,S/I2,S` schwerpunktbezogen, Torsionskonstanten, Schubspannungs-/Torsions-Zusatzwerte).
- **Grenzen:** Feste Spaltenbreite (`width = 210`); bei sehr vielen Zusatzzeilen (Schub+Torsion gleichzeitig) muss ggf. gescrollt werden (`results_scroll_y`).

### `drawSigmaInput/ drawShearInput / drawTorsionInput(gc, w, h)`
- **Zweck:** Zeichnen die jeweiligen mehrstufigen Texteingabemasken fuer σx-, Schub- und Torsionsberechnung.

### `drawShearProfileLegacy(gc)`
- **Zweck:** Zeichnet den gewaehlten Schubspannungs-/Momenten-Verlauf (`shear_view_mode` 1–10) als Liniendiagramm entlang des Profils, inkl. Rand-/Min-/Max-Markierungen, Pfeilmarkierungen der Laufrichtung und gezielter Startmarkierung an echten freien bzw. symmetrischen Integrationsanfaengen.
- **Grenzen:** Diagrammbreite ist ein fester Bildschirm-Pixelwert (`36/scale`), keine automatische Skalierung nach Spannungsgroesse ausser dem gemeinsamen `shared_section_max`.

### `drawShearProfile(gc)`
- **Zweck:** Wrapper, ruft die aktive Darstellung `drawShearProfileLegacy` auf.
- **Moeglichkeiten:** Entkoppelt den Aufruf aus `on.paint` von der aktuellen Implementierung der Schubverlaufsdarstellung.
- **Grenzen:** Die fachliche Darstellung liegt weiterhin vollstaendig in `drawShearProfileLegacy`.

### `drawShearSelector(gc, w, h)`
- **Zweck:** Zeigt das Auswahlmenue (Tasten 0–9) fuer die 10 verfuegbaren Schubspannungs-/Momentenverlaeufe, einspaltig untereinander, Kastengroesse passt sich automatisch an die Eintragsanzahl an.

### `drawSigmaResultsTable(gc, w, h)`
- **Zweck:** Tabellarische Detailausgabe aller σx-Zwischenwerte (`N`, `My`, `Mz`, `A`, `Iy/Iz/Iyz`, Extremstellen) mit Scroll-Unterstuetzung.

### `drawSigmaDistribution(gc, w, h)`
- **Zweck:** Liniendiagramm der σx-Verteilung ueber die Koordinate `z` (reiner Biegeanteil vs. Biegung+Normalkraft).
- **Grenzen:** Nur eindimensionale Darstellung ueber `z`, keine 2D-Flaechendarstellung (siehe `drawSigmaCrossSection`/`drawSigmaOverlay`).

### `drawSigmaCrossSection(gc, w, h)`
- **Zweck:** Zweigeteilte Ansicht: eingefaerbter Querschnitt (Zug/Druck-Heatmap, feste 28x22-Rasterung) plus separates Spannungsverlaufs-Diagramm.
- **Grenzen:** Rasteraufloesung fest (28x22 Zellen), keine adaptive Verfeinerung an Elementraendern.

### `drawSigmaOverlay(gc, w, h)`
- **Zweck:** Alternative Vollbild-Overlay-Darstellung der σx-Verteilung direkt ueber der Zeichenflaeche (inkl. neutraler Faser, Hauptachsen, Extremwert-Markierungen), adaptive Rasterung je nach Zoomstufe.
- **Grenzen:** Rasterzellenzahl an `scale` gekoppelt (12–60 Zellen je Achse); bei sehr grossem Zoom kann die Heatmap grob wirken.

### `drawSigmaExtrema(gc)`
- **Zweck:** Zeichnet nur die beiden Extrempunkte (`σx,max`/`σx,min`) als farbige Punkte in der normalen Querschnittsansicht.

### `drawMenu(gc, w, h)` / `buildMenuItems()`
- **Zweck:** `buildMenuItems()` liefert die Textzeilen der aktuellen Menueseite (`menuPage`), `drawMenu` zeichnet sie inkl. Hervorhebung der aktiven Zeile und Inline-Eingabefeld.
- **Grenzen:** Feste Kastenbreite (`220px`); bei sehr langen Zeilen (z. B. Elementbearbeitung mit vielen Punkten) kein Zeilenumbruch, nur Kuerzung durch Fensterbreite.

### `drawOverlapPrompt(gc, w, h)`
- **Zweck:** Zeigt den Abfrage-Dialog bei Flaechenueberlappung (Abziehen/Addieren/Verwerfen).

### `drawTable(gc, w, h)`
- **Zweck:** Scrollbare Einzelwerte-Tabelle je Element (A, Schwerpunkt, lokale und globale Traegheitsmomente inkl. Steiner-Anteilen).
- **Grenzen:** Spaltenbreite fest (`75px`), keine automatische Skalierung bei sehr vielen Elementen (nur horizontales/vertikales Scrollen ueber `table_scroll_x/y`).

### `drawShearMomentTable(gc, w, h)`
- **Zweck:** Zeigt die Tabelle aus `berechneSchubMomentTabelle()` (Teilkraefte je Element + Gesamtmoment) fuer die Schubmittelpunkt-Kontrolle.

### `drawInfArrow(gc, u0, v0, du, dv, label)`
- **Zweck:** Zeichnet einen "ins Unendliche" weisenden Pfeil (fuer Kernflaechen-Geraden parallel zu einer Achse, die die Achse nicht schneiden).

### `drawKern(gc, w, h)`
- **Zweck:** Zeichnet je nach `kernMode` (1 = umhuellende Geraden, 2 = Kernflaeche) die entsprechende Geometrie inkl. Hover-Hervorhebung und Schnittpunkt-Koordinatenanzeige.

---

## 9. Menü- & Interaktionslogik

### `toggleCalculationMenu()`
- **Zweck:** Oeffnet/schliesst das Berechnungsmenue (`menuPage = 5`) bzw. bei bereits vorhandenem `shear_results` das Schubspannungs-Zusatzmenue (`menuPage = 8`).
- **Moeglichkeiten:** Erreichbar ueber `Strg+Menü` (`on.menuKey`/`on.contextMenu`) **und** die Taste `b`.
- **Grenzen:** Tut nichts, solange eine Text-Eingabemaske aktiv ist (`sigma_input_step ~= 0 or inputMode`).

### `finish_shape(type_name)` / `finish_thin_line()`
- **Zweck:** Schliessen einer Massiv-Form bzw. eines Duennwand-Linienzugs nach den noetigen Klicks; ruft `checkOverlapStatus`/`berechneSystem` auf.
- **Grenzen:** `finish_thin_line()` zerlegt einen Linienzug in einzelne 2-Punkt-Elemente (`duenn_elemente`), keine Mehrpunkt-Elemente.

### `zoomCenter(factor)` / `autoZoom()`
- **Zweck:** Zoomen um die Bildschirmmitte bzw. automatisches Einpassen aller Elemente in den sichtbaren Bereich.

### `enterMenuInput()`
- **Zweck:** Verarbeitet eine abgeschlossene Texteingabe im Menuekontext (Raster, Dicke, KOS-Groesse, `ξ`-Profilbeiwert, Element-/Kraft-Koordinaten, Elementdicke).
- **Grenzen:** Keine Einheiten-/Wertebereichspruefung ausser Mindestwerten (`math.max(..., 1e-5)` o. ae.).

### `enterMenuAction()`
- **Zweck:** Verarbeitet die Auswahl eines Menuepunkts (Seitenwechsel, Modus setzen, Aktionen wie KOS-Verschiebung, Element loeschen, Punkt-Tausch bei Bogenelementen).
- **Grenzen:** Sehr grosse Funktion (naeherungsweise an der TI-Lua-Grenze von 60 lokalen Upvalues); neue Menueoptionen sollten bevorzugt global gespeicherte Zustandsvariablen verwenden, wenn die Grenze erreicht wird.

### `on.charIn(c)`
- **Zweck:** Zentrale Tastatur-Dispatch-Funktion fuer Zeicheneingaben (Menues oeffnen `m`/`d`/`b`, Ergebnisse `e`, Tabelle `t`, Schubverlauf `v` + Ziffern, Zoom `+`/`-`, `c`=Clear, `h`=AutoZoom, `k`=Kernflaechen-Modus, `o`=Optionen, Ueberlappungs-Dialog `1/2/3`).
- **Grenzen:** Einzeltasten-basiert (kein Modifikator ausser dem separaten `on.menuKey`/`on.contextMenu`); Tastenkollisionen muessen manuell geprueft werden, bevor neue Kuerzel vergeben werden.

### `on.arrowKey(k)`
- **Zweck:** Kontextabhaengige Pfeiltastensteuerung: Tabellen-/Ergebnis-Scrollen, Menuezeilen-Navigation (inkl. Links/Rechts-Seitenwechsel nur zwischen Optionsseite `4` und KOS-Verschiebungsseite `9`), sonst Verschieben der Zeichenflaeche.

### `on.enterKey()` / `on.menuKey()` / `on.contextMenu()`
- **Zweck:** Bestaetigen der aktuellen Eingabe/Auswahl bzw. Oeffnen des Berechnungsmenues per Kontextmenue-Taste.

### `on.escapeKey()`
- **Zweck:** Bricht alle offenen Eingaben/Untermenues ab, setzt aber (im Gegensatz zu `on.clearKey()`) keine Geometrie zurueck.

### `on.clearKey()` / `on.backspaceKey()` / `on.deleteKey()`
- **Zweck:** `on.clearKey()` loescht das gesamte Modell (Geometrie, Kraefte, Ergebnisse) und setzt KOS-Einstellungen wie `plane/rotation` auf Standard zurueck. `on.backspaceKey()` loescht ohne aktive Eingabe das zuletzt erstellte Element bzw. bei doppeltem Escape+Backspace das gesamte Modell. `on.deleteKey()` ist ein Alias fuer `on.backspaceKey()`.
- **Moeglichkeiten:** Das Loeschen eines Massiv-Elements berechnet die Systemwerte direkt neu.
- **Grenzen:** Eine automatische Neueinstufung vorhandener Elemente als Loch erfolgt nach dem Loeschen nicht; die Lochkennzeichnung eines Elements wird beim Anlegen bestimmt.

### `on.mouseMove(x, y)` / `on.mouseUp(x, y)`
- **Zweck:** Hover-Erkennung (Kraefte vor Elementen priorisiert) bzw. Klickverarbeitung fuer Zeichenmodi, Elementauswahl und Kernflaechen-Hover.

### `on.paint(gc)`
- **Zweck:** Zentrale Zeichenroutine, die je nach aktuellem Zustand (Tabelle/Sigma/Schub/Torsion-Eingabe/Normalansicht) die passenden Unterfunktionen aufruft.
- **Grenzen:** Sehr grosse Funktion mit vielen Zustandsabfragen; neue Anzeigezustaende sollten moeglichst als fruehe `return`-Zweige ergaenzt werden, um die Komplexitaet nicht weiter zu erhoehen.

---

## 10. Bekannte projektweite Einschraenkungen (Kurzuebersicht)

- **Mehrzellige geschlossene Duennwandprofile:** nicht unterstuetzt (nur eine Zelle wird ausgewertet).
- **Unsymmetrische geschlossene Zellen:** Schubfluss-Konstante `q0` nicht exakt bestimmt; Schubmittelpunkt faellt auf Schwerpunkt-Naeherung zurueck.
- **TI-Nspire-Lua-Upvalue-Grenze:** max. 60 lokale Upvalues je Funktion; grosse Funktionen (`enterMenuAction`, `on.paint`) sind nahe am Limit.
