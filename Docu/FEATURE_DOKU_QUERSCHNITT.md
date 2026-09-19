# Feature-Dokumentation: Statik Programm

Diese Datei dokumentiert alle funktionalen Features des Programms, ihre Möglichkeiten (Zweck) und aktuellen technischen Grenzen. Sie ist bei jeder Änderung an den Lua-Skripten zusammen mit der Funktionsdokumentation zu aktualisieren.

## 0. Programmkonzept und Arbeitsablauf
**Zweck:**
- Das Programm modelliert ebene Querschnitte für Aufgaben der technischen Mechanik und Statik.
- Massivflächen, dünnwandige Mittellinien, Kräfte und Berechnungseinstellungen werden in einem gemeinsamen Modell verwaltet.
- Die Eingabe erfolgt grafisch über das Zeichenfenster; numerische Korrekturen sind anschließend über den Element-Editor möglich.

**Typischer Arbeitsablauf:**
1. Koordinatensystem, Raster, Einheiten und Standarddicke in den Optionen einstellen.
2. Massiv- oder dünnwandige Geometrie zeichnen.
3. Überlappungen und Loch- beziehungsweise Additionsentscheidungen bestätigen.
4. Bei Bedarf Elemente und Punkte über Hover + Enter numerisch nachbearbeiten.
5. Kräfte platzieren und ihre Komponenten im Element-Editor eingeben.
6. Ergebnisse, Normalspannung, Schubspannung, Torsion oder Kernfläche über das Berechnungsmenü öffnen.
7. Bei Bedarf das KOS zum Schwerpunkt verschieben und die Ergebnisse erneut kontrollieren.

**Grenzen:**
- Das Programm ist eine interaktive Querschnitts- und Balkentheorie-Anwendung, keine allgemeine Finite-Elemente- oder 3D-Spannungsanalyse.
- Die Ergebnisse hängen von der gewählten Idealisierung, der Geometrieauflösung und den eingegebenen Vorzeichen ab.

## 1. Massiv-Querschnitte (Menü: M)
**Möglichkeiten:**
- Erstellung verschiedener Grundformen per Mausklick: Rechteck (2 Klicks), Kreis (2), Dreieck (3), Polygon/Trapez (n), Kreisausschnitt/Kreisabschnitt (3) und dicke Linie (2).
- Massivformen können positiv oder als Loch modelliert werden.
- **Loch-Erkennung:** Wird ein Element vollständig innerhalb eines anderen gezeichnet, wird es automatisch als Loch erkannt und die Fläche für die Querschnittswerte abgezogen.
- **Überlappungen:** Bei partieller Überlappung erscheint ein Dialog zur interaktiven Wahl: Abziehen (als Loch), Addieren (als Positivform) oder Verwerfen.
- Bei numerischer Addition wird die überlappende Geometrie rasterbasiert erfasst; das Programm kennzeichnet solche Systeme als numerisch berechnet.
- Die lokalen Flächenwerte, Schwerpunkte und Trägheitsmomente jedes Elements können in der Einzelwertetabelle geprüft werden.

**Grenzen:**
- Komplexe boolesche Operationen (Verschmelzen mehrerer sich überschneidender Positiv-Flächen zu einer einzelnen logischen Rand-Kontur) existieren nicht – Flächen und Trägheitsmomente werden bei "numerischer Addition" lediglich aufsummiert.
- Die automatische Loch- und Überlappungserkennung arbeitet mit Stichproben und kann sehr schmale Überlappungsbereiche übersehen.
- Selbstüberschneidende Polygone und entartete Formen mit nahezu verschwindender Fläche sind nicht zuverlässig auswertbar.

## 2. Dünnwandige Profile (Menü: D)
**Möglichkeiten:**
- Zeichnen von dünnwandigen Segmenten: Linienzüge (n Klicks), Kreise (2) und Kreisbögen (3).
- Jedes Element erhält eine definierte Standarddicke $t$, die sich jederzeit global oder pro Element anpassen lässt.
- Ein Linienzug wird intern in einzelne Zwei-Punkt-Kanten zerlegt.
- Gemeinsame Punkte bleiben als topologisch verbundene Knoten erhalten; dadurch können Verzweigungen, T-Stöße und geschlossene Umläufe erkannt werden.
- Dünnwandige Elemente können gemeinsam mit Massivflächen in einem gemischten Querschnitt verwendet werden.

