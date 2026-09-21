# Lösungsvorschlag — Modulprüfung Technische Mechanik II, PO 2019
**SoSe 24 · 27. September 2024** · Univ.-Prof. Dr.-Ing. Tim Ricken · ISD Stuttgart · 100 Punkte

---

## Aufgabe 1 — Richtig / Falsch (10 P.)

| Nr. | Aussage | Antwort | Begründung |
|---|---|---|---|
| **1** | E-Modul beschreibt die Fähigkeit, **plastisch** zu verformen | **falsch** | $E$ beschreibt die **elastische** Steifigkeit, $\sigma=E\varepsilon$ im linear-elastischen Bereich |
| **2** | Hooke'sches Gesetz gilt nur im linear-elastischen Bereich | **richtig** | Definitionsgemäß; oberhalb der Proportionalitätsgrenze ungültig |
| **3** | Spannung ist unabhängig von der Kraft | **falsch** | $\sigma=N/A$ — direkt proportional zur Kraft |
| **4** | Positive Poisson-Zahl ⇒ Querdehnung bei Längsdehnung | **falsch** | Bei $\nu>0$ **kontrahiert** das Material quer: $\varepsilon_q=-\nu\varepsilon_l$ |
| **5** | Biegemoment ist überall gleich groß | **falsch** | $M_y(x)$ ist i. A. eine Funktion von $x$; nur bei reiner Biegung konstant |
| **6** | Thermische Dehnung proportional zu $\Delta T$ | **richtig** | $\varepsilon_T=\alpha_T\,\Delta T$ (lineare Näherung) |
| **7** | Schubspannungen bei reiner Zugbelastung | **richtig** | In geneigten Schnitten: $\tau_{\max}=\sigma/2$ bei $45^\circ$ |
| **8** | Mohr-Kreis zeigt Spannungen bei **beliebiger** Belastung | **falsch** | Der Kreis gilt für den Spannungszustand **in einem Punkt** und beschreibt die Spannungen über alle Schnittrichtungen — keine räumliche „Verteilung im Material" |
| **9** | Anzahl RB + ÜB $\ge$ Anzahl Unbekannter | **richtig** | Zur eindeutigen Bestimmung aller Integrationskonstanten erforderlich |
| **10** | Kernfläche = Bereich ohne Versagen bei Normalkraft | **falsch** | Die Kernfläche ist der Bereich, in dem eine Normalkraft **nur gleichsinnige** Spannungen (kein Vorzeichenwechsel) erzeugt — sie sagt nichts über Versagen aus |

**Punktverteilung:** 6× falsch, 4× richtig.

---

## Aufgabe 2 — Bosch-Profil, Flächenträgheitsmomente (12 P.)

Gegeben: $a=20$ mm, $t=2$ mm. Dünnwandige Idealisierung: **zentrales Quadrat** plus
**vier Diagonalstege** unter $45^\circ$.

### a) Berechnung

**Allgemeiner Ansatz:**

$$I_y=\sum_i\left[I_{y,i}^{\text{eigen}}+A_i\bar z_i^{\,2}\right],\qquad
I_z=\sum_i\left[I_{z,i}^{\text{eigen}}+A_i\bar y_i^{\,2}\right]$$

**Für das zentrale Quadrat (Seitenlänge $s$, Wanddicke $t$), dünnwandig:**

* 2 waagerechte Wände: $I_y^{\text{eig}}=2\cdot\dfrac{st^3}{12}\approx0$,
  Steiner: $2\cdot st\left(\dfrac{s}{2}\right)^2=\dfrac{s^3t}{2}$
* 2 senkrechte Wände: $I_y^{\text{eig}}=2\cdot\dfrac{ts^3}{12}=\dfrac{ts^3}{6}$, Steiner $=0$

$$I_y^{\square}=I_z^{\square}=\frac{s^3t}{2}+\frac{ts^3}{6}=\frac{2}{3}s^3t$$

**Für einen Diagonalsteg** (Länge $\ell_d$, Neigung $45^\circ$, Schwerpunkt bei $(\bar y,\bar z)$):

$$I_y^{\text{eig}}=\frac{t\ell_d^3}{12}\sin^2 45^\circ=\frac{t\ell_d^3}{24},\qquad
I_z^{\text{eig}}=\frac{t\ell_d^3}{12}\cos^2 45^\circ=\frac{t\ell_d^3}{24}$$

