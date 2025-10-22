# FINALER FORENSISCHER ANALYSEBERICHT: Godot Tactical RPG Projekt

**Datum der Analyse:** 2025-10-22
**Analyst:** Leitender Godot 4 Engine-Architekt
**Analyse-Umfang:** Vollständiges Projekt-Repository und Kontextdokument.
**Ziel:** Umfassende Identifizierung aller Fehler, Risiken, Inkonsistenzen und Code Smells.

---

## METHODIK

Dieser Bericht ist das Ergebnis einer mehrstufigen statischen Analyse. Zunächst wurden die im bereitgestellten Kontextdokument genannten Probleme verifiziert. Anschließend wurden automatisierte Skripte zur projektweiten Überprüfung von Ressourcen-Pfaden (`res://`) und -Identifiern (`uid://`) eingesetzt. **Wichtiger Hinweis:** Die automatisierten Werkzeuge zeigten aufgrund von Limitierungen im Umgang mit Godots `res://`-Protokoll eine hohe Rate an Falsch-Positiven. Daher wurden alle potenziellen Fehler manuell gegengeprüft, um die Korrektheit der hier dokumentierten Befunde sicherzustellen. Die Analyse umfasste zudem die manuelle Überprüfung der Projektkonfiguration, der Szenen-Integrität und der Kern-Logik-Skripte.

---

## ZUSAMMENFASSUNG (EXECUTIVE SUMMARY)

Die statische Analyse des Projekts offenbart eine Codebasis mit einer soliden architektonischen Vision (Model/Module/Service), die jedoch in der Umsetzung von kritischen Fehlern und signifikanten Risiken für die Wartbarkeit untergraben wird.

Die schwerwiegendsten Befunde sind **defekte Ressourcen- und Autoload-Pfade**, die zu garantierten Laufzeitfehlern und einem unmittelbaren Absturz beim Start führen. Darüber hinaus ist der **Pathfinding- und Interaktionsmechanismus für prozedurale Karten fundamental fehlerhaft**, was das Kern-Gameplay unspielbar macht. Eine ineffiziente und fehleranfällige Handhabung von Karten-Assets (`test_arena.tscn`) sowie brüchige, hartkodierte Abhängigkeiten zwischen Modulen erschweren zukünftige Änderungen am Projekt extrem.

Eine Überarbeitung der identifizierten kritischen Punkte ist zwingend erforderlich, bevor dieses Projekt als stabile Vorlage oder Grundlage für eine Weiterentwicklung dienen kann.

---

## KATEGORIE 1: KRITISCHE FEHLER (BLOCKER)

Diese Fehler verhindern die Lauffähigkeit wesentlicher Teile des Projekts oder führen garantiert zu Abstürzen.

### 1.1: Defekter Autoload-Pfad in `project.godot` (**NEUER FUND**)

*   **Was:** Die `project.godot`-Datei konfiguriert einen Autoload für `DebugMenu`, der auf eine nicht existierende Szene verweist.
*   **Wo:** `project.godot` (Zeile 27): `DebugMenu="*res://addons/debug_menu/debug_menu.tscn"`
*   **Warum:** Godot versucht beim Start, diese Szene zu laden. Da die Datei nicht existiert, wird der Start des gesamten Projekts mit einem Fehler fehlschlagen.

### 1.2: Defekte Ressourcenpfade (fehlende .tres-Dateien)

*   **Was:** Mehrere zentrale Skripte versuchen, Konfigurations-Ressourcen (`.tres`-Dateien) zu laden, die im Projektverzeichnis nicht existieren.
*   **Wo:**
    *   `data/modules/tactics/camera/camera.gd` (Zeile 13, 15)
    *   `data/modules/tactics/controls/controls.gd` (Zeile 10, 12, 14, 16)
    *   `data/modules/tactics/level/participants/tactics_participant.gd` (Zeile 10, 12, 14)
*   **Fehlende Dateien:**
    *   `res://data/models/view/camera/tactics/camera.tres`
    *   `res://data/models/view/control/tactics/control.tres`
    *   `res://data/models/world/combat/participant/participant.tres`
    *   `res://data/models/world/combat/arena/arena.tres`
