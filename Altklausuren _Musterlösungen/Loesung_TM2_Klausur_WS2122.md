# Lösungsvorschlag — Modulprüfung Technische Mechanik II, PO 2019
**WS 21/22 · 6. April 2022** · Univ.-Prof. Dr.-Ing. Tim Ricken · ISD Stuttgart · 100 Punkte

---

## Aufgabe 1 — Theorie (10 P.)

### a) Spannungstensor benennen

$$\boldsymbol\sigma=\begin{bmatrix}10 & 25\\ 25 & -4\end{bmatrix}\ \frac{\text{kN}}{\text{m}^2}
=\begin{bmatrix}\sigma_{xx} & \tau_{xy}\\ \tau_{yx} & \sigma_{yy}\end{bmatrix}$$

| Eintrag | Bezeichnung | Wirkung am Element |
|---|---|---|
| $\sigma_{xx}=+10$ | Normalspannung in $x$ | **Zug**, Pfeile senkrecht aus den beiden $x$-Flächen heraus |
| $\sigma_{yy}=-4$ | Normalspannung in $y$ | **Druck**, Pfeile auf die $y$-Flächen zu |
| $\tau_{xy}=\tau_{yx}=+25$ | Schubspannung | tangential in den Flächen, **paarweise gleich** (Satz der zugeordneten Schubspannungen), Pfeile bilden ein in sich geschlossenes „Wirbelpaar" |

**Skizze:** Quadratisches Element; an den linken/rechten Flächen Zugpfeile ($10$), oben/unten
Druckpfeile ($4$), an allen vier Flächen tangentiale Pfeile ($25$), die auf gegenüberliegenden
Seiten entgegengesetzt und an angrenzenden Kanten **zur gemeinsamen Ecke hin bzw. von ihr weg**
zeigen (Momentengleichgewicht $\Rightarrow \tau_{xy}=\tau_{yx}$).

### b) Zwei geometrische Voraussetzungen der geraden Biegung

1. **Bernoulli-Hypothese:** Querschnitte bleiben bei der Verformung **eben** und stehen
   weiterhin **senkrecht** auf der verformten Stabachse (keine Schubverzerrung, $\gamma_{xz}=0$).
2. **Lastebene = Hauptachsenebene:** Die Belastungsebene enthält eine Hauptträgheitsachse
   des Querschnitts ($I_{yz}=0$), sodass keine schiefe Biegung auftritt.

*(Zusätzlich: schlanker Stab, kleine Verformungen, $\sigma_y=\sigma_z=0$.)*

### c) Tonti-Diagramm

Das Tonti-Diagramm zeigt die **Struktur der Feldgleichungen der Elastostatik** und wie die
Grundgleichungen zu einem geschlossenen Kreislauf zusammenwirken:

* **linke Seite — Kinematik:** Verschiebungen $u$ → (Differentialoperator) → Verzerrungen $\varepsilon$
* **untere Verbindung — Stoffgesetz:** $\varepsilon$ → (Hooke, $E$) → Spannungen $\sigma$
* **rechte Seite — Statik:** $\sigma$ → (adjungierter Differentialoperator, Gleichgewicht) → Lasten $q$
* **obere Verbindung:** die eingeprägten Lasten und Randbedingungen schließen den Kreis

$$u \xrightarrow{\ \text{Kinematik}\ } \varepsilon
\xrightarrow{\ \text{Stoffgesetz}\ } \sigma
\xrightarrow{\ \text{Gleichgewicht}\ } q$$

**Aussage:** Kinematik und Gleichgewicht sind **zueinander adjungiert** (dual); das Stoffgesetz
ist die einzige materialabhängige Brücke. Daraus folgt unmittelbar die DGL der Biegelinie
$(EIw'')''=q$ als Hintereinanderschaltung der drei Kanten.

---

## Aufgabe 2 — Flächenträgheitsmomente Vollquerschnitt (12 P.)

Der Querschnitt setzt sich zusammen aus
**Rechteck** ($6{,}41\ell\times12\ell$) $+$ **Halbkreis** ($r=6\ell$) $-$ **2 Kreislöcher** ($r=2\ell$).

