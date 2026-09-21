# Lösungsvorschlag — Modulprüfung Technische Mechanik II, PO 2019
**SoSe 25 · 26. September 2025** · Univ.-Prof. Dr.-Ing. Tim Ricken · ISD Stuttgart · 100 Punkte

---

## Aufgabe 1 — Theorie (12 P.)

### a) Querschnitt konstruktiv optimieren (Biegesteifigkeit um die $x$-Achse)

Gegeben ist ein **liegendes flaches Rechteck** — der denkbar ungünstigste Querschnitt für
Biegung um die $x$-Achse, da $I_x\sim h^3$ und die Bauhöhe minimal ist.

**Optimierungsmaßnahmen (Leichtbau: mehr Steifigkeit bei gleicher Fläche):**

1. **Material nach außen verlagern** → Aufkanten der Ränder zu einem **I-, Kasten- oder
   C-Profil**. Die Gurte übernehmen die Normalspannungen, ein dünner Steg nur den Schub.
2. **Bauhöhe $h$ vergrößern**, Wanddicken reduzieren — $I$ wächst mit $h^3$, die Masse nur
   linear mit $h$.
3. **Sicken / Abkantungen** einbringen, wenn die Bauhöhe begrenzt ist.

$$\text{Zeichnung: Rechteck}\;\longrightarrow\;\text{I-Profil / Kastenprofil gleicher Fläche}$$

**Kernaussage des Leichtbaus:** Material in der neutralen Faser trägt nichts zur
Biegesteifigkeit bei — es gehört an den Rand.

### b) Kinematische Beziehung und Stoffgesetz (1D)

$$\text{Kinematik:}\qquad \varepsilon(x)=\frac{\mathrm du(x)}{\mathrm dx}=u'(x)$$

$$\text{Stoffgesetz (linear-elastisch, Hooke):}\qquad \sigma=E\,\varepsilon$$

Mit Temperaturanteil allgemein:
$$\varepsilon=\frac{\sigma}{E}+\alpha_T\Delta T
\quad\Longleftrightarrow\quad
\sigma=E\left(\varepsilon-\alpha_T\Delta T\right)$$

### c) Tensoren im zweidimensionalen Fall

$$\text{Allgemeiner Spannungstensor:}\quad
\boldsymbol\sigma=\begin{bmatrix}\sigma_x & \tau_{xy}\\ \tau_{xy} & \sigma_y\end{bmatrix}$$

$$\text{Hauptspannungstensor:}\quad
\boldsymbol\sigma^*=\begin{bmatrix}\sigma_I & 0\\ 0 & \sigma_{II}\end{bmatrix}
\qquad(\text{schubspannungsfrei, Diagonalform})$$

$$\text{Verzerrungstensor:}\quad
\boldsymbol\varepsilon=\begin{bmatrix}\varepsilon_x & \tfrac{1}{2}\gamma_{xy}\\[2pt]
\tfrac{1}{2}\gamma_{xy} & \varepsilon_y\end{bmatrix}$$

**Wichtig:** Im Verzerrungstensor steht die **halbe** Gleitung $\gamma_{xy}/2$ — nur so ist
$\boldsymbol\varepsilon$ ein echter Tensor und der Mohr'sche Kreis anwendbar.

### d) Spannungen im Balken unter Biegung

* **Biegenormalspannungen** $\sigma_x=\dfrac{M_y}{I_y}z$ — linear über die Höhe
* **Schubspannungen** $\tau_{xz}=\dfrac{Q_zS_y}{I_yt}$ aus der Querkraft — parabolisch
* bei zusätzlicher Normalkraft: $\dfrac{N}{A}$ (konstanter Anteil)
* bei Torsion: $\tau_T$ aus $M_T$

Bei **reiner** Biegung ($Q=0$) treten ausschließlich $\sigma_x$ auf.
$\sigma_y$ und $\sigma_z$ werden in der technischen Balkentheorie zu null gesetzt.

### e) Spannungselemente