$$I_y^{\text{diag}}=4\left[\frac{t\ell_d^3}{24}+\ell_dt\,\bar z^{\,2}\right],\qquad
I_z^{\text{diag}}=4\left[\frac{t\ell_d^3}{24}+\ell_dt\,\bar y^{\,2}\right]$$

Wegen der Vierfachsymmetrie gilt für die Diagonalen $|\bar y|=|\bar z|$ und damit

$$\boxed{I_y=I_z=\frac{2}{3}s^3t+4\left[\frac{t\ell_d^3}{24}+\ell_dt\,\bar z^{\,2}\right]}$$

Mit den Maßen der Skizze ($s=a/2=10$ mm, Diagonalen von den Quadratecken nach außen,
$t=2$ mm) einzusetzen. Der Quadratanteil beträgt $\tfrac23\cdot1000\cdot2=1333$ mm⁴ je Achse.

> **Hinweis:** Maßgeblich ist die konsequente Anwendung von Eigen- plus Steiner-Anteil;
> die exakte Diagonallänge ist der Bemaßung ($a$, $a/2$) zu entnehmen.

### b) Sind $I_y$ und $I_z$ Hauptträgheitsmomente?

**Ja.**

Der Querschnitt besitzt **zwei zueinander senkrechte Symmetrieachsen** ($y$ und $z$).
Für jede Teilfläche findet sich eine spiegelbildliche Partnerfläche mit
$\bar y\to-\bar y$ bzw. $\bar z\to-\bar z$, sodass sich alle Steiner-Anteile des
Deviationsmoments paarweise aufheben:

$$I_{yz}=\sum_i A_i\bar y_i\bar z_i=0$$

Ein Achsenpaar mit $I_{yz}=0$ **ist** definitionsgemäß das Hauptachsensystem.
$$\Rightarrow\quad I_y=I_1,\quad I_z=I_2$$

### c) Sind $I_\xi$ und $I_\eta$ unter $45^\circ$ ebenfalls Hauptträgheitsmomente?

**Ja — und zwar mit demselben Zahlenwert.**

Das Profil besitzt **Vierfachsymmetrie** (Drehsymmetrie um $90^\circ$), daher

$$I_y=I_z \quad\text{und}\quad I_{yz}=0$$

Der **Mohr'sche Trägheitskreis entartet dann zu einem Punkt**:

$$R=\sqrt{\left(\frac{I_y-I_z}{2}\right)^2+I_{yz}^2}=\sqrt{0+0}=0$$

Aus der Transformationsformel folgt für **jeden beliebigen** Winkel $\varphi$:

$$I_\xi=\frac{I_y+I_z}{2}+\underbrace{\frac{I_y-I_z}{2}}_{=0}\cos2\varphi
-\underbrace{I_{yz}}_{=0}\sin2\varphi=\frac{I_y+I_z}{2}=I_y$$

$$\boxed{I_\xi=I_\eta=I_y=I_z\quad\text{und}\quad I_{\xi\eta}=0\ \ \forall\varphi}$$

**Jede** Schwerachse ist Hauptachse — das Profil ist **isotrop bezüglich der Biegesteifigkeit**.
Genau das ist der konstruktive Sinn eines Bosch-Profils: gleiche Steifigkeit in alle Richtungen.

---

## Aufgabe 3 — Zugstab, Querkontraktion, Temperatur (6 P.)

Gegeben: $\ell_0$, $r_0$, $E$, $\nu$, $F$, $\alpha_T$; Querschnitt $A_0=\pi r_0^2$.

### a) Längenänderung

Hooke: $\;\sigma=\dfrac{F}{A_0}=\dfrac{F}{\pi r_0^2}$, $\;\varepsilon_x=\dfrac{\sigma}{E}$

$$\boxed{\;\Delta\ell=\varepsilon_x\,\ell_0=\frac{F\,\ell_0}{E\,A_0}=\frac{F\,\ell_0}{E\,\pi r_0^2}\;}$$

**Diagramm $F$ über $\Delta\ell$:** Im linear-elastischen Bereich eine **Ursprungsgerade** mit der
Steigung (= Stabsteifigkeit)

$$k=\frac{\mathrm dF}{\mathrm d(\Delta\ell)}=\frac{EA_0}{\ell_0}=\frac{E\pi r_0^2}{\ell_0}$$

