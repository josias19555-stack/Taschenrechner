# Projektrichtlinien

## Dokumentationspflicht (automatisch, ohne Nachfrage)
Bei jeder Aenderung an einem Lua-Skript muessen die passenden Dokumentationen im Ordner `Docu` aktualisiert werden:
- Aenderungen an `Querschnitt.lua`: `Docu/FUNKTIONSDOKU_QUERSCHNITT.md` und `Docu/FEATURE_DOKU_QUERSCHNITT.md`.
- Aenderungen an `AktuellerStand.lua` oder `Zeichnen.lua`: `Docu/FUNKTIONSDOKU_TRAGWERK.md` und `Docu/FEATURE_DOKU_TRAGWERK.md`.
- Wenn eine Aenderung die gemeinsame Schnittstelle oder sichtbare Gesamtfunktion betrifft, beide Modulpaare pruefen und bei Bedarf beide aktualisieren.
- Neue Funktion/neuer Befehl hinzugefuegt -> neuen Eintrag ergaenzen.
- Bestehende Funktion geaendert -> Zweck/Moeglichkeiten/Grenzen im bestehenden Eintrag anpassen.
- Funktion entfernt -> Eintrag loeschen.
- Neues Feature hinzugefuegt -> im passenden `FEATURE_DOKU_*.md` ergaenzen.
- Bestehendes Feature geaendert oder entfernt -> den passenden Eintrag im passenden `FEATURE_DOKU_*.md` anpassen oder loeschen.
- Format je Eintrag: **Zweck**, **Moeglichkeiten**, **Grenzen/bekannte Einschraenkungen**.
- Gruppierung nach den bestehenden `-- === ... ===`-Abschnitten in der Datei.
- Das gilt automatisch in jeder Session, auch in neuen Chats, ohne dass der Nutzer es erneut erwaehnen muss.

## Build/Test
Syntaxpruefung nach jeder Aenderung:
Nach jeder Lua-Aenderung die Syntax der betroffenen Datei(en) pruefen, zum Beispiel:
`lua -e "local f=assert(io.open('Querschnitt.lua','rb')); local s=f:read('*a'); f:close(); if s:sub(1,3)==string.char(239,187,191) then s=s:sub(4) end; assert(loadstring(s))"`
`lua -e "local f=assert(io.open('AktuellerStand.lua','rb')); local s=f:read('*a'); f:close(); if s:sub(1,3)==string.char(239,187,191) then s=s:sub(4) end; assert(loadstring(s))"`
`Zeichnen.lua` wird als gemeinsam eingebundener Teil des Tragwerksmoduls ebenfalls auf Syntaxfehler geprueft.

## TI-Nspire-Lua-Einschraenkung
Maximal 60 lokale Upvalues pro Funktion. Bei Fehler "more than 60 upvalues" betroffene Variable global statt lokal deklarieren (siehe bereits so behandelte Faelle: `kernMode`, `torsion_xi`).
