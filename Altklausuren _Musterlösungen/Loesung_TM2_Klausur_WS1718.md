# Lösungsvorschlag — Klausur Technische Mechanik II, WS 17/18 (16.02.2018)
Prof. Dr.-Ing. T. Ricken · Universität Stuttgart · ISD

> Ausgearbeiteter Lösungsweg zu allen Aufgaben. Zwischenergebnisse sind angegeben,
> damit Teilschritte nachvollzogen und Punkte einzeln überprüft werden können.

---

## Aufgabe 1 — Theorieteil (21 Punkte)

### 1a) Kernfläche des dünnwandigen L-Querschnitts (2 P.)

**Vorgehen:**
1. Schwerpunkt S des Winkelprofils bestimmen, Hauptachsen $\eta,\zeta$ einzeichnen.
2. Für jede Ecke des umschriebenen Polygons (die vier "Eckpunkte" der Kontur) die
   zugehörige **neutrale Faser** als Tangente an die Querschnittskontur einzeichnen.
   Maßgebend sind nur die Tangenten, die den gesamten Querschnitt auf einer Seite lassen
   (umschreibendes Polygon → beim L-Profil ein Dreieck/Viereck aus den vier äußeren Tangenten).
3. Zu jeder neutralen Faser den zugehörigen Kernpunkt berechnen:

$$k_\zeta=-\frac{i_\eta^2}{\zeta_0},\qquad k_\eta=-\frac{i_\zeta^2}{\eta_0},\qquad
i_\eta^2=\frac{I_\eta}{A},\; i_\zeta^2=\frac{I_\zeta}{A}$$

wobei $\eta_0,\zeta_0$ die Achsabschnitte der neutralen Faser sind.

4. Da jede neutrale Faser (Gerade) auf **einen** Kernpunkt abgebildet wird und jede
   Konturecke auf **eine Kerngerade**, entsteht als Kernfläche ein **Polygon mit so vielen
   Ecken, wie das umschreibende Tangentenpolygon Seiten hat**.

**Ergebnis (qualitativ):** Die Kernfläche ist ein **geschlossenes, konvexes Viereck**,
das den Schwerpunkt enthält und **unsymmetrisch** zur langen Schenkelrichtung liegt —
schlank und in Richtung der schwachen Hauptachse stark eingeschnürt.
Wichtig für die Bewertung:

* Kernfläche ist immer **konvex** und enthält S.
* Eckpunkt der Kontur ↔ Gerade der Kernfläche (Dualität),
  gerade Konturseite ↔ Eckpunkt der Kernfläche.
* Alle vier Tangenten an die Außenkontur sind einzuzeichnen (die beiden Außenkanten
  der Schenkel und die beiden Tangenten an die Schenkelenden).

---

### 1b) Zugversuch — Schnitt mit maximaler Schubspannung (2 P.)

Einachsiger Zug: $\sigma_x=\sigma$, $\sigma_y=\tau_{xy}=0$.

$$\tau_\alpha=-\frac{\sigma_x-\sigma_y}{2}\sin 2\alpha=-\frac{\sigma}{2}\sin 2\alpha$$

Extremum für $\sin 2\alpha=\pm1 \;\Rightarrow\; 2\alpha=90^\circ$

$$\boxed{\alpha_{\max\tau}=45^\circ}\qquad\text{(bzw. }135^\circ\text{)},\qquad
\tau_{\max}=\frac{\sigma}{2}=\frac{F}{2A}$$

**In die Skizze:** zwei um $45^\circ$ zur Stabachse geneigte Schnittlinien (Kreuz),
die das bekannte Schubversagen im Zugversuch markieren.

---

### 1c) Zuordnung der Festigkeitshypothesen (3 P.)

| Formel | Festigkeitshypothese |
|---|---|
| $\sigma_v = 2\,\tau_{\max}$ | **Schubspannungshypothese (Tresca)** |
| $\sigma_v=\sqrt{\sigma_x^2+\sigma_y^2-\sigma_x\sigma_y+3\tau_{xy}^2}$ | **Gestaltänderungsenergiehypothese (von Mises / GEH)** |
| $\sigma_v=\lVert\sigma_1\rVert$ | **Normalspannungshypothese (Rankine)** |

*Merkhilfe:* Rankine → spröde Werkstoffe (Guss), Tresca/von Mises → zähe Werkstoffe (Stahl).

