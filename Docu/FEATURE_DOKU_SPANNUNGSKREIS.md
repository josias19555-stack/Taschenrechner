# Spannungskreis (Spannungskreis/Spannungskreis.lua)

Ebener Spannungszustand, eingegeben über **Schnitte**. Das Skript braucht kein CAS; alle
Rechenschritte sind geschlossen lösbar (Kapitel 4 und 5).

## 1. Tabelle: Eingabe und Ergebnis in einem

Es gibt nur **eine** Tabelle, und sie ist immer editierbar. Spalten sind die Schnitte, Zeilen
sind die drei Größen:

| Zeile | Bedeutung |
|---|---|
| $\alpha$ [°] | Winkel der **Schnittnormalen** gegen die x-Achse, **mathematisch positiv** (gegen den Uhrzeigersinn). Der Hinweis steht über der Tabelle. |
| $\sigma$ | Normalspannung in diesem Schnitt |
| $\tau$ | Schubspannung in diesem Schnitt (Tangente = Normale um $+90^\circ$ gedreht) |

- **Leere Zellen sind unbekannt** und werden berechnet; berechnete Werte stehen **grün**,
  eingegebene **schwarz**.
- Rechts neben dem letzten Schnitt steht eine Spalte `neu`: Schreibt man dort etwas hinein,
  entsteht ein weiterer Schnitt. So viele Schnitte wie nötig.
- Nach jeder übernommenen Zelle wird sofort neu gerechnet – die Ergebnisse unter der Tabelle und
  die Statuszeile sind also immer aktuell. `b` rechnet zusätzlich auf Wunsch und wirft eine
  leere letzte Spalte weg.
- Eingaben dürfen Ausdrücke sein (`10*2`, `sqrt(2)`, `1,5`); mit CAS wird `approx(...)` benutzt,
  ohne CAS ein Lua-Ausdruck.
- Gibt es für einen berechneten Winkel zwei Lösungen, steht die zweite klein hinter dem Wert
  (`|117.0`).
- Alle Beschriftungen passen sich der Bildschirmbreite an: Hinweis-, Status- und Ergebniszeilen
  werden bei Bedarf gekürzt, die Zeilenbeschriftung links notfalls kleiner gesetzt. Nichts läuft
  über den Rand, und das markierte Eingabefeld liegt genau auf der Zeile, die links beschriftet
  ist.

Unter der Tabelle stehen $\sigma_1$, $\sigma_2$, $\sigma_m$, $R = \tau_{max}$, die Hauptrichtung
$\alpha_1$ (und der Winkel für $\tau_{max}$) sowie $\sigma_x$, $\sigma_y$, $\tau_{xy}$; der Block
nutzt den Platz bis zum unteren Rand.

## 2. Tasten

| Taste | Wirkung |
|---|---|
| Pfeile | Tabelle: Zelle wählen (links/rechts Schnitt, oben/unten $\alpha$/$\sigma$/$\tau$); Kreis: Marke bewegen (links/rechts Schnitt, oben/unten 5°) |
| Ziffer, `.`, `-`, `+`, `(` | beginnt sofort eine neue Eingabe in der Zelle |
| `Enter` | Zelle zum Ändern öffnen (mit dem alten Wert vorbelegt) bzw. übernehmen; danach geht es $\alpha \to \sigma \to \tau \to$ nächster Schnitt |
| `Backspace` | beim Ändern ein Zeichen löschen, sonst die Zelle leeren (Wert wird wieder berechnet) |
| `b` | rechnen |
| `s` | Spannungsscheibe |
| `k` | Mohrscher Spannungskreis |
| `t`, `e` | zurück zur Tabelle |
| `Del`, `Clear` | alles löschen – mit Rückfrage (`Enter` löscht, `Esc` bricht ab) |
| `Esc` | Rückfrage/Änderung abbrechen, sonst zurück zur Tabelle |

**Gesperrt:** `s` und `k` funktionieren nur, wenn der Zustand eindeutig bestimmt **und**
widerspruchsfrei ist. Sonst bleibt das Programm in der Tabelle und sagt, warum.

## 3. Ansichten

**Spannungsscheibe (`s`):** Gezeichnet wird im Koordinatensystem des Querschnitts: **x zeigt
nach unten, y nach rechts**. Ein Punkt $(x, y)$ landet also bei $(c_x + y,\ c_y + x)$, eine
Richtung entsprechend; ein Schnitt mit $\alpha = 0$ hat seine Normale nach unten und liegt damit
an der Unterkante. Ein wachsendes $\alpha$ dreht auf dem Bildschirm weiter gegen den
Uhrzeigersinn, passt also zur Zählweise in der Tabelle.

Die Scheibe ist ein **Vieleck mit einer Kante je Schnitt** –
gebildet als Schnitt der Halbebenen $\vec n_i \cdot \vec x \le r$. Decken die Normalen nicht den
ganzen Umfang ab (z. B. nur zwei Schnitte), kommen die Rückseiten $-\vec n_i$ dazu, damit die
Scheibe geschlossen ist; zwei senkrechte Schnitte ergeben so das übliche Rechteck, die
Rückseitenkante ist mit `R` gekennzeichnet. An **jeder** Kante werden Normalspannung (rot, längs
der Normalen; Zug nach außen, Druck auf die Kante zu) und Schubspannung (blau, längs der Kante)
gezeichnet, dazu die Beschriftung `S_i (α)`, `σ=…`, `τ=…` außerhalb der Kante. Kleine Werte
bekommen eine Mindestpfeillänge, damit nichts unsichtbar bleibt.

