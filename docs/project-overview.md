# Projectoverzicht — alpha-v0.0.4

Camiel is een Nederlandstalig educatief 3D-spel in Godot 4.7.2 voor kinderen vanaf ongeveer drie jaar. Het spel werkt offline, zonder accounts, telemetrie of externe opslag van kindgegevens.

Via het titelscherm en hoofdmenu zijn de introductie en zes lessen bereikbaar. De lessen oefenen kleurherkenning, tellen, vormen en volgorde. Camiel heeft een 3D-model met idle-, loop- en springanimaties. Instructies en feedback bevatten gebundelde Nederlandse spraak. De instellingen bieden hoog contrast en afzonderlijke audiovolumes; aanraakbediening ondersteunt bewegen en springen.

Lesafrondingen worden lokaal bewaard. Het ouderdashboard leest een handmatig gekozen voortgangsbestand via een lokale webinterface; het verzamelt geen gegevens van andere apparaten.

## Beschikbaarheid en acceptatie

De implementatie is gemergd via [PR #10](https://github.com/Euraika-Labs/Project-Camiel/pull/10). CI exporteert Windows, Linux, macOS en Web. De technische tests, lokale macOS-flow en lokale browserflow zijn uitgevoerd; native Windows/Linux-uitvoering, fysiek touchscreengebruik en menselijke speelacceptatie staan nog open. Een gepubliceerde alpha-v0.0.4-release is hiermee niet aangetoond.

Zie [snel starten](quick-start.md) voor bediening, [bouwen en releasen](build-and-release.md) voor pakketten en [roadmap](roadmap.md) voor bewijsgrenzen. De 2D-versie is geschiedenis, terug te vinden onder tag `archive/2d-alpha-v0.0.3`.
