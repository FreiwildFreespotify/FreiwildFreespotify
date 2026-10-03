# Freiwild Spotify modded 🟣

**Dark + Lila Spotify-Theme** – basiert auf [Spicetify](https://spicetify.app).

> Open Source · built on Spicetify CLI (LGPL-2.1)

---

## Installation (Einzeiler)

Öffne **PowerShell** und füge ein:

```powershell
irm https://raw.githubusercontent.com/FreiwildFreespotify/Freiwild-Spotify/main/install.ps1 | iex
```

Das war's. Das Skript:

1. lädt (falls fehlend) die **offizielle Spicetify-CLI** herunter
2. holt sich das **neueste Freiwild-Paket** von diesem Repo
3. installiert Theme + Extension nach `%APPDATA%\spicetify`
4. setzt die Config und führt `spicetify backup apply` aus

## Updates

**Einfach den gleichen Einzeiler nochmal ausführen.**

Das Skript vergleicht die lokale `version.json` mit der auf GitHub und
zieht sich automatisch die neue Version. Kein Neustart nötig.

## Deinstallation

```powershell
irm https://raw.githubusercontent.com/FreiwildFreespotify/Freiwild-Spotify/main/install.ps1 | iex -ArgumentList -Uninstall
```

oder lokal:

```powershell
.\install.ps1 -Uninstall
```

---

## Was ist drin?

| Pfad | Inhalt |
|---|---|
| `install.ps1` | Installer + Auto-Updater (PowerShell 5.1+) |
| `themes/Freiwild/` | Theme mit 3 Farbschemata: `freiwild`, `freiwild-amoled`, `freiwild-soft` |
| `extensions/Freiwild.js` | Version-Badge + Menüeintrag in Spotify |
| `version.json` | Versionsnummer für das Update-System |

### Farbschemata

Nach der Installation umschaltbar mit:

```powershell
spicetify config color_scheme freiwild-amoled
spicetify apply
```

- **freiwild** – Deep Dark mit Neon-Lila
- **freiwild-amoled** – True Black (OLED)
- **freiwild-soft** – helles Lila für tagsüber

## Voraussetzungen

- Windows 10/11
- Spotify Desktop-App
- PowerShell 5.1+ (vorinstalliert)

## Anforderungen an dieses Repo (wichtig für Updates)

Die `install.ps1` erwartet diese Dateien **exakt** unter diesen Pfaden
(im `main`-Branch):

```
version.json
themes/Freiwild/color.ini
themes/Freiwild/user.css
extensions/Freiwild.js
README.md
```

Wenn du neue Dateien hinzufügst, musst du `install.ps1` anpassen
(Funktion `Install-FreiwildPackage`).

## Rechtliches / Credits

- ✅ Eigene CSS-/JS-Dateien: frei nutzbar
- 🔗 Basierend auf [Spicetify CLI](https://github.com/spicetify/cli) – **LGPL-2.1**
  (das Original-[LICENSE](LICENSE) bleibt erhalten)
- ⚠️ Nicht mit Spotify AG verbunden. Kein Premium-Bypass, keine Werbeblockade –
  nur optische Anpassung.
