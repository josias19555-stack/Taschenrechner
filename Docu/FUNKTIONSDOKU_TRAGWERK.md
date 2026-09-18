# Funktionsdokumentation: Tragwerks- und Statikmodul

Diese Datei dokumentiert die wichtigsten Funktionen des gemeinsamen Tragwerksmoduls aus `AktuellerStand.lua` und `Zeichnen.lua`. Funktionen in `AktuellerStand.lua` bilden Datenmodell, Eingabe, Berechnung, Kinematik und Export; Funktionen in `Zeichnen.lua` stellen diese Zustände grafisch dar.

## 1. Zustände und Datenmodell

### `math.eval`-Brücke in `test_runner.lua` / `python_cas.py`

- **Zweck:** Emuliert den für die lokalen Regressionstests benötigten TI-Nspire-CAS-Aufruf über Python und SymPy.
- **Möglichkeiten:** Persistente Variablen und Funktionsdefinitionen, `DelVar`, `exact`, `expand`, `approx`, symbolische Ausdrücke und bestimmte Integrale mit TI-Nspire-ähnlicher Syntax.
- **Grenzen:** Kein vollständiger TI-Nspire-CAS-Ersatz; nicht unterstützte Befehle liefern keinen verwertbaren Wert. Durch einen Python-Prozess pro Aufruf ist der Testlauf langsamer als auf dem Taschenrechner oder mit dem alten Mock.

### `erstelleKnoten(lx, ly)`

- **Zweck:** Erzeugt einen Knoten mit Koordinaten, Lager-, Gelenk-, Last-, Feder-, Reaktions- und Ergebnisfeldern.
- **Möglichkeiten:** Initialisiert alle Freiheitsgrade und Ergebniswerte mit neutralen Standardwerten.
- **Grenzen:** Erstellt nur das Datenobjekt; die Einbindung in das Modell erfolgt durch die Zeichen- und Klicklogik.

### `erstelleStab(k1_idx, k2_idx)`

- **Zweck:** Erzeugt ein Stabobjekt zwischen zwei Knotenindizes.
- **Möglichkeiten:** Initialisiert $EA$, $EI$, Bogenradius, Lastausdrücke, Endlasten, Gelenke, Schnittgrößen und lokale Freiheitsgrade. Der aktuelle Standardwert für $EA$ beträgt $10^{10}$ und bildet für Vergleichsrechnungen ein nahezu axial starres Stabmodell ab.
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

### `exportBiegelinienNeuToTI(stab_index)`

- **Zweck:** Erzeugt einen separaten symbolischen Biegelinienexport mit Randgleichungssystem je geradem Stab.
- **Möglichkeiten:** Ist im aktiven Modul verfügbar und über das Exportmenü aufrufbar. Für mehrere gerade Stäbe übernimmt der Export die geprüfte globale FEM-/Hermite-Rekonstruktion und stellt sie unter `vne1`, `vne2` usw. bereit; dadurch werden Übergänge, Lager, Gelenke und Knotenfedern gemeinsam berücksichtigt. Für einen einzelnen geraden Stab bleibt der separate Rand-LGS-Pfad verfügbar.
- **Grenzen:** Bögen, Gelenk-Sonderfälle und nichtnumerische Staborientierungen benötigen weiterhin gesonderte Behandlung. Der Einzelstab-Rand-LGS-Pfad ist nicht als global gekoppelter Mehrstabsolver ausgelegt.

### `exportULinienNeuToTI(stab_index)`

- **Zweck:** Erzeugt den symbolischen Export der lokalen Längsverschiebungslinie als `uneu1`, `uneu2` usw.
- **Möglichkeiten:** Nutzt bei mehreren Stäben die global berechneten lokalen Endverschiebungen und interpoliert sie entlang des Stabs. Dadurch werden Rahmenverformungen durch Querlasten, Knotenfedern und globale Kopplung berücksichtigt.
- **Grenzen:** Bögen und Sonderfälle außerhalb gerader Stäbe benötigen weiterhin gesonderte Behandlung; exportiert wird die lokale Stabverschiebung, nicht die globale X-/Y-Komponente.

## 3. Geometrie, Anzeige und Mausposition

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

### `drawArrow(gc, x1, y1, x2, y2)`

- **Zweck:** Zeichnet einen Linienpfeil mit Pfeilspitze.
- **Möglichkeiten:** Gemeinsame Darstellung für Lasten, Reaktionen, PvV-Beiträge und kinematische Bewegungen.
- **Grenzen:** Pfeillänge und Spitzengeometrie sind grafische Bildschirmwerte.

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
- **Möglichkeiten:** Berechnet `kgv_delta` und `kgv_delta0` durch wiederholte Berechnung des Grund- und Einheitszustands.
- **Grenzen:** Nur aktiv, wenn der automatische KGV-Solver überzählige Größen gefunden hat.

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

### Längslinienexport (`exportULinienToTI` / `exportULinienNeuToTI`)

- **Zweck:** Erzeugt die axiale Verformungslinie aus den axialen Endverschiebungen und der axialen Streckenlast.
- **Möglichkeiten:** Unterstützt konstante, linear veränderliche und CAS-auswertbare Lastfunktionen `n(x)`, auch im globalen Mehrstabexport. Der Lastanteil wird über `integral((x-t)*n(t),t,0,x)` doppelt integriert und in Kompatibilitäts- und Lagerbedingungen durch das jeweilige `EA` in eine Verschiebung umgerechnet; bei quadratischem `n(x)` entstehen dadurch die erwarteten Terme bis zur vierten Potenz. Der globale Ansatz verwendet Verschiebungskompatibilität, axiales Knotengleichgewicht `ΣN=0` und bei einer Knotenfeder `ΣN+c_parallel*u=0`.
- **Grenzen:** Konzentrierte axiale Einzelkräfte innerhalb eines Stabes benötigen eine stückweise Darstellung; die Ausgabe setzt einen verfügbaren CAS voraus. Die axiale Mehrstabkopplung setzt an Übergangsknoten eine gemeinsame Stabachse voraus.

### `findZeroForceMembers()`

- **Zweck:** Findet Nullstäbe in Fachwerken durch wiederholte lokale Gleichgewichtsregeln.
- **Möglichkeiten:** Erkennt unbelastete Ein-, Zwei- und Drei-Stab-Knoten sowie Fälle mit Kraft- oder Rollenlagerrichtung.
- **Grenzen:** Funktioniert auf Basis idealisierter Fachwerkbedingungen; Rahmenwirkungen und nichtstandardisierte Lastfälle können die Interpretation einschränken.

## 6. Systemberechnung

### `starteBerechnung()`

- **Zweck:** Zentraler Startpunkt für eine vollständige Tragwerksanalyse.
- **Möglichkeiten:** Löscht alte CAS-Variablen, prüft symbolische Eingaben, bereitet KGV-Zustände vor, sichert das System, berechnet numerisch und symbolisch, stellt den numerischen Grundzustand wieder her und bereitet Beschriftungen vor.
- **Grenzen:** Bei kinematischen, singulären oder nicht auswertbaren Systemen können nur Warnungen beziehungsweise unvollständige Ergebnisse entstehen.

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
- **Möglichkeiten:** `clear` setzt das komplette Modell zurück, `backspace` entfernt das ausgewählte Objekt, `escape` beendet Menüs und Sondermodi oder stellt PvV-Bindungen wieder her.
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
