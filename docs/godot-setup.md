# Godot instellen voor Camiel

## Vastgepinde versie

Gebruik **Godot 4.7.2.stable**, standaardeditie zonder .NET, en exporttemplates
**4.7.2.stable**. CI en de exporthelper weigeren een afwijkende engineversie.
Download de binary voor je besturingssysteem en de templates uit de
[officiële 4.7.2-release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable).
Controleer downloads tegen `SHA512-SUMS.txt` uit dezelfde release voordat je ze
uitpakt. Installeer de `.tpz` via **Editor → Manage Export Templates → Install
from File**. CI voert de download, hashcontrole en installatie automatisch uit.

```bash
/path/to/Godot --version
/path/to/Godot --editor --path .
```

De versie-uitvoer begint met `4.7.2.stable`. Op macOS staat de binary gewoonlijk
in `/Applications/Godot.app/Contents/MacOS/Godot`. Een algemene pakketmanager
kan een andere versie installeren; controleer altijd de feitelijke uitvoer.

## 3D-project

`project.godot` start `res://scenes/title_screen.tscn`. De menu's leiden naar de
introductie en lessen. `scenes/camiel.tscn` heeft een `CharacterBody3D` met
3D-collision en camera; `scripts/camiel_controller.gd` verwerkt beweging via
InputMap-acties. Het project gebruikt de Compatibility-renderer. De huidige
spelwereld bestaat uit 3D-scenes; de oude 2D/SpriteFrames-verifier geldt niet
voor deze build.

Audio en voortgang worden beheerd door autoloads. Voortgang blijft lokaal in
Godots `user://`-directory. Verander `config/name` of de custom user-directory
niet zonder migratie: bestaande saves kunnen anders onzichtbaar worden.
De releaseversie staat afzonderlijk in `application/config/version`.

## Verificatie

```bash
GODOT=/path/to/Godot bash scripts/tools/run_headless_check.sh
GODOT=/path/to/Godot bash scripts/tools/test_headless_check.sh
```

De eerste controle importeert het project, start de hoofdscene, laadt de scripts
en scenes met `verify_3d_project.gd` en voert de `probe_*.gd`-gedragscontroles uit.
De tweede voert ook opzettelijke foutgevallen uit op een tijdelijke kopie.

Een Godot-exitcode nul is onvoldoende: de wrapper controleert foutmeldingen,
de verifier-successregel en proceslimieten. Headless controles bewijzen geen
juiste visuele weergave, bediening of kindvriendelijkheid. Gebruik de editor
(F5) en uitgepakte builds voor die aanvullende controles.

Zie [bouwen en releasen](build-and-release.md) voor exportpresets, pakketnamen,
webexport en de releaseworkflow.