**Mohrscher Kreis (`k`):** $\sigma$ waagerecht, $\tau$ senkrecht nach oben, Kreis um
$(\sigma_m, 0)$ mit Radius $R$; Hauptspannungen und Mittelpunkt sind markiert, jeder Schnitt ist
als Punkt mit Radiusstrahl eingezeichnet. Bei wachsendem $\alpha$ wandern die Punkte im
Uhrzeigersinn (Drehung im Kreis: $2\alpha$).

Mit den **Pfeiltasten** wandert eine Marke über den Kreis: links/rechts springt zyklisch von
Schnittwinkel zu Schnittwinkel, hoch/runter dreht in 5-Grad-Schritten frei weiter (Winkel modulo
$180^\circ$, denn $\sigma(\alpha)$ und $\tau(\alpha)$ haben diese Periode). Die Marke wird als
oranger Punkt mit Radiusstrahl gezeichnet und unten mit `S<i>  α = …°   σ = …   τ = …`
beschriftet – so liest man den Zustand in jedem Schnitt ab, auch in einem, der gar nicht
eingegeben wurde. `Del` setzt die Marke zurück.

Gezeichnet wird in einem **klassischen Koordinatensystem**: Die $\tau$-Achse steht bei
$\sigma = 0$, der Nullpunkt ist mit `0` beschriftet. Der Ausschnitt umfasst dafür den Bereich von
$\min(0,\ \sigma_m - R)$ bis $\max(0,\ \sigma_m + R)$. Damit der Kreis dabei nicht zur Murmel wird,
gilt ein Mindestradius von 35 px: Liegt der Zustand sehr weit vom Ursprung entfernt (etwa
$\sigma_m = 999$, $R = 1$), hat der Kreis Vorrang, und der Nullpunkt wird stattdessen mit einer
gepunkteten Linie und `σ=0 →` am Bildrand vermerkt.

## 4. Wann ist der Zustand bestimmt?

Mit $\sigma_m = \frac{\sigma_x+\sigma_y}{2}$, $R_c = \frac{\sigma_x-\sigma_y}{2}$,
$R_s = \tau_{xy}$ gilt für einen Schnitt mit bekanntem Winkel

$$\sigma(\alpha) = \sigma_m + R_c\cos 2\alpha + R_s\sin 2\alpha, \qquad
  \tau(\alpha) = -R_c\sin 2\alpha + R_s\cos 2\alpha .$$

Beide Gleichungen sind in $(\sigma_m, R_c, R_s)$ **linear**. Jede Angabe ist damit eine lineare
Gleichung; **drei unabhängige Angaben** bestimmen den Zustand eindeutig. Gelöst wird mit Gauß und
Spaltenpivot, dabei wird der Rang gezählt – „eindeutig bestimmt" meldet das Programm erst bei
Rang 3. Parallele Schnitte oder wiederholte Angaben erhöhen den Rang nicht.

Sind mehr Angaben vorhanden als nötig, werden die überzähligen Zeilen geprüft: passen sie nicht,
erscheint **Eingaben widersprechen sich** und die Ansichten bleiben gesperrt.

## 5. Unbekannte Winkel

Steht der Zustand fest, folgt ein fehlender Winkel geschlossen aus
$\sigma = \sigma_m + R\cos(2\alpha-\varphi)$ und $\tau = -R\sin(2\alpha-\varphi)$ mit
$\varphi = \operatorname{atan2}(R_s, R_c)$:

| gegeben | Lösung | Anzahl |
|---|---|---|
| $\sigma$ und $\tau$ | $2\alpha = \varphi + \operatorname{atan2}(-\tau,\ \sigma-\sigma_m)$ | eindeutig (mod $180^\circ$) |
| nur $\sigma$ | $2\alpha = \varphi \pm \arccos\frac{\sigma-\sigma_m}{R}$ | zwei |
| nur $\tau$ | $2\alpha = \varphi + \arcsin\frac{-\tau}{R}$ bzw. $\varphi + \pi - \arcsin\frac{-\tau}{R}$ | zwei |

Liegt der Wert nicht auf dem Kreis ($|\sigma-\sigma_m| > R$ bzw. $|\tau| > R$), steht der Grund
unter der Tabelle. Ein CAS wird an keiner Stelle gebraucht.

## 6. Grenzen

- Schnitte **ohne** Winkel tragen nichts zur Bestimmung bei; sie werden erst ausgewertet, wenn
  der Zustand aus anderen Angaben feststeht. Sind nur die Winkel *zwischen* Schnitten bekannt:
  den ersten Schnitt auf $0^\circ$ setzen, die anderen relativ dazu.
- Ebener Spannungszustand, keine räumlichen Zustände, kein Verformungskreis.
- Einen ganzen Schnitt löscht man, indem man seine drei Zellen leert (`Backspace`); `Del` beginnt
  komplett neu.
