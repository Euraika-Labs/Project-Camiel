# Ouders en leerkrachten — Camiel alpha-v0.0.4

Camiel is een Nederlandstalig 3D-leerspel voor kinderen vanaf ongeveer drie jaar. Het ontwerp biedt rustige opdrachten zonder tijdslimiet. Of kinderen de instructies zelfstandig begrijpen en de beweging prettig vinden, moet nog met een menselijke speeltest worden beoordeeld. Speel aanvankelijk samen.

## Start en lessen

Kies **Spelen**, daarna **Start** voor de introductie of **Lessen** voor de lesselectie. Alle zes lessen zijn direct kiesbaar.

| Les | Opdracht |
|---|---|
| 1 | Rood en blauw aanraken en drie telvoorwerpen verzamelen, in vrije taakvolgorde |
| 2 | Cirkel, vierkant en driehoek in die volgorde aanraken |
| 3 | De cijfers 1, 2 en 3 in volgorde aanraken |
| 4 | Geel en groen aanraken en drie telvoorwerpen verzamelen, in vrije taakvolgorde |
| 5 | De cijfers 1 tot en met 4 in volgorde aanraken |
| 6 | De cijfers 1 tot en met 5 in volgorde aanraken |

Beweeg met WASD of de pijltjestoetsen en spring met Spatie. Op een gedetecteerd aanraakscherm verschijnen een joystick en springknop. Dit is technisch getest met gesimuleerde invoer; fysieke touchscreenbediening staat nog open. Gebruik de zichtbare terugknoppen om van lessen naar de selectie en het menu te gaan.

Nederlandse instructies en feedback zijn als audio meegeleverd. Muziek, effecten en stemvolume zijn afzonderlijk instelbaar. Hoog contrast is bereikbaar via **Instellingen**. Zie [toegankelijkheid](accessibility-report.md) voor de gemeten tekstcontrasten en beperkingen; dit is geen volledige WCAG-certificering.

## Voortgang en privacy

Elke afgeronde les voegt lokaal een record toe met sterren, duur en datum. De gemeten duur is geen aftellende tijdslimiet. Na afsluiten blijft voortgang bewaard. Browsergegevens wissen kan webvoortgang verwijderen.

Het [ouderdashboard](parent-dashboard.md) toont een handmatig gekozen `progress.json`. Het draait alleen lokaal en bevat geen accounts, telemetrie of cloudopslag. Het leest browseropslag niet automatisch uit.

## Samen uitproberen

Laat het kind kleuren benoemen, samen tellen en uitleggen welk doel het volgende is. Noteer per les waar hulp nodig is, of gesproken aanwijzingen verstaanbaar zijn en of camera en bediening comfortabel blijven. Sluit het spel volledig af en controleer na herstart de voortgang. Automatische tests vervangen deze observaties niet.

Zie [startinstructies](quick-start.md) voor installatie. Windows, Linux, macOS en Web worden geëxporteerd; alleen macOS en de lokale browserbuild zijn hier daadwerkelijk doorlopen. Het project valt onder de [repositorylicentie](../LICENSE).
