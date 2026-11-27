# Toegankelijkheidsrapport — Camiel alpha-v0.0.4

Bijgewerkt op 19 september 2026. Dit rapport beschrijft de geïntegreerde 3D-versie op Godot 4.7.2. Het vervangt de historische 2D-claims. **Volledige WCAG-conformiteit is niet vastgesteld.** De onderstaande technische controles zijn geen menselijke beoordeling van begrijpelijkheid, comfort of zelfstandig spelen.

## Gemeten tekstcontrast

`scripts/tools/probe_accessibility.gd` berekent contrast met gelineariseerde RGB-waarden en relatieve luminantie. Het gedeelde thema gebruikt donkere tekst `Color(0.12156863, 0.22745098, 0.3372549, 1)`.

| Achtergrond | Kleur | Gemeten verhouding |
|---|---|---|
| Blauwe menuachtergrond | `(0.62, 0.82, 0.95)` | 7,16:1 |
| Crèmekleurig paneel/knop | `(1, 0.9647059, 0.9098039)` | 10,90:1 |
| Ingedrukte knop | `(0.92, 0.88752943, 0.8370196)` | 9,12:1 |

De definitieve geïntegreerde probe slaagt. De aanvullende broninventaris `builds/verification/text-contrast-inventory.json` kruist alle 15 expliciete, actieve tekstkleurinstellingen met alle 13 ondoorzichtige UI-achtergronden uit thema en scènes: 195 conservatieve combinaties, waaronder combinaties die niet samen worden getoond. Het minimum is **5,339:1**, boven de strengere grens van 4,5:1 voor normale tekst. Een onafhankelijke herberekening bevestigt alle verhoudingen en de themabronhash tegen de geteste eindboom.

Broncontrole bevestigt de thema-overerving voor titel, menu, lesselectie, instellingen, HUD en winpanelen, inclusief de Label-kinderen van menuknoppen; er zijn geen aanvullende runtime-tekstkleuroverrides. Hoog contrast gebruikt zwarte tekst en haalt ook over de conservatieve achtergrondset minimaal 9,598:1. De 3D-lescijfers gebruiken witte tekst met een zwarte contour van 24 eenheden: tekst tegenover contour is 21:1. De aanvullende runtime-inventaris `builds/verification/text-inventory.gd` instantieert tien scènes plus instellingen en controleert 65 werkelijke tekstnodes, inclusief verborgen winpanelen en de 3D-cijfers. Het bijbehorende `text-runtime.log` eindigt op `UI_TEXT_INVENTORY_PASS labels=65`, zonder fouten of waarschuwingen; daarmee is ook de daadwerkelijke thema-overerving gecontroleerd. **ACCESS-01 is hiermee voldaan voor tekstcontrast in de opgeleverde 3D-UI.** Uitgeschakelde bedieningselementen en tijdelijke in-/uitfades zijn uitgezonderd; dit is geen algemene WCAG-certificering.

## Hoog contrast en bediening

Het hoofdmenu biedt **Instellingen → Hoog contrast**. De gedeelde thematekst wordt zwart; themapanelen en knoppen krijgen een witte achtergrond en zwarte randen. De volumebalkvulling blijft zwart, zodat deze zichtbaar is op wit. De voorkeur wordt lokaal bewaard in `user://settings.cfg`.

De technische probe bevestigt bereikbaarheid van de instellingenknop, omschakelen via de UI, onmiddellijke wijziging van het geladen thema, opslaan van de voorkeur, sluiten met Escape en herstel van focus naar Start. De coördinator heeft de macOS-instellingenflow visueel doorlopen. De oorspronkelijke witte volumebalk op een wit paneel is daarbij gevonden en hersteld.

De vaste crèmekleurige HUD-achtergrond en lokale winpaneelstijl schakelen niet integraal naar wit; hun tekst schakelt wel mee. Daaruit wordt geen volledige schermbrede hoogcontrastgarantie afgeleid. Titelscherm, hoofdmenu en lesselectie gebruiken dezelfde gedeelde themabron, maar de lesdoelkleuren blijven inhoudelijk behouden.

## Tekst, geluid en aanraakbediening

Het thema definieert 20 px voor kleine labels, 28 px voor knoplabels, 40 px voor koppen en 64 px voor de grote titel. Dit zijn Godot-layoutwaarden; de effectieve fysieke grootte hangt van scherm en schaling af. Er wordt geen universele leesbaarheids- of aanraakdoelconformiteit uit afgeleid.

Nederlandse instructies en feedback zijn als offline audio meegeleverd op een afzonderlijke Voice-bus. Hoofdmenu en instellingen bieden afzonderlijke regelaars voor muziek, effecten en stem. Audioprobes bewijzen routing en niet-stille samples; zij beoordelen geen verstaanbaarheid. Browsers kunnen audio blokkeren tot een gebruikersgebaar.

De touchprobe controleert proportionele joystickinvoer, gelijktijdig springen, loslaten en focusverlies in intro en alle zes lessen. Dit is gesimuleerde invoer. Een werkelijk touchscreen en menselijke bediening zijn nog apart te beoordelen.

