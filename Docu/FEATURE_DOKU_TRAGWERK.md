# Feature-Dokumentation: Tragwerks- und Statikmodul

Diese Datei beschreibt die aktuell sichtbaren und fachlich wichtigen Funktionen des Tragwerksmoduls. Das Modul besteht aus `AktuellerStand.lua` für Datenmodell, Berechnung und Interaktion sowie `Zeichnen.lua` für die grafische Darstellung.

## 0. Programmkonzept

Das Programm dient zur ebenen Berechnung und Darstellung von Stabtragwerken. Knoten und Stäbe werden grafisch eingegeben, an Knoten und Stäben können Lager, Gelenke und Lasten definiert werden. Die Berechnung basiert auf der Methode der finiten Elemente beziehungsweise auf einem aus Stabfreiheitsgraden aufgebauten globalen Gleichungssystem.

Das Modell unterstützt sowohl allgemeine Rahmen- und Balkensysteme als auch ebene Fachwerke. Zusätzlich gibt es Werkzeuge zur kinematischen Untersuchung, zum Polplan, zur virtuellen Verschiebung und zum Export von Rechenmatrizen und Ergebnisfunktionen an das TI-Nspire-CAS.

## 1. Typischer Arbeitsablauf

1. Im Zeichenfenster Knoten durch Klicks auf dem Raster anlegen.
2. Zwei Knoten nacheinander auswählen, um einen Stab zwischen ihnen zu erzeugen.
3. Knotenlager, Gelenke, Knotenlasten und Federn über Hover + Enter definieren.
4. Stabparameter, Streckenlasten, Endlasten, Momentenlasten, Bogenradius und Gelenke bearbeiten.
5. Bei Bedarf globale Einstellungen wie Raster, Standardwerte für $EA$ und $EI$, Fachwerkmodus oder automatische KGV-Ermittlung ändern.
6. Mit `b` das System berechnen.
7. Die Darstellung mit den Ansichtsmodi für $N$, $Q$, $M$, $U$, $W$, System, Explosion, Polplan oder Verschiebungszustand kontrollieren.
8. Ergebnisse und Funktionen bei Bedarf über das Einstellungsmenü an das TI-Nspire-CAS exportieren.

Das Programm zeigt einen roten Berechnungsstatus, wenn Stäbe vorhanden sind, aber das System nach einer Änderung noch nicht neu berechnet wurde.

## 1.1 Lokaler TI-Nspire-CAS-Test

Der Test-Runner und die Regressionstests (`Emulator/test_regression.lua`) reichen die im Lua-Modul verwendeten `math.eval`-Aufrufe über `Emulator/cas_bridge.lua` an einen SymPy-Server (`python_cas_server.py`, `python_cas.py`) weiter. Dadurch lassen sich numerische Ausdrücke, gespeicherte Funktionen, exakte Ausdrücke und bestimmte Integrale ohne angeschlossenen TI-Nspire prüfen.

Numerische CAS-Textrückgaben werden vor der Lua-Konvertierung normalisiert; dadurch bleiben Dezimalkommas gültig, ohne zusätzliche Rückgabewerte von String-Ersetzungen als Zahlenbasis zu interpretieren.

Die symbolische Biegelinienrekonstruktion verwendet die Last- und Randwertkonvention des Rechenmodells. Die exportierten Polynome werden aus Lastintegral und berechneten Hermite-Randwerten zusammengesetzt und nicht auf eine externe Musterlösung angepasst. Der Anfangswert der lokalen Biegelinie wird dabei mit $c_1=v_a EI$ und nicht mit umgekehrtem Vorzeichen eingesetzt.

**Grenzen:**

- Der Emulator deckt nur den von `Biegelinieneu.lua` verwendeten `math.eval`-Teilumfang ab.
- TI-Nspire-spezifische Formatierungen können von der SymPy-Textdarstellung abweichen.

## 2. Geometrie und Modellierung

### 2.1 Knoten

Knoten besitzen:

- kartesische Koordinaten $x$ und $y$ in Metern,
- ein optionales ideales Gelenk,
- Lagerbedingungen in globaler X-Richtung, globaler Y-Richtung und für die Rotation,
- Knotenkräfte $F_x$, $F_y$ und ein Knotenmoment,
- Federsteifigkeiten $c_x$, $c_y$ und $c_m$,
- einen Lagerwinkel und einen Winkel für die Kraftrichtung,
- berechnete Auflagerreaktionen und Verschiebungen.

