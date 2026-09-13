"""
build_tp.py — Genera el entregable de un TP integrando pandoc.

Reemplazo total del generador anterior: NO usa python-docx ni un parser de
Markdown propio. La conversión la hace pandoc; los estilos se toman de
tools/reference.docx (DOCX) o de tools/tp_style.css (PDF).

Salida por defecto: PDF (HTML estilizado con CSS + Chrome headless).
Con `--docx`: archivo .docx clásico.

Uso:
    python tps/build_tp.py <numero>          # genera tps/N/trabajo_practico.pdf
    python tps/build_tp.py <numero> --docx   # genera tps/N/trabajo_practico.docx

Requiere pandoc en el PATH (https://pandoc.org/installing.html).
Para PDF se usa Chrome o Edge (headless); en el primer uso del DOCX se genera
automáticamente tools/reference.docx con tools/make_reference.py.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TPS_ROOT = ROOT / "tps"
LOGO = ROOT / "tools" / "logo_unpsjb.png"
REFERENCE = ROOT / "tools" / "reference.docx"
MAKE_REFERENCE = ROOT / "tools" / "make_reference.py"
STYLE_CSS = ROOT / "tools" / "tp_style.css"

# ── Datos de la carátula ─────────────────────────────────────────────────
MATERIA = "Administración de Redes y Seguridad"
JTP = "Lucas Krmpotic"
ALUMNO = "Gonzalo Agú"
REPO_URL = "https://github.com/GonzaloAgu/arys"
REPO_TEXT = "github.com/GonzaloAgu/arys"

NBSP = "\u00A0"
RULE = "\u2501" * 50  # separador de 50 "━"

# Carátula en Markdown para DOCX: cada `::: {custom-style="X"}` es un párrafo
# con el estilo X definido en tools/reference.docx.
COVER_DOCX = """::: {custom-style="CoverSpacerLarge"}
@@NBSP@@
:::

@@LOGO@@
::: {custom-style="CoverUniv"}
UNIVERSIDAD NACIONAL DE LA PATAGONIA SAN JUAN BOSCO
:::

::: {custom-style="CoverSub"}
Facultad de Ingeniería
:::

::: {custom-style="CoverSub"}
Licenciatura en Sistemas
:::

::: {custom-style="CoverRule"}
@@RULE@@
:::

::: {custom-style="CoverTitle"}
@@TITULO@@
:::

::: {custom-style="CoverMateria"}
@@MATERIA@@
:::

::: {custom-style="CoverLabel"}
Jefe de Trabajo Práctico
:::

::: {custom-style="CoverValue"}
@@JTP@@
:::

::: {custom-style="CoverSpacerSmall"}
@@NBSP@@
:::

::: {custom-style="CoverLabel"}
Alumno
:::

::: {custom-style="CoverValue"}
@@ALUMNO@@
:::

::: {custom-style="CoverSpacer"}
@@NBSP@@
:::

::: {custom-style="CoverRule"}
@@RULE@@
:::

::: {custom-style="CoverLabel"}
Repositorio
:::

::: {custom-style="CoverRepo"}
[@@REPO_TEXT@@](@@REPO_URL@@)
:::

```{=openxml}
<w:p><w:r><w:br w:type="page"/></w:r></w:p>
```
"""

# Carátula en Markdown para PDF: las clases se estilizan en tools/tp_style.css.
COVER_PDF = """::: {.cover-logo}
![](@@LOGO_REL@@){width=110px}
:::

::: {.cover-univ}
UNIVERSIDAD NACIONAL DE LA PATAGONIA SAN JUAN BOSCO
:::

::: {.cover-sub}
Facultad de Ingeniería
:::

::: {.cover-sub}
Licenciatura en Sistemas
:::

::: {.cover-rule}
@@RULE@@
:::

::: {.cover-title}
@@TITULO@@
:::

::: {.cover-materia}
@@MATERIA@@
:::

::: {.cover-label}
Jefe de Trabajo Práctico
:::

