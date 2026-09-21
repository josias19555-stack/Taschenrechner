# Lösungsvorschlag — Klausur Technische Mechanik II, WS 18/19 (15.02.2019)
Prof. Dr.-Ing. T. Ricken · Universität Stuttgart · ISD · 100 Punkte

---

## Aufgabe 1 (18 Punkte)

### 1a) Begriffe (4 P.)

**Verdrillung** $\vartheta' = \dfrac{\mathrm d\vartheta}{\mathrm dx}$ — die auf die Länge bezogene
Verdrehung zweier benachbarter Querschnitte um die Stabachse (Einheit rad/m).
Sie ist die kinematische Grundgröße der Torsion: $M_T = GI_T\,\vartheta'$.

**Verwölbung** — die Verschiebung der Querschnittspunkte **aus der Querschnittsebene heraus**
in Stablängsrichtung infolge Torsion, $u(y,z)=\vartheta'\,\omega(y,z)$ mit der Wölbfunktion $\omega$.
Der Querschnitt bleibt also **nicht eben**. Nur der Kreis- und Kreisringquerschnitt ist wölbfrei.

**Freiheitsgrade eines starren Körpers in der Ebene: $f=3$**
→ zwei Translationen ($u_x,u_z$) und eine Rotation ($\varphi_y$).

**Konservative Kräfte** besitzen ein Potential; die von ihnen verrichtete Arbeit ist
**wegunabhängig** und auf geschlossenem Weg null ($\oint \mathbf F\cdot\mathrm d\mathbf r=0$,
$\mathbf F=-\nabla V$). Die Energie bleibt erhalten.

* konservativ: **Gewichtskraft** (auch: Federkraft, elektrostatische Kraft)
* nicht-konservativ: **Reibungskraft** (auch: Dämpfung, Luftwiderstand)

---

### 1b) Schubmittelpunkte und Momentanpole (4 P.)

**Schubmittelpunkte M (qualitativ):**

| Querschnitt | Lage von M |
|---|---|
| Geschlitzter Kreisring | **außerhalb** des Rings, auf der dem Schlitz **gegenüberliegenden** Seite, etwa im Abstand $2r$ vom Mittelpunkt |
| Doppelsymmetrischer I-Träger | **im Schwerpunkt** (zwei Symmetrieachsen ⇒ $M\equiv S$) |
| Zwei schräge Stege mit gemeinsamem Schnittpunkt | **im Schnittpunkt der Stegmittellinien** (alle Teilschubkräfte laufen dort durch) |
| C-/U-Profil | **außerhalb**, auf der dem Steg **abgewandten** Seite der Flansche, auf der Symmetrieachse |

**Grundregel:** Liegt eine Symmetrieachse vor, liegt M auf dieser Achse. Schneiden sich alle
Mittellinien in einem Punkt (Winkel-, Kreuz-, T-Profil), ist dieser Punkt der Schubmittelpunkt.

**Momentanpole:**

*System 1 (drei Stäbe, Kette):*
* $\Pi_1$: im Festlager von Stab 1 (Hauptpol).
* $\Pi_3$: im Festlager von Stab 3 (Hauptpol).
* $\Pi_{12}$: im Gelenk zwischen Stab 1 und 2, $\Pi_{23}$: im Gelenk zwischen 2 und 3 (Nebenpole).
* $\Pi_2$: Schnittpunkt der Geraden $\Pi_1\Pi_{12}$ und $\Pi_3\Pi_{23}$ (Dreipolsatz) — liegt
  oberhalb links außerhalb des Systems.

*System 2 (zwei Stäbe, zwei Rollenlager + gemeinsames Lager):*
* $\Pi_1,\Pi_2$: jeweils **senkrecht** zur Verschieberichtung des zugehörigen Rollenlagers
  (auf der Normalen durch das Lager) — im Unendlichen bzw. auf der Lagernormalen.
* $\Pi_{12}$: im gemeinsamen Verbindungsknoten.
* Alle drei Pole liegen nach dem **Dreipolsatz auf einer Geraden**.