*   **Warum:** Der `load()`-Befehl schlägt fehl, wenn die Zieldatei nicht existiert. Dies führt unweigerlich zu einem Absturz, sobald eine Szene gestartet wird, die diese Skripte verwendet.

### 1.3: Defekter Pfad zur Test-Level-Szene

*   **Was:** Das Hauptmenü-Skript versucht, die Szene `test_level.tscn` zu laden, die unter dem konstruierten Pfad nicht existiert.
*   **Wo:** `data/main.gd` (Zeile 46): `var level_path: String = "res://assets/maps/level/%s_level.tscn" % "test"`
*   **Warum:** Ein Klick auf den "Map 1"-Button führt zu einem Absturz, da die zu ladende Szene nicht gefunden werden kann.

### 1.4: Ungültiger Node-Pfad (`%TacticsArena`)

*   **Was:** Das Skript `tactics_participant.gd` verwendet den Unique-Name-Identifier `%TacticsArena`. In der Szenenstruktur (`procedural_level.tscn`) ist `TacticsArena` jedoch ein Geschwisterknoten, kein Kindknoten.
*   **Wo:** `data/modules/tactics/level/participants/tactics_participant.gd` (Zeile 21)
*   **Warum:** Dies führt zu einem Laufzeitfehler, da der Knoten nicht gefunden werden kann. Die Referenz wird `null` sein, was zu Folgefehlern führt.

### 1.5: Logikfehler im Pathfinding für prozedurale Karten

*   **Was:** Die Pathfinding-Logik in `TacticsArenaService` schließt prozedurale Kacheln explizit von der Verarbeitung aus.
*   **Wo:** `data/models/world/combat/arena/service/service.gd` (Zeile 42): `if _curr_tile is ProceduralTile: continue`
*   **Warum:** Dies bedeutet, dass für prozedurale Karten keine Pfade berechnet werden können. Die KI kann sich nicht bewegen, und die Reichweitenanzeige für den Spieler wird nicht funktionieren. Das Kern-Gameplay auf prozeduralen Karten ist damit defekt.

---

## KATEGORIE 2: ARCHITEKTUR- & WARTBARKEITSRISIKEN

### 2.1: Brüchige Singleton-Implementierung via Autoload

*   **Was:** Die Welterzeugung (`WorldGeneration.gd`) ist von einem globalen Autoload (`WorldService`) abhängig, um ihren Zustand (die Liste der prozeduralen Kacheln) zu speichern und für andere Skripte zugänglich zu machen.
*   **Wo:** `scripts/WorldGeneration.gd` (Zeile 14), `project.godot` (Zeile 26)
*   **Warum:** Dies ist eine Form von hartkodierter, globaler Abhängigkeit. Es macht den Code schwerer zu testen und wiederzuverwenden, da eine Abhängigkeit zum `WorldService`-Singleton besteht.

### 2.2: Hartkodierte relative Node-Pfade

*   **Was:** Mehrere Skripte verwenden `get_node("../...")`, um auf Geschwisterknoten zuzugreifen, was eine starre Abhängigkeit von der Szenenstruktur schafft.
*   **Wo:**
    *   `data/modules/tactics/level/participants/player/tactics_player.gd` (Zeile 26): `get_node("../TacticsOpponent")`
    *   `data/modules/tactics/level/participants/opponent/tactics_opponent.gd` (Zeile 30): `get_node("../TacticsPlayer")`
*   **Warum:** Jede Änderung der Hierarchie in der Szene führt dazu, dass dieser Code bricht und Laufzeitfehler verursacht, ohne dass der Editor oder Compiler eine Warnung ausgibt.

### 2.3: Ineffiziente Asset-Speicherung in `test_arena.tscn`

