# Lösungsvorschlag — Modulprüfung Technische Mechanik II, PO 2019
**WiSe 25/26 · 1. April 2026** · Univ.-Prof. Dr.-Ing. Tim Ricken · ISD Stuttgart · 100 Punkte

---

## Aufgabe 1 — Theorie (12 P.)

### a) Parallelverschiebung der Bezugsachse

**Satz von Steiner:**

$$I_{\bar y}=I_y+A\,d^2$$

Das Flächenträgheitsmoment **nimmt immer zu**, wenn die Bezugsachse parallel vom Schwerpunkt
weg verschoben wird — und zwar **quadratisch** mit dem Abstand $d$.

$$\Rightarrow\quad \text{Das Flächenträgheitsmoment ist bezüglich der \textbf{Schwerachse minimal}.}$$

Der Steiner-Anteil ist stets positiv ($A>0$, $d^2\ge0$); eine Verschiebung kann $I$ niemals
verkleinern.

### b) Physikalische Bedeutung des Elastizitätsmoduls

$E$ ist die **Steigung der Spannungs-Dehnungs-Kurve** im linear-elastischen Bereich:

$$E=\frac{\sigma}{\varepsilon}\qquad\left[\frac{\text{N}}{\text{mm}^2}\right]$$

Er beschreibt den **Widerstand des Werkstoffs gegen elastische Längenänderung** —
je größer $E$, desto steifer das Material. Anschaulich: $E$ ist die (fiktive) Spannung,
die zu einer Dehnung von 100 % führen würde.

$E$ ist eine reine **Werkstoffkonstante**, unabhängig von der Bauteilgeometrie.
Die **Bauteilsteifigkeit** ergibt sich erst aus $EA$ (Dehnung) bzw. $EI$ (Biegung).

### c) Warum mehrere Integrationsbereiche?

Die Biegedifferentialgleichung $EIw''''=q$ setzt voraus, dass alle Funktionen im Bereich
**stetig differenzierbar** sind. An jeder Unstetigkeitsstelle bricht diese Voraussetzung,
daher muss ein **neuer Bereich** mit eigenen Integrationskonstanten begonnen werden.

**Zwei Beispiele:**

1. **Einzellast oder Einzelmoment** im Feld — die Querkraft springt um $F$ bzw. das
   Moment springt um $M$; $w'''$ bzw. $w''$ ist dort unstetig.
2. **Sprung der Streckenlast** oder **Änderung der Biegesteifigkeit $EI$**
   (Querschnittswechsel) — die vierte Ableitung ändert sich sprunghaft.

*(Weitere: Zwischenlager, Gelenke, Federn, Beginn/Ende einer Teilstreckenlast.)*

### d) Kernfläche des Dreiecks

Für ein **Dreieck** ist die Kernfläche wieder ein **Dreieck** — aber **um 180° gedreht**
(auf dem Kopf stehend) und deutlich kleiner.

**Konstruktion:** Jede der drei Dreiecksseiten wird als neutrale Faser angesetzt; der
zugehörige Kernpunkt ist

$$k=-\frac{i^2}{\text{Achsabschnitt}},\qquad i^2=\frac{I}{A}$$

Für das gleichschenklige Dreieck mit Höhe $h$ (Schwerpunkt bei $h/3$ von der Basis):

$$k_{z,\text{oben}}=\frac{h}{4}\cdot\frac{1}{?}\quad\text{bzw. allgemein}\quad
k=\frac{I_y}{A\,e}$$

**Skizze:** Ein kleines, auf dem Kopf stehendes Dreieck um $S$, dessen Ecken jeweils den
gegenüberliegenden Dreiecksseiten zugeordnet sind. Die Kernfläche liegt vollständig
innerhalb des Querschnitts und ist **konvex**.

**Dualität merken:** Konturecke ↔ Kerngerade, Konturseite ↔ Kernecke.

### e) Normalspannungsverteilung bei exzentrischer Druckkraft

**1.) Angriffspunkt INNERHALB der Kernfläche:**

$$\sigma(y,z)=\frac{N}{A}+\frac{M_y}{I_y}z+\frac{M_z}{I_z}y$$

Die Spannung hat **im gesamten Querschnitt dasselbe Vorzeichen** (hier: überall Druck).
Die neutrale Faser liegt **außerhalb** des Querschnitts — sie schneidet ihn nicht.
Das ist der Normalfall für Baustoffe, die keinen Zug aufnehmen können (Mauerwerk, Beton).

**2.) Angriffspunkt AUSSERHALB der Kernfläche:**

Die neutrale Faser **schneidet den Querschnitt**. Es entsteht ein
**Vorzeichenwechsel**: ein Teil des Querschnitts steht unter Druck, der andere unter **Zug**.

$$\Rightarrow\quad\text{Bei zugunfähigen Werkstoffen klafft die Fuge auf.}$$

**Grenzfall (auf dem Kernrand):** Die neutrale Faser ist **Tangente** an die
Querschnittskontur — die Randspannung wird gerade null.

### f) Schubmittelpunkte bei vertikaler Last