### Vorgehen (Superposition mit Steiner)

$$I_y=\sum_i\left[I_{y,i}^{\text{eigen}}+A_i\,\bar z_i^{\,2}\right],\qquad
I_z=\sum_i\left[I_{z,i}^{\text{eigen}}+A_i\,\bar y_i^{\,2}\right],\qquad
I_{yz}=\sum_i\left[I_{yz,i}^{\text{eigen}}+A_i\,\bar y_i\bar z_i\right]$$

Aussparungen gehen mit **negativer Fläche** ein.

### Teilflächen und Eigenträgheitsmomente

| Teil | $A_i$ | $I_{y,i}^{\text{eigen}}$ | $I_{z,i}^{\text{eigen}}$ | $I_{yz,i}^{\text{eigen}}$ |
|---|---|---|---|---|
| ① Rechteck $b\times h=6{,}41\ell\times12\ell$ | $76{,}92\,\ell^2$ | $\frac{bh^3}{12}=923{,}0\,\ell^4$ | $\frac{hb^3}{12}=263{,}4\,\ell^4$ | $0$ |
| ② Halbkreis $r=6\ell$ | $\frac{\pi r^2}{2}=56{,}55\,\ell^2$ | $\frac{\pi r^4}{8}=508{,}9\,\ell^4$ | $\left(\frac{\pi}{8}-\frac{8}{9\pi}\right)r^4=141{,}8\,\ell^4$ | $0$ |
| ③,④ Löcher $r=2\ell$ | $-\pi r^2=-12{,}57\,\ell^2$ je | $-\frac{\pi r^4}{4}=-12{,}57\,\ell^4$ je | dito | $0$ |

**Wichtig beim Halbkreis:** Der Eigenschwerpunkt liegt um $e=\dfrac{4r}{3\pi}=2{,}546\,\ell$
von der Schnittkante entfernt; $I_z^{\text{eigen}}$ ist **bereits auf diesen Schwerpunkt bezogen**
(deshalb der Term $-\tfrac{8}{9\pi}r^4$).

### Deviationsmoment

Für jedes Teil gilt $I_{yz,i}^{\text{eigen}}=0$ (Rechteck mit achsparallelen Seiten, Kreis,
Halbkreis mit Symmetrieachse). Es bleibt **nur der Steiner-Anteil**:

$$\boxed{I_{yz}=\sum_i A_i\,\bar y_i\,\bar z_i}$$

* Die beiden **Löcher liegen diagonal versetzt** zum Schwerpunkt: das obere links
  ($\bar y<0$, $\bar z<0$) liefert $A\bar y\bar z>0$, wegen $A<0$ also einen **negativen** Beitrag;
  das untere rechts ($\bar y>0$, $\bar z>0$) ebenso.
* Rechteck und Halbkreis liegen auf der $y$-Achse ($\bar z\approx0$ bzw. symmetrisch) und
  liefern kleine bzw. keine Beiträge.

$$\Rightarrow\quad I_{yz}<0$$

Der Querschnitt besitzt **keine** Symmetrieachse mehr (die Löcher zerstören die Symmetrie zur
$y$-Achse), daher ist $I_{yz}\ne0$ und $y,z$ sind **keine Hauptachsen**.

> **Hinweis zur Durchführung:** Alle $\bar y_i,\bar z_i$ sind **vom gegebenen Schwerpunkt $S$ aus**
> zu messen (die Lage von $S$ ist in der Aufgabe bereits eingezeichnet, muss also nicht
> berechnet werden). Kontrolle: $\sum A_i\bar y_i=\sum A_i\bar z_i=0$.

---

## Aufgabe 3 — Mohr'scher Spannungskreis (11 P.)

Gegeben: Auf **Seite 2** wirkt $\sigma=40$ kN/cm² (Zug, Normale vertikal),
auf **Seite 4** wirkt $\sigma=53{,}3$ kN/cm², Kantenwinkel $80^\circ$, $90^\circ$, $120^\circ$;
auf **Seite 3 keine Schubspannung** ⇒ Seite 3 ist eine **Hauptspannungsebene**. $\tau_{xy}>0$.