| Lastfall | Eintrag am Element |
|---|---|
| **1-axialer Zug** | $\sigma_x>0$, Pfeile **aus** beiden $x$-Flächen heraus; $\sigma_y=\tau=0$ |
| **1-axialer Druck** | $\sigma_x<0$, Pfeile **auf** beide $x$-Flächen zu; $\sigma_y=\tau=0$ |
| **Reine Torsion** | nur $\tau_{xy}=\tau_{yx}$ tangential an allen vier Flächen, paarweise umlaufend; $\sigma_x=\sigma_y=0$ |

Bei reiner Torsion liegen die Hauptspannungen unter $45^\circ$ mit
$\sigma_{I,II}=\pm\tau$ — deshalb versagen spröde Wellen unter Torsion in einer
$45^\circ$-Schraubenfläche.

---

## Aufgabe 2 — Dünnwandiger Querschnitt aus drei Stäben (10 P.)

Gegeben: $t=2$ mm; Stab **A** horizontal (20 mm, links unten), Stab **B** vertikal (25 mm),
Stab **C** horizontal (20 mm, rechts oben). Bezug: $z$ von der Oberkante (Mittellinie C)
nach unten, $y$ nach rechts; die Mittellinie von B liegt bei $y=0$.

### Teilflächen

| Stab | $\ell_i$ | $A_i=\ell_it$ | $y_i$ | $z_i$ |
|---|---|---|---|---|
| A (horizontal, unten) | 20 mm | 40 mm² | $-10$ mm | $20$ mm |
| B (vertikal) | 25 mm | 50 mm² | $0$ | $12{,}5$ mm |
| C (horizontal, oben) | 20 mm | 40 mm² | $+10$ mm | $0$ mm |
| **Σ** | | **130 mm²** | | |

### a) Schwerpunktlage

$$z_S=\frac{\sum A_iz_i}{\sum A_i}=\frac{40\cdot20+50\cdot12{,}5+40\cdot0}{130}
=\frac{800+625}{130}=\boxed{10{,}96\ \text{mm}}$$

$$y_S=\frac{40\cdot(-10)+50\cdot0+40\cdot10}{130}=\boxed{0\ \text{mm}}$$

*(gemessen von der Mittellinie des oberen Gurtes C nach unten bzw. von der Stegmittellinie)*

### b) Flächenträgheitsmomente

| (in mm⁴) | **A** | **B** | **C** |
|---|---|---|---|
| $I_{y,i}$ | $\frac{20\cdot2^3}{12}=13{,}3$ | $\frac{2\cdot25^3}{12}=2604{,}2$ | $\frac{20\cdot2^3}{12}=13{,}3$ |
| $I_{y,i}^{\text{Steiner}}$ | $40\cdot(20-10{,}96)^2=3268{,}6$ | $50\cdot(12{,}5-10{,}96)^2=118{,}6$ | $40\cdot(0-10{,}96)^2=4805{,}3$ |
| $I_{z,i}$ | $\frac{2\cdot20^3}{12}=1333{,}3$ | $\frac{25\cdot2^3}{12}=16{,}7$ | $\frac{2\cdot20^3}{12}=1333{,}3$ |
| $I_{z,i}^{\text{Steiner}}$ | $40\cdot(-10)^2=4000$ | $50\cdot0^2=0$ | $40\cdot10^2=4000$ |
| $I_{yz,i}$ | $0$ | $0$ | $0$ |
| $I_{yz,i}^{\text{Steiner}}$ | $40\cdot(-10)(9{,}04)=-3615{,}4$ | $50\cdot0\cdot1{,}54=0$ | $40\cdot(10)(-10{,}96)=-4384{,}6$ |

$$\boxed{I_y=10\,823\ \text{mm}^4,\qquad
I_z=10\,683\ \text{mm}^4,\qquad
I_{yz}=-8000\ \text{mm}^4}$$

> **Hinweis:** $I_{yz,i}^{\text{eigen}}=0$ für jedes achsparallele Rechteck — es bleiben
> nur die Steiner-Anteile. Der große negative Wert entsteht, weil A und C **diagonal
> versetzt** zum Schwerpunkt liegen (beide im 2. bzw. 4. Quadranten).

### c) Hauptachsen

