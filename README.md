# Project Camiel

[![CI](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/ci.yml/badge.svg)](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/ci.yml)
[![CodeQL](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/codeql.yml/badge.svg)](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/codeql.yml)

Project Camiel is een Nederlandstalig educatief 3D-spel in Godot, met Camiel de Berner sennenhond. Het ontwerp richt zich op jonge kinderen die zelfstandig kunnen spelen.

## Ontwikkelstatus

De huidige ontwikkelversie is **alpha-v0.0.4**. Integratie en eindacceptatie zijn nog bezig. Een versienummer of groene CI-badge is geen bevestiging dat alle desktop- en webfuncties zijn geaccepteerd.

De 3D-codebasis bevat een titelscherm, hoofdmenu, introductiewereld en lesselectie. Lessen oefenen kleuren, vormen, tellen en volgordes. Lesvoortgang gebruikt het lokale bestand `user://progress.json` met les, sterren, speelduur en voltooiingstijd.

Karakteranimaties, toegankelijkheidsinstellingen, Nederlandse spraak, aanraakbediening, webexport, het lokale ouderdashboard en extra lesinhoud worden voor deze versie geïntegreerd en gecontroleerd. De uiteindelijke speelbaarheid en opslag na herstart worden afzonderlijk getest. Beoordeling van kindvriendelijkheid en bewegingsgevoel blijft een menselijke speeltest.

De eerdere 2D-versie is gearchiveerd onder de tag `archive/2d-alpha-v0.0.3`; de huidige runtime gebruikt `CharacterBody3D` en de Compatibility-renderer. Zie de [roadmap](docs/roadmap.md) voor de voortgang en [.planning/REQUIREMENTS.md](.planning/REQUIREMENTS.md) voor de acceptatiecriteria.

## Bediening

| Actie | Toetsen |
|---|---|
| Bewegen in de 3D-wereld | Pijltjestoetsen of WASD |
| Springen | Spatie |
| Menukeuze | Klik op een knop of gebruik de toetsenbordfocus |

De camera volgt Camiel automatisch.

## Starten vanuit de broncode

1. Installeer Godot **4.7.2** volgens [Godot instellen](docs/godot-setup.md).
2. Importeer `project.godot` in de Godot-projectbeheerder.
3. Open het project en druk op F5 om bij het titelscherm te beginnen.

Zie [snel starten](docs/quick-start.md) voor verdere instructies. Voor webexport en lokaal aanbieden in een browser: [webexport](docs/web-export.md). Voor desktopbuilds en benodigde exporttemplates: [bouwen en releasen](docs/build-and-release.md).

## Controles

```bash
python3 scripts/tools/quality_gate.py --root .
python3 -m unittest discover -s tests
```

De Godot-controles staan in `scripts/tools/run_headless_check.sh`. Deze voeren ook opslagprobes uit: gebruik hiervoor een afzonderlijke testkopie met een aantoonbaar geïsoleerde Godot-gebruikersmap, zodat bestaande voortgang behouden blijft. Headless controles vervangen geen visuele speeltest of controle op een echt touchscreen.

## Documentatie

- [Ouder- en leerkrachtnotities](docs/parent-teacher-notes.md)
- [Lokaal ouderdashboard](docs/parent-dashboard.md)
- [Toegankelijkheidsrapport](docs/accessibility-report.md)
- [Bouwen en releasen](docs/build-and-release.md)
- [Bijdragen](CONTRIBUTING.md), [beveiliging](SECURITY.md) en [ondersteuning](SUPPORT.md)

## Licentie

Copyright © 2026 Euraika Labs. **Alle rechten voorbehouden.** Broncode, assets, documentatie en builds zijn eigendom van Euraika Labs, tenzij afzonderlijk schriftelijk anders gelicentieerd. Zie [LICENSE](LICENSE) voor de voorwaarden.