::: {.cover-value}
@@JTP@@
:::

::: {.cover-label}
Alumno
:::

::: {.cover-value}
@@ALUMNO@@
:::

::: {.cover-rule}
@@RULE@@
:::

::: {.cover-label}
Repositorio
:::

::: {.cover-repo}
[@@REPO_TEXT@@](@@REPO_URL@@)
:::

::: {.page-break}
@@NBSP@@
:::
"""

CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
]


def extract_title(consigna_path: Path, tp_number: int) -> str:
    if consigna_path.exists():
        first_line = consigna_path.read_text(encoding="utf-8").split("\n")[0]
        m = re.match(r"^#\s+(.*)", first_line)
        if m:
            return m.group(1).strip()
    return f"Trabajo Práctico {tp_number}"


def _md_escape(text: str) -> str:
    return re.sub(r"([\\*_\[\]#`<>])", r"\\\1", text)


def _cover_base(cover: str, titulo: str) -> str:
    return (
        cover.replace("@@NBSP@@", NBSP)
        .replace("@@RULE@@", RULE)
        .replace("@@TITULO@@", _md_escape(titulo.upper()))
        .replace("@@MATERIA@@", _md_escape(MATERIA))
        .replace("@@JTP@@", _md_escape(JTP))
        .replace("@@ALUMNO@@", _md_escape(ALUMNO))
        .replace("@@REPO_TEXT@@", REPO_TEXT)
        .replace("@@REPO_URL@@", REPO_URL)
    )


def render_cover_docx(titulo: str) -> str:
    logo = (
        '::: {custom-style="CoverCenter"}\n'
        f'![]({LOGO.resolve().as_posix()}){{width=2.8cm}}\n'
        ':::\n'
    ) if LOGO.exists() else ""
    return _cover_base(COVER_DOCX, titulo).replace("@@LOGO@@", logo)


def render_cover_pdf(titulo: str, solucion_dir: Path) -> str:
    logo_rel = ""
    if LOGO.exists():
        logo_rel = os.path.relpath(str(LOGO), str(solucion_dir)).replace("\\", "/")
    return _cover_base(COVER_PDF, titulo).replace("@@LOGO_REL@@", logo_rel)


def find_solucion(tp_dir: Path) -> Path | None:
    # tps/N/A/solucion.md, tps/N/B/solucion.md, etc.
    for subdir in sorted(tp_dir.iterdir()):
        if subdir.is_dir():
            candidate = subdir / "solucion.md"
            if candidate.exists():
                return candidate
    # tps/N/solucion.md
    candidate = tp_dir / "solucion.md"
    if candidate.exists():
        return candidate
    return None


def _require_pandoc():
    if shutil.which("pandoc") is None:
        print("Error: pandoc no está instalado.", file=sys.stderr)
        print("Instalalo manualmente y volvé a ejecutar. Opciones:", file=sys.stderr)
        print("  - winget install --id JohnMacFarlane.Pandoc", file=sys.stderr)
        print("  - https://pandoc.org/installing.html", file=sys.stderr)
        sys.exit(1)


def ensure_reference():
    if REFERENCE.exists():
        return True
    print("Primer uso: generando tools/reference.docx ...")
    subprocess.run([sys.executable, str(MAKE_REFERENCE)], cwd=ROOT)
    return REFERENCE.exists()


def find_chromium() -> str | None:
    env_override = os.environ.get("ARYS_CHROME")
    if env_override and Path(env_override).exists():
        return env_override
    for candidate in CHROME_CANDIDATES:
        if Path(candidate).exists():
            return candidate
    if shutil.which("chrome"):
        return shutil.which("chrome")
    if shutil.which("msedge"):
        return shutil.which("msedge")
    return None


def build_docx(tp_dir: Path, tp_number: int, titulo: str, solucion: Path):
    if not ensure_reference():
        print("Error: no se pudo generar tools/reference.docx.", file=sys.stderr)
        sys.exit(1)

    cover = render_cover_docx(titulo)
    body = solucion.read_text(encoding="utf-8")

    output = tp_dir / "trabajo_practico.docx"
    cmd = [
        "pandoc",
        "-f", "markdown+raw_attribute",
        "-t", "docx",
        f"--reference-doc={REFERENCE}",
        f"--resource-path={solucion.parent}",
        "-o", str(output),
    ]
    try:
        subprocess.run(cmd, input=(cover + "\n\n" + body).encode("utf-8"),
                       cwd=solucion.parent, check=True)
    except subprocess.CalledProcessError as exc:
        print(f"Error: pandoc falló al convertir el DOCX (código {exc.returncode}).",
              file=sys.stderr)
        sys.exit(1)
    print(f"Documento creado: {output}")
    return output


def build_pdf(tp_dir: Path, titulo: str, solucion: Path):
    chrome = find_chromium()
    if chrome is None:
        print("Error: no se encontró Chrome ni Edge para generar el PDF.", file=sys.stderr)
        print("Instalá Google Chrome o Microsoft Edge, o definí ARYS_CHROME", file=sys.stderr)
        print("con la ruta al ejecutable.", file=sys.stderr)
        sys.exit(1)

    cover = render_cover_pdf(titulo, solucion.parent)
    body = solucion.read_text(encoding="utf-8")
    combined = (cover + "\n\n" + body).encode("utf-8")

    output = tp_dir / "trabajo_practico.pdf"
    with tempfile.TemporaryDirectory(prefix="tp_build_") as tmp:
        tmp = Path(tmp)
        html = tmp / "documento.html"
        profile_dir = tmp / "chrome_profile"

        try:
            subprocess.run(
                ["pandoc", "-f", "markdown+raw_attribute", "-t", "html",
                 "--standalone", "--embed-resources", f"--css={STYLE_CSS}",
                 "-o", str(html)],
                input=combined, cwd=solucion.parent, check=True,
            )
        except subprocess.CalledProcessError as exc:
            print(f"Error: pandoc falló al generar el HTML (código {exc.returncode}).",
                  file=sys.stderr)
            sys.exit(1)

        try:
            subprocess.run([
                chrome, "--headless=new", "--disable-gpu",
                "--no-margins", "--no-pdf-header-footer",
                f"--user-data-dir={profile_dir}",
                f"--print-to-pdf={output}",
                html.resolve().as_uri(),
            ], timeout=180)
        except (subprocess.SubprocessError, OSError) as exc:
            print(f"Error: Chrome/Edge falló al imprimir el PDF ({exc}).", file=sys.stderr)
            sys.exit(1)

        # Chrome a veces termina antes de flush del PDF; esperar a que exista.
        for _ in range(40):
            if output.exists() and output.stat().st_size > 0:
                break
            time.sleep(0.5)
        else:
            print("Error: Chrome no escribió el PDF.", file=sys.stderr)
            sys.exit(1)

    print(f"Documento creado: {output}")
    return output


def build_tp(tp_number: int, fmt: str):
    tp_dir = TPS_ROOT / str(tp_number)
    if not tp_dir.exists():
        print(f"Error: no existe tps/{tp_number}/", file=sys.stderr)
        sys.exit(1)

    consigna = tp_dir / "consigna.md"
    titulo = extract_title(consigna, tp_number)

    solucion = find_solucion(tp_dir)
    if not solucion:
        print(f"Error: no se encontró solucion.md en tps/{tp_number}/", file=sys.stderr)
        sys.exit(1)

    _require_pandoc()

    if fmt == "docx":
        build_docx(tp_dir, tp_number, titulo, solucion)
    else:
        build_pdf(tp_dir, titulo, solucion)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Genera el entregable de un TP (PDF por defecto).")
    parser.add_argument("numero", type=int, help="Número de TP, ej. 1")
    parser.add_argument("--docx", action="store_true",
                        help="Genera .docx en lugar del PDF por defecto")
    args = parser.parse_args()

    build_tp(args.numero, "docx" if args.docx else "pdf")