*   **Was:** Die Szenendatei `test_arena.tscn` ist extrem groß, da sie die gesamten Vertex-Daten für hunderte von Kacheln als `[sub_resource type="ArrayMesh" ...]` direkt einbettet.
*   **Wo:** `assets/maps/level/arena/test_arena.tscn`
*   **Warum:** Dies ist extrem ineffizient für die Versionskontrolle (Git), macht das Mergen fast unmöglich und verlangsamt das Laden der Szene. Die empfohlene Godot-Lösung hierfür ist eine `GridMap` mit einer `MeshLibrary`.

### 2.4: Falsche Skriptzuweisung in `procedural_level.tscn`

*   **Was:** Das Skript `WorldGeneration.gd` ist direkt an einen Node in `procedural_level.tscn` angehängt.
*   **Wo:** `assets/maps/level/procedural_level.tscn`
*   **Warum:** Da die Logik über das `WorldService`-Singleton global zugänglich gemacht wird, ist diese Instanziierung in der Szene redundant. Es widerspricht dem Singleton-Konzept und kann zu unvorhersehbarem Verhalten führen, wenn die Szene entladen und die Instanz zerstört wird.

---

## KATEGORIE 3: LOGIKFEHLER & BUGS

### 3.1: Doppelte Generierung der prozeduralen Welt

*   **Was:** Die `_ready()`-Funktion in `WorldGeneration.gd` ruft `generate_new_cubes_from_position()` zweimal hintereinander auf.
*   **Wo:** `scripts/WorldGeneration.gd` (Zeile 12 und 15)
*   **Warum:** Die gesamte Karte wird unnötigerweise zweimal generiert, was die Ladezeit ohne jeden Nutzen verdoppelt.

### 3.2: Fehlerhafte Kachel-Suche für prozedurale Karten

*   **Was:** `WorldGeneration.gd` speichert prozedurale Kacheln in einem Dictionary mit einem `Vector3`-Schlüssel, der eine `float`-Höhe verwendet. Das `pawn.gd`-Skript versucht jedoch, die Kachel mit einem Schlüssel zu finden, der eine gerundete `int`-Höhe vom Raycast-Kollisionspunkt verwendet.
*   **Wo:**
    *   `scripts/WorldGeneration.gd` (Zeile 40): `procedural_tiles[Vector3(x, height, z)] = proc_tile`
    *   `data/modules/tactics/level/pawn/pawn.gd` (Zeile 90): `var search_key = Vector3(x, y, z)` (wobei y `int(round(collision_point.y))` ist)
*   **Warum:** Ein Dictionary-Lookup erfordert eine exakte Schlüsselübereinstimmung. Da ein gerundeter Integer-Wert fast nie exakt dem ursprünglichen Float-Wert entspricht, schlägt die Suche für praktisch jede Kachel fehl. Die Interaktion auf prozeduralen Karten ist damit fundamental defekt.

### 3.3: KI-Zielsystem-Absturzrisiko

*   **Was:** Das Skript `oppnt_serv.gd` greift auf `res.targets.get_children()` zu. Obwohl die Variable `targets` in der Ressource existiert, wird sie mit `null` initialisiert und es ist nicht garantiert, dass sie vor diesem Zugriff zugewiesen wird.
*   **Wo:** `data/models/world/combat/participant/opponent_service/oppnt_serv.gd` (Zeile 101)
*   **Warum:** Wenn die KI-Logik in einer unerwarteten Reihenfolge aufgerufen wird, ist `res.targets` `null`, was zu einem Absturz führt, wenn `get_children()` darauf aufgerufen wird.

---

## KATEGORIE 4: PERFORMANCE-PROBLEME

### 4.1: Ineffiziente Kachel-Suche durch lineare Iteration

*   **Was:** Das Skript `input.gd` versucht, eine prozedurale Kachel zu finden, indem es bei jeder Mausbewegung über alle Werte im `procedural_tiles`-Dictionary iteriert und den Collider vergleicht.
*   **Wo:** `data/models/view/control/tactics/service/input.gd` (Zeile 30-33)
*   **Warum:** Dies ist eine O(n)-Operation, die bei jeder Mausbewegung ausgeführt wird. Bei einer großen Karte führt dies zu unnötiger CPU-Last. Eine direkte Dictionary-Suche mit einem korrigierten Schlüssel (siehe 3.2) wäre eine O(1)-Operation und wesentlich performanter.