Koordinaten werden beim Anklicken auf das eingestellte Raster gerundet. Bereits vorhandene Knoten werden wiederverwendet, wenn der neue Klick dieselben Rasterkoordinaten trifft.

### 2.2 Stäbe

Ein Stab verbindet zwei Knoten und besitzt unter anderem:

- $EA$ für die axiale Steifigkeit,
- $EI$ für die Biegesteifigkeit,
- einen optionalen Bogenradius,
- konstante oder veränderliche Streckenlasten $q(x)$ und $n(x)$,
- eine konstante oder veränderliche Momentenlast $m(x)$,
- globale Linienlasten $g_x(x)$ und $g_y(x)$,
- optionale Projektion globaler Linienlasten auf die Stabrichtung beziehungsweise Querrichtung,
- Endgelenke für Moment, Normalkraft oder Querkraft,
- Endgrößen für Schnittkräfte und Verformungen.

Für Vergleichsrechnungen mit der Musterlösung wird standardmäßig $EA=10^{10}$ verwendet. Dieser Wert ist eine numerische Näherung für axial unnachgiebige Stäbe; ein tatsächlich endlicher $EA$ verändert bei Rahmen die Knotenverschiebungen und damit auch die Biegelinien.

Ein Stab kann durch `F` umgedreht werden. Dabei werden Anfang und Ende vertauscht und die zugehörigen Anfangs- und Endlasten mitgetauscht.

### 2.3 Geradstäbe und Bögen

Gerade Stäbe werden mit der üblichen lokalen Stabachse ausgewertet. Ein Stab mit gültigem Radius wird als Kreisbogenelement behandelt oder für die grafische Darstellung durch Segmente angenähert.

**Grenzen:**

- Bögen werden in Teilen der Darstellung und Auswertung segmentiert; die Segmentzahl ist einstellbar.
- Sehr kurze, geometrisch entartete oder ungültige Bogenkonfigurationen sind nicht zuverlässig auswertbar.
- Die Darstellung von Bogen-Schnittgrößen und Bogenverformungen ist gegenüber geraden Stäben stärker von der gewählten Abtastung abhängig.

## 3. Lager, Gelenke und Federn

### 3.1 Knotenlager

An jedem Knoten können unabhängig aktiviert werden:

- Lager X für eine horizontale beziehungsweise gedrehte X-Richtung,
- Lager Y für die zweite Lagerkomponente,
- Lager M für die Rotation.

Der Lagerwinkel erlaubt schräg orientierte Lagerbedingungen. Reaktionskräfte und Reaktionsmomente werden nach der Berechnung grafisch und numerisch angezeigt.

### 3.2 Stabgelenke

Stabgelenke können an Anfang und Ende getrennt definiert werden:

- M-Gelenk trennt die Momentenübertragung,
- N-Gelenk trennt die axiale Übertragung,
- Q-Gelenk trennt die Querübertragung.

Diese Gelenke beeinflussen sowohl das Gleichungssystem als auch die topologische Freiheitsgrad- und Kinematikprüfung. Aktive Federn in den drei Knotenfreiheitsgraden werden bei der topologischen Systemzahl zusätzlich als elastische Bindungen berücksichtigt; ein Freiheitsgrad mit idealem Lager wird dabei nicht doppelt gezählt.

Der Export der Längslinie berücksichtigt den axialen Streckenlastanteil über eine doppelte Integration. Für eine Lastfunktion `n(x)` wird der Verformungsanteil proportional zu `integral((x-t)*n(t),t,0,x)` gebildet; der globale Mehrstabexport verwendet dafür das globale axiale Rand-LGS und verwirft die Lastpolynomterme nicht mehr. Axiale Knotenfedern werden im Rand-LGS mit `ΣN+c_parallel*u=0` berücksichtigt.

### 3.3 Federn

Knotenfedern können für die drei Freiheitsgradtypen eingegeben werden:

- translatorische Feder $c_x$,
- translatorische Feder $c_y$,
- rotatorische Feder $c_m$.

Die Federwerte werden in das globale Gleichungssystem integriert. Ein Federwinkel kann für eine gedrehte Federorientierung hinterlegt werden.

### 3.4 Verformungslinien über das Rand-LGS (`vne`, `uneu`, `randbed`)