**Grenzen:**
- Für die Geometrieauswertung erfolgt keine echte Flächenverschneidung an Knotenpunkten; Flächen und Momente basieren auf der Mittellinien-Idealisierung.
- Schnittpunkte werden für die Schubfluss-Topologie atomar aufgeteilt, ändern aber nicht automatisch die ursprüngliche Geometrie zu einer exakten Randkontur.
- Die dünnwandige Näherung vernachlässigt bei geraden Linienelementen das lokale Eigenträgheitsmoment in Dickenrichtung.

## 3. Querschnittswerte & Ergebnisse
**Möglichkeiten:**
- Automatische Berechnung von: Fläche ($A$), Schwerpunkt ($y_s, z_s$), Flächenträgheitsmomenten ($I_y, I_z, I_{yz}$), Hauptträgheitsmomenten ($I_1, I_2$) und dem Hauptachsenwinkel $\alpha$.
- Visuelle Darstellung der Hauptachsen (rot gestrichelt) ausgehend vom Schwerpunkt.
- Anzeige der Trägheitswerte wahlweise bezogen auf den aktuellen Ursprung oder den Schwerpunkt.
- Torsionsflächenmomente ($I_T$) für offene dünnwandige Profile über die Näherung $\sum \frac{1}{3} b_i t_i^3$, mit einstellbarem Korrekturfaktor $\xi$.
- Berechnung für reine Massivquerschnitte, reine dünnwandige Profile und gemischte Querschnitte durch additive Beiträge.
- Ausgabe von Trägheitsradien und Widerstandsmomenten für die Hauptachsen beziehungsweise die resultierenden Querschnittsachsen.
- Anzeige der lokalen Hauptachsen und lokalen Trägheitswerte eines ausgewählten Elements.
- Automatische Aktualisierung der Systemwerte nach dem Zeichnen, Bearbeiten, Verschieben oder Löschen von Elementen.

**Einheiten und Vorzeichen:**
- Intern rechnet das Programm mit N, mm und Nmm; die Anzeige kann zwischen N/kN, mm/cm/dm/m sowie Nmm/Ncm/Nm/kNmm/kNcm/kNm umgeschaltet werden.
- Bei der σx-Eingabe wird die tatsächlich eingestellte Momenteneinheit im Eingabehinweis angezeigt. Der Eingabewert wird genau einmal in Nmm umgerechnet; die anschließende Spannungsberechnung verwendet diesen internen Nmm-Wert ohne weitere Skalierung.
- Bereits bestätigte Eingaben bleiben im Dialog in der eingestellten Einheit sichtbar; interne Nmm-Werte werden nur für die Berechnung verwendet.
- Flächen-, Volumen- und Trägheitseinheiten werden aus der gewählten Längeneinheit abgeleitet.
- Das Deviationsmoment $I_{yz}$ und die Hauptachsenrichtung sind vorzeichenabhängig; die Interpretation muss zusammen mit der aktuellen KOS-Orientierung erfolgen.
- Zahlen können als Dezimalzahl, Bruch oder Wurzel-Bruch angezeigt werden. Das Anzeigeformat ändert nicht die interne Berechnung.

**Grenzen:**
- Gemischte Querschnitte (Massiv + Dünnwandig gleichzeitig) werden rein additiv behandelt; spezielle schubweiche Interaktionen zwischen massiven und dünnwandigen Teilen werden nicht berücksichtigt.
- Bei nahezu verschwindender Gesamtfläche werden keine sinnvollen Systemwerte erzeugt.
- Die Torsionskonstante eines offenen Profils ist eine dünnwandige Näherung und keine allgemeine Saint-Venant-Lösung für beliebig dicke oder komplexe Querschnitte.