---

### 1d) Verbundquerschnitte (6 P.)

#### Fall 1 — Stahlzylinder mit Kupfermantel, Kraft F, starre Platte (Parallelschaltung)

Beide Teilquerschnitte sind über die starre Platte gekoppelt → **gleiche Dehnung**.

$$\varepsilon_1=\varepsilon_2,\qquad \sigma_i=E_i\varepsilon\;\Rightarrow\;
\sigma_1<\sigma_2 \quad(E_1<E_2)$$
$$N_i=\sigma_i A_i,\quad \sigma_1<\sigma_2 \;\wedge\; A_1<A_2\;\Rightarrow\; N_1<N_2$$

$$\boxed{N_1 < N_2\qquad \sigma_1 < \sigma_2 \qquad \varepsilon_1 = \varepsilon_2}$$

#### Fall 2 — Zwei Materialien, gleichmäßige Erwärmung $\Delta T$, beidseitig starr eingespannt (Reihenschaltung)

Die Stäbe liegen **hintereinander** zwischen zwei starren Wänden
($A_1=A_2$, $E_1<E_2$, $\alpha_1=\alpha_2$).

Gleichgewicht am Schnitt: $N_1=N_2=N$ (Druckkraft).
Wegen $A_1=A_2$ folgt $\sigma_1=\sigma_2$.
Verzerrung: $\varepsilon_i=\dfrac{N}{E_iA}+\alpha\Delta T$ mit $N<0$ →
der Term $N/(E_iA)$ ist bei kleinerem $E$ betragsmäßig größer (negativer):

$$\boxed{N_1 = N_2\qquad \sigma_1 = \sigma_2 \qquad \varepsilon_1 < \varepsilon_2}$$

(Die Gesamtverlängerung ist null: $\varepsilon_1 a+\varepsilon_2 a=0$, d.h. $\varepsilon_1=-\varepsilon_2$.)

---

### 1e) Freistoß (2 P.)

Wurfparabel ohne Luftwiderstand:

$$x_2(x_1)=x_1\tan\varphi_0-\frac{g\,x_1^2}{2v_0^2\cos^2\varphi_0}$$

Mit $x_1=20\,$m, $x_2=2{,}4\,$m, $\varphi_0=30^\circ$, $g=10\,$m/s²:

$$v_0^2=\frac{g\,x_1^2}{2\cos^2\varphi_0\,\bigl(x_1\tan\varphi_0-x_2\bigr)}
=\frac{10\cdot 400}{2\cdot 0{,}75\cdot(11{,}547-2{,}4)}=\frac{4000}{13{,}72}=291{,}5\ \tfrac{\text{m}^2}{\text{s}^2}$$

$$v_0=17{,}07\ \frac{\text{m}}{\text{s}}
\qquad\Rightarrow\qquad \boxed{v_0\approx 61{,}5\ \frac{\text{km}}{\text{h}}}$$

---

### 1f) Zuordnung der Beschleunigungsanteile (3 P.)

$$\mathbf a(t)=\underbrace{\bar{\mathbf a}}_{\textbf{6}}
+\overbrace{\underbrace{\overbrace{\mathbf a_0}^{\textbf{2}}
+\overbrace{\dot{\boldsymbol\Omega}\times\bar{\mathbf x}}^{\textbf{3}}
+\overbrace{\boldsymbol\Omega\times(\boldsymbol\Omega\times\bar{\mathbf x})}^{\textbf{1}}}_{\textbf{5}}}
+\underbrace{2\boldsymbol\Omega\times\bar{\mathbf v}}_{\textbf{4}}$$

| Term | Zahl | Bezeichnung |
|---|---|---|
| $\bar{\mathbf a}$ | **6** | Relativbeschleunigung |
| $\mathbf a_0$ | **2** | Beschleunigung des Bezugssystems (translatorisch) |
| $\dot{\boldsymbol\Omega}\times\bar{\mathbf x}$ | **3** | Beschleunigung des Bezugssystems (rotatorisch) |
| $\boldsymbol\Omega\times(\boldsymbol\Omega\times\bar{\mathbf x})$ | **1** | Zentrifugalbeschleunigung |
| Klammer $\{\mathbf a_0+\dot{\boldsymbol\Omega}\times\bar{\mathbf x}+\boldsymbol\Omega\times(\boldsymbol\Omega\times\bar{\mathbf x})\}$ | **5** | Führungsbeschleunigung |
| $2\boldsymbol\Omega\times\bar{\mathbf v}$ | **4** | Coriolisbeschleunigung |