Neben den Referenzexporten (`v_EI_stab_i`, `u_EA_stab_i` aus der FEM-Lösung) gibt es im Obermenü `O`, Seite 2, die Einträge `Neue Biegelinie (Rand-LGS)` und `Neue Längslinie (Rand-LGS)`. Beide rufen dieselbe Funktion (`neuRandLGS`): Für alle Stäbe wird der Ansatz `EI·w_i(x) = wp_i(x) + c1·x³/6 + c2·x²/2 + c3·x + c4` und `EA·u_i(x) = up_i(x) + C1·x + C2` gewählt; die 6 Konstanten je Stab folgen aus den Rand- und Übergangsbedingungen des ganzen Systems (Lager, auch gedrehte; Gelenke M/N/Q; Federn `cx`, `cy`, `cm`; Knotenlasten und -momente; Verträglichkeit der Stabenden an jedem Knoten). Das Gleichungssystem wird im CAS mit `simult` gelöst.

Exportiert werden je Stab `vne_i(x) = EI·w_i(x)` und `uneu_i(x) = EA·u_i(x)` (lokale Koordinate `x_i` von 0 bis `L_i`, Zählrichtung vom ersten zum zweiten Knoten, `w` positiv in lokaler Querrichtung wie in den Diagrammen) sowie den Spaltenvektor `randbed` (`["…";"…"]`) mit allen verwendeten Bedingungen als lesbare Strings. Schnittgrößen werden dabei über die Ableitungen der Verformungen geschrieben: `-EIw'''` statt Q, `-EIw''` statt M, `EAu'` statt N, `-w'` statt φ (mit Temperatur `-EI(w''+κT)` bzw. `EA(u'-εT)`). Beispiele: `"w1(x1=0)=0"`, `"w1'(x1=0)=0"`, `"w1(x1=l)=w2(x2=0)"`, `"EIw2''(x2=0)=0"`, `"EIw1'''(x1=l)-EIw2'''(x2=0)+F=0"`, `"-EIw1''(x1=0)+cm*w1'(x1=0)=0"`. Die Funktionen sind exakt (keine Rundung); `approx(vne1(x))` liefert Dezimalzahlen. Im symbolischen Modus erscheinen die Stablängen als Vielfache der Referenzlänge (`x1=l`, `x2=(2*l)`), Lasten und Steifigkeiten als Symbole.

**Dehnstarr (Standard an):** Obermenü `O`, Seite 4, `Rand-LGS dehnstarr`. Stäbe mit Zahlen-EA (auch der Standard `EA = 1e10`) werden als dehnstarr gerechnet, wie in der Handrechnung üblich: Im LGS steht `EA = EA_Zahl/rleps`, danach wird jede Konstante mit `limit(…, rleps, 0)` bestimmt. So verschwinden die EI/EA-Anteile (früher z. B. `ei*h*l/10000000000`), und Fälle, in denen sich N nach den Dehnsteifigkeiten verteilt (Horizontallast zwischen zwei Festlagern), bleiben lösbar. `uneu_i(x)` ist weiter `EA·u_i(x)`, solange das endlich bleibt (Stab axial gehalten, keine Temperaturdehnung); verschiebt sich ein dehnstarrer Stab als Ganzes (z. B. der Riegel eines verschieblichen Rahmens) oder dehnt er sich durch Temperatur, wird stattdessen `uneu_i(x) = u_i(x)` exportiert. Welche Stäbe dehnstarr sind und welche `uneu_i` Verschiebungen sind, steht im Spaltenvektor `randinfo`. Symbolisches EA (`EA_str = "EA"`) bleibt immer dehnbar. Eine behinderte Temperaturdehnung (unendliche Zwangskraft) führt zum Abbruch mit Meldung; dann dehnstarr ausschalten.

Symbolische Eingaben werden in den grafischen Menüs wieder als eingegebener Ausdruck angezeigt. Das betrifft insbesondere Knotenfedern wie `EI/l^3` sowie die global gesetzten Stabwerte `EI` und `EA`.