### a) Konstruktion des Kreises

1. Seite 3 ist schubspannungsfrei ⇒ ihre Normale ist eine **Hauptrichtung**, der zugehörige
   Bildpunkt liegt auf der $\sigma$-Achse.
2. Die Normalen der Seiten 2 und 4 schließen einen bekannten Winkel ein (aus den
   Kantenwinkeln $80^\circ/90^\circ/120^\circ$ der Scheibe); im Mohr-Kreis erscheint dieser
   Winkel **verdoppelt**.
3. Damit sind drei Bedingungen bekannt: zwei Punkte mit bekannter Normalspannung
   ($40$ und $53{,}3$) im bekannten Winkelabstand $2\Delta\varphi$, plus ein Punkt auf der
   $\sigma$-Achse. Mittelpunkt $\sigma_M$ und Radius $R$ sind eindeutig konstruierbar.

### b) Hauptspannungen

$$\sigma_{I,II}=\sigma_M\pm R,\qquad
\sigma_M=\frac{\sigma_x+\sigma_y}{2},\qquad
R=\sqrt{\left(\frac{\sigma_x-\sigma_y}{2}\right)^2+\tau_{xy}^2}$$

Eine Hauptrichtung ist die **Normale der Seite 3**; die zweite steht senkrecht dazu.
Die Hauptspannungsrichtung folgt aus

$$\tan2\varphi_0=\frac{2\tau_{xy}}{\sigma_x-\sigma_y}$$

Aus $\tau_{xy}>0$ folgt die Vorzeichenwahl der Wurzel bzw. die Zuordnung von $\sigma_I$.

### c) Spannungszustände auf allen vier Seiten

Für jede Seite $i$ mit Normalenwinkel $\varphi_i$ gegenüber der $x$-Achse:

$$\sigma_{\varphi_i}=\sigma_M+R\cos\left(2\varphi_i-2\varphi_0\right),\qquad
\tau_{\varphi_i}=-R\sin\left(2\varphi_i-2\varphi_0\right)$$

| Seite | Normalenwinkel | $\sigma$ | $\tau$ |
|---|---|---|---|
| 1 | aus $80^\circ$-Kante | aus Kreis ablesen | aus Kreis ablesen |
| 2 | vertikal | $40$ kN/cm² (**gegeben**) | aus Kreis, $\ne 0$ |
| 3 | schräg ($120^\circ$-Kante) | $=\sigma_I$ oder $\sigma_{II}$ | $\mathbf{0}$ (**gegeben**) |
| 4 | schräg | $53{,}3$ kN/cm² (**gegeben**) | aus Kreis, $\ne0$ |

**Skizze:** Auf jeder Kante $\sigma$ senkrecht und $\tau$ tangential antragen; auf Seite 3 nur
der Normalspannungspfeil. Kontrolle: An jeder Ecke müssen die zugeordneten Schubspannungen
beider angrenzender Seiten **zur Ecke hin oder von ihr weg** zeigen.

---

## Aufgabe 4 — Werkstoffkennwerte aus zwei Versuchen (6 P.)

### Versuch 1 — Zugversuch ⇒ $E_W$

Probe: $L_0=\ell$, Fläche $A$, Kraft $F_1=\dfrac{E_0A}{4}$, gemessen $\Delta L=\dfrac{\ell}{10}$

$$\varepsilon=\frac{\Delta L}{L_0}=\frac{\ell/10}{\ell}=0{,}1
\qquad
\sigma=\frac{F_1}{A}=\frac{E_0}{4}$$

$$\boxed{E_W=\frac{\sigma}{\varepsilon}=\frac{E_0/4}{0{,}1}=\frac{10}{4}E_0=2{,}5\,E_0}$$

### Versuch 2 — Thermische Belastung ⇒ $\alpha_{T,W}$