## 4. Kräfte platzieren
**Möglichkeiten:**
- Einzelkräfte lassen sich mit einem Klick visuell auf dem Querschnitt platzieren.
- Bearbeitung per Element-Editor (Hover + Enter) zur Eingabe von Kräften in der Ebene (z.B. $F_y, F_z$) und aus der Ebene (z.B. $F_x$).
- Grafische Unterscheidung: Kräfte in der Ebene werden als Pfeile gezeichnet (Spitze zeigt auf den Angriffspunkt), Kräfte aus der Ebene als Kreis mit Punkt (heraus) oder Kreuz (hinein). Zusätzlich wird der Kraftangriffspunkt als sichtbarer Punkt markiert.
- Die drei Kraftkomponenten werden abhängig von der aktuellen KOS-Ebene als zwei Komponenten in der Querschnittsebene und eine Komponente senkrecht zur Ebene angezeigt.
- Aus den platzierten Kräften können Resultierende für Normalspannung, Querkräfte für Schubspannung und ein Torsionsmoment um den Schubmittelpunkt gebildet werden (ist der Schubmittelpunkt statisch unbestimmt, wird die Torsion aus Kräften nicht berechnet).

**Grenzen:**
- Für die Normalspannung wird die Kraftkomponente senkrecht zur Querschnittsebene als Normalkraft verwendet; ihre Exzentrizität liefert die Biegemomente.
- Für Schub und Torsion werden die Komponenten in der Querschnittsebene verwendet.
- Eine Kraft senkrecht zur Ebene erzeugt im aktuellen Modell keine zusätzliche Torsion aus einer Exzentrizitätskopplung.
- Die Orientierung der Kraftkomponenten und die Vorzeichen der Momente folgen dem aktuell gewählten Koordinatensystem.

## 5. Normalspannungsberechnung ($\sigma_x$)
**Möglichkeiten:**
- Berechnung der Normalspannung bei gegebener Längskraft ($N$) und Biegemomenten ($M_y, M_z$) nach der Formel für schiefe Biegung.
- Grafische Visualisierung der Spannungsverteilung als farbige Verlaufsschicht (Isolinien) direkt über dem Querschnitt.
- Darstellung der Nullspannungsgerade.
- Ausgabe einer Ergebnistabelle mit Minimal- und Maximalspannungen.
- Manuelle Eingabe von $N$, $M_y$ und optional $M_z$ über eine mehrstufige Eingabemaske.
- Direkte Berechnung ausschließlich aus den platzierten Kräften über die Option "σx aus Kräften".
- Berücksichtigung des Deviationsmoments $I_{yz}$ bei schiefer Biegung.
- Anzeige der verwendeten manuellen und aus Kräften resultierenden Schnittgrößen getrennt in der Ergebnistabelle.

**Grenzen:**
- Berechnungen basieren auf den integralen Querschnittswerten der Gesamtform, spezielle lokale Effekte (z.B. Spannungssingularitäten an scharfen Innenecken) werden nach der elementaren Balkentheorie vernachlässigt.
- Die Extremwertsuche prüft relevante Randpunkte; für stark konkave Geometrien können innere lokale Extremwerte außerhalb dieser Punktmenge liegen.
- Es gibt keine Materialgesetze, Plastizitätsgrenzen, Stabilitätsnachweise oder zeitabhängigen Lastfälle.