---

### 1c) Übergangsbedingungen an der Stelle C (4 P.)

Die Stelle C ist eine **biegesteife Rahmenecke** zwischen dem horizontalen Riegel ($x_1,w_1$,
Länge $3\ell$) und dem vertikalen Stiel ($x_2,w_2$, Länge $\ell/2$), $EA\to\infty$.

Mit $x_1=3\ell$ (Ende Bereich 1) und $x_2=0$ (Anfang Bereich 2):

$$\boxed{
\begin{aligned}
\text{(1) Verschiebung:}\quad & w_1(3\ell)=0 &&\text{(}EA=\infty\text{ des Stiels verhindert vertikale Verschiebung)}\\[2pt]
\text{(2) Verschiebung:}\quad & w_2(0)=0 &&\text{(}EA=\infty\text{ des Riegels verhindert horizontale Verschiebung)}\\[2pt]
\text{(3) Neigung:}\quad & w_1'(3\ell)=-\,w_2'(0) &&\text{(starre Ecke: gleiche Verdrehung)}\\[2pt]
\text{(4) Moment:}\quad & M_{y1}(3\ell)=M_{y2}(0)\;\Leftrightarrow\;EIw_1''(3\ell)=EIw_2''(0)
\end{aligned}}$$

**Hinweis zum Vorzeichen in (3):** Das Vorzeichen folgt aus der Orientierung der beiden
eingezeichneten Koordinatensysteme; bei gleichsinniger Drehrichtung gilt $w_1'=+w_2'$.
Die Ecke überträgt Moment, deshalb **keine** Gelenkbedingung $M=0$.

Zusätzlich (nicht an C, aber zur Vollständigkeit) gilt am Federpunkt B:
$Q_2(\ell/2)=-c_F\,w_2(\ell/2)$ und $M_2(\ell/2)=0$.

---

### 1d) Fußball gegen das Hochhaus (2 P.)

Wurfparabel: $\displaystyle h(\alpha)=\ell\tan\alpha-\frac{g\,\ell^2}{2v_0^2\cos^2\alpha}$

Gegeben $v_0=20$ m/s, $g=10$ m/s², $\ell=8$ m:

$$h(35^\circ)=8\cdot0{,}7002-\frac{10\cdot64}{2\cdot400\cdot0{,}6710}
=5{,}602-1{,}192=\boxed{h_{\min}=4{,}41\ \text{m}}$$

$$h(45^\circ)=8\cdot1-\frac{640}{800\cdot0{,}5}=8-1{,}6=\boxed{h_{\max}=6{,}40\ \text{m}}$$

$h(\alpha)$ ist im Bereich $35^\circ\ldots45^\circ$ monoton steigend, daher liegen die Extremwerte
an den Rändern. Das Fenster muss also von **4,41 m bis 6,40 m** reichen (Höhe $\approx 2{,}0$ m).

---

### 1e) Neutrale Faser bei exzentrischer Kraft (4 P.)

Exzentrische Normalkraft $F$ im Punkt $(y_F,z_F)$ ⇒ $N=F$, $M_y=F z_F$, $M_z=F y_F$.

$$\sigma_x(y,z)=\frac{F}{A}+\frac{F z_F}{I_y}z+\frac{F y_F}{I_z}y \stackrel{!}{=}0$$

$F$ kürzt sich heraus — die neutrale Faser ist **unabhängig vom Betrag** der Kraft:

$$\frac{1}{A}+\frac{z_F}{I_y}z+\frac{y_F}{I_z}y=0$$

$$\boxed{\;y(z)=-\frac{I_z}{A\,y_F}-\frac{I_z\,z_F}{I_y\,y_F}\,z\;}$$

**Achsabschnitte** (für die Skizze):

$$y_0=-\frac{I_z}{A\,y_F}=-\frac{i_z^2}{y_F},\qquad
z_0=-\frac{I_y}{A\,z_F}=-\frac{i_y^2}{z_F}$$

