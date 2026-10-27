# Making a web build, by engine

JuicyJuicy serves the build folder at the root of the game's own origin (`https://<id>.juicyjuicy.space/`) inside a sandboxed iframe. What works: static files, ES modules, WebAssembly (`.wasm` is served as `application/wasm`), `localStorage`/IndexedDB saves (kept across versions; cookies are cleared), fetches to public CDNs and APIs, fullscreen, gamepads, pointer lock. What doesn't: server code, `SharedArrayBuffer` (no cross-origin isolation), popups and navigating the top page.

## Plain HTML, CSS and JavaScript
No build step. `buildDir` is `.` (the project folder), `entry` is `index.html`. Keep everything the game needs inside the folder and reference files with relative paths. Don't keep secrets in the folder, although hidden files (`.env`) are never uploaded anyway.

## Vite (also Phaser, Three.js, PixiJS templates)
```bash
npm install
npm run build        # → dist/
```
`buildDir: "dist"`. Vite's `base` must be `"/"` (the default) or `"./"`. A GitHub Pages-style base like `"/my-game/"` breaks asset URLs; `check` warns about it. Assets in `public/` are copied to `dist/`.

## Other bundlers (webpack, Parcel, esbuild, Rollup)
Run the production build and set `buildDir` to its output (`dist/`, `build/` or `out/`). Use a root or relative public path.

## Godot 4
Export for **Web with thread support off** (Godot 4.3+: Project → Export → Web → *Thread Support* unchecked). Threaded builds need `SharedArrayBuffer`, which isn't available on JuicyJuicy.
```bash
godot --headless --export-release "Web" export/web/index.html
```
`buildDir: "export/web"`, `engine: "godot"`. Keep the `.pck` and `.wasm` next to `index.html`.

## Unity
Build for WebGL. Prefer **Brotli or Gzip compression with "Decompression Fallback" off**: JuicyJuicy serves `*.br` and `*.gz` files with the right `Content-Encoding`. `buildDir` is the folder with `index.html` (and `Build/`), `engine: "unity"`. Builds over 150 MB won't fit: lower texture sizes and strip unused code.

## Size limits
150 MB per version, 3,000 files, 100 MB per file. Source maps (`*.map`) are skipped unless you pass `--include-source-maps`.
