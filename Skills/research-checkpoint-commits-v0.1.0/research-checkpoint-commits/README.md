# Research Checkpoint Commits

Ein portabler Agent-Skill für wissenschaftliche Git-Workflows mit Markplane.

## Was der Skill erzwingt

- Ein wissenschaftlich sinnvoller Kontrollpunkt pro Commit.
- Eine Markplane-TASK als Eigentümer jedes Diffs.
- Methodische Entscheidungen und Anomalien als Markplane-NOTES.
- Explizite Validierung vor dem Abschluss.
- Commit-Nachrichten, die das **Warum** und den Forschungsbezug dokumentieren.
- Gemeinsame Versionierung von Code, überprüfbaren Ergebnissen und Projektstatus.

## Markplane-Modell

| Markplane-Objekt | Verwendung im Forschungsprojekt |
|---|---|
| EPIC | Paper, Kapitel, Forschungsfrage oder Replikation |
| PLAN | Mehrstufiger Analyse- oder Reproduktionsplan |
| TASK | Genau ein commitfähiger Forschungsschritt |
| NOTE | Entscheidung, Datenherkunft, Anomalie, Interpretation oder Befund |

## Paketinhalt

- `SKILL.md` — vollständiger Workflow für den Agenten.
- `references/validation-matrix.md` — fachliche Prüfungen nach Arbeitsschritt.
- `references/markplane-integration.md` — Zuordnung, Status- und Verknüpfungsregeln.
- `templates/research-task-body.md` — Body-Vorlage für eine Checkpoint-TASK.
- `templates/research-plan-body.md` — Vorlage für einen mehrstufigen Forschungsplan.
- `templates/research-decision-note.md` — Vorlage für dauerhafte methodische Entscheidungen.
- `AGENTS.md.snippet.md` — kurze Projektanweisung zur automatischen Nutzung.
- `.mcp.json.example` — projektweite Markplane-MCP-Konfiguration.
- `scripts/checkpoint-audit.sh` — schreibgeschützte Prüfung des gestagten Checkpoints.

## Verwendung

1. Stelle sicher, dass das Projekt ein Git-Repository und eine `.markplane/`-Struktur besitzt.
2. Verbinde Markplane über MCP oder stelle die `markplane`-CLI bereit.
3. Installiere beziehungsweise lade den Skill in einem Agenten, der den offenen `SKILL.md`-Standard unterstützt.
4. Ergänze bei Bedarf den Inhalt aus `AGENTS.md.snippet.md` in den Projektanweisungen.
5. Starte beispielsweise mit:

```text
Nutze research-checkpoint-commits. Zerlege die Baseline-Analyse in
Markplane-TASKs und bearbeite anschließend den ersten Kontrollpunkt.
```

Oder mit einer bestehenden Aufgabe:

```text
Nutze research-checkpoint-commits für TASK-k3m8p. Committe nur,
wenn die Daten- und Stichprobenprüfungen bestanden sind.
```

## Empfohlene Markplane-Konfiguration

Der Standard-Task-Typ `research` und die Standard-Notiztypen `research`,
`analysis` und `decision` passen bereits gut. Sinnvolle zusätzliche Tags sind:

```text
exploratory
confirmatory
data
sample
variables
estimation
robustness
simulation
figure
paper
reproducibility
```

## Sicherheitsprinzip

Der Skill commitet keine Rohdaten oder sensiblen Daten automatisch. Er bevorzugt
Code, Provenienz, Prüfsummen, Schemata, kleine erlaubte Fixtures und
Validierungszusammenfassungen.