## Bewijs en open punten

De volledige geïntegreerde Godot-gate bevat de toegankelijkheidsprobe en slaagt. Bewijs is lokaal gebundeld onder `builds/verification/acceptance/` en in de workspace-acceptatietaak. Webschermafbeeldingen staan onder `builds/web-verification-final/`. Deze lokale bestanden worden niet automatisch als gepubliceerde releasebijlage aangeboden.

Open blijven:

- Aanvullende audit van focusindicatie, iconen en overige niet-tekstuele toegankelijkheid in alle schermtoestanden.
- Schaling en bruikbaarheid op uiteenlopende schermen en fysieke touchapparaten.
- Beoordeling met kinderen en begeleiders, inclusief kleuronderscheid, begrijpend luisteren en motorische belasting.
- Ondersteunende technologie, schermlezers, bewegingsgevoeligheid en een volledige toegankelijkheidsaudit.

De geautomatiseerde resultaten rechtvaardigen uitsluitend de hierboven beschreven controles; er is geen algemene toegankelijkheidscertificering of volledige mijlpaalacceptatie afgegeven.

## Pictogrammen en toetsenbordfocus in alpha-v0.0.20

De standaardpictogrammen gebruiken donkergroen. De contrastverhouding steeg op crème van 2,04:1 naar 9,78:1 en op de gouden speelknop van 1,42:1 naar 6,79:1. De pictogrammen op de kleurenkaarten behouden hun leskleuren en hebben een donkere omtrek. Als ondergrens voor de gecontroleerde pictogrammen en focusrand gebruikt de probe 3:1. [W3C-richtlijn voor niet-tekstueel contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)

In Chrome op 800 × 450 verplaatsten Tab en de pijltjestoetsen de zichtbare focus tussen leskaarten, knoppen en volumeregelaars. De focusrand bleef zichtbaar toen de muis op een andere regelaar stond. De rand bleef ook herkenbaar met **Hoog contrast** aan. In de Webexport op 390 × 844 zijn **Pauze** en **Verder spelen** via gesimuleerde aanraking getest. Het Linux-uitvoerbestand toonde de focusrand bij **Geluid** na twee keer Tab in een Debian-VM. Schermafbeeldingen en uitvoer staan lokaal onder `builds/verification/ui-contrast-alpha-v0.0.20/`.

## Toetsenbord bij pauze en lesafronding in alpha-v0.0.25

Bij het openen van een eindscherm of pauzepaneel behoudt de geselecteerde knop de focus zolang de looppijl van daarvoor ingedrukt blijft. Een nieuwe druk op de pijl verplaatst de focus. Dit is gecontroleerd bij de eindring, na les 1 en in het pauzepaneel. De toetsproef doorliep de intro en alle zes lessen in Chrome op 800 × 450. Na herladen hervatte het spel bij les 4. Leskaarten waren met de pijltjestoetsen bereikbaar op 800 × 450 en 390 × 844. Schermafbeeldingen en uitvoer staan lokaal onder `builds/verification/keyboard-alpha-v0.0.25/`.

## Eindknoppen en hoog contrast in alpha-v0.0.44

De eindknoppen in de intro, lessen en het tuinfeest zijn op een laag, breed scherm minimaal 104 Godot-eenheden hoog. Op 568 × 260 komt dat neer op circa 45 CSS-pixels. In WebKit kon de speler na het draaien van het scherm de intro met **Nog een keer** herhalen. Na les 6 opende een tik het tuinfeest terwijl **Opslaan duurt even…** nog in beeld stond. Na het vrijgeven van de opslag was elke les één keer vastgelegd.

De gemeten kleurverhouding van de opslagmelding was 10,90:1 in het gewone thema en 21:1 met hoog contrast. Op 320 × 568 en 568 × 260 was de focusrand van **Vier mee** zichtbaar en kon de speler de confetti opnieuw starten. **Hoog contrast (aan)** stond ook na terugkeer in de instellingen. Beelden en meetgegevens staan onder `builds/verification/eindknoppen-alpha-v0.0.44/`.

## Spraak bij de eerste keer spelen in alpha-v0.0.44

De Nederlandse begroeting op het titelscherm, de menu-uitleg en de intro zijn opgenomen in Chrome en in het Linux-uitvoerbestand op Debian 12 met een virtuele PulseAudio-uitgang. In de Chrome-proef op 390 × 844 gaf een gesimuleerde aanraking toegang tot het hoofdmenu en daarna tot de gesproken aanraakinstructies.

Firefox hield het geluid bij geblokkeerd automatisch afspelen stil tot de eerste invoer. Enter op **Spelen** opende het hoofdmenu en startte de volledige menu-uitleg. In een aparte sessie speelde een klik op Camiels portret de volledige begroeting terwijl het titelscherm openbleef. De opnamen en meetgegevens staan onder `builds/verification/eerste-speelminuut-alpha-v0.0.44/`.