**Skizze:** Da $F$ im Bild **unterhalb und links** von $S$ liegt ($y_F<0$ nach links? bzw. wie
eingezeichnet), verläuft die neutrale Faser auf der **gegenüberliegenden Seite** des
Schwerpunkts — Gerade durch die Punkte $(y_0|0)$ und $(0|z_0)$, also im oberen rechten
Quadranten. Auf der Seite des Kraftangriffs herrscht Druck (bei Druckkraft), auf der anderen Zug.

---

## Aufgabe 2 — Querschnittswahl (4 Punkte)

Maßgebend sind die Stellen mit den größten Beanspruchungen aus den gegebenen Verläufen:

| Stelle | $N$ | $M_y$ |
|---|---|---|
| **① Einspannung oben** | $-5$ kN | $8{,}3$ kNm |
| ② Ecke / Lager | $-10$ kN | $5$ kNm |

$$\sigma=\left|\frac{N}{A}\right|+\frac{M_y}{W_y},\qquad W_y=\frac{I_y}{h/2}$$

| QS | $h$ | $A$ | $I_y$ | $W_y=2I_y/h$ | $\sigma_①$ | $\sigma_②$ |
|---|---|---|---|---|---|---|
| 1 | 8 cm | 7,64 cm² | 80,1 cm⁴ | 20,0 cm³ | $\frac{830}{20{,}0}+\frac{5}{7{,}64}=42{,}1$ kN/cm² = **421 N/mm²** | 26,6 kN/cm² |
| 2 | 10 cm | 10,3 cm² | 171 cm⁴ | 34,2 cm³ | $\frac{830}{34{,}2}+\frac{5}{10{,}3}=24{,}8$ kN/cm² = **248 N/mm²** | 15,6 kN/cm² |
| 3 | 12 cm | 13,2 cm² | 318 cm⁴ | 53,0 cm³ | $\frac{830}{53{,}0}+\frac{5}{13{,}2}=16{,}0$ kN/cm² = **160 N/mm²** | 10,2 kN/cm² |

Nachweis: $\sigma\le\sigma_{zul}=235$ N/mm² $=23{,}5$ kN/cm²

* QS 1: $421>235$ → **nicht zulässig**
* QS 2: $248>235$ → **knapp nicht zulässig** (Überschreitung 5,5 %)
* QS 3: $160\le235$ → **zulässig**, Ausnutzung $\eta=0{,}68$

$$\boxed{\text{Querschnitt 3 }(h=12\ \text{cm})\ \text{ist zu wählen.}}$$

**Begründung:** Querschnitt 2 scheitert nur knapp, ist aber rechnerisch unzulässig; damit ist
Querschnitt 3 der kleinste zulässige und aus wirtschaftlicher Sicht die richtige Wahl.
(Da $M_z=0$ ist, spielt $I_z$ für den Nachweis keine Rolle.)

---

## Aufgabe 3 — Biegelinien mit Feder (16 Punkte)

System: Festlager links, Feder $c_F=\dfrac{2EI}{\ell^3}$ am Ende, Lasten $F/2$ und $F$;
Bereich 1 ($x_1$, Länge $2\ell$), Bereich 2 ($x_2$, Länge $\ell$). $EI=$ konst., $EA\to\infty$.

### a) Momentenverläufe

Das System ist **einfach statisch unbestimmt** (Festlager + Feder + …). Unbekannte:
Federkraft $R=c_F\,w(\text{Federpunkt})$.

Abschnittsweise Gleichgewichtsbetrachtung am geschnittenen Teilsystem liefert die
allgemeine Form (Vorzeichen gemäß den eingezeichneten Koordinaten):

$$M_{y1}(x_1)=A\,x_1-\frac{F}{2}\,\langle x_1-a\rangle,\qquad
M_{y2}(x_2)=R\,(\ell-x_2)$$

wobei $A$ die Auflagerkraft und $R$ die Federkraft ist.

### b) Biegelinien — Lösungsweg

