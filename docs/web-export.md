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
camiel_version=$(python3 scripts/tools/release_version.py)
unzip -o "builds/release/Camiel-$camiel_version-web.zip" -d builds/web
python3 scripts/tools/serve_web.py builds/web
```

Open **http://127.0.0.1:8060/index.html** in een desktopbrowser met WebGL 2.
Klik in het spel om audio en toetsenbordbediening te activeren. Stop de server
met Ctrl+C. Gebruik `--port 8061` alleen wanneer nodig; een andere poort krijgt
een afzonderlijke browseropslag.

De archiefnaam volgt de projectversie en het releasekanaal. Het buildcommando
drukt de exacte pakketnaam af. Rechtstreeks exporteren kan ook.

```bash
mkdir -p builds/web
godot --headless --path . --import
godot --headless --path . --export-release "Web" builds/web/index.html
python3 scripts/tools/serve_web.py builds/web
```

Controleer exportlogs op `SCRIPT ERROR`, `Parse Error` en `ERROR:`; alleen exitcode
0 bewijst geen geslaagde Godot-export. Het Python-buildcommando voert deze controle
uit en weigert ontbrekende uitvoerbestanden.

## CI-artifact

De herbruikbare `.github/workflows/export.yml` bouwt ook het platform `web`.
De exportjob pakt het versiegebonden webarchief uit en opent het in Chrome.
De browserproef wacht op het door Godot getekende titelscherm. Bij succes staat
de SHA-256 van `index.pck` in het joblogboek. Bij een opstartfout stopt de job
vóór het uploaden.

Dezelfde proef werkt lokaal met Node.js, Chrome en Python. Geef de uitgepakte
exportmap en de naam of het pad van Chrome mee. De proef start zelf een
tijdelijke server. Geef eventueel het pad naar Python als derde argument.

```bash
node scripts/tools/verify_web_boot.mjs builds/web google-chrome
```

Controleer de GitHub-run van het gewenste commit. Download het webartifact,
pak het artifact en daarna `Camiel-<versie>-web.zip` uit en serveer de map met
`serve_web.py`. De releaseworkflow voegt het webarchief toe aan getagde releases.

## Bestanden en hosting

Houd de **hele** exportmap samen, inclusief `index.html`, `index.js`, `index.wasm`,
`index.pck` en gegenereerde pictogrammen/audiohulpbestanden. De PCK staat los van
HTML. Open `index.html` niet via `file://`: het spel moet via HTTP(S) worden geladen.

Godot genereert `index.html` uit `web/loading_shell.html`. Het Nederlandstalige
laadscherm gebruikt het opstartbeeld uit de projectinstellingen en toont
voortgang zodra de downloadgrootte bekend is. Het laadscherm blijft zichtbaar
tot het eerste beeld van het titelportret klaar is. De gouden bol in het
portret gebruikt hetzelfde materiaal als in de intro. Daardoor bereidt de
browser de verlichting van de bol en de lesdoelen al bij het opstarten voor.
**Opnieuw proberen** opent bij een onderbroken download opnieuw hetzelfde
adres. [Godot-documentatie voor de HTML-shell](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html)

De lokale server bindt uitsluitend aan `127.0.0.1` en serveert WASM als
`application/wasm`. Publiceer extern met HTTPS en dezelfde MIME-types.
Threads en PWA staan uit; deze preset vereist geen cross-origin isolation headers
of serviceworker. Desktopbrowsers zijn het primaire doel; mobiele prestaties en
browsercompatibiliteit moeten afzonderlijk worden getest.

## Op een tablet of telefoon

Zet de volledige uitgepakte webbuild op een webserver met HTTPS. Open de
HTTPS-link van `index.html` op het toestel. Tik op **Spelen** en **Start** om
de intro met beeld, geluid en touchbediening te proberen. Gebruik bij een
volgende speelronde hetzelfde adres en browserprofiel om de voortgang terug
te vinden. Bij een gewoon HTTP-adres vraagt het spel om de HTTPS-link voordat
het de grote spelbestanden ophaalt.

## Voortgang en herlaadtest