---

### 1g) Momentanpol und Geschwindigkeitsverteilung der Walze (3 P.)

**Situation 1 — Walze rollt auf dem Boden (rollen ohne gleiten):**
* Momentanpol **Π im Berührpunkt** Walze/Boden.
* $v(r)=\Omega\cdot r$, gemessen **vom Berührpunkt**.
* Verteilung: **dreieckförmig (linear)**, $v=0$ am Boden, $v_{\max}=2\Omega R$ am höchsten Punkt,
  $v_M=\Omega R$ in Achshöhe. Alle Vektoren zeigen in dieselbe Richtung (horizontal).

**Situation 2 — Walze im Mittelpunkt gelagert (Drehung um die eigene Achse):**
* Momentanpol **Π im Mittelpunkt M** (Lager).
* $v(r)=\Omega\cdot r$ vom Mittelpunkt aus.
* Verteilung: **antimetrisch**, $v=0$ in der Achse, $v=\Omega R$ oben und $v=\Omega R$ unten,
  jedoch mit **entgegengesetztem Richtungssinn** (Doppeldreieck).

---

## Aufgabe 2 — Spannungsnachweis Rahmen (44 Punkte)

### System und Lasten

Eingespannter Stiel $h=10\,$m mit horizontalem Kragarm $a=2\,$m am Kopf.
Am Kragarmende: $F_V=40\,$kN (vertikal, nach unten), $F_H=50\,$kN (horizontal, zum Stiel hin).

### 2.1 Schnittgrößen (6 P.)

**Kragarm (Länge 2 m, Laufkoordinate vom freien Ende):**

| Größe | freies Ende | Ecke |
|---|---|---|
| $N_x$ | $-50$ kN (konstant, Druck) | $-50$ kN |
| $Q_z$ | $40$ kN (konstant) | $40$ kN |
| $M_y$ | $0$ | $40\cdot2=80$ kNm (linear) |

**Stiel (Laufkoordinate von oben nach unten, $s=0\ldots10$ m):**

$$N_x=-40\ \text{kN}\quad(\text{konstant, Druck aus }F_V)$$
$$Q_z=50\ \text{kN}\quad(\text{konstant, aus }F_H)$$
$$M_y(s)=-80\ \text{kNm}+50\,\text{kN}\cdot s$$

| Stelle | $M_y$ |
|---|---|
| Stielkopf $s=0$ | $-80$ kNm (aus dem Kragarm eingeleitet) |
| Nulldurchgang $s=1{,}6$ m | $0$ |
| **Einspannung $s=10$ m** | $+50\cdot10-80=\mathbf{420\ kNm}$ |

**Diagramme:**
* $N_x$: Rechteck, konstant $40$ kN Druck über den Stiel; $50$ kN Druck im Kragarm.
* $Q_z$: Rechteck, konstant $50$ kN im Stiel; $40$ kN im Kragarm.
* $M_y$: **linear**, Vorzeichenwechsel bei $1{,}6$ m unter dem Kopf,
  Maximalwert $|M_y|_{\max}=420$ kNm an der Einspannung.

> **Maßgebende Stelle für die Spannungsnachweise: Einspannung**
> mit $M_y=420$ kNm, $N_x=-40$ kN, $Q_z=50$ kN.

---

### 2.2 Querschnittswerte und Widerstandsmomente (12 P.)

**Dünnwandige Idealisierung (Mittellinien), Maße in cm, $z$ nach unten:**

| Nr. | Teil | $A_i$ [cm²] | $y_i$ [cm] | $z_i$ [cm] |
|---|---|---|---|---|
| 1 | Obergurt $40\times1{,}5$ | 60 | 0 | 0 |
| 2 | Steg links $20\times1{,}0$ | 20 | $-20$ | 10 |
| 3 | Steg rechts $20\times1{,}0$ | 20 | $+20$ | 10 |
| 4 | Schräge links $\ell=\sqrt{15^2+20^2}=25$, $t=1{,}0$ | 25 | $-27{,}5$ | 30 |
| 5 | Schräge rechts | 25 | $+27{,}5$ | 30 |
| | **Σ** | **150** | | |

