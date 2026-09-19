# Godot-versie en projectformaat

De huidige 3D-versie gebruikt **Godot 4.7.2.stable**, met bijpassende exporttemplates. `project.godot` gebruikt `config_version=5`. Dit formaatnummer is geen engineversienummer en mag niet voor een versiebump worden verhoogd.

De vroegere tekst op deze pagina over een 4.6.2 → 4.6.4-upgrade, `config_version=6`, Android-builds en specifieke enginefixes was geen betrouwbare beschrijving van de huidige implementatie en is ingetrokken. Raadpleeg de gitgeschiedenis uitsluitend als historisch materiaal.

## Huidige afspraken

- De engineversie is vastgelegd in `ci.yml`, `export.yml` en de buildhelper. De releaseworkflow hergebruikt die keten.
- De renderer is Compatibility; de 3D-physicsbackend is Jolt Physics.
- De spelversie komt uit `application/config/version`, momenteel `alpha-v0.0.4`.
- `application/config/name` blijft `Camiel alpha-v0.0.3` om de bestaande gebruikersmap met saves te behouden; dit is geen aanwijzing dat de runtime nog 2D is.
- Android APK-export en ondertekende desktopdistributie vallen buiten deze mijlpaal.

Volg [Godot instellen](godot-setup.md) en [bouwen en releasen](build-and-release.md). Een latere engine-upgrade vereist opnieuw import-, spel-, opslag- en exportverificatie; alleen een instelling aanpassen bewijst geen compatibiliteit.