## 6. Schubspannungsberechnung ($\tau$) & Schubmittelpunkt
**Möglichkeiten:**
- Berechnung der Schubspannungen aus Querkräften ($V_y, V_z$ bzw. $Q_a, Q_b$) und Torsion ($M_T$).
- Topologie-aware Integration für dünnwandige Profile mit Verzweigungen, Schnittpunkten, offenen Enden und geschlossenen Profilzellen.
- Pfeile markieren die Integrationsrichtung entlang der dünnwandigen Elemente.
- Die Beschriftung "Start" erscheint nur am tatsächlichen Integrationsbeginn: bei offenen Profilen am freien Rand und bei geschlossenen Profilen am Symmetrieachsen-Start; bei Mischprofilen werden beide Arten angezeigt.
- Interaktive Wahl des Betrachtungsmodus ("V" drücken), um statische Momente ($S_y, S_z$), einzelne Schubspannungsanteile oder die resultierende Gesamtschubspannung ($\tau_{gesamt}$) zu visualisieren.
- Numerische Ausgabe der maximalen Schubspannung und deren Lage (z.B. $\tau_{max}$, $\tau_{gesamt,max}$).
- Automatische Berechnung und Anzeige des Schubmittelpunkts für offene, symmetrisch geschlossene und gemischte dünnwandige Profile.
- Die Schubspannungsansicht kann über zehn Darstellungen geprüft werden: zwei Momentendichten, zwei statische Momente, zwei Querlastanteile, Torsionsanteil, resultierende Schubspannung und Laufkoordinate $s$.
- Für Kontrollen stehen die integrierten Teilkräfte und Momentbeiträge je Element in einer Schubmomenttabelle bereit.
- Bei einer Last aus platzierten Kräften können die beiden Querkraftkomponenten automatisch aus den Kraftresultierenden übernommen werden.
- Berechnet wird nur, was nach TM2 statisch bestimmt ist: offene Profile (auch unsymmetrisch, mit $I_{yz}$-Kopplung $\tau = -\frac{Q_z (I_y S_y + I_{yz} S_z)}{(I_y I_z - I_{yz}^2)\,t}$, für $Q_y$ analog) und Profile mit genau einer geschlossenen Zelle (auch mit offenen Ästen, z. B. Kasten mit überstehendem Gurt), sofern die Querkraft parallel zu einer Symmetrieachse wirkt. Dann ist der Schubfluss antisymmetrisch und $q_0$ folgt aus der Symmetrie; freie Äste werden vorher integriert.
- Mehrzellige Profile, unsymmetrische geschlossene Zellen und eine Querkraft quer zur einzigen Symmetrieachse sind statisch unbestimmt: Die Rechnung bricht mit einer Meldung ab. Der Schubmittelpunkt wird nur so weit angegeben, wie er bestimmt ist (z. B. nur die Lage auf der Symmetrieachse).
- Massive Querschnitte: $\tau = Q S/(I b)$ über waagerechte bzw. senkrechte Schnitte (auch für Sektor, Kreisabschnitt und dicke Linie), nur wenn $I_{yz} = 0$ ist. Gemischte massiv/dünnwandige Querschnitte werden nicht berechnet.
- Eingegebene Querkräfte und Momente beziehen sich auf das angezeigte KOS und werden intern gedreht (auch bei KOS-Drehung 90°/270°).
- Die Schubmomententabelle verwendet die aktuell aktive Querschnitts-KOS und zeigt hinter jeder Lastspalte den zugehörigen effektiven Hebelarm $r=M/F$.
- Die Lastspalten zeigen die signierten Teilschubkräfte; kleine Werte unter $0{,}01$ werden exponentiell formatiert. Der Hebelarm bleibt signiert, damit $M=F\,r$ nachvollziehbar bleibt.
- Die Schubspannungsanteile werden aus dem statischen Moment mit der Vorzeichenkonvention $q=-Q S/I$ beziehungsweise $\tau=-Q S/(I t)$ berechnet.

**Grenzen:**
- Die exakte Visualisierung und Verteilung des Schubflusses ist primär auf dünnwandige Profile zugeschnitten. Bei rein massiven Vollquerschnitten basiert die Berechnung auf einer schichtweisen Integration, die bei komplexen Geometrien (z.B. sternförmig) an die Grenzen der 1D-Balkentheorie stößt.
- Statisch unbestimmte Fälle (siehe oben) werden bewusst nicht berechnet; es gibt keine Verträglichkeits- oder Mehrzellenrechnung.
- Die Integrationsauflösung ist an das Zeichenraster gekoppelt und kann bei sehr kleinen oder sehr großen Geometrien die Genauigkeit beeinflussen.
- Die Angaben zur Schubspannung werden in MPa dargestellt, sofern die internen Einheiten N und mm verwendet werden.