Der Stab $\overline{AB}$ (Werkstoff W, Länge $2\ell$, Fläche $A$, $\alpha_{T,W}$, $\Delta T$)
dehnt sich; über die starre Scheibe ($EA,EI\to\infty$) wird die Dehnung auf den Stab
$\overline{DE}$ (Länge $2\ell$, $E_0$, $A$) übertragen, in dem $\varepsilon_{DE}=5\,\%=0{,}05$
gemessen wird.

**Kinematik (starre Scheibe, Drehung um C):** Die Verschiebungen der Anschlusspunkte verhalten
sich wie ihre Hebelarme zum Momentanpol. Mit den Geometriemaßen $2\ell$, $3\ell$, $\ell$, $4\ell$
ergibt sich ein Übertragungsfaktor $\kappa$:

$$\Delta\ell_{AB}=\kappa\cdot\Delta\ell_{DE}
\qquad\text{mit}\qquad \kappa=\frac{a_{AB}}{a_{DE}}\ \ \text{(Hebelarmverhältnis)}$$

**Verzerrung des Stabes AB** (Kraft- **und** Temperaturanteil):

$$\varepsilon_{AB}=\frac{N_{AB}}{E_WA}+\alpha_{T,W}\,\Delta T$$

**Gleichgewicht** an der starren Scheibe (Momentengleichgewicht um C) koppelt $N_{AB}$ und
$N_{DE}=\varepsilon_{DE}E_0A=0{,}05\,E_0A$:

$$N_{AB}\cdot a_{AB}=N_{DE}\cdot a_{DE}
\;\Rightarrow\; N_{AB}=\frac{a_{DE}}{a_{AB}}\cdot0{,}05\,E_0A$$

**Auflösen nach $\alpha_{T,W}$:**

$$\boxed{\;\alpha_{T,W}=\frac{1}{\Delta T}\left[\kappa\cdot\varepsilon_{DE}
-\frac{N_{AB}}{E_WA}\right]
=\frac{1}{\Delta T}\left[\kappa\cdot0{,}05-\frac{0{,}05\,E_0}{\kappa\,\cdot2{,}5E_0}\right]\;}$$

$$\Rightarrow\quad \alpha_{T,W}=\frac{0{,}05}{\Delta T}\left(\kappa-\frac{1}{2{,}5\,\kappa}\right)$$

mit $\kappa$ aus der Hebelarmgeometrie der Skizze. **Beide Anteile sind zu berücksichtigen** —
der Stab AB dehnt sich thermisch und wird gleichzeitig durch die Reaktionskraft gestaucht.

---

## Aufgabe 5 — Parallelschaltung zweier Materialien (4 P.)

Dehnstarre Scheibe ⇒ **gleiche Verzerrung** (Parallelschaltung).
Gegeben: $A_1>A_2$, $E_1>E_2$.

$$\varepsilon_1=\varepsilon_2=\varepsilon$$
$$\sigma_i=E_i\varepsilon \;\Rightarrow\; \sigma_1>\sigma_2 \quad(\text{da }E_1>E_2)$$
$$N_i=\sigma_iA_i \;\Rightarrow\; N_1>N_2 \quad(\text{da }\sigma_1>\sigma_2 \text{ und } A_1>A_2)$$

$$\boxed{\varepsilon_1=\varepsilon_2,\qquad \sigma_1>\sigma_2,\qquad N_1>N_2}$$

**Merksatz:** Das steifere und größere Teilsystem „zieht die Last an sich".
Die Lastaufteilung folgt $N_i=F\dfrac{E_iA_i}{E_1A_1+E_2A_2}$.

---

## Aufgabe 6 — Biegenormalspannungsnachweis, Breite $b$ gesucht (7 P.)

Gegeben: $F=15$ kN unter $45^\circ$, Maße $3$ m / $4$ m / $3$ m,
Rechteckquerschnitt $h=0{,}05$ m, $\sigma_{zul}=235$ N/mm².

### Schnittgrößen

Die schräge Kraft wird zerlegt:

$$F_H=F_V=F\cos45^\circ=15\cdot0{,}7071=\mathbf{10{,}61\ kN}$$