---

## KATEGORIE 5: INKONSISTENZEN & CODE SMELLS

### 5.1: Projekt-Konfiguration

*   **Was:** Die `project.godot`-Datei enthält veraltete Konfigurationen. Zudem wurde die `InputMap` auf ungenutzte Aktionen überprüft.
*   **Wo:** `project.godot`
*   **Details:**
    *   **Veraltete Ordnerfarben:** Die `[file_customization]`-Sektion definiert Farben für nicht mehr existierende Ordner (`res://maps/`, `res://modules/`).
    *   **InputMap:** Eine Überprüfung aller in der `InputMap` definierten Aktionen hat ergeben, dass **alle Aktionen** im Code verwendet werden. Es gibt hier keine Leichen.
*   **Warum:** Veraltete Konfigurationen sollten bereinigt werden, um die Datei sauber zu halten. Die Überprüfung der InputMap war ein Teil der Analyse-Checkliste.

### 5.2: Ressourcen-Konsistenz

*   **Was:** Eine projektweite Analyse der Ressourcen-Identifier (`.uid`-Dateien und `uid://`-Referenzen) wurde durchgeführt.
*   **Ergebnis:** Es wurden **keine doppelten oder verwaisten UIDs** gefunden. Die Ressourcen-Konsistenz in diesem Bereich ist intakt.
*   **Warum:** Dieser Punkt wurde im Rahmen der forensischen Checkliste überprüft, um sicherzustellen, dass keine Referenzen auf gelöschte Ressourcen bestehen.

### 5.3: Redundante und temporäre Dateien (**NEUER FUND**)

*   **Was:** Das Projektverzeichnis enthält eine Backup-Szene und zahlreiche `.tmp`-Dateien.
*   **Wo:**
    *   `assets/maps/level/procedural_level_backup.tscn`
    *   Diverse `.tmp`-Dateien in `data/modules/tactics/controls`, `assets/scene`, etc.
*   **Warum:** Diese Dateien sind Überbleibsel aus dem Entwicklungsprozess und sollten aus dem Repository entfernt werden.

### 5.4: Fehlende Addon-Dateien (**NEUER FUND**)

*   **Was:** Das `Dialogue Manager`-Addon verweist auf Beispiel- und Testdateien, die im Projekt nicht vorhanden sind.
*   **Wo:**
    *   `addons/dialogue_manager/views/main_view.tscn`: Verweise auf `res://examples/*.dialogue`
    *   `addons/dialogue_manager/plugin.gd`: Prüft auf `res://tests/test_basic_dialogue.gd`
*   **Warum:** Dies deutet auf eine unvollständige Installation des Addons hin und kann zu Fehlern führen, wenn versucht wird, auf diese Beispiele oder Tests zuzugreifen.

### 5.5: Sprachliche Inkonsistenz (Deutsch/Englisch)

*   **Was:** Kommentare, Klassen- und Funktionsnamen sind eine Mischung aus Deutsch und Englisch.
*   **Wo:** `data/main.gd`, `data/modules/tactics/level/tactics_level_setup.gd`, `data/modules/tactics/level/arena/tactics_arena.gd`
*   **Warum:** Eine einheitliche Sprache (typischerweise Englisch) sollte verwendet werden, um die Lesbarkeit und Wartbarkeit zu verbessern.

### 5.6: Polymorphie-Verletzung bei Kachel-Typen

*   **Was:** An mehreren Stellen im Code wird explizit zwischen `TacticsTile` und `ProceduralTile` unterschieden.
*   **Wo:** `data/models/world/combat/arena/service/service.gd` (Zeile 30)
*   **Warum:** Dies verletzt das Prinzip der Polymorphie. Eine `BaseTile`-Klasse sollte eine einheitliche Schnittstelle bieten, sodass der aufrufende Code den spezifischen Typ nicht kennen muss.

---
**ENDE DES BERICHTS**