| Querschnitt | Lage von M | Begründung |
|---|---|---|
| **Kreisring (geschlossen)** | **im Mittelpunkt** $M\equiv S$ | Punktsymmetrie: alle Schubflüsse gehen durch den Mittelpunkt |
| **I-Profil (doppelsymmetrisch)** | **im Schwerpunkt** $M\equiv S$ | zwei Symmetrieachsen ⇒ M liegt im Schnittpunkt |
| **C-/U-Profil** | **außerhalb**, auf der dem Steg **abgewandten** Seite, auf der horizontalen Symmetrieachse | Die Flanschschubkräfte bilden ein Kräftepaar, dessen Moment nur durch einen Versatz von M ausgeglichen werden kann |

**Grundregel:** M liegt immer auf einer vorhandenen Symmetrieachse. Bei offenen Profilen
liegt M außerhalb der Fläche; das ist die Ursache dafür, dass U-Profile unter vertikaler
Last verdrillen.

---

## Aufgabe 2 — Flügelprofil, Flächenträgheitsmomente (12 P.)

Halbprofil aus **Viertelkreis (1)** ($r=0{,}5$ m), **Rechteck (2)** ($b=2{,}5$ m)
und **Dreieck (3)** ($b=1$ m); Bezugsachse $y$ = untere Kante (strichpunktierte Achse),
Gesamthöhe $0{,}5$ m ($=0{,}2+0{,}3$).

### a) Flächenträgheitsmomente im $x$–$z$-System

**Eigenträgheitsmomente und Schwerpunktlagen:**

| Teil | $A_i$ [m²] | $I_{yi}$ [m⁴] | $I_{zi}$ [m⁴] |
|---|---|---|---|
| ① Viertelkreis $r=0{,}5$ | $\frac{\pi r^2}{4}=0{,}1963$ | $\left(\frac{\pi}{16}-\frac{4}{9\pi}\right)r^4=0{,}00343$ | dito (symmetrisch) |
| ② Rechteck $2{,}5\times0{,}5$ | $1{,}25$ | $\frac{bh^3}{12}=\frac{2{,}5\cdot0{,}5^3}{12}=0{,}02604$ | $\frac{hb^3}{12}=\frac{0{,}5\cdot2{,}5^3}{12}=0{,}6510$ |
| ③ Dreieck $1\times0{,}5$ | $0{,}25$ | $\frac{bh^3}{36}=\frac{1\cdot0{,}5^3}{36}=0{,}00347$ | $\frac{hb^3}{36}=\frac{0{,}5\cdot1^3}{36}=0{,}01389$ |

**Steiner-Anteile:** $I^{\text{Steiner}}_{yi}=A_i\bar z_i^2$, $I^{\text{Steiner}}_{zi}=A_i\bar y_i^2$

mit den Schwerpunktabständen:
* Viertelkreis: $\bar z_1=\dfrac{4r}{3\pi}=0{,}2122$ m; $\bar y_1=-\dfrac{4r}{3\pi}$ von der Kante
* Rechteck: $\bar z_2=0{,}25$ m; $\bar y_2=0{,}5+1{,}25=1{,}75$ m
* Dreieck: $\bar z_3=\dfrac{h}{3}=0{,}1667$ m; $\bar y_3=0{,}5+2{,}5+\dfrac{1}{3}=3{,}333$ m

**Ausfüllen der Tabelle und Summation:**

$$\boxed{I_y=\sum_i\left(I_{yi}+I_{yi}^{\text{Steiner}}\right),\qquad
I_z=\sum_i\left(I_{zi}+I_{zi}^{\text{Steiner}}\right)}$$

Zahlenwerte (gerundet):

$$I_y\approx0{,}00343+0{,}0088+0{,}02604+0{,}0781+0{,}00347+0{,}00694\approx\mathbf{0{,}127\ m^4}$$
$$I_z\approx(0{,}00343+0{,}0059)+(0{,}6510+3{,}8281)+(0{,}01389+2{,}7778)\approx\mathbf{7{,}28\ m^4}$$

*(Die genauen Werte hängen von der exakten Zuordnung der Maße 0,2 / 0,3 ab — das Schema
Eigenanteil + Steiner ist entscheidend.)*

### b) Rechteck (A) entfernt

Das Rechteck (A) ($b_A=2$ m, $h_A$ aus der Bemaßung) wird als **negative Fläche**
subtrahiert:

$$\boxed{I_y^{\text{ohne A}}=I_y-\left(\frac{b_Ah_A^3}{12}+A_A\bar z_A^2\right)}$$
$$\boxed{I_z^{\text{ohne A}}=I_z-\left(\frac{h_Ab_A^3}{12}+A_A\bar y_A^2\right)}$$

**Wichtig:** Es wird **nur subtrahiert**, die Bezugsachse bleibt unverändert. Der Steiner-Anteil
der Aussparung ist ebenfalls abzuziehen — ein häufiger Fehler ist, ihn zu vergessen.

**Zu erwartende Tendenz:** $I_y$ sinkt nur mäßig (die Aussparung liegt nahe der Bezugsachse),
$I_z$ sinkt **stark** (die Aussparung liegt weit von der $z$-Achse entfernt, großer
Steiner-Anteil).

---

## Aufgabe 3 — Verkürzung der linken Feder (5 P.)

Gegeben: $\ell$, $EA$, $F$, $c_f=\dfrac{3EA}{4\ell}$; starrer Balken ($EA,EI\to\infty$)
der Länge $8\ell$ (vier Abschnitte à $2\ell$).

### System

