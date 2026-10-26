# web/ — browser build of the clean-room slice

The same Rust code, compiled to WebAssembly. No CDN, no tracker, no original
asset: three files and a static host.

| File | What it is |
|---|---|
| `index.html` | the page: 4:3 canvas, one line of chrome |
| `tds.wasm` | `cargo build --release --target wasm32-unknown-unknown` |
| `mq_js_bundle.js` | WebGL + input glue shipped inside the `macroquad` crate |
| `serve.mjs` | dependency-free static server with the right `.wasm` MIME |
| `build.ps1` | rebuilds `tds.wasm` from `../game` and copies it here |

## Build

```powershell
.\build.ps1
```

## Run locally

```powershell
node serve.mjs          # http://localhost:8080/
```

The server binds `0.0.0.0`, so the address it prints also works from a phone on
the same network. Opening `index.html` from `file://` does **not** work: the
browser refuses to fetch the `.wasm` from disk.

## Deploy

It is a static folder. Any host that serves `application/wasm` works:

- GitHub Pages: push this folder, Settings -> Pages -> deploy from `main` / root.
- Netlify / Vercel / Cloudflare Pages: drag the folder, no build command.

## Controls in the browser

`SPACE` buy, `E` upgrade, `ENTER` start the wave, `R` restart, or click a shop
card. Click the canvas once if the keyboard does not answer: the game only
receives keys while the canvas has focus.

Balance is still a placeholder (`src/run.rs::BALANCE`, BOUNCE GAME-01) and every
mark on screen is a rectangle, circle or triangle.
