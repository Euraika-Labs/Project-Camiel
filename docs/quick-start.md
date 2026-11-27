# Camiel starten

Camiel is een Nederlandstalig 3D-leerspel. In werkversie alpha-v0.0.45 verken je de bostuin en speel je zes opdrachten. Beoordeling door kinderen en begeleiders blijft afzonderlijk nodig.

## Vanuit de broncode

1. Installeer de standaardeditie van **Godot 4.7.2**, volgens [Godot instellen](godot-setup.md).
2. Kies **Importeren** in de Godot-projectbeheerder en selecteer `project.godot`.
3. Open het project en druk op **F5**. Wacht bij de eerste start op het importeren van assets.
4. Kies **Spelen** op het titelscherm. Bij de eerste start opent **Start** de intro. Zodra je de intro hebt uitgespeeld, brengt **Verder spelen** je naar de eerste onafgeronde les.

## Vanuit een desktopbuild

Pak op Windows `Camiel-alpha-v0.0.45-windows-portable.zip` volledig uit en dubbelklik op **Camiel spelen.exe**. Houd **Camiel spelen.pck** in dezelfde map. De Godot-runtime zit in het archief. Vanuit deze clone kun je Camiel ook openen met `builds/windows-godot/Camiel spelen.lnk`. [Verplaatsbaar Windows-pakket](build-and-release.md#verplaatsbaar-windows-pakket)

Pak het complete platformarchief uit; houd het uitvoerbestand en eventuele bijbestanden samen. Open op macOS de `.app`, op Windows het `.exe`-bestand, of op Linux het uitvoerbare bestand. Builds zijn niet ondertekend of genotariseerd. Gebruik alleen een build waarvan je de bron vertrouwt; houd eventuele beveiligingsmeldingen van het besturingssysteem aan. Bouwinstructies en exacte pakketnamen staan in [bouwen en releasen](build-and-release.md).

## In de browser

De lokale webbuild van alpha-v0.0.45 startte in Chrome met het nieuwe titelportret. De exportworkflow controleert het webpakket in Chrome vóór upload. [Bouwbewijs](build-and-release.md#webpakket-controleren-vóór-upload) · [PR-checks](https://github.com/Euraika-Labs/Project-Camiel/pull/13/checks)

Pak de webbuild uit in `builds/web` en voer vanuit de repository uit:

```bash
python3 scripts/tools/serve_web.py builds/web
```

Open **http://127.0.0.1:8060/index.html**. De browser toont de laadvoortgang. Kies **Opnieuw proberen** als het laden wordt onderbroken. Klik in het spel om toetsenbord en audio te activeren. Houd voor voortgang hetzelfde browserprofiel en dezelfde URL/poort aan. Zie [webexport](web-export.md) voor export, browseropslag en probleemoplossing. Dubbelklikken op het HTML-bestand werkt niet als startmethode.

Als Firefox het geluid tegenhoudt, kun je op Camiels portret klikken om de begroeting te horen. Met **Spelen** kom je direct bij de gesproken menu-uitleg. [Spraak bij de eerste keer spelen](accessibility-report.md#spraak-bij-de-eerste-keer-spelen-in-alpha-v0044)

Open voor een speelproef op een tablet of telefoon de HTTPS-link van de uitgepakte webbuild op dat toestel. Het lokale startadres is voor de computer waarop de webserver draait. [Webbuild op tablet of telefoon](web-export.md#op-een-tablet-of-telefoon)

## Bediening en geluid

| Actie | Bediening |
|---|---|
| Bewegen | Pijltjestoetsen, WASD op QWERTY of ZQSD op Belgisch AZERTY |
| Springen | Spatie |
| Pauzeren of hervatten | P, **Pauze** of **Verder spelen** |
| Terug naar de lessen of het menu | Escape of de terugknop |
| De opdracht opnieuw horen | L of **Luister** |
| Menukeuze | Pijltjes en Enter, Tab, muis of aanraken |
| Schermbediening bij touch | Joystick en springknop, waar touch gedetecteerd wordt |
| Muziek en effecten | Schuifregelaars in het hoofdmenu en in pauze |
| Hoog contrast en stemvolume | Instellingen in het hoofdmenu en in pauze |

De camera volgt Camiel met een vaste kijkrichting. Een oplichtende ring toont een bereikbaar lesdoel. De pictogrammen bovenaan laten de kleuren, vormen of telstippen uit de opdracht zien. Elk voltooid doel wordt kleiner op zijn voetstuk en krijgt een vinkje boven het voorwerp en in de opdrachtbalk. Een korte klank bevestigt de aanraking. Als de bereikbare doelen buiten beeld liggen, wijst een pijl met het passende pictogram aan waar je heen kunt lopen. Na een les kun je opnieuw spelen, naar de lesselectie of door naar de volgende les. Camiel spreekt de opdrachten uit met meegeleverde Nederlandse spraak.

Bij het begin van de intro vertelt Camiel hoe je loopt en springt. Met een toetsenbord gebruik je de pijltjestoetsen en Spatie. Op een aanraakscherm doet het gele rondje de sleepbeweging voor en licht de springknop kort op. Elke aanwijzing verdwijnt zodra je die beweging hebt geprobeerd. De gouden bol ophalen kan ook meteen. Vanaf daar leiden de stapstenen naar de groene eindring bij de poort. Met **Luister** hoor je de uitleg of het huidige doel opnieuw.

Kies je je eerste les rechtstreeks via **Lessen**, dan doet de joystick het slepen voor of zie je de pijltjestoetsen. Sta je na de lesuitleg nog stil, dan zegt Camiel één keer hoe je loopt. De aanwijzing verdwijnt zodra je een stukje hebt gelopen.

In de vormen- en tellessen staat bovenaan welke vorm of welk getal je zoekt. Bij het volgende voorwerp zie je hetzelfde pictogram. Het bordje in een telles toont het cijfer en de bijbehorende telstippen. Raak je per ongeluk een ander doel, dan licht het juiste doel op en noemt Camiel het opnieuw. **Luister** herhaalt die stap.

In de twee kleurenlessen mag je de kleuren en telstenen in je eigen volgorde vinden. Camiel zegt welke kleur je hebt gevonden en telt de stenen hardop. Bovenaan vullen de drie telplekken zich van links naar rechts. **Luister** noemt de kleuren die je nog zoekt en zegt het als er nog telstenen liggen.

Tijdens pauze staat de lestijd stil. Escape sluit eerst het pauzepaneel. Muziek, effecten, stemvolume en hoog contrast worden lokaal bewaard.

Elke leskaart toont een beeld uit het speelveld. Een vinkje en het label **Afgerond** geven aan dat je die les al hebt uitgespeeld. Op een staand scherm verschijnen de leskaarten in twee kolommen. Het spel past de indeling aan wanneer je het scherm draait.

Na de laatste ontbrekende les verschijnt **Naar het tuinfeest**. Je mag de zes lessen in je eigen volgorde spelen. Als je ze alle zes hebt afgerond, kun je het feest ook openen vanuit de leskeuze. Kies op het tuinfeest **Vier mee** om Camiels sprongen en de confetti opnieuw af te spelen.

Na de intro leidt de bovenste knop direct naar een les. Na elke les leidt die knop naar de volgende onafgeronde les zolang er nog lessen over zijn. Enter kiest dezelfde route. Laat een ingedrukte looppijl eerst los als je met die pijl een andere knop wilt kiezen. **Kies een les** en **Nog een keer** blijven beschikbaar op het eindscherm. Vanuit het hoofdmenu kun je ook de intro herhalen en het vrijgespeelde tuinfeest bezoeken.

## Voortgang en ouderdashboard

Op desktop bewaart Camiel de intro en je lesafrondingen in Godots gebruikersmap. De lesresultaten staan in `user://progress.json`. In de browser delen tabbladen op hetzelfde webadres en in hetzelfde browserprofiel de voortgang. Een open hoofdmenu en de leskaarten werken bij zodra een ander tabblad een les opslaat. De webversie neemt eerdere intro- en lesresultaten uit dat profiel over. Als je de sitegegevens wist, verdwijnt die voortgang.

Het ouderdashboard leest een handmatig gekozen `progress.json` en vervangt de spelopslag niet:

```bash
python3 -m dashboard
```

Open **http://127.0.0.1:8765/**. Zie [ouderdashboard](parent-dashboard.md) voor het exportformaat en de privacygrenzen.

## Verificatiegrenzen

In alpha-v0.0.45 is Camiels nieuwe model bekeken op een staand en een liggend scherm. In het Windows-pakket zijn het portret, de overgang naar de intro en de animaties voor lopen, springen en landen gecontroleerd. Chrome toonde hetzelfde nieuwe portret. Beelden en testuitvoer staan in `builds/verification/camiel-model-alpha-v0.0.45/`.

In alpha-v0.0.44 zijn de eindknoppen op 568 × 260 getest na de intro, na les 6 en op het tuinfeest. Met gesimuleerde aanraking ging het tuinfeest open terwijl het laatste lesresultaat nog werd opgeslagen. Met **Hoog contrast** aan bleven de opslagmelding, de focusrand en de aan-stand van de instelling zichtbaar. [Eindknoppen en hoog contrast](accessibility-report.md#eindknoppen-en-hoog-contrast-in-alpha-v0044)

In alpha-v0.0.43 gaf een gewoon HTTP-adres de HTTPS-aanwijzing vóór het ophalen van WebAssembly en het spelpakket. Op een lokaal HTTPS-testadres klonk de volledige Nederlandse intro in Chrome. Na draaien naar 568 × 260 pixels kon Camiel met twee gesimuleerde aanrakingen tegelijk lopen en springen. Alle zes lessen zijn via HTTPS uitgespeeld en het tuinfeest bleef bereikbaar na herladen. Beelden, opname en testuitvoer staan in `builds/verification/tablet-https-alpha-v0.0.43/`.

In alpha-v0.0.42 is in WebKit een opslagtransactie vanuit een ander tabblad opengehouden. Het spel startte en de speler kon na de intro en na een les door. Toen de opslag vrijkwam, verscheen **Les opgeslagen** op het eindscherm. Ook na les 6 ging het tuinfeest open terwijl het laatste resultaat nog wachtte. Na herladen stonden de zes resultaten elk één keer in de opslag. Beelden en testuitvoer staan in `builds/verification/opslagwachttijd-alpha-v0.0.42/`.

Het Linux-pakket van alpha-v0.0.42 is in een Debian-VM uitgespeeld. Na een herstart hervatte **Verder spelen** bij les 4. Na de volgende herstart ging het tuinfeest opnieuw open en klonk de Nederlandse uitnodiging via de virtuele audio-uitgang. [Linux-speeltest in alpha-v0.0.42](build-and-release.md#linux-speeltest-in-alpha-v0042)

In alpha-v0.0.41 is de route van de intro via alle zes lessen naar het tuinfeest doorlopen in Chrome, WebKit en het verplaatsbare Windows-pakket. In alle drie kon het tuinfeest na een herstart of herladen opnieuw open. In Chrome startte **Vier mee** de viering met Enter en met gesimuleerde aanraking. Ook liggend op 568 × 260 pixels bleef de knop bereikbaar. De uitnodiging is opgenomen in Chrome en bij het herhalen bleven de zes opgeslagen lesresultaten gelijk. Beelden en testuitvoer staan in `builds/verification/tuinfeest-alpha-v0.0.41/`.

In alpha-v0.0.40 is de vormenles vanuit de leskeuze uitgespeeld. Op 320 × 568 verscheen het bordje achtereenvolgens bij de cirkel, het vierkant en de driehoek. In les 6 bleef het na een verkeerde eerste aanraking bij de één staan. De screenshots van twee, drie en vijf tonen het juiste aantal losse stippen. Bij twee en drie loopt de rij van linksboven naar rechtsonder, zoals in de opdrachtbalk. Na **Nog een keer** verscheen het bordje weer bij de één.

De SwiftShader-proef in Chrome mat per versie twee reeksen van 3,6 seconden tijdens lopen en springen in les 6. Op 390 × 844 CSS-pixels bij DPR 3 lag het 95e percentiel van de beeldintervallen in beide versies op 42,5 ms. Beelden en meetgegevens staan in `builds/verification/doelbordjes-alpha-v0.0.40/`.

In alpha-v0.0.39 zijn de kleurblokken en telstenen op 320 × 568 en van dichtbij gecontroleerd. De gemeten CIELAB-afstand tussen het midden van een blok en zijn pictogram daalde voor de vier kleuren van 22,7–41,3 naar 8,2–10,8. Tussen het groene blok en het gras nam die afstand toe van 23,1 naar 36,1. De twee leskaarten gebruiken beelden uit de vernieuwde speelvelden.

In Chrome met SwiftShader duurde 95 procent van de gemeten beeldintervallen in les 4 hoogstens 48,6 ms in beide werkversies. Per versie zijn twee reeksen van 3,6 seconden gemeten tijdens lopen en springen op 390 × 844 CSS-pixels bij DPR 3. Beelden en meetgegevens staan in `builds/verification/kleurdoelen-alpha-v0.0.39/`.

In alpha-v0.0.38 is **Lessen → Les 1** rechtstreeks geopend met een leeg browserprofiel. Op 390 × 844 deed de joystick het slepen voor. De uitleg bleef leesbaar bij draaien naar 568 × 260. Op 800 × 450 verscheen het pictogram met de pijltjestoetsen. In beide invoermodi klonk de loophulp één keer na de lesopdracht als Camiel stilstond. Bij meteen lopen viel de gesproken loophulp weg. In de proef werd les 1 opgeslagen en opende **Naar les 2** de vormenles. Beelden, opnamen en testuitvoer staan in `builds/verification/eerste-les-alpha-v0.0.38/`.

In alpha-v0.0.37 zijn lopen en springen in beide volgordes getest. In Chrome bleef op 390 × 844 na het lopen alleen de springaanwijzing zichtbaar. Na draaien naar 568 × 260 bleef de aanwijzing leesbaar en kon Camiel met twee contacten tegelijk lopen en springen. Eerst springen liet de loopaanwijzing zichtbaar. De Godot-proef controleerde beide routes met toetsenbord en gesimuleerde aanraking, het herstel van beide aanwijzingen bij **Nog een keer** en de verwijzing naar de gouden bol via **Luister**. Beelden en testuitvoer staan in `builds/verification/introbediening-alpha-v0.0.37/`.

In alpha-v0.0.23 gaat een onderbroken gesproken aanwijzing verder wanneer je de pauze sluit. De browserproef in Chrome op 390 × 844 is opgenomen met muziek en geluidseffecten op nul. Tijdens **Pauze** bleef de stem stil. Na **Verder spelen** ging de vormenopdracht verder. Bij aanraking van de driehoek verwees de stem naar de cirkel. De controle in het Windows-spelpakket bevestigde dat geplande aanwijzingen tijdens de pauze bewaard blijven en vervallen wanneer je de les verlaat. Opnamen en uitvoer staan lokaal onder `builds/verification/narration-pause-alpha-v0.0.23/`.

In alpha-v0.0.22 is in Chrome op 320 × 568 met twee gesimuleerde contacten gelopen en gesprongen. Dit lukte ook bij de omheining. De browseropname bevatte de springuitleg voor aanraken en toetsenbord. In het Windows-spelpakket is in de intro en alle zes lessen naar elke hoek gesprongen. In alle 28 gevallen kon Camiel terug het speelveld in. Beelden en uitvoer staan lokaal onder `builds/verification/jump-help-alpha-v0.0.22/`.

In alpha-v0.0.21 is de route vanaf het nieuwe laadscherm tot het tuinfeest opnieuw doorlopen met gesimuleerde aanraking in Chrome. In les 3 draaide het scherm van 390 × 844 naar 844 × 390 en terug. Na pauzeren en hervatten kon Camiel de les afmaken. Na herladen hervatte het spel bij les 4. Alle zes resultaten en het tuinfeest bleven bewaard. Zie [bouwbewijs voor de nieuwe start](build-and-release.md#opstarten-in-alpha-v0021).

In alpha-v0.0.20 volgt een zichtbare rand de actieve knop en volumeregelaar als je Tab of de pijltjestoetsen gebruikt. In Chrome is de focus gecontroleerd met **Hoog contrast** aan en uit. Op 390 × 844 zijn de pictogrammen van **Luister**, **Pauze** en **Verder spelen** getest met gesimuleerde aanraking. Op 320 × 568 bleven de zes leskaarten en **Naar menu** in beeld.

In alpha-v0.0.19 opende een oudere save het tuinfeest op Windows en in een Debian-VM. In Chrome hervatte **Verder spelen** les 2 na de overstap van alpha-v0.0.18. De browserproef gebruikte hetzelfde adres en profiel. Zie [bouwbewijs voor projectnaam en opslag](build-and-release.md#projectnaam-en-opslag-in-alpha-v0019).

In alpha-v0.0.18 zijn de intro en alle zes lessen vanaf een lege voortgang uitgespeeld met gesimuleerde aanraking in Chrome op 390 × 844. Les 3 liep door na draaien naar 844 × 390 en na pauzeren. Na herladen bracht **Verder spelen** de speler naar les 4. In die les is zichtbaar gecontroleerd dat Camiel vrij in beeld blijft achter een voltooid kleurblok. Elke les schreef precies één resultaat. Het tuinfeest kon na herladen opnieuw worden geopend. De leskeuze toonde op 320 × 568 alle zes afgeronde lessen en de knop **Tuinfeest**. De volledige route is ook met geautomatiseerde invoer in het Windows-spelpakket doorlopen.

In alpha-v0.0.17 zijn de eerste bedieningsaanwijzingen in Chrome gecontroleerd op 800 × 450 met toetsenbord en 390 × 844 met gesimuleerde aanraking. De touchintro bleef speelbaar na draaien van het scherm. Na het bewegen verdween de bedieningshulp en bij opnieuw oefenen kwam die terug. De opgenomen browseraudio bevatte in beide gevallen de bijbehorende aanwijzing. In het Windows-spelpakket is de route na een herstart tot en met het tuinfeest doorlopen met geautomatiseerde invoer zonder grafisch scherm.

In alpha-v0.0.16 is de intro met gesimuleerde aanrakingen uitgespeeld in Chrome op 390 × 844. Na herladen bood **Verder spelen** les 1 aan. De intro kon ook opnieuw worden geopend. Na les 1 was precies één lesafronding opgeslagen en bracht **Verder spelen** de speler na herladen naar les 2. De Windows- en Linux-spelpakketten zijn zonder grafisch scherm getest over twee processen, op Windows en in een Debian-VM. De eerste sessie schreef de intro weg en de tweede voltooide de zes lessen en het tuinfeest. Op Windows zijn ook drie opgeslagen resultaten uit alpha-v0.0.15 teruggelezen en aangevuld met de resterende lessen.

In alpha-v0.0.15 is de hele route uitgespeeld vanaf het titelscherm tot het tuinfeest op 320 × 568. Enter activeerde de bovenste knop en elke les bewaarde één afronding. Een tweede ronde begon met drie opgeslagen afrondingen uit alpha-v0.0.14. Het hoofdmenu opende les 2, vervolgens kwamen les 4 en 5 en daarna het tuinfeest. In Chrome op 390 × 844 ging de intro met gesimuleerde aanrakingen over in les 1 en daarna les 2. Na herladen bracht **Verder spelen** de speler opnieuw naar les 2.

Op Debian 12 x86-64 zijn de intro en alle zes lessen met het uitvoerbestand van alpha-v0.0.28 uitgespeeld in een QEMU-VM met X11. Na les 3 hervatte een verplaatst uitvoerbestand bij les 4. Na les 6 ging het tuinfeest open en bleef het na een nieuwe herstart toegankelijk. [Volledige Linux-speeltest](build-and-release.md#volledige-linux-speeltest-in-alpha-v0028)

In alpha-v0.0.14 zijn beide kleurenlessen uitgespeeld op Windows. In elke les werd eerst de middelste steen gepakt en daarna een kleur. De opdracht stond na die twee acties nog op twee resterende stenen en één resterende kleur. **Luister** noemde de resterende doelen. In Chrome is les 1 op 390 × 844 getest met gesimuleerde aanrakingen. Aan de hand van de opgenomen browseraudio is gecontroleerd of de drie telcues en de aanwijzingen op het juiste moment klonken.

In alpha-v0.0.13 is de vormenles in Windows uitgespeeld op 1280 × 720 en 320 × 568. Een verkeerde aanraking liet de juiste volgende vorm horen. **Luister** gaf na de cirkel de aanwijzing voor het vierkant. Dezelfde route is in Chrome op 390 × 844 uitgevoerd met gesimuleerde aanrakingen. De browser speelde de twee juiste aanwijzingen af en bewaarde de lesafronding.

De lokale Windows-speelversie van alpha-v0.0.12 is met gesimuleerde spelinvoer getest vanaf de intro tot en met alle zes lessen. In twee extra speelrondes met verschillende lesvolgordes ging het tuinfeest open bij de laatste ontbrekende les. De zes opgeslagen lesresultaten uit alpha-v0.0.11 waren ook in deze versie zichtbaar. De leskeuze en het tuinfeest zijn gecontroleerd op een scherm van 320 × 568. Het Windows-toepassingsbeleid blokkeerde eerder de losse export. De snelkoppeling opent het spelpakket met de officiële Godot-runtime.

In Chrome zijn les 3 en les 2 met gesimuleerde aanrakingen uitgespeeld. Vier eerder gespeelde testresultaten vulden de voortgang aan. Het feest ging open na les 2 en bleef na herladen bereikbaar vanuit de leskeuze. De Linux- en macOS-archieven van alpha-v0.0.12 zijn technisch gecontroleerd.

Voor de huidige werkversie staan een speeltest met kinderen, bediening op een fysiek touchscreen, hoorbaarheid op verschillende apparaten, een test op fysieke Linux-hardware en uitvoering van de macOS-app nog open.