Oberhalb der Proportionalitätsgrenze $F_P$ flacht die Kurve ab (plastischer Bereich) —
im hier betrachteten Bereich ist sie jedoch exakt linear.

### b) Radiusabnahme durch Querkontraktion

$$\varepsilon_r=-\nu\,\varepsilon_x=-\nu\frac{F}{EA_0}$$

$$\boxed{\;\Delta r=\varepsilon_r\,r_0=-\frac{\nu F r_0}{E\pi r_0^2}=-\frac{\nu F}{E\,\pi r_0}\;}$$

Das Minuszeichen kennzeichnet die **Abnahme** des Radius. Der neue Radius ist
$r=r_0\left(1-\dfrac{\nu F}{EA_0}\right)$.

### c) Reine Temperaturerhöhung $\Delta T>0$

Bei **freier, unbehinderter** Dehnung entstehen **keine Spannungen** — der Stab dehnt sich
lediglich in **alle** Richtungen gleichmäßig aus (isotroper Werkstoff):

$$\boxed{\;\Delta\ell_T=\alpha_T\,\Delta T\,\ell_0\;}\qquad
\boxed{\;\Delta r_T=+\alpha_T\,\Delta T\,r_0\;}$$

**Entscheidender Unterschied zu a)/b):** Im Gegensatz zur mechanischen Belastung wächst der
Radius hier **mit** (keine Querkontraktion, da keine Spannung vorliegt). Die Querkontraktionszahl
$\nu$ spielt **keine** Rolle.

Bei **behinderter** Ausdehnung dagegen entstünde die Zwangsspannung
$\sigma=-E\alpha_T\Delta T$ (Druck).

---

## Aufgabe 4 — Thermomechanisches System, Verschiebung von P (6 P.)

Gegeben: $EA$, $EI\to\infty$ (starrer horizontaler Stab), $M=2EA$, $c=\dfrac{EA}{5}$,
$\Delta T>0$, $\alpha_T$; Maße 5 / 6 / 2 [m].

### Lösungsweg

**1. Kinematik:** Der horizontale Stab ist **starr**. Er dreht sich um den Festpunkt;
alle Vertikalverschiebungen sind proportional zum Abstand vom Drehpunkt:

$$\frac{w_1}{a_1}=\frac{w_2}{a_2}=\frac{w_P}{a_P}=\varphi$$

mit den Hebelarmen $a_i$ aus den Maßen 5 / 6 / 2 m.

**2. Elastizitätsgesetz der Einzelelemente:**

* Dehnstab (Fläche $A$, Länge $\ell$, thermisch belastet):
  $$\Delta\ell=\frac{N\ell}{EA}+\alpha_T\Delta T\,\ell$$
* Feder: $\;F_c=c\cdot\Delta_c=\dfrac{EA}{5}\Delta_c$
* Biegestab: $\;w=\dfrac{M\ell^2}{2EI}$ bzw. entsprechende Einflusszahl

**3. Gleichgewicht** am starren Stab — Momentengleichgewicht um den Drehpunkt:

$$\sum M=0:\qquad N\cdot a_N + F_c\cdot a_c - M = 0$$

**4. Auflösen:** Die Kinematik verknüpft $\Delta\ell$ und $\Delta_c$ über $\varphi$;
zusammen mit dem Gleichgewicht ergibt sich ein lineares Gleichungssystem für $N$, $F_c$
und $\varphi$.

$$\boxed{\;w_P=\varphi\cdot a_P=\underbrace{w_P^{(M)}}_{\text{aus }M=2EA}
+\underbrace{w_P^{(T)}}_{\text{aus }\alpha_T\Delta T}\;}$$

**Superpositionsprinzip:** Die Lösung zerfällt sauber in einen **mechanischen** Anteil
(aus $M$) und einen **thermischen** Anteil (aus $\Delta T$), die addiert werden.

**Charakteristik der Lösung:**
* Der thermische Anteil ist **proportional zu $\alpha_T\Delta T$** und unabhängig von $M$.
* Der mechanische Anteil ist proportional zu $M/(EA)$; mit $M=2EA$ ist er
  **unabhängig von der Steifigkeit** — ein typischer Klausurtrick, der zu einer
  reinen Zahlenlösung führt.
* Die Feder mit $c=EA/5$ ist **fünfmal nachgiebiger** als ein Dehnstab der Länge $1$ m
  und bestimmt damit maßgeblich die Verschiebung.