* **$N_x$-Verlauf:** abschnittsweise **konstant** (Rechteckform). Im vertikalen Stiel wirkt die
  Vertikalkomponente als Normalkraft $N=-10{,}61$ kN (Druck), im horizontalen Riegel die
  Horizontalkomponente $N=-10{,}61$ kN.
* **$M_y$-Verlauf:** **linear** von null am Lastangriffspunkt bis zum Maximum an der
  Einspannung/maßgebenden Stelle:

$$M_{y,\max}=F_V\cdot a_H+F_H\cdot a_V$$

mit den Hebelarmen $a_H,a_V$ aus der Systemgeometrie (3 m / 4 m / 3 m).
Bei einem Hebelarm von $3$ m für beide Komponenten:

$$M_{y,\max}=10{,}61\cdot3+10{,}61\cdot3=\mathbf{63{,}6\ kNm}$$

*(Der genaue Wert hängt von der Zuordnung der Maße in der Systemskizze ab — der Nachweisweg
bleibt identisch.)*

### Erforderliche Breite

Rechteckquerschnitt: $A=b\,h$, $\;W_y=\dfrac{b\,h^2}{6}$

$$\sigma_{\max}=\frac{|N|}{bh}+\frac{M_y}{bh^2/6}\stackrel{!}{\le}\sigma_{zul}$$

Nach $b$ aufgelöst — $b$ kürzt sich **nicht** heraus, sondern steht in beiden Nennern:

$$\boxed{\;b\ge\frac{1}{\sigma_{zul}}\left(\frac{|N|}{h}+\frac{6M_y}{h^2}\right)\;}$$

Zahlenwerte mit $h=0{,}05$ m $=50$ mm, $\sigma_{zul}=235$ N/mm², $N=10\,610$ N,
$M_y=63{,}6\cdot10^6$ Nmm:

$$b\ge\frac{1}{235}\left(\frac{10\,610}{50}+\frac{6\cdot63{,}6\cdot10^6}{2500}\right)
=\frac{1}{235}\left(212{,}2+152\,640\right)=\boxed{650\ \text{mm}}$$

Der Momentenanteil dominiert vollständig (Faktor $\approx700$ gegenüber der Normalkraft).
Eine Breite von 65 cm bei nur 5 cm Höhe ist konstruktiv unsinnig — **das Profil ist falsch
orientiert**; sinnvoll wäre, $h$ zu vergrößern, da $W_y\sim h^2$.

---

## Aufgabe 7 — Biegelinien $w_1,w_2$ (17 P.)

System: Lager A und B, Gleichlast $q_0$ über den Bereich $6\ell$, Einzelkraft $F=q_0\ell$;
Bereich 2 der Länge $2\ell$. $EA\to\infty$, $EI=$ konst.

### Differentialgleichungen

$$EI\,w_1''''(x_1)=q_0\qquad\qquad EI\,w_2''''(x_2)=0$$

$$EI\,w_1=\frac{q_0}{24}x_1^4+\frac{C_1}{6}x_1^3+\frac{C_2}{2}x_1^2+C_3x_1+C_4$$
$$EI\,w_2=\frac{D_1}{6}x_2^3+\frac{D_2}{2}x_2^2+D_3x_2+D_4$$

**8 Integrationskonstanten ⇒ 8 Rand- und Übergangsbedingungen:**

| # | Bedingung | Typ |
|---|---|---|
| 1 | $w_1(0)=0$ | Lager A |
| 2 | $EIw_1''(0)=0$ | gelenkiges Lager ⇒ $M=0$ |
| 3 | $w_1(6\ell)=0$ | Lager B |
| 4 | $w_1(6\ell)=w_2(0)$ bzw. Stetigkeit | Übergang |
| 5 | $w_1'(6\ell)=w_2'(0)$ | Neigungsstetigkeit |
| 6 | $EIw_1''(6\ell)=EIw_2''(0)$ | Momentenstetigkeit |
| 7 | $EIw_2''(2\ell)=0$ | freies Ende, $M=0$ |
| 8 | $-EIw_2'''(2\ell)=F=q_0\ell$ | freies Ende, Querkraft $=F$ |

### Schnittgrößen zur Kontrolle

$$M_y=-EIw'',\qquad Q_z=-EIw'''$$