**Grenzen:** Keine Bögen und keine KGV-Einheitszustände (Zustand 0 wählen). Mechanismen und Lasten in frei beweglichen Richtungen werden abgebrochen; die Meldung steht dann in `randbed` (`["Fehler: …"]`), alte `vne`/`uneu` werden vorher gelöscht. Eingaben mit Dezimalkomma (`1,5`) und e-Notation (`1e8`) werden für das CAS umgeschrieben. Mit ausgeschaltetem dehnstarr entstehen bei numerisch großen Steifigkeiten (Standard `EI = 1e8`, `EA = 1e10`) exakte, aber lange Brüche aus dem EI/EA-Verhältnis. Die Rundungsfunktion `eval_cas_string(…, true)` ist dafür nicht geeignet (6 Stellen, absolute Schwelle 1e-6). Der Referenzexport `v_EI_stab_i` rundet Koeffizienten auf `casToleranz` Stellen (Standard 5), was bei großen `x` Abweichungen bis etwa `1e-5·x³` ergibt; das Rand-LGS rundet nicht.

## 4. Lasten

**Koordinaten und Vorzeichen:** Weltkoordinaten wie auf dem Bildschirm (`x` nach rechts, `y` nach unten). Lokale Stabrichtung vom ersten zum zweiten Knoten, lokale Querrichtung `n = (−dy, dx)/L`; `q`, `w` positiv in `n`, `φ = −w'`, `M' = Q − m`. Lagerwinkel `winkel` und Federwinkel `f_winkel` drehen die Achsen wie gezeichnet (Drehung um `−winkel`: Lagerachse `ξ = (cos w, −sin w)`, `η = (sin w, cos w)`; Federachse `cx = (cos f, −sin f)`). Knotenlasten `last_x`, `last_y` werden um `−last_w` gedreht; `last_m` und `cm` wirken im `φ`-Sinn. Ein konstantes Streckenmoment `m` geht als konsistente Stabendkräfte `Q_i = −m`, `Q_k = +m` in die FEM ein (wie der CAS-Pfad für `m(x)`), die Biegelinie enthält `+∫m(t)(x−t)²/2`.


### 4.1 Knotenlasten

Knotenlasten bestehen aus zwei Kraftkomponenten, einem Moment und einem Kraftrichtungswinkel. Sie werden im Modell gespeichert, in das globale Lastvektor-System übernommen und als Pfeile beziehungsweise Momentenpfeile gezeichnet.

### 4.2 Stablasten

Unterstützt werden:

- konstante oder funktionale Querlast $q(x)$,
- konstante oder funktionale Längslast $n(x)$,
- konstante oder funktionale Momentenlast $m(x)$,
- globale Linienlast $g_x(x)$,
- globale Linienlast $g_y(x)$,
- trapezförmige Anfangs- und Endwerte für $q$ und $n$,
- temperaturähnliche oder vorgegebene Dehnungs- und Krümmungsanteile über $T_{oben}$, $T_{unten}$, $\alpha_t$ und $h$.

Alle numerischen Eingabefelder akzeptieren mathematische Ausdrücke mit Dezimalkomma, Klammern, `+`, `-`, `*`, `/` und `^`; außerdem sind TI-Nspire-CAS-Funktionen wie `sqrt(...)` oder `sin(...)` möglich. Funktionale Eingaben können Variablen wie `x` enthalten. Wenn eine symbolische Eingabe erkannt wird, wechselt das Programm in den symbolischen Modus und versucht, die zugehörigen CAS-Ausdrücke zu erzeugen.

Symbolische Trapezlasten (`q_A = 0`, `q_B = q`), Streckenlasten, Streckenmomente, Eigengewicht und Knotenlasten werden per Superposition exakt als Vielfache der Referenzlänge ausgegeben. Referenzlänge ist das eine Längensymbol der Geometrie; enthält die Geometrie kein Symbol, gilt automatisch ein Rasterabstand als `l` und alle Stablängen werden als Vielfache von `l` ausgegeben (Raster 0,5 m: Stab 2 m = `4*l`). Fälle, die der symbolische Modus nicht korrekt abbilden kann, brechen die Berechnung mit einer roten Meldung ab: Temperaturlasten, Lastfunktionen mit `x` (z. B. `q/l*x`), Bögen, mehr als ein Längensymbol in der Geometrie und Koordinaten, die kein reines Vielfaches des Längensymbols sind (z. B. `a+2`), das Symbol `t` (Integrationsvariable) sowie `EI`/`EA` in Feder- oder Lasttexten, wenn nicht alle Stäbe diese Steifigkeit symbolisch haben (sonst würde mit zwei verschiedenen Zahlenwerten gerechnet).

### 4.3 Projektion globaler Linienlasten