* **Links** ($x=0$): Feder $c_f$
* **Mitte** ($x=4\ell$): festes Auflager (Drehpunkt)
* **Rechts** ($x=8\ell$): zwei Stäbe — $2EA$ mit Länge $\ell$ (nach oben) und
  $EA$ mit Länge $2\ell$ (nach unten)
* **Lasten:** $2F$ bei $x=2\ell$, $F$ bei $x=6\ell$

### Ersatzfedersteifigkeiten

Die beiden rechten Stäbe wirken **parallel** (gleicher Knoten, gleiche Verschiebung):

$$c_{rechts}=\frac{2EA}{\ell}+\frac{EA}{2\ell}=\frac{4EA+EA}{2\ell}=\frac{5EA}{2\ell}=2{,}5\,\frac{EA}{\ell}$$

$$c_f=\frac{3EA}{4\ell}=0{,}75\,\frac{EA}{\ell}$$

### Kinematik

Der Balken ist **starr** ⇒ er kann sich nur um das mittlere Auflager drehen.
Bei einer Drehung $\varphi$ gilt für die Verschiebungen an den Enden (Hebelarm je $4\ell$):

$$\delta_{links}=4\ell\,\varphi\ (\text{nach unten}),\qquad
\delta_{rechts}=4\ell\,\varphi\ (\text{nach oben}) \;\Rightarrow\; \delta_{links}=\delta_{rechts}=\delta$$

### Momentengleichgewicht um das mittlere Auflager

**Antreibende Lasten:**
$$2F\cdot 2\ell\ (\text{links, dreht links nach unten}) \;-\; F\cdot2\ell\ (\text{rechts, entgegengesetzt})
=4F\ell-2F\ell=2F\ell$$

**Rückstellende Federkräfte** (beide mit Hebelarm $4\ell$):
$$c_f\,\delta\cdot4\ell \;+\; c_{rechts}\,\delta\cdot4\ell$$

$$2F\ell=4\ell\,\delta\left(c_f+c_{rechts}\right)
=4\ell\,\delta\left(0{,}75+2{,}5\right)\frac{EA}{\ell}=13\,\delta\,EA$$

### Ergebnis

$$\boxed{\;\delta=\Delta\ell_{Feder}=\frac{2F\ell}{13\,EA}\approx0{,}154\,\frac{F\ell}{EA}\;}$$

Da sich das linke Balkenende **nach unten** bewegt, wird die Feder **zusammengedrückt** —
es handelt sich um eine **Verkürzung**.

**Kontrolle:** Federkraft $F_c=c_f\delta=\dfrac{3EA}{4\ell}\cdot\dfrac{2F\ell}{13EA}=\dfrac{3F}{26}=0{,}115\,F$;
Kraft in den rechten Stäben $=2{,}5\dfrac{EA}{\ell}\cdot\dfrac{2F\ell}{13EA}=\dfrac{5F}{13}=0{,}385\,F$.
Momentenprobe: $(0{,}115+0{,}385)F\cdot4\ell=2F\ell$ ✓

---

## Aufgabe 4 — Drei Stäbe, Temperatur und Kraft (5 P.)

Gegeben: $\ell$, $A$, $E$, $\alpha_T$, $F$
Stab ①: $E$, $A$, $\alpha_T$, $\Delta T$, Länge $3\ell$ (links, an der Wand)
Stäbe ② ($E$, $2A/3$) und ③ ($E$, $A/3$): Länge $2\ell$, **parallel** zwischen den Scheiben A und B
Kraft $F$ greift bei B an.

### Gleichgewicht

Die Kraft $F$ wird über die gesamte Kette bis zur Wand durchgeleitet:

$$N_① = N_②+N_③ = F$$

Die Parallelstäbe teilen sich $F$ nach ihren Dehnsteifigkeiten:

$$c_②=\frac{E\cdot\frac{2A}{3}}{2\ell}=\frac{EA}{3\ell},\qquad
c_③=\frac{E\cdot\frac{A}{3}}{2\ell}=\frac{EA}{6\ell}$$

$$c_{23}=c_②+c_③=\frac{EA}{3\ell}+\frac{EA}{6\ell}=\frac{EA}{2\ell}$$

### Bedingung: Querschnitt A verschiebt sich nicht

Die Verschiebung von A ist die Verlängerung von Stab ① (mechanisch **und** thermisch):

$$u_A=\underbrace{\frac{N_①\cdot 3\ell}{EA}}_{\text{mechanisch}}
+\underbrace{\alpha_T\,\Delta T\cdot3\ell}_{\text{thermisch}}\stackrel{!}{=}0$$

$$\frac{F\cdot3\ell}{EA}+3\ell\,\alpha_T\Delta T=0$$

$$\boxed{\;\Delta T=-\frac{F}{\alpha_T\,E\,A}\;}$$

**Interpretation:** $\Delta T<0$ — der Stab muss **abgekühlt** werden. Die Zugkraft $F$ will
ihn verlängern; die thermische Kontraktion muss diese Verlängerung exakt kompensieren.
Bemerkenswert: $\Delta T$ ist **unabhängig von der Stablänge** $3\ell$, da sich die Länge
in beiden Anteilen herauskürzt.

### Verschiebung des Querschnitts B

$$u_B=u_A+\Delta\ell_{23}=0+\frac{F}{c_{23}}=\frac{F}{\frac{EA}{2\ell}}$$

$$\boxed{\;u_B=\frac{2F\ell}{EA}\;}$$