**Schwerpunkt** (Symmetrie → $y_S=0$):

$$z_S=\frac{\sum A_iz_i}{\sum A_i}=\frac{0+200+200+750+750}{150}=\frac{1900}{150}
=\boxed{12{,}67\ \text{cm}}$$

Randabstände: $e_o=12{,}67$ cm (Obergurt), $e_u=40-12{,}67=27{,}33$ cm (Schrägenenden), $e_y=35$ cm.

**Flächenträgheitsmomente** (Steiner; für die Schrägen gilt
$I_{y,\text{eig}}=\frac{t\ell^3}{12}\sin^2\alpha$, $I_{z,\text{eig}}=\frac{t\ell^3}{12}\cos^2\alpha$
mit $\sin\alpha=0{,}8$, $\cos\alpha=0{,}6$):

$$I_y = 9637{,}9+2\cdot808{,}9+2\cdot8344{,}4=\boxed{27\,944{,}6\ \text{cm}^4}$$
$$I_z = 8000+2\cdot8001{,}7+2\cdot19\,375=\boxed{62\,753{,}3\ \text{cm}^4}$$

**Hauptachsen:** Der Querschnitt ist **symmetrisch zur $z$-Achse** ⇒ $I_{yz}=0$ ⇒
$y$ und $z$ sind bereits **Hauptachsen**, $\varphi_0=0^\circ$.

**Widerstandsmomente:**

| Biegung um | maßgebender Rand | $W=I/e$ |
|---|---|---|
| $y$-Achse | Obergurt, $e_o=12{,}67$ cm | $W_{y,o}=27\,944{,}6/12{,}67=\mathbf{2206\ cm^3}$ |
| $y$-Achse | Schrägenende, $e_u=27{,}33$ cm | $W_{y,u}=27\,944{,}6/27{,}33=\mathbf{1022\ cm^3}$ |
| $z$-Achse | $e_y=35$ cm | $W_z=62\,753{,}3/35=\mathbf{1793\ cm^3}$ |

$$\boxed{W_{\max}=2206\ \text{cm}^3\ \text{(Biegung um }y\text{, Obergurt)},\qquad
W_{\min}=1022\ \text{cm}^3\ \text{(Biegung um }y\text{, Untergurt)}}$$

Der Querschnitt ist damit **gegen Biegung um die $y$-Achse am schwächsten**
(maßgebend: unterer Rand), gegen Biegung um die $z$-Achse deutlich steifer
($I_z/I_y=2{,}25$).

---

### 2.3 Normalspannung an der maßgebenden Stelle (5 P.)

$$\sigma_x(z)=\frac{N_x}{A}+\frac{M_y}{I_y}\,z \qquad (z\ \text{ab Schwerpunkt})$$

$$\frac{N_x}{A}=\frac{-40\cdot10^3\,\text{N}}{15\,000\ \text{mm}^2}=-2{,}67\ \tfrac{\text{N}}{\text{mm}^2}$$
$$\frac{M_y}{I_y}=\frac{420\cdot10^6\ \text{Nmm}}{2{,}794\cdot10^8\ \text{mm}^4}=1{,}503\ \tfrac{\text{N}}{\text{mm}^3}$$

| Faser | $z$ [mm] | $\sigma_x$ [N/mm²] |
|---|---|---|
| Obergurt | $-126{,}7$ | $-2{,}67-190{,}4=\mathbf{-193{,}0}$ (Druck) |
| Schwerachse | $0$ | $-2{,}67$ |
| Schrägenende | $+273{,}3$ | $-2{,}67+410{,}8=\mathbf{+408{,}1}$ (Zug) |

**Verlauf:** linear über die Querschnittshöhe, Nulldurchgang um
$\Delta z = 2{,}67/1{,}503=1{,}8$ mm gegenüber der Schwerachse verschoben
(praktisch in Schwerpunkthöhe), betragsmäßiges Maximum am unteren Rand.

$$\boxed{\sigma_{x,\max}=+408\ \tfrac{\text{N}}{\text{mm}^2}\ \text{(unten)},\qquad
\sigma_{x,\min}=-193\ \tfrac{\text{N}}{\text{mm}^2}\ \text{(oben)}}$$

---

### 2.4 Schubspannungsverlauf (14 P.)

$$\tau(s)=\frac{Q_z\,S_y(s)}{I_y\,t(s)},\qquad Q_z=50\ \text{kN}$$

