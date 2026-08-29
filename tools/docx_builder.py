"""
docx_builder.py — Generador de documentos .docx con estilo consistente.

Uso:
    from tools.docx_builder import DocxBuilder

    builder = DocxBuilder()
    builder.set_title("Trabajo Práctico 1")
    builder.add_heading("Sección", level=2)
    builder.add_paragraph("Texto de ejemplo.")
    builder.add_bullet("Item 1")
    builder.add_bullet("Item 2")
    builder.save("output.docx")

Estilo:
    - Fuente principal: Calibri 11pt
    - Títulos: Calibri Bold, jerarquía 1-3
    - Viñetas: sangría consistente
    - Márgenes: 2.5cm lado, 2cm arriba/abajo
    - Interlineado: 1.15
"""

from pathlib import Path
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.style import WD_STYLE_TYPE


# ── Configuración de estilo ──────────────────────────────────────────────

FONT_BODY = "Calibri"
FONT_HEADING = "Calibri"
FONT_SIZE_BODY = Pt(11)
FONT_SIZE_H1 = Pt(18)
FONT_SIZE_H2 = Pt(14)
FONT_SIZE_H3 = Pt(12)

LINE_SPACING = 1.15

MARGIN_LEFT = Cm(2.5)
MARGIN_RIGHT = Cm(2.5)
MARGIN_TOP = Cm(2)
MARGIN_BOTTOM = Cm(2)

COLOR_HEADING = RGBColor(0x1A, 0x1A, 0x2E)  # Azul oscuro sobrio
COLOR_BODY = RGBColor(0x00, 0x00, 0x00)


class DocxBuilder:
    """Generador de documentos .docx con estilo consistente."""

    def __init__(self):
        self.doc = Document()
        self._configure_styles()
        self._configure_page()

    def _configure_styles(self):
        """Aplica estilos consistentes al documento."""
        style = self.doc.styles["Normal"]
        font = style.font
        font.name = FONT_BODY
        font.size = FONT_SIZE_BODY
        font.color.rgb = COLOR_BODY
        pf = style.paragraph_format
        pf.space_after = Pt(6)
        pf.line_spacing = LINE_SPACING

        for level, size in [
            ("Heading 1", FONT_SIZE_H1),
            ("Heading 2", FONT_SIZE_H2),
            ("Heading 3", FONT_SIZE_H3),
        ]:
            s = self.doc.styles[level]
            s.font.name = FONT_HEADING
            s.font.size = size
            s.font.bold = True
            s.font.color.rgb = COLOR_HEADING
            s.paragraph_format.space_before = Pt(18 if level == "Heading 1" else 12)
            s.paragraph_format.space_after = Pt(8)

    def _configure_page(self):
        """Configura márgenes y tamaño de página."""
        for section in self.doc.sections:
            section.left_margin = MARGIN_LEFT
            section.right_margin = MARGIN_RIGHT
            section.top_margin = MARGIN_TOP
            section.bottom_margin = MARGIN_BOTTOM

    # ── API pública ───────────────────────────────────────────────────────

    def set_title(self, text: str):
        """Agrega un título principal (H1) al documento."""
        self.doc.add_heading(text, level=1)
        return self

    def add_heading(self, text: str, level: int = 2):
        """Agrega un encabezado con el nivel indicado (1-3)."""
        self.doc.add_heading(text, level=level)
        return self

    def add_paragraph(self, text: str, bold: bool = False):
        """Agrega un párrafo normal."""
        p = self.doc.add_paragraph(text)
        if bold:
            for run in p.runs:
                run.bold = True
        return self

    def add_bullet(self, text: str, level: int = 0):
        """Agrega un ítem de lista con viñeta."""
        p = self.doc.add_paragraph(text, style="List Bullet")
        if level > 0:
            p.paragraph_format.left_indent = Cm(1.27 * level)
        return self

    def add_numbered(self, text: str):
        """Agrega un ítem de lista numerada."""
        self.doc.add_paragraph(text, style="List Number")
        return self

    def add_separator(self):
        """Agrega una línea separadora visual (triple guión)."""
        p = self.doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run("─" * 50)
        run.font.color.rgb = RGBColor(0xCC, 0xCC, 0xCC)
        run.font.size = Pt(8)
        return self

    def add_quote(self, text: str, author: str = ""):
        """Agrega una cita con formato especial."""
        p = self.doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(1.5)
        p.paragraph_format.right_indent = Cm(1.5)
        run = p.add_run(f'"{text}"')
        run.italic = True
        run.font.color.rgb = RGBColor(0x55, 0x55, 0x55)
        if author:
            run2 = p.add_run(f"\n— {author}")
            run2.font.color.rgb = RGBColor(0x77, 0x77, 0x77)
            run2.font.size = Pt(10)
        return self

    def add_table(self, headers: list[str], rows: list[list[str]]):
        """Agrega una tabla con encabezados y filas."""
        table = self.doc.add_table(rows=1 + len(rows), cols=len(headers))
        table.style = "Light Grid Accent 1"
        for i, header in enumerate(headers):
            cell = table.rows[0].cells[i]
            cell.text = header
            for p in cell.paragraphs:
                for run in p.runs:
                    run.bold = True
        for r_idx, row in enumerate(rows):
            for c_idx, val in enumerate(row):
                table.rows[r_idx + 1].cells[c_idx].text = val
        return self

    def add_image(self, path: str | Path, width: Cm = Cm(15)):
        """Agrega una imagen al documento."""
        self.doc.add_picture(str(path), width=width)
        return self

    def save(self, path: str | Path):
        """Guarda el documento en la ruta indicada."""
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        self.doc.save(str(path))
        return str(path.resolve())


# ── CLI rápido ────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import sys

    output = sys.argv[1] if len(sys.argv) > 1 else "output.docx"
    b = DocxBuilder()
    b.set_title("Documento de Ejemplo")
    b.add_heading("Sección de Prueba", level=2)
    b.add_paragraph("Este es un párrafo de ejemplo con estilo consistente.")
    b.add_bullet("Primer ítem")
    b.add_bullet("Segundo ítem")
    b.add_quote("La seguridad no es un producto, es un proceso.", "Kevin Mitnick")
    b.add_table(["Concepto", "Descripción"], [
        ["Confidencialidad", "Proteger la información de acceso no autorizado"],
        ["Integridad", "Garantizar que la información no sea alterada"],
    ])
    result = b.save(output)
    print(f"Documento creado: {result}")