---

## Aufgabe 5 — Biegelinien $w_1,w_2,w_3$ (22 P.)

Gegeben: $\ell$, $EA=\dfrac{EI}{\ell^2}$, $EI$, $EI_2\to\infty$, $F$.
Drei Bereiche der Länge $\ell$; ein Teil ist **biegestarr**, zwei Dehnstäbe wirken als Federn.

### Schritt 1 — Dehnstäbe durch Ersatzfedern ersetzen

$$c=\frac{EA}{\ell}=\frac{EI/\ell^2}{\ell}=\frac{EI}{\ell^3}$$

Die dimensionslose Federsteifigkeit ist also $\dfrac{c\ell^3}{EI}=1$ — Feder und Balken sind
**gleich steif**, die Last verteilt sich in vergleichbaren Anteilen.

### Schritt 2 — Differentialgleichungen

$$EI\,w_i''''(x_i)=0\qquad (i=1,2,3;\ \text{nur Einzelkraft }F)$$

$$EI\,w_i(x_i)=\frac{C_{i1}}{6}x_i^3+\frac{C_{i2}}{2}x_i^2+C_{i3}x_i+C_{i4}$$

**12 Konstanten ⇒ 12 Bedingungen.**

Für den **biegestarren Bereich** ($EI_2\to\infty$) gilt $w''=0$: die Biegelinie ist dort
eine **Gerade**, was zwei Konstanten sofort eliminiert:

$$w_2(x_2)=w_2(0)+w_2'(0)\cdot x_2$$

### Schritt 3 — Rand- und Übergangsbedingungen

| # | Bedingung | Bedeutung |
|---|---|---|
| 1 | $w_1(0)=0$ | Lager |
| 2 | $EIw_1''(0)=0$ | gelenkiges Lager ⇒ $M=0$ |
| 3–5 | $w_1(\ell)=w_2(0)$, $w_1'(\ell)=w_2'(0)$, $M_1(\ell)=M_2(0)$ | Übergang 1→2 |
| 6 | $Q_1(\ell)=Q_2(0)+F_{\text{Feder},1}$ | Federkraft als Querkraftsprung |
| 7–9 | $w_2(\ell)=w_3(0)$, $w_2'(\ell)=w_3'(0)$, $M_2(\ell)=M_3(0)$ | Übergang 2→3 |
| 10 | $Q_2(\ell)=Q_3(0)+F_{\text{Feder},2}$ | zweite Feder |
| 11 | $M_3(\ell)=0$ | freies Ende |
| 12 | $Q_3(\ell)=-F$ | Einzelkraft am Ende |

mit $F_{\text{Feder},k}=c\cdot w(\text{Federpunkt}_k)=\dfrac{EI}{\ell^3}w_k$

### Schritt 4 — Auswertung

Die Schnittgrößen folgen aus $M_y=-EIw''$ und $Q_z=-EIw'''$.
Da $EI_2\to\infty$, ist $M_2$ zwar endlich, aber die **Krümmung** dort null — der starre
Bereich überträgt Moment ohne sich zu verformen und wirkt wie ein starrer Hebel zwischen
den beiden elastischen Bereichen.

**Kontrollen:**
* $w_1(0)=0$ und $M(0)=0$ am gelenkigen Lager,
* $w_2$ ist eine **Gerade** (Test: $w_2''\equiv0$),
* Summe aller Vertikalkräfte: $\sum F_{\text{Feder}}+A=F$,
* Für $c\to\infty$ müssen die Federpunkte zu starren Lagern werden.

---

## Aufgabe 6 — Querschnittswerte, Kernfläche, Biegespannung (15 P.)

Gegeben: $F_1=1$ kN, $F_2=200$ kN, $A=173{,}14$ mm²;
System: Träger zwischen A und B, Felder 6 m und 3 m;
Querschnitt: dünnwandig, Schwerpunkt S mit $z$-Randabständen $13{,}47$ mm (oben) und
$6{,}53$ mm (unten), Wanddicken 1 und 2 mm, Breite $15+5+20+5+15=60$ mm, Höhe $20$ mm.

### a) Hauptträgheitsmomente

Der Querschnitt ist **symmetrisch zur $z$-Achse** ⇒ $I_{yz}=0$ ⇒ $y,z$ sind bereits
**Hauptachsen**, $\varphi^*=0$.

