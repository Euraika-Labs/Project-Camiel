# Webbuild starten

De preset **Web** gebruikt Godot **4.7.2.stable**, de Compatibility-renderer
(WebGL 2) en één thread. Installeer de exporttemplates van exact dezelfde versie
via **Editor → Manage Export Templates**. Open in **Project → Export** de preset
**Web**; het platform heet in Godot 4 niet HTML5.

## Exporteren en lokaal spelen

Vanuit de repository, met `godot` op het PATH:

```bash
python3 scripts/tools/build_release.py web --godot godot
mkdir -p builds/web
unzip -o builds/release/Camiel-alpha-v0.0.4-web.zip -d builds/web
python3 scripts/tools/serve_web.py builds/web
```

Open **http://127.0.0.1:8060/index.html** in een desktopbrowser met WebGL 2.
Klik in het spel om audio en toetsenbordbediening te activeren. Stop de server
met Ctrl+C. Gebruik `--port 8061` alleen wanneer nodig; een andere poort krijgt
een afzonderlijke browseropslag.

De archiefnaam volgt `config/version` in `project.godot`. Na een versiewijziging
gebruik je de bestandsnaam die het buildcommando afdrukt. Rechtstreeks exporteren
kan ook:

```bash
mkdir -p builds/web
godot --headless --editor --path . --quit
godot --headless --path . --export-release "Web" builds/web/index.html
python3 scripts/tools/serve_web.py builds/web
```

Controleer exportlogs op `SCRIPT ERROR`, `Parse Error` en `ERROR:`; alleen exitcode
0 bewijst geen geslaagde Godot-export. Het Python-buildcommando voert deze controle
uit en weigert ontbrekende uitvoerbestanden.

## CI-artifact

De herbruikbare `.github/workflows/export.yml` bouwt ook het platform `web`.
CI voert de exportketen na de projectcontroles uit. Download het webartifact van
het gewenste CI-commit, pak het artifact en daarna `Camiel-<versie>-web.zip` uit,
en serveer de uitgepakte map met hetzelfde `serve_web.py`-commando.
De releaseworkflow voegt het webarchief aan getagde releases toe.
Een ingestelde workflow is geen bewijs van een geslaagde CI-run: controleer de run
voor het commit waarvan je het artifact gebruikt.

## Bestanden en hosting

Houd de **hele** exportmap samen, inclusief `index.html`, `index.js`, `index.wasm`,
`index.pck` en gegenereerde pictogrammen/audiohulpbestanden. De PCK staat los van
HTML. Open `index.html` niet via `file://`: het spel moet via HTTP(S) worden geladen.
De lokale server bindt uitsluitend aan `127.0.0.1` en serveert WASM als
`application/wasm`. Publiceer extern met HTTPS en dezelfde MIME-types.
Threads en PWA staan uit; deze preset vereist geen cross-origin isolation headers
of serviceworker. Desktopbrowsers zijn het primaire doel; mobiele prestaties en
browsercompatibiliteit moeten afzonderlijk worden getest.

## Voortgang en herlaadtest

Godot bewaart `user://progress.json` in **IndexedDB van deze browser en origin**.
Gebruik voor behoud hetzelfde browserprofiel, protocol, host en poort. Privémodus,
geblokkeerde websiteopslag of het wissen van sitegegevens kan voortgang verwijderen.
De webopslag is niet het desktopbestand in de Godot-appdatamap.

1. Start via titelscherm → menu → leskeuze en speel een les volledig uit.
2. Wacht na de voltooiing enkele seconden zodat de browser de opslag kan verwerken.
3. Controleer in browserontwikkelaarstools de IndexedDB-opslag op `progress.json`
   met de afgeronde les in `entries`.
4. Herlaad dezelfde URL. Speel opnieuw een les uit en controleer dat de eerdere
   entry behouden blijft en een nieuwe entry is toegevoegd.
5. Controleer de console op scriptfouten, ontbrekende bestanden en WebGL-fouten.

Technische achtergrond: [Godot webexport en persistente opslag](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).