Der Kragarm (Bereich 2) überträgt an der Stelle B das Moment

$$M_B=-F\cdot2\ell=-2q_0\ell^2$$

Dieses Kragmoment wirkt als Randmoment auf den Feldbereich 1 und **hebt die Feldmitten­durchbiegung
teilweise auf**. Die maximale Durchbiegung liegt dadurch nicht in Feldmitte, sondern zur
Seite A hin verschoben.

**Kontrolle der Lösung:**
* $w$ an beiden Lagern null,
* Momentenverlauf am Kragarm linear mit $M(2\ell)=0$,
* Feldmoment im Bereich 1 parabolisch mit Randwert $-2q_0\ell^2$ bei B.

---

## Aufgabe 8 — Kragträger, zweiachsige Biegung (15 P.)

Gegeben: $\ell=200$ cm, $F_x=40$ kN, $F_y=0{,}3$ kN, $q_0=0{,}1$ kN/cm²,
$A=18$ cm², $I_y=33{,}8$ cm⁴, $I_z=21{,}0$ cm⁴

### a) Schnittgrößen bei $x=\ell/2=100$ cm

$$N=-F_x=-40\ \text{kN}\quad(\text{Druck, in Stabachse})$$

$$M_z\big(\tfrac{\ell}{2}\big)=F_y\cdot\frac{\ell}{2}=0{,}3\cdot100=\mathbf{30\ kNcm}$$

$$M_y\big(\tfrac{\ell}{2}\big)=\frac{q_z}{2}\left(\frac{\ell}{2}\right)^2$$

mit der auf die Länge bezogenen Streckenlast $q_z=q_0\cdot b$ ($b$ = belastete Breite des
Querschnitts, aus der Skizze: $b=3$ cm ⇒ $q_z=0{,}3$ kN/cm):

$$M_y=\frac{0{,}3}{2}\cdot100^2=\mathbf{1500\ kNcm}$$

### b) Biegenormalspannung

Da der Querschnitt **einfach symmetrisch** ist und $I_{yz}=0$ angenommen wird
(die Aufgabe gibt nur $I_y,I_z$), gilt die einfache Superposition:

$$\boxed{\;\sigma_x(y,z)=\frac{N}{A}+\frac{M_y}{I_y}\,z+\frac{M_z}{I_z}\,y\;}$$

$$\sigma_x(y,z)=\frac{-40}{18}+\frac{1500}{33{,}8}z+\frac{30}{21{,}0}y
=-2{,}22+44{,}38\,z+1{,}43\,y\quad\left[\tfrac{\text{kN}}{\text{cm}^2}\right]$$

### c) Extremwerte

Die Extrema liegen in den **am weitesten von der neutralen Faser entfernten Eckpunkten**.
Mit den Randabständen aus der Skizze ($z$-Ränder bei $+2{,}3$ cm und $-2{,}7$ cm,
$y$-Ränder bei $\pm2$ cm):

$$\sigma_{\max}=-2{,}22+44{,}38\cdot2{,}3+1{,}43\cdot2=\mathbf{+98{,}9\ \tfrac{kN}{cm^2}}$$
$$\sigma_{\min}=-2{,}22-44{,}38\cdot2{,}7-1{,}43\cdot2=\mathbf{-125{,}9\ \tfrac{kN}{cm^2}}$$

Der Biegeanteil aus $M_y$ dominiert um mehr als eine Größenordnung.

### d) Kernfläche

$$i_y^2=\frac{I_y}{A}=\frac{33{,}8}{18}=1{,}878\ \text{cm}^2,\qquad
i_z^2=\frac{I_z}{A}=\frac{21{,}0}{18}=1{,}167\ \text{cm}^2$$

Kernpunkte (jeweils gegenüberliegend zum betrachteten Rand):