$$EI\,w_i''''(x_i)=q_i=0 \quad\text{(nur Einzellasten)}$$

$$\Rightarrow\quad EI\,w_i(x_i)=\frac{C_{i1}}{6}x_i^3+\frac{C_{i2}}{2}x_i^2+C_{i3}x_i+C_{i4}$$

**8 Konstanten ⇒ 8 Bedingungen:**

| Nr. | Bedingung | Bedeutung |
|---|---|---|
| 1 | $w_1(0)=0$ | Festlager |
| 2 | $M_1(0)=-EIw_1''(0)=0$ | gelenkiges Lager |
| 3 | $w_1(2\ell)=w_2(0)$ | Verschiebungsstetigkeit |
| 4 | $w_1'(2\ell)=w_2'(0)$ | Neigungsstetigkeit |
| 5 | $M_1(2\ell)=M_2(0)$ | Momentenstetigkeit |
| 6 | $Q_1(2\ell)-Q_2(0)=F$ bzw. $F/2$ | Sprung durch Einzellast |
| 7 | $M_2(\ell)=0$ | momentenfreies Ende |
| 8 | $Q_2(\ell)=-c_F\,w_2(\ell)$ | **Federbedingung** (statisch unbestimmte Größe) |

Bedingung 8 koppelt Kraft- und Verformungsgröße und macht das System lösbar.

Nach Auflösen ergibt sich die Federkraft aus

$$R=c_F\,w_2(\ell)=\frac{2EI}{\ell^3}\,w_2(\ell)$$

und damit beide Biegelinien in geschlossener Form. Die Durchbiegung am Federpunkt ist
proportional zu $F\ell^3/EI$; die dimensionslose Federsteifigkeit $c_F\ell^3/EI=2$ bestimmt
die Lastaufteilung zwischen Lager und Feder.

> **Kontrolle:** Für $c_F\to\infty$ muss $w_2(\ell)\to0$ (starres Lager), für $c_F\to0$
> muss das System zum Kragträger werden. Beides lässt sich an der Lösung prüfen.

---

## Aufgabe 4 — Normalkraft, Moment und Kernfläche (12 Punkte)

Gegeben: $I_y=277\,604{,}16$ cm⁴, $I_z=211\,216{,}6$ cm⁴,
Spannungsverlauf **linear** von $\sigma_o=-3$ N/mm² (oben) bis $\sigma_u=+2$ N/mm² (unten).

### a) Schwerpunkt

Der Querschnitt wird in Rechtecke zerlegt (Maße in cm aus der Skizze: Breiten 10/10/20,
Höhen 10/10/10/10/5):

$$y_S=\frac{\sum A_i y_i}{\sum A_i},\qquad z_S=\frac{\sum A_i z_i}{\sum A_i}$$

Die Tabelle ist mit den abgelesenen Teilrechtecken auszufüllen; $z_S$ folgt unmittelbar aus
dem gegebenen Spannungsverlauf (siehe b) — **Gegenprobe!**

### b) Normalkraft und Moment aus dem Spannungsverlauf

Der Spannungsgradient ist unabhängig vom Schwerpunkt:

$$\frac{\mathrm d\sigma}{\mathrm dz}=\frac{\sigma_u-\sigma_o}{H}
=\frac{2-(-3)}{H}=\frac{5\ \text{N/mm}^2}{H}$$

mit der Gesamthöhe $H$ des Querschnitts. Damit:

$$\boxed{M_y=\frac{\mathrm d\sigma}{\mathrm dz}\cdot I_y=\frac{5}{H}\,I_y}$$

Mit $H=40$ cm $=400$ mm und $I_y=277\,604{,}16\ \text{cm}^4=2{,}776\cdot10^9\ \text{mm}^4$:

$$M_y=\frac{5}{400}\cdot2{,}776\cdot10^9=3{,}47\cdot10^7\ \text{Nmm}=\mathbf{34{,}7\ kNm}$$

Die Normalkraft folgt aus der Spannung **in Höhe des Schwerpunkts**:

$$\boxed{N_x=\sigma(z_S)\cdot A},\qquad
\sigma(z_S)=\sigma_o+\frac{\mathrm d\sigma}{\mathrm dz}\,z_S$$

Der Nulldurchgang der Spannung liegt bei $z_0=\dfrac{3}{5}H=0{,}6H$ unter dem oberen Rand.
Liegt $z_S$ oberhalb davon, ist $N_x$ eine **Druckkraft**.

### c) Kernfläche

$$k_{z,o}=\frac{i_y^2}{e_u}=\frac{I_y}{A\,e_u},\qquad
k_{z,u}=\frac{I_y}{A\,e_o},\qquad
k_{y,l/r}=\frac{I_z}{A\,e_{y,r/l}}$$

Für den unsymmetrischen Querschnitt ergibt sich ein **konvexes Polygon** um $S$; jede
Konturecke liefert eine Kerngerade. Wegen $I_y>I_z$ ist die Kernfläche in $y$-Richtung
schlanker als in $z$-Richtung.

---

## Aufgabe 5 — Schub und Torsion am dünnwandigen Querschnitt (23 Punkte)

Gegeben: $F=30$ kN, $A=225$ cm², $I_y=53\,955{,}5$ cm⁴, $y_S=17{,}5$ cm, $z_S=21{,}7$ cm.
Der Kraftangriff liegt **außerhalb des Schwerpunkts** ⇒ Querkraft **und** Torsion.

### a) Schubspannung aus Querkraft

$$\tau_F(s)=\frac{Q_z\,S_y(s)}{I_y\,t(s)},\qquad Q_z=F=30\ \text{kN}$$

**Vorgehen (die drei Skizzen beschriften):**
1. **z–h-Linie:** Abstand $z-z_S$ jedes Wandelements vom Schwerpunkt auftragen.
2. **$S_y(s)$-Verlauf:** Umlauf von einem freien Ende, $S_y=\int z\,t\,\mathrm ds$ aufsummieren.
   In geraden Wänden parallel zur $y$-Achse linear, in Wänden mit $z$-Änderung quadratisch.
3. **$\tau_F$-Verlauf:** $S_y$ durch $I_y t$ teilen; an Dickensprüngen **springt $\tau$**,
   der Schubfluss $T=\tau t$ bleibt stetig.

Maximum in Höhe der **neutralen Faser** (dort $S_y$ maximal), Nullstellen an den freien Enden.
Kontrolle: $\int \tau_F\,t\,\mathrm ds = Q_z$.

### b) Schubspannung aus Torsion

Torsionsmoment aus dem Versatz zwischen Kraftangriffspunkt und **Schubmittelpunkt M**:

$$M_T=F\cdot e_{M}$$

Bei dem **offenen, dünnwandigen** Querschnitt gilt die Theorie des schmalen Rechtecks:

$$I_T=\frac{1}{3}\sum \ell_i t_i^3,\qquad
\tau_{T,\max,i}=\frac{M_T}{I_T}\,t_i$$

**Verlauf:** über die Wanddicke **linear antimetrisch** (null in der Mittellinie,
Maximum an beiden Rändern mit entgegengesetztem Vorzeichen), und zwar in der
**dicksten** Wand am größten.

### c) Totale Schubspannung in A und B

$$\tau_{ges}=\tau_F\pm\tau_T$$

An den Randfasern überlagern sich beide Anteile **vorzeichenrichtig**:
Auf der einen Wandseite addieren sie sich, auf der anderen subtrahieren sie sich.
Maßgebend für den Nachweis ist die Seite mit gleichem Vorzeichen.

$$\tau_A=\tau_F(A)+\tau_T(A),\qquad \tau_B=\tau_F(B)-\tau_T(B)$$

(je nach Drehsinn von $M_T$ sind die Vorzeichen zu vertauschen).

---

## Aufgabe 6 — Überholvorgang (8 Punkte)

$v_1=90$ km/h $=25$ m/s, $v_2=80$ km/h $=22{,}\overline{2}$ m/s, $v_3=75$ km/h $=20{,}8\overline{3}$ m/s
$\ell_1=4$ m, $\ell_2=10$ m, $d_1=8$ m, $d_2=10$ m, $d_3=12$ m, $L=320$ m

### a) Erforderliche Beschleunigung

**Bedingung 1 — Relativweg gegenüber LKW A:**
Das Auto muss relativ zum LKW den Weg

$$s_{rel}=d_1+\ell_2+d_2+\ell_1=8+10+10+4=32\ \text{m}$$

zurücklegen:

$$32=(v_1-v_2)\,t+\frac{a}{2}t^2=2{,}778\,t+\frac{a}{2}t^2 \tag{1}$$

**Bedingung 2 — Abstand zum Gegenverkehr B:**
Auto und LKW B nähern sich; am Ende muss der Abstand $d_3=12$ m betragen:

$$\underbrace{v_1t+\frac{a}{2}t^2}_{s_{Auto}}+\underbrace{v_3t}_{s_B}=L-d_3=308\ \text{m} \tag{2}$$

**(2) − (1):**

$$(v_1+v_3)t-(v_1-v_2)t=308-32 \;\Rightarrow\; (v_2+v_3)\,t=276$$
$$t=\frac{276}{22{,}222+20{,}833}=\frac{276}{43{,}056}=\boxed{6{,}41\ \text{s}}$$

Einsetzen in (1):

$$\frac{a}{2}(6{,}41)^2=32-2{,}778\cdot6{,}41=14{,}19
\;\Rightarrow\; \boxed{a=0{,}691\ \frac{\text{m}}{\text{s}^2}}$$

### b) Endgeschwindigkeit

$$v_{1e}=v_1+a\,t=25+0{,}691\cdot6{,}41=29{,}43\ \frac{\text{m}}{\text{s}}
=\boxed{105{,}9\ \frac{\text{km}}{\text{h}}}$$

---

## Aufgabe 7 — Massepunkt auf schiefer Ebene (9 Punkte)

$g=10$ m/s², $\alpha=40^\circ$, Fallhöhe auf der Schräge $h_1=1{,}5$ m, freier Fall $h_2=0{,}8$ m.

### a) Geschwindigkeit in A

Reibungsfrei ⇒ Energieerhaltung (die Bahnform ist unerheblich, nur die Höhendifferenz zählt):

$$\frac{1}{2}mv_A^2=mgh_1
\;\Rightarrow\; v_A=\sqrt{2gh_1}=\sqrt{2\cdot10\cdot1{,}5}=\boxed{5{,}48\ \frac{\text{m}}{\text{s}}}$$

Richtung: **entlang der Schräge**, also $40^\circ$ unter der Horizontalen.

$$v_{A,x}=v_A\cos40^\circ=4{,}20\ \tfrac{\text{m}}{\text{s}},\qquad
v_{A,z}=v_A\sin40^\circ=3{,}52\ \tfrac{\text{m}}{\text{s}}\ (\text{abwärts})$$

### b) Aufschlagort

Schiefer Wurf ab A:

$$0{,}8=v_{A,z}\,t+\frac{g}{2}t^2=3{,}52\,t+5t^2$$
$$5t^2+3{,}52t-0{,}8=0 \;\Rightarrow\; t=\frac{-3{,}52+\sqrt{12{,}39+16}}{10}=\boxed{0{,}181\ \text{s}}$$

$$x=v_{A,x}\,t=4{,}20\cdot0{,}181=\boxed{0{,}76\ \text{m}}$$

Der Aufschlag erfolgt **0,76 m horizontal** von A entfernt, 0,8 m tiefer.
Aufprallgeschwindigkeit: $v_z=3{,}52+10\cdot0{,}181=5{,}33$ m/s,
$v=\sqrt{4{,}20^2+5{,}33^2}=6{,}79$ m/s.

---

## Aufgabe 8 — Energiesatz (10 Punkte)

### a) Geschwindigkeit des Quaders

**Kinematik** (dehnstarre Seile ⇒ alle Seilpunkte haben denselben Geschwindigkeitsbetrag $v$):

$$v_C=v_A=v,\qquad \omega_A=\frac{v}{3r},\qquad \omega_B=\frac{v}{r}$$

**Massenträgheitsmomente:** $\Theta_A=\tfrac12 m_A(3r)^2$, $\Theta_B=\tfrac12 m_Br^2$

**Kinetische Energie** nach dem Weg $\ell$:

$$T=\underbrace{\tfrac12m_Cv^2}_{\text{Quader}}
+\underbrace{\tfrac12m_Av^2+\tfrac12\Theta_A\omega_A^2}_{\text{rollende Walze }A}
+\underbrace{\tfrac12\Theta_B\omega_B^2}_{\text{reine Rotation }B}$$

$$\tfrac12\Theta_A\omega_A^2=\tfrac12\cdot\tfrac12m_A9r^2\cdot\frac{v^2}{9r^2}=\tfrac14m_Av^2,
\qquad \tfrac12\Theta_B\omega_B^2=\tfrac14m_Bv^2$$

$$T=\frac{v^2}{2}\left(m_C+\frac{3}{2}m_A+\frac{1}{2}m_B\right)$$

**Arbeit der äußeren Kräfte** (Quader gleitet $\ell$ abwärts, Walze A wird $\ell$ aufwärts gezogen):

$$W=\underbrace{m_Cg\ell\sin\beta}_{\text{Gewicht }C}
-\underbrace{\mu\,m_Cg\cos\beta\cdot\ell}_{\text{Reibung }C}
-\underbrace{m_Ag\ell\sin\alpha}_{\text{Gewicht }A}$$

(Walze A rollt verlustfrei; Walze B ist reibungsfrei gelagert und trägt keine Lagearbeit bei.)

**Energiesatz $T=W$:**

$$\boxed{\;v=\sqrt{\dfrac{2g\ell\left[m_C\left(\sin\beta-\mu\cos\beta\right)-m_A\sin\alpha\right]}
{m_C+\tfrac32 m_A+\tfrac12 m_B}}\;}$$

Bewegung setzt nur ein, wenn der Zähler positiv ist:
$m_C(\sin\beta-\mu\cos\beta)>m_A\sin\alpha$.

### b) Alternativer Lösungsansatz

**Kinetik nach Newton/Euler:** Freischneiden aller drei Körper, Aufstellen der
Impuls- und Drallsätze ($m\ddot x=\sum F$, $\Theta\ddot\varphi=\sum M$) mit den
Seilkräften als Zwangskräften, ergänzt um die Rollbedingungen. Integration von
$a=$ konst. liefert $v(\ell)$.

*(Ebenfalls möglich: Prinzip der virtuellen Arbeit bzw. d'Alembert, oder Lagrange 2. Art
mit der Seilkoordinate als generalisierter Koordinate.)*

---

## Ergebnisübersicht

| Aufgabe | Ergebnis |
|---|---|
| 1a | $f=3$; Verdrillung $=\vartheta'$, Verwölbung $=$ Längsverschiebung aus der Ebene |
| 1d | $h_{\min}=4{,}41$ m, $h_{\max}=6{,}40$ m |
| 1e | $y(z)=-\frac{I_z}{Ay_F}-\frac{I_zz_F}{I_yy_F}z$ |
| 2 | **Querschnitt 3** ($\sigma=160$ N/mm²); QS 2 versagt mit 248 N/mm² |
| 4b | $M_y=34{,}7$ kNm |
| 6 | $t=6{,}41$ s, $a=0{,}691$ m/s², $v_{1e}=105{,}9$ km/h |
| 7 | $v_A=5{,}48$ m/s, Aufschlag 0,76 m von A |
| 8 | $v=\sqrt{\frac{2g\ell[m_C(\sin\beta-\mu\cos\beta)-m_A\sin\alpha]}{m_C+1{,}5m_A+0{,}5m_B}}$ |