Offener Querschnitt → Start am freien Ende (Schrägenspitze), $S_y=0$.

**Statische Momente (Umlauf: Schrägenspitze → Steg → halber Obergurt):**

| Stelle | $S_y$ [cm³] | $t$ [cm] | $\tau$ [N/mm²] |
|---|---|---|---|
| Schrägenspitze | $0$ | 1,0 | $0$ |
| Schräge/Steg (Knick) | $25\cdot17{,}33=433{,}3$ | 1,0 | $\mathbf{7{,}75}$ |
| **Neutrale Faser** (im Steg) | $433{,}3+\tfrac{7{,}33^2}{2}=460{,}2$ | 1,0 | $\mathbf{8{,}23}$ (Maximum) |
| Steg/Obergurt (Steg-Seite) | $433{,}3-53{,}3=380{,}0$ | 1,0 | $6{,}80$ |
| Steg/Obergurt (Gurt-Seite) | $380{,}0$ | 1,5 | $4{,}53$ (Sprung!) |
| Symmetrieachse (Gurtmitte) | $380{,}0-380{,}0=0$ | 1,5 | $0$ ✓ |

**Verlaufscharakteristik (für die drei Skizzen):**
1. **Schrägen:** $S_y$ quadratisch ⇒ $\tau$ **parabelförmig** von 0 auf 7,75 N/mm².
2. **Stege:** $\tau$ parabelförmig mit **Maximum 8,23 N/mm² in Höhe der neutralen Faser**,
   Abfall auf 6,80 N/mm² am Obergurt.
3. **Obergurt:** $\tau$ **linear** von 4,53 N/mm² am Knick auf **0 in der Symmetrieachse**
   (Dickensprung $1{,}0\to1{,}5$ cm erzeugt den Spannungssprung, der Schubfluss
   $T=\tau\,t$ bleibt stetig: $T=6{,}80$ N/mm konstant über den Knoten).

$$\boxed{\tau_{\max}=8{,}23\ \tfrac{\text{N}}{\text{mm}^2}\ \text{in der neutralen Faser (Steg)}}$$

Kontrolle: $\oint$ Schubfluss ⇒ $S_y=0$ in der Symmetrieachse ✓

---

### 2.5 Spannungsnachweise und Bewertung (7 P.)

Maßgebend sind zwei Punkte, $\sigma_y=\sigma_z=0$:

**Punkt A — unterer Rand (maximales $\sigma$, $\tau=0$):** $\sigma_x=408{,}1$, $\tau=0$

| Hypothese | $\sigma_v$ [N/mm²] | Nachweis $\sigma_v\le235$ |
|---|---|---|
| Normalspannung (Rankine) | $408{,}1$ | **nicht erfüllt** |
| Schubspannung (Tresca) $\;2\tau_{\max}=\sigma_x$ | $408{,}1$ | **nicht erfüllt** |
| von Mises $\sqrt{\sigma_x^2+3\tau^2}$ | $408{,}1$ | **nicht erfüllt** |

**Punkt B — neutrale Faser (maximales $\tau$):** $\sigma_x=-2{,}67$, $\tau=8{,}23$

$$\sigma_v^{\text{Mises}}=\sqrt{2{,}67^2+3\cdot8{,}23^2}=14{,}5\ \tfrac{\text{N}}{\text{mm}^2}\ \le 235 \quad✓$$

**Ausnutzungsgrad:** $\eta=\dfrac{408{,}1}{235}=\mathbf{1{,}74}\;\Rightarrow$
**Überschreitung um 74 %.**

**Bewertung:** Der Querschnitt ist für das dargestellte System **nicht geeignet**.
Die Biegenormalspannung am unteren Rand liegt weit über $\sigma_{zul}$; Schub ist völlig
unkritisch, das Profil ist also **biegeschwach und schubstark** — das Material sitzt an
der falschen Stelle.

**Zwei mögliche Verbesserungen:**
1. **Untergurt ausbilden / Querschnitt schließen:** die aufgebogenen Schrägen zu einem
   durchgehenden Untergurt (Kastenprofil) umformen — erhöht $I_y$ und vor allem
   $W_{y,u}$ drastisch und macht den Querschnitt annähernd doppeltsymmetrisch.