## 7. Kernfläche
**Möglichkeiten:**
- Berechnung der Kernfläche des Querschnitts zur Sicherstellung einer überdrückten/überzogenen Fuge.
- Anzeige sowohl der umhüllenden Geraden als auch der zugehörigen Kernpunkte.
- Umschalten zwischen der Darstellung der umhüllenden Geraden und dem Kernflächenpolygon über den Kernflächenmodus.
- Anzeige von Schnittpunkten der Begrenzungsgeraden und Kennzeichnung paralleler beziehungsweise ins Unendliche laufender Geraden.
- Die Kernfläche kann als Kontrolle für die Lage einer Druckresultierenden relativ zum Schwerpunkt genutzt werden.

**Grenzen:**
- Die Aussagekraft hängt von der zugrunde liegenden Querschnittsmodellierung und den berücksichtigten Randkonturen ab.
- Die Konstruktion basiert auf der konvexen Hülle der gesammelten Rand- und Stützpunkte.
- Bei stark konkaven Querschnitten, Löchern oder grob abgetasteten Bögen kann die dargestellte Kernfläche eine Näherung sein.

## 8. Interaktives Koordinatensystem (KOS)
**Möglichkeiten:**
- Das Raster (Fangradius für Klicks) ist numerisch frei definierbar.
- Das KOS kann durchgeschaltet werden (Projektionen xy, yz, xz) und in 90°-Schritten rotiert werden.
- Alle Achsenbeschriftungen (z.B. in Tabellen, Menüs oder Kraft-Labels) passen sich dynamisch der aktuellen KOS-Wahl an.
- Die visuelle Größe des KOS-Kreuzes auf dem Bildschirm ist einstellbar.
- Das KOS kann zum Schwerpunkt verschoben werden; alle gemeinsamen Geometrie- und Kraftpunkte werden dabei nur einmal verschoben.
- Die Drehung betrifft die Anzeigeorientierung in 90°-Schritten und wird bei Koordinaten, Beschriftungen, Kraftkomponenten und Momenten konsistent berücksichtigt.
- Das Raster dient sowohl zum Fangen von Eingabepunkten als auch als Einflussgröße für bestimmte numerische Integrationen.

**Grenzen:**
- Die KOS-Drehung ist auf vier Orientierungen (0°, 90°, 180°, 270°) beschränkt.
- Eine Verschiebung des KOS ist keine Rotation und verändert nicht die physikalische Geometrie; durch die Neuberechnung ändern sich jedoch die ursprungsbezogenen Darstellungwerte.
- Die Anzeigeeinheiten und das Zahlenformat beeinflussen nur Darstellung und Eingabeumrechnung, nicht die internen Basiseinheiten.
- Die Verlaeufe `z*h(z)`, `y*h(y)` sowie `S_y/S_z` verwenden fuer ihre Vorzeichen dieselbe Orientierung wie das gezeichnete Koordinatensystem; die numerischen Werte an den Verlaufenden werden ohne das zusaetzliche Praefix `Rand` angezeigt.

## 9. Element-Editor (Hover + Enter)
**Möglichkeiten:**
- Fährt der Mauszeiger über ein Element (Massiv, Dünnwandig, Kraft) und wird "Enter" gedrückt, öffnet sich ein kontextsensitives Bearbeitungsmenü.
- Manuelle und exakte numerische Nachkorrektur aller Stützpunktkoordinaten (P1, P2, ...).
- Umschalten der Eigenschaft "Positiv" vs. "Loch".
- Vertauschen von Start- und Endpunkten bei Bögen, um die Krümmungsrichtung umzukehren.
- Element Löschen (Rückgängig-Funktion).
- Bei dünnwandigen Elementen kann die Dicke $t$ individuell geändert werden.
- Bei Kräften können Angriffspunkt und alle drei Komponenten numerisch bearbeitet werden.
- Bei Bögen kann die Reihenfolge von Start- und Endpunkt getauscht werden, um die Umlaufrichtung zu ändern.

**Grenzen:**
- Der Editor bearbeitet einzelne gespeicherte Elemente; eine automatische Neuvernetzung oder geometrische Verschmelzung wird nicht durchgeführt.
- Nachträgliche Änderungen können die Einordnung als Loch, die Topologie oder die Symmetrie des Gesamtmodells beeinflussen und lösen deshalb eine Neuberechnung aus.

