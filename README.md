# Project Camiel

[![CI](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/ci.yml/badge.svg)](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/ci.yml)
[![CodeQL](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/codeql.yml/badge.svg)](https://github.com/Euraika-Labs/Project-Camiel/actions/workflows/codeql.yml)

Project Camiel is een Nederlandstalig educatief 3D-spel in Godot, met Camiel de Berner sennenhond. Het ontwerp richt zich op jonge kinderen die zelfstandig kunnen spelen.

## Ontwikkelstatus

De huidige werkversie is **alpha-v0.0.45**. In de intro laat Camiel zien en horen hoe je loopt en springt. Daarna volg je stapstenen naar de eindring en speel je door naar de lessen en het tuinfeest. Na een herstart gaat **Verder spelen** door naar de eerste onafgeronde les. De zes lessen hebben elk eigen tuindecor dat je op de leskaarten ziet. In de kleurenlessen benoemt Camiel de gevonden kleuren en telt hij de stenen hardop. In de vormen- en tellessen noemt hij bij elke stap de volgende vorm of het volgende getal. Een afgerond doel wordt kleiner op zijn voetstuk en krijgt een vinkje. Een korte klank bevestigt de aanraking. Een pijl helpt je verder als het doel buiten beeld ligt. Je kunt pauzeren om geluid en contrast aan te passen. De eerdere technische integratie van **alpha-v0.0.4** is gemergd via [PR #10](https://github.com/Euraika-Labs/Project-Camiel/pull/10).

De 3D-codebasis bevat een titelscherm, hoofdmenu, introductiewereld en lesselectie. Lessen oefenen kleuren, vormen, tellen en volgordes. Camiel bewaart per resultaat de les, sterren, speelduur en voltooiingstijd. Op desktop staan die gegevens in `user://progress.json`. In de webversie delen tabbladen op hetzelfde webadres de browseropslag.

Karakteranimaties, toegankelijkheidsinstellingen, Nederlandse spraak, aanraakbediening, webexport en het lokale ouderdashboard zijn geïntegreerd. Actuele speeltests en de resultaten per platform staan in de [snelstartgids](docs/quick-start.md#verificatiegrenzen).

De eerdere 2D-versie is gearchiveerd onder de tag `archive/2d-alpha-v0.0.3`; de huidige runtime gebruikt `CharacterBody3D` en de Compatibility-renderer. Zie de [roadmap](docs/roadmap.md) voor de voortgang en [.planning/REQUIREMENTS.md](.planning/REQUIREMENTS.md) voor de acceptatiecriteria.

## Bediening

| Actie | Toetsen |
|---|---|
| Bewegen in de 3D-wereld | Pijltjestoetsen, WASD op QWERTY of ZQSD op Belgisch AZERTY |
| Springen | Spatie |
| Pauzeren of hervatten | P, **Pauze** of **Verder spelen** |
| Terug naar de lessen of het menu | Escape |
| De opdracht opnieuw horen | L of **Luister** |
| Menukeuze | Klik op een knop of gebruik de toetsenbordfocus |

De camera volgt Camiel met een vaste kijkrichting.

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

De vier remote CI-exports en de verplichte Windows-check voor alpha-v0.0.4 zijn gedocumenteerd bij [bouwbewijs en releasegrenzen](docs/build-and-release.md). De lokale werkversie kan worden gebouwd met dezelfde exportpresets.