$$k_{z,o}=\frac{i_y^2}{e_u}=\frac{1{,}878}{2{,}7}=0{,}696\ \text{cm},\qquad
k_{z,u}=\frac{i_y^2}{e_o}=\frac{1{,}878}{2{,}3}=0{,}817\ \text{cm}$$
$$k_{y}=\frac{i_z^2}{e_y}=\frac{1{,}167}{2{,}0}=0{,}583\ \text{cm}$$

**Skizze:** Ein **konvexes Viereck** um $S$ mit den Eckpunkten bei
$(0\,|\,{-0{,}696})$, $(0\,|\,{+0{,}817})$, $(\pm0{,}583\,|\,0)$ — deutlich in $z$-Richtung
verschoben, da der Querschnitt unsymmetrisch zur $y$-Achse ist.

---

## Aufgabe 9 — Schubspannungen am dünnwandigen Querschnitt (12 P.)

Gegeben: $F=10$ kN, $A=66$ cm², $I_y=949{,}09$ cm⁴, $I_z=1782$ cm⁴,
Kastenquerschnitt $12\times18$ cm, Wanddicken $1$ und $2$ cm.

### a) Schubspannung im **geschlossenen** Querschnitt

$$\tau_F(s)=\frac{Q_z\,S_y(s)}{I_y\,t(s)}+\tau_0$$

Beim geschlossenen (einzelligen) Querschnitt tritt ein **konstanter Umlaufschubfluss $T_0$**
hinzu, der aus der Verträglichkeitsbedingung folgt:

$$\oint\frac{\tau}{G}\,\mathrm ds=0\quad\Longrightarrow\quad
T_0=-\frac{\displaystyle\oint\frac{Q_zS_y}{I_yt}\,\mathrm ds}{\displaystyle\oint\frac{\mathrm ds}{t}}$$

**Vorgehen für die Skizzen:**
1. Querschnitt an einer Stelle **gedanklich aufschneiden** ⇒ offenes Ersatzsystem.
2. $S_y(s)$ umlaufend berechnen (in den Gurten linear, in den Stegen quadratisch).
3. $\tau^{(0)}=\dfrac{Q_zS_y}{I_yt}$ auftragen.
4. Konstanten Anteil $T_0/t$ überlagern.

**Charakteristik:** Kein Nullpunkt an den Ecken; $\tau$ ist **umlaufend geschlossen**,
Maximum in den Stegen auf Höhe der neutralen Faser, Sprünge an den Dickenwechseln
($1\to2$ cm), Schubfluss $T=\tau t$ bleibt stetig.

### b) Oben **eingeschlitzter** Querschnitt

Der Schlitz macht den Querschnitt **offen**:

* $T_0$ entfällt ⇒ $\tau(s)=\dfrac{Q_zS_y}{I_yt}$ mit $\;\tau=0$ **an beiden Schlitzufern**.
* Der Verlauf startet und endet bei null, das Maximum verschiebt sich in die Stegmitte.
* **Die Torsionssteifigkeit bricht dramatisch ein** ($I_T$ des offenen Profils ist um Größen­ordnungen
  kleiner als beim geschlossenen), die Biegesteifigkeit ändert sich dagegen kaum.

### c) Qualitative Verläufe der drei Querschnitte

| Querschnitt | Charakteristik des $\tau$-Verlaufs |
|---|---|
| Geschlossener Kasten | umlaufend, nirgends null, Sprünge nur an Dickenwechseln |
| Offenes I/U-Profil | null an allen freien Enden, parabolisch im Steg, linear in den Flanschen, Maximum in der neutralen Faser |
| Offenes Profil mit Schlitz | wie offenes Profil, $\tau=0$ am Schlitz, stark reduzierte Torsionssteifigkeit |