## 10. Berechnungs- und Anzeigeauswahl
**Möglichkeiten:**
- Aufruf der Berechnungsansicht über das Menü beziehungsweise den Tastaturkurzbefehl `b`.
- Umschaltung zwischen Ergebnis-, Spannungs- und Schubflussdarstellungen ohne Änderung der Geometrie.
- Interaktive Bearbeitung der Eingangsgrößen für Normalspannung, Schubspannung und Torsion.
- Die Ergebnisse können als Tabellenansicht, Normalspannungsverteilung, Schubspannungsverlauf oder Torsionsdarstellung betrachtet werden.
- Tabellen und Ergebnisbereiche unterstützen Scrollen, wenn die verfügbaren Zeilen oder Elemente die Bildschirmhöhe überschreiten.
- Die zentrale Ergebnisanzeige enthält unter anderem Fläche, Schwerpunkt, Trägheitswerte, Hauptträgheitswerte, Widerstandsmomente, Torsionswerte und verfügbare Schubspannungsresultate.

**Tastatur- und Bedienkürzel:**
- `m`: Massiv-Element zeichnen.
- `d`: Dünnwandiges Element zeichnen.
- `b`: Berechnungsmenü öffnen.
- `e`: Ergebnistabelle öffnen.
- `t`: Einzelwertetabelle öffnen.
- `v`: Schubverlaufs-Auswahl öffnen; Ziffern `0` bis `9` wählen die Darstellung.
- `k`: Kernflächenmodus weiterschalten.
- `o`: Optionen öffnen.
- `h`: Geometrie automatisch einpassen.
- `+`/`-`: Zoom ändern.
- `Esc`: Aktuelle Eingabe oder Ansicht abbrechen.
- `Backspace` beziehungsweise `Delete`: Letztes Element löschen.

**Grenzen:**
- Die Berechnung verwendet die im Programm hinterlegte Mittellinien- und Balkentheorie-Idealisierung; reale 3D-Effekte und lokale Spannungsspitzen werden nicht abgebildet.
- Das Modell besitzt keine persistenten Lastkombinationen, Materialdatenbank, Projektdatei-Verwaltung oder automatische Berichtserzeugung.

## 11. Bekannte fachliche und technische Grenzen
**Geometrie:**
- Mehrzellige und unsymmetrische geschlossene dünnwandige Profile sind statisch unbestimmt und werden für Schub und Torsion abgelehnt.
- Torsion wird nur für rein dünnwandige Profile berechnet: offen $I_T = \sum \frac{\xi}{3} h t^3$, $\tau_{max} = M_T t_{max}/I_T$; einzellig geschlossen (Bredt) $I_T = 4A_m^2/\oint ds/t$, $\tau_{max} = M_T/(2A_m t_{min})$. Massive Querschnitte (Prandtl) werden nicht berechnet.
- Kreis- und Bogenelemente werden für bestimmte Prüfungen und die Kernfläche durch Stützpunkte angenähert.

**Berechnung:**
- Die verwendeten Formeln sind Querschnitts- und Balkentheorie-Näherungen. Lokale 3D-Effekte, Spannungssingularitäten und Verformungskompatibilität realer Bauteile sind nicht enthalten.
- Numerische Überlappungs- und Rasterverfahren sind auf die gewählte Geometrieauflösung angewiesen.
- Die Ergebnisse sollten bei kritischen Aufgaben mit einer unabhängigen Rechnung oder einem geeigneten Statikprogramm kontrolliert werden.

**Bedienung und Laufzeit:**
- Sehr lange Menüzeilen und große Tabellen können auf dem begrenzten TI-Nspire-Bildschirm nur durch Scrollen vollständig gelesen werden.
- Die TI-Nspire-Lua-Laufzeit besitzt eine Begrenzung für lokale Upvalues pro Funktion; größere Erweiterungen müssen diese technische Grenze berücksichtigen.
- Eine Prüfung auf realer TI-Nspire-Hardware ist zusätzlich zur Syntaxprüfung empfehlenswert.