Die Stäbe ② und ③ erfahren **keine** Temperaturlast, daher nur der mechanische Anteil.
Die Verschiebung erfolgt in Richtung von $F$ (nach rechts).

**Kontrolle der Lastaufteilung:**
$N_②=F\cdot\frac{c_②}{c_{23}}=\frac{2}{3}F$, $N_③=\frac{1}{3}F$ — entsprechend den Flächen
$2A/3$ und $A/3$. Beide Stäbe haben dieselbe Spannung $\sigma=\frac{F}{A}$ ✓

---

## Aufgabe 5 — Ebener Spannungszustand (13 P.)

$$\boldsymbol\sigma=\begin{bmatrix}-10 & 20\\ 20 & 15\end{bmatrix}\ \text{MPa}$$

Gegeben: $E=2{,}1\cdot10^5$ N/mm², $\nu=0{,}3$, $\alpha_T=5\cdot10^{-6}$ 1/K

### a) Hauptspannungen

$$\sigma_M=\frac{\sigma_x+\sigma_y}{2}=\frac{-10+15}{2}=2{,}5\ \text{MPa}$$

$$R=\sqrt{\left(\frac{\sigma_x-\sigma_y}{2}\right)^2+\tau_{xy}^2}
=\sqrt{\left(\frac{-25}{2}\right)^2+20^2}=\sqrt{156{,}25+400}=\sqrt{556{,}25}=23{,}59\ \text{MPa}$$

$$\boxed{\sigma_I=2{,}5+23{,}59=26{,}08\ \text{MPa},\qquad
\sigma_{II}=2{,}5-23{,}59=-21{,}08\ \text{MPa}}$$

**Hauptrichtung:**

$$\tan2\varphi_0=\frac{2\tau_{xy}}{\sigma_x-\sigma_y}=\frac{40}{-25}=-1{,}6
\;\Rightarrow\; 2\varphi_0=122{,}0^\circ \;\Rightarrow\; \boxed{\varphi_0=61{,}0^\circ}$$

$$\tau_{\max}=R=23{,}59\ \text{MPa}\quad\text{(unter }\varphi_0\pm45^\circ\text{)}$$

**Mohr-Kreis:** Mittelpunkt $(2{,}5\,|\,0)$, Radius $23{,}59$.
Bildpunkt der $x$-Fläche: $(-10\,|\,20)$; der $y$-Fläche: $(15\,|\,-20)$.

### b) Spannungskomponenten auf Seite ②

Transformation mit dem Normalenwinkel $\theta_②$ der Kante ② (aus der Scheibengeometrie,
Kantenwinkel $50^\circ$ bei ①/②):

$$\sigma_\theta=\sigma_M+\frac{\sigma_x-\sigma_y}{2}\cos2\theta+\tau_{xy}\sin2\theta$$
$$\tau_\theta=-\frac{\sigma_x-\sigma_y}{2}\sin2\theta+\tau_{xy}\cos2\theta$$

$$\sigma_\theta=2{,}5-12{,}5\cos2\theta+20\sin2\theta,\qquad
\tau_\theta=12{,}5\sin2\theta+20\cos2\theta$$

Mit dem aus der Skizze abgelesenen $\theta_②$ einzusetzen.

### c) Winkel $\alpha$, sodass auf Seite ③ nur Schub wirkt

Bedingung: $\sigma_\theta=0$

$$2{,}5-12{,}5\cos2\theta+20\sin2\theta=0$$

Umformen mit $R=23{,}59$:

$$23{,}59\cos\left(2\theta+58{,}0^\circ\right)=2{,}5
\;\Rightarrow\;\cos(2\theta+58{,}0^\circ)=0{,}1060$$

$$2\theta+58{,}0^\circ=\pm83{,}92^\circ$$

$$\boxed{\theta_1=12{,}96^\circ \qquad\text{oder}\qquad \theta_2=-70{,}96^\circ}$$

Die zugehörige Schubspannung beträgt dort

$$\tau=\pm\sqrt{R^2-\sigma_M^2}=\pm\sqrt{556{,}25-6{,}25}=\pm23{,}45\ \text{MPa}$$

**Anschaulich im Mohr-Kreis:** Da der Kreis die $\tau$-Achse schneidet
($|\sigma_M|=2{,}5 < R=23{,}59$), existieren **zwei** Schnittrichtungen mit reiner
Schubbeanspruchung. Das ist genau dann der Fall, wenn $\sigma_I$ und $\sigma_{II}$
**unterschiedliche Vorzeichen** haben — hier erfüllt.

Der gesuchte Winkel $\alpha$ folgt aus der Differenz zwischen $\theta$ und der
Kantenorientierung in der Skizze.

### d) Spannungskomponenten auf Seite ④

Mit dem Normalenwinkel $\theta_④$ (aus dem $30^\circ$-Eckwinkel) in dieselben
Transformationsformeln wie in b) einsetzen. Die Werte lassen sich auch direkt am
Mohr-Kreis abgreifen — der Winkel zwischen den Kanten erscheint dort **verdoppelt**.

### e) Temperaturänderung für $\varepsilon_x=0$

Hooke mit Temperaturanteil (ebener Spannungszustand):

$$\varepsilon_x=\frac{1}{E}\left(\sigma_x-\nu\sigma_y\right)+\alpha_T\Delta T\stackrel{!}{=}0$$