Globale X- und Y-Linienlasten können optional auf die lokale Stabnormale beziehungsweise Stabachse projiziert werden. Dadurch können Lasten unabhängig von der Staborientierung eingegeben werden.

**Grenzen:**

- Symbolische Ausdrücke benötigen eine kompatible TI-Nspire-CAS-Auswertung.
- Ungültige oder nicht auswertbare Eingaben werden teilweise zu Null beziehungsweise zu einem Dummywert zurückgeführt; Eingaben sollten daher nach der Berechnung kontrolliert werden.
- Lastvorzeichen beziehen sich auf die im Programm verwendete lokale beziehungsweise globale Richtung und müssen bei umgedrehten Stäben geprüft werden.

## 5. Berechnung des Tragwerks

### 5.1 Globales Gleichungssystem

Die Berechnung assembliert aus den lokalen Stabmatrizen ein globales Steifigkeitssystem. Je nach Modell werden translatorische und rotatorische Freiheitsgrade der Knoten sowie zusätzliche Stabendfreiheitsgrade berücksichtigt.

Aus dem System werden berechnet:

- globale Verschiebungen,
- Knotenrotationen,
- Stabendgrößen,
- Auflagerreaktionen,
- lokale Schnittgrößen,
- Biegelinien und Längsverformungen.

Die Gleichungen werden für Rahmen-/Balkensysteme und im Fachwerkmodus unterschiedlich aufgebaut.

### 5.2 Fachwerkmodus

Im Fachwerkmodus werden Knoten standardmäßig gelenkig behandelt. Das Gleichungssystem verwendet Stabnormalkräfte und Lagerreaktionen. Die grafische Darstellung kann Nullstäbe hervorheben.

Der Modus ist für ebene Fachwerke gedacht, bei denen die Stäbe im Wesentlichen Normalkräfte übertragen. Biege- und Momentenwirkungen sind dort nicht als allgemeine Rahmenwirkung zu interpretieren.

### 5.3 Starrmodus und statische Unbestimmtheit

Der Starrmodus setzt hohe Standardwerte für $EA$ und $EI$ und dient zur Modellierung beziehungsweise Anzeige eines nahezu starren Systems. Das ist keine exakte unendlich steife Formulierung.

Das Programm warnt bei einem kinematischen System. Bei einem starren und gleichzeitig statisch unbestimmten System erscheint ebenfalls eine gesonderte Warnung.

### 5.4 Automatischer KGV-Solver

Der automatische KGV-Solver erkennt überzählige Bindungen beziehungsweise Freiheitsgrade und bildet Zustände für die überzähligen Größen. Ein Zustand $X_i=1$ kann über die Zifferntasten ausgewählt werden. Zusätzlich können KGV-Matrizen exportiert werden.

**Grenzen:**

- Die automatische Erkennung hängt von der gewählten Modellierung und den erkannten Bindungen ab.
- Bei ungünstig modellierten Gelenken, Federn oder Sonderfällen kann die automatische Auswahl der überzähligen Größen fachlich kontrolliert werden müssen.
- Der Starrmodus ersetzt keine exakte Starrkörper- oder Zwangsbedingungsanalyse.

## 6. Schnittgrößen und Verformungen

Die Ergebnisansichten zeigen entlang der Stäbe beziehungsweise Bogenabschnitte:

- `N`: Normalkraftverlauf,
- `Q`: Querkraftverlauf,
- `M`: Momentenverlauf,
- `U`: axiale beziehungsweise longitudinale Verschiebung,
- `W`: Biegelinie beziehungsweise transversale Verschiebung.

Abhängig von der Einstellung können Schnittgrößen am Anfang und Ende, am Hoverpunkt oder an Start- und Endposition angezeigt werden. Maximalwerte können ein- oder ausgeblendet werden.

Die Biegelinie wird aus Anfangsverschiebung, Anfangsverdrehung und partikulären Lastanteilen aufgebaut. Bei einem inneren Gelenk wird die lokale Biegelinie ohne zusätzliche starre Endkorrektur vom Gelenkende aus fortgesetzt; dadurch bleiben Verschiebungskontinuität und die getrennten Gelenkrotationen erhalten. Bei symbolischen Systemen wird die Endverschiebung `vb` mit der für die exportierte Randkorrektur erforderlichen Vorzeichenkonvention übernommen; insbesondere wird der vollständige Ausdruck aus Randwert und Lastintegral vor der Multiplikation mit der Hermite-Randfunktion geklammert und der symbolische Endwert nicht gegenüber `v_local[5]` gespiegelt. Für symbolische oder funktionale Lasten werden CAS-Stützwerte erzeugt und in die Darstellung einbezogen.