2. **Bauhöhe vergrößern bzw. Blechdicken im Zugbereich erhöhen** (z.B. Stege auf 40 cm,
   Gurtdicke $\ge$ 2,0 cm) — $W_y$ wächst quadratisch mit der Höhe.

*(Alternativen: Hebelarm des Kragarms verkürzen, höherfesten Stahl S355 einsetzen,
Stiel am Kopf zusätzlich abspannen/aussteifen.)*

---

## Aufgabe 3 — Knotenblech, Mohr'scher Spannungskreis (10 Punkte)

Gegeben: $\sigma_x=50$ N/mm², $\tau_{xy}=20$ N/mm², $\alpha=60^\circ$.
Die $x$-Fläche liegt senkrecht zur Hypotenuse, die $y$-Fläche senkrecht zur
geneigten linken Kante ⇒ die **Schweißnaht (horizontal) hat eine Normale, die um
$\varphi=30^\circ$ gegen die $x$-Achse geneigt** ist.

### a) Bestimmung von $\sigma_y$

$$\tau_\varphi=-\frac{\sigma_x-\sigma_y}{2}\sin2\varphi+\tau_{xy}\cos2\varphi$$

mit $2\varphi=60^\circ$, $\sin60^\circ=0{,}866$, $\cos60^\circ=0{,}5$:

$$10=-\frac{50-\sigma_y}{2}\cdot0{,}866+20\cdot0{,}5
=-0{,}433\,(50-\sigma_y)+10$$

$$\Rightarrow\;0{,}433\,(50-\sigma_y)=0\qquad
\boxed{\sigma_y=50\ \tfrac{\text{N}}{\text{mm}^2}}$$

Zugehörige Normalspannung in der Naht:
$$\sigma_\varphi=\frac{\sigma_x+\sigma_y}{2}+\frac{\sigma_x-\sigma_y}{2}\cos2\varphi+\tau_{xy}\sin2\varphi
=50+0+20\cdot0{,}866=67{,}3\ \tfrac{\text{N}}{\text{mm}^2}$$

> *Hinweis:* Fordert man $\tau_\varphi=-10$ N/mm² (umgekehrter Richtungssinn in der Naht),
> ergibt sich als zweite Lösung $\sigma_y=3{,}8$ N/mm².

### b) Mohr'scher Spannungskreis

Mit $\sigma_x=\sigma_y=50$, $\tau_{xy}=20$:

$$\sigma_M=\frac{\sigma_x+\sigma_y}{2}=50\ \tfrac{\text{N}}{\text{mm}^2}
\qquad
R=\sqrt{\left(\frac{\sigma_x-\sigma_y}{2}\right)^2+\tau_{xy}^2}=\sqrt{0+400}=20\ \tfrac{\text{N}}{\text{mm}^2}$$

$$\boxed{\sigma_1=\sigma_M+R=70\ \tfrac{\text{N}}{\text{mm}^2},\qquad
\sigma_2=\sigma_M-R=30\ \tfrac{\text{N}}{\text{mm}^2}}$$
$$\boxed{\tau_{\max/\min}=\pm R=\pm20\ \tfrac{\text{N}}{\text{mm}^2}}$$

**Richtungen:**

$$\tan2\varphi_0=\frac{2\tau_{xy}}{\sigma_x-\sigma_y}=\frac{40}{0}\to\infty
\;\Rightarrow\; 2\varphi_0=90^\circ \;\Rightarrow\; \boxed{\varphi_0=45^\circ}$$

* Hauptnormalspannungen: $\sigma_1$ unter $45^\circ$, $\sigma_2$ unter $135^\circ$ zur $x$-Achse.
* Hauptschubspannungen: $45^\circ$ dazu gedreht, also **in den Richtungen der $x$- und
  $y$-Achse** ($\varphi_{\tau}=0^\circ$ bzw. $90^\circ$) — konsistent mit $\tau_{xy}=20=\tau_{\max}$.
* Der Kreis hat den Mittelpunkt $(50\,|\,0)$ und Radius 20; der Punkt der $x$-Fläche
  liegt bei $(50\,|\,20)$, der der $y$-Fläche bei $(50\,|\,-20)$ — beide **senkrecht
  übereinander**, was den Sonderfall $\sigma_x=\sigma_y$ kennzeichnet.

---

## Aufgabe 4 — Biegelinie des eingespannten Trägers (13 Punkte)