$$\frac{1}{2{,}1\cdot10^5}\left(-10-0{,}3\cdot15\right)+5\cdot10^{-6}\,\Delta T=0$$

$$\frac{-14{,}5}{2{,}1\cdot10^5}=-6{,}905\cdot10^{-5}$$

$$\boxed{\;\Delta T=\frac{6{,}905\cdot10^{-5}}{5\cdot10^{-6}}=+13{,}81\ \text{K}\;}$$

**Der Werkstoff muss erwärmt werden** — die Druckspannung $\sigma_x=-10$ MPa staucht in
$x$-Richtung, die Wärmedehnung gleicht dies aus.

**Dehnung in $y$-Richtung:**

$$\varepsilon_y=\frac{1}{E}\left(\sigma_y-\nu\sigma_x\right)+\alpha_T\Delta T
=\frac{15+3}{2{,}1\cdot10^5}+6{,}905\cdot10^{-5}$$

$$\varepsilon_y=8{,}571\cdot10^{-5}+6{,}905\cdot10^{-5}=\boxed{1{,}548\cdot10^{-4}}$$

Die Probe dehnt sich also in $y$-Richtung um 0,0155 %, während sie in $x$-Richtung
maßhaltig bleibt.

---

## Aufgabe 6 — Verformungsfigur und Randbedingungen (10 P.)

Gegeben: $EA\to\infty$, $EI=$ konst., $q$, Wegfeder $c_f$, Drehfeder $c_m$;
drei Bereiche à 3 m.

### a) Qualitative Verformungsfigur

**Zeichenregeln:**
* $EA\to\infty$ ⇒ **keine Längenänderung** der Stäbe: Rahmenecken verschieben sich nur
  senkrecht zur jeweiligen Stabachse.
* Die **Wegfeder $c_f$** lässt eine Verschiebung zu (proportional zur Federkraft) —
  kein starres Lager zeichnen!
* Die **Drehfeder $c_m$** lässt eine Verdrehung zu, überträgt aber Moment — eine
  „weiche Einspannung" zwischen voller Einspannung und Gelenk.
* Rahmenecken bleiben **rechtwinklig** (biegesteif).
* Die Krümmung folgt dem Momentenverlauf: Wendepunkte dort, wo $M=0$.

### b) Rand- und Übergangsbedingungen

Drei Bereiche ⇒ $3\times4=\mathbf{12}$ Integrationskonstanten ⇒ **12 Bedingungen**:

| # | Bedingung | Typ |
|---|---|---|
| 1 | $w_1(0)=0$ | Lager |
| 2 | $-EIw_1''(0)=c_m\,w_1'(0)$ | **Drehfeder**: Moment $\propto$ Verdrehung |
| 3 | $w_1(3)=w_2(0)$ | Verschiebungsstetigkeit (Ecke) |
| 4 | $w_1'(3)=\pm w_2'(0)$ | Neigungsstetigkeit (biegesteife Ecke) |
| 5 | $M_1(3)=M_2(0)$ | Momentenstetigkeit |
| 6 | $Q_1(3)=Q_2(0)$ | Querkraftstetigkeit (keine Einzellast) |
| 7 | $w_2(3)=w_3(0)$ | Übergang 2→3 |
| 8 | $w_2'(3)=\pm w_3'(0)$ | Neigungsstetigkeit |
| 9 | $M_2(3)=M_3(0)$ | Momentenstetigkeit |
| 10 | $Q_2(3)=Q_3(0)$ | Querkraftstetigkeit |
| 11 | $M_3(3)=0$ | freies Ende bzw. Gelenk |
| 12 | $Q_3(3)=-c_f\,w_3(3)$ | **Wegfeder**: Kraft $\propto$ Verschiebung |

**Wegen $EA\to\infty$** kommen zusätzlich die kinematischen Kopplungen an den Ecken hinzu:
die Verschiebung eines Bereichs in Richtung der Achse des angrenzenden Bereichs ist null
(z. B. $w_2(0)=0$, wenn der angrenzende Stab dehnstarr in dieser Richtung liegt).

**Merksätze für Federrandbedingungen:**
$$\text{Wegfeder:}\quad Q=\mp c_f\,w \qquad\qquad \text{Drehfeder:}\quad M=\mp c_m\,w'$$
Das Vorzeichen folgt daraus, dass die Feder der Verformung stets **entgegenwirkt**.

---

## Aufgabe 7 — Biegelinie mit Ersatzfeder (11 P.)

Gegeben: $\ell$, $EI_1$, $EI_2\to\infty$, $EA_1\to\infty$,
$EA_2=\dfrac{3EI_1}{12\ell^2}=\dfrac{EI_1}{4\ell^2}$, Gleichlast $q$;
horizontaler Stab Länge $4\ell$, Stab ② Länge $2\ell$.

### Schritt 1 — Stab ② durch Ersatzfeder ersetzen (Hinweis der Aufgabe)

$$c=\frac{EA_2}{\ell_2}=\frac{EI_1/(4\ell^2)}{2\ell}=\boxed{\frac{EI_1}{8\ell^3}}$$

Die dimensionslose Federsteifigkeit ist $\dfrac{c\,(4\ell)^3}{EI_1}=8$ — eine
**relativ weiche** Stütze.

### Schritt 2 — Differentialgleichung

Mit $L=4\ell$, Einspannung bei $x_1=0$, Feder am Gelenk bei $x_1=L$:

