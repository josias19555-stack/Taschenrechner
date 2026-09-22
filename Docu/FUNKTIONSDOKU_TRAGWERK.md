# Funktionsdokumentation: Tragwerks- und Statikmodul

Diese Datei dokumentiert die wichtigsten Funktionen des gemeinsamen Tragwerksmoduls aus `AktuellerStand.lua` und `Zeichnen.lua`. Funktionen in `AktuellerStand.lua` bilden Datenmodell, Eingabe, Berechnung, Kinematik und Export; Funktionen in `Zeichnen.lua` stellen diese Zustände grafisch dar.

## 1. Zustände und Datenmodell

### `math.eval`-Brücke: `cas_bridge.lua` / `python_cas_server.py` / `python_cas.py`

- **Zweck:** Emuliert den TI-Nspire-CAS-Aufruf `math.eval` über einen dauerhaft laufenden Python/SymPy-Server, damit `test_runner.lua` und `test_regression.lua` ohne Taschenrechner laufen.
- **Aufruf:** `luajit Emulator/test_regression.lua` bzw. `luajit Emulator/test_runner.lua [last]` aus beliebigem Ordner. `BIEGELINIE=<pfad>` testet eine andere Skriptversion, `CAS_VERBOSE=1` protokolliert jede Anfrage, `CAS_TIMEOUT=<s>` setzt die Wartezeit pro Anfrage (Standard 120 s).
- **Möglichkeiten:** TI-Semantik: Namen ohne Groß-/Kleinschreibung, `EI`, `lnc1`, `q_A` bleiben je ein Symbol, `log` = Zehnerlogarithmus. Unterstützt `f(x):=…`, `name:=…`, `DelVar`, `Disp`, `exact`, `approx`, `expand`, `string`, `integral` (bestimmt und unbestimmt), Matrizen `[[a,b][c,d]]`, `[a,b]`, `[a;b]`, 1-basierte Indizes `m[i,j]` (auch in Funktionsdefinitionen), `colAugment`, Matrixinverse. Jede Definition wird nur einmal eingelesen und integriert; ein kompletter Testlauf dauert wenige Sekunden.
- **Protokoll:** Nummerierte Anfrage-/Antwortdateien in `%TEMP%`, atomar geschrieben. Ergebnisse von `string(…)` bleiben in Lua immer Strings. Der Server beendet sich bei `cas.stop()` oder nach 120 s ohne Anfrage.
- **Grenzen:** Kein vollständiger TI-Nspire-CAS-Ersatz. Ausgaben folgen der SymPy-Normalform (z. B. `41*l^4*q/24`) und können sich in der Form, nicht im Wert, vom TI unterscheiden. Winkelfunktionen rechnen im Bogenmaß.

### Testsammlung `Emulator/tests/`

- **Aufruf:** `luajit Emulator/tests/alle.lua` führt alle Testreihen nacheinander aus (je ein Prozess mit eigenem CAS-Server) und gibt nur Fehler und eine Zusammenfassung aus; `-v` zeigt alles. Einzelne Reihen: `luajit Emulator/tests/<datei>.lua [Filter]`, mit `TEST_VERBOSE=1` jede Prüfung.
- **Reihen:** `test_regression.lua` (behobene Fehler, symbolischer Modus, Rand-LGS-Befunde), `test_runner.lua` (Originaltestfälle), `balken_hand.lua` (12 Balkensysteme gegen Lehrbuchformeln: w, φ, M, Q, u, N), `rahmen_hand.lua` (9 Rahmen gegen Handrechnung bzw. Kraftgrößenverfahren), `symbolisch.lua` (geschlossene Formeln und erwartete Abbrüche), `randlgs_fem.lua` (Rand-LGS gegen die FEM-Lösung, Stabenden exakt, Stabinneres gegen den gerundeten Referenzexport), `dehnstarr.lua` (Grenzwert EA → ∞ gegen Handrechnung mit dehnstarren Stäben, Abbruch bei Zwang), `oberflaeche.lua` (Warnhinweise mit ESC, Obermenü-Vorgaben für neue Stäbe, Umbruch der Fehlerbox, Stabmenü biegesteif/dehnsteif; `on.paint` mit Zeichen-Attrappe), `starr.lua` (biegesteife/dehnsteife Stäbe: Rand-LGS gegen Handrechnung, FEM-Verschiebungen und -Schnittkräfte exakt, Temperatur, symbolischer Modus), `kgv.lua` (KGV-Matrizen: X aus delta gegen die FEM, gelöster Pendelstab mit und ohne Eigenanteil), `starr_direkt.lua` (direkte Methode gegen Grenzwert-Methode an 12 Systemen einschließlich Klausur TM2 Aufgabe 4, Rückfall bei starr gegen starr), `randbed.lua` (Lesbarkeit der Randbedingungen: eingesetzte bekannte Werte, Gruppierung nach Biege- und Längslinie, Ergebnisse gegen die FEM), `temperatur.lua` (symbolische Temperatur, Klausurtyp „ΔT so, dass u = 0“ mit Probe, starre Scheibe, symbolisch gegen numerisch am unbestimmten Rahmen, h = 0, Hinweisbox), `querschnitt.lua` (Querschnittsmodul). Die übrigen Reihen rechnen mit `randDehnstarr = false` (endliches EA wie die FEM).
- **Eigene Tests:** `common.lua` stellt Bausteine bereit (`node`, `bar`, `fixed`, `pinned`, `roller`, `rechne`, `randLGS`, `pruef`, `zahl`, `ev`, `evs`, `fall`, `ende`).
- **Grenzen:** Alles läuft gegen den SymPy-Emulator, nicht gegen den TI-Nspire. Ableitungen (`d()`) kennt der Emulator nicht; die Handrechnungs-Tests interpolieren die Polynome exakt und leiten die Koeffizienten ab.

### `erstelleKnoten(lx, ly)`