System: links volle Einspannung, rechts Loslager, Gleichlast $q$, $L=10$ m,
$EI=2{,}4\cdot10^4$ kNm² (einfach statisch unbestimmt).

### a) Größtmögliche Last q

**DGL:** $EI\,w''''(x)=q$

**Randbedingungen:** $w(0)=0,\;w'(0)=0,\;w(L)=0,\;M(L)=EI\,w''(L)=0$

**Lösung:**

$$w(x)=\frac{q}{48EI}\left(2x^4-5Lx^3+3L^2x^2\right)$$

Kontrolle: $w(0)=w'(0)=0$ ✓, $w(L)=\frac{q}{48EI}(2-5+3)L^4=0$ ✓,
$w''(L)=\frac{q}{48EI}(24-30+6)L^2=0$ ✓

**Auflagerreaktionen:** $A=\tfrac58 qL$, $B=\tfrac38 qL$, $M_A=\tfrac{qL^2}{8}$

**Ort der maximalen Durchbiegung:** $w'(x)=0$

$$8x^3-15Lx^2+6L^2x=0\;\Rightarrow\;8\xi^2-15\xi+6=0,\ \xi=x/L$$
$$\xi=\frac{15-\sqrt{33}}{16}=0{,}5785\quad\Rightarrow\quad x_{\max}=5{,}785\ \text{m}$$

$$w_{\max}=\frac{q}{48EI}\cdot0{,}25996\,L^4=0{,}005416\,\frac{qL^4}{EI}=\frac{qL^4}{184{,}6\,EI}$$

**Nachweisbedingung:** $w_{\max}\le\dfrac{L}{300}=\dfrac{10}{300}=0{,}03333\ \text{m}=33{,}3\ \text{mm}$

$$q\le\frac{184{,}6\,EI}{L^4}\cdot\frac{L}{300}
=\frac{184{,}6\cdot2{,}4\cdot10^4}{10^4}\cdot0{,}03333$$

$$\boxed{q_{\max}=14{,}77\ \frac{\text{kN}}{\text{m}}\approx 14{,}8\ \frac{\text{kN}}{\text{m}}}$$

### b) Skizze der Biegelinie — markante Stellen

| Stelle | $x$ | Wert / Merkmal |
|---|---|---|
| Einspannung | $0$ | $w=0$, $w'=0$ (**waagerechte Tangente**), $M_A=-\tfrac{qL^2}{8}=-184{,}6$ kNm |
| Wendepunkt ($M=0$) | $x=\tfrac{L}{4}=2{,}5$ m | Krümmungswechsel |
| Maximales Feldmoment ($Q=0$) | $x=\tfrac58 L=6{,}25$ m | $M=\tfrac{9qL^2}{128}=103{,}8$ kNm |
| **Maximale Durchbiegung** | $x=0{,}5785\,L=5{,}79$ m | $w_{\max}=L/300=\mathbf{33{,}3\ mm}$ |
| Loslager | $L=10$ m | $w=0$, $M=0$, Tangente geneigt |

Kurvenform: von der Einspannung mit waagerechter Tangente abfallend, Wendepunkt bei
2,5 m, flacher Scheitel bei 5,79 m, dann zurück auf null am Loslager — **unsymmetrisch**,
Scheitel zum Loslager hin verschoben.

### c) Zwei Möglichkeiten, die Durchbiegung zu verringern

1. **Biegesteifigkeit $EI$ erhöhen** — größeres Flächenträgheitsmoment (höheres Profil,
   Material weiter außen) oder Werkstoff mit höherem E-Modul.
2. **Stützweite verringern bzw. zusätzliche Unterstützung einbauen** — $w\sim L^4$,
   eine Mittelstütze oder eine zweite Einspannung reduziert die Durchbiegung um ein Vielfaches.

*(Weitere: Überhöhung/Vorspannung, Lastreduktion, Abspannung.)*

---

## Aufgabe 5 — Kinematik Flugzeug (12 Punkte)

### a) Endgeschwindigkeiten aus den Diagrammen

#### Fall 1 — $a(t)$ linear über der **Zeit**: $a(t)=a_0\left(1-\dfrac{t}{2t_e}\right)$

$$v(t)=\int_0^t a\,\mathrm dt=a_0\left(t-\frac{t^2}{4t_e}\right)
\;\Rightarrow\; v_e=\frac{3}{4}a_0t_e$$
$$x(t)=a_0\left(\frac{t^2}{2}-\frac{t^3}{12t_e}\right)
\;\Rightarrow\; L=x(t_e)=\frac{5}{12}a_0t_e^2
\;\Rightarrow\; t_e=\sqrt{\frac{12L}{5a_0}}$$

$$v_{e(1)}=\frac34 a_0\sqrt{\frac{12L}{5a_0}}=\frac34\sqrt{\frac{12}{5}a_0L}
\qquad\boxed{v_{e(1)}=1{,}162\,\sqrt{a_0L}}$$

#### Fall 2 — $a(x)$ linear über dem **Weg**: $a(x)=a_0\left(1-\dfrac{x}{2L}\right)$

Mit $v\,\mathrm dv=a\,\mathrm dx$:

$$\frac{v_e^2}{2}=\int_0^L a_0\left(1-\frac{x}{2L}\right)\mathrm dx
=a_0\left(L-\frac{L}{4}\right)=\frac34 a_0L$$

$$\boxed{v_{e(2)}=\sqrt{\frac32 a_0L}=1{,}225\,\sqrt{a_0L}}$$

> Vergleich: $v_{e(2)}>v_{e(1)}$ — bei wegabhängiger Abnahme wirkt die hohe
> Beschleunigung über eine längere Zeitspanne.

### b) Startvorgang mit $a(v)=a_0\dfrac{C_0}{C_0+v}$

$a_0=2$ m/s², $C_0=250$ m/s, $v_e=50$ m/s ⇒ $a_0C_0=500$ m²/s³

**Weg** (aus $a=v\,\dfrac{\mathrm dv}{\mathrm ds}$):

$$s=\int_0^{v_e}\frac{v}{a(v)}\,\mathrm dv=\frac{1}{a_0C_0}\int_0^{v_e}\left(C_0v+v^2\right)\mathrm dv
=\frac{1}{a_0C_0}\left[\frac{C_0v^2}{2}+\frac{v^3}{3}\right]_0^{50}$$

$$s=\frac{1}{500}\left(312\,500+41\,667\right)=\boxed{708{,}3\ \text{m}}$$

**Zeit** (aus $a=\dfrac{\mathrm dv}{\mathrm dt}$):

$$t=\int_0^{v_e}\frac{\mathrm dv}{a(v)}=\frac{1}{a_0C_0}\int_0^{50}\left(C_0+v\right)\mathrm dv
=\frac{1}{500}\left[250v+\frac{v^2}{2}\right]_0^{50}=\frac{12\,500+1250}{500}$$

$$\boxed{t=27{,}5\ \text{s}}$$

---

## Ergebnisübersicht

| Aufgabe | Ergebnis |
|---|---|
| 1b | $\alpha=45^\circ$, $\tau_{\max}=\sigma/2$ |
| 1d Fall 1 | $N_1<N_2$, $\sigma_1<\sigma_2$, $\varepsilon_1=\varepsilon_2$ |
| 1d Fall 2 | $N_1=N_2$, $\sigma_1=\sigma_2$, $\varepsilon_1<\varepsilon_2$ |
| 1e | $v_0=61{,}5$ km/h |
| 1f | 6 / 2 / 3 / 1 / 5 / 4 |
| 2.1 | $M_{y,\max}=420$ kNm, $N=-40$ kN, $Q=50$ kN |
| 2.2 | $A=150$ cm², $z_S=12{,}67$ cm, $I_y=27\,945$ cm⁴, $I_z=62\,753$ cm⁴, $W_{\min}=1022$ cm³ |
| 2.3 | $\sigma=+408 / -193$ N/mm² |
| 2.4 | $\tau_{\max}=8{,}23$ N/mm² |
| 2.5 | $\eta=1{,}74$ → **Nachweis nicht erfüllt** |
| 3a | $\sigma_y=50$ N/mm² |
| 3b | $\sigma_{1,2}=70/30$ N/mm², $\tau_{\max}=\pm20$ N/mm², $\varphi_0=45^\circ$ |
| 4a | $q_{\max}=14{,}77$ kN/m |
| 5a | $v_{e(1)}=1{,}162\sqrt{a_0L}$, $v_{e(2)}=1{,}225\sqrt{a_0L}$ |
| 5b | $s=708{,}3$ m, $t=27{,}5$ s |
