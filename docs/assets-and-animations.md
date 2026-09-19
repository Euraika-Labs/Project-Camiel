# Assets en animaties — 3D

## Camiel

Het huidige model staat in `assets/characters/camiel/camiel.glb`, met importinstellingen in de bijbehorende `.glb.import`. Het is een voor dit project opgebouwd, textuurvrij glTF-model met materiaalvlakken en transformanimaties. De generator is `scripts/tools/build_camiel_model.py`; de referentie is Camiels gearchiveerde 2D-tekening. Het model is meegeleverd, dus Python of modelleersoftware is tijdens het spelen niet nodig.

```bash
python3 scripts/tools/build_camiel_model.py
```

Dit commando overschrijft het model. Importeer het resultaat met de vastgepinde Godot-versie en voer de model- en bewegingsprobes uit voordat je een gewijzigde asset oplevert.

`scripts/characters/camiel_visual.gd` bestuurt `idle`, `walk` en `jump`. Loopanimatie volgt werkelijke verplaatsing; de gedeelde `scripts/camiel_controller.gd` behoudt beweging, botsingen en camera. Lesobjecten blijven eenvoudige 3D-vormen.

Model- en bewegingsprobes zijn geslaagd. Herkenbaarheid als Camiel en prettig animatiegevoel moeten nog door mensen beoordeeld worden.

## Geluid en UI

Muziek en effecten staan in `assets/audio/`; Nederlandse PCM WAV-spraak en tekstcatalogus in `assets/audio/speech_nl/`. Zie de [audioassetnotities](../assets/audio/README.md). Het gedeelde UI-thema staat in `assets/theme/ui_theme.tres`; iconen worden door `scripts/ui/vector_icon.gd` getekend.

## Historische 2D-assets

De voormalige `assets/camiel/`, `assets/dogs/` en `assets/dogs_side/` horen bij tag `archive/2d-alpha-v0.0.3`. De huidige runtime gebruikt geen `AnimatedSprite2D` of SpriteFrames voor Camiel. De [ontwikkellog](development-log.md) bewaart de oude assetwerkwijze.
