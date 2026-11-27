# Camiel bouwen en releasen

Gebruik **Godot 4.7.2.stable** (standaardeditie, geen .NET), de bijbehorende
**4.7.2.stable exporttemplates** en Python 3. Zie [Godot instellen](godot-setup.md).

## Versiebron

`config/version` in `project.godot` bevat het nummer `X.Y.Z`. Godots Windows-
en macOS-exports gebruiken dit nummer voor hun bestandsinformatie. Het versielabel
in het spel en `scripts/tools/release_version.py` gebruiken ook `config/release_channel`.
Kanaal `alpha` geeft `alpha-vX.Y.Z` en kanaal `stable` geeft `vX.Y.Z`.
De opslagmap is apart ingesteld voor bestaande saves. [Godot-projectinstellingen](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html#class-projectsettings-property-application-config-custom-user-dir-name)

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
/tmp/camiel-build-venv/bin/python -m unittest tests.test_quality_gate tests.test_ci_workflows tests.test_release_build tests.test_web_export tests.test_parent_dashboard tests.test_voice_assets
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
De uitvoerbestanden uit de standaard desktopexports krijgen geen eigen ondertekening of notarisatie.

## Verplaatsbaar Windows-pakket

De lokale helper bouwt ook `Camiel-<versie>-windows-portable.zip`. Pak het volledige archief uit en open **Camiel spelen.exe**. Dat bestand is de ongewijzigde Windows-runtime uit de officiële Godot-release. Godot laadt **Camiel spelen.pck** uit dezelfde map. Het archief bevat de licentie van Camiel en de licentieteksten van Godot.

Geef de GUI-versie van de officiële Windows x86-64-runtime door met `--windows-runtime` en een tekstbestand met Godots licentie en vermeldingen van meegeleverde onderdelen met `--godot-notices`. De helper controleert de SHA256-vingerafdruk van de runtime voordat hij het pakket bouwt. [Officiële Godot-release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable) · [Godot-licentievermeldingen](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)

```powershell
py -3.12 scripts/tools/build_release.py windows-portable --godot builds/windows-godot/Godot_v4.7.2-stable_win64_console.exe --windows-runtime builds/windows-godot/Godot_v4.7.2-stable_win64.exe --godot-notices builds/windows-godot/Godot-licenties.txt
```

De ZIP van alpha-v0.0.29 is op Windows uitgepakt en rechtstreeks gestart vanuit een andere werkmap. Na les 3 is de volledige uitgepakte map verplaatst. De volgende start ging door bij les 4 en na les 6 ging het tuinfeest open. Bij een derde start waren alle zes lesresultaten nog aanwezig en kon het tuinfeest opnieuw worden geopend. De ondertekening van de runtime was geldig. Het PCK-bestand kwam byte voor byte overeen met het geteste Windows-spelpakket. De testgegevens staan onder `builds/verification/windows-portable-alpha-v0.0.29/`.

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
is aan de uitvoer van `scripts/tools/release_version.py`. De tag start de releaseworkflow.

Controleer na een echte run de tag-SHA, de geslaagde jobs, alle vier attachments
en de start van de uitgepakte builds op hun doelplatform. Een Python-test van
workflowstructuur of pakketinhoud bewijst geen uitgevoerde GitHub-run, geen
werkende desktopstart en geen menselijke speelbeoordeling. Vermeld die
resultaten afzonderlijk in de oplevering.

Referenties: [Godot command-line export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html)
en [herbruikbare GitHub-workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows).

## Bewijs na integratie — 19 september 2026

[PR #10](https://github.com/Euraika-Labs/Project-Camiel/pull/10) is gemergd als `c00504dc2d4f28a050ac3f31db5f9c84b3190836`. [CI-run 35468153825](https://github.com/Euraika-Labs/Project-Camiel/actions/runs/35468153825) slaagde op PR-head `2e84a3a97bee5627ef43c05300c1bbecaa6b07d5`: projectcontrole, 16 foutinjectiegevallen en vier exports. Alle 11 PR-checks waren groen, inclusief de exacte verplichte naam `Export Windows build`.

De eerdere lokale integratierun telde 41 Python-tests en 13 Godot-probes. De latere Windows-gate voegde een Python-regressietest toe. Lokale macOS- en browserflows en opslag na een echte procesherstart zijn getest. De CI-webexport is gebouwd, maar het gedownloade CI-webartifact is niet afzonderlijk in een browser gespeeld; het eerdere browserbewijs betreft de lokaal geëxporteerde runtime. Menselijke speelacceptatie, fysiek touchscreengebruik, native Windows/Linux-uitvoering en een getagde releasepublicatie blijven open. Lokale bewijsbestanden onder `builds/verification/` worden niet in git meegeleverd.

De verplichte check `Export Windows build` is een compatibiliteitsgate na de herbruikbare exportworkflow. Hij slaagt alleen als alle vier exports slagen en faalt ook bij overgeslagen of geannuleerde exports. De echte Windows-exportjob heet `export-builds / Export windows build`.

## Linux-speeltest — 26 november 2026

Het uitvoerbestand uit `Camiel-alpha-v0.0.15-linux.tar.gz` draaide op Debian 12 x86-64 in QEMU. In X11 op 800 × 450 met Mesa-softwareweergave zijn het titelscherm, de intro, pauze en beweging met een gesimuleerd toetsenbord gecontroleerd. Nadat een eerste lesafronding was opgeslagen, toonde een nieuwe grafische sessie **Verder spelen** en opende les 2. De inhoud van `progress.json` bleef bij die herstart en het openen van les 2 gelijk. Na het opslaan van alle zes afrondingen opende het Linux-spelbestand het tuinfeest vanuit het hoofdmenu.

Voor de volledige route draaide het ingebedde Linux-spelpakket in de officiële Linux-versie van Godot 4.7.2, zonder grafisch scherm. De eerste sessie voltooide de intro en les 1. De tweede sessie hervatte dezelfde voortgang bij les 2, voltooide les 2 tot en met 6 en opende het tuinfeest. Het voortgangsbestand bevatte zes unieke lesafrondingen. Prestaties op een fysieke Linux-machine en audio-uitvoer staan nog open. [Godot 4.7.2](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable) · [Debian](https://www.debian.org/distrib/) · [QEMU](https://www.qemu.org/download/)

## Projectnaam en opslag in alpha-v0.0.19

De Webexport gebruikt **Camiel** al tijdens het laden. Het Windows-bestand vermeldt `0.0.19.0` en `Camiel.app` vermeldt `0.0.19` in `Info.plist`. De bundle-ID van macOS is `com.euraika.camiel`. De macOS-controle betrof het pakket en de bestandsinformatie.

Op Windows en in een Debian-VM hielden de spelpakketten na de overstap dezelfde bestanden voor voortgang, intro, contrast en stemvolume. Het eerder vrijgespeelde tuinfeest bleef bereikbaar. In Chrome schreef alpha-v0.0.18 les 1 en een aangepaste geluidsinstelling. Na herladen op hetzelfde adres las alpha-v0.0.19 die gegevens en voegde het spel les 2 toe aan hetzelfde voortgangsbestand.

## Opstarten in alpha-v0.0.21

De Webexport toonde Camiels opstartbeeld en downloadvoortgang in Chrome op 800 × 450 en 390 × 844. Het titelscherm ging door naar het hoofdmenu met Enter of een gesimuleerde aanraking. Na een gesimuleerde downloadfout opende **Opnieuw proberen** het titelscherm op hetzelfde adres. Een browser zonder WebGL 2 kreeg uitleg voordat de spelbestanden werden opgehaald.

Het Linux-uitvoerbestand toonde het opstartbeeld en het 3D-titelscherm in een Debian-VM. Enter opende het hoofdmenu. Het Windows-spelpakket startte in de officiële Godot-runtime en bevatte het PNG-bestand uit de opstartinstellingen. Voor macOS is het pakket gecontroleerd. De vier lokale archieven bevatten dezelfde spelgegevens. De beelden en uitvoer staan onder `builds/verification/boot-alpha-v0.0.21/`.

## Eerste lesovergang in alpha-v0.0.24

Bij een Chrome-meting op deze Windows-pc met een gesimuleerd aanraakscherm van 390 × 844 ging de langste beeldpauze bij de eerste opening van de intro van 1,71 seconde naar 0,13 seconde. Bij rechtstreeks openen van les 6 ging die van 1,84 seconde naar 0,19 seconde. Tijdens het lopen bleef de frametijd op het 95e percentiel 6,2 ms. Ongeveer 1,5 seconde voorbereiding van de WebGL-verlichting verschoof naar het laadscherm.

Enter opende het hoofdmenu zodra het titelscherm klaar was. In de browsertest werkten herstel na een onderbroken download, de intro, alle zes lessen en het heropenen van het tuinfeest met bewaarde voortgang. De meetgegevens en beelden staan onder `builds/verification/performance-alpha-v0.0.24/`.

## Windows-speeltest in alpha-v0.0.25

Het uitvoerbestand uit `Camiel-alpha-v0.0.25-windows.zip` draaide op Windows met OpenGL. Met gesimuleerde toetsaanslagen werden de intro en lessen 1 tot en met 3 afgerond. Een nieuw proces startte vanuit een andere map met spaties in de naam, las de drie lesresultaten en hervatte bij les 4. Na les 6 ging het tuinfeest open. De voortgang bevatte precies één resultaat per les.

Met de toetsen Z, Q, S en D op de Belgische AZERTY-indeling is de intro nog eens doorlopen. Camiel pakte de bol, bereikte de eindring en ging met Enter naar les 1. De uitvoer en het titelscherm staan onder `builds/verification/windows-desktop-alpha-v0.0.25/`.

## Zicht op Camiel bij de eindring in alpha-v0.0.26

De visuele proef vergeleek 292 posities per versie, verdeeld over de intro, de zes lessen en vensters van 320 × 568 en 800 × 450. Op de onderzochte plek naast de oude poort steeg het zichtbare deel van Camiels silhouet op het smalle scherm van 23% naar 98%. De stapstenen leiden naar de verlichte ring op het gras.

De intro en alle zes lessen zijn uitgespeeld met gesimuleerde aanraking in Chrome en met toetsenbordinvoer in het uitvoerbestand uit het Windows-archief. De voortgang werd na herstart teruggelezen en het tuinfeest ging open na les 6. Meetgegevens en beelden staan onder `builds/verification/eindring-alpha-v0.0.26/`.

## Spraak en bevestigingsgeluiden in alpha-v0.0.27

De klank bij het oppakken van de bol is 4,8 dB zachter gemaakt. De eindklank is 7,0 dB zachter gemaakt. In de Godot-mixer op Windows was de stem met fabrieksinstellingen eerst 3,3 dB luider dan de achtergrond tijdens het oppakgeluid en 6,0 dB tijdens de eindklank. Met de nieuwe bestanden zijn die verschillen 7,2 dB en 10,1 dB, gemeten in intervallen van 100 ms met actieve spraak en een hoorbare klank. De gemeten mix bleef minstens 4,1 dB onder digitale oversturing.

Firefox 161 speelde de gesproken aanwijzingen en beide zachtere klanken af in de Webbuild met een schoon profiel. Meetgegevens en opnamen van voor en na de aanpassing staan onder `builds/verification/geluidsmix-alpha-v0.0.27/`. De meting gebeurde in de softwaremixer. Beoordeling van de verstaanbaarheid op luidsprekers blijft deel van de speeltest.

## Aanwijzingen op een smal scherm in alpha-v0.0.28

De intro en de eerste kleurenles zijn op 320 × 568 gespeeld met gesimuleerde aanraking, aan de hand van de stenen, de opdrachttekst en de pijl. Na het oppakken van een telsteen meldt de tekst hoeveel stenen er nog liggen en krijgt de gevonden steen een vinkje. De vormenles toont het aantal afgeronde stappen.

Bij 400 bemonsterde cameraposities in vier vensterformaten was een richtingspijl 179 keer nodig. De gemeten ruimte rond het pictogram en de pijl bleef binnen het scherm en vrij van de knoppen. Beelden van voor en na de aanpassing en de meetgegevens staan onder `builds/verification/richtinghulp-alpha-v0.0.28/`.

## Volledige Linux-speeltest in alpha-v0.0.28

Het uitvoerbestand uit `Camiel-alpha-v0.0.28-linux.tar.gz` draaide op Debian 12.15 x86-64 in QEMU met X11 op 800 × 450. Met gesimuleerde toetsen zijn de intro en lessen 1 tot en met 3 afgerond. Een tweede proces startte het uitvoerbestand vanuit een andere map en ging met **Verder spelen** door bij les 4. Na les 6 ging het tuinfeest open.

Een derde proces opende het tuinfeest opnieuw vanuit het hoofdmenu. De zeven opgeslagen uitkomsten, de intro en de zes lessen, waren nog beschikbaar. Het voortgangsbestand bevatte precies één resultaat per les en bleef bij de laatste herstart byte voor byte gelijk.

De Mesa-softwareweergave in de VM haalde tijdens de proef 9 tot 14 beelden per seconde. Grafische prestaties en audio-uitvoer op een fysieke Linux-machine staan nog open. Beelden, logboeken en controlesommen staan onder `builds/verification/linux-alpha-v0.0.28/`.

## Vloeiendere softwareweergave in alpha-v0.0.29

Bij Mesa llvmpipe gebruikt het spel een randfilter op het 3D-beeld en één schaduwkaart. De opdrachtkaarten worden daarna getekend. De onderstaande mediane frametijden zijn gemeten in dezelfde Debian-VM met de geëxporteerde spelpakketten. Per versie zijn op 800 × 450 twee reeksen van 36 frames per scène gemeten. Bij 320 × 568 was dat één reeks van 14 frames per scène.

| Scène en formaat | Alpha-v0.0.28 | Alpha-v0.0.29 |
|---|---:|---:|
| Titel op 800 × 450 | 97,2 ms | 34,3 ms |
| Intro op 800 × 450 | 76,6 ms | 27,9 ms |
| Les 4 op 800 × 450 | 101,6 ms | 33,3 ms |
| Les 6 op 800 × 450 | 91,5 ms | 27,7 ms |
| Intro op 320 × 568 | 51,5 ms | 20,7 ms |
| Les 4 op 320 × 568 | 64,5 ms | 26,4 ms |

De gemeten delen van de tekstkaarten waren pixel voor pixel gelijk. In de volledige speelronde met het Linux-uitvoerbestand leverde de beeldweergave 27 tot 42 beelden per seconde over 103 meetintervallen, met een mediaan van 36. Na twee herstarts waren alle zes lesresultaten en het tuinfeest nog beschikbaar. Op de Windows-test-pc draaiden het titelscherm en de intro met 2× MSAA op de NVIDIA-kaart. De metingen en beelden staan onder `builds/verification/softwareweergave-alpha-v0.0.29/`.

In Chrome en met de officiële Godot-runtime op Windows is de route tot het tuinfeest ook uitgespeeld met gesimuleerde invoer. In beide tests werd de voortgang na les 3 teruggelezen. Toepassingsbeheer hield het losse Windows-uitvoerbestand op de test-pc tegen. De Windows-snelkoppeling start het geteste spelpakket via de Godot-runtime.

## Vloeiende camerabeweging in alpha-v0.0.30

Bij ongeveer 144 beelden per seconde bleef de camera tijdens lopen in de intro en les 6 in alpha-v0.0.29 bij 57 van 97 beeldwissels op dezelfde plek staan. In alpha-v0.0.30 bewoog de camera bij iedere gemeten beeldwissel tijdens het lopen. In les 6 daalde de grootste verschuiving van een vast punt op het scherm van 2,04 naar 0,93 pixel bij het lopen en van 3,20 naar 1,49 pixel bij het springen. Beide versies draaiden de fysica op 60 stappen per seconde.

De camera stond tijdens de gemeten pauzeframes stil en stond op de juiste plek bij het opnieuw beginnen van de intro. Bij de intro en alle zes lessen stond de camera vanaf het eerste beeld op de ingestelde afstand, zowel op 800 × 450 als op 320 × 568. Meetgegevens en beelden staan onder `builds/verification/camerabeweging-alpha-v0.0.30/`.

De Windows-ZIP en Chrome-export van alpha-v0.0.30 zijn met gesimuleerde invoer tot het tuinfeest uitgespeeld. In beide tests werd de voortgang bij les 4 hervat. Het tuinfeest bleef na herstart of herladen toegankelijk.

## Browseropslag in alpha-v0.0.31

In Firefox stonden twee tabbladen op dezelfde URL open voordat er was gespeeld. In alpha-v0.0.30 verdween het resultaat van les 1 nadat het tweede tabblad les 2 afrondde. In alpha-v0.0.31 bewaarde IndexedDB beide resultaten. Na herladen wees **Verder spelen** naar les 3.

Bij de overstap van alpha-v0.0.30 naar alpha-v0.0.31 op dezelfde URL bleven de afgeronde intro, de sterren en tijd van les 1 behouden. Na twee herladingen stond het eerdere lesresultaat één keer in de nieuwe opslag. Daarna kwam les 2 erbij.

De intro en zes lessen zijn uitgespeeld in het verplaatsbare Windows-pakket en in Chrome met gesimuleerde aanraking. **Verder spelen** ging in Windows naar les 4 nadat de spelmap was verplaatst, en in Chrome nadat de pagina was herladen. Na een volgende herstart of herlading bleef het tuinfeest toegankelijk. De testresultaten en schermafbeeldingen staan in `builds/verification/browseropslag-alpha-v0.0.31/`.

## Open menu's bijwerken in alpha-v0.0.32

In Firefox stonden het hoofdmenu en de leskeuze al open toen les 1 in een derde tabblad werd voltooid. In alpha-v0.0.31 bleef **Start** zichtbaar en opende Enter de intro. In alpha-v0.0.32 toonde hetzelfde open menu **Verder spelen · Les 2** en opende Enter les 2. De open leskeuze gaf les 1 een vinkje en toonde **1 van 6 afgerond**. Tijdens de proef werden de pagina's niet herladen.

De Godot-proef controleert ook dat het tuinfeest in beide open menu's verschijnt na de laatste ontbrekende les en bereikbaar is met Tab. Met het Windows-pakket en in Chrome zijn alle zes lessen doorlopen en bleef het tuinfeest na een nieuwe start toegankelijk. De vergelijking en screenshots staan in `builds/verification/tabbladen-alpha-v0.0.32/`.

## Schermindeling in alpha-v0.0.33

De leskeuze toont twee kolommen op zowel 539 × 540 als 540 × 540. Op 640 × 480 en 568 × 260 staan de zes leskaarten in drie kolommen. Voor de lage, brede indeling is de fotostrook korter gemaakt om de terugknop en het tuinfeest in beeld te houden. Op 568 × 260 groeide het raakvlak van **Pauze** van circa 33 × 33 naar 44 × 44 pixels. De terugknop werd circa 45 pixels hoog. De springuitleg gebruikt grotere letters.

Chrome toonde negen schermtoestanden op zes vensterformaten. Bij 568 × 260 en twee beeldpixels per CSS-pixel zijn **Pauze**, **Verder spelen** en lopen en springen met twee gesimuleerde contacten getest. De volledige terugkeer naar het tuinfeest is getest in het Windows-pakket en Chrome. Afmetingen en beelden staan in `builds/verification/schermindeling-alpha-v0.0.33/`.

## Linux-speeltest in alpha-v0.0.42

Het uitvoerbestand uit `Camiel-alpha-v0.0.42-linux.tar.gz` draaide in een Debian 12.15-VM met X11 op 800 × 450 en Mesa llvmpipe. De intro en de zes lessen zijn uitgespeeld met geautomatiseerde toetsenbordinvoer. Na les 3 hervatte het verplaatste uitvoerbestand bij les 4. Bij de volgende herstart ging het tuinfeest open vanuit het hoofdmenu en startte **Vier mee** de confetti opnieuw. Het opgeslagen bestand bleef byte voor byte gelijk en bevatte één resultaat per les.

De volledige Nederlandse uitnodiging op het tuinfeest is opgenomen via de virtuele PulseAudio-uitgang. De opname, screenshots, controlesommen en testuitvoer staan in `builds/verification/linux-alpha-v0.0.42/`. Een speeltest op fysieke Linux-hardware staat open.

## Webpakket controleren vóór upload

De webexport in de eerdere GitHub-run voor PR #10 slaagde. De bestanden uit die run hadden een bewaartermijn van veertien dagen en staan niet meer in de lijst met downloads. [Eerdere GitHub-run](https://github.com/Euraika-Labs/Project-Camiel/actions/runs/35468153825)

De exportworkflow in de werkversie start het webarchief vóór upload in Chrome. De lokale proef op het uitgepakte archief van alpha-v0.0.42 bereikte het titelscherm. Een controlekopie met een beschadigd WebAssembly-bestand werd geweigerd. De logboeken en controlesommen staan in `builds/verification/github-webproef-alpha-v0.0.42/`. De eerste GitHub-run met de browserproef staat open.