$$\tan 2\varphi^*=\frac{2I_{yz}}{I_y-I_z}=\frac{2\cdot(-8000)}{10\,823-10\,683}
=\frac{-16\,000}{140}=-114{,}2$$

$$2\varphi^*=-89{,}50^\circ\qquad\Rightarrow\qquad \boxed{\varphi^*=-44{,}75^\circ}$$

**Hauptträgheitsmomente:**

$$I_{1,2}=\frac{I_y+I_z}{2}\pm\sqrt{\left(\frac{I_y-I_z}{2}\right)^2+I_{yz}^2}
=10\,753\pm\sqrt{70^2+8000^2}=10\,753\pm8000$$

$$\boxed{I_1=18\,754\ \text{mm}^4,\qquad I_2=2753\ \text{mm}^4}$$

**Interpretation:** Da $I_y\approx I_z$, aber $I_{yz}$ sehr groß ist, liegen die Hauptachsen
praktisch exakt unter $\mp45^\circ$ — typisch für Z-förmige Querschnitte. Die
Hauptträgheitsmomente unterscheiden sich um den Faktor 7, obwohl $I_y$ und $I_z$ fast
gleich sind: Ein Rechnen mit $I_y,I_z$ statt mit den Hauptachsen wäre hier **grob falsch**.

---

## Aufgabe 3 — Koaxiale Rohre, Kraftaufteilung (4 P.)

Beide Rohre stehen auf einem starren Fundament und werden über eine **starre Platte**
gemeinsam belastet ⇒ **Parallelschaltung**, gleiche Länge $\ell$.

**Kinematik (Verträglichkeit):**
$$\Delta\ell_1=\Delta\ell_2
\quad\Longrightarrow\quad \frac{F_1\ell}{E_1A_1}=\frac{F_2\ell}{E_2A_2}
\quad\Longrightarrow\quad \frac{F_1}{F_2}=\frac{E_1A_1}{E_2A_2}$$

**Gleichgewicht:**
$$F_1+F_2=F$$

**Auflösen:**

$$\boxed{\;F_1=F\,\frac{E_1A_1}{E_1A_1+E_2A_2}\;,\qquad
F_2=F\,\frac{E_2A_2}{E_1A_1+E_2A_2}\;}$$

**Interpretation:** Die Last verteilt sich **im Verhältnis der Dehnsteifigkeiten** $EA$.
Das steifere Rohr trägt den größeren Anteil. Die Spannungen sind
$\sigma_i=\dfrac{F_i}{A_i}=\dfrac{FE_i}{E_1A_1+E_2A_2}$ — sie verhalten sich wie die
E-Moduln, unabhängig von den Flächen.

*(Die ungehinderte radiale Ausdehnung stellt sicher, dass kein Pressverband und damit
kein mehrachsiger Spannungszustand entsteht.)*

---

## Aufgabe 4 — E-Modul aus Zugversuch mit Temperatur (6 P.)

Gegeben: $\ell_0=500$ mm, $\Delta\ell=1{,}5$ mm, $d_0=10$ mm, $F=50$ kN,
$\alpha_T=12\cdot10^{-6}$ K⁻¹, $\Delta T=30$ K

### a) Zugspannung

$$A_0=\frac{\pi d_0^2}{4}=\frac{\pi\cdot100}{4}=78{,}54\ \text{mm}^2$$

$$\boxed{\;\sigma=\frac{F}{A_0}=\frac{50\,000\ \text{N}}{78{,}54\ \text{mm}^2}
=636{,}6\ \frac{\text{N}}{\text{mm}^2}\;}$$

### b) Elastizitätsmodul

**Entscheidender Punkt:** Die gemessene Verlängerung enthält **beide** Anteile —
den mechanischen und den thermischen. Nur der mechanische Anteil gehört ins Hooke'sche Gesetz.

$$\varepsilon_{ges}=\frac{\Delta\ell}{\ell_0}=\frac{1{,}5}{500}=3{,}000\cdot10^{-3}$$

$$\varepsilon_T=\alpha_T\,\Delta T=12\cdot10^{-6}\cdot30=3{,}600\cdot10^{-4}$$