Symbolische Knotenfedersteifigkeiten `cx`, `cy` und `cm` werden beim Berechnungsstart über ihre gespeicherten Texte `cx_str`, `cy_str` und `cm_str` in Dummywerte für die numerische Zwischenrechnung überführt; der Originalausdruck bleibt für die symbolische Eingabe verfügbar.

**Grenzen:**

- Die grafischen Verläufe werden über eine einstellbare Punktzahl pro Stab abgetastet und sind daher keine beliebig fein aufgelöste Darstellung.
- Bei sehr großen Werten kann die gemeinsame Verlaufsskalierung die Detaildarstellung beeinflussen.
- Die Verschiebungsdarstellung ist zur Sichtbarkeit skaliert und nicht automatisch maßstäblich zur Geometrie.
- Die direkte Fortsetzung am inneren Gelenk setzt eine korrekt gelöste lokale Verschiebung und Verdrehung am Gelenkende voraus.

## 7. Explosion und Detailansichten

Mit `e` wird die Explosionsansicht geöffnet. Sie stellt Stabendgrößen und lokale Freiheitsgrade getrennt dar. Über `e` kann zwischen den Explosionsseiten gewechselt werden; `t` blendet die Detailbeschriftungen um.

In der Explosion werden unter anderem dargestellt:

- lokale Stabkräfte und Momente,
- Auflager- und Gelenkbeiträge,
- lokale Verschiebungen und Rotationen,
- Lastangriff und Reaktionsbeiträge,
- symbolische Bezeichnungen, wenn der symbolische Modus aktiv ist.

## 8. Kinematik, Polplan und Verschiebungszustände

### 8.1 Kinematische Prüfung

Mit `v` wird die kinematische Ansicht geöffnet. Das Programm prüft, ob das System stabil ist. Kinematische Systeme werden als solche markiert und können animiert dargestellt werden.

### 8.2 Polplan

Mit `p` wird der Polplan geöffnet. Er zeigt Starrkörperbereiche, Pole und Polstrahlen. In den Optionen kann zwischen notwendigen, keinen oder allen Polstrahlen gewählt werden.

Der Polplan unterstützt die qualitative Untersuchung von Bewegungszuständen und Scheibenrotationen. Rotierende Scheiben werden um ihre momentanen Pole visualisiert.

### 8.3 Prinzip der virtuellen Verschiebungen

Ist ein System starr, kann mit `Enter` der PvV-Modus gestartet werden. Danach kann ein Knoten oder Stab ausgewählt und eine Bindung temporär gelöst werden:

- Lager X, Lager Y oder Lagermoment am Knoten,
- Knoten-Gelenk bei geeigneten Knoten,
- M-, N- oder Q-Gelenk an einem Stabende.

Das System wird mit der gelösten Bindung als virtueller Bewegungszustand untersucht. Angezeigt werden Verschiebungen, Rotationen, Arbeitsanteile $W_i$ und bei Gelenklösungen Klaffungen beziehungsweise relative Bewegungen.

Die ursprünglichen Bindungen werden gesichert und beim Beenden wiederhergestellt.

**Grenzen:**

- Der PvV-Modus ist eine qualitative und rechnerisch unterstützte Untersuchung einzelner gelöster Bindungen.
- Nur zulässige Bindungen können gelöst werden; ungeeignete Kombinationen werden zurückgewiesen.
- Die animierte Darstellung ist skaliert und stellt keine maßstäbliche reale Zeit- oder Verformungsbewegung dar.

## 9. Nullstäbe im Fachwerk

Der Nullstab-Algorithmus sucht iterativ nach unbelasteten Knoten und typischen Gleichgewichtsbedingungen:

- ein einzelner unbelasteter Stab ohne relevante äußere Bindung,
- zwei nicht kollineare Stäbe an einem unbelasteten Knoten,
- drei Stäbe mit zwei kollinearen Stäben,
- Sonderfälle mit Kraft oder Rollenlager in Stabrichtung.

Erkannte Nullstäbe werden für die Darstellung markiert. Der Algorithmus wiederholt die Prüfung, weil das Entfernen eines Nullstabs weitere Erkennungen ermöglichen kann.

