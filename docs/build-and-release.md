# Camiel bouwen en releasen

Gebruik **Godot 4.7.2.stable** (standaardeditie, geen .NET), de bijbehorende
**4.7.2.stable exporttemplates** en Python 3. Zie [Godot instellen](godot-setup.md).

## Versiebron

`project.godot`, sectie `[application]`, bevat `config/version="alpha-v0.0.4"`.
`scripts/tools/release_version.py` leest uitsluitend deze instelling. Dezelfde
versie wordt gebruikt voor de zichtbare spelversie en alle pakketnamen.
Verander de applicatienaam niet voor een versiebump: die naam kan de locatie van
bestaande lokale voortgang bepalen.

```bash
python3 scripts/tools/release_version.py
```

Een releasetag moet exact overeenkomen met deze waarde (`alpha-vX.Y.Z` of
`vX.Y.Z`). Een afwijkende tag stopt vóór het bouwen en publiceren.

## Lokaal controleren en bouwen

Voer deze commando's uit vanuit de repositoryroot. Stel `GODOT` in op de juiste
enginebinary; op macOS bijvoorbeeld `/Applications/Godot.app/Contents/MacOS/Godot`.

```bash
python3 -m venv /tmp/camiel-build-venv
/tmp/camiel-build-venv/bin/pip install PyYAML
/tmp/camiel-build-venv/bin/python -m unittest tests.test_quality_gate tests.test_ci_workflows tests.test_release_build tests.test_web_export
python3 scripts/tools/quality_gate.py --root .
GODOT=/pad/naar/Godot bash scripts/tools/run_headless_check.sh
GODOT=/pad/naar/Godot bash scripts/tools/test_headless_check.sh
GODOT=/pad/naar/Godot python3 scripts/tools/build_release.py windows
GODOT=/pad/naar/Godot python3 scripts/tools/build_release.py linux
GODOT=/pad/naar/Godot python3 scripts/tools/build_release.py macos
GODOT=/pad/naar/Godot python3 scripts/tools/build_release.py web
```

De helper controleert de engineversie, importeert en exporteert met harde
proceslimieten en stopt bij `SCRIPT ERROR`, `Parse Error`, `ERROR:` of een
niet-nul exitcode. Iedere export krijgt een nieuwe tijdelijke uitvoermap.
Ontbrekende uitvoer kan daardoor niet door een oude build worden gemaskeerd.
`--output /pad/naar/pakketten` wijzigt de pakketmap (standaard `builds/release/`).

| Doel | Presetnaam | Pakket in `builds/release/` |
|---|---|---|
| Windows x86_64 | `Windows Desktop` | `Camiel-<versie>-windows.zip` |
| Linux x86_64 | `Linux` | `Camiel-<versie>-linux.tar.gz` |
| macOS | `macOS` | `Camiel-<versie>-macos.zip` |
| Browser | `Web` | `Camiel-<versie>-web.zip` |

Windows- en Linux-pakketten bevatten alle uitgevoerde bestanden, inclusief een
los `.pck` of bibliotheken als de preset die produceert. Het Linux-uitvoerbestand
staat in de root van de tarball en heeft uitvoerrechten. De macOS-ZIP bevat
rechtstreeks de `.app`, zonder extra ZIP-laag. De web-ZIP bevat `index.html` en
bijbehorende JavaScript-, WebAssembly- en PCK-bestanden. Serveer de uitgepakte
webbuild via een lokale webserver; dubbelklikken op HTML is geen browsertest.
De desktopbuilds worden niet ondertekend of genotariseerd.

## GitHub Actions

- `ci.yml`: pushes en pull requests naar `main`, handmatige controle en
  hergebruik via `workflow_call`. Repositoryhygiene → echte headless controle
  en foutinjectietests → exports.
- `export.yml`: uitsluitend een herbruikbare workflow, aangeroepen na de gates.
  Een matrix bouwt Windows, Linux, macOS en Web. Engine en templates worden
  vóór uitpakken gecontroleerd tegen de officiële SHA512-lijst. Pakketten zijn
  veertien dagen beschikbaar als Actions-artifacts `release-<platform>`.
- `release.yml`: alleen tags `alpha-v*` en `v*`. Controleert tag tegen versie,
  roept de volledige CI-keten aan en publiceert pas na alle vier exports.
  Dit is de enige releasecreator. Alleen de publicatiejob heeft `contents: write`.

De releasejob downloadt artifacts naar één map, controleert vier niet-lege
pakketbestanden en geeft de vier exacte bestandspaden door aan de vastgepinde
releaseactie. Een alpha-tag wordt een prerelease. Runs voor dezelfde tag worden
achter elkaar verwerkt. Er is geen handmatige invoer waarmee een andere tag of
ongecontroleerde branch kan worden gepubliceerd.

## Releaseprocedure en bewijs

Werk versie en changelog bij, beoordeel de wijziging en voer bovenstaande
controles uit. Maak en push pas na releaseautorisatie een tag die exact gelijk
is aan `config/version`. De tag start de releaseworkflow; deze handleiding voert
geen push of publicatie uit.

Controleer na een echte run de tag-SHA, de geslaagde jobs, alle vier attachments
en de start van de uitgepakte builds op hun doelplatform. Een Python-test van
workflowstructuur of pakketinhoud bewijst geen uitgevoerde GitHub-run, geen
werkende desktopstart en geen menselijke speelbeoordeling. Vermeld die
resultaten afzonderlijk in de oplevering.

Referenties: [Godot command-line export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html)
en [herbruikbare GitHub-workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows).