$$\varepsilon_{mech}=\varepsilon_{ges}-\varepsilon_T=3{,}000\cdot10^{-3}-0{,}360\cdot10^{-3}
=2{,}640\cdot10^{-3}$$

$$\boxed{\;E=\frac{\sigma}{\varepsilon_{mech}}=\frac{636{,}6}{2{,}640\cdot10^{-3}}
=241\,144\ \frac{\text{N}}{\text{mm}^2}\approx 241\ \text{GPa}\;}$$

**Plausibilität:** Der Wert liegt im Bereich von Stahl ($\approx210$ GPa) — leicht darüber,
was auf einen hochfesten Stahl hindeutet.

**Kontrolle (typischer Fehler):** Ohne Abzug des thermischen Anteils ergäbe sich
$E=636{,}6/3{,}0\cdot10^{-3}=212$ GPa — ein Fehler von 12 %.

---

## Aufgabe 5 — Verbundwerkstoffprobe, ebener Spannungszustand (13 P.)

Gegeben: $E=2{,}1\cdot10^5$ N/mm², $\nu=0{,}33$, $\alpha=30^\circ$, $\beta=80^\circ$,
$p=150$ bar, $\varepsilon_x=1{,}21\cdot10^{-4}$

### a) Normalspannungen und Mohr-Kreis

Der Druck $p$ wirkt in $y$-Richtung als **Druckspannung**:

$$\sigma_y=-p=-150\ \text{bar}=-150\cdot10^{-1}\ \text{MPa}=\boxed{-15\ \frac{\text{N}}{\text{mm}^2}}$$

Aus dem Hooke'schen Gesetz für den **ebenen Spannungszustand** in $x$-Richtung:

$$\varepsilon_x=\frac{1}{E}\left(\sigma_x-\nu\sigma_y\right)
\quad\Longrightarrow\quad \sigma_x=E\,\varepsilon_x+\nu\,\sigma_y$$

$$\sigma_x=2{,}1\cdot10^5\cdot1{,}21\cdot10^{-4}+0{,}33\cdot(-15)
=25{,}41-4{,}95=\boxed{20{,}46\ \frac{\text{N}}{\text{mm}^2}}$$

**Mohr'scher Spannungskreis:** Da keine Schubspannung wirkt ($\tau_{xy}=0$), sind $x$ und $y$
bereits **Hauptrichtungen**:

$$\sigma_M=\frac{\sigma_x+\sigma_y}{2}=\frac{20{,}46-15}{2}=2{,}73\ \frac{\text{N}}{\text{mm}^2}$$
$$R=\frac{\sigma_x-\sigma_y}{2}=\frac{20{,}46+15}{2}=17{,}73\ \frac{\text{N}}{\text{mm}^2}$$

$$\boxed{\sigma_I=20{,}46\ \tfrac{\text{N}}{\text{mm}^2}\ (\varphi=0^\circ),\qquad
\sigma_{II}=-15\ \tfrac{\text{N}}{\text{mm}^2}\ (\varphi=90^\circ)}$$
$$\tau_{\max}=R=17{,}73\ \frac{\text{N}}{\text{mm}^2}$$

Der Kreis hat den Mittelpunkt $(2{,}73\,|\,0)$ und den Radius $17{,}73$; die Bildpunkte der
$x$- und $y$-Fläche liegen auf der $\sigma$-Achse (diametral gegenüber).

### b) Spannungen in den Fasern A und B

Transformationsformeln mit $\tau_{xy}=0$, Schnittnormale unter dem Winkel $\theta$ zur $x$-Achse:

$$\sigma_\theta=\sigma_M+R\cos2\theta,\qquad \tau_\theta=-R\sin2\theta$$

**Faser A** ($\alpha=30^\circ$ ⇒ Schnittnormale unter $\theta_A=30^\circ$):

$$\sigma_A=2{,}73+17{,}73\cos60^\circ=2{,}73+8{,}87=\boxed{+11{,}60\ \tfrac{\text{N}}{\text{mm}^2}}$$
$$\tau_A=-17{,}73\sin60^\circ=\boxed{-15{,}35\ \tfrac{\text{N}}{\text{mm}^2}}$$