## 10. Export zum TI-Nspire-CAS

Über das Einstellungsmenü können folgende Daten exportiert werden:

- alle Systemdaten,
- Biegelinien,
- Längsverformungslinien,
- KGV-Daten,
- Arbeitssatzdaten,
- Schnittkraftfunktionen,
- globale LGS-Matrix,
- Verformungslinien aus dem Rand-LGS (`vne_i`, `uneu_i`, `randbed`).

Typische gespeicherte Variablen sind `sys_k`, `sys_f`, `sys_u`, `ggw_a`, `ggw_b`, `ggw_x`, `ggw_eqs` sowie stabspezifische Matrizen und Funktionen.

Für gerade Stäbe können analytische CAS-Funktionen für $N(x)$, $Q(x)$, $M(x)$, $v(x)$ und $u(x)$ erzeugt werden. Funktionale Lasten werden nach Möglichkeit als Integrale exportiert. Für Bögen existieren winkelabhängige Schnittkraftfunktionen.

**Grenzen:**

- Der Export setzt eine verfügbare `var.store`- beziehungsweise TI-Nspire-CAS-Umgebung voraus.
- Die Exportfunktionen sind für bereits berechnete Systeme gedacht.
- Nicht jede Sonderform, insbesondere jede Kombination aus Bogen, Symbolik und Gelenken, erzeugt für alle Größen dieselbe analytische Darstellung.

## 11. Anzeige, Einstellungen und Bedienung

### Tastaturkürzel

- `b`: Tragwerk berechnen.
- `m`: Momentenverlauf anzeigen.
- `n`: Normalkraftverlauf anzeigen.
- `q`: Querkraftverlauf anzeigen.
- `u`: Längsverformung anzeigen.
- `w`: Biegelinie anzeigen.
- `s`: Systemansicht öffnen.
- `e`: Explosionsansicht öffnen beziehungsweise Seite wechseln.
- `t`: Beschriftungen in der Explosionsansicht ein-/ausblenden.
- `v`: Kinematik beziehungsweise Verschiebungszustand öffnen oder schließen.
- `p`: Polplan öffnen.
- `l`: globales LGS anzeigen.
- `o`: Einstellungsmenü öffnen.
- `h`: System automatisch in den sichtbaren Bereich einpassen.
- `f`: Richtung eines unter dem Cursor befindlichen Stabs umkehren.
- `+`/`-`: Zoom ändern.
- `Esc`: Eingabe, Menü oder Sondermodus abbrechen.
- `Backspace`: Eingabe löschen oder das ausgewählte Element entfernen.

### Einstellungsgruppen

Die Einstellungen sind in mehrere Seiten aufgeteilt:

1. Raster und Standardwerte für $EA$ und $EI$, Starrmodus, Auto-KGV, Anzeige von $n$, Schnittgrößenmodus und Fachwerkmodus.
2. Exporte zum TI-Nspire-CAS.
3. CAS-Toleranz, Punkte pro Stab, Zoomschritte, Bogenauflösung, Bemaßung, Zahlenformat und Maximalwerte.
4. Polstrahlmodus und Verlaufsskalierung.

## 12. Bekannte Grenzen und fachliche Hinweise

- Das Programm ist eine ebene lineare Stabwerksberechnung und keine allgemeine nichtlineare oder dreidimensionale Tragwerksanalyse.
- Materialnichtlinearität, Plastizität, Stabilitätsversagen, Kontakt und große Verformungen werden nicht als allgemeine Modelle gelöst.
- Die verwendeten $EA$- und $EI$-Werte sind Eingabeparameter; eine automatische Material- oder Querschnittsdatenbank ist nicht vorhanden.
- Kinematische und statisch unbestimmte Systeme sollten anhand der Warnungen und der Systemzahl fachlich kontrolliert werden.
- Symbolische Rechnungen und Exporte hängen von der Leistungsfähigkeit und Syntax des TI-Nspire-CAS ab.
- Das Programm speichert die Geometrie und Einstellungen nicht als allgemeine Projektdatei.
- Sehr lange Menüs, LGS-Ausgaben und Tabellen benötigen Scrollen und können die begrenzte Bildschirmgröße überschreiten.
- Eine Prüfung auf realer TI-Nspire-Hardware und eine unabhängige Vergleichsrechnung bleiben für wichtige Ergebnisse empfehlenswert.