$$EI_1\,w_1''''=q$$

$$EI_1\,w_1(x_1)=\frac{q}{24}x_1^4+\frac{C_1}{6}x_1^3+\frac{C_2}{2}x_1^2+C_3x_1+C_4$$

### Schritt 3 — Randbedingungen

| # | Bedingung | Folge |
|---|---|---|
| 1 | $w_1(0)=0$ | $C_4=0$ |
| 2 | $w_1'(0)=0$ (Einspannung) | $C_3=0$ |
| 3 | $M_1(L)=-EIw_1''(L)=0$ (Gelenk) | $\frac{qL^2}{2}+C_1L+C_2=0$ |
| 4 | $Q_1(L)=c\,w_1(L)$ (Federkraft) | $qL+C_1=c\,w_1(L)$ |

### Schritt 4 — Auflösen

Aus (3): $\;C_2=-\dfrac{qL^2}{2}-C_1L$

$$EI_1w_1(L)=\frac{qL^4}{24}+\frac{C_1L^3}{6}-\frac{qL^4}{4}-\frac{C_1L^3}{2}
=-\frac{5qL^4}{24}-\frac{C_1L^3}{3}$$

Mit $L=4\ell$ ($L^3=64\ell^3$, $L^4=256\ell^4$) und $\dfrac{c}{EI_1}=\dfrac{1}{8\ell^3}$
in (4) eingesetzt:

$$4q\ell+C_1=\frac{1}{8\ell^3}\left(-\frac{5q\cdot256\ell^4}{24}-\frac{64C_1\ell^3}{3}\right)
=-\frac{20}{3}q\ell-\frac{8}{3}C_1$$

$$\frac{11}{3}C_1=-\frac{32}{3}q\ell \quad\Longrightarrow\quad
\boxed{C_1=-\frac{32}{11}q\ell}$$

$$C_2=-8q\ell^2+\frac{128}{11}q\ell^2=\boxed{\frac{40}{11}q\ell^2}$$

### Ergebnis

$$\boxed{\;w_1(x_1)=\frac{q}{EI_1}\left[\frac{x_1^4}{24}-\frac{16\,\ell}{33}x_1^3
+\frac{20\,\ell^2}{11}x_1^2\right]\;}$$

### Durchbiegung am Gelenk

$$w_1(4\ell)=\frac{q}{EI_1}\left[\frac{256\ell^4}{24}-\frac{16\ell\cdot64\ell^3}{33}
+\frac{20\ell^2\cdot16\ell^2}{11}\right]$$

$$=\frac{q\ell^4}{EI_1}\left[\frac{32}{3}-\frac{1024}{33}+\frac{320}{11}\right]
=\frac{q\ell^4}{EI_1}\cdot\frac{352-1024+960}{33}$$

$$\boxed{\;w_1(4\ell)=\frac{96}{11}\cdot\frac{q\ell^4}{EI_1}\approx8{,}73\,\frac{q\ell^4}{EI_1}\;}$$

**Kontrolle über die Federkraft:**

$$F_c=c\,w_1(4\ell)=\frac{EI_1}{8\ell^3}\cdot\frac{96\,q\ell^4}{11\,EI_1}=\frac{12}{11}q\ell=1{,}09\,q\ell$$

Gegenprobe mit (4): $qL+C_1=4q\ell-\frac{32}{11}q\ell=\frac{44-32}{11}q\ell=\frac{12}{11}q\ell$ ✓

Von der Gesamtlast $qL=4q\ell$ trägt die Feder also nur $27\,\%$ — die weiche Stütze
entlastet die Einspannung kaum.

---

## Aufgabe 8 — Schiefe Biegung im Hauptachsensystem (15 P.)

Gegeben: $\ell=200$ cm, $F_y=0{,}5$ kN, $F_z=0{,}3$ kN, $n=0{,}1$ kN/cm,
$A=11{,}77$ cm², $I_y=I_z=34{,}27$ cm⁴, $I_{yz}=-6{,}38$ cm⁴, $\varphi^*=-45^\circ$

### a) Hauptträgheitsmomente

$$I_{y_0}=\frac{I_y+I_z}{2}+\frac{I_y-I_z}{2}\cos2\varphi^*-I_{yz}\sin2\varphi^*$$

Mit $I_y=I_z$ entfällt der zweite Term; $\sin(2\cdot(-45^\circ))=\sin(-90^\circ)=-1$:

$$I_{y_0}=34{,}27+0-(-6{,}38)\cdot(-1)=34{,}27-6{,}38=\boxed{27{,}89\ \text{cm}^4}$$

$$I_{z_0}=34{,}27+6{,}38=\boxed{40{,}65\ \text{cm}^4}$$

**Kontrolle (Invarianten):**
$$I_{y_0}+I_{z_0}=68{,}54=I_y+I_z \;✓\qquad
R=\sqrt{0+6{,}38^2}=6{,}38 \;✓$$

Wegen $I_y=I_z$ liegen die Hauptachsen **exakt unter $\pm45^\circ$** — der Mohr'sche
Trägheitskreis hat seinen Mittelpunkt auf der Ordinate der Ausgangswerte.

### b) Biegenormalspannung bei $x=\ell/2$

**Schnittgrößen** (Kragträger, Einspannung links, Lasten am freien Ende):

$$N\left(\tfrac{\ell}{2}\right)=n\cdot\frac{\ell}{2}=0{,}1\cdot100=\mathbf{10\ kN}$$
$$M_y\left(\tfrac{\ell}{2}\right)=F_z\cdot\frac{\ell}{2}=0{,}3\cdot100=\mathbf{30\ kNcm}$$
$$M_z\left(\tfrac{\ell}{2}\right)=F_y\cdot\frac{\ell}{2}=0{,}5\cdot100=\mathbf{50\ kNcm}$$

**Zusätzlich:** Da die Lasten laut Aufgabenstellung an der **äußeren Ecke** angreifen,
erzeugt die Normalkraft $N$ zusätzliche Momente
$\Delta M_y=N\cdot z_F$ und $\Delta M_z=N\cdot y_F$ mit den Eckkoordinaten $(y_F,z_F)$.

**Transformation ins Hauptachsensystem** (Drehung um $\varphi^*=-45^\circ$):

$$M_{y_0}=M_y\cos\varphi^*-M_z\sin\varphi^*,\qquad
M_{z_0}=M_y\sin\varphi^*+M_z\cos\varphi^*$$

Mit $\cos(-45^\circ)=0{,}7071$, $\sin(-45^\circ)=-0{,}7071$:

$$M_{y_0}=0{,}7071\,(M_y+M_z)=0{,}7071\cdot80=\mathbf{56{,}6\ kNcm}$$
$$M_{z_0}=0{,}7071\,(M_z-M_y)=0{,}7071\cdot20=\mathbf{14{,}1\ kNcm}$$

**Spannungsfunktion im Hauptachsensystem** (dort gilt die einfache Superposition,
da $I_{y_0z_0}=0$):

$$\boxed{\;\sigma_x(y_0,z_0)=\frac{N}{A}+\frac{M_{y_0}}{I_{y_0}}z_0+\frac{M_{z_0}}{I_{z_0}}y_0\;}$$

$$\sigma_x=\frac{10}{11{,}77}+\frac{56{,}6}{27{,}89}z_0+\frac{14{,}1}{40{,}65}y_0
=0{,}850+2{,}029\,z_0+0{,}347\,y_0\quad\left[\tfrac{\text{kN}}{\text{cm}^2}\right]$$

### c) Maximal- und Minimalwerte

Die Extremwerte treten in den **am weitesten von der neutralen Faser entfernten Eckpunkten**
auf. Die Eckkoordinaten des L-Profils (Schenkel $2{,}0$ cm und $3{,}0$ cm, Breite
$2{,}5+2{,}5$ cm) sind zunächst ins $y_0$-$z_0$-System zu drehen:

$$y_0=y\cos\varphi^*+z\sin\varphi^*,\qquad z_0=-y\sin\varphi^*+z\cos\varphi^*$$

Anschließend in die Spannungsfunktion einsetzen und den größten bzw. kleinsten Wert
ablesen:

$$\sigma_{\max}=\sigma_x(y_0,z_0)\big|_{\text{Ecke mit größtem }(2{,}029z_0+0{,}347y_0)}$$
$$\sigma_{\min}=\sigma_x(y_0,z_0)\big|_{\text{Ecke mit kleinstem Wert}}$$

Da der Koeffizient von $z_0$ rund **sechsmal größer** ist als der von $y_0$, dominiert die
Biegung um die $y_0$-Achse; maßgebend sind die Ecken mit den größten $|z_0|$.

### d) Neutrale Faser

$$\sigma_x=0:\qquad 0{,}850+2{,}029\,z_0+0{,}347\,y_0=0$$

$$\boxed{\;z_0(y_0)=-0{,}419-0{,}171\,y_0\;}$$

**Achsabschnitte für die Skizze:**
* $z_0$-Achsabschnitt: $z_0(0)=-0{,}419$ cm
* $y_0$-Achsabschnitt: $y_0(0)=-2{,}45$ cm

Die neutrale Faser ist eine **Gerade mit der Steigung $-0{,}171$** im $y_0$-$z_0$-System,
also nahezu **parallel zur $y_0$-Achse** und leicht unterhalb des Schwerpunkts.
Sie ist **nicht** parallel zur Momentenachse — das charakteristische Merkmal der
**schiefen Biegung**.

---

## Aufgabe 9 — Schubspannungen und Torsion (17 P.)

Gegeben: $F_1=\sqrt2\cdot150$ kN unter $\alpha=45^\circ$ im Schwerpunkt,
$F_2=200$ kN in $y$-Richtung,
$I_y=1{,}0\cdot10^8$ mm⁴, $I_z=3{,}73\cdot10^7$ mm⁴, $\xi=1{,}31$;
Wanddicken 1 und 2 mm, Abmessungen 100/200/200/100 mm.

### Zerlegung der Kraft $F_1$

$$F_{1y}=F_{1z}=F_1\cos45^\circ=\sqrt2\cdot150\cdot\frac{1}{\sqrt2}=\mathbf{150\ kN}$$

### a) Schubspannungsverlauf $\tau_y$ aus $Q_y$

$$\boxed{\;\tau_y(s)=\frac{Q_y\,S_z(s)}{I_z\,t(s)}\;},\qquad Q_y=150\ \text{kN}$$

**Arbeitsschritte (Skizzen auf Seite 11 beschriften):**

**① y-h-Linie:** Für jedes Wandelement den Abstand $y(s)$ von der $z$-Schwerachse
(multipliziert mit $t$) auftragen.

**② $S_z(s)$:** Umlauf von einem freien Ende:
$$S_z(s)=\int_0^s y(\bar s)\,t(\bar s)\,\mathrm d\bar s$$
* Wände **parallel zur $z$-Achse** (konstantes $y$): $S_z$ **linear**
* Wände **parallel zur $y$-Achse** ($y$ veränderlich): $S_z$ **quadratisch**
* an Knoten: zulaufende Äste addieren

**③ $\tau_y$-Verlauf:** Division durch $I_z\,t$.
$\tau=0$ an freien Enden, Maximum dort, wo $S_z$ maximal ist (in der Nähe der $z$-Achse),
**Sprünge** an den Dickenwechseln $1\to2$ mm (Faktor 2), Schubfluss $T=\tau t$ stetig.

$$\text{Kontrolle:}\quad \int\tau_y\,t\,\mathrm ds=Q_y=150\ \text{kN}$$

### b) Schubspannungsverlauf $\tau_z$ aus $Q_z$

$$\boxed{\;\tau_z(s)=\frac{Q_z\,S_y(s)}{I_y\,t(s)}\;},\qquad Q_z=150\ \text{kN}$$

Analog mit der **z-h-Linie** und $S_y(s)=\int z\,t\,\mathrm d\bar s$.
Maximum in Höhe der neutralen Faser ($y$-Achse).

**Wichtiger Vergleich:** Wegen $I_y=1{,}0\cdot10^8$ mm⁴ gegenüber
$I_z=3{,}73\cdot10^7$ mm⁴ (Faktor 2,7) ist bei gleich großen Querkräften der
$\tau_y$-Anteil deutlich größer — die **schwache Achse** bestimmt die Schubbeanspruchung.

**Gesamtschubspannung** aus $F_1$: vektorielle Überlagerung
$$\tau_{ges}(s)=\tau_y(s)+\tau_z(s)$$
(beide tangential zur Mittellinie, daher skalare Addition mit Vorzeichen).

### c) Torsionsschubspannung aus $F_2$

$F_2=200$ kN greift **im Schwerpunkt** an — nicht im Schubmittelpunkt. Daraus resultiert

$$M_T=F_2\cdot e$$

mit $e$ = Abstand zwischen Schwerpunkt S und Schubmittelpunkt M.

**Offener dünnwandiger Querschnitt:**

$$\boxed{\;I_T=\frac{\xi}{3}\sum_i\ell_i\,t_i^3\;},\qquad \xi=1{,}31$$

$$\tau_T(s)=\frac{M_T}{I_T}\,t(s),\qquad
\tau_{T,\max}=\frac{M_T}{I_T}\,t_{\max}=\frac{M_T}{I_T}\cdot 2\ \text{mm}$$

**Grafische Darstellung (Skizze Seite 13):**
* In **jeder** Wand zwei gegenläufige Pfeilreihen an den beiden Wandrändern
* **null in der Mittellinie**, betragsmäßig maximal an den Rändern
* entlang jedes Segments **konstanter** Betrag
* der Umlaufsinn ist **in allen Wänden gleich** und entspricht dem Drehsinn von $M_T$
* die **dickste Wand** ($t=2$ mm) trägt die doppelte Spannung der dünnen Wände

**Merksatz:** Beim offenen Profil ist $I_T\sim t^3$ und damit sehr klein — die
Torsionsspannungen aus einem kleinen Lastversatz übertreffen die
Querkraftschubspannungen oft um ein Vielfaches. Deshalb ist der Schubmittelpunkt
bei offenen Profilen konstruktiv so wichtig.

---

## Ergebnisübersicht

| Aufgabe | Ergebnis |
|---|---|
| 1a | $I_{\bar y}=I_y+Ad^2$ — nimmt immer zu, Minimum in der Schwerachse |
| 1e | innerhalb: kein Vorzeichenwechsel · außerhalb: neutrale Faser schneidet den Querschnitt |
| 3 | $\Delta\ell_{Feder}=\dfrac{2F\ell}{13EA}$ (Verkürzung) |
| 4 | $\Delta T=-\dfrac{F}{\alpha_TEA}$ (Abkühlung); $u_B=\dfrac{2F\ell}{EA}$ |
| 5a | $\sigma_I=26{,}08$ MPa, $\sigma_{II}=-21{,}08$ MPa, $\varphi_0=61{,}0^\circ$ |
| 5c | $\theta=12{,}96^\circ$ bzw. $-70{,}96^\circ$; $\tau=\pm23{,}45$ MPa |
| 5e | $\Delta T=+13{,}81$ K; $\varepsilon_y=1{,}548\cdot10^{-4}$ |
| 7 | $c=\dfrac{EI_1}{8\ell^3}$; $w(4\ell)=\dfrac{96}{11}\dfrac{q\ell^4}{EI_1}=8{,}73\dfrac{q\ell^4}{EI_1}$ |
| 8a | $I_{y_0}=27{,}89$ cm⁴, $I_{z_0}=40{,}65$ cm⁴ |
| 8b | $N=10$ kN, $M_{y_0}=56{,}6$ kNcm, $M_{z_0}=14{,}1$ kNcm |
| 9 | $F_{1y}=F_{1z}=150$ kN; $I_T=\frac{1{,}31}{3}\sum\ell_it_i^3$ |