**Universelle Kontrollen:** $\tau=0$ an jedem freien Rand · $\int\tau t\,\mathrm ds=Q_z$ ·
Schubfluss an Knoten ist knotenweise ausgeglichen (Kirchhoff'sche Knotenregel).

---

## Aufgabe 10 — Torsion eines Rohres mit veränderlicher Dicke (6 P.)

Gegeben: Radius $r$, Länge $\ell$, Streckenmoment $m$, Einzelmoment $M$ am Ende.

### a) Torsionsmomentenverlauf

Schnitt an der Stelle $x$, Gleichgewicht am rechten Teilstück:

$$\boxed{\;M_T(x)=M+m\,(\ell-x)\;}$$

**Verlauf:** linear abfallend von $M_T(0)=M+m\ell$ an der Einspannung auf
$M_T(\ell)=M$ am freien Ende.

### b) Dicke $t(x)$ für konstante Schubspannung

Dünnwandiges **geschlossenes** Profil ⇒ 1. Bredt'sche Formel mit
$A_m=\pi r^2$ (von der Mittellinie umschlossene Fläche):

$$\tau=\frac{M_T(x)}{2A_m\,t(x)}\stackrel{!}{=}\tau_0=\text{konst.}$$

$$\boxed{\;t(x)=\frac{M_T(x)}{2A_m\tau_0}=\frac{M+m(\ell-x)}{2\pi r^2\,\tau_0}\;}$$

Die Dicke nimmt **linear** von $t(0)=\dfrac{M+m\ell}{2\pi r^2\tau_0}$ auf
$t(\ell)=\dfrac{M}{2\pi r^2\tau_0}$ ab — das Material folgt exakt der Beanspruchung
(Leichtbau-Optimum).

### c) Torsionsträgheitsmoment

2. Bredt'sche Formel für das dünnwandige Kreisrohr ($t=$ konst. über den Umfang):

$$I_T=\frac{4A_m^2}{\displaystyle\oint\frac{\mathrm ds}{t}}
=\frac{4\left(\pi r^2\right)^2}{\dfrac{2\pi r}{t(x)}}
=2\pi r^3\,t(x)$$

Mit $t(x)$ aus b):

$$\boxed{\;I_T(x)=2\pi r^3\cdot\frac{M+m(\ell-x)}{2\pi r^2\tau_0}
=\frac{r\,\bigl[M+m(\ell-x)\bigr]}{\tau_0}=\frac{r\,M_T(x)}{\tau_0}\;}$$

**Elegante Kontrolle:** $\tau=\dfrac{M_T\,t}{2A_m t}$ und $I_T=\dfrac{rM_T}{\tau_0}$ liefern
$\vartheta'=\dfrac{M_T}{GI_T}=\dfrac{\tau_0}{Gr}=$ **konstant** — bei konstanter Schubspannung
ist auch die Verdrillung über die gesamte Länge konstant.

---

## Ergebnisübersicht

| Aufgabe | Ergebnis |
|---|---|
| 1a | $\sigma_{xx}=10$ (Zug), $\sigma_{yy}=-4$ (Druck), $\tau_{xy}=\tau_{yx}=25$ |
| 2 | $I_{yz}<0$; Superposition mit negativen Lochflächen |
| 3 | Seite 3 = Hauptspannungsebene ⇒ Bildpunkt auf der $\sigma$-Achse |
| 4 | $E_W=2{,}5\,E_0$; $\alpha_{T,W}=\frac{0{,}05}{\Delta T}\left(\kappa-\frac{1}{2{,}5\kappa}\right)$ |
| 5 | $\varepsilon_1=\varepsilon_2$, $\sigma_1>\sigma_2$, $N_1>N_2$ |
| 6 | $F_H=F_V=10{,}61$ kN; $b\ge\frac{1}{\sigma_{zul}}\left(\frac{N}{h}+\frac{6M_y}{h^2}\right)$ |
| 8a | $N=-40$ kN, $M_y=1500$ kNcm, $M_z=30$ kNcm |
| 8d | $i_y^2=1{,}878$ cm², $i_z^2=1{,}167$ cm² |
| 10 | $M_T=M+m(\ell-x)$, $t(x)=\frac{M_T}{2\pi r^2\tau_0}$, $I_T=\frac{rM_T}{\tau_0}$ |