- **Zweck:** Erzeugt einen Knoten mit Koordinaten, Lager-, Gelenk-, Last-, Feder-, Reaktions- und Ergebnisfeldern.
- **Möglichkeiten:** Initialisiert alle Freiheitsgrade und Ergebniswerte mit neutralen Standardwerten.
- **Grenzen:** Erstellt nur das Datenobjekt; die Einbindung in das Modell erfolgt durch die Zeichen- und Klicklogik.

### `erstelleStab(k1_idx, k2_idx)`

- **Zweck:** Erzeugt ein Stabobjekt zwischen zwei Knotenindizes.
- **Möglichkeiten:** Initialisiert $EA$, $EI$ samt Eingabetext (`EA_str = defEA_str`, `EI_str = defEI_str` aus dem Obermenü, damit ein symbolisches `EA` auch für später gezeichnete Stäbe gilt), Bogenradius, Lastausdrücke, Endlasten, Gelenke, Schnittgrößen und lokale Freiheitsgrade. Der aktuelle Standardwert für $EA$ beträgt $10^{10}$ und bildet für Vergleichsrechnungen ein nahezu axial starres Stabmodell ab.
- **Grenzen:** Prüft nicht selbst, ob die Knoten existieren oder identisch sind; solche Prüfungen müssen beim Erzeugen beziehungsweise Berechnen erfolgen.

### `pvvBackupSystem()` / `pvvRestoreSystem()`

- **Zweck:** Sichern und Wiederherstellen von Lagern, Gelenken und Stabendgelenken für den Prinzip-der-virtuellen-Verschiebungen-Modus.
- **Möglichkeiten:** Temporäres Lösen einer Bindung ohne dauerhafte Änderung des eigentlichen Tragwerks.
- **Grenzen:** Sichert die für PvV relevanten Bindungszustände, nicht beliebige neu hinzukommende Modellfelder.

## 2. Eingabe, Ausdrücke und Zahlenformat

### `evalInput(text, keep_str)`

- **Zweck:** Wertet numerische, CAS-kompatible oder symbolische Eingaben aus.
- **Möglichkeiten:** Akzeptiert Dezimalkomma, direkte Zahlen, Klammern, `+`, `-`, `*`, `/`, `^`, TI-Nspire-CAS-Funktionen und symbolische Variablen. Der Ausdruck wird in allen numerischen Eingabefeldern über denselben Parser ausgewertet; dazu gehören auch die Knotenfedersteifigkeiten `cx`, `cy` und `cm`. Auf Wunsch wird der Originaltext für die spätere symbolische Anzeige zurückgegeben.
- Symbolische Ausdrücke bleiben nach der Eingabe in den jeweiligen `*_str`-Feldern erhalten und werden in den Knoten-, Feder-, Stab- und globalen Einstellungsmenüs angezeigt; numerische Dummywerte werden nur intern für die Berechnung verwendet.
- CAS-Ergebnisse aus numerischen Zwischenberechnungen werden über eine eigene Konvertierung auf den ersten Rückgabewert begrenzt; dadurch bleiben symbolische Lastfunktionen wie `q/l*x` auch bei TI-Nspire-CAS-Rückgaben als Text stabil.
- Symbolische Anfangs- und Endwerte der Trapezlast werden mit der Stablänge in die Funktion `q(x)` eingebaut; bei einer funktionalen q-Last verwendet die Darstellung die vollständige CAS-Stützstellenkurve ohne zusätzlichen Dummy-Grundwert.
- Für grafische und numerische Zwischenwerte werden freie Symbole über ihre Dummywerte eingesetzt, während der ursprüngliche symbolische Ausdruck für Export und symbolische Ergebnisse erhalten bleibt.
- In der Elementlastbildung werden funktionale Lasten über CAS integriert.
- **Grenzen:** Bei nicht auswertbaren Ausdrücken wird `nil` beziehungsweise ein Dummywert aus dem symbolischen Modus verwendet. Eingaben sollten nach der Berechnung geprüft werden.

### `casToNumber(value)`

- **Zweck:** Wandelt numerische Rückgaben des TI-Nspire-CAS beziehungsweise des lokalen SymPy-Emulators sicher in Lua-Zahlen um.
- **Möglichkeiten:** Akzeptiert bereits numerische Werte und normalisiert Dezimalkommas in Textwerten.
- **Grenzen:** Symbolische oder nicht numerische Texte liefern `nil`.

### `getDummyNumeric(text)`

- **Zweck:** Ermittelt für symbolische Ausdrücke einen numerischen Ersatzwert, damit numerische Systempfade weiterlaufen können.
- **Möglichkeiten:** Erkennt Variablennamen, legt Dummywerte in `sym_vars` an und markiert den symbolischen Modus.
- **Grenzen:** Der Ersatzwert ist keine symbolische Lösung und darf nicht mit dem exakten CAS-Ergebnis verwechselt werden.

### `smartToFracStr(v, tol)` / `floatToFrac_lua(val, tol, max_denom)`

- **Zweck:** Formatiert numerische Ergebnisse als Dezimalzahl, Bruch oder einfachen Wurzelbruch; der quadrierte Wert wird vor seiner Bereichsprüfung berechnet.
- **Möglichkeiten:** Begrenzung des Nenners, Toleranzsteuerung und Anzeigeformat über `zahlenFormat`.
- **Grenzen:** Komplexe irrationale Werte werden nur angenähert oder dezimal angezeigt.

### `fN_export(n)`

- **Zweck:** Formatiert numerische Werte für den TI-Nspire-CAS-Export.
- **Möglichkeiten:** Rundet nach `casToleranz`, wandelt wissenschaftliche Schreibweise in CAS-Syntax und versucht Brüche zu erzeugen.
- **Grenzen:** Das Ergebnis hängt von `math.eval` und der CAS-Funktion `approxFraction` ab.

### `exportBiegelinienToTI(stab_index)`

- **Zweck:** Erzeugt die symbolischen Biegelinien $EI\,w(x)$ aus Lastpartikulärlösung und Hermite-Randwerten.
- **Möglichkeiten:** Setzt die Lastpartikulärlösung und die vier Hermite-Randwerte aus dem berechneten Stabzustand zusammen; der Anfangs-Biegeversatz wird mit seinem lokalen Vorzeichen als $c_1=v_a EI$ übernommen. Symbolische Lasten werden als CAS-Integrale exportiert.
- **Grenzen:** Die Vorzeichenkonvention folgt den lokalen Stabgrößen des Rechenmodells. Eine externe Musterlösung mit anderer Last- oder Koordinatenkonvention kann deshalb abweichende Polynome liefern.