Vanaf alpha-v0.0.31 bewaart Camiel de intro en lesresultaten in de IndexedDB-database
`camiel-progress`, in object store `state` onder sleutel `progress`. Bij de eerste start
neemt het spel de nog aanwezige intro en lesresultaten uit de oude Godot-opslag over.
Tabbladen delen de voortgang als ze hetzelfde browserprofiel, protocol, host en poort
gebruiken. Bij geblokkeerde websiteopslag kan het spel de voortgang alleen tijdens de
sessie bijhouden. Het wissen van sitegegevens verwijdert de bewaarde voortgang.

Vanaf alpha-v0.0.42 kun je ook spelen als de opslag tijdelijk bezet is. Bij een
trage schrijfpoging verschijnt op het eindscherm **Opslaan duurt even…**. Je
kunt meteen door naar de volgende les of het vrijgespeelde tuinfeest. Zolang
het tabblad openstaat, kan de browser het resultaat alsnog opslaan.

Vanaf alpha-v0.0.32 werken een open hoofdmenu en leskeuze bij zodra een ander tabblad
op hetzelfde webadres een les opslaat. Laat beide schermen open en rond les 1 af in
een derde tabblad om dit te testen. Het hoofdmenu biedt **Verder spelen · Les 2**
aan en in de leskeuze krijgt les 1 de aanduiding **Afgerond**.

1. Open Camiel in twee tabbladen op dezelfde URL voordat je begint te spelen.
2. Speel les 1 uit in het eerste tabblad en les 2 in het tweede.
3. Controleer in de ontwikkelaarstools bij IndexedDB dat beide lessen in `entries` staan.
4. Herlaad de pagina en controleer dat beide lesresultaten behouden zijn. **Verder spelen**
   gaat vanuit het hoofdmenu naar les 3.
5. Test een versiewissel op dezelfde URL door in alpha-v0.0.30 een les af te ronden.
   Open vervolgens alpha-v0.0.31 en controleer na twee herladingen dat het eerdere
   resultaat één keer in `entries` staat.

