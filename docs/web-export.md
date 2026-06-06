# Web Export Guide (HTML5)

Camiel can be exported as a self-contained HTML5 game that runs in any modern desktop browser. This document covers how to export, what to expect, and how to host the result.

---

## Prerequisites

1. **Download Godot 4.6.3 export templates** before exporting for the first time:
   - Open Godot 4.6.3 editor
   - Go to **Editor → Manage Export Templates**
   - In the version field type `4.6.3` and press Enter
   - Click **Download** and wait for it to complete (~500 MB)
   - Templates are stored at `~/.local/share/godot/export_templates/4.6.3/`

2. **Godot editor must be the 4.6.3 release** — download from [godotengine.org/download](https://godotengine.org/download)

---

## How to Export

1. Open the project in Godot 4.6.3 editor (`godot --path .`)
2. Go to **Project → Export**
3. If no HTML5 preset is configured, click **Add…** and select **HTML5**
4. Set **Export Path** to e.g. `builds/html5/index.html`
5. Click **Export Project** and wait (~1–2 minutes)
6. The output is a folder containing `index.html`, `index.pck`, and supporting files (~30–50 MB total)

---

## Performance Notes

| Platform | Recommended | Notes |
|----------|-------------|-------|
| Desktop Chrome/Firefox/Edge | ✅ Yes | Full performance, hardware-accelerated WebGL |
| macOS Safari | ⚠️ Caution | Some rendering issues known in Godot 4.x |
| Mobile browsers | ❌ Not recommended | Touch input works but framerate is poor; Android Chrome may crash on complex scenes |

Web export is designed for **desktop browsers only**. For mobile, use the Android APK instead.

---

## Loading Screen

Godot's HTML5 export includes a built-in loading screen that displays automatically while the game assets load. You can customise it by replacing the files in the exported `index.html` — search for `loading` in the generated file for the relevant section.

---

## Hosting Options

### Option 1 — itch.io (Recommended for indie games)

1. Export to a folder, e.g. `builds/html5/`
2. Zip the entire folder (itch.io requires a `.zip` upload)
3. Create a new project on [itch.io](https://itch.io)
4. Upload the zip file
5. Set **Kind** to HTML
6. Enable **Embedded** for iframe embedding

**Embed code for itch.io:**
```html
<iframe
  src="https://your-username.itch.io/camiel/index.html"
  width="1280"
  height="720"
  frameborder="0"
  allowfullscreen>
</iframe>
```

### Option 2 — GitHub Pages

1. Push the exported `html5/` folder contents to a GitHub repository
2. Enable GitHub Pages in **Settings → Pages → Source: main (root)**
3. Game is available at `https://yourusername.github.io/repo-name/index.html`
4. Note: GitHub Pages does not support WebAssembly threading by default — disable threads in the HTML5 export options if you encounter issues.

### Option 3 — Self-hosted

Upload the exported folder to any web server (nginx, Apache, Caddy, etc.). No server-side code is required. Ensure your server's `mime.types` includes:
```
application/wasm wasm
application/javascript js
```

---

## File Structure of a Web Export

```
html5/
├── index.html          # Main entry point
├── index.pck           # Compressed game data (embedded in HTML by default)
├── index.js            # Godot engine loader
├── index.wasm          # Godot WebAssembly binary
└── index.icon.png      # Favicon
```

Size tip: Enable **Variant → Compress** in the HTML5 export preset to reduce download size (~30 MB vs ~50 MB uncompressed). Godot also embeds the PCK into the HTML by default in 4.x, keeping file count minimal.

---

## CI/CD Web Export

The `.github/workflows/export.yml` workflow does not currently build the web export due to the large export template download (~1 GB) making CI runners slow. To add a web export job:

```yaml
  export-web:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: gobject/godot-action@v3
        with:
          godot-version: 4.6.3
      - name: Export HTML5
        run: |
          mkdir -p builds/$GITHUB_REF_NAME/web
          godot --headless --path . --export-release "HTML5" builds/$GITHUB_REF_NAME/web/index.html
      - uses: actions/upload-artifact@v4
        with:
          name: camiel-web-$GITHUB_REF_NAME
          path: builds/$GITHUB_REF_NAME/web/
          retention-days: 30
```

Add `export-web` to the `needs` list of the `release` job to include it in releases.