# Toegankelijkheidsrapport — Camiel alpha-v0.0.4

Bijgewerkt op 19 september 2026. Dit rapport beschrijft de geïntegreerde 3D-versie op Godot 4.7.2. Het vervangt de historische 2D-claims. **Volledige WCAG-conformiteit is niet vastgesteld.** De onderstaande technische controles zijn geen menselijke beoordeling van begrijpelijkheid, comfort of zelfstandig spelen.

## Gemeten tekstcontrast

`scripts/tools/probe_accessibility.gd` berekent contrast met gelineariseerde RGB-waarden en relatieve luminantie. Het gedeelde thema gebruikt donkere tekst `Color(0.12156863, 0.22745098, 0.3372549, 1)`.

| Achtergrond | Kleur | Gemeten verhouding |
|---|---|---|
| Blauwe menuachtergrond | `(0.62, 0.82, 0.95)` | 7,16:1 |
| Crèmekleurig paneel/knop | `(1, 0.9647059, 0.9098039)` | 10,90:1 |
| Ingedrukte knop | `(0.92, 0.88752943, 0.8370196)` | 9,12:1 |

De probe controleert alle expliciet ingestelde, niet-uitgeschakelde tekstkleuren in het thema tegen deze drie achtergronden met een grens van 4,5:1. De definitieve geïntegreerde run slaagt. Dit is geen volledige inventaris van elke gerenderde pixel, transparantiecombinatie, systeemwidget of 3D-achtergrond. Uitgeschakelde tekststates zijn niet in deze berekening opgenomen.

## Hoog contrast en bediening

Het hoofdmenu biedt **Instellingen → Hoog contrast**. De gedeelde thematekst wordt zwart; themapanelen en knoppen krijgen een witte achtergrond en zwarte randen. De volumebalkvulling blijft zwart, zodat deze zichtbaar is op wit. De voorkeur wordt lokaal bewaard in `user://settings.cfg`.

De technische probe bevestigt bereikbaarheid van de instellingenknop, omschakelen via de UI, onmiddellijke wijziging van het geladen thema, opslaan van de voorkeur, sluiten met Escape en herstel van focus naar Start. De coördinator heeft de macOS-instellingenflow visueel doorlopen. De oorspronkelijke witte volumebalk op een wit paneel is daarbij gevonden en hersteld.

De vaste crèmekleurige HUD-achtergrond en lokale winpaneelstijl schakelen niet integraal naar wit; hun tekst schakelt wel mee. Daaruit wordt geen volledige schermbrede hoogcontrastgarantie afgeleid. Titelscherm, hoofdmenu en lesselectie gebruiken dezelfde gedeelde themabron, maar de lesdoelkleuren blijven inhoudelijk behouden.

## Tekst, geluid en aanraakbediening

Het thema definieert 20 px voor kleine labels, 28 px voor knoplabels, 40 px voor koppen en 64 px voor de grote titel. Dit zijn Godot-layoutwaarden; de effectieve fysieke grootte hangt van scherm en schaling af. Er wordt geen universele leesbaarheids- of aanraakdoelconformiteit uit afgeleid.

Nederlandse instructies en feedback zijn als offline audio meegeleverd op een afzonderlijke Voice-bus. Hoofdmenu en instellingen bieden afzonderlijke regelaars voor muziek, effecten en stem. Audioprobes bewijzen routing en niet-stille samples; zij beoordelen geen verstaanbaarheid. Browsers kunnen audio blokkeren tot een gebruikersgebaar.

De touchprobe controleert proportionele joystickinvoer, gelijktijdig springen, loslaten en focusverlies in intro en alle zes lessen. Dit is gesimuleerde invoer. Een werkelijk touchscreen en menselijke bediening zijn nog apart te beoordelen.

## Bewijs en open punten

De volledige geïntegreerde Godot-gate bevat de toegankelijkheidsprobe en slaagt. Bewijs is lokaal gebundeld onder `builds/acceptance/` en in de workspace-acceptatietaak. Webschermafbeeldingen staan onder `builds/web-verification-final/`. Deze lokale bestanden worden niet automatisch als gepubliceerde releasebijlage aangeboden.

Open blijven:

- Volledige audit van alle tekst-, focus-, icoon- en achtergrondcombinaties in alle schermtoestanden.
- Schaling en bruikbaarheid op uiteenlopende schermen en fysieke touchapparaten.
- Beoordeling met kinderen en begeleiders, inclusief kleuronderscheid, begrijpend luisteren en motorische belasting.
- Ondersteunende technologie, schermlezers, bewegingsgevoeligheid en een volledige toegankelijkheidsaudit.

De geautomatiseerde resultaten rechtvaardigen uitsluitend de hierboven beschreven controles; er is geen algemene toegankelijkheidscertificering of volledige mijlpaalacceptatie afgegeven.