Godot beschrijft de onderliggende browseropslag in de [documentatie over webexports](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

## Browsertests in alpha-v0.0.26

De lokale Webbuild is van de intro tot en met het tuinfeest doorlopen in Chrome met gesimuleerde aanraking en in Firefox 161 op Windows met gesimuleerde toetsenbordinvoer. In Firefox draaide WebGL 2 in headless-modus op 800 × 450. Na herladen hervatte het spel bij les 4. Aan het eind bleven alle zes resultaten en het tuinfeest beschikbaar. Op 500 × 844 stonden de afgeronde leskaarten in twee kolommen.

De audioproef in Firefox nam de gesproken uitleg van de vormenles op met muziek en geluidseffecten op nul. Tijdens de pauze bleef de opname stil. Na hervatten kwam het vervolg van dezelfde aanwijzing terug in de opname. Beelden, opnamen en testuitvoer staan onder `builds/verification/firefox-alpha-v0.0.26/`.

## WebKit in alpha-v0.0.33

In Playwright WebKit 27.2 op Windows zijn de intro en alle zes lessen met gesimuleerde aanraking uitgespeeld. In les 3 draaide het scherm van 390 × 844 naar 844 × 390 en terug. Na herladen hervatte **Verder spelen** bij les 4. Aan het eind bleven alle zes resultaten en het tuinfeest beschikbaar. De zes afgeronde leskaarten zijn ook weergegeven op 320 × 568.

De gebruikte Windows-build biedt geen `AudioContext`. Die speelproef beoordeelde beeld, bediening en opslag. Voor Safari op een Apple-apparaat is een afzonderlijke speeltest nodig. Beelden en testuitvoer staan in `builds/verification/webkit-alpha-v0.0.33/`. [Playwright over WebKit per platform](https://playwright.dev/docs/browsers#webkit)

## Laadherstel in alpha-v0.0.34

Bij een minuut zonder nieuwe bytes of eerste spelbeeld verschijnt **Opnieuw proberen**. Camiel blijft intussen laden. Nieuwe bytes tonen weer de voortgang en verlengen de wachttijd. In Playwright WebKit is de download onderbroken en op twee manieren hersteld. De download kon zelf doorgaan tot het titelscherm. De herstelknop kon ook een nieuwe download starten die het titelscherm bereikte.

In WebKitGTK 2.50.6 met een virtuele processor waarop WebAssembly-SIMD niet beschikbaar was, bleef alpha-v0.0.33 na de download op het laadscherm staan. Alpha-v0.0.34 toont meteen hoe je een geschikte browser kunt openen. De gecontroleerde browser vroeg `index.wasm` en `index.pck` in dat geval niet op. [WebAssembly SIMD](https://github.com/WebAssembly/simd/blob/main/proposals/simd/BinarySIMD.md)

De volledige speelroute van alpha-v0.0.34 is opnieuw doorlopen in Playwright WebKit op Windows en in Chrome. In beide browsers bleven de zes lesresultaten en het tuinfeest na herladen beschikbaar. Uitvoer en beelden staan in `builds/verification/opstarten-alpha-v0.0.34/`.

Met WebAssembly-SIMD beschikbaar bereikte WebKitGTK 2.50.6 in de Debian-VM het titelscherm en hoofdmenu. De opname aan de audio-uitgang van de VM bevatte spelgeluid. In Firefox bevatte een aparte opname van de vormenles spraak vóór en na het pauzeren. Tijdens de pauze gaf de opname geen signaal.

## Tijdelijke voortgang in alpha-v0.0.35

Ook wanneer een browser een lesresultaat niet kan opslaan, telt de les mee zolang het spel in dat tabblad openstaat. Na de laatste ontbrekende les verschijnt **Naar het tuinfeest**. Bij een mislukte schrijfpoging toont het eindscherm van die les **Les voltooid. Opslaan mislukt.**

In Playwright WebKit zijn twee routes met gesimuleerde aanraking uitgespeeld. In de eerste proef werd elke schrijfpoging geweigerd. In de tweede proef mislukte alleen het opslaan van les 2. De knop na les 6 ging in beide gevallen rechtstreeks naar het tuinfeest en de leskeuze toonde zes vinkjes. Na herladen begon de eerste proef opnieuw bij de intro. In de tweede proef waren vijf resultaten bewaard en opende **Verder spelen** les 2. Uitvoer en beelden staan in `builds/verification/sessievoortgang-alpha-v0.0.35/`.

## Softwareweergave op hoge pixeldichtheid in alpha-v0.0.36

Bij detectie van SwiftShader of llvmpipe tekent de browser maximaal één beeldpixel per CSS-pixel. Het spel vult het browservenster en de knoppen behouden hun afmetingen. Een schermfilter verzacht de randen van de 3D-wereld en één schaduwkaart van 1024 × 1024 behoudt de schaduwen. Met hardwareversnelling en als de browser de renderer niet doorgeeft, gebruikt Godot de standaard pixeldichtheid.

Op 390 × 844 CSS-pixels zijn in Chrome 158 op Windows per versie en pixeldichtheid twee reeksen van 3,6 seconden gemeten tijdens lopen en springen. In de softwareproef was SwiftShader expliciet ingeschakeld. De tabel toont de mediane tijd tussen opeenvolgende browserframes.

| Weergave | Alpha-v0.0.35 | Alpha-v0.0.36 |
|---|---:|---:|
| SwiftShader, DPR 3 | 321,2–357,6 ms | 36,4–42,4 ms |
| SwiftShader, DPR 2 | 181,8 ms | 36,4 ms |
| RTX 5090, DPR 2 en 3 | 6,1 ms | 6,1 ms |

Op 568 × 260 CSS-pixels zijn in de softwareproef op DPR 3 **Pauze** en **Verder spelen** aanraakbaar gebleven. Camiel liep met één contact en sprong met een tweede contact terwijl de joystick werd vastgehouden.

De intro, alle zes lessen en het tuinfeest zijn met gesimuleerde aanraking doorlopen in Chrome met beide weergavemodi op DPR 3 en in Playwright WebKit op DPR 1. Tijdens les 3 draaide het scherm van 390 × 844 naar 844 × 390 en terug. Na herladen hervatte het spel bij les 4 en bleef het tuinfeest aan het eind bereikbaar. Meetgegevens en screenshots staan in `builds/verification/softwareweergave-alpha-v0.0.36/`. Een speeltest op fysieke telefoons staat nog open.
