"""Arma el paquete web para itch.io a partir de export_web/ (preset "Web").

    godot --headless --path . --export-release "Web" export_web/index.html
    python tools/package_web.py

- Agrega index.wasm.gz (el motor comprimido: ~40 MB -> ~10 MB). La pagina
  (web/head_include.html) lo baja y lo descomprime en el navegador; si algo
  falla usa index.wasm, que tambien va en el paquete.
- Genera luke_web.zip con index.html en la raiz.
"""
import gzip
import pathlib
import zipfile

root = pathlib.Path(__file__).resolve().parent.parent
web = root / "export_web"
wasm = web / "index.wasm"
gz = web / "index.wasm.gz"
gz.write_bytes(gzip.compress(wasm.read_bytes(), compresslevel=9, mtime=0))
print("index.wasm %.1f MB -> index.wasm.gz %.1f MB" % (wasm.stat().st_size / 1e6, gz.stat().st_size / 1e6))

out = root / "luke_web.zip"
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for f in sorted(web.iterdir()):
        if f.name.startswith("."):
            continue
        # Lo ya comprimido (gz, png) se guarda sin recomprimir.
        kind = zipfile.ZIP_STORED if f.suffix in (".gz", ".png") else zipfile.ZIP_DEFLATED
        z.write(f, f.name, compress_type=kind)
print("luke_web.zip: %.1f MB" % (out.stat().st_size / 1e6))