$$I_y=\sum_i\left[\frac{b_it_i^3}{12}+A_i(z_i-z_S)^2\right],\qquad
I_z=\sum_i\left[\frac{t_ib_i^3}{12}+A_iy_i^2\right]$$

Mit den Randabständen $e_o=13{,}47$ mm, $e_u=6{,}53$ mm (Summe $=20$ mm = Bauhöhe ✓)
sind die Steiner-Anteile zu bilden. Die Trägheitsradien:

$$i_y^2=\frac{I_y}{A},\qquad i_z^2=\frac{I_z}{A},\qquad A=173{,}14\ \text{mm}^2$$

### b) Kernfläche

$$k_{z,o}=\frac{i_y^2}{e_u}=\frac{I_y}{A\cdot6{,}53},\qquad
k_{z,u}=\frac{i_y^2}{e_o}=\frac{I_y}{A\cdot13{,}47},\qquad
k_y=\pm\frac{i_z^2}{30}=\pm\frac{I_z}{A\cdot30}$$

**Skizze:** Konvexes Polygon um S. Wegen $e_o\gg e_u$ ist die Kernfläche **nach unten
verschoben** und in $z$-Richtung stark unsymmetrisch; wegen der großen Breite (60 mm
gegenüber 20 mm Höhe) ist sie in $y$-Richtung sehr schlank.

**Merkregel:** Großer Randabstand ⇒ kleiner Kernpunkt auf der **gegenüberliegenden** Seite.

### c) Biegenormalspannung am Auflager B

**Schnittgrößen:** $F_2=200$ kN wirkt als Normalkraft (200-mal größer als $F_1$!),
$F_1=1$ kN erzeugt die Biegung.

$$N=-F_2=-200\ \text{kN},\qquad M_y^{(B)}=F_1\cdot 3\ \text{m}=3\ \text{kNm}$$

*(Bei durchlaufendem Träger über beide Felder ist $M_y$ am Zwischenauflager aus dem
Dreimomentensatz bzw. der Auflagerreaktion zu bestimmen.)*

$$\boxed{\;\sigma_x(z)=\frac{N}{A}+\frac{M_y}{I_y}\,z\;}$$

Grundspannung aus $N$:

$$\frac{N}{A}=\frac{-200\,000\ \text{N}}{173{,}14\ \text{mm}^2}=\mathbf{-1155\ \tfrac{N}{mm^2}}$$

Das ist bereits **weit über jeder zulässigen Stahlspannung** — der Querschnitt ist für
$F_2=200$ kN drastisch unterdimensioniert. Die Biegung aus $F_1$ ist demgegenüber ein
kleiner Zusatzeffekt, der die Spannung auf der einen Seite erhöht, auf der anderen
vermindert.

**Verlauf:** linear über die Höhe, Nullpunkt bei
$z_0=-\dfrac{N\,I_y}{A\,M_y}$ — liegt bei diesem Kräfteverhältnis **weit außerhalb**
des Querschnitts, d. h. der gesamte Querschnitt steht unter **Druck**.
Damit liegt der Kraftangriffspunkt **innerhalb der Kernfläche** — konsistent mit b).

---

## Aufgabe 7 — Mohr'scher Spannungskreis (13 P.)

Gegeben: Spannungen an zwei Kanten der Scheibe ($60$, $50$, $25$, $45$ N/mm²),
gesuchter Winkel $\alpha$.

### a) Fehlende Komponenten graphisch

1. Jede Kante liefert einen **Bildpunkt** $(\sigma\,|\,\tau)$ im Mohr-Diagramm.
2. Zwei **senkrecht zueinander** stehende Schnittflächen liegen im Mohr-Kreis
   **diametral gegenüber** (Winkelverdopplung: $90^\circ\to180^\circ$).
3. Damit: Mittelpunkt $\sigma_M=\dfrac{\sigma_1+\sigma_2}{2}$ = Mittelwert der beiden
   Normalspannungen; Radius aus dem bekannten Punktabstand.

$$\sigma_M=\frac{\sigma_x+\sigma_y}{2},\qquad
R=\sqrt{\left(\frac{\sigma_x-\sigma_y}{2}\right)^2+\tau_{xy}^2}$$

Die fehlenden Komponenten werden auf dem Kreis abgegriffen und **richtungsrichtig**
(Pfeilsinn!) in die Skizze eingetragen.

