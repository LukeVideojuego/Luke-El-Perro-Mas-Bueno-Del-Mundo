"""Copia web/head_include.html al html/head_include del preset "Web"
(export_presets.cfg), escapado como string de Godot.

    python tools/update_head_include.py
"""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
html = (root / "web" / "head_include.html").read_text(encoding="utf-8")
esc = html.replace("\\", "\\\\").replace('"', '\\"').replace("\r", "").replace("\n", "\\n")
cfg_path = root / "export_presets.cfg"
cfg = cfg_path.read_text(encoding="utf-8")
lines = cfg.split("\n")
idx = [i for i, l in enumerate(lines) if l.startswith('html/head_include="')]
assert len(idx) == 1, "no se encontro html/head_include en export_presets.cfg"
lines[idx[0]] = 'html/head_include="' + esc + '"'
cfg_path.write_text("\n".join(lines), encoding="utf-8", newline="\n")
print("head_include actualizado:", len(html), "caracteres")
