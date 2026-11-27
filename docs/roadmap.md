# Roadmap

## Werkversie alpha-v0.0.45

Camiel is opgebouwd als Nederlandstalig 3D-spel in Godot 4.7.2 met Compatibility-rendering. De oude 2D-runtime is gearchiveerd onder `archive/2d-alpha-v0.0.3`; historische 2D-functies zijn geen claims over de huidige build.

| Onderdeel | Geïmplementeerd | Bewijs en grens |
|---|---|---|
| Intro en lessen | Intro, zes lessen met gesproken begeleiding en een herhaalbaar tuinfeest | De volledige route doorlopen in Windows en Chrome met geautomatiseerde invoer in alpha-v0.0.44 |
| Voortgang | Lokale lesafrondingen met sterren, tijd en datum | In alpha-v0.0.44 de zes resultaten teruggelezen na een herstart in Windows en na herladen in Chrome |
| Camiel | Vernieuwd 3D-model met knipperen en bewegende hangoren | Het portret is getest in Windows en Chrome. Lopen, springen en landen zijn getest in Windows |
| Toegankelijkheid | Leesbare themakleuren en instelling voor hoog contrast | Gemeten kleurparen en live themaprobe; geen volledige WCAG-conformiteitsclaim |
| Nederlandse spraak | Gebundelde instructies en feedback, eigen volumebus | Audiobus en assetprobes; luisteren op doelapparaten apart |
| Touch | Proportionele joystick, gelijktijdig springen, vrijgeven en focusverlies | Inputprobes in intro en alle lessen; fysiek touchscreen open |
| Web | Web-preset, lokale server en een Chrome-opstartproef voor upload | De lokale Chrome-proef slaagde in alpha-v0.0.45. Zie de [PR-checks](https://github.com/Euraika-Labs/Project-Camiel/pull/13/checks) voor de GitHub-run |
| Ouderdashboard | Lokale import, voortgang en samenvatting | HTTP- en browsercontroles; geen accounts of cloudopslag |
| Releases | Versiebron, vier exportdoelen en één releaseworkflow | Lokale Windows- en Webpakketten voor alpha-v0.0.45 gecontroleerd. Getagde releasepublicatie staat open |

De [snelstartgids](quick-start.md#verificatiegrenzen) vermeldt per werkversie welke speelroutes en platformen zijn getest. [PR #13](https://github.com/Euraika-Labs/Project-Camiel/pull/13) volgt de integratie van de werkversie.

## Starten en bouwen

- [Snel starten](quick-start.md)
- [Desktopbuilds en releases](build-and-release.md)
- [Webexport en browseropslag](web-export.md)
- [Lokaal ouderdashboard](parent-dashboard.md)

## Ontwerpprincipes

Eén opdracht tegelijk, duidelijke kleuren, grote bedieningsvlakken, weinig toetsen en geen tijdsdruk. Menselijke tests bepalen of kinderen het spel werkelijk zelfstandig begrijpen en prettig kunnen bedienen.

## Buiten deze mijlpaal

Fysieke touchscreenbediening, hoorbaarheid op verschillende apparaten en zelfstandig spelen door jonge kinderen staan nog ter beoordeling. Accounts, telemetrie, cloudopslag, multiplayer, Android APK en betaalde codesigning vallen buiten deze werkversie.

## Bewijs na integratie — 19 september 2026

[PR #10](https://github.com/Euraika-Labs/Project-Camiel/pull/10) is gemergd als `c00504dc2d4f28a050ac3f31db5f9c84b3190836`. [CI-run 35468153825](https://github.com/Euraika-Labs/Project-Camiel/actions/runs/35468153825) slaagde op PR-head `2e84a3a97bee5627ef43c05300c1bbecaa6b07d5`: projectcontrole, 16 foutinjectiegevallen en vier exports. Alle 11 PR-checks waren groen, inclusief de exacte verplichte naam `Export Windows build`.

De eerdere lokale integratierun telde 41 Python-tests en 13 Godot-probes. De latere Windows-gate voegde een Python-regressietest toe. Lokale macOS- en browserflows en opslag na een echte procesherstart zijn getest. De CI-webexport is gebouwd, maar het gedownloade CI-webartifact is niet afzonderlijk in een browser gespeeld; het eerdere browserbewijs betreft de lokaal geëxporteerde runtime. Menselijke speelacceptatie, fysiek touchscreengebruik, native Windows/Linux-uitvoering en een getagde releasepublicatie blijven open. Lokale bewijsbestanden onder `builds/verification/` worden niet in git meegeleverd.