### `exportBiegelinienNeuToTI()` / `exportULinienNeuToTI()` (Rand-LGS, `neuRandLGS`)

- **Zweck:** Stellt für das ganze System alle Rand- und Übergangsbedingungen auf, löst sie im CAS und exportiert je Stab `wneu_i(x) = EI·w_i(x)`, `uneu_i(x) = EA·u_i(x)` sowie die Bedingungen `randbed` als Spaltenvektor aus Strings (`["w1(x1=l)=w2(x2=0)";"EIw2''(x2=0)=0";…]`; Schnittgrößen als Ableitungen: Q = `-EIw'''`, M = `-EIw''`, N = `EAu'`). Beide Menüpunkte rufen dieselbe Funktion; sie braucht keine vorherige FEM-Berechnung.
- **Ansatz:** je Stab `EI·w = wp + c1·x³/6 + c2·x²/2 + c3·x + c4` und `EA·u = up + C1·x + C2` mit `wp = ∫q(t)(x−t)³/6 + ∫m(t)(x−t)²/2 − EI·κT·x²/2`, `up = −∫n(t)(x−t) + EA·εT·x`; daraus `Q = −c1 − ∫q`, `M = −(wp'' + c1·x + c2)`, `N = C1 − ∫n`, `φ = −w'`. Konventionen wie im Rechenmodell (`n = (−dy, dx)/L`, `M' = Q − m`).
- **Bedingungen je Knoten:** Verträglichkeit von `u`, `w`, `φ` aller Stabenden (über ein Referenzende, bei Bedarf globale Knotenunbekannte `ux(K)`, `uy(K)`), `N=0`/`Q=0`/`M=0` an N-/Q-/M-Gelenken, Lagerbedingung in den (gedrehten) Lagerrichtungen oder Gleichgewicht aus Stabendkräften, Knotenlasten (`last_x`, `last_y`, `last_w`, `last_m`) und Federn (`cx`, `cy`, `f_winkel`, `cm`).
- **Lösung (`neuVorElimination(rows, mitAlias)`):** drei Stufen, alle ohne CAS-Aufruf. (1) Zeilen mit nur einer Unbekannten liefern deren Wert; `wannBekannt[j]` merkt den Schritt (für die Anzeige), `r.quelle` die gelieferte Unbekannte. (2) Unbekannte, die nur in einer einzigen Zeile vorkommen, fallen mit dieser Zeile aus dem LGS und werden am Schluss daraus nachgerechnet (kein Einsetzen, keine längeren Ausdrücke). (3) Zeilen mit zwei Unbekannten und reinem Zahlenverhältnis ohne Konstante (`x_j = f·x_m`) werden überall eingesetzt; ein kleiner Zahlenparser (`num`) erkennt Zahlenkoeffizienten wie `-(1)` oder `(1/2)*(2)`. Stufe (3) läuft nicht bei der Grenzwertmethode (`rleps`), weil die Ausdrücke dort zu groß werden. Rückgabe: `values`, verbleibende Zeilen, Liste der vorab eliminierten Unbekannten mit ihrer Zeile, `wannBekannt` und die Kopplungen. Der Rest wird in unabhängige Blöcke zerlegt (Union-Find über die Unbekannten der verbleibenden Zeilen) und Block für Block mit `exact(simult(A,b))` gelöst; passen Zeilen- und Unbekanntenzahl eines Blocks nicht zusammen, wird alles zusammen gelöst. Danach werden die vorab eliminierten Werte rückwärts nachgerechnet (lange Ausdrücke einmal mit `exact` vereinfacht). Zahlen gehen exakt ein (`neuZahl`). Die exportierten Funktionen sind exakt (keine Rundung); auf dem Rechner bei Bedarf `approx(wneu1(x))`.
- **Anzeige der Bedingungen (`rlBedText(cond, wert)`):** Die Texte entstehen erst nach der Vorelimination. `wert(q)` liefert den Wert einer Größe, wenn alle ihre Konstanten *vor* dieser Bedingung feststanden (chronologisch wie in einer Handrechnung) und der Wert kurz ist (≤ 24 Zeichen, bei `rleps` über `limit`); solche Größen werden durch ihren Wert ersetzt und wandern in den konstanten Teil. So wird aus `"w1(x1=l)=u2(x2=3*l)"` bei dehnstarrem, gehaltenem Stab 2 `"w1(x1=l)=0"`. Bleibt keine Größe übrig, wird der unveränderte Text genommen. `rlBedText` liefert zusätzlich die Zahl der noch offenen Größen.
- **Trennung Biegelinie/Längslinie:** `typVon(j)` ordnet jede Unbekannte einem Stab-`w` (c1..c4) oder `u` (C1, C2) zu; Knotenunbekannte zählen zu beiden. `huelle(typ)` verfolgt von allen Konstanten dieses Typs aus rückwärts, welche Zeilen sie bestimmen (`bestimmt[j]`: Zeilennummer oder `"block"` für das simult-System), und meldet, ob dabei nur Größen des eigenen Typs auftauchen; vorab bestimmte Größen zählen als Zahlen, weil sie im Text eingesetzt sind. Ergebnis: `randbed` wird in zwei Gruppen mit Überschrift ausgegeben (beide unabhängig, oder eine Gruppe genügt für sich), `randinfo` nennt den Fall.
- **Temperatur (`neuTemperatur`):** εT und κT als exakte CAS-Texte aus `To_str`/`Tu_str`/`alpha_str`/`h_str` (sonst Zahlen), damit auch symbolisch; nil, wenn der Anteil 0 ist. Aktiv, sobald To oder Tu gesetzt ist; κT nur mit h ≠ 0. Die Entscheidung läuft über die Texte, weil alle Symbole im symbolischen Modus den Platzhalterwert 1 haben.
- **Verschiebungen `wv_i`, `uv_i`:** `wneu_i/EI` bzw. `uneu_i/EA`; bei starren Stäben die exportierte Verschiebung bzw. 0. Gedacht für `solve(uv1(l)=0,dt)` auf dem Rechner. Werden wie `wneu`/`uneu` vorher gelöscht.
- **Methode für starre Stäbe (`randStarrDirekt`, Obermenü Seite 4):** `neuRandLGS` prüft und löscht, `neuRandLGSLoesen(direkt)` stellt auf, löst und exportiert. Direkt (Standard): `neuStabDaten(..., direkt)` setzt für biegesteife Stäbe `w = c4 + c3·x − κT·x²/2` (c3 = w'(0), c4 = w(0)) und für dehnsteife `u = C2 + εT·x`; Schnittgrößen wie sonst über c1, c2, C1. Ist das LGS singulär (starre Teile gegenseitig statisch unbestimmt), wiederholt `neuRandLGS` mit der Grenzwert-Methode. Lasttexte, die nur aus Zahlen bestehen und 0 ergeben (`neuIstNull`), werden nicht integriert; die Konstanten werden erst im Export vereinfacht.
- **Starre Stäbe, Grenzwert-Methode (`stabDehnsteif`, `stabBiegesteif`):** Diese Stäbe bekommen im LGS `EA = 1/rleps` bzw. `EI = 1/rleps`. Nach `simult` bestimmt `neuGrenzwert` jede Konstante als `limit(…, rleps, 0)` (nil bei `undef`, ∞ oder CAS-Fehler). Für die Starrkörperanteile (`C2 = EA·u(0)` bzw. `c3`, `c4`) wird zuerst `limit(rleps·Konstante)` gebildet: sind sie 0 und εT bzw. κT = 0, bleibt `uneu_i = EA·u_i` bzw. `wneu_i = EI·w_i`; sonst werden `uneu_i(x) = εT·x + u(0)` bzw. `wneu_i(x) = −κT·x²/2 + w'(0)·x + w(0)` exportiert. `randinfo` (Spaltenvektor aus Strings) nennt die starren Stäbe und die Funktionen, die Verschiebungen sind. Unendliche Grenzwerte (behinderte Temperaturverformung) brechen mit Meldung ab.
- **Grenzen:** Keine Bögen (Abbruch mit Meldung), keine Stäbe mit `is_cut`, keine KGV-Einheitszustände. Fehler werden zusätzlich als `randbed = ["Fehler: …"]` abgelegt; vorher werden `randbed`, `randinfo`, `rleps`, `wneu1..` und `uneu1..` gelöscht. Knoten, an denen alle Stabenden N- bzw. Q-Gelenke haben, bekommen ohne Last die Bedingung `U=0` in der freien Richtung, mit Last wird abgebrochen. Mechanismen führen zu `Rand-LGS singulär`. Ein Moment an einem Vollgelenkknoten wird wie im FEM ignoriert. Ein singuläres oder nicht quadratisches System wird gemeldet, nicht still ausgegeben. Im symbolischen Modus gelten dessen Grenzen (`symbolFehler`).

## 3. Geometrie, Anzeige und Mausposition

### `loescheAlles()` / `on.clearKey()` / `loeschFrage`
- **Zweck:** `on.clearKey` setzt nur `loeschFrage` und zeichnet die Rueckfrage "Wirklich alles loeschen?"; `on.enterKey` ruft `loescheAlles()` (der bisherige Inhalt von `clearKey`: Knoten, Staebe, Auswahl, Modi), `on.escapeKey` bricht ab. Beide Handler pruefen die Frage als Erstes, die Box wird in `on.paint` zuletzt gezeichnet. Bei leerem System wird ohne Rueckfrage geloescht.

### Menueposition
- **Zweck:** Alle Menuekaesten (Obermenue, Knoten, Stab, PvV) stehen links. Die Zeichenbefehle im Menueblock sind relativ zur Fensterbreite `b` geschrieben (`b - 160` usw.); statt jede Position zu aendern, wird im Block ein eigener Bezugswert `local b = mW + 20` gesetzt. Der Kasten liegt damit bei `x = 10`, die innere Aufteilung bleibt unveraendert.

### `pixelZuMeterX(px)` / `pixelZuMeterY(py)`

- **Zweck:** Wandelt Bildschirmkoordinaten in gerasterte Modellkoordinaten um.
- **Möglichkeiten:** Berücksichtigt Zoom, Ursprungsoffset und `rasterMass`.
- **Grenzen:** Rundet immer auf das aktuelle Raster; frei liegende Zwischenkoordinaten können dadurch nicht direkt angelegt werden.

### `abstand(x1, y1, x2, y2)` / `abstandZurLinie(...)`

- **Zweck:** Berechnet Punkt- und Punkt-zu-Strecken-Abstände für Hover- und Auswahltests.
- **Möglichkeiten:** Clamping auf das endliche Streckenintervall verhindert Auswahl außerhalb eines Stabs.
- **Grenzen:** Die Auswahlgenauigkeit hängt vom festgelegten Bildschirmabstand ab.

### `drawRotatedPolygon(gc, pts, cx, cy, angle)`

- **Zweck:** Zeichnet ein Polygon um einen Mittelpunkt gedreht.
- **Möglichkeiten:** Wird für gedrehte grafische Symbole und Lastdarstellungen verwendet.
- **Grenzen:** Nur Darstellung; verändert keine Modellkoordinaten.

### `drawArrow(gc, x1, y1, x2, y2, kopf)`

- **Zweck:** Zeichnet einen Linienpfeil mit Pfeilspitze.
- **Möglichkeiten:** Gemeinsame Darstellung für Lasten, Reaktionen, PvV-Beiträge und kinematische Bewegungen. `kopf` skaliert die Spitze; die Lastflächen der Streckenlasten zeichnen mit `LASTPFEIL_KOPF` (1.4) etwas größere Spitzen als der Rest.
- **Grenzen:** Pfeillänge und Spitzengeometrie sind grafische Bildschirmwerte.

### `lastResultierende(pts, L, wA, wB, R_cas, S_cas, faktor)`

- **Zweck:** Resultierende `R` und statisches Moment `S` (um den Anfangsknoten) einer Streckenlast.
- **Möglichkeiten:** Liegen elf CAS-Stützwerte vor, wird mit der Simpson-Regel integriert (exakt bis zur dritten Ordnung); sonst Trapezformel aus den Endwerten plus vorbereitetem CAS-Anteil. `faktor` bildet projizierte Lasten ab.
- **Grenzen:** Bei nicht polynomialen Lastfunktionen ist die Stützwert-Integration eine Näherung; ohne berechnetes System fehlen die Stützwerte.

### `resultierendenLabel(L_phys, L_eff, qs, qa, qb, R_cas, S_cas, R_num, S_num, typ)`

- **Zweck:** Beschriftung `R = …` für die Resultierende einer Streckenlast in der Explosionsansicht.
- **Möglichkeiten:** Im symbolischen Modus liefert `processDistLoad_PvV` den CAS-Term, sonst wird der Betrag als Zahl gesetzt; die Richtung zeigt der Pfeil.
- **Grenzen:** Reine Beschriftung; der Wert selbst wird an der Aufrufstelle aus Last und Länge gebildet.

### `merkeResultierende(x, y)`

- **Zweck:** Merkt den Angriffspunkt einer Resultierenden in `glob_resultant_pts`.
- **Möglichkeiten:** `drawBemassung` nimmt diese Punkte zusammen mit den Knoten in die globale Maßkette auf, sodass der Hebelarm ablesbar ist.
- **Grenzen:** Die Liste wird zu Beginn jedes `on.paint` geleert und gilt nur für den aktuellen Frame.

## 4. CAS- und Ergebnisexport

### `speichereMatrix(name, mat)`

- **Zweck:** Speichert eine Matrix oder einen Vektor im TI-Nspire-Variablenbereich.
- **Möglichkeiten:** Nutzt `var.store`, sofern vorhanden; meldet sonst, dass Speichern nicht möglich ist.
- **Grenzen:** Funktioniert nur in einer Umgebung mit verfügbarer Variablenschnittstelle.

### `exportStabToTI(i)` / `exportKnotenToTI(i)`

- **Zweck:** Exportiert bereits berechnete lokale Stab- beziehungsweise Knotenmatrizen.
- **Möglichkeiten:** Schreibt stabspezifische Matrizen wie `stab1_k`, `stab1_p`, `stab1_v` und Knotenmatrizen wie `knot1_pv`.
- **Grenzen:** Ohne vorherige Berechnung oder ohne gespeicherte Matrizen erfolgt kein sinnvoller Export.

### `exportAllToTI()`

- **Zweck:** Exportiert alle vorhandenen lokalen Matrizen, Knotenmatrizen sowie globale Systemmatrizen.
- **Möglichkeiten:** Erzeugt unter anderem `sys_k`, `sys_f` und `sys_u`.
- **Grenzen:** Bricht ohne berechnete Stäbe ab.

### `exportSchnittkraefteToTI(stab_index)`

- **Zweck:** Erzeugt CAS-Funktionen für Normalkraft-, Quer- und Momentenverläufe.
- **Möglichkeiten:** Unterstützt konstante, trapezförmige, globale und funktionale Lastanteile; kann einen einzelnen Stab oder alle Stäbe exportieren.
- **Grenzen:** Für Sonderfälle und Bögen gelten gesonderte Exportpfade; die CAS-Syntax muss kompatibel sein.

### `exportBiegelinienToTI(stab_index)`

- **Zweck:** Exportiert Biegelinien beziehungsweise $v(x)\cdot EI$.
- **Möglichkeiten:** Kombiniert Anfangsverschiebung und Anfangsverdrehung mit partikulären Quer- und Momentenlasten sowie funktionalen CAS-Integralen. Bei Stäben an einem inneren Gelenk wird die Biegelinie direkt vom Gelenkende aus fortgesetzt, sodass keine zusätzliche Endkorrektur die Gelenkkinematik verfälscht. In der symbolischen Superposition wird der Endverschiebungsbeitrag `vb` mit dem Vorzeichen der exportierten Randkorrektur übernommen; die vollständigen Differenzen aus Randwert und Lastintegral werden vor der Multiplikation mit der Hermite-Randfunktion geklammert. Dadurch bleiben Endwerte, lokale Verschiebung und symbolische Referenzlösung konsistent.
- **Grenzen:** Der Export ist auf berechnete Stäbe und gültige Steifigkeiten angewiesen; bei symbolischen Gelenksystemen bleibt die Darstellung auf den verfügbaren CAS-Ausdrücken und Randwerten aufgebaut.

### `exportULinienToTI(stab_index)`

- **Zweck:** Exportiert axiale Verformungslinien beziehungsweise $u(x)\cdot EA$.
- **Möglichkeiten:** Verarbeitet konstante und funktionale Normallasten.
- **Grenzen:** Für ungültige oder verschwindende Stablängen ist keine sinnvolle Funktion möglich.

### `exportKGVToTI()`

- **Zweck:** Exportiert die Einflussmatrizen des Kraftgrößenverfahrens.
- **Möglichkeiten:** Berechnet `kgv_delta` und `kgv_delta0` durch wiederholte Berechnung des Grund- und Einheitszustands. `getGap` liefert die Klaffung der jeweiligen Bindung aus den Knotenverschiebungen; für einen gelösten Pendelstab (`typ = "pendel_n"`, Stab ist `is_cut`) kommt über `eigenNachgiebigkeit` seine eigene Nachgiebigkeit `L/EA` zu `delta_ii` dazu (dehnsteif: 0). Geprüft in `Emulator/tests/kgv.lua` gegen die FEM-Lösung.
- **Grenzen:** Nur aktiv, wenn der automatische KGV-Solver überzählige Größen gefunden hat. Der Automatismus wählt nur unbelastete Stäbe (auch ohne Temperatur), daher braucht `kgv_delta0` keinen Zusatzterm.

### `exportLGSMatrixToTI(only_build)` / `buildLGS()`

- **Zweck:** Baut das globale Gleichungssystem als exportierbare Matrix und Gleichungsliste auf.
- **Möglichkeiten:** Unterstützt Fachwerk- und allgemeine Teilsystem-LGS, speichert `ggw_a`, `ggw_b`, `ggw_x`, `ggw_eqs` und kann eine lesbare Gleichungsliste für die LGS-Ansicht erzeugen.
- **Grenzen:** Bei großen oder symbolischen Systemen können Matrixgröße und CAS-Auswertung die Gerätegrenzen erreichen.

## 5. Lokale Lasten und Systemgrößen

### `getEqQ(s, L, fN)` / `getEqN(s, L, fN)`

- **Zweck:** Bauen die lokalen beziehungsweise projizierten Lastausdrücke für Quer- und Normallast auf.
- **Möglichkeiten:** Kombinieren Stablasten mit globalen Linienlasten und deren Projektion.
- **Grenzen:** Die Richtungs- und Vorzeichenkonventionen sind an die lokale Staborientierung gekoppelt.

### `updateAlleLasten()`

- **Zweck:** Berechnet CAS-Stützwerte und partikuläre Lastanteile für alle Stäbe neu.
- **Möglichkeiten:** Verarbeitet funktionale $q$, $n$, $m$, $g_x$ und $g_y$, erzeugt Verlaufspunkte und Zwischenwerte für Schnittgrößen und Verformungen.
- **Grenzen:** Benötigt für funktionale Eingaben `math.eval`; die Genauigkeit der grafischen Stützwerte hängt von `ptsBiegelinie` ab.

### `getTopologicalN()`

- **Zweck:** Bestimmt eine topologische Systemzahl aus Knoten, Stäben, Lagern, Federn und Gelenken.
- **Möglichkeiten:** Berücksichtigt jede aktive translatorische oder rotatorische Feder als eine zusätzliche elastische Bindung, sofern am gleichen Freiheitsgrad kein ideales Lager sitzt. Grundlage für die Anzeige von `n` und die Stabilitäts-/Bestimmtheitskontrolle.
- **Grenzen:** Die Zahl ist eine Modellierungsdiagnose; Federsteifigkeiten müssen positiv sein, und die Zählung ersetzt keine vollständige fachliche Prüfung von Sonderfällen oder der tatsächlichen Matrixrangprüfung.

### Längslinienexport (`exportULinienToTI`)

- **Zweck:** Erzeugt die axiale Verformungslinie `u_EA_stab_i` aus den axialen Endverschiebungen der FEM-Lösung und der axialen Streckenlast.
- **Möglichkeiten:** Konstante, linear veränderliche und CAS-auswertbare Lastfunktionen `n(x)`; der Lastanteil wird über `integral((x-t)*n(t),t,0,x)` doppelt integriert.
- **Grenzen:** Konzentrierte axiale Einzelkräfte innerhalb eines Stabes benötigen eine stückweise Darstellung. Die global gekoppelte Variante ist `exportULinienNeuToTI` (Rand-LGS, `uneu_i = EA·u_i`).

### `findZeroForceMembers()`

- **Zweck:** Findet Nullstäbe in Fachwerken durch wiederholte lokale Gleichgewichtsregeln.
- **Möglichkeiten:** Erkennt unbelastete Ein-, Zwei- und Drei-Stab-Knoten sowie Fälle mit Kraft- oder Rollenlagerrichtung.
- **Grenzen:** Funktioniert auf Basis idealisierter Fachwerkbedingungen; Rahmenwirkungen und nichtstandardisierte Lastfälle können die Interpretation einschränken.

## 6. Systemberechnung

### `starteBerechnung()`

- **Zweck:** Zentraler Startpunkt für eine vollständige Tragwerksanalyse.
- **Möglichkeiten:** Löscht alte CAS-Variablen, prüft symbolische Eingaben, bereitet KGV-Zustände vor, sichert das System, berechnet numerisch und symbolisch, stellt den numerischen Grundzustand wieder her und bereitet Beschriftungen vor.
- **Grenzen:** Bei kinematischen, singulären oder nicht auswertbaren Systemen können nur Warnungen beziehungsweise unvollständige Ergebnisse entstehen.

### Starre Stäbe: `stabDehnsteif(s)`, `stabBiegesteif(s)`, `stabEA_K`/`stabEI_K`, `stabEA`/`stabEI`

- **Zweck:** `stabBiegesteif` = Schalter `s.biegesteif`; `stabDehnsteif` = `s.dehnsteif` oder (`randDehnstarr` und EA weder im Stabmenü eingegeben (`s.EA_manuell`) noch symbolisch). `stabEA_K`/`stabEI_K` liefern die Steifigkeit für die Steifigkeitsmatrix (starrer Anteil 0, außer im PvV-Modus). `stabEA`/`stabEI` liefern für Zeichnung und Referenzexporte einen sehr großen Ersatzwert (`STARR_FAKTOR`·größte Steifigkeit der nicht starren Stäbe).
- **Grenzen:** Mehrere starre Stäbe, die sich gegenseitig statisch unbestimmt halten, haben keine eindeutige Kraftverteilung; die FEM nimmt dann eine Lösung der Zwangskräfte (Ausgleichsrechnung), das Rand-LGS die Verteilung gleicher Starrheit.

### `baueZwangsbedingungen(ids)`, `faktorisiereMitZwang(K, zeilen)`, `loeseMitZwang(zf, F)`

- **Zweck:** Starre Stäbe in der FEM exakt: Zwangsbedingungen `C·u = g` (dehnsteif: `u_B − u_A = εT·L`, ohne N-Gelenk; biegesteif: `φ_A − φ_B = −κT·L` und, ohne Q-Gelenk, `w_B − w_A + L·φ_A = −κT·L²/2`) in globalen Freiheitsgraden (über `T·TKᵀ`, auch bei gedrehten Lagern). `faktorisiereMitZwang` eliminiert sie (reduzierte Stufenform, redundante Zeilen werden verworfen) zu `u = Tz·u_r + u0` und faktorisiert `Tzᵀ K Tz`. `loeseMitZwang` löst, bestimmt die Lagrange-Multiplikatoren aus `(C Cᵀ) λ = C (F − K u)` und legt je Stab die lokalen Zusatz-Endkräfte `clᵀ λ` in `glob_zwang` ab; `berechneAlleSchnittgroessen` addiert sie zu `s_local`.
- **Grenzen:** Zeilen, die nur festgehaltene Freiheitsgrade betreffen, entfallen (z. B. starrer Stab zwischen zwei Einspannungen: Kräfte aus den Festeinspannkräften). Im PvV-Modus gibt es keine Zwangsbedingungen. `exportLGSMatrixToTI` exportiert weiter die unreduzierte Matrix.

### `sammleHinweise()`

- **Zweck:** Nach jeder Berechnung Hinweise für die gelbe Box sammeln (`hinweisListe`, `hinweisOffen`; ESC setzt `hinweisQuittiert`; die Signatur enthält `systemFingerabdruck()` aus allen Eingabefeldern von Knoten und Stäben (`KNOTEN_EINGABEN`, `STAB_EINGABEN`) sowie Schaltern, daher erscheinen die Hinweise nach jeder Systemänderung wieder): Temperatur mit To ≠ Tu bei h = 0; Temperatur im symbolischen Modus; im symbolischen Modus Zahl-EI (bzw. -EA) eines nicht starren Stabes ohne beidseitige Gelenke, wenn andere Steifigkeiten (Stab-EI/EA oder Federn) symbolisch sind und die FEM-Endkräfte Biegung (bzw. Normalkraft) zeigen.
- **Grenzen:** Die Beanspruchung wird an den FEM-Endkräften mit Platzhalterwerten gemessen (relativ 1e-9 zur größten Endkraft); bei kinematischem System keine Steifigkeitshinweise.

### `berechneSystemGleichungen(...)` / `rechneAktuellesSystem()`

- **Zweck:** Erzeugen und lösen die globalen Gleichungen beziehungsweise schreiben die gelösten Freiheitsgrade zurück in Knoten und Stäbe.
- **Möglichkeiten:** Berücksichtigen Lager, Federn, Gelenke, Knotenlasten, Stablasten und lokale Steifigkeitsbeiträge.
- **Grenzen:** Die exakte Signatur und interne Aufteilung ist eng an den aktuellen Solverzustand gekoppelt; neue Freiheitsgrade müssen in allen Assemblierungsstufen ergänzt werden.

### `berechneSystemGleichungen(...)` im Fachwerkmodus

- **Zweck:** Assemblierung von Stabnormalkräften und Lagerreaktionen für ein ebenes Fachwerk.
- **Möglichkeiten:** Baut je Knoten Gleichgewichtszeilen in X- und Y-Richtung.
- **Grenzen:** Fachwerkannahmen schließen allgemeine Momenten- und Biegesteifigkeitswirkungen aus.

### `getSuppLetter(nodeIndex)` / `getHingeNumber(nodeIndex)`

- **Zweck:** Erzeugt stabile Bezeichner für Lager und Gelenke in Anzeigen und LGS-Exporten.
- **Möglichkeiten:** Nummeriert nur relevante beziehungsweise erkannte Lager-/Gelenkobjekte.
- **Grenzen:** Die Bezeichnung ist eine Anzeige- und Exportkennung, keine dauerhaft gespeicherte Objekt-ID.

## 7. Kinematik und Polplan

### `buildPolplan()`

- **Zweck:** Baut aus Knoten, Stäben und Bindungen den Polplan beziehungsweise die Starrkörperscheiben auf.
- **Möglichkeiten:** Ermittelt Pole, Polstrahlen, feste Scheiben und Widersprüche.
- **Grenzen:** Die geometrische Polplananalyse setzt ein sinnvoll verbundenes ebenes System voraus.

### `calcKinematicStates()`

- **Zweck:** Berechnet Verschiebungs- und Rotationszustände kinematischer Scheiben.
- **Möglichkeiten:** Liefert Zustände für Animation, PvV-Auswertung und kinematische Beschriftungen.
- **Grenzen:** Die Zustände sind relativ beziehungsweise normiert und keine reale elastische Lösung.

### `getKinematicDisp(nodeIndex)` / `getKinematicRot(nodeIndex)`

- **Zweck:** Liefert die kinematische Verschiebung beziehungsweise Rotation eines Knotens.
- **Möglichkeiten:** Wird von Animation, PvV und grafischen Detailanzeigen genutzt.
- **Grenzen:** Nur verfügbar, wenn zuvor gültige kinematische Zustände erzeugt wurden.

### `pvvPrepareCAS()` / `getKinematicWork_Stab(...)`

- **Zweck:** Bereitet CAS-Ausdrücke und Arbeitsbeiträge für den Prinzip-der-virtuellen-Verschiebungen-Modus vor.
- **Möglichkeiten:** Ermittelt $W_i$ aus Lasten und virtuellen Verschiebungen beziehungsweise Rotationen.
- **Grenzen:** Symbolische Arbeitsausdrücke können bei komplexen Lasten nur teilweise numerisch angezeigt werden.

## 8. Knoten-, Stab- und Menüsteuerung

### `on.mouseMove(x, y)`

- **Zweck:** Aktualisiert Mausposition, Hoverobjekt und Bildschirmdarstellung.
- **Möglichkeiten:** Erkennt Knoten und Stäbe und ermöglicht kontextabhängige Bearbeitung.
- **Grenzen:** Hover hängt von Bildschirmmaßstab und Auswahlabstand ab.

### `on.mouseUp(x, y)`

- **Zweck:** Verarbeitet Knoten-, Stab- und Messpunktklicks.
- **Möglichkeiten:** Legt neue Knoten an, verbindet ausgewählte Knoten zu Stäben, öffnet PvV-Auswahl und setzt Messpunkte für Hover-Schnittgrößen.
- **Grenzen:** Die Eingabe ist rastergebunden; ein Klick in ein bestehendes Objekt wird als Auswahl statt als neuer Punkt interpretiert.

### `on.charIn(char)`

- **Zweck:** Zentrale Tastaturverteilung.
- **Möglichkeiten:** Steuert Berechnung, Ansichtsmodi, Export-/LGS-Ansicht, Optionen, Kinematik, Polplan, Zoom, AutoZoom, Stabrichtung und Löschfunktion.
- **Grenzen:** Einzelzeichenkürzel benötigen eindeutige Belegung. Nicht auswertbare oder unvollständige Ausdrücke werden beim Bestätigen nicht übernommen.

### `on.enterKey()`

- **Zweck:** Bestätigt Menüs, Eingabefelder, Modelländerungen und PvV-Aktionen.
- **Möglichkeiten:** Bearbeitet Knotenkoordinaten, Lager, Lasten, Federn, Stabparameter, Linienlasten, Gelenke und Exporte.
- **Grenzen:** Die Bedeutung der Eingabetaste hängt von Menütyp, Menüseite, Zeile und Kinematikmodus ab.

### `on.arrowKey(key)`

- **Zweck:** Navigiert Menüseiten und verschiebt Ansicht oder Ergebnisdarstellungen.
- **Möglichkeiten:** Scrollt LGS, wechselt Menüseiten und bewegt das Zeichenfenster.
- **Grenzen:** Während Texteingaben sind Pfeiltasten nicht allgemeine Navigationsbefehle.

### `on.clearKey()` / `on.backspaceKey()` / `on.escapeKey()`

- **Zweck:** Löschen beziehungsweise Abbrechen von Eingaben und Zuständen.
- **Möglichkeiten:** `clear` setzt das komplette Modell zurück, `backspace` entfernt das ausgewählte Objekt, `escape` arbeitet von oben nach unten: offene Eingabe/Menü, dann Warnhinweise (`warnungKinematisch`, `warnungStarrBestimmt`, Box zu `symbolFehler` über `symbolFehlerOffen`; ein ESC schließt alle und tut sonst nichts), dann Sondermodi und PvV-Bindungen, zuletzt die Auswahl. `symbolFehler` selbst bleibt gesetzt, bis die nächste Berechnung ihn neu prüft.
- **Grenzen:** Ein vollständiges Löschen ist nicht dasselbe wie das Entfernen eines einzelnen Knotens; beim Knotenlöschen müssen Stabindizes angepasst werden.

## 9. Zeichnen und Ergebnisdarstellung in `Zeichnen.lua`

### `on.paint(gc)`

- **Zweck:** Zentrale Zeichenroutine des Tragwerksmoduls.
- **Möglichkeiten:** Zeichnet Raster, Achsen, Knoten, Stäbe, Lager, Lasten, Reaktionen, Schnittkraftverläufe, Verformungen, Explosion, Polplan, Kinematik, PvV und Menüs.
- **Grenzen:** Die Routine ist zustandsabhängig und groß; neue Ansichten müssen frühzeitig in die bestehende Moduslogik integriert werden.

### `drawExplosionArrow(...)` / `drawReactionArrow(...)` / `drawFBDArrow(...)`

- **Zweck:** Zeichnen gerichtete Last-, Reaktions- und Freikörperpfeile.
- **Möglichkeiten:** Berücksichtigen Vorzeichen, KGV-Zustand, Beschriftung und symbolische beziehungsweise numerische Werte.
- **Grenzen:** Pfeile sind für Bildschirmlesbarkeit skaliert und nicht maßstäbliche Kraftvektoren.

### `get_u_val(s, x, L_m, j, nA, nB)`

- **Zweck:** Berechnet die axiale Verformung an einer Stabposition.
- **Möglichkeiten:** Kombiniert homogene Endverschiebungen mit klassischem und CAS-basiertem Lastanteil.
- **Grenzen:** Nutzt die im Stab gespeicherten Verformungs- und Steifigkeitswerte; bei ungültigem $EA$ ist keine physikalisch sinnvolle Darstellung möglich.

### Schnittgrößen- und Verlaufspfad in `on.paint`

- **Zweck:** Berechnet und zeichnet $N$, $Q$, $M$, $U$ und $W$ entlang gerader Stäbe und segmentierter Bögen.
- **Möglichkeiten:** Berücksichtigt Endgrößen, Streckenlasten, Linienlastprojektionen, CAS-Stützwerte und Verlaufsskalierung.
- **Grenzen:** Die Darstellung ist punktweise abgetastet und dient der Visualisierung, nicht als Ersatz für eine unabhängige kontinuierliche Auswertung.

### Kinematik- und PvV-Darstellung in `on.paint`

- **Zweck:** Visualisiert virtuelle Bindungslösungen, Verschiebungen, Rotationen, Klaffungen, Arbeitsanteile, Pole und rotierende Scheiben.
- **Möglichkeiten:** Animierte Pfeile und Bögen, normierte Verschiebungsfaktoren, Beschriftung von $\delta_N$, $\delta_Q$, $\delta_M$ und Arbeitsausdrücken.
- **Grenzen:** Die Animation ist eine überhöhte qualitative Darstellung.

## 10. Projektweite technische Grenzen

- Das Skript ist für die TI-Nspire-Lua-Umgebung mit verfügbarer `platform.window`, `timer`, `var` und optional `math.eval` ausgelegt.
- Die Bildschirmdarstellung und Menüs sind auf die begrenzten Abmessungen des TI-Nspire-Fensters zugeschnitten.
- Große Systeme, viele Stäbe, symbolische Lasten und umfangreiche CAS-Exporte können Rechenzeit, Speicher und Bildschirmdarstellung belasten.
- Die TI-Nspire-Lua-Grenze von maximal etwa 60 lokalen Upvalues pro Funktion ist bei großen Funktionen wie `on.paint` und `on.enterKey` zu berücksichtigen.
- Die Funktionsnamen und Zustandsfelder bilden eine gekoppelte interne Schnittstelle; Änderungen an Freiheitsgraden, Gelenken oder Lasten müssen Solver, Export und Darstellung gemeinsam berücksichtigen.
