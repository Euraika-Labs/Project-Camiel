# Roadmap

## Alpha-v0.0.4 — geïntegreerd, acceptatie open

Camiel is opgebouwd als Nederlandstalig 3D-spel in Godot 4.7.2 met Compatibility-rendering. De oude 2D-runtime is gearchiveerd onder `archive/2d-alpha-v0.0.3`; historische 2D-functies zijn geen claims over de huidige build.

| Onderdeel | Geïmplementeerd | Bewijs en grens |
|---|---|---|
| Intro en lessen | Titelscherm, hoofdmenu, lesselectie, introductie en zes lessen | Headless flows en lesregels getest; menselijke speelbeoordeling open |
| Voortgang | Lokale lesafrondingen met sterren, tijd en datum | Alle zes lessen na echte procesexit teruggelezen |
| Camiel | GLB-karakter met idle-, loop- en springanimatie | Model- en bewegingsprobes; menselijke herkenbaarheid en animatiegevoel open |
| Toegankelijkheid | Leesbare themakleuren en instelling voor hoog contrast | Gemeten kleurparen en live themaprobe; geen volledige WCAG-conformiteitsclaim |
| Nederlandse spraak | Gebundelde instructies en feedback, eigen volumebus | Audiobus en assetprobes; luisteren op doelapparaten apart |
| Touch | Proportionele joystick, gelijktijdig springen, vrijgeven en focusverlies | Inputprobes in intro en alle lessen; fysiek touchscreen open |
| Web | Web-preset, lokale server en CI-exportconfiguratie | Echte browserles en opslag na herladen getest; bron/buildmatching gecontroleerd; remote CI-export geslaagd; CI-artifact zelf nog niet in browser gespeeld |
| Ouderdashboard | Lokale import, voortgang en samenvatting | HTTP- en browsercontroles; geen accounts of cloudopslag |
| Releases | Versiebron, vier exportdoelen en één releaseworkflow | Lokale gates, remote CI en vier exportjobs geslaagd; getagde GitHub-release niet uitgevoerd |

De volledige geïntegreerde Godot-gate is geslaagd. Een eerder aangetroffen importcrash en testfouten worden in het acceptatiebewijs bewaard; een latere geslaagde run maakt die waarnemingen niet ongedaan. Builds moeten aan de daadwerkelijk geteste broninhoud worden gekoppeld. Het technische bewijs staat in de workspace-taak **Onafhankelijke controle en speelbare oplevering**; de projectplanning houdt open acceptatiecriteria zichtbaar.

## Starten en bouwen

- [Snel starten](quick-start.md)
- [Desktopbuilds en releases](build-and-release.md)
- [Webexport en browseropslag](web-export.md)
- [Lokaal ouderdashboard](parent-dashboard.md)

## Ontwerpprincipes

Eén opdracht tegelijk, duidelijke kleuren, grote bedieningsvlakken, weinig toetsen en geen tijdsdruk. Menselijke tests bepalen of kinderen het spel werkelijk zelfstandig begrijpen en prettig kunnen bedienen.

## Buiten deze mijlpaal

Accounts, telemetrie, cloudopslag, multiplayer, Android APK en betaalde codesigning zijn geen onderdeel van deze oplevering. Windows- en Linux-uitvoering, fysiek touchscreengebruik en menselijke acceptatie worden niet uit macOS- of headless resultaten afgeleid.

## Bewijs na integratie — 19 september 2026

[PR #10](https://github.com/Euraika-Labs/Project-Camiel/pull/10) is gemergd als `c00504dc2d4f28a050ac3f31db5f9c84b3190836`. [CI-run 35468153825](https://github.com/Euraika-Labs/Project-Camiel/actions/runs/35468153825) slaagde op PR-head `2e84a3a97bee5627ef43c05300c1bbecaa6b07d5`: projectcontrole, 16 foutinjectiegevallen en vier exports. Alle 11 PR-checks waren groen, inclusief de exacte verplichte naam `Export Windows build`.

De eerdere lokale integratierun telde 41 Python-tests en 13 Godot-probes. De latere Windows-gate voegde een Python-regressietest toe. Lokale macOS- en browserflows en opslag na een echte procesherstart zijn getest. De CI-webexport is gebouwd, maar het gedownloade CI-webartifact is niet afzonderlijk in een browser gespeeld; het eerdere browserbewijs betreft de lokaal geëxporteerde runtime. Menselijke speelacceptatie, fysiek touchscreengebruik, native Windows/Linux-uitvoering en een getagde releasepublicatie blijven open. Lokale bewijsbestanden onder `builds/verification/` worden niet in git meegeleverd.
