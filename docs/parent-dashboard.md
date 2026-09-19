# Lokaal ouderdashboard

Bekijk de opgeslagen lesafrondingen van één kind zonder accounts, installatie van
pakketten, telemetrie of externe verbindingen. Vereist Python 3.10 of nieuwer.
Start vanuit de projectmap:

```sh
python3 -m dashboard
```

Open **http://127.0.0.1:8765** en kies `progress.json`. Stop met Ctrl+C. Een andere
lokale poort kan met `python3 -m dashboard --port 8766`. De server bindt uitsluitend
op `127.0.0.1`; gebruik exact het afgedrukte adres (geen `localhost`, LAN-adres,
reverse proxy of publieke hosting). Er is geen toegang vanaf een ander apparaat.

## Het voortgangsbestand vinden

Het spel schrijft `user://progress.json` via `scripts/progress_tracker.gd`.
Voor de huidige projectnaam `Camiel alpha-v0.0.3` staat dit normaal in:

- Windows: `%APPDATA%\Godot\app_userdata\Camiel alpha-v0.0.3\progress.json`
- macOS: `~/Library/Application Support/Godot/app_userdata/Camiel alpha-v0.0.3/progress.json`
- Linux: `~/.local/share/godot/app_userdata/Camiel alpha-v0.0.3/progress.json`

De mapnaam volgt `application/config/name` in `project.godot`. Kopieer het bestand
bij voorkeur nadat het spel afgesloten is. Het dashboard zoekt of wijzigt geen
spelbestanden. Voor een webbuild is een expliciete export vanuit de webopslag nodig;
dit dashboard leest de browseropslag van het spel niet automatisch.

## Werkelijk opslagformaat

```json
{
  "version": 1,
  "entries": [
    {"lesson_id": "lesson_1", "stars": 3, "time_seconds": 142.75, "completed_at": "2026-06-05T14:32:00"},
    {"lesson_id": "lesson_1", "stars": 3, "time_seconds": 95.5, "completed_at": "2026-06-05T14:38:00"}
  ]
}
```

De eerdere ontwerptekst met `lessons` kwam niet overeen met het spel. Deze
implementatie gebruikt uitsluitend het echte, versiegebonden `entries`-formaat.
De eerder voorgestelde Next.js-stack is vervangen door Python-stdlib en lokale
HTML/CSS/JavaScript: geen buildstap, CDN of pakketinstallatie nodig.

Elke entry is één afronding, niet één unieke les. Herhaalde lescodes en identieke
entries blijven meetellen: het append-log heeft geen unieke sessiesleutel waarmee
veilige deduplicatie mogelijk is. Het huidige spel geeft altijd drie sterren;
het dashboard accepteert 1–3 voor het versie-1-formaat. Sterren zijn geen
vaardigheidsscore. Totale speeltijd behoudt fracties; de UI rondt alleen de weergave
af op twee decimalen. `last_session` is de grootste opgeslagen lokale datum, niet
noodzakelijk de laatste arraypositie. Er wordt geen tijdzone verzonnen.

## API-contract

| Methode | Pad | Resultaat |
| --- | --- | --- |
| GET | `/api/progress` | Huidige gevalideerde snapshot: `{ "version": 1, "entries": [...] }` |
| GET | `/api/summary` | Statistieken zoals hieronder |
| POST | `/api/progress/import` | `multipart/form-data` met precies één bestandsveld `file`; 200 met de volledige nieuwe snapshot |

```json
{
  "total_lessons_completed": 2,
  "total_stars": 6,
  "total_time_seconds": 238.25,
  "star_rating_breakdown": { "1_star": 0, "2_star": 0, "3_star": 2 },
  "last_session": "2026-06-05T14:38:00"
}
```

Een lege snapshot geeft nul totalen en `last_session: null`. Import **vervangt** de
snapshot in servergeheugen. Opnieuw uploaden verdubbelt niets. De oude formulering
“merge” is bewust niet geïmplementeerd: combineren van kinderen is buiten fase 8.
Er is geen database, LocalStorage of terugschrijven naar het originele bestand.
Alle tabbladen van dezelfde server zien dezelfde snapshot. Sluiten van alleen het
browservenster wist het servergeheugen niet; stoppen van de server wel. Gebruik dit
op een vertrouwd persoonlijk apparaat: andere lokale processen kunnen de API lezen.

### Validatie en grenzen

- Hoogstens 2 MiB per HTTP-upload, inclusief multipart-omslag; maximaal 10.000 entries.
- UTF-8 JSON (optionele BOM), geen dubbele keys of extra velden; `version` exact integer 1.
- `lesson_id`: 1–100 letters, cijfers, underscores of koppeltekens.
- `stars`: integer 1–3; booleans zijn niet toegestaan als getal.
- `time_seconds`: eindig getal van 0 tot 31.536.000, inclusief fracties.
- `completed_at`: geldige kalenderdatum, exact `YYYY-MM-DDTHH:MM:SS`, overeenkomstig Godot.
- Eén `Content-Length` vereist; chunked uploads worden geweigerd. Socket-timeout: 5 seconden.
- Geen bestandsnaam wordt als pad gebruikt. Alleen de drie vaste UI-assets en API-routes zijn bereikbaar.
- Host moet `127.0.0.1:<poort>` zijn. Een meegegeven Origin moet exact overeenkomen;
  cross-site en same-site browserrequests worden geweigerd. Er zijn geen CORS-toestemmingen.
- CSP beperkt assets en fetches tot de eigen oorsprong; responses zijn `no-store`.

Fouten geven JSON `{ "error": "Nederlandse uitleg" }`: 400 bij ongeldige data,
403 bij vreemde host/origin, 404 bij onbekende routes, 408 bij upload-timeout,
411 bij ongeldige of ontbrekende lengte en 413 bij te grote uploads. Een afgewezen
import laat de vorige snapshot intact. Upload nooit persoonlijke notities in dit
bestand; alleen de beschreven velden worden geaccepteerd.

## Verificatie

```sh
python3 -m unittest discover -s tests -p test_parent_dashboard.py -v
```

Tests starten een echte tijdelijke loopbackserver met uitsluitend synthetische
gegevens. Ze controleren statistieken, herhaalde afrondingen, herimport, lege data,
malformed JSON/schema, uploadlimieten, multipart, padtraversal, origin/hostcontrole,
lokale assets en behoud van een tijdelijk nagebootst spelbestand. Een omgeving die
loopbacksockets blokkeert kan deze runtime-tests niet uitvoeren.
