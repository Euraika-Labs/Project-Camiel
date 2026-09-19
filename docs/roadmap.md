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
| Web | Web-preset, lokale server en CI-exportconfiguratie | Echte browserles en opslag na herladen getest; bron/buildmatching gecontroleerd; externe CI-run apart |
| Ouderdashboard | Lokale import, voortgang en samenvatting | HTTP- en browsercontroles; geen accounts of cloudopslag |
| Releases | Versiebron, vier exportdoelen en één releaseworkflow | Lokale gates en pakketchecks; getagde GitHub-release niet uitgevoerd |

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
