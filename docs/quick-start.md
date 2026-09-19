# Camiel starten

Camiel is een Nederlandstalig 3D-leerspel. Alpha-v0.0.4 is technisch geïntegreerd en gemergd; beoordeling door kinderen en begeleiders blijft afzonderlijk nodig.

## Vanuit de broncode

1. Installeer de standaardeditie van **Godot 4.7.2**, volgens [Godot instellen](godot-setup.md).
2. Kies **Importeren** in de Godot-projectbeheerder en selecteer `project.godot`.
3. Open het project en druk op **F5**. Wacht bij de eerste start op het importeren van assets.
4. Kies **Spelen** op het titelscherm. Kies daarna **Start** voor de introductie of **Lessen** voor de zes lessen.

## Vanuit een desktopbuild

Pak het complete platformarchief uit; houd het uitvoerbestand en eventuele bijbestanden samen. Open op macOS de `.app`, op Windows het `.exe`-bestand, of op Linux het uitvoerbare bestand. Builds zijn niet ondertekend of genotariseerd. Gebruik alleen een build waarvan je de bron vertrouwt; houd eventuele beveiligingsmeldingen van het besturingssysteem aan. Bouwinstructies en exacte pakketnamen staan in [bouwen en releasen](build-and-release.md).

## In de browser

Een lokale Web-export en browserproef zijn uitgevoerd; ook de remote CI-export slaagt. De browserproef geldt voor de lokale build, niet voor een apart gedownload CI-artifact. Zie [bouwbewijs](build-and-release.md) voor commits en grenzen.

Pak de webbuild uit in `builds/web` en voer vanuit de repository uit:

```bash
python3 scripts/tools/serve_web.py builds/web
```

Open **http://127.0.0.1:8060/index.html**. Klik in het spel om toetsenbord en audio te activeren. Houd voor voortgang hetzelfde browserprofiel en dezelfde URL/poort aan. Zie [webexport](web-export.md) voor export, browseropslag en probleemoplossing. Dubbelklikken op het HTML-bestand werkt niet als startmethode.

## Bediening en geluid

| Actie | Bediening |
|---|---|
| Bewegen | WASD of pijltjestoetsen |
| Springen | Spatie |
| Schermbediening bij touch | Joystick en springknop, waar touch gedetecteerd wordt |
| Muziek en effecten | Schuifregelaars in het hoofdmenu |
| Hoog contrast en stemvolume | Instellingen in het hoofdmenu |

De camera volgt Camiel. Voor teruggaan gebruik je de zichtbare menuknoppen. Tijdens lessen geeft tekst samen met Nederlandse spraak de opdracht. De spraakassets zijn meegeleverd; er is geen spraakdienst nodig tijdens het spelen.

## Voortgang en ouderdashboard

Lesafrondingen worden lokaal opgeslagen. Desktop gebruikt Godots gebruikersmap (`user://progress.json`); web gebruikt IndexedDB in de browser. Het wissen van browsergegevens of gebruik van een andere origin kan webvoortgang verwijderen.

Het ouderdashboard leest een handmatig gekozen `progress.json` en vervangt de spelopslag niet:

```bash
python3 -m dashboard
```

Open **http://127.0.0.1:8765/**. Zie [ouderdashboard](parent-dashboard.md) voor het exportformaat en de privacygrenzen.

## Verificatiegrenzen

Headless spelprobes en browseropslagcontroles zijn uitgevoerd. Native uitvoer op Windows en Linux, fysiek multi-touchgebruik, hoorbaarheid op ieder apparaat en menselijke kindvriendelijkheidsbeoordeling zijn hiermee niet bewezen. Een volledig conformiteitslabel voor toegankelijkheid volgt niet uit enkele gemeten contrastverhoudingen. De [roadmap](roadmap.md) onderscheidt implementatie van acceptatie.