**Faser B** ($\beta=80^\circ$ ⇒ $\theta_B=80^\circ$):

$$\sigma_B=2{,}73+17{,}73\cos160^\circ=2{,}73-16{,}66=\boxed{-13{,}93\ \tfrac{\text{N}}{\text{mm}^2}}$$
$$\tau_B=-17{,}73\sin160^\circ=\boxed{-6{,}06\ \tfrac{\text{N}}{\text{mm}^2}}$$

**Interpretation:** Faser A steht unter **Zug** mit hoher Schubbeanspruchung, Faser B unter
**Druck**. Für einen faserverstärkten Verbund ist das entscheidend — Fasern tragen Zug gut,
Schub und Druck deutlich schlechter.

### c) Winkel für maximale Schubspannung

$$\tau_\theta=-R\sin2\theta \quad\Rightarrow\quad |\tau|_{\max}\ \text{für}\ \sin2\theta=\pm1$$

$$2\theta=90^\circ\quad\Longrightarrow\quad\boxed{\alpha=\beta=45^\circ}$$

(gleichwertig: $135^\circ$)

**Begründung:** Da $x,y$ Hauptachsen sind, treten die Hauptschubspannungen stets unter
$45^\circ$ zu den Hauptachsen auf — im Mohr-Kreis entspricht das der Drehung um $2\theta=90^\circ$
vom Hauptpunkt zum Scheitelpunkt. Der Wert beträgt dann
$\tau_{\max}=R=17{,}73$ N/mm².

---

## Aufgabe 6 — Statische Bestimmtheit und Biegelinien (23 P.)

Gegeben: $\ell$, $q_0$, $EA=\dfrac{EI}{\ell^2}$, $EI$, $EA_1=EA_2\to\infty$,
$c_F=\dfrac{EI}{\ell^3}$

### a) Statische Bestimmtheit

$$n=a+z-3\,p$$

mit $a$ = Auflagerreaktionen, $z$ = Zwischenreaktionen, $p$ = Anzahl der Scheiben.

* Lager A und B sowie die Feder C liefern die Auflagerwertigkeiten,
* die biegesteifen Ecken übertragen je 3 Zwischenreaktionen.

Ergebnis: $n>0$ ⇒ das System ist **$n$-fach statisch unbestimmt**. Die Federkraft in C
eignet sich als statisch Überzählige. Die Lösung über die Biegedifferentialgleichung
funktioniert dennoch direkt, weil die Federbedingung $Q=-c_Fw$ als zusätzliche
**Randbedingung** eingeht.

### b) Biegelinien $w_1,w_2,w_3$