### b) Winkel $\alpha$

$\alpha$ ist der Winkel des gedrehten Koordinatensystems gegenüber $(x,y)$.
Im Mohr-Kreis erscheint er als $2\alpha$:

$$\boxed{\;\alpha=\frac{1}{2}\arctan\frac{2\tau_{xy}}{\sigma_x-\sigma_y}\;}$$

**Wichtig:** Drehsinn im Mohr-Kreis und in der Realität sind **gleichsinnig**, der Winkel
im Kreis aber **doppelt so groß**. Das gedrehte System $(\xi,\eta)$ ist um $\alpha$ gegen
$(x,y)$ geneigt einzuzeichnen.

### c) Hauptnormalspannungen

$$\boxed{\;\sigma_{I,II}=\sigma_M\pm R\;}$$

$$\tan2\varphi_0=\frac{2\tau_{xy}}{\sigma_x-\sigma_y}
\quad\Rightarrow\quad \varphi_0,\ \varphi_0+90^\circ$$

Das **Hauptachsensystem** ist schubspannungsfrei; im Mohr-Kreis sind es die beiden
Schnittpunkte mit der $\sigma$-Achse. In die Skizze sind zwei senkrecht zueinander
stehende Achsen unter $\varphi_0$ einzuzeichnen, mit $\sigma_I$ (größte) und $\sigma_{II}$.

### d) Vergleichsspannungen

**Schubspannungshypothese (Tresca):**

$$\boxed{\;\sigma_{V,SH}=\sigma_I-\sigma_{II}=2R\;}$$

**Gestaltänderungshypothese (von Mises):**

$$\boxed{\;\sigma_{V,vM}=\sqrt{\sigma_I^2-\sigma_I\sigma_{II}+\sigma_{II}^2}
=\sqrt{\sigma_x^2-\sigma_x\sigma_y+\sigma_y^2+3\tau_{xy}^2}\;}$$

**Vergleich:** Es gilt stets $\sigma_{V,vM}\le\sigma_{V,SH}$ — Tresca ist die
**konservativere** Hypothese (Verhältnis bis zu $2/\sqrt3=1{,}155$ bei reinem Schub).
Für zähe Werkstoffe wie Stahl ist von Mises die realitätsnähere Hypothese.

---

## Aufgabe 8 — Schub, Schubmittelpunkt, Torsion (16 P.)

Gegeben: $F=900$ N, $I_y=12\,000$ mm⁴, $I_z=22\,381$ mm⁴, $\xi=1{,}06$,
Wanddicken 2 und 3 mm, Maße $20$ mm, $21{,}196$ mm, $\alpha=30^\circ$.

### a) Schubspannungsverlauf aus Querkraft

$$\boxed{\;\tau_F(s)=\frac{Q_z\,S_y(s)}{I_y\,t(s)}\;},\qquad Q_z=F=900\ \text{N}$$

**Drei Arbeitsschritte (die Skizzen entsprechend beschriften):**

**① z-Ordinate:** Für jedes Wandsegment den Abstand $z(s)$ von der Schwerachse auftragen.
Bei geneigten Wänden ($\alpha=30^\circ$) gilt $z(s)=z_0+s\sin\alpha$.

**② Statisches Moment $S_y(s)$:** Umlauf **von einem freien Ende** aus:

$$S_y(s)=\int_0^s z(\bar s)\,t(\bar s)\,\mathrm d\bar s$$

* in Wänden **parallel** zur $y$-Achse: $S_y$ **linear**
* in **geneigten/senkrechten** Wänden: $S_y$ **quadratisch (Parabel)**
* am Knoten: Beiträge der zulaufenden Äste **addieren**

**③ $\tau_F$-Verlauf:** Division durch $I_yt$.
An Dickenwechseln $2\to3$ mm **springt** $\tau$ im Verhältnis $3:2$ nach unten,
der Schubfluss $T=\tau t$ bleibt stetig.

**Maximum** in Höhe der neutralen Faser (dort $S_y$ maximal), **Null** an allen freien Enden.
**Kontrolle:** $\displaystyle\int \tau_F\,t\,\mathrm ds=Q_z=900$ N.

### b) Lage des Schubmittelpunkts

**Teilschubkräfte** je Segment $k$ (Simpson-Regel gemäß Aufgabenhinweis):

