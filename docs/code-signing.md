# Ondertekening van desktopbuilds

## Huidige status — alpha-v0.0.4

Windows- en macOS-builds zijn **niet ondertekend**; macOS wordt niet genotariseerd. De exportpreset schakelt signing uit en `.github/workflows/export.yml` bevat geen certificaatdecodeer- of signtool-stap. De eerder beschreven `AUTHENTICODE_*`-integratie is niet geïmplementeerd. Het toevoegen van die secrets schakelt signing dus niet in.

Het besturingssysteem kan waarschuwingen of blokkades tonen. Gebruik builds uit een vertrouwde bron en volg de beveiligingsmelding van het apparaat; deze handleiding adviseert niet om beveiligingsfuncties uit te schakelen.

## Toekomstige uitbreiding

Signing en notarisation zijn uitgestelde requirements `REL-01` en `PLAT-02`. Een toekomstige implementatie moet certificaatbeheer, toegang tot sleutels, timestamping, verificatie van het uiteindelijke pakket en tests op het doelplatform omvatten. Bewaar privésleutels en certificaatwachtwoorden nooit in git.

De oude providerprijzen, gratis-abonnementsclaims en garanties over SmartScreen zijn verwijderd: ze zijn niet nodig voor de huidige ongetekende bouwketen en waren niet onderbouwd voor deze oplevering.

Zie [bouwen en releasen](build-and-release.md) voor de daadwerkelijk geïmplementeerde distributieprocedure.
