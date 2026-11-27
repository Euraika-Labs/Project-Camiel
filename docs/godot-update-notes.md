# Godot-versie en projectformaat

De huidige 3D-versie gebruikt **Godot 4.7.2.stable**, met bijpassende exporttemplates. `project.godot` gebruikt `config_version=5`. Dit formaatnummer is geen engineversienummer en mag niet voor een versiebump worden verhoogd.

De vroegere tekst op deze pagina over een 4.6.2 → 4.6.4-upgrade, `config_version=6`, Android-builds en specifieke enginefixes was geen betrouwbare beschrijving van de huidige implementatie en is ingetrokken. Raadpleeg de gitgeschiedenis uitsluitend als historisch materiaal.

## Huidige afspraken

- De engineversie is vastgelegd in `ci.yml`, `export.yml` en de buildhelper. De releaseworkflow hergebruikt die keten.
- De renderer is Compatibility; de 3D-physicsbackend is Jolt Physics.
- `application/config/version` bevat het versienummer. `application/config/release_channel` bepaalt het voorvoegsel van de titel en releasetag.
- De projectnaam is `Camiel`. De afzonderlijke instelling `config/custom_user_dir_name` verwijst per platform naar de bestaande opslagmap.
- Android APK-export en ondertekende desktopdistributie vallen buiten deze mijlpaal.

Volg [Godot instellen](godot-setup.md) en [bouwen en releasen](build-and-release.md). Een latere engine-upgrade vereist opnieuw import-, spel-, opslag- en exportverificatie; alleen een instelling aanpassen bewijst geen compatibiliteit.