$$T_k=\int_0^{\ell_k}\tau(s)\,t\,\mathrm ds
\;\approx\;\frac{\ell_k}{6}\bigl(a+4b+c\bigr)\cdot t$$

mit $a,b,c$ = $\tau$-Werte am Anfang, in der Mitte und am Ende des Segments.

**Momentengleichgewicht** um einen beliebigen Bezugspunkt $P$:

$$\boxed{\;Q_z\cdot e_y=\sum_k T_k\cdot r_k\;}$$

$r_k$ = senkrechter Abstand der Wirkungslinie von $T_k$ zum Bezugspunkt.

$$\Rightarrow\quad e_y=\frac{\sum_k T_k\,r_k}{Q_z}$$

**Kontrolle:** Der Schubmittelpunkt liegt stets auf einer vorhandenen **Symmetrieachse**.
Bei offenen Profilen liegt er **außerhalb** der Querschnittsfläche — typischerweise
auf der dem Steg abgewandten Seite.

### c) Schubspannung aus reiner Torsion

Offener dünnwandiger Querschnitt ⇒ Theorie des schmalen Rechtecks mit Korrekturfaktor $\xi=1{,}06$:

$$\boxed{\;I_T=\frac{\xi}{3}\sum_i \ell_i\,t_i^3\;}$$

$$\tau_T(s)=\frac{M_T}{I_T}\,t(s)$$

**Verlauf:**
* über die **Wanddicke linear antimetrisch**: null in der Mittellinie, betragsmäßig maximal
  an beiden Wandrändern mit **entgegengesetztem Vorzeichen**
* entlang der Mittellinie **konstant** innerhalb eines Segments konstanter Dicke
* **größter Wert in der dicksten Wand** ($t=3$ mm)

In der Skizze: In jeder Wand zwei gegenläufige Pfeilreihen an den Rändern, die insgesamt
einen geschlossenen Umlaufsinn ergeben.

### d) Maximale Torsionsschubspannung bei Angriff im Schwerpunkt

Greift $F$ im **Schwerpunkt** an (nicht im Schubmittelpunkt!), entsteht das Torsionsmoment

$$M_T=F\cdot e_{SM}$$

mit $e_{SM}$ = Abstand zwischen **Schwerpunkt und Schubmittelpunkt** aus Teil b).

$$\boxed{\;\tau_{T,\max}=\frac{M_T}{I_T}\,t_{\max}
=\frac{F\,e_{SM}}{\frac{\xi}{3}\sum \ell_it_i^3}\cdot t_{\max}\;}$$

mit $t_{\max}=3$ mm.

**Wesentliche Erkenntnis:** Bei offenen dünnwandigen Profilen ist $I_T$ **extrem klein**
($\sim t^3$), weshalb schon ein geringer Versatz $e_{SM}$ sehr große Torsionsspannungen
erzeugt — oft ein Vielfaches der Querkraftschubspannung. Deshalb greift man bei offenen
Profilen die Last möglichst **im Schubmittelpunkt** an.

---

## Ergebnisübersicht

| Aufgabe | Ergebnis |
|---|---|
| 1 | F, R, F, F, F, R, R, F, R, F |
| 2b | Ja — zwei Symmetrieachsen ⇒ $I_{yz}=0$ |
| 2c | **Ja** — wegen $I_y=I_z$, $I_{yz}=0$ ist **jede** Achse Hauptachse ($R=0$) |
| 3a | $\Delta\ell=\frac{F\ell_0}{E\pi r_0^2}$, Gerade mit Steigung $EA_0/\ell_0$ |
| 3b | $\Delta r=-\frac{\nu F}{E\pi r_0}$ |
| 3c | $\Delta\ell_T=\alpha_T\Delta T\ell_0$, $\Delta r_T=+\alpha_T\Delta T\,r_0$, **spannungsfrei** |
| 5 | Ersatzfeder $c=EI/\ell^3$; starrer Bereich ⇒ $w_2$ linear |
| 6c | $N/A=-1155$ N/mm² — Querschnitt stark überlastet |
| 7d | $\sigma_{V,SH}=2R$, $\sigma_{V,vM}=\sqrt{\sigma_I^2-\sigma_I\sigma_{II}+\sigma_{II}^2}$ |
| 8c | $I_T=\frac{\xi}{3}\sum\ell_it_i^3$ mit $\xi=1{,}06$ |