$$EI\,w_1''''=q_0,\qquad EI\,w_2''''=0,\qquad EI\,w_3''''=0$$

$$EI\,w_1=\frac{q_0}{24}x_1^4+\frac{C_1}{6}x_1^3+\frac{C_2}{2}x_1^2+C_3x_1+C_4$$
$$EI\,w_i=\frac{C_{i1}}{6}x_i^3+\frac{C_{i2}}{2}x_i^2+C_{i3}x_i+C_{i4}\quad(i=2,3)$$

**12 Bedingungen:**

| # | Bedingung | Bedeutung |
|---|---|---|
| 1 | $w_1(0)=0$ | Lager A |
| 2 | $M_1(0)=-EIw_1''(0)=0$ | gelenkiges Lager |
| 3–5 | $w_1(\ell)=w_2(0)$, $w_1'(\ell)=w_2'(0)$, $M_1(\ell)=M_2(0)$ | Übergang 1→2 |
| 6 | $Q_1(\ell)=Q_2(0)$ | keine Einzellast am Übergang |
| 7–9 | Übergang 2→3 an der biegesteifen Ecke: $w_2(\ell)=0$ (wegen $EA_2\to\infty$), $w_3(0)=0$ (wegen $EA_1\to\infty$), $w_2'(\ell)=\pm w_3'(0)$ | starre Rahmenecke |
| 10 | $M_2(\ell)=M_3(0)$ | Momentenstetigkeit |
| 11 | $M_3(2\ell)=0$ | freies Ende des vertikalen Balkens |
| 12 | $\boldsymbol{Q_3(2\ell)=-c_F\,w_3(2\ell)}$ | **Federbedingung C** (laut Hinweis) |

**Der entscheidende Hinweis der Aufgabe:** Die Auflagerkraft der Feder C
$$F_C=c_F\,w_3(2\ell)=\frac{EI}{\ell^3}\,w_3(2\ell)$$
liefert die fehlende Randbedingung für die Durchbiegung am Ende des vertikalen Balkens —
ohne sie wäre das System nicht auflösbar.

Die dimensionslose Federsteifigkeit beträgt $\dfrac{c_F\ell^3}{EI}=1$; Feder und Balken sind
also gleich steif und teilen sich die Last etwa hälftig.

### c) Verschiebungsfunktion $u_3$

Der Stab 3 besitzt eine **endliche Dehnsteifigkeit** $EA=\dfrac{EI}{\ell^2}$
(im Gegensatz zu $EA_1,EA_2\to\infty$). Aus der Stab-DGL:

$$EA\,u_3''(x_3)=-n(x_3)=0\quad\text{(keine Längsstreckenlast)}$$

$$\Rightarrow\quad u_3(x_3)=\frac{N_3}{EA}\,x_3+u_3(0)$$

Mit $u_3(0)=0$ (starrer Anschluss an die Ecke) und der Normalkraft $N_3$ im vertikalen Stab
(= Vertikalkomponente der übertragenen Kräfte, im Wesentlichen die Auflagerkraft aus $q_0$):

$$\boxed{\;u_3(x_3)=\frac{N_3}{EA}\,x_3=\frac{N_3\,\ell^2}{EI}\,x_3\;}$$

Am Stabende: $u_3(2\ell)=\dfrac{2N_3\ell^3}{EI}$ — **linearer** Verlauf, da keine
Längsstreckenlast wirkt.

---

## Aufgabe 7 — Biegenormalspannung, neutrale Faser, Kernfläche (16 P.)

Gegeben: $F_1=2500$ N, $F_2=100$ N, $A=153{,}14$ mm²,
$I_y=9659{,}6$ mm⁴, $I_z=29\,618$ mm⁴;
Querschnitt aus 10-mm-Segmenten, Wanddicken 1 und 2 mm.

### a) Biegenormalspannung am freien Ende

Am **freien Ende** ($x=0$, Kraftangriff) sind die Biegemomente null — es wirkt dort nur die
**Normalkraft** und ggf. das aus dem exzentrischen Kraftangriff resultierende Moment:

$$\boxed{\;\sigma_x(y,z)=\frac{N}{A}+\frac{M_y}{I_y}z+\frac{M_z}{I_z}y\;}$$

Mit $N=-F_1=-2500$ N (Druck, axial) und den Exzentrizitätsmomenten
$M_y=F_1\cdot z_F$, $M_z=F_1\cdot y_F$ (Kraftangriff außerhalb von $S$):

$$\frac{N}{A}=\frac{-2500}{153{,}14}=-16{,}33\ \frac{\text{N}}{\text{mm}^2}$$

$$\sigma_x(y,z)=-16{,}33+\frac{2500\,z_F}{9659{,}6}z+\frac{2500\,y_F}{29\,618}y$$

Die Exzentrizitäten $y_F,z_F$ sind aus der Querschnittsskizze (Angriffspunkte von $F_1,F_2$)
abzulesen.

### b) Neutrale Faser

$$\sigma_x=0:\qquad \frac{N}{A}+\frac{M_y}{I_y}z+\frac{M_z}{I_z}y=0$$

$$\boxed{\;z(y)=-\frac{N\,I_y}{A\,M_y}-\frac{M_z\,I_y}{M_y\,I_z}\,y\;}$$

**Achsabschnitte für die Skizze:**

$$z_0=-\frac{N I_y}{A M_y}=-\frac{i_y^2}{z_F},\qquad
y_0=-\frac{N I_z}{A M_z}=-\frac{i_z^2}{y_F}$$

mit $i_y^2=\dfrac{9659{,}6}{153{,}14}=63{,}08$ mm² und $i_z^2=\dfrac{29\,618}{153{,}14}=193{,}4$ mm².

Die neutrale Faser liegt stets auf der **dem Kraftangriff gegenüberliegenden** Seite von $S$
und ist **unabhängig vom Betrag** der Kraft.

### c) Maximale Balkenlänge

Am Einspannquerschnitt A sind die Momente maximal:

$$M_y(\ell)=F_2\cdot\ell + F_1z_F,\qquad M_z(\ell)=F_1\cdot\ell\ \text{bzw.}\ F_2\cdot\ell$$

Nachweis in den beiden maßgebenden Eckpunkten:

$$\sigma_{\max}(\ell)\stackrel{!}{\le}\sigma_{Zug,zul}=300\ \text{MPa}$$
$$\sigma_{\min}(\ell)\stackrel{!}{\ge}\sigma_{Druck,zul}=-200\ \text{MPa}$$

Beide Ungleichungen sind **linear in $\ell$**. Die maßgebende (kleinere) der beiden Lösungen ist:

$$\boxed{\;\ell_{\max}=\min\left\{\ell_{Zug},\ \ell_{Druck}\right\}\;}$$

**Zu erwarten:** Da $\sigma_{Druck,zul}$ betragsmäßig kleiner ist und die konstante
Normalspannung $-16{,}33$ N/mm² bereits **in die Druckrichtung** wirkt, ist in der Regel
der **Druck­nachweis maßgebend**.

### d) Kernfläche

$$k_{z}=\frac{i_y^2}{e_{u/o}}=\frac{63{,}08}{e},\qquad
k_{y}=\frac{i_z^2}{e_{r/l}}=\frac{193{,}4}{e}$$

Mit den Randabständen aus der Skizze (Höhe und Breite je ca. 30 mm, Randabstände $\approx15$ mm):

$$k_z\approx\frac{63{,}08}{15}=4{,}2\ \text{mm},\qquad
k_y\approx\frac{193{,}4}{15}=12{,}9\ \text{mm}$$

**Skizze:** Konvexes Polygon um $S$, in $z$-Richtung deutlich **schlanker** als in
$y$-Richtung (Verhältnis $\approx1:3$, entsprechend $I_z/I_y=3{,}07$).

**Zusammenhang mit b):** Liegt der Kraftangriffspunkt **innerhalb** dieser Kernfläche,
schneidet die neutrale Faser den Querschnitt **nicht** — der gesamte Querschnitt steht
dann unter Druck.

---

## Aufgabe 8 — Schub, Torsion, Schubmittelpunkt (16 P.)

Gegeben: $F_z=F_y=1000$ N, $I_y=93\,965$ mm⁴, $I_z=325\,260$ mm⁴, $\xi=1{,}12$;
$z_S$-Randabstände $17{,}5$ mm und $42{,}5$ mm; Wanddicken 1 und 2 mm;
Teilschubkräfte $T_1=T_5=416{,}53$ N (gegeben).

### a) Schubspannung aus Querkraft $F_z$

$$\boxed{\;\tau_Q(s)=\frac{F_z\,S_y(s)}{I_y\,t(s)}\;}$$

**Drei Arbeitsschritte:**

**① z-h-Diagramm** $[\text{mm}^2]$: Produkt $z(s)\cdot t(s)$ über die abgewickelte Länge auftragen.
Sprünge an den Dickenwechseln ($1\to2$ mm).

**② $S_y(s)$-Verlauf** $[\text{mm}^3]$: Umlaufende Integration von einem **freien Ende**:
$$S_y(s)=\int_0^s z\,t\,\mathrm d\bar s$$
* Gurte (parallel zu $y$): **linear**
* Stege (parallel zu $z$): **quadratisch/parabolisch**
* an Knoten: Beiträge der zulaufenden Äste **addieren**

**③ $\tau_Q$-Verlauf** $[\text{N/mm}^2]$: Division durch $I_yt$.
Maximum in Höhe der neutralen Faser, null an den freien Enden,
**Sprung** an jedem Dickenwechsel (Schubfluss $T=\tau t$ bleibt stetig).

**Kontrolle:** $\displaystyle\int\tau_Q\,t\,\mathrm ds=F_z=1000$ N

### b) Schubspannung aus Torsion

Greift $F_z$ nicht im Schubmittelpunkt an, entsteht

$$M_T=F_z\cdot e$$

Offener dünnwandiger Querschnitt:

$$\boxed{\;I_T=\frac{\xi}{3}\sum_i\ell_it_i^3\;},\qquad \xi=1{,}12$$

$$\tau_T(s)=\frac{M_T}{I_T}\,t(s)$$

**Verlauf (Skizze):**
* über die **Wanddicke linear antimetrisch** — null in der Mittellinie, maximal an beiden
  Wandrändern mit **entgegengesetztem Vorzeichen**
* entlang jedes Segments **konstant**
* **größter Wert in der dicksten Wand** ($t=2$ mm), dort $\tau_{T,\max}=\dfrac{2M_T}{I_T}$

### c) Lage des Angriffspunkts von $F_y$ ohne Torsion (Schubmittelpunkt)

Damit **keine Torsion** entsteht, muss $F_y$ **im Schubmittelpunkt M** angreifen.

**Momentengleichgewicht** der Teilschubkräfte um einen Bezugspunkt $P$:

$$F_y\cdot e_z=\sum_k T_k\cdot r_k$$

Mit den gegebenen Teilschubkräften $T_1=T_5=416{,}53$ N (die beiden äußeren Gurtsegmente)
und ihren Hebelarmen $r_1=r_5$ zum Bezugspunkt:

$$\boxed{\;e_z=\frac{T_1r_1+T_5r_5+\sum_{k=2,3,4}T_kr_k}{F_y}
=\frac{2\cdot416{,}53\cdot r_1+\ldots}{1000}\;}$$

Die Teilschubkräfte der mittleren Segmente folgen aus dem gegebenen $\tau_{F_y}$-Verlauf
mit der Simpson-Formel des Aufgabenhinweises:

$$T_k=\frac{\ell_k}{3}\left(b+2c\right)\cdot t$$

**Grafische Darstellung:** Der Punkt M ist auf der **Symmetrieachse** einzuzeichnen,
**außerhalb** der Querschnittsfläche — bei diesem offenen Profil auf der den Gurten
abgewandten Seite des Stegs.

**Kontrolle der Größenordnung:** $\dfrac{2\cdot416{,}53}{1000}=0{,}83$ — die beiden äußeren
Segmente allein liefern bereits 83 % der Querkraft und dominieren die Lage von M.

---

## Ergebnisübersicht

| Aufgabe | Ergebnis |
|---|---|
| 2a | $A=130$ mm², $z_S=10{,}96$ mm, $y_S=0$ |
| 2b | $I_y=10\,823$ mm⁴, $I_z=10\,683$ mm⁴, $I_{yz}=-8000$ mm⁴ |
| 2c | $\varphi^*=-44{,}75^\circ$; $I_1=18\,754$ mm⁴, $I_2=2753$ mm⁴ |
| 3 | $F_1=F\frac{E_1A_1}{E_1A_1+E_2A_2}$, $F_2=F\frac{E_2A_2}{E_1A_1+E_2A_2}$ |
| 4a | $\sigma=636{,}6$ N/mm² |
| 4b | $E=241\,144$ N/mm² $\approx241$ GPa |
| 5a | $\sigma_x=20{,}46$, $\sigma_y=-15$ N/mm²; $\tau_{\max}=17{,}73$ N/mm² |
| 5b | Faser A: $\sigma=+11{,}60$, $\tau=-15{,}35$ · Faser B: $\sigma=-13{,}93$, $\tau=-6{,}06$ |
| 5c | $\alpha=\beta=45^\circ$ |
| 6c | $u_3(x_3)=\frac{N_3\ell^2}{EI}x_3$ (linear) |
| 7d | $i_y^2=63{,}08$ mm², $i_z^2=193{,}4$ mm² |
| 8b | $I_T=\frac{1{,}12}{3}\sum\ell_it_i^3$ |
