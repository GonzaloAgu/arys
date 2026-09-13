"""
make_reference.py — Genera tools/reference.docx para pandoc.

Toma el reference.docx por defecto que trae pandoc, le agrega los estilos de la
carátula (centrado, tipografías y colores) y ajusta los márgenes de página.
Es una tarea de configuración puntual: la primera vez que se ejecuta
tps/build_tp.py (o manualmente aquí) si falta tools/reference.docx.

Usa solo la stdlib de Python. Requiere pandoc en el PATH.

Uso:
    python tools/make_reference.py
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tools" / "reference.docx"

STYLES_PATH = "word/styles.xml"
DOC_PATH = "word/document.xml"

# Márgenes de página en twips (top/bottom 2 cm = 1134, lado 2.5 cm = 1418).
MARGINS = {"w:top": "1134", "w:bottom": "1134", "w:left": "1418", "w:right": "1418"}

# Estilos de párrafo de la carátula, insertados antes de </w:styles>.
COVER_STYLES = """
  <w:style w:type="paragraph" w:styleId="CoverCenter">
    <w:name w:val="CoverCenter"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverSpacer">
    <w:name w:val="CoverSpacer"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0" w:line="340" w:lineRule="exact"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="2"/><w:szCs w:val="2"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverSpacerSmall">
    <w:name w:val="CoverSpacerSmall"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0" w:line="120" w:lineRule="exact"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="2"/><w:szCs w:val="2"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverSpacerLarge">
    <w:name w:val="CoverSpacerLarge"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0" w:line="540" w:lineRule="exact"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="2"/><w:szCs w:val="2"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverUniv">
    <w:name w:val="CoverUniv"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:color w:val="444444"/><w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverSub">
    <w:name w:val="CoverSub"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:color w:val="666666"/><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverTitle">
    <w:name w:val="CoverTitle"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:color w:val="1A1A2E"/><w:sz w:val="52"/><w:szCs w:val="52"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverMateria">
    <w:name w:val="CoverMateria"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:color w:val="333333"/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverLabel">
    <w:name w:val="CoverLabel"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:color w:val="777777"/><w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverValue">
    <w:name w:val="CoverValue"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:color w:val="1A1A2E"/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverRule">
    <w:name w:val="CoverRule"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:color w:val="1A1A2E"/><w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="CoverRepo">
    <w:name w:val="CoverRepo"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr><w:spacing w:before="0" w:after="0"/><w:jc w:val="center"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr>
  </w:style>
"""


def pandoc_default(tmp_dir: Path) -> bytes:
    if shutil.which("pandoc") is None:
        print("Error: pandoc no está instalado.", file=sys.stderr)
        print("Instalalo manualmente y volvé a ejecutar:", file=sys.stderr)
        print("  - winget install --id JohnMacFarlane.Pandoc", file=sys.stderr)
        print("  - https://pandoc.org/installing.html", file=sys.stderr)
        sys.exit(1)
    result = subprocess.run(
        ["pandoc", "--print-default-data-file", "reference.docx"],
        capture_output=True,
    )
    if result.returncode != 0:
        print("Error: pandoc no devolvió el reference.docx por defecto.", file=sys.stderr)
        print(result.stderr.decode("utf-8", "replace"), file=sys.stderr)
        sys.exit(1)
    return result.stdout


def patch_styles(styles_xml: str) -> str:
    needle = "</w:styles>"
    if needle not in styles_xml:
        raise RuntimeError("no se encontró </w:styles> en word/styles.xml")
    return styles_xml.replace(needle, COVER_STYLES + "\n" + needle, 1)


def _patch_margins(xml: str) -> str:
    m = re.search(r"<w:pgMar\b[^>]*/>", xml)
    if not m:
        return xml
    mar = m.group(0)
    for attr, val in MARGINS.items():
        mar = re.sub(rf'({attr}=")\d+(")', rf"\g<1>{val}\g<2>", mar)
    return xml[: m.start()] + mar + xml[m.end():]


def main():
    if OUT.exists():
        print(f"tools/reference.docx ya existe. Para regenerarlo, borralo antes.")
        return

    print("Pidiendo el reference.docx por defecto a pandoc ...")
    default = pandoc_default(Path(tempfile.gettempdir()))

    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp) / "base.docx"
        base.write_bytes(default)

        with zipfile.ZipFile(base) as zin:
            infolist = zin.infolist()
            items = {info.filename: zin.read(info) for info in infolist}

        items[STYLES_PATH] = patch_styles(items[STYLES_PATH].decode("utf-8")).encode("utf-8")
        doc = items.get(DOC_PATH)
        if doc:
            items[DOC_PATH] = _patch_margins(doc.decode("utf-8")).encode("utf-8")

        with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as zout:
            for info in infolist:
                zout.writestr(info.filename, items[info.filename])

    print("Estilos de carátula agregados y márgenes ajustados.")
    print(f"Referencia creada: {OUT}")


if __name__ == "__main__":
    main